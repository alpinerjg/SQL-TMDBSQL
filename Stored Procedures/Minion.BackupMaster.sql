SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [Minion].[BackupMaster] 
(
	@DBType VARCHAR(6) = NULL,
    @BackupType VARCHAR(20) = NULL,
    @StmtOnly BIT = 0 ,
    @Include VARCHAR(2000) = NULL , --Valid values: NULL|Regex|Missing|comma-separated list of DBs including wildcard searches containing '%'.
    @Exclude VARCHAR(2000) = NULL ,
    @ReadOnly TINYINT = 1,
	@Debug BIT = 0,
	@SyncSettings BIT = 0,
	@SyncLogs BIT = 0,
	@FailJobOnError BIT = 0,
	@FailJobOnWarning BIT = 0,
	@TestDateTime DATETIME = NULL
)

/*
Modification log: 
	11/9/2016 S.M. - Fixed the ordering levels, again.
*/
/***********************************************************************************

Created By: MinionWare LLC. and MidnightDBA.com

For SQL Server consulting, see our website http://www.MidnightSQL.com
No job is too big or too small.

Also, check out our FREE SQL Server training videos at http://www.MidnightDBA.com

This is a big routine with many nuances.  Our documentation is complete, but if 
you prefer, we also have videos that show you how to use each of the features.
You can find them at http://www.MidnightDBA.com/Minion

Minion Backup is a free, standalone, backup routine that is a component 
of the Minion Enterprise Management solution.

Minion Enterprise is an enterprise management solution that makes managing your 
SQL Server enterprise super easy. The backup routine folds into the enterprise 
solution with ease.  By integrating your backups into the Minion Enterprise, you 
get the ability to manage your backup parameters from a central location. And, 
Minion Enterprise provides enterprise-level reporting and alerting.
Download a 90-day trial of Minion Enterprise at http://MinionWare.net

* By running this software you are agreeing to the terms of the license agreement.
* You can find a copy of the license agreement here: http://www.midnightsql.com/minion-end-user-license-agreement/
--------------------------------------------------------------------------------

--Purpose: This procedure calls the backup procedure for the appropriate database(s).

--Walkthrough: --!--
--      1. 

--Conventions:

--Parameters:
-------------
--    @DBType				'System' or 'User'
    
--	@BackupType			'Log' or 'Full'
    
--	@StmtOnly			Valid options: 1, 0. Excellent choice for running stmts manually.  Allows you to pick and choose which backups you want to do.
    
--	@Include			Backup ONLY the databases listed here.  
--						Comma-separated like this : DB1,DB2,DB3
--						Option: use 'All' (or NULL) here to include all databases. 
--						(Used in conjunction with @DBType, this will back up all User 
--						or System databases.)
    
--	@Exclude			Do NOT back up the databases listed here.  
--						Comma-separated like this : DB1,DB2,DB3
	
--    @ReadOnly			Valid options: 1, 2, 3.  
--						1: Include ReadOnly DBs. 
--						2: Don't include ReadOnly DBs. 
--						3: Only Include ReadOnly DBs.
    
--Tables: <review>
----------
--	#BackupMasterDBs				A read-only temp table that returns the StateDesc, recovery model and
--						backup order.

--	#RegexLookUp		A temp table for excluding certain databases, such as dated ones.


--Example Executions:
--	-- Take a full backup of all user databases:
--	EXEC [Minion].[BackupMaster]
--		@DBType = 'User' ,
--		@BackupType 'Full';

--	-- Take a log backup of all user databases, except for DB1 and DB2:
--	EXEC [Minion].[BackupMaster]
--		@DBType = 'User' ,
--		@BackupType = 'Log', 
--		@Except = 'DB1, DB2';

--	-- Generate backup statements for all system databases:
--	EXEC [Minion].[BackupMaster]
--		@DBType = 'System' ,
--		@BackupType = 'Full', 
--		@Include = 'All',
--		@StmtOnly = 1;

--Revision History:
	

--***********************************************************************************/ 

AS 

    SET NOCOUNT ON

----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
---------------------------------BEGIN Define Schedule----------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----If the incoming vars are NULL then we get the value from the SettingsServer table.
IF @BackupType IS NULL
	BEGIN --Define Schedule

	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------BEGIN Reset Counter------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	----The counters are per day, so if it's a new day we'll have to reset them.
	UPDATE Minion.BackupSettingsServer
	SET CurrentNumBackups = 0
	WHERE (CONVERT(VARCHAR(10), LastRunDateTime, 101) <> CONVERT(VARCHAR(10), GETDATE(), 101) OR LastRunDateTime IS NULL)
	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------END Reset Counter--------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------


	CREATE TABLE #MasterParams
	(
		ID INT IDENTITY(1,1) NOT NULL,
		SettingServerID INT,
		DBType VARCHAR(6) COLLATE DATABASE_DEFAULT,
		BackupType VARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
		Day VARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
		ReadOnly TINYINT NULL,
		BeginTime VARCHAR(20) NULL,
		EndTime VARCHAR(20) NULL,
		MaxForTimeframe INT NULL,
		FrequencyMins INT NULL,
		CurrentNumBackups INT NULL,
		LastRunDateTime DATETIME NULL,
		Include VARCHAR(2000) COLLATE DATABASE_DEFAULT NULL,
		Exclude VARCHAR(2000) COLLATE DATABASE_DEFAULT NULL,
		SyncSettings BIT NULL,
		SyncLogs BIT NULL,
		BatchPreCode VARCHAR(MAX) COLLATE DATABASE_DEFAULT NULL,
		BatchPostCode VARCHAR(MAX) COLLATE DATABASE_DEFAULT NULL,
		Debug BIT,
		FailJobOnError BIT,
		FailJobOnWarning BIT
	)

DECLARE 
		@CurrentNumBackups INT,
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
	INSERT #MasterParams (SettingServerID, DBType, BackupType, Day, ReadOnly, BeginTime, EndTime, MaxForTimeframe, FrequencyMins, CurrentNumBackups, LastRunDateTime, Include, Exclude, SyncSettings, SyncLogs, BatchPreCode, BatchPostCode, Debug)
		SELECT
			ID, DBType, BackupType, Day, ReadOnly, BeginTime, EndTime, MaxForTimeframe, FrequencyMins, CurrentNumBackups, LastRunDateTime, Include, Exclude, SyncSettings, SyncLogs, BatchPreCode, BatchPostCode, Debug
			FROM Minion.BackupSettingsServer
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
			DELETE #MasterParams WHERE NOT (CONVERT(VARCHAR(20), @TodayTimeCompare, 114) BETWEEN CONVERT(VARCHAR(20), BeginTime, 114) AND CONVERT(VARCHAR(20), EndTime, 114)) AND (BeginTime IS NOT NULL AND EndTime IS NOT NULL)
		END
	---Delete frequencies.  Anything that is too soon to backup needs to go.
		BEGIN
			DELETE #MasterParams WHERE DATEDIFF(MINUTE, LastRunDateTime, @TodayTimeCompare) < FrequencyMins AND FrequencyMins IS NOT NULL;
		END

--SELECT 'After initial delete', * FROM #MasterParams
	-----------------------------BEGIN All High-level Settings-----------------------------
	----If today is Beginning of year then delete everything else.
	IF @IsFirstOfYear = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM #MasterParams WHERE [Day] = 'FirstOfYear')
			BEGIN
				DELETE #MasterParams  
				WHERE [Day] <> 'FirstOfYear' 
				AND DBType = 'User'
				AND ISNULL([Include], '') IN (SELECT ISNULL([Include], '') FROM #MasterParams WHERE [Day] = 'FirstOfYear')
			END
	END

	----If today is End of year then delete everything else.
	IF @IsLastOfYear = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM #MasterParams WHERE [Day] = 'LastOfYear')
			BEGIN
				DELETE #MasterParams  
				WHERE [Day] <> 'LastOfYear' 
				AND DBType = 'User'
				AND ISNULL([Include], '') IN (SELECT ISNULL([Include], '') FROM #MasterParams WHERE [Day] = 'LastOfYear')
			END
	END

	----If today is Beginning of month then delete everything else.
	IF @IsFirstOfMonth = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM #MasterParams WHERE [Day] = 'FirstOfMonth')
			BEGIN
				DELETE #MasterParams  
				WHERE [Day] <> 'FirstOfMonth' 
				AND DBType = 'User'
				AND ISNULL([Include], '') IN (SELECT ISNULL([Include], '') FROM #MasterParams WHERE [Day] = 'FirstOfMonth')
			END
	END

	----If today is End of month then delete everything else.
	IF @IsLastOfMonth = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM #MasterParams WHERE [Day] = 'LastOfMonth')
			BEGIN
				DELETE #MasterParams  
				WHERE [Day] <> 'LastOfMonth' 
				AND DBType = 'User'
				AND ISNULL([Include], '') IN (SELECT ISNULL([Include], '') FROM #MasterParams WHERE [Day] = 'LastOfMonth')
			END
	END

------------------------------------------------------------------------
---------------------BEGIN DELETE High-levels---------------------------
------------------------------------------------------------------------
--If it's not one of these high-level days, they need to be deleted.
--You can't run a FirstOfMonth if it's not the 1st of the month now can you?
IF @IsFirstOfYear = 0
	BEGIN
		DELETE #MasterParams  
		WHERE [Day] = 'FirstOfYear' 
	END

IF @IsLastOfYear = 0
	BEGIN
		DELETE #MasterParams  
		WHERE [Day] = 'LastOfYear' 
	END

IF @IsFirstOfMonth = 0
	BEGIN
		DELETE #MasterParams  
		WHERE [Day] = 'FirstOfMonth' 
	END

IF @IsLastOfMonth = 0
	BEGIN
		DELETE #MasterParams  
		WHERE [Day] = 'LastOfMonth' 
	END
------------------------------------------------------------------------
---------------------END DELETE High-levels-----------------------------
------------------------------------------------------------------------


------------------------BEGIN DELETE Named Days that Don't Match---------------
	--If there are named days, then delete everything that isn't the named day if the named day is today.
	--So if the named day is Friday and today is Monday, then it shouldn't be in the table.

			----IF EXISTS (SELECT 1 FROM #MasterParams WHERE [Day] = DATENAME(dw, @TodayDateCompare) AND CurrentNumBackups >= MaxForTimeframe)
			BEGIN
				DELETE #MasterParams  WHERE ([Day] IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') 
				AND [Day] <> DATENAME(dw, @TodayDateCompare))
			END
------------------------END DELETE Named Days that Don't Match-----------------

------------------------BEGIN DELETE Higher-level days when Today has run---------------
	--If there are named days, then delete everything that isn't the named day if the named day is today.
	--So if the named day is Friday and today is Monday, then it shouldn't be in the table.

			IF EXISTS (SELECT 1 FROM #MasterParams WHERE [Day] = DATENAME(dw, @TodayDateCompare) AND CurrentNumBackups >= MaxForTimeframe)
			BEGIN
				DELETE MP1
				FROM #MasterParams MP1
				WHERE MP1.[Day] IN ('Daily', 'Weekend', 'Weekday') 
				AND MP1.BackupType IN (SELECT BackupType FROM #MasterParams MP2 WHERE [Day] = DATENAME(dw, @TodayDateCompare) AND CurrentNumBackups >= MaxForTimeframe)
			END
------------------------END DELETE Higher-level days when Today has run-----------------


IF (@IsLastOfMonth = 0 AND @IsFirstOfMonth = 0 AND @IsFirstOfYear = 0 AND @IsLastOfYear = 0)
OR NOT EXISTS (SELECT 1 FROM #MasterParams WHERE UPPER(Day) IN ('FIRSTOFYEAR', 'FIRSTOFMONTH', 'LASTOFYEAR', 'LASTOFMONTH')) --1.3 fix.
	BEGIN -- Delete Days
		----I think this entire section should only be called if all of the above conditions are true.  
		----Those higher level settings should always override these daily settings.
	----If today is a Weekday then delete everything else.
	--IF (SELECT 1 FROM #MasterParams WHERE [Day] = 'Weekday') = 1 --Removed as 1.1 fix
	BEGIN
		IF DATENAME(dw, @TodayDateCompare) IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
			BEGIN
				DELETE #MasterParams  WHERE ([Day] NOT IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday') AND [Day] <> 'Weekday' AND [Day] <> 'Daily') AND DBType = 'User'-- Fix for 1.1: Added "AND [Day] <> 'Daily'" because it was deleting Daily rows when it shouldn't be.
			END
	END


	----If today is a Weekend then delete everything else.
	--IF (SELECT 1 FROM #MasterParams WHERE [Day] = 'Weekend') = 1 --Removed as 1.1 fix
	BEGIN
		IF DATENAME(dw, @TodayDateCompare) IN ('Saturday', 'Sunday')
			BEGIN
				DELETE #MasterParams  WHERE ([Day] NOT IN ('Saturday', 'Sunday') AND [Day] <> 'Weekend' AND [Day] <> 'Daily') AND DBType = 'User'-- Fix for 1.1: Added "AND [Day] <> 'Daily'" because it was deleting Daily rows when it shouldn't be.
			END
	END


	-----------------------------END All High-level Settings-------------------------------



	----If there are records for today, then delete everything else.
	IF EXISTS (SELECT 1 FROM #MasterParams WHERE [Day] = DATENAME(dw, @TodayDateCompare))
		BEGIN
			DELETE #MasterParams WHERE [Day] <> DATENAME(dw, @TodayDateCompare) OR [Day] IS NULL
		END

	----1.1 Fix
	----Now we should be down to just the daily runs if so, then delete everything else.
	IF EXISTS (SELECT 1 FROM #MasterParams WHERE [Day] = 'Daily')
		BEGIN
			DELETE #MasterParams WHERE [Day] IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
		END
	END -- Delete Days

	DELETE #MasterParams
	WHERE ISNULL(CurrentNumBackups, 0) >= MaxForTimeframe;
	---------------------------------------------------
	-----------------END Delete Rows-------------------
	---------------------------------------------------

	---------------------------------------------------
	-------------BEGIN Set Vars------------------------
	---------------------------------------------------

	--IF @CurrentNumBackups < @MaxForTimeframe
		BEGIN
			SELECT TOP 1
		   @MasterParamID = ID,
		   @SettingServerID = SettingServerID,
		   @DBType = DBType,
		   @MaxforTimeframe = MaxForTimeframe,
		   @CurrentNumBackups = ISNULL(CurrentNumBackups, 0),
		   @BackupType = BackupType,
		   @ReadOnly = ReadOnly,
		   @Include = Include,
		   @Exclude = Exclude,
		   @SyncSettings = SyncSettings,
		   @SyncLogs = SyncLogs,
		   @BatchPreCode = BatchPreCode,
		   @BatchPostCode = BatchPostCode,
		   @Debug = Debug,
		   @FailJobOnError = FailJobOnError,
		   @FailJobOnWarning = FailJobOnWarning
	FROM #MasterParams
	ORDER BY DBType ASC, BackupType ASC
		END

----This is here to show which schedule was picked. It's a great way to tshoot the process.
SELECT * 
FROM #MasterParams WHERE ID = @MasterParamID
---------------------------------------------------
-------------END Set Vars--------------------------
---------------------------------------------------

END --Define Schedule

	--SELECT @DBType AS DBType,
	--	   @MasterParamID AS MasterParamID,
	--	   @BackupType AS BackupType,
	--	   @ReadOnly AS ReadOnly,
	--	   @Include AS Include,
	--	   @Exclude AS exclude,
	--	   @SyncSettings AS SyncSettings,
	--	   @SyncLogs AS SyncLogs,
	--	   @BatchPreCode AS BatchPre,
	--	   @BatchPostCode AS BatchPost


----------------------------------------------------------------------------------
-----------------BEGIN Update BackupSettingsServer--------------------------------
----------------------------------------------------------------------------------
----1.1 Fix
If @StmtOnly = 0
BEGIN
	----We don't want to increment the table row if there are no rows to run.
	IF @MasterParamID IS NOT NULL
		BEGIN
			UPDATE Minion.BackupSettingsServer
			SET CurrentNumBackups = ISNULL(CurrentNumBackups, 0) + 1,
				LastRunDateTime = GETDATE()
			WHERE ID = @SettingServerID;
		END
END
----------------------------------------------------------------------------------
-----------------BEGIN Update BackupSettingsServer--------------------------------
----------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
---------------------------------END Define Schedule------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------



    DECLARE @currDB VARCHAR(100) ,
        @currTables VARCHAR(10) ,
        @currStmtOnly BIT ,
        @DBName NVARCHAR(400) ,
        @SQL NVARCHAR(200) ,
        @ExecutionDateTime DATETIME ,
		@ExecutionEndDateTime DATETIME,
        @IncludeRAW VARCHAR(2000) ,
        @ExcludeRAW VARCHAR(2000),
		@RegexCT SMALLINT,
		@LogDBType VARCHAR(6),
		@VersionRaw VARCHAR(50),
		@Version DECIMAL(3,1),
		@Edition VARCHAR(15),
		@IsPrimaryReplica BIT,
		@DBIsInAG BIT,
		@Status VARCHAR(MAX),
		@ServiceStatus BIT,
		@MonitorJobRunning BIT,
		@SettingLevel INT,
		@PreferredServer VARCHAR(150),
		@IsPrefferedReplica BIT,
		@DBIsInAGQuery VARCHAR(4000),
		@IsPrimaryReplicaQuery VARCHAR(4000),
		@Port VARCHAR(10),
        @PreCMD VARCHAR(100),
        @TotalCMD VARCHAR(2000),
		@BackupCmd VARCHAR(2000),
        @ServerInstance VARCHAR(200),
		@BatchPreCodeStartDateTime DATETIME,
		@BatchPreCodeEndDateTime DATETIME,
		@BatchPreCodeTimeInSecs INT,
		@BatchPostCodeStartDateTime DATETIME,
		@BatchPostCodeEndDateTime DATETIME,
		@BatchPostCodeTimeInSecs INT,
		@BackupLogID BIGINT,
		@BackupLogDetailsID BIGINT,
		@BackupDBErrors VARCHAR(MAX);

    SET @ExecutionDateTime = GETDATE();

------------------------------------------------------------
------------BEGIN Logic Errors------------------------------
------------------------------------------------------------

    IF UPPER(@DBType) = 'SYSTEM'
        AND UPPER(@BackupType) = 'LOG' 
        BEGIN
			INSERT Minion.BackupLog (ExecutionDateTime, STATUS, DBType, BackupType)
			SELECT @ExecutionDateTime, 'FATAL ERROR: System databases do not support log backups.  This is a logic error. Either set @DBType = ''User'', or @BackupType = ''Full''.', @DBType, @BackupType
				
            RAISERROR ('System databases do not support log backups.  This is a logic error. Either set @DBType = ''User'', or @BackupType = ''Full''.', 16, 1); 
            RETURN;		    
        END	

    IF UPPER(@DBType) = 'SYSTEM'
        AND @ReadOnly = 3 
        BEGIN
			INSERT Minion.BackupLog (ExecutionDateTime, STATUS, DBType, BackupType)
			SELECT @ExecutionDateTime, 'FATAL ERROR: System databases cannot be readonly.  This is a logic error. Either set @DBType = ''User'', or @ReadOnly = 1 or 2.', @DBType, @BackupType
			
            RAISERROR ('System databases cannot be readonly.  This is a logic error. Either set @DBType = ''User'', or @ReadOnly = 1 or 2.', 16, 1); 
            RETURN;		    
        END	
------------------------------------------------------------
------------END Logic Errors--------------------------------
------------------------------------------------------------


-------------------------------------------------------------------------
----------------BEGIN Check Cmdshell-------------------------------------
-------------------------------------------------------------------------
DECLARE @CmdshellON BIT;
SET @CmdshellON = (SELECT CAST(value_in_use AS BIT) FROM sys.configurations WHERE name = 'xp_cmdshell')
IF @CmdshellON = 0
	BEGIN

			INSERT Minion.BackupLog (ExecutionDateTime, STATUS, DBType, BackupType)
			SELECT @ExecutionDateTime, 'FATAL ERROR: xp_cmdshell is not enabled.  You must enable xp_cmdshell in order to run this procedure', @LogDBType, @BackupType
				
	END
-------------------------------------------------------------------------
-----------------END Check Cmdshell--------------------------------------
-------------------------------------------------------------------------

------------------ BEGIN Get Version Info----------------------------------------
---------------------------------------------------------------------------------
															          
	SELECT	@VersionRaw = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(15)), 4);

	SET @Version = @VersionRaw;
	SELECT	@Edition = CAST(SERVERPROPERTY('Edition') AS VARCHAR(25));

	DECLARE	@OnlineEdition BIT
	IF @Edition LIKE '%Enterprise%'
		OR @Edition LIKE '%Developer%' 
		BEGIN
			SET @OnlineEdition = 1
		END
	
	IF @Edition NOT LIKE '%Enterprise%'
		AND @Edition NOT LIKE '%Developer%' 
		BEGIN
			SET @OnlineEdition = 0
		END	

DECLARE @Instance NVARCHAR(128);
SET @Instance = (SELECT CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)));

DECLARE @InstanceName NVARCHAR(128);
SET @InstanceName = (SELECT CAST(SERVERPROPERTY('InstanceName') AS NVARCHAR(128)));

If @InstanceName IS NULL
BEGIN
SET @ServerInstance = CAST(serverproperty('MachineName') AS varchar(200));
END

If @InstanceName IS NOT NULL
BEGIN
SET @ServerInstance = CAST(serverproperty('MachineName') AS varchar(200)) + '\' + @InstanceName;
END
---------------------------------------------------------------------------------
------------------ END Get Version Info------------------------------------------
---------------------------------------------------------------------------------

    CREATE TABLE #BackupMasterDBs
        (
		  ID SMALLINT IDENTITY(1,1),
          DBName NVARCHAR(400) COLLATE DATABASE_DEFAULT ,
          IsReadOnly BIT ,
          StateDesc VARCHAR(50) COLLATE DATABASE_DEFAULT ,
          RecoveryModel VARCHAR(12) COLLATE DATABASE_DEFAULT ,
          BackupGroupOrder INT ,
          BackupGroupDBOrder INT
        )

----These vars get destroyed in the While loops below.  So they need to be preserved into another var 
----so they can be logged later.

    SET @IncludeRAW = @Include;
    SET @ExcludeRAW = @Exclude;

------------------------------------------------------------
------------BEGIN Process Included DBs----------------------
------------------------------------------------------------

----We need to save the DBGroups in a #table so we can get the escape chars for each row.
CREATE TABLE #MasterDBEscapesInclude
(
Action VARCHAR(10),
MaintType varchar(20),
GroupName VARCHAR(200),
GroupDef VARCHAR(400),
[Escape] CHAR(1)
)

CREATE TABLE #MasterDBInsertedWildcardDBs
(
DBName NVARCHAR(400)
)

-------------------------------------
------BEGIN Process Missing DBs------
-------------------------------------
----If there were DBs that errored on the last run and you need to back them up now, just 
----call this SP with @Include = 'Missing' and it will search the log for the broken DBs and back them up now.
----You have to make sure the BackupType and DBType are the same.
DECLARE @IsMissing BIT,
		@MissingDateTime datetime;
SET @IsMissing = 0;

IF UPPER(@Include) = 'MISSING'
	BEGIN
		SET @IsMissing = 1;
		SET @MissingDateTime = (SELECT MAX(BD2.ExecutionDateTime) FROM Minion.BackupLogDetails BD2 WHERE BackupType = @BackupType AND DBType = @DBType);

			SET @Include = (SELECT DISTINCT STUFF(( SELECT ',' + BD1.DBName FROM Minion.BackupLogDetails BD1 
			WHERE ExecutionDateTime = @MissingDateTime		
			AND BackupType = @BackupType
			AND (PctComplete < 100
			OR PctComplete IS NULL)
				  FOR
					XML PATH('')
				  ), 1, 1, '')
			FROM Minion.BackupLogDetails AS T2);
	END

-------------------------------------
------END Process Missing DBs--------
-------------------------------------

    ---- If @Include has a list of databases...
    IF UPPER(@Include) <> 'ALL' AND @Include IS NOT NULL AND UPPER(@Include) <> 'REGEX'
        BEGIN -- <> All
			--Get rid of any spaces in the DB list.
            SET @Include = REPLACE(@Include, ', ', ',');
			
            DECLARE @IncludeDBNameTable TABLE ( DBName NVARCHAR(400) );
            DECLARE @IncludeDBNameString NVARCHAR(500);
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
		AND (UPPER(MaintType) = 'BACKUP' OR UPPER(MaintType) = 'ALL')
		AND GroupName = @currDB
		AND IsActive = 1;

FETCH NEXT FROM GroupDBs INTO @currDB
	END

CLOSE GroupDBs
DEALLOCATE GroupDBs


INSERT #MasterDBEscapesInclude
        (Action, MaintType, GroupName, GroupDef, [Escape])
SELECT Action, MaintType, GroupName, GroupDef, [Escape]
FROM [Minion].[DBMaintDBGroups]
WHERE GroupName IN (SELECT REPLACE(DBName, 'DBGROUP:', '') FROM @IncludeDBNameTable WHERE REPLACE(DBName, 'DBGROUP:', '') = REPLACE(DBName, 'DBGROUP:', '')
AND DBName LIKE 'DBGROUP:%')
AND UPPER(Action) = 'INCLUDE'
AND (UPPER(MaintType) = 'BACKUP' OR UPPER(MaintType) = 'ALL')
---Now delete the LIKE DBs that were passed into the param as the actual DB names are in the table now.
DELETE @IncludeDBNameTable
WHERE UPPER(DBName) LIKE '%DBGROUP:%' 

END --@IncludeRAW
-------------------END DBGroups----------------------------------

------------------------------------
----BEGIN Insert Static DB Names----
------------------------------------
--These are the actual DB names passed into the @Include param.
                INSERT  #BackupMasterDBs (DBName, IsReadOnly, StateDesc, RecoveryModel, BackupGroupOrder, BackupGroupDBOrder)
                        SELECT  ID.DBName COLLATE DATABASE_DEFAULT, 
						SD.is_read_only, SD.state_desc COLLATE DATABASE_DEFAULT, 
						SD.recovery_model_desc COLLATE DATABASE_DEFAULT
						, 0, 0
                        FROM @IncludeDBNameTable ID
						INNER JOIN master.sys.databases SD WITH (NOLOCK)
						ON ID.DBName COLLATE DATABASE_DEFAULT = SD.name COLLATE DATABASE_DEFAULT
						WHERE ID.DBName NOT LIKE '%\%%' ESCAPE '\'
				UNION
						SELECT DBName COLLATE DATABASE_DEFAULT
						, NULL, NULL, NULL, NULL, NULL
						FROM @IncludeDBNameTable
						WHERE DBName COLLATE DATABASE_DEFAULT LIKE '%\%%' ESCAPE '\'

------------------------------------
----END Insert Static DB Names------
------------------------------------


-------------------------------------------
----BEGIN Missing DBs of Wrong DBType------
-------------------------------------------
----If you're backing up missing DBs from the last run, then the routine may have been stopped before it filled in the DBType in the log.
----If that's the case then you'll need to get rid of the unwanted DBType here.
----The DBs have already been put into #BackupMasterDBs, so this is the perfect place to get to only the list you want.
IF @IsMissing = 1
BEGIN --@IsMissing = 1
	IF @BackupType = 'User'
		BEGIN
			DELETE FROM #BackupMasterDBs
			WHERE DBName IN ('master', 'msdb', 'tempdb', 'model')
		END
	IF @BackupType = 'System'
		BEGIN
			DELETE FROM #BackupMasterDBs
			WHERE DBName NOT IN ('master', 'msdb', 'tempdb', 'model')
		END

END --@IsMissing = 1
-------------------------------------------
----END Missing DBs of Wrong DBType--------
-------------------------------------------

----------------Insert LIKE Include DB Names----------------
--You can mix static and LIKE DB names so here's where we're processing the LIKE names.

DECLARE @Escape CHAR(1);
IF @IncludeRAW LIKE '%\%%' ESCAPE '\' OR UPPER(@IncludeRAW) LIKE '%DBGROUP:%'
BEGIN --@IncludeRAW
DECLARE LikeDBs CURSOR
STATIC
FOR SELECT DBName
FROM #BackupMasterDBs
WHERE DBName LIKE '%\%%' ESCAPE '\' 

OPEN LikeDBs

	FETCH NEXT FROM LikeDBs INTO @currDB
	WHILE (@@fetch_status <> -1)
	BEGIN

	SET @Escape = (SELECT [Escape] FROM #MasterDBEscapesInclude WHERE GroupDef = @currDB);

		INSERT #BackupMasterDBs (DBName, IsReadOnly, StateDesc, RecoveryModel, BackupGroupOrder, BackupGroupDBOrder)
		SELECT name, is_read_only, state_desc, recovery_model_desc, 0, 0
		FROM master.sys.databases WITH (NOLOCK)
		WHERE name LIKE @currDB ESCAPE @Escape
			  AND name NOT IN ('master', 'msdb', 'tempdb', 'model')

----We have to insert the Actual DB names from sys.databases here.  Currently, #BackupMasterDBs still holds the wildcards passed
----in from the @Include var and we're inserting the names into this same table.  So if the DB itself has a wildcard in it, then 
----it too will be deleted from the list and never backed up.  So we put the DB names themselves into this table so when the delete
----happens just below this cursor, we can filter out the actual DB names and just delete the wildcards we don't want.
----If the above insert ever changes, then we'll also need to change this one as we're selecting the same data criteria. 
		INSERT #MasterDBInsertedWildcardDBs (DBName)
		SELECT name
		FROM master.sys.databases WITH (NOLOCK)
		WHERE name LIKE @currDB ESCAPE @Escape
			  AND name NOT IN ('master', 'msdb', 'tempdb', 'model')
		
FETCH NEXT FROM LikeDBs INTO @currDB
	END

CLOSE LikeDBs
DEALLOCATE LikeDBs

---Now delete the LIKE DBs that were passed into the param as the actual DB names are in the table now.
---This is where we join to the #table we insterted above so we can keep the actual DBs we got from sys.databases.
DELETE #BackupMasterDBs
WHERE DBName LIKE '%\%%' ESCAPE '\'
AND DBName NOT IN (SELECT DBName FROM #MasterDBInsertedWildcardDBs)

TRUNCATE TABLE #MasterDBInsertedWildcardDBs;
DROP TABLE #MasterDBEscapesInclude;

END --@IncludeRAW
-------------------END LIKE Include DB Names---------------------


        END -- <> All AND IS NOT NULL

    IF UPPER(@Include) = 'ALL' OR (@Include IS NULL AND @IsMissing = 0)
	BEGIN --@Include = 'All' OR @Include IS NULL 
        IF @BackupType = 'Full' OR @BackupType = 'Diff' 
            BEGIN -- @BackupType = 'Full'
	
                BEGIN -- = 'All'

                    IF @DBType = 'System' 
                        BEGIN
                            INSERT  #BackupMasterDBs
                                    SELECT  name ,
                                            is_read_only ,
                                            state_desc ,
                                            recovery_model_desc ,
                                            0 ,
                                            0
                                    FROM    master.sys.databases WITH (NOLOCK)
                                    WHERE   name IN ( 'master', 'msdb',
                                                      'model' )
											AND source_database_id IS NULL
                        END
        
                    IF @DBType = 'User' 
                        BEGIN
                            INSERT  #BackupMasterDBs
                                    SELECT  name ,
                                            is_read_only ,
                                            state_desc ,
                                            recovery_model_desc ,
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
                    FROM    Minion.BackupSettings
                    WHERE   DBName = 'MinionDefault' AND IsActive = 1;

                    UPDATE  #BackupMasterDBs
                    SET     BackupGroupOrder = @GroupOrder ,
                            BackupGroupDBOrder = @GroupDBOrder;

						---------------------------------------
						-----END Set Default Settings----------
						---------------------------------------
					                        
						---------------------------------------
						-----BEGIN Set DB Override Settings----
						---------------------------------------
  ----!!!This has been moved right above the Run cursor because that's really where it belongs anyway.
  ----You shouldn't worry about sorting the DBs until you get down to the final list.
       --             UPDATE  D
       --             SET     D.BackupGroupOrder = DBM.GroupOrder ,
       --                     D.BackupGroupDBOrder = DBM.GroupDBOrder,
							--@Port = Port
       --             FROM    #BackupMasterDBs D
       --                     INNER JOIN Minion.BackupSettings DBM WITH ( NOLOCK ) ON DBM.DBName = D.DBName
							--WHERE DBM.IsActive = 1
						---------------------------------------
						-----END Set DB Override Settings------
						---------------------------------------


						---------------------------------------
						-----BEGIN ReadOnly DBs----------------
						---------------------------------------

                    IF @ReadOnly = 2 
                        BEGIN
                            DELETE  #BackupMasterDBs
                            WHERE   IsReadOnly = 1
                        END
                            
                    IF @ReadOnly = 3 
                        BEGIN
                            DELETE  #BackupMasterDBs
                            WHERE   IsReadOnly = 0
                        END

						---------------------------------------
						-----END ReadOnly DBs------------------
						---------------------------------------


                END -- = 'All'
            END -- @BackupType = 'Full'


    IF @BackupType = 'Log' 
        BEGIN -- @BackupType = 'Log'
	
            BEGIN -- = 'All'
        
                IF @DBType = 'User' 
                    BEGIN
                        INSERT  #BackupMasterDBs
                                SELECT  name ,
                                        is_read_only ,
                                        state_desc ,
                                        recovery_model_desc ,
                                        0 ,
                                        0
       FROM    master.sys.databases WITH (NOLOCK)
                                WHERE   name NOT IN ( 'master', 'msdb',
                                                      'model', 'tempdb' )
                                        AND recovery_model_desc <> 'Simple'
                                        AND state_desc = 'ONLINE'
                                        AND is_read_only = 0
										AND source_database_id IS NULL
                    END
                        
            END -- = 'All'
        END -- @BackupType = 'Log'

 
 END --@Include = 'All' OR @Include IS NULL    
------------------------------------------------------------
------------END Process Included DBs------------------------
------------------------------------------------------------

						---------------------------------------
						-----BEGIN Delete ExcludeFromBackup----
						---------------------------------------

IF (SELECT COUNT(*) FROM Minion.BackupSettings WHERE DBName = 'MinionDefault' AND Exclude = 1 AND IsActive = 1 AND (BackupType = 'All' OR BackupType = @BackupType)) > 0
BEGIN
	TRUNCATE TABLE #BackupMasterDBs;

	RAISERROR ('All DBs have been excluded because of the ''MinionDefault'' setting in Minion.BackupSettings. Set Exclude = 0 for BackupType = ''All'' or BackupType = @BackupType.', 16, 1); 
            RETURN;
END

IF @IncludeRAW IS NULL
	BEGIN	
        DELETE  D
        FROM    #BackupMasterDBs D
                INNER JOIN Minion.BackupSettings DBM WITH ( NOLOCK ) ON DBM.DBName = D.DBName
        WHERE   DBM.Exclude = 1
			AND (UPPER(DBM.BackupType) = 'ALL' OR DBM.BackupType = @BackupType)
				AND IsActive = 1
	END
						---------------------------------------
						-----END Delete ExcludeFromBackup------
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

IF UPPER(@Include) = 'REGEX' AND (@Exclude IS NULL OR @Exclude = '')
BEGIN --@Include = 'Regex' AND (@Exclude IS NULL OR @Exclude = '')
IF @Version >= 10.0
BEGIN --@Version >= 10
        SELECT DISTINCT
                DFL.Regex,
                DFL.Action
		INTO #RegexMatchInclude
        FROM    Minion.DBMaintRegexLookup DFL
        WHERE   Action = 'Include'
                AND ( MaintType = 'All'
                      OR MaintType = 'Backup'
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


    DECLARE BackupMasterRunDBsDBs CURSOR READ_ONLY
    FOR
	SELECT * FROM #RegexMatchInclude

    OPEN BackupMasterRunDBsDBs

    FETCH NEXT FROM BackupMasterRunDBsDBs INTO @Regex, @Action
    WHILE ( @@fetch_status <> -1 ) 
        BEGIN

            SET @RegexCMD = 'EXEC xp_cmdshell ''powershell "'

			IF @Version = 10.0 OR @Version = 10.5
			BEGIN
                SET @RegexCMD = @RegexCMD  + 'ADD-PSSNAPIN SQLServerCmdletSnapin100; '
			END

			IF @Version >= 11
			BEGIN
                SET @RegexCMD = @RegexCMD  + 'IMPORT-MODULE SQLPS -DisableNameChecking -WarningAction SilentlyContinue; '
			END
            SET @RegexCMD = @RegexCMD + '$DBList = invoke-sqlcmd -serverinstance "' + @Instance + '" -database master -query ''''select Name from master..sysdatabases''''; $FinalList = $DBList | ?{$_.Name -match '''''
                        + @Regex + '''''}; $FinalList"  '''	

            INSERT  #RegexLookupInclude
                    ( DBName )
                    EXEC ( @RegexCMD
                        ) 

            FETCH NEXT FROM BackupMasterRunDBsDBs INTO @Regex, @Action
        END

    CLOSE BackupMasterRunDBsDBs
    DEALLOCATE BackupMasterRunDBsDBs


--Get rid of any rows that aren't actually DBNames.  The cmdshell gives us back some crap with our results.-
    DELETE  #RegexLookupInclude
    WHERE   DBName IS NULL


 INSERT  #BackupMasterDBs
    SELECT  name ,
            is_read_only ,
            state_desc ,
            recovery_model_desc ,
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
        FROM  #BackupMasterDBs AS T1
        ORDER BY T1.ID
      FOR
        XML PATH('')
      ), 1, 1, '')
FROM #BackupMasterDBs AS T2;
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
		AND (UPPER(MaintType) = 'BACKUP' OR UPPER(MaintType) = 'ALL')
		AND GroupName = @currDB
		AND IsActive = 1;

		--INSERT #BackupMasterDBs (DBName, IsReadOnly, StateDesc, RecoveryModel, BackupGroupOrder, BackupGroupDBOrder)
		--SELECT name, is_read_only, state_desc, recovery_model_desc, 0, 0
		--FROM master.sys.databases WITH (NOLOCK)
		--WHERE name IN (SELECT DBName FROM Minion.BackupSettings WHERE DBGroup = @currDB)
		--	  AND name NOT IN ('master', 'msdb', 'tempdb', 'model')
		
FETCH NEXT FROM GroupDBs INTO @currDB
	END

CLOSE GroupDBs
DEALLOCATE GroupDBs


CREATE TABLE #MasterDBEscapesExclude
(
Action VARCHAR(10),
MaintType varchar(20),
GroupName VARCHAR(200),
GroupDef VARCHAR(400),
[Escape] CHAR(1)
)

INSERT #MasterDBEscapesExclude
        (Action, MaintType, GroupName, GroupDef, [Escape])
SELECT Action, MaintType, GroupName, GroupDef, [Escape]
FROM [Minion].[DBMaintDBGroups]
WHERE GroupName IN (SELECT REPLACE(DBName, 'DBGROUP:', '') FROM @ExcludeDBNameTable WHERE REPLACE(DBName, 'DBGROUP:', '') = REPLACE(DBName, 'DBGROUP:', '')
AND DBName LIKE 'DBGROUP:%')
AND UPPER(Action) = 'EXCLUDE'
AND (UPPER(MaintType) = 'BACKUP' OR UPPER(MaintType) = 'ALL')

---Now delete the LIKE DBs that were passed into the param as the actual DB names are in the table now.
DELETE @ExcludeDBNameTable
WHERE UPPER(DBName) LIKE '%DBGROUP:%' 

END --@ExcludeRAW
-------------------END DBGroups----------------------------------



--You can mix static and LIKE DB names so here's where we're processing the LIKE names.

IF @ExcludeRAW LIKE '%\%%' ESCAPE '\' OR UPPER(@ExcludeRAW) LIKE '%DBGROUP:%'
BEGIN --@ExcludeRAW
DECLARE LikeDBs CURSOR
STATIC
FOR SELECT DBName
FROM @ExcludeDBNameTable
WHERE DBName LIKE '%\%%' ESCAPE '\' 

OPEN LikeDBs

	FETCH NEXT FROM LikeDBs INTO @currDB
	WHILE (@@fetch_status <> -1)
	BEGIN

	SET @Escape = (SELECT [Escape] FROM #MasterDBEscapesInclude WHERE GroupDef = @currDB);
		INSERT @ExcludeDBNameTable (DBName)
		SELECT name
		FROM master.sys.databases WITH (NOLOCK)
		WHERE name LIKE @currDB ESCAPE @Escape
			  AND name NOT IN ('master', 'msdb', 'tempdb', 'model')

----We have to insert the Actual DB names from sys.databases here.  Currently, #BackupMasterDBs still holds the wildcards passed
----in from the @Include var and we're inserting the names into this same table.  So if the DB itself has a wildcard in it, then 
----it too will be deleted from the list and never backed up.  So we put the DB names themselves into this table so when the delete
----happens just below this cursor, we can filter out the actual DB names and just delete the wildcards we don't want.
----If the above insert ever changes, then we'll also need to change this one as we're selecting the same data criteria. 
		INSERT #MasterDBInsertedWildcardDBs (DBName)
		SELECT name
		FROM master.sys.databases WITH (NOLOCK)
		WHERE name LIKE @currDB ESCAPE @Escape
			  AND name NOT IN ('master', 'msdb', 'tempdb', 'model')

		
FETCH NEXT FROM LikeDBs INTO @currDB
	END

CLOSE LikeDBs
DEALLOCATE LikeDBs

---Now delete the LIKE DBs that were passed into the param as the actual DB names are in the table now.
DELETE @ExcludeDBNameTable
WHERE DBName LIKE '%\%%' ESCAPE '\'
AND DBName NOT IN (SELECT DBName FROM #MasterDBInsertedWildcardDBs)

TRUNCATE TABLE #MasterDBInsertedWildcardDBs;

END --@ExcludeRAW
-------------------END LIKE Include DB Names---------------------

            DELETE  DBs
            FROM    #BackupMasterDBs DBs
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


IF UPPER(@ExcludeRAW) = 'REGEX' AND (UPPER(@IncludeRAW) = 'ALL' OR @IncludeRAW IS NULL)
BEGIN --@ExcludeRAW = 'Regex'
	IF @Version >= 10.0
	BEGIN --@Version >= 10
			SELECT DISTINCT
					DFL.Regex,
					DFL.Action
			INTO #RegexMatchExclude
			FROM    Minion.DBMaintRegexLookup DFL
			WHERE   Action = 'Exclude'
					AND ( MaintType = 'All'
						  OR MaintType = 'Backup'
						)

	SET @RegexCT = (SELECT COUNT(*) FROM #RegexMatchExclude)

	IF @RegexCT > 0

	BEGIN --@RegexCT > 0

		DECLARE BackupMasterRunDBsRegexDBs CURSOR READ_ONLY
		FOR
			SELECT DISTINCT
					DFL.Regex ,
					DFL.Action
			FROM    Minion.DBMaintRegexLookup DFL
			WHERE   Action = 'Exclude'
					AND ( MaintType = 'All'
						  OR MaintType = 'Backup'
						)

		OPEN BackupMasterRunDBsRegexDBs

		FETCH NEXT FROM BackupMasterRunDBsRegexDBs INTO @Regex, @Action
		WHILE ( @@fetch_status <> -1 ) 
			BEGIN
				SET @RegexCMD = 'EXEC xp_cmdshell ''powershell "'
				SET @RegexCMD = @RegexCMD  + 'IMPORT-MODULE SQLPS -DisableNameChecking; '
				SET @RegexCMD = @RegexCMD + '$DBList = invoke-sqlcmd -serverinstance "' + @Instance + '" -database master -query ''''select Name from master..sysdatabases''''; $FinalList = $DBList | ?{$_.Name -match '''''
				+ @Regex + '''''}; $FinalList"  '''	

				INSERT  #RegexLookupExclude
						( DBName )
						EXEC ( @RegexCMD
							) 

				FETCH NEXT FROM BackupMasterRunDBsRegexDBs INTO @Regex, @Action
			END

		CLOSE BackupMasterRunDBsRegexDBs
		DEALLOCATE BackupMasterRunDBsRegexDBs


	--Get rid of any rows that aren't actually DBNames.  The cmdshell gives us back some crap with our results.-
		DELETE  #RegexLookupExclude
		WHERE   DBName IS NULL;

	--Delete DBs that are meant to be excluded off of the Regex search.
		DELETE  DBs
		FROM    #BackupMasterDBs DBs
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


------------------------BEGIN Set DBType---------------------------------
IF @DBName IN ('master', 'msdb', 'model', 'distribution')
   SET @LogDBType = 'System'

IF @DBName NOT IN ('master', 'msdb', 'model', 'distribution')
   SET @LogDBType = 'User'
------------------------END Set DBType-----------------------------------


------------------------------------------------------------------------
------------------------------------------------------------------------
------------------BEGIN Exclude HA Considerations-----------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
--These are excluded after everything else because no matter what else is in place, these are not negotiable.
--If a DB isn't a mirror principle (or any other HA scenario 2ndary), then it can't be backed up regardless of your desire.

------Delete Mirroring 2ndaries.
DELETE D
FROM #BackupMasterDBs D
INNER JOIN sys.database_mirroring dm
ON D.DBName COLLATE DATABASE_DEFAULT = DB_NAME(dm.database_id) 
WHERE (UPPER(dm.mirroring_role_desc) COLLATE DATABASE_DEFAULT <> 'PRINCIPAL' AND dm.mirroring_role_desc IS NOT NULL)

------Delete Log Shipping 2ndaries.
DELETE D
FROM #BackupMasterDBs D
INNER JOIN msdb.dbo.log_shipping_secondary_databases dm
ON D.DBName COLLATE DATABASE_DEFAULT = dm.secondary_database COLLATE DATABASE_DEFAULT


------------------------------------------------------------------------
------------------------------------------------------------------------
------------------END Exclude HA Considerations-------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------

------------------------------------------------------------
------------------------------------------------------------
------------BEGIN Remove DBs with No Log Backup-------------
------------------------------------------------------------
------------------------------------------------------------
--If it's a log backup it'll fail if there isn't a restore base.
--So to prevent that, we're deleting all DBs that haven't had a
--log backup yet.

IF UPPER(@BackupType) = 'LOG'
	BEGIN
		DELETE #BackupMasterDBs
		WHERE DBName IN
		(
			SELECT 
			d.name COLLATE DATABASE_DEFAULT
			FROM sys.database_recovery_status drs 
			JOIN sys.databases d WITH (NOLOCK)
			ON d.database_id = drs.database_id
			WHERE drs.last_log_backup_lsn IS NULL
		)
	END
------------------------------------------------------------
------------------------------------------------------------
------------END Remove DBs with No Log Backup---------------
------------------------------------------------------------
------------------------------------------------------------



------------------------------------------------------------
------------------------------------------------------------
------------BEGIN Remove Diff DBs with No Full Backup-------
------------------------------------------------------------
------------------------------------------------------------
--If it's a diff backup it'll fail if there isn't a restore base.
--So to prevent that, we're deleting all DBs that haven't had a
--full backup yet.

IF UPPER(@BackupType) = 'DIFF'
	BEGIN
		DELETE #BackupMasterDBs
		WHERE DBName IN
		(
			SELECT 
			d.name COLLATE DATABASE_DEFAULT
			FROM sys.master_files drs WITH (NOLOCK)
			JOIN sys.databases d 
			ON d.database_id = drs.database_id
			WHERE drs.differential_base_guid IS NULL
				AND drs.type_desc = 'ROWS'
		)
	END
------------------------------------------------------------
------------------------------------------------------------
------------END Remove Diff DBs with No Full Backup---------
------------------------------------------------------------
------------------------------------------------------------



------------------------------------------------------------
------------------------------------------------------------
------------BEGIN Delete DBs That Never Backup--------------
------------------------------------------------------------
------------------------------------------------------------
--If it's a log backup it'll fail if there isn't a restore base.
--So to prevent that, we're deleting all DBs that haven't had a
--log backup yet.

	BEGIN
		DELETE #BackupMasterDBs
		WHERE DBName IN
		(
		'ReportServerTempDB'
		)
	END
------------------------------------------------------------
------------------------------------------------------------
------------END Delete DBs That Never Backup----------------
------------------------------------------------------------
------------------------------------------------------------



------------------------------------------------------------
------------------------------------------------------------
------------BEGIN Initial Log-------------------------------
------------------------------------------------------------
------------------------------------------------------------


----Get comma-delimited list of DBs that were kicked out by the Regex lookup.
    IF @StmtOnly = 0 
    BEGIN --@StmtOnly = 0 
		IF UPPER(@Include) = 'ALL' OR @Include IS NULL 			
			BEGIN
				DECLARE @RegexExcludeDBs VARCHAR(8000) 
				SELECT  @RegexExcludeDBs = COALESCE(@RegexExcludeDBs + ', ', '') + DBName
				FROM    #RegexLookupExclude
				WHERE   DBName IS NOT NULL
			END
	END --@StmtOnly = 0 

    IF @StmtOnly = 0 AND @DBType IS NOT NULL -- Dont log if there isn't going to be a run.
        BEGIN

            INSERT  Minion.BackupLog
                    ( ExecutionDateTime,
                      STATUS,
                      DBType,
					  BackupType,
                      StmtOnly,
					  NumDBsOnServer,
					  NumDBsProcessed,
                      ReadOnly,
                      IncludeDBs,
                      ExcludeDBs,
					  RegexDBsIncluded,
                      RegexDBsExcluded
                    )
                    SELECT  @ExecutionDateTime,
							'Configuring Run',
							@DBType,
							@BackupType,
							@StmtOnly,
							(SELECT COUNT(*) FROM sys.databases WITH(NOLOCK) WHERE database_id > 4 AND source_database_id IS NULL),
							(SELECT COUNT(*) FROM #BackupMasterDBs),
							@ReadOnly,
							@IncludeRAW,
							@ExcludeRAW,
							@RegexIncludeDBs,
							@RegexExcludeDBs
							
            INSERT  Minion.BackupLogDetails
                    ( ExecutionDateTime ,
					  STATUS ,
                      DBName ,
					  BackupType ,
                      READONLY,
                      StmtOnly ,
                      IncludeDBs ,
                      ExcludeDBs ,
                      BackupGroupOrder ,
                      BackupGroupDBOrder ,
                      RegexDBsExcluded
                    )
                    SELECT  @ExecutionDateTime ,
                            'In Queue' ,
                            DBName ,
							@BackupType ,
                            @ReadOnly ,
                            @StmtOnly ,
                            @IncludeRAW ,
                            @ExcludeRAW ,
                            BackupGroupOrder ,
                            BackupGroupDBOrder ,
                            @RegexExcludeDBs
                    FROM    #BackupMasterDBs
		SET @BackupLogID = (SELECT ID FROM Minion.BackupLog WHERE ExecutionDateTime = @ExecutionDateTime AND DBType = @DBType AND BackupType = @BackupType)
        END

    IF @StmtOnly = 1 
        BEGIN
            INSERT  Minion.BackupLog
                    ( ExecutionDateTime ,
                      ReadOnly,
                      StmtOnly ,
                      IncludeDBs ,
                      ExcludeDBs ,
                      RegexDBsExcluded
                    )
                    SELECT  @ExecutionDateTime ,
                            @ReadOnly ,
                            @StmtOnly ,
                            @IncludeRAW ,
                            @ExcludeRAW ,
                            @RegexExcludeDBs
        END


------------------------------------------------------------
------------------------------------------------------------
------------END Initial Log---------------------------------
------------------------------------------------------------
------------------------------------------------------------


------------------------------------------------------------
------------------------------------------------------------
------------BEGIN Stop If Runs Exceeded---------------------
------------------------------------------------------------
------------------------------------------------------------

----SELECT @CurrentNumBackups CurrentNumBackups, @MaxForTimeframe AS MaxForTimeframe
IF @StmtOnly = 0 
    BEGIN
		IF @CurrentNumBackups >= @MaxforTimeframe --OR @DBType IS NULL
	BEGIN
		UPDATE Minion.BackupLog
			SET STATUS = 'FATAL ERROR: The number of executions for backup type ''' + ISNULL(@BackupType, '') + ''' and DBType ''' + ISNULL(@DBType, '') + ''' have been exceeded.  This setting comes from the Minion.BackupSettingsServer table.  The setting that was chosen out of the table is ID = ' + ISNULL(CAST(@MasterParamID AS VARCHAR(5)), '<no row available>')
			WHERE ID = @BackupLogID;

		UPDATE Minion.BackupLogDetails
			SET STATUS = 'FATAL ERROR: The number of executions for backup type ''' + ISNULL(@BackupType, '') + ''' and DBType ''' + ISNULL(@DBType, '') + ''' have been exceeded.  This setting comes from the Minion.BackupSettingsServer table.  The setting that was chosen out of the table is ID = ' + ISNULL(CAST(@MasterParamID AS VARCHAR(5)), '<no row available>')
			WHERE ExecutionDateTime = @ExecutionDateTime
				  AND BackupType = @BackupType;

		RAISERROR ('FATAL ERROR: The number of executions for this backup type have been exceeded.  This setting comes from the Minion.BackupSettingsServer table.  See Minion.BackupLog for more details.', 16, 1); 
		RETURN;	
	END
	END
------------------------------------------------------------
------------------------------------------------------------
------------END Stop If Runs Exceeded-----------------------
------------------------------------------------------------
------------------------------------------------------------



-------------------------------------------------------------------------------
--------------------BEGIN Sync Settings----------------------------------------
-------------------------------------------------------------------------------
INSERT Minion.Work
SELECT @ExecutionDateTime, 'Backup', 'MinionBatch', @BackupType, '@SyncLogs', 'BackupMaster', @SyncLogs

INSERT Minion.Work
SELECT @ExecutionDateTime, 'Backup', 'MinionBatch', @BackupType, '@SyncSettings', 'BackupMaster', @SyncSettings
-------------------------------------------------------------------------------
--------------------END Sync Settings------------------------------------------
-------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
-------------------------------------------BEGIN DBPreCode-----------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

        IF @BatchPreCode IS NOT NULL AND @BatchPreCode <> ''
            BEGIN -- @BatchPreCode IS NOT NULL AND @BatchPreCode <> ''

-----BEGIN Log------

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'BackupMaster Before Precode'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID

	INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupMaster', '@BatchPreCode', @BatchPreCode
END
-------------------DEBUG-------------------------------

                IF @BatchPreCode IS NOT NULL
                    BEGIN -- @BatchPreCode
                        IF @StmtOnly = 0
                            BEGIN -- @StmtOnly = 0
                                SET @BatchPreCodeStartDateTime = GETDATE();

                                BEGIN
                                    UPDATE
                                            Minion.BackupLog
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
 SELECT @BackupLogID AS BackupLogID
                        UPDATE
                                Minion.BackupLog
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
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'BackupMaster After Precode'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID

	INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupMaster', '@PreCodeErrors', @PreCodeErrors
END
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
                                        UPDATE
                                                Minion.BackupLog
                                            SET
                                                BatchPreCodeEndDateTime = @BatchPreCodeEndDateTime,
                                                BatchPreCodeTimeInSecs = DATEDIFF(s,
                                                              CONVERT(VARCHAR(25), @BatchPreCodeStartDateTime, 21),
                                                              CONVERT(VARCHAR(25), @BatchPreCodeEndDateTime, 21))
                                            WHERE
                                                ID = @BackupLogID;
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
                                        UPDATE
                                                Minion.BackupLog
                                            SET
                                                Warnings = ISNULL(Warnings, '')
                                                + @PreCodeErrors,
                                                BatchPreCodeEndDateTime = @BatchPreCodeEndDateTime,
                                                BatchPreCodeTimeInSecs = DATEDIFF(s,
                                                              CONVERT(VARCHAR(25), @BatchPreCodeStartDateTime, 21),
                                                              CONVERT(VARCHAR(25), @BatchPreCodeEndDateTime, 21))
                                            WHERE
                                                ID = @BackupLogID;
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

DECLARE @HasWork INT;
SET @HasWork = (SELECT COUNT(*) FROM #BackupMasterDBs)

				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------
				---------------------BEGIN PRE Service Check------------------------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------
IF @HasWork > 0
	BEGIN --HasWork ServiceCheck
		IF @Version < 10.5
		BEGIN --@Version < 10.5
				CREATE TABLE #PREService (col1 VARCHAR(1000) COLLATE DATABASE_DEFAULT)

				BEGIN
							SET @RegexCMD = 'EXEC xp_cmdshell ''powershell "'
							SET @RegexCMD = @RegexCMD + ' $a = (gwmi win32_service | ?{$_.Name -LIKE ''''SQLAgent$' + @InstanceName + '''''}).State; If($a -eq ''''Running''''){$a = 1} ELSE{$a = 0}"'''

							INSERT  #PREService
									( col1 )
									EXEC ( @RegexCMD
										) 
		-------------------DEBUG-------------------------------
		IF @Debug = 1
		BEGIN
			INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
			SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupMaster', 'PreService cmd', @RegexCMD
		END
		-------------------DEBUG-------------------------------

				SET @ServiceStatus = (SELECT TOP 1 col1 FROM #PREService)
				DROP TABLE #PREService;
				END
		END --@Version < 10.5

		IF @Version >= 10.5
		BEGIN

				SELECT @ServiceStatus = 
					CASE WHEN [status] = 4 THEN 1
					ELSE 0
					END 
				FROM sys.dm_server_services WHERE servicename LIKE '%Agent%'

		END
END--HasWork ServiceCheck
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------
				------------------------------END PRE Service Check-----------------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------


				--------------------------------------------------------------------------------
				---------------------BEGIN PRE Turn ON StatusMonitor ---------------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------

IF @HasWork > 0
BEGIN --HasWork StatusMonitor
	IF @StmtOnly = 0
	BEGIN --@StmtOnly = 0
		IF @ServiceStatus = 1
			BEGIN --@ServiceStatus = 1

				SET @MonitorJobRunning = (SELECT COUNT(*)
				FROM sys.dm_exec_sessions es 
					INNER JOIN msdb.dbo.sysjobs sj 
					ON sj.job_id = CAST(CONVERT( BINARY(16), SUBSTRING(es.program_name , 30, 34), 1) AS UNIQUEIDENTIFIER) 
				WHERE program_name LIKE 'SQLAgent - TSQL JobStep (Job % : Step %)' 
				AND sj.name = 'MinionBackupStatusMonitor')

			END --@ServiceStatus = 1

				IF @ServiceStatus = 1
				BEGIN --@ServiceStatus = 1
					IF @MonitorJobRunning = 0
					BEGIN --@MonitorJobRunning = 0
						BEGIN
							EXEC msdb.dbo.sp_start_job 'MinionBackupStatusMonitor'
						END
					END --@MonitorJobRunning = 0
		END --@ServiceStatus = 1
	END --@StmtOnly = 0
END --HasWork StatusMonitor
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------
				------------------------------END PRE Turn ON StatusMonitor --------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------


        CREATE TABLE #BackupMasterResults
            (
                ID INT IDENTITY(1, 1),
                col1 VARCHAR(MAX) COLLATE DATABASE_DEFAULT
            )

        CREATE TABLE #BackupSettings
            (
             PreferredServer VARCHAR(150) COLLATE DATABASE_DEFAULT,
			 BackupType VARCHAR(20) COLLATE DATABASE_DEFAULT 
            ) 

DECLARE @IsPrefferedReplicaTable TABLE (col1 BIT)

	DECLARE	@AGResults TABLE ( numReplicaIDs INT );
	DECLARE	@PrimaryReplica TABLE ( numReplicaIDs INT );


---------------------------------------------------------------------------------------------------------------------
--------------------------------------------BEGIN Set DB Order Override Settings-------------------------------------
---------------------------------------------------------------------------------------------------------------------
 ----Here we're ordering the DBs.  There's some complicated logic we could put in there to snipe the exact updates we're interested in,
 ----but because the result sets will be small then we can just walk the chain from top to bottom changing the ordering as we go.
 ----This way they will all be changed to MinionDefault-All, and then their orders will change as it gets more granular.
 ----This isn't a technique you could get away with on large customer result sets, but here since we'll only ever have a few thousand rows, the
 ----perf shouldn't be too bad.

                     UPDATE  D
                    SET     D.BackupGroupOrder = DBM.GroupOrder ,
                            D.BackupGroupDBOrder = DBM.GroupDBOrder,
							@Port = Port
                    FROM    #BackupMasterDBs D
                            INNER JOIN Minion.BackupSettings DBM WITH ( NOLOCK ) ON 1=1
							WHERE 
							DBM.DBName = 'MinionDefault'
							AND DBM.BackupType = 'All'
							AND DBM.IsActive = 1

                     UPDATE  D
                    SET     D.BackupGroupOrder = DBM.GroupOrder ,
                            D.BackupGroupDBOrder = DBM.GroupDBOrder,
							@Port = Port
                    FROM    #BackupMasterDBs D
                            INNER JOIN Minion.BackupSettings DBM WITH ( NOLOCK ) ON 1=1
							WHERE 
							DBM.DBName = 'MinionDefault'
							AND DBM.BackupType = @BackupType
							AND DBM.IsActive = 1

                    UPDATE  D
                    SET     D.BackupGroupOrder = DBM.GroupOrder ,
                            D.BackupGroupDBOrder = DBM.GroupDBOrder,
							@Port = Port
                    FROM    #BackupMasterDBs D
                            INNER JOIN Minion.BackupSettings DBM WITH ( NOLOCK ) ON DBM.DBName = D.DBName
							WHERE 
							DBM.BackupType = 'All'
							AND DBM.IsActive = 1


							UPDATE  D
							SET     D.BackupGroupOrder = DBM.GroupOrder ,
									D.BackupGroupDBOrder = DBM.GroupDBOrder,
									@Port = Port
							FROM    #BackupMasterDBs D
									INNER JOIN Minion.BackupSettings DBM WITH ( NOLOCK ) ON DBM.DBName = D.DBName
									WHERE 
									DBM.BackupType = @BackupType
									AND DBM.IsActive = 1

---------------------------------------------------------------------------------------------------------------------
--------------------------------------------END Set DB Order Override Settings---------------------------------------
---------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------
---------BEGIN Set Port and MaintDB---------------------------------
--------------------------------------------------------------------
 IF @ServerInstance NOT LIKE '%\%'
	BEGIN
		SET @Port = CASE WHEN @Port IS NULL AND @ServerInstance NOT LIKE '%.%' THEN '' --',' + '1433'
						 WHEN @Port IS NULL AND @ServerInstance LIKE '%.%' THEN '' --',' + '1433'
						 WHEN @Port = '1433' THEN '' --',' + '1433'
						 WHEN @Port IS NOT NULL AND @Port <> '1433' AND @ServerInstance NOT LIKE '%.%' THEN ',' + @Port
						 WHEN @Port IS NOT NULL AND @ServerInstance LIKE '%.%' THEN ''
						 END
	END
IF @ServerInstance LIKE '%\%'
	BEGIN
			SET @Port = CASE WHEN @Port IS NULL THEN ''
							 WHEN @Port IS NOT NULL AND @Port <> '1433' THEN ',' + @Port
							 END
	END

DECLARE @MaintDB sysname;
SET @MaintDB = DB_NAME();
--------------------------------------------------------------------
---------END Set Port and MaintDB-----------------------------------
--------------------------------------------------------------------
 
 	WITH CTE AS (
        SELECT  DBName, MAX(BackupGroupOrder) AS BackupGroupOrder, MAX(BackupGroupDBOrder) AS BackupGroupDBOrder
        FROM    #BackupMasterDBs
		GROUP BY DBName
		)
		SELECT DBName, CTE.BackupGroupOrder, CTE.BackupGroupDBOrder
		FROM CTE  
        ORDER BY BackupGroupOrder DESC ,
                BackupGroupDBOrder DESC

        ----SELECT   *
        ----FROM    #BackupMasterDBs
        ----ORDER BY BackupGroupOrder DESC ,
        ----        BackupGroupDBOrder DESC;

    DECLARE BackupMasterRunDBsRunDBs CURSOR READ_ONLY
    FOR
	WITH CTE AS (
        SELECT  DBName, MAX(BackupGroupOrder) AS BackupGroupOrder, MAX(BackupGroupDBOrder) AS BackupGroupDBOrder
        FROM    #BackupMasterDBs
		GROUP BY DBName
		)
		SELECT DBName
		FROM CTE  
        ORDER BY BackupGroupOrder DESC ,
                BackupGroupDBOrder DESC

  --      SELECT  DBName, MAX(BackupGroupOrder) AS BackupGroupOrder, MAX(BackupGroupDBOrder) AS BackupGroupDBOrder
  --      FROM    #BackupMasterDBs
		--GROUP BY DBName
  --      ORDER BY BackupGroupOrder DESC ,
  --              BackupGroupDBOrder DESC

    OPEN BackupMasterRunDBsRunDBs

    FETCH NEXT FROM BackupMasterRunDBsRunDBs INTO @currDB
    WHILE ( @@fetch_status <> -1 ) 
        BEGIN

----Get the current DB log record for use later.
SET @BackupLogDetailsID = (SELECT ID FROM Minion.BackupLogDetails WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @currDB AND BackupType = @BackupType )

------------------------------------------------------------
----------------BEGIN Delete Work Table---------------------
------------------------------------------------------------
----If a previous run didn't complete it may not have cleaned up the work table.
DELETE Minion.Work
WHERE ExecutionDateTime < @ExecutionDateTime
AND BackupType = @BackupType
AND DBName = @currDB
------------------------------------------------------------
----------------END Delete Work Table-----------------------
------------------------------------------------------------

            IF @StmtOnly = 0 
                BEGIN --@StmtOnly = 0 
-------Check that the DB is the Primary Replica in an AG.

SET @DBIsInAG = 0
		IF @Version >= 11 AND @OnlineEdition = 1
			BEGIN --@Version >= 11
					--- We HAVE to run this select statement as an EXEC; even with the IF, this'd generate an error on SQL 05/08.

						SET @DBIsInAGQuery = ('INSERT Minion.Work(ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value) SELECT ' 
						+ '''' + CONVERT(VARCHAR(25), @ExecutionDateTime, 121) + '''' + ', ''Backup'', ''' + @currDB + ''', ''' + 
						+ @BackupType + ''', ''@DBIsInAG'', ''BackupMaster''' + ', COUNT(replica_id) from sys.databases with(nolock) where Name = '''
						+ @currDB + ''' AND replica_id IS NOT NULL')
						EXEC (@DBIsInAGQuery)

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupMaster', '@DBIsInAGQuery', @DBIsInAGQuery
END
-------------------DEBUG-------------------------------

						SET @DBIsInAG = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'Backup' AND DBName = @currDB AND BackupType = @BackupType AND SPName = 'BackupMaster' AND Param = '@DBIsInAG')
						IF @DBIsInAG IS NULL
							BEGIN
								SET @DBIsInAG = 0
							END

					----DELETE FROM @AGResults; -- We're in a loop; clear results each time.
					--- We HAVE to run this select statement as an EXEC; even with the IF, this'd generate an error on SQL 05/08.
					IF @DBIsInAG = 1
					BEGIN --@DBIsInAG = 1			
						SET @IsPrimaryReplicaQuery = ('INSERT Minion.Work(ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value) SELECT '
						+ '''' + CONVERT(VARCHAR(25), @ExecutionDateTime, 121) + '''' + ', ''Backup'', ''' + @currDB + ''', ''' + 
						+ @BackupType + ''', ''@IsPrimaryReplica'', ''BackupMaster''' + ', count(*)        
						FROM sys.databases dbs with(nolock) INNER JOIN sys.dm_hadr_availability_replica_states ars ON dbs.replica_id = ars.replica_id WHERE dbs.name = '''
						+ @currDB + ''' AND ars.role = 1')
						EXEC (@IsPrimaryReplicaQuery)

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupMaster', '@IsPrimaryReplicaQuery', @IsPrimaryReplicaQuery
END
-------------------DEBUG-------------------------------

						SET @IsPrimaryReplica = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'Backup' AND DBName = @currDB AND BackupType = @BackupType AND SPName = 'BackupMaster' AND Param = '@IsPrimaryReplica')
							IF @IsPrimaryReplica IS NULL
							BEGIN
								SET @IsPrimaryReplica = 0
							END
					END --@DBIsInAG = 1
			END --@Version >= 11

-------------------------------------------------------------------------------------------
-----------------------BEGIN Choose AG Location--------------------------------------------
-------------------------------------------------------------------------------------------
        SET @SettingLevel = ( SELECT COUNT(*) FROM Minion.BackupSettings WHERE DBName = @currDB AND IsActive = 1)

        IF @SettingLevel > 0
            BEGIN
		
                INSERT #BackupSettings
                        (
							PreferredServer
						)
                    SELECT
                            PreferredServer
                        FROM
                            Minion.BackupSettings
                        WHERE
                            DBName = @DBName
                            AND (
                                 BackupType = @BackupType
                                 OR BackupType = 'All'
                                )
                            AND IsActive = 1
		----------------------	  

            END
        IF @SettingLevel = 0
            BEGIN
                INSERT #BackupSettings
                        (
							PreferredServer
						)
                    SELECT
                        PreferredServer
                        FROM
                            Minion.BackupSettings
                        WHERE
                            DBName = 'MinionDefault'
                            AND (
                                 BackupType = @BackupType
                                 OR BackupType = 'All'
                                )
                            AND IsActive = 1
            END


        IF (SELECT COUNT(*) FROM #BackupSettings WHERE BackupType = @BackupType) > 0
            BEGIN
                DELETE #BackupSettings
                WHERE
                      BackupType <> @BackupType
            END

        IF (SELECT COUNT(*) FROM #BackupSettings WHERE BackupType = @BackupType) = 0
            BEGIN
                DELETE #BackupSettings 
				WHERE BackupType <> 'All'
            END

        SELECT
                @PreferredServer = PreferredServer
            FROM
                #BackupSettings 

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN

				INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
				SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupMaster', '@PreferredServer', @PreferredServer
END
-------------------DEBUG-------------------------------


IF (@PreferredServer = 'AGPreferred' OR @PreferredServer IS NULL)
BEGIN
	IF @Version >= 11
		BEGIN --@Version >= 11
					INSERT	INTO @IsPrefferedReplicaTable
							(col1)
							EXEC
								( 'SELECT sys.fn_hadr_backup_is_preferred_replica( '''
								  + @currDB + ''')'
								);

					SELECT TOP 1
							@IsPrefferedReplica = col1
					FROM	@IsPrefferedReplicaTable;
					DELETE @IsPrefferedReplicaTable

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN

				INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
				SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupMaster', '@IsPrefferedReplica', @IsPrefferedReplica
END
-------------------DEBUG-------------------------------

		END --@Version >= 11
END

IF @PreferredServer IS NOT NULL AND @PreferredServer <> 'AGPreferred'
BEGIN
	IF @PreferredServer = @@ServerName
	BEGIN
		SET @IsPrefferedReplica = 1
	END
	IF @PreferredServer <> @@ServerName
	BEGIN
		SET @IsPrefferedReplica = 0
	END

END


----------------------------------------------------
---------BEGIN Diff Exception-----------------------
----------------------------------------------------
----Diffs can't be taken on non-primary replicas.
----So we make sure it's eliminated from the list.
IF @IsPrimaryReplica = 0 AND UPPER(@BackupType) = 'DIFF'
	BEGIN
		SET @IsPrefferedReplica = 0
	END
----------------------------------------------------
---------END Diff Exception-------------------------
----------------------------------------------------

-------------BEGIN Delete Non-Preferred Server from Log--------------
----If it's not a preferred replica then it doesn't need to be in the log.
IF @IsPrefferedReplica = 0
	BEGIN
		DELETE Minion.BackupLogDetails
		WHERE ExecutionDateTime = @ExecutionDateTime
			  AND DBName = @currDB
			  AND BackupType = @BackupType
	END
-------------BEGIN Delete Non-Preferred Server from Log--------------

----SELECT @IsPrefferedReplica as IsPrefferedReplica, @PreferredServer as PreferredServer

-------------------------------------------------------------------------------------------
-----------------------END Choose AG Location----------------------------------------------
-------------------------------------------------------------------------------------------

			IF @DBIsInAG = 0 OR (@DBIsInAG = 1 AND @IsPrefferedReplica = 1)
				BEGIN

					SET @BackupCmd = ' EXEC Minion.BackupDB ' + '''' + @currDB + '''' + ', ' + '''' +  @BackupType + '''' + ', 0, ' + '''' + CONVERT(VARCHAR(25), @ExecutionDateTime, 121) + ''''
                    SET @PreCMD = 'sqlcmd -r 1 -S"' + @ServerInstance
                        + CAST(@Port AS VARCHAR(6))
						+ '" -d "' + @MaintDB + '" -q "' 
                    SET @TotalCMD = @PreCMD
                        + @BackupCmd + '"'
						--PRINT @PreCMD
                    INSERT #BackupMasterResults (col1)
                            EXEC xp_cmdshell @TotalCMD;

					DELETE FROM #BackupMasterResults
					WHERE col1 LIKE '%--%' OR col1 IS NULL OR col1 = 'output' OR col1 = 'NULL' OR col1 LIKE '%DBCC execution completed%';

                        SELECT
                                @BackupDBErrors = STUFF((
                                                     SELECT
                                                            ' ' + col1
                                                        FROM
                                                            #BackupMasterResults AS T1
                                                        ORDER BY
                                                            T1.ID
                                                    FOR
                                                     XML PATH('')
                                                    ), 1, 1, '')
                            FROM
                                #BackupMasterResults AS T2;
--SELECT @BackupDBErrors AS BackupDBErrors, * FROM #BackupMasterResults

							TRUNCATE TABLE #BackupMasterResults;
							IF @BackupDBErrors IS NOT NULL
								BEGIN
									UPDATE Minion.BackupLogDetails
										SET STATUS = 
													CASE WHEN STATUS LIKE '%Complete%' THEN STATUS
														 ELSE 'FATAL ERROR: ' + ISNULL(@BackupDBErrors, '')
													END,
											Warnings = 
													CASE WHEN STATUS LIKE '%Complete%' THEN ISNULL(Warnings, '') + ISNULL(@BackupDBErrors, '')
														 ELSE Warnings
													END
										--WHERE ID = @BackupLogDetailsID;
										WHERE ExecutionDateTime = @ExecutionDateTime
											
								END



-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @currDB, @BackupType, 'BackupMaster', 'BackupCMD', ('EXEC Minion.BackupDB  @DBName = ''' + @currDB + ''', @BackupType = ''' + @BackupType + '''' )
END
-------------------DEBUG-------------------------------

            --   EXEC Minion.BackupDB @currDB, @BackupType, 0, @ExecutionDateTime, @Debug
				END

                END --@StmtOnly = 0 

            IF @StmtOnly = 1 
                BEGIN
                    PRINT 'EXEC Minion.BackupDB  @DBName = '''
                        + @currDB + ''', @BackupType = ''' + @BackupType
                        + '''' 
                        + ', @StmtOnly = ' + CAST(@StmtOnly AS CHAR(1))
                    PRINT 'GO'
                END
            FETCH NEXT FROM BackupMasterRunDBsRunDBs INTO @currDB
        END

    CLOSE BackupMasterRunDBsRunDBs
    DEALLOCATE BackupMasterRunDBsRunDBs

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------------------------BEGIN Post-Backup Log-----------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN

	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'BackupMaster Before Complete Log'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------

		BEGIN 
			UPDATE Minion.BackupLog 
			SET STATUS = 'Backups Complete',
				TotalBackupSizeInMB = (SELECT CAST(SUM(SizeInMB) AS DECIMAL(10,2)) FROM Minion.BackupLogDetails WHERE ExecutionDateTime = @ExecutionDateTime AND STATUS NOT LIKE 'FATAL ERROR:%' AND STATUS LIKE '%Complete%')
				WHERE ExecutionDateTime = @ExecutionDateTime
				AND BackupType = @BackupType;
		END 


-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN

	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'BackupMaster After Complete Log'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------------------------END Post-Backup Log-------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------
				---------------------BEGIN POST Service Check-----------------------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------

IF @Version < 10.5
BEGIN --@Version < 10.5
		CREATE TABLE #POSTService (col1 VARCHAR(1000) COLLATE DATABASE_DEFAULT)

		BEGIN
					SET @RegexCMD = 'EXEC xp_cmdshell ''powershell "'
					SET @RegexCMD = @RegexCMD + ' $a = (gwmi win32_service | ?{$_.Name -LIKE ''''SQLAgent$' + @InstanceName + '''''}).State; If($a -eq ''''Running''''){$a = 1} ELSE{$a = 0}"'''

		--PRINT @RegexCMD
					INSERT  #POSTService
							( col1 )
							EXEC ( @RegexCMD
								) 

		SET @ServiceStatus = (SELECT TOP 1 col1 FROM #POSTService)
		DROP TABLE #POSTService;
		END

END --@Version < 10.5

IF @Version >= 10.5
BEGIN

		SELECT @ServiceStatus = 
			CASE WHEN [status] = 4 THEN 1
			ELSE 0
			END 
		FROM sys.dm_server_services WHERE servicename LIKE '%Agent%'

END
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------
				------------------------------END POST Service Check----------------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------


				--------------------------------------------------------------------------------
				---------------------BEGIN Turn OFF StatusMonitor ------------------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------


IF @ServiceStatus = 1
BEGIN --@ServiceStatus = 1

	SET @MonitorJobRunning = (SELECT COUNT(*)
	FROM sys.dm_exec_sessions es 
		INNER JOIN msdb.dbo.sysjobs sj 
		ON sj.job_id = CAST(CONVERT( BINARY(16), SUBSTRING(es.program_name , 30, 34), 1) AS UNIQUEIDENTIFIER) 
	WHERE program_name LIKE 'SQLAgent - TSQL JobStep (Job % : Step %)' 
	AND sj.name = 'MinionBackupStatusMonitor')

END --@ServiceStatus = 1


IF @MonitorJobRunning = 1
BEGIN --@MonitorJobRunning = 1
	BEGIN
		EXEC msdb.dbo.sp_stop_job 'MinionBackupStatusMonitor'
	END
END --@MonitorJobRunning = 1

				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------
				------------------------------END Turn OFF StatusMonitor------------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
-------------------------------------------BEGIN DBPostCode-----------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

        IF @BatchPostCode IS NOT NULL AND @BatchPostCode <> ''
            BEGIN -- @BatchPostCode IS NOT NULL AND @BatchPostCode <> ''


-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'BackupMaster Before PostCode'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID

				INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
				SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupMaster', '@BatchPostCode', @BatchPostCode
END
-------------------DEBUG-------------------------------

-----BEGIN Log------

                IF @BatchPostCode IS NOT NULL
                    BEGIN -- @BatchPostCode
                        IF @StmtOnly = 0
                            BEGIN -- @StmtOnly = 0
                                SET @BatchPostCodeStartDateTime = GETDATE();

                                BEGIN
                                    UPDATE
                                            Minion.BackupLog
                                        SET
                                            STATUS = 'Postcode running',
                                            BatchPostCodeStartDateTime = @BatchPostCodeStartDateTime,
                                            BatchPostCode = @BatchPostCode
                                        WHERE
                                            ID = @BackupLogID;
                                END
                            END -- @StmtOnly = 0
                    END -- @@BatchPostCode
------END Log-------

                IF @BatchPostCode IS NOT NULL
                    BEGIN -- @BatchPostCode
-----------------BEGIN Log BatchPostCode------------------
                        UPDATE
                                Minion.BackupLog
                            SET
                                BatchPostCode = @BatchPostCode,
                                BatchPostCodeStartDateTime = @BatchPostCodeStartDateTime
                            WHERE
                                ID = @BackupLogID;
-----------------END Log BatchPostCode--------------------

--------------------------------------------------
----------------BEGIN Run Postcode-----------------
--------------------------------------------------
                        DECLARE
                            @PostCodeErrors VARCHAR(MAX),
                            @PostCodeErrorExist VARCHAR(MAX);
                        CREATE TABLE #BatchPostCode
                            (
                             ID INT IDENTITY(1, 1),
                             col1 VARCHAR(MAX)
                            )

                        BEGIN TRY
                            EXEC (@BatchPostCode) 
                        END TRY

                        BEGIN CATCH
                            SET @PostCodeErrors = ERROR_MESSAGE();
                        END CATCH
                        SELECT
                                @PostCodeErrors AS PostCodeErrors
                        IF @PostCodeErrors IS NOT NULL
                            BEGIN
                                SELECT
                                        @PostCodeErrors = 'PostCODE ERROR: '
                                        + @PostCodeErrors
                            END	 


-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
				INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
				SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupMaster', '@PostCodeErrors', @PostCodeErrors
END
-------------------DEBUG-------------------------------


--------------------------------------------------
----------------END Run Postcode-------------------
--------------------------------------------------
                    END -- @BatchPostCode


-----BEGIN Log------

                IF @BatchPostCode IS NOT NULL
                    BEGIN -- @BatchPostCode
                        IF @StmtOnly = 0
                            BEGIN -- @StmtOnly = 0

-----------------------------------------------------
-------------BEGIN Log PostCode Success---------------
-----------------------------------------------------
                                IF @PostCodeErrors IS NULL
                                    BEGIN --@PostCodeErrors IS NULL
                                        SET @BatchPostCodeEndDateTime = GETDATE();
                                        UPDATE
                                                Minion.BackupLog
                                            SET
                                                BatchPostCodeEndDateTime = @BatchPostCodeEndDateTime,
                                                BatchPostCodeTimeInSecs = DATEDIFF(s,
                                                              CONVERT(VARCHAR(25), @BatchPostCodeStartDateTime, 21),
                                                              CONVERT(VARCHAR(25), @BatchPostCodeEndDateTime, 21))
                                            WHERE
                                                ID = @BackupLogID;
                                    END --@PostCodeErrors IS NULL
-----------------------------------------------------
-------------END Log PostCode Success-----------------
-----------------------------------------------------

-----------------------------------------------------
-------------BEGIN Log PostCode Failure---------------
-----------------------------------------------------
                                IF @PostCodeErrors IS NOT NULL
                                    BEGIN --@PostCodeErrors IS NULL
                                        SET @BatchPostCodeEndDateTime = GETDATE();
                                        UPDATE
                                                Minion.BackupLog
                                            SET
                                                Warnings = ISNULL(Warnings, '')
                                                + @PostCodeErrors,
                                                BatchPostCodeEndDateTime = @BatchPostCodeEndDateTime,
                                                BatchPostCodeTimeInSecs = DATEDIFF(s,
                                                              CONVERT(VARCHAR(25), @BatchPostCodeStartDateTime, 21),
                                                              CONVERT(VARCHAR(25), @BatchPostCodeEndDateTime, 21))
                                            WHERE
                                                ID = @BackupLogID;
                                    END --@PostCodeErrors IS NULL
-----------------------------------------------------
-------------END Log PostCode Failure-----------------
-----------------------------------------------------
                            END -- @StmtOnly = 0
                    END -- @@BatchPostCode

------END Log-------

            END -- @BatchPostCode IS NOT NULL AND @BatchPostCode <> ''
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
-------------------------------------------END DBPostCode------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
---------------------------BEGIN File Actions-------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
---This is where backup files get moved/copied if they're set to AfterBatch.
---put fileAction and fileActiontime into the log so it's easier to pull it out here.
IF @StmtOnly = 0
BEGIN --@StmtOnly = 0

		DECLARE 
				@Warnings VARCHAR(MAX),
				@LogVerb VARCHAR(20),
				@FileActionBeginDateTime DATETIME,
				@FileActionEndDateTime DATETIME;


CREATE TABLE #FileActionDBs
(
ID INT IDENTITY(1,1),
DBName sysname COLLATE DATABASE_DEFAULT,
FileAction VARCHAR(10) COLLATE DATABASE_DEFAULT,
DateLogic VARCHAR(50) COLLATE DATABASE_DEFAULT,
BackupType VARCHAR(10) COLLATE DATABASE_DEFAULT
)

INSERT #FileActionDBs
        (DBName, FileAction, DateLogic, BackupType)
SELECT DBName, 
FileAction, 
(SELECT TOP (1) DateLogic FROM Minion.BackupFiles BF WHERE BF.DBName = BL1.DBName AND BF.BackupType = @BackupType AND BF.ExecutionDateTime = @ExecutionDateTime) AS DateLogic, 
BackupType 
FROM Minion.BackupLogDetails BL1
WHERE FileAction IS NOT NULL
AND UPPER(FileActionTime) = 'AFTERBATCH'
AND ExecutionDateTime = @ExecutionDateTime 

DECLARE 
		@currFileAction VARCHAR(10),
		@currDateLogic VARCHAR(50),
		@FileActionSQL NVARCHAR(2000)

DECLARE FileActions CURSOR
READ_ONLY
FOR SELECT DBName, FileAction, DateLogic FROM #FileActionDBs

OPEN FileActions

	FETCH NEXT FROM FileActions INTO @currDB, @currFileAction, @currDateLogic
	WHILE (@@fetch_status <> -1)
	BEGIN

	  -------------Begin Log Beginning of Action-------------------
		IF @StmtOnly = 0
		BEGIN --@StmtOnly = 0
				SET @FileActionBeginDateTime = GETDATE();

				SELECT @Status = STATUS, 
				@Warnings = Warnings
				FROM Minion.BackupLogDetails
				WHERE ExecutionDateTime = @ExecutionDateTime
				AND DBName = @DBName
				AND BackupType = @BackupType


-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'BackupMaster Before FileAction Log'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------

				BEGIN --Backup OK
					UPDATE Minion.BackupLogDetails 
					SET STATUS = 'Performing FileAction',
					FileActionBeginDateTime = @FileActionBeginDateTime
						WHERE ExecutionDateTime = @ExecutionDateTime
						AND DBName = @DBName;
				END --Backup OK
		END --@StmtOnly = 0
		-------------End Log Beginning of Action---------------------

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'BackupMaster After FileAction Log'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------


		SET @FileActionSQL = 'EXEC Minion.BackupFileAction  ''' + @currDB + ''', ' +
				   '''' + @currDateLogic + '''' + ', ' +
				   '''' + @BackupType + '''' + ', ' +
						  CAST(0 AS CHAR(1))
		EXEC (@FileActionSQL)

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
				INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
				SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupMaster', '@FileActionSQL', @FileActionSQL
END
-------------------DEBUG-------------------------------


-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'BackupMaster Before FileAction Complete Log'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------


		-------------BEGIN Log End of Action---------------------
		SET @FileActionEndDateTime = GETDATE();

		BEGIN --Backup OK
			UPDATE Minion.BackupLogDetails 
			SET STATUS = 'FileAction Complete',
			FileActionBeginDateTime = @FileActionBeginDateTime,
			FileActionEndDateTime = @FileActionEndDateTime,
			FileActionTimeInSecs = DATEDIFF(s,
                CONVERT(VARCHAR(25), @FileActionBeginDateTime, 21),
                CONVERT(VARCHAR(25), @FileActionEndDateTime, 21))
				WHERE ExecutionDateTime = @ExecutionDateTime
				AND DBName = @currDB
				AND BackupType = @BackupType;
		END --Backup OK
		-------------END Log End of Action---------------------


-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'BackupMaster After FileAction Complete Log'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------
		
FETCH NEXT FROM FileActions INTO @currDB, @currFileAction, @currDateLogic
	END

CLOSE FileActions
DEALLOCATE FileActions

END --@StmtOnly = 0

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
---------------------------END File Actions---------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------



----------------------------------------------------------------------------
----------------------------------------------------------------------------	
--------------------BEGIN Verify--------------------------------------------	
----------------------------------------------------------------------------	
----------------------------------------------------------------------------		
DECLARE @BackupErrorMaster VARCHAR(5);
SET @BackupErrorMaster = (SELECT Value 
				FROM Minion.Work 
				WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'Backup' AND DBName = @currDB AND BackupType = @BackupType AND SPName = 'BackupDB' AND Param = '@BackupError')

IF @BackupErrorMaster = 'OK'
	BEGIN --@BackupError = 'OK'
			 -------------------DEBUG-------------------------------
				IF @Debug = 1
				BEGIN
					INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
					SELECT
						ExecutionDateTime, STATUS, DBName, BackupType, 'Master: Before BackupDB Verify Log'
						FROM Minion.BackupLogDetails
						WHERE ID = @BackupLogDetailsID
				END
			-------------------DEBUG-------------------------------	

	If (SELECT COUNT(*)
	FROM Minion.BackupLogDetails
	WHERE STATUS LIKE '%Complete%'
		  AND UPPER(Verify) = 'AFTERBATCH'
		  AND ExecutionDateTime = @ExecutionDateTime) > 0

			BEGIN
				EXEC Minion.BackupVerify @ExecutionDateTime
			END

			 -------------------DEBUG-------------------------------
				IF @Debug = 1
				BEGIN
					INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
					SELECT
						ExecutionDateTime, STATUS, DBName, BackupType, 'Master: After BackupDB Verify Log'
						FROM Minion.BackupLogDetails
						WHERE ID = @BackupLogDetailsID
				END

			-------------------DEBUG-------------------------------	

	END --@BackupError = 'OK'
----------------------------------------------------------------------------
----------------------------------------------------------------------------	
--------------------END Verify----------------------------------------------	
----------------------------------------------------------------------------	
----------------------------------------------------------------------------


-------------------------------------------
---------BEGIN Final Log-------------------
-------------------------------------------


-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'BackupMaster Before Final Log'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------


DECLARE @FinalErrorCT INT,
		@FinalWarningCT INT;
SET @FinalErrorCT = (SELECT COUNT(*) FROM Minion.BackupLogDetails WHERE ExecutionDateTime = @ExecutionDateTime AND (STATUS NOT LIKE '%Complete' AND STATUS LIKE 'FATAL ERROR%'));
SET @FinalWarningCT = (SELECT COUNT(*) FROM Minion.BackupLogDetails WHERE ExecutionDateTime = @ExecutionDateTime AND (Warnings IS NOT NULL AND Warnings <> ''));

--SELECT @FinalErrorCT AS FinalErrorCT, @FinalWarningCT AS FinalWarningCT


UPDATE Minion.BackupLogDetails
SET STATUS = 
			CASE 
				 WHEN STATUS = 'Performing FileAction' THEN 'FATAL ERROR: The backup was interrupted after the FileAction began.  Either we couldn''t capture the error or the routine was manually cancelled.'
				 WHEN STATUS = 'Getting LogSpace' THEN 'FATAL ERROR: There was an error getting the LogSpace. The routine was either manually cancelled or an error occurred that couldn''t be captured.'
				 WHEN STATUS = 'Gathering VLF Info' THEN 'FATAL ERROR: There was an error getting the VLF info. The routine was either manually cancelled or an error occurred that couldn''t be captured.'
				 WHEN (STATUS LIKE '%Complete' AND (Warnings IS NULL OR Warnings = '')) THEN 'All Complete'
				 WHEN (STATUS LIKE '%Warnings' AND STATUS NOT LIKE '%FATAL ERROR%') OR (Warnings IS NOT NULL AND Warnings <> '') THEN 'Complete with Warnings'
				 WHEN STATUS IS NULL THEN 'FATAL ERROR: This is an unhandled error.  Contact support for assistance.'
				 WHEN STATUS LIKE 'FATAL ERROR%' THEN STATUS
			END
WHERE ExecutionDateTime = @ExecutionDateTime --AND STATUS <> 'Complete' --AND STATUS NOT LIKE 'FATAL ERROR%'

SET @ExecutionEndDateTime = GETDATE();

UPDATE Minion.BackupLog
SET STATUS = 
			CASE 
				 --WHEN STATUS LIKE '%Complete' THEN 'All Complete'
				 WHEN (@FinalErrorCT = 0 AND @FinalWarningCT = 0) THEN 'All Complete'
				 WHEN (@FinalErrorCT > 0 AND @FinalWarningCT = 0) THEN 'Complete with ' + CAST(@FinalErrorCT AS VARCHAR(10)) + ' Error' + CASE WHEN @FinalErrorCT > 1 THEN 's' ELSE '' END
				 WHEN (@FinalErrorCT = 0 AND @FinalWarningCT > 0) THEN 'Complete with ' + CAST(@FinalWarningCT AS VARCHAR(10)) + ' Warning' + CASE WHEN @FinalWarningCT > 1 THEN 's' ELSE '' END
				 WHEN (@FinalErrorCT > 0 AND @FinalWarningCT > 0) THEN 
				 ('Complete with ' + CAST(@FinalErrorCT AS VARCHAR(10)) + ' Error' + CASE WHEN @FinalErrorCT > 1 THEN 's' ELSE '' END) +
				 (' and ' + CAST(@FinalWarningCT AS VARCHAR(10)) + ' Warning' + CASE WHEN @FinalWarningCT > 1 THEN 's' ELSE '' END)
			END
				, ExecutionEndDateTime = @ExecutionEndDateTime
				, ExecutionRunTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @ExecutionDateTime, 21), CONVERT(VARCHAR(25), @ExecutionEndDateTime, 21))
WHERE ExecutionDateTime = @ExecutionDateTime


-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'BackupMaster After Final Log'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------

-------------------------------------------
---------END Final Log---------------------
-------------------------------------------


----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-------------------------BEGIN Sync Settings--------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
--We have to do this after the final log because the final log settings have to be synched to the other box.
--So we can't update any logs after we sync.  
--This means that this process could fail and we have to count on the job failure to tell us.

IF @SyncSettings = 1
BEGIN
	EXEC Minion.BackupSyncSettings @ExecutionDateTime
	EXEC Minion.SyncPush 'Settings', NULL, NULL, NULL, 'New'
END
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-------------------------BEGIN Sync Settings--------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-------------------------BEGIN Sync Logs------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
--We have to do this after the final log because the final log settings have to be synched to the other box.
--So we can't update any logs after we sync.  
--This means that this process could fail and we have to count on the job failure to tell us.

IF @SyncLogs = 1
BEGIN
	EXEC Minion.BackupSyncLogs @ExecutionDateTime
	EXEC Minion.SyncPush 'Logs', NULL, NULL, NULL, 'New'	
END
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-------------------------BEGIN Sync Logs------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------


------------------------------------------------------------------------
-------------------BEGIN Log to Minion----------------------------------
------------------------------------------------------------------------

DECLARE @BackupLoggingPath varchar(1000),
		@ServerLabel varchar(150),
		@TriggerFile VARCHAR(2000);
							SET @BackupLoggingPath = (SELECT TOP 1 Value 
													 FROM Minion.Work 
													 WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'Backup' AND SPName = 'BackupDB' AND Param = '@BackupLoggingPath')

            SET @ServerLabel = @@ServerName;
            IF @ServerLabel LIKE '%\%'
                BEGIN --Begin @ServerLabel
                    SET @ServerLabel = REPLACE(@ServerLabel, '\', '~')
                END	--End @ServerLabel

IF @StmtOnly = 0
	BEGIN --@StmtOnly = 0
            SET @TriggerFile = 'Powershell "''' + ''''''
                + CONVERT(VARCHAR(25), @ExecutionDateTime, 21) + ''''''''
                + ' | out-file "' + @BackupLoggingPath + 'BackupMaster\' + @ServerLabel + '.'
                + '" -append"' 
----print @TriggerFile
            EXEC xp_cmdshell @TriggerFile 
	END --@StmtOnly = 0


------------------------------------------------------------------------
-------------------END Log to Minion------------------------------------
------------------------------------------------------------------------


------------------------------------------------------------
----------------BEGIN Delete Work Table---------------------
------------------------------------------------------------
DELETE Minion.Work
WHERE ExecutionDateTime = @ExecutionDateTime
AND BackupType = @BackupType
------------------------------------------------------------
----------------END Delete Work Table-----------------------
------------------------------------------------------------


DECLARE @FailureErrorCT INT,
		@FailureErrorTxt VARCHAR(1000),
		@LangFmt TINYINT;
--SET @FailureErrorCT = (SELECT COUNT(*) FROM Minion.BackupLog WHERE ExecutionDateTime = @ExecutionDateTime AND STATUS LIKE '%Warning%' OR STATUS LIKE '%Error%')

----------------------------------------------------------------------------------------
---------------------------BEGIN Force Agent Job Failure--------------------------------
----------------------------------------------------------------------------------------
IF (@FailJobOnError = 1 AND @FailJobOnWarning = 1)
	BEGIN --Error and Warning
	IF @FinalErrorCT > 0 OR @FinalWarningCT > 0
	BEGIN
	SET @FailureErrorTxt = 'There were errors and/or warnings in the backup process. You can see the errors by connecting to ' + @ServerInstance
							+ ' and running the folling query: SELECT ExecutionDateTime, STATUS, DBName, BackupType, Warnings FROM [' + DB_NAME() + '].[Minion].[BackupLogDetails] WHERE ExecutionDateTime = ''' + CONVERT(VARCHAR(25), @ExecutionDateTime, 121) + ''''
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

GO
