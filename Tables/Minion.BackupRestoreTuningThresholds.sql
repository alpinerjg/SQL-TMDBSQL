CREATE TABLE [Minion].[BackupRestoreTuningThresholds]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[ServerName] [varchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBName] [sys].[sysname] NOT NULL,
[RestoreType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SpaceType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ThresholdMeasure] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ThresholdValue] [bigint] NULL,
[Buffercount] [smallint] NULL,
[MaxTransferSize] [bigint] NULL,
[BlockSize] [bigint] NULL,
[Replace] [bit] NULL,
[WithFlags] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BeginTime] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EndTime] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DayOfWeek] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsActive] [bit] NULL,
[Comment] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Minion].[BackupRestoreTuningThresholds] WITH NOCHECK ADD CONSTRAINT [CK_RThresholds_BeginTimeFormat] CHECK (([BeginTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]' OR [BeginTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [BeginTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]' OR [BeginTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [BeginTime] IS NULL))
GO
ALTER TABLE [Minion].[BackupRestoreTuningThresholds] WITH NOCHECK ADD CONSTRAINT [CK_RThresholds_EndTimeFormat] CHECK (([EndTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]' OR [EndTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [EndTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]' OR [EndTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [EndTime] IS NULL))
GO
