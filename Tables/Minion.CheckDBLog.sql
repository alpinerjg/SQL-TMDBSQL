CREATE TABLE [Minion].[CheckDBLog]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[ExecutionDateTime] [datetime] NULL,
[STATUS] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBType] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OpName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NumConcurrentOps] [tinyint] NULL,
[DBInternalThreads] [tinyint] NULL,
[NumDBsOnServer] [int] NULL,
[NumDBsProcessed] [int] NULL,
[RotationLimiter] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RotationLimiterMetric] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RotationMetricValue] [int] NULL,
[TimeLimitInMins] [int] NULL,
[ExecutionEndDateTime] [datetime] NULL,
[ExecutionRunTimeInSecs] [float] NULL,
[BatchPreCodeStartDateTime] [datetime] NULL,
[BatchPostCodeStartDateTime] [datetime] NULL,
[BatchPreCode] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BatchPostCode] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Schemas] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Tables] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IncludeDBs] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ExcludeDBs] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RegexDBsIncluded] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RegexDBsExcluded] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [clustExecDate] ON [Minion].[CheckDBLog] ([ExecutionDateTime]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
