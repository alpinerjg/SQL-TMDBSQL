CREATE TABLE [Minion].[CheckDBSettingsRotation]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[DBName] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OpName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RotationLimiter] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RotationLimiterMetric] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RotationMetricValue] [int] NULL,
[RotationPeriodInDays] [int] NULL,
[IsActive] [bit] NULL,
[Comment] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
