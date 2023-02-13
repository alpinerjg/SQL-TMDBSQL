SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vwCXRATES]
AS
SELECT substring(bbsecurity,1,3)+'-'+substring(bbsecurity,4,3) as symbol,
		price,
		ts,
		tsbb
FROM [TMDBSQL].[dbo].[vwTICKDB] 
WHERE bbsecurity like '%Curncy' and price IS NOT NULL

GO
