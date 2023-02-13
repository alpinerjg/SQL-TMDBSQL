SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetAsk] 
	-- Add the parameters for the stored procedure here
	@bbsecurity varchar(32),
	@ask decimal(12,6) = -1.0 output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXECUTE GetValue @bbsecurity,"A", @ask OUT

	RETURN
END
GO
