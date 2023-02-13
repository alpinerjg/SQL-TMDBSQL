CREATE TABLE [Minion].[HELPObjects]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[Module] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ObjectName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ObjectType] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MinionVersion] [float] NULL,
[GlobalPosition] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [Minion].[HELPObjects] ADD CONSTRAINT [PK__Objects__3214EC27E83D3C4F] PRIMARY KEY CLUSTERED ([ID]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
