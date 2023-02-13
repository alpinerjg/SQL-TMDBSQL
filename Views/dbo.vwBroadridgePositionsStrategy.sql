SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[vwBroadridgePositionsStrategy]
AS
SELECT
	   *
FROM            dbo.BroadridgePositionsStrategy
WHERE        (ts_end IS NULL)
GO
