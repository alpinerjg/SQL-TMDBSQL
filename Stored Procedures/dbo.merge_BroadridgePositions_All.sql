SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Robert Gusick
-- Create date: April 9, 2021
-- Description:	Move all BroadridgePositions staging table to SCDT2
-- =============================================
CREATE PROCEDURE [dbo].[merge_BroadridgePositions_All]
AS
BEGIN
    DECLARE @TimeStamp Datetime = GETDATE();

	-- ETL
	UPDATE [TMDBSQL].[dbo].[BroadridgePositions_staging]
	SET CustomStrategyCode = CONCAT(' ' , CustomStrategyCode)
	WHERE CustomStrategyCode like '[0-9][0-9][0-9]'

	BEGIN TRANSACTION merge_BroadridgePositions_All

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	EXEC merge_BroadridgePositions @TimeStamp
	EXEC merge_BroadridgePositions_Custom @TimeStamp
	EXEC merge_BroadridgePositions_Market @TimeStamp
	EXEC merge_BroadridgePositions_Other @TimeStamp
	EXEC merge_BroadridgePositions_Position @TimeStamp
	EXEC merge_BroadridgePositions_Security @TimeStamp
	EXEC merge_BroadridgePositions_Strategy @TimeStamp

	COMMIT TRANSACTION merge_BroadridgePositions_All
END
GO
