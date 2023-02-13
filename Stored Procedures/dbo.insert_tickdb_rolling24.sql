SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO













-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[insert_tickdb_rolling24] 
	@bbsecurity VARCHAR(32),
	@type CHAR(1),
	@src VARCHAR(15),
    @value DECIMAL(12,6),
	@delayed BIT,
	@markethours BIT,
	@tsbb DATETIME2 = NULL,
	@ts DATETIME2 = NULL,
	@return_status INT = 0 OUTPUT 
AS
BEGIN

-- VVVV Remove comment if performance lags VVVV
--RETURN 0
-- ^^^^                                    ^^^^

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
		DECLARE @FifteenMinutesAgo DATETIME2
		SET @FifteenMinutesAgo = DATEADD(minute, -15, GETDATE())
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
IF NOT EXISTS(SELECT 1 FROM dbo.tickdb_rolling24 WHERE bbsecurity = @bbsecurity AND type = @type AND src = @src AND tsbb = @tsbb)
	BEGIN
		INSERT INTO [TMDBSQL].[dbo].[tickdb_rolling24]
			(bbsecurity, type, src , value , delayed, markethours, ts, tsbb)
		VALUES
			(@bbsecurity, @type, @src, @value , @delayed, @markethours, @ts, @tsbb)
END

--DELETE FROM [TMDBSQL].[dbo].[tickdb_rolling24_qa]
--	WHERE [tsbb] <= dateadd(DD,-1,@tsbb)

-- DELETE FROM [TMDBSQL].[dbo].[tickdb_rolling24_qa]
--	WHERE @tsbb <= dateadd(DD,-1,SYSDATETIME())

COMMIT TRANSACTION

-- PRINT @bbsecurity
-- PRINT @return_status
-- RETURN @return_status

END
GO
