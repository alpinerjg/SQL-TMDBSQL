CREATE TABLE [Minion].[BackupCert]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[CertType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CertPword] [varbinary] (max) NULL,
[BackupCert] [bit] NULL
) ON [PRIMARY]
GO
