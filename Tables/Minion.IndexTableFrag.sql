CREATE TABLE [Minion].[IndexTableFrag]
(
[ExecutionDateTime] [datetime] NOT NULL,
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DBID] [int] NOT NULL,
[TableID] [bigint] NOT NULL,
[SchemaName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TableName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IndexName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IndexID] [bigint] NOT NULL,
[IndexType] [tinyint] NULL,
[IndexTypeDesc] [nvarchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsDisabled] [bit] NULL,
[IsHypothetical] [bit] NULL,
[avg_fragmentation_in_percent] [float] NULL,
[ReorgThreshold] [tinyint] NULL,
[RebuildThreshold] [tinyint] NULL,
[FILLFACTORopt] [tinyint] NULL,
[PadIndex] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ONLINEopt] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortInTempDB] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MAXDOPopt] [tinyint] NULL,
[DataCompression] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GetRowCT] [bit] NULL,
[GetPostFragLevel] [bit] NULL,
[UpdateStatsOnDefrag] [bit] NULL,
[StatScanOption] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IgnoreDupKey] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StatsNoRecompute] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AllowRowLocks] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AllowPageLocks] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WaitAtLowPriority] [bit] NULL,
[MaxDurationInMins] [int] NULL,
[AbortAfterWait] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LogProgress] [bit] NULL,
[LogRetDays] [smallint] NULL,
[PushToMinion] [bit] NULL,
[LogIndexPhysicalStats] [bit] NULL,
[IndexScanMode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TablePreCode] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TablePostCode] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Prepped] [bit] NULL,
[ReindexGroupOrder] [int] NULL,
[ReindexOrder] [int] NULL,
[StmtPrefix] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StmtSuffix] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RebuildHeap] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [Minion].[IndexTableFrag] ADD CONSTRAINT [PK_IndexTableFrag] PRIMARY KEY CLUSTERED ([ExecutionDateTime], [DBName], [TableID], [IndexID]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [nonDBNameTableID] ON [Minion].[IndexTableFrag] ([DBName], [TableID], [IndexID]) INCLUDE ([ONLINEopt]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [nonExecDateDBName] ON [Minion].[IndexTableFrag] ([ExecutionDateTime]) INCLUDE ([DBName], [SchemaName], [TableName]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
