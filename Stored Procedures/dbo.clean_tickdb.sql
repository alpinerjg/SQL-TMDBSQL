SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[clean_tickdb]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @PREV_BUS_DAY DATETIME2
	
	SELECT @PREV_BUS_DAY = DATEADD(DAY, CASE (DATEPART(WEEKDAY, GETDATE()) + @@DATEFIRST) % 7 
                        WHEN 1 THEN -2 
                        WHEN 2 THEN -3 
                        ELSE -1 
                    END, DATEDIFF(DAY, 0, GETDATE()));

	DELETE
		FROM [TMDBSQL].[dbo].[TICKDB]
		WHERE tsbb < @PREV_BUS_DAY

	DELETE
		FROM [TMDBSQL].[dbo].[TICKDB_TYPE]
		WHERE tsbb < @PREV_BUS_DAY

END
GO
