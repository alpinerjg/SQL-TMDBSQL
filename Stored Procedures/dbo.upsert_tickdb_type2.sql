SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- ============================================= 
-- Author:     
-- Create date:  
-- Description:   https://www.mssqltips.com/sqlservertip/3188/implementing-sql-server-transaction-retry-logic-for-failed-transactions/
-- ============================================= 
CREATE PROCEDURE [dbo].[upsert_tickdb_type2] @bbsecurity    VARCHAR(32), 
                                            @type          CHAR(1), 
                                            @src           VARCHAR(15), 
                                            @value         DECIMAL(12, 6), 
                                            @delayed       BIT, 
                                            @tsbb          DATETIME2 = NULL, 
                                            @ts            DATETIME2 = NULL, 
                                            @return_status INT = 0 output 
AS 
  BEGIN 
      -- DECLARE @ts datetime2; 
      IF ( @ts IS NULL ) 
        SET @ts = Sysdatetime() 

      -- DECLARE @return_status int; 
      SET @return_status = 0; 

      IF ( @tsbb IS NULL ) 
        SET @tsbb = @ts 

      -- Some prices are coming in with times in the future (ie. ROL Equity) 
      -- Consider checking at the source and flagging/correcting 
      -- This stored procedure should be simple and fast 
      IF ( @tsbb > @ts ) 
        SET @tsbb = @ts 

      DECLARE @RetryCount INT 
      DECLARE @Success BIT 

      SELECT @RetryCount = 1, 
             @Success = 0 

      WHILE @RetryCount < = 3 
            AND @Success = 0 
        BEGIN 
            BEGIN try 
                BEGIN TRANSACTION 

                -- This line is to show you on which execution  
                -- we successfully commit. 
                SELECT 'Attempt #' 
                       + Cast (@RetryCount AS VARCHAR(5)) 

                -- Check to see if we already have the bb symbol 
                IF EXISTS(SELECT 1 
                          FROM   dbo.tickdb_type 
                          WHERE  bbsecurity = @bbsecurity 
                                 AND type = @type 
                                 AND src = @src) 
                  BEGIN 
                      -- Even if it's there, make sure that it's more recent 
                      IF EXISTS(SELECT 1 
                                FROM   dbo.tickdb_type 
                                WHERE  bbsecurity = @bbsecurity 
                                       AND type = @type 
                                       AND src = @src 
                                       AND tsbb < @tsbb) 
                        BEGIN 
                            UPDATE dbo.tickdb_type WITH (serializable) 
                            SET    value = @value, 
                                   delayed = @delayed, 
                                   tsbb = @tsbb, 
                                   ts = @ts 
                            WHERE  bbsecurity = @bbsecurity 
                                   AND type = @type 
                                   AND src = @src 

                            SET @return_status = 1 
                        END 
                  END 
                ELSE 
                  BEGIN 
                      -- new record 
                      INSERT INTO dbo.tickdb_type 
                                  (bbsecurity, 
                                   type, 
                                   src, 
                                   value, 
                                   delayed, 
                                   ts, 
                                   tsbb) 
                      VALUES      (@bbsecurity, 
                                   @type, 
                                   @src, 
                                   @value, 
                                   @delayed, 
                                   @ts, 
                                   @tsbb) 

                      SET @return_status = 1 
                  END 

                COMMIT TRANSACTION 

                SELECT 'Success!' 

                SELECT @Success = 1 -- To exit the loop 
            END try 

            BEGIN catch 
                ROLLBACK TRANSACTION 

                SELECT Error_number()  AS [Error Number], 
                       Error_message() AS [ErrorMessage]; 

                -- Now we check the error number to  
                -- only use retry logic on the errors we  
                -- are able to handle. 
                -- 
                -- You can set different handlers for different  
                -- errors 
                IF Error_number() IN ( 1204, -- SqlOutOfLocks 
                                       1205, -- SqlDeadlockVictim 
                                       1222-- SqlLockRequestTimeout 
                                      ) 
                  BEGIN 
                      SET @RetryCount = @RetryCount + 1 

                      -- This delay is to give the blocking  
                      -- transaction time to finish. 
                      -- So you need to tune according to your  
                      -- environment 
                      WAITFOR delay '00:00:02' 
                  END 
                ELSE 
                  BEGIN 
                      -- If we don't have a handler for current error 
                      -- then we throw an exception and abort the loop 
                      THROW; 
                  END 
            END catch 
        END 
  END 
GO
