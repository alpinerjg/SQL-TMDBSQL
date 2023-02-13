CREATE TABLE [dbo].[BroadridgePositionsOther]
(
[UserName] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UniqKey] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ts_start] [datetime] NOT NULL,
[ts_end] [datetime] NULL,
[Custodian_TradeCpty_TradeCptyName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Fund_Currency_Currency_CurrencyID] [int] NULL,
[Fund_TradeFund_Name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Total_Position_Calculated_PositionCash] [decimal] (30, 2) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BroadridgePositionsOther] ADD CONSTRAINT [PK_BroadridgePositionsOther] PRIMARY KEY CLUSTERED ([UserName], [UniqKey], [ts_start] DESC) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
