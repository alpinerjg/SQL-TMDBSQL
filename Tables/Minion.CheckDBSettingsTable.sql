CREATE TABLE [Minion].[CheckDBSettingsTable]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SchemaName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TableName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IndexName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Exclude] [bit] NULL,
[GroupOrder] [int] NULL,
[GroupTableOrder] [int] NULL,
[DefaultTimeEstimateMins] [int] NULL,
[PreferredServer] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TableOrderType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NoIndex] [bit] NULL,
[RepairOption] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RepairOptionAgree] [bit] NULL,
[AllErrorMsgs] [bit] NULL,
[ExtendedLogicalChecks] [bit] NULL,
[NoInfoMsgs] [bit] NULL,
[IsTabLock] [bit] NULL,
[ResultMode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IntegrityCheckLevel] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HistRetDays] [int] NULL,
[TablePreCode] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TablePostCode] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StmtPrefix] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StmtSuffix] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BeginTime] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EndTime] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DayOfWeek] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsActive] [bit] NULL,
[Comment] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
