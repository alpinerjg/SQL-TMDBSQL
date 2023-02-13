CREATE TABLE [Minion].[SyncCmds]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[ExecutionDateTime] [datetime] NULL,
[Module] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Status] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ObjectName] [sys].[sysname] NOT NULL,
[Op] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Cmd] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Pushed] [bit] NULL,
[Attempts] [bigint] NULL,
[ErroredServers] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
