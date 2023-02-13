SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spLiveByUser] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @cols AS NVARCHAR(MAX),
    @query  AS NVARCHAR(MAX)

	SELECT @cols = STUFF((SELECT distinct ',' + [src] 
                    from [TMDBSQL].[dbo].[TICKDB_TYPE]
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

	set @query = N'SELECT * FROM (
		SELECT [bbsecurity],[src],count([delayed]) AS [live]
		FROM [TMDBSQL].[dbo].[TICKDB_TYPE]
		WHERE type=''P'' and [delayed] = 0
		GROUP BY bbsecurity,src
	) x
	PIVOT (
		count(live) FOR src in (' + @cols + ')
	) p'

-- print @query
	exec (@query)
END
GO
