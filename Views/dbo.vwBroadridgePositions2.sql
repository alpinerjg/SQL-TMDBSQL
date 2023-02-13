SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[vwBroadridgePositions2]
AS
SELECT	Market.UserName,
		Market.UniqKey,
		Market.ts_start,
		Market.Position_Calculated_BaseLongMarketValueGain,
		Market.Position_Calculated_BaseLongMarketValue,
		Market.Position_Calculated_BaseMarketValueDayGain,
		Market.Position_Calculated_BaseMarketValue ,
		Market.Position_Calculated_BasePNL_DTD ,
		Market.Position_Calculated_BasePNL_MTD ,
		Market.Position_Calculated_BasePNL_YTD ,
		Market.Position_Calculated_BaseShortMarketValueGain ,
		Market.Position_Calculated_BaseShortMarketValue ,
		Market.Position_Calculated_LocalMarketValue ,
		Market.Position_Calculated_MarketPrice ,
        Market.Security_Security_MD_RealTimePrice ,

		Custom.CustomBloombergID,
		Custom.CustomFundName,
		Custom.CustomFundSort,
		Custom.CustomPartnershipID,
		Custom.CustomRiskCategoryCode,
		Custom.CustomStrategyCode,
		Custom.CustomTickerSort,
		Custom.CustomTicker,

		Other.Custodian_TradeCpty_TradeCptyName,
		Other.Fund_Currency_Currency_CurrencyID,
		Other.Fund_TradeFund_Name,
		Other.Total_Position_Calculated_PositionCash,

		Position.Position_Calculated_AverageCost,
		Position.Position_Calculated_PositionCash,
		Position.Position_Calculated_PositionValue,
		Position.Position_PositionID,
		Position.Position_PositionTypeString,

		Security.Security_Currency_Currency_Ccy,
		Security.Security_Currency_Currency_CurrencyID,
		Security.Security_Security_BloombergGlobalId,
		Security.Security_Security_BloombergID,
		Security.Security_Security_Code,
		Security.Security_Security_ConversionRatio,
		Security.Security_Security_Name,
		Security.Security_Security_SecurityID,
		Security.Security_Security_Ticker,
		Security.Security_Type_SecurityType_Name,
		Security.Security_Underlying_Security_Code,

		Strategy.Strategy_Risk_Category_RiskCategory_RiskCategoryID,
		Strategy.Strategy_Risk_Category_RiskCategory_RiskName,
		Strategy.Strategy_TradeStrategy_ActiveBenchmarkID,
		Strategy.Strategy_TradeStrategy_CountryID_mkt,
		Strategy.Strategy_TradeStrategy_Description,
		Strategy.Strategy_TradeStrategy_EndDate,
		Strategy.Strategy_TradeStrategy_IndustryID,
		Strategy.Strategy_TradeStrategy_IsClosed,
		Strategy.Strategy_TradeStrategy_Leverage,
		Strategy.Strategy_TradeStrategy_Name,
		Strategy.Strategy_TradeStrategy_PortfolioID,
		Strategy.Strategy_TradeStrategy_ShortCode

FROM [vwBroadridgePositionsCustom] Custom
	INNER JOIN [vwBroadridgePositionsMarket] Market ON Market.UserName = Custom.UserName and Market.UniqKey = Custom.UniqKey
	INNER JOIN [vwBroadridgePositionsOther] Other ON Other.UserName = Custom.UserName and Other.UniqKey = Custom.UniqKey
	INNER JOIN [vwBroadridgePositionsPosition] Position ON Position.UserName = Custom.UserName and Position.UniqKey = Custom.UniqKey
	INNER JOIN [vwBroadridgePositionsSecurity] Security ON Security.UserName = Custom.UserName and Security.UniqKey = Custom.UniqKey
	INNER JOIN [vwBroadridgePositionsStrategy] Strategy ON Strategy.UserName = Custom.UserName and Strategy.UniqKey = Custom.UniqKey

GO
