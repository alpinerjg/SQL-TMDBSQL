CREATE TABLE [Minion].[CheckDBSettingsSnapshot]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OpName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomSnapshot] [bit] NULL,
[SnapshotRetMins] [int] NULL,
[SnapshotRetDeviation] [int] NULL,
[DeleteFinalSnapshot] [bit] NULL,
[SnapshotFailAction] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BeginTime] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EndTime] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DayOfWeek] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsActive] [bit] NULL,
[Comment] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
