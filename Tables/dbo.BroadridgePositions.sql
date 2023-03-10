CREATE TABLE [dbo].[BroadridgePositions]
(
[UserName] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UniqKey] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ts_start] [datetime] NOT NULL,
[ts_end] [datetime] NULL,
[Custodian_TradeCpty_TradeCptyName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomAccount] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomBloombergID] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomFundName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomFundSort] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomPartnershipID] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomRiskCategoryCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomStrategyCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomTickerSort] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomTicker] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Fund_Currency_Currency_CurrencyID] [int] NULL,
[Fund_TradeFund_Name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Position_Calculated_AverageCost] [decimal] (30, 10) NULL,
[Position_Calculated_BaseLongMarketValueGain] [decimal] (30, 8) NULL,
[Position_Calculated_BaseLongMarketValue] [decimal] (30, 8) NULL,
[Position_Calculated_BaseMarketValueDayGain] [decimal] (30, 8) NULL,
[Position_Calculated_BaseMarketValue] [decimal] (30, 10) NULL,
[Position_Calculated_BasePNL_DTD] [decimal] (30, 2) NULL,
[Position_Calculated_BasePNL_MTD] [decimal] (30, 2) NULL,
[Position_Calculated_BasePNL_YTD] [decimal] (30, 2) NULL,
[Position_Calculated_BaseShortMarketValueGain] [decimal] (30, 8) NULL,
[Position_Calculated_BaseShortMarketValue] [decimal] (30, 8) NULL,
[Position_Calculated_LocalMarketValue] [decimal] (30, 8) NULL,
[Position_Calculated_MarketPrice] [decimal] (30, 8) NULL,
[Position_Calculated_PositionCash] [decimal] (30, 2) NULL,
[Position_Calculated_PositionValue] [decimal] (18, 0) NULL,
[Position_PositionID] [int] NULL,
[Position_PositionTypeString] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Security_Currency_Currency_Ccy] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Security_Currency_Currency_CurrencyID] [int] NULL,
[Security_Security_BloombergGlobalId] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Security_Security_BloombergID] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Security_Security_Code] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Security_Security_ConversionRatio] [decimal] (30, 5) NULL,
[Security_Security_MD_RealTimePrice] [decimal] (30, 8) NULL,
[Security_Security_Name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Security_Security_SecurityID] [int] NULL,
[Security_Security_Ticker] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Security_Type_SecurityType_Name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Security_Underlying_Security_Code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Strategy_Risk_Category_RiskCategory_RiskCategoryID] [int] NULL,
[Strategy_Risk_Category_RiskCategory_RiskName] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Strategy_TradeStrategy_ActiveBenchmarkID] [int] NULL,
[Strategy_TradeStrategy_CountryID_mkt] [int] NULL,
[Strategy_TradeStrategy_Description] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Strategy_TradeStrategy_EndDate] [date] NULL,
[Strategy_TradeStrategy_IndustryID] [int] NULL,
[Strategy_TradeStrategy_IsClosed] [bit] NULL,
[Strategy_TradeStrategy_Leverage] [decimal] (30, 8) NULL,
[Strategy_TradeStrategy_Name] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Strategy_TradeStrategy_PortfolioID] [int] NULL,
[Strategy_TradeStrategy_ShortCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Total_Position_Calculated_PositionCash] [decimal] (30, 2) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BroadridgePositions] ADD CONSTRAINT [PK_BroadridgePositions] PRIMARY KEY CLUSTERED ([UserName], [UniqKey], [ts_start] DESC) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
