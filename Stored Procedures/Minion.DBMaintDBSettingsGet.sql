SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [Minion].[DBMaintDBSettingsGet]
(
@Module VARCHAR(25),
@DBName VARCHAR(400),
@OpName VARCHAR(50),
@SettingID INT OUTPUT,
@TestDateTime datetime = NULL
)

AS

SET NOCOUNT ON;

DECLARE @TodayDateCompare DATETIME,
		@TodayTimeCompare DATETIME;
	IF @TestDateTime IS NOT NULL
		BEGIN
			SET @TodayDateCompare =  @TestDateTime  --GETDATE();
			SET @TodayTimeCompare = @TodayDateCompare --GETDATE();
		END

	IF @TestDateTime IS NULL
		BEGIN
			SET @TodayDateCompare =  GETDATE();
			SET @TodayTimeCompare = @TodayDateCompare;
		END

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
---------------------------------------BEGIN CheckDB-------------------------
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

IF UPPER(@Module) = 'CHECKDB'
BEGIN --CHECKDB
DECLARE @CheckDBSettingLevel INT

CREATE TABLE #CheckDBSettingsDBDBMaintDBSettingsGet
(
	 ID   int  IDENTITY(1,1) NOT NULL,
	 SettingID INT NULL,
	 BeginTime VARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
	 EndTime VARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
	 DayOfWeek VARCHAR(10) COLLATE DATABASE_DEFAULT NULL
);

SET @CheckDBSettingLevel = (
                        SELECT COUNT(*)
                        FROM Minion.CheckDBSettingsDB
                        WHERE
                            DBName = @DBName
                            AND IsActive = 1
                    );

        IF @CheckDBSettingLevel > 0
            BEGIN		
                INSERT #CheckDBSettingsDBDBMaintDBSettingsGet
                        (
							SettingID,
							BeginTime,
							EndTime,
							DayOfWeek
						)
                    SELECT
							ID,
							BeginTime,
							EndTime,
							DayOfWeek
                        FROM
                            Minion.CheckDBSettingsDB
                        WHERE
                            DBName = @DBName 
							AND UPPER(OpName) = UPPER(@OpName)                           
                            AND IsActive = 1
		----------------------	  

            END
        IF @CheckDBSettingLevel = 0
            BEGIN
                INSERT #CheckDBSettingsDBDBMaintDBSettingsGet
                        (
							SettingID,
							BeginTime,
							EndTime,
							DayOfWeek
						)
                    SELECT
							ID,
							BeginTime,
							EndTime,
							DayOfWeek
                        FROM
                            Minion.CheckDBSettingsDB
                        WHERE
                            DBName = 'MinionDefault' 
							AND UPPER(OpName) = UPPER(@OpName)                           
                            AND IsActive = 1;
            END

-----------------------------------------------------------
-------------BEGIN Delete Unwanted Thresholds--------------
-----------------------------------------------------------

----Delete times first.
	BEGIN
		DELETE #CheckDBSettingsDBDBMaintDBSettingsGet WHERE NOT (CONVERT(VARCHAR(20), @TodayDateCompare, 114) BETWEEN CONVERT(VARCHAR(20), BeginTime, 114) AND CONVERT(VARCHAR(20), EndTime, 114)) AND (BeginTime IS NOT NULL AND EndTime IS NOT NULL)
	END

----If today is a Weekday of month then delete everything else.
IF (SELECT TOP 1 1 FROM #CheckDBSettingsDBDBMaintDBSettingsGet WHERE [DayOfWeek] = 'Weekday') = 1
BEGIN
	IF DATENAME(dw,@TodayDateCompare) IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
		BEGIN
			DELETE #CheckDBSettingsDBDBMaintDBSettingsGet WHERE ([DayOfWeek] NOT IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday') AND [DayOfWeek] <> 'Weekday' OR [DayOfWeek] IS NULL)
		END
END

----If today is a Weekend of month then delete everything else.
IF (SELECT TOP 1 1 FROM #CheckDBSettingsDBDBMaintDBSettingsGet WHERE [DayOfWeek] = 'Weekend') = 1
BEGIN
	IF DATENAME(dw,@TodayDateCompare) IN ('Saturday', 'Sunday')
		BEGIN
			DELETE #CheckDBSettingsDBDBMaintDBSettingsGet  WHERE ([DayOfWeek] NOT IN ('Saturday', 'Sunday') AND [DayOfWeek] <> 'Weekend' OR [DayOfWeek] IS NULL)
		END
END

----If there are records for today, then delete everything else.
IF EXISTS (SELECT 1 FROM #CheckDBSettingsDBDBMaintDBSettingsGet WHERE [DayOfWeek] = DATENAME(dw,@TodayDateCompare))
	BEGIN
		DELETE #CheckDBSettingsDBDBMaintDBSettingsGet WHERE [DayOfWeek] <> DATENAME(dw,@TodayDateCompare) OR [DayOfWeek] IS NULL
	END

------------------------BEGIN DELETE Named Days that Don't Match---------------
	--If there are named days, then delete everything that isn't the named day if the named day is today.
	--So if the named day is Friday and today is Monday, then it shouldn't be in the table.

			BEGIN
				DELETE #CheckDBSettingsDBDBMaintDBSettingsGet  WHERE ([DayOfWeek] IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') 
				AND [DayOfWeek] <> DATENAME(dw, @TodayDateCompare))
			END
------------------------END DELETE Named Days that Don't Match-----------------

----If there are NO records for today, then delete the days that aren't null so we can be left with only NULLs.
IF EXISTS (SELECT 1 FROM #CheckDBSettingsDBDBMaintDBSettingsGet WHERE [BeginTime] IS NOT NULL)
	BEGIN
		DELETE #CheckDBSettingsDBDBMaintDBSettingsGet WHERE [BeginTime] IS NULL
	END

-----------------------------------------------------------
-------------END Delete Unwanted Thresholds----------------
-----------------------------------------------------------

SET @SettingID = (SELECT TOP 1 SettingID FROM #CheckDBSettingsDBDBMaintDBSettingsGet)

END --CHECKDB
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
---------------------------------------END CheckDB---------------------------
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------


GO
