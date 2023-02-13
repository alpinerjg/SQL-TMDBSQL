SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[vwBroadridgePositionsOther]
AS
SELECT
	   *
FROM            dbo.BroadridgePositionsOther
WHERE        (ts_end IS NULL)
GO
