SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- ============================================= 
-- Author:     
-- Create date:  
-- Description:    https://www.mssqltips.com/sqlservertip/3188/implementing-sql-server-transaction-retry-logic-for-failed-transactions/
-- ============================================= 
CREATE PROCEDURE [dbo].[GetValue2] 
	-- Add the parameters for the stored procedure here
	@bbsecurity varchar(32),
	@type char(1),
	@value decimal(12,6) = -1.0 output
AS 
  BEGIN 
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

				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

				-- Insert statements for procedure here
				SELECT TOP(1) @value = [value] FROM [TMDBSQL].[dbo].[TICKDB_TYPE] WHERE [bbsecurity] = @bbsecurity and [type] = @type ORDER BY [tsbb] DESC
				PRINT @bbsecurity + ' ' + @type + ' = ' + CAST(@value as varchar)

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
