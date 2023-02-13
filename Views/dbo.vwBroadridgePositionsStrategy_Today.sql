SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[vwBroadridgePositionsStrategy_Today]
AS
SELECT *   FROM [TMDBSQL].[dbo].[BroadridgePositionsStrategy] WHERE ts_end >  DATEADD(hour,7,DATEDIFF(d,0,GETDATE())) or ts_start > DATEADD(hour,7,DATEDIFF(d,0,GETDATE()))
GO
