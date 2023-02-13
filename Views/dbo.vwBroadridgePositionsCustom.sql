SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[vwBroadridgePositionsCustom]
AS
SELECT
	   *
FROM            dbo.BroadridgePositionsCustom
WHERE        (ts_end IS NULL)
GO
