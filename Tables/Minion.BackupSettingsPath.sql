CREATE TABLE [Minion].[BackupSettingsPath]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[DBName] [sys].[sysname] NOT NULL,
[IsMirror] [bit] NULL CONSTRAINT [DF__BackupSet__isMir__1367E606] DEFAULT ((0)),
[BackupType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BackupLocType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BackupDrive] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BackupPath] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FileName] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FileExtension] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerLabel] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RetHrs] [int] NULL,
[FileActionMethod] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FileActionMethodFlags] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PathOrder] [int] NULL CONSTRAINT [DF__BackupSet__PathO__145C0A3F] DEFAULT ((0)),
[IsActive] [bit] NULL,
[AzureCredential] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Comment] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
