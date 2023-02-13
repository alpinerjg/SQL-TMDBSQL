CREATE TABLE [Minion].[SyncServer]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[Module] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBName] [sys].[sysname] NOT NULL,
[SyncServerName] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SyncDBName] [sys].[sysname] NOT NULL,
[Port] [int] NULL,
[ConnectionTimeoutInSecs] [int] NULL
) ON [PRIMARY]
GO
