SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[upsert_badsecurity] 
	@bbsecurity varchar(32),
    @symbol varchar(15),
    @description varchar(64),
	@return_status int = 0 output 
AS
BEGIN

DECLARE @today date
IF (@today IS NULL)
	SET @today = CONVERT(date, getdate())

-- DECLARE @return_status int;
SET @return_status = 0;

BEGIN TRANSACTION

-- This stored procedure should be simple and fast

-- Check to see if we already have a record
IF EXISTS(SELECT 1 FROM dbo.BADSECURITY WHERE bbsecurity = @bbsecurity AND symbol = @symbol)
	BEGIN
	    -- Even if it's there, make sure that it's more recent
		IF EXISTS(SELECT 1 FROM dbo.BADSECURITY WHERE bbsecurity = @bbsecurity AND symbol = @symbol AND mostrecent < @today)
			BEGIN
				UPDATE dbo.BADSECURITY WITH (SERIALIZABLE)
					SET description = @description,  mostrecent = @today
					WHERE bbsecurity = @bbsecurity AND symbol = @symbol
				SET @return_status = 1
			END
	END
ELSE
	BEGIN
     -- new record
		INSERT INTO dbo.BADSECURITY
			(bbsecurity, symbol, description, firstseen, mostrecent)
		VALUES
			(@bbsecurity, @symbol, @description, @today, @today)
		SET @return_status = 1
	END

COMMIT TRANSACTION

-- PRINT @bbsecurity
-- PRINT @return_status
-- RETURN @return_status

END
GO
