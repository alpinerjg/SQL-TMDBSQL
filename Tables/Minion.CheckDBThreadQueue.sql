CREATE TABLE [Minion].[CheckDBThreadQueue]
(
[ID] [smallint] NOT NULL IDENTITY(1, 1),
[ExecutionDateTime] [datetime] NULL,
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OpName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBInternalThreads] [tinyint] NULL,
[IsReadOnly] [bit] NULL,
[StateDesc] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CheckDBGroupOrder] [int] NULL,
[CheckDBOrder] [int] NULL,
[Processing] [bit] NULL,
[ProcessingThread] [tinyint] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [clustExecDateDBName] ON [Minion].[CheckDBThreadQueue] ([ExecutionDateTime], [DBName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
