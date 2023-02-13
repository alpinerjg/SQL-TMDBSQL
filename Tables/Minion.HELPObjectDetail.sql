CREATE TABLE [Minion].[HELPObjectDetail]
(
[ObjectID] [int] NULL,
[DetailName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Position] [smallint] NULL,
[DetailType] [sys].[sysname] NULL,
[DetailHeader] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DetailText] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DataType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Minion].[HELPObjectDetail] ADD CONSTRAINT [FK_ObjectDetail_Objects_ID] FOREIGN KEY ([ObjectID]) REFERENCES [Minion].[HELPObjects] ([ID])
GO
