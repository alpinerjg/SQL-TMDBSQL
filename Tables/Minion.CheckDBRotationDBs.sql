CREATE TABLE [Minion].[CheckDBRotationDBs]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[ExecutionDateTime] [datetime] NULL,
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OpName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [clustExecDateDBName] ON [Minion].[CheckDBRotationDBs] ([ExecutionDateTime], [DBName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
