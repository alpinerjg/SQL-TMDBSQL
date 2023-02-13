SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[merge_TMWDEALDB_All]
AS
BEGIN
    DECLARE @TimeStamp Datetime = GETDATE();

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION merge_TMWDEALDB_All
	EXEC merge_TMWDEALDB @TimeStamp
	COMMIT TRANSACTION merge_TMWDEALDB_All
END
GO
