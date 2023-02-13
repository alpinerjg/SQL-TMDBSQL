SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[insert_gridsparklines] 
	@return_status INT = 0 OUTPUT 
AS
BEGIN

DECLARE @todayStart AS date = (cast(GETDATE() as date))

-- DECLARE @return_status int;
SET @return_status = 0;

BEGIN TRANSACTION

DECLARE @tsNew datetime2 = (SELECT TOP 1 UpdateTime FROM vwGRID);
DECLARE @tsMax datetime2 = (SELECT TOP 1 Max(UpdateTime) as UpdateTime FROM [dbo].GRIDSPARKLINES);

IF (@tsNew != @tsMax OR @tsMax is null)
	BEGIN
		--PRINT N'Differ';
		INSERT INTO [dbo].GRIDSPARKLINES (Fund,Account,UpdateTime,DayPL,MonthPL,YearPL)
			SELECT Fund,Account,UpdateTime,DayPL,MonthPL,YearPL FROM vwGRID
	END;
ELSE
    BEGIN
--		PRINT N'No Change';
		SET @return_status = 1;
	END;

DELETE FROM [dbo].GRIDSPARKLINES WHERE UpdateTime < @todayStart

COMMIT TRANSACTION

END
GO
