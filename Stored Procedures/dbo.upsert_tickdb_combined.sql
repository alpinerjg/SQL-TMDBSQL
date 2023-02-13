SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[upsert_tickdb_combined] 
	@bbsecurity varchar(32),
      @price decimal(12,6),
	  @bid decimal(12,6) = null,
	  @ask decimal(12,6) = null,
	  @delayed bit,
	  @src varchar(15),
	  @tsbb datetime2 = null,
	  @ts datetime2 = null,
	  @return_status int = 0 output 
AS
BEGIN

-- DECLARE @ts datetime2;
IF (@ts IS NULL)
	SET @ts = SYSDATETIME()

-- DECLARE @return_status int;
SET @return_status = 0;

BEGIN TRANSACTION

IF (@tsbb IS NULL)
	SET @tsbb = @ts 

-- Some prices are coming in with times in the future (ie. ROL Equity)
-- Consider checking at the source and flagging/correcting
-- This stored procedure should be simple and fast
IF (@tsbb > @ts)
	SET @tsbb = @ts

-- Check to see if we already have the bb symbol
IF EXISTS(SELECT 1 FROM dbo.TICKDB_COMBINED WHERE bbsecurity = @bbsecurity)
	BEGIN
	    -- Even if it's there, make sure that it's more recent
		IF EXISTS(SELECT 1 FROM dbo.TICKDB_COMBINED WHERE bbsecurity = @bbsecurity AND tsbb < @tsbb)
			BEGIN
				UPDATE dbo.TICKDB_COMBINED WITH (SERIALIZABLE)
					SET price = @price, bid = @bid, ask = @ask, delayed = @delayed, src = @src, tsbb = @tsbb, ts = @ts
					WHERE bbsecurity = @bbsecurity
				SET @return_status = 1
			END
	END
ELSE
	BEGIN
     -- new record
		INSERT INTO dbo.TICKDB_COMBINED
			(bbsecurity, price, bid, ask, delayed, src, ts, tsbb)
		VALUES
			(@bbsecurity, @price, @bid, @ask, @delayed, @src, @ts, @tsbb)
		SET @return_status = 1
	END

COMMIT TRANSACTION

-- PRINT @bbsecurity
-- PRINT @return_status
-- RETURN @return_status

END
GO
