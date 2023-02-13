CREATE TABLE [Minion].[CheckDBDebugSnapshotThreads]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[ExecutionDateTime] [datetime] NULL,
[CurrentDateTime] [datetime] NULL,
[RunType] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SnapshotDBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SPName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SnapshotCompareBegin] [datetime] NULL,
[SnapshotRetMins] [tinyint] NULL,
[SnapshotDelta] [int] NULL,
[DeleteCurrentSnapshot] [bit] NULL,
[CreateNewSnapshot] [bit] NULL,
[Thread] [tinyint] NULL,
[SnapshotCreationOwner] [tinyint] NULL
) ON [PRIMARY]
GO
