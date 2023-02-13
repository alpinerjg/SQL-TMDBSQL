CREATE TABLE [Minion].[SyncErrorCmds]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[SyncServerName] [varchar] (140) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SyncDBName] [varchar] (140) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Port] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SyncCmdID] [bigint] NULL,
[STATUS] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastAttemptDateTime] [datetime] NULL
) ON [PRIMARY]
GO
