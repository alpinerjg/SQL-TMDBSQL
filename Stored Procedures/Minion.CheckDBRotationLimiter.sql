SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[CheckDBRotationLimiter]
(
@ExecutionDateTime DATETIME,
@OpName VARCHAR(50),
@DBName nvarchar(400) = NULL
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
                
                EXEC Minion.HELP 'CHECKDB', 'Minion.CheckDBRotationLimiter';


PURPOSE: 


WALKTHROUGH: 
      1. 


CONVENTIONS:
    
    
TABLES: 
                

EXAMPLE EXECUTIONS:


REVISION HISTORY:
                

--***********************************************************************************/ 


SET NOCOUNT ON;
DECLARE @SettingLevel TINYINT,
		@RotationLimiter VARCHAR(50),
		@RotationLimiterMetric VARCHAR(10),
		@RotationMetricValue INT,
		@RotationPeriodInDays INT, --If all objects aren't processed within this time period, the rotation will begin again.
		@IsFullReload BIT,
		@PerformFullReloadDelete BIT,
		@TableCT INT;
DECLARE @RotationDBsCT INT,
		@ThreadQueueCT INT;
SET @IsFullReload = 0;

CREATE TABLE #RotationLimiterDBs
(
ID INT IDENTITY(1,1),
DBName VARCHAR(400)
)

IF UPPER(@OpName) = 'CHECKDB'
	BEGIN --CHECKDB
	----------------------------------------------------
	----------------BEGIN Settings Level----------------
	----------------------------------------------------


--Backup the ThreadQ table to a #table before doing anything.
SELECT IDENTITY(INT,1,1) AS ID, ExecutionDateTime, DBName, OpName, DBInternalThreads, IsReadOnly,
			StateDesc, CheckDBGroupOrder, CheckDBOrder, Processing,
			ProcessingThread
INTO #ThreadQTemp
FROM Minion.CheckDBThreadQueue
WHERE ExecutionDateTime = @ExecutionDateTime
ORDER BY CheckDBGroupOrder DESC, CheckDBOrder DESC;

------------------------------------------------------------------------------------------
---------------------BEGIN Manage DB list-------------------------------------------------
------------------------------------------------------------------------------------------

--------------------------------------------------------
----------------BEGIN Insert New------------------------
--------------------------------------------------------
----This table is needed because even though the same info is in the LogDetails table, it's both easier to get to here, and this table will be shorter, and
----you can easily alter the rotation queue by altering this table manually w/o deleting anything from the log.
----The log tables are mainly log tables and they shouldn't be called on for too much more.

--If the DBs are in the LogDetails table in the latest run, then they need to go into RotationDBs because they've already been run and we need to track them.
--So these are the DBs that ran last time.
INSERT Minion.CheckDBRotationDBs (ExecutionDateTime, DBName, OpName)
SELECT DISTINCT ExecutionDateTime, DBName, OpName
FROM Minion.CheckDBLogDetails
WHERE ExecutionDateTime IN (SELECT MAX(ExecutionDateTime) FROM Minion.CheckDBLogDetails WHERE OpName = 'CHECKDB' AND STATUS LIKE 'Complete%')
AND OpName = 'CHECKDB' AND STATUS LIKE 'Complete%';
--------------------------------------------------------
----------------END Insert New--------------------------
--------------------------------------------------------

--------------------------------------------------------
----------------BEGIN Delete Dupes----------------------
--------------------------------------------------------
----When you add new records above you're likely to end up with dupes.  We only want the latest CHECKDB for any given DB in this table.
;WITH cteRotationDBs (RowNum, ID, ExecutionDateTime, DBName)
AS
(
SELECT --use the row_number function to get the newest record
    ROW_NUMBER() OVER(PARTITION BY DBName ORDER BY  ExecutionDateTime DESC) AS RowNum, 
    ID,ExecutionDateTime,  DBName
FROM Minion.CheckDBRotationDBs

)

DELETE Minion.CheckDBRotationDBs
WHERE ID IN
(SELECT ID FROM cteRotationDBs
WHERE RowNum > 1);
--------------------------------------------------------
----------------END Delete Dupes------------------------
--------------------------------------------------------

------------------------------------------------------------------------------------------
---------------------END Manage DB list---------------------------------------------------
------------------------------------------------------------------------------------------

		--SET @SettingLevel = (SELECT COUNT(*) FROM Minion.CheckDBRotationSettings WHERE UPPER(OpName) = 'CHECKDB' AND IsActive = 1)
		SELECT TOP 1 @RotationLimiter = RotationLimiter,
			   @RotationLimiterMetric = RotationLimiterMetric,
			   @RotationMetricValue = RotationMetricValue,
			   @RotationPeriodInDays = RotationPeriodInDays
		FROM Minion.CheckDBSettingsRotation 
		WHERE UPPER(OpName) = 'CHECKDB' 
		AND IsActive = 1

--------------------------------------------------
----------------BEGIN Log To Work-----------------
--------------------------------------------------
INSERT Minion.Work
		(ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value)
SELECT @ExecutionDateTime, 'CHECKDB', 'CHECKDB', 'CHECKDB', '@RotationLimiter', 'CheckDBRotationLimiter', ISNULL(@RotationLimiter, 'None');
INSERT Minion.Work
		(ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value)
SELECT @ExecutionDateTime, 'CHECKDB', 'CHECKDB', 'CHECKDB', '@RotationLimiterMetric', 'CheckDBRotationLimiter', ISNULL(@RotationLimiterMetric, 'None');
INSERT Minion.Work
		(ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value)
SELECT @ExecutionDateTime, 'CHECKDB', 'CHECKDB', 'CHECKDB', '@RotationMetricValue', 'CheckDBRotationLimiter', ISNULL(@RotationMetricValue, 0);


--------------------------------------------------
----------------END Log To Work-------------------
--------------------------------------------------

----If it's Time, then we set this to all the tables in the original Q or we'll reach a point where we won't add anymore tables.
----If you've got say 1 table that is skipped it'll keep showing up again and again.  If you don't set this here, then it'll always be the 
----only one in the Q table so it'll just get skipped and the job will end w/o even trying more table.
----Here, we're ensuring that it goes into the proper branch below... the one that's not =.
IF @RotationLimiter = 'Time'
	BEGIN
		SET @RotationMetricValue = (SELECT COUNT(*) FROM #ThreadQTemp)
	END


	----------------------------------------------------
	----------------END Settings Level------------------
	----------------------------------------------------

----INSERT #RotationLimiterDBs (DBName)
----SELECT DISTINCT DBName 
----FROM Minion.CheckDBLogDetails
----WHERE ExecutionDateTime IN (SELECT MAX(ExecutionDateTime) FROM Minion.CheckDBLogDetails WHERE OpName = 'CHECKDB' AND STATUS LIKE 'Complete%')

--------------------------------------------------------
-------------BEGIN Delete Previous DBs------------------
--------------------------------------------------------
----SELECT TQ.DBName FROM Minion.CheckDBThreadQueue TQ
----INNER JOIN Minion.CheckDBRotationDBs CR
----ON CR.DBName = TQ.DBName
----WHERE TQ.ExecutionDateTime = '2016-08-21 18:11:43.823'--@ExecutionDateTime;

----Get counts of each table before ThreadQ is trimmed.

SET @RotationDBsCT = (SELECT COUNT(*) FROM Minion.CheckDBRotationDBs);
SET @ThreadQueueCT = (SELECT COUNT(*) FROM Minion.CheckDBThreadQueue WHERE ExecutionDateTime = @ExecutionDateTime);



----SELECT 'Before', * FROM Minion.CheckDBThreadQueue WHERE ExecutionDateTime = @ExecutionDateTime
DELETE TQ
FROM Minion.CheckDBThreadQueue TQ
INNER JOIN Minion.CheckDBRotationDBs CR
ON CR.DBName = TQ.DBName
WHERE TQ.ExecutionDateTime = @ExecutionDateTime;
----SELECT 'After', * FROM Minion.CheckDBThreadQueue WHERE ExecutionDateTime = @ExecutionDateTime


--------------------------------------------------------
-------------END Delete Previous DBs--------------------
--------------------------------------------------------


	IF UPPER(@RotationLimiter) = 'DBCOUNT' OR UPPER(@RotationLimiter) = 'TIME'
		----For DBCount, RotationPeriod doesn't mean anything.  This is the simplest, and most straightforward rotation.  It'll work through all the DBs no matter how long it takes.
		----Other rotations can be concerned with completing in a specific time, but not this one.
		BEGIN -- @RotationLimiter = 'DBCount'
			
			-------------------------------------------------------
			--------------BEGIN Restart Cycle----------------------
			-------------------------------------------------------
			
			----If the cycle has completed, or will complete during this run then we'll need to know that here and manage the list such that it starts the list over again.
			----There are 2 scenarios.  1. the cycle finished completely in the last run and needs to be completely restarted. 2. It partially completed and now we're going to finish
			----the current loop and add some DBs from the previous loop.  So this is the partial restart.

			------------------------------------------------
			------------------------------------------------
			-------------BEGIN Full Restart-----------------
			------------------------------------------------
			------------------------------------------------
			--This will only happen with an even number of DBs.  Say you've got a 100 and you're doing 10 every day. Most of the time, this won't be relevant.
			IF @RotationDBsCT = @ThreadQueueCT
				BEGIN
					--So here we're starting the rotation over.  We don't have to worry about RotationDBs being populated right now cause that'll get done next time the routine runs.
					--Instead of truncating the table, maybe get the current list and 
					--put the in a #table and then truncate, and put those few back.
					--the problem is that in the previous run when we rolled over to the top 
					--of the list, we didn't preserve them and we need to in order to keep from
					--duplicating a few DBs over and over.
					
					TRUNCATE TABLE Minion.CheckDBRotationDBs;

					INSERT Minion.CheckDBRotationDBs(ExecutionDateTime, DBName, OpName)
					SELECT ExecutionDateTime, DBName, OpName
					FROM Minion.CheckDBRotationDBsReload
					----WHERE IsTail = 0;

					TRUNCATE TABLE Minion.CheckDBRotationDBsReload;
					--This tells us that it's a full reload and it shouldn't fill the Reload table in the next step.
					SET @IsFullReload = 1;
					SET @PerformFullReloadDelete = 1;
				END
			------------------------------------------------
			------------------------------------------------
			-------------END Full Restart-------------------
			------------------------------------------------
			------------------------------------------------


			------------------------------------------------
			------------------------------------------------
			-------------BEGIN Partial Restart--------------
			------------------------------------------------
			------------------------------------------------
			--This is a partial restart. We want to do, say 10, DBs/night. But we've only got say 7 left in the current rotation.
			--So here we've got to do those 7, but then add the other 3 back to the end of the list so we can start over with the rotation.
			IF (@ThreadQueueCT - @RotationDBsCT) < @RotationMetricValue
				BEGIN

					--Delete ThreadQ rows that already exist in the RotationDBs table.
					DELETE TQ
					FROM Minion.CheckDBThreadQueue TQ
					INNER JOIN Minion.CheckDBRotationDBs CR
					ON CR.DBName = TQ.DBName
					WHERE TQ.ExecutionDateTime = @ExecutionDateTime;

					--Now force the order so we can make sure that the ones from the previous round get run before the ones that are coming in as the new round.
					--So we're getting the highest GroupOrder and just adding 1 to it.
					UPDATE Minion.CheckDBThreadQueue
					SET CheckDBGroupOrder = (SELECT MAX(CheckDBGroupOrder) + 1 FROM #ThreadQTemp)

					----If we put all the rows back in from the #Q table then we can delete the ones we don't need in the final step below.
					----The only thing we need here is to renumber them so that we make sure we pick the proper ones.
					----We have to reset the numbers to ensure that we keep the ones that haven't processed yet on the top so they'll process before the 
					----ones that have beed added back do.
					INSERT Minion.CheckDBThreadQueue
					        (ExecutionDateTime, DBName, OpName, DBInternalThreads, IsReadOnly,
					         StateDesc, CheckDBGroupOrder, CheckDBOrder, Processing,
					         ProcessingThread)
					SELECT ExecutionDateTime, DBName, OpName, DBInternalThreads, IsReadOnly,
					         StateDesc, CheckDBGroupOrder, CheckDBOrder, Processing,
					         ProcessingThread
					FROM #ThreadQTemp
					ORDER BY CheckDBGroupOrder DESC, CheckDBOrder DESC

					----Remove dupes
					;WITH cteThreadQDBs (RowNum, ID, ExecutionDateTime, DBName, CheckDBGroupOrder)
					AS
					(
					SELECT --use the row_number function to get the newest record
						ROW_NUMBER() OVER(PARTITION BY DBName ORDER BY  CheckDBGroupOrder DESC) AS RowNum, 
						ID,ExecutionDateTime, DBName, CheckDBGroupOrder
					FROM Minion.CheckDBThreadQueue
					WHERE ExecutionDateTime = @ExecutionDateTime

					)

					DELETE Minion.CheckDBThreadQueue
					WHERE ID IN
					(SELECT ID FROM cteThreadQDBs
					WHERE RowNum > 1);

					--Save the current run so it's available for the next round since we've truncated the RotationDBs table.
					IF @IsFullReload = 0
						BEGIN
							INSERT Minion.CheckDBRotationDBsReload (ExecutionDateTime, DBName, OpName)
							SELECT ExecutionDateTime, DBName, @OpName
							FROM Minion.CheckDBThreadQueue
							WHERE DBName IN (SELECT TOP (@RotationMetricValue) DBName FROM Minion.CheckDBThreadQueue WHERE ExecutionDateTime = @ExecutionDateTime AND (OpName = 'CHECKDB' OR OpName IS NULL) ORDER BY CheckDBGroupOrder DESC, CheckDBOrder DESC)
							AND ExecutionDateTime = @ExecutionDateTime
							
							--We're only going to mark the end of the cycle.  We need to know where the last DBs in the final cycle
							--are because if we don't delete them then they won't be part of this cycle.
							UPDATE Minion.CheckDBRotationDBsReload
							SET IsTail = 1
							WHERE DBName IN (SELECT TOP (@ThreadQueueCT - @RotationDBsCT) DBName FROM Minion.CheckDBRotationDBsReload ORDER BY ID DESC)

							UPDATE Minion.CheckDBRotationDBsReload
							SET IsTail = 0
							WHERE IsTail IS NULL;
												
						END
				END

			------------------------------------------------
			------------------------------------------------
			-------------END Partial Restart----------------
			------------------------------------------------
			------------------------------------------------

			-------------------------------------------------------
			--------------END Restart Cycle------------------------
			-------------------------------------------------------

			----Delete all except the rows you want for this run from the ThreadQ table.
			----The number of rows in the ThreadQ should be @RotationMetricValue cause these are the rows to process.
			
			IF @PerformFullReloadDelete = 1
			BEGIN
			----Start by deleting the rows that are already in the RotationDBs table.
			----If we don't do this then we'll double-up during a partial restart.
			----This is only needed on the full reload run.
			----That's the one right after the partial reload has run.
				DELETE TQ
				FROM Minion.CheckDBThreadQueue TQ
				INNER JOIN Minion.CheckDBRotationDBs CR
				ON CR.DBName = TQ.DBName
				WHERE TQ.ExecutionDateTime = @ExecutionDateTime;
			END			

			IF UPPER(@RotationLimiter) = 'DBCOUNT'
				BEGIN --DBC1
			----Now that the included rows are out of the ThreadQ, we can
			----limit it to the ones we're interested in.
			DELETE Minion.CheckDBThreadQueue
			WHERE DBName NOT IN (SELECT TOP (@RotationMetricValue) DBName FROM Minion.CheckDBThreadQueue WHERE ExecutionDateTime = @ExecutionDateTime AND (OpName = 'CHECKDB' OR OpName IS NULL) ORDER BY CheckDBGroupOrder DESC, CheckDBOrder DESC)
			AND ExecutionDateTime = @ExecutionDateTime
				END --DBC1
		END -- @RotationLimiter = 'DBCount'

	END --CHECKDB

-------------------------------------------------------
-------------------------------------------------------
---------------BEGIN CheckTable------------------------
-------------------------------------------------------
-------------------------------------------------------

IF UPPER(@OpName) = 'CHECKTABLE'
	BEGIN --CHECKTABLE
	----------------------------------------------------
	----------------BEGIN Settings Level----------------
	----------------------------------------------------


--Backup the ThreadQ table to a #table before doing anything.
SELECT IDENTITY(INT,1,1) AS ID, 
ExecutionDateTime, DBName, SchemaName, TableName, IndexName, Exclude, 
GroupOrder, GroupDBOrder, NoIndex, RepairOption, RepairOptionAgree, AllErrorMsgs, 
ExtendedLogicalChecks, NoInfoMsgs, IsTabLock, ResultMode, IntegrityCheckLevel, 
HistRetDays, TablePreCode, TablePostCode, PreferredServer, Processing, ProcessingThread			
INTO #CheckTableThreadQTemp
FROM Minion.CheckDBCheckTableThreadQueue
WHERE ExecutionDateTime = @ExecutionDateTime
ORDER BY GroupOrder DESC, GroupDBOrder DESC;

------------------------------------------------------------------------------------------
---------------------BEGIN Manage DB list-------------------------------------------------
------------------------------------------------------------------------------------------

--------------------------------------------------------
----------------BEGIN Insert New------------------------
--------------------------------------------------------
----This table is needed because even though the same info is in the LogDetails table, it's both easier to get to here, and this table will be shorter, and
----you can easily alter the rotation queue by altering this table manually w/o deleting anything from the log.
----The log tables are mainly log tables and they shouldn't be called on for too much more.

--If the DBs are in the LogDetails table in the latest run, then they need to go into RotationDBs because they've already been run and we need to track them.
--So these are the DBs that ran last time.
INSERT Minion.CheckDBRotationTables (ExecutionDateTime, DBName, SchemaName, TableName, OpName)
SELECT DISTINCT ExecutionDateTime, DBName, SchemaName, TableName, OpName
FROM Minion.CheckDBLogDetails
WHERE ExecutionDateTime IN (SELECT MAX(ExecutionDateTime) FROM Minion.CheckDBLogDetails WHERE OpName = 'CHECKTABLE' AND STATUS LIKE 'Complete%')
AND OpName = 'CHECKTABLE' AND STATUS LIKE 'Complete%';
--------------------------------------------------------
----------------END Insert New--------------------------
--------------------------------------------------------

--------------------------------------------------------
----------------BEGIN Delete Dupes----------------------
--------------------------------------------------------
----When you add new records above you're likely to end up with dupes.  We only want the latest CHECKDB for any given DB in this table.
;WITH cteRotationTables (RowNum, ID, ExecutionDateTime, DBName, SchemaName, TableName)
AS
(
SELECT --use the row_number function to get the newest record
    ROW_NUMBER() OVER(PARTITION BY DBName, SchemaName, TableName ORDER BY  ExecutionDateTime DESC) AS RowNum, 
    ID,ExecutionDateTime, DBName, SchemaName, TableName
FROM Minion.CheckDBRotationTables

)

DELETE Minion.CheckDBRotationTables
WHERE ID IN
(SELECT ID FROM cteRotationTables
WHERE RowNum > 1);
--------------------------------------------------------
----------------END Delete Dupes------------------------
--------------------------------------------------------

------------------------------------------------------------------------------------------
---------------------END Manage DB list---------------------------------------------------
------------------------------------------------------------------------------------------

		--SET @SettingLevel = (SELECT COUNT(*) FROM Minion.CheckDBRotationSettings WHERE UPPER(OpName) = 'CHECKDB' AND IsActive = 1)
		SELECT TOP 1 @RotationLimiter = RotationLimiter,
			   @RotationLimiterMetric = RotationLimiterMetric,
			   @RotationMetricValue = RotationMetricValue,
			   @RotationPeriodInDays = RotationPeriodInDays
		FROM Minion.CheckDBSettingsRotation 
		WHERE UPPER(OpName) = 'CHECKTABLE' 
		AND IsActive = 1

--------------------------------------------------
----------------BEGIN Log To Work-----------------
--------------------------------------------------
INSERT Minion.Work
		(ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value)
SELECT @ExecutionDateTime, 'CHECKDB', @DBName, 'CHECKDB', '@RotationLimiter-CHECKTABLE', 'CheckDBRotationLimiter', ISNULL(@RotationLimiter, 'None');
INSERT Minion.Work
		(ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value)
SELECT @ExecutionDateTime, 'CHECKDB', @DBName, 'CHECKDB', '@RotationLimiterMetric-CHECKTABLE', 'CheckDBRotationLimiter', ISNULL(@RotationLimiterMetric, 'None');
INSERT Minion.Work
		(ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value)
SELECT @ExecutionDateTime, 'CHECKDB', @DBName, 'CHECKDB', '@RotationMetricValue-CHECKTABLE', 'CheckDBRotationLimiter', ISNULL(@RotationMetricValue, 0);


--------------------------------------------------
----------------END Log To Work-------------------
--------------------------------------------------


	----------------------------------------------------
	----------------END Settings Level------------------
	----------------------------------------------------


--------------------------------------------------------
-------------BEGIN Delete Previous DBs------------------
--------------------------------------------------------

----Get counts of each table before ThreadQ is trimmed.
DECLARE @RotationTablesCT INT;

SET @RotationTablesCT = (SELECT COUNT(*) FROM Minion.CheckDBRotationTables);
SET @ThreadQueueCT = (SELECT COUNT(*) FROM Minion.CheckDBCheckTableThreadQueue WHERE ExecutionDateTime = @ExecutionDateTime);

----SELECT 'Before', * FROM Minion.CheckDBThreadQueue WHERE ExecutionDateTime = @ExecutionDateTime
DELETE TQ
FROM Minion.CheckDBCheckTableThreadQueue TQ
INNER JOIN Minion.CheckDBRotationTables CR
ON CR.DBName = TQ.DBName AND CR.SchemaName = TQ.SchemaName AND CR.TableName = TQ.TableName
WHERE TQ.ExecutionDateTime = @ExecutionDateTime;
----SELECT 'After', * FROM Minion.CheckDBThreadQueue WHERE ExecutionDateTime = @ExecutionDateTime


----If it's Time, then we set this to all the tables in the original Q or we'll reach a point where we won't add anymore tables.
----If you've got say 1 table that is skipped it'll keep showing up again and again.  If you don't set this here, then it'll always be the 
----only one in the Q table so it'll just get skipped and the job will end w/o even trying more table.
----Here, we're ensuring that it goes into the proper branch below... the one that's not =.
IF @RotationLimiter = 'Time'
	BEGIN
		SET @RotationMetricValue = (SELECT COUNT(*) FROM #ThreadQTemp)
	END

--------------------------------------------------------
-------------END Delete Previous DBs--------------------
--------------------------------------------------------


	IF UPPER(@RotationLimiter) = 'TABLECOUNT' OR UPPER(@RotationLimiter) = 'TIME'
		----For DBCount, RotationPeriod doesn't mean anything.  This is the simplest, and most straightforward rotation.  It'll work through all the DBs no matter how long it takes.
		----Other rotations can be concerned with completing in a specific time, but not this one.
		BEGIN -- @RotationLimiter = 'DBCount'
			
			-------------------------------------------------------
			--------------BEGIN Restart Cycle----------------------
			-------------------------------------------------------
			
			----If the cycle has completed, or will complete during this run then we'll need to know that here and manage the list such that it starts the list over again.
			----There are 2 scenarios.  1. the cycle finished completely in the last run and needs to be completely restarted. 2. It partially completed and now we're going to finish
			----the current loop and add some DBs from the previous loop.  So this is the partial restart.

			------------------------------------------------
			------------------------------------------------
			-------------BEGIN Full Restart-----------------
			------------------------------------------------
			------------------------------------------------
			--This will only happen with an even number of DBs.  Say you've got a 100 and you're doing 10 every day. Most of the time, this won't be relevant.
			IF @RotationTablesCT = @ThreadQueueCT
				BEGIN
					--So here we're starting the rotation over.  We don't have to worry about RotationDBs being populated right now cause that'll get done next time the routine runs.
					--Instead of truncating the table, maybe get the current list and 
					--put the in a #table and then truncate, and put those few back.
					--the problem is that in the previous run when we rolled over to the top 
					--of the list, we didn't preserve them and we need to in order to keep from
					--duplicating a few DBs over and over.
					
					TRUNCATE TABLE Minion.CheckDBRotationTables;

					INSERT Minion.CheckDBRotationTables(ExecutionDateTime, DBName, SchemaName, TableName, OpName)
					SELECT ExecutionDateTime, DBName, SchemaName, TableName, OpName
					FROM Minion.CheckDBRotationTablesReload
					----WHERE IsTail = 0;

					TRUNCATE TABLE Minion.CheckDBRotationTablesReload;
					--This tells us that it's a full reload and it shouldn't fill the Reload table in the next step.
					SET @IsFullReload = 1;
					SET @PerformFullReloadDelete = 1;
				END
			------------------------------------------------
			------------------------------------------------
			-------------END Full Restart-------------------
			------------------------------------------------
			------------------------------------------------


			------------------------------------------------
			------------------------------------------------
			-------------BEGIN Partial Restart--------------
			------------------------------------------------
			------------------------------------------------
			--This is a partial restart. We want to do, say 10, DBs/night. But we've only got say 7 left in the current rotation.
			--So here we've got to do those 7, but then add the other 3 back to the end of the list so we can start over with the rotation.
			IF (@ThreadQueueCT - @RotationTablesCT) < @RotationMetricValue
				BEGIN
					--Delete ThreadQ rows that already exist in the RotationDBs table.
					DELETE TQ
					FROM Minion.CheckDBCheckTableThreadQueue TQ
					INNER JOIN Minion.CheckDBRotationTables CR
					ON CR.DBName = TQ.DBName AND CR.SchemaName = TQ.SchemaName AND CR.TableName = TQ.TableName
					WHERE TQ.ExecutionDateTime = @ExecutionDateTime;

					--Now force the order so we can make sure that the ones from the previous round get run before the ones that are coming in as the new round.
					--So we're getting the highest GroupOrder and just adding 1 to it.
					UPDATE Minion.CheckDBCheckTableThreadQueue
					SET GroupOrder = (SELECT MAX(GroupOrder) + 1 FROM #CheckTableThreadQTemp)

					----If we put all the rows back in from the #Q table then we can delete the ones we don't need in the final step below.
					----The only thing we need here is to renumber them so that we make sure we pick the proper ones.
					----We have to reset the numbers to ensure that we keep the ones that haven't processed yet on the top so they'll process before the 
					----ones that have beed added back do.
					INSERT Minion.CheckDBCheckTableThreadQueue
					        (ExecutionDateTime, DBName, SchemaName, TableName, IndexName, Exclude, GroupOrder, GroupDBOrder, NoIndex, RepairOption, RepairOptionAgree, AllErrorMsgs, ExtendedLogicalChecks, NoInfoMsgs, IsTabLock, ResultMode, IntegrityCheckLevel, HistRetDays, TablePreCode, TablePostCode, PreferredServer, Processing, ProcessingThread)
					SELECT   ExecutionDateTime, DBName, SchemaName, TableName, IndexName, Exclude, GroupOrder, GroupDBOrder, NoIndex, RepairOption, RepairOptionAgree, AllErrorMsgs, ExtendedLogicalChecks, NoInfoMsgs, IsTabLock, ResultMode, IntegrityCheckLevel, HistRetDays, TablePreCode, TablePostCode, PreferredServer, Processing, ProcessingThread
					FROM #CheckTableThreadQTemp
					ORDER BY GroupOrder DESC, GroupDBOrder DESC

					----Remove dupes
					;WITH cteThreadQTables (RowNum, ID, ExecutionDateTime, DBName, SchemaName, TableName, CheckDBGroupOrder)
					AS
					(
					SELECT --use the row_number function to get the newest record
						ROW_NUMBER() OVER(PARTITION BY DBName, SchemaName, TableName ORDER BY GroupOrder DESC) AS RowNum, 
						ID,ExecutionDateTime, DBName, SchemaName, TableName, GroupOrder
					FROM Minion.CheckDBCheckTableThreadQueue
					WHERE ExecutionDateTime = @ExecutionDateTime

					)

					DELETE Minion.CheckDBCheckTableThreadQueue
					WHERE ID IN
					(SELECT ID FROM cteThreadQTables
					WHERE RowNum > 1);

					--Save the current run so it's available for the next round since we've truncated the RotationDBs table.
					IF @IsFullReload = 0
						BEGIN
							INSERT Minion.CheckDBRotationTablesReload (ExecutionDateTime, DBName, SchemaName, TableName, OpName)
							SELECT ExecutionDateTime, DBName, SchemaName, TableName, @OpName
							FROM Minion.CheckDBCheckTableThreadQueue
							WHERE DBName IN (SELECT TOP (@RotationMetricValue) DBName FROM Minion.CheckDBCheckTableThreadQueue WHERE ExecutionDateTime = @ExecutionDateTime ORDER BY GroupOrder DESC, GroupDBOrder DESC)
							AND ExecutionDateTime = @ExecutionDateTime
							
							--We're only going to mark the end of the cycle.  We need to know where the last DBs in the final cycle
							--are because if we don't delete them then they won't be part of this cycle.
							SET @TableCT = (@ThreadQueueCT - @RotationTablesCT);
							
							IF (@ThreadQueueCT - @RotationTablesCT) < 0
								BEGIN
									SET @TableCT = @ThreadQueueCT;
								END
							UPDATE Minion.CheckDBRotationTablesReload
							SET IsTail = 1
							WHERE DBName IN (SELECT TOP (@TableCT) DBName FROM Minion.CheckDBRotationTablesReload ORDER BY ID DESC)

							UPDATE Minion.CheckDBRotationTablesReload
							SET IsTail = 0
							WHERE IsTail IS NULL;
												
						END
				END

			------------------------------------------------
			------------------------------------------------
			-------------END Partial Restart----------------
			------------------------------------------------
			------------------------------------------------

			-------------------------------------------------------
			--------------END Restart Cycle------------------------
			-------------------------------------------------------

			----Delete all except the rows you want for this run from the ThreadQ table.
			----The number of rows in the ThreadQ should be @RotationMetricValue cause these are the rows to process.
			
			IF @PerformFullReloadDelete = 1
			BEGIN
			----Start by deleting the rows that are already in the RotationDBs table.
			----If we don't do this then we'll double-up during a partial restart.
			----This is only needed on the full reload run.
			----That's the one right after the partial reload has run.
				DELETE TQ
				FROM Minion.CheckDBCheckTableThreadQueue TQ
				INNER JOIN Minion.CheckDBRotationTables CR
				ON CR.DBName = TQ.DBName AND CR.SchemaName = TQ.SchemaName AND CR.TableName = TQ.TableName
				WHERE TQ.ExecutionDateTime = @ExecutionDateTime;
			END			

			IF UPPER(@RotationLimiter) = 'TABLECOUNT'
				BEGIN --DBC1
			----Now that the included rows are out of the ThreadQ, we can
			----limit it to the ones we're interested in.
			DELETE Q1
			FROM Minion.CheckDBCheckTableThreadQueue  AS Q1
			LEFT OUTER JOIN 
				(SELECT TOP (@RotationMetricValue) * 
				FROM Minion.CheckDBCheckTableThreadQueue
				WHERE ExecutionDateTime = @ExecutionDateTime  
				ORDER BY GroupOrder DESC, GroupDBOrder DESC) AS Q2
			ON Q1.DBName = Q2.DBName
			AND Q1.SchemaName = Q2.SchemaName
			AND Q1.TableName = Q2.TableName
			WHERE Q2.DBName IS NULL 
			AND Q2.SchemaName IS NULL 
			AND Q2.TableName IS NULL 
			AND Q1.ExecutionDateTime = @ExecutionDateTime;
			
				END --DBC1
		END -- @RotationLimiter = 'DBCount'

	END --CHECKTABLE

-------------------------------------------------------
-------------------------------------------------------
---------------END CheckTable--------------------------
-------------------------------------------------------
-------------------------------------------------------
GO
