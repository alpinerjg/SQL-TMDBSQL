CREATE TABLE [Minion].[CheckDBDebug]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[ExecutionDateTime] [datetime] NULL,
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OpName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SPName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StepName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StepValue] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
