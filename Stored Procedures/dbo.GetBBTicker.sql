SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetBBTicker] 
	-- Add the parameters for the stored procedure here
	@symbol VARCHAR(32),
	@bbsecurity VARCHAR(32) = '' OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- SELECT [bbsecurity] FROM [TMDBSQL].[dbo].[SymbolMap] WHERE [symbol] = 'IBM' AND [ts_end] IS NULL

	SELECT @bbsecurity = [bbsecurity] FROM [TMDBSQL].[dbo].[SymbolMap] WHERE [symbol] = @symbol AND [ts_end] IS NULL
	PRINT @symbol + ' = ' + @bbsecurity
	RETURN
END
GO
