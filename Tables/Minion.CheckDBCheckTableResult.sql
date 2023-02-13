CREATE TABLE [Minion].[CheckDBCheckTableResult]
(
[ExecutionDateTime] [datetime] NULL,
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SchemaName] [varchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TableName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IndexName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IndexType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BeginTime] [datetime] NULL,
[EndTime] [datetime] NULL,
[Error] [int] NULL,
[Level] [int] NULL,
[State] [int] NULL,
[MessageText] [varchar] (7000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RepairLevel] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Status] [int] NULL,
[DbId] [int] NULL,
[DbFragId] [int] NULL,
[ObjectId] [bigint] NULL,
[IndexID] [int] NULL,
[PartitionId] [bigint] NULL,
[AllocUnitId] [bigint] NULL,
[RidDBId] [int] NULL,
[RidPruId] [int] NULL,
[File] [int] NULL,
[Page] [bigint] NULL,
[Slot] [bigint] NULL,
[RefDbId] [int] NULL,
[RefPruId] [int] NULL,
[RefFile] [bigint] NULL,
[RefPage] [bigint] NULL,
[RefSlot] [bigint] NULL,
[Allocation] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [nonDBSchemaTable] ON [Minion].[CheckDBCheckTableResult] ([DBName], [SchemaName], [TableName]) INCLUDE ([ExecutionDateTime]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [clustExecDateDBName] ON [Minion].[CheckDBCheckTableResult] ([ExecutionDateTime], [DBName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
