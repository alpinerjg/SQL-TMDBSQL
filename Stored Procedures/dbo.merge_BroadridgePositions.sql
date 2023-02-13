SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[merge_BroadridgePositions] 
     @Timestamp DateTime = NULL

	 AS
BEGIN

if (@Timestamp IS NULL)
	SET @Timestamp = GETDATE()

BEGIN TRANSACTION merge_BroadridgePositions

-- ETL
UPDATE [TMDBSQL].[dbo].[BroadridgePositions_staging]
SET CustomStrategyCode = CONCAT(' ' , CustomStrategyCode)
WHERE CustomStrategyCode like '[0-9][0-9][0-9]'

IF EXISTS(SELECT UniqKey FROM [TMDBSQL].[dbo].[BroadridgePositions_staging])
	UPDATE t1 
	SET t1.ts_end = @Timestamp
	FROM [TMDBSQL].[dbo].[BroadridgePositions] t1
	LEFT JOIN [TMDBSQL].[dbo].[BroadridgePositions_staging] t2 ON t2.UserName = t1.UserName AND t2.[UniqKey] = t1.[UniqKey] 
	WHERE t1.ts_end IS NULL and t2.[UniqKey] IS NULL

-- ==================================================
-- Slowly Changing Dimension script by SCD Merge Wizard
-- Author: Miljan Radovic
-- Official web site: https://github.com/SQLPlayer/SCD-Merge-Wizard/
-- Version: 4.3.0.0
-- Publish date: 4/8/2021 9:05:16 AM
-- Script creation date: 4/8/2021 4:08:05 PM
-- ==================================================

-- ==================================================
-- SCD1
-- ==================================================
MERGE [dbo].[BroadridgePositions] WITH (HOLDLOCK) as [target]
USING
(
	SELECT
		[Custodian_TradeCpty_TradeCptyName],
		[CustomAccount],
		[CustomBloombergID],
		[CustomFundName],
		[CustomFundSort],
		[CustomPartnershipID],
		[CustomRiskCategoryCode],
		[CustomStrategyCode],
		[CustomTicker],
		[CustomTickerSort],
		[Fund_Currency_Currency_CurrencyID],
		[Fund_TradeFund_Name],
		[Position_Calculated_AverageCost],
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
		[Position_Calculated_PositionCash],
		[Position_Calculated_PositionValue],
		[Position_PositionID],
		[Position_PositionTypeString],
		[Security_Currency_Currency_Ccy],
		[Security_Currency_Currency_CurrencyID],
		[Security_Security_BloombergGlobalId],
		[Security_Security_BloombergID],
		[Security_Security_Code],
		[Security_Security_ConversionRatio],
		[Security_Security_MD_RealTimePrice],
		[Security_Security_Name],
		[Security_Security_SecurityID],
		[Security_Security_Ticker],
		[Security_Type_SecurityType_Name],
		[Security_Underlying_Security_Code],
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
		[Total_Position_Calculated_PositionCash],
		[UniqKey],
		[UserName]
	FROM [dbo].[BroadridgePositions_staging]
) as [source]
ON
(
	[source].[UniqKey] = [target].[UniqKey] AND
	[source].[UserName] = [target].[UserName]
)

WHEN MATCHED AND
(
	[target].[ts_end] = NULL
)
AND
(
	([source].[Position_Calculated_BaseLongMarketValue] <> [target].[Position_Calculated_BaseLongMarketValue] OR ([source].[Position_Calculated_BaseLongMarketValue] IS NULL AND [target].[Position_Calculated_BaseLongMarketValue] IS NOT NULL) OR ([source].[Position_Calculated_BaseLongMarketValue] IS NOT NULL AND [target].[Position_Calculated_BaseLongMarketValue] IS NULL)) OR
	([source].[Position_Calculated_BaseLongMarketValueGain] <> [target].[Position_Calculated_BaseLongMarketValueGain] OR ([source].[Position_Calculated_BaseLongMarketValueGain] IS NULL AND [target].[Position_Calculated_BaseLongMarketValueGain] IS NOT NULL) OR ([source].[Position_Calculated_BaseLongMarketValueGain] IS NOT NULL AND [target].[Position_Calculated_BaseLongMarketValueGain] IS NULL)) OR
	([source].[Position_Calculated_BaseMarketValue] <> [target].[Position_Calculated_BaseMarketValue] OR ([source].[Position_Calculated_BaseMarketValue] IS NULL AND [target].[Position_Calculated_BaseMarketValue] IS NOT NULL) OR ([source].[Position_Calculated_BaseMarketValue] IS NOT NULL AND [target].[Position_Calculated_BaseMarketValue] IS NULL)) OR
	([source].[Position_Calculated_BaseMarketValueDayGain] <> [target].[Position_Calculated_BaseMarketValueDayGain] OR ([source].[Position_Calculated_BaseMarketValueDayGain] IS NULL AND [target].[Position_Calculated_BaseMarketValueDayGain] IS NOT NULL) OR ([source].[Position_Calculated_BaseMarketValueDayGain] IS NOT NULL AND [target].[Position_Calculated_BaseMarketValueDayGain] IS NULL)) OR
	([source].[Position_Calculated_BasePNL_DTD] <> [target].[Position_Calculated_BasePNL_DTD] OR ([source].[Position_Calculated_BasePNL_DTD] IS NULL AND [target].[Position_Calculated_BasePNL_DTD] IS NOT NULL) OR ([source].[Position_Calculated_BasePNL_DTD] IS NOT NULL AND [target].[Position_Calculated_BasePNL_DTD] IS NULL)) OR
	([source].[Position_Calculated_BasePNL_MTD] <> [target].[Position_Calculated_BasePNL_MTD] OR ([source].[Position_Calculated_BasePNL_MTD] IS NULL AND [target].[Position_Calculated_BasePNL_MTD] IS NOT NULL) OR ([source].[Position_Calculated_BasePNL_MTD] IS NOT NULL AND [target].[Position_Calculated_BasePNL_MTD] IS NULL)) OR
	([source].[Position_Calculated_BasePNL_YTD] <> [target].[Position_Calculated_BasePNL_YTD] OR ([source].[Position_Calculated_BasePNL_YTD] IS NULL AND [target].[Position_Calculated_BasePNL_YTD] IS NOT NULL) OR ([source].[Position_Calculated_BasePNL_YTD] IS NOT NULL AND [target].[Position_Calculated_BasePNL_YTD] IS NULL)) OR
	([source].[Position_Calculated_BaseShortMarketValue] <> [target].[Position_Calculated_BaseShortMarketValue] OR ([source].[Position_Calculated_BaseShortMarketValue] IS NULL AND [target].[Position_Calculated_BaseShortMarketValue] IS NOT NULL) OR ([source].[Position_Calculated_BaseShortMarketValue] IS NOT NULL AND [target].[Position_Calculated_BaseShortMarketValue] IS NULL)) OR
	([source].[Position_Calculated_BaseShortMarketValueGain] <> [target].[Position_Calculated_BaseShortMarketValueGain] OR ([source].[Position_Calculated_BaseShortMarketValueGain] IS NULL AND [target].[Position_Calculated_BaseShortMarketValueGain] IS NOT NULL) OR ([source].[Position_Calculated_BaseShortMarketValueGain] IS NOT NULL AND [target].[Position_Calculated_BaseShortMarketValueGain] IS NULL)) OR
	([source].[Position_Calculated_LocalMarketValue] <> [target].[Position_Calculated_LocalMarketValue] OR ([source].[Position_Calculated_LocalMarketValue] IS NULL AND [target].[Position_Calculated_LocalMarketValue] IS NOT NULL) OR ([source].[Position_Calculated_LocalMarketValue] IS NOT NULL AND [target].[Position_Calculated_LocalMarketValue] IS NULL)) OR
	([source].[Position_Calculated_MarketPrice] <> [target].[Position_Calculated_MarketPrice] OR ([source].[Position_Calculated_MarketPrice] IS NULL AND [target].[Position_Calculated_MarketPrice] IS NOT NULL) OR ([source].[Position_Calculated_MarketPrice] IS NOT NULL AND [target].[Position_Calculated_MarketPrice] IS NULL)) OR
	([source].[Security_Security_MD_RealTimePrice] <> [target].[Security_Security_MD_RealTimePrice] OR ([source].[Security_Security_MD_RealTimePrice] IS NULL AND [target].[Security_Security_MD_RealTimePrice] IS NOT NULL) OR ([source].[Security_Security_MD_RealTimePrice] IS NOT NULL AND [target].[Security_Security_MD_RealTimePrice] IS NULL))
)
AND
(
	([source].[Custodian_TradeCpty_TradeCptyName] = [target].[Custodian_TradeCpty_TradeCptyName] OR ([source].[Custodian_TradeCpty_TradeCptyName] IS NULL AND [target].[Custodian_TradeCpty_TradeCptyName] IS NULL)) AND
	([source].[CustomAccount] = [target].[CustomAccount] OR ([source].[CustomAccount] IS NULL AND [target].[CustomAccount] IS NULL)) AND
	([source].[CustomBloombergID] = [target].[CustomBloombergID] OR ([source].[CustomBloombergID] IS NULL AND [target].[CustomBloombergID] IS NULL)) AND
	([source].[CustomFundName] = [target].[CustomFundName] OR ([source].[CustomFundName] IS NULL AND [target].[CustomFundName] IS NULL)) AND
	([source].[CustomFundSort] = [target].[CustomFundSort] OR ([source].[CustomFundSort] IS NULL AND [target].[CustomFundSort] IS NULL)) AND
	([source].[CustomPartnershipID] = [target].[CustomPartnershipID] OR ([source].[CustomPartnershipID] IS NULL AND [target].[CustomPartnershipID] IS NULL)) AND
	([source].[CustomRiskCategoryCode] = [target].[CustomRiskCategoryCode] OR ([source].[CustomRiskCategoryCode] IS NULL AND [target].[CustomRiskCategoryCode] IS NULL)) AND
	([source].[CustomStrategyCode] = [target].[CustomStrategyCode] OR ([source].[CustomStrategyCode] IS NULL AND [target].[CustomStrategyCode] IS NULL)) AND
	([source].[CustomTicker] = [target].[CustomTicker] OR ([source].[CustomTicker] IS NULL AND [target].[CustomTicker] IS NULL)) AND
	([source].[CustomTickerSort] = [target].[CustomTickerSort] OR ([source].[CustomTickerSort] IS NULL AND [target].[CustomTickerSort] IS NULL)) AND
	([source].[Fund_Currency_Currency_CurrencyID] = [target].[Fund_Currency_Currency_CurrencyID] OR ([source].[Fund_Currency_Currency_CurrencyID] IS NULL AND [target].[Fund_Currency_Currency_CurrencyID] IS NULL)) AND
	([source].[Fund_TradeFund_Name] = [target].[Fund_TradeFund_Name] OR ([source].[Fund_TradeFund_Name] IS NULL AND [target].[Fund_TradeFund_Name] IS NULL)) AND
	([source].[Position_Calculated_AverageCost] = [target].[Position_Calculated_AverageCost] OR ([source].[Position_Calculated_AverageCost] IS NULL AND [target].[Position_Calculated_AverageCost] IS NULL)) AND
	([source].[Position_Calculated_PositionCash] = [target].[Position_Calculated_PositionCash] OR ([source].[Position_Calculated_PositionCash] IS NULL AND [target].[Position_Calculated_PositionCash] IS NULL)) AND
	([source].[Position_Calculated_PositionValue] = [target].[Position_Calculated_PositionValue] OR ([source].[Position_Calculated_PositionValue] IS NULL AND [target].[Position_Calculated_PositionValue] IS NULL)) AND
	([source].[Position_PositionID] = [target].[Position_PositionID] OR ([source].[Position_PositionID] IS NULL AND [target].[Position_PositionID] IS NULL)) AND
	([source].[Position_PositionTypeString] = [target].[Position_PositionTypeString] OR ([source].[Position_PositionTypeString] IS NULL AND [target].[Position_PositionTypeString] IS NULL)) AND
	([source].[Security_Currency_Currency_Ccy] = [target].[Security_Currency_Currency_Ccy] OR ([source].[Security_Currency_Currency_Ccy] IS NULL AND [target].[Security_Currency_Currency_Ccy] IS NULL)) AND
	([source].[Security_Currency_Currency_CurrencyID] = [target].[Security_Currency_Currency_CurrencyID] OR ([source].[Security_Currency_Currency_CurrencyID] IS NULL AND [target].[Security_Currency_Currency_CurrencyID] IS NULL)) AND
	([source].[Security_Security_BloombergGlobalId] = [target].[Security_Security_BloombergGlobalId] OR ([source].[Security_Security_BloombergGlobalId] IS NULL AND [target].[Security_Security_BloombergGlobalId] IS NULL)) AND
	([source].[Security_Security_BloombergID] = [target].[Security_Security_BloombergID] OR ([source].[Security_Security_BloombergID] IS NULL AND [target].[Security_Security_BloombergID] IS NULL)) AND
	([source].[Security_Security_Code] = [target].[Security_Security_Code] OR ([source].[Security_Security_Code] IS NULL AND [target].[Security_Security_Code] IS NULL)) AND
	([source].[Security_Security_ConversionRatio] = [target].[Security_Security_ConversionRatio] OR ([source].[Security_Security_ConversionRatio] IS NULL AND [target].[Security_Security_ConversionRatio] IS NULL)) AND
	([source].[Security_Security_Name] = [target].[Security_Security_Name] OR ([source].[Security_Security_Name] IS NULL AND [target].[Security_Security_Name] IS NULL)) AND
	([source].[Security_Security_SecurityID] = [target].[Security_Security_SecurityID] OR ([source].[Security_Security_SecurityID] IS NULL AND [target].[Security_Security_SecurityID] IS NULL)) AND
	([source].[Security_Security_Ticker] = [target].[Security_Security_Ticker] OR ([source].[Security_Security_Ticker] IS NULL AND [target].[Security_Security_Ticker] IS NULL)) AND
	([source].[Security_Type_SecurityType_Name] = [target].[Security_Type_SecurityType_Name] OR ([source].[Security_Type_SecurityType_Name] IS NULL AND [target].[Security_Type_SecurityType_Name] IS NULL)) AND
	([source].[Security_Underlying_Security_Code] = [target].[Security_Underlying_Security_Code] OR ([source].[Security_Underlying_Security_Code] IS NULL AND [target].[Security_Underlying_Security_Code] IS NULL)) AND
	([source].[Strategy_Risk_Category_RiskCategory_RiskCategoryID] = [target].[Strategy_Risk_Category_RiskCategory_RiskCategoryID] OR ([source].[Strategy_Risk_Category_RiskCategory_RiskCategoryID] IS NULL AND [target].[Strategy_Risk_Category_RiskCategory_RiskCategoryID] IS NULL)) AND
	([source].[Strategy_Risk_Category_RiskCategory_RiskName] = [target].[Strategy_Risk_Category_RiskCategory_RiskName] OR ([source].[Strategy_Risk_Category_RiskCategory_RiskName] IS NULL AND [target].[Strategy_Risk_Category_RiskCategory_RiskName] IS NULL)) AND
	([source].[Strategy_TradeStrategy_ActiveBenchmarkID] = [target].[Strategy_TradeStrategy_ActiveBenchmarkID] OR ([source].[Strategy_TradeStrategy_ActiveBenchmarkID] IS NULL AND [target].[Strategy_TradeStrategy_ActiveBenchmarkID] IS NULL)) AND
	([source].[Strategy_TradeStrategy_CountryID_mkt] = [target].[Strategy_TradeStrategy_CountryID_mkt] OR ([source].[Strategy_TradeStrategy_CountryID_mkt] IS NULL AND [target].[Strategy_TradeStrategy_CountryID_mkt] IS NULL)) AND
	([source].[Strategy_TradeStrategy_Description] = [target].[Strategy_TradeStrategy_Description] OR ([source].[Strategy_TradeStrategy_Description] IS NULL AND [target].[Strategy_TradeStrategy_Description] IS NULL)) AND
	([source].[Strategy_TradeStrategy_EndDate] = [target].[Strategy_TradeStrategy_EndDate] OR ([source].[Strategy_TradeStrategy_EndDate] IS NULL AND [target].[Strategy_TradeStrategy_EndDate] IS NULL)) AND
	([source].[Strategy_TradeStrategy_IndustryID] = [target].[Strategy_TradeStrategy_IndustryID] OR ([source].[Strategy_TradeStrategy_IndustryID] IS NULL AND [target].[Strategy_TradeStrategy_IndustryID] IS NULL)) AND
	([source].[Strategy_TradeStrategy_IsClosed] = [target].[Strategy_TradeStrategy_IsClosed] OR ([source].[Strategy_TradeStrategy_IsClosed] IS NULL AND [target].[Strategy_TradeStrategy_IsClosed] IS NULL)) AND
	([source].[Strategy_TradeStrategy_Leverage] = [target].[Strategy_TradeStrategy_Leverage] OR ([source].[Strategy_TradeStrategy_Leverage] IS NULL AND [target].[Strategy_TradeStrategy_Leverage] IS NULL)) AND
	([source].[Strategy_TradeStrategy_Name] = [target].[Strategy_TradeStrategy_Name] OR ([source].[Strategy_TradeStrategy_Name] IS NULL AND [target].[Strategy_TradeStrategy_Name] IS NULL)) AND
	([source].[Strategy_TradeStrategy_PortfolioID] = [target].[Strategy_TradeStrategy_PortfolioID] OR ([source].[Strategy_TradeStrategy_PortfolioID] IS NULL AND [target].[Strategy_TradeStrategy_PortfolioID] IS NULL)) AND
	([source].[Strategy_TradeStrategy_ShortCode] = [target].[Strategy_TradeStrategy_ShortCode] OR ([source].[Strategy_TradeStrategy_ShortCode] IS NULL AND [target].[Strategy_TradeStrategy_ShortCode] IS NULL)) AND
	([source].[Total_Position_Calculated_PositionCash] = [target].[Total_Position_Calculated_PositionCash] OR ([source].[Total_Position_Calculated_PositionCash] IS NULL AND [target].[Total_Position_Calculated_PositionCash] IS NULL))
)
THEN UPDATE
SET
	[target].[Position_Calculated_BaseLongMarketValue] = [source].[Position_Calculated_BaseLongMarketValue] ,
	[target].[Position_Calculated_BaseLongMarketValueGain] = [source].[Position_Calculated_BaseLongMarketValueGain] ,
	[target].[Position_Calculated_BaseMarketValue] = [source].[Position_Calculated_BaseMarketValue] ,
	[target].[Position_Calculated_BaseMarketValueDayGain] = [source].[Position_Calculated_BaseMarketValueDayGain] ,
	[target].[Position_Calculated_BasePNL_DTD] = [source].[Position_Calculated_BasePNL_DTD] ,
	[target].[Position_Calculated_BasePNL_MTD] = [source].[Position_Calculated_BasePNL_MTD] ,
	[target].[Position_Calculated_BasePNL_YTD] = [source].[Position_Calculated_BasePNL_YTD] ,
	[target].[Position_Calculated_BaseShortMarketValue] = [source].[Position_Calculated_BaseShortMarketValue] ,
	[target].[Position_Calculated_BaseShortMarketValueGain] = [source].[Position_Calculated_BaseShortMarketValueGain] ,
	[target].[Position_Calculated_LocalMarketValue] = [source].[Position_Calculated_LocalMarketValue] ,
	[target].[Position_Calculated_MarketPrice] = [source].[Position_Calculated_MarketPrice] ,
	[target].[Security_Security_MD_RealTimePrice] = [source].[Security_Security_MD_RealTimePrice]
;


-- ==================================================
-- SCD2
-- ==================================================
INSERT INTO [dbo].[BroadridgePositions]
(
	[Custodian_TradeCpty_TradeCptyName],
	[CustomAccount],
	[CustomBloombergID],
	[CustomFundName],
	[CustomFundSort],
	[CustomPartnershipID],
	[CustomRiskCategoryCode],
	[CustomStrategyCode],
	[CustomTicker],
	[CustomTickerSort],
	[Fund_Currency_Currency_CurrencyID],
	[Fund_TradeFund_Name],
	[Position_Calculated_AverageCost],
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
	[Position_Calculated_PositionCash],
	[Position_Calculated_PositionValue],
	[Position_PositionID],
	[Position_PositionTypeString],
	[Security_Currency_Currency_Ccy],
	[Security_Currency_Currency_CurrencyID],
	[Security_Security_BloombergGlobalId],
	[Security_Security_BloombergID],
	[Security_Security_Code],
	[Security_Security_ConversionRatio],
	[Security_Security_MD_RealTimePrice],
	[Security_Security_Name],
	[Security_Security_SecurityID],
	[Security_Security_Ticker],
	[Security_Type_SecurityType_Name],
	[Security_Underlying_Security_Code],
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
	[Total_Position_Calculated_PositionCash],
	[ts_end],
	[ts_start],
	[UniqKey],
	[UserName]
)
SELECT
	[Custodian_TradeCpty_TradeCptyName],
	[CustomAccount],
	[CustomBloombergID],
	[CustomFundName],
	[CustomFundSort],
	[CustomPartnershipID],
	[CustomRiskCategoryCode],
	[CustomStrategyCode],
	[CustomTicker],
	[CustomTickerSort],
	[Fund_Currency_Currency_CurrencyID],
	[Fund_TradeFund_Name],
	[Position_Calculated_AverageCost],
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
	[Position_Calculated_PositionCash],
	[Position_Calculated_PositionValue],
	[Position_PositionID],
	[Position_PositionTypeString],
	[Security_Currency_Currency_Ccy],
	[Security_Currency_Currency_CurrencyID],
	[Security_Security_BloombergGlobalId],
	[Security_Security_BloombergID],
	[Security_Security_Code],
	[Security_Security_ConversionRatio],
	[Security_Security_MD_RealTimePrice],
	[Security_Security_Name],
	[Security_Security_SecurityID],
	[Security_Security_Ticker],
	[Security_Type_SecurityType_Name],
	[Security_Underlying_Security_Code],
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
	[Total_Position_Calculated_PositionCash],
	[ts_end],
	[ts_start],
	[UniqKey],
	[UserName]
FROM
(
	MERGE [dbo].[BroadridgePositions] WITH (HOLDLOCK) as [target]
	USING
	(
		SELECT
			[Custodian_TradeCpty_TradeCptyName],
			[CustomAccount],
			[CustomBloombergID],
			[CustomFundName],
			[CustomFundSort],
			[CustomPartnershipID],
			[CustomRiskCategoryCode],
			[CustomStrategyCode],
			[CustomTicker],
			[CustomTickerSort],
			[Fund_Currency_Currency_CurrencyID],
			[Fund_TradeFund_Name],
			[Position_Calculated_AverageCost],
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
			[Position_Calculated_PositionCash],
			[Position_Calculated_PositionValue],
			[Position_PositionID],
			[Position_PositionTypeString],
			[Security_Currency_Currency_Ccy],
			[Security_Currency_Currency_CurrencyID],
			[Security_Security_BloombergGlobalId],
			[Security_Security_BloombergID],
			[Security_Security_Code],
			[Security_Security_ConversionRatio],
			[Security_Security_MD_RealTimePrice],
			[Security_Security_Name],
			[Security_Security_SecurityID],
			[Security_Security_Ticker],
			[Security_Type_SecurityType_Name],
			[Security_Underlying_Security_Code],
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
			[Total_Position_Calculated_PositionCash],
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
		[Custodian_TradeCpty_TradeCptyName],
		[CustomAccount],
		[CustomBloombergID],
		[CustomFundName],
		[CustomFundSort],
		[CustomPartnershipID],
		[CustomRiskCategoryCode],
		[CustomStrategyCode],
		[CustomTicker],
		[CustomTickerSort],
		[Fund_Currency_Currency_CurrencyID],
		[Fund_TradeFund_Name],
		[Position_Calculated_AverageCost],
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
		[Position_Calculated_PositionCash],
		[Position_Calculated_PositionValue],
		[Position_PositionID],
		[Position_PositionTypeString],
		[Security_Currency_Currency_Ccy],
		[Security_Currency_Currency_CurrencyID],
		[Security_Security_BloombergGlobalId],
		[Security_Security_BloombergID],
		[Security_Security_Code],
		[Security_Security_ConversionRatio],
		[Security_Security_MD_RealTimePrice],
		[Security_Security_Name],
		[Security_Security_SecurityID],
		[Security_Security_Ticker],
		[Security_Type_SecurityType_Name],
		[Security_Underlying_Security_Code],
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
		[Total_Position_Calculated_PositionCash],
		[ts_end],
		[ts_start],
		[UniqKey],
		[UserName]
	)
	VALUES
	(
		[Custodian_TradeCpty_TradeCptyName],
		[CustomAccount],
		[CustomBloombergID],
		[CustomFundName],
		[CustomFundSort],
		[CustomPartnershipID],
		[CustomRiskCategoryCode],
		[CustomStrategyCode],
		[CustomTicker],
		[CustomTickerSort],
		[Fund_Currency_Currency_CurrencyID],
		[Fund_TradeFund_Name],
		[Position_Calculated_AverageCost],
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
		[Position_Calculated_PositionCash],
		[Position_Calculated_PositionValue],
		[Position_PositionID],
		[Position_PositionTypeString],
		[Security_Currency_Currency_Ccy],
		[Security_Currency_Currency_CurrencyID],
		[Security_Security_BloombergGlobalId],
		[Security_Security_BloombergID],
		[Security_Security_Code],
		[Security_Security_ConversionRatio],
		[Security_Security_MD_RealTimePrice],
		[Security_Security_Name],
		[Security_Security_SecurityID],
		[Security_Security_Ticker],
		[Security_Type_SecurityType_Name],
		[Security_Underlying_Security_Code],
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
		[Total_Position_Calculated_PositionCash],
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
	([target].[Custodian_TradeCpty_TradeCptyName] <> [source].[Custodian_TradeCpty_TradeCptyName] OR ([target].[Custodian_TradeCpty_TradeCptyName] IS NULL AND [source].[Custodian_TradeCpty_TradeCptyName] IS NOT NULL) OR ([target].[Custodian_TradeCpty_TradeCptyName] IS NOT NULL AND [source].[Custodian_TradeCpty_TradeCptyName] IS NULL)) OR
	([target].[CustomAccount] <> [source].[CustomAccount] OR ([target].[CustomAccount] IS NULL AND [source].[CustomAccount] IS NOT NULL) OR ([target].[CustomAccount] IS NOT NULL AND [source].[CustomAccount] IS NULL)) OR
	([target].[CustomBloombergID] <> [source].[CustomBloombergID] OR ([target].[CustomBloombergID] IS NULL AND [source].[CustomBloombergID] IS NOT NULL) OR ([target].[CustomBloombergID] IS NOT NULL AND [source].[CustomBloombergID] IS NULL)) OR
	([target].[CustomFundName] <> [source].[CustomFundName] OR ([target].[CustomFundName] IS NULL AND [source].[CustomFundName] IS NOT NULL) OR ([target].[CustomFundName] IS NOT NULL AND [source].[CustomFundName] IS NULL)) OR
	([target].[CustomFundSort] <> [source].[CustomFundSort] OR ([target].[CustomFundSort] IS NULL AND [source].[CustomFundSort] IS NOT NULL) OR ([target].[CustomFundSort] IS NOT NULL AND [source].[CustomFundSort] IS NULL)) OR
	([target].[CustomPartnershipID] <> [source].[CustomPartnershipID] OR ([target].[CustomPartnershipID] IS NULL AND [source].[CustomPartnershipID] IS NOT NULL) OR ([target].[CustomPartnershipID] IS NOT NULL AND [source].[CustomPartnershipID] IS NULL)) OR
	([target].[CustomRiskCategoryCode] <> [source].[CustomRiskCategoryCode] OR ([target].[CustomRiskCategoryCode] IS NULL AND [source].[CustomRiskCategoryCode] IS NOT NULL) OR ([target].[CustomRiskCategoryCode] IS NOT NULL AND [source].[CustomRiskCategoryCode] IS NULL)) OR
	([target].[CustomStrategyCode] <> [source].[CustomStrategyCode] OR ([target].[CustomStrategyCode] IS NULL AND [source].[CustomStrategyCode] IS NOT NULL) OR ([target].[CustomStrategyCode] IS NOT NULL AND [source].[CustomStrategyCode] IS NULL)) OR
	([target].[CustomTicker] <> [source].[CustomTicker] OR ([target].[CustomTicker] IS NULL AND [source].[CustomTicker] IS NOT NULL) OR ([target].[CustomTicker] IS NOT NULL AND [source].[CustomTicker] IS NULL)) OR
	([target].[CustomTickerSort] <> [source].[CustomTickerSort] OR ([target].[CustomTickerSort] IS NULL AND [source].[CustomTickerSort] IS NOT NULL) OR ([target].[CustomTickerSort] IS NOT NULL AND [source].[CustomTickerSort] IS NULL)) OR
	([target].[Fund_Currency_Currency_CurrencyID] <> [source].[Fund_Currency_Currency_CurrencyID] OR ([target].[Fund_Currency_Currency_CurrencyID] IS NULL AND [source].[Fund_Currency_Currency_CurrencyID] IS NOT NULL) OR ([target].[Fund_Currency_Currency_CurrencyID] IS NOT NULL AND [source].[Fund_Currency_Currency_CurrencyID] IS NULL)) OR
	([target].[Fund_TradeFund_Name] <> [source].[Fund_TradeFund_Name] OR ([target].[Fund_TradeFund_Name] IS NULL AND [source].[Fund_TradeFund_Name] IS NOT NULL) OR ([target].[Fund_TradeFund_Name] IS NOT NULL AND [source].[Fund_TradeFund_Name] IS NULL)) OR
	([target].[Position_Calculated_AverageCost] <> [source].[Position_Calculated_AverageCost] OR ([target].[Position_Calculated_AverageCost] IS NULL AND [source].[Position_Calculated_AverageCost] IS NOT NULL) OR ([target].[Position_Calculated_AverageCost] IS NOT NULL AND [source].[Position_Calculated_AverageCost] IS NULL)) OR
	([target].[Position_Calculated_PositionCash] <> [source].[Position_Calculated_PositionCash] OR ([target].[Position_Calculated_PositionCash] IS NULL AND [source].[Position_Calculated_PositionCash] IS NOT NULL) OR ([target].[Position_Calculated_PositionCash] IS NOT NULL AND [source].[Position_Calculated_PositionCash] IS NULL)) OR
	([target].[Position_Calculated_PositionValue] <> [source].[Position_Calculated_PositionValue] OR ([target].[Position_Calculated_PositionValue] IS NULL AND [source].[Position_Calculated_PositionValue] IS NOT NULL) OR ([target].[Position_Calculated_PositionValue] IS NOT NULL AND [source].[Position_Calculated_PositionValue] IS NULL)) OR
	([target].[Position_PositionID] <> [source].[Position_PositionID] OR ([target].[Position_PositionID] IS NULL AND [source].[Position_PositionID] IS NOT NULL) OR ([target].[Position_PositionID] IS NOT NULL AND [source].[Position_PositionID] IS NULL)) OR
	([target].[Position_PositionTypeString] <> [source].[Position_PositionTypeString] OR ([target].[Position_PositionTypeString] IS NULL AND [source].[Position_PositionTypeString] IS NOT NULL) OR ([target].[Position_PositionTypeString] IS NOT NULL AND [source].[Position_PositionTypeString] IS NULL)) OR
	([target].[Security_Currency_Currency_Ccy] <> [source].[Security_Currency_Currency_Ccy] OR ([target].[Security_Currency_Currency_Ccy] IS NULL AND [source].[Security_Currency_Currency_Ccy] IS NOT NULL) OR ([target].[Security_Currency_Currency_Ccy] IS NOT NULL AND [source].[Security_Currency_Currency_Ccy] IS NULL)) OR
	([target].[Security_Currency_Currency_CurrencyID] <> [source].[Security_Currency_Currency_CurrencyID] OR ([target].[Security_Currency_Currency_CurrencyID] IS NULL AND [source].[Security_Currency_Currency_CurrencyID] IS NOT NULL) OR ([target].[Security_Currency_Currency_CurrencyID] IS NOT NULL AND [source].[Security_Currency_Currency_CurrencyID] IS NULL)) OR
	([target].[Security_Security_BloombergGlobalId] <> [source].[Security_Security_BloombergGlobalId] OR ([target].[Security_Security_BloombergGlobalId] IS NULL AND [source].[Security_Security_BloombergGlobalId] IS NOT NULL) OR ([target].[Security_Security_BloombergGlobalId] IS NOT NULL AND [source].[Security_Security_BloombergGlobalId] IS NULL)) OR
	([target].[Security_Security_BloombergID] <> [source].[Security_Security_BloombergID] OR ([target].[Security_Security_BloombergID] IS NULL AND [source].[Security_Security_BloombergID] IS NOT NULL) OR ([target].[Security_Security_BloombergID] IS NOT NULL AND [source].[Security_Security_BloombergID] IS NULL)) OR
	([target].[Security_Security_Code] <> [source].[Security_Security_Code] OR ([target].[Security_Security_Code] IS NULL AND [source].[Security_Security_Code] IS NOT NULL) OR ([target].[Security_Security_Code] IS NOT NULL AND [source].[Security_Security_Code] IS NULL)) OR
	([target].[Security_Security_ConversionRatio] <> [source].[Security_Security_ConversionRatio] OR ([target].[Security_Security_ConversionRatio] IS NULL AND [source].[Security_Security_ConversionRatio] IS NOT NULL) OR ([target].[Security_Security_ConversionRatio] IS NOT NULL AND [source].[Security_Security_ConversionRatio] IS NULL)) OR
	([target].[Security_Security_Name] <> [source].[Security_Security_Name] OR ([target].[Security_Security_Name] IS NULL AND [source].[Security_Security_Name] IS NOT NULL) OR ([target].[Security_Security_Name] IS NOT NULL AND [source].[Security_Security_Name] IS NULL)) OR
	([target].[Security_Security_SecurityID] <> [source].[Security_Security_SecurityID] OR ([target].[Security_Security_SecurityID] IS NULL AND [source].[Security_Security_SecurityID] IS NOT NULL) OR ([target].[Security_Security_SecurityID] IS NOT NULL AND [source].[Security_Security_SecurityID] IS NULL)) OR
	([target].[Security_Security_Ticker] <> [source].[Security_Security_Ticker] OR ([target].[Security_Security_Ticker] IS NULL AND [source].[Security_Security_Ticker] IS NOT NULL) OR ([target].[Security_Security_Ticker] IS NOT NULL AND [source].[Security_Security_Ticker] IS NULL)) OR
	([target].[Security_Type_SecurityType_Name] <> [source].[Security_Type_SecurityType_Name] OR ([target].[Security_Type_SecurityType_Name] IS NULL AND [source].[Security_Type_SecurityType_Name] IS NOT NULL) OR ([target].[Security_Type_SecurityType_Name] IS NOT NULL AND [source].[Security_Type_SecurityType_Name] IS NULL)) OR
	([target].[Security_Underlying_Security_Code] <> [source].[Security_Underlying_Security_Code] OR ([target].[Security_Underlying_Security_Code] IS NULL AND [source].[Security_Underlying_Security_Code] IS NOT NULL) OR ([target].[Security_Underlying_Security_Code] IS NOT NULL AND [source].[Security_Underlying_Security_Code] IS NULL)) OR
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
	([target].[Strategy_TradeStrategy_ShortCode] <> [source].[Strategy_TradeStrategy_ShortCode] OR ([target].[Strategy_TradeStrategy_ShortCode] IS NULL AND [source].[Strategy_TradeStrategy_ShortCode] IS NOT NULL) OR ([target].[Strategy_TradeStrategy_ShortCode] IS NOT NULL AND [source].[Strategy_TradeStrategy_ShortCode] IS NULL)) OR
	([target].[Total_Position_Calculated_PositionCash] <> [source].[Total_Position_Calculated_PositionCash] OR ([target].[Total_Position_Calculated_PositionCash] IS NULL AND [source].[Total_Position_Calculated_PositionCash] IS NOT NULL) OR ([target].[Total_Position_Calculated_PositionCash] IS NOT NULL AND [source].[Total_Position_Calculated_PositionCash] IS NULL))

)
	THEN UPDATE
	SET
		[ts_end] = @TimeStamp


	OUTPUT
		$Action as [MERGE_ACTION_eca623d4-44ee-434b-9830-7c538e4574e3],
		[source].[Custodian_TradeCpty_TradeCptyName] AS [Custodian_TradeCpty_TradeCptyName],
		[source].[CustomAccount] AS [CustomAccount],
		[source].[CustomBloombergID] AS [CustomBloombergID],
		[source].[CustomFundName] AS [CustomFundName],
		[source].[CustomFundSort] AS [CustomFundSort],
		[source].[CustomPartnershipID] AS [CustomPartnershipID],
		[source].[CustomRiskCategoryCode] AS [CustomRiskCategoryCode],
		[source].[CustomStrategyCode] AS [CustomStrategyCode],
		[source].[CustomTicker] AS [CustomTicker],
		[source].[CustomTickerSort] AS [CustomTickerSort],
		[source].[Fund_Currency_Currency_CurrencyID] AS [Fund_Currency_Currency_CurrencyID],
		[source].[Fund_TradeFund_Name] AS [Fund_TradeFund_Name],
		[source].[Position_Calculated_AverageCost] AS [Position_Calculated_AverageCost],
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
		[source].[Position_Calculated_PositionCash] AS [Position_Calculated_PositionCash],
		[source].[Position_Calculated_PositionValue] AS [Position_Calculated_PositionValue],
		[source].[Position_PositionID] AS [Position_PositionID],
		[source].[Position_PositionTypeString] AS [Position_PositionTypeString],
		[source].[Security_Currency_Currency_Ccy] AS [Security_Currency_Currency_Ccy],
		[source].[Security_Currency_Currency_CurrencyID] AS [Security_Currency_Currency_CurrencyID],
		[source].[Security_Security_BloombergGlobalId] AS [Security_Security_BloombergGlobalId],
		[source].[Security_Security_BloombergID] AS [Security_Security_BloombergID],
		[source].[Security_Security_Code] AS [Security_Security_Code],
		[source].[Security_Security_ConversionRatio] AS [Security_Security_ConversionRatio],
		[source].[Security_Security_MD_RealTimePrice] AS [Security_Security_MD_RealTimePrice],
		[source].[Security_Security_Name] AS [Security_Security_Name],
		[source].[Security_Security_SecurityID] AS [Security_Security_SecurityID],
		[source].[Security_Security_Ticker] AS [Security_Security_Ticker],
		[source].[Security_Type_SecurityType_Name] AS [Security_Type_SecurityType_Name],
		[source].[Security_Underlying_Security_Code] AS [Security_Underlying_Security_Code],
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
		[source].[Total_Position_Calculated_PositionCash] AS [Total_Position_Calculated_PositionCash],
		NULL AS [ts_end],
		@TimeStamp AS [ts_start],
		[source].[UniqKey] AS [UniqKey],
		[source].[UserName] AS [UserName]

)MERGE_OUTPUT
WHERE MERGE_OUTPUT.[MERGE_ACTION_eca623d4-44ee-434b-9830-7c538e4574e3] = 'UPDATE' 
	AND MERGE_OUTPUT.[UniqKey] IS NOT NULL
	AND MERGE_OUTPUT.[UserName] IS NOT NULL
;
COMMIT TRANSACTION merge_BroadridgePositions
END
GO
