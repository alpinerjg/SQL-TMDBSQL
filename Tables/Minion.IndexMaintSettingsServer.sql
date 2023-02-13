CREATE TABLE [Minion].[IndexMaintSettingsServer]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[DBType] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IndexOption] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReorgMode] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RunPrepped] [bit] NULL,
[PrepOnly] [bit] NULL,
[Day] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BeginTime] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[EndTime] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MaxForTimeframe] [int] NULL,
[FrequencyMins] [int] NULL,
[CurrentNumOps] [int] NULL,
[NumConcurrentOps] [tinyint] NULL,
[DBInternalThreads] [tinyint] NULL,
[TimeLimitInMins] [int] NULL,
[LastRunDateTime] [datetime] NULL,
[Include] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Exclude] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Schemas] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Tables] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BatchPreCode] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BatchPostCode] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Debug] [bit] NULL,
[FailJobOnError] [bit] NULL,
[FailJobOnWarning] [bit] NULL,
[IsActive] [bit] NULL,
[Comment] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Minion].[IndexMaintSettingsServer] ADD CONSTRAINT [CK_IndexMaintBeginTimeFormat] CHECK (([BeginTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]' OR [BeginTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [BeginTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]' OR [BeginTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [BeginTime] IS NULL))
GO
ALTER TABLE [Minion].[IndexMaintSettingsServer] ADD CONSTRAINT [CK_IndexMaintEndTimeFormat] CHECK (([EndTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]' OR [EndTime] like '[2][0-3]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [EndTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]' OR [EndTime] like '[0-1][0-9]:[0-5][0-9]:[0-5][0-9]:[0-9][0-9][0-9]' OR [EndTime] IS NULL))
GO
ALTER TABLE [Minion].[IndexMaintSettingsServer] ADD CONSTRAINT [PK_IndexMaintSettingsServer] PRIMARY KEY CLUSTERED ([ID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
