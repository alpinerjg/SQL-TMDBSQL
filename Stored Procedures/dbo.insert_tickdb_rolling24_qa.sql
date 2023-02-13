SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[insert_tickdb_rolling24_qa] 
	@bbsecurity VARCHAR(32),
	@type CHAR(1),
	@src VARCHAR(15),
    @value DECIMAL(12,6),
	@delayed BIT,
	@markethours BIT,
	@tsbb DATETIME2 = NULL,
	@ts DATETIME2 = NULL,
	@return_status INT = 0 OUTPUT 
AS
BEGIN

-- Run legacy procedure (no input for "markethours")
EXEC @return_status = [dbo].[insert_tickdb_rolling24] @bbsecurity, @type, @src, @value, @delayed, @markethours, @tsbb, @ts 

END
GO
