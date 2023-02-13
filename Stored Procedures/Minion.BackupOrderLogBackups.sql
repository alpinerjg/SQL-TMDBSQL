SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [Minion].[BackupOrderLogBackups]
      @Comment VARCHAR(2000)
    , @IReadTheWarning BIT = 0
AS /*
	PURPOSE: 
	This is an SP to be used as precode, to reorder log backups based on log usage. 
	It looks at sqlperf(logspace); the DB that's the biggest and fullest can be backed up first. 
	(Other way to do it is iostats, but we'd have to keep a record.)

	USE: 
	This can be used as precode for log backups. 

	EFFECTS: 
	LOTS. To order individual log backups, we have to make sure that ALL databases have an entry
	in Minion.BackupSettings. So: 
		* Any database-specific row with BackupType=Log just gets ordered.
		* Any database-specific row with BackupType=All, but no BackupType=Log, gets a new row with BackupType=Log. 
		  (The settings for the new row are pulled from that DB-specific row, BackupType=All.)
		* Any database without a database-specific row, gets two new rows: one for BackupType=All, and one for All.
		  (The settings for the new row are pulled from MinionDefault/Log, if it exists, or MinionDefault/All otherwise.)
	
	Note that we deal exclusively with IsActive=1 rows. IsActive=0 rows are ignored entirely.

	PARAMETERS: 
		@Comment	Used as the value for the "Comment" field of new rows. This can be used as an
					identifier, so that postcode can turn off these rows (if desired).
					
					FUTURE FEATURE: This script should, in the future, check for existing, disabled rows with 
					the same @Comment value; if it finds them, it can turn them on.

		@IReadTheWarning	Used to keep people from messing up their Minion.BackupSettings scenarios. 
					WARNING: This procedure will completely alter your settings in Minion.BackupSettings. 
					It will add new rows, and change the GroupDBOrder column values, in order to order log backups.

	LIMITS: 
	I'm working on the EXCLUDE thing; if we have a database with Exclude=1, at THIS point the script 
	will actually add it back. Oops.

DISCUSSION:
	What this does for us: well, we get to load all of the entries for specific databases, specifically for
	log backups. And then we get to load in entries for specific databases, BackupType=ALL (where DBName 
	isn't already in the temp table). Then, everything else. 

	The "Everything else" settings have to be based on something, so we're going with MinionDefault/Log
	if it exists, or MinionDefault/All if it doesn't.


WALKTHROUGH:
	 0. Setup
	 1. DBNAME/LOG SETTINGS EXISTS: Read in all existing DBName/Log where IsActive=1.  
	 2. DBNAME/ALL SETTINGS EXIST: Read in all existing DBName/All where IsActive=1 AND not in DBName/Log 
	 3. ONLY MINIONDEFAULT EXISTS FOR DB: Read in all remaining DB names from sys.databases, with a specialized comment identifier.
	 4. Order them in the temp table.
	 5. DBNAME/LOG SETTINGS EXISTS: Update the table with the new ordering, for DB and log-specific rows.
	 6. DBNAME/ALL SETTINGS EXIST: Insert a row for DBs with existing BackupType='All':
	 7. ONLY MINIONDEFAULT EXISTS FOR DB: INSERT missing DB rows into the table. 
	 8. Cleanup and return.

EXAMPLE EXECUTION: 
	EXEC Minion.BackupOrderLogBackups @Comment = 'OrderLogBackups2016.';
	

*/

      BEGIN 

            IF @IReadTheWarning = 0
               BEGIN
                     ROLLBACK TRAN;
				
                     RAISERROR('You did not read the warning. The warning says that this procedure will completely alter your settings in Minion.BackupSettings (including adding new rows), so that it can order log backups.', 16, 1);
                
                     RETURN 1;
               END;


----------------------------------------------------
-- 0. Setup
            CREATE TABLE #tmp
                   (
                     DBName NVARCHAR(256)
                   , BackupType VARCHAR(20)
                   , Exclude BIT
                   , GroupDBOrder INT NULL
                   );

            CREATE TABLE #logspace
                   (
                     [DBName] NVARCHAR(256)
                   , [LogSizeMB] FLOAT
                   , [LogSpaceUsedPct] FLOAT
                   , [Status] INT
                   , [LogSpaceUsedMB] FLOAT
                   , GroupDBOrder INT NULL
                   );
----------------------------------------------------
-- 1. DBNAME/LOG SETTINGS EXISTS: Read in all existing DBName/Log where IsActive=1.  
---- If the DB already has a row for Log backups, no problem. We'll just use that & order it.
            INSERT  INTO #tmp
                    ( DBName
                    , BackupType
                    , Exclude
                    , GroupDBOrder
                    )
                    SELECT  DBName
                          , BackupType
                          , Exclude
                          , 0 AS GroupDBOrder
                    FROM    Minion.BackupSettings
                    WHERE   IsActive = 1
                            AND DBName <> 'MinionDefault'
                            AND BackupType = 'Log';

----------------------------------------------------
-- 2. DBNAME/ALL SETTINGS EXIST: Read in all existing DBName/All where IsActive=1 AND not in DBName/Log 
---- If the DBName has an All level, but not a Log level, we'll INSERT a Log row for it.
            INSERT  INTO #tmp
                    ( DBName
                    , BackupType
                    , Exclude
                    )
                    SELECT  S.DBName
                          , S.BackupType
                          , S.Exclude
                    FROM    Minion.BackupSettings AS S
                    LEFT OUTER JOIN #tmp AS t
                            ON t.DBName = S.DBName
                    WHERE   S.IsActive = 1
                            AND S.DBName <> 'MinionDefault'
                            AND S.BackupType = 'All'
                            AND t.DBName IS NULL;

----------------------------------------------------
-- 3. ONLY MINIONDEFAULT EXISTS FOR DB: Read in all remaining DB names from sys.databases, with a specialized comment identifier.
-- If the DB doesn't have DB-specific row, we have to insert both an All and a Log row for it.
            INSERT  INTO #tmp
                    ( DBName
                    , BackupType
                    , Exclude
                    )
                    SELECT  d.name AS DBName
                          , 'Log' AS BackupType
                          , NULL AS Exclude
                    FROM    sys.databases AS d
                    LEFT OUTER JOIN #tmp AS t
                            ON d.name = t.DBName
                    WHERE   d.name NOT IN ( 'MinionDefault', 'master', 'msdb',
                                            'tempdb', 'ReportServer',
                                            'ReportServerTempDB' )
                            AND t.DBName IS NULL;

----------------------------------------------------
-- 4. Order them in the temp table.

            INSERT  INTO #logspace
                    ( [DBName]
                    , LogSizeMB
                    , LogSpaceUsedPct
                    , Status
                    )
                    EXEC ( 'DBCC SQLPERF(logspace);'
                        );

            DELETE  FROM #logspace
            WHERE   DBName IN ( 'master', 'msdb', 'tempdb', 'ReportServer',
                                'ReportServerTempDB' );

            UPDATE  #logspace
            SET     LogSpaceUsedMB = LogSizeMB * LogSpaceUsedPct / 100.0;


-- IMPORTANT: Remember that in MB, ordering is weighted. Higher numbers go first. So, 
-- the DB with the highest space used (MB) should be taken care of first & have the highest order #.
            WITH    CTE
                      AS ( SELECT   DBName
                                  , LogSpaceUsedMB
                                  , ROW_NUMBER() OVER ( ORDER BY LogSpaceUsedMB ASC ) AS rownum
                           FROM     #logspace
                         )
                 UPDATE T
                 SET    T.GroupDBOrder = CTE.rownum
                 FROM   #tmp AS T
                 INNER JOIN CTE
                        ON T.DBName = CTE.DBName;

-- SELECT * FROM #logspace;
-- SELECT * FROM #tmp order by DBName;

----------------------------------------------------
-- 5. DBNAME/LOG SETTINGS EXISTS: Update the table with the new ordering, for DB and log-specific rows.
--- Nearly forgot: make sure every time we reference the settings table, we're only talking about IsActive=1 rows.
            UPDATE  S
            SET     S.GroupOrder = NULL
                  , S.GroupDBOrder = t.GroupDBOrder
            FROM    Minion.BackupSettings AS S
            INNER JOIN #tmp AS t
                    ON S.IsActive = 1
                       AND S.DBName = t.DBName
                       AND S.BackupType = t.BackupType
                       AND S.BackupType = 'Log';

		--SELECT * 
		--FROM    Minion.BackupSettings AS S
		--INNER JOIN #tmp AS t
		--        ON S.IsActive = 1
		--           AND S.DBName = t.DBName
		--           AND S.BackupType = t.BackupType
		--           AND S.BackupType = 'Log';

-- Remove any rows from #tmp that are already covered in the settings table (DB and log specific).
            DELETE  t
            FROM    #tmp AS t
            INNER JOIN Minion.BackupSettings AS S
                    ON S.IsActive = 1
                       AND S.DBName = t.DBName
                       AND S.BackupType = t.BackupType
                       AND S.BackupType = 'Log';

----------------------------------------------------
-- 6. DBNAME/ALL SETTINGS EXIST: Insert a row for DBs with existing BackupType='All':

            INSERT  INTO Minion.BackupSettings
                    ( DBName
                    , Port
                    , BackupType
                    , Exclude
                    , GroupOrder
                    , GroupDBOrder
                    , Mirror
                    , DelFileBefore
                    , DelFileBeforeAgree
                    , LogLoc
                    , HistRetDays
                    , MinionTriggerPath
                    , DBPreCode
                    , DBPostCode
                    , PushToMinion
                    , DynamicTuning
                    , Verify
                    , PreferredServer
                    , ShrinkLogOnLogBackup
                    , ShrinkLogThresholdInMB
                    , ShrinkLogSizeInMB
                    , MinSizeForDiffInGB
                    , DiffReplaceAction
                    , LogProgress
                    , FileAction
                    , FileActionTime
                    , Encrypt
                    , Name
                    , ExpireDateInHrs
                    , RetainDays
                    , Descr
                    , Checksum
                    , Init
                    , Format
                    , CopyOnly
                    , Skip
                    , BackupErrorMgmt
                    , MediaName
                    , MediaDescription
                    , IsActive
                    , Comment
                    )
                    SELECT  t.DBName AS DBName
                          , Port
                          , 'Log' AS BackupType
                          , 0 AS Exclude
                          , GroupOrder
                          , t.GroupDBOrder AS GroupDBOrder
                          , Mirror
                          , DelFileBefore
                          , DelFileBeforeAgree
                          , LogLoc
                          , HistRetDays
                          , MinionTriggerPath
                          , DBPreCode
                          , DBPostCode
                          , PushToMinion
                          , DynamicTuning
                          , Verify
                          , PreferredServer
                          , ShrinkLogOnLogBackup
                          , ShrinkLogThresholdInMB
                          , ShrinkLogSizeInMB
                          , MinSizeForDiffInGB
                          , DiffReplaceAction
                          , LogProgress
                          , FileAction
                          , FileActionTime
                          , Encrypt
                          , Name
                          , ExpireDateInHrs
                          , RetainDays
                          , Descr
                          , Checksum
                          , Init
                          , Format
                          , CopyOnly
                          , Skip
                          , BackupErrorMgmt
                          , MediaName
                          , MediaDescription
                          , IsActive
                          , @Comment AS Comment
                    FROM    Minion.BackupSettings AS S
                    INNER JOIN #tmp AS t
                            ON S.IsActive = 1
                               AND S.DBName = t.DBName
                               AND S.BackupType = 'All'
                               AND t.BackupType = 'All';

-- Remove any rows from #tmp that are already covered in the settings table (DB and NOW-log specific).
            DELETE  t
            FROM    #tmp AS t
            INNER JOIN Minion.BackupSettings AS S
                    ON S.IsActive = 1
                       AND S.DBName = t.DBName
                       AND S.BackupType = 'Log'
                       AND t.BackupType = 'All';

		--SELECT  *
		--FROM    #tmp AS t
		--INNER JOIN Minion.BackupSettings AS S
		--		ON S.IsActive = 1
		--		   AND S.DBName = t.DBName
		--		   AND S.BackupType = 'Log'
		--		   AND t.BackupType = 'All';
		
		
----------------------------------------------------
-- 7. ONLY MINIONDEFAULT EXISTS FOR DB: INSERT missing DB rows into the table. 
--	  NULL for precode/postcode when you insert new rows. BUT, use MB/Log when available; MB/all if not.


            DECLARE @BackupType VARCHAR(10);
            IF EXISTS ( SELECT  *
                        FROM    Minion.BackupSettings
                        WHERE   IsActive = 1
                                AND DBName = 'MinionDefault'
                                AND BackupType = 'Log' )
               SET @BackupType = 'Log';
            ELSE
               SET @BackupType = 'All';

-- First, I need a DBName/ALL row in. We'll get the settings from MinionDefault/All.
            INSERT  INTO Minion.BackupSettings
                    ( DBName
                    , Port
                    , BackupType
                    , Exclude
                    , GroupOrder
                    , GroupDBOrder
                    , Mirror
                    , DelFileBefore
                    , DelFileBeforeAgree
                    , LogLoc
                    , HistRetDays
                    , MinionTriggerPath
                    , DBPreCode
                    , DBPostCode
                    , PushToMinion
                    , DynamicTuning
                    , Verify
                    , PreferredServer
                    , ShrinkLogOnLogBackup
                    , ShrinkLogThresholdInMB
                    , ShrinkLogSizeInMB
                    , MinSizeForDiffInGB
                    , DiffReplaceAction
                    , LogProgress
                    , FileAction
                    , FileActionTime
                    , Encrypt
                    , Name
                    , ExpireDateInHrs
                    , RetainDays
                    , Descr
                    , Checksum
                    , Init
                    , Format
                    , CopyOnly
                    , Skip
                    , BackupErrorMgmt
                    , MediaName
                    , MediaDescription
                    , IsActive
                    , Comment
                    )
                    SELECT  t.DBName AS DBName
                          , S.Port
                          , 'All' AS BackupType
                          , 0 AS Exclude
                          , S.GroupOrder
                          , S.GroupDBOrder -- Don't get groupDB order for the new All row. The intent is to leave the non-Log backups alone.
                          , S.Mirror
                          , S.DelFileBefore
                          , S.DelFileBeforeAgree
                          , S.LogLoc
                          , S.HistRetDays
                          , S.MinionTriggerPath
                          , S.DBPreCode
                          , S.DBPostCode
                          , S.PushToMinion
                          , S.DynamicTuning
                          , S.Verify
                          , S.PreferredServer
                          , S.ShrinkLogOnLogBackup
                          , S.ShrinkLogThresholdInMB
                          , S.ShrinkLogSizeInMB
                          , S.MinSizeForDiffInGB
                          , S.DiffReplaceAction
                          , S.LogProgress
                          , S.FileAction
                          , S.FileActionTime
                          , S.Encrypt
                          , S.Name
                          , S.ExpireDateInHrs
                          , S.RetainDays
                          , S.Descr
                          , S.Checksum
                          , S.Init
                          , S.Format
                          , S.CopyOnly
                          , S.Skip
                          , S.BackupErrorMgmt
                          , S.MediaName
                          , S.MediaDescription
                          , S.IsActive
                          , @Comment AS Comment
                    FROM    Minion.BackupSettings AS S
                    CROSS JOIN #tmp AS t
                    WHERE   S.IsActive = 1
                            AND S.DBName = 'MinionDefault'
                            AND S.BackupType = 'All';

-- Second, I need a DBName/LOG row in. We'll get the settings from MinionDefault/Log, if there is one. (Else, Log.)
            INSERT  INTO Minion.BackupSettings
                    ( DBName
                    , Port
                    , BackupType
                    , Exclude
                    , GroupOrder
                    , GroupDBOrder
                    , Mirror
                    , DelFileBefore
                    , DelFileBeforeAgree
                    , LogLoc
                    , HistRetDays
                    , MinionTriggerPath
                    , DBPreCode
                    , DBPostCode
                    , PushToMinion
                    , DynamicTuning
                    , Verify
                    , PreferredServer
                    , ShrinkLogOnLogBackup
                    , ShrinkLogThresholdInMB
                    , ShrinkLogSizeInMB
                    , MinSizeForDiffInGB
                    , DiffReplaceAction
                    , LogProgress
                    , FileAction
                    , FileActionTime
                    , Encrypt
                    , Name
                    , ExpireDateInHrs
                    , RetainDays
                    , Descr
                    , Checksum
                    , Init
                    , Format
                    , CopyOnly
                    , Skip
                    , BackupErrorMgmt
                    , MediaName
                    , MediaDescription
                    , IsActive
                    , Comment
                    )
                    SELECT  t.DBName AS DBName
                          , S.Port
                          , 'Log' AS BackupType
                          , 0 AS Exclude
                          , GroupOrder
                          , t.GroupDBOrder AS GroupDBOrder
                          , S.Mirror
                          , S.DelFileBefore
                          , S.DelFileBeforeAgree
                          , S.LogLoc
                          , S.HistRetDays
                          , S.MinionTriggerPath
                          , S.DBPreCode
                          , S.DBPostCode
                          , S.PushToMinion
                          , S.DynamicTuning
                          , S.Verify
                          , S.PreferredServer
                          , S.ShrinkLogOnLogBackup
                          , S.ShrinkLogThresholdInMB
                          , S.ShrinkLogSizeInMB
                          , S.MinSizeForDiffInGB
                          , S.DiffReplaceAction
                          , S.LogProgress
                          , S.FileAction
                          , S.FileActionTime
                          , S.Encrypt
                          , S.Name
                          , S.ExpireDateInHrs
                          , S.RetainDays
                          , S.Descr
                          , S.Checksum
                          , S.Init
                          , S.Format
                          , S.CopyOnly
                          , S.Skip
                          , S.BackupErrorMgmt
                          , S.MediaName
                          , S.MediaDescription
                          , S.IsActive
                          , @Comment AS Comment
                    FROM    Minion.BackupSettings AS S
                    CROSS JOIN #tmp AS t
                    WHERE   S.IsActive = 1
                            AND S.DBName = 'MinionDefault'
                            AND S.BackupType = @BackupType;

----------------------------------------------------
-- 8. Cleanup and return.
            DROP TABLE #tmp;
            DROP TABLE #logspace;

            SELECT  *
            FROM    Minion.BackupSettings
            WHERE   IsActive = 1
                    AND BackupType = 'Log'
            ORDER BY GroupDBOrder DESC
                  , DBName
                  , BackupType;

      END;


GO
