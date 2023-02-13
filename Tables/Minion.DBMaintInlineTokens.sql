CREATE TABLE [Minion].[DBMaintInlineTokens]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[DynamicName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ParseMethod] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsCustom] [bit] NULL,
[Definition] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsActive] [bit] NULL,
[Comment] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Minion].[DBMaintInlineTokens] ADD CONSTRAINT [ukInlineTokensActive] UNIQUE NONCLUSTERED ([DynamicName], [IsActive]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
