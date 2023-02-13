SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[merge_BroadridgePositions_Market] 
     @Timestamp DateTime
AS
BEGIN
BEGIN TRANSACTION merge_BroadridgePositions_Market
UPDATE t1 
SET t1.ts_end = @Timestamp
FROM [TMDBSQL].[dbo].[BroadridgePositionsMarket] t1
LEFT JOIN [TMDBSQL].[dbo].[BroadridgePositions_staging] t2 ON t2.UserName = t1.UserName AND t2.[UniqKey] = t1.[UniqKey] 
WHERE t1.ts_end IS NULL and t2.[UniqKey] IS NULL

-- ==================================================
-- Slowly Changing Dimension script by SCD Merge Wizard
-- Author: Miljan Radovic
-- Official web site: https://github.com/SQLPlayer/SCD-Merge-Wizard/
-- Version: 4.3.0.0
-- Publish date: 4/7/2021 4:51:57 PM
-- Script creation date: 4/7/2021 8:57:31 PM
-- ==================================================


-- ==================================================
-- SCD2
-- ==================================================
INSERT INTO [dbo].[BroadridgePositionsMarket]
(
	[Position_Calculated_BaseLongMarketValue],
	[Position_Calculated_BaseLongMarketValueGain],
	[Position_Calculated_BaseMarketValue],
	[Position_Calculated_BaseMarketValueDayGain],
	[Position_Calculated_BasePNL_DTD],
	[Position_Calculated_BasePNL_MTD],
	[Position_Calculated_BasePNL_YTD],
	[Position_Calculated_BaseShortMarketValue],
	[Position_Calculated_BaseShortMarketValueGain],
	[Position_Calculated_LocalMarketValue],
	[Position_Calculated_MarketPrice],
	[Security_Security_MD_RealTimePrice],
	[ts_end],
	[ts_start],
	[UniqKey],
	[UserName]
)
SELECT
	[Position_Calculated_BaseLongMarketValue],
	[Position_Calculated_BaseLongMarketValueGain],
	[Position_Calculated_BaseMarketValue],
	[Position_Calculated_BaseMarketValueDayGain],
	[Position_Calculated_BasePNL_DTD],
	[Position_Calculated_BasePNL_MTD],
	[Position_Calculated_BasePNL_YTD],
	[Position_Calculated_BaseShortMarketValue],
	[Position_Calculated_BaseShortMarketValueGain],
	[Position_Calculated_LocalMarketValue],
	[Position_Calculated_MarketPrice],
	[Security_Security_MD_RealTimePrice],
	[ts_end],
	[ts_start],
	[UniqKey],
	[UserName]
FROM
(
	MERGE [dbo].[BroadridgePositionsMarket] WITH(HOLDLOCK) as [target]
	USING
	(
		SELECT
			[Position_Calculated_BaseLongMarketValue],
			[Position_Calculated_BaseLongMarketValueGain],
			[Position_Calculated_BaseMarketValue],
			[Position_Calculated_BaseMarketValueDayGain],
			[Position_Calculated_BasePNL_DTD],
			[Position_Calculated_BasePNL_MTD],
			[Position_Calculated_BasePNL_YTD],
			[Position_Calculated_BaseShortMarketValue],
			[Position_Calculated_BaseShortMarketValueGain],
			[Position_Calculated_LocalMarketValue],
			[Position_Calculated_MarketPrice],
			[Security_Security_MD_RealTimePrice],
			[UniqKey],
			[UserName]
		FROM [dbo].[BroadridgePositions_staging]

	) as [source]
	ON
	(
		[source].[UniqKey] = [target].[UniqKey] AND
		[source].[UserName] = [target].[UserName]
	)

	WHEN NOT MATCHED BY TARGET
	THEN INSERT
	(
		[Position_Calculated_BaseLongMarketValue],
		[Position_Calculated_BaseLongMarketValueGain],
		[Position_Calculated_BaseMarketValue],
		[Position_Calculated_BaseMarketValueDayGain],
		[Position_Calculated_BasePNL_DTD],
		[Position_Calculated_BasePNL_MTD],
		[Position_Calculated_BasePNL_YTD],
		[Position_Calculated_BaseShortMarketValue],
		[Position_Calculated_BaseShortMarketValueGain],
		[Position_Calculated_LocalMarketValue],
		[Position_Calculated_MarketPrice],
		[Security_Security_MD_RealTimePrice],
		[ts_end],
		[ts_start],
		[UniqKey],
		[UserName]
	)
	VALUES
	(
		[Position_Calculated_BaseLongMarketValue],
		[Position_Calculated_BaseLongMarketValueGain],
		[Position_Calculated_BaseMarketValue],
		[Position_Calculated_BaseMarketValueDayGain],
		[Position_Calculated_BasePNL_DTD],
		[Position_Calculated_BasePNL_MTD],
		[Position_Calculated_BasePNL_YTD],
		[Position_Calculated_BaseShortMarketValue],
		[Position_Calculated_BaseShortMarketValueGain],
		[Position_Calculated_LocalMarketValue],
		[Position_Calculated_MarketPrice],
		[Security_Security_MD_RealTimePrice],
		NULL,
		@TimeStamp,
		[UniqKey],
		[UserName]
	)


WHEN MATCHED AND
(
	[ts_end] = NULL
)
AND
(
	([target].[Position_Calculated_BaseLongMarketValue] <> [source].[Position_Calculated_BaseLongMarketValue] OR ([target].[Position_Calculated_BaseLongMarketValue] IS NULL AND [source].[Position_Calculated_BaseLongMarketValue] IS NOT NULL) OR ([target].[Position_Calculated_BaseLongMarketValue] IS NOT NULL AND [source].[Position_Calculated_BaseLongMarketValue] IS NULL)) OR
	([target].[Position_Calculated_BaseLongMarketValueGain] <> [source].[Position_Calculated_BaseLongMarketValueGain] OR ([target].[Position_Calculated_BaseLongMarketValueGain] IS NULL AND [source].[Position_Calculated_BaseLongMarketValueGain] IS NOT NULL) OR ([target].[Position_Calculated_BaseLongMarketValueGain] IS NOT NULL AND [source].[Position_Calculated_BaseLongMarketValueGain] IS NULL)) OR
	([target].[Position_Calculated_BaseMarketValue] <> [source].[Position_Calculated_BaseMarketValue] OR ([target].[Position_Calculated_BaseMarketValue] IS NULL AND [source].[Position_Calculated_BaseMarketValue] IS NOT NULL) OR ([target].[Position_Calculated_BaseMarketValue] IS NOT NULL AND [source].[Position_Calculated_BaseMarketValue] IS NULL)) OR
	([target].[Position_Calculated_BaseMarketValueDayGain] <> [source].[Position_Calculated_BaseMarketValueDayGain] OR ([target].[Position_Calculated_BaseMarketValueDayGain] IS NULL AND [source].[Position_Calculated_BaseMarketValueDayGain] IS NOT NULL) OR ([target].[Position_Calculated_BaseMarketValueDayGain] IS NOT NULL AND [source].[Position_Calculated_BaseMarketValueDayGain] IS NULL)) OR
	([target].[Position_Calculated_BasePNL_DTD] <> [source].[Position_Calculated_BasePNL_DTD] OR ([target].[Position_Calculated_BasePNL_DTD] IS NULL AND [source].[Position_Calculated_BasePNL_DTD] IS NOT NULL) OR ([target].[Position_Calculated_BasePNL_DTD] IS NOT NULL AND [source].[Position_Calculated_BasePNL_DTD] IS NULL)) OR
	([target].[Position_Calculated_BasePNL_MTD] <> [source].[Position_Calculated_BasePNL_MTD] OR ([target].[Position_Calculated_BasePNL_MTD] IS NULL AND [source].[Position_Calculated_BasePNL_MTD] IS NOT NULL) OR ([target].[Position_Calculated_BasePNL_MTD] IS NOT NULL AND [source].[Position_Calculated_BasePNL_MTD] IS NULL)) OR
	([target].[Position_Calculated_BasePNL_YTD] <> [source].[Position_Calculated_BasePNL_YTD] OR ([target].[Position_Calculated_BasePNL_YTD] IS NULL AND [source].[Position_Calculated_BasePNL_YTD] IS NOT NULL) OR ([target].[Position_Calculated_BasePNL_YTD] IS NOT NULL AND [source].[Position_Calculated_BasePNL_YTD] IS NULL)) OR
	([target].[Position_Calculated_BaseShortMarketValue] <> [source].[Position_Calculated_BaseShortMarketValue] OR ([target].[Position_Calculated_BaseShortMarketValue] IS NULL AND [source].[Position_Calculated_BaseShortMarketValue] IS NOT NULL) OR ([target].[Position_Calculated_BaseShortMarketValue] IS NOT NULL AND [source].[Position_Calculated_BaseShortMarketValue] IS NULL)) OR
	([target].[Position_Calculated_BaseShortMarketValueGain] <> [source].[Position_Calculated_BaseShortMarketValueGain] OR ([target].[Position_Calculated_BaseShortMarketValueGain] IS NULL AND [source].[Position_Calculated_BaseShortMarketValueGain] IS NOT NULL) OR ([target].[Position_Calculated_BaseShortMarketValueGain] IS NOT NULL AND [source].[Position_Calculated_BaseShortMarketValueGain] IS NULL)) OR
	([target].[Position_Calculated_LocalMarketValue] <> [source].[Position_Calculated_LocalMarketValue] OR ([target].[Position_Calculated_LocalMarketValue] IS NULL AND [source].[Position_Calculated_LocalMarketValue] IS NOT NULL) OR ([target].[Position_Calculated_LocalMarketValue] IS NOT NULL AND [source].[Position_Calculated_LocalMarketValue] IS NULL)) OR
	([target].[Position_Calculated_MarketPrice] <> [source].[Position_Calculated_MarketPrice] OR ([target].[Position_Calculated_MarketPrice] IS NULL AND [source].[Position_Calculated_MarketPrice] IS NOT NULL) OR ([target].[Position_Calculated_MarketPrice] IS NOT NULL AND [source].[Position_Calculated_MarketPrice] IS NULL)) OR
	([target].[Security_Security_MD_RealTimePrice] <> [source].[Security_Security_MD_RealTimePrice] OR ([target].[Security_Security_MD_RealTimePrice] IS NULL AND [source].[Security_Security_MD_RealTimePrice] IS NOT NULL) OR ([target].[Security_Security_MD_RealTimePrice] IS NOT NULL AND [source].[Security_Security_MD_RealTimePrice] IS NULL))

)
	THEN UPDATE
	SET
		[ts_end] = @TimeStamp


	OUTPUT
		$Action as [MERGE_ACTION_83076186-b044-4a7c-9ea2-6d2014b6741c],
		[source].[Position_Calculated_BaseLongMarketValue] AS [Position_Calculated_BaseLongMarketValue],
		[source].[Position_Calculated_BaseLongMarketValueGain] AS [Position_Calculated_BaseLongMarketValueGain],
		[source].[Position_Calculated_BaseMarketValue] AS [Position_Calculated_BaseMarketValue],
		[source].[Position_Calculated_BaseMarketValueDayGain] AS [Position_Calculated_BaseMarketValueDayGain],
		[source].[Position_Calculated_BasePNL_DTD] AS [Position_Calculated_BasePNL_DTD],
		[source].[Position_Calculated_BasePNL_MTD] AS [Position_Calculated_BasePNL_MTD],
		[source].[Position_Calculated_BasePNL_YTD] AS [Position_Calculated_BasePNL_YTD],
		[source].[Position_Calculated_BaseShortMarketValue] AS [Position_Calculated_BaseShortMarketValue],
		[source].[Position_Calculated_BaseShortMarketValueGain] AS [Position_Calculated_BaseShortMarketValueGain],
		[source].[Position_Calculated_LocalMarketValue] AS [Position_Calculated_LocalMarketValue],
		[source].[Position_Calculated_MarketPrice] AS [Position_Calculated_MarketPrice],
		[source].[Security_Security_MD_RealTimePrice] AS [Security_Security_MD_RealTimePrice],
		NULL AS [ts_end],
		@TimeStamp AS [ts_start],
		[source].[UniqKey] AS [UniqKey],
		[source].[UserName] AS [UserName]

)MERGE_OUTPUT
WHERE MERGE_OUTPUT.[MERGE_ACTION_83076186-b044-4a7c-9ea2-6d2014b6741c] = 'UPDATE' 
	AND MERGE_OUTPUT.[UniqKey] IS NOT NULL
	AND MERGE_OUTPUT.[UserName] IS NOT NULL
;
COMMIT TRANSACTION merge_BroadridgePositions_Market
END
GO
