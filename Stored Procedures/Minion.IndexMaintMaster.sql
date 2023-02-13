SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [Minion].[IndexMaintMaster]
    @IndexOption VARCHAR(100) = NULL, -- Valid options: All, ONLINE, OFFLINE.  So All the indexes, or only the indexes that can be done online or offline.
    @ReorgMode VARCHAR(7) = NULL, -- Valid options: All, REORG, REBUILD. For REORG mode, only REORG stmts will be generated.  For REBUILD, only REBUILD stmts will be generated.
    @RunPrepped BIT = 0 ,  --The index frag data has already been collected and you want to use that data instead of querying for the frag data now.
    @PrepOnly BIT = 0 , -- Valid options: 1, 0. Only gets index frag stats and saves to a table.  This preps the DB to be reindexed.  Run this with @RunPrepped = 1 to take advantage of the prep.
    @StmtOnly BIT = 0 ,  --Print the reindex calls only.
    @Include NVARCHAR(2000) = NULL , --Index ONLY these DBs.  comma-separated like this : DB1,DB2,DB3
    @Exclude NVARCHAR(2000) = NULL , -- Valid options: 1, 0. Only prints reindex stmts.  Excellent choice for running stmts manually.  Allows you to pick and choose which indexes you want to do or just see how many are over the thresholds.
    @LogProgress BIT = 1, -- Valid options: 1, 0.  Allows you to have every step of the run printed in the log so you can see the progress it's making.  This can take a little extra time so leave it out if you just want it to run w/o being monitored.
	@TestDateTime DATETIME = NULL,
	@FailJobOnError BIT = 0,
	@FailJobOnWarning BIT = 0,
	@Debug BIT = 0

AS 

--v.1.3
/***********************************************************************************
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------------------Minion Reindex------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Created By: MinionWare LLC, MidnightSQL Consulting LLC. and MidnightDBA.com



For SQL Server consulting, see our website http://www.MidnightSQL.com
No job is too big or too small.

Also, check out our FREE SQL Server training videos at http://www.MidnightDBA.com

This is a big routine with many nuances.  Our documentation is complete, but if 
you prefer, we also have videos that show you how to use each of the features.
You can find them at http://MinionWare.net

Minion Reindex is a free, standalone, index maintenance routine that is a component 
of the Minion Enterprise Management solution.

Minion Enterprise is an enterprise management solution that makes managing your 
SQL Server enterprise super easy. The backup routine folds into the enterprise 
solution with ease.  By integrating your backups into the Minion Enterprise, you 
get the ability to manage your backup parameters from a central location. And, 
Minion Enterprise provides enterprise-level reporting and alerting.
Download a 90-day trial of Minion Enterprise at http://MinionWare.net

* By running this software you are agreeing to the terms of the license agreement.
* You can find a copy of the license agreement here: http://minionware.net/wp-content/uploads/MinionModulesLicenseAgreement.pdf
--------------------------------------------------------------------------------
Table of Contents: 
	Define Schedule
		 Reset Counter
		 Declare Vars
		 Insert All Rows
		 Delete Rows
			 All High-level Settings
				 DELETE High-levels
				 DELETE Named Days that Don't Match
				 DELETE Higher-level days when Today has run
		 Set Vars
		 Update IndexMaintSettingsServer
	Get Version Info
	 Process Included DBs
		 Insert Static DB Names
		 Insert LIKE Include DB Names
		 Delete ExcludeFromReindex
		 Set GroupOrder
	 Process Excluded DBs
		 LIKE Exclude DB Names
	 Process Regex Excluded DBs
	 ONLINE DBs
	 ReadOnly DBs
	 Logging
	 DB Cursor

Example Execution: 
	EXEC [Minion].[IndexMaintMaster] 
		@IndexOption = 'All',	-- All, ONLINE, OFFLINE
		@ReorgMode = 'All',
		@RunPrepped = 0,		-- Valid options: 1, 0. If you've collected index frag stats ahead of time by running with @PrepOnly = 1, then you can use this option. 
		@PrepOnly = 0,
		@StmtOnly = 1,
		@Include = 'Minion%, ReportSERVER', -- Only do DBs listed here. Commas are used. ex: @Include = 'master, model, msdb'
		@Exclude = NULL,			-- Do all DBs except the ones listed here. Commas are used. ex: @Exclude = 'master, model, msdb'
		@LogProgress = 1

Revisions:
	1.1		Add ability to handle Availability Groups
	1.2		Multiple fixes. Improved error trapping and logging. Statement prefix, statement suffix.
	1.3		Get @Version (etc.) from Minion.DBMaintSQLInfoGet. Added handling for heaps. Improved international support.
			Add Minion.IndexMaintSettingsServer functionality (table based schedules).

*/
    SET NOCOUNT ON;

----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
---------------------------------BEGIN Define Schedule----------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----If the incoming vars are NULL then we get the value from the SettingsServer table.
BEGIN
    DECLARE @ExecutionDateTime DATETIME;
    
    IF @TestDateTime IS NULL
    	BEGIN
    		SET @TestDateTime = GETDATE();
    	END
    SET @ExecutionDateTime = @TestDateTime;
END

IF @ReorgMode IS NULL
	BEGIN --Define Schedule

--	SET @NumConcurrentProcesses = NULL;

	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------BEGIN Reset Counter------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	----The counters are per day, so if it's a new day we'll have to reset them.
IF @StmtOnly = 0
	BEGIN
		UPDATE Minion.IndexMaintSettingsServer
		SET CurrentNumOps = 0
		WHERE (CONVERT(VARCHAR(10), LastRunDateTime, 101) <> CONVERT(VARCHAR(10), GETDATE(), 101) OR LastRunDateTime IS NULL)
	END	
	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------END Reset Counter--------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------


	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------BEGIN Declare Vars-------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	
	CREATE TABLE #IndexMaintMasterParams
	(
		ID INT IDENTITY(1,1) NOT NULL,
		SettingServerID INT,
		DBType VARCHAR(6) COLLATE DATABASE_DEFAULT,
		IndexOption VARCHAR(100) COLLATE DATABASE_DEFAULT NULL,
		ReorgMode VARCHAR(7) COLLATE DATABASE_DEFAULT NULL,
		RunPrepped BIT NULL,
		PrepOnly BIT NULL,
		Day VARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
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
		--SyncSettings BIT NULL,   !!!!!!!!!!!!!!!need time and internalthreads cols.
		--SyncLogs BIT NULL,
		BatchPreCode NVARCHAR(MAX) COLLATE DATABASE_DEFAULT NULL,
		BatchPostCode NVARCHAR(MAX) COLLATE DATABASE_DEFAULT NULL,
		Debug BIT,
		FailJobOnError BIT,
		FailJobOnWarning BIT
	);

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
		@BatchPreCode NVARCHAR(MAX),
		@BatchPostCode NVARCHAR(MAX),
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


	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------END Declare Vars---------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------


	--------------------------------------------------------------
	--------------------------------------------------------------
	----------BEGIN Insert All Rows-------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	BEGIN
	INSERT #IndexMaintMasterParams (SettingServerID, DBType, IndexOption, ReorgMode, RunPrepped, PrepOnly, Day, BeginTime, EndTime, MaxForTimeframe, FrequencyMins, CurrentNumOps, NumConcurrentOps, DBInternalThreads, TimeLimitInMins, LastRunDateTime, Include, Exclude, [Schemas], [Tables], BatchPreCode, BatchPostCode, Debug)
		SELECT
			ID, DBType, IndexOption, ReorgMode, RunPrepped, PrepOnly, Day, BeginTime, EndTime, MaxForTimeframe, FrequencyMins, CurrentNumOps, NumConcurrentOps, DBInternalThreads, TimeLimitInMins, LastRunDateTime, Include, Exclude, [Schemas], [Tables], BatchPreCode, BatchPostCode, Debug
			FROM Minion.IndexMaintSettingsServer
			WHERE IsActive = 1; ----AND ISNULL(CurrentNumBackups, 0) < MaxForTimeframe;
	END

	--------------------------------------------------------------
	--------------------------------------------------------------
	----------END Insert All Rows---------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------

	
	--------------------------------------------------------------
	--------------------------------------------------------------
	-----------------BEGIN Delete Rows----------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	---Deletes times first.  Anything that doesn't fall in the timeslot automatically gets whacked.
		BEGIN
			DELETE #IndexMaintMasterParams WHERE NOT (CONVERT(VARCHAR(20), @TodayTimeCompare, 114) BETWEEN CONVERT(VARCHAR(20), BeginTime, 114) AND CONVERT(VARCHAR(20), EndTime, 114)) AND (BeginTime IS NOT NULL AND EndTime IS NOT NULL)
		END

	---Delete frequencies.  Anything that is too soon to backup needs to go.
		BEGIN
			DELETE #IndexMaintMasterParams WHERE DATEDIFF(MINUTE, LastRunDateTime, @TodayTimeCompare) < FrequencyMins AND FrequencyMins IS NOT NULL;
		END

----SELECT 'After initial delete', * FROM #IndexMaintMasterParams

	---------------------------------------------------
	--------BEGIN All High-level Settings--------------
	---------------------------------------------------
		
	----If today is Beginning of year then delete everything else.
	IF @IsFirstOfYear = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM #IndexMaintMasterParams WHERE [Day] = 'FirstOfYear')
			BEGIN
				DELETE #IndexMaintMasterParams  
				WHERE [Day] <> 'FirstOfYear' 
				AND DBType = 'User'
				AND Include IN (SELECT Include FROM #IndexMaintMasterParams WHERE [Day] = 'FirstOfYear') --!-- See MB for code! 
			END
	END

	----If today is End of year then delete everything else.
	IF @IsLastOfYear = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM #IndexMaintMasterParams WHERE [Day] = 'LastOfYear')
			BEGIN
				DELETE #IndexMaintMasterParams  
				WHERE [Day] <> 'LastOfYear' 
				AND DBType = 'User'
				AND Include IN (SELECT Include FROM #IndexMaintMasterParams WHERE [Day] = 'LastOfYear')
			END
	END

	----If today is Beginning of month then delete everything else.
	IF @IsFirstOfMonth = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM #IndexMaintMasterParams WHERE [Day] = 'FirstOfMonth')
			BEGIN
				DELETE #IndexMaintMasterParams  
				WHERE [Day] <> 'FirstOfMonth' 
				AND DBType = 'User'
				AND Include IN (SELECT Include FROM #IndexMaintMasterParams WHERE [Day] = 'FirstOfMonth')
			END
	END

	----If today is End of month then delete everything else.
	IF @IsLastOfMonth = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM #IndexMaintMasterParams WHERE [Day] = 'LastOfMonth')
			BEGIN
				DELETE #IndexMaintMasterParams  
				WHERE [Day] <> 'LastOfMonth' 
				AND DBType = 'User'
				AND Include IN (SELECT Include FROM #IndexMaintMasterParams WHERE [Day] = 'LastOfMonth')
			END
	END


	---------------------BEGIN DELETE High-levels---------------------------

	--If it's not one of these high-level days, they need to be deleted.
	--You can't run a FirstOfMonth if it's not the 1st of the month now can you?
	IF @IsFirstOfYear = 0
		BEGIN
			DELETE #IndexMaintMasterParams  
			WHERE [Day] = 'FirstOfYear' 
		END

	IF @IsLastOfYear = 0
		BEGIN
			DELETE #IndexMaintMasterParams  
			WHERE [Day] = 'LastOfYear' 
		END

	IF @IsFirstOfMonth = 0
		BEGIN
			DELETE #IndexMaintMasterParams  
			WHERE [Day] = 'FirstOfMonth' 
		END

	IF @IsLastOfMonth = 0
		BEGIN
			DELETE #IndexMaintMasterParams  
			WHERE [Day] = 'LastOfMonth' 
		END

	---------------------END DELETE High-levels-----------------------------



	------------------------BEGIN DELETE Named Days that Don't Match---------------

	--If there are named days, then delete everything that isn't the named day if the named day is today.
	--So if the named day is Friday and today is Monday, then it shouldn't be in the table.

		----IF EXISTS (SELECT 1 FROM #MasterParams WHERE [Day] = DATENAME(dw, @TodayDateCompare) AND CurrentNumBackups >= MaxForTimeframe)
		BEGIN
			DELETE #IndexMaintMasterParams  WHERE ([Day] IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') 
			AND [Day] <> DATENAME(dw, @TodayDateCompare))
		END

	------------------------END DELETE Named Days that Don't Match-----------------


	------------------------BEGIN DELETE Higher-level days when Today has run---------------

	--If there are named days, then delete everything that isn't the named day if the named day is today.
	--So if the named day is Friday and today is Monday, then it shouldn't be in the table.

		IF EXISTS (SELECT 1 FROM #IndexMaintMasterParams WHERE [Day] = DATENAME(dw, @TodayDateCompare) AND CurrentNumOps >= MaxForTimeframe)
		BEGIN
			DELETE MP1
			FROM #IndexMaintMasterParams MP1
			WHERE MP1.[Day] IN ('Daily', 'Weekend', 'Weekday') 
			AND MP1.ReorgMode IN (SELECT ReorgMode FROM #IndexMaintMasterParams MP2 WHERE [Day] = DATENAME(dw, @TodayDateCompare) AND CurrentNumOps >= MaxForTimeframe)
		END

	------------------------END DELETE Higher-level days when Today has run-----------------

IF (@IsLastOfMonth = 0 AND @IsFirstOfMonth = 0 AND @IsFirstOfYear = 0 AND @IsLastOfYear = 0)
	BEGIN -- Delete Days
		----I think this entire section should only be called if all of the above conditions are true.  
		----Those higher level settings should always override these daily settings.
		----If today is a Weekday then delete everything else.
		--IF (SELECT 1 FROM #MasterParams WHERE [Day] = 'Weekday') = 1 --Removed as 1.1 fix
		BEGIN
			IF DATENAME(dw, @TodayDateCompare) IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
				BEGIN
					DELETE #IndexMaintMasterParams  WHERE ([Day] NOT IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday') AND [Day] <> 'Weekday' AND [Day] <> 'Daily') --AND DBType = 'User'-- Fix for 1.1: Added "AND [Day] <> 'Daily'" because it was deleting Daily rows when it shouldn't be.
				END
		END

		----If today is a Weekend then delete everything else.
		--IF (SELECT 1 FROM #MasterParams WHERE [Day] = 'Weekend') = 1 --Removed as 1.1 fix
		BEGIN
			IF DATENAME(dw, @TodayDateCompare) IN ('Saturday', 'Sunday')
				BEGIN
					DELETE #IndexMaintMasterParams  WHERE ([Day] NOT IN ('Saturday', 'Sunday') AND [Day] <> 'Weekend' AND [Day] <> 'Daily')-- Fix for 1.1: Added "AND [Day] <> 'Daily'" because it was deleting Daily rows when it shouldn't be.
				END
		END

	----SELECT DATENAME(dw, @TodayDateCompare), @TodayDateCompare, 'Weekdays', * FROM #IndexMaintMasterParams
--RETURN
		----If there are records for today, then delete everything else.
		IF EXISTS (SELECT 1 FROM #IndexMaintMasterParams WHERE [Day] = DATENAME(dw, @TodayDateCompare))
			BEGIN
				DELETE #IndexMaintMasterParams WHERE [Day] <> DATENAME(dw, @TodayDateCompare) OR [Day] IS NULL
			END

		----Now we should be down to just the daily runs if so, then delete everything else.
		IF EXISTS (SELECT 1 FROM #IndexMaintMasterParams WHERE [Day] = 'Daily')
			BEGIN
				DELETE #IndexMaintMasterParams WHERE [Day] IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
			END
	END -- Delete Days


	DELETE #IndexMaintMasterParams
	WHERE ISNULL(CurrentNumOps, 0) >= MaxForTimeframe;


	---------------------------------------------------
	--------END All High-level Settings--------------
	---------------------------------------------------
	
		
	--------------------------------------------------------------
	--------------------------------------------------------------
	-----------------END Delete Rows------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------


	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------BEGIN Set Vars-----------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------

		BEGIN
			SELECT TOP 1 
				@MasterParamID = ID,
				@SettingServerID = SettingServerID,
				@IndexOption = IndexOption,
				@ReorgMode = ReorgMode,
				@RunPrepped = RunPrepped,
				@PrepOnly = PrepOnly,
				@MaxforTimeframe = MaxForTimeframe,
				--@NumConcurrentProcesses = ISNULL(NumConcurrentOps, 1),---This var is the problem...
				--@DBInternalThreads = DBInternalThreads,
				-- @TimeLimitInMins = TimeLimitInMins,
				@Include = Include,
				@Exclude = Exclude,
				--@Schemas = [Schemas],
				--@Tables = [Tables],
				----@SyncSettings = SyncSettings,
				----@SyncLogs = SyncLogs,
				@BatchPreCode = BatchPreCode,
				@BatchPostCode = BatchPostCode,
				@Debug = Debug,
				@FailJobOnError = FailJobOnError,
				@FailJobOnWarning = FailJobOnWarning
			FROM #IndexMaintMasterParams
			ORDER BY DBType ASC, ReorgMode ASC;
		END

	----This is here to show which schedule was picked. It's a great way to tshoot the process.
	SELECT 				DATENAME(dw, @TodayDateCompare) AS CurrentDay, 
				@TodayDateCompare AS CurrentDateTime, * 
	FROM #IndexMaintMasterParams WHERE ID = @MasterParamID;

	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------END Set Vars-------------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------

END --Define Schedule



--------------------------------------------------------------
--------------------------------------------------------------
-------------BEGIN Update IndexMaintSettingsServer------------
--------------------------------------------------------------
--------------------------------------------------------------

If @StmtOnly = 0
BEGIN
	----We don't want to increment the table row if there are no rows to run.
	IF @MasterParamID IS NOT NULL
		BEGIN
			UPDATE Minion.IndexMaintSettingsServer
			SET CurrentNumOps = ISNULL(CurrentNumOps, 0) + 1,
				LastRunDateTime = GETDATE()
			WHERE ID = @SettingServerID;
		END
END

--------------------------------------------------------------
--------------------------------------------------------------
-------------END Update IndexMaintSettingsServer--------------
--------------------------------------------------------------
--------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
---------------------------------END Define Schedule------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------


    DECLARE --@ExecutionDateTime DATETIME ,
        @currDB NVARCHAR(400) ,
        @currTables VARCHAR(10) ,
        @currRunPrepped BIT ,
        @currStmtOnly BIT ,
        @DBName NVARCHAR(400) ,
        @SQL NVARCHAR(200),
		@currDBName NVARCHAR(400),
		@IncludeRAW NVARCHAR(2000),
		@ExcludeRAW NVARCHAR(2000),
		@Version DECIMAL(3,1), --*-- 1.3
		@Edition VARCHAR(15),
		@RegexCT smallint,
		@IsPrimaryReplica bit,
		@DBIsInAG bit;

    SET @ExecutionDateTime = GETDATE();

----Seed initial AG value since most DBs won't be in an AG, we go ahead and set it here.  If it is 
----in an AG then we'll set it again later.
SET @DBIsInAG = 0;


-------------------------------------------------------------------------
----------------BEGIN Check Cmdshell-------------------------------------
-------------------------------------------------------------------------
DECLARE @CmdshellON BIT;
SET @CmdshellON = (SELECT CAST(value_in_use AS BIT) FROM sys.configurations WHERE name = 'xp_cmdshell')
IF @CmdshellON = 0
	BEGIN

			INSERT Minion.IndexMaintLog (ExecutionDateTime, DBName, [Status])
			SELECT @ExecutionDateTime, 'All', 'FATAL ERROR: xp_cmdshell is not enabled.  You must enable xp_cmdshell in order to run this procedure';

			RETURN;
				
	END	--*-- 1.3
	
-------------------------------------------------------------------------
-----------------END Check Cmdshell--------------------------------------
-------------------------------------------------------------------------

CREATE TABLE #DBs
(
	DBName NVARCHAR(400) COLLATE DATABASE_DEFAULT,
	IsReadOnly BIT,
	StateDesc VARCHAR(50) COLLATE DATABASE_DEFAULT,
	ReindexGroupOrder INT ,
	ReindexOrder INT
);



----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
--------------------------------- BEGIN Get Version Info--------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

	DECLARE	@OnlineEdition BIT;

	SELECT 
		@Version = [Version],
		@Edition = Edition,
		@OnlineEdition = OnlineEdition
	FROM Minion.DBMaintSQLInfoGet();  --*-- 1.3


----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
---------------------------------END Get Version Info-----------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
---------------------------------BEGIN Process Included DBs-----------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
/* IF @ReorgMode IS NOT NULL - this makes sure we have either a set of parameters passed in, OR an applicable schdule
   (and therefore, a bunch of settings we can use).  If we ran Minion.IndexMaintmaster with no params, AND there's no 
   applicable schedule, then the run should do nothing. -JM */
IF @ReorgMode IS NOT NULL --*-- 1.3
BEGIN -- @ReorgMode IS NOT NULL
	SET @IncludeRAW = @Include;

    IF @Include <> 'All' AND @Include IS NOT NULL 
        BEGIN -- <> All
			--Get rid of any spaces in the DB list.
            SET @Include = REPLACE(@Include, ' ', '') 

            DECLARE @IncludeDBNameTable TABLE ( DBName NVARCHAR(400) );
            DECLARE @IncludeDBNameString NVARCHAR(400);
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

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------BEGIN Insert Static DB Names---------------------
			--------------------------------------------------------------
			--------------------------------------------------------------
			--These are the actual DB names passed into the @Include param.
            INSERT  #DBs
                    SELECT  ID.DBName, SD.is_read_only, SD.state_desc, 0 , 0
                    FROM @IncludeDBNameTable ID
					INNER JOIN master.sys.databases SD
					ON ID.DBName = SD.Name COLLATE DATABASE_DEFAULT
					WHERE ID.DBName NOT LIKE '%\%%' ESCAPE '\'
			UNION
					SELECT DBName, NULL, NULL, NULL, NULL
					FROM @IncludeDBNameTable
					WHERE DBName LIKE '%\%%' ESCAPE '\'

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------END Insert Static DB Names-----------------------
			--------------------------------------------------------------
			--------------------------------------------------------------


			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------BEGIN Insert LIKE Include DB Names---------------
			--------------------------------------------------------------
			--------------------------------------------------------------
			--You can mix static and LIKE DB names so here's where we're processing the LIKE names.

			IF @IncludeRAW LIKE '%\%%' ESCAPE '\'
			BEGIN --@IncludeRAW
				DECLARE LikeDBs CURSOR
				READ_ONLY
				FOR SELECT DBName
				FROM #DBs
				WHERE DBName LIKE '%\%%' ESCAPE '\' 

				OPEN LikeDBs

				FETCH NEXT FROM LikeDBs INTO @currDBName
				WHILE (@@fetch_status <> -1)
					BEGIN
						SELECT @currDBName AS CurrDBName
								INSERT #DBs
								SELECT Name, is_read_only, state_desc, 0, 0
								FROM master.sys.databases
								WHERE Name LIKE @currDBName
		
						FETCH NEXT FROM LikeDBs INTO @currDBName
					END

				CLOSE LikeDBs
				DEALLOCATE LikeDBs

				---Now delete the LIKE DBs that were passed into the param as the actual DB names are in the table now.
				DELETE #DBs
				WHERE DBName LIKE '%\%%' ESCAPE '\'

			END --@IncludeRAW
			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------END Insert LIKE Include DB Names-----------------
			--------------------------------------------------------------
			--------------------------------------------------------------
				
        END -- <> All

    ELSE IF @Include = 'All' OR @Include IS NULL 
        BEGIN -- = 'All'

            INSERT  #DBs (DBName, IsReadOnly, StateDesc, ReindexGroupOrder, ReindexOrder)
                    SELECT  Name, is_read_only, state_desc, 0, 0
                    FROM    master.sys.databases
                    WHERE   NAME NOT IN ( 'ReportServerTempDB',
                                            'tempdb' )


			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------BEGIN Delete ExcludeFromReindex------------------
			--------------------------------------------------------------
			--------------------------------------------------------------

			DELETE D
			FROM #DBs D
			INNER JOIN Minion.IndexSettingsDB DBM WITH (NOLOCK)
			ON DBM.DBName = D.DBName
			WHERE DBM.Exclude = 1
			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------END Delete ExcludeFromReindex--------------------
			--------------------------------------------------------------
			--------------------------------------------------------------


			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------BEGIN Set GroupOrder-----------------------------
			--------------------------------------------------------------
			--------------------------------------------------------------
										                
			UPDATE D 
			SET D.ReindexGroupOrder = DBM.ReindexGroupOrder,
				D.ReindexOrder = DBM.ReindexOrder
			FROM #DBs D
			INNER JOIN Minion.IndexSettingsDB DBM WITH (NOLOCK)
			ON DBM.DBName = D.DBName
			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------END Set GroupOrder-------------------------------
			--------------------------------------------------------------
			--------------------------------------------------------------

        END -- = 'All'

END; -- @ReorgMode IS NOT NULL
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
---------------------------------END Process Included DBs-------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
------------BEGIN Process Excluded DBs--------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

	SET @ExcludeRAW = @Exclude;

    IF @Exclude IS NOT NULL 
        BEGIN

			--Get rid of any spaces in the DB list.
            SET @Exclude = REPLACE(@Exclude, ' ', '') 

            DECLARE @ExcludeDBNameTable TABLE ( DBName NVARCHAR(400) );
            DECLARE @ExcludeDBNameString  NVARCHAR(400);
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

		--------------------------------------------------------------
		--------------------------------------------------------------
		----------------BEGIN LIKE Exclude DB Names-------------------
		--------------------------------------------------------------
		--------------------------------------------------------------


		--You can mix static and LIKE DB names so here's where we're processing the LIKE names.

		IF @ExcludeRAW LIKE '%\%%' ESCAPE '\'
		BEGIN --@ExcludeRAW
			DECLARE LikeDBs CURSOR
			READ_ONLY
			FOR SELECT DBName
			FROM @ExcludeDBNameTable
			WHERE DBName LIKE '%\%%' ESCAPE '\' 

			OPEN LikeDBs

			FETCH NEXT FROM LikeDBs INTO @currDBName
			WHILE (@@fetch_status <> -1)
			BEGIN
				SELECT @currDBName AS CurrDBName
						--INSERT @ExcludeDBNameTable (DBName)
						--SELECT Name
						--FROM master.sys.databases
						--WHERE Name LIKE @currDBName
						DELETE #DBs
						WHERE DBName LIKE @currDBName --'%\%%' ESCAPE '\'

				--SELECT @currDBName AS 'CurrDBName'		
				FETCH NEXT FROM LikeDBs INTO @currDBName
			END

			CLOSE LikeDBs
			DEALLOCATE LikeDBs


			---Now delete the LIKE DBs that were passed into the param as the actual DB names are in the table now.
			--DELETE #DBs
			--WHERE DBName LIKE '%\%%' ESCAPE '\'

		END --@ExcludeRAW

		--------------------------------------------------------------
		--------------------------------------------------------------
		-------------------END LIKE Exclude DB Names------------------
		--------------------------------------------------------------
		--------------------------------------------------------------

		--SELECT 'ExcludedDBs', * FROM @ExcludeDBNameTable 

        DELETE  DBs
        FROM    #DBs DBs
                INNER JOIN @ExcludeDBNameTable E ON DBs.DBName = E.DBName
		--WHERE DBName IN (SELECT DBName from @ExcludeDBNameTable)
    
	END -- IF @Exclude IS NOT NULL

----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
------------END Process Excluded DBs----------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
------------BEGIN Process Regex Excluded DBs--------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

	--You may want to exclude DBs based off of a regex expression.  The regex expression is stored in the Minion.DBMaintRegexLookup table.
	--This is great functionality and is meant for rotating dated archive DBs or dev DBs that rotate.  
	--As an example, a prod DB will be picked up by the routine, but maybe you don't want the dated versions to be reindexed... like Minion201408 and Minion201409.
	--These DBs get created and dropped every wk or so and you don't care about maintaining them.

	------!!! The regex function isn't available for 2005.

	If @Version >= 10
	BEGIN --@Version >= 2008
			SELECT DISTINCT
					DFL.Regex,
					DFL.Action
			INTO #RegexMatch
			FROM    Minion.DBMaintRegexLookup DFL
			WHERE   Action = 'Exclude'
					AND ( MaintType = 'All'
						  OR MaintType = 'Reindex'
						)

		SET @RegexCT = (select count(*) from #RegexMatch)

		If @RegexCT > 0

		BEGIN --@RegexCT > 0
			CREATE TABLE #RegexLookup
				(
				  DBName NVARCHAR(400) NULL ,
				  Action VARCHAR(10)
				)

			DECLARE @Regex NVARCHAR(200) , 
				@Action VARCHAR(10) ,
				@RegexCMD  NVARCHAR(2000);

			DECLARE @Instance NVARCHAR(128);
			SET @Instance = (SELECT CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)));


			DECLARE DBs CURSOR READ_ONLY
			FOR
			SELECT * from #RegexMatch
				--SELECT DISTINCT
				--        DFL.Regex ,
				--        DFL.Action
				--FROM    Minion.DBMaintRegexLookup DFL
				--WHERE   Action = 'Exclude'
				--        AND ( MaintType = 'All'
				--              OR MaintType = 'Reindex'
				--            )

			OPEN DBs

			FETCH NEXT FROM DBs INTO @Regex, @Action
			WHILE ( @@fetch_status <> -1 ) 
				BEGIN

					SET @RegexCMD = 'EXEC xp_cmdshell ''powershell "'

					If @Version = 10
					BEGIN
						SET @RegexCMD = @RegexCMD  + 'ADD-PSSNAPIN SQLServerCmdletSnapin100; '
					END

					If @Version >= 11
					BEGIN
						SET @RegexCMD = @RegexCMD  + 'IMPORT-MODULE SQLPS -DisableNameChecking; '
					END
					SET @RegexCMD = @RegexCMD + '$DBList = invoke-sqlcmd -serverinstance "' + @Instance + '" -database master -query ''''select Name from master..sysdatabases''''; $FinalList = $DBList | ?{$_.Name -match '''''
			   + @Regex + '''''}; $FinalList"  '''	--$FinalList = $DBList | ?{$_.Name -match ''''Minion\w+''''}; $FinalList"  '''	
		PRINT @RegexCMD
					INSERT  #RegexLookup
							( DBName )
							EXEC ( @RegexCMD
								) 

					FETCH NEXT FROM DBs INTO @Regex, @Action
				END

			CLOSE DBs
			DEALLOCATE DBs


		--Get rid of any rows that aren't actually DBNames.  The cmdshell gives us back some crap with our results.-
			DELETE  #RegexLookup
			WHERE   DBName IS NULL

		--Delete DBs that are meant to be excluded off of the Regex search.
			DELETE  DBs
			FROM    #DBs DBs
					INNER JOIN #RegexLookup FL ON DBs.DBName = FL.DBName

		END --@RegexCT > 0

	END --@Version >= 2008

----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
------------END Process Regex Excluded DBs----------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
------------BEGIN ONLINE DBs----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
	--This is done after everything else because no matter what you picked, you can't reindex a DB that isn't online and healthy,
	--so it has to be excluded, but we don't want it to fall out of the list until it's necessary or it may
	-- be put back in by a later step.
	DELETE #DBs
	WHERE StateDesc <> 'ONLINE';

----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
------------END ONLINE DBs------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
------------BEGIN ReadOnly DBs----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
	--This is done after everything else because no matter what you picked, you can't reindex a READONLY DB,
	--so it has to be excluded, but we don't want it to fall out of the list until it's necessary or it may
	-- be put back in by a later step.
	DELETE #DBs
	WHERE IsReadOnly = 1;

----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
------------END ReadOnly DBs------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
------------BEGIN Logging---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
    IF @StmtOnly = 0
		IF @RegexCT > 0
		BEGIN
		----Get comma-delimited list of DBs that were kicked out by the Regex lookup.
				DECLARE @RegexDBs NVARCHAR(4000) 
			SELECT  @RegexDBs = COALESCE(@RegexDBs + ', ', '') + DBName
			FROM    #RegexLookup
			WHERE   DBName IS NOT NULL

		END
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
------------END Logging-----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
------------BEGIN DB Cursor-------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

	DECLARE	@AGResults TABLE ( numReplicaIDs INT );

    DECLARE DBs CURSOR READ_ONLY
    FOR
        SELECT  DBName
        FROM    #DBs
		ORDER BY ReindexGroupOrder DESC, ReindexOrder DESC

    OPEN DBs

    FETCH NEXT FROM DBs INTO @currDB
    WHILE ( @@fetch_status <> -1 ) 
        BEGIN

            IF @StmtOnly = 0 
                BEGIN --@StmtOnly = 0 

-------Check that the DB is the Primary Replica in an AG.
--Only Version 11 and Enterprise will work so we're only going to check if it meets both criteria.
		If @Version >= 11 AND @OnlineEdition = 1
			BEGIN --@Version >= 11

					--- We HAVE to run this select statement as an EXEC; even with the IF, this'd generate an error on SQL 05/08.
					INSERT	INTO @AGResults
							( numReplicaIDs
							)
							EXEC
								( 'select count(replica_id) from sys.databases where Name = '''
								  + @currDB + ''' AND replica_id IS NOT NULL'
								);

					SELECT TOP 1
							@DBIsInAG = numReplicaIDs
					FROM	@AGResults;

					DELETE FROM @AGResults; -- We're in a loop; clear results each time.


					If @DBIsInAG = 1
					BEGIN --@DBIsInAG = 1
						SET @IsPrimaryReplica = (SELECT count(*)        
						FROM             
							sys.databases dbs,             
							sys.dm_hadr_availability_replica_states ars         
						WHERE             
							dbs.replica_id = ars.replica_id             
							AND dbs.name = @currDB  
							AND ars.role = 1)
					END --@DBIsInAG = 1
			END --@Version >= 11


			If @DBIsInAG = 0 OR (@DBIsInAG = 1 AND @IsPrimaryReplica = 1)
				BEGIN
                    EXEC Minion.IndexMaintDB @currDB, @IndexOption, @ReorgMode,
                        @RunPrepped, @PrepOnly, @StmtOnly 
				END

                END --@StmtOnly = 0 

            IF @StmtOnly = 1 
                BEGIN
                    PRINT 'EXEC Minion.IndexMaintDB @DBName = ''' + @currDB
                        + ''', @IndexOption = ''' + @IndexOption
                        + ''', @ReorgMode = ''' + @ReorgMode + ''', '
                        + ' @RunPrepped = ' + CAST(@RunPrepped AS CHAR(1))
                        + ', ' + ' @PrepOnly = ' + CAST(@PrepOnly AS CHAR(1))
                        + ', @StmtOnly = ' + CAST(@StmtOnly AS CHAR(1))
                        + ', @LogProgress = ' + CAST(@StmtOnly AS CHAR(1))
                    PRINT 'GO'
                END
            FETCH NEXT FROM DBs INTO @currDB
        END

    CLOSE DBs
    DEALLOCATE DBs


----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
------------END DB Cursor---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

    SELECT  *
    FROM    #DBs
	ORDER BY ReindexGroupOrder DESC, ReindexOrder DESC



GO
