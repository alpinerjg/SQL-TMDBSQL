CREATE TABLE [Minion].[CheckDBSettingsAutoThresholds]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ThresholdMethod] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ThresholdType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ThresholdMeasure] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ThresholdValue] [int] NULL,
[IsActive] [bit] NULL,
[Comment] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
