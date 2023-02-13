SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







/*******************************************************************************************/
/*  Solution from https://stackoverflow.com/questions/6841605/get-top-1-row-of-each-group  */
/*******************************************************************************************/
-- WITH cte as 
-- (SELECT *, ROW_NUMBER() OVER (PARTITION BY bbsecurity, type ORDER BY tsbb DESC) as rn
--  FROM [TMDBSQL].[dbo].[vwTICKDB_TYPE_TIES]
-- ) SELECT bbsecurity,type,value,tsbb FROM cte where rn = 1

/***********************************************************************************************************************/
/*  Solution from https://stackoverflow.com/questions/6520036/using-max-and-returning-whole-row-with-max-column-value  */
/***********************************************************************************************************************/

--
-- SPECIAL WARNING!!!!!!
--
--  TradeMaster accessing pricing data by querying this view with the following query:
--     SELECT TOP(1) [value] FROM [TMDBSQL].[dbo].[vwTICKDB_TYPE] WHERE [bbsecurity] = 'foo' and [type] = 'P' and [value] IS NOT NULL ORDER BY [tsbb] DESC
--
--  Be VERY careful making any changes to this query
--

CREATE VIEW [dbo].[vwTICKDB_TYPE]
WITH SCHEMABINDING
AS
	SELECT  [bbsecurity],[type],[src],[value],[delayed],[markethours],[tsbb],[ts],DATEDIFF(s,[tsbb],[ts]) as lag,convert(char(8),dateadd(s,datediff(s,[tsbb],[ts]),'1900-1-1'),8) as tsdiff
	from    (
			SELECT row_number() OVER (PARTITION BY [bbsecurity],[type] ORDER BY [tsbb] DESC,[ts] ASC) as rn
			,       [bbsecurity],[type],[src],[value],[delayed],[markethours],[tsbb],[ts]
			FROM    [dbo].[TICKDB_TYPE] 
			) as SubQueryAlias
	WHERE   rn = 1



GO
