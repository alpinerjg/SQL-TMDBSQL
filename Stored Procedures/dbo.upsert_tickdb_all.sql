SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[upsert_tickdb_all] 
	@bbsecurity varchar(32),
      @price decimal(12,6),
	  @bid decimal(12,6) = null,
	  @ask decimal(12,6) = null,
	  @delayed bit,
	  @src varchar(15),
	  @tsbb datetime2 = null,
	  @return_status int = 0 output 
AS
BEGIN

-- DO NOTHING!
SET @return_status = 0
RETURN @return_status

END
GO
