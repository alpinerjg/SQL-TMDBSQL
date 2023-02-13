SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[vwBroadridgePositionsSecurity_Today]
AS
SELECT *   FROM [TMDBSQL].[dbo].[BroadridgePositionsSecurity] WHERE ts_end >  DATEADD(hour,7,DATEDIFF(d,0,GETDATE())) or ts_start > DATEADD(hour,7,DATEDIFF(d,0,GETDATE()))
GO
