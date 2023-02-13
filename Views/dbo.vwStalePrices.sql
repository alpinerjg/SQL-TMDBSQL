SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[vwStalePrices]
AS
		SELECT * 
		FROM [TMDBSQL].[dbo].[TICKDB_TYPE] 
		WHERE [tsbb] < (SELECT [datebb] from [vwPriorDate])
GO
