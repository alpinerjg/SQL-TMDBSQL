CREATE TABLE [Minion].[CheckDBCheckTableThreadQueue]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[ExecutionDateTime] [datetime] NULL,
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SchemaName] [varchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TableName] [varchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IndexName] [varchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Exclude] [bit] NULL,
[GroupOrder] [int] NULL,
[GroupDBOrder] [int] NULL,
[TimeEstimateSecs] [int] NULL,
[SizeInMB] [float] NULL,
[EstimatedKBperMS] [float] NULL,
[LastOpTimeInSecs] [int] NULL,
[NoIndex] [bit] NULL,
[RepairOption] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RepairOptionAgree] [bit] NULL,
[AllErrorMsgs] [bit] NULL,
[ExtendedLogicalChecks] [bit] NULL,
[NoInfoMsgs] [bit] NULL,
[IsTabLock] [bit] NULL,
[ResultMode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IntegrityCheckLevel] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HistRetDays] [int] NULL,
[TablePreCode] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TablePostCode] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StmtPrefix] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StmtSuffix] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PreferredServer] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Processing] [bit] NULL,
[ProcessingThread] [tinyint] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [clustExecDateDBName] ON [Minion].[CheckDBCheckTableThreadQueue] ([ExecutionDateTime], [DBName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
