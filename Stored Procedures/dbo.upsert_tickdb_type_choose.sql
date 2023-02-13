SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[upsert_tickdb_type_choose] 
	@bbsecurity varchar(32),
	@type char(1),
	@src varchar(15),
    @value decimal(12,6),
	@delayed bit,
	@tsbb datetime2 = null,
	@ts datetime2 = null,
	@return_status int = 0 output 
AS
BEGIN
	EXECUTE upsert_tickdb_type2 
				@bbsecurity,
				@type,
				@src ,
				@value,
				@delayed,
				@tsbb,
				@ts,
				@return_status OUT
END
GO
