CREATE TABLE [Minion].[BackupSettingsServer]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[DBType] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BackupType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Day] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReadOnly] [tinyint] NULL,
[BeginTime] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[EndTime] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MaxForTimeframe] [int] NULL,
[FrequencyMins] [int] NULL,
[CurrentNumBackups] [int] NULL,
[NumConcurrentBackups] [tinyint] NULL,
[LastRunDateTime] [datetime] NULL,
[Include] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Exclude] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SyncSettings] [bit] NULL,
[SyncLogs] [bit] NULL,
[BatchPreCode] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BatchPostCode] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Debug] [bit] NULL,
[FailJobOnError] [bit] NULL,
[FailJobOnWarning] [bit] NULL,
[IsActive] [bit] NULL,
[Comment] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Minion].[BackupSettingsServer] ADD CONSTRAINT [CK_BeginTimeFormat] CHECK (([BeginTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]' OR [BeginTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [BeginTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]' OR [BeginTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [BeginTime] IS NULL))
GO
ALTER TABLE [Minion].[BackupSettingsServer] ADD CONSTRAINT [CK_EndTimeFormat] CHECK (([EndTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]' OR [EndTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [EndTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]' OR [EndTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [EndTime] IS NULL))
GO
ALTER TABLE [Minion].[BackupSettingsServer] ADD CONSTRAINT [PK_BackupSettingsServer] PRIMARY KEY CLUSTERED ([ID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
