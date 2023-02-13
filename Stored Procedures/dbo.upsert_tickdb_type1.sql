SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- ============================================= 
-- Author:     
-- Create date:  
-- Description:   
-- ============================================= 
CREATE PROCEDURE [dbo].[upsert_tickdb_type1] @bbsecurity    VARCHAR(32), 
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

      BEGIN TRANSACTION 

      IF ( @tsbb IS NULL ) 
        SET @tsbb = @ts 

      -- Some prices are coming in with times in the future (ie. ROL Equity) 
      -- Consider checking at the source and flagging/correcting 
      -- This stored procedure should be simple and fast 
      IF ( @tsbb > @ts ) 
        SET @tsbb = @ts 

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
  -- PRINT @bbsecurity 
  -- PRINT @return_status 
  -- RETURN @return_status 
  END 
GO
