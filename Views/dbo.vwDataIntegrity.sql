SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vwDataIntegrity]
AS
	SELECT [bbsecurity]
      ,[type]
	  ,MAX(value) as maxvalue
	  ,MIN(value) as minvalue
	  ,AVG(value) as avgvalue
	  ,MAX(value)-MIN(value) as range
	  ,(MAX(value)-MIN(value)) / MIN(value) as pct
	  ,MAX(value)/MIN(value) as ratio
	  FROM [TMDBSQL].[dbo].[TICKDB_TYPE]
	  GROUP BY [bbsecurity],[type]
GO
