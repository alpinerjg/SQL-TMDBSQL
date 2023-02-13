SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[vwBroadridgePositionsPosition]
AS
SELECT
	   *
FROM            dbo.BroadridgePositionsPosition
WHERE        (ts_end IS NULL)
GO
