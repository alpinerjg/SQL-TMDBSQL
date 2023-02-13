SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vwTICKDB_SRC]
AS
	SELECT  [bbsecurity]
			,[price]
			,[bid]
			,[ask]
			,[src]
			,[delayed]
			,[markethours]
			,[tsbb]
			,[ts]
	from    (
			SELECT row_number() OVER (PARTITION BY [bbsecurity] ORDER BY [tsbb] DESC,[ts] ASC,[src]) as rn
			,       *
			FROM    [TMDBSQL].[dbo].[TICKDB] 
			) as SubQueryAlias
	WHERE   rn = 1
GO
