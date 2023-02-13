CREATE TABLE [dbo].[BroadridgePositionsCustom]
(
[UserName] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UniqKey] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ts_start] [datetime] NOT NULL,
[ts_end] [datetime] NULL,
[CustomAccount] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomBloombergID] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomFundName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomFundSort] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomPartnershipID] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomRiskCategoryCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomStrategyCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomTickerSort] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomTicker] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BroadridgePositionsCustom] ADD CONSTRAINT [PK_BroadridgePositionsCustom] PRIMARY KEY CLUSTERED ([UserName], [UniqKey], [ts_start] DESC) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
