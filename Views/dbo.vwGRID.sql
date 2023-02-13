SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vwGRID]
AS
SELECT        MAX(UpdateTime) AS UpdateTime, Fund, Account, SUM(DayPL) AS DayPL, SUM(MonthPL) AS MonthPL, SUM(YearPL) AS YearPL
FROM            dbo.GRID
GROUP BY UpdateTime, Fund, Account
GO
