SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[vwLagDetail]
WITH SCHEMABINDING

AS
  -- Before market opens, grab the past 1 hour of prices
  SELECT [bbsecurity],[type],[src],[value],[delayed],[markethours],[tsbb],[ts],[lag],[tsdiff],DATEDIFF(SECOND, tsbb, SYSDATETIME()) AS age,LEFT(CONVERT(VARCHAR, DATEADD(SECOND, DATEDIFF(SECOND, tsbb, SYSDATETIME()), 0), 114),8) AS agefmt
  FROM [dbo].[vwTICKDB_TYPE]
  WHERE type = 'P' AND delayed = 0 AND tsbb > GETDATE() - CAST('1:00' AS DATETIME) AND CAST(GETDATE() AS TIME) <= '09:30:00'

  UNION ALL

  -- After market opens, grab everything since the market opened
  SELECT [bbsecurity],[type],[src],[value],[delayed],[markethours],[tsbb],[ts],[lag],[tsdiff],DATEDIFF(SECOND, tsbb, SYSDATETIME()) AS age,LEFT(CONVERT(VARCHAR, DATEADD(SECOND, DATEDIFF(SECOND, tsbb, SYSDATETIME()), 0), 114),8) AS agefmt
  FROM [dbo].[vwTICKDB_TYPE]
  WHERE type = 'P' AND delayed = 0 AND tsbb > CAST(CAST(SYSUTCDATETIME() AS DATE) AS DATETIME) + CAST('9:30' AS DATETIME)
GO
