SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[upsert_tickdb_qa] 
	  @bbsecurity VARCHAR(32),
      @price DECIMAL(12,6),
	  @bid DECIMAL(12,6) = NULL,
	  @ask DECIMAL(12,6) = NULL,
	  @delayed BIT,
	  @markethours BIT,
	  @src VARCHAR(15),
	  @tsbb DATETIME2 = NULL,
	  @return_status INT = 0 OUTPUT 
AS
BEGIN

DECLARE @ts datetime2;
SET @ts = SYSDATETIME()

DECLARE @tsmin datetime2 = '1976-01-01';
IF ((@tsbb IS NULL) OR (@tsbb < @tsmin))
	SET @tsbb = @ts

DECLARE @return_status_combined int;
DECLARE @return_status_src int;
DECLARE @return_status_type_p int;
DECLARE @return_status_type_b INT;
DECLARE @return_status_type_a INT;
DECLARE @return_status_rolling24_p INT;
DECLARE @return_status_rolling24_b INT;
DECLARE @return_status_rolling24_a INT;

SET @return_status_combined = 0;
SET @return_status_src = 0;
SET @return_status_type_p = 0;
SET @return_status_type_b = 0;
SET @return_status_type_a = 0;
SET @return_status_rolling24_p = 0;
SET @return_status_rolling24_b = 0;
SET @return_status_rolling24_a = 0;

-- For Delayed prices, don't let them compete with published prices with no delay
IF @delayed = 1
	BEGIN
		DECLARE @FifteenMinutesAgo DATETIME2 = DATEADD(minute, -15, GETDATE())
		SET @FifteenMinutesAgo = DATEADD(minute, -15, GETDATE())
		-- Arbitrarily impose a minumum 15 minute offset on delayed pricing
		if @tsbb > @FifteenMinutesAgo
			SET @tsbb = @FifteenMinutesAgo
	END

-- Persist to table keeping @src detail
EXEC @return_status_src = upsert_tickdb @bbsecurity, @price , @bid , @ask , @delayed , @markethours, @src , @tsbb , @ts

-- Persist to table with separate rows for each @type data point
EXEC @return_status_type_p = upsert_tickdb_type @bbsecurity, 'P' , @src , @price, @delayed , @markethours , @tsbb , @ts
-- EXEC @return_status_rolling24_p = insert_tickdb_rolling24 @bbsecurity, 'P' , @src , @price, @delayed , @tsbb , @ts

IF (@bid IS NOT NULL)
	BEGIN
		EXEC @return_status_type_b = upsert_tickdb_type @bbsecurity, 'B' , @src , @bid, @delayed , @markethours, @tsbb , @ts
--		EXEC @return_status_rolling24_b = insert_tickdb_rolling24 @bbsecurity, 'B' , @src , @bid, @delayed , @tsbb , @ts
	END

IF (@ask IS NOT NULL)
	BEGIN
		EXEC @return_status_type_a = upsert_tickdb_type @bbsecurity, 'A' , @src , @ask, @delayed , @markethours, @tsbb , @ts
--		EXEC @return_status_rolling24_a = insert_tickdb_rolling24 @bbsecurity, 'A' , @src , @ask, @delayed , @tsbb , @ts
	END

SET @return_status = @return_status_type_p

PRINT @bbsecurity
PRINT @return_status

RETURN @return_status

END
GO
