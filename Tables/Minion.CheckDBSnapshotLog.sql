CREATE TABLE [Minion].[CheckDBSnapshotLog]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[ExecutionDateTime] [datetime] NULL,
[OpName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SnapshotDBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FileID] [int] NULL,
[TypeDesc] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Name] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PhysicalName] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Size] [bigint] NULL,
[IsReadOnly] [bit] NULL,
[IsSparse] [bit] NULL,
[SnapshotDrive] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SnapshotPath] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FullPath] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerLabel] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PathOrder] [int] NULL,
[Cmd] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SizeInKB] [bigint] NULL,
[MaxSizeInKB] [bigint] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [clustExecDate] ON [Minion].[CheckDBSnapshotLog] ([ExecutionDateTime]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
