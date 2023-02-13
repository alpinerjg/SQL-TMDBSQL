CREATE TABLE [Minion].[CheckDBSnapshotPath]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OpName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FileName] [varchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SnapshotDrive] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SnapshotPath] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerLabel] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PathOrder] [int] NULL CONSTRAINT [DF__CheckDB__PathO__145C0A3F] DEFAULT ((1)),
[IsActive] [bit] NULL,
[Comment] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
