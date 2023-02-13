SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[insert_tickdb_lag_history]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
DECLARE @TS AS Datetime
DECLARE @bbsecurity AS VARCHAR(32)
DECLARE @CNT AS INTEGER
DECLARE @MAXLAG AS INTEGER
DECLARE @AvgTop1PctLag AS INTEGER
DECLARE @AvgTop5PctLag AS INTEGER
DECLARE @AvgTop10PctLag AS INTEGER
DECLARE @AvgTop25PctLag AS INTEGER
DECLARE @AVGLAG AS INTEGER

SELECT @TS = DATEADD(mi, datediff(mi, 0, dateadd(s, 30, GETDATE())), 0)
SELECT TOP 1 @bbsecurity = bbsecurity FROM dbo.vwTICKDB_TYPE WHERE type = 'P' AND delayed = 0 ORDER BY LAG DESC
SELECT @CNT = COUNT(LAG), @AVGLAG =  AVG(LAG), @MAXLAG = MAX(LAG) FROM  dbo.vwTICKDB_TYPE WHERE type = 'P' AND delayed = 0
SELECT @AvgTop1PctLag = AVG(AvgTop1PctLag.LAG) FROM (SELECT TOP 1 PERCENT LAG FROM dbo.vwTICKDB_TYPE WHERE type = 'P' AND delayed = 0 ORDER BY LAG DESC) AvgTop1PctLag
SELECT @AvgTop5PctLag = AVG(AvgTop5PctLag.LAG) FROM (SELECT TOP 5 PERCENT LAG FROM dbo.vwTICKDB_TYPE WHERE type = 'P' AND delayed = 0 ORDER BY LAG DESC) AvgTop5PctLag
SELECT @AvgTop10PctLag = AVG(AvgTop10PctLag.LAG) FROM (SELECT TOP 10 PERCENT LAG FROM dbo.vwTICKDB_TYPE WHERE type = 'P' AND delayed = 0 ORDER BY LAG DESC) AvgTop10PctLag
SELECT @AvgTop25PctLag = AVG(AvgTop25PctLag.LAG) FROM (SELECT TOP 25 PERCENT LAG FROM dbo.vwTICKDB_TYPE WHERE type = 'P' AND delayed = 0 ORDER BY LAG DESC) AvgTop25PctLag

BEGIN TRANSACTION

IF NOT EXISTS(SELECT 1 FROM [TMDBSQL].[dbo].[TICKDB_LAG_HISTORY] WHERE ts = @ts)
BEGIN
    INSERT INTO [TMDBSQL].[dbo].[TICKDB_LAG_HISTORY]
           (ts, bbsecurity, cnt , maxlag , avgtop1pctlag , avgtop5pctlag , avgtop10pctlag , avgtop25pctlag , avglag )
    VALUES
           (@ts, @bbsecurity, @cnt , @maxlag , @avgtop1pctlag , @avgtop5pctlag , @avgtop10pctlag , @avgtop25pctlag , @avglag )
END

COMMIT TRANSACTION
END
GO
