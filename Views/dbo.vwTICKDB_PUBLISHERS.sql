SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- vwTICKDB



CREATE VIEW [dbo].[vwTICKDB_PUBLISHERS]
AS
SELECT [src]
      ,MAX([ts]) as tsmax
	  ,MAX([tsbb]) as tsbbmax
	  ,DATEDIFF(day,MAX(ts),SYSDATETIME()) as days
	  ,CAST(CASE WHEN 2 < DATEDIFF(MINUTE,MAX([ts]),SYSDATETIME()) THEN 0 ELSE 1 END AS BIT) AS 'live'
	  ,COUNT(*) as num
  FROM [TMDBSQL].[dbo].[vwTICKDB]
  GROUP BY src
--  ORDER BY tsmax DESC
GO
