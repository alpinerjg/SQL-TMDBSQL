SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vwTICKDB]
AS
SELECT bbsecurity,	
		P AS price,
		B AS bid, 
		A AS ask,
		src,
		delayed,
		markethours,
		tsbb,
		ts,
		CASE WHEN tsbb = CAST(tsbb AS datetime2(0)) THEN 1 ELSE 0 END AS unmodified,
		CONVERT(VARCHAR(6), datediff(second, tsbb, ts)/3600) + ':' +
				RIGHT('0' + CONVERT(VARCHAR(2), (datediff(second, tsbb, ts) % 3600) / 60), 2) + ':' + 
				RIGHT('0' + CONVERT(VARCHAR(2), datediff(second, tsbb, ts) % 60), 2) as diff
FROM (
	SELECT * FROM (
		SELECT *
		FROM [TMDBSQL].[dbo].[vwTICKDB_TYPE]
	) AS SourceTable PIVOT(AVG([value]) FOR [type] IN ([P],[B],[A])) AS PivotTable
) AS pba
GO
