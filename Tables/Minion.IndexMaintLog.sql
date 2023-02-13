CREATE TABLE [Minion].[IndexMaintLog]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[ExecutionDateTime] [datetime] NULL,
[Status] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Tables] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RunPrepped] [bit] NULL,
[PrepOnly] [bit] NULL,
[ReorgMode] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NumTablesProcessed] [int] NULL,
[NumIndexesProcessed] [int] NULL,
[NumIndexesRebuilt] [int] NULL,
[NumIndexesReorged] [int] NULL,
[RecoveryModelChanged] [bit] NULL,
[RecoveryModelCurrent] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RecoveryModelReindex] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SQLVersion] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SQLEdition] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBPreCode] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBPostCode] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBPreCodeBeginDateTime] [datetime] NULL,
[DBPreCodeEndDateTime] [datetime] NULL,
[DBPostCodeBeginDateTime] [datetime] NULL,
[DBPostCodeEndDateTime] [datetime] NULL,
[DBPreCodeRunTimeInSecs] [int] NULL,
[DBPostCodeRunTimeInSecs] [int] NULL,
[ExecutionFinishTime] [datetime] NULL,
[ExecutionRunTimeInSecs] [int] NULL,
[IncludeDBs] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ExcludeDBs] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RegexDBsIncluded] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RegexDBsExcluded] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Warnings] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ixIndexMaintLogDate] ON [Minion].[IndexMaintLog] ([ExecutionDateTime], [DBName]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
