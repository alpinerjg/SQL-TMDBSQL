SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[vwLiveDelayedCount]
AS
	SELECT [bbsecurity]
			,SUM(CASE WHEN [delayed] = 0 THEN 1 else 0 END) [live]	
			,SUM(CASE WHEN [delayed] = 1 THEN 1 else 0 END) [delayed]
			,SUM(CASE WHEN [markethours] = 0 THEN 1 else 0 END) [offhours]	
			,SUM(CASE WHEN [markethours] = 1 THEN 1 else 0 END) [markethours]
	FROM [TMDBSQL].[dbo].[TICKDB_TYPE]
	WHERE type='P'
	GROUP BY bbsecurity
GO
