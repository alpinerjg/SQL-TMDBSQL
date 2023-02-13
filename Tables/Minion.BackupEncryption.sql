CREATE TABLE [Minion].[BackupEncryption]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[DBName] [sys].[sysname] NOT NULL,
[BackupType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CertType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CertName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EncrAlgorithm] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ThumbPrint] [varbinary] (32) NULL,
[IsActive] [bit] NULL
) ON [PRIMARY]
GO
