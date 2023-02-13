CREATE TABLE [Minion].[IndexMaintLogDetails]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[ExecutionDateTime] [datetime] NOT NULL,
[Status] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TableID] [bigint] NULL,
[SchemaName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TableName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IndexID] [int] NULL,
[IndexName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IndexTypeDesc] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IndexScanMode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Op] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ONLINEopt] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReorgThreshold] [tinyint] NULL,
[RebuildThreshold] [tinyint] NULL,
[FILLFACTORopt] [tinyint] NULL,
[PadIndex] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FragLevel] [tinyint] NULL,
[Stmt] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReindexGroupOrder] [int] NULL,
[ReindexOrder] [int] NULL,
[PreCode] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PostCode] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OpBeginDateTime] [datetime] NULL,
[OpEndDateTime] [datetime] NULL,
[OpRunTimeInSecs] [int] NULL,
[TableRowCTBeginDateTime] [datetime] NULL,
[TableRowCTEndDateTime] [datetime] NULL,
[TableRowCTTimeInSecs] [int] NULL,
[TableRowCT] [bigint] NULL,
[PostFragBeginDateTime] [datetime] NULL,
[PostFragEndDateTime] [datetime] NULL,
[PostFragTimeInSecs] [int] NULL,
[PostFragLevel] [tinyint] NULL,
[UpdateStatsBeginDateTime] [datetime] NULL,
[UpdateStatsEndDateTime] [datetime] NULL,
[UpdateStatsTimeInSecs] [int] NULL,
[UpdateStatsStmt] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PreCodeBeginDateTime] [datetime] NULL,
[PreCodeEndDateTime] [datetime] NULL,
[PreCodeRunTimeInSecs] [int] NULL,
[PostCodeBeginDateTime] [datetime] NULL,
[PostCodeEndDateTime] [datetime] NULL,
[PostCodeRunTimeInSecs] [bigint] NULL,
[UserSeeks] [bigint] NULL,
[UserScans] [bigint] NULL,
[UserLookups] [bigint] NULL,
[UserUpdates] [bigint] NULL,
[LastUserSeek] [datetime] NULL,
[LastUserScan] [datetime] NULL,
[LastUserLookup] [datetime] NULL,
[LastUserUpdate] [datetime] NULL,
[SystemSeeks] [bigint] NULL,
[SystemScans] [bigint] NULL,
[SystemLookups] [bigint] NULL,
[SystemUpdates] [bigint] NULL,
[LastSystemSeek] [datetime] NULL,
[LastSystemScan] [datetime] NULL,
[LastSystemLookup] [datetime] NULL,
[LastSystemUpdate] [datetime] NULL,
[Warnings] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [nonExecDateDBNameLogDet] ON [Minion].[IndexMaintLogDetails] ([ExecutionDateTime], [DBName], [SchemaName], [TableName], [IndexName]) INCLUDE ([Warnings]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO