SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	https://stackoverflow.com/questions/24213299/how-to-delete-large-data-of-table-in-sql-without-log
-- =============================================
CREATE PROCEDURE [dbo].[clean_tickdb_rolling24_qa] 
AS
BEGIN

DECLARE @Deleted_Rows INT;
SET @Deleted_Rows = 10000;

WHILE (@Deleted_Rows = 10000)
  BEGIN

   BEGIN TRANSACTION

   -- Delete some small number of rows at a time
     DELETE TOP (10000)  [TMDBSQL].[dbo].[tickdb_rolling24_qa] 
     WHERE [ts] < DATEADD(d,-1,GETDATE())

     SET @Deleted_Rows = @@ROWCOUNT;

   COMMIT TRANSACTION
   CHECKPOINT -- for simple recovery model
END

ALTER INDEX ALL ON [TMDBSQL].[dbo].[tickdb_rolling24_qa]  REBUILD

END
GO
