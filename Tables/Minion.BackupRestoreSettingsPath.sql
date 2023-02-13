CREATE TABLE [Minion].[BackupRestoreSettingsPath]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [varchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RestoreType] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FileType] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TypeName] [varchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RestoreDrive] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RestorePath] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RestoreFileName] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RestoreFileExtension] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BackupLocation] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RestoreDBName] [varchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerLabel] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PathOrder] [int] NULL,
[IsActive] [bit] NULL,
[Comment] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
