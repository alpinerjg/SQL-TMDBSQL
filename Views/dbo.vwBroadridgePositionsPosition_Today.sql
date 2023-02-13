SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[vwBroadridgePositionsPosition_Today]
AS
SELECT *   FROM [TMDBSQL].[dbo].[BroadridgePositionsPosition] WHERE ts_end >  DATEADD(hour,7,DATEDIFF(d,0,GETDATE())) or ts_start > DATEADD(hour,7,DATEDIFF(d,0,GETDATE()))
GO
