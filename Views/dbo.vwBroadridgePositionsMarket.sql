SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE VIEW [dbo].[vwBroadridgePositionsMarket]
AS
SELECT
	   *
FROM            dbo.BroadridgePositionsMarket
WHERE        (ts_end IS NULL)
GO
