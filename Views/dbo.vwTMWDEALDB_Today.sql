SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[vwTMWDEALDB_Today]
AS
SELECT *  FROM [TMDBSQL].[dbo].[TMWDEALDB] WHERE ts_end >  DATEDIFF(d,0,GETDATE()) or ts_start > DATEDIFF(d,0,GETDATE())
GO