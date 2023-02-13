CREATE TABLE [Minion].[DBMaintDBGroups]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[Action] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaintType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GroupName] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GroupDef] [varchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Escape] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsActive] [bit] NULL,
[Comment] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
