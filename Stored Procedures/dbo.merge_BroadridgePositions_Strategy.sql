SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[merge_BroadridgePositions_Strategy] 
     @Timestamp DateTime
AS
BEGIN
BEGIN TRANSACTION merge_BroadridgePositions_Strtgy
UPDATE t1 
SET t1.ts_end = @Timestamp
FROM [TMDBSQL].[dbo].[BroadridgePositionsStrategy] t1
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

INSERT INTO [dbo].[BroadridgePositionsStrategy]
(
	[Strategy_Risk_Category_RiskCategory_RiskCategoryID],
	[Strategy_Risk_Category_RiskCategory_RiskName],
	[Strategy_TradeStrategy_ActiveBenchmarkID],
	[Strategy_TradeStrategy_CountryID_mkt],
	[Strategy_TradeStrategy_Description],
	[Strategy_TradeStrategy_EndDate],
	[Strategy_TradeStrategy_IndustryID],
	[Strategy_TradeStrategy_IsClosed],
	[Strategy_TradeStrategy_Leverage],
	[Strategy_TradeStrategy_Name],
	[Strategy_TradeStrategy_PortfolioID],
	[Strategy_TradeStrategy_ShortCode],
	[ts_end],
	[ts_start],
	[UniqKey],
	[UserName]
)
SELECT
	[Strategy_Risk_Category_RiskCategory_RiskCategoryID],
	[Strategy_Risk_Category_RiskCategory_RiskName],
	[Strategy_TradeStrategy_ActiveBenchmarkID],
	[Strategy_TradeStrategy_CountryID_mkt],
	[Strategy_TradeStrategy_Description],
	[Strategy_TradeStrategy_EndDate],
	[Strategy_TradeStrategy_IndustryID],
	[Strategy_TradeStrategy_IsClosed],
	[Strategy_TradeStrategy_Leverage],
	[Strategy_TradeStrategy_Name],
	[Strategy_TradeStrategy_PortfolioID],
	[Strategy_TradeStrategy_ShortCode],
	[ts_end],
	[ts_start],
	[UniqKey],
	[UserName]
FROM
(
	MERGE [dbo].[BroadridgePositionsStrategy] WITH (HOLDLOCK) as [target]
	USING
	(
		SELECT
			[Strategy_Risk_Category_RiskCategory_RiskCategoryID],
			[Strategy_Risk_Category_RiskCategory_RiskName],
			[Strategy_TradeStrategy_ActiveBenchmarkID],
			[Strategy_TradeStrategy_CountryID_mkt],
			[Strategy_TradeStrategy_Description],
			[Strategy_TradeStrategy_EndDate],
			[Strategy_TradeStrategy_IndustryID],
			[Strategy_TradeStrategy_IsClosed],
			[Strategy_TradeStrategy_Leverage],
			[Strategy_TradeStrategy_Name],
			[Strategy_TradeStrategy_PortfolioID],
			[Strategy_TradeStrategy_ShortCode],
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
		[Strategy_Risk_Category_RiskCategory_RiskCategoryID],
		[Strategy_Risk_Category_RiskCategory_RiskName],
		[Strategy_TradeStrategy_ActiveBenchmarkID],
		[Strategy_TradeStrategy_CountryID_mkt],
		[Strategy_TradeStrategy_Description],
		[Strategy_TradeStrategy_EndDate],
		[Strategy_TradeStrategy_IndustryID],
		[Strategy_TradeStrategy_IsClosed],
		[Strategy_TradeStrategy_Leverage],
		[Strategy_TradeStrategy_Name],
		[Strategy_TradeStrategy_PortfolioID],
		[Strategy_TradeStrategy_ShortCode],
		[ts_end],
		[ts_start],
		[UniqKey],
		[UserName]
	)
	VALUES
	(
		[Strategy_Risk_Category_RiskCategory_RiskCategoryID],
		[Strategy_Risk_Category_RiskCategory_RiskName],
		[Strategy_TradeStrategy_ActiveBenchmarkID],
		[Strategy_TradeStrategy_CountryID_mkt],
		[Strategy_TradeStrategy_Description],
		[Strategy_TradeStrategy_EndDate],
		[Strategy_TradeStrategy_IndustryID],
		[Strategy_TradeStrategy_IsClosed],
		[Strategy_TradeStrategy_Leverage],
		[Strategy_TradeStrategy_Name],
		[Strategy_TradeStrategy_PortfolioID],
		[Strategy_TradeStrategy_ShortCode],
		NULL,
		@TimeStamp,
		[UniqKey],
		[UserName]
	)


WHEN MATCHED AND
(
	([ts_end] = NULL OR ([ts_end] IS NULL AND NULL IS NULL))
)
AND
(
	([target].[Strategy_Risk_Category_RiskCategory_RiskCategoryID] <> [source].[Strategy_Risk_Category_RiskCategory_RiskCategoryID] OR ([target].[Strategy_Risk_Category_RiskCategory_RiskCategoryID] IS NULL AND [source].[Strategy_Risk_Category_RiskCategory_RiskCategoryID] IS NOT NULL) OR ([target].[Strategy_Risk_Category_RiskCategory_RiskCategoryID] IS NOT NULL AND [source].[Strategy_Risk_Category_RiskCategory_RiskCategoryID] IS NULL)) OR
	([target].[Strategy_Risk_Category_RiskCategory_RiskName] <> [source].[Strategy_Risk_Category_RiskCategory_RiskName] OR ([target].[Strategy_Risk_Category_RiskCategory_RiskName] IS NULL AND [source].[Strategy_Risk_Category_RiskCategory_RiskName] IS NOT NULL) OR ([target].[Strategy_Risk_Category_RiskCategory_RiskName] IS NOT NULL AND [source].[Strategy_Risk_Category_RiskCategory_RiskName] IS NULL)) OR
	([target].[Strategy_TradeStrategy_ActiveBenchmarkID] <> [source].[Strategy_TradeStrategy_ActiveBenchmarkID] OR ([target].[Strategy_TradeStrategy_ActiveBenchmarkID] IS NULL AND [source].[Strategy_TradeStrategy_ActiveBenchmarkID] IS NOT NULL) OR ([target].[Strategy_TradeStrategy_ActiveBenchmarkID] IS NOT NULL AND [source].[Strategy_TradeStrategy_ActiveBenchmarkID] IS NULL)) OR
	([target].[Strategy_TradeStrategy_CountryID_mkt] <> [source].[Strategy_TradeStrategy_CountryID_mkt] OR ([target].[Strategy_TradeStrategy_CountryID_mkt] IS NULL AND [source].[Strategy_TradeStrategy_CountryID_mkt] IS NOT NULL) OR ([target].[Strategy_TradeStrategy_CountryID_mkt] IS NOT NULL AND [source].[Strategy_TradeStrategy_CountryID_mkt] IS NULL)) OR
	([target].[Strategy_TradeStrategy_Description] <> [source].[Strategy_TradeStrategy_Description] OR ([target].[Strategy_TradeStrategy_Description] IS NULL AND [source].[Strategy_TradeStrategy_Description] IS NOT NULL) OR ([target].[Strategy_TradeStrategy_Description] IS NOT NULL AND [source].[Strategy_TradeStrategy_Description] IS NULL)) OR
	([target].[Strategy_TradeStrategy_EndDate] <> [source].[Strategy_TradeStrategy_EndDate] OR ([target].[Strategy_TradeStrategy_EndDate] IS NULL AND [source].[Strategy_TradeStrategy_EndDate] IS NOT NULL) OR ([target].[Strategy_TradeStrategy_EndDate] IS NOT NULL AND [source].[Strategy_TradeStrategy_EndDate] IS NULL)) OR
	([target].[Strategy_TradeStrategy_IndustryID] <> [source].[Strategy_TradeStrategy_IndustryID] OR ([target].[Strategy_TradeStrategy_IndustryID] IS NULL AND [source].[Strategy_TradeStrategy_IndustryID] IS NOT NULL) OR ([target].[Strategy_TradeStrategy_IndustryID] IS NOT NULL AND [source].[Strategy_TradeStrategy_IndustryID] IS NULL)) OR
	([target].[Strategy_TradeStrategy_IsClosed] <> [source].[Strategy_TradeStrategy_IsClosed] OR ([target].[Strategy_TradeStrategy_IsClosed] IS NULL AND [source].[Strategy_TradeStrategy_IsClosed] IS NOT NULL) OR ([target].[Strategy_TradeStrategy_IsClosed] IS NOT NULL AND [source].[Strategy_TradeStrategy_IsClosed] IS NULL)) OR
	([target].[Strategy_TradeStrategy_Leverage] <> [source].[Strategy_TradeStrategy_Leverage] OR ([target].[Strategy_TradeStrategy_Leverage] IS NULL AND [source].[Strategy_TradeStrategy_Leverage] IS NOT NULL) OR ([target].[Strategy_TradeStrategy_Leverage] IS NOT NULL AND [source].[Strategy_TradeStrategy_Leverage] IS NULL)) OR
	([target].[Strategy_TradeStrategy_Name] <> [source].[Strategy_TradeStrategy_Name] OR ([target].[Strategy_TradeStrategy_Name] IS NULL AND [source].[Strategy_TradeStrategy_Name] IS NOT NULL) OR ([target].[Strategy_TradeStrategy_Name] IS NOT NULL AND [source].[Strategy_TradeStrategy_Name] IS NULL)) OR
	([target].[Strategy_TradeStrategy_PortfolioID] <> [source].[Strategy_TradeStrategy_PortfolioID] OR ([target].[Strategy_TradeStrategy_PortfolioID] IS NULL AND [source].[Strategy_TradeStrategy_PortfolioID] IS NOT NULL) OR ([target].[Strategy_TradeStrategy_PortfolioID] IS NOT NULL AND [source].[Strategy_TradeStrategy_PortfolioID] IS NULL)) OR
	([target].[Strategy_TradeStrategy_ShortCode] <> [source].[Strategy_TradeStrategy_ShortCode] OR ([target].[Strategy_TradeStrategy_ShortCode] IS NULL AND [source].[Strategy_TradeStrategy_ShortCode] IS NOT NULL) OR ([target].[Strategy_TradeStrategy_ShortCode] IS NOT NULL AND [source].[Strategy_TradeStrategy_ShortCode] IS NULL))

)
	THEN UPDATE
	SET
		[ts_end] = @TimeStamp


	OUTPUT
		$Action as [MERGE_ACTION_039fce51-76a0-409e-9971-0dd646ef3a58],
		[source].[Strategy_Risk_Category_RiskCategory_RiskCategoryID] AS [Strategy_Risk_Category_RiskCategory_RiskCategoryID],
		[source].[Strategy_Risk_Category_RiskCategory_RiskName] AS [Strategy_Risk_Category_RiskCategory_RiskName],
		[source].[Strategy_TradeStrategy_ActiveBenchmarkID] AS [Strategy_TradeStrategy_ActiveBenchmarkID],
		[source].[Strategy_TradeStrategy_CountryID_mkt] AS [Strategy_TradeStrategy_CountryID_mkt],
		[source].[Strategy_TradeStrategy_Description] AS [Strategy_TradeStrategy_Description],
		[source].[Strategy_TradeStrategy_EndDate] AS [Strategy_TradeStrategy_EndDate],
		[source].[Strategy_TradeStrategy_IndustryID] AS [Strategy_TradeStrategy_IndustryID],
		[source].[Strategy_TradeStrategy_IsClosed] AS [Strategy_TradeStrategy_IsClosed],
		[source].[Strategy_TradeStrategy_Leverage] AS [Strategy_TradeStrategy_Leverage],
		[source].[Strategy_TradeStrategy_Name] AS [Strategy_TradeStrategy_Name],
		[source].[Strategy_TradeStrategy_PortfolioID] AS [Strategy_TradeStrategy_PortfolioID],
		[source].[Strategy_TradeStrategy_ShortCode] AS [Strategy_TradeStrategy_ShortCode],
		NULL AS [ts_end],
		@TimeStamp AS [ts_start],
		[source].[UniqKey] AS [UniqKey],
		[source].[UserName] AS [UserName]

)MERGE_OUTPUT
WHERE MERGE_OUTPUT.[MERGE_ACTION_039fce51-76a0-409e-9971-0dd646ef3a58] = 'UPDATE' 
	AND MERGE_OUTPUT.[UniqKey] IS NOT NULL
	AND MERGE_OUTPUT.[UserName] IS NOT NULL
;
COMMIT TRANSACTION merge_BroadridgePositions_Strtgy
END
GO
