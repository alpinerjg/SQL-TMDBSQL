CREATE TABLE [dbo].[BroadridgePositionsStrategy]
(
[UserName] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UniqKey] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ts_start] [datetime] NOT NULL,
[ts_end] [datetime] NULL,
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
[Strategy_TradeStrategy_ShortCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BroadridgePositionsStrategy] ADD CONSTRAINT [PK_BroadridgePositionsStrategy] PRIMARY KEY CLUSTERED ([UserName], [UniqKey], [ts_start] DESC) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
