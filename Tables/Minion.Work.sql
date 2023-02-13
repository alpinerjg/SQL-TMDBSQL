CREATE TABLE [Minion].[Work]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[ExecutionDateTime] [datetime] NULL,
[Module] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BackupType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Param] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SPName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Value] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
