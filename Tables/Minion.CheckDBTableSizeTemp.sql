CREATE TABLE [Minion].[CheckDBTableSizeTemp]
(
[ExecutionDateTime] [datetime] NULL,
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SchemaName] [sys].[sysname] NULL,
[TableName] [sys].[sysname] NOT NULL,
[RowCT] [bigint] NULL,
[TotalSpaceKB] [numeric] (20, 1) NULL,
[UsedSpaceKB] [bigint] NULL,
[UnusedSpaceKB] [bigint] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [clustExecDateDBName] ON [Minion].[CheckDBTableSizeTemp] ([ExecutionDateTime], [DBName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
