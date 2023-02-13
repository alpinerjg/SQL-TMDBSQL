SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	https://stackoverflow.com/questions/24213299/how-to-delete-large-data-of-table-in-sql-without-log
-- =============================================
CREATE PROCEDURE [dbo].[clean_tickdb_rolling24] 
AS
BEGIN

DECLARE @Deleted_Rows INT;
SET @Deleted_Rows = 10000;

WHILE (@Deleted_Rows = 10000)
  BEGIN

   BEGIN TRANSACTION

   -- SELECT COUNT(*) FROM [TMDBSQL].[dbo].[TICKDB_ROLLING24] WHERE [ts] < DATEADD(d,-1,GETDATE()) AND type='P' 
   -- SELECT TOP 10 * FROM [TMDBSQL].[dbo].[TICKDB_ROLLING24] ORDER BY ts ASC
   -- SELECT COUNT(*) AS cnt FROM [TMDBSQL].[dbo].[TICKDB_ROLLING24] WHERE [ts] < DATEADD(d,-1,GETDATE())
   -- SELECT DATEADD(d,-1,GETDATE())
   --
   -- Delete some small number of rows at a time
     DELETE TOP (10000)  [TMDBSQL].[dbo].[TICKDB_ROLLING24] 
     WHERE [ts] < DATEADD(d,-1,GETDATE())

     SET @Deleted_Rows = @@ROWCOUNT;

   COMMIT TRANSACTION
   CHECKPOINT -- for simple recovery model
END

ALTER INDEX ALL ON [TMDBSQL].[dbo].[TICKDB_ROLLING24]  REBUILD

END
GO
