CREATE TABLE [dbo].[BroadridgePositionsSecurity]
(
[UserName] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UniqKey] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ts_start] [datetime] NOT NULL,
[ts_end] [datetime] NULL,
[Security_Currency_Currency_Ccy] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Security_Currency_Currency_CurrencyID] [int] NULL,
[Security_Security_BloombergGlobalId] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Security_Security_BloombergID] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Security_Security_Code] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Security_Security_ConversionRatio] [decimal] (30, 5) NULL,
[Security_Security_Name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Security_Security_SecurityID] [int] NULL,
[Security_Security_Ticker] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Security_Type_SecurityType_Name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Security_Underlying_Security_Code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BroadridgePositionsSecurity] ADD CONSTRAINT [PK_BroadridgePositionsSecurity] PRIMARY KEY CLUSTERED ([UserName], [UniqKey], [ts_start] DESC) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
