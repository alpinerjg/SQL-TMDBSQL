SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[clean_tickdb_user]
	-- Add the parameters for the stored procedure here
	@src varchar(15)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	  DECLARE @datebb AS DATE
  
	SELECT @datebb = [datebb] FROM [TMDBSQL].[dbo].[vwPriorDate]

	BEGIN TRAN

	DELETE FROM [TMDBSQL].[dbo].[TICKDB]
		WHERE src=@src and CONVERT(DATE,[tsbb]) < @datebb

	DELETE FROM [TMDBSQL].[dbo].[TICKDB_COMBINED]
		WHERE src=@src and CONVERT(DATE,[tsbb]) < @datebb

	DELETE FROM [TMDBSQL].[dbo].[TICKDB_SRC]
		WHERE src=@src and CONVERT(DATE,[tsbb]) < @datebb

	DELETE FROM [TMDBSQL].[dbo].[TICKDB_TYPE]
		WHERE src=@src and CONVERT(DATE,[tsbb]) < @datebb

	COMMIT TRAN
END
GO
