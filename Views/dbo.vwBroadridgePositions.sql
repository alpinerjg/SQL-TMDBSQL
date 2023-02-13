SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE VIEW [dbo].[vwBroadridgePositions]
AS
SELECT
	   CONCAT(CustomAccount,'|',CustomStrategyCode,'|',CustomTickerSort) as UniqKey,
	   ts_start,
	   ts_end,
	   UniqKey as BroadridgeUniqKey,
	   [UserName]
           ,[Custodian_TradeCpty_TradeCptyName]
           ,[CustomAccount]
           ,[CustomBloombergID]
           ,[CustomFundName]
           ,[CustomFundSort]
           ,[CustomPartnershipID]
           ,[CustomRiskCategoryCode]
           ,[CustomStrategyCode]
           ,[CustomTickerSort]
           ,[CustomTicker]
           ,[Fund_Currency_Currency_CurrencyID]
           ,[Fund_TradeFund_Name]
           ,[Position_Calculated_AverageCost]
           ,[Position_Calculated_BaseLongMarketValueGain]
           ,[Position_Calculated_BaseLongMarketValue]
           ,[Position_Calculated_BaseMarketValueDayGain]
           ,[Position_Calculated_BaseMarketValue]
           ,[Position_Calculated_BasePNL_DTD]
           ,[Position_Calculated_BasePNL_MTD]
           ,[Position_Calculated_BasePNL_YTD]
           ,[Position_Calculated_BaseShortMarketValueGain]
           ,[Position_Calculated_BaseShortMarketValue]
           ,[Position_Calculated_LocalMarketValue]
           ,[Position_Calculated_MarketPrice]
           ,[Position_Calculated_PositionCash]
           ,[Position_Calculated_PositionValue]
           ,[Position_PositionID]
           ,[Position_PositionTypeString]
           ,[Security_Currency_Currency_Ccy]
           ,[Security_Currency_Currency_CurrencyID]
           ,[Security_Security_BloombergGlobalId]
           ,[Security_Security_BloombergID]
           ,[Security_Security_Code]
           ,[Security_Security_ConversionRatio]
           ,[Security_Security_MD_RealTimePrice]
           ,[Security_Security_Name]
           ,[Security_Security_SecurityID]
           ,[Security_Security_Ticker]
           ,[Security_Type_SecurityType_Name]
           ,[Security_Underlying_Security_Code]
           ,[Strategy_Risk_Category_RiskCategory_RiskCategoryID]
           ,[Strategy_Risk_Category_RiskCategory_RiskName]
           ,[Strategy_TradeStrategy_ActiveBenchmarkID]
           ,[Strategy_TradeStrategy_CountryID_mkt]
           ,[Strategy_TradeStrategy_Description]
           ,[Strategy_TradeStrategy_EndDate]
           ,[Strategy_TradeStrategy_IndustryID]
           ,[Strategy_TradeStrategy_IsClosed]
           ,[Strategy_TradeStrategy_Leverage]
           ,[Strategy_TradeStrategy_Name]
           ,[Strategy_TradeStrategy_PortfolioID]
           ,[Strategy_TradeStrategy_ShortCode]
           ,[Total_Position_Calculated_PositionCash]
FROM            dbo.BroadridgePositions
WHERE        (ts_end IS NULL)
GO
