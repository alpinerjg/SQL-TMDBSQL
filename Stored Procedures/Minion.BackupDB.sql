SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[BackupDB]
    (
     @DBName NVARCHAR(400),
     @BackupType VARCHAR(20),
     @StmtOnly BIT = 0,
     @ExecutionDateTime DATETIME = NULL,
	 @Debug BIT = 0
)
/***********************************************************************************
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
--------------------Minion Backup------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
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

--Purpose: This SP creates and runs performs a backup (or if @StmtOnly=1, provides the backup statement) 
--		 for a single database, based on the settings configured in Minion.BackupSettings.

--		 IMPORTANT: We HIGHLY recommend using Minion.BackupMaster for all of your backup operations, 
--		 even when backing up a single database.  Do not call Minion.BackupDB to perform backups. The 
--		 Minion.BackupMaster procedure makes all the decisions on which databases to back up, and what 
--		 order they should be in.  It’s certainly possible to call Minion.BackupDB manually, to back up
--		 an individual database, but we instead recommend using the Minion.BackupMaster procedure (and 
--		 just include the single database using the @Include parameter).  
		
--Features:
--	*  EXTENSIVE logging.
--	*  Backup full, diff, or log.
--	*  Choose to only generate backup statements.
--	*  Also backup TDE certificate, if that is configured in the Minion.BackupSettings table. 
--	*  Back up according to the appropriate backup tuning settings. (This is based on variations 
--	   of database size. Run Minion.Help 'How to: Set up dynamic backup tuning thresholds' for 
--	   more information.)
--	* [] Takes full backup of Availability Group scenarios. For example, you can choose which replica 
--	   to back up on by backup type. For more information, [] 
--	*  Configure Minion Backup NOT to take differential backups if the database is below a certain size.
--	*  Minion Backup provides the option of running code before and/or after backups, using DBPrecode and 
--	   DBPostcode in Minion.BackupSettings.
--	* Verifies (or, if not exists, creates) backup paths.
--	* Deletes old backup files based on retention settings. []
--	* Backup monitor. []
--	* Choose to shrink the log after backups. []

--Limitations:
--	*  ___

--Notes:
--	* ___


--Walkthrough: 
--	1. Initial steps, data gathering: 
--			Get Version Info
--			ServerLabel
--			Get Misc Settings (Tuning settings, Backup settings)
--			Get AG info	[commented out; needs work]
--			DBSize	
--			MIN Diff Size	
--			PRE Log Info	
--			VLFs	
--			Dynamic Log Tuning	
--			Backup CMD		
--			Set New Backup Type	
--	2. DBPrecode
--	3. Cleanup and preparation: 
--			Delete History
--			Initial Log to Minion.BackupLogDetails (plus Catch-up on Errors)
--			DB Selection	[extraneous code]
--			Create directories (Create paths)
--			Delete Files Before 
--			Prebackup log
--	4. Backup DB
--	5. Post-backup operations:
--			Postbackup log
--			Turn off monitor
--			Shrink log
--				Post sqlperf
--				log shrink info
--			Delete old files
--			Log delete old files
--			Log file info
--	6. Cert backup
--	7. DBPostCode
--	8. Post operations logging and cleanup
--			

--			Totalsize
--			BackupLoggingPath
--			PreTrigger Log
--			PostTrigger Log
--			Compression Stats
--			Backup Complete Log
--			File Action
--			Final log

--Conventions:


--Parameters:
-------------

--	@DBName	- Database name to be backed up. We back up a single DB at a time.

--	@BackupType - Full, Diff, or Log. 
	
--	@StmtOnly - Valid options: 1, 0. Only prints backup statements.  Excellent 
--	choice for running statements manually.  Allows you to pick and choose which 
--	backups you want to do or just see how many are over the thresholds.
    
--	@ExecutionDateTime - The date and time the backup ran; if this SP was called
--	by Minion.BackupMaster, @ExecutionDateTime will be passed in, so this 
--	backup is included as part of the entire (multi-database) backup operation.

--Tables:
-------------
--	#DirExist			Temp table used to hold info returned from xp_fileexist. 
--						The DirExist col is really the only important one. If it is '0' 
--						then the dir does not exist, and it will be created.
--	#BackupFiles		Temp table for holding the list of files in the current DB folder. 
--						This is used to parse the date and get the oldest files. Once 
--						obtained, the oldest files will be deleted from disk.						  
--	#BackupProcess		Temp table that holds all files from #BackupFiles with the dates 
--						parsed. The actual deletes are done from this table.  
   

--Example Execution:
--	-- Take a full backup of the master database.
--	EXEC [Minion].[BackupDB] 'master', 'full', 0;

--	-- Genearate a log backup statement for the ReportServer database.
--	EXEC [Minion].[BackupDB] 'ReportServer', 'Log', 1;


--Revision History:
----To get current version exec [spFullBackupAllUserDBs] @version= 'Version'
--Verify- NONE|Now|Delay

--***********************************************************************************/
AS
    SET NOCOUNT ON
    SET ANSI_WARNINGS OFF


    BEGIN 

        DECLARE
            @BackupStartDateTime DATETIME,
            @BackupEndDateTime DATETIME,
            @HistRetDays INT,
            @BasePath VARCHAR(MAX),
            @MirrorPath VARCHAR(MAX),
            @MirrorBackup BIT,
            @Buffercount VARCHAR(50),
            @NumberOfFiles TINYINT,
            @MaxTransferSize VARCHAR(50),
            @Compression BIT,
            @BackupCmd VARCHAR(MAX),
            @DeleteFilesBefore BIT,
            @DeleteFilesBeforeAgree BIT,
            @BackupError VARCHAR(5),
            @ErrorMessage VARCHAR(2000),
            @ErrorNumber VARCHAR(10),
            @ErrorSeverity VARCHAR(10),
            @ErrorState VARCHAR(5),
            @BackupLogging VARCHAR(25),
            @BackupLoggingRetDays SMALLINT,
            @ServerLabel sysname,
            @NETBIOSName VARCHAR(128),
            @DBPreCode NVARCHAR(MAX),
            @DBPostCode NVARCHAR(MAX),
            @DBPreCodeStartDateTime DATETIME,
            @DBPreCodeEndDateTime DATETIME,
            @DBPostCodeStartDateTime DATETIME,
            @DBPostCodeEndDateTime DATETIME,
            @DBPreCodeRunTimeInSecs INT,
            @DBPostCodeRunTimeInSecs INT,
            @LogDBType VARCHAR(6),
            @Retention TINYINT,
            @PrevFullPath VARCHAR(100),
            @PrevFullDate DATETIME,
            @TriggerFile VARCHAR(2000),
            @BackupLoggingPath VARCHAR(1000),
            @CurrentLog INT,
            @SettingLevel TINYINT,
            @Folder VARCHAR(5000),
            @MirrorFolder VARCHAR(5000),
            @UnCompressedBackupSizeMB FLOAT,
            @CompressedBackupSizeMB FLOAT,
            @CompressionRatio FLOAT,
            @COMPRESSIONPct NUMERIC(20, 1),
            @BackupRetHrs TINYINT,
            @FileExistCMD NVARCHAR(4000),
            @DynamicTuning BIT,
            @TuningSettingLevel TINYINT,
            @Verify VARCHAR(20),
            @FileList VARCHAR(MAX),
            @TuningTypeLevel TINYINT,
            @ShrinkLogOnLogBackup BIT,
            @ShrinkLogThresholdInMB INT,
            @ShrinkLogSizeInMB INT,
            @FullPath VARCHAR(2000),
            @IsPrimaryReplica BIT,
           -- @IsInAG BIT,
            @IsTDE BIT,
			@BackupCert BIT,
            @Version VARCHAR(50),
			@VersionMinor varchar(50),
            @Edition VARCHAR(15),
            @OnlineEdition BIT,
            @IsClustered BIT,
            @FullFileName VARCHAR(1000),
            @DateLogic VARCHAR(100),
            @Extension VARCHAR(5),
            @CertPword VARCHAR(4000),
            @EncryptBackup BIT,
            @BackupName VARCHAR(128),
            @ExpireDateInHrs INT,
            @Descr VARCHAR(255),
            @RetainDays INT,
            @IsChecksum BIT,
			@BlockSize BIGINT,
            @IsInit BIT,
            @IsFormat BIT,
            @IsCopyOnly BIT,
            @IsSkip BIT,
            @BackupErrorMgmt VARCHAR(50),
            @MediaName VARCHAR(128),
            @MediaDescription VARCHAR(255),
            @BackupLocType VARCHAR(20),
            @MirrorRetHrs INT,
            @FileRetHrs INT,
            @FileAction VARCHAR(20),
            @FileActionTime VARCHAR(25),
            @Status VARCHAR(MAX),
            @VLFs BIGINT,
			@VLFStmt NVARCHAR(500),
            @Port VARCHAR(10),
            @BackupFilesDeleteStartDateTime DATETIME,
            @BackupFilesDeleteEndDateTime DATETIME,
            @BackupFilesDeleteTimeInSecs INT,
            @NewBackupType VARCHAR(4),
            @MinSizeForDiffInGB BIGINT,
            @DiffReplaceAction VARCHAR(4),
            @DBSize DECIMAL(18, 2),
            @BackupLogDetailsID BIGINT,
			@BackupEncryptionCertName VARCHAR(100),
			@EncrAlgorithm VARCHAR(20),
			@BackupEncryptionCertThumbPrint VARBINARY(32),
			@MaintDB VARCHAR(150),
            @PreCMD VARCHAR(100),
            @TotalCMD VARCHAR(8000),
            @ServerInstance VARCHAR(200),
			@SyncLogs BIT,
			@MBPerSec VARCHAR(20),
			@BackupTypeORIG VARCHAR(20),
			@MEServer VARCHAR(400);
                    
       
	    IF @ExecutionDateTime IS NULL
            BEGIN
                SET @ExecutionDateTime = GETDATE();
            END

SET @MaintDB = DB_NAME();
SET @ServerInstance = @@ServerName;

--We need to track this because as of 1.3 we can pass in a CHECKDB type right after, it'll be changed to FULL.
SET @BackupTypeORIG = @BackupType;
-------------------------------------------------------------------------
-------------------BEGIN Initial Log Record------------------------------
-------------------------------------------------------------------------
--It could have already been created in the Master SP so we have to check
--If there's a record already in there.

If @StmtOnly = 0
BEGIN --@StmtOnly = 0
        IF (
            SELECT
                    ExecutionDateTime
                FROM
                    Minion.BackupLogDetails
                WHERE
                    ExecutionDateTime = @ExecutionDateTime
                    AND DBName = @DBName
                    AND BackupType = @BackupType
           ) IS NULL
            BEGIN
                INSERT Minion.BackupLogDetails
                        (
                         ExecutionDateTime,
                         DBName,
                         BackupType
                        )
                    SELECT
                            @ExecutionDateTime,
                            @DBName,
                            @BackupType     
            END

-----Get the log record we just created, or the one that was created in the Master SP.
        SET @BackupLogDetailsID = (
                                   SELECT ID
                                    FROM  Minion.BackupLogDetails
                                    WHERE
                                        ExecutionDateTime = @ExecutionDateTime
                                        AND DBName = @DBName
                                        AND BackupType = @BackupType
                                  ) 
		   
----Update the BackupLog table for top-level logging.
        UPDATE
                Minion.BackupLog
            SET
                STATUS = 'Processing ' + @DBName
            WHERE
                ExecutionDateTime = @ExecutionDateTime
                AND BackupType = @BackupType;
END --@StmtOnly = 0					    
-------------------------------------------------------------------------
-------------------END Initial Log Record--------------------------------
-------------------------------------------------------------------------

------------------------BEGIN Set DBType---------------------------------
        IF @DBName IN ('master', 'msdb', 'model', 'distribution')
            SET @LogDBType = 'System'

        IF @DBName NOT IN ('master', 'msdb', 'model', 'distribution')
            SET @LogDBType = 'User'
------------------------END Set DBType-----------------------------------



-------------------------------------------------------------------------------
---------------- BEGIN Get Version Info----------------------------------------
-------------------------------------------------------------------------------
--Major Version
        SELECT
                @Version = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(15)), CHARINDEX('.', CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(15)), 1) - 1)
--Edition
        SELECT
                @Edition = CAST(SERVERPROPERTY('Edition') AS VARCHAR(25));

        IF @Edition LIKE '%Enterprise%'
            OR @Edition LIKE '%Developer%'
            BEGIN
                SET @OnlineEdition = 1
            END
--Online or not	
        IF @Edition NOT LIKE '%Enterprise%'
            AND @Edition NOT LIKE '%Developer%'
            BEGIN
                SET @OnlineEdition = 0
            END	

--Minor Version
       SELECT @VersionMinor = CAST(SERVERPROPERTY('ProductVersion') AS varchar(20))

            DECLARE @VersionMinorTable TABLE ( ID tinyint identity(1,1), VersionPart VARCHAR(10) );
            DECLARE @VersionMinorString VARCHAR(500);
            WHILE LEN(@VersionMinor) > 0 
                BEGIN
                    SET @VersionMinorString = LEFT(@VersionMinor, ISNULL(NULLIF(CHARINDEX('.', @VersionMinor) - 1, -1), LEN(@VersionMinor)))
                    SET @VersionMinor = SUBSTRING(@VersionMinor, ISNULL(NULLIF(CHARINDEX('.', @VersionMinor), 0), LEN(@VersionMinor)) + 1, LEN(@VersionMinor))

                    INSERT  INTO @VersionMinorTable
                            ( VersionPart )
                    VALUES  ( @VersionMinorString )
                END  

SET @VersionMinor = NULL;
SET @VersionMinor = (SELECT VersionPart from @VersionMinorTable WHERE ID = 3)

---------------------------------------------------------------------------------
------------------ END Get Version Info------------------------------------------
---------------------------------------------------------------------------------


----------------------------------------------------------------------------
----------------------BEGIN ServerLabel--------------------------------------
----------------------------------------------------------------------------

        IF @ServerLabel IS NULL
            BEGIN
                SET @ServerLabel = @@ServerName;
            END

        SET @NETBIOSName = CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS VARCHAR(128))
        SET @IsClustered = CAST(SERVERPROPERTY('IsClustered') AS VARCHAR(128))

--------------------------------------------------------------------------
--------------------END ServerLabel---------------------------------------
--------------------------------------------------------------------------

--------------------------------------------------------------------------
---------------------BEGIN Get Misc Settings------------------------------
--------------------------------------------------------------------------



----------------------------------------------------------------------------------------
------------------------------BEGIN Backup Settings-------------------------------------
----------------------------------------------------------------------------------------
        CREATE TABLE #BackupSettingsBackupDB
            (
             DynamicTuning BIT,
             Port INT,
             BackupType VARCHAR(20),
             RetHrs INT NULL,
             LogLoc VARCHAR(25) COLLATE DATABASE_DEFAULT NULL,
             DelFileBefore BIT NULL,
			 DelFileBeforeAgree BIT NULL,
             HistRetDays SMALLINT NULL,
             Verify VARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
             ShrinkLogOnLogBackup BIT NULL,
             ShrinkLogThresholdInMB INT NULL,
             ShrinkLogSizeInMB INT NULL,
             DBPreCode VARCHAR(MAX) COLLATE DATABASE_DEFAULT,
             DBPostCode VARCHAR(MAX) COLLATE DATABASE_DEFAULT,
             RetDays INT,
             MirrorBackup BIT,
             MinionTriggerPath VARCHAR(1000) COLLATE DATABASE_DEFAULT,
             FileAction VARCHAR(10) COLLATE DATABASE_DEFAULT,
             FileActionTime VARCHAR(25) COLLATE DATABASE_DEFAULT,
             MinSizeForDiffInGB BIGINT,
             DiffReplaceAction VARCHAR(4) COLLATE DATABASE_DEFAULT
            ) 

----Find out if the settings will come from the DB level or from the default level.
        SET @SettingLevel = (
                             SELECT COUNT(*)
                                FROM
                                    Minion.BackupSettings
                                WHERE
                                    DBName = @DBName
                                    AND IsActive = 1
                            )


        IF @SettingLevel > 0
            BEGIN
		
                INSERT #BackupSettingsBackupDB
                        (
                         DynamicTuning,
                         Port,
                         BackupType,
                         LogLoc,
                         DelFileBefore,
						 DelFileBeforeAgree,
                         HistRetDays,
                         Verify,
                         ShrinkLogOnLogBackup,
                         ShrinkLogThresholdInMB,
                         ShrinkLogSizeInMB,
                         DBPreCode,
                         DBPostCode,
                         MirrorBackup,
						 MinionTriggerPath,
                         FileAction,
                         FileActionTime,
                         MinSizeForDiffInGB,
                         DiffReplaceAction
						)
                    SELECT
                            DynamicTuning,
                            Port,
                            BackupType,
                            LogLoc,
                            DelFileBefore,
							DelFileBeforeAgree,
                            HistRetDays,
                            Verify,
                            ShrinkLogOnLogBackup,
                            ShrinkLogThresholdInMB,
                            ShrinkLogSizeInMB,
                            DBPreCode,
                            DBPostCode,
                            Mirror,
							MinionTriggerPath,
                            FileAction,
                            FileActionTime,
                            MinSizeForDiffInGB,
                            DiffReplaceAction
                        FROM
                            Minion.BackupSettings
                        WHERE
                            DBName = @DBName
                            AND 
                                (BackupType LIKE @BackupType
                                 OR BackupType = 'All')                               
                            AND IsActive = 1
		----------------------	  

            END
        IF @SettingLevel = 0
            BEGIN
                INSERT #BackupSettingsBackupDB
                        (
                         DynamicTuning,
                         Port,
                         BackupType,
                         LogLoc,
                         DelFileBefore,
						 DelFileBeforeAgree,
                         HistRetDays,
                         Verify,
                         ShrinkLogOnLogBackup,
                         ShrinkLogThresholdInMB,
                         ShrinkLogSizeInMB,
                         DBPreCode,
                         DBPostCode,
                         MirrorBackup,
						 MinionTriggerPath,
                         FileAction,
                         FileActionTime,
                         MinSizeForDiffInGB,
                         DiffReplaceAction
						)
                    SELECT
                            DynamicTuning,
                            Port,
                            BackupType,
                            LogLoc,
                            DelFileBefore,
							DelFileBeforeAgree,
                            HistRetDays,
                            Verify,
                            ShrinkLogOnLogBackup,
                            ShrinkLogThresholdInMB,
                            ShrinkLogSizeInMB,
                            DBPreCode,
                            DBPostCode,
                            Mirror,
							MinionTriggerPath,
                            FileAction,
                            FileActionTime,
                            MinSizeForDiffInGB,
                            DiffReplaceAction
                        FROM
                            Minion.BackupSettings
                        WHERE
                            DBName = 'MinionDefault'
                            AND 
                                 (BackupType = @BackupType
                                 OR BackupType = 'All')                              
                            AND IsActive = 1
            END

--SELECT @DBName, @BackupType, '#BackupSettingsBackupDB2', * FROM #BackupSettingsBackupDB
----We've filled #BackupSettingsBackupDB with all of the settings and now
----we delete the ones we don't need.

        IF (
            SELECT COUNT(*)
                FROM #BackupSettingsBackupDB
                WHERE
                    BackupType = @BackupType
           ) > 0
            BEGIN
                DELETE #BackupSettingsBackupDB
                    WHERE
                        BackupType <> @BackupType
            END

        IF (
            SELECT COUNT(*)
                FROM #BackupSettingsBackupDB
                WHERE
                    BackupType = @BackupType
           ) = 0
            BEGIN
                DELETE #BackupSettingsBackupDB
                    WHERE
                        BackupType <> 'All'
            END


        SELECT
                @DynamicTuning = DynamicTuning,
                @Port = Port,
                @FileRetHrs = RetHrs,
                @BackupLogging = LogLoc,
                @DeleteFilesBefore = DelFileBefore,
				@DeleteFilesBeforeAgree = DelFileBeforeAgree,
                @BackupLoggingRetDays = HistRetDays,
                @Verify = Verify,
                @ShrinkLogOnLogBackup = ShrinkLogOnLogBackup,
                @ShrinkLogThresholdInMB = ShrinkLogThresholdInMB,
                @ShrinkLogSizeInMB = ShrinkLogSizeInMB,
                @DBPreCode = DBPreCode,
                @DBPostCode = DBPostCode,
                @HistRetDays = HistRetDays,
                @BackupRetHrs = RetDays,
                @MirrorBackup = MirrorBackup,
                @BackupLoggingPath = MinionTriggerPath,
                @FileAction = FileAction,
                @FileActionTime = FileActionTime,
                @MinSizeForDiffInGB = MinSizeForDiffInGB,
                @DiffReplaceAction = DiffReplaceAction
            FROM
                #BackupSettingsBackupDB 


IF UPPER(@BackupType) = 'CHECKDB'
	BEGIN
		SET @BackupType = 'Full';
	END

If @StmtOnly = 0
	BEGIN
        CREATE TABLE #DeleteResults
            (
                ID INT IDENTITY(1, 1),
                col1 VARCHAR(MAX) COLLATE DATABASE_DEFAULT
            )

        CREATE TABLE #LogShrinkResults
            (
                ID INT IDENTITY(1, 1),
                col1 VARCHAR(MAX) COLLATE DATABASE_DEFAULT
            )

	END
----------------------------------------------------------------------------------------
------------------------------END Backup Settings---------------------------------------
----------------------------------------------------------------------------------------
 




---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
-------------------------------------------BEGIN DBPreCode-----------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------	

        IF @StmtOnly = 0
            BEGIN -- @StmtOnly = 0

-----BEGIN Log------

                IF @DBPreCode IS NOT NULL
                    BEGIN -- @DBPreCode
                        IF @StmtOnly = 0
                            BEGIN -- @StmtOnly = 0
                                SET @DBPreCodeStartDateTime = GETDATE();

                                BEGIN
                                    UPDATE Minion.BackupLogDetails
                                        SET
                                            STATUS = 'Precode running',
                                            DBPreCodeStartDateTime = @DBPreCodeStartDateTime,
                                            DBPreCode = @DBPreCode
                                        WHERE
                                            ID = @BackupLogDetailsID;
                                END
                            END -- @StmtOnly = 0
                    END -- @@DBPreCode
------END Log-------

                IF @DBPreCode IS NOT NULL
                    BEGIN -- @DBPreCode
-----------------BEGIN Log DBPreCode------------------
                        UPDATE Minion.BackupLogDetails
                            SET
                                DBPostCode = @DBPostCode,
                                DBPostCodeStartDateTime = @DBPostCodeStartDateTime
                            WHERE
                                ID = @BackupLogDetailsID;
-----------------END Log DBPreCode--------------------

--------------------------------------------------
----------------BEGIN Run Precode-----------------
--------------------------------------------------
                        DECLARE
                            @PreCodeErrors VARCHAR(MAX),
                            @PreCodeErrorExist VARCHAR(MAX);
                        CREATE TABLE #PreCode
                            (
                             ID INT IDENTITY(1, 1),
                             col1 VARCHAR(MAX)
                            )

                        BEGIN TRY
                            EXEC (@DBPreCode) 
                        END TRY

                        BEGIN CATCH
                            SET @PreCodeErrors = ERROR_MESSAGE();
                        END CATCH

                        IF @PreCodeErrors IS NOT NULL
                            BEGIN
                                SELECT @PreCodeErrors = 'PRECODE ERROR: '
                                        + @PreCodeErrors
                            END	 

--------------------------------------------------
----------------END Run Precode-------------------
--------------------------------------------------
                    END -- @DBPreCode


-----BEGIN Log------

                IF @DBPreCode IS NOT NULL
                    BEGIN -- @DBPreCode
                        IF @StmtOnly = 0
                            BEGIN -- @StmtOnly = 0

-----------------------------------------------------
-------------BEGIN Log PreCode Success---------------
-----------------------------------------------------
                                IF @PreCodeErrors IS NULL
                                    BEGIN --@PreCodeErrors IS NULL
                                        SET @DBPreCodeEndDateTime = GETDATE();
                                        UPDATE Minion.BackupLogDetails
                                            SET
                                                DBPreCodeEndDateTime = @DBPreCodeEndDateTime,
                                                DBPreCodeTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @DBPreCodeStartDateTime, 21), CONVERT(VARCHAR(25), @DBPreCodeEndDateTime, 21))
                                            WHERE
                                                ID = @BackupLogDetailsID;
                                    END --@PreCodeErrors IS NULL
-----------------------------------------------------
-------------END Log PreCode Success-----------------
-----------------------------------------------------

-----------------------------------------------------
-------------BEGIN Log PreCode Failure---------------
-----------------------------------------------------
                                IF @PreCodeErrors IS NOT NULL
                                    BEGIN --@PreCodeErrors IS NULL
                                        SET @DBPreCodeEndDateTime = GETDATE();
                                        UPDATE Minion.BackupLogDetails
                                            SET
                                                Warnings = ISNULL(Warnings, '')
                                                + @PreCodeErrors,
                                                DBPreCodeEndDateTime = @DBPreCodeEndDateTime,
                                                DBPreCodeTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @DBPreCodeStartDateTime, 21), CONVERT(VARCHAR(25), @DBPreCodeEndDateTime, 21))
                                            WHERE
                                                ID = @BackupLogDetailsID;
                                    END --@PreCodeErrors IS NULL
-----------------------------------------------------
-------------END Log PreCode Failure-----------------
-----------------------------------------------------
                            END -- @StmtOnly = 0
                    END -- @@DBPreCode

------END Log-------

            END -- @StmtOnly = 0
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
-------------------------------------------END DBPreCode-------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------	





----------------------------------------------------------------------------------------
----------------------------BEGIN Tuning Settings---------------------------------------
----------------------------------------------------------------------------------------

        SET @TuningSettingLevel = (
                                   SELECT COUNT(*)
                                    FROM
                                        Minion.BackupTuningThresholds
                                    WHERE
                                        DBName = @DBName
                                        AND IsActive = 1
                                  )


			--MinionDefault
        IF @TuningSettingLevel = 0
            BEGIN --@TuningSettingLevel = 0
				--Find out whether you're going to be working at the 'All' level or at the override level.
				----1 = MinionDefault, BackupType. 0 = MinionDefault, All
                SET @TuningTypeLevel = (
                                        SELECT
                                                COUNT(*)
                                            FROM
                                                Minion.BackupTuningThresholds
                                            WHERE
                                                DBName = 'MinionDefault'
                                                AND BackupType = @BackupType
                                                AND IsActive = 1
                                       )
            END --@TuningSettingLevel = 0

			--DBName
        IF @TuningSettingLevel > 0
            BEGIN --@TuningSettingLevel > 0
				--Find out whether you're going to be working at the 'All' level or at the override level.
					----1 = DBName, BackupType. 0 = DBName, All
                SET @TuningTypeLevel = (
                                        SELECT
                                                COUNT(*)
                                            FROM
                                                Minion.BackupTuningThresholds
                                            WHERE
                                                DBName = @DBName
                                                AND BackupType = @BackupType
                                                AND IsActive = 1
                                       )
            END	--@TuningSettingLevel > 0
----------------------------------------------------------------------------------------
-------------------------------END Tuning Settings--------------------------------------
----------------------------------------------------------------------------------------

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

----Set ServerInstance to '.' to avoid possibly overloading the DNS server. -- 1.1 fix.
 IF @ServerInstance NOT LIKE '%\%' AND (@IsClustered = 0 OR @IsClustered IS NULL)
	BEGIN
		SET @ServerInstance = '.'
	END
IF @ServerInstance LIKE '%\%' AND (@IsClustered = 0 OR @IsClustered IS NULL)
	BEGIN
		SET @ServerInstance = '.' + '\' + CONVERT(VARCHAR(100), SERVERPROPERTY('InstanceName'));
	END

------------------------------BEGIN Save Param-----------------------------------------------
INSERT Minion.Work(ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value)
SELECT @ExecutionDateTime, 'Backup', @DBName, @BackupType, '@BackupLoggingPath', 'BackupDB', @BackupLoggingPath
------------------------------END Save Param-------------------------------------------------
----SELECT 'BackupWork', * FROM Minion.Work 
	
----------------------------------------------------------------------------
-----------------------END Get Misc Settings--------------------------------
----------------------------------------------------------------------------


--------------------------------------------------------------------------
--------------------------------------------------------------------------
------------------BEGIN Get AG Info---------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

---------------------------------------------------------------
----------------BEGIN AG Info----------------------------------
---------------------------------------------------------------
DECLARE @DBIsInAG BIT;
		IF @Version >= 11 AND @OnlineEdition = 1
			BEGIN --@Version >= 11
							SET @DBIsInAG = (SELECT Value 
													 FROM Minion.Work 
													 WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'Backup' AND DBName = @DBName AND BackupType = @BackupType AND SPName = 'BackupMaster' AND Param = '@DBIsInAG')
							If @DBIsInAG IS NULL
								BEGIN
									SET @DBIsInAG = 0
								END
					--- We HAVE to run this select statement as an EXEC; even with the IF, this'd generate an error on SQL 05/08.
					IF @DBIsInAG = 1
					BEGIN --@DBIsInAG = 1
							SET @IsPrimaryReplica = (SELECT Value 
													 FROM Minion.Work 
													 WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'Backup' AND DBName = @DBName AND BackupType = @BackupType AND SPName = 'BackupMaster' AND Param = '@IsPrimaryReplica')

					END --@DBIsInAG = 1

IF @IsPrimaryReplica = 0
	BEGIN --@IsPrimaryReplica = 0


	DECLARE @BackupDBAGGroupQuery VARCHAR(2000),
			@CurrentPrimaryReplica varchar(150);
	SET @BackupDBAGGroupQuery = 'SELECT
drcs.database_name AS DBName,
AG.name AS GroupName,
ISNULL(agstates.primary_replica, '''') AS PrimaryServer,
CASE WHEN arstates.role = 1 THEN ''Primary''
	 WHEN arstates.role = 2 THEN ''Secondary''  
	 WHEN arstates.role = 3 THEN ''None''
	 END AS [LocalReplicaRole],
ISNULL(dbrs.synchronization_state, 0) AS [SyncState],
ISNULL(dbrs.is_suspended, 0) AS [IsSuspended],
ISNULL(drcs.is_database_joined, 0) AS [IsJoined]
FROM master.sys.availability_groups AS AG
LEFT OUTER JOIN master.sys.dm_hadr_availability_group_states as agstates
   ON AG.group_id = agstates.group_id
INNER JOIN master.sys.availability_replicas AS AR
   ON AG.group_id = AR.group_id
INNER JOIN master.sys.dm_hadr_availability_replica_states AS arstates
   ON AR.replica_id = arstates.replica_id AND arstates.is_local = 1
INNER JOIN master.sys.dm_hadr_database_replica_cluster_states AS drcs
   ON arstates.replica_id = drcs.replica_id
LEFT OUTER JOIN master.sys.dm_hadr_database_replica_states AS dbrs
   ON drcs.replica_id = dbrs.replica_id AND drcs.group_database_id = dbrs.group_database_id
ORDER BY AG.name ASC, drcs.database_name'

CREATE TABLE #BackupDBAGGroups
(
ID INT IDENTITY(1,1),
DBName VARCHAR(150),
GroupName VARCHAR(150),
PrimaryServer VARCHAR(150),
LocalReplicaRole VARCHAR(20),
SyncState TINYINT,
IsSuspended BIT,
IsJoined BIT
)

INSERT #BackupDBAGGroups(DBName, GroupName, PrimaryServer, LocalReplicaRole, SyncState, IsSuspended, IsJoined)
EXEC (@BackupDBAGGroupQuery)

SET @CurrentPrimaryReplica = (SELECT PrimaryServer FROM #BackupDBAGGroups WHERE DBName = @DBName)
DROP TABLE #BackupDBAGGroups

	END --@IsPrimaryReplica = 0



			END --@Version >= 11

---------------------------------------------------------------
----------------END AG Info------------------------------------
---------------------------------------------------------------

------------------------------------------------------------------------
------------------------------------------------------------------------
----------------END Get AG Info-----------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
        SET @IsTDE = (
                      SELECT is_encrypted
                        FROM sys.databases
                        WHERE
                            name = @DBName
                     )

--------------------------------------------------------------------------------------------------------------------------------
-------------------BEGIN DBSize-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
----We need to get the space if we're using DynamicTuning or if we're doing a diff backup and the min size is set.
----Because we have to know what the size of the DB is before we can say whether or not we're going to change the backup type.
        IF @DynamicTuning = 1 OR ( @BackupType = 'Diff' AND @MinSizeForDiffInGB IS NOT NULL)
            BEGIN --@DynamicTuning = 1
                DECLARE
                    @DBSizeCMD VARCHAR(4000),
                    @SpaceType VARCHAR(20)

----This only picks up settings larger than 1GB.  There's just no need to do dynamic tuning for anything under 1GB.
----Truth be told even 1GB is way too small for this, but we had to make the limit something.
						-------------------------------------------------------------------------
						-------------------------------BEGIN SpaceType---------------------------
						-------------------------------------------------------------------------

                IF @TuningSettingLevel = 0
                    BEGIN --@TuningSettingLevel = 0

				--Find out whether you're going to be working at the 'All' level or at the override level.
				--Level 0 is ALL.
                        IF @TuningTypeLevel = 0
                            BEGIN --@TuningTypeLevel = 0
                                SELECT TOP 1
                                        @SpaceType = SpaceType
                                    FROM
                                        Minion.BackupTuningThresholds
                                    WHERE
                                        ThresholdValue >= 1
                                        AND DBName = 'MinionDefault'
                                        AND BackupType = 'All'
                                        AND IsActive = 1
                                    ORDER BY
                                        ThresholdValue DESC

                            END --@TuningTypeLevel = 0

                        IF @TuningTypeLevel > 0
                            BEGIN --@TuningTypeLevel > 0
                                SELECT TOP 1
                                        @SpaceType = SpaceType
                                    FROM
                                        Minion.BackupTuningThresholds
                                    WHERE
                                        ThresholdValue >= 1
                                        AND DBName = 'MinionDefault'
                                        AND BackupType = @BackupType
                                        AND IsActive = 1
                                    ORDER BY
                                        ThresholdValue DESC
                            END --@TuningTypeLevel > 0
                    END --@TuningSettingLevel = 0

                IF @TuningSettingLevel > 0
                    BEGIN --@TuningSettingLevel > 0
				--Find out whether you're going to be working at the 'All' level or at the override level.				
                        IF @TuningTypeLevel = 0
                            BEGIN --@TuningTypeLevel = 0
                                SELECT TOP 1
                                        @SpaceType = SpaceType
                                    FROM
                                        Minion.BackupTuningThresholds
                                    WHERE
                                        ThresholdValue >= 1
                                        AND DBName = @DBName
                                        AND BackupType = 'All'
                                        AND IsActive = 1
                                    ORDER BY
                                        ThresholdValue DESC
                            END --@TuningTypeLevel = 0

                        IF @TuningTypeLevel > 0
                            BEGIN --@TuningTypeLevel > 0
                                SELECT TOP 1 @SpaceType = SpaceType
                                    FROM Minion.BackupTuningThresholds
                                    WHERE
                                        ThresholdValue >= 1
                                        AND DBName = @DBName
                                        AND BackupType = @BackupType
                                        AND IsActive = 1
                                    ORDER BY
                                        ThresholdValue DESC
                            END --@TuningTypeLevel > 0
                    END --@TuningSettingLevel > 0

					-------------------------------------------------------------------------
					-------------------------------END SpaceType-----------------------------
					-------------------------------------------------------------------------
                IF @BackupType <> 'Log'
                    BEGIN --@BackupType <> 'Log'
                        ----IF @SpaceType IS NULL
                        ----    BEGIN
                        ----        SET @SpaceType = 'Data';

                        ----    END

                        ----CREATE TABLE #TBackupDB
                        ----    (
                        ----     ID INT IDENTITY(1, 1),
                        ----     col1 VARCHAR(MAX) COLLATE DATABASE_DEFAULT
                        ----    )

                        DECLARE @InstanceName NVARCHAR(128);
                        SET @InstanceName = (SELECT CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)));
                       
					   EXEC [Minion].[DBMaintDBSizeGet] 'Backup', @BackupType, @DBName, @DBSize = @DBSize OUTPUT;

					    ----IF @InstanceName NOT LIKE '%\%'
                        ----    BEGIN
                        ----        SET @InstanceName = @InstanceName + '\Default';
                        ----    END

                        ----SET @DBSizeCMD = 'EXEC xp_cmdshell ''powershell "';
			
                        ----IF @Version = 10
                        ----    BEGIN
                        ----        SET @DBSizeCMD = @DBSizeCMD
                        ----            + 'ADD-PSSNAPIN SQLServerProviderSnapin100; ';
                        ----    END

                        ----IF @Version >= 11
                        ----    BEGIN
                        ----        SET @DBSizeCMD = @DBSizeCMD
                        ----            + 'IMPORT-MODULE SQLPS -DisableNameChecking 3> $null; '
                        ----    END
			---------------BEGIN Set Connection String------------
                        ----SET @DBSizeCMD = @DBSizeCMD + ' cd sqlserver:\sql\'
                        ----    + @InstanceName + '\databases;';
			---------------END Set Connection String--------------

			----IF @SpaceType = 'File'
			----	BEGIN
			----		SET @DBSizeCMD = @DBSizeCMD + ' $DB = (get-item $(encode-sqlname ''''' + @DBName + ''''')); $Size = $DB.Size; $Size/1024 "''';				 
			----	END

			----IF @SpaceType = 'Data'
			----	BEGIN
			----		SET @DBSizeCMD = @DBSizeCMD + ' $DB = (get-item $(encode-sqlname ''''' + @DBName + ''''')); $Size = $DB.DataSpaceUsage; ($Size/1024/1024) "''';
			----	END

			----IF @SpaceType = 'DataAndIndex'
			----	BEGIN
			----		SET @DBSizeCMD = @DBSizeCMD + ' $DB = (get-item $(encode-sqlname ''''' + @DBName + ''''')); $Size = $DB.DataSpaceUsage + $DB.IndexSpaceUsage; ($Size/1024/1024) "''';
			----	END
--SELECT @DBSizeCMD AS DBSizeCMD;
-------------------DEBUG-------------------------------
----IF @Debug = 1
----BEGIN
----	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
----	SELECT
----		ExecutionDateTime, STATUS, DBName, BackupType, 'DBSizeCMD'
----		FROM Minion.BackupLogDetails
----		WHERE ID = @BackupLogDetailsID

----				INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
----				SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupDB', 'DBSizeCMD', @DBSizeCMD
----END
-------------------DEBUG-------------------------------
                        ----INSERT #TBackupDB
                        ----EXEC (@DBSizeCMD)	
                        ----DECLARE
                        ----    @ErrorsProv VARCHAR(MAX),
                        ----    @ProviderError BIT;

                        ----DELETE FROM #TBackupDB WHERE col1 IS NULL
                        ----SELECT
                        ----        @ErrorsProv = STUFF((
                        ----                             SELECT ' ' + col1
                        ----                                FROM #TBackupDB AS T1
                        ----                                ORDER BY T1.ID
                        ----                            FOR XML PATH('')), 1, 1, '')
                        ----    FROM
                        ----        #TBackupDB AS T2;


-------------------DEBUG-------------------------------
----IF @Debug = 1
----BEGIN
----	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
----	SELECT
----		ExecutionDateTime, STATUS, DBName, BackupType, 'DBSizeCMD-TableRowdata'
----		FROM Minion.BackupLogDetails
----		WHERE ID = @BackupLogDetailsID

----				INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
----				SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupDB', 'DBSizeCMD-TableRaw data', @ErrorsProv
----END
-------------------DEBUG-------------------------------

--------------------BEGIN LOG ERRORS------------------------------
----If @ErrorsProv LIKE '%running scripts is disabled on this system%'
----BEGIN
----                UPDATE Minion.BackupLogDetails
----                    SET
----                        STATUS = 'FATAL ERROR: Powershell scripts are not enabled. Run "set-executionpolicy remotesigned" to correct the issue. The actual error message follows: ' + @ErrorsProv
----                    WHERE
----                        ID = @BackupLogDetailsID;
----						RETURN
----END
--------------------END LOG ERRORS------------------------------

----If something happens with the above call then the @DBSize var won't be able to be assigned so this is an excellent place to put in the error handling.
       ----                 BEGIN TRY
							------Sometimes on int'l systems we get a , back from PS so we have to change it back to a decimal point.
							----SET @DBSize = (SELECT REPLACE(col1, ',', '.') FROM #TBackupDB)
       ----                 END TRY

       ----                 BEGIN CATCH
       ----                     SET @ProviderError = 1;
       ----                 END CATCH
       ----                 DROP TABLE #TBackupDB

----If DBSize is under 0 it won't trigger the NumberOfFiles so it has to be at least 0.
                        ----IF @DBSize < 1
                        ----    BEGIN
                        ----        SET @DBSize = 1
                        ----    END

                    END  --@BackupType <> 'Log'
----END --@DBSize IS NULL
            END --@DynamicTuning = 1

--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
-------------------END DBSize---------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'DBSize'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID

	INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupDB', '@DBSize', @DBSize
END
-------------------DEBUG-------------------------------

------------------------------------------------------------------------
-------------------BEGIN MIN Diff Size----------------------------------
------------------------------------------------------------------------
----If the DB is too small to mess with doing a Diff then we need to choose what to do instead.
----We'll assume that Log is the default so if the table entry is NULL then we'll make it a log.
----This section has to stay above the Paths sections becasue they'll gather paths based on BackupType, which we may change here.
        IF @BackupType = 'Diff'
            BEGIN
                IF @DBSize < @MinSizeForDiffInGB
                    BEGIN
                        SET @BackupType = ISNULL(@DiffReplaceAction, 'Log');
                    END
            END
------------------------------------------------------------------------
-------------------END MIN Diff Size------------------------------------
------------------------------------------------------------------------



------------------------------------------------------------------
------------------------------------------------------------------
-----------------BEGIN PRE Log Info-------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
 If @StmtOnly = 0
        BEGIN --@StmtOnly = 0
            IF @BackupType = 'Log'
                BEGIN --@BackupType = 'Log'
 
--------------BEGIN Log Action---------------------
                    UPDATE Minion.BackupLogDetails
                        SET
                            STATUS = 'Getting Log Size'
                        WHERE
                            ID = @BackupLogDetailsID;
--------------END Log Action-----------------------

                    DECLARE
                        @PRELogSpaceUsed FLOAT,
                        @PRELogSizeInMB FLOAT,
                        @POSTLogSpaceUsed FLOAT,
                        @POSTLogSizeInMB FLOAT,
                        @PRELogReuseWait VARCHAR(255),
                        @POSTLogReuseWait VARCHAR(255);

                    CREATE TABLE #LogSize
                        (
                         DBName sysname COLLATE DATABASE_DEFAULT,
                         SizeInMB FLOAT,
                         SpaceUsed FLOAT,
                         STATUS TINYINT
                        )

                    CREATE TABLE #LogFiles
                        (
                         LogName sysname COLLATE DATABASE_DEFAULT
                        )

	----------- BEGIN PRE Log Reuse Wait -----------
                    SET @PRELogReuseWait = (
                                            SELECT log_reuse_wait_desc
                                                FROM sys.databases
                                                WHERE
                                                    DB_NAME(database_id) = @DBName
                                           )
	----------- BEGIN PRE Log Reuse Wait -----------

	----------- BEGIN PRE SQLPERF -----------
                    INSERT #LogSize
                            (
                             DBName,
                             SizeInMB,
                             SpaceUsed,
                             [STATUS]
							)
                            EXEC ('DBCC SQLPERF(LOGSPACE)');

                    SELECT
                            @PRELogSizeInMB = SizeInMB,
                            @PRELogSpaceUsed = SpaceUsed
                        FROM
                            #LogSize
                        WHERE
                            DBName = @DBName
	----------- END PRE SQLPERF --------------

                    TRUNCATE TABLE #LogSize;
                END --@BackupType = 'Log'
        END --@StmtOnly = 0
------------------------------------------------------------------
------------------------------------------------------------------
-----------------END PRE Log Info---------------------------------
------------------------------------------------------------------
------------------------------------------------------------------



---------------------------------------------------------
-----------BEGIN VLFs------------------------------------
---------------------------------------------------------
If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
        IF @BackupType = 'Log'
            BEGIN --@BackupType = 'Log'

		-------------Begin Log Beginning of Action-------------------

                UPDATE Minion.BackupLogDetails
                    SET
                        STATUS = 'Gathering VLF Info'
                    WHERE
                        ID = @BackupLogDetailsID;

		-------------End Log Beginning of Action---------------------
                CREATE TABLE #VLFs
                    (
                     RecoveryUnitID VARCHAR(50),
                     FileID VARCHAR(50),
                     FileSize VARCHAR(50),
                     StartOffset VARCHAR(50),
                     FSeqNo VARCHAR(50),
                     Status VARCHAR(50),
                     Parity VARCHAR(50),
                     CreateLSN VARCHAR(50)
                    )

			SET @VLFStmt = 'USE [' + @DBName + ']; DBCC LOGINFO();'
                IF @Version >= 11
                    BEGIN --@Version < 11

                        INSERT #VLFs
                                (
                                 RecoveryUnitID,
                                 FileID,
                                 FileSize,
                                 StartOffset,
                                 FSeqNo,
                                 Status,
                                 Parity,
                                 CreateLSN
								)
                                EXEC (@VLFStmt)
                    END --@Version < 11

                IF @Version < 11
                    BEGIN --@Version < 11

                        INSERT #VLFs
                                (
                                 FileID,
                                 FileSize,
                                 StartOffset,
                                 FSeqNo,
                                 Status,
                                 Parity,
                                 CreateLSN
								)
                                EXEC (@VLFStmt)
                    END --@Version < 11

                SET @VLFs = (SELECT COUNT (*) FROM #VLFs)
                DROP TABLE #VLFs
            END --@BackupType = 'Log'
	END --@StmtOnly = 0
---------------------------------------------------------
-----------END VLFs--------------------------------------
---------------------------------------------------------



------------------------------------------------------------------
------------------------------------------------------------------
-----------------BEGIN Dynamic Log Tuning-------------------------
------------------------------------------------------------------
------------------------------------------------------------------
----If it's a log backup the size of the DB isn't important, it's the size
----of the log that counts.  Therefore, here we'll set the DBSize
---- equal to the log size.  This way
----We can just pass in the same DBSize value w/o having to change a bunch of other code.
----So if you have a BackupType = 'Log' in the Thresholds table, then the Spacetype is Log, regardless 
---of what it says in the col.  However, it's recommended that you set SpaceType to 'Log' whenver the 
----BackupType = 'Log' because it'll help remind you how it's calculated. However, for log backups, unlike Full and Diff,
----it doesn't really matter what you put in SpaceType.
If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
        IF @BackupType = 'Log'
            BEGIN
                SET @DBSize = ((@PRELogSizeInMB * @PRELogSpaceUsed) / 100) / 1024; -- Convert to GB since that's what the StmtGet SP expects.
            END
END --@StmtOnly = 0
------------------------------------------------------------------
------------------------------------------------------------------
-----------------END Dynamic Log Tuning---------------------------
------------------------------------------------------------------
------------------------------------------------------------------


-----------------------------------------------------
-----------------BEGIN Backup CMD--------------------
-----------------------------------------------------	

        CREATE TABLE #Backup
            (
             ID INT IDENTITY(1, 1),
             ServerLabel sysname COLLATE DATABASE_DEFAULT NULL,
             NETBIOSName sysname COLLATE DATABASE_DEFAULT,
             Command VARCHAR(4000) COLLATE DATABASE_DEFAULT,
             BackupDrive VARCHAR(100) COLLATE DATABASE_DEFAULT,
             BackupPath VARCHAR(1000) COLLATE DATABASE_DEFAULT,
             BackupLocType VARCHAR(20) COLLATE DATABASE_DEFAULT,
             FullPath VARCHAR(2000) COLLATE DATABASE_DEFAULT,
             FullFileName VARCHAR(1000) COLLATE DATABASE_DEFAULT,
             FileName VARCHAR(100) COLLATE DATABASE_DEFAULT,
             DateLogic VARCHAR(100) COLLATE DATABASE_DEFAULT,
             Extension VARCHAR(5) COLLATE DATABASE_DEFAULT,
             MainFileList VARCHAR(MAX) COLLATE DATABASE_DEFAULT,
             MirrorFileList VARCHAR(MAX) COLLATE DATABASE_DEFAULT,
             IsMirror BIT,
             RetHrs INT,
             PathOrder TINYINT,
             FileNumber TINYINT,
             Buffercount INT,
             MaxTransferSize BIGINT,
             NumberOfFiles INT,
             Compression BIT,
             MirrorBackup BIT,
             DynamicTuning BIT,
             EncryptBackup BIT,
             BackupName VARCHAR(128) COLLATE DATABASE_DEFAULT,
             ExpireDateInHrs INT,
             Descr VARCHAR(255) COLLATE DATABASE_DEFAULT,
             RetainDays INT,
             IsChecksum BIT,
			 [BlockSize] BIGINT,
             IsInit BIT,
             IsFormat BIT,
             IsCopyOnly BIT,
             IsSkip BIT,
             BackupErrorMgmt VARCHAR(50) COLLATE DATABASE_DEFAULT,
             MediaName VARCHAR(128) COLLATE DATABASE_DEFAULT,
             MediaDescription VARCHAR(255) COLLATE DATABASE_DEFAULT,
			 CertName varchar(100) COLLATE DATABASE_DEFAULT,
			 EncrAlgorithm varchar(20) COLLATE DATABASE_DEFAULT,
			 ThumbPrint varbinary(32)
            )


		---- If @BackupType = 'Full' OR @BackupType = 'Diff'
        BEGIN
            INSERT INTO #Backup
                    (
                     ServerLabel,
                     NETBIOSName,
                     Command,
                     BackupDrive,
                     BackupPath,
                     BackupLocType,
                     FullPath,
                     FullFileName,
                     [FileName],
                     DateLogic,
                     Extension,
                     MainFileList,
                     MirrorFileList,
                     IsMirror,
                     RetHrs,
                     PathOrder,
                     FileNumber,
                     [Buffercount],
                     [MaxTransferSize],
                     NumberOfFiles,
                     [Compression],
                     MirrorBackup,
                     DynamicTuning, --MultiDrive, 
                     EncryptBackup,
                     BackupName,
                     ExpireDateInHrs,
                     Descr,
                     [RetainDays],
                     IsChecksum,
					 [BlockSize],
                     IsInit,
                     IsFormat,
                     IsCopyOnly,
                     IsSkip,
                     BackupErrorMgmt,
                     [MediaName],
                     [MediaDescription],
					 CertName ,
					 EncrAlgorithm ,
					 ThumbPrint
					)
                    EXEC Minion.BackupStmtGet @DBName, @BackupTypeORIG, @DBSize			
        END

        SELECT TOP 1
                @BackupCmd = Command,
                @FileList = MainFileList,
                @Buffercount = Buffercount,
                @MaxTransferSize = MaxTransferSize,
                @NumberOfFiles = NumberOfFiles,
                @Compression = Compression,
                @BackupLocType = BackupLocType,
                @FullPath = FullPath,
                @FullFileName = FullFileName,
                @DateLogic = DateLogic,
                @Extension = Extension,
                @MirrorBackup = MirrorBackup,
                @DynamicTuning = DynamicTuning, 
                @EncryptBackup = EncryptBackup,
                @BackupName = BackupName,
                @ExpireDateInHrs = ExpireDateInHrs,
                @Descr = Descr,
                @RetainDays = RetainDays,
                @IsChecksum = IsChecksum,
				@BlockSize = [BlockSize],
                @IsInit = IsInit,
                @IsFormat = IsFormat,
                @IsCopyOnly = IsCopyOnly,
                @IsSkip = IsSkip,
                @BackupErrorMgmt = BackupErrorMgmt,
                @MediaName = MediaName,
                @MediaDescription = MediaDescription,
				@BackupEncryptionCertName = CertName,
				@EncrAlgorithm = EncrAlgorithm,
				@BackupEncryptionCertThumbPrint = ThumbPrint
            FROM
                #Backup; 
				          
        SELECT @FileList = (SELECT TOP 1 MainFileList FROM #Backup); 


-----------------------------------------------------
-----------------END Backup CMD----------------------
-----------------------------------------------------


--------------------------------------------------------------------------------------------
------------------BEGIN Catch-up on Errors--------------------------------------------------
--------------------------------------------------------------------------------------------
----These are fatal errors that will stop the run.  We couldn't log them earlier because the initial 
----log record hadn't been written yet.  So we're logging them now.  
----These will stop the job.

-------BEGIN BackupCmd is empty-------
If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
        IF @BackupCmd IS NULL OR @BackupCmd = ''
            BEGIN
                DECLARE @BackupCmdStatus VARCHAR(8000);
                SET @BackupCmdStatus = 'FATAL ERROR:  @BackupCmd is empty. Common causes are misconfigured BackupSettings and BackupTuningThresholds tables. If you need help configuring them, consult the documentation as it has examples of proper configurations outlined.'
                ----IF @ProviderError = 1
                ----    BEGIN
                ----        SET @BackupCmdStatus = @BackupCmdStatus
                ----            + 'We have detected that the DBSize calculation had an issue. Some possible causes: 1.) Powershell is not installed or is not in the system path. 2.) The SQL Server provider was not able to load. 3.) There is a misconfiguration in the BackupTuningThresholds table. THE SPECIFIC ERROR FOLLOWS: '
                ----            + @ErrorsProv
                ----    END

                UPDATE Minion.BackupLogDetails
                    SET
                        STATUS = @BackupCmdStatus
                    WHERE
                        ID = @BackupLogDetailsID;

					------------------------------------------------------------------------
					-------------------BEGIN Log to Minion----------------------------------
					------------------------------------------------------------------------
					----Here we're logging this failure to Minion.  We'll want to know about this error
					----and since we're returning out of the SP right after this, it's the only place
					----to log this issue.
					If (select TOP 1 PushToMinion from Minion.BackupSettings) IS NOT NULL
						BEGIN
									SET @ServerLabel = @@ServerName;
									IF @ServerLabel LIKE '%\%'
										BEGIN --Begin @ServerLabel
											SET @ServerLabel = REPLACE(@ServerLabel, '\', '~')
										END	--End @ServerLabel

						IF @StmtOnly = 0
							BEGIN --@StmtOnly = 0
									SET @TriggerFile = 'Powershell "''' + ''''''
										+ CONVERT(VARCHAR(25), @ExecutionDateTime, 21) + ''''''''
										+ ' | out-file "' + @BackupLoggingPath + 'BackupDB\' + @ServerLabel + '.'
										+ @DBName + '" -append"' 
						----print @TriggerFile
									EXEC xp_cmdshell @TriggerFile 
							END --@StmtOnly = 0
						END

					------------------------------------------------------------------------
					-------------------END Log to Minion------------------------------------
					------------------------------------------------------------------------

                RETURN
            END
END --@StmtOnly = 0
-------END BackupCmd is empty---------



--------------------------------------------------------------------------------------------
------------------END Catch-up on Errors----------------------------------------------------
--------------------------------------------------------------------------------------------


-----------------------------------------------------------------
----------------------BEGIN Set New Backup Type------------------
-----------------------------------------------------------------
----This is for the MinSizeForDiffInGB setting in the Settings table.
----In the case that the DiffReplaceAction sets this to a different BackupType
----than the one passed in, we'll need to change it here so that it gets logged
----properly.  Setting it here, early in the routine ensures that everyhing 
----should work as expected with the new BackupType.
        IF @BackupType <> @NewBackupType
            BEGIN
                SET @BackupType = @NewBackupType;
            END
-----------------------------------------------------------------
----------------------END Set New Backup Type--------------------
-----------------------------------------------------------------




-------------------------------------------------------------------------
-----------------------BEGIN Log Run Data--------------------------------
-------------------------------------------------------------------------

        IF @StmtOnly = 0
            BEGIN --@StmtOnly = 0				 
                BEGIN
                    UPDATE Minion.BackupLogDetails
                        SET --STATUS = @STATUS,								  
                            ServerLabel = @ServerLabel,
                            NETBIOSName = @NETBIOSName,
                            IsClustered = @IsClustered,
                            IsInAG = ISNULL(@DBIsInAG, 0),
                            IsPrimaryReplica = ISNULL(@IsPrimaryReplica, 0),
                            DBType = @LogDBType,
                            --BackupType = @BackupType,
                            StmtOnly = @StmtOnly,
                            FileAction = @FileAction,
                            FileActionTime = @FileActionTime,
                            MirrorBackup = @MirrorBackup,
                            DynamicTuning = @DynamicTuning,
                            IsEncryptedBackup = @EncryptBackup,
                            BackupName = @BackupName,
                            ExpireDateInHrs = @ExpireDateInHrs,
                            Descr = @Descr,
                            RetainDays = @RetainDays,
                            IsCheckSum = @IsChecksum,
							[BlockSize] = @BlockSize,
                            IsInit = @IsInit,
                            IsFormat = @IsFormat,
                            IsCopyOnly = @IsCopyOnly,
                            IsSkip = @IsSkip,
                            BackupErrorMgmt = @BackupErrorMgmt,
                            MediaName = @MediaName,
                            MediaDescription = @MediaDescription,
                            IsTDE = @IsTDE
                        WHERE
                            ID = @BackupLogDetailsID
	
                END
            END --@StmtOnly = 0

-------------------------------------------------------------------------
-----------------------END Log Run Data----------------------------------
-------------------------------------------------------------------------






--------------------------------------------------------------- 
---------------------------------------------------------------
-----------------------Begin Delete History--------------------
---------------------------------------------------------------
---------------------------------------------------------------
If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
		-----BEGIN Log------

        BEGIN
            UPDATE Minion.BackupLogDetails
                SET
                    STATUS = 'Deleting log history'
                WHERE
                    ID = @BackupLogDetailsID;
        END

		------END Log-------

SET @SyncLogs = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'Backup' AND DBName = @DBName AND BackupType = @BackupType AND SPName = 'BackupMaster' AND Param = '@SyncLogs')
----BackupLogDetails
        WHILE 1 = 1
            BEGIN
	---BEGIN Write to sync log---

	If @SyncLogs = 1
		BEGIN
                INSERT Minion.SyncCmds
                        (
                         ExecutionDateTime,
                         Module,
                         Status,
                         ObjectName,
                         Op,
                         Cmd,
                         Pushed,
                         Attempts
						)
                    SELECT
                            @ExecutionDateTime,
                            'Backup',
                            'In queue',
                            'BackupLogDetails',
                            'DELETE',
                            ('DELETE TOP (100) Minion.BackupLogDetails where DATEDIFF(d, ExecutionDateTime, GetDate()) > '
                             + CAST(@HistRetDays AS VARCHAR(10))
                             + ' AND DBName = ''' + @DBName + ''''),
                            0,
                            0;
		END
	---END Write to sync log---

                DELETE TOP (100) Minion.BackupLogDetails
                    WHERE
                        DATEDIFF(d, ExecutionDateTime, GETDATE()) > @HistRetDays
                        AND DBName = @DBName

                IF @@rowcount = 0
                    BREAK
            END

----BackupLog
        WHILE 1 = 1
            BEGIN
	---BEGIN Write to sync log---
		If @SyncLogs = 1
		BEGIN
                INSERT Minion.SyncCmds
                        (
                         ExecutionDateTime,
                         Module,
                         Status,
                         ObjectName,
                         Op,
                         Cmd,
                         Pushed,
                         Attempts
						)
                    SELECT
                            @ExecutionDateTime,
                            'Backup',
                            'In queue',
                            'BackupLog',
                            'DELETE',
                            'DELETE TOP (100) Minion.BackupLog where DATEDIFF(d, ExecutionDateTime, GetDate()) > '
                            + CAST(@HistRetDays AS VARCHAR(10)),
                            0,
                            0;
		END
	---END Write to sync log---

                DELETE TOP (100) Minion.BackupLog
                    WHERE
                        DATEDIFF(d, ExecutionDateTime, GETDATE()) > @HistRetDays
                IF @@rowcount = 0
                    BREAK
            END

----BackupFiles
        WHILE 1 = 1
            BEGIN
	---BEGIN Write to sync log---
		If @SyncLogs = 1
		BEGIN
                INSERT Minion.SyncCmds
                        (
                         ExecutionDateTime,
                         Module,
                         Status,
                         ObjectName,
                         Op,
                         Cmd,
                         Pushed,
                         Attempts
						)
                    SELECT
                            @ExecutionDateTime,
                            'Backup',
                            'In queue',
                            'BackupFiles',
                            'DELETE',
                            ('DELETE TOP (100) Minion.BackupFiles where DATEDIFF(d, ExecutionDateTime, GetDate()) > '
                             + CAST(@HistRetDays AS VARCHAR(10))
                             + ' AND DBName = ''' + @DBName + '''')
                            + '	AND (IsArchive = 0 OR IsArchive IS NULL)',
                            0,
                            0
		END
	---END Write to sync log---

                DELETE TOP (100) Minion.BackupFiles
                    WHERE
                        DATEDIFF(d, ExecutionDateTime, GETDATE()) > @HistRetDays
                        AND DBName = @DBName
                        AND (IsArchive = 0 OR IsArchive IS NULL)
                IF @@rowcount = 0
                    BREAK
            END

----SyncCmds
        WHILE 1 = 1
            BEGIN
	---BEGIN Write to sync log---
		If @SyncLogs = 1
		BEGIN
                INSERT Minion.SyncCmds
                        (
                         ExecutionDateTime,
                         Module,
                         Status,
                         ObjectName,
                         Op,
                         Cmd,
                         Pushed,
                         Attempts
						)
                    SELECT
                            @ExecutionDateTime,
                            'Backup',
                            'In queue',
                            'SyncCmds',
                            'DELETE',
                            ('DELETE TOP (100) Minion.SyncCmds where DATEDIFF(d, ExecutionDateTime, GetDate()) > '
                             + CAST(@HistRetDays AS VARCHAR(10))
                             + ' AND DBName = ''' + @DBName + ''' AND Module = ''Backup'''),
                            0,
                            0; 
		END
	---END Write to sync log---

                DELETE TOP (100) Minion.BackupLogDetails
                    WHERE
                        DATEDIFF(d, ExecutionDateTime, GETDATE()) > @HistRetDays
                        AND DBName = @DBName

                IF @@rowcount = 0
                    BREAK
            END

----BackupDebug
        WHILE 1 = 1
            BEGIN

                DELETE TOP (100) Minion.BackupDebug
                    WHERE
                        DATEDIFF(d, ExecutionDateTime, GETDATE()) > @HistRetDays
                        AND DBName = @DBName

                IF @@rowcount = 0
                    BREAK
            END

----BackupDebugLogDetails
        WHILE 1 = 1
            BEGIN

                DELETE TOP (100) Minion.BackupDebugLogDetails
                    WHERE
                        DATEDIFF(d, ExecutionDateTime, GETDATE()) > @HistRetDays
                        AND DBName = @DBName

                IF @@rowcount = 0
                    BREAK
            END

----SyncCmds
        WHILE 1 = 1
            BEGIN

                DELETE TOP (100) Minion.SyncCmds
                    WHERE
                        DATEDIFF(d, ExecutionDateTime, GETDATE()) > @HistRetDays

                IF @@rowcount = 0
                    BREAK
            END


END --@StmtOnly = 0
--------------------------------------------------------------- 
---------------------------------------------------------------
-----------------------End Delete History----------------------
---------------------------------------------------------------
---------------------------------------------------------------


--------------------------------------------------------------- 
---------------------------------------------------------------
--------------------Begin DB Selection-------------------------
---------------------------------------------------------------
---------------------------------------------------------------

-- Get all the databases that will be backed up and insert into temp table
-- Check the exclusion bit and global exclusion list

		--*-- This table is not used. --*-- 
        CREATE TABLE #DBBackupLst
            (
             DBName VARCHAR(100) COLLATE DATABASE_DEFAULT,
             BackupRetention TINYINT,
             FullPath VARCHAR(1000) COLLATE DATABASE_DEFAULT,
             PrevFullPath VARCHAR(1000) COLLATE DATABASE_DEFAULT,
             PrevFullDate DATETIME
            )


        BEGIN		--*-- This BEGIN/END appears to be here for no reason? --*-- 
  
--!!!!!!!!!!!!!!!!!!!!!GET LocType and use it to set the MB/sec in the log update stmt...
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
------------------------BEGIN Create Directories--------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
 If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
            IF @BackupLocType <> 'URL' AND @BackupLocType IS NOT NULL
                BEGIN --@BackupLocType <> 'URL' and @BackupLocType IS NOT NULL

                    CREATE TABLE #DirExist
                        (
                         DirExist VARCHAR(2000) COLLATE DATABASE_DEFAULT
                        ) 

 		-----BEGIN Log Create Directories------
                    BEGIN
                        UPDATE Minion.BackupLogDetails
                            SET
                                STATUS = 'Creating Directories'
                            WHERE
                                ID = @BackupLogDetailsID;
                    END
		------END Log Create Directories-------

----------------------------------------------------
------------BEGIN Create Paths----------------------
----------------------------------------------------

                    DECLARE
                        @i TINYINT,
                        @CT TINYINT,
                        @FileErrors VARCHAR(MAX);
                    SET @i = 1;
                    SET @CT = (SELECT COUNT(*) FROM #Backup);
                    SET @FileErrors = '';
                    WHILE @i <= @CT
                        BEGIN --FileCreate

                            SET @FullPath = (SELECT FullPath FROM #Backup WHERE ID = @i); 
							 
	 -- -- Set folder path 
	  
                            SET @FileExistCMD = ''; 
                            SET @FileExistCMD = ' powershell "If ((test-path '''
                                + @FullPath + ''') -eq $False){MD ' + ''''
                                + @FullPath
                                + ''' -errorvariable err -erroraction silentlycontinue} If ($err.count -gt 0){$Final = $err} ELSE{$Final = ''Dir Exists''}; $Final" '

                            INSERT #DirExist
                                    EXEC master..xp_cmdshell @FileExistCMD

                            IF (SELECT TOP 1 DirExist FROM #DirExist) <> 'Dir Exists'
                                BEGIN
                                    SELECT
                                            @FileErrors = @FileErrors
                                            + 'Error: ' + (SELECT TOP 1 DirExist FROM #DirExist) + '  '
                                END	 

                            TRUNCATE TABLE #DirExist;
                            SET @i = @i + 1;      
                        END --FileCreate

---- Reset table so the mirror backups can use it.
                    TRUNCATE TABLE #DirExist
			--PRINT @FileErrors
                    IF @FileErrors <> ''
                        BEGIN
                            UPDATE Minion.BackupLogDetails
                                SET
                                    STATUS = 'FATAL ERROR: We were not able to create the folder in the path specified.  Make sure your settings in the Minion.BackupSettingsPath table are correct and that you have permission to create folders on this drive. ACTUAL ERROR FOLLOWS: '
                                    + @FileErrors
                                WHERE
                                    ID = @BackupLogDetailsID;

------------------------------------------------------------------------
-------------------BEGIN Log to Minion----------------------------------
------------------------------------------------------------------------
If (select TOP 1 PushToMinion from Minion.BackupSettings) IS NOT NULL
	BEGIN
				SET @ServerLabel = @@ServerName;
				IF @ServerLabel LIKE '%\%'
					BEGIN --Begin @ServerLabel
						SET @ServerLabel = REPLACE(@ServerLabel, '\', '~')
					END	--End @ServerLabel


	IF @StmtOnly = 0
		BEGIN --@StmtOnly = 0
				SET @TriggerFile = 'Powershell "''' + ''''''
					+ CONVERT(VARCHAR(25), @ExecutionDateTime, 21) + ''''''''
					+ ' | out-file "' + @BackupLoggingPath + 'BackupDB\' + @ServerLabel + '.'
					+ @DBName + '" -append"' 
	----print @TriggerFile
				EXEC xp_cmdshell @TriggerFile 
		END --@StmtOnly = 0
	END

------------------------------------------------------------------------
-------------------END Log to Minion------------------------------------
------------------------------------------------------------------------

                            RETURN
                        END
----------------------------------------------------
------------END Create Paths------------------------
----------------------------------------------------

                END --@BackupLocType <> 'URL' and @BackupLocType IS NOT NULL
END --@StmtOnly = 0
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
------------------------END Create Directories----------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

 
------------------------------------------------------------------
------------------------------------------------------------------
-----------------BEGIN Delete Files Before------------------------
------------------------------------------------------------------
------------------------------------------------------------------
	
	
 		-----BEGIN PreDelete Old Log Files------
If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
            BEGIN
                UPDATE Minion.BackupLogDetails
                    SET
                        STATUS = 'Deleting backup files'
                    WHERE
                        ID = @BackupLogDetailsID;
            END
END --@StmtOnly = 0
		------END PreDelete Old Log Files-------	
			   	   

--Delete the files before the backup if flags are set.
If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
            IF (@DeleteFilesBefore = 1 AND @DeleteFilesBeforeAgree = 1)
                BEGIN --@DeleteFilesBefore = 1 AND @DeleteFilesBeforeAgree = 1
                    SET @BackupFilesDeleteStartDateTime = GETDATE();
                    EXEC Minion.BackupFilesDelete @DBName = @DBName,
                        @RetHrs = NULL, @Delete = 1, @EvalDateTime = NULL;
                    SET @BackupFilesDeleteEndDateTime = GETDATE();

                    SET @BackupFilesDeleteTimeInSecs = DATEDIFF(ss, @BackupFilesDeleteStartDateTime, @BackupFilesDeleteEndDateTime)

                    UPDATE Minion.BackupLogDetails
                        SET
                            DeleteFilesStartDateTime = @BackupFilesDeleteStartDateTime,
                            DeleteFilesEndDateTime = @BackupFilesDeleteEndDateTime,
                            DeleteFilesTimeInSecs = @BackupFilesDeleteTimeInSecs
                        WHERE
                            ID = @BackupLogDetailsID;

                END --@DeleteFilesBefore = 1 AND @DeleteFilesBeforeAgree = 1
	END --@StmtOnly = 0
------------------------------------------------------------------
------------------------------------------------------------------
-----------------END Delete Files Before--------------------------
------------------------------------------------------------------
------------------------------------------------------------------



 ----------------------------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------BEGIN Log Delete Old Files------------------
 ----------------------------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------------------------
 If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
             IF (@DeleteFilesBefore = 1 AND @DeleteFilesBeforeAgree = 1)
                BEGIN --@DeleteFilesBefore = 1 AND @DeleteFilesBeforeAgree = 1

 ---------------BEGIN Log Delete Old Files-------------------
                            UPDATE Minion.BackupLogDetails
                                SET
                                    STATUS = 'Deleting backup files'
                                WHERE
                                    ID = @BackupLogDetailsID;
 ---------------END Log Delete Old Files--------------------				  



 ----------------BEGIN Delete Old Files---------------------
                    SET @BackupFilesDeleteStartDateTime = GETDATE();
					DECLARE @DeleteCMD VARCHAR(2000)
					SET @DeleteCMD = ' EXEC Minion.BackupFilesDelete  ' + '''' + @DBName + '''' + ', @RetHrs = NULL, @Delete = 1, @EvalDateTime = NULL'
                    SET @PreCMD = 'sqlcmd -r 1 -S"' + @ServerInstance + '"'
                        + CAST(@Port AS VARCHAR(6))
						+ '" -d "' + @MaintDB + '" -q "' 
                    SET @TotalCMD = @PreCMD
                        + @DeleteCMD + '"'
--SELECT @TotalCMD
					DECLARE @FileDeleteErrors VARCHAR(max);
                    INSERT #DeleteResults
                            (col1)
                            EXEC xp_cmdshell @TotalCMD;
                            --EXEC Minion.BackupFilesDelete @DBName = @DBName,
                            --    @RetHrs = NULL, @Delete = 1,
                            --    @EvalDateTime = NULL;
----SELECT '#DeleteResults', * FROM #DeleteResults
                            SET @BackupFilesDeleteEndDateTime = GETDATE();

                            SET @BackupFilesDeleteTimeInSecs = DATEDIFF(ss, @BackupFilesDeleteStartDateTime, @BackupFilesDeleteEndDateTime)

							DELETE FROM #DeleteResults
								   WHERE col1 IS NULL
									  OR col1 = 'output'
									  OR col1 = 'NULL'
									  OR col1 LIKE '%-------------------------------------%'

							SELECT
										@FileDeleteErrors = 'FILE DELETE ERROR: '
										+ STUFF((SELECT ' ' + col1
											FROM #DeleteResults AS T1
											ORDER BY T1.ID
											FOR XML PATH('')), 1, 1, '')
									FROM
										#DeleteResults AS T2;
--SELECT '#DeleteResults', * FROM #DeleteResults
----------------END Delete Old Files------------------------

---------------BEGIN Log Delete Old Files------------------
                            UPDATE Minion.BackupLogDetails
                                SET
									Warnings = CASE
													WHEN @FileDeleteErrors LIKE '%error%' THEN ISNULL(Warnings, '') + 'FILE DELETE ERRORS: ' + @FileDeleteErrors
													ELSE Warnings
												END,
                                    DeleteFilesStartDateTime = @BackupFilesDeleteStartDateTime,
                                    DeleteFilesEndDateTime = @BackupFilesDeleteEndDateTime,
                                    DeleteFilesTimeInSecs = @BackupFilesDeleteTimeInSecs
                                WHERE
                                    ID = @BackupLogDetailsID;
---------------END Log Delete Old Files--------------------

                END --@DeleteFilesBefore = 1 AND @DeleteFilesBeforeAgree = 1
	END --@StmtOnly = 0
 ----------------------------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------END Log Delete Old Files--------------------
 ----------------------------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------------------------




 -------------------------BEGIN PreBackup Log-------------------------
 If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
 ----------BEGIN StatusMonitorCheck-------------
----We have to check that the StatusMonitor job is on so we can notify the user that the PctComplete col won't be updated.
            SET @BackupStartDateTime = GETDATE();
            DECLARE @MonitorJobRunning TINYINT;
            SET @MonitorJobRunning = (SELECT COUNT(*)
                                        FROM sys.dm_exec_sessions es
                                        INNER JOIN msdb.dbo.sysjobs sj
                                        ON  sj.job_id = CAST(CONVERT(BINARY(16), SUBSTRING(es.program_name, 30, 34), 1) AS UNIQUEIDENTIFIER)
                                        WHERE
                                            program_name LIKE 'SQLAgent - TSQL JobStep (Job % : Step %)'
                                            AND sj.name = 'MinionBackupStatusMonitor'
                                     )
 ----------BEGIN StatusMonitorCheck-------------
            BEGIN

                IF @MonitorJobRunning = 0
                    BEGIN
                        SET @Status = 'Backup running(Status Monitor OFF)'
                    END

                IF @MonitorJobRunning > 0
                    BEGIN
                        SET @Status = 'Backup running'
                    END
                UPDATE Minion.BackupLogDetails --(ExecutionDateTime, Status, DBName, DBType, BackupType, BackupStartDateTime, Buffercount, MaxTransferSize, NumberOfFiles, StmtOnly, BackupCmd)
                    SET
                        STATUS = @Status,
                        PctComplete = 0,
                        BackupStartDateTime = @BackupStartDateTime,
                        Buffercount = @Buffercount,
                        MaxTransferSize = @MaxTransferSize,
                        Compression = @Compression,
                        NumberOfFiles = @NumberOfFiles,
                        BackupRetHrs = @FileRetHrs,
                        DelFileBefore = @DeleteFilesBefore,
                        BackupLogging = @BackupLogging,
                        BackupLoggingRetDays = @BackupLoggingRetDays,
                        BackupCmd = @BackupCmd,
                        FileList = @FileList,
                        Verify = @Verify
                    WHERE
                        ID = @BackupLogDetailsID;

            END;
	END --@StmtOnly = 0
-------------------------END PreBackup Log---------------------------



------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------Begin Backup DB-----------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------

            IF @StmtOnly = 0
                BEGIN --Begin StmtOnly = 0

                    SET @PreCMD = 'sqlcmd -r 1 -S"' + @ServerInstance
                        + CAST(@Port AS VARCHAR(6))
                    SET @TotalCMD = @PreCMD
                        + '" -q " DBCC TRACEON(3604,3213); ' + @BackupCmd + '"'
					--	PRINT @TotalCMD
                    CREATE TABLE #BackupResults
                        (
                         ID INT IDENTITY(1, 1),
                         col1 VARCHAR(MAX) COLLATE DATABASE_DEFAULT
                        )

                    INSERT #BackupResults
                            (col1)
                            EXEC xp_cmdshell @TotalCMD;

                    DELETE FROM #BackupResults
                        WHERE
                            col1 IS NULL --OR col1 LIKE '%DBCC execution completed%';

---------------------------------------------------------------------------
---------------------BEGIN MB/Sec------------------------------------------
---------------------------------------------------------------------------
--We were getting MB/sec by calculating it before, but in 1.1 we put in the
--ability to use NUL as a path for testing and the calculation isn't available.
--So we need to change the way we do it.  Originally we considered only doing it
--this way if NUL is used to keep from upsetting what we've already got, but
--ultimately we decided it best to do the same thing everywhere.
--If that turns out to not be a good idea we'll change it back and only use this method 
--for NUL.
DECLARE @first_char nvarchar(10)
DECLARE @second_char nvarchar(10)

SET @first_char = '(';
SET @second_char = ')';

SET @MBPerSec = (SELECT SUBSTRING
(
-- column
 col1
-- start position
,CHARINDEX(@first_char, col1 , 1) + 1
-- length
,CASE
WHEN (CHARINDEX(@second_char, col1 , 0) - CHARINDEX(@first_char, col1, 0)) > 0
THEN CHARINDEX(@second_char, col1, 0) - CHARINDEX(@first_char, col1, 0) - 1
ELSE 0
END
) AS NULMBsec
FROM #BackupResults u WHERE col1 LIKE '%BACKUP DATABASE successfully processed%' OR col1 LIKE '%BACKUP LOG successfully processed%')

SET @MBPerSec = REPLACE(@MBPerSec, ' MB/sec', '')
--We have to replace . with , if it's not USenglish.
IF @@LANGUAGE <> 'us_english'
	BEGIN
		SET @MBPerSec = REPLACE(@MBPerSec, '.', ',')
	END
---------------------------------------------------------------------------
---------------------END MB/Sec--------------------------------------------
---------------------------------------------------------------------------


------------------------------------------------------------
--------------------BEGIN Parse T3213-----------------------
------------------------------------------------------------
                    DECLARE
                        @Errors VARCHAR(max),
                        @MemoryLimit VARCHAR(50),
                        @FileSystemIOAlign VARCHAR(50),
                        @TotalBufferSpace VARCHAR(50),
                        @SetsOfBuffers VARCHAR(50);
		
                    SET @MemoryLimit = (SELECT col1 FROM #BackupResults WHERE col1 LIKE '%Memory Limit%');
                    SET @MemoryLimit = REPLACE(@MemoryLimit, 'Memory limit:', ''); 
                    SET @MemoryLimit = LTRIM(RTRIM(REPLACE(@MemoryLimit, 'MB',  '')));
		
                    SET @TotalBufferSpace = (SELECT col1 FROM #BackupResults WHERE col1 LIKE '%Total buffer space%');
                    SET @TotalBufferSpace = REPLACE(@TotalBufferSpace, 'Total buffer space:', ''); 
                    SET @TotalBufferSpace = LTRIM(RTRIM(REPLACE(@TotalBufferSpace, 'MB', '')));

                    SET @FileSystemIOAlign = (SELECT col1 FROM #BackupResults WHERE col1 LIKE '%Filesystem i/o alignment%');
                    SET @FileSystemIOAlign = REPLACE(@FileSystemIOAlign, 'Filesystem i/o alignment:', ''); 
                    SET @FileSystemIOAlign = LTRIM(RTRIM(@FileSystemIOAlign));

                    SET @SetsOfBuffers = (SELECT col1 FROM #BackupResults WHERE col1 LIKE '%Sets Of Buffers%');
                    SET @SetsOfBuffers = REPLACE(@SetsOfBuffers, 'Sets Of Buffers:', ''); 
                    SET @SetsOfBuffers = LTRIM(RTRIM(@SetsOfBuffers));

                    IF @Buffercount = 0 OR @Buffercount IS NULL
                        BEGIN
                            SET @Buffercount = (SELECT col1 FROM #BackupResults WHERE col1 LIKE '%BufferCount%');
                            SET @Buffercount = REPLACE(@Buffercount, 'BufferCount:', ''); 
                            SET @Buffercount = LTRIM(RTRIM(@Buffercount));

                        END

                    IF @MaxTransferSize = 0 OR @MaxTransferSize IS NULL
                        BEGIN
                            SET @MaxTransferSize = (SELECT col1 FROM #BackupResults WHERE col1 LIKE '%MaxTransferSize%' AND col1 NOT LIKE 'Min%');
                            SET @MaxTransferSize = REPLACE(@MaxTransferSize, 'MaxTransferSize:', ''); 
                            SET @MaxTransferSize = LTRIM(RTRIM(REPLACE(@MaxTransferSize, 'KB', '')));
                            SET @MaxTransferSize = LTRIM(RTRIM(CAST(@MaxTransferSize AS BIGINT))) * 1024;
	
                        END
------------------------------------------------------------
--------------------END Parse T3213-------------------------
------------------------------------------------------------


----------------------------------------------------------------------
------------BEGIN Clear non-msg txt from Backup Error-----------------
----------------------------------------------------------------------
----Currently @BackupError has error and trace flag info even when it fails.
----It's nicer for the user if we try to get rid of some of the extra data
----so the error msg is easier to read.
----select '#BackupResults' as BackupResults, * from #BackupResults

If NOT EXISTS (select col1 from #BackupResults WHERE col1 LIKE '%BACKUP%successfully%')
	BEGIN
		DELETE FROM #BackupResults
			WHERE col1 IS NULL
			OR	  col1 LIKE '%DBCC execution completed%'
			OR	  col1 LIKE '%Memory limit%'
			OR	  col1 LIKE '%BufferCount%'
			OR	  col1 LIKE '%Sets of Buffers%'
			OR	  col1 LIKE '%TransferSize%'
			OR	  col1 LIKE '%Total buffer space%'
			OR	  col1 LIKE '%Tabular data%'
			OR	  col1 LIKE '%Fulltext data device count%'
			OR	  col1 LIKE '%Filestream device count%'
			OR	  col1 LIKE '%TXF device count%'
			OR	  col1 LIKE '%i/o alignment%'
			OR	  col1 LIKE '%Media Buffer%'
			OR	  col1 LIKE '%Backup/Restore buffer configuration parameters%'
			OR	  col1 LIKE '---%'
			OR	  col1 = ''
			OR	  col1 LIKE '      %'
	END
----------------------------------------------------------------------
------------END Clear non-msg txt from Backup Error-------------------
----------------------------------------------------------------------

                    SELECT @Errors = STUFF((SELECT' ' + col1
                                                FROM #BackupResults AS T1
                                                ORDER BY T1.ID
                                            FOR XML PATH('')), 1, 1, '')
                        FROM #BackupResults AS T2;

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, '@Errors'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID

				INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
				SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupDB', '@Errors', @Errors
END
-------------------DEBUG-------------------------------

                    IF @Errors LIKE '%BACKUP%successfully%'
                        BEGIN
                            SET @BackupError = 'OK'
                        END
                    IF @Errors LIKE '%The certificate used for encrypting the database encryption key has not been backed up. You should immediately back up the certificate and the private key associated with the certificate%BACKUP%successfully%' 
                        BEGIN
                            SET @BackupError = 'OK'
                        END
                    IF @Errors NOT LIKE '%BACKUP%successfully%'
                        OR @Errors IS NULL
                        BEGIN
                            SET @BackupError = 'FAIL'
                        END
	 
                    DROP TABLE #BackupResults

------Insert into Work table so other SPs can easily see the backup result.
------A good example of this is when the Master SP uses this for Verify.
INSERT Minion.Work(ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value)
SELECT @ExecutionDateTime, 'Backup', @DBName, @BackupType, '@BackupError', 'BackupDB', @BackupError

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, '@BackupError'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID

				INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
				SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupDB', '@BackupError', @BackupError
END
-------------------DEBUG-------------------------------


-------------------------BEGIN POSTBackup Log-------------------------
                    SET @BackupEndDateTime = GETDATE();

                    IF @BackupError = 'FAIL'
                        BEGIN
                            UPDATE
                                    Minion.BackupLogDetails
                                SET
                                    STATUS = 'FATAL ERROR: ' + ISNULL(@Errors, ' The command object was NULL. This is an unusual situation; contact support. If you wish to troubleshoot on your own, this error was probably caused by the @TotalCMD variable being NULL when the backup was run.'),
                                    BackupEndDateTime = @BackupEndDateTime,
                                    BackupTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @BackupStartDateTime, 21), CONVERT(VARCHAR(25), @BackupEndDateTime, 21))
                                WHERE
                                    ID = @BackupLogDetailsID;
                            RETURN
                        END


-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'Backup FAIL'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID

				INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
				SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupDB', '@TotalCMD', @TotalCMD
END
-------------------DEBUG-------------------------------

                    IF @BackupError = 'OK'
                        BEGIN
                            UPDATE
                                    Minion.BackupLogDetails
                                SET
                                    STATUS = 'Backup Complete',
                                    PctComplete = 100,
                                    BackupEndDateTime = @BackupEndDateTime,
                                    BackupTimeInSecs = DATEDIFF(ms, CONVERT(VARCHAR(25), @BackupStartDateTime, 21), CONVERT(VARCHAR(25), @BackupEndDateTime, 21)) / 1000.0,
                                    Buffercount = @Buffercount,
                                    MaxTransferSize = @MaxTransferSize,
                                    MemoryLimitInMB = @MemoryLimit,
                                    VLFs = @VLFs,
                                    TotalBufferSpaceInMB = @TotalBufferSpace,
                                    FileSystemIOAlignInKB = @FileSystemIOAlign,
                                    SetsOfBuffers = ISNULL(@SetsOfBuffers, 1),
                                    Verified = 0,
									BackupEncryptionCertName = @BackupEncryptionCertName,
									BackupEncryptionAlgorithm = @EncrAlgorithm,
									BackupEncryptionCertThumbPrint = @BackupEncryptionCertThumbPrint,
									Warnings = CASE
													WHEN @Errors LIKE '%The certificate used for encrypting the database encryption key has not been backed up. You should immediately back up the certificate and the private key associated with the certificate%BACKUP%successfully%'  THEN @Errors
													ELSE NULL
											   END
                                WHERE
                                    ID = @BackupLogDetailsID;

                        END;

-------------------------END POSTBackup Log---------------------------

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'BACKUP OK'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID

				INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
				SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupDB', '@TotalCMD', @TotalCMD
END
-------------------DEBUG-------------------------------

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-----------------------------BEGIN Shrink Log-------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

                    IF @BackupType = 'Log'
                        BEGIN --@BackupType = 'Log'
                            IF @ShrinkLogOnLogBackup = 1
                                BEGIN --@ShrinkLogOnLogBackup = 1

-------------BEGIN Log Shrink Info---------------
                                    IF @BackupError = 'OK'
                                        BEGIN
                                            UPDATE Minion.BackupLogDetails
                                                SET STATUS = 'Shrinking Log'
                                                WHERE
                                                    ID = @BackupLogDetailsID;
                                        END;

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'Shrinking Log'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID

				--INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
				--SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupDB', '@TotalCMD', @TotalCMD
END
-------------------DEBUG-------------------------------

-------------END Log Shrink Info---------------

                                    INSERT #LogFiles
                                            (
                                             LogName
											)
                                        SELECT name -- size is # of pages so it's *8 for each 8KB page.
                                            FROM sys.master_files
                                            WHERE
                                                DB_NAME(database_id) = @DBName
                                                AND type_desc = 'LOG'

                                    IF @PRELogSizeInMB >= @ShrinkLogThresholdInMB
                                        BEGIN -- @LogSUM >= @ShrinkLogThresholdInMB
                                            DECLARE
                                                @currLogFile VARCHAR(300),
                                                @LogShrinkSQL NVARCHAR(1000),
												@ShrinkFileErrors varchar(max);

                                            DECLARE ShrinkLog CURSOR READ_ONLY
                                            FOR
                                                SELECT LogName FROM #LogFiles

                                            OPEN ShrinkLog

                                            FETCH NEXT FROM ShrinkLog INTO @currLogFile
                                            WHILE (@@fetch_status <> -1)
                                                BEGIN
												SELECT @ShrinkLogSizeInMB AS ShrinkLogSizeInMB
                                                    SET @LogShrinkSQL = 'USE ['
                                                        + @DBName
                                                        + ']; DBCC SHRINKFILE (['
                                                        + @currLogFile 
                                                    IF @ShrinkLogSizeInMB > 0
                                                        BEGIN
                                                            SET @LogShrinkSQL = @LogShrinkSQL
                                                              + '], '
                                                              + CAST(@ShrinkLogSizeInMB AS VARCHAR(10))
                                                        END
                                                    SET @LogShrinkSQL = @LogShrinkSQL + ')' 
	
-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
				INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
				SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupDB', '@LogShrinkSQL', @LogShrinkSQL
END
-------------------DEBUG-------------------------------	
SELECT @DBIsInAG as DBIsInAG
SELECT @CurrentPrimaryReplica as CurrentPrimaryReplica	
							If @DBIsInAG = 1
								BEGIN --@DBIsInAG = 1
									If @CurrentPrimaryReplica <> @ServerInstance
										BEGIN --@CurrentPrimaryReplica <> @ServerInstance										
												SET @PreCMD = 'sqlcmd -r 1 -S"' + @CurrentPrimaryReplica
													+ CAST(@Port AS VARCHAR(6))
													+ '" -q "' 
												SET @TotalCMD = @PreCMD + @LogShrinkSQL + '"'
												--PRINT @TotalCMD
												INSERT #LogShrinkResults (col1)
														EXEC xp_cmdshell @TotalCMD;	

												DELETE FROM #LogShrinkResults WHERE col1 IS NULL

												SELECT @ShrinkFileErrors = STUFF((
												SELECT ' ' + col1
												FROM #LogShrinkResults AS T1
												ORDER BY T1.ID
											FOR XML PATH('')), 1, 1, '')
											FROM #LogShrinkResults AS T2;

											IF @ShrinkFileErrors NOT LIKE '%Msg%Level%State%'
												BEGIN
													 UPDATE Minion.BackupLogDetails
													 SET
													 Warnings = CASE WHEN @ShrinkFileErrors LIKE '%error%' THEN ISNULL(Warnings, '') + 'SHRINKFILE ERRORS: ' + @ShrinkFileErrors
												END,
                                    DeleteFilesStartDateTime = @BackupFilesDeleteStartDateTime,
                                    DeleteFilesEndDateTime = @BackupFilesDeleteEndDateTime,
                                    DeleteFilesTimeInSecs = @BackupFilesDeleteTimeInSecs
                                WHERE
                                    ID = @BackupLogDetailsID;
												END
											END --@CurrentPrimaryReplica <> @ServerInstance
									END --@DBIsInAG = 1
													
								If @DBIsInAG = 0
									BEGIN
										--PRINT @LogShrinkSQL
                                        EXEC (@LogShrinkSQL)
                                    END   
		
                                                    FETCH NEXT FROM ShrinkLog INTO @currLogFile
                                                END

                                            CLOSE ShrinkLog
                                            DEALLOCATE ShrinkLog
                                        END -- @LogSUM >= @ShrinkLogThresholdInMB

----------- BEGIN POST Log Reuse Wait -----------
                                    SET @POSTLogReuseWait = (SELECT log_reuse_wait_desc FROM sys.databases WHERE DB_NAME(database_id) = @DBName)
-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
			INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
			SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupDB', '@POSTLogReuseWait', @POSTLogReuseWait
END
-------------------DEBUG-------------------------------	

----------- END POST Log Reuse Wait -----------

----------- BEGIN POST SQLPERF --------------
                                    INSERT #LogSize
                                            (
                                             DBName, SizeInMB, SpaceUsed, STATUS
											)
                                            EXEC ('DBCC SQLPERF(LOGSPACE)')
----Get sum of all log file sizes for the current DB.
----Use sys.master_files to avoid the dynamic sql of using sys.database_files
                                    SELECT
                                            @POSTLogSizeInMB = SizeInMB,
                                            @POSTLogSpaceUsed = SpaceUsed
                                        FROM #LogSize
                                        WHERE
                                            DBName = @DBName

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
			INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
			SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupDB', '@POSTLogSizeInMB', @POSTLogSizeInMB

			INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
			SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupDB', '@POSTLogSpaceUsed', @POSTLogSpaceUsed
END
-------------------DEBUG-------------------------------	

----------- END POST SQLPERF ----------------

-------------BEGIN Log Shrink Info---------------
                                    IF @BackupError = 'OK'
                                        BEGIN
 
                                            UPDATE Minion.BackupLogDetails
                                                SET
                                                    ShrinkLogOnLogBackup = @ShrinkLogOnLogBackup,
                                                    ShrinkLogThresholdInMB = @ShrinkLogThresholdInMB,
                                                    ShrinkLogSizeInMB = @ShrinkLogSizeInMB,
                                                    PreBackupLogSizeInMB = @PRELogSizeInMB,
                                                    PreBackupLogUsedPct = @PRELogSpaceUsed,
                                                    PostBackupLogSizeInMB = @POSTLogSizeInMB,
                                                    PostBackupLogUsedPct = @POSTLogSpaceUsed,
                                                    PreBackupLogReuseWait = @PRELogReuseWait,
                                                    PostBackupLogReuseWait = @POSTLogReuseWait
                                                WHERE
                                                    ID = @BackupLogDetailsID;

                                        END;

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'Backup OK-LogSize Details'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------	

-------------END Log Shrink Info---------------

                                    DROP TABLE #LogSize;
                                    DROP TABLE #LogFiles;

                                END --@ShrinkLogOnLogBackup = 1
                        END --@BackupType = 'Log'

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-----------------------------END Shrink Log---------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------


                END--End StmtOnly = 0

---------- End Backup current DB.-----------
--------------------------------------------

            IF @StmtOnly = 1
                BEGIN
                    PRINT @BackupCmd
                END

-- Backups the database after the deletion 
            IF (@DeleteFilesBefore = 0)
                BEGIN --@DeleteFilesBefore = 0

If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
--Only delete the files if the backup succeeds.
                    IF @BackupError = 'OK'
                        BEGIN --@BackupError = 'OK'
 


 ----------------------------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------BEGIN Log Delete Old Files------------------
 ----------------------------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------------------------
                            UPDATE Minion.BackupLogDetails
                                SET
                                    STATUS = 'Deleting backup files'
                                WHERE
                                    ID = @BackupLogDetailsID;
 ---------------END Log Delete Old Files--------------------				  

 -------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT ExecutionDateTime, STATUS, DBName, BackupType, 'Deleting backup files'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------	


 ----------------BEGIN Delete Old Files---------------------
                    SET @BackupFilesDeleteStartDateTime = GETDATE();
					--DECLARE @DeleteCMD VARCHAR(2000)
					SET @DeleteCMD = ' EXEC Minion.BackupFilesDelete  ' + '''' + @DBName + '''' + ', @RetHrs = NULL, @Delete = 1, @EvalDateTime = NULL'
                    SET @PreCMD = 'sqlcmd -r 1 -S"' + @ServerInstance
                        + CAST(@Port AS VARCHAR(6))
						+ '" -d "' + @MaintDB + '" -q "' 
                    SET @TotalCMD = @PreCMD + @DeleteCMD + '"'


					--DECLARE @FileDeleteErrors VARCHAR(max);
                    INSERT #DeleteResults (col1)
                            EXEC xp_cmdshell @TotalCMD;
                            --EXEC Minion.BackupFilesDelete @DBName = @DBName,
                            --    @RetHrs = NULL, @Delete = 1,
                            --    @EvalDateTime = NULL;
--SELECT '#DeleteResults', * FROM #DeleteResults

							DELETE FROM #DeleteResults
								   WHERE col1 IS NULL
									  OR col1 = 'output'
									  OR col1 = 'NULL'
									  OR col1 LIKE '%-------------------------------------%'

                            SET @BackupFilesDeleteEndDateTime = GETDATE();

                            SET @BackupFilesDeleteTimeInSecs = DATEDIFF(ss, @BackupFilesDeleteStartDateTime, @BackupFilesDeleteEndDateTime)


							SELECT @FileDeleteErrors = 'FILE DELETE ERROR: '
										+ STUFF((SELECT ' ' + col1
											FROM #DeleteResults AS T1
											ORDER BY T1.ID
											FOR XML PATH('')), 1, 1, '')
									FROM #DeleteResults AS T2;

----------------END Delete Old Files------------------------

---------------BEGIN Log Delete Old Files------------------
                            UPDATE Minion.BackupLogDetails
                                SET
									Warnings = CASE
													WHEN @FileDeleteErrors LIKE '%error%' THEN ISNULL(Warnings, '') + 'FILE DELETE ERRORS: ' + @FileDeleteErrors
													ELSE Warnings
												END,
                                    DeleteFilesStartDateTime = @BackupFilesDeleteStartDateTime,
                                    DeleteFilesEndDateTime = @BackupFilesDeleteEndDateTime,
                                    DeleteFilesTimeInSecs = @BackupFilesDeleteTimeInSecs
                                WHERE
                                    ID = @BackupLogDetailsID;
---------------END Log Delete Old Files--------------------


 -------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'Delete files times'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------	

 ----------------------------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------END Log Delete Old Files--------------------
 ----------------------------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------------------------

                        END; --@BackupError = 'OK'
                END; --@DeleteFilesBefore = 0
	END --@StmtOnly = 0
--!!!!!!Move this section below the size add and change size to save file sizes here as well as saving totals to BackupLog.
---------------------------------------
--------BEGIN Log File Info------------
---------------------------------------
If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
            IF @BackupError = 'OK'
                BEGIN
                    INSERT Minion.BackupFiles
                            (
                             ExecutionDateTime,
                             Op,
                             Status,
                             DBName,
                             ServerLabel,
                             NETBIOSName,
                             BackupType,
                             BackupLocType,
                             BackupDrive,
                             BackupPath,
                             FullPath,
                             FullFileName,
                             FileName,
                             DateLogic,
                             Extension,
                             RetHrs,
                             IsMirror,
                             ToBeDeleted,
                             IsDeleted,
                             IsArchive
							)
                        SELECT
                                @ExecutionDateTime,
                                'Backup',
                                'Complete',
                                @DBName,
                                ServerLabel,
                                NETBIOSName,
                                @BackupType,
                                BackupLocType,
                                BackupDrive,
                                BackupPath,
                                FullPath,
                                FullFileName,
                                FileName,
                                DateLogic,
                                Extension,
                                RetHrs,
                                IsMirror,
                                DATEADD(hh, RetHrs, @ExecutionDateTime),
                                0 AS IsDeleted,
                                0 AS IsArchive
                            FROM
                                #Backup
                END
	END --@StmtOnly = 0
---------------------------------------
--------END Log File Info--------------
---------------------------------------


------------------------------------------------------------------------------------------------
-------------BEGIN Cert Backup------------------------------------------------------------------
------------------------------------------------------------------------------------------------
IF @StmtOnly = 0
	BEGIN --@StmtOnly = 0
IF @DBName = 'master'
BEGIN
	SELECT @BackupCert = BackupCert
	FROM Minion.BackupCert 
	WHERE CertType = 'ServerCert';
END	 

IF @LogDBType = 'User' AND @BackupType = 'Full'
BEGIN
	SELECT @BackupCert = BackupCert,
		   @CertPword = DECRYPTBYCERT(CERT_ID('MinionEncrypt'), CertPword)
	FROM Minion.BackupCert 
	WHERE CertType = 'DatabaseCert'
END	 

                IF @BackupCert = 1
                    BEGIN --@BackupCert = 1

--------------BEGIN Get Cert Paths-------------
                                    DECLARE
                                        @BackupCerti TINYINT,
                                        @FileCounter TINYINT,
                                        @MaxCertDrives TINYINT,
                                        @CertName VARCHAR(100),
                                        @CertRetHrs INT,
										@ServiceMasterKeyPWord varchar(max);

                                    CREATE TABLE #CertPaths
                                        (
                                         ID INT IDENTITY(1, 1),
										 CertName VARCHAR(150) COLLATE DATABASE_DEFAULT,
                                         CertPword VARBINARY(max), 
										 DBName VARCHAR(400) COLLATE DATABASE_DEFAULT,
                                         BackupType VARCHAR(20) COLLATE DATABASE_DEFAULT,
                                         BackupLocType VARCHAR(20) COLLATE DATABASE_DEFAULT,
                                         BackupDrive VARCHAR(100) COLLATE DATABASE_DEFAULT,
                                         BackupPath VARCHAR(1000) COLLATE DATABASE_DEFAULT,
										 FileName VARCHAR(500) COLLATE DATABASE_DEFAULT,
										 FileExtension VARCHAR(50) COLLATE DATABASE_DEFAULT,
                                         ServerLabel VARCHAR(100) COLLATE DATABASE_DEFAULT,
                                         RetHrs INT,
                                         PathOrder TINYINT
                                        )

                                    CREATE TABLE #ServiceMasterKeyPaths
                                        (
                                         ID INT IDENTITY(1, 1),
                                         DBName sysname COLLATE DATABASE_DEFAULT,
                                         BackupType VARCHAR(20) COLLATE DATABASE_DEFAULT,
                                         BackupLocType VARCHAR(20) COLLATE DATABASE_DEFAULT,
                                         BackupDrive VARCHAR(100) COLLATE DATABASE_DEFAULT,
                                         BackupPath VARCHAR(1000) COLLATE DATABASE_DEFAULT,
                                         ServerLabel VARCHAR(100) COLLATE DATABASE_DEFAULT,
                                         RetHrs INT,
                                         PathOrder TINYINT
                                        )
CREATE TABLE #CertName
(
ID INT IDENTITY(1,1),
CertName VARCHAR(150)
)
CREATE TABLE #CertDirExist
    (
        DirExist VARCHAR(2000) COLLATE DATABASE_DEFAULT
    ) 
CREATE TABLE #CertBackup
    (
        ID INT IDENTITY(1, 1),
        col1 VARCHAR(MAX)
        COLLATE DATABASE_DEFAULT
    )
IF @DBName = 'master'
BEGIN
--------------New stuff------------
INSERT #CertPaths
        (CertName, CertPword, DBName, BackupType, BackupLocType, BackupDrive, BackupPath,
         FileName, FileExtension, ServerLabel, RetHrs, PathOrder)
	SELECT sc.name, BC.CertPword,
	CP.DBName, CP.BackupType, CP.BackupLocType, CP.BackupDrive, CP.BackupPath,
         CP.FileName, CP.FileExtension, CP.ServerLabel, CP.RetHrs, CP.PathOrder 
	FROM Minion.BackupCert BC
	INNER JOIN Minion.BackupSettingsPath CP
	ON BC.CertType = CP.BackupType
	INNER JOIN master.sys.certificates sc
	ON 1=1
	WHERE sc.name NOT LIKE '##%##'
		AND BC.CertType = 'ServerCert'
        AND CP.IsActive = 1
UNION ALL
	SELECT 'ServiceMasterKey', BC.CertPword,
	CP.DBName, CP.BackupType, CP.BackupLocType, CP.BackupDrive, CP.BackupPath,
         CP.FileName, CP.FileExtension, CP.ServerLabel, CP.RetHrs, CP.PathOrder 
	FROM Minion.BackupCert BC
	INNER JOIN Minion.BackupSettingsPath CP
	ON BC.CertType = CP.BackupType
	WHERE BC.CertType = 'ServiceMasterKey'
        AND CP.IsActive = 1

--------------New stuff------------

END

IF @LogDBType = 'User'
BEGIN
	DECLARE @CertSQL VARCHAR(1000);
		--SET @CertSQL = 'SELECT name FROM [' + @DBName + '].sys.certificates WHERE NAME NOT LIKE ''##%##'''

	SET @CertSQL = 'SELECT sc.name, BC.CertPword,
	CP.DBName, CP.BackupType, CP.BackupLocType, CP.BackupDrive, CP.BackupPath,
         CP.FileName, CP.FileExtension, CP.ServerLabel, CP.RetHrs, CP.PathOrder 
	FROM [' + @MaintDB + '].Minion.BackupCert BC
	INNER JOIN [' + @MaintDB + '].Minion.BackupSettingsPath CP
	ON BC.CertType = CP.BackupType
	INNER JOIN master.sys.certificates sc
	ON 1=1
	WHERE sc.name NOT LIKE ''##%##''
		AND BC.CertType = ''DatabaseCert''
        AND CP.IsActive = 1'
		INSERT #CertPaths
        (CertName, CertPword, DBName, BackupType, BackupLocType, BackupDrive, BackupPath,
         FileName, FileExtension, ServerLabel, RetHrs, PathOrder)
	EXEC(@CertSQL)
END

--IF @DBName = 'master'
--BEGIN --@DBName = 'master'
--        INSERT #CertPaths
--                (
--                    DBName,
--                    BackupType,
--                    BackupLocType,
--                    BackupDrive,
--                    BackupPath,
--                    ServerLabel,
--                    RetHrs,
--                    PathOrder
--				)
--            SELECT
--                    DBName,
--                    BackupType,
--                    BackupLocType,
--                    BackupDrive,
--                    BackupPath,
--                    ISNULL(ServerLabel, @@SERVERNAME),
--                    RetHrs,
--                    PathOrder
--                FROM
--                    Minion.BackupSettingsPath
--                WHERE
--                    IsActive = 1
--                    AND BackupType IN ('ServerCert')

--        INSERT #ServiceMasterKeyPaths
--                (
--                    DBName,
--                    BackupType,
--                    BackupLocType,
--                    BackupDrive,
--                    BackupPath,
--                    ServerLabel,
--                    RetHrs,
--                    PathOrder
--				)
--            SELECT
--                    DBName,
--                    BackupType,
--                    BackupLocType,
--                    BackupDrive,
--                    BackupPath,
--                    ISNULL(ServerLabel, @@SERVERNAME),
--                    RetHrs,
--                    PathOrder
--                FROM
--                    Minion.BackupSettingsPath
--                WHERE
--                    IsActive = 1
--                    AND BackupType IN ('ServiceMasterKey')
--END --@DBName = 'master'

----IF @LogDBType = 'User'
----BEGIN --@BackupType = 'User'
----        INSERT #CertPaths
----                (
----                    DBName,
----                    BackupType,
----                    BackupLocType,
----                    BackupDrive,
----                    BackupPath,
----                    ServerLabel,
----                    RetHrs,
----                    PathOrder
----				)
----            SELECT
----                    DBName,
----                    BackupType,
----                    BackupLocType,
----                    BackupDrive,
----                    BackupPath,
----                    ISNULL(ServerLabel, @@SERVERNAME),
----                    RetHrs,
----                    PathOrder
----                FROM
----                    Minion.BackupSettingsPath
----                WHERE
----                    IsActive = 1
----                    AND BackupType = 'DatabaseCert'
----END --@BackupType = 'User'

DECLARE 
		@SQL nvarchar(200),
		@currCertName VARCHAR(150),
		@currCertPword VARBINARY(max),
		@currDBName VARCHAR(400),
		@currBackupType VARCHAR(20),
		@currBackupLocType VARCHAR(20),
		@currBackupDrive VARCHAR(100),
		@currBackupPath VARCHAR(1000),
		@currFileName VARCHAR(500),
		@currFileExtension VARCHAR(50),
		@currServerLabel VARCHAR(150),
		@currRetHrs INT,
		@currPathOrder int;

DECLARE CertBackCursor CURSOR
READ_ONLY
FOR SELECT CertName, CertPword, DBName, BackupType, BackupLocType, BackupDrive, BackupPath,
         FileName, FileExtension, ServerLabel, RetHrs, PathOrder
	FROM #CertPaths

OPEN CertBackCursor

	FETCH NEXT FROM CertBackCursor INTO @currCertName, @currCertPword, @currDBName, @currBackupType, @currBackupLocType, @currBackupDrive, @currBackupPath, @currFileName, @currFileExtension, @currServerLabel, @currRetHrs, @currPathOrder
	WHILE (@@fetch_status <> -1)
	BEGIN
		

                                    DECLARE
                                        @NumberOfCertFiles TINYINT,
                                        @FullCertName VARCHAR(2000),
                                        @FullCertPvkName VARCHAR(2000),
										@CertBackupType VARCHAR(20),
                                        @CertBackupDrive VARCHAR(100),
                                        @CertBackupPath VARCHAR(1000),
                                        @CertExtension VARCHAR(5),
                                        @CertCertExtension VARCHAR(5),
                                        @CertPvkExtension VARCHAR(5),
                                        @PathOrder TINYINT,
                                        @FileNumber TINYINT,
                                        @CertFileErrors VARCHAR(MAX),
                                        @CertFileExistCMD VARCHAR(8000),
                                        @FullCertPath VARCHAR(2000),
                                        @CertServerLabel VARCHAR(150),
                                        @CertBackupLocType VARCHAR(20);

										IF @currFileName IS NULL OR @currFileName = '' OR UPPER(@currFileName) = 'MINIONDEFAULT'
											BEGIN
												SET @currFileName = @currCertName + '%Date%';
											END

										IF @currFileName LIKE '%\%CertName\%%' ESCAPE '\'
											BEGIN
												SET @currFileName = REPLACE(@currFileName, '%CertName%', @currCertName);
											END

										If @currCertName <> 'ServiceMasterKey'
												BEGIN --Not ServiceMasterKey
											IF @currFileExtension IS NULL OR @currFileExtension = '' OR UPPER(@currFileExtension) = 'MINIONDEFAULT'
												BEGIN
													SET @currFileExtension = '.cer';
												END											
											END --Not ServiceMasterKey

										If @currCertName = 'ServiceMasterKey'
												BEGIN --ServiceMasterKey
											IF @currFileExtension IS NULL OR UPPER(@currFileExtension) = 'MINIONDEFAULT'
												BEGIN
													SET @currFileExtension = '.smk';
												END											
											END --ServiceMasterKey

										----EXEC Minion.DBMaintDynamicNameParse @DBName, @DynamicName = @currBackupDrive OUTPUT, @ServerLabel = @currServerLabel;
										EXEC Minion.DBMaintInlineTokenParse @DBName, @DynamicName = @currBackupPath OUTPUT, @ServerLabel = @currServerLabel;
										EXEC Minion.DBMaintInlineTokenParse @DBName, @DynamicName = @currCertName OUTPUT, @ServerLabel = @currServerLabel;
										EXEC Minion.DBMaintInlineTokenParse @DBName, @DynamicName = @currFileName OUTPUT, @ServerLabel = @currServerLabel;
										EXEC Minion.DBMaintInlineTokenParse @DBName, @DynamicName = @currFileExtension OUTPUT, @ServerLabel = @currServerLabel;
										

                                        BEGIN --Cert While

										If @currCertName <> 'ServiceMasterKey'
											BEGIN --Not ServiceMasterKey
                                                  SET @CertBackupDrive = @currBackupDrive;
                                                    SET @CertBackupPath = @currBackupPath;
                                                    SET @FullCertName = @currBackupDrive + @currBackupPath
														+ @currFileName + @currFileExtension;
                                                    SET @FullCertPvkName = @currBackupDrive + @currBackupPath 
														+ @currFileName + '.pvk';
                                                    SET @FullCertPath = @currBackupDrive
                                                    + @currBackupPath;
                                                    SET @CertCertExtension = @currFileExtension;
                                                    SET @CertPvkExtension = '.pvk';
                                                    SET @CertServerLabel = @currServerLabel;
                                                    SET @CertBackupLocType = @currBackupLocType;
                                                    SET @CertRetHrs = @currRetHrs;
													SET @CertBackupType = @currBackupType;
											END --Not ServiceMasterKey

										If @currCertName = 'ServiceMasterKey'
											BEGIN -- ServiceMasterKey
                                                    SET @CertBackupDrive = @currBackupDrive;
                                                    SET @CertBackupPath = @currBackupPath;
                                                    SET @FullCertName = @currBackupDrive + @currBackupPath
														+ @currFileName + @currFileExtension;
                                                    SET @FullCertPath = @currBackupDrive
                                                    + @currBackupPath;
                                                    SET @CertCertExtension = @currFileExtension;
                                                    SET @CertServerLabel = @currServerLabel;
                                                    SET @CertBackupLocType = @currBackupLocType;
                                                    SET @CertRetHrs = @currRetHrs;
													SET @CertBackupType = @currBackupType;
											END -- ServiceMasterKey

----SELECT @CertBackupDrive AS CertBackupDrive, @CertBackupPath AS CertBackupPath, @CertServerLabel AS ServerLabel, @FullCertName AS FullCertName, @CertRetHrs AS CertRetHrs, @currCertName
---------------------BEGIN Create Cert Path----------------------
--SELECT @FullCertPath AS FullCertPath
                                            SET @CertFileErrors = '';
                                            SET @CertFileExistCMD = ''; 
                                            SET @CertFileExistCMD = ' powershell "If ((test-path '''
                                                + @FullCertPath
                                                + ''') -eq $False){MD ' + ''''
                                                + @FullCertPath
                                                + ''' -errorvariable err -erroraction silentlycontinue} If ($err.count -gt 0){$Final = $err} ELSE{$Final = ''Dir Exists''}; $Final" '

                                            INSERT #CertDirExist
                                            EXEC master..xp_cmdshell @CertFileExistCMD
--SELECT * FROM #CertDirExist;
                                            IF (SELECT TOP 1 DirExist FROM #CertDirExist WHERE DirExist IS NOT NULL) <> 'Dir Exists'
                                                BEGIN
                                                    SELECT @CertFileErrors = @CertFileErrors
                                                            + 'Cert Backup ERROR: '
                                                            + (SELECT TOP 1 DirExist FROM #CertDirExist) + '  '
                                         --       END	 

                                            TRUNCATE TABLE #CertDirExist;
----SET @Certi = @Certi + 1;      
END --Cert While

---- Reset table so the mirror backups can use it.
                                            TRUNCATE TABLE #CertDirExist
--		PRINT @CertFileErrors
                                            IF @CertFileErrors <> '' OR @CertFileErrors IS NOT NULL
                                                BEGIN
                                                    UPDATE Minion.BackupLogDetails
                                                        SET 
                                                            Warnings = ISNULL(Warnings, '') + @CertFileErrors
                                                        WHERE
                                                            ID = @BackupLogDetailsID;

                                                END


 -------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'Cert Warnings'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------	
SET @BackupCmd = NULL;

---------------------END Create Cert Cert Path------------------------
                                            IF @CertFileErrors = '' OR @CertFileErrors IS NULL
                                                BEGIN -- Run Cert Backup
													If @currCertName <> 'ServiceMasterKey'
														BEGIN
															SET @BackupCmd = 'BACKUP CERTIFICATE ['
																+ @currCertName
																+ '] TO FILE = '''
																+ @FullCertName
																+ ''''
																+ ' WITH PRIVATE KEY (FILE = '''
																+ @FullCertPvkName
																+ ''', ENCRYPTION BY PASSWORD = '
																+ '''' + CAST(DECRYPTBYCERT(CERT_ID('MinionEncrypt'), @currCertPword) AS VARCHAR(2000))
																+ ''')'
														END

													If @currCertName = 'ServiceMasterKey'
														BEGIN
															SET @BackupCmd = 'BACKUP SERVICE MASTER KEY '
																+ 'TO FILE = '''
																+ @FullCertName
																+ ''''
																+ ' ENCRYPTION BY PASSWORD = '
																+ '''' + CAST(DECRYPTBYCERT(CERT_ID('MinionEncrypt'), @currCertPword) AS VARCHAR(2000))
																+ ''''
														END

                                                    SET @PreCMD = '';
                                                    SET @TotalCMD = '';
                                                    SET @ServerInstance = @@ServerName;

----SELECT @currCertName AS CertName, @FullCertName AS FullCertName, @FullCertPvkName AS CertPvkName, CAST(DECRYPTBYCERT(CERT_ID('MinionEncrypt'), @currCertPword) AS VARCHAR(2000)) AS CertPWord, @BackupCmd AS BackupCmd
                                                    SET @PreCMD = 'sqlcmd -d "' +@DBName + '" -M -r 1 -S'
                                                        + @ServerInstance
                                                        + CAST(@Port AS VARCHAR(6))
                                                    SET @TotalCMD = @PreCMD
                                                        + ' -q "' + @BackupCmd
                                                        + '"'

                                                    INSERT #CertBackup (col1)
                                                   EXEC xp_cmdshell @TotalCMD;
----PRINT @TotalCMD
----SELECT * FROM #CertBackup
                                                    DELETE FROM #CertBackup
                                                        WHERE
                                                            col1 IS NULL;

                                                    DECLARE @CertErrors VARCHAR(8000);
                                                    SET @CertErrors = '';

                                                    SELECT @CertErrors = 'Cert Backup ERROR: '
                                                            + STUFF(( SELECT ' ' + col1
                                                              FROM #CertBackup AS T1
                                                              ORDER BY T1.ID 
															  FOR XML PATH('')), 1, 1, '')
                                                        FROM #CertBackup AS T2;

                                                    IF @CertErrors <> ''
                                                        BEGIN
                                                            UPDATE Minion.BackupLogDetails
                                                              SET
                                                              Warnings = ISNULL(Warnings, '') + @CertErrors
                                                              WHERE
                                                              ID = @BackupLogDetailsID;

                                                        END


 -------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'CertErrors'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------	

---------------------------------------------------------
----------BEGIN Log Cert File----------------------------
---------------------------------------------------------
SELECT @FullCertName AS FullCertName, @currFileName AS FileName
                                                    IF @CertErrors = ''
                                                        BEGIN
                                                            INSERT Minion.BackupFiles
                                                              (
                                                              ExecutionDateTime,
                                                              Op,
                                                              Status,
                                                              DBName,
                                                              ServerLabel,
                                                              NETBIOSName,
                                                              BackupType,
                                                              BackupLocType,
                                                              BackupDrive,
                                                              BackupPath,
                                                              FullPath,
                                                              FullFileName,
                                                              FileName,
                                                              DateLogic,
                                                              Extension,
                                                              RetHrs,
                                                              IsMirror,
                                                              ToBeDeleted,
															  IsArchive
															  )
                                                              SELECT
                                                              @ExecutionDateTime,
                                                              'CertBackup',
                                                              'Complete',
                                                              @DBName,
                                                              @CertServerLabel,
                                                              @NETBIOSName,
                                                              'Certificate',
                                                              @CertBackupLocType,
                                                              @CertBackupDrive,
                                                              @CertBackupPath,
                                                              @CertBackupDrive + @CertBackupPath,
                                                              @FullCertName,
                                                              @currFileName
                                                              + @CertCertExtension,
                                                              @DateLogic,
                                                              @CertCertExtension,
                                                              @CertRetHrs,
                                                              0 AS IsMirror,
                                                              DATEADD(hh,
                                                              @CertRetHrs,
                                                              @ExecutionDateTime),
															  0;

                                                            INSERT Minion.BackupFiles
                                                              (
                                                              ExecutionDateTime,
                                                              Op,
                                                              Status,
                                                              DBName,
                                                              ServerLabel,
                                                              NETBIOSName,
                                                              BackupType,
                                                              BackupLocType,
                                                              BackupDrive,
                                                              BackupPath,
                                                              FullPath,
                                                              FullFileName,
                                                              FileName,
                                                              DateLogic,
                                                              Extension,
                                                              RetHrs,
                                                              IsMirror,
                                                              ToBeDeleted,
															  IsArchive
															  )
                                                              SELECT
                                                              @ExecutionDateTime,
                                                              'CertBackup',
                                                              'Complete',
                                                              @DBName,
                                                              @CertServerLabel,
                                                              @NETBIOSName,
                                                              'Private Key',
                                                              @CertBackupLocType,
                                                              @CertBackupDrive,
                                                              @CertBackupPath,
                                                              @CertBackupDrive + @CertBackupPath,
                                                              @FullCertPvkName,
                                                              @currFileName
                                                              + '.pvk',
                                                              @DateLogic,
                                                              '.pvk',
                                                              @CertRetHrs,
                                                              0 AS IsMirror,
                                                              DATEADD(hh,
                                                              @CertRetHrs,
                                                              @ExecutionDateTime),
															  0;
                                                        END
---------------------------------------------------------
----------END Log Cert File------------------------------
---------------------------------------------------------

                                                END -- Run Cert Backup
                                           -- SET @BackupCerti = @BackupCerti + 1;
                                        END --Cert While	 

--------BEGIN Log Cert Cert Info----------
                        IF @CertFileErrors = '' AND @CertErrors = ''
                            BEGIN
                                UPDATE Minion.BackupLogDetails
                                    SET
                                        BackupCert = @BackupCert,
                                        CertPword = ENCRYPTBYCERT(CERT_ID('MinionEncrypt'), @CertPword)
                                    WHERE
                                        ID = @BackupLogDetailsID;
                           END

 -------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupDB', '@CertFileErrors', @CertFileErrors
END
-------------------DEBUG-------------------------------	


--------END Log Cert Cert Info------------

                    

FETCH NEXT FROM CertBackCursor INTO @currCertName, @currCertPword, @currDBName, @currBackupType, @currBackupLocType, @currBackupDrive, @currBackupPath, @currFileName, @currFileExtension, @currServerLabel, @currRetHrs, @currPathOrder
			END
			  DROP TABLE #CertBackup
		CLOSE CertBackCursor
		DEALLOCATE CertBackCursor
    END --@BackupCert = 1
END --Begin StmtOnly = 0
------------------------------------------------------------------------------------------------
-------------END Cert Backup--------------------------------------------------------------------
------------------------------------------------------------------------------------------------


--------------------------------------------------
----------------BEGIN Run Postcode----------------
--------------------------------------------------
            IF @StmtOnly = 0
                BEGIN --@StmtOnly = 0
                    DECLARE
                        @PostCodeErrors VARCHAR(MAX),
                        @PostCodeErrorExist VARCHAR(MAX);
                    CREATE TABLE #PostCode
                        (
                         ID INT IDENTITY(1, 1),
                         col1 VARCHAR(MAX)
                        )

-----------------BEGIN Log DBPostCode------------------
                    SET @DBPostCodeStartDateTime = GETDATE();
                    UPDATE Minion.BackupLogDetails
                        SET
                            DBPostCode = @DBPostCode,
                            DBPostCodeStartDateTime = @DBPostCodeStartDateTime
                        WHERE
                            ID = @BackupLogDetailsID;
-----------------END Log DBPostCode--------------------

                    BEGIN TRY
                        EXEC (@DBPostCode) 
                    END TRY

                    BEGIN CATCH
                        SET @PostCodeErrors = ERROR_MESSAGE();
                    END CATCH

                    IF @PostCodeErrors IS NOT NULL
                        BEGIN
                            SELECT @PostCodeErrors = 'POSTCODE ERROR: ' + @PostCodeErrors
                        END	 

--------------------------------------------------
----------------END Run Postcode-------------------
--------------------------------------------------

-----BEGIN Log------

                    IF @DBPostCode IS NOT NULL
                        BEGIN -- @DBPostCode
-----------------------------------------------------
-------------BEGIN Log PostCode Success---------------
-----------------------------------------------------
                            IF @PostCodeErrors IS NULL
                                BEGIN --@PostCodeErrors IS NULL
                                    SET @DBPostCodeEndDateTime = GETDATE();
                                    UPDATE Minion.BackupLogDetails
                                        SET
                                            DBPostCodeEndDateTime = @DBPostCodeEndDateTime,
                                            DBPostCodeTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @DBPostCodeStartDateTime, 21), CONVERT(VARCHAR(25), @DBPostCodeEndDateTime, 21))
                                        WHERE
                                            ID = @BackupLogDetailsID;
                                END --@PostCodeErrors IS NULL
-----------------------------------------------------
-------------END Log PostCode Success-----------------
-----------------------------------------------------

-----------------------------------------------------
-------------BEGIN Log PostCode Failure---------------
-----------------------------------------------------
                            IF @PostCodeErrors IS NOT NULL
                                BEGIN --@PostCodeErrors IS NULL
                                    SET @DBPostCodeEndDateTime = GETDATE();
                                    UPDATE Minion.BackupLogDetails
                                        SET
                                            Warnings = ISNULL(Warnings, '')
                                            + @PostCodeErrors,
                                            DBPostCodeEndDateTime = @DBPostCodeEndDateTime,
                                            DBPostCodeTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @DBPostCodeStartDateTime, 21), CONVERT(VARCHAR(25), @DBPostCodeEndDateTime, 21))
                                        WHERE
                                            ID = @BackupLogDetailsID;
                                END --@PostCodeErrors IS NULL
-----------------------------------------------------
-------------END Log PostCode Failure-----------------
-----------------------------------------------------

                        END -- @@DBPostCode

------END Log-------

                END -- @StmtOnly = 0
-----------------------------------
-----------------------------------
--------END DBPostCode-------------
-----------------------------------
-----------------------------------	

------------------------------------------------
-----------------BEGIN HeaderOnly---------------
------------------------------------------------
If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
            IF @BackupError = 'OK'
                BEGIN --@BackupError = 'OK'
  ----This is stupid.  We found a couple edge cases where the headeronly portion was failing because the server couldn't see the file for some reason.
  ----This occurred right after the backup so there really was no reason for it.  The instances we saw actually hung the process and forced the routine to exit completely
  ----w/o backing up the rest of the DBs.  And in 1 case even when we ran the stmt manually it still hung and took several mins to kill.
  ----So for this reason, we had to go from a straight INSERT EXEC to this dynamic sql monstrosity.
  ----This allows us to put in a query timeout so that it disconnects gracefully and processes the rest of the DBs.
  ----You won't get DBSize info or any other headeronly cols, but at least your DB will backup and will be logged.
  ----And the error will be logged in the Warning col of BackupLogDetails.                 
                    DECLARE @HeaderCMD VARCHAR(max),
							@HeaderErrors VARCHAR(MAX);
					SET @FileList = REPLACE(@FileList, '''', '''''')

					CREATE TABLE #HeaderResults (ID INT IDENTITY(1,1), col1 VARCHAR(max));
						----Dump the work table.
						DELETE Minion.BackupHeaderOnlyWork
                        WHERE
                            ExecutionDateTime < @ExecutionDateTime
                            AND DBName = @DBName
                            AND BT = @BackupType

                    IF @Version < 11
						BEGIN
							SET @HeaderCMD = '; SET NOCOUNT ON;CREATE TABLE #HeaderOnly(BackupName VARCHAR(100) COLLATE DATABASE_DEFAULT NULL,BackupDescription VARCHAR(1000)COLLATE DATABASE_DEFAULT,BackupType TINYINT,ExpirationDate DATETIME,Compressed BIT,POSITION TINYINT,DeviceType TINYINT,UserName VARCHAR(100) COLLATE DATABASE_DEFAULT,ServerLabel VARCHAR(100) COLLATE DATABASE_DEFAULT,DatabaseName VARCHAR(100) COLLATE DATABASE_DEFAULT,DatabaseVersion INT,DatabaseCreationDate DATETIME,BackupSize BIGINT,FirstLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,LastLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,CheckpointLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,DatabaseBackupLSN VARCHAR(100)COLLATE DATABASE_DEFAULT,BackupStartDate DATETIME,BackupFinishDate DATETIME,SortOrder INT,CODEPAGE INT,UnicodeLocaleId INT,UnicodeComparisonStyle INT,CompatibilityLevel INT,SoftwareVendorId INT,SoftwareVersionMajor INT,SoftwareVersionMinor INT,SovtwareVersionBuild INT,MachineName VARCHAR(100) COLLATE DATABASE_DEFAULT,Flags INT,BindingID VARCHAR(100) COLLATE DATABASE_DEFAULT,RecoveryForkID VARCHAR(100) COLLATE DATABASE_DEFAULT,COLLATION VARCHAR(100) COLLATE DATABASE_DEFAULT,FamilyGUID VARCHAR(100) COLLATE DATABASE_DEFAULT,HasBulkLoggedData BIT,IsSnapshot BIT,IsReadOnly BIT,IsSingleUser BIT,HasBackupChecksums BIT,IsDamaged BIT,BeginsLogChain BIT,HasIncompleteMeatdata BIT,IsForceOffline BIT,IsCopyOnly BIT,FirstRecoveryForkID VARCHAR(100)COLLATE DATABASE_DEFAULT,ForkPointLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,RecoveryModel VARCHAR(15) COLLATE DATABASE_DEFAULT,DifferentialBaseLSN VARCHAR(100)COLLATE DATABASE_DEFAULT,DifferentialBaseGUID VARCHAR(100)COLLATE DATABASE_DEFAULT,BackupTypeDescription VARCHAR(25)COLLATE DATABASE_DEFAULT,BackupSetGUID VARCHAR(100) COLLATE DATABASE_DEFAULT,CompressedBackupSize BIGINT,CONTAINMENT TINYINT);'
							SET @HeaderCMD = @HeaderCMD +
							' INSERT #HeaderOnly(BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,POSITION,DeviceType,UserName,ServerLabel,DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,BackupStartDate,BackupFinishDate,SortOrder,CODEPAGE,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SovtwareVersionBuild,MachineName,Flags,BindingID,RecoveryForkID,COLLATION,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,IsDamaged,BeginsLogChain,HasIncompleteMeatdata,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize) EXEC(''RESTORE HEADERONLY FROM ' + @FileList + '''); '
							SET @HeaderCMD = @HeaderCMD +
							' INSERT [' + @MaintDB + '].Minion.BackupHeaderOnlyWork(BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,POSITION,DeviceType,UserName,ServerLabel,DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,BackupStartDate,BackupFinishDate,SortOrder,CODEPAGE,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SovtwareVersionBuild,MachineName,Flags,BindingID,RecoveryForkID,COLLATION,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,IsDamaged,BeginsLogChain,HasIncompleteMeatdata,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize) SELECT BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,POSITION,DeviceType,UserName,ServerLabel,DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,BackupStartDate,BackupFinishDate,SortOrder,CODEPAGE,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SovtwareVersionBuild,MachineName,Flags,BindingID,RecoveryForkID,COLLATION,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,IsDamaged,BeginsLogChain,HasIncompleteMeatdata,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize FROM #HeaderOnly; '
							SET @HeaderCMD = @HeaderCMD +
							' UPDATE [' + @MaintDB + '].Minion.BackupHeaderOnlyWork SET ExecutionDateTime = ''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''', DBName = ''' + @DBName + '''' + ', BT = ''' + @BackupType + ''''
						END

                    IF @Version = 11
						BEGIN
							SET @HeaderCMD = 'SET NOCOUNT ON;CREATE TABLE #HeaderOnly(BackupName VARCHAR(100) COLLATE DATABASE_DEFAULT NULL,BackupDescription VARCHAR(1000)COLLATE DATABASE_DEFAULT,BackupType TINYINT,ExpirationDate DATETIME,Compressed BIT,POSITION TINYINT,DeviceType TINYINT,UserName VARCHAR(100) COLLATE DATABASE_DEFAULT,ServerLabel VARCHAR(100) COLLATE DATABASE_DEFAULT,DatabaseName VARCHAR(100) COLLATE DATABASE_DEFAULT,DatabaseVersion INT,DatabaseCreationDate DATETIME,BackupSize BIGINT,FirstLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,LastLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,CheckpointLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,DatabaseBackupLSN VARCHAR(100)COLLATE DATABASE_DEFAULT,BackupStartDate DATETIME,BackupFinishDate DATETIME,SortOrder INT,CODEPAGE INT,UnicodeLocaleId INT,UnicodeComparisonStyle INT,CompatibilityLevel INT,SoftwareVendorId INT,SoftwareVersionMajor INT,SoftwareVersionMinor INT,SovtwareVersionBuild INT,MachineName VARCHAR(100) COLLATE DATABASE_DEFAULT,Flags INT,BindingID VARCHAR(100) COLLATE DATABASE_DEFAULT,RecoveryForkID VARCHAR(100) COLLATE DATABASE_DEFAULT,COLLATION VARCHAR(100) COLLATE DATABASE_DEFAULT,FamilyGUID VARCHAR(100) COLLATE DATABASE_DEFAULT,HasBulkLoggedData BIT,IsSnapshot BIT,IsReadOnly BIT,IsSingleUser BIT,HasBackupChecksums BIT,IsDamaged BIT,BeginsLogChain BIT,HasIncompleteMeatdata BIT,IsForceOffline BIT,IsCopyOnly BIT,FirstRecoveryForkID VARCHAR(100)COLLATE DATABASE_DEFAULT,ForkPointLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,RecoveryModel VARCHAR(15) COLLATE DATABASE_DEFAULT,DifferentialBaseLSN VARCHAR(100)COLLATE DATABASE_DEFAULT,DifferentialBaseGUID VARCHAR(100)COLLATE DATABASE_DEFAULT,BackupTypeDescription VARCHAR(25)COLLATE DATABASE_DEFAULT,BackupSetGUID VARCHAR(100) COLLATE DATABASE_DEFAULT,CompressedBackupSize BIGINT,CONTAINMENT TINYINT);'
							SET @HeaderCMD = @HeaderCMD +
							' INSERT #HeaderOnly(BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,POSITION,DeviceType,UserName,ServerLabel,DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,BackupStartDate,BackupFinishDate,SortOrder,CODEPAGE,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SovtwareVersionBuild,MachineName,Flags,BindingID,RecoveryForkID,COLLATION,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,IsDamaged,BeginsLogChain,HasIncompleteMeatdata,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize,CONTAINMENT) EXEC(''RESTORE HEADERONLY FROM ' + @FileList + '''); '
							SET @HeaderCMD = @HeaderCMD +
							' INSERT [' + @MaintDB + '].Minion.BackupHeaderOnlyWork(BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,POSITION,DeviceType,UserName,ServerLabel,DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,BackupStartDate,BackupFinishDate,SortOrder,CODEPAGE,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SovtwareVersionBuild,MachineName,Flags,BindingID,RecoveryForkID,COLLATION,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,IsDamaged,BeginsLogChain,HasIncompleteMeatdata,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize,CONTAINMENT) SELECT BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,POSITION,DeviceType,UserName,ServerLabel,DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,BackupStartDate,BackupFinishDate,SortOrder,CODEPAGE,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SovtwareVersionBuild,MachineName,Flags,BindingID,RecoveryForkID,COLLATION,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,IsDamaged,BeginsLogChain,HasIncompleteMeatdata,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize,CONTAINMENT FROM #HeaderOnly; '
							SET @HeaderCMD = @HeaderCMD +
							' UPDATE [' + @MaintDB + '].Minion.BackupHeaderOnlyWork SET ExecutionDateTime = ''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''', DBName = ''' + @DBName + '''' + ', BT = ''' + @BackupType + ''''
						--PRINT @HeaderCMD
						
						END
----This version of SQL saw 3 new cols in HEADERONLY so this had to be broken out even further.
----So anything under 4100 gets one set of cols and anything over gets another.
                    IF @Version = 12
						If @Version = 12 AND @VersionMinor < 4100
						BEGIN --@Version = 12 AND @VersionMinor < 4100
							SET @HeaderCMD = 'SET NOCOUNT ON;CREATE TABLE #HeaderOnly(BackupName VARCHAR(100) COLLATE DATABASE_DEFAULT NULL,BackupDescription VARCHAR(1000)COLLATE DATABASE_DEFAULT,BackupType TINYINT,ExpirationDate DATETIME,Compressed BIT,POSITION TINYINT,DeviceType TINYINT,UserName VARCHAR(100) COLLATE DATABASE_DEFAULT,ServerLabel VARCHAR(100) COLLATE DATABASE_DEFAULT,DatabaseName VARCHAR(100) COLLATE DATABASE_DEFAULT,DatabaseVersion INT,DatabaseCreationDate DATETIME,BackupSize BIGINT,FirstLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,LastLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,CheckpointLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,DatabaseBackupLSN VARCHAR(100)COLLATE DATABASE_DEFAULT,BackupStartDate DATETIME,BackupFinishDate DATETIME,SortOrder INT,CODEPAGE INT,UnicodeLocaleId INT,UnicodeComparisonStyle INT,CompatibilityLevel INT,SoftwareVendorId INT,SoftwareVersionMajor INT,SoftwareVersionMinor INT,SovtwareVersionBuild INT,MachineName VARCHAR(100) COLLATE DATABASE_DEFAULT,Flags INT,BindingID VARCHAR(100) COLLATE DATABASE_DEFAULT,RecoveryForkID VARCHAR(100) COLLATE DATABASE_DEFAULT,COLLATION VARCHAR(100) COLLATE DATABASE_DEFAULT,FamilyGUID VARCHAR(100) COLLATE DATABASE_DEFAULT,HasBulkLoggedData BIT,IsSnapshot BIT,IsReadOnly BIT,IsSingleUser BIT,HasBackupChecksums BIT,IsDamaged BIT,BeginsLogChain BIT,HasIncompleteMeatdata BIT,IsForceOffline BIT,IsCopyOnly BIT,FirstRecoveryForkID VARCHAR(100)COLLATE DATABASE_DEFAULT,ForkPointLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,RecoveryModel VARCHAR(15) COLLATE DATABASE_DEFAULT,DifferentialBaseLSN VARCHAR(100)COLLATE DATABASE_DEFAULT,DifferentialBaseGUID VARCHAR(100)COLLATE DATABASE_DEFAULT,BackupTypeDescription VARCHAR(25)COLLATE DATABASE_DEFAULT,BackupSetGUID VARCHAR(100) COLLATE DATABASE_DEFAULT,CompressedBackupSize BIGINT,CONTAINMENT TINYINT);'
							SET @HeaderCMD = @HeaderCMD +
							' INSERT #HeaderOnly(BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,POSITION,DeviceType,UserName,ServerLabel,DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,BackupStartDate,BackupFinishDate,SortOrder,CODEPAGE,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SovtwareVersionBuild,MachineName,Flags,BindingID,RecoveryForkID,COLLATION,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,IsDamaged,BeginsLogChain,HasIncompleteMeatdata,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize,CONTAINMENT) EXEC(''RESTORE HEADERONLY FROM ' + @FileList + '''); '
							SET @HeaderCMD = @HeaderCMD +
							' INSERT [' + @MaintDB + '].Minion.BackupHeaderOnlyWork(BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,POSITION,DeviceType,UserName,ServerLabel,DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,BackupStartDate,BackupFinishDate,SortOrder,CODEPAGE,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SovtwareVersionBuild,MachineName,Flags,BindingID,RecoveryForkID,COLLATION,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,IsDamaged,BeginsLogChain,HasIncompleteMeatdata,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize,CONTAINMENT) SELECT BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,POSITION,DeviceType,UserName,ServerLabel,DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,BackupStartDate,BackupFinishDate,SortOrder,CODEPAGE,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SovtwareVersionBuild,MachineName,Flags,BindingID,RecoveryForkID,COLLATION,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,IsDamaged,BeginsLogChain,HasIncompleteMeatdata,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize,CONTAINMENT FROM #HeaderOnly; '
							SET @HeaderCMD = @HeaderCMD +
							' UPDATE [' + @MaintDB + '].Minion.BackupHeaderOnlyWork SET ExecutionDateTime = ''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''', DBName = ''' + @DBName + '''' + ', BT = ''' + @BackupType + ''''
						--PRINT @HeaderCMD
						
						END --@Version = 12 AND @VersionMinor < 4100

						If @Version = 12 AND @VersionMinor >= 4100
						BEGIN --@Version = 12 AND @VersionMinor >= 4100
							SET @HeaderCMD = 'SET NOCOUNT ON;CREATE TABLE #HeaderOnly(BackupName VARCHAR(100) COLLATE DATABASE_DEFAULT NULL,BackupDescription VARCHAR(1000)COLLATE DATABASE_DEFAULT,BackupType TINYINT,ExpirationDate DATETIME,Compressed BIT,POSITION TINYINT,DeviceType TINYINT,UserName VARCHAR(100) COLLATE DATABASE_DEFAULT,ServerLabel VARCHAR(100) COLLATE DATABASE_DEFAULT,DatabaseName VARCHAR(100) COLLATE DATABASE_DEFAULT,DatabaseVersion INT,DatabaseCreationDate DATETIME,BackupSize BIGINT,FirstLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,LastLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,CheckpointLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,DatabaseBackupLSN VARCHAR(100)COLLATE DATABASE_DEFAULT,BackupStartDate DATETIME,BackupFinishDate DATETIME,SortOrder INT,CODEPAGE INT,UnicodeLocaleId INT,UnicodeComparisonStyle INT,CompatibilityLevel INT,SoftwareVendorId INT,SoftwareVersionMajor INT,SoftwareVersionMinor INT,SovtwareVersionBuild INT,MachineName VARCHAR(100) COLLATE DATABASE_DEFAULT,Flags INT,BindingID VARCHAR(100) COLLATE DATABASE_DEFAULT,RecoveryForkID VARCHAR(100) COLLATE DATABASE_DEFAULT,COLLATION VARCHAR(100) COLLATE DATABASE_DEFAULT,FamilyGUID VARCHAR(100) COLLATE DATABASE_DEFAULT,HasBulkLoggedData BIT,IsSnapshot BIT,IsReadOnly BIT,IsSingleUser BIT,HasBackupChecksums BIT,IsDamaged BIT,BeginsLogChain BIT,HasIncompleteMeatdata BIT,IsForceOffline BIT,IsCopyOnly BIT,FirstRecoveryForkID VARCHAR(100)COLLATE DATABASE_DEFAULT,ForkPointLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,RecoveryModel VARCHAR(15) COLLATE DATABASE_DEFAULT,DifferentialBaseLSN VARCHAR(100)COLLATE DATABASE_DEFAULT,DifferentialBaseGUID VARCHAR(100)COLLATE DATABASE_DEFAULT,BackupTypeDescription VARCHAR(25)COLLATE DATABASE_DEFAULT,BackupSetGUID VARCHAR(100) COLLATE DATABASE_DEFAULT,CompressedBackupSize BIGINT,CONTAINMENT TINYINT, KeyAlgorithm nvarchar(32), EncryptorThumbprint varbinary(20), EncryptorType nvarchar(32));'
							SET @HeaderCMD = @HeaderCMD +
							' INSERT #HeaderOnly(BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,POSITION,DeviceType,UserName,ServerLabel,DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,BackupStartDate,BackupFinishDate,SortOrder,CODEPAGE,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SovtwareVersionBuild,MachineName,Flags,BindingID,RecoveryForkID,COLLATION,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,IsDamaged,BeginsLogChain,HasIncompleteMeatdata,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize,CONTAINMENT,KeyAlgorithm,EncryptorThumbprint,EncryptorType) EXEC(''RESTORE HEADERONLY FROM ' + @FileList + '''); '
							SET @HeaderCMD = @HeaderCMD +
							' INSERT [' + @MaintDB + '].Minion.BackupHeaderOnlyWork(BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,POSITION,DeviceType,UserName,ServerLabel,DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,BackupStartDate,BackupFinishDate,SortOrder,CODEPAGE,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SovtwareVersionBuild,MachineName,Flags,BindingID,RecoveryForkID,COLLATION,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,IsDamaged,BeginsLogChain,HasIncompleteMeatdata,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize,CONTAINMENT,KeyAlgorithm,EncryptorThumbprint,EncryptorType) SELECT BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,POSITION,DeviceType,UserName,ServerLabel,DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,BackupStartDate,BackupFinishDate,SortOrder,CODEPAGE,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SovtwareVersionBuild,MachineName,Flags,BindingID,RecoveryForkID,COLLATION,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,IsDamaged,BeginsLogChain,HasIncompleteMeatdata,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize,CONTAINMENT,KeyAlgorithm,EncryptorThumbprint,EncryptorType FROM #HeaderOnly; '
							SET @HeaderCMD = @HeaderCMD +
							' UPDATE [' + @MaintDB + '].Minion.BackupHeaderOnlyWork SET ExecutionDateTime = ''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''', DBName = ''' + @DBName + '''' + ', BT = ''' + @BackupType + ''''
						--PRINT @HeaderCMD
						
						END --@Version = 12 AND @VersionMinor >= 4100

						If @Version > 12 
						BEGIN --@Version > 12
							SET @HeaderCMD = 'SET NOCOUNT ON;CREATE TABLE #HeaderOnly(BackupName VARCHAR(100) COLLATE DATABASE_DEFAULT NULL,BackupDescription VARCHAR(1000)COLLATE DATABASE_DEFAULT,BackupType TINYINT,ExpirationDate DATETIME,Compressed BIT,POSITION TINYINT,DeviceType TINYINT,UserName VARCHAR(100) COLLATE DATABASE_DEFAULT,ServerLabel VARCHAR(100) COLLATE DATABASE_DEFAULT,DatabaseName VARCHAR(100) COLLATE DATABASE_DEFAULT,DatabaseVersion INT,DatabaseCreationDate DATETIME,BackupSize BIGINT,FirstLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,LastLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,CheckpointLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,DatabaseBackupLSN VARCHAR(100)COLLATE DATABASE_DEFAULT,BackupStartDate DATETIME,BackupFinishDate DATETIME,SortOrder INT,CODEPAGE INT,UnicodeLocaleId INT,UnicodeComparisonStyle INT,CompatibilityLevel INT,SoftwareVendorId INT,SoftwareVersionMajor INT,SoftwareVersionMinor INT,SovtwareVersionBuild INT,MachineName VARCHAR(100) COLLATE DATABASE_DEFAULT,Flags INT,BindingID VARCHAR(100) COLLATE DATABASE_DEFAULT,RecoveryForkID VARCHAR(100) COLLATE DATABASE_DEFAULT,COLLATION VARCHAR(100) COLLATE DATABASE_DEFAULT,FamilyGUID VARCHAR(100) COLLATE DATABASE_DEFAULT,HasBulkLoggedData BIT,IsSnapshot BIT,IsReadOnly BIT,IsSingleUser BIT,HasBackupChecksums BIT,IsDamaged BIT,BeginsLogChain BIT,HasIncompleteMeatdata BIT,IsForceOffline BIT,IsCopyOnly BIT,FirstRecoveryForkID VARCHAR(100)COLLATE DATABASE_DEFAULT,ForkPointLSN VARCHAR(100) COLLATE DATABASE_DEFAULT,RecoveryModel VARCHAR(15) COLLATE DATABASE_DEFAULT,DifferentialBaseLSN VARCHAR(100)COLLATE DATABASE_DEFAULT,DifferentialBaseGUID VARCHAR(100)COLLATE DATABASE_DEFAULT,BackupTypeDescription VARCHAR(25)COLLATE DATABASE_DEFAULT,BackupSetGUID VARCHAR(100) COLLATE DATABASE_DEFAULT,CompressedBackupSize BIGINT,CONTAINMENT TINYINT, KeyAlgorithm nvarchar(32), EncryptorThumbprint varbinary(20), EncryptorType nvarchar(32));'
							SET @HeaderCMD = @HeaderCMD +
							' INSERT #HeaderOnly(BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,POSITION,DeviceType,UserName,ServerLabel,DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,BackupStartDate,BackupFinishDate,SortOrder,CODEPAGE,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SovtwareVersionBuild,MachineName,Flags,BindingID,RecoveryForkID,COLLATION,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,IsDamaged,BeginsLogChain,HasIncompleteMeatdata,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize,CONTAINMENT,KeyAlgorithm,EncryptorThumbprint,EncryptorType) EXEC(''RESTORE HEADERONLY FROM ' + @FileList + '''); '
							SET @HeaderCMD = @HeaderCMD +
							' INSERT [' + @MaintDB + '].Minion.BackupHeaderOnlyWork(BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,POSITION,DeviceType,UserName,ServerLabel,DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,BackupStartDate,BackupFinishDate,SortOrder,CODEPAGE,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SovtwareVersionBuild,MachineName,Flags,BindingID,RecoveryForkID,COLLATION,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,IsDamaged,BeginsLogChain,HasIncompleteMeatdata,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize,CONTAINMENT,KeyAlgorithm,EncryptorThumbprint,EncryptorType) SELECT BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,POSITION,DeviceType,UserName,ServerLabel,DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,BackupStartDate,BackupFinishDate,SortOrder,CODEPAGE,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SovtwareVersionBuild,MachineName,Flags,BindingID,RecoveryForkID,COLLATION,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,IsDamaged,BeginsLogChain,HasIncompleteMeatdata,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize,CONTAINMENT,KeyAlgorithm,EncryptorThumbprint,EncryptorType FROM #HeaderOnly; '
							SET @HeaderCMD = @HeaderCMD +
							' UPDATE [' + @MaintDB + '].Minion.BackupHeaderOnlyWork SET ExecutionDateTime = ''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''', DBName = ''' + @DBName + '''' + ', BT = ''' + @BackupType + ''''
						--PRINT @HeaderCMD
						
						END --@Version > 12

					SET @PreCMD = 'sqlcmd -r 1 -t10 -S"' + @ServerInstance + '"' -- + ISNULL(@Port, '')
						+ ' -d "' + @MaintDB + '" -q "' 
					SET @TotalCMD = @PreCMD + @HeaderCMD + '"'
					INSERT #HeaderResults(col1)
					EXEC xp_cmdshell @TotalCMD;
					--PRINT @TotalCMD
					DELETE FROM #HeaderResults WHERE col1 IS NULL

					SELECT @HeaderErrors = STUFF(( SELECT ' ' + col1
                                FROM #HeaderResults AS T1
                                ORDER BY T1.ID
                            FOR XML PATH('')), 1, 1, '')
							FROM #HeaderResults AS T2;
-----------------------------------------------------								
-----------Log HeaderOnly Error as Warning-----------
-----------------------------------------------------

                    UPDATE BF
                        SET
                            BF.BackupSizeInMB = H.BackupSize / 1024 / 1024,
                            BF.ExecutionDateTime = @ExecutionDateTime,
                            BF.DBName = @DBName,
							BF.BackupName = H.BackupName,
							BF.BackupDescription = H.BackupDescription,
                            BF.BackupType = @BackupType,
							BF.ExpirationDate = H.ExpirationDate,
							BF.Compressed = H.Compressed,
                            BF.POSITION = H.POSITION,
                            BF.DeviceType = H.DeviceType,
                            BF.UserName = H.UserName,
--BF.ServerLabel = H.ServerLabel,
                            BF.DatabaseVersion = H.DatabaseVersion,
                            BF.DatabaseCreationDate = H.DatabaseCreationDate,
                            BF.BackupSizeInBytes = H.BackupSize,
                            BF.FirstLSN = H.FirstLSN,
                            BF.LastLSN = H.LastLSN,
                            BF.CheckpointLSN = H.CheckpointLSN,
                            BF.DatabaseBackupLSN = H.DatabaseBackupLSN,
                            BF.BackupStartDate = H.BackupStartDate,
                            BF.BackupFinishDate = H.BackupFinishDate,
                            BF.SortOrder = H.SortOrder,
                            BF.CODEPAGE = H.CODEPAGE,
                            BF.UnicodeLocaleId = H.UnicodeLocaleId,
                            BF.UnicodeComparisonStyle = H.UnicodeComparisonStyle,
                            BF.CompatibilityLevel = H.CompatibilityLevel,
                            BF.SoftwareVendorId = H.SoftwareVendorId,
                            BF.SoftwareVersionMajor = H.SoftwareVersionMajor,
                            BF.SoftwareVersionMinor = H.SoftwareVersionMinor,
                            BF.SovtwareVersionBuild = H.SovtwareVersionBuild,
                            BF.MachineName = H.MachineName,
                            BF.Flags = H.Flags,
                            BF.BindingID = H.BindingID,
                            BF.RecoveryForkID = H.RecoveryForkID,
                            BF.COLLATION = H.COLLATION,
                            BF.FamilyGUID = H.FamilyGUID,
                            BF.HasBulkLoggedData = H.HasBulkLoggedData,
                            BF.IsSnapshot = H.IsSnapshot,
                            BF.IsReadOnly = H.IsReadOnly,
                            BF.IsSingleUser = H.IsSingleUser,
                            BF.HasBackupChecksums = H.HasBackupChecksums,
                            BF.IsDamaged = H.IsDamaged,
                            BF.BeginsLogChain = H.BeginsLogChain,
                            BF.HasIncompleteMeatdata = H.HasIncompleteMeatdata,
                            BF.IsForceOffline = H.IsForceOffline,
                            BF.IsCopyOnly = H.IsCopyOnly,
                            BF.FirstRecoveryForkID = H.FirstRecoveryForkID,
                            BF.ForkPointLSN = H.ForkPointLSN,
                            BF.RecoveryModel = H.RecoveryModel,
                            BF.DifferentialBaseLSN = H.DifferentialBaseLSN,
                            BF.DifferentialBaseGUID = H.DifferentialBaseGUID,
                            BF.BackupTypeDescription = H.BackupTypeDescription,
                            BF.BackupSetGUID = H.BackupSetGUID,
                            BF.CompressedBackupSize = H.CompressedBackupSize,
                            BF.CONTAINMENT = H.CONTAINMENT
                        FROM
                            Minion.BackupFiles BF
                        INNER JOIN Minion.BackupHeaderOnlyWork H
                        ON  BF.DBName = H.DBName
						AND BF.ExecutionDateTime = H.ExecutionDateTime
						AND BF.BackupType = H.BT							
                        WHERE
                            BF.ExecutionDateTime = @ExecutionDateTime
                            AND BF.DBName = @DBName
                            AND BF.BackupType = @BackupType

						----Dump the work table.
						DELETE Minion.BackupHeaderOnlyWork
                        WHERE
                            ExecutionDateTime <= @ExecutionDateTime
                            AND DBName = @DBName
                            AND BT = @BackupType

                END --@BackupError = 'OK'
	
            DROP TABLE #Backup

--SELECT @HeaderErrors AS HeaderErrors

		IF @HeaderErrors IS NOT NULL
			BEGIN
						UPDATE Minion.BackupLogDetails
							SET
								Warnings = 'HEADERONLY ERROR: You will be missing DBSize and other info in the logs.  Error message follows: ' + ISNULL(Warnings, '') + @HeaderErrors
							WHERE
								ID = @BackupLogDetailsID;
              
			END
		END --@StmtOnly = 0
------------------------------------------------
-----------------END HeaderOnly-----------------
------------------------------------------------






------------------------------------------------------------
------------------------------------------------------------
----------------BEGIN TotalSize-----------------------------
------------------------------------------------------------
------------------------------------------------------------
 If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
            IF @BackupError = 'OK'
                BEGIN --@BackupError = 'OK'

                    DECLARE @TotalSize FLOAT;

                    SET @TotalSize = ( 
										SELECT TOP 1 BackupSizeInBytes
                                        FROM  Minion.BackupFiles
                                        WHERE
                                            ExecutionDateTime = @ExecutionDateTime
                                            AND DBName = @DBName
                                            AND BackupType = @BackupType
                                     )

                END --@BackupError = 'OK'
	END --@StmtOnly = 0
 -------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
		INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
		SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupDB', '@TotalSize', @TotalSize
END
-------------------DEBUG-------------------------------	

------------------------------------------------------------
------------------------------------------------------------
----------------END TotalSize-------------------------------
------------------------------------------------------------
------------------------------------------------------------


---Get the ID of the current log entry to send to the trigger file.
			--SET @CurrentLog = ( SELECT	ID
			--					FROM	Minion.BackupLogDetails
			--					WHERE	ExecutionDateTime = @ExecutionDateTime
			--							AND DBName = @DBName
			--				  )

            SET @ServerLabel = @@ServerName;
            IF @ServerLabel LIKE '%\%'
                BEGIN --Begin @ServerLabel
                    SET @ServerLabel = REPLACE(@ServerLabel, '\', '$')
                END	--End @ServerLabel



-------------------------BEGIN PreTrigger Log-------------------------
            SET @BackupEndDateTime = GETDATE();

 -------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'Before Minion Save Start'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------	
If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
            BEGIN
                UPDATE Minion.BackupLogDetails --(ExecutionDateTime, Status, DBName, DBType, BackupType, BackupStartDateTime, Buffercount, MaxTransferSize, NumberOfFiles, StmtOnly, BackupCmd)
                    SET
                        STATUS = 'Saving to Minion'
                    WHERE
                        ID = @BackupLogDetailsID;

            END
	END --@StmtOnly = 0
 -------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'After Minion Save Start'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------	

-------------------------END PreTrigger Log---------------------------


------------------------------------------------------------------------
-------------------BEGIN Log to Minion----------------------------------
------------------------------------------------------------------------

            SET @ServerLabel = @@ServerName;
            IF @ServerLabel LIKE '%\%'
                BEGIN --Begin @ServerLabel
                    SET @ServerLabel = REPLACE(@ServerLabel, '\', '~')
                END	--End @ServerLabel

If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
            SET @TriggerFile = 'Powershell "''' + ''''''
                + CONVERT(VARCHAR(25), @ExecutionDateTime, 21) + ''''''''
                + ' | out-file "' + @BackupLoggingPath + 'BackupDB\' + @ServerLabel + '.'
                + @DBName + '" -append"' 

            EXEC xp_cmdshell @TriggerFile 
	END --@StmtOnly = 0


------------------------------------------------------------------------
-------------------END Log to Minion------------------------------------
------------------------------------------------------------------------



--------------------------------BEGIN Compression Stats---------------------------------------------
----------------------------------------------------------------------------------------------------
If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
            SELECT TOP 1 @UnCompressedBackupSizeMB = CONVERT (BIGINT, b.backup_size / 1048576),
						 @CompressedBackupSizeMB = CONVERT (BIGINT, b.compressed_backup_size / 1048576),
                    @CompressionRatio = CONVERT (NUMERIC(20, 2), (CONVERT (FLOAT, b.backup_size) / CONVERT (FLOAT, b.compressed_backup_size))),
                    @COMPRESSIONPct = CONVERT(NUMERIC(20, 1), 100 - ((b.compressed_backup_size / b.backup_size) * 100))
                FROM msdb.dbo.backupset b
                WHERE
                    b.database_name = @DBName
                ORDER BY
                    b.backup_finish_date DESC
	END --@StmtOnly = 0
--------------------------------END Compression Stats-----------------------------------------------
----------------------------------------------------------------------------------------------------

 -------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'Before Backup Complete Log'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------	

-------------------------BEGIN Backup Complete Log-------------------------
If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
            SET @BackupEndDateTime = GETDATE();

            IF @BackupError = 'OK' AND (@CertFileErrors = '' OR @CertFileErrors IS NULL) AND (@CertErrors = '' OR @CertErrors IS NULL)
                BEGIN
                    SET @Status = 'Backup Complete';
                END

            IF @BackupError = 'OK' AND (@CertFileErrors <> '' OR @CertErrors <> '')
                BEGIN
                    SET @Status = 'Backup Complete with Warnings';
                END
            BEGIN
                UPDATE Minion.BackupLogDetails
                    SET
                        STATUS = @Status,
                        SizeInMB = CAST(@TotalSize / 1024.0 / 1024.0 AS DECIMAL(24,2)),
                        MBPerSec = @MBPerSec, ----CAST(((@TotalSize / BackupTimeInSecs) / 1024.0 / 1024.0) AS DECIMAL(24,2)),
                        UnCompressedBackupSizeMB = @UnCompressedBackupSizeMB,
                        CompressedBackupSizeMB = @CompressedBackupSizeMB,
                        CompressionRatio = @CompressionRatio,
                        COMPRESSIONPct = @COMPRESSIONPct
                    WHERE
                        ID = @BackupLogDetailsID;

            END
	END --@StmtOnly = 0
-------------------------END Backup Complete Log---------------------------


 -------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'After Backup Complete Log'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------	


----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
---------------------------BEGIN File Actions-------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
            IF @BackupError = 'OK'
                BEGIN --@BackupError = 'OK'
                    IF @FileActionTime = 'AfterBackup'
                        BEGIN --@FileActionTime = 'AfterBackup'
                            DECLARE --@LogVerb VARCHAR(20),
                                @FileActionBeginDateTime DATETIME,
                                @FileActionEndDateTime DATETIME,
                                @FileActionResults VARCHAR(MAX);

                            SET @FileActionBeginDateTime = GETDATE();

		-------------Begin Log Beginning of Action-------------------

 -------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'Before BackupDB FileAction Log'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------	

                            IF @FileActionTime = 'AfterBackup'
                                BEGIN --@FileAction IS NOT NULL
                                    UPDATE Minion.BackupLogDetails
                                        SET
                                            STATUS = 'Performing FileAction',
                                            FileActionBeginDateTime = @FileActionBeginDateTime
                                        WHERE
                                            ID = @BackupLogDetailsID;


 -------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'After BackupDB FileAction Log'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------	

		-------------End Log Beginning of Action---------------------

                                    CREATE TABLE #FileActionResults
                                        (
                                         ID INT IDENTITY(1, 1),
                                         col1 VARCHAR(MAX) COLLATE DATABASE_DEFAULT
                                        )

                                    SET @FileActionResults = (SELECT col1 FROM #FileActionResults)
                                    DECLARE @FileActionErrors VARCHAR(MAX)
                                    EXEC Minion.BackupFileAction @DBName, @DateLogic, @BackupType, 0
									--PRINT 'EXEC Minion.BackupFileAction ''' + @DBName + ''', ' + '''' + @DateLogic + ''', ' + '''' + @BackupType + ''', 0'
                                END--@FileAction IS NOT NULL

                            SET @FileActionEndDateTime = GETDATE();

 -------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
		INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
		SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupDB', '@FileActionErrors', @FileActionErrors
END
-------------------DEBUG-------------------------------	



-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT
		ExecutionDateTime, STATUS, DBName, BackupType, 'Before BackupDB FileAction Complete Log'
		FROM Minion.BackupLogDetails
		WHERE ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------	

		-------------BEGIN Log End of Action No Errors---------------------
                            BEGIN --Log 
                                UPDATE Minion.BackupLogDetails
                                    SET
                                        STATUS = 'FileAction Complete',
                                        FileActionEndDateTime = @FileActionEndDateTime,
                                        FileActionTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @FileActionBeginDateTime, 21), CONVERT(VARCHAR(25), @FileActionEndDateTime, 21))
                                    WHERE
                                        ID = @BackupLogDetailsID;
                            END --Log 

 -------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT ExecutionDateTime, STATUS, DBName, BackupType, 'After BackupDB FileAction Complete Log'
		FROM Minion.BackupLogDetails
		WHERE 
			ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------	

		-------------End Log End of Action No Errors---------------------


                        END --@FileActionTime = 'AfterBackup'
                END --@BackupError = 'OK'
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
If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
		IF @BackupError = 'OK'
			BEGIN --@BackupError = 'OK'
					IF @Verify = 'AfterBackup'
					BEGIN ----@Verify = 'AfterBackup'
					 -------------------DEBUG-------------------------------
						IF @Debug = 1
						BEGIN
							INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
							SELECT ExecutionDateTime, STATUS, DBName, BackupType, 'Before BackupDB Verify Log'
								FROM Minion.BackupLogDetails
								WHERE 
									ID = @BackupLogDetailsID
						END
					-------------------DEBUG-------------------------------	

						EXEC Minion.BackupVerify @ExecutionDateTime, @DBName

					 -------------------DEBUG-------------------------------
						IF @Debug = 1
						BEGIN
							INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
							SELECT ExecutionDateTime, STATUS, DBName, BackupType, 'After BackupDB Verify Log'
								FROM Minion.BackupLogDetails
								WHERE 
									ID = @BackupLogDetailsID
						END

					-------------------DEBUG-------------------------------	
					END ----@Verify = 'AfterBackup'
			END --@BackupError = 'OK'
	END --@StmtOnly = 0		
----------------------------------------------------------------------------
----------------------------------------------------------------------------	
--------------------END Verify----------------------------------------------	
----------------------------------------------------------------------------	
----------------------------------------------------------------------------



-------------------------BEGIN Final Log-------------------------
            SET @BackupEndDateTime = GETDATE();

            DECLARE @Warnings VARCHAR(MAX);

 -------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT ExecutionDateTime, STATUS, DBName, BackupType, 'Before BackupDB Final Log'
		FROM Minion.BackupLogDetails
		WHERE 
			ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------	


IF @StmtOnly = 0
	BEGIN --@StmtOnly = 0
            UPDATE Minion.BackupLogDetails
                SET
                    STATUS = CASE WHEN (@BackupError = 'OK' AND STATUS LIKE '%Complete%' AND (@FileActionTime IS NULL OR @FileActionTime = 'AfterBatch') AND (Warnings IS NULL OR Warnings = '')) THEN 'Backup Complete'
                                  WHEN (@BackupError = 'OK' AND STATUS LIKE '%Complete%' AND (@FileActionTime IS NULL OR @FileActionTime = 'AfterBackup') AND (Warnings IS NULL OR Warnings = '')) THEN 'All Complete'
                                  WHEN (@BackupError = 'OK' AND STATUS LIKE '%Complete%' AND (Warnings IS NOT NULL OR Warnings <> '')) THEN 'Complete with Warnings'
                                  WHEN @BackupError <> 'OK' THEN STATUS
                                  ELSE 'Unspecified Error.'
                             END
                WHERE
                    ID = @BackupLogDetailsID;
	END --@Stmt)nly = 0
-------------------------END Final Log---------------------------

        END

    END

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
	SELECT ExecutionDateTime, STATUS, DBName, BackupType, 'After BackupDB Final Log'
		FROM Minion.BackupLogDetails
		WHERE 
			ID = @BackupLogDetailsID
END
-------------------DEBUG-------------------------------	

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------	
------------------------BEGIN Verify--------------------------------------------	
--------------------------------------------------------------------------------	
--------------------------------------------------------------------------------		

----IF @Verify = 'AfterBackup'
----BEGIN --@Verify = 'AfterBackup'
---- -------------------DEBUG-------------------------------
----IF @Debug = 1
----BEGIN
----	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
----	SELECT
----		ExecutionDateTime, STATUS, DBName, BackupType, 'Before BackupDB Verify Log'
----		FROM Minion.BackupLogDetails
----		WHERE ID = @BackupLogDetailsID
----END
-----------------------DEBUG-------------------------------	

----BEGIN
----EXEC Minion.BackupVerify @ExecutionDateTime, @DBName


---- -------------------DEBUG-------------------------------
----IF @Debug = 1
----BEGIN
----	INSERT Minion.BackupDebugLogDetails (ExecutionDateTime, STATUS, DBName, BackupType, StepName)
----	SELECT
----		ExecutionDateTime, STATUS, DBName, BackupType, 'After BackupDB Verify Log'
----		FROM Minion.BackupLogDetails
----		WHERE ID = @BackupLogDetailsID
----END
-----------------------DEBUG-------------------------------	

----END --@Verify = 'AfterBackup'

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------	
------------------------END Verify----------------------------------------------	
--------------------------------------------------------------------------------	
--------------------------------------------------------------------------------	



GO
