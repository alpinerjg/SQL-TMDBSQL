SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[upsert_tickdb] 
	@bbsecurity VARCHAR(32),
      @price DECIMAL(12,6),
	  @bid DECIMAL(12,6) = NULL,
	  @ask DECIMAL(12,6) = NULL,
	  @delayed BIT,
	  @markethours BIT,
	  @src VARCHAR(15),
	  @tsbb DATETIME2 = NULL,
	  @ts DATETIME2 = NULL,
	  @return_status INT = 0 OUTPUT 
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

-- For Delayed prices, don't let them compete with published prices with no delay
IF @delayed = 1
	BEGIN
		DECLARE @FifteenMinutesAgo DATETIME2 = DATEADD(minute, -15, GETDATE())
		-- Arbitrarily impose a minumum 15 minute offset on delayed pricing
		if @tsbb > @FifteenMinutesAgo
			SET @tsbb = @FifteenMinutesAgo
	END

-- Some prices are coming in with times in the future (ie. ROL Equity)
-- Consider checking at the source and flagging/correcting
-- This stored procedure should be simple and fast
IF (@tsbb > @ts)
	SET @tsbb = @ts

-- Check to see if we already have the bb symbol
IF EXISTS(SELECT 1 FROM [TMDBSQL].[dbo].[TICKDB] WHERE bbsecurity = @bbsecurity AND src = @src)
	BEGIN
	    -- Even if it's there, make sure that it's more recent
		IF EXISTS(SELECT 1 FROM dbo.TICKDB WHERE bbsecurity = @bbsecurity AND src = @src AND tsbb < @tsbb)
			BEGIN
				UPDATE [TMDBSQL].[dbo].[TICKDB] WITH (SERIALIZABLE)
					SET price = @price, bid = @bid, ask = @ask, delayed = @delayed, markethours = @markethours, src = @src, tsbb = @tsbb, ts = @ts
					WHERE bbsecurity = @bbsecurity AND src = @src
				SET @return_status = 1
			END
	END
ELSE
	BEGIN
     -- new record
		INSERT INTO dbo.TICKDB
			(bbsecurity, price, bid, ask, delayed, markethours, src, ts, tsbb)
		VALUES
			(@bbsecurity, @price, @bid, @ask, @delayed, @markethours, @src, @ts, @tsbb)
		SET @return_status = 1
	END

COMMIT TRANSACTION

-- PRINT @bbsecurity
-- PRINT @return_status
-- RETURN @return_status

END
GO
