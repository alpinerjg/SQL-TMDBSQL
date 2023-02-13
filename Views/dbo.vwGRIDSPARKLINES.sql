SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vwGRIDSPARKLINES]
AS
SELECT	gsl.Fund, 
		gsl.Account, 
		gsl.UpdateTime, 
		CAST(ROUND(100 * ISNULL(gsl.DayPL / NULLIF (pla.DayPLAbs, 0), 0), 0) AS int) AS DayPL
FROM	dbo.GRIDSPARKLINES AS gsl INNER JOIN
        dbo.vwGRIDSPARKLINES_DayPLAbs AS pla 
		ON	gsl.Fund = pla.Fund AND 
			gsl.Account = pla.Account
GO
