SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Alpine Symbol to Bloomberg Ticker mapping>
-- =============================================
CREATE PROCEDURE [dbo].[upsert_symbol_map] 
	@symbol varchar(32),
	@bbsecurity varchar(32),
	@ts datetime2 = null,
	@return_status int = 0 output 
AS
BEGIN

IF (@bbsecurity <> '')
    BEGIN

		-- DECLARE @ts datetime2;
		IF (@ts IS NULL)
			SET @ts = SYSDATETIME()

		-- DECLARE @return_status int;
		SET @return_status = 0;

		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
		BEGIN TRANSACTION

		-- Check to see if we already have the bb symbol
		IF EXISTS(SELECT 1 FROM dbo.SymbolMap WHERE symbol = @symbol)
			BEGIN
				-- Only update if the bbsecurity has changed
				IF NOT(EXISTS(SELECT 1 FROM dbo.SymbolMap WHERE symbol = @symbol AND bbsecurity = @bbsecurity AND ts_end IS NULL))
					BEGIN
						UPDATE dbo.SymbolMap WITH (SERIALIZABLE)
							SET ts_end = @ts
							WHERE symbol = @symbol and ts_end IS NULL

						INSERT INTO dbo.SymbolMap
							(symbol, bbsecurity, ts_start, ts_end)
						VALUES 
							(@symbol, @bbsecurity, @ts, NULL)
						SET @return_status = 1
					END
			END
		ELSE
			BEGIN
			 -- new record
				INSERT INTO dbo.SymbolMap
					(symbol, bbsecurity, ts_start, ts_end)
				VALUES 
					(@symbol, @bbsecurity, @ts, NULL)
				SET @return_status = 1
			END

		COMMIT TRANSACTION
	END
END
GO
