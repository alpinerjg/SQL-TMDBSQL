CREATE TABLE [Minion].[BackupTuningThresholds]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[DBName] [sys].[sysname] NOT NULL,
[BackupType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SpaceType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ThresholdMeasure] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ThresholdValue] [bigint] NULL,
[NumberOfFiles] [tinyint] NULL,
[Buffercount] [smallint] NULL,
[MaxTransferSize] [bigint] NULL,
[Compression] [bit] NULL,
[BlockSize] [bigint] NULL,
[BeginTime] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EndTime] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DayOfWeek] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsActive] [bit] NULL,
[Comment] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Minion].[BackupTuningThresholds] WITH NOCHECK ADD CONSTRAINT [CK_Thresholds_BeginTimeFormat] CHECK (([BeginTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]' OR [BeginTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [BeginTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]' OR [BeginTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [BeginTime] IS NULL))
GO
ALTER TABLE [Minion].[BackupTuningThresholds] WITH NOCHECK ADD CONSTRAINT [CK_Thresholds_EndTimeFormat] CHECK (([EndTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]' OR [EndTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [EndTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]' OR [EndTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [EndTime] IS NULL))
GO
