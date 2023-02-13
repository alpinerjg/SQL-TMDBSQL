SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[vwLagFrequency]
WITH SCHEMABINDING

AS
  -- Before market opens, grab the past 1 hour of prices
  SELECT [lag],
		COUNT([lag]) AS cnt,
		tsdiff,
		CAST(
			CAST(100*COUNT([lag]) AS NUMERIC(10,2))/
			CAST((SELECT COUNT(*) FROM [dbo].[vwLagDetail]) AS NUMERIC(10,2))
			AS NUMERIC(10,2)) AS pct
  FROM [dbo].[vwLagDetail]
  GROUP BY [lag],[tsdiff]
GO
