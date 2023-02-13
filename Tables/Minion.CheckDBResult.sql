CREATE TABLE [Minion].[CheckDBResult]
(
[ExecutionDateTime] [datetime] NULL,
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
[RidDBId] [bigint] NULL,
[RidPruId] [bigint] NULL,
[File] [int] NULL,
[Page] [bigint] NULL,
[Slot] [bigint] NULL,
[RefDbId] [int] NULL,
[RefPruId] [int] NULL,
[RefFile] [int] NULL,
[RefPage] [bigint] NULL,
[RefSlot] [bigint] NULL,
[Allocation] [int] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ClustExecDBName] ON [Minion].[CheckDBResult] ([ExecutionDateTime], [DBName]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
