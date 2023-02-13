CREATE TABLE [Minion].[BackupSettings]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[DBName] [sys].[sysname] NOT NULL,
[Port] [int] NULL,
[BackupType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Exclude] [bit] NULL,
[GroupOrder] [int] NULL,
[GroupDBOrder] [int] NULL,
[Mirror] [bit] NULL,
[DelFileBefore] [bit] NULL,
[DelFileBeforeAgree] [bit] NULL,
[LogLoc] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HistRetDays] [smallint] NULL,
[MinionTriggerPath] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBPreCode] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBPostCode] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PushToMinion] [bit] NULL,
[DynamicTuning] [bit] NULL,
[Verify] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PreferredServer] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShrinkLogOnLogBackup] [bit] NULL,
[ShrinkLogThresholdInMB] [int] NULL,
[ShrinkLogSizeInMB] [int] NULL,
[MinSizeForDiffInGB] [bigint] NULL,
[DiffReplaceAction] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LogProgress] [bit] NULL,
[FileAction] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FileActionTime] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Encrypt] [bit] NULL,
[Name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ExpireDateInHrs] [int] NULL,
[RetainDays] [smallint] NULL,
[Descr] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Checksum] [bit] NULL,
[Init] [bit] NULL,
[Format] [bit] NULL,
[CopyOnly] [bit] NULL,
[Skip] [bit] NULL,
[BackupErrorMgmt] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MediaName] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MediaDescription] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsActive] [bit] NULL,
[Comment] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO