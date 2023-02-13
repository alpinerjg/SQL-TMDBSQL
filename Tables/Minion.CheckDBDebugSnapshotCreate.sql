CREATE TABLE [Minion].[CheckDBDebugSnapshotCreate]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[ExecutionDateTime] [datetime] NULL,
[CurrentDateTime] [datetime] NULL,
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SnapshotDBName] [varchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SPName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SnapshotCompareBegin] [datetime] NULL,
[SnapshotRetMins] [tinyint] NULL,
[SnapshotDelta] [int] NULL,
[DeleteCurrentSnapshot] [bit] NULL,
[CreateNewSnapshot] [bit] NULL,
[Thread] [tinyint] NULL,
[SnapshotCreationOwner] [tinyint] NULL,
[CheckDBCmd] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
