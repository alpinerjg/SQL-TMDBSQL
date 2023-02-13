CREATE TABLE [dbo].[BroadridgePositionsMarket]
(
[UserName] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UniqKey] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ts_start] [datetime] NOT NULL,
[ts_end] [datetime] NULL,
[CustomMarketPrice] [decimal] (30, 8) NULL,
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
[Security_Security_MD_RealTimePrice] [decimal] (30, 8) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BroadridgePositionsMarket] ADD CONSTRAINT [PK_BroadridgePositionsMarket] PRIMARY KEY CLUSTERED ([UserName], [UniqKey], [ts_start] DESC) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
