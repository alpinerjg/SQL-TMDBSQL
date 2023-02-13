SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[IndexMaintDB]
	@DBName NVARCHAR(400) , 
	@IndexOption VARCHAR(7) ,
	@ReorgMode VARCHAR(7) , 
	@RunPrepped BIT , 
	@PrepOnly BIT , 
	@StmtOnly BIT , 
	@LogProgress BIT = 1 
AS 

--v.1.3
/***********************************************************************************
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------------------Minion Reindex------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Created By: MidnightSQL Consulting LLC. and MidnightDBA.com

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

Purpose: This SP does a reindex or reorg of tables meeting the criteria stored in master..IndexMaint.
	It has many features that listed below.

Features:
	*  Redinex or reorg.
	*  Set reindex and reorg threshholds at the table level using the IndexMaint table.
	*  Reports everything it does to the IndexMaintLog table.  You can see how long it's taking at 
	   every step.
	*  A look at the IndexMaintLog table will tell you how long the current index took last time 
	   it was run.  So you can estimate how long it'll take this time.
	*  Get row counts for the tables after the reindex.  This can help with planning downtime windows when data expands.
	*  Get a frag % after the Op.  Some tables don't ever defrag completely.  Even when they're newly 
	   reindexed they're still at say 35%.  This lets you know what the % is when the reindex/reorg is fresh.
	*  Order the tables at 2 levels.  You can group them and say that you want this entire group of tables to be done
	   first.  And you can say that within those groups you want the tables to be done in a certain order. 
	*  Set the fillfactor and pad index options for each table in IndexMaint table.
	*  Process LOB, nonLOB or All tables from single sp.
	*  Specify many reindex options in IndexMaint table.
	*  Choose to update stats or not when you do a reorg.  Set in IndexMaint.
	*  You can specify that a table always gets processed, or never gets processed by setting the values in IndexMaint.
	   To make sure a table always gets processed, set the Threshold cols to 0.  To make sure they're never processed, set them
	   to above 100.  Since the percent will never be above 100, they'll never reach the threashold.
	*  Specify that any table can have online/offline reindex. (assuming it's supported).
	*  You can get the frag level of the desired tables beforehand and when this SP runs it'll spend its time actually reindexing
	   tables instead of finding frag levels.  In large DBs it can take a very long time to get the frag level of the tables so 
	   it can take up to several hours to even determine which tables need to be reindexed.  If you have such a DB and a tight 
	   maint window, you may take advantage of this feature and get the frag levels earlier in the day and spend your maint window
	   on the actual maint.   

Limitations:
	*  You can't specify a stop time for the sp.  So you can't tell it to say run for only 2hrs.
	*  Doesn't work for SQL Server 2000.
	*  All options specified in IndexMaint are for each table, which means that all the indexes on that table will
	   be processed with those values.  Keeping up with individual indexes would just be too much effort in an enterprise.

Notes:
	* Be careful when using PostFrag feature.  It can greately increase the length of your maint and
	  since it is done after every index is processed, you won't roll through the individual indexes as fast.
  
	* There are times when I could have used static tables and it may have even been easier and made the SP shorter.  However,
	  one of my main goals when pushing these objects out to servers is to push out as few objects as possible.  Therefore,
	  I will only push out static objects when there is no other choice.  

	* Be aware that part of the functionality keys off of the [Status] used in Minion.IndexMaintLogDetails. Specifically, 
	  we want to keep the DB-level stats gathering row, so the status for that row must always include FRAG STATS, and none
	  of the index-level rows can include the phrase FRAG STATS.  -JM, 1.3


Walkthrough: 
----------------
	Declare Vars
	Initial Status
	Get RecoveryModel
	Get Version Info
	Check Param Logic
	Port
	DBPreCode
	Index Selection
		Log Status
	delete excluded tables
	delete unwanted indexes
	Get Index Fragmentation
	Prep Save
	Finalize Index Options
	Initial Log Entry
	Get Row Count 
		Log Status
		Row CT Log
	Log Status
	Insert #TableFrag
		Create #IndexTableFrag
	Reindex Stmt Cursor
	DBPostCode
	Central Logging
	Reset RecoveryModel
	Log to IndexMaintLogMaster

Conventions:
----------------


Parameters:
-----------

	@DBName	- Database name to be reindexed. We reindex a single DB at a time.
	
	@IndexOption - Valid options: All, ONLINE, OFFLINE.  So All the indexes, 
	or only the indexes that can be done online or offline.
    
	@ReorgMode - Valid options: All, REORG, REBUILD. For REORG mode, only 
	REORG stmts will be generated.  For REBUILD, only REBUILD stmts will be 
	generated.

	@RunPrepped - Valid options: 1, 0. If you've collected index frag stats 
	ahead of time by running with @PrepOnly = 1, then you can use this option. 
    
	@PrepOnly - Valid options: 1, 0. Only gets index frag stats and saves to a 
	table.  This preps the DB to be reindexed.  Run this with @RunPrepped = 1 
	to take advantage of the prep.
    
	@StmtOnly - Valid options: 1, 0. Only prints reindex stmts.  Excellent 
	choice for running stmts manually.  Allows you to pick and choose which 
	indexes you want to do or just see how many are over the thresholds.
    
	@LogProgress - Valid options: 1, 0.  Allows you to have every step of the 
	run printed in the log so you can see the progress it's making.  This can 
	take a little extra time so leave it out if you just want it to run without
	being monitored.

Tables:
--------
	#IndexName - The list of all indexes in the database.  This list is then reduced to only those
				 that meet the criteria for reindexing given in the parameters and settings tables.
	
	#PostFrag - For use in gathering fragmentation stats after index operations are complete, per DB. []
	
	#IndexPhysicalStats - For use in deciding which indexes are maintained, based on the index's physical
							stats. Used per DB


Example Execution:
--------------------
	-- Demo DB, reorg all
	EXEC [Minion].[IndexMaintDB] @DBName = 'Demo'
		, @IndexOption = 'All'
		, @ReorgMode = 'All'
		, @RunPrepped = 0
		, @PrepOnly = 0
		, @StmtOnly = 0
	GO

	-- Demo DB, prep only
	EXEC [Minion].[IndexMaintDB] @DBName = 'Demo'
		, @IndexOption = 'All'
		, @ReorgMode = 'All'
		, @RunPrepped = 1
		, @PrepOnly = 0
		, @StmtOnly = 0
	GO


Revision History:
	9/23/2014	Added rowcount functionality, removed #TableFrag references. J.M.
	1.3			Version 1.3: changed so we get @Version (etc.) from Minion.DBMaintSQLInfoGet.
				Moved #TableFrag to just before "BEGIN Get Row Count"; it has to be after all 
				of the modifications to Minion.IndexTableFrag are done. HEAPS handling. Improved
				international support. See "Revisions" in the help.

DEPRECATED
	@PostFragVar - @table that holds intermediate results for the postFrag operation.  It's used because
					you need to get it from dynamic sql.  The data in this var is immediately
					moved to a local var to make the update easier.
NOTES
	SET QUOTED_IDENTIFIER ON is critical, as we use quotes and not brackets for table and index names.
***********************************************************************************/



--IF @DBName = 'Help'
--GOTO HELP
SET QUOTED_IDENTIFIER ON;


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
----------------------------------------BEGIN Declare Vars----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
	DECLARE 
		@ReorgThreshold TINYINT ,
		@RebuildThreshold TINYINT ,
		@Fillfactor TINYINT ,
		@PadIndex VARCHAR(3) ,
		@Online VARCHAR(3) ,
		@SortInTempDB VARCHAR(3) ,
		@MAXDOP TINYINT ,
		@DataCompression VARCHAR(50) ,
		@PartitionReindex BIT ,
		@GetRowCT BIT ,
		@GetPostFragLevel BIT ,
		@UpdateStatsOnDefrag BIT ,
		@ReindexGroupOrder BIT ,
		@ReindexOrder BIT ,
		@StatScanOption VARCHAR(25) ,
		@IndexScanMode VARCHAR(25) ,
		@IncludeUsageDetails BIT,
		@IsClustered BIT;

	IF @IndexOption IS NULL 
		BEGIN
			SET @IndexOption = 'All'
		END

	IF @ReorgMode IS NULL 
		BEGIN
			SET @ReorgMode = 'All'
		END

	DECLARE	@ExecutionDateTime DATETIME ,
		@RebuildPct TINYINT ,
		@ReorgPct TINYINT ,
		@LogDB VARCHAR(100) ,
		@SQL NVARCHAR(2000) ,
		@LogSQL NVARCHAR(2000) ,
		@ReindexSQL NVARCHAR(4000) ,
		@RowCT BIGINT ,
		@RowCTSQL NVARCHAR(2000) ,
		@LogPostFrag BIT ,
		@CurrentRecoveryModel VARCHAR(12) ,
		@ReindexRecoveryModel VARCHAR(12) ,
		@Version DECIMAL(3,1), --*-- 1.3
		@Edition VARCHAR(15) ,
		@TableCtrl NVARCHAR(100) ,
		@currDBID INT ,
		@currSchemaName NVARCHAR(400) ,
		@currTableID BIGINT ,
		@currTableName NVARCHAR(400),
		@currIndexName NVARCHAR(400),
		@currIndexID INT ,
		@currIndexType INT ,
		@currIndexTypeDesc VARCHAR(50) ,
		@currPartitionNumber INT ,
		@currFragLevel VARCHAR(50) ,
		@currOP VARCHAR(10) ,
		@currReorgThreshold VARCHAR(50) ,
		@currRebuildThreshold VARCHAR(50) ,
		@currFILLFACTORopt VARCHAR(50) ,
		@currPadIndex VARCHAR(50) ,
		@currONLINEopt VARCHAR(50) ,
		@currSortInTempDB VARCHAR(50) ,
		@currMAXDOPopt VARCHAR(50) ,
		@currDataCompression VARCHAR(100) ,
		@currIgnoreDupKey VARCHAR(50) ,
		@currStatsNoRecompute VARCHAR(50) ,
		@currAllowRowLocks VARCHAR(50) ,
		@currAllowPageLocks VARCHAR(50) ,
		@currLogProgress BIT ,
		@currLogRetDays SMALLINT ,
		@currPushToMinion BIT ,
		@currLogIndexPhysicalStats BIT ,
		@currTablePreCode NVARCHAR(MAX) ,
		@currTablePostCode NVARCHAR(MAX) ,
		@TablePreCodeBeginDateTime DATETIME ,
		@TablePreCodeEndDateTime DATETIME ,
		@TablePostCodeBeginDateTime DATETIME ,
		@TablePostCodeEndDateTime DATETIME ,
		@currPartitionReindex BIT ,
		@currGetRowCT BIT ,
		@currGetPostFragLevel BIT ,
		@currUpdateStatsOnDefrag BIT ,
		@currIndexScanMode VARCHAR(25) ,
		@currStatScanOption VARCHAR(25) ,
		@currWaitAtLowPriority BIT ,
		@currMaxDurationInMins INT ,
		@currAbortAfterWait VARCHAR(20) ,
		@currStmtPrefix NVARCHAR(1000),
		@currStmtSuffix NVARCHAR(1000),
		@currRebuildHeap BIT,	--*-- 1.3
		@OpBeginDateTime DATETIME ,
		@OpEndDateTime DATETIME ,
		@CallBeginDateTime DATETIME ,
		@CallEndDateTime DATETIME ,
		@RowCTBeginDateTime DATETIME ,
		@RowCTEndDateTime DATETIME ,
		@PostFragBeginDateTime DATETIME ,
		@PostFragEndDateTime DATETIME ,
		@PostFragLevel TINYINT ,
		@StatsBeginDateTime DATETIME ,
		@StatsEndDateTime DATETIME ,
		@StatsSQL NVARCHAR(2000) ,
		@ChangeComment NVARCHAR(100) ,
		@TableListSQL VARCHAR(2000) ,
		@FragStatsSQL VARCHAR(2000) ,
		@FragTableCtrl VARCHAR(100) ,
		@PostFragSQL VARCHAR(MAX) ,
		@currIndexForFragStats NVARCHAR(500) ,
		@ErrLine INT ,
		@ErrMsg NVARCHAR(MAX) ,
		@UpdateStatErrMsg NVARCHAR(MAX),  --*-- 1.3
		@ErrSev VARCHAR(50) ,
		@ErrProc VARCHAR(50) ,
		@ErrNum INT ,
		@DBPreCode NVARCHAR(MAX) ,
		@DBPostCode NVARCHAR(MAX) ,
		@DBPreCodeBeginDateTime DATETIME ,
		@DBPreCodeEndDateTime DATETIME ,
		@DBPostCodeBeginDateTime DATETIME ,
		@DBPostCodeEndDateTime DATETIME ,
		@DBPreCodeRunTimeInSecs INT ,
		@DBPostCodeRunTimeInSecs INT ,
		@NumTablesProcessed INT ,
		@NumIndexesProcessed INT ,
		@NumIndexesRebuilt INT ,
		@NumIndexesReorged INT ,
		@FragLogCtr INT ,
		@FragLogTotalCtr INT,
		@WithErrors BIT,
		@Status NVARCHAR(1000),
		@TableCT INT,
		@currTableIterator INT,
		@Port VARCHAR(10),
		@ServerInstance NVARCHAR(200),
		@MaintDB VARCHAR(150);

	SET @TableCtrl = '';				   
	SET @FragTableCtrl = '';
	SET @FragLogCtr = 0;	
	SET @ExecutionDateTime = GETDATE();
	SET @WithErrors = 0;
	
	IF @LogProgress IS NULL
	SET @LogProgress = 1

	SET NOCOUNT ON;

SET @MaintDB = DB_NAME();
SET @ServerInstance = @@ServerName;
SET @IsClustered = CONVERT(CHAR(1), SERVERPROPERTY('IsClustered'));

--Here we're connecting locally if it's not a cluster.  
IF @ServerInstance NOT LIKE '%\%' AND (@IsClustered = 0 OR @IsClustered IS NULL)
	BEGIN
		SET @ServerInstance = '.'
	END
IF @ServerInstance LIKE '%\%' AND (@IsClustered = 0 OR @IsClustered IS NULL)
	BEGIN
			SET @ServerInstance = '.' + '\' + CONVERT(CHAR(100), SERVERPROPERTY('InstanceName'));
	END
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
-----------------------------------------END Declare Vars-----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN Initial Status---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

----This initial log gives you something to look at while the routine is doing this initial stuff before
----it actually begins processing indexes.  This way you have some insight into what the routine is doing.

	IF @StmtOnly = 0 
		BEGIN --@StmtOnly = 0
			--If ((@PrepOnly <> 1) AND (@RunPrepped <> 1)) OR (@PrepOnly = 1)
				BEGIN
					INSERT	Minion.IndexMaintLog
							( ExecutionDateTime ,
							  Status ,
							  DBName,
							  Tables,
							  RunPrepped,
							  PrepOnly,
							  ReorgMode
						
							)
							SELECT	@ExecutionDateTime,
									'Configuring Run' ,
									@DBName,
									@IndexOption,
									@RunPrepped,
									@PrepOnly ,
									@ReorgMode
				END
		END --@StmtOnly = 0


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Initial Status-----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN Get RecoveryModel------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

	IF @StmtOnly = 0 
		BEGIN  --@StmtOnly = 0   --RecoveryModel

		IF @PrepOnly = 0
		BEGIN --@PrepOnly = 0

			SET @CurrentRecoveryModel = ( SELECT	recovery_model_desc
										  FROM		master.sys.databases
										  WHERE		name = @DBName
										);
			SET @ReindexRecoveryModel = ( SELECT	RecoveryModel
										  FROM		Minion.IndexSettingsDB
										  WHERE		DBName = 'MinionDefault'
										);

		----Override default RecoveryModel if a DB override exists.
			IF ( SELECT	RecoveryModel
				 FROM	Minion.IndexSettingsDB
				 WHERE	DBName = @DBName
			   ) IS NOT NULL 
				BEGIN
					SET @ReindexRecoveryModel = ( SELECT	RecoveryModel
												  FROM		Minion.IndexSettingsDB
												  WHERE		DBName = @DBName
												);
				END


			IF @ReindexRecoveryModel IS NULL 
				BEGIN
					SET @ReindexRecoveryModel = @CurrentRecoveryModel;
				END

		----Don't change RecoveryModel if value is NULL in IndexDBSettings.
			BEGIN  --@ReindexRecoveryModel

				IF @CurrentRecoveryModel <> @ReindexRecoveryModel
					AND @ReindexRecoveryModel IS NOT NULL 
					BEGIN
						DECLARE	@RecoveryModelSQL VARCHAR(150) ,
							@RecoveryModelChanged BIT;
	
						SET @RecoveryModelSQL = 'ALTER DATABASE [' + @DBName + '] SET RECOVERY ' + @ReindexRecoveryModel;
						EXEC (@RecoveryModelSQL);
						SET @RecoveryModelChanged = 1;
					END
			END  --@ReindexRecoveryModel


			IF @ReindexRecoveryModel = @CurrentRecoveryModel 
				BEGIN 
					SET @RecoveryModelChanged = 0;
				END  
			END --@PrepOnly = 0

		END  --@StmtOnly = 0   --RecoveryModel

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Get RecoveryModel--------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN Get Version Info-------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

	--SELECT	@Version = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(15)), CHARINDEX('.', CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(15)), 1) - 1)
	--SELECT	@Edition = CAST(SERVERPROPERTY('Edition') AS VARCHAR(25));

	DECLARE	@OnlineEdition BIT

	--IF @Edition LIKE '%Enterprise%'
	--	OR @Edition LIKE '%Developer%' 
	--	BEGIN
	--		SET @OnlineEdition = 1
	--	END
	
	--IF @Edition NOT LIKE '%Enterprise%'
	--	AND @Edition NOT LIKE '%Developer%' 
	--	BEGIN
	--		SET @OnlineEdition = 0
	--	END	

	SELECT 
		@Version = [Version],
		@Edition = Edition,
		@OnlineEdition = OnlineEdition
	FROM Minion.DBMaintSQLInfoGet();	--*-- 1.3

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Get Version Info---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN Check Param Logic------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
	
	IF @RunPrepped = 1
		AND @PrepOnly = 1
--You can't run in prepped mode and prep it at the same time.
--The SP would physically run, but you would get dupes it would never
--actually reindex anything.
		BEGIN

			UPDATE Minion.IndexMaintLog
			SET Status = 'FATAL ERROR: @RunPrepped and @PrepOnly are both 1.  This is a logic error.  Set one of them to 0.  You either want to prep or you want to run prepped.  You cannot do both at the same time.'
			WHERE ExecutionDateTime = @ExecutionDateTime 
			AND   DBName = @DBName

			RAISERROR ('@RunPrepped and @PrepOnly are both 1.  This is a logic error.  Set one of them to 0.  You either want to prep or you want to run prepped.  You cannot do both at the same time.', 16, 1); 

			RETURN;		    
		END	

	IF @OnlineEdition = 0
		AND @IndexOption = 'ONLINE'
--You can't reindex ONLINE on this edition of SQL Server.  No work will be done.  Change the @IndexOption parameter to 'All' or 'Offline'.
		BEGIN

			UPDATE Minion.IndexMaintLog
			SET Status = 'FATAL ERROR: @OnlineEdition = 0 and @IndexOption = ''ONLINE''.  This is a logic error.  You can''t reindex ONLINE on this edition of SQL Server.  No work will be done.  Change the @IndexOption parameter to ''All'' or ''Offline'''
			WHERE ExecutionDateTime = @ExecutionDateTime 
			AND   DBName = @DBName

			RAISERROR ('@OnlineEdition = 0 and @IndexOption = ''ONLINE''.  This is a logic error.  You can''t reindex ONLINE on this edition of SQL Server.  No work will be done.  Change the @IndexOption parameter to ''All'' or ''Offline''', 16, 1); 			
			
			RETURN;	    
		END	

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Check Param Logic--------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN Port-------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

	SET @Port = (SELECT TOP 1 Port FROM Minion.IndexSettingsDB)

	 IF @ServerInstance NOT LIKE '%\%'
		BEGIN
			SET @Port = CASE WHEN @Port IS NULL THEN ',' + '1433'
							 WHEN @Port IS NOT NULL THEN ',' + @Port
							 END
		END
	IF @ServerInstance LIKE '%\%'
		BEGIN
				SET @Port = CASE WHEN @Port IS NULL THEN ''
								 WHEN @Port IS NOT NULL THEN ',' + @Port
								 END
		END

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Port---------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN DBPreCode--------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

	IF @StmtOnly = 0 
	BEGIN --@StmtOnly = 0 
			IF @PrepOnly = 0
				BEGIN --@PrepOnly = 0
				----Get default PreCode for all DBs.
					SET @DBPreCode = ( SELECT	DBPreCode
									   FROM		Minion.IndexSettingsDB
									   WHERE	DBName = 'MinionDefault'
									 )

				----Override default PreCode if a DB override exists.
					IF ( SELECT	DBPreCode
						 FROM	Minion.IndexSettingsDB
						 WHERE	DBName = @DBName
					   ) IS NOT NULL 
						BEGIN
							SET @DBPreCode = ( SELECT	DBPreCode
											   FROM		Minion.IndexSettingsDB
											   WHERE	DBName = @DBName
											 );
						END




					IF @DBPreCode IS NOT NULL 
						BEGIN --@DBPreCode IS NOT NULL

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------BEGIN Log Status---------------------------------
			--------------------------------------------------------------
			--------------------------------------------------------------

							IF @StmtOnly = 0 
								BEGIN --@StmtOnly = 0
								IF @PrepOnly = 0
									BEGIN
												UPDATE	Minion.IndexMaintLog
												SET		Status = 'Running DB PreCode'
												WHERE	ExecutionDateTime = @ExecutionDateTime
														AND DBName = @DBName
									END

								END --@StmtOnly = 0

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------END Log Status-----------------------------------
			--------------------------------------------------------------
			--------------------------------------------------------------
	

							SET @DBPreCodeBeginDateTime = GETDATE();
							EXEC (@DBPreCode)
							SET @DBPreCodeEndDateTime = GETDATE();

						END --@DBPreCode IS NOT NULL
				END --@PrepOnly = 0
		END --@StmtOnly = 0

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END DBPreCode--------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN Index Selection--------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------BEGIN Log Status---------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	
	IF @StmtOnly = 0 
		BEGIN --@StmtOnly = 0

			--IF @LogProgress = 1 
			--	BEGIN --@LogProgress = 1

					--If @PrepOnly = 0
					--	Begin --@PrepOnly = 0
					
					INSERT	Minion.IndexMaintLogDetails
							( ExecutionDateTime ,
								Status,
								DBName
							)
							SELECT	@ExecutionDateTime ,
									'Configuring tables to process',
									@DBName;

						--End --@PrepOnly = 0
				--END --@LogProgress = 1
		END --@StmtOnly = 0

	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------END Log Status-----------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	

---In case there was an error during the last run and the table didn't get 
---completely cleared out, clear it out here.
	DELETE	Minion.IndexTableFrag
	WHERE	DBName = @DBName
			AND Prepped = 0;


	DELETE	Minion.IndexTableFrag
	WHERE	DBName = @DBName
			AND Prepped = 1
			AND ExecutionDateTime <> (SELECT MAX(ExecutionDateTime) FROM Minion.IndexTableFrag WHERE DBName = @DBName AND Prepped = 1);


	IF @RunPrepped = 0
	BEGIN --@RunPrepped = 0

		DECLARE	@IndexNameSQL NVARCHAR(2000)
		SET @IndexNameSQL = N'USE [' + @DBName
			+ N']; SELECT DISTINCT
			so.object_id ,
			SCHEMA_NAME(so.schema_id) AS SchemaName ,
			OBJECT_NAME(so.object_id) TableName ,
			si.Name AS IndexName ,
			si.index_id ,
			CAST(''ON'' AS VARCHAR(3)) AS ONLINEopt, -- CAST(NULL AS VARCHAR(3)) AS ONLINEopt ,
			si.type AS IndexType ,
			si.type_desc AS IndexTypeDesc ,
			is_disabled AS IsDisabled ,
			is_hypothetical AS IsHypothetical
	INTO    #T
	FROM    sys.indexes si WITH ( NOLOCK )
			INNER JOIN sys.objects so WITH ( NOLOCK )
			ON si.object_id = so.object_id
	WHERE   ( so.type = ''U''
			  OR so.type = ''V''
			)
			AND so.is_ms_shipped <> 1; 
			SELECT * from #T;'

	END --@RunPrepped = 0


	IF @RunPrepped = 0
	BEGIN --@RunPrepped = 0

		CREATE TABLE #IndexName 
			(
			  TableID INT ,
			  SchemaName NVARCHAR(400) COLLATE DATABASE_DEFAULT ,
			  TableName NVARCHAR(400) COLLATE DATABASE_DEFAULT ,
			  IndexName NVARCHAR(400) COLLATE DATABASE_DEFAULT ,
			  IndexID INT ,
			  ONLINEopt VARCHAR(3) COLLATE DATABASE_DEFAULT ,
			  IndexType TINYINT ,
			  IndexTypeDesc NVARCHAR(120) COLLATE DATABASE_DEFAULT ,
			  IsDisabled BIT ,
			  IsHypothetical BIT
			);

		INSERT #IndexName
		EXEC (@IndexNameSQL);

		CREATE NONCLUSTERED INDEX IndexNameix1 ON #IndexName (IsDisabled);
		CREATE NONCLUSTERED INDEX IndexNameix2 ON #IndexName (IsHypothetical);
		CREATE NONCLUSTERED INDEX IndexNameix3 ON #IndexName (IndexType);
		CREATE NONCLUSTERED INDEX IndexNameix4 ON #IndexName (TableID, IndexID) INCLUDE (ONLINEopt);

	END --@RunPrepped = 0


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Index Selection----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


	CREATE TABLE #PostFrag
		(
			MaxFrag TINYINT ,
			Index_ID INT ,
			Index_Level INT
		);

	CREATE TABLE #ReindexResults
		(
			ID INT IDENTITY(1, 1),
			col1 NVARCHAR(MAX) COLLATE DATABASE_DEFAULT
		);

	CREATE TABLE #UpdateStatsResults
		(
			ID INT IDENTITY(1, 1),
			col1 NVARCHAR(MAX) COLLATE DATABASE_DEFAULT
		);


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN delete excluded tables-------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


	IF @RunPrepped = 0
	BEGIN --@RunPrepped = 0

		DELETE	FROM I
		FROM	#IndexName I 
				INNER JOIN Minion.IndexSettingsTable IM ON I.SchemaName = IM.SchemaName 
														   AND I.TableName = IM.TableName 
		WHERE	IM.DBName = @DBName
				AND IM.Exclude = 1;

	END --@RunPrepped = 0

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END delete excluded tables---------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN delete unwanted indexes-----------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

	IF @RunPrepped = 0
	BEGIN --@RunPrepped = 0

		----Disabled indexes
		DELETE	FROM #IndexName
		WHERE	IsDisabled = 1;

		----Hypothetical indexes
		DELETE	FROM #IndexName
		WHERE	IsHypothetical = 1;

		----HEAPs ---update instead of delete but this is a good place for it. --*-- 1.3
		UPDATE #IndexName
		SET IndexName = 'TableHEAP'
		WHERE IndexName IS NULL;

		----In-Memory (Heakton)
		DELETE	FROM #IndexName
		WHERE	IndexType = 7;	--WHERE	IndexTypeDesc = 'NONCLUSTERED HASH'; 

	END --@RunPrepped = 0
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END delete unwanted indexes--------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------Begin Get Index Fragmentation------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

	IF @RunPrepped = 0
		OR @PrepOnly = 1
	--The point of having a prep mode is so you don't have to incur the cost
	--of getting the frag stats during your maint window.  So we're only
	--going to run this if we're trying to prep or running it w/o prep.
		BEGIN --@RunPrepped = 0 OR @PrepOnly = 1


			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------BEGIN Get Current Options------------------------
			--------------------------------------------------------------
			--------------------------------------------------------------
	
			--Set current DB options to Minion default for all DBs.
			--This is used if you haven't chosen to manage at the DB or table levels.

			--Get initial table and index list from #IndexName
			INSERT	Minion.IndexTableFrag 
					( ExecutionDateTime ,
						DBName ,
						DBID,
						TableID ,
						SchemaName ,
						TableName ,
						IndexName ,
						IndexID ,
						IndexType ,
						IndexTypeDesc ,
						IsDisabled ,
						ONLINEopt,
						IsHypothetical
					)
					SELECT	@ExecutionDateTime ,
							@DBName ,
							DB_ID(@DBName),
							TableID ,
							SchemaName ,
							TableName ,
							IndexName ,
							IndexID ,
							IndexType ,
							IndexTypeDesc ,
							IsDisabled ,
							ONLINEopt,
							IsHypothetical
					FROM	#IndexName

			--Now update with default options.
			UPDATE	ITF
			SET		
					ReorgThreshold = IMD.ReorgThreshold ,
					RebuildThreshold = IMD.RebuildThreshold ,
					FILLFACTORopt = IMD.FILLFACTORopt ,
					PadIndex = IMD.PadIndex ,
					ONLINEopt = IMD.ONLINEopt ,
					SortInTempDB = IMD.SortInTempDB ,
					MAXDOPopt = IMD.MAXDOPopt ,
					DataCompression = IMD.DataCompression ,
					GetRowCT = IMD.GetRowCT ,
					GetPostFragLevel = IMD.GetPostFragLevel ,
					UpdateStatsOnDefrag = IMD.UpdateStatsOnDefrag ,
					StatScanOption = IMD.StatScanOption ,
					IgnoreDupKey = IMD.IgnoreDupKey ,
					StatsNoRecompute = IMD.StatsNoRecompute ,
					AllowRowLocks = IMD.AllowRowLocks ,
					AllowPageLocks = IMD.AllowPageLocks ,
					WaitAtLowPriority = IMD.WaitAtLowPriority ,
					MaxDurationInMins = IMD.MaxDurationInMins ,
					AbortAfterWait = IMD.AbortAfterWait ,
					LogProgress = IMD.LogProgress ,
					LogRetDays = IMD.LogRetDays ,
					PushToMinion = IMD.PushToMinion ,
					LogIndexPhysicalStats = IMD.LogIndexPhysicalStats ,
					IndexScanMode = IMD.IndexScanMode ,
					TablePreCode = IMD.TablePreCode ,
					TablePostCode = IMD.TablePostCode,
					StmtPrefix = IMD.StmtPrefix,
					StmtSuffix = IMD.StmtSuffix,
					RebuildHeap = IMD.RebuildHeap	--*-- 1.3
			FROM	Minion.IndexTableFrag ITF 
					INNER JOIN Minion.IndexSettingsDB IMD ON 1 = 1 --We want to set all the values to default.  After, we'll override with either DB or table overrides.
			WHERE	IMD.DBName = 'MinionDefault'
					AND ITF.ExecutionDateTime = @ExecutionDateTime
					
		-------DB override values-------------
		--These are options for the individual DB.  Use this if you don't want to use the defaults.
		--If you manage even 1 option at this level they all have to be managed here.

			UPDATE	ITF
			SET		ReorgThreshold = IMD.ReorgThreshold ,
					RebuildThreshold = IMD.RebuildThreshold ,
					FILLFACTORopt = IMD.FILLFACTORopt ,
					PadIndex = IMD.PadIndex ,
					ONLINEopt = IMD.ONLINEopt ,
					SortInTempDB = IMD.SortInTempDB ,
					MAXDOPopt = IMD.MAXDOPopt ,
					DataCompression = IMD.DataCompression ,
					GetRowCT = IMD.GetRowCT ,
					GetPostFragLevel = IMD.GetPostFragLevel ,
					UpdateStatsOnDefrag = IMD.UpdateStatsOnDefrag ,
					StatScanOption = IMD.StatScanOption ,
					IgnoreDupKey = IMD.IgnoreDupKey ,
					StatsNoRecompute = IMD.StatsNoRecompute ,
					AllowRowLocks = IMD.AllowRowLocks ,
					AllowPageLocks = IMD.AllowPageLocks ,
					WaitAtLowPriority = IMD.WaitAtLowPriority ,
					MaxDurationInMins = IMD.MaxDurationInMins ,
					AbortAfterWait = IMD.AbortAfterWait ,
					LogProgress = IMD.LogProgress ,
					LogRetDays = IMD.LogRetDays ,
					PushToMinion = IMD.PushToMinion ,
					LogIndexPhysicalStats = IMD.LogIndexPhysicalStats ,
					IndexScanMode = IMD.IndexScanMode ,
					TablePreCode = IMD.TablePreCode ,
					TablePostCode = IMD.TablePostCode,
					StmtPrefix = IMD.StmtPrefix,
					StmtSuffix = IMD.StmtSuffix,
					RebuildHeap = IMD.RebuildHeap	--*-- 1.3
			FROM	Minion.IndexTableFrag ITF 
					INNER JOIN Minion.IndexSettingsDB IMD ON ITF.DBName = IMD.DBName
			WHERE	IMD.DBName = @DBName
					AND ITF.ExecutionDateTime = @ExecutionDateTime



			--------------------------------------------------------------
			-------------BEGIN Change Online Option-----------------------
			--------------------------------------------------------------
	


			---------------------BEGIN All SQL Versions---------------------
			----There are still datatypes that have to be done offline for all versions of SQL.
			BEGIN --All Versions

				DECLARE	@UpdateONLINEoptSQL NVARCHAR(2000)
				SET @UpdateONLINEoptSQL = 'USE [' + @DBName
					+ '];         UPDATE  T
			SET     ONLINEopt = ''OFF''
			FROM    [' + @MaintDB + '].Minion.IndexTableFrag T
					INNER JOIN sys.all_columns AC
					ON T.TableID = AC.object_id
			WHERE   ( AC.system_type_id IN ( 34, 35, 99, 241 )
					  OR AC.max_length = -1		  
					)
					AND T.IndexID = 1;

					UPDATE  T
			SET     ONLINEopt = ''OFF''
			FROM    [' + @MaintDB + '].Minion.IndexTableFrag T
					INNER JOIN sys.indexes si WITH ( NOLOCK )
					ON T.IndexID = si.index_id
					   AND T.TableID = si.object_id
					INNER JOIN sys.index_columns ic WITH ( NOLOCK )
					ON si.object_id = ic.object_id
					   AND si.index_id = ic.index_id
					   AND ic.index_id = T.IndexID -- Just mark the one index with the LOB column offline, not all indexes.
					INNER JOIN sys.columns sc WITH ( NOLOCK )
					ON si.object_id = sc.object_id
					   AND sc.column_id = ic.column_id
			WHERE   sc.system_type_id IN ( 34, 35, 99, 241 )
					OR sc.max_length = -1;';

				EXEC (@UpdateONLINEoptSQL);

			END --All Versions
			---------------------END All SQL Versions---------------------



			---------------------BEGIN Below 2012---------------------
			If @Version < 11
			BEGIN --@Version < 11

			--	DECLARE	@UpdateONLINEoptSQL NVARCHAR(2000)
				SET @UpdateONLINEoptSQL = 'USE [' + @DBName
					+ '];         UPDATE  T
			SET     ONLINEopt = ''OFF''
			FROM    [' + @MaintDB + '].Minion.IndexTableFrag T
					INNER JOIN sys.all_columns AC
					ON T.TableID = AC.object_id
			WHERE   ( AC.system_type_id IN ( 240 )
					  OR AC.max_length = -1		  
					)
					AND AC.user_type_id NOT IN (128)
					AND T.IndexID = 1;

					UPDATE  T
			SET     ONLINEopt = ''OFF''
			FROM    [' + @MaintDB + '].Minion.IndexTableFrag T
					INNER JOIN sys.indexes si WITH ( NOLOCK )
					ON T.IndexID = si.index_id
					   AND T.TableID = si.object_id
					INNER JOIN sys.index_columns ic WITH ( NOLOCK )
					ON si.object_id = ic.object_id
					   AND si.index_id = ic.index_id
					   AND ic.index_id = T.IndexID -- Just mark the one index with the LOB column offline, not all indexes.
					INNER JOIN sys.columns sc WITH ( NOLOCK )
					ON si.object_id = sc.object_id
					   AND sc.column_id = ic.column_id
			WHERE   sc.system_type_id IN ( 240 )
					OR sc.max_length = -1
					AND sc.user_type_id NOT IN (128);';


				EXEC (@UpdateONLINEoptSQL);

			END --@Version < 11
			---------------------END Below 2012---------------------


			---------------------BEGIN XML Indexes---------------------
			----XML indexes still have to be done offline so we'll handle them here until they can be done online.  
			----Either way, we'll handle them separately here.

			UPDATE  Minion.IndexTableFrag
			SET     ONLINEopt = 'OFF'
			WHERE IndexTypeDesc = 'XML';
	
			---------------------END XML Indexes---------------------
	 

			--------------------------------------------------------------
			-------------END Change Online Option-------------------------
			--------------------------------------------------------------
	




			--------------------------------------------------------------
			-------------BEGIN Remove (non)LOB Tables---------------------
			--------------------------------------------------------------
	

			-----Only do ONLINE or OFFLINE tables.  Whichever is passed in to the sp.
			-----You may only want to do tables that can be online or offline.
			-----The value gets passed into the SP and you delete the unwanted tables
			-----here.  This only counts for any editions of SQL that can be done
			-----ONLINE because otherwise they're all OFFLINE anyway.

			-----You can't use online mode one some versions of SQL so there's no need to even try.
			-----Set them all to OFF in this case.

			IF @RunPrepped = 0	
			BEGIN --@RunPrepped = 0

				IF @OnlineEdition = 0 
					BEGIN
	
						UPDATE	Minion.IndexTableFrag --#IndexName  
						SET		ONLINEopt = 'OFF'					
	
					END

			SET @OnlineEdition = 1
				IF @OnlineEdition = 1 
					BEGIN --@OnlineEdition = 1
						IF @IndexOption = 'ONLINE' --Only do ONLINE indexes.
							BEGIN --nonLOB
								DELETE	Minion.IndexTableFrag --#IndexName
								WHERE	ONLINEopt = 'OFF'
							END --nonLOB

						IF @IndexOption = 'OFFLINE' --Only do OFFLINE indexes.
							BEGIN --LOB
								DELETE	Minion.IndexTableFrag --#IndexName
								WHERE	ONLINEopt = 'ON'
							END --LOB

					END --@OnlineEdition = 1

			END --@RunPrepped - 0

			--------------------------------------------------------------
			-------------END Remove (non)LOB Tables-----------------------
			--------------------------------------------------------------
	

			--------------------------------------------------------------
			-------------BEGIN Heaps--------------------------------------	--*-- 1.3
			--------------------------------------------------------------
	
			---- If we have a heap, but we're in REORG mode, remove the heaps from the list. We don't reorg heaps.
			---- Note that this delete does NOT affect nonclustered indexes on the heaps; just the heaps (IndexType=0).
			IF @ReorgMode = 'REORG'
			BEGIN
				DELETE I
				FROM #IndexName AS I
					INNER JOIN Minion.IndexTableFrag AS ITF ON ITF.TableID = I.TableID
															AND ITF.IndexID = I.IndexID
				WHERE I.IndexType = 0
					  AND ITF.DBName = @DBName
					  AND ITF.ExecutionDateTime = @ExecutionDateTime;
			END;


			---- We may not want to process heaps.  So here, if we don't want to (RebuildHeaps isn't 1), remove them from the list.
			---- Note that this delete does NOT affect nonclustered indexes on the heaps; just the heaps (IndexType=0).
			IF @ReorgMode <> 'REORG'
			BEGIN
				DELETE I
				FROM #IndexName AS I
					INNER JOIN Minion.IndexTableFrag AS ITF ON ITF.TableID = I.TableID
															AND ITF.IndexID = I.IndexID
				WHERE I.IndexType = 0
					  AND ITF.DBName = @DBName
					  AND ITF.ExecutionDateTime = @ExecutionDateTime
					  AND ISNULL(ITF.RebuildHeap, 0) = 0;
			END;


			--------------------------------------------------------------
			-------------END Heaps----------------------------------------
			--------------------------------------------------------------
	

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------END Get Current Options--------------------------
			--------------------------------------------------------------
			--------------------------------------------------------------



			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------BEGIN Frag Stats Cursor--------------------------
			--------------------------------------------------------------
			--------------------------------------------------------------
	
			CREATE TABLE #IndexPhysicalStats
				(
					ExecutionDateTime DATETIME ,
					BatchDateTime DATETIME ,
					IndexScanMode VARCHAR(25) COLLATE DATABASE_DEFAULT ,
					DBName NVARCHAR(400) COLLATE DATABASE_DEFAULT ,
					SchemaName NVARCHAR(400) COLLATE DATABASE_DEFAULT ,
					TableName NVARCHAR(400) COLLATE DATABASE_DEFAULT ,
					IndexName NVARCHAR(400) COLLATE DATABASE_DEFAULT ,
					database_id SMALLINT NULL ,
					object_id INT NULL ,
					index_id INT NULL ,
					partition_number INT NULL ,
					index_type_desc NVARCHAR(60) COLLATE DATABASE_DEFAULT NULL ,
					alloc_unit_type_desc NVARCHAR(60) COLLATE DATABASE_DEFAULT NULL ,
					index_depth TINYINT NULL ,
					index_level TINYINT NULL ,
					avg_fragmentation_in_percent FLOAT NULL ,
					fragment_count BIGINT NULL ,
					avg_fragment_size_in_pages FLOAT NULL ,
					page_count BIGINT NULL ,
					avg_page_space_used_in_percent FLOAT NULL ,
					record_count BIGINT NULL ,
					ghost_record_count BIGINT NULL ,
					version_ghost_record_count BIGINT NULL ,
					min_record_size_in_bytes INT NULL ,
					max_record_size_in_bytes INT NULL ,
					avg_record_size_in_bytes FLOAT NULL ,
					forwarded_record_count BIGINT NULL -- ,
					--compressed_page_count bigint NULL
				);
			--We're going to cursor through and get the frag stats for all the indexes we want.
			--We're doing it at the index level so each table and maybe each index some day
			--can have it's own ScanMode.



			--------------------------------------------------------------
			-------------BEGIN Log Status---------------------------------
			--------------------------------------------------------------
	
			IF @StmtOnly = 0 
				BEGIN --@StmtOnly = 0

					UPDATE	Minion.IndexMaintLog
					SET		Status = 'Gathering Fragmentation Stats'
					WHERE	ExecutionDateTime = @ExecutionDateTime
							AND DBName = @DBName

				END --@StmtOnly = 0

			--------------------------------------------------------------
			-------------END Log Status-----------------------------------
			--------------------------------------------------------------
	

			--------------------------------------------------------------
			-------------BEGIN Table override values----------------------
			--------------------------------------------------------------
	
			--These are options for the individual table.  Use this if you don't want to use the defaults or DB level values.
			--If you manage even 1 option at this level they all have to be managed here.  That means you have to duplicate the 
			--threshold, indexscanmode, etc that you want to be used here.

			UPDATE	ITF
			SET		ITF.ReorgThreshold = IMD.ReorgThreshold ,
					ITF.RebuildThreshold = IMD.RebuildThreshold ,
					ITF.FILLFACTORopt = IMD.FILLFACTORopt ,
					ITF.PadIndex = IMD.PadIndex ,
					ITF.ONLINEopt = IMD.ONLINEopt ,
					ITF.SortInTempDB = IMD.SortInTempDB ,
					ITF.MAXDOPopt = IMD.MAXDOPopt ,
					ITF.DataCompression = IMD.DataCompression ,
					ITF.GetRowCT = IMD.GetRowCT ,
					ITF.GetPostFragLevel = IMD.GetPostFragLevel ,
					ITF.UpdateStatsOnDefrag = IMD.UpdateStatsOnDefrag ,
					ITF.StatScanOption = IMD.StatScanOption ,
					ITF.IgnoreDupKey = IMD.IgnoreDupKey ,
					ITF.StatsNoRecompute = IMD.StatsNoRecompute ,
					ITF.AllowRowLocks = IMD.AllowRowLocks ,
					ITF.AllowPageLocks = IMD.AllowPageLocks ,
					ITF.WaitAtLowPriority = IMD.WaitAtLowPriority ,
					ITF.MaxDurationInMins = IMD.MaxDurationInMins ,
					ITF.AbortAfterWait = IMD.AbortAfterWait ,
					ITF.LogProgress = IMD.LogProgress ,
					ITF.LogRetDays = IMD.LogRetDays ,
					ITF.PushToMinion = IMD.PushToMinion ,
					ITF.LogIndexPhysicalStats = IMD.LogIndexPhysicalStats ,
					ITF.IndexScanMode = IMD.IndexScanMode ,
					ITF.TablePreCode = IMD.TablePreCode ,
					ITF.TablePostCode = IMD.TablePostCode ,
					ITF.ReindexGroupOrder = IMD.ReindexGroupOrder ,
					ITF.ReindexOrder = IMD.ReindexOrder ,
					ITF.StmtPrefix = IMD.StmtPrefix ,
					ITF.StmtSuffix = IMD.StmtSuffix,
					ITF.RebuildHeap = IMD.RebuildHeap
			FROM	Minion.IndexTableFrag ITF
			INNER JOIN Minion.IndexSettingsTable IMD ON ITF.DBName = IMD.DBName
													AND ITF.TableName = IMD.TableName
													AND ITF.SchemaName = IMD.SchemaName
			WHERE	ITF.ExecutionDateTime = @ExecutionDateTime;
					--AND IMD.DBName = @DBName
					--AND ITF.SchemaName = @currSchemaName
					--AND ITF.TableName = @currTableName;
	
			--------------------------------------------------------------
			-------------END Table override values------------------------
			--------------------------------------------------------------

			--------------------------------------------------------------
			-------------BEGIN ONLINEopt stopgap--------------------------
			--------------------------------------------------------------
			-- We're transitioning away from the temp table, and managed to update ONLINEopt
			-- in ITF and not the temp table. MR 2.0 won't have #IndexName anyway, so for now
			-- we're just updating the temp table. 
			
			UPDATE I
			SET I.ONLINEopt = ITF.ONLINEopt
			FROM #IndexName AS I
			INNER JOIN Minion.IndexTableFrag AS ITF ON ITF.DBName = @DBName
				AND ITF.TableID = I.TableID
				AND ITF.IndexID = I.IndexID;


			--------------------------------------------------------------
			-------------END ONLINEopt stopgap----------------------------
			--------------------------------------------------------------

			DECLARE FragStats CURSOR READ_ONLY
			FOR
				SELECT	TableID ,
						SchemaName ,
						TableName  ,
						IndexName AS IndexName ,
						IndexID AS IndexID ,
						ONLINEopt
				FROM	#IndexName;

			OPEN FragStats;

			FETCH NEXT FROM FragStats INTO @currTableID, @currSchemaName,
				@currTableName, @currIndexName, @currIndexID, @currONLINEopt;
	
			WHILE ( @@fetch_Status <> -1 ) 
				BEGIN -- Begin Cursor Loop

					----Placeholder for index-level ops.
					--If @FragTableCtrl = @currTable	
					--	BEGIN
					--	END

					--IF @FragTableCtrl <> @currTableName 
					--	BEGIN --@FragTableCtrl <> @currTable
						-- Moved "Table override values" outside of the loop. --*-- 1.3
					--	END --@FragTableCtrl <> @currTable
	

					---------------------------------------------------
					--------------BEGIN Columnstore Settings-----------
					---------------------------------------------------
					--Some settings are incompatable with columnstore indexes.
					--Therefore, they need to be set here if the table has any columnstore indexes on it.

					--UPDATE ITF
					--SET ITF.ONLINEopt = 'OFFLINE',
					--	ITF.IgnoreDupKey = NULL

					--FROM	Minion.IndexTableFrag ITF
					--		INNER JOIN Minion.IndexTableFrag ITF2 ON ITF.DBName = ITF2.DBName
					--WHERE	ITF2.DBName = @DBName
					--		AND ITF.ExecutionDateTime = @ExecutionDateTime
					--		AND ITF.SchemaName = @currSchemaName
					--		AND ITF.TableName = @currTableName
					--		AND ITF2.IndexTypeDesc LIKE '%COLUMNSTORE%'

					---------------------------------------------------
					--------------END Columnstore Settings-------------
					---------------------------------------------------



					------------------------------------------------------
					------------BEGIN Get Index Frag Stats----------------
					------------------------------------------------------
					/* -- 1.3 instead of looping, perhaps run once for limited and once for detailed. */
					SET @currIndexScanMode = ( SELECT TOP ( 1 )
												ISNULL(IndexScanMode,
														'Limited') AS IndexScanMode -- Change NULL to Limited for logging purposes.  I don't like seeing NULL in the log if I can help it.
										FROM		Minion.IndexTableFrag
										WHERE	DBName = @DBName
												AND ExecutionDateTime = @ExecutionDateTime
												AND SchemaName = @currSchemaName
												AND TableID = @currTableID
												AND IndexID = @currIndexID
										);

					--UPDATE Minion.IndexTableFrag
					--SET IndexScanMode = @currIndexScanMode
					--WHERE	DBName = @DBName
					--AND ExecutionDateTime = @ExecutionDateTime
					--AND SchemaName = @currSchemaName
					--AND TableID = @currTableID
					--AND IndexID = @currIndexID

					---------------------BEGIN Log Status---------------------

					IF @StmtOnly = 0 
						BEGIN --@StmtOnly = 0

							IF @LogProgress = 1 
								BEGIN --@LogProgress = 1
									SET @FragLogCtr = @FragLogCtr + 1

									--If @PrepOnly = 0
										--Begin --@PrepOnly = 0

											UPDATE	Minion.IndexMaintLogDetails
											SET		Status = CAST(@FragLogCtr AS VARCHAR(10))
													+ ' of '
													+ CAST(@FragLogTotalCtr AS VARCHAR(10))
													+ ': GATHERING FRAG STATS: '
													+ @currSchemaName + '.'
													+ @currTableName + '.'
													+ @currIndexName
											WHERE	ExecutionDateTime = @ExecutionDateTime
													AND DBName = @DBName;

					--End --@PrepOnly = 0
								END --@LogProgress = 1
						END --@StmtOnly = 0

					---------------------END Log Status---------------------


					----This just makes the below insert easier to read.
					----Changed in v.1.3 to help with some edge cases where some names need to be in double-quotes instead of in [].
					--SET @currIndexForFragStats = '[' + @DBName + ']' + '.'
					--	+ '[' + @currSchemaName + ']' + '.' + '[' + @currTableName + ']'
					SET @currIndexForFragStats = '"' + @DBName + '"' + '.'
						+ '"' + @currSchemaName + '"' + '.' + '"' + @currTableName + '"'

				----PRINT @currIndexForFragStats
					INSERT	#IndexPhysicalStats
							( ExecutionDateTime ,
								IndexScanMode ,
								DBName ,
								SchemaName ,
								TableName ,
								IndexName ,
								database_id ,
								object_id ,
								index_id ,
								partition_number ,
								index_type_desc ,
								alloc_unit_type_desc ,
								index_depth ,
								index_level ,
								avg_fragmentation_in_percent ,
								fragment_count ,
								avg_fragment_size_in_pages ,
								page_count ,
								avg_page_space_used_in_percent ,
								record_count ,
								ghost_record_count ,
								version_ghost_record_count ,
								min_record_size_in_bytes ,
								max_record_size_in_bytes ,
								avg_record_size_in_bytes ,
								forwarded_record_count--, compressed_page_count
 							)
					SELECT	@ExecutionDateTime ,
							@currIndexScanMode ,
							@DBName ,
							@currSchemaName ,
							@currTableName ,
							@currIndexName ,
							database_id ,
							object_id ,
							index_id ,
							partition_number ,
							index_type_desc ,
							alloc_unit_type_desc ,
							index_depth ,
							index_level ,
							avg_fragmentation_in_percent ,
							fragment_count ,
							avg_fragment_size_in_pages ,
							page_count ,
							avg_page_space_used_in_percent ,
							record_count ,
							ghost_record_count ,
							version_ghost_record_count ,
							min_record_size_in_bytes ,
							max_record_size_in_bytes ,
							avg_record_size_in_bytes ,
							forwarded_record_count--, compressed_page_count
					FROM	sys.dm_db_index_physical_stats(DB_ID(@DBName),
														OBJECT_ID(@currIndexForFragStats),
														@currIndexID,
														NULL,
														@currIndexScanMode); 					

					--SELECT '#IndexPhysStats', * FROM #IndexPhysicalStats
					------------------------------------------------------
					------------END Get Index Frag Stats------------------
					------------------------------------------------------



					--------------------------------------------------------------
					-------------BEGIN Log IndexPhysicalStats---------------------
					--------------------------------------------------------------
					--The purpose of logging this is to get the raw stats for all indexes.
					--Therefore, the data is logged whether or not the index will have any
					--run against it.  This data is for analysis should you need it.

					SET @currLogIndexPhysicalStats = ( SELECT TOP ( 1 )
																LogIndexPhysicalStats
														FROM	  Minion.IndexTableFrag
														WHERE  DBName = @DBName
																--AND TableID = @currTableID	--*-- 1.3
																--AND IndexID = @currIndexID	--*-- 1.3
																AND TableName = @currTableName --*-- This would have needed schema anyway!
																AND IndexName = @currIndexName
																AND ExecutionDateTime = @ExecutionDateTime
														);

					IF @currLogIndexPhysicalStats = 1
						AND @StmtOnly <> 1 
						BEGIN
							INSERT	Minion.IndexPhysicalStats
									( ExecutionDateTime ,
										IndexScanMode ,
										DBName ,
										SchemaName ,
										TableName ,
										IndexName ,
										database_id ,
										object_id ,
										index_id ,
										partition_number ,
										index_type_desc ,
										alloc_unit_type_desc ,
										index_depth ,
										index_level ,
										avg_fragmentation_in_percent ,
										fragment_count ,
										avg_fragment_size_in_pages ,
										page_count ,
										avg_page_space_used_in_percent ,
										record_count ,
										ghost_record_count ,
										version_ghost_record_count ,
										min_record_size_in_bytes ,
										max_record_size_in_bytes ,
										avg_record_size_in_bytes ,
										forwarded_record_count --,
										--compressed_page_count
									)
									SELECT	ExecutionDateTime ,
											IndexScanMode ,
											DBName ,
											SchemaName ,
											TableName ,
											IndexName ,
											database_id ,
											object_id ,
											index_id ,
											partition_number ,
											index_type_desc ,
											alloc_unit_type_desc ,
											index_depth ,
											index_level ,
											avg_fragmentation_in_percent ,
											fragment_count ,
											avg_fragment_size_in_pages ,
											page_count ,
											avg_page_space_used_in_percent ,
											record_count ,
											ghost_record_count ,
											version_ghost_record_count ,
											min_record_size_in_bytes ,
											max_record_size_in_bytes ,
											avg_record_size_in_bytes ,
											forwarded_record_count --,
										--compressed_page_count
									FROM	#IndexPhysicalStats
						END

					--------------------------------------------------------------
					-------------END Log IndexPhysicalStats-----------------------
					--------------------------------------------------------------
	

					--------------------------------------------------------------
					-------------BEGIN DELETE Unwanted index levels---------------
					--------------------------------------------------------------

					--If it's a clustered index we're really only interested in the base level, which is 0.
					--So we delete the rest of the levels and we're only going to compare the frag level
					--against level 0.
					IF @currIndexScanMode = 'Detailed' 
						BEGIN
							DELETE	#IndexPhysicalStats
							WHERE	index_id = 1
									AND index_level > 0
						END

					--------------------------------------------------------------
					-------------END DELETE Unwanted index levels-----------------
					--------------------------------------------------------------
	

					--------------------------------------------------------------
					-------------BEGIN Add Frag % to Minion.IndexTableFrag--------
					--------------------------------------------------------------
	
					--We're only taking the max fragmented of all the index levels.
					--Different levels of the index will have different frag levels.  We have to measure against something, so we're using the max of all the levels for the index.
					--The #IndexPhysicalStats table holds all of the stats for the different levels of the index.  So we're updating the Minion.IndexTableFrag table to reflect that max frag level we want.
					--	NOTE: We're getting the MAX fragmentation, because though this is the data for a single index, we do have multiple rows 
					--	(with differing fragmentation) for each level of the index.
					UPDATE ITF
					SET ITF.avg_fragmentation_in_percent = IPS.avg_fragmentation_in_percent
					FROM Minion.IndexTableFrag ITF
						INNER JOIN (
								SELECT IPS.ExecutionDateTime,
									IPS.DBName,
									IPS.object_id,
									IPS.index_id,
									MAX(IPS.avg_fragmentation_in_percent) AS "avg_fragmentation_in_percent"
								FROM #IndexPhysicalStats IPS
								WHERE IPS.ExecutionDateTime = @ExecutionDateTime
								GROUP BY IPS.ExecutionDateTime,
									IPS.DBName,
									IPS.object_id,
									IPS.index_id
							) IPS ON ITF.DBName = IPS.DBName
								AND ITF.TableID = IPS.object_id
								AND ITF.IndexID = IPS.index_id
								AND ITF.ExecutionDateTime = IPS.ExecutionDateTime	
								AND ITF.ExecutionDateTime = @ExecutionDateTime;	--*-- 1.3

					--------------------------------------------------------------
					-------------END Add Frag % to Minion.IndexTableFrag----------
					--------------------------------------------------------------
	

					--Clear the table for the next index.
					TRUNCATE TABLE #IndexPhysicalStats

					----Set the ctrl var that's used to tell when we've switched tables in the cursor.
					SET @FragTableCtrl = @currTableName;

					FETCH NEXT FROM FragStats INTO @currTableID,
						@currSchemaName, @currTableName, @currIndexName,
						@currIndexID, @currONLINEopt

				END -- End Cursor Loop

			CLOSE FragStats
			DEALLOCATE FragStats

			
			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------END Frag Stats Cursor----------------------------
			--------------------------------------------------------------
			--------------------------------------------------------------
	
			IF @RunPrepped = 0
			BEGIN --@RunPrepped = 0

				SET @FragLogTotalCtr = ( SELECT	COUNT(*)
											FROM	#IndexName
										)
			END --@RunPrepped = 0

			DROP TABLE #IndexName;

			----------------------------------------------------------------
			----------------------------------------------------------------
			---------------BEGIN Log Status---------------------------------
			----------------------------------------------------------------
			----------------------------------------------------------------
	
			IF @StmtOnly = 0 
				BEGIN --@StmtOnly = 0

					IF @LogProgress = 1 
						BEGIN --@LogProgress = 1
				
							--If @PrepOnly = 0
								--Begin --@PrepOnly = 0
							IF @ErrMsg IS NULL
							BEGIN --@ErrMsg IS NULL

									UPDATE	Minion.IndexMaintLogDetails
									SET		Status = 'FRAG STATS COMPLETE. ' + CAST(@FragLogCtr AS VARCHAR(10))
											+ ' of '
											+ CAST(@FragLogTotalCtr AS VARCHAR(10))
											+ ' Frag Stats Gathered. ', 
											OpBeginDateTime	= @ExecutionDateTime, 
											OpEndDateTime= GETDATE(), 
											OpRunTimeInSecs = DATEDIFF(SECOND, @ExecutionDateTime, GETDATE())
									WHERE	ExecutionDateTime = @ExecutionDateTime
											AND DBName = @DBName;

									--*-- 1.3 Because we're keeping the Frag Stats row, we don't want to update it with this message.
									--UPDATE	Minion.IndexMaintLogDetails
									--SET		Status = 'Prepping Minion tables'
									--WHERE	ExecutionDateTime = @ExecutionDateTime
									--		AND DBName = @DBName;
							END --@ErrMsg IS NULL
								--End --@PrepOnly = 0
						END --@LogProgress = 1
				END --@StmtOnly = 0

			----------------------------------------------------------------
			----------------------------------------------------------------
			---------------END Log Status-----------------------------------
			----------------------------------------------------------------
			----------------------------------------------------------------
	

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------BEGIN Delete Indexes Below Threshold-------------
			--------------------------------------------------------------
			--------------------------------------------------------------
			--Logically speaking, the reorgThreshold should always be lower than the rebuildThreshold since you would never
			--do a reorg Op if you did a full rebuild before you even got to it.  So using the reorgThreshold as the metric
			--to delete tables from the process is appropriate.
	
			DELETE	Minion.IndexTableFrag
			WHERE	avg_fragmentation_in_percent < ReorgThreshold
					AND ExecutionDateTime = @ExecutionDateTime
					AND DBName = @DBName;

			--------------------------------------------------------------
			-------------BEGIN Remove Heaps under REBUILD threshold-------
			--------------------------------------------------------------
			
			--Heaps should never get a reorg; so, any heap under the rebuild threshold is out. --*-- 1.3
			/* Here's the thing...we're removing heaps as appropriate in the HEAPS section above, before getting frag stats. 
			   That deletes data from #IndexName...the list of indexes we're to work on.
	   
			   What that means though is that we don't actually have a frag stat to work on here, and we DO have the heap
			   row(s) in IndexTableFrag. That's why, for now, I'm pulling that ISNULL(afv frag %, -1) thing. If we don't have 
			   frag stats, then we definitely need to remove the info from IndexTableFrag.

			   Note: IndexTableFrag is used to populate the temp table right before "Reindex Stmt Cursor".
			*/
			DELETE	Minion.IndexTableFrag
			WHERE	ISNULL(avg_fragmentation_in_percent,-1) < RebuildThreshold
					AND IndexType = 0
					AND ExecutionDateTime = @ExecutionDateTime
					AND DBName = @DBName;

			--------------------------------------------------------------
			-------------END Remove Heaps under REBUILD threshold---------
			--------------------------------------------------------------
	
			----If it's rebuild mode, then we need to delete everything below the rebuildthreshold.
			IF @ReorgMode = 'Rebuild'
				BEGIN
						DELETE	Minion.IndexTableFrag
						WHERE	avg_fragmentation_in_percent < RebuildThreshold
								AND ExecutionDateTime = @ExecutionDateTime
								AND DBName = @DBName;		
				END

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------END Delete Indexes Below Threshold---------------
			--------------------------------------------------------------
			--------------------------------------------------------------


			--------------------------------------------------------------
			--------------------------------------------------------------
			--------------BEGIN Delete Nonclustered Indexes on heaps------	--*-- 1.3
			--------------------------------------------------------------
			--------------------------------------------------------------
			-- For any heap that we're going to rebuild, remove the nonclustered indexes.
			DELETE	ITF
			FROM Minion.IndexTableFrag AS ITF
			INNER JOIN Minion.IndexTableFrag AS ITF0 ON ITF.DBName  = ITF0.DBName
				AND ITF.TableID = ITF0.TableID
				AND ITF.ExecutionDateTime = ITF0.ExecutionDateTime
			WHERE	ITF0.IndexType = 0
					AND ITF0.avg_fragmentation_in_percent >= ITF0.RebuildThreshold
					AND ITF.IndexType > 0
					AND ITF.ExecutionDateTime = @ExecutionDateTime
					AND ITF.DBName = @DBName;
	
			--------------------------------------------------------------
			--------------------------------------------------------------
			--------------END Delete Nonclustered Indexes on heaps--------
			--------------------------------------------------------------
			--------------------------------------------------------------


			--------------------------------------------------------------
			--------------------------------------------------------------
			--------------BEGIN Set Default Index Order-------------------
			--------------------------------------------------------------
			--------------------------------------------------------------

			UPDATE	Minion.IndexTableFrag
			SET		ReindexGroupOrder = 0
			WHERE	ReindexGroupOrder IS NULL
					AND ExecutionDateTime = @ExecutionDateTime
					AND DBName = @DBName


			UPDATE	Minion.IndexTableFrag
			SET		ReindexOrder = 0
			WHERE	ReindexOrder IS NULL
					AND ExecutionDateTime = @ExecutionDateTime
					AND DBName = @DBName

			--------------------------------------------------------------
			--------------------------------------------------------------
			--------------END Set Default Index Order---------------------
			--------------------------------------------------------------
			--------------------------------------------------------------


		END-- @RunPrepped = 0 OR @PrepOnly = 1

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Get Index Fragmentation--------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN Prep Save--------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


	IF @PrepOnly = 0 AND @RunPrepped = 0
		BEGIN

	------------Set Prepped flag------------
	----This flag is used to keep from confusing prepped loads with unprepped loads.
			UPDATE	Minion.IndexTableFrag
			SET		Prepped = 0
			WHERE	ExecutionDateTime = @ExecutionDateTime
					AND DBName = @DBName;

		END


	IF @PrepOnly = 1 
		BEGIN

	--Since this option only preps the index frag stats, that's all we're
	--interested in.  So no further processing is needed.  
	--We can end the SP here.


	------------Set Prepped flag------------
	----This flag is used to keep from confusing prepped loads with unprepped loads.
			UPDATE	Minion.IndexTableFrag
			SET		Prepped = 1
			WHERE	ExecutionDateTime = @ExecutionDateTime
					AND DBName = @DBName;


			UPDATE	Minion.IndexMaintLog
			SET		Status = 'Complete',
					ExecutionFinishTime = GETDATE(),
					ExecutionRunTimeInSecs = DATEDIFF(s,
														CONVERT(VARCHAR(25), @ExecutionDateTime, 21),
														CONVERT(VARCHAR(25), GETDATE(), 21)) 
			WHERE	ExecutionDateTime = @ExecutionDateTime
					AND DBName = @DBName;

			--UPDATE	Minion.IndexMaintLogDetails
			--SET		Status = 'Complete. ' + CAST(@FragLogCtr AS VARCHAR(10))
			--		+ ' of '
			--		+ CAST(@FragLogTotalCtr AS VARCHAR(10))
			--		+ ' Frag Stats Gathered. '
			--WHERE	ExecutionDateTime = @ExecutionDateTime
			--		AND DBName = @DBName;

			RETURN;

		END

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Prep Save----------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN Finalize Index Options-------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
	--Use a @Table for this because it's filled from dynamic sql and this is the easiest
	--way to get the data into a var.      
	DECLARE	@PostFragVar TABLE ( col1 INT );

	--*-- 1.3 Just a note: Nothing changed here from 1.2; something got moved at some point.

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Finalize Index Options---------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------Begin Initial Log Entry------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

----Put all the indexes to be done along with the table info into the log table.
----This is how you're going to tell how long you have to go before the job is finished.
----If you can see all the indexes it's expecting to do then you can make a good decision
----on whether to stop it if you need to.  But this step is essential to that goal because
----before you even start to reindex/reorg you need to have that complete list.

	IF @StmtOnly = 0 
		BEGIN --@StmtOnly = 0

			IF @PrepOnly = 0
				BEGIN --@PrepOnly = 0

				IF @RunPrepped = 1
					BEGIN	--@RunPrepped = 1

					--*-- 1.3 This is the frag stats row. We want to keep it, unless we're @RunPrepped = 1:
					DELETE	Minion.IndexMaintLogDetails
					WHERE	ExecutionDateTime = @ExecutionDateTime
							AND DBName = @DBName;
					END;	 --@RunPrepped = 1

				IF @RunPrepped = 0
					BEGIN --@RunPrepped = 0

					INSERT	Minion.IndexMaintLogDetails
							( ExecutionDateTime ,
							  Status ,
							  DBName ,
							  TableID ,
							  SchemaName ,
							  TableName ,
							  IndexID ,
							  IndexName ,
							  IndexTypeDesc ,
							  IndexScanMode ,
							  ONLINEopt ,
							  ReorgThreshold ,
							  RebuildThreshold ,
							  FILLFACTORopt ,
							  PadIndex ,
							  ReindexGroupOrder ,
							  ReindexOrder
							)
							SELECT	@ExecutionDateTime ,
									'In Queue' ,
									@DBName ,
									TableID ,
									SchemaName ,
									TableName ,
									IndexID ,
									IndexName ,
									IndexTypeDesc ,
									IndexScanMode ,
									ONLINEopt ,
									ReorgThreshold ,
									RebuildThreshold ,
									FILLFACTORopt ,
									PadIndex ,
									ReindexGroupOrder ,
									ReindexOrder
							FROM	Minion.IndexTableFrag
							WHERE	ExecutionDateTime = @ExecutionDateTime
									AND DBName = @DBName
							ORDER BY ReindexGroupOrder DESC ,
									ReindexOrder DESC

					END --@RunPrepped = 0


				IF @RunPrepped = 1
					BEGIN --@RunPrepped = 1

					INSERT	Minion.IndexMaintLogDetails
							( ExecutionDateTime ,
							  Status ,
							  DBName ,
							  TableID ,
							  SchemaName ,
							  TableName ,
							  IndexID ,
							  IndexName ,
							  IndexTypeDesc ,
							  IndexScanMode ,
							  ONLINEopt ,
							  ReorgThreshold ,
							  RebuildThreshold ,
							  FILLFACTORopt ,
							  PadIndex ,
							  ReindexGroupOrder ,
							  ReindexOrder
							)
							SELECT	@ExecutionDateTime ,
									'In Queue' ,
									@DBName ,
									TableID ,
									SchemaName ,
									TableName ,
									IndexID ,
									IndexName ,
									IndexTypeDesc ,
									IndexScanMode ,
									ONLINEopt ,
									ReorgThreshold ,
									RebuildThreshold ,
									FILLFACTORopt ,
									PadIndex ,
									ReindexGroupOrder ,
									ReindexOrder
							FROM	Minion.IndexTableFrag
							WHERE	DBName = @DBName
									AND ExecutionDateTime IN (SELECT MAX(ExecutionDateTime) FROM Minion.IndexTableFrag WHERE DBName = @DBName AND Prepped = 1)
									AND Prepped = 1
							ORDER BY ReindexGroupOrder DESC ,
									ReindexOrder DESC

					END --@RunPrepped = 1


				END --@PrepOnly = 0
		END --@StmtOnly = 0

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Initial Log Entry--------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN Get Row Count---------------------------------------------------------- 
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
 
--!!!-- Need to inner join to make sure we only get rowcounts for those that WANT rowcounts!!
--!!!-- For now, going the easy route: update everything and let dog sort it out.  -J.M. 9/23/2014


	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------BEGIN Log Status---------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	
 	IF @PrepOnly = 0
		BEGIN --@PrepOnly = 0 

		IF @LogProgress = 1 
			BEGIN --@LogProgress = 1

			IF @ErrMsg IS NULL
				BEGIN --@ErrMsg IS NULL
					UPDATE	Minion.IndexMaintLogDetails
					SET		Status = 'Getting table row count'
					WHERE	ExecutionDateTime = @ExecutionDateTime
						AND [Status] NOT LIKE '%FRAG STATS%';
											----AND DBName = @DBName
											----AND SchemaName = @currSchemaName
											----AND TableName = @currTableName
											----AND IndexName = @currIndexName
				END --@ErrMsg IS NULL
			END --@LogProgress = 1
		END --@PrepOnly = 0

	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------END Log Status-----------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	
	IF @StmtOnly = 0 
		BEGIN
			SET @RowCTBeginDateTime = GETDATE();

		-- Run a dynamic sql statement once for every DB in the current @ExecutionDateTime:
			CREATE TABLE #RowCount
				(
				  DBName NVARCHAR(400) COLLATE DATABASE_DEFAULT NULL ,
				  TableID BIGINT NULL ,
				  IndexID BIGINT NULL ,
				  TableRowCT BIGINT NULL
				);


			DECLARE RowCT CURSOR READ_ONLY
			FOR
				SELECT  DISTINCT
						DBName
				FROM	Minion.IndexMaintLogDetails IML
				WHERE	ExecutionDateTime = @ExecutionDateTime
					AND [Status] NOT LIKE '%FRAG STATS%';

			OPEN RowCT

			FETCH NEXT FROM RowCT INTO @DBName
	
			WHILE ( @@fetch_Status <> -1 ) 
				BEGIN -- Begin Cursor Loop

					SET @RowCTSQL = 'SELECT	''' + @DBName + ''' AS DBName ,
			IML.TableID,
			IML.IndexID,
			SUM(PS.row_count) AS TableRowCT
	FROM	Minion.IndexMaintLogDetails IML
			INNER JOIN [' + @DBName
						+ '].sys.dm_db_partition_stats AS PS ON IML.TableID = PS.OBJECT_ID
															AND IML.IndexID = PS.index_id
			INNER JOIN [' + @DBName
						+ '].sys.objects o ON IML.TableID = o.OBJECT_ID
			INNER JOIN [' + @DBName
						+ '].sys.schemas s ON o.schema_id = s.schema_id
	WHERE IML.ExecutionDateTime = '''
						+ CONVERT(VARCHAR(50), @ExecutionDateTime, 109) + '''
		AND IML.DBName = ''' + @DBName + '''
	AND IML.[Status] NOT LIKE ''%FRAG STATS%''
	GROUP BY IML.TableID ,
			IML.IndexID';
			


					INSERT	INTO #RowCount
							( DBName ,
							  TableID ,
							  IndexID ,
							  TableRowCT
							)
							EXEC ( @RowCTSQL
								);

					FETCH NEXT FROM RowCT INTO @DBName
				END

			CLOSE RowCT;
			DEALLOCATE RowCT;


	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------BEGIN Row CT Log---------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
						
			SET @RowCTEndDateTime = GETDATE();

			--------------------------------------------------------------
			-------------BEGIN RUN----------------------------------------
			--------------------------------------------------------------		
						
			WITH	rowCountCTE
					  AS ( SELECT	SUM(TableRowCT) AS TableRowCT ,
									DBName ,
									TableID ,
									IndexID
						   FROM		#RowCount
						   GROUP BY	DBName ,
									TableID ,
									IndexID
						 )
				UPDATE	IML
				SET		TableRowCTBeginDateTime = CONVERT(VARCHAR(25), @RowCTBeginDateTime, 21) ,
						TableRowCTEndDateTime = CONVERT(VARCHAR(25), @RowCTEndDateTime, 21) ,
						TableRowCTTimeInSecs = DATEDIFF(s,
														CONVERT(VARCHAR(25), @RowCTBeginDateTime, 21),
														CONVERT(VARCHAR(25), @RowCTEndDateTime, 21)) ,
						IML.TableRowCT = RC.TableRowCT
				FROM	Minion.IndexMaintLogDetails IML
						INNER JOIN rowCountCTE AS RC ON IML.DBName = RC.DBName
														AND IML.TableID = RC.TableID
														AND IML.IndexID = RC.IndexID
				WHERE	IML.ExecutionDateTime = @ExecutionDateTime
				AND [Status] NOT LIKE '%FRAG STATS%';

			DROP TABLE #RowCount;


		END --IF @StmtOnly = 0 
		--------------------------------------------------------------
		-------------END RUN------------------------------------------
		--------------------------------------------------------------
	
	
	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------END Row CT Log-----------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Get Row Count------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN Log Status-------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


	IF @StmtOnly = 0 
		BEGIN --@StmtOnly = 0

			UPDATE	Minion.IndexMaintLogDetails
			SET		Status = 'In Queue'
			WHERE	ExecutionDateTime = @ExecutionDateTime
					AND DBName = @DBName
					AND [Status] NOT LIKE '%FRAG STATS%';

			UPDATE	Minion.IndexMaintLog
			SET		Status = 'Processing Tables'
			WHERE	ExecutionDateTime = @ExecutionDateTime
					AND DBName = @DBName;

		END --@StmtOnly = 0

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Log Status---------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN Insert #TableFrag------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

--Since we allow to run prepped, we have to have a common table here for the cursor.
--So we put into a #table and run the cursor off of that.

	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------BEGIN Create #IndexTableFrag---------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	

	CREATE TABLE #TableFrag
		(
		  ExecutionDateTime DATETIME NULL ,
		  DBName NVARCHAR(400) COLLATE DATABASE_DEFAULT NULL,
		  DBID INT NULL ,
		  TableID BIGINT NULL ,
		  SchemaName NVARCHAR(400) COLLATE DATABASE_DEFAULT NULL ,
		  TableName NVARCHAR(400) COLLATE DATABASE_DEFAULT NULL ,
		  IndexName NVARCHAR(400) COLLATE DATABASE_DEFAULT NULL ,
		  IndexID BIGINT NULL ,
		  IndexType TINYINT NULL ,
		  IndexTypeDesc NVARCHAR(120) COLLATE DATABASE_DEFAULT NULL ,
		  IsDisabled BIT NULL ,
		  IsHypothetical BIT NULL ,
		  avg_fragmentation_in_percent FLOAT NULL ,
		  ReorgThreshold TINYINT NULL ,
		  RebuildThreshold TINYINT NULL ,
		  FILLFACTORopt TINYINT NULL ,
		  PadIndex VARCHAR(3) COLLATE DATABASE_DEFAULT NULL ,
		  ONLINEopt VARCHAR(3) COLLATE DATABASE_DEFAULT NULL ,
		  SortInTempDB VARCHAR(3) COLLATE DATABASE_DEFAULT NULL ,
		  MAXDOPopt TINYINT NULL ,
		  DataCompression VARCHAR(50) COLLATE DATABASE_DEFAULT NULL ,
		  GetRowCT BIT NULL ,
		  GetPostFragLevel BIT NULL ,
		  UpdateStatsOnDefrag BIT NULL ,
		  StatScanOption VARCHAR(25) COLLATE DATABASE_DEFAULT NULL ,
		  IgnoreDupKey VARCHAR(3) COLLATE DATABASE_DEFAULT NULL ,
		  StatsNoRecompute VARCHAR(3) COLLATE DATABASE_DEFAULT NULL ,
		  AllowRowLocks VARCHAR(3) COLLATE DATABASE_DEFAULT NULL ,
		  AllowPageLocks VARCHAR(3) COLLATE DATABASE_DEFAULT NULL ,
		  WaitAtLowPriority BIT NULL ,
		  MaxDurationInMins INT NULL ,
		  AbortAfterWait VARCHAR(20) COLLATE DATABASE_DEFAULT NULL ,
		  LogProgress BIT NULL ,
		  LogRetDays SMALLINT NULL ,
		  PushToMinion BIT NULL ,
		  LogIndexPhysicalStats BIT NULL ,
		  IndexScanMode VARCHAR(25) COLLATE DATABASE_DEFAULT NULL ,
		  TablePreCode NVARCHAR(MAX) COLLATE DATABASE_DEFAULT NULL ,
		  TablePostCode NVARCHAR(MAX) COLLATE DATABASE_DEFAULT NULL ,
		  Prepped BIT NULL ,
		  ReindexGroupOrder INT NULL ,
		  ReindexOrder INT NULL,
		  StmtPrefix NVARCHAR(1000) COLLATE DATABASE_DEFAULT NULL,
		  StmtSuffix NVARCHAR(1000) COLLATE DATABASE_DEFAULT NULL,
		  RebuildHeap BIT NULL
		); --*-- 1.3 added back; added RebuildHeap.

	--------------------------------------------------------------
	--------------------------------------------------------------
	-------------END Create #IndexTableFrag-----------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	

	IF @RunPrepped = 0
	BEGIN
		--*-- Added column list, 2 statements:
		INSERT #TableFrag (ExecutionDateTime, DBName, DBID, TableID, SchemaName, TableName, IndexName, IndexID, 
			IndexType, IndexTypeDesc, IsDisabled, IsHypothetical, avg_fragmentation_in_percent, ReorgThreshold, 
			RebuildThreshold, FILLFACTORopt, PadIndex, ONLINEopt, SortInTempDB, MAXDOPopt, DataCompression, 
			GetRowCT, GetPostFragLevel, UpdateStatsOnDefrag, StatScanOption, IgnoreDupKey, StatsNoRecompute, 
			AllowRowLocks, AllowPageLocks, WaitAtLowPriority, MaxDurationInMins, AbortAfterWait, LogProgress, 
			LogRetDays, PushToMinion, LogIndexPhysicalStats, IndexScanMode, TablePreCode, TablePostCode, Prepped, 
			ReindexGroupOrder, ReindexOrder, StmtPrefix, StmtSuffix, RebuildHeap )
		SELECT			
			  ExecutionDateTime,
			  DBName,
			  DBID,
			  TableID,
			  SchemaName,
			  TableName,
			  IndexName,
			  IndexID,
			  IndexType,
			  IndexTypeDesc,
			  IsDisabled,
			  IsHypothetical,
			  avg_fragmentation_in_percent,
			  ReorgThreshold,
			  RebuildThreshold,
			  FILLFACTORopt,
			  PadIndex,
			  ONLINEopt,
			  SortInTempDB,
			  MAXDOPopt,
			  DataCompression,
			  GetRowCT,
			  GetPostFragLevel,
			  UpdateStatsOnDefrag,
			  StatScanOption,
			  IgnoreDupKey,
			  StatsNoRecompute,
			  AllowRowLocks,
			  AllowPageLocks,
			  WaitAtLowPriority,
			  MaxDurationInMins,
			  AbortAfterWait,
			  LogProgress,
			  LogRetDays,
			  PushToMinion,
			  LogIndexPhysicalStats,
			  IndexScanMode,
			  TablePreCode,
			  TablePostCode,
			  Prepped,
			  ReindexGroupOrder,
			  ReindexOrder,
			  StmtPrefix,
			  StmtSuffix,
			  RebuildHeap
			FROM	Minion.IndexTableFrag
			WHERE	DBName = @DBName
					AND ExecutionDateTime = @ExecutionDateTime
			ORDER BY ReindexGroupOrder DESC ,
					ReindexOrder DESC;
	END

	IF @RunPrepped = 1
		BEGIN

		INSERT #TableFrag (ExecutionDateTime, DBName, DBID, TableID, SchemaName, TableName, IndexName, IndexID, 
			IndexType, IndexTypeDesc, IsDisabled, IsHypothetical, avg_fragmentation_in_percent, ReorgThreshold, 
			RebuildThreshold, FILLFACTORopt, PadIndex, ONLINEopt, SortInTempDB, MAXDOPopt, DataCompression, 
			GetRowCT, GetPostFragLevel, UpdateStatsOnDefrag, StatScanOption, IgnoreDupKey, StatsNoRecompute, 
			AllowRowLocks, AllowPageLocks, WaitAtLowPriority, MaxDurationInMins, AbortAfterWait, LogProgress, 
			LogRetDays, PushToMinion, LogIndexPhysicalStats, IndexScanMode, TablePreCode, TablePostCode, Prepped, 
			ReindexGroupOrder, ReindexOrder, StmtPrefix, StmtSuffix, RebuildHeap )
		SELECT			
			  ExecutionDateTime,
			  DBName,
			  DBID,
			  TableID,
			  SchemaName,
			  TableName,
			  IndexName,
			  IndexID,
			  IndexType,
			  IndexTypeDesc,
			  IsDisabled,
			  IsHypothetical,
			  avg_fragmentation_in_percent,
			  ReorgThreshold,
			  RebuildThreshold,
			  FILLFACTORopt,
			  PadIndex,
			  ONLINEopt,
			  SortInTempDB,
			  MAXDOPopt,
			  DataCompression,
			  GetRowCT,
			  GetPostFragLevel,
			  UpdateStatsOnDefrag,
			  StatScanOption,
			  IgnoreDupKey,
			  StatsNoRecompute,
			  AllowRowLocks,
			  AllowPageLocks,
			  WaitAtLowPriority,
			  MaxDurationInMins,
			  AbortAfterWait,
			  LogProgress,
			  LogRetDays,
			  PushToMinion,
			  LogIndexPhysicalStats,
			  IndexScanMode,
			  TablePreCode,
			  TablePostCode,
			  Prepped,
			  ReindexGroupOrder,
			  ReindexOrder,
			  StmtPrefix,
			  StmtSuffix,
			  RebuildHeap 
				FROM	Minion.IndexTableFrag
				WHERE	DBName = @DBName
						AND ExecutionDateTime IN (SELECT MAX(ExecutionDateTime) FROM Minion.IndexTableFrag WHERE DBName = @DBName AND Prepped = 1)
						AND Prepped = 1
				ORDER BY ReindexGroupOrder DESC ,
						ReindexOrder DESC;

	END

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Insert #TableFrag--------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------Begin Reindex Stmt Cursor----------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

	DECLARE Tables CURSOR READ_ONLY
	FOR
		SELECT	TableID ,
				SchemaName ,
				TableName ,
				IndexName ,
				IndexID ,
				IndexType ,
				IndexTypeDesc ,
				avg_fragmentation_in_percent ,
				ReorgThreshold ,
				RebuildThreshold ,
				FILLFACTORopt ,
				PadIndex ,
				ONLINEopt ,
				SortInTempDB ,
				MAXDOPopt ,
				DataCompression ,
				GetRowCT ,
				GetPostFragLevel ,
				UpdateStatsOnDefrag ,
				StatScanOption ,
				IgnoreDupKey ,
				StatsNoRecompute ,
				AllowRowLocks ,
				AllowPageLocks ,
				WaitAtLowPriority ,
				MaxDurationInMins ,
				AbortAfterWait ,
				LogProgress ,
				LogRetDays ,
				PushToMinion ,
				LogIndexPhysicalStats ,
				IndexScanMode ,
				TablePreCode ,
				TablePostCode ,
				StmtPrefix,
				StmtSuffix,
				RebuildHeap
		FROM	#TableFrag
		ORDER BY ReindexGroupOrder DESC ,
				ReindexOrder DESC

	OPEN Tables

	FETCH NEXT FROM Tables INTO @currTableID, @currSchemaName, @currTableName,
		@currIndexName, @currIndexID, @currIndexType, @currIndexTypeDesc,
		@currFragLevel, @currReorgThreshold, @currRebuildThreshold,
		@currFILLFACTORopt, @currPadIndex, @currONLINEopt, @currSortInTempDB,
		@currMAXDOPopt, @currDataCompression, @currGetRowCT,
		@currGetPostFragLevel, @currUpdateStatsOnDefrag, @currStatScanOption,
		@currIgnoreDupKey, @currStatsNoRecompute, @currAllowRowLocks,
		@currAllowPageLocks, @currWaitAtLowPriority, @currMaxDurationInMins,
		@currAbortAfterWait, @currLogProgress, @currLogRetDays,
		@currPushToMinion, @currLogIndexPhysicalStats, @currIndexScanMode,
		@currTablePreCode, @currTablePostCode, @currStmtPrefix, @currStmtSuffix, @currRebuildHeap

	WHILE ( @@fetch_Status <> -1 ) 
		BEGIN -- Begin Cursor Loop
			SET @ErrMsg = NULL;
			SET @ReindexSQL = N'';

			IF @TableCtrl <> @currTableName
			BEGIN
				SET @currTableIterator = 1;
			END

			IF @TableCtrl = @currTableName
			BEGIN
				SET @currTableIterator = @currTableIterator + 1;
			END

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------BEGIN Call Log----------------------------------- Inside cursor
			--------------------------------------------------------------
			--------------------------------------------------------------
	
			--Log the call of the Op.  This is done just before the reindex/reorg is actually started.
			IF @StmtOnly = 0 
				BEGIN --@StmtOnly = 0 
  					IF @PrepOnly = 0
						BEGIN --@PrepOnly = 0 
						     
							UPDATE	Minion.IndexMaintLogDetails
							SET		FragLevel = CAST(@currFragLevel AS DECIMAL(3, 0)) ,
									IndexTypeDesc = @currIndexTypeDesc
							WHERE	ExecutionDateTime = CONVERT(VARCHAR(25), @ExecutionDateTime, 21)
									AND DBName = @DBName
									----AND TableID = @currTableID  --*-- 1.3
									----AND IndexID = @currIndexID;  --*-- 1.3
									AND SchemaName = @currSchemaName
									AND TableName = @currTableName
									AND IndexName = @currIndexName
									AND [Status] NOT LIKE '%FRAG STATS%'; --*-- 1.3

						END --@PrepOnly = 0 
				END --@StmtOnly = 0 

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------END Call Log------------------------------------- Inside cursor
			--------------------------------------------------------------
			--------------------------------------------------------------
	
			IF @TableCtrl <> @currTableName
			BEGIN

				--SET @TableCT = (SELECT COUNT(*) FROM #TableFrag WHERE TableID = @currTableID);  --*-- 1.3 Was, TableName = @currTableName!
				SET @TableCT = (SELECT COUNT(*) FROM #TableFrag WHERE TableName = @currTableName);
		
			END

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------BEGIN Reindex Stmt Build------------------------- Inside cursor
			--------------------------------------------------------------
			--------------------------------------------------------------
	
			SET @ReindexSQL = N'';

			-- If you're in REORG mode you won't be able to do REBUILD at all, but the conditions for REORG change.
			-- If the REORG moce is 'REORG' then you're interested in indexes that are greater than @currReorgThreshold.
			-- So since it's REORG mode then even the ones that would ordinarily be rebuilt are reorged.
			-- Therefore you need 2 sets of criteria here.  The one for REORG mode uses the 1 set of criteria for the decision,
			-- while the 'All' mode uses both @currReorgThreshold and @currRebuildThreshold.

			IF @ReorgMode <> 'REBUILD' 
				BEGIN  --@ReorgMode <> 'REBUILD' 
 
					IF @ReorgMode = 'REORG' 
						BEGIN -- @ReorgMode = 'REORG'
							IF CAST(@currFragLevel AS DECIMAL(3, 0)) >= @currReorgThreshold 
								BEGIN -- REORG Mode
					 
									----Changed in v.1.3 to help with some edge cases where some names need to be in double-quotes instead of in [].
									SET @ReindexSQL = N'USE [' + @DBName
										+ N']; ' + ISNULL(@currStmtPrefix, '') + N'ALTER INDEX "' + @currIndexName
										+ N'" ON "' + @currSchemaName + N'"."'
										+ @currTableName + N'" REORGANIZE';

										--+ N']; ' + ISNULL(@currStmtPrefix, '') + N'ALTER INDEX [' + @currIndexName
										--+ N'] ON [' + @currSchemaName + N'].['
										--+ @currTableName + N'] REORGANIZE';
									SET @currOP = 'Reorg';
								END -- REORG Mode  
						END -- @ReorgMode = 'REORG'

					IF @ReorgMode = 'All' 
						BEGIN -- @ReorgMode = 'All'
							IF CAST(@currFragLevel AS DECIMAL(3, 0)) >= @currReorgThreshold
								AND CAST(@currFragLevel AS DECIMAL(3, 0)) < @currRebuildThreshold 
								BEGIN -- Reorg Mode
					 
									----Changed in v.1.3 to help with some edge cases where some names need to be in double-quotes instead of in [].
									SET @ReindexSQL = N'USE [' + @DBName
										+ N']; ' + ISNULL(@currStmtPrefix, '') + N'ALTER INDEX "' + @currIndexName
										+ N'" ON "' + @currSchemaName + N'"."'
										+ @currTableName + N'" REORGANIZE';

										--+ N']; ' + ISNULL(@currStmtPrefix, '') + N'ALTER INDEX [' + @currIndexName
										--+ N'] ON [' + @currSchemaName + N'].['
										--+ @currTableName + N'] REORGANIZE';
									SET @currOP = 'Reorg';
								END -- Reorg Mode
						END -- @ReorgMode = 'All'
				END  --@ReorgMode <> 'REBUILD'  


			IF @ReorgMode <> 'REORG' 
				BEGIN  --@ReorgMode <> 'REORG'   
					IF CAST(@currFragLevel AS DECIMAL(3, 0)) >= @currRebuildThreshold 
						BEGIN -- @currFragLevel AS DECIMAL(3, 0)) >= @currRebuildThreshold

							IF @currFILLFACTORopt IS NOT NULL 
								SET @currFILLFACTORopt = 'FILLFACTOR = '
									+ @currFILLFACTORopt;

							IF @currPadIndex IS NOT NULL 
								SET @currPadIndex = ', PAD_INDEX = '
									+ @currPadIndex;
                           

							IF @currSortInTempDB IS NOT NULL 
								SET @currSortInTempDB = ', SORT_IN_TEMPDB = '
									+ @currSortInTempDB;
                           

							IF @currMAXDOPopt IS NOT NULL 
								SET @currMAXDOPopt = ', MAXDOP = '
									+ @currMAXDOPopt;
                           

							IF @currDataCompression IS NOT NULL 
								SET @currDataCompression = ', DATA_COMPRESSION = '
									+ @currDataCompression;
                           

							IF @currIgnoreDupKey IS NOT NULL 
								SET @currIgnoreDupKey = ', IGNORE_DUP_KEY = '
									+ @currIgnoreDupKey;
                           

							IF @currStatsNoRecompute IS NOT NULL 
								SET @currStatsNoRecompute = ', STATISTICS_NORECOMPUTE = '
									+ @currStatsNoRecompute;
                           

							IF @currAllowRowLocks IS NOT NULL 
								SET @currAllowRowLocks = ', ALLOW_ROW_LOCKS = '
									+ @currAllowRowLocks;
                           

							IF @currAllowPageLocks IS NOT NULL 
								SET @currAllowPageLocks = ', ALLOW_PAGE_LOCKS = '
									+ @currAllowPageLocks;
 
					----Set wait priority for SQL Server 2014 and above.
					----If MaxDurationInMins is NULL then we set it to 0.
					----If AbortAfterWait is NULL then we set it to NONE.    
					----!!! WaitPriority always has to stay above ONLINEopt because we have to eval it as ON before it gets turned into the flag itself.                   
							IF @Version >= '12' 
								BEGIN

									IF @currWaitAtLowPriority = 1 AND @currONLINEopt = 'ON'
										BEGIN
											DECLARE @currWaitAtLowPriorityTxt varchar(150);
										SET @currWaitAtLowPriorityTxt = ' (WAIT_AT_LOW_PRIORITY (MAX_DURATION = '
											+ CAST(ISNULL(@currMaxDurationInMins,
															0) AS VARCHAR(10))
											+ ' MINUTES, ABORT_AFTER_WAIT = '
											+ ISNULL(@currAbortAfterWait,
														'NONE') + '))'

										END

								END

							IF @currONLINEopt IS NOT NULL 
								SET @currONLINEopt = ', ONLINE = '
									+ @currONLINEopt;
                           
	
							----Changed in v.1.3 to help with some edge cases where some names need to be in double-quotes instead of in [].
							SET @ReindexSQL = N'USE [' + @DBName
								+ ']; ' + ISNULL(@currStmtPrefix, '') 
								+ CASE WHEN @currIndexTypeDesc = 'HEAP' THEN 'ALTER TABLE "' + @currSchemaName + '"."' + @currTableName + '" '
									ELSE 'ALTER INDEX "' + @currIndexName
								+ '" ON "' + @currSchemaName + '"."'
								+ @currTableName + '" ' END + 'REBUILD WITH ('

								--+ CASE WHEN @currIndexTypeDesc = 'HEAP' THEN 'ALTER TABLE [' + @currSchemaName + '].[' + @currTableName + '] '
								--	ELSE 'ALTER INDEX [' + @currIndexName
								--+ '] ON [' + @currSchemaName + '].['
								--+ @currTableName + '] ' END + 'REBUILD WITH ('
								+ ISNULL(@currFILLFACTORopt, '')
								+ ISNULL(@currPadIndex, '')
								+ ISNULL(@currONLINEopt, '')
								+ ISNULL(@currWaitAtLowPriorityTxt, '')
								+ ISNULL(@currSortInTempDB, '')
								+ ISNULL(@currMAXDOPopt, '')
								+ ISNULL(@currDataCompression, '')
								+ ISNULL(@currIgnoreDupKey, '')
								+ ISNULL(@currStatsNoRecompute, '')
								+ ISNULL(@currAllowRowLocks, '')
								+ ISNULL(@currAllowPageLocks, '') + ')'

							SET @ReindexSQL = REPLACE(@ReindexSQL, 'WITH ()', '')
							SET @ReindexSQL = REPLACE(@ReindexSQL, 'WITH (, ', 'WITH (')
							SET @currOP = 'Rebuild'
						END -- @currFragLevel AS DECIMAL(3, 0)) >= @currRebuildThreshold

				END --@ReorgMode <> 'REORG' 


			IF @currIndexTypeDesc LIKE '%COLUMNSTORE%' 
				BEGIN

					----Changed in v.1.3 to help with some edge cases where some names need to be in double-quotes instead of in []. (Just added quotes here.)
					SET @ReindexSQL = N'';
					SET @ReindexSQL = 'USE [' + @DBName + ']; ' + ISNULL(@currStmtPrefix, '') + 'ALTER INDEX "'
						+ @currIndexName + '" ON "' + @currSchemaName + '"."'
						+ @currTableName + '" ' + 'REBUILD';

				END



			SET @ReindexSQL = @ReindexSQL + '; ' + ISNULL(@currStmtSuffix, '')

			-----------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------
			------------END Reindex Stmt Build------------------------------------------------- Inside cursor
			-----------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------   


			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------BEGIN Run or Print Reindex Stmt------------------ Inside cursor
			--------------------------------------------------------------
			--------------------------------------------------------------
	

			--------------------------------------------------------------
			-------------BEGIN PRINT--------------------------------------
			--------------------------------------------------------------
			SET @OpBeginDateTime = GETDATE();
		
			IF @StmtOnly = 1 
				BEGIN --@StmtOnly = 1
					PRINT '------------------------------------------------------------------------------'
					PRINT '-------' + 'DB: ' + @DBName
					PRINT '-------' + 'Table: ' + @currSchemaName + '.'
						+ @currTableName
					PRINT '-------' + 'Index: ' + @currIndexName
					PRINT '-------' + 'Reorg Threshold: '
						+ @currReorgThreshold + '   Rebuild Threshold: '
						+ @currRebuildThreshold
					PRINT '-------' + 'Current Frag: ' + @currFragLevel
					PRINT @ReindexSQL;		
				END --@StmtOnly = 1
			--------------------------------------------------------------
			-------------END PRINT----------------------------------------
			--------------------------------------------------------------
	

			
			--------------------------------------------------------------
			-------------BEGIN Table PreCode------------------------------
			--------------------------------------------------------------
			
			IF @StmtOnly = 0 
				BEGIN -- @StmtOnly = 0

					IF @TableCtrl <> @currTableName 
						BEGIN --TableCtrl

							IF @currTablePreCode IS NOT NULL 
								BEGIN --@currTablePreCode IS NOT NULL

									SET @TablePreCodeBeginDateTime = GETDATE();
									---------------------BEGIN Log Status---------------------

									IF @StmtOnly = 0 
										BEGIN --@StmtOnly = 0

  									IF @PrepOnly = 0
										BEGIN --@PrepOnly = 0 

											IF @LogProgress = 1 
												BEGIN --@LogProgress = 1
													IF @currTablePreCode IS NOT NULL 
														BEGIN --@currTablePreCode IS NOT NULL

															UPDATE	Minion.IndexMaintLogDetails
															SET		Status = 'Running Table PreCode' ,
																	PreCode = @currTablePreCode ,
																	PreCodeBeginDateTime = @TablePreCodeBeginDateTime
															WHERE	ExecutionDateTime = @ExecutionDateTime
																	AND DBName = @DBName
																	--AND TableID = @currTableID  --*-- 1.3
																	--AND IndexID = @currIndexID;  --*-- 1.3
																	AND SchemaName = @currSchemaName
																	AND TableName = @currTableName
																	AND IndexName = @currIndexName
																	AND [Status] NOT LIKE '%FRAG STATS%'; --*-- 1.3

														END  --@currTablePreCode IS NOT NULL
												END --@LogProgress = 1
											END --@PrepOnly = 0
										END --@StmtOnly = 0

									---------------------END Log Status---------------------


									---------------------BEGIN Run Table PreCode---------------------
									EXEC (@currTablePreCode)

									---------------------END Run Table PreCode---------------------

									SET @TablePreCodeEndDateTime = GETDATE();

								END --@currTablePreCode IS NOT NULL

						END --TableCtrl
				END -- @StmtOnly = 0


			--------------------------------------------------------------
			-------------END Table PreCode--------------------------------
			--------------------------------------------------------------
			

			--------------------------------------------------------------
			-------------BEGIN Log Status---------------------------------
			--------------------------------------------------------------
			
			IF @StmtOnly = 0 
				BEGIN --@StmtOnly = 0

  					IF @PrepOnly = 0
						BEGIN --@PrepOnly = 0 

							IF @LogProgress = 1 
								BEGIN --@LogProgress = 1

									UPDATE	Minion.IndexMaintLogDetails
									SET		[Status] = 'Processing index' ,
											Stmt = @ReindexSQL ,
											OpBeginDateTime = @OpBeginDateTime
									WHERE	ExecutionDateTime = @ExecutionDateTime
											AND DBName = @DBName
											--AND TableID = @currTableID  --*-- 1.3
											--AND IndexID = @currIndexID;  --*-- 1.3
											AND SchemaName = @currSchemaName
											AND TableName = @currTableName
											AND IndexName = @currIndexName
											AND [Status] NOT LIKE '%FRAG STATS%'; --*-- 1.3

								END --@LogProgress = 1

						END --@PrepOnly = 0
				END --@StmtOnly = 0

			--------------------------------------------------------------
			-------------END Log Status-----------------------------------
			--------------------------------------------------------------
				
					 
			--------------------------------------------------------------
			-------------BEGIN RUN----------------------------------------
			--------------------------------------------------------------
			
			DECLARE @PreCMD NVARCHAR(2000),
					@TotalCMD NVARCHAR(2000);  
       
			IF @StmtOnly = 0 
				BEGIN --@StmtOnly = 0
					--*-- 1.3: We switched from using brackets, to using quotes, around object names. That messes up SQLCMD; so we 
					--*-- replace " with "".
					SET @ReindexSQL = REPLACE(@ReindexSQL, '"', '""');

                    SET @PreCMD = 'sqlcmd -I -r 1 -S"' + @ServerInstance + CAST(@Port AS VARCHAR(6))
                    SET @TotalCMD = @PreCMD + '" -q "' + @ReindexSQL + '"' 

						--PRINT @TotalCMD

--WAITFOR DELAY '00:00:10'
					SET @ErrMsg = NULL;
                    INSERT #ReindexResults
                            (col1)
                            EXEC xp_cmdshell @TotalCMD;

					--*-- 1.3: For logging, switch back to " instead of "". This makes a usable query.
					SET @ReindexSQL = REPLACE(@ReindexSQL, '""', '"');


                    DELETE FROM
                            #ReindexResults
                    WHERE
                        col1 IS NULL
						OR col1 LIKE '%Changed database context%'
						OR col1 LIKE 'Warning:%';		


					---------------------BEGIN Error Var---------------------
                    SELECT @ErrMsg = STUFF((SELECT ' ' + col1 FROM #ReindexResults AS T1 ORDER BY T1.ID
                                        FOR XML PATH('')), 1, 1, '')
                    FROM
                        #ReindexResults AS T2;

					TRUNCATE TABLE #ReindexResults;
					---------------------END Error Var---------------------



					---------------------BEGIN Log Error---------------------
					IF @ErrMsg IS NOT NULL
						BEGIN

							UPDATE	Minion.IndexMaintLogDetails
							SET		[Status] = 'FATAL ERROR: ' + @ErrMsg ,
									PostCode = @currTablePostCode ,
									PostCodeBeginDateTime = @TablePostCodeBeginDateTime
							WHERE	ExecutionDateTime = @ExecutionDateTime
									AND DBName = @DBName
									--AND TableID = @currTableID  --*-- 1.3
									--AND IndexID = @currIndexID;  --*-- 1.3
									AND SchemaName = @currSchemaName
									AND TableName = @currTableName
									AND IndexName = @currIndexName
									AND [Status] NOT LIKE '%FRAG STATS%'; --*-- 1.3
						END

					---------------------END Log Error---------------------

				END --@StmtOnly = 0        

			SET @OpEndDateTime = GETDATE();        
			--------------------------------------------------------------
			-------------END RUN------------------------------------------
			--------------------------------------------------------------
			
			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------END Run or Print Reindex Stmt-------------------- Inside cursor
			--------------------------------------------------------------
			--------------------------------------------------------------


			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------BEGIN Log Reindex Op----------------------------- Inside cursor
			--------------------------------------------------------------
			--------------------------------------------------------------
			
			IF @StmtOnly = 0 
				BEGIN --@StmtOnly = 0 

    				IF @PrepOnly = 0
					BEGIN --@PrepOnly = 0   
					    
							UPDATE	Minion.IndexMaintLogDetails
							SET		OpBeginDateTime = CONVERT(VARCHAR(25), @OpBeginDateTime, 21) ,
									OpEndDateTime = CONVERT(VARCHAR(25), @OpEndDateTime, 21) ,
									Op = @currOP ,
									Stmt = @ReindexSQL ,
									OpRunTimeInSecs = DATEDIFF(s,
															   CONVERT(VARCHAR(25), @OpBeginDateTime, 21),
															   CONVERT(VARCHAR(25), @OpEndDateTime, 21)) ,
									PreCode = @currTablePreCode ,
									PreCodeBeginDateTime = @TablePreCodeBeginDateTime ,
									PreCodeEndDateTime = @TablePreCodeEndDateTime ,
									PreCodeRunTimeInSecs = DATEDIFF(s,
																	CONVERT(VARCHAR(25), @TablePreCodeBeginDateTime, 21),
																	CONVERT(VARCHAR(25), @TablePreCodeEndDateTime, 21)) ,
									PostCode = @currTablePostCode ,
									PostCodeBeginDateTime = @TablePostCodeBeginDateTime ,
									PostCodeEndDateTime = @TablePostCodeEndDateTime ,
									PostCodeRunTimeInSecs = DATEDIFF(s,
																	 CONVERT(VARCHAR(25), @TablePostCodeBeginDateTime, 21),
																	 CONVERT(VARCHAR(25), @TablePostCodeEndDateTime, 21))
							WHERE	ExecutionDateTime = CONVERT(VARCHAR(25), @ExecutionDateTime, 21)
									AND DBName = @DBName
									--AND TableID = @currTableID  --*-- 1.3
									--AND IndexID = @currIndexID;  --*-- 1.3
									AND SchemaName = @currSchemaName
									AND TableName = @currTableName
									AND IndexName = @currIndexName
									AND [Status] NOT LIKE '%FRAG STATS%'; --*-- 1.3

					END --@PrepOnly = 0

				END --@StmtOnly = 0 

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------END Log Reindex Op------------------------------- Inside cursor
			--------------------------------------------------------------
			--------------------------------------------------------------
			

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------BEGIN Run Stats Update--------------------------- Inside cursor
			--------------------------------------------------------------
			--------------------------------------------------------------
			
			--Run Stats if the table has it flagged to do so, but only on defrags.
			IF @StmtOnly = 0
				BEGIN --@StmtOnly = 0
					
					IF @ErrMsg IS NULL
						BEGIN --@ErrMsg IS NULL

						--------------------------------------------------------------
						-------------BEGIN LOG PREP-----------------------------------
						--------------------------------------------------------------

						IF @currOP = 'Reorg'
							AND @currUpdateStatsOnDefrag = 1
							AND UPPER(@currIndexTypeDesc) <> 'XML' AND UPPER(@currIndexTypeDesc) <> 'SPATIAL' 
							BEGIN --Stats Update and Log


						------------------BEGIN Log Status---------------------------------

						IF @LogProgress = 1 
							BEGIN --@LogProgress = 1

    							IF @PrepOnly = 0
								BEGIN --@PrepOnly = 0   
								
									IF @ErrMsg IS NULL
									BEGIN --@ErrMsg IS NULL
										UPDATE	Minion.IndexMaintLogDetails
										SET		Status = 'Updating stats'
										WHERE	ExecutionDateTime = @ExecutionDateTime
												AND DBName = @DBName
												--AND TableID = @currTableID  --*-- 1.3
												--AND IndexID = @currIndexID;  --*-- 1.3
												AND SchemaName = @currSchemaName
												AND TableName = @currTableName
												AND IndexName = @currIndexName
												AND [Status] NOT LIKE '%FRAG STATS%'; --*-- 1.3

									END --@ErrMsg IS NULL
								END --@PrepOnly = 0
							END --@LogProgress = 1
						------------------END Log Status---------------------------------

						SET @currOP = 'Stats';
						SET @StatsBeginDateTime = GETDATE();
	
						--------------------------------------------------------------
						-------------END LOG PREP-------------------------------------
						--------------------------------------------------------------
			
			
						--------------------------------------------------------------
						-------------BEGIN STMT BUILD---------------------------------
						--------------------------------------------------------------
	
						----Changed in v.1.3 to help with some edge cases where some names need to be in double-quotes instead of in [].
						----Also in 1.3: Only update statistics if the index in question is NOT a spatial index.
						IF @currIndexTypeDesc <> 'SPATIAL'
						BEGIN
							SET @StatsSQL = 'USE [' + @DBName
								+ ']; UPDATE STATISTICS "' + @currSchemaName + '"."'
								+ @currTableName + '" ' + '"' + @currIndexName + '"'
								--+ ']; UPDATE STATISTICS [' + @currSchemaName + '].['
								--+ @currTableName + '] ' + '[' + @currIndexName + ']'

								IF @currStatScanOption IS NOT NULL
								BEGIN
									SET @StatsSQL = @StatsSQL + ' WITH ' + @currStatScanOption;
								END
						END; 

						SET @StatsEndDateTime = GETDATE();
			
						--------------------------------------------------------------
						-------------END STMT BUILD-----------------------------------
						--------------------------------------------------------------
			

						--------------------------------------------------------------
						-------------BEGIN RUN----------------------------------------
						--------------------------------------------------------------
						IF @currIndexTypeDesc <> 'SPATIAL'
						BEGIN
							--*-- 1.3: We switched from using brackets, to using quotes, around object names. That messes up SQLCMD; so we 
							--*-- replace " with "".
							SET @StatsSQL = REPLACE(@StatsSQL, '"', '""');

							SET @PreCMD = 'sqlcmd -I -r 1 -S"' + @ServerInstance + CAST(@Port AS VARCHAR(6))
							SET @TotalCMD = @PreCMD + '" -q "' + @StatsSQL + '"' 

								--PRINT @TotalCMD

							--*-- 1.3: For logging, switch back to " instead of "". This makes a usable query.
							SET @StatsSQL = REPLACE(@StatsSQL, '""', '"');

							SET @ErrMsg = NULL;
							INSERT #UpdateStatsResults (col1)
									EXEC xp_cmdshell @TotalCMD;
						

							DELETE FROM
									#UpdateStatsResults
							WHERE
								col1 IS NULL
								OR col1 LIKE '%Changed database context%'
								OR col1 LIKE '%completed successfully%';;		
						

							---------------------BEGIN Error Var---------------------
                   
							SELECT @UpdateStatErrMsg = STUFF((SELECT ' ' + col1 FROM #UpdateStatsResults AS T1 ORDER BY T1.ID
							FOR XML PATH('')), 1, 1, '')
							FROM
								#UpdateStatsResults AS T2;

							----SELECT @UpdateStatErrMsg AS UpdateStatErrMsg
							TRUNCATE TABLE #UpdateStatsResults;

						
							---------------------END Error Var---------------------

							--EXEC (@StatsSQL);
						END;
						
						--------------------------------------------------------------
						-------------END RUN------------------------------------------
						--------------------------------------------------------------
						
			
					--------------------------------------------------------------
					-------------BEGIN Stats Log---------------------------------- Inside cursor
					--------------------------------------------------------------
						
					IF @StmtOnly = 0 
						BEGIN --@StmtOnly = 0

    					IF @PrepOnly = 0
						BEGIN --@PrepOnly = 0   
					        
							UPDATE	Minion.IndexMaintLogDetails
							SET		UpdateStatsBeginDateTime = CONVERT(VARCHAR(25), @StatsBeginDateTime, 21) ,
									UpdateStatsEndDateTime = CONVERT(VARCHAR(25), @StatsEndDateTime, 21) ,
									UpdateStatsStmt = @StatsSQL ,
									UpdateStatsTimeInSecs = DATEDIFF(s,
															  CONVERT(VARCHAR(25), @StatsBeginDateTime, 21),
															  CONVERT(VARCHAR(25), @StatsEndDateTime, 21)),
									Warnings = CASE
													WHEN @UpdateStatErrMsg IS NOT NULL THEN ISNULL(Warnings, '') + @UpdateStatErrMsg
											   END
							WHERE	ExecutionDateTime = CONVERT(VARCHAR(25), @ExecutionDateTime, 21)
									AND DBName = @DBName
									--AND TableID = @currTableID  --*-- 1.3
									--AND IndexID = @currIndexID;  --*-- 1.3
									AND SchemaName = @currSchemaName
									AND TableName = @currTableName
									AND IndexName = @currIndexName	
									AND [Status] NOT LIKE '%FRAG STATS%'; --*-- 1.3								
							END --@PrepOnly = 0

						END	--@StmtOnly = 0		

							END ----Stats Update and Log
						END --Stats Update and Log

						IF @currIndexTypeDesc = 'SPATIAL' AND @currOP = 'Reorg' AND @currUpdateStatsOnDefrag = 1
						BEGIN
							SET @UpdateStatErrMsg = 'Spatial index: cannot update statistics. To resolve, turn UpdateStatsOnDefrag off for this table in Minion.IndexSettingsTable.';
							
							UPDATE Minion.IndexMaintLogDetails
							SET Warnings = ISNULL(Warnings, '') + @UpdateStatErrMsg
							WHERE ExecutionDateTime = CONVERT(VARCHAR(25), @ExecutionDateTime, 21)
								  AND DBName = @DBName
								  --AND TableID = @currTableID  --*-- 1.3
								  --AND IndexID = @currIndexID;  --*-- 1.3
								  AND SchemaName = @currSchemaName
								  AND TableName = @currTableName
								  AND IndexName = @currIndexName
								  AND [Status] NOT LIKE '%FRAG STATS%'; --*-- 1.3	
						END;
					--------------------------------------------------------------
					-------------END Stats Log------------------------------------ Inside cursor
					-------------------------------------------------------------- 

				END --@StmtOnly = 0
			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------END Run Stats Update----------------------------- Inside cursor
			--------------------------------------------------------------
			--------------------------------------------------------------
			

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------BEGIN Post Frag---------------------------------- Inside cursor
			--------------------------------------------------------------
			--------------------------------------------------------------
			
			IF @ErrMsg IS NULL
				BEGIN --@ErrMsg IS NULL

					IF @currGetPostFragLevel = 1 --AND @StmtOnly = 0
						BEGIN --Post Frag

							--------------------------------------------------------------
							-------------BEGIN Log Status---------------------------------
							--------------------------------------------------------------

							IF @LogProgress = 1 
								BEGIN --@LogProgress = 1

    								IF @PrepOnly = 0
										BEGIN --@PrepOnly = 0  
											SET @PostFragBeginDateTime = GETDATE(); 

											--*-- Status MUST say "fragmentation", not frag. Because we cue off of FRAG STATS for the DB-level frag stats row.
											UPDATE	Minion.IndexMaintLogDetails
											SET		[Status] = 'Getting Post Fragmentation stats', 
													PostFragBeginDateTime = @PostFragBeginDateTime
											WHERE	ExecutionDateTime = @ExecutionDateTime
													AND DBName = @DBName
													--AND TableID = @currTableID  --*-- 1.3
													--AND IndexID = @currIndexID;  --*-- 1.3
													AND SchemaName = @currSchemaName
													AND TableName = @currTableName
													AND IndexName = @currIndexName
													AND [Status] NOT LIKE '%FRAG STATS%'; --*-- 1.3

										END --@Preponly = 0

								END --@LogProgress = 1

							--------------------------------------------------------------
							-------------END Log Status-----------------------------------
							--------------------------------------------------------------
							

							--------------------------------------------------------------
							-------------BEGIN STMT PREP----------------------------------
							--------------------------------------------------------------
							
							----Changed in v.1.3 to help with some edge cases where some names need to be in double-quotes instead of in [].
							--SET @currIndexForFragStats = '[' + @DBName + ']' + '.'
							--	+ '[' + @currSchemaName + ']' + '.' + '[' + @currTableName + ']'
							SET @currIndexForFragStats = '"' + @DBName + '"' + '.'
								+ '"' + @currSchemaName + '"' + '.' + '"' + @currTableName + '"'
						      
							--This can be done better. Add some cols and make some decisions based off of scanmode, etc.			
							INSERT	#PostFrag
								SELECT	avg_fragmentation_in_percent ,
										index_id ,
										index_level
								FROM	sys.dm_db_index_physical_stats(DB_ID(@DBName),
																	OBJECT_ID(@currIndexForFragStats),
																	@currIndexID,
																	NULL,
																	@currIndexScanMode) 


							--SELECT 'SELECT	avg_fragmentation_in_percent ,
							--		index_id ,
							--		index_level
							--FROM	sys.dm_db_index_physical_stats(DB_ID(' + @DBName + '),' +
							--								  'OBJECT_ID(' + @currIndexForFragStats + '),'
							--								  + ISNULL(CAST(@currIndexID AS VARCHAR(5)), 'SEAN') + ',' +
							--								  'NULL,' + 
							--								  ISNULL(@currIndexScanMode, 'SEAN') + ') ' AS PostFragStmt
							--------------------------------------------------------------
							-------------END STMT PREP------------------------------------
							--------------------------------------------------------------
							
						END  --Post Frag


					--------------------------------------------------------------
					-------------BEGIN Post Frag Log------------------------------ Inside cursor
					--------------------------------------------------------------
	
			
					IF @ErrMsg IS NULL
						BEGIN --@ErrMsg IS NULL

							-----The same conditions apply here as for the initial frag stats.  So we're either going to take the max
							-----or we're going to take level 0 for the clustered index.

							IF @currIndexScanMode IS NULL
								BEGIN
									SET @currIndexScanMode = 'Limited'
								END

							IF @currIndexScanMode = 'Limited' 
								BEGIN
									SET @PostFragLevel = ( SELECT	MAX(MaxFrag)
														   FROM		#PostFrag
														 );
								END

							IF @currIndexScanMode = 'Detailed' 
								BEGIN
									SET @PostFragLevel = ( SELECT	MAX(MaxFrag)
														   FROM		#PostFrag
														   WHERE	Index_ID = 1
																	AND Index_Level = 0
														 );
		
								END

							--Prep #PostFrag for the next index.
							TRUNCATE TABLE #PostFrag

							SET @PostFragEndDateTime = GETDATE(); 
	
							---------------------BEGIN RUN---------------------
								
							IF @StmtOnly = 0 
								BEGIN --@StmtOnly = 0
  
      								IF @PrepOnly = 0
									BEGIN --@PrepOnly = 0  
					      
											UPDATE	Minion.IndexMaintLogDetails
											SET		--PostFragBeginDateTime = CONVERT(VARCHAR(25), @RowCTBeginDateTime, 21) ,
													PostFragEndDateTime = CONVERT(VARCHAR(25), @PostFragBeginDateTime, 21) ,
													PostFragTimeInSecs = DATEDIFF(s,
																			  CONVERT(VARCHAR(25), @PostFragBeginDateTime, 21),
																			  CONVERT(VARCHAR(25), @PostFragEndDateTime, 21)) ,
													PostFragLevel = @PostFragLevel
											WHERE	ExecutionDateTime = CONVERT(VARCHAR(25), @ExecutionDateTime, 21)
													AND DBName = @DBName
													--AND TableID = @currTableID  --*-- 1.3
													--AND IndexID = @currIndexID;  --*-- 1.3
													AND SchemaName = @currSchemaName
													AND TableName = @currTableName
													AND IndexName = @currIndexName
													AND [Status] NOT LIKE '%FRAG STATS%'; --*-- 1.3

									END --@PrepOnly = 0

								END --@StmtOnly = 0
							---------------------END RUN---------------------	

						END --@ErrMsg IS NULL
						

					--------------------------------------------------------------
					-------------END Post Frag Log-------------------------------- Inside cursor
					--------------------------------------------------------------
	
 		
		
				END --@ErrMsg IS NULL 

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------END Post Frag------------------------------------ Inside cursor
			--------------------------------------------------------------
			--------------------------------------------------------------
			

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------BEGIN Table PostCode-----------------------------
			--------------------------------------------------------------
			--------------------------------------------------------------


			IF @StmtOnly = 0 
				BEGIN -- @StmtOnly = 0

					IF @currTableIterator = @TableCT--@TableCtrl <> @currTableName AND @TableCtrl <> ''
						BEGIN --TableCtrl

							IF @currTablePostCode IS NOT NULL 
								BEGIN --@currTablePostCode IS NOT NULL

									SET @TablePostCodeBeginDateTime = GETDATE();
									--------------------------------------------------------------
									-------------BEGIN Log Status---------------------------------
									--------------------------------------------------------------

										IF @StmtOnly = 0 
											BEGIN --@StmtOnly = 0
  												IF @PrepOnly = 0
													BEGIN --@PrepOnly = 0 

														IF @LogProgress = 1 
															BEGIN --@LogProgress = 1
																IF @currTablePostCode IS NOT NULL 
																	BEGIN --@currTablePostCode IS NOT NULL

																		IF @ErrMsg IS NULL
																		BEGIN --@ErrMsg IS NULL
																		UPDATE	Minion.IndexMaintLogDetails
																		SET		Status = 'Running Table PostCode' ,
																				PostCode = @currTablePostCode ,
																				PostCodeBeginDateTime = @TablePostCodeBeginDateTime
																		WHERE	ExecutionDateTime = @ExecutionDateTime
																				AND DBName = @DBName
																				--AND TableID = @currTableID  --*-- 1.3
																				--AND IndexID = @currIndexID;  --*-- 1.3
																				AND SchemaName = @currSchemaName
																				AND TableName = @currTableName
																				AND IndexName = @currIndexName
																				AND [Status] NOT LIKE '%FRAG STATS%'; --*-- 1.3
																		END --@ErrMsg IS NULL

																	END  --@currTablePostCode IS NOT NULL
															END --@LogProgress = 1

													END --@PrepOnly = 0
											END --@StmtOnly = 0

									--------------------------------------------------------------
									-------------END Log Status-----------------------------------
									--------------------------------------------------------------


									--------------------------------------------------------------
									-------------BEGIN Run Table PostCode-------------------------
									--------------------------------------------------------------
									EXEC (@currTablePostCode)

									--------------------------------------------------------------
									-------------END Run Table PostCode---------------------------
									--------------------------------------------------------------

									SET @TablePostCodeEndDateTime = GETDATE();

								END --@currTablePostCode IS NOT NULL

						END --TableCtrl
				END -- @StmtOnly = 0

			--------------------------------------------------------------
			--------------------------------------------------------------
			-------------END Table PostCode-------------------------------
			--------------------------------------------------------------
			--------------------------------------------------------------
			


		--------------------------------------------------------------
		--------------------------------------------------------------
		-------------BEGIN Usage Details------------------------------
		--------------------------------------------------------------
		--------------------------------------------------------------
			
		IF @ErrMsg IS NULL
		BEGIN
			IF @StmtOnly = 0 
				BEGIN  --@StmtOnly = 0   --UsageDetails

					SET @IncludeUsageDetails = ( SELECT	IncludeUsageDetails
													FROM	Minion.IndexSettingsDB
													WHERE	DBName = 'MinionDefault'
												)

		----Override default PreCode if a DB override exists.
					IF ( SELECT	IncludeUsageDetails
							FROM	Minion.IndexSettingsDB
							WHERE	DBName = @DBName
						) IS NOT NULL 
						BEGIN
							SET @IncludeUsageDetails = ( SELECT
																IncludeUsageDetails
															FROM Minion.IndexSettingsDB
															WHERE
																DBName = @DBName
														);
						END

				END  --@StmtOnly = 0   --UsageDetails


      		IF @PrepOnly = 0
				BEGIN --@PrepOnly = 0  

					IF @IncludeUsageDetails = 1 
						BEGIN --@IncludeUsageDetails = 1 

							UPDATE	IML
							SET		IML.UserSeeks = IUS.user_seeks ,
									IML.UserScans = IUS.user_scans ,
									IML.UserLookups = IUS.user_lookups ,
									IML.UserUpdates = IUS.user_updates ,
									IML.LastUserSeek = IUS.last_user_seek ,
									IML.LastUserScan = IUS.last_user_scan ,
									IML.LastUserLookup = IUS.last_user_lookup ,
									IML.LastUserUpdate = IUS.last_user_update ,
									IML.SystemSeeks = IUS.system_seeks ,
									IML.SystemScans = IUS.system_scans ,
									IML.SystemLookups = IUS.system_lookups ,
									IML.SystemUpdates = IUS.system_updates ,
									IML.LastSystemSeek = IUS.last_system_seek ,
									IML.LastSystemScan = IUS.last_system_scan ,
									IML.LastSystemLookup = IUS.last_system_lookup ,
									IML.LastSystemUpdate = IUS.last_system_update
							FROM	Minion.IndexMaintLogDetails IML
									INNER JOIN sys.dm_db_index_usage_stats IUS ON @currTableID = IUS.object_id
																	  AND @currIndexID = IUS.index_id
							WHERE	IML.DBName = @DBName
									AND IML.TableID = @currTableID
									AND IML.IndexID = @currIndexID
									AND IML.ExecutionDateTime = @ExecutionDateTime
									AND IML.[Status] NOT LIKE '%FRAG STATS%'; --*-- 1.3

						END --@PrepOnly = 0

				END --@IncludeUsageDetails = 1 

		END --@ErrMsg IS NULL
		--------------------------------------------------------------
		--------------------------------------------------------------
		-------------END Usage Details--------------------------------
		--------------------------------------------------------------
		--------------------------------------------------------------
			


		--------------------------------------------------------------
		--------------------------------------------------------------
		-------------BEGIN Delete Log History-------------------------
		--------------------------------------------------------------
		--------------------------------------------------------------
			

		
		--------------------------------------------------------------
		-------------BEGIN Log Status---------------------------------
		--------------------------------------------------------------
		
	
		IF @PrepOnly = 0
			BEGIN --@PrepOnly = 0 
		
				IF @ErrMsg IS NULL
					BEGIN --@ErrMsg IS NULL
						IF @LogProgress = 1 
							BEGIN --@LogProgress = 1

								UPDATE	Minion.IndexMaintLogDetails
								SET		Status = 'Deleting Table History'
								WHERE	ExecutionDateTime = @ExecutionDateTime
										AND DBName = @DBName
										--AND TableID = @currTableID  --*-- 1.3
										--AND IndexID = @currIndexID;  --*-- 1.3
										AND SchemaName = @currSchemaName
										AND TableName = @currTableName
										AND IndexName = @currIndexName
										AND [Status] NOT LIKE '%FRAG STATS%'; --*-- 1.3
							END --@LogProgress = 1 
					END --@ErrMsg IS NULL

			END --@PrepOnly = 0

		
		--------------------------------------------------------------
		-------------END Log Status-----------------------------------
		--------------------------------------------------------------
		
		IF @PrepOnly = 0
			BEGIN --@PrepOnly = 0 

				DELETE	Minion.IndexMaintLogDetails
				WHERE	DATEDIFF(dd, ExecutionDateTime, GETDATE()) > @currLogRetDays
						AND DBName = @DBName
						--AND TableID = @currTableID;  --*-- 1.3
						AND SchemaName = @currSchemaName
						AND TableName = @currTableName; --*-- 1.3

			END --@PrepOnly = 0

		--------------------------------------------------------------
		--------------------------------------------------------------
		-------------END Delete Log History---------------------------
		--------------------------------------------------------------
		--------------------------------------------------------------
			

		--------------------------------------------------------------
		--------------------------------------------------------------
		-------------BEGIN Delete Current Table from TableFrag--------
		--------------------------------------------------------------
		--------------------------------------------------------------
			
		IF @RunPrepped = 1
			BEGIN --@RunPrepped = 1
				DELETE	Minion.IndexTableFrag
				WHERE	TableID = @currTableID
						AND IndexID = @currIndexID
						AND DBName = @DBName
						AND Prepped = 1
			END --@RunPrepped = 1


		IF @RunPrepped = 0
			BEGIN --@RunPrepped = 1
				DELETE	Minion.IndexTableFrag
				WHERE	TableID = @currTableID
						AND IndexID = @currIndexID
						AND DBName = @DBName
						AND Prepped = 0
			END --@RunPrepped = 1

		--------------------------------------------------------------
		--------------------------------------------------------------
		-------------END Delete Current Table from Table Frag---------
		--------------------------------------------------------------
		--------------------------------------------------------------
			

		--------------------------------------------------------------
		--------------------------------------------------------------
		-------------BEGIN Log Complete Status------------------------
		--------------------------------------------------------------
		--------------------------------------------------------------
				
		IF @ErrMsg IS NULL
			BEGIN --@ErrMsg IS NULL

      			IF @PrepOnly = 0
				BEGIN --@PrepOnly = 0 

					IF @LogProgress = 1 
						BEGIN --@LogProgress = 1

							UPDATE	Minion.IndexMaintLogDetails
							SET		[Status] = 'Complete'
							WHERE	ExecutionDateTime = @ExecutionDateTime
									AND DBName = @DBName
									--AND TableID = @currTableID  --*-- 1.3
									--AND IndexID = @currIndexID;  --*-- 1.3
									AND SchemaName = @currSchemaName
									AND TableName = @currTableName
									AND IndexName = @currIndexName
									AND [Status] NOT LIKE '%FRAG STATS%'; --*-- 1.3
						END --@LogProgress = 1

				END --@PrepOnly = 0

			END --@ErrMsg IS NULL

		--------------------------------------------------------------
		--------------------------------------------------------------
		-------------END Log Complete Status--------------------------
		--------------------------------------------------------------
		--------------------------------------------------------------
			
			----Set Error var for next index.

			SET @TableCtrl = @currTableName

			FETCH NEXT FROM Tables INTO @currTableID, @currSchemaName,
				@currTableName, @currIndexName, @currIndexID, @currIndexType,
				@currIndexTypeDesc, @currFragLevel, @currReorgThreshold,
				@currRebuildThreshold, @currFILLFACTORopt, @currPadIndex,
				@currONLINEopt, @currSortInTempDB, @currMAXDOPopt,
				@currDataCompression, @currGetRowCT, @currGetPostFragLevel,
				@currUpdateStatsOnDefrag, @currStatScanOption,
				@currIgnoreDupKey, @currStatsNoRecompute, @currAllowRowLocks,
				@currAllowPageLocks, @currWaitAtLowPriority,
				@currMaxDurationInMins, @currAbortAfterWait, @currLogProgress,
				@currLogRetDays, @currPushToMinion, @currLogIndexPhysicalStats,
				@currIndexScanMode, @currTablePreCode, @currTablePostCode, @currStmtPrefix, @currStmtSuffix, @currRebuildHeap
	
		END -- End Cursor Loop

	CLOSE Tables
	DEALLOCATE Tables

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Reindex Stmt Cursor------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN DBPostCode-------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

	IF @StmtOnly = 0 
		BEGIN --@StmtOnly = 0 MAIN

			IF @PrepOnly = 0
				BEGIN --@PrepOnly = 0

					----Get default PostCode for all DBs.
					SET @DBPostCode = ( SELECT	DBPostCode
										FROM	Minion.IndexSettingsDB
										WHERE	DBName = 'MinionDefault'
									  )

					----Override default PostCode if a DB override exists.
					IF ( SELECT	DBPostCode
						 FROM	Minion.IndexSettingsDB
						 WHERE	DBName = @DBName
					   ) IS NOT NULL 
						BEGIN
							SET @DBPostCode = ( SELECT	DBPostCode
												FROM	Minion.IndexSettingsDB
												WHERE	DBName = @DBName
											  );
						END


					IF @DBPostCode IS NOT NULL 
						BEGIN --@DBPostCode IS NOT NULL

					--------------------------------------------------------------
					--------------------------------------------------------------
					-------------BEGIN Log Status---------------------------------
					--------------------------------------------------------------
					--------------------------------------------------------------
			
							IF @StmtOnly = 0 
								BEGIN --@StmtOnly = 0

									UPDATE	Minion.IndexMaintLog
									SET		Status = 'Running DB PostCode'
									WHERE	ExecutionDateTime = @ExecutionDateTime
											AND DBName = @DBName

								END --@StmtOnly = 0

					--------------------------------------------------------------
					--------------------------------------------------------------
					-------------END Log Status-----------------------------------
					--------------------------------------------------------------
					--------------------------------------------------------------
			
							SET @DBPostCodeBeginDateTime = GETDATE();
							EXEC (@DBPostCode)
							SET @DBPostCodeEndDateTime = GETDATE();

						END --@DBPostCode IS NOT NULL
				END --@PrepOnly = 0

		END --@StmtOnly = 0 MAIN

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END DBPostCode---------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------




--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------Begin Central Logging--------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


--It's important that none of the trigger files have a file ext.  Just parse out the server.DBName.
--The template file is there because you can't just create a file in dos like you can in PS and 
--all the boxes can't have PS put on them.  This is the easiest low-tech way to accomplish this.
--So put an empty file called 'Template' with no ext and you rename it during the copy.

	IF @StmtOnly = 0 

		IF @PrepOnly = 0
			BEGIN --@PrepOnly = 0

				BEGIN -- @StmtOnly = 0
					DECLARE	@ReindexLogging BIT ,	--*-- 1.3
						@ReindexLoggingPath NVARCHAR(1000);

					SELECT	@ReindexLogging = PushToMinion ,
							@ReindexLoggingPath = MinionTriggerPath
					FROM	Minion.IndexSettingsDB
					WHERE	DBName = 'MinionDefault';

					----Override default Logging if a DB override exists.
					--*-- 1.3 Change this. Logic before said that if PushToMinion IS NOT NULL for the DB row, then use that value. 
					--*-- That's not really what we want; the DB row should take precedene over MinionDefault, no matter if there's a PushToMinion val or not.
					IF EXISTS ( SELECT	PushToMinion
						 FROM	Minion.IndexSettingsDB
						 WHERE	DBName = @DBName
					   ) 
						BEGIN
							SELECT	@ReindexLogging = PushToMinion ,
									@ReindexLoggingPath = MinionTriggerPath
							FROM	Minion.IndexSettingsDB
							WHERE	DBName = @DBName;
						END


					IF @ReindexLogging = 1	--*-- 1.3 Was 'Repo'
						BEGIN
							DECLARE	@TriggerFile VARCHAR(4000) ,
								@InstanceName VARCHAR(128) ,
								@FullServerName VARCHAR(200);
			
							--SET @InstanceName = CAST(SERVERPROPERTY('InstanceName') AS NVARCHAR(128));	

		----Separate the Instance and servername with a $ instead of a \.  This way it doesn't get turned into a folder 
		----in the dos call below.
							--IF @InstanceName IS NOT NULL 
							--	SET @InstanceName = '$' + @InstanceName;

							--IF @InstanceName IS NULL 
								SET @InstanceName = @@ServerName;

		----Build the full server$Instance name to make the dos call below cleaner.
							SET @FullServerName = REPLACE(@InstanceName, '\', '~')

		---Log to the trigger file to be pushed into repo.
							SET @TriggerFile = 'Powershell "' + ''''''''
								+ CONVERT(VARCHAR(25), @ExecutionDateTime, 21)
								+ '''''''' + ' | out-file "' + @ReindexLoggingPath
								+ @FullServerName + '.' + @DBName + ' -append"' 

							EXEC xp_cmdshell @TriggerFile; 
						END

			END --@PrepOnly = 0

		END -- @StmtOnly = 0

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Central Logging----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN Reset RecoveryModel---------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
	
	IF @PrepOnly = 0
	BEGIN --@PrepOnly = 0

			IF @RecoveryModelChanged = 1 
				BEGIN
					SET @RecoveryModelSQL = 'ALTER DATABASE [' + @DBName
						+ '] SET RECOVERY ' + @CurrentRecoveryModel;
					EXEC (@RecoveryModelSQL);

				END

	END -- @PrepOnly = 0
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Reset RecoveryModel------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN Log to IndexMaintLogMaster---------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

IF @PrepOnly = 0
	BEGIN --@PrepOnly = 0

		SET @NumTablesProcessed = ( SELECT	COUNT(DISTINCT TableName)
									FROM	Minion.IndexMaintLogDetails WITH ( NOLOCK )
									WHERE	ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName
											AND [Status] NOT LIKE '%FRAG STATS%' --*-- 1.3
								  );
		SET @NumIndexesProcessed = ( SELECT	COUNT(IndexName)
									 FROM	Minion.IndexMaintLogDetails WITH ( NOLOCK )
									 WHERE	ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName
											AND [Status] NOT LIKE '%FRAG STATS%' --*-- 1.3
								   );
		SET @NumIndexesRebuilt = ( SELECT	COUNT(*)
								   FROM		Minion.IndexMaintLogDetails WITH ( NOLOCK )
								   WHERE	UPPER(Op) = 'REBUILD'
											AND ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName
											AND [Status] NOT LIKE '%FRAG STATS%' --*-- 1.3
								 );
		SET @NumIndexesReorged = ( SELECT	COUNT(*)
								   FROM		Minion.IndexMaintLogDetails WITH ( NOLOCK )
								   WHERE	UPPER(Op) = 'REORG'
											AND ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName
											AND [Status] NOT LIKE '%FRAG STATS%' --*-- 1.3
								 );

		DECLARE @FinalErrorCT INT,
				@FinalWarningCT INT;
		SET @FinalErrorCT = (SELECT COUNT(*) FROM Minion.IndexMaintLogDetails WHERE ExecutionDateTime = @ExecutionDateTime AND [Status] NOT LIKE '%FRAG STATS%' AND (Status NOT LIKE '%Complete' AND Status LIKE 'FATAL ERROR%'));
		SET @FinalWarningCT = (SELECT COUNT(*) FROM Minion.IndexMaintLogDetails WHERE ExecutionDateTime = @ExecutionDateTime AND [Status] NOT LIKE '%FRAG STATS%' AND (Warnings IS NOT NULL AND Warnings <> ''));


		UPDATE Minion.IndexMaintLogDetails
		SET [Status] = 
			CASE 
				 WHEN ([Status] LIKE '%Complete' AND (Warnings IS NULL OR Warnings = '')) THEN 'All Complete'
				 WHEN ([Status] LIKE '%Warnings' AND [Status] NOT LIKE '%FATAL ERROR%') OR (Warnings IS NOT NULL AND Warnings <> '') THEN 'Complete with Warnings'
				 WHEN [Status] IS NULL THEN 'FATAL ERROR: This is an unhandled error.  Contact support for assistance.'
				 WHEN [Status] LIKE 'FATAL ERROR%' THEN [Status]
			END
		WHERE ExecutionDateTime = @ExecutionDateTime
			AND [Status] NOT LIKE '%FRAG STATS%';


		UPDATE	Minion.IndexMaintLog
		SET		ExecutionDateTime = @ExecutionDateTime ,
				Status = 
			CASE 
				 WHEN (@FinalErrorCT = 0 AND @FinalWarningCT = 0) THEN 'All Complete'
				 WHEN (@FinalErrorCT > 0 AND @FinalWarningCT = 0) THEN 'Complete with ' + CAST(@FinalErrorCT AS VARCHAR(10)) + ' Error' + CASE WHEN @FinalErrorCT > 1 THEN 's' ELSE '' END
				 WHEN (@FinalErrorCT = 0 AND @FinalWarningCT > 0) THEN 'Complete with ' + CAST(@FinalWarningCT AS VARCHAR(10)) + ' Warning' + CASE WHEN @FinalWarningCT > 1 THEN 's' ELSE '' END
				 WHEN (@FinalErrorCT > 0 AND @FinalWarningCT > 0) THEN 
				 ('Complete with ' + CAST(@FinalErrorCT AS VARCHAR(10)) + ' Error' + CASE WHEN @FinalErrorCT > 1 THEN 's' ELSE '' END) +
				 (' and ' + CAST(@FinalWarningCT AS VARCHAR(10)) + ' Warning' + CASE WHEN @FinalWarningCT > 1 THEN 's' ELSE '' END)
			END,
				DBName = @DBName ,
				Tables = @IndexOption ,
				RunPrepped = @RunPrepped ,
				PrepOnly = @PrepOnly ,
				ReorgMode = @ReorgMode ,
				NumTablesProcessed = ISNULL(@NumTablesProcessed, 0) ,
				NumIndexesProcessed = ISNULL(@NumIndexesProcessed, 0) ,
				NumIndexesRebuilt = ISNULL(@NumIndexesRebuilt, 0) ,
				NumIndexesReorged = ISNULL(@NumIndexesReorged, 0) ,
				RecoveryModelChanged = @RecoveryModelChanged ,
				RecoveryModelCurrent = @CurrentRecoveryModel ,
				RecoveryModelReindex = @ReindexRecoveryModel ,
				SQLVersion = @Version ,
				SQLEdition = @Edition ,
				DBPreCode = @DBPreCode ,
				DBPostCode = @DBPostCode ,
				DBPreCodeBeginDateTime = @DBPreCodeBeginDateTime ,
				DBPreCodeEndDateTime = @DBPreCodeEndDateTime ,
				DBPostCodeBeginDateTime = @DBPostCodeBeginDateTime ,
				DBPostCodeEndDateTime = @DBPostCodeEndDateTime ,
				DBPreCodeRunTimeInSecs = DATEDIFF(s,
												  CONVERT(VARCHAR(25), @DBPreCodeBeginDateTime, 21),
												  CONVERT(VARCHAR(25), @DBPreCodeEndDateTime, 21)) ,
				DBPostCodeRunTimeInSecs = DATEDIFF(s,
												   CONVERT(VARCHAR(25), @DBPostCodeBeginDateTime, 21),
												   CONVERT(VARCHAR(25), @DBPostCodeEndDateTime, 21)) ,
				ExecutionFinishTime = GETDATE() ,
				ExecutionRunTimeInSecs = DATEDIFF(s,
												  CONVERT(VARCHAR(25), @ExecutionDateTime, 21),
												  CONVERT(VARCHAR(25), GETDATE(), 21))
		WHERE	ExecutionDateTime = @ExecutionDateTime
				AND DBName = @DBName

	END --@PrepOnly = 0

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
---------------------------------------END Log to IndexMaintLogMaster-----------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------




GO
