CREATE TABLE [dbo].[GRIDSPARKLINES]
(
[Fund] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Account] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UpdateTime] [datetime2] NOT NULL,
[DayPL] [decimal] (12, 2) NOT NULL,
[MonthPL] [decimal] (12, 2) NOT NULL,
[YearPL] [decimal] (12, 2) NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[GRIDSPARKLINES] ADD CONSTRAINT [PK_GRIDSPARKLINES] PRIMARY KEY CLUSTERED ([Fund], [Account], [UpdateTime]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
