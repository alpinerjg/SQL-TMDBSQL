CREATE TABLE [Minion].[CheckDBTableSnapshotQueue]
(
[ExecutionDateTime] [datetime] NULL,
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LatestSnapshotDateTime] [datetime] NULL,
[SnapshotDBName] [varchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Owner] [tinyint] NULL
) ON [PRIMARY]
GO
