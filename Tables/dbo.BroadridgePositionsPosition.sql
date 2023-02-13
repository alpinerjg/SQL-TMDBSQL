CREATE TABLE [dbo].[BroadridgePositionsPosition]
(
[UserName] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UniqKey] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ts_start] [datetime] NOT NULL,
[ts_end] [datetime] NULL,
[Position_Calculated_AverageCost] [decimal] (30, 10) NULL,
[Position_Calculated_PositionCash] [decimal] (30, 2) NULL,
[Position_Calculated_PositionValue] [decimal] (18, 0) NULL,
[Position_PositionID] [int] NULL,
[Position_PositionTypeString] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BroadridgePositionsPosition] ADD CONSTRAINT [PK_BroadridgePositionsPosition] PRIMARY KEY CLUSTERED ([UserName], [UniqKey], [ts_start] DESC) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
