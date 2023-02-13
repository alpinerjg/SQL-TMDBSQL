SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetValue1] 
	-- Add the parameters for the stored procedure here
	@bbsecurity varchar(32),
	@type char(1),
	@value decimal(12,6) = -1.0 output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT TOP(1) @value = [value] FROM [TMDBSQL].[dbo].[TICKDB_TYPE] WHERE [bbsecurity] = @bbsecurity and [type] = @type ORDER BY [tsbb] DESC
	PRINT @bbsecurity + ' ' + @type + ' = ' + CAST(@value as varchar)
	RETURN
END
GO
