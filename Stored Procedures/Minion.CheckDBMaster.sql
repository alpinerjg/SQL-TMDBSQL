SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [Minion].[CheckDBMaster]
(
@DBType VARCHAR(6) = 'User',
@OpName VARCHAR(50) = NULL,
@StmtOnly BIT = 0, -- Valid options: 1, 0. Only prints reindex stmts.
@ReadOnly TINYINT = 1,
@Schemas NVARCHAR(max) = NULL, -- Only valid for single DBs unless all DBs have the same objects. Can be a list.  Will check all tables in this schema.
@Tables NVARCHAR(max) = NULL, -- Only valid for single DBs unless all DBs have the same objects. Does all tables
@Include NVARCHAR(2000) = NULL, --Process ONLY these DBs.  comma-separated like this : DB1,DB2,DB3
@Exclude NVARCHAR(2000) = NULL,
@NumConcurrentProcesses tinyint = 1,
@DBInternalThreads TINYINT = NULL,
@TestDateTime DATETIME = NULL,
@TimeLimitInMins INT = NULL,
@FailJobOnError BIT = 0,
@FailJobOnWarning BIT = 0,
@Debug bit = 0
)

AS

/***********************************************************************************

Created By: MinionWare LLC. and MidnightDBA.com

Minion CheckDB is a free, standalone, integrity check routine that is a component 
of the Minion Enterprise management solution. Home base: http://MinionWare.net/CheckDB

Minion Enterprise is an enterprise management solution that makes managing your 
SQL Server enterprise super easy. The CheckDB routine folds into the enterprise 
solution with ease.  By integrating your integration checks into the Minion 
Enterprise, you get the ability to manage your configuration from a central 
location. And, Minion Enterprise provides enterprise-level reporting and alerting.
Download a 30-day trial of Minion Enterprise at http://MinionWare.net


For SQL Server consulting, see our website http://www.MidnightSQL.com
No job is too big or too small.

Also, check out our FREE SQL Server training videos at http://www.MidnightDBA.com

This is a big routine with many nuances.  Our documentation is complete, but if 
you prefer, we also have videos that show you how to use each of the features.
You can find them at http://www.MidnightDBA.com/Minion

* By running this software you are agreeing to the terms of the license agreement.
* You can find a copy of the license agreement here: http://www.midnightsql.com/minion-end-user-license-agreement/
--------------------------------------------------------------------------------

HELP: For information on parameters and more, see the documentation at
                  http://www.MinionWare.net/CheckDB, or with the product download, or use
                
                EXEC Minion.HELP 'CHECKDB', 'Minion.CheckDBMaster';


PURPOSE: 


WALKTHROUGH: 
      1. 


CONVENTIONS:
    
    
TABLES: 
                

EXAMPLE EXECUTIONS:


REVISION HISTORY:
                

--***********************************************************************************/ 


SET NOCOUNT ON;
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
---------------------------------BEGIN Define Schedule----------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----If the incoming vars are NULL then we get the value from the SettingsServer table.
DECLARE @ExecutionDateTime DATETIME;
IF @TestDateTime IS NULL
	BEGIN
		SET @TestDateTime = GETDATE();
	END
SET @ExecutionDateTime = @TestDateTime;

IF @OpName IS NULL
	BEGIN --Define Schedule

	SET @NumConcurrentProcesses = NULL;
	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------BEGIN Reset Counter------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	----The counters are per day, so if it's a new day we'll have to reset them.
	UPDATE Minion.CheckDBSettingsServer
	SET CurrentNumOps = 0
	WHERE (CONVERT(VARCHAR(10), LastRunDateTime, 101) <> CONVERT(VARCHAR(10), GETDATE(), 101) OR LastRunDateTime IS NULL)
	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------END Reset Counter--------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------


	CREATE TABLE #CheckDBMasterParams
	(
		ID INT IDENTITY(1,1) NOT NULL,
		SettingServerID INT,
		DBType VARCHAR(6) COLLATE DATABASE_DEFAULT,
		OpName VARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
		Day VARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
		ReadOnly TINYINT NULL,
		BeginTime VARCHAR(20) NULL,
		EndTime VARCHAR(20) NULL,
		MaxForTimeframe INT NULL,
		FrequencyMins INT NULL,
		CurrentNumOps INT NULL,
		NumConcurrentOps INT NULL,
		DBInternalThreads TINYINT NULL,
		TimeLimitInMins INT NULL,
		LastRunDateTime DATETIME NULL,
		Include NVARCHAR(2000) COLLATE DATABASE_DEFAULT NULL,
		Exclude NVARCHAR(2000) COLLATE DATABASE_DEFAULT NULL,
		[Schemas] NVARCHAR(2000) COLLATE DATABASE_DEFAULT NULL,
		[Tables] NVARCHAR(2000) COLLATE DATABASE_DEFAULT NULL,
		--SyncSettings BIT NULL,   !!!!!!!!!!!!!!!need time and DBInternalThreads cols.
		--SyncLogs BIT NULL,
		BatchPreCode VARCHAR(MAX) COLLATE DATABASE_DEFAULT NULL,
		BatchPostCode VARCHAR(MAX) COLLATE DATABASE_DEFAULT NULL,
		Debug BIT,
		FailJobOnError BIT,
		FailJobOnWarning BIT
	)

DECLARE 
		@MaxforTimeframe INT,
		@FirstOfMonth DATETIME,
		@LastOfMonth DATETIME,
		@FirstOfYear DATETIME,
		@LastOfYear DATETIME,
		@IsFirstOfMonth BIT,
		@IsLastOfMonth BIT,
		@IsFirstOfYear BIT,
		@IsLastOfYear BIT,
		@Today DATETIME,
		@BatchPreCode VARCHAR(MAX),
		@BatchPostCode VARCHAR(MAX),
		@SettingServerID INT,
		@MasterParamID INT,
		@TodayDateCompare DATETIME,
		@TodayTimeCompare DATETIME;

	SET @IsFirstOfMonth = 0;
	SET @IsLastOfMonth = 0;
	SET @IsFirstOfYear = 0;
	SET @IsLastOfYear = 0;

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
	--SELECT DATENAME(dw, @TodayDateCompare) AS tDay
	SET @Today = CONVERT(VARCHAR(10), @TodayDateCompare, 101)
	SET @FirstOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TodayDateCompare), 0)
	SET @LastOfMonth = CONVERT(VARCHAR(10), (DATEADD(DAY, -(DAY(DATEADD(MONTH, 1, @TodayDateCompare))), DATEADD(MONTH, 1, @TodayDateCompare))), 101)
	SET @FirstOfYear = DATEADD(YEAR, DATEDIFF(YEAR, 0, @TodayDateCompare), 0)
	SET @LastOfYear = DATEADD(dd, -1, DATEADD(yy, DATEDIFF(yy,0,@TodayDateCompare) + 1, 0))

	--SET @Today = CONVERT(VARCHAR(10), '2016-02-01 11:01:37.890', 101)
	--SET @FirstOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, '2016-02-01 11:01:37.890'), 0)
	--SET @LastOfMonth = CONVERT(VARCHAR(10), (DATEADD(DAY, -(DAY(DATEADD(MONTH, 1, '2016-02-01 11:01:37.890'))), DATEADD(MONTH, 1, '2016-02-29 11:01:37.890'))), 101)
	--SET @FirstOfYear = DATEADD(YEAR, DATEDIFF(YEAR, 0, '2016-02-01 11:01:37.890'), 0)
	--SET @LastOfYear = DATEADD(dd, -1, DATEADD(yy, DATEDIFF(yy,0,'2016-02-01 11:01:37.890') + 1, 0))

	IF @Today = @FirstOfMonth
	BEGIN
		SET @IsFirstOfMonth = 1;
	END

	IF @Today = @LastOfMonth
	BEGIN
		SET @IsLastOfMonth = 1;
	END

	IF @Today = @FirstOfYear
	BEGIN
		SET @IsFirstOfYear = 1;
	END

	IF @Today = @LastOfYear
	BEGIN
		SET @IsLastOfYear = 1;
	END
--SELECT @IsFirstOfMonth AS IsFirstOfMonth, @IsLastOfMonth AS IsLastOfMonth
	---------------------------------------------------
	----------BEGIN Insert All Rows--------------------
	---------------------------------------------------
	BEGIN
	INSERT #CheckDBMasterParams (SettingServerID, DBType, OpName, Day, ReadOnly, BeginTime, EndTime, MaxForTimeframe, FrequencyMins, CurrentNumOps, NumConcurrentOps, DBInternalThreads, TimeLimitInMins, LastRunDateTime, Include, Exclude, [Schemas], [Tables], BatchPreCode, BatchPostCode, Debug)
		SELECT
			ID, DBType, OpName, Day, ReadOnly, BeginTime, EndTime, MaxForTimeframe, FrequencyMins, CurrentNumOps, NumConcurrentOps, DBInternalThreads, TimeLimitInMins, LastRunDateTime, Include, Exclude, [Schemas], [Tables], BatchPreCode, BatchPostCode, Debug
			FROM Minion.CheckDBSettingsServer
			WHERE IsActive = 1 ----AND ISNULL(CurrentNumBackups, 0) < MaxForTimeframe;
	END

	---------------------------------------------------
	----------END Insert All Rows----------------------
	---------------------------------------------------

	---------------------------------------------------
	-----------------BEGIN Delete Rows-----------------
	---------------------------------------------------
	---Deletes times first.  Anything that doesn't fall in the timeslot automatically gets whacked.
		BEGIN
			DELETE #CheckDBMasterParams WHERE NOT (CONVERT(VARCHAR(20), @TodayTimeCompare, 114) BETWEEN CONVERT(VARCHAR(20), BeginTime, 114) AND CONVERT(VARCHAR(20), EndTime, 114)) AND (BeginTime IS NOT NULL AND EndTime IS NOT NULL)
		END
	---Delete frequencies.  Anything that is too soon to backup needs to go.
		BEGIN
			DELETE #CheckDBMasterParams WHERE DATEDIFF(MINUTE, LastRunDateTime, @TodayTimeCompare) < FrequencyMins AND FrequencyMins IS NOT NULL;
		END

--SELECT 'After initial delete', * FROM #CheckDBMasterParams
	-----------------------------BEGIN All High-level Settings-----------------------------
	----If today is Beginning of year then delete everything else.
	IF @IsFirstOfYear = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM #CheckDBMasterParams WHERE [Day] = 'FirstOfYear')
			BEGIN
				DELETE #CheckDBMasterParams  
				WHERE [Day] <> 'FirstOfYear' 
				AND DBType = 'User'
				AND Include IN (SELECT Include FROM #CheckDBMasterParams WHERE [Day] = 'FirstOfYear')
			END
	END

	----If today is End of year then delete everything else.
	IF @IsLastOfYear = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM #CheckDBMasterParams WHERE [Day] = 'LastOfYear')
			BEGIN
				DELETE #CheckDBMasterParams  
				WHERE [Day] <> 'LastOfYear' 
				AND DBType = 'User'
				AND Include IN (SELECT Include FROM #CheckDBMasterParams WHERE [Day] = 'LastOfYear')
			END
	END

	----If today is Beginning of month then delete everything else.
	IF @IsFirstOfMonth = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM #CheckDBMasterParams WHERE [Day] = 'FirstOfMonth')
			BEGIN
				DELETE #CheckDBMasterParams  
				WHERE [Day] <> 'FirstOfMonth' 
				AND DBType = 'User'
				AND Include IN (SELECT Include FROM #CheckDBMasterParams WHERE [Day] = 'FirstOfMonth')
			END
	END

	----If today is End of month then delete everything else.
	IF @IsLastOfMonth = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM #CheckDBMasterParams WHERE [Day] = 'LastOfMonth')
			BEGIN
				DELETE #CheckDBMasterParams  
				WHERE [Day] <> 'LastOfMonth' 
				AND DBType = 'User'
				AND Include IN (SELECT Include FROM #CheckDBMasterParams WHERE [Day] = 'LastOfMonth')
			END
	END

------------------------------------------------------------------------
---------------------BEGIN DELETE High-levels---------------------------
------------------------------------------------------------------------
--If it's not one of these high-level days, they need to be deleted.
--You can't run a FirstOfMonth if it's not the 1st of the month now can you?
IF @IsFirstOfYear = 0
	BEGIN
		DELETE #CheckDBMasterParams  
		WHERE [Day] = 'FirstOfYear' 
	END

IF @IsLastOfYear = 0
	BEGIN
		DELETE #CheckDBMasterParams  
		WHERE [Day] = 'LastOfYear' 
	END

IF @IsFirstOfMonth = 0
	BEGIN
		DELETE #CheckDBMasterParams  
		WHERE [Day] = 'FirstOfMonth' 
	END

IF @IsLastOfMonth = 0
	BEGIN
		DELETE #CheckDBMasterParams  
		WHERE [Day] = 'LastOfMonth' 
	END
--SELECT 'After high levels', * FROM #CheckDBMasterParams
------------------------------------------------------------------------
---------------------END DELETE High-levels-----------------------------
------------------------------------------------------------------------


------------------------BEGIN DELETE Named Days that Don't Match---------------
	--If there are named days, then delete everything that isn't the named day if the named day is today.
	--So if the named day is Friday and today is Monday, then it shouldn't be in the table.

			----IF EXISTS (SELECT 1 FROM #MasterParams WHERE [Day] = DATENAME(dw, @TodayDateCompare) AND CurrentNumBackups >= MaxForTimeframe)
			BEGIN
				DELETE #CheckDBMasterParams  WHERE ([Day] IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') 
				AND [Day] <> DATENAME(dw, @TodayDateCompare))
			END
--SELECT 'After names', * FROM #CheckDBMasterParams
------------------------END DELETE Named Days that Don't Match-----------------

------------------------BEGIN DELETE Higher-level days when Today has run---------------
	--If there are named days, then delete everything that isn't the named day if the named day is today.
	--So if the named day is Friday and today is Monday, then it shouldn't be in the table.

			IF EXISTS (SELECT 1 FROM #CheckDBMasterParams WHERE [Day] = DATENAME(dw, @TodayDateCompare) AND CurrentNumOps >= MaxForTimeframe)
			BEGIN
				DELETE MP1
				FROM #CheckDBMasterParams MP1
				WHERE MP1.[Day] IN ('Daily', 'Weekend', 'Weekday') 
				AND MP1.OpName IN (SELECT OpName FROM #CheckDBMasterParams MP2 WHERE [Day] = DATENAME(dw, @TodayDateCompare) AND CurrentNumOps >= MaxForTimeframe)
			END
--SELECT 'After high-level days', * FROM #CheckDBMasterParams
------------------------END DELETE Higher-level days when Today has run-----------------


IF (@IsLastOfMonth = 0 AND @IsFirstOfMonth = 0 AND @IsFirstOfYear = 0 AND @IsLastOfYear = 0)
OR NOT EXISTS (SELECT 1 FROM #CheckDBMasterParams WHERE UPPER(Day) IN ('FIRSTOFYEAR', 'FIRSTOFMONTH', 'LASTOFYEAR', 'LASTOFMONTH'))
	BEGIN -- Delete Days
		----I think this entire section should only be called if all of the above conditions are true.  
		----Those higher level settings should always override these daily settings.
	----If today is a Weekday then delete everything else.
	--IF (SELECT 1 FROM #MasterParams WHERE [Day] = 'Weekday') = 1 --Removed as 1.1 fix
	BEGIN
		IF DATENAME(dw, @TodayDateCompare) IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
			BEGIN
				DELETE #CheckDBMasterParams  WHERE ([Day] NOT IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday') AND [Day] <> 'Weekday' AND [Day] <> 'Daily') AND DBType = 'User'-- Fix for 1.1: Added "AND [Day] <> 'Daily'" because it was deleting Daily rows when it shouldn't be.
			END
	END

	----If today is a Weekend then delete everything else.
	--IF (SELECT 1 FROM #MasterParams WHERE [Day] = 'Weekend') = 1 --Removed as 1.1 fix
	BEGIN
		IF DATENAME(dw, @TodayDateCompare) IN ('Saturday', 'Sunday')
			BEGIN
				DELETE #CheckDBMasterParams  WHERE ([Day] NOT IN ('Saturday', 'Sunday') AND [Day] <> 'Weekend' AND [Day] <> 'Daily') AND DBType = 'User'-- Fix for 1.1: Added "AND [Day] <> 'Daily'" because it was deleting Daily rows when it shouldn't be.
			END
	END

--SELECT 'After weekend stuff', * FROM #CheckDBMasterParams
	-----------------------------END All High-level Settings-------------------------------



	----If there are records for today, then delete everything else.
	IF EXISTS (SELECT 1 FROM #CheckDBMasterParams WHERE [Day] = DATENAME(dw, @TodayDateCompare))
		BEGIN
			DELETE #CheckDBMasterParams WHERE [Day] <> DATENAME(dw, @TodayDateCompare) OR [Day] IS NULL
		END

	----Now we should be down to just the daily runs if so, then delete everything else.
	IF EXISTS (SELECT 1 FROM #CheckDBMasterParams WHERE [Day] = 'Daily')
		BEGIN
			DELETE #CheckDBMasterParams WHERE [Day] IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
		END
	END -- Delete Days
--SELECT 'After daily', * FROM #CheckDBMasterParams

	DELETE #CheckDBMasterParams
	WHERE ISNULL(CurrentNumOps, 0) >= MaxForTimeframe;
	---------------------------------------------------
	-----------------END Delete Rows-------------------
	---------------------------------------------------

	---------------------------------------------------
	-------------BEGIN Set Vars------------------------
	---------------------------------------------------

		BEGIN
			SELECT TOP 1
		   @MasterParamID = ID,
		   @SettingServerID = SettingServerID,
		   @DBType = DBType,
		   @MaxforTimeframe = MaxForTimeframe,
		   @NumConcurrentProcesses = ISNULL(NumConcurrentOps, 1),---This var is the problem...
		   @OpName = OpName,
		   @DBInternalThreads = DBInternalThreads,
		   @TimeLimitInMins = TimeLimitInMins,
		   @ReadOnly = ReadOnly,
		   @Include = Include,
		   @Exclude = Exclude,
		   @Schemas = [Schemas],
		   @Tables = [Tables],
		   ----@SyncSettings = SyncSettings,
		   ----@SyncLogs = SyncLogs,
		   @BatchPreCode = BatchPreCode,
		   @BatchPostCode = BatchPostCode,
		   @Debug = Debug,
		   @FailJobOnError = FailJobOnError,
		   @FailJobOnWarning = FailJobOnWarning
	FROM #CheckDBMasterParams
	ORDER BY DBType ASC, OpName ASC
		END

----This is here to show which schedule was picked. It's a great way to tshoot the process.
SELECT * 
FROM #CheckDBMasterParams WHERE ID = @MasterParamID
---------------------------------------------------
-------------END Set Vars--------------------------
---------------------------------------------------

END --Define Schedule

----------------------------------------------------------------------------------
-----------------BEGIN Update CheckDBSettingsServer-------------------------------
----------------------------------------------------------------------------------

If @StmtOnly = 0
BEGIN
	----We don't want to increment the table row if there are no rows to run.
	IF @MasterParamID IS NOT NULL
		BEGIN
			UPDATE Minion.CheckDBSettingsServer
			SET CurrentNumOps = ISNULL(CurrentNumOps, 0) + 1,
				LastRunDateTime = GETDATE()
			WHERE ID = @SettingServerID;
		END

END
----------------------------------------------------------------------------------
-----------------END Update CheckDBSettingsServer---------------------------------
----------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
---------------------------------END Define Schedule------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

IF @StmtOnly = 0 AND @OpName IS NULL
	BEGIN
		RETURN;
	END


----You can only print a stmt if you're running a single thread.
----Here we choose to enforce that instead of throwing an error because
----the intent is clear... to get a stmt.
IF @StmtOnly = 1
	BEGIN
		SET @NumConcurrentProcesses = 1;
	END

--RETURN;
    DECLARE 
		@OpNameOrig VARCHAR(100),
		@currDB VARCHAR(100) ,
        @currTables VARCHAR(10) ,
        @currStmtOnly BIT ,
        @DBName VARCHAR(100) ,
        @SQL NVARCHAR(200) ,
		@ExecutionEndDateTime DATETIME,
        @IncludeRAW VARCHAR(2000) ,
        @ExcludeRAW VARCHAR(2000),
		@RegexCT SMALLINT,
		@LogDBType VARCHAR(6),
		@VersionRaw VARCHAR(50),
		@Version DECIMAL(3,1),
		@Edition VARCHAR(15),
		@IsPrimaryReplica BIT,
		@Status VARCHAR(MAX),
		@ServiceStatus BIT,
		@MonitorJobRunning BIT,
		@SettingLevel INT,
		@PreferredServer VARCHAR(150),
		@IsPrefferedReplica BIT,
		@DBIsInAG BIT,
		@DBIsInAGQuery VARCHAR(4000),
		@IsPrimaryReplicaQuery VARCHAR(4000),
		@Port VARCHAR(10),
        @PreCMD VARCHAR(100),
        @TotalCMD VARCHAR(2000),
		--@BackupCmd VARCHAR(2000),
        @ServerInstance VARCHAR(200),
		--@BatchPreCode VARCHAR(MAX),
		--@BatchPostCode VARCHAR(MAX),
		@BatchPreCodeStartDateTime DATETIME,
		@BatchPreCodeEndDateTime DATETIME,
		@BatchPreCodeTimeInSecs INT,
		@BatchPostCodeStartDateTime DATETIME,
		@BatchPostCodeEndDateTime DATETIME,
		@BatchPostCodeTimeInSecs INT,
		@BackupLogID BIGINT,
		@BackupLogDetailsID BIGINT,
		@BackupDBErrors VARCHAR(MAX),
		--@IsMissing BIT,
		--@ReadOnly TINYINT,
		@PrepOnly BIT,
		@RunPrepped BIT,
		@DBInternalThreadsORIG TINYINT,
		@jobId binary(16),
		@DBSize DECIMAL(18, 2),
		@SettingID INT,
		@MasterRotationLimiter VARCHAR(50),
		@MasterRotationLimiterMetric VARCHAR(10),
		@MasterRotationMetricValue INT,
		@MinionTriggerPath varchar(1000),
		@TriggerFile VARCHAR(2000),
		@PushToMinion VARCHAR(25);

DECLARE @JobThreadSQL VARCHAR(8000),
		@JobName VARCHAR(500),
		@JobStepSQL VARCHAR(8000),
		@JobStartSQL VARCHAR(400);
DECLARE @i INT;
DECLARE @NumWorkerThreadsRunning TINYINT,
		@LoopDelaySecs VARCHAR(25);

	SET @ServerInstance = @@ServerName;
	SET @DBInternalThreadsORIG = @DBInternalThreads;
	SET @OpNameOrig = @OpName;

 DECLARE @MaintDB sysname,
		 @OnlineEdition BIT,
		 @Instance NVARCHAR(128),
		 @InstanceName NVARCHAR(128),
		 @ServerAndInstance VARCHAR(400);
SET @MaintDB = DB_NAME();

CREATE TABLE #CheckDBMasterDBs
    (
		ID SMALLINT IDENTITY(1,1),
        DBName VARCHAR(100) COLLATE DATABASE_DEFAULT ,
		OpName VARCHAR(50),
		DBInternalThreads TINYINT,
        IsReadOnly BIT ,
        StateDesc VARCHAR(50) COLLATE DATABASE_DEFAULT ,
        CheckDBGroupOrder INT ,
        CheckDBOrder INT
    )

----These vars get destroyed in the While loops below.  So they need to be preserved into another var 
----so they can be logged later.

    SET @IncludeRAW = @Include;
    SET @ExcludeRAW = @Exclude;
---------------------------------------------------------------------------------
------------------ BEGIN Get Version Info----------------------------------------
---------------------------------------------------------------------------------

SELECT 
@VersionRaw = VersionRaw,
@Version = [Version],
@Edition = Edition,
@OnlineEdition = OnlineEdition,
@Instance = Instance,
@InstanceName = InstanceName,
@ServerAndInstance = ServerAndInstance
FROM Minion.DBMaintSQLInfoGet();
															          
---------------------------------------------------------------------------------
------------------ END Get Version Info------------------------------------------
---------------------------------------------------------------------------------

----------------------BEGIN Minion Push Data--------------
IF @StmtOnly = 0
	BEGIN
		SET @PushToMinion = (SELECT TOP 1 PushToMinion FROM Minion.CheckDBSettingsDB WHERE IsActive = 1);

		IF @PushToMinion = 1
			BEGIN
				SET @MinionTriggerPath = (SELECT TOP 1 MinionTriggerPath FROM Minion.CheckDBSettingsDB WHERE IsActive = 1);
			END
	END
----------------------END Minion Push Data----------------


-------------------------------------------------------------------------
----------------BEGIN Check Cmdshell-------------------------------------
-------------------------------------------------------------------------
DECLARE @CmdshellON BIT;
SET @CmdshellON = (SELECT CAST(value_in_use AS BIT) FROM sys.configurations WHERE name = 'xp_cmdshell')
IF @CmdshellON = 0
	BEGIN
			INSERT Minion.CheckDBLog (ExecutionDateTime, STATUS, DBType, OpName)
			SELECT @ExecutionDateTime, 'FATAL ERROR: xp_cmdshell is not enabled.  You must enable xp_cmdshell in order to run this procedure', @LogDBType, @OpName				
	END
-------------------------------------------------------------------------
-----------------END Check Cmdshell--------------------------------------
-------------------------------------------------------------------------



------------------------------------------------------------
------------BEGIN Process Included DBs----------------------
------------------------------------------------------------

----We need to save the DBGroups in a #table so we can get the escape chars for each row.
CREATE TABLE #CDBMasterDBEscapesInclude
(
Action VARCHAR(10),
MaintType varchar(20),
GroupName VARCHAR(200),
GroupDef VARCHAR(400),
[Escape] CHAR(1)
)

CREATE TABLE #CDBMasterDBInsertedWildcardDBs
(
DBName VARCHAR(400)
)

    ---- If @Include has a list of databases...
    IF @Include <> 'All' AND @Include IS NOT NULL AND @Include <> 'Regex'
        BEGIN -- <> All
			--Get rid of any spaces in the DB list.
            SET @Include = REPLACE(@Include, ', ', ',');
			
            DECLARE @IncludeDBNameTable TABLE ( DBName VARCHAR(500) );
            DECLARE @IncludeDBNameString VARCHAR(500);
            WHILE LEN(@Include) > 0 
                BEGIN
                    SET @IncludeDBNameString = LEFT(@Include,
                                                    ISNULL(NULLIF(CHARINDEX(',',
                                                              @Include) - 1,
                                                              -1),
                                                           LEN(@Include)))
                    SET @Include = SUBSTRING(@Include,
                                             ISNULL(NULLIF(CHARINDEX(',',
                                                              @Include), 0),
                                                    LEN(@Include)) + 1,
                                             LEN(@Include))

                    INSERT  INTO @IncludeDBNameTable
                            ( DBName )
                    VALUES  ( @IncludeDBNameString )
                END  

----------------BEGIN DBGroups-----------------------------------
--If we put this into the same @table that's got the static and wildcard DBs mixed together, then it'll just process it normally like everything else
--and we don't have to do anything special.  So get the expanded list of DBs from the Groups table, and then let the routine do the rest.


IF UPPER(@IncludeRAW) LIKE '%DBGROUP:%'
BEGIN --@IncludeRAW

DECLARE GroupDBs CURSOR
READ_ONLY
FOR SELECT DBName
FROM @IncludeDBNameTable
WHERE UPPER(DBName) LIKE '%DBGROUP:%'

OPEN GroupDBs

	FETCH NEXT FROM GroupDBs INTO @currDB
	WHILE (@@fetch_status <> -1)
	BEGIN

		SET @currDB = REPLACE( UPPER(@currDB), 'DBGROUP:', '');

		INSERT @IncludeDBNameTable (DBName)
		SELECT GroupDef 
		FROM Minion.DBMaintDBGroups 
		WHERE 
		UPPER(Action) = 'INCLUDE'
		AND (UPPER(MaintType) = 'CHECKDB' OR UPPER(MaintType) = 'ALL')
		AND GroupName = @currDB
		AND IsActive = 1;

FETCH NEXT FROM GroupDBs INTO @currDB
	END

CLOSE GroupDBs
DEALLOCATE GroupDBs


INSERT #CDBMasterDBEscapesInclude
        (Action, MaintType, GroupName, GroupDef, [Escape])
SELECT Action, MaintType, GroupName, GroupDef, [Escape]
FROM [Minion].[DBMaintDBGroups]
WHERE GroupName IN (SELECT REPLACE(DBName, 'DBGROUP:', '') FROM @IncludeDBNameTable WHERE REPLACE(DBName, 'DBGROUP:', '') = REPLACE(DBName, 'DBGROUP:', '')
AND DBName LIKE 'DBGROUP:%')
AND UPPER(Action) = 'INCLUDE'
AND (UPPER(MaintType) = 'CHECKDB' OR UPPER(MaintType) = 'ALL')
---Now delete the LIKE DBs that were passed into the param as the actual DB names are in the table now.
DELETE @IncludeDBNameTable
WHERE UPPER(DBName) LIKE '%DBGROUP:%' 

END --@IncludeRAW
-------------------END DBGroups----------------------------------


------------------------------------
----BEGIN Insert Static DB Names----
------------------------------------
--These are the actual DB names passed into the @Include param.
                INSERT  #CheckDBMasterDBs (DBName, IsReadOnly, StateDesc, CheckDBGroupOrder, CheckDBOrder)
                        SELECT  ID.DBName COLLATE DATABASE_DEFAULT, 
						SD.is_read_only, SD.state_desc COLLATE DATABASE_DEFAULT, 0, 0
                        FROM @IncludeDBNameTable ID
						INNER JOIN master.sys.databases SD WITH (NOLOCK)
						ON ID.DBName COLLATE DATABASE_DEFAULT = SD.name COLLATE DATABASE_DEFAULT
						WHERE ID.DBName NOT LIKE '%\%%' ESCAPE '\'
						AND SD.source_database_id IS NULL
				UNION
						SELECT DBName COLLATE DATABASE_DEFAULT
						, NULL, NULL, NULL, NULL
						FROM @IncludeDBNameTable
						WHERE DBName COLLATE DATABASE_DEFAULT LIKE '%\%%' ESCAPE '\'
------------------------------------
----END Insert Static DB Names------
------------------------------------


----------------Insert LIKE Include DB Names----------------
--You can mix static and LIKE DB names so here's where we're processing the LIKE names.
DECLARE @Escape CHAR(1);
IF @IncludeRAW LIKE '%\%%' ESCAPE '\' OR UPPER(@IncludeRAW) LIKE '%DBGROUP:%'
BEGIN --@IncludeRAW
DECLARE LikeDBs CURSOR
READ_ONLY
FOR SELECT DBName
FROM #CheckDBMasterDBs
WHERE DBName LIKE '%\%%' ESCAPE '\' 

OPEN LikeDBs

	FETCH NEXT FROM LikeDBs INTO @currDB
	WHILE (@@fetch_status <> -1)
	BEGIN

		SET @Escape = (SELECT [Escape] FROM #CDBMasterDBEscapesInclude WHERE GroupDef = @currDB);

		INSERT #CheckDBMasterDBs (DBName, IsReadOnly, StateDesc, CheckDBGroupOrder, CheckDBOrder)
		SELECT name, is_read_only, state_desc, 0, 0
		FROM master.sys.databases WITH (NOLOCK)
		WHERE name LIKE @currDB
			  --AND name NOT IN ('master', 'msdb', 'tempdb', 'model')
			  AND source_database_id IS NULL

----We have to insert the Actual DB names from sys.databases here.  Currently, #BackupMasterDBs still holds the wildcards passed
----in from the @Include var and we're inserting the names into this same table.  So if the DB itself has a wildcard in it, then 
----it too will be deleted from the list and never backed up.  So we put the DB names themselves into this table so when the delete
----happens just below this cursor, we can filter out the actual DB names and just delete the wildcards we don't want.
----If the above insert ever changes, then we'll also need to change this one as we're selecting the same data criteria. 
		INSERT #CDBMasterDBInsertedWildcardDBs (DBName)
		SELECT name
		FROM master.sys.databases WITH (NOLOCK)
		WHERE name LIKE @currDB ESCAPE @Escape
			  --AND name NOT IN ('master', 'msdb', 'tempdb', 'model')
FETCH NEXT FROM LikeDBs INTO @currDB
	END

CLOSE LikeDBs
DEALLOCATE LikeDBs

---Now delete the LIKE DBs that were passed into the param as the actual DB names are in the table now.
DELETE #CheckDBMasterDBs
WHERE DBName LIKE '%\%%' ESCAPE '\'

END --@IncludeRAW
-------------------END LIKE Include DB Names---------------------
        END -- <> All AND IS NOT NULL

    IF @Include = 'All' OR @Include IS NULL 
	BEGIN --@Include = 'All' OR @Include IS NULL 
	
                BEGIN -- = 'All'

                    IF @DBType = 'System' 
                        BEGIN
                            INSERT  #CheckDBMasterDBs (DBName, IsReadOnly, StateDesc, CheckDBGroupOrder, CheckDBOrder)
                                    SELECT  name ,
                                            is_read_only ,
                                            state_desc ,
                                            --recovery_model_desc ,
                                            0 ,
                                            0
                                    FROM    master.sys.databases WITH (NOLOCK)
                                    WHERE   name IN ( 'master', 'msdb',
                                                      'model' )
											AND source_database_id IS NULL
                        END
        
                    IF @DBType = 'User' 
          BEGIN
                            INSERT  #CheckDBMasterDBs (DBName, IsReadOnly, StateDesc, CheckDBGroupOrder, CheckDBOrder)
                                    SELECT  name ,
                                            is_read_only ,
                                            state_desc ,
                                            0 ,
                                            0
                                    FROM    master.sys.databases WITH ( NOLOCK )
                                    WHERE   name NOT IN ( 'master', 'msdb',
                                                          'model', 'tempdb' )
                                            AND state_desc = 'ONLINE' 
											AND source_database_id IS NULL
                        END


						---------------------------------------
						-----BEGIN Set Default Settings--------
						---------------------------------------
						
                    DECLARE @GroupOrder INT ,
							@GroupDBOrder INT;

                    SELECT  @GroupOrder = GroupOrder ,
                            @GroupDBOrder = GroupDBOrder,
							@Port = Port
                    FROM    Minion.CheckDBSettingsDB
                    WHERE   DBName = 'MinionDefault' AND IsActive = 1;

                    UPDATE  #CheckDBMasterDBs
                    SET     CheckDBGroupOrder = ISNULL(@GroupOrder, 0) ,
                            CheckDBOrder = ISNULL(@GroupDBOrder, 0);

						---------------------------------------
						-----END Set Default Settings----------
						---------------------------------------
					                        
						---------------------------------------
						-----BEGIN Set DB Override Settings----
						---------------------------------------
                    UPDATE  D
                    SET     D.CheckDBGroupOrder = ISNULL(DBM.GroupOrder, 0)  ,
                            D.CheckDBOrder = ISNULL(DBM.GroupDBOrder, 0) ,
							@Port = Port
                    FROM    #CheckDBMasterDBs D
                            INNER JOIN Minion.CheckDBSettingsDB DBM WITH ( NOLOCK ) ON DBM.DBName = D.DBName
							WHERE DBM.IsActive = 1
						---------------------------------------
						-----END Set DB Override Settings------
						---------------------------------------


						---------------------------------------
						-----BEGIN ReadOnly DBs----------------
						---------------------------------------

                    IF @ReadOnly = 2 
                        BEGIN
                            DELETE  #CheckDBMasterDBs
                            WHERE   IsReadOnly = 1
                        END
                            
                    IF @ReadOnly = 3 
                        BEGIN
                            DELETE  #CheckDBMasterDBs
                            WHERE   IsReadOnly = 0
                        END

						---------------------------------------
						-----END ReadOnly DBs------------------
						---------------------------------------


                END -- = 'All'

       ----     BEGIN -- = 'All'
        
       ----         IF @DBType = 'User' 
       ----             BEGIN
       ----                 INSERT  #CheckDBMasterDBs
       ----                         SELECT  name ,
       ----                                 is_read_only ,
       ----                                 state_desc ,
       ----                                 0 ,
       ----                                 0
       ----FROM    master.sys.databases WITH (NOLOCK)
       ----                         WHERE   name NOT IN ( 'master', 'msdb',
       ----                                               'model', 'tempdb' )
       ----                                 AND recovery_model_desc <> 'Simple'
       ----                                 AND state_desc = 'ONLINE'
       ----                                 AND is_read_only = 0
							----			AND source_database_id IS NULL
       ----             END
                        
       ----     END -- = 'All'

 
 END --@Include = 'All' OR @Include IS NULL    
------------------------------------------------------------
------------END Process Included DBs------------------------
------------------------------------------------------------

						---------------------------------------
						-----BEGIN Delete ExcludeFromCheckDB---
						---------------------------------------

IF (SELECT COUNT(*) FROM Minion.CheckDBSettingsDB WHERE DBName = 'MinionDefault' AND Exclude = 1 AND IsActive = 1) > 0
BEGIN
	TRUNCATE TABLE #CheckDBMasterDBs;

	RAISERROR ('All DBs have been excluded because of the ''MinionDefault'' setting in Minion.CheckDBSettingsDB. Set Exclude = 0 for the OpName.', 16, 1); 
            RETURN;
END

IF @IncludeRAW IS NULL
	BEGIN	
        DELETE  D
        FROM    #CheckDBMasterDBs D
                INNER JOIN Minion.CheckDBSettingsDB DBM WITH ( NOLOCK ) ON DBM.DBName COLLATE DATABASE_DEFAULT = D.DBName COLLATE DATABASE_DEFAULT
        WHERE   DBM.Exclude = 1
			--AND (DBM.BackupType = 'All' OR DBM.BackupType = @BackupType)
				AND IsActive = 1
	END
						---------------------------------------
						-----END Delete ExcludeFromCheckDB-----
						---------------------------------------


------------------------------------------------------------
------------------------------------------------------------
------------BEGIN Process Regex Included DBs----------------
------------------------------------------------------------
------------------------------------------------------------
--You may want to include DBs based off of a regex expression.  The regex expression is stored in the Minion.DBMaintRegexLookup table.
--This is great functionality and is meant for rotating dated archive DBs or dev DBs that rotate.  
--As an example, a prod DB will be picked up by the routine, but maybe you don't want the dated versions to be reindexed... like Minion201408 and Minion201409.
--These DBs get created and dropped every wk or so and you don't care about maintaining them.

------!!! The regex function isn't available for 2005.

IF @Include = 'Regex' AND (@Exclude IS NULL OR @Exclude = '')
BEGIN --@Include = 'Regex' AND (@Exclude IS NULL OR @Exclude = '')
IF @Version >= 10.0
BEGIN --@Version >= 10
        SELECT DISTINCT
                DFL.Regex,
                DFL.Action
		INTO #RegexMatchInclude
        FROM    Minion.DBMaintRegexLookup DFL
        WHERE   Action = 'Include'
                AND ( UPPER(MaintType) = 'ALL'
                      OR UPPER(MaintType) = 'CHECKDB'
                    )

SET @RegexCT = (SELECT COUNT(*) FROM #RegexMatchInclude)

IF @RegexCT > 0

BEGIN --@RegexCT > 0
    CREATE TABLE #RegexLookupInclude
        (
		  ID SMALLINT IDENTITY(1,1),
          DBName sysname COLLATE DATABASE_DEFAULT NULL ,
          Action VARCHAR(10) COLLATE DATABASE_DEFAULT
        )

    DECLARE @Regex VARCHAR(200) ,
        @Action VARCHAR(10) ,
        @RegexCMD VARCHAR(2000);


    DECLARE DBs CURSOR READ_ONLY
    FOR
	SELECT * FROM #RegexMatchInclude

    OPEN DBs

    FETCH NEXT FROM DBs INTO @Regex, @Action
    WHILE ( @@fetch_status <> -1 ) 
        BEGIN

            SET @RegexCMD = 'EXEC xp_cmdshell ''powershell "'

			IF @Version = 10.0 OR @Version = 10.5
			BEGIN
                SET @RegexCMD = @RegexCMD  + 'ADD-PSSNAPIN SQLServerCmdletSnapin100; '
			END

			IF @Version >= 11
			BEGIN
                SET @RegexCMD = @RegexCMD  + 'IMPORT-MODULE SQLPS -DisableNameChecking 3> $null; '
			END
            SET @RegexCMD = @RegexCMD + '$DBList = invoke-sqlcmd -serverinstance "' + @Instance + '" -database master -query ''''select Name from master..sysdatabases''''; $FinalList = $DBList | ?{$_.Name -match '''''
                        + @Regex + '''''}; $FinalList"  '''	

            INSERT  #RegexLookupInclude
                    ( DBName )
                    EXEC ( @RegexCMD
                        ) 

            FETCH NEXT FROM DBs INTO @Regex, @Action
        END

    CLOSE DBs
    DEALLOCATE DBs


--Get rid of any rows that aren't actually DBNames.  The cmdshell gives us back some crap with our results.-
    DELETE  #RegexLookupInclude
    WHERE   DBName IS NULL

 INSERT  #CheckDBMasterDBs (DBName, IsReadOnly, StateDesc, CheckDBGroupOrder, CheckDBOrder)
    SELECT  name ,
            is_read_only ,
            state_desc ,
            0 ,
            0
    FROM    master.sys.databases WITH (NOLOCK)
    WHERE   name IN (SELECT DBName FROM #RegexLookupInclude)
	AND source_database_id IS NULL

--------------------------------------------------------
------------BEGIN Get List of REGEX Included DBs--------
--------------------------------------------------------
DECLARE @RegexIncludeDBs VARCHAR(MAX);
SELECT @RegexIncludeDBs = STUFF(( SELECT ', ' + DBName
        FROM  #CheckDBMasterDBs AS T1
        ORDER BY T1.ID
      FOR
        XML PATH('')
      ), 1, 1, '')
FROM #CheckDBMasterDBs AS T2;
--------------------------------------------------------
------------END Get List of REGEX Included DBs----------
--------------------------------------------------------


END --@RegexCT > 0

END --@Version >= 10
END --@Include = 'Regex' AND (@Exclude IS NULL OR @Exclude = '')
------------------------------------------------------------
------------------------------------------------------------
------------END Process Regex Included DBs------------------
------------------------------------------------------------
------------------------------------------------------------



------------------------------------------------------------
------------BEGIN Process Excluded DBs----------------------
------------------------------------------------------------

    IF @Exclude IS NOT NULL 
        BEGIN

--Get rid of any spaces in the DB list.
			SET @Exclude = REPLACE(@Exclude, ', ', ',');
            DECLARE @ExcludeDBNameTable TABLE ( DBName VARCHAR(500) );
            DECLARE @ExcludeDBNameString VARCHAR(500);
            WHILE LEN(@Exclude) > 0 
                BEGIN
                    SET @ExcludeDBNameString = LEFT(@Exclude,
                                                    ISNULL(NULLIF(CHARINDEX(',',
                                                              @Exclude) - 1,
                                                              -1),
                                                           LEN(@Exclude)))
                    SET @Exclude = SUBSTRING(@Exclude,
                                             ISNULL(NULLIF(CHARINDEX(',',
                                                              @Exclude), 0),
                                                    LEN(@Exclude)) + 1,
                                             LEN(@Exclude))

                    INSERT  INTO @ExcludeDBNameTable
                            ( DBName )
                    VALUES  ( @ExcludeDBNameString )
                END  

----------------Insert LIKE Include DB Names----------------

----------------BEGIN DBGroups-----------------------------------
--If we put this into the same @table that's got the static and wildcard DBs mixed together, then it'll just process it normally like everything else
--and we don't have to do anything special.  So get the expanded list of DBs from the Groups table, and then let the routine do the rest.

IF UPPER(@ExcludeRAW) LIKE '%DBGROUP:%'
BEGIN --@ExcludeRAW

DECLARE GroupDBs CURSOR
READ_ONLY
FOR SELECT DBName
FROM @ExcludeDBNameTable
WHERE UPPER(DBName) LIKE '%DBGROUP:%'

OPEN GroupDBs

	FETCH NEXT FROM GroupDBs INTO @currDB
	WHILE (@@fetch_status <> -1)
	BEGIN

		SET @currDB = REPLACE( UPPER(@currDB), 'DBGROUP:', '');

		INSERT @ExcludeDBNameTable (DBName)
		SELECT GroupDef 
		FROM Minion.DBMaintDBGroups 
		WHERE 
		UPPER(Action) = 'EXCLUDE'
		AND (UPPER(MaintType) = 'CHECKDB' OR UPPER(MaintType) = 'ALL')
		AND GroupName = @currDB
		AND IsActive = 1;

		
FETCH NEXT FROM GroupDBs INTO @currDB
	END

CLOSE GroupDBs
DEALLOCATE GroupDBs


CREATE TABLE #CDBMasterDBEscapesExclude
(
Action VARCHAR(10),
MaintType varchar(20),
GroupName VARCHAR(200),
GroupDef VARCHAR(400),
[Escape] CHAR(1)
)

INSERT #CDBMasterDBEscapesExclude
        (Action, MaintType, GroupName, GroupDef, [Escape])
SELECT Action, MaintType, GroupName, GroupDef, [Escape]
FROM [Minion].[DBMaintDBGroups]
WHERE GroupName IN (SELECT REPLACE(DBName, 'DBGROUP:', '') FROM @ExcludeDBNameTable WHERE REPLACE(DBName, 'DBGROUP:', '') = REPLACE(DBName, 'DBGROUP:', '')
AND DBName LIKE 'DBGROUP:%')
AND UPPER(Action) = 'EXCLUDE'
AND (UPPER(MaintType) = 'CHECKDB' OR UPPER(MaintType) = 'ALL')

---Now delete the LIKE DBs that were passed into the param as the actual DB names are in the table now.
DELETE @ExcludeDBNameTable
WHERE UPPER(DBName) LIKE '%DBGROUP:%' 

END --@ExcludeRAW
-------------------END DBGroups----------------------------------


--You can mix static and LIKE DB names so here's where we're processing the LIKE names.

IF @ExcludeRAW LIKE '%\%%' ESCAPE '\' OR UPPER(@ExcludeRAW) LIKE '%DBGROUP:%'
BEGIN --@IncludeRAW
DECLARE LikeDBs CURSOR
READ_ONLY
FOR SELECT DBName
FROM @ExcludeDBNameTable
WHERE DBName LIKE '%\%%' ESCAPE '\' 

OPEN LikeDBs

	FETCH NEXT FROM LikeDBs INTO @currDB
	WHILE (@@fetch_status <> -1)
	BEGIN
	SET @Escape = (SELECT [Escape] FROM #CDBMasterDBEscapesInclude WHERE GroupDef = @currDB);
		INSERT @ExcludeDBNameTable (DBName)
		SELECT name
		FROM master.sys.databases WITH (NOLOCK)
		WHERE name LIKE @currDB
			 -- AND name NOT IN ('master', 'msdb', 'tempdb', 'model')
----We have to insert the Actual DB names from sys.databases here.  Currently, #BackupMasterDBs still holds the wildcards passed
----in from the @Include var and we're inserting the names into this same table.  So if the DB itself has a wildcard in it, then 
----it too will be deleted from the list and never backed up.  So we put the DB names themselves into this table so when the delete
----happens just below this cursor, we can filter out the actual DB names and just delete the wildcards we don't want.
----If the above insert ever changes, then we'll also need to change this one as we're selecting the same data criteria. 
		INSERT #CDBMasterDBInsertedWildcardDBs (DBName)
		SELECT name
		FROM master.sys.databases WITH (NOLOCK)
		WHERE name LIKE @currDB ESCAPE @Escape
			 -- AND name NOT IN ('master', 'msdb', 'tempdb', 'model')
		
FETCH NEXT FROM LikeDBs INTO @currDB
	END

CLOSE LikeDBs
DEALLOCATE LikeDBs

---Now delete the LIKE DBs that were passed into the param as the actual DB names are in the table now.
DELETE @ExcludeDBNameTable
WHERE DBName LIKE '%\%%' ESCAPE '\'
AND DBName NOT IN (SELECT DBName FROM #CDBMasterDBInsertedWildcardDBs)

TRUNCATE TABLE #CDBMasterDBInsertedWildcardDBs;

END --@IncludeRAW
-------------------END LIKE Include DB Names---------------------

            DELETE  DBs
            FROM    #CheckDBMasterDBs DBs
                    INNER JOIN @ExcludeDBNameTable E ON DBs.DBName = E.DBName;
        END

------------------------------------------------------------
------------END Process Excluded DBs------------------------
------------------------------------------------------------



------------------------------------------------------------
------------------------------------------------------------
------------BEGIN Process Regex Excluded DBs----------------
------------------------------------------------------------
------------------------------------------------------------
--You may want to exclude DBs based off of a regex expression.  The regex expression is stored in the Minion.DBMaintRegexLookup table.
--This is great functionality and is meant for rotating dated archive DBs or dev DBs that rotate.  
--As an example, a prod DB will be picked up by the routine, but maybe you don't want the dated versions to be reindexed... like Minion201408 and Minion201409.
--These DBs get created and dropped every wk or so and you don't care about maintaining them.

------!!! The regex function isn't available for 2005.
		CREATE TABLE #RegexLookupExclude
			(
			  DBName sysname COLLATE DATABASE_DEFAULT NULL ,
			  Action VARCHAR(10) COLLATE DATABASE_DEFAULT
			)


IF @ExcludeRAW = 'Regex' AND (@IncludeRAW = 'All' OR @IncludeRAW IS NULL)
BEGIN --@ExcludeRAW = 'Regex'
	IF @Version >= 10.0
	BEGIN --@Version >= 10
			SELECT DISTINCT
					DFL.Regex,
					DFL.Action
			INTO #RegexMatchExclude
			FROM    Minion.DBMaintRegexLookup DFL
			WHERE   Action = 'Exclude'
                AND ( UPPER(MaintType) = 'ALL'
                      OR UPPER(MaintType) = 'CHECKDB'
						)

	SET @RegexCT = (SELECT COUNT(*) FROM #RegexMatchExclude)

	IF @RegexCT > 0

	BEGIN --@RegexCT > 0

		DECLARE DBs CURSOR READ_ONLY
		FOR
			SELECT DISTINCT
					DFL.Regex ,
					DFL.Action
			FROM    Minion.DBMaintRegexLookup DFL
			WHERE   Action = 'Exclude'
                AND ( UPPER(MaintType) = 'ALL'
                      OR UPPER(MaintType) = 'CHECKDB'
						)

		OPEN DBs

		FETCH NEXT FROM DBs INTO @Regex, @Action
		WHILE ( @@fetch_status <> -1 ) 
			BEGIN
				SET @RegexCMD = 'EXEC xp_cmdshell ''powershell "'
				SET @RegexCMD = @RegexCMD  + 'IMPORT-MODULE SQLPS -DisableNameChecking 3> $null; '
				SET @RegexCMD = @RegexCMD + '$DBList = invoke-sqlcmd -serverinstance "' + @Instance + '" -database master -query ''''select Name from master..sysdatabases''''; $FinalList = $DBList | ?{$_.Name -match '''''
				+ @Regex + '''''}; $FinalList"  '''	

				INSERT  #RegexLookupExclude
						( DBName )
						EXEC ( @RegexCMD
							) 

				FETCH NEXT FROM DBs INTO @Regex, @Action
			END

		CLOSE DBs
		DEALLOCATE DBs


	--Get rid of any rows that aren't actually DBNames.  The cmdshell gives us back some crap with our results.-
		DELETE  #RegexLookupExclude
		WHERE   DBName IS NULL;

	--Delete DBs that are meant to be excluded off of the Regex search.
		DELETE  DBs
		FROM    #CheckDBMasterDBs DBs
				INNER JOIN #RegexLookupExclude FL 
				ON DBs.DBName = FL.DBName;

	END --@RegexCT > 0

	END --@Version >= 10
END  --@ExcludeRAW = 'Regex'
------------------------------------------------------------
------------------------------------------------------------
------------END Process Regex Excluded DBs------------------
------------------------------------------------------------
------------------------------------------------------------



------------------------------------------------------------------------
------------------------------------------------------------------------
------------------BEGIN Exclude HA Considerations-----------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
--These are excluded after everything else because no matter what else is in place, these are not negotiable.
--If a DB isn't a mirror principle (or any other HA scenario 2ndary), then it can't be backed up regardless of your desire.

------Delete Mirroring 2ndaries.
DELETE D
FROM #CheckDBMasterDBs D
INNER JOIN sys.database_mirroring dm
ON D.DBName COLLATE DATABASE_DEFAULT = DB_NAME(dm.database_id) 
WHERE (UPPER(dm.mirroring_role_desc) COLLATE DATABASE_DEFAULT <> 'PRINCIPAL' AND dm.mirroring_role_desc IS NOT NULL)

--------Delete Log Shipping 2ndaries.
--DELETE D
--FROM #CheckDBMasterDBs D
--INNER JOIN msdb.dbo.log_shipping_secondary_databases dm
--ON D.DBName COLLATE DATABASE_DEFAULT = dm.secondary_database COLLATE DATABASE_DEFAULT

-----Delete non-readable AG 2ndaries.
IF @Version >= 11
	BEGIN
		DELETE CD
		FROM #CheckDBMasterDBs CD
		INNER JOIN master.sys.databases d 
		ON CD.DBName COLLATE DATABASE_DEFAULT = d.name COLLATE DATABASE_DEFAULT
		INNER JOIN sys.dm_hadr_database_replica_states hs
		ON (d.database_id = hs.database_id AND d.replica_id = hs.replica_id AND d.group_database_id = hs.group_database_id)
		INNER JOIN sys.availability_replicas ar
		ON (hs.group_id = ar.group_id AND hs.replica_id = ar.replica_id)
		WHERE d.state = 0
		AND ar.secondary_role_allow_connections_desc IN ('NO', 'READ_ONLY');
	END
--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------END Exclude HA Considerations-------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------



--------------------------------------------------------------
--------------------------------------------------------------
--------------BEGIN Initial Log-------------------------------
--------------------------------------------------------------
--------------------------------------------------------------


--------Get comma-delimited list of DBs that were kicked out by the Regex lookup.
    IF @StmtOnly = 0 
    BEGIN --@StmtOnly = 0 
		IF @Include = 'All' OR @Include IS NULL 			
			BEGIN
				DECLARE @RegexExcludeDBs VARCHAR(8000) 
				SELECT  @RegexExcludeDBs = COALESCE(@RegexExcludeDBs + ', ', '') + DBName
				FROM    #RegexLookupExclude
				WHERE   DBName IS NOT NULL
			END
	END --@StmtOnly = 0 

    IF @StmtOnly = 0 AND @DBType IS NOT NULL -- Dont log if there isn't going to be a run.
        BEGIN
            INSERT  Minion.CheckDBLog
                    ( ExecutionDateTime,
                      STATUS,
                      DBType,
					  OpName,
					  NumConcurrentOps,
					  DBInternalThreads,
					  NumDBsOnServer,
					  NumDBsProcessed,
					  [Schemas],
					  [Tables],
                      IncludeDBs,
                      ExcludeDBs,
					  RegexDBsIncluded,
                      RegexDBsExcluded
                    )
                    SELECT  @ExecutionDateTime,
							'Configuring Run',
							@DBType,
							@OpNameOrig,
							@NumConcurrentProcesses,
							@DBInternalThreads,
							(SELECT COUNT(*) FROM sys.databases WITH(NOLOCK) WHERE database_id > 4 AND source_database_id IS NULL),
							(SELECT COUNT(*) FROM #CheckDBMasterDBs),
							@Schemas,
							@Tables,
							@IncludeRAW,
							@ExcludeRAW,
							@RegexIncludeDBs,
							@RegexExcludeDBs;
	END						

--------------------------------------------------------------
--------------------------------------------------------------
--------------END Initial Log---------------------------------
--------------------------------------------------------------
--------------------------------------------------------------




--------------------------------------------------------------
--------------------------------------------------------------
--------------BEGIN Stop If Runs Exceeded---------------------
--------------------------------------------------------------
--------------------------------------------------------------

------SELECT @CurrentNumBackups CurrentNumBackups, @MaxForTimeframe AS MaxForTimeframe
----IF @StmtOnly = 0 
----    BEGIN
----		IF @CurrentNumBackups >= @MaxforTimeframe --OR @DBType IS NULL
----	BEGIN
----		UPDATE Minion.BackupLog
----			SET STATUS = 'FATAL ERROR: The number of executions for backup type ''' + ISNULL(@BackupType, '') + ''' and DBType ''' + ISNULL(@DBType, '') + ''' have been exceeded.  This setting comes from the Minion.CheckDBSettingsDBServer table.  The setting that was chosen out of the table is ID = ' + ISNULL(CAST(@MasterParamID AS VARCHAR(5)), '<no row available>')
----			WHERE ID = @BackupLogID;

----		UPDATE Minion.BackupLogDetails
----			SET STATUS = 'FATAL ERROR: The number of executions for backup type ''' + ISNULL(@BackupType, '') + ''' and DBType ''' + ISNULL(@DBType, '') + ''' have been exceeded.  This setting comes from the Minion.CheckDBSettingsDBServer table.  The setting that was chosen out of the table is ID = ' + ISNULL(CAST(@MasterParamID AS VARCHAR(5)), '<no row available>')
----			WHERE ExecutionDateTime = @ExecutionDateTime
----				  AND BackupType = @BackupType;

----		RAISERROR ('FATAL ERROR: The number of executions for this backup type have been exceeded.  This setting comes from the Minion.CheckDBSettingsDBServer table.  See Minion.BackupLog for more details.', 16, 1); 
----		RETURN;	
----	END
----	END
--------------------------------------------------------------
--------------------------------------------------------------
--------------END Stop If Runs Exceeded-----------------------
--------------------------------------------------------------
--------------------------------------------------------------


---------------------------------------------------------------------------------
----------------------BEGIN Sync Settings----------------------------------------
---------------------------------------------------------------------------------
----INSERT Minion.Work
----SELECT @ExecutionDateTime, 'Backup', 'MinionBatch', @BackupType, '@SyncLogs', 'BackupMaster', @SyncLogs

----INSERT Minion.Work
----SELECT @ExecutionDateTime, 'Backup', 'MinionBatch', @BackupType, '@SyncSettings', 'BackupMaster', @SyncSettings
---------------------------------------------------------------------------------
----------------------END Sync Settings------------------------------------------
---------------------------------------------------------------------------------



-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
---------------------------------------------BEGIN DBPreCode-----------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

        IF @BatchPreCode IS NOT NULL AND @BatchPreCode <> ''
            BEGIN -- @BatchPreCode IS NOT NULL AND @BatchPreCode <> ''

-----BEGIN Log------

-------------------DEBUG-------------------------------
--IF @Debug = 1
--BEGIN
--	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
--	SELECT
--		ExecutionDateTime, STATUS, DBName, BackupType, 'BackupMaster Before Precode'
--		FROM Minion.BackupLogDetails
--		WHERE ID = @BackupLogDetailsID

--	INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
--	SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupMaster', '@BatchPreCode', @BatchPreCode
--END
-------------------DEBUG-------------------------------

                IF @BatchPreCode IS NOT NULL
                    BEGIN -- @BatchPreCode
                        IF @StmtOnly = 0
                            BEGIN -- @StmtOnly = 0
                                SET @BatchPreCodeStartDateTime = GETDATE();

                                BEGIN
                                    UPDATE
                                            Minion.CheckDBLog
                                        SET
                                            STATUS = 'Precode running',
                                            BatchPreCodeStartDateTime = @BatchPreCodeStartDateTime,
                                            BatchPreCode = @BatchPreCode
                                        WHERE
                                            ID = @BackupLogID;
                                END
                            END -- @StmtOnly = 0
                    END -- @@BatchPreCode
------END Log-------

                IF @BatchPreCode IS NOT NULL
                    BEGIN -- @BatchPreCode
-----------------BEGIN Log BatchPreCode------------------
                        UPDATE
                                Minion.CheckDBLog
                            SET
                                BatchPostCode = @BatchPostCode,
                                BatchPostCodeStartDateTime = @BatchPostCodeStartDateTime
                            WHERE
                                ID = @BackupLogID;
-----------------END Log BatchPreCode--------------------

--------------------------------------------------
----------------BEGIN Run Precode-----------------
--------------------------------------------------
                        DECLARE
                            @PreCodeErrors VARCHAR(MAX),
                            @PreCodeErrorExist VARCHAR(MAX);
                        CREATE TABLE #BatchPreCode
                            (
                             ID INT IDENTITY(1, 1),
                             col1 VARCHAR(MAX)
                            )

                        BEGIN TRY
                            EXEC (@BatchPreCode) 
                        END TRY

                        BEGIN CATCH
                            SET @PreCodeErrors = ERROR_MESSAGE();
                        END CATCH

                        IF @PreCodeErrors IS NOT NULL
                            BEGIN
                                SELECT
                                        @PreCodeErrors = 'PRECODE ERROR: '
                                        + @PreCodeErrors
                            END	 

-------------------DEBUG-------------------------------
--IF @Debug = 1
--BEGIN
--	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
--	SELECT
--		ExecutionDateTime, STATUS, DBName, BackupType, 'BackupMaster After Precode'
--		FROM Minion.BackupLogDetails
--		WHERE ID = @BackupLogDetailsID

--	INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
--	SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupMaster', '@PreCodeErrors', @PreCodeErrors
--END
-------------------DEBUG-------------------------------


--------------------------------------------------
----------------END Run Precode-------------------
--------------------------------------------------
                    END -- @BatchPreCode


-----BEGIN Log------

                IF @BatchPreCode IS NOT NULL
                    BEGIN -- @BatchPreCode
                        IF @StmtOnly = 0
                            BEGIN -- @StmtOnly = 0

-----------------------------------------------------
-------------BEGIN Log PreCode Success---------------
-----------------------------------------------------
                                IF @PreCodeErrors IS NULL
                                    BEGIN --@PreCodeErrors IS NULL
                                        SET @BatchPreCodeEndDateTime = GETDATE();
                                        --UPDATE
                                        --        Minion.CheckDBLog
                                        --    SET
                                        --        BatchPreCodeEndDateTime = @BatchPreCodeEndDateTime,
                                        --        BatchPreCodeTimeInSecs = DATEDIFF(s,
                                        --                      CONVERT(VARCHAR(25), @BatchPreCodeStartDateTime, 21),
                                        --                      CONVERT(VARCHAR(25), @BatchPreCodeEndDateTime, 21))
                                        --    WHERE
                                        --        ID = @BackupLogID;
                                    END --@PreCodeErrors IS NULL
-----------------------------------------------------
-------------END Log PreCode Success-----------------
-----------------------------------------------------

-----------------------------------------------------
-------------BEGIN Log PreCode Failure---------------
-----------------------------------------------------
                                IF @PreCodeErrors IS NOT NULL
                                    BEGIN --@PreCodeErrors IS NULL
                                        SET @BatchPreCodeEndDateTime = GETDATE();
                                        --UPDATE
                                        --        Minion.CheckDBLog
                                        --    SET
                                        --        --Warnings = ISNULL(Warnings, '')
                                        --        --+ @PreCodeErrors,
                                        --        BatchPreCodeEndDateTime = @BatchPreCodeEndDateTime,
                                        --        BatchPreCodeTimeInSecs = DATEDIFF(s,
                                        --                      CONVERT(VARCHAR(25), @BatchPreCodeStartDateTime, 21),
                                        --                      CONVERT(VARCHAR(25), @BatchPreCodeEndDateTime, 21))
                                        --    WHERE
                                        --        ID = @BackupLogID;
                                    END --@PreCodeErrors IS NULL


-----------------------------------------------------
-------------END Log PreCode Failure-----------------
-----------------------------------------------------
                            END -- @StmtOnly = 0
                    END -- @@BatchPreCode

------END Log-------

            END -- @BatchPreCode IS NOT NULL AND @BatchPreCode <> ''
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
-------------------------------------------END DBPreCode-------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------
---------------------BEGIN Update Group Order ----------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

----For each individual OpName, we'll set the GroupOrder to that Op's order.
IF UPPER(@OpNameOrig) = 'CHECKDB' OR UPPER(@OpNameOrig) = 'CHECKTABLE'
UPDATE C
SET CheckDBGroupOrder = CS.GroupOrder,
	CheckDBOrder = CS.GroupDBOrder
FROM #CheckDBMasterDBs C
INNER JOIN Minion.CheckDBSettingsDB CS
ON C.DBName COLLATE DATABASE_DEFAULT = CS.DBName COLLATE DATABASE_DEFAULT
WHERE UPPER(CS.OpName) = @OpNameOrig;	

----If it's an AUTO job then we'll use the ordering for CHECKDB.
IF UPPER(@OpNameOrig) = 'AUTO'
UPDATE C
SET CheckDBGroupOrder = CS.GroupOrder,
	CheckDBOrder = CS.GroupDBOrder
FROM #CheckDBMasterDBs C
INNER JOIN Minion.CheckDBSettingsDB CS
ON C.DBName COLLATE DATABASE_DEFAULT = CS.DBName COLLATE DATABASE_DEFAULT
WHERE UPPER(CS.OpName) = 'CHECKDB';	
--------------------------------------------------------------------------------
---------------------END Update Group Order ------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



	
				--------------------------------------------------------------------------------
				---------------------BEGIN PRE Turn ON StatusMonitor ---------------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------

IF @StmtOnly = 0
BEGIN --@StmtOnly = 0
	EXEC Minion.DBMaintStatusMonitorONOff 'CHECKDB', 'ON', @Version, @InstanceName
END --@StmtOnly = 0
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------
				------------------------------END PRE Turn ON StatusMonitor --------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
--------------------------------------BEGIN Single-thread Run Cursor--------------------------------------
----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
IF @NumConcurrentProcesses = 1 OR @StmtOnly = 1
BEGIN --@NumConcurrentProcesses = 1

	INSERT Minion.CheckDBThreadQueue(ExecutionDateTime, DBName, OpName, DBInternalThreads, IsReadOnly, StateDesc, CheckDBGroupOrder, CheckDBOrder, Processing)
	SELECT @ExecutionDateTime, DBName, OpName, DBInternalThreads, IsReadOnly, StateDesc, CheckDBGroupOrder, CheckDBOrder, 0 AS Processing
	FROM #CheckDBMasterDBs
	ORDER BY CheckDBGroupOrder DESC, CheckDBOrder DESC;
			
		--SELECT DBName, @OpName AS OpName, CheckDBGroupOrder, CheckDBOrder
		--FROM Minion.CheckDBThreadQueue --#CheckDBMasterDBs
		--WHERE ExecutionDateTime = @ExecutionDateTime
		--ORDER BY CheckDBGroupOrder DESC, CheckDBOrder DESC;

--SELECT 'temp', * from #CheckDBMasterDBs;

---------------------------------------------------------------------
---------------------------------------------------------------------
------------------BEGIN ST Rotation Figuring-------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
----We only want to manage a rotation if there were no DBs passed into the job.
----If you need to run a checkdb on a specific DB right now, the rotation could knock it back out because it's already been run recently.
----So in that case it would be impossible to run a DB manually while rotations are turned on.
----We don't want to be smarter than the DBA who knows he needs to run the process.  So if rotations are only available if you don't pass
----any DBs into the job.
IF @StmtOnly = 0
	BEGIN --Rotation Figuring
		IF EXISTS (SELECT 1 FROM [Minion].[CheckDBSettingsRotation] WHERE UPPER(OpName) = 'CHECKDB' AND IsActive = 1)
		BEGIN
			IF @IncludeRAW IS NULL OR @IncludeRAW = ''
				BEGIN
					EXEC Minion.CheckDBRotationLimiter @ExecutionDateTime = @ExecutionDateTime, @OpName = @OpName;
				END
		END

		SET @MasterRotationLimiter = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'CHECKDB' AND DBName = 'CHECKDB'  AND SPName = 'CheckDBRotationLimiter' AND Param = '@RotationLimiter')
		SET @MasterRotationLimiterMetric = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'CHECKDB' AND DBName = 'CHECKDB'  AND SPName = 'CheckDBRotationLimiter' AND Param = '@RotationLimiterMetric')
		SET @MasterRotationMetricValue = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'CHECKDB' AND DBName = 'CHECKDB'  AND SPName = 'CheckDBRotationLimiter' AND Param = '@RotationMetricValue')
	
		IF @TimeLimitInMins IS NULL
			BEGIN
				SET @TimeLimitInMins = ISNULL(@MasterRotationMetricValue, 0);
			END

		UPDATE Minion.CheckDBLog
				SET RotationLimiter = ISNULL(@MasterRotationLimiter, 'None'),
					RotationLimiterMetric = ISNULL(@MasterRotationLimiterMetric, 'None'),
					RotationMetricValue = ISNULL(@MasterRotationMetricValue, 0),
					TimeLimitInMins = @TimeLimitInMins
				WHERE ExecutionDateTime = @ExecutionDateTime;
 		
		----Log @TimeLimitInMins to the Work table so we can use it in the other SP.
		INSERT Minion.Work
				(ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value)
		SELECT @ExecutionDateTime, 'CHECKDB', 'CHECKDB', 'CHECKDB', '@TimeLimitInMins', 'CheckDBMaster', ISNULL(@TimeLimitInMins, 0);
END --Rotation Figuring
---------------------------------------------------------------------
---------------------------------------------------------------------
------------------END ST Rotation Figuring---------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

DECLARE @currCheckDBTimeEstimate INT;

	DECLARE DBs CURSOR
	READ_ONLY
	FOR 
	select DBName 
	FROM Minion.CheckDBThreadQueue WHERE ExecutionDateTime = @ExecutionDateTime 
	ORDER BY CheckDBGroupOrder DESC, CheckDBOrder DESC

	OPEN DBs

		FETCH NEXT FROM DBs INTO @currDB
		WHILE (@@fetch_status <> -1)
		BEGIN

			If @StmtOnly = 0
			BEGIN --@StmtOnly = 0
				


--------------------------------------------------------------------------
--------------------------------------------------------------------------
---------------------------BEGIN DBSize-----------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

--/*
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--the reason we have the Auto table is because the thresholds table holds values for each op type and we
--wouldn't have a solid place to keep the values. So where do we do it, or checkdb or checktable, etc?
--So this is a clean settings table to say when to switch from checkdb to checktable w/o any of the hassle
--of figuring out which row to use for each DB.
--Also, we should prob rename checkdbthresholds to checkdbsnapsotsettings. it's more fitting.
--in our auto table we prob need to give the unit of measure for each value so it's clear what we're doing.
--we're also currently using the threshold setting from Settings and I think that needs to stop.
--We also need to add in table count to the auto table so we can do more than just size.
--*/

				IF UPPER(@OpNameOrig) = 'AUTO'
					BEGIN --AUTO
							SET @OpName = @OpNameOrig;					
							EXEC Minion.DBMaintDBSizeGet @Module = 'CHECKDB', @OpName = @OpName OUTPUT, @DBName = @currDB, @DBSize = @DBSize OUTPUT
					END --AUTO


--------------------------------------------------------------------------
--------------------------------------------------------------------------
---------------------------END DBSize-------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

				
------------------------------------------------------------------------------------------------------------				
------------------BEGIN Run CheckDB-------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------


-------------------------------------------------------
--------------------BEGIN CheckDB Call-----------------
-------------------------------------------------------								
				IF UPPER(@OpName) = 'CHECKDB' OR UPPER(@OpName) = 'CHECKALLOC'
					BEGIN --Run CheckDB
						----Update the CheckDBLog table for top-level logging.
						UPDATE Minion.CheckDBLog
							SET STATUS = 'Processing ' + @DBName					
							WHERE ExecutionDateTime = @ExecutionDateTime;

						BEGIN						
							EXEC Minion.CheckDB @currDB, @OpName, @StmtOnly, @ExecutionDateTime
						END
					END --Run CheckDB
-------------------------------------------------------
--------------------END CheckDB Call-------------------
-------------------------------------------------------


-------------------------------------------------------
--------------------BEGIN CheckTable Call--------------
-------------------------------------------------------								
				IF UPPER(@OpName) = 'CHECKTABLE'
					BEGIN --CheckTable Single-thread call
						----We have to find out how many checktable threads we want to run with.
						----If it's NULL then we expect the value to come from the config table.
						----If there's a number passed in then that'll be used.

						IF @DBInternalThreadsORIG IS NULL
						BEGIN --@DBInternalThreads IS NULL
							EXEC Minion.DBMaintDBSettingsGet 'CHECKDB', @currDB, 'CHECKTABLE', @SettingID = @SettingID OUTPUT;

							SELECT TOP 1
							@DBInternalThreads = DBInternalThreads
							FROM Minion.CheckDBSettingsDB
							WHERE ID = @SettingID;
						END --@DBInternalThreads IS NULL						

						
----SELECT @DBInternalThreadsORIG, @DBInternalThreads AS Internals

						IF @DBInternalThreads = 1 OR @DBInternalThreads = 0
						BEGIN	
							SET @DBInternalThreads = 0;					
							SET @PrepOnly = 0;
							SET @RunPrepped = 0;
							----PRINT 'EXEC Minion.CheckDBCheckTable ' + @currDB + ',  ' + ISNULL(@Schemas, 'NULL') + ', ' + ISNULL(@Tables, 'NULL') + ', ' + CAST(@StmtOnly AS VARCHAR(1)) + ', ' + CAST(@PrepOnly AS CHAR(1)) + ', ' + CAST(@RunPrepped AS CHAR(1)) + ', ' + CAST(@ExecutionDateTime AS VARCHAR(25)) + ', ' + CAST(@DBInternalThreads AS CHAR(1));
							EXEC Minion.CheckDBCheckTable @currDB,  @Schemas, @Tables, @StmtOnly, @PrepOnly, @RunPrepped, @ExecutionDateTime, @DBInternalThreads;
						END

------------------------------------------------------------------------
-------------------BEGIN Log to Minion----------------------------------
------------------------------------------------------------------------
If @StmtOnly = 0
	BEGIN --@StmtOnly = 0

--SELECT @PushToMinion, @MinionTriggerPath AS TriggerPath

IF @PushToMinion = 1
	BEGIN
		EXEC Minion.DBMaintLogToMinion @Module = 'CHECKDB', @DBName = @DBName, @MinionTriggerPath = @MinionTriggerPath, @ExecutionDateTime = @ExecutionDateTime, @ServerName = @ServerInstance, @Folder = 'CheckDB'
	END
	END --@StmtOnly = 0

------------------------------------------------------------------------
-------------------END Log to Minion------------------------------------
------------------------------------------------------------------------

						------------------------------------------------------------------
						------------------------------------------------------------------
						---------------------BEGIN MT CheckTable--------------------------
						------------------------------------------------------------------
						------------------------------------------------------------------
						IF @DBInternalThreads > 1
						BEGIN --@DBInternalThreads > 1

---------------------------------------------------------------------------------															          
---------------------------------------------------------------------------------
------------------ BEGIN Pre Service Check---------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
DECLARE @ServiceOn BIT;
EXEC Minion.DBMaintServiceCheck @ServiceStatus = @ServiceOn OUTPUT;

IF @ServiceOn = 0
BEGIN -- PRE Service Off
DECLARE @FatalError VARCHAR(200);
SET @FatalError = 'FATAL ERROR: You have configured a multi-threaded run and the Agent service is turned off.  You must turn the Agent service on or configure this as a single-threaded run.'
    RAISERROR (@FatalError, 16, 1); 
    RETURN;	
END -- PRE Service Off

---------------------------------------------------------------------------------															          
---------------------------------------------------------------------------------
------------------ END Pre Service Check-----------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
							
							-------------------------------------------------
							--------------BEGIN PrepOnly---------------------
							-------------------------------------------------
							----In order to have all the threads pull from a central list of tables, we have to prep the list ahead of time.
							----It's too much trouble to have one of the threads do it, and this is a great solution.  Do it here before they
							----even get called.  This way when the threads spin up they can just get to work.
							SET @PrepOnly = 1;
							SET @RunPrepped = 0;
							--PRINT 'EXEC Minion.CheckDBCheckTable ' + @currDB + ',  ' + ISNULL(@Schemas, 'NULL') + ', ' + ISNULL(@Tables, 'NULL') + ', ' + CAST(@StmtOnly AS VARCHAR(1)) + ', ' + CAST(@PrepOnly AS CHAR(1)) + ', ' + CAST(@RunPrepped AS CHAR(1)) + ', ' + CAST(@ExecutionDateTime AS VARCHAR(25)) + ', ' + CAST(@DBInternalThreads AS CHAR(1));
							EXEC Minion.CheckDBCheckTable @currDB,  @Schemas, @Tables, @StmtOnly, @PrepOnly, @RunPrepped, @ExecutionDateTime, @DBInternalThreads;

						----Insert the 1st SnapshotQueue row.  This is much easier than having them fight over it in the MT SP.
						----This means that this row will always be written regardless of whether a custom snapshot is wanted.  That's ok cause it's worth it.
						----We'll also go ahead and make T1 the owner.  Again, it's better than having them fight over it.
						INSERT Minion.CheckDBTableSnapshotQueue WITH (TABLOCKX)
						SELECT @ExecutionDateTime, @DBName, NULL, NULL, 1;
							-------------------------------------------------
							--------------END PrepOnly-----------------------
							-------------------------------------------------						

							--------------------------------------------------------------------------------------------------------
							--------------------------------------------------------------------------------------------------------
							-------------------------------BEGIN MultiThread Job Create---------------------------------------------
							--------------------------------------------------------------------------------------------------------
							--------------------------------------------------------------------------------------------------------
								BEGIN --MultiThread Job Create

							--!!!!!!!!!!!!!!ExecutionDateTime below needs to be made Int'l.!!!!!!!!!!!!!!!!!!!!!!!!!!!

									BEGIN
									----Only set these manually if you've already run PrepOnly.
										SET @PrepOnly = 0;
										SET @RunPrepped = 1;
									END
							SET @i = 1;

							WHILE @i <= @DBInternalThreads
							BEGIN --While

SET @JobStepSQL = '
DECLARE @ExecutionDateTime datetime,
		@DBName varchar(400);
SET @ExecutionDateTime = ''''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''''';
SET @DBName = ''''' + @currDB + ''''';

EXEC Minion.CheckDBCheckTable 
@DBName = @DBName, 
@Schemas = NULL, 
@Tables = NULL, 
@StmtOnly = 0, 
@PrepOnly = '  + CAST(@PrepOnly AS VARCHAR(5)) + ',' +
'@RunPrepped = '  + CAST(@i AS VARCHAR(5)) + ',' +
'@ExecutionDateTime = @ExecutionDateTime,
@Thread = ' + CAST(@i AS VARCHAR(5)) + ';'

SET @JobStartSQL = @JobStepSQL
+ '

------------------------------------------------------------------------
-------------------BEGIN Log to Minion----------------------------------
------------------------------------------------------------------------
	BEGIN 
		DECLARE 
		@MinionTriggerPath varchar(1000),
		@TriggerFile VARCHAR(2000),
		@PushToMinion VARCHAR(25);
		SET @PushToMinion = (SELECT TOP 1 PushToMinion FROM Minion.CheckDBSettingsDB WHERE IsActive = 1);

		IF @PushToMinion = 1
			BEGIN
				SET @MinionTriggerPath = (SELECT TOP 1 MinionTriggerPath FROM Minion.CheckDBSettingsDB WHERE IsActive = 1);
			END

            IF @ServerInstance LIKE ''''%\%''''
                BEGIN --Begin @ServerLabel
                    SET @ServerInstance = REPLACE(@ServerInstance, ''''\'''', ''''~!~'''')
                END	--End @ServerLabel

            SET @TriggerFile = ''''Powershell "'''''''''''' + ''''''''''''''''''''''''
                + CONVERT(VARCHAR(25), @ExecutionDateTime, 21) + ''''''''''''''''''''''''''''''''
                + '''' | out-file "'''' + @MinionTriggerPath + ''''CheckDB\'''' + @ServerInstance + ''''~#~''''
                + @currDB + + ''''" -append"'''' 

            EXEC xp_cmdshell @TriggerFile, no_output;
	END
------------------------------------------------------------------------
-------------------END Log to Minion------------------------------------
------------------------------------------------------------------------
';
		
									SET @JobName = 'MinionCheckDB-CHECKTABLE-' + @currDB +  '-ThreadWorker-' + CAST(@i AS VARCHAR(5));

									SET @JobThreadSQL = '
									BEGIN TRANSACTION
									DECLARE @jobId BINARY(16)

									EXEC msdb.dbo.sp_add_job @job_name=N''' + @JobName +  ''', 
											@enabled=1, 
											@notify_level_eventlog=0, 
											@notify_level_email=0, 
											@notify_level_netsend=0, 
											@notify_level_page=0, 
											@delete_level=0, 
											@description=N''No description available.'', 
											@category_name=N''[Uncategorized (Local)]'', 
											@job_id = @jobId OUTPUT

									EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run CheckDB'', 
											@step_id=1, 
											@cmdexec_success_code=0, 
											@on_success_action=1, 
											@on_success_step_id=0, 
											@on_fail_action=2, 
											@on_fail_step_id=0, 
											@retry_attempts=0, 
											@retry_interval=0, 
											@os_run_priority=0, @subsystem=N''TSQL'', 
											@command=N''' + @JobStepSQL + ''',
											@database_name=N''' + @MaintDB + ''', 
											@flags=0
									EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
									COMMIT TRANSACTION
									GO
									'
									EXEC(@JobThreadSQL)
								SET @i = @i + 1;
								SET @JobStartSQL = 'EXEC msdb.dbo.sp_start_job @job_name = ''' + @JobName + ''''
								PRINT @JobStartSQL
								EXEC(@JobStartSQL)	
								WAITFOR DELAY '0:0:02'
							END --While

							END --MultiThread Job Create
							--------------------------------------------------------------------------------------------------------
							--------------------------------------------------------------------------------------------------------
							-------------------------------END MultiThread Job Create-----------------------------------------------
							--------------------------------------------------------------------------------------------------------
							--------------------------------------------------------------------------------------------------------


							----------------------------------------------------------------------------------
							----------------------------------------------------------------------------------
							-------------------BEGIN Thread Waiter--------------------------------------------
							----------------------------------------------------------------------------------
							----------------------------------------------------------------------------------
							----While the threads are running we need to wait because once the jobs are started the SP
							----doesn't stick around until they complete.  It starts them and moves on.  So the SP
							----will exit quickly after the jobs are started and we've got other stuff that needs doing
							----like post code, and final logging, etc.  So we need the SP to stay active until the jobs are finished.
							----So we're going to check for the jobs running in a loop until they all finish.
							----We'll check every 5secs.  That's a decent time because it doesn't have to be down to the second.
							----It's not going to matter if the job time reads an extra 30secs.  However if anyone wants to change this value then
							----they're certainly welcome to.

							SET @NumWorkerThreadsRunning = 1; --initial seed value.
							SET @LoopDelaySecs = '0:0:05';
							WAITFOR DELAY @LoopDelaySecs
							WHILE @NumWorkerThreadsRunning > 0
								BEGIN --WHILE
									SET @NumWorkerThreadsRunning = (SELECT COUNT(*)
												FROM sys.dm_exec_sessions es 
													INNER JOIN msdb.dbo.sysjobs sj 
													ON sj.job_id = CAST(CONVERT( BINARY(16), SUBSTRING(es.program_name , 30, 34), 1) AS UNIQUEIDENTIFIER) 
												WHERE program_name LIKE 'SQLAgent - TSQL JobStep (Job % : Step %)' 
												AND sj.name LIKE 'MinionCheckDB-CHECKTABLE-%')

								IF @NumWorkerThreadsRunning > 0
									BEGIN
										WAITFOR DELAY @LoopDelaySecs
									END

								IF @NumWorkerThreadsRunning = 0
									BEGIN

										---------------------------------------
										------------BEGIN Delete Jobs----------
										---------------------------------------
										--------Cleanup jobs from current run. The jobs are only meant to be temp so we're assuming we're ending cleanly here which means we're free to kill them.
										--------If something happens and they don't get cleaned up then they're deleted above so the next run starts clean. 
										WHILE (1=1)
										BEGIN
											SET @jobId = NULL
											SELECT TOP 1 @jobId = job_id FROM msdb.dbo.sysjobs WHERE (name like N'MinionCheckDB-CHECKTABLE-%') 

											IF @@ROWCOUNT = 0
												BREAK

											IF (@jobId IS NOT NULL) 
											BEGIN     
												EXEC msdb.dbo.sp_delete_job @jobId 
											END 
										END
										---------------------------------------
										------------END Delete Jobs------------
										---------------------------------------

										BREAK;
									END
								END --WHILE
							----------------------------------------------------------------------------------
							----------------------------------------------------------------------------------
							-------------------END Thread Waiter----------------------------------------------
							----------------------------------------------------------------------------------
							----------------------------------------------------------------------------------

							----------------------------------------------------------------------------------
							---------------------------BEGIN Cleanup------------------------------------------
							----------------------------------------------------------------------------------
							----We need to cleanup the work tables we used for this DB.
							DELETE Minion.CheckDBTableSnapshotQueue WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @currDB;
							----------------------------------------------------------------------------------
							---------------------------END Cleanup--------------------------------------------
							----------------------------------------------------------------------------------
						
						END --@DBInternalThreads > 1

						------------------------------------------------------------------
						------------------------------------------------------------------
						---------------------END MT CheckTable----------------------------
						------------------------------------------------------------------
						------------------------------------------------------------------

					END --CheckTable Single-thread call
-------------------------------------------------------
--------------------BEGIN CheckDB Call-----------------
-------------------------------------------------------


------------------------------------------------------------------------------------------------------------				
------------------END Run CheckDB---------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------


			END --@StmtOnly = 0

------------------------------------------------------------------------------------------------------------				
------------------BEGIN StmtOnly = 1 -----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

			If @StmtOnly = 1
			BEGIN --@StmtOnly = 1
				IF @Schemas IS NULL
					BEGIN 
						SET @Schemas = 'NULL'
					END
				IF @Tables IS NULL
					BEGIN 
						SET @Tables = 'NULL'
					END
			IF UPPER(@OpName) = 'CHECKDB' OR UPPER(@OpName) = 'CHECKALLOC'
				BEGIN
					PRINT 'EXEC Minion.CheckDB @DBName = ''' + @currDB + ''', @Op = ''' + @OpName + ''''
					+ ', @StmtOnly = ' + CAST(@StmtOnly as char(1))
					PRINT 'GO'
				END

			IF UPPER(@OpName) = 'CHECKTABLE'
				BEGIN
					PRINT 'EXEC Minion.CheckDBCheckTable @DBName = ''' + @currDB + ''',' 
					+ CASE WHEN @Schemas = 'NULL' THEN (' @Schemas = ' + @Schemas + ',') WHEN @Schemas <> 'NULL' THEN (' @Schemas = ''' + @Schemas + ''',') END
					+ CASE WHEN @Tables = 'NULL' THEN (' @Tables = ' + @Tables + ',') WHEN @Tables <> 'NULL' THEN (' @Tables = ''' + @Tables + ''',') END
					+ ' @StmtOnly = ' + CAST(@StmtOnly as char(1))
					PRINT 'GO'
				END
			END --@StmtOnly = 1
------------------------------------------------------------------------------------------------------------				
------------------END StmtOnly = 1 -------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

		FETCH NEXT FROM DBs INTO @currDB
		END

	CLOSE DBs
	DEALLOCATE DBs

END --@NumConcurrentProcesses = 1
----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
--------------------------------------END Single-thread Run Cursor----------------------------------------
----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------





------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------BEGIN Multi-thread Run Cursor---------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------
---------------------------------------------------------------------
------------------BEGIN Insert Thread Queue--------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
IF @NumConcurrentProcesses > 1
BEGIN

	----Update the CheckDBLog table for top-level logging.
	UPDATE Minion.CheckDBLog
		SET STATUS = 'Processing MT DBs. See Minion.CheckDBLogDetails for currently processing DBs.'					
		WHERE ExecutionDateTime = @ExecutionDateTime;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
---------------------------BEGIN DBSize-----------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

----Since this is an MT run, we're going to be creating job threads that do the actual runs.
----We really want those jobs to be as dumb as possible so there're not a lot of logic to gum them up.
----This also gives us a better way to test the logic of the code being passed into the job step.
----To this end we're going to do as much as we can here to keep the job step dumb.  
----This also gives us the added benefit of knowing what ops are going to be run by inspecting the job queue table so we can
----change them during the run if we like.  This will come in handy for somebody.

-------------------------------------
---------BEGIN Sync ID Col-----------
-------------------------------------
--Reset the ID so the loop below works.
--This is the easiest way to reset it w/o
--having to switch to a new table for the rest
--of the SP.

SELECT *
INTO #CheckDBMasterDBsTemp
FROM #CheckDBMasterDBs;
TRUNCATE TABLE #CheckDBMasterDBs
INSERT #CheckDBMasterDBs
        (DBName, OpName, DBInternalThreads, IsReadOnly, StateDesc,
         CheckDBGroupOrder, CheckDBOrder)
SELECT DBName, OpName, DBInternalThreads, IsReadOnly, StateDesc,
       CheckDBGroupOrder, CheckDBOrder
FROM #CheckDBMasterDBsTemp
ORDER BY CheckDBGroupOrder, CheckDBOrder;
DROP TABLE #CheckDBMasterDBsTemp;
-------------------------------------
---------END Sync ID Col-------------
-------------------------------------
SELECT 'DBList' AS DBList, * FROM #CheckDBMasterDBs;

DECLARE @CT SMALLINT;
SET @CT = (SELECT COUNT(*) FROM #CheckDBMasterDBs);
SET @i = 1;
WHILE @i <= @CT
	BEGIN --WHILE
	SELECT @currDB = DBName
	FROM #CheckDBMasterDBs
	WHERE ID = @i;

					IF UPPER(@OpNameOrig) = 'AUTO'
						BEGIN --AUTO	
							SET @OpName = @OpNameOrig;					
							EXEC Minion.DBMaintDBSizeGet @Module = 'CHECKDB', @OpName = @OpName OUTPUT, @DBName = @currDB, @DBSize = @DBSize OUTPUT WITH RECOMPILE;

							----Get the number of threads for a CHECKTABLE to use.
							IF @DBInternalThreadsORIG IS NULL AND UPPER(@OpName) = 'CHECKTABLE'
							BEGIN --@DBInternalThreads IS NULL
								--DECLARE @SettingID INT;
								EXEC Minion.DBMaintDBSettingsGet 'CHECKDB', @currDB, 'CHECKTABLE', @SettingID = @SettingID OUTPUT;

								SELECT TOP 1
								@DBInternalThreads = DBInternalThreads
								FROM Minion.CheckDBSettingsDB
								WHERE ID = @SettingID;
							END --@DBInternalThreads IS NULL

							UPDATE #CheckDBMasterDBs
							SET OpName = @OpName,
								DBInternalThreads = @DBInternalThreads
							WHERE ID = @i;
			
						END --AUTO

					IF UPPER(@OpNameOrig) <> 'AUTO'
						BEGIN
							UPDATE #CheckDBMasterDBs
							SET OpName = @OpNameOrig,
								DBInternalThreads = @DBInternalThreads
							WHERE ID = @i;
						END
			SET @i = @i + 1;	
	END --WHILE
--------------------------------------------------------------------------
--------------------------------------------------------------------------
---------------------------END DBSize-------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

							UPDATE #CheckDBMasterDBs
							SET 
								DBInternalThreads = 1
							WHERE OpName = 'CHECKTABLE' AND DBInternalThreads IS NULL;


	INSERT Minion.CheckDBThreadQueue(ExecutionDateTime, DBName, OpName, DBInternalThreads, IsReadOnly, StateDesc, CheckDBGroupOrder, CheckDBOrder, Processing)
	SELECT @ExecutionDateTime, DBName, OpName, DBInternalThreads, IsReadOnly, StateDesc, CheckDBGroupOrder, CheckDBOrder, 0 AS Processing
	FROM #CheckDBMasterDBs
	ORDER BY CheckDBGroupOrder DESC, CheckDBOrder DESC
END
---------------------------------------------------------------------
---------------------------------------------------------------------
------------------END Insert Thread Queue----------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
----SELECT 'ThreadQ', * FROM Minion.CheckDBThreadQueue WHERE ExecutionDateTime = @ExecutionDateTime;



----SELECT 'here',* 
----FROM Minion.CheckDBThreadQueue--#CheckDBMasterDBs
----WHERE ExecutionDateTime = @ExecutionDateTime
----ORDER BY CheckDBGroupOrder DESC, CheckDBOrder DESC;


IF @NumConcurrentProcesses > 1
BEGIN --@NumConcurrentProcesses > 1




---------------------------------------------------------------------
---------------------------------------------------------------------
------------------BEGIN MT Rotation Figuring-------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
----We only want to manage a rotation if there were no DBs passed into the job.
----If you need to run a checkdb on a specific DB right now, the rotation could knock it back out because it's already been run recently.
----So in that case it would be impossible to run a DB manually while rotations are turned on.
----We don't want to be smarter than the DBA who knows he needs to run the process.  So if rotations are only available if you don't pass
----any DBs into the job.
IF EXISTS (SELECT 1 FROM [Minion].[CheckDBSettingsRotation] WHERE UPPER(OpName) = 'CHECKDB' AND IsActive = 1)
BEGIN
	IF @IncludeRAW IS NULL OR @IncludeRAW = ''
		BEGIN
			EXEC Minion.CheckDBRotationLimiter @ExecutionDateTime = @ExecutionDateTime, @OpName = @OpName;
		END
END

SET @MasterRotationLimiter = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'CHECKDB' AND DBName = 'CHECKDB'  AND SPName = 'CheckDBRotationLimiter' AND Param = '@RotationLimiter')
SET @MasterRotationLimiterMetric = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'CHECKDB' AND DBName = 'CHECKDB'  AND SPName = 'CheckDBRotationLimiter' AND Param = '@RotationLimiterMetric')
SET @MasterRotationMetricValue = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'CHECKDB' AND DBName = 'CHECKDB'  AND SPName = 'CheckDBRotationLimiter' AND Param = '@RotationMetricValue')

IF @TimeLimitInMins IS NULL
	BEGIN
		SET @TimeLimitInMins = ISNULL(@MasterRotationMetricValue, 0);
	END 

UPDATE Minion.CheckDBLog
		SET RotationLimiter = ISNULL(@MasterRotationLimiter, 'None'),
			RotationLimiterMetric = ISNULL(@MasterRotationLimiterMetric, 'None'),
			RotationMetricValue = ISNULL(@MasterRotationMetricValue, 0),
			TimeLimitInMins = @TimeLimitInMins
		WHERE ExecutionDateTime = @ExecutionDateTime;

----Log @TimeLimitInMins to the Work table so we can use it in the other SP.
INSERT Minion.Work
		(ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value)
SELECT @ExecutionDateTime, 'CHECKDB', 'CHECKDB', 'CHECKDB', '@TimeLimitInMins', 'CheckDBMaster', ISNULL(@TimeLimitInMins, 0);

---------------------------------------------------------------------
---------------------------------------------------------------------
------------------END MT Rotation Figuring---------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------


-----------------------------------
--------BEGIN Delete Jobs----------
-----------------------------------
----You can only run one multithread instance at a time. This is just a req I'm putting on the system.
----So to that end, if there are other workers that were left over from the last run, say the box bounced
----during the run, or the Agent stopped, or anything else, we need to get rid of the old jobs before we
----create the new ones.  We have to create new ones because the ExecutionDateTime is hardcoded in the job step.
----So we clearly can't use the last jobs for this run.
---Just delete them wholesale and start over. So if they're still running then tough.

WHILE (1=1)
BEGIN
    SET @jobId = NULL
    SELECT TOP 1 @jobId = job_id FROM msdb.dbo.sysjobs WHERE (name like N'MinionCheckDBThreadWorker%') 

    IF @@ROWCOUNT = 0
        BREAK

    IF (@jobId IS NOT NULL) 
    BEGIN     
        EXEC msdb.dbo.sp_delete_job @jobId 
    END 
END
---------------------------------------
------------END Delete Jobs------------
---------------------------------------



---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
--------------------------BEGIN Create Thread Jobs-------------------------------------
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
--------If we've got multiple threads defined then we're going to use different jobs to handle this.
--------This is kind of a low tech solution so it should work fairly well.
--------It's actually how people handle this anyway, they just do it manually so we're just coding something
--------that they do already.  This just ensures that they don't have to manage the process and it gives them
--------an easy and visual way to shutdown the queue if they want.

------!!!!!!!!!!!!!!ExecutionDateTime below needs to be made Int'l.!!!!!!!!!!!!!!!!!!!!!!!!!!!

---------------------------------------------------------------------------------															          
---------------------------------------------------------------------------------
------------------ BEGIN Pre Service Check---------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

EXEC Minion.DBMaintServiceCheck @ServiceStatus = @ServiceOn OUTPUT;

IF @ServiceOn = 1
BEGIN -- PRE Service On
	EXEC Minion.CheckDBThreadCreator 
	@ExecutionDateTime = @ExecutionDateTime,  
	@DBName = NULL,
	@OpName = NULL,
	@ConcurrentProcesses = @NumConcurrentProcesses, 
	@DBInternalThreads = @DBInternalThreads,
	@Schemas = @Schemas,
	@Tables = @Tables--,
	--@StartJobs = 1, 
	--@StartJobDelaySecs = '0:00:02' -- Time to wait between starting each job. Reduces possible contention.

	PRINT 'EXEC Minion.CheckDBThreadCreator 
	@ExecutionDateTime = ''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''',  
	@ConcurrentProcesses = ' + CAST(@NumConcurrentProcesses AS VARCHAR(5)) + ', 
	@DBInternalThreads = ' + ISNULL(CAST(@DBInternalThreads AS VARCHAR(5)), 'NULL') + ',
	@Schemas = ''' + ISNULL(@Schemas, 'NULL') + ''',
	@Tables = ''' + ISNULL(@Tables, 'NULL') + ''''

END -- PRE Service On

IF @ServiceOn = 0
BEGIN -- PRE Service Off
--DECLARE @FatalError VARCHAR(200);
SET @FatalError = 'FATAL ERROR: You have configured a multi-threaded run and the Agent service is turned off.  You must turn the Agent service on or configure this as a single-threaded run.'
    RAISERROR (@FatalError, 16, 1); 
    RETURN;	
END -- PRE Service Off

---------------------------------------------------------------------------------															          
---------------------------------------------------------------------------------
------------------ END Pre Service Check-----------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------



---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
--------------------------END Create Thread Jobs---------------------------------------
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------




						------------------------------------------------------------------
						------------------------------------------------------------------
						---------------------BEGIN MT CheckTable--------------------------
						------------------------------------------------------------------
						------------------------------------------------------------------

----IF UPPER(@OpName) = 'CHECKTABLE'
----	BEGIN --CHECKTABLE
	
----							--------------------------------------------------------------------------------------------------------
----							--------------------------------------------------------------------------------------------------------
----							-------------------------------BEGIN MultiThread Job Create---------------------------------------------
----							--------------------------------------------------------------------------------------------------------
----							--------------------------------------------------------------------------------------------------------
----								BEGIN --MultiThread Job Create

----							--!!!!!!!!!!!!!!ExecutionDateTime below needs to be made Int'l.!!!!!!!!!!!!!!!!!!!!!!!!!!!

----									BEGIN
----									----Only set these manually if you've already run PrepOnly.
----										SET @PrepOnly = 0;
----										SET @RunPrepped = 1;
----									END
----							SET @i = 1;

----							WHILE @i <= @DBInternalThreads
----							BEGIN --While

----SET @JobStepSQL = '
----DECLARE @ExecutionDateTime datetime,
----		@DBName varchar(400);
----SET @ExecutionDateTime = ''''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''''';
----SET @DBName = ''''' + @currDB + ''''';

----EXEC Minion.CheckTable 
----@DBName = @DBName, 
----@Schemas = NULL, 
----@Tables = NULL, 
----@StmtOnly = 0, 
----@PrepOnly = '  + CAST(@PrepOnly AS VARCHAR(5)) + ',' +
----'@RunPrepped = '  + CAST(@i AS VARCHAR(5)) + ',' +
----'@ExecutionDateTime = @ExecutionDateTime,
----@Thread = ' + CAST(@i AS VARCHAR(5)) + ';'
		
----									SET @JobName = 'MinionCheckDB-CHECKTABLE-' + @currDB +  '-ThreadWorker-' + CAST(@i AS VARCHAR(5));

----									SET @JobThreadSQL = '
----									BEGIN TRANSACTION
----									DECLARE @jobId BINARY(16)

----									EXEC msdb.dbo.sp_add_job @job_name=N''' + @JobName +  ''', 
----											@enabled=1, 
----											@notify_level_eventlog=0, 
----											@notify_level_email=0, 
----											@notify_level_netsend=0, 
----											@notify_level_page=0, 
----											@delete_level=0, 
----											@description=N''No description available.'', 
----											@category_name=N''[Uncategorized (Local)]'', 
----											@job_id = @jobId OUTPUT

----									EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run CheckDB'', 
----											@step_id=1, 
----											@cmdexec_success_code=0, 
----											@on_success_action=1, 
----											@on_success_step_id=0, 
----											@on_fail_action=2, 
----											@on_fail_step_id=0, 
----											@retry_attempts=0, 
----											@retry_interval=0, 
----											@os_run_priority=0, @subsystem=N''TSQL'', 
----											@command=N''' + @JobStepSQL + ''',
----											@database_name=N''' + @MaintDB + ''', 
----											@flags=0
----									EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
----									COMMIT TRANSACTION
----									GO
----									'
----									EXEC(@JobThreadSQL)
----								SET @i = @i + 1;
----								SET @JobStartSQL = 'EXEC msdb.dbo.sp_start_job @job_name = ''' + @JobName + ''''
----								PRINT @JobStartSQL
----								EXEC(@JobStartSQL)	
----								WAITFOR DELAY '0:0:02'
----							END --While

----							END --MultiThread Job Create
----END --CHECKTABLE


						------------------------------------------------------------------
						------------------------------------------------------------------
						---------------------END MT CheckTable----------------------------
						------------------------------------------------------------------
						------------------------------------------------------------------


							--------------------------------------------------------------------------------------------------------
							--------------------------------------------------------------------------------------------------------
							-------------------------------END MultiThread Job Create-----------------------------------------------
							--------------------------------------------------------------------------------------------------------
							--------------------------------------------------------------------------------------------------------





							----------------------------------------------------------------------------------
							----------------------------------------------------------------------------------
							-------------------BEGIN Thread Waiter--------------------------------------------
							----------------------------------------------------------------------------------
							----------------------------------------------------------------------------------
							----While the threads are running we need to wait because once the jobs are started the SP
							----doesn't stick around until they complete.  It starts them and moves on.  So the SP
							----will exit quickly after the jobs are started and we've got other stuff that needs doing
							----like post code, and final logging, etc.  So we need the SP to stay active until the jobs are finished.
							----So we're going to check for the jobs running in a loop until they all finish.
							----We'll check every 5secs.  That's a decent time because it doesn't have to be down to the second.
							----It's not going to matter if the job time reads an extra 30secs.  However if anyone wants to change this value then
							----they're certainly welcome to.

							SET @NumWorkerThreadsRunning = 1; --initial seed value.
							SET @LoopDelaySecs = '0:0:05';
							WAITFOR DELAY @LoopDelaySecs
							WHILE @NumWorkerThreadsRunning > 0
								BEGIN --WHILE
									SET @NumWorkerThreadsRunning = (SELECT COUNT(*)
												FROM sys.dm_exec_sessions es 
													INNER JOIN msdb.dbo.sysjobs sj 
													ON sj.job_id = CAST(CONVERT( BINARY(16), SUBSTRING(es.program_name , 30, 34), 1) AS UNIQUEIDENTIFIER) 
												WHERE program_name LIKE 'SQLAgent - TSQL JobStep (Job % : Step %)' 
												AND sj.name LIKE 'MinionCheckDBThreadWorker-%')

								IF @NumWorkerThreadsRunning > 0
									BEGIN
										WAITFOR DELAY @LoopDelaySecs
									END

								IF @NumWorkerThreadsRunning = 0
									BEGIN

										---------------------------------------
										------------BEGIN Delete Jobs----------
										---------------------------------------
										--------Cleanup jobs from current run. The jobs are only meant to be temp so we're assuming we're ending cleanly here which means we're free to kill them.
										--------If something happens and they don't get cleaned up then they're deleted above so the next run starts clean. 
										WHILE (1=1)
										BEGIN
											SET @jobId = NULL
											SELECT TOP 1 @jobId = job_id FROM msdb.dbo.sysjobs WHERE (name like N'MinionCheckDBThreadWorker-%') 

											IF @@ROWCOUNT = 0
												BREAK

											IF (@jobId IS NOT NULL) 
											BEGIN     
												EXEC msdb.dbo.sp_delete_job @jobId 
											END 
										END
										---------------------------------------
										------------END Delete Jobs------------
										---------------------------------------

										BREAK;
									END
								END --WHILE
							----------------------------------------------------------------------------------
							----------------------------------------------------------------------------------
							-------------------END Thread Waiter----------------------------------------------
							----------------------------------------------------------------------------------
							----------------------------------------------------------------------------------



							----------------------------------------------------------------------------------
							---------------------------BEGIN Cleanup------------------------------------------
							----------------------------------------------------------------------------------
							----We need to cleanup the work tables we used for this DB.
							DELETE Minion.CheckDBTableSnapshotQueue WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @currDB;
							----------------------------------------------------------------------------------
							---------------------------END Cleanup--------------------------------------------
							----------------------------------------------------------------------------------




END --@NumConcurrentProcesses > 1
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------END Multi-thread Run Cursor-----------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------




				--------------------------------------------------------------------------------
				---------------------BEGIN Turn OFF StatusMonitor ------------------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------

IF @StmtOnly = 0
BEGIN --@StmtOnly = 0
	EXEC Minion.DBMaintStatusMonitorONOff 'CHECKDB', 'OFF', @Version, @InstanceName
END --@StmtOnly = 0

				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------
				------------------------------END Turn OFF StatusMonitor------------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------


----------------------------------------------------------------------------------
---------------------------BEGIN Final Cleanup------------------------------------
----------------------------------------------------------------------------------
----We need to cleanup the work tables we used for this DB.
DELETE Minion.CheckDBThreadQueue WHERE ExecutionDateTime = @ExecutionDateTime;
DELETE Minion.CheckDBCheckTableThreadQueue WHERE ExecutionDateTime = @ExecutionDateTime;
----------------------------------------------------------------------------------
---------------------------END Final Cleanup--------------------------------------
----------------------------------------------------------------------------------


---------------------------------------------------------------
---------------------------------------------------------------
-------------------BEGIN Final Log-----------------------------
---------------------------------------------------------------
---------------------------------------------------------------
SET @ExecutionEndDateTime = GETDATE();

DECLARE @FinalErrorCT INT,
		@FinalWarningCT INT;
SET @FinalErrorCT = (SELECT COUNT(*) FROM Minion.CheckDBLogDetails WHERE ExecutionDateTime = @ExecutionDateTime AND (STATUS LIKE '%Complete%errors%'));
SET @FinalWarningCT = (SELECT COUNT(*) FROM Minion.CheckDBLogDetails WHERE ExecutionDateTime = @ExecutionDateTime AND (Warnings IS NOT NULL AND Warnings <> ''));


	----UPDATE Minion.CheckDBLog
	----	SET STATUS = 'Complete',
	----		NumDBsProcessed = (SELECT COUNT(DISTINCT DBName) FROM Minion.CheckDBLogDetails WHERE ExecutionDateTime = @ExecutionDateTime),
	----		ExecutionEndDateTime = GETDATE(),
	----		ExecutionRunTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @ExecutionDateTime, 21), CONVERT(VARCHAR(25), GETDATE(), 21))					
	----	WHERE ExecutionDateTime = @ExecutionDateTime;


UPDATE Minion.CheckDBLog
SET STATUS = 
			CASE 
				 --WHEN STATUS LIKE '%Complete' THEN 'All Complete'
				 WHEN (@FinalErrorCT = 0 AND @FinalWarningCT = 0) THEN 'Complete'
				 WHEN (@FinalErrorCT > 0 AND @FinalWarningCT = 0) THEN 'Complete with ' + CAST(@FinalErrorCT AS VARCHAR(10)) + ' DBCC Error' + CASE WHEN @FinalErrorCT > 1 THEN 's' ELSE '' END
				 WHEN (@FinalErrorCT = 0 AND @FinalWarningCT > 0) THEN 'Complete with ' + CAST(@FinalWarningCT AS VARCHAR(10)) + ' Warning' + CASE WHEN @FinalWarningCT > 1 THEN 's' ELSE '' END
				 WHEN (@FinalErrorCT > 0 AND @FinalWarningCT > 0) THEN 
				 ('Complete ' + CAST(@FinalErrorCT AS VARCHAR(10)) + ' DBCC Error' + CASE WHEN @FinalErrorCT > 1 THEN 's' ELSE '' END) +
				 (' and ' + CAST(@FinalWarningCT AS VARCHAR(10)) + ' Warning' + CASE WHEN @FinalWarningCT > 1 THEN 's' ELSE '' END)
			END,
				NumDBsProcessed = (SELECT COUNT(DISTINCT DBName) FROM Minion.CheckDBLogDetails WHERE ExecutionDateTime = @ExecutionDateTime),	
				ExecutionEndDateTime = @ExecutionEndDateTime,
				ExecutionRunTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @ExecutionDateTime, 21), CONVERT(VARCHAR(25), GETDATE(), 21))
WHERE ExecutionDateTime = @ExecutionDateTime
---------------------------------------------------------------
---------------------------------------------------------------
-------------------END Final Log-------------------------------
---------------------------------------------------------------
---------------------------------------------------------------


----------------------------------------------------------------------------------------
---------------------------BEGIN Force Agent Job Failure--------------------------------
----------------------------------------------------------------------------------------
DECLARE @FailureErrorCT INT,
		@FailureErrorTxt VARCHAR(1000),
		@LangFmt TINYINT;

IF (@FailJobOnError = 1 AND @FailJobOnWarning = 1)
	BEGIN --Error and Warning
	IF @FinalErrorCT > 0 OR @FinalWarningCT > 0
	BEGIN
	SET @FailureErrorTxt = 'There were errors and/or warnings in the checkdb process. You can see the errors by connecting to ' + @ServerInstance
							+ ' and running the folling query: SELECT ExecutionDateTime, STATUS, DBName, OpName, Warnings FROM [' + DB_NAME() + '].[Minion].[CheckDBLogDetails] WHERE ExecutionDateTime = ''' + CONVERT(VARCHAR(25), @ExecutionDateTime, 121) + ''''
	RAISERROR (@FailureErrorTxt, 16, 1)
	END
END --Error and Warning

IF (@FailJobOnError = 1 AND @FailJobOnWarning = 0)
	BEGIN --Error and Warning
	IF @FinalErrorCT > 0
	BEGIN
	SET @FailureErrorTxt = 'There were errors in the backup process. You can see the errors by connecting to ' + @ServerInstance
							+ ' and running the folling query: SELECT ExecutionDateTime, STATUS, DBName, BackupType, Warnings FROM [' + DB_NAME() + '].[Minion].[BackupLogDetails] WHERE ExecutionDateTime = ''' + CONVERT(VARCHAR(25), @ExecutionDateTime, 121) + ''''
	RAISERROR (@FailureErrorTxt, 16, 1)
	END
END --Error and Warning

IF (@FailJobOnError = 0 AND @FailJobOnWarning = 1)
	BEGIN --Error and Warning
	IF @FinalWarningCT > 0
	BEGIN
	SET @FailureErrorTxt = 'There were warnings in the backup process. You can see the errors by connecting to ' + @ServerInstance
							+ ' and running the folling query: SELECT ExecutionDateTime, STATUS, DBName, BackupType, Warnings FROM [' + DB_NAME() + '].[Minion].[BackupLogDetails] WHERE ExecutionDateTime = ''' + CONVERT(VARCHAR(25), @ExecutionDateTime, 121) + ''''
	RAISERROR (@FailureErrorTxt, 16, 1)
	END
END --Error and Warning

----------------------------------------------------------------------------------------
---------------------------END Force Agent Job Failure----------------------------------
----------------------------------------------------------------------------------------

------------------------------------------------------------------------
-------------------BEGIN Log to Minion----------------------------------
------------------------------------------------------------------------
If @StmtOnly = 0 AND @OpName IS NOT NULL
	BEGIN --@StmtOnly = 0
		IF @PushToMinion = 1
			BEGIN
				EXEC Minion.DBMaintLogToMinion @Module = 'CHECKDB', @DBName = @DBName, @MinionTriggerPath = @MinionTriggerPath, @ExecutionDateTime = @ExecutionDateTime, @ServerName = @ServerInstance, @Folder = 'CheckDBMaster'
			END
--SELECT @PushToMinion, @MinionTriggerPath AS TriggerPath
            ----IF @ServerInstance LIKE '%\%'
            ----    BEGIN --Begin @ServerLabel
            ----        SET @ServerInstance = REPLACE(@ServerInstance, '\', '~')
            ----    END	--End @ServerLabel


            ----SET @TriggerFile = 'Powershell "''' + ''''''
            ----    + CONVERT(VARCHAR(25), @ExecutionDateTime, 21) + ''''''''
            ----    + ' | out-file "' + @MinionTriggerPath + 'CheckDBMaster\' + @ServerInstance + '.'
            ----    + '" -append"' 

            ---- EXEC xp_cmdshell @TriggerFile, no_output;
	END --@StmtOnly = 0

------------------------------------------------------------------------
-------------------END Log to Minion------------------------------------
------------------------------------------------------------------------


GO
