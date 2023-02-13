SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[clean_BroadridgePositions]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	TRUNCATE TABLE [TMDBSQL].[dbo].[BroadridgePositions]
	TRUNCATE TABLE [TMDBSQL].[dbo].[BroadridgePositions_staging]
	TRUNCATE TABLE [TMDBSQL].[dbo].[BroadridgePositionsCustom]
	TRUNCATE TABLE [TMDBSQL].[dbo].[BroadridgePositionsMarket]
	TRUNCATE TABLE [TMDBSQL].[dbo].[BroadridgePositionsOther]
	TRUNCATE TABLE [TMDBSQL].[dbo].[BroadridgePositionsPosition]
	TRUNCATE TABLE [TMDBSQL].[dbo].[BroadridgePositionsSecurity]
	TRUNCATE TABLE [TMDBSQL].[dbo].[BroadridgePositionsStrategy]

END
GO
