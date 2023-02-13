SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE VIEW [dbo].[vwBroadridgePositionsSecurity]
AS
SELECT
	   *
FROM            dbo.BroadridgePositionsSecurity
WHERE        (ts_end IS NULL)
GO
