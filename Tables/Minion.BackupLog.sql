CREATE TABLE [Minion].[BackupLog]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[ExecutionDateTime] [datetime] NULL,
[STATUS] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBType] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BackupType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StmtOnly] [bit] NULL,
[NumDBsOnServer] [int] NULL,
[NumDBsProcessed] [int] NULL,
[TotalBackupSizeInMB] [float] NULL,
[ReadOnly] [tinyint] NULL,
[ExecutionEndDateTime] [datetime] NULL,
[ExecutionRunTimeInSecs] [float] NULL,
[BatchPreCode] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BatchPostCode] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BatchPreCodeStartDateTime] [datetime] NULL,
[BatchPreCodeEndDateTime] [datetime] NULL,
[BatchPreCodeTimeInSecs] [int] NULL,
[BatchPostCodeStartDateTime] [datetime] NULL,
[BatchPostCodeEndDateTime] [datetime] NULL,
[BatchPostCodeTimeInSecs] [int] NULL,
[IncludeDBs] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ExcludeDBs] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RegexDBsIncluded] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RegexDBsExcluded] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Warnings] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [nonExecutionDateTime] ON [Minion].[BackupLog] ([ExecutionDateTime], [DBType], [BackupType]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [clustID] ON [Minion].[BackupLog] ([ID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
