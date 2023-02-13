SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [Minion].[BackupRestoreDB]
	@ServerName VARCHAR(400),
	@DBName NVARCHAR(400),
	@BackupType VARCHAR(20) = 'FULL',		-- FULL, LOG, or DIFF (TDE)
	@BackupLoc VARCHAR(10) = 'Backup',		-- Backup / Primary, Mirror, Copy, or Move. it will only take the first Copy location.
	@RestoreDBName NVARCHAR(400) = NULL,
	@StmtOnly BIT = 0						-- Right now we'll only support @StmtOnly 
/***********************************************************************************
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------------------Minion Backup------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
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

Purpose: 

Features:
	* 

Limitations:
	*  

Notes:
		* 


Walkthrough:  --!--

	1. Get a list of all recent backups for that database, including and since the last full backup.
	2. Delete the files we're NOT going to use.

Parameters:
-----------
	@DBName - The name of the database you'd like to generate restore statements for.
	
	@BackupType - FULL, LOG, or DIFF 

	@BackupLoc - Backup location. Valid inputs: PRIMARY, MIRROR, Copy, or Move. It will only 
				 use the first Copy location.

	@StmtOnly - Only generate statements. Currently, Minion Backup only supports @StmtOnly = 1.


Tables:
-----------


Example Execution: 
-----------
	-- 
	EXEC Minion.RestoreDB 'MinionDev';

Revision History:  
-----------

***********************************************************************************/
AS 
	DECLARE @ExecutionDateTime DATETIME ,
		@Op VARCHAR(20),
		@Status VARCHAR(MAX),
		@ServerLabel VARCHAR(150),
		@FileList VARCHAR(MAX),
		@FileListForMove VARCHAR(MAX),
		@WithMove VARCHAR(MAX),
		@RestoreCmd VARCHAR(MAX),
		@ThisServer VARCHAR(200),
		@PathSettingLevel int,
		@ThisServerWithoutInstance VARCHAR(400);

	SET NOCOUNT ON;

SET @ThisServer = CAST(SERVERPROPERTY('ServerName') AS VARCHAR(200));

----Get the servername without the instance.  When connecting to a server to restore a DB file, you don't conn to the instance
----you conn to the server.
IF @ThisServer LIKE '%\%'
	BEGIN
		DECLARE @CharIndex INT;
		SET @CharIndex = CHARINDEX('\', @ThisServer);
		SET @ThisServerWithoutInstance = SUBSTRING(@ThisServer, 1, @CharIndex-1);
	END

IF @ThisServer NOT LIKE '%\%'
	BEGIN
		SET @ThisServerWithoutInstance = @ThisServer;
	END
----------------------------------------------------------------------------------------
---- 1. Get a list of all recent backups for that database, including and since the last full backup.
---- Retrieve the latest FULL backup files for @DBName, wherever they are:

	IF OBJECT_ID('tempdb..#Backupfiles') IS NOT NULL 
		DROP TABLE #Backupfiles;
	IF OBJECT_ID('tempdb..#filelist') IS NOT NULL 
		DROP TABLE #filelist;

CREATE TABLE #BackupFiles(
	[ID] [BIGINT] NOT NULL,
	[ExecutionDateTime] [datetime] NULL,
	[Op] [varchar](20) NULL,
	[Status] [nvarchar](max) NULL,
	[DBName] [nvarchar](400) NOT NULL,
	[ServerLabel] [varchar](150) NULL,
	[NETBIOSName] [varchar](128) NULL,
	[BackupType] [varchar](20) NULL,
	[BackupLocType] [varchar](20) NULL,
	[BackupDrive] [varchar](100) NULL,
	[BackupPath] [varchar](1000) NULL,
	[FullPath] [varchar](4000) NULL,
	[FullFileName] [nvarchar](4000) NULL,
	[FileName] [varchar](500) NULL,
	[DateLogic] [varchar](100) NULL,
	[Extension] [varchar](5) NULL,
	[RetHrs] [int] NULL,
	[IsMirror] [bit] NULL,
	[ToBeDeleted] [datetime] NULL,
	[DeleteDateTime] [datetime] NULL,
	[IsDeleted] [bit] NULL,
	[IsArchive] [bit] NULL,
	[BackupSizeInMB] [numeric](15, 3) NULL,
	[BackupName] [varchar](100) NULL,
	[BackupDescription] [varchar](1000) NULL,
	[ExpirationDate] [datetime] NULL,
	[Compressed] [bit] NULL,
	[POSITION] [tinyint] NULL,
	[DeviceType] [tinyint] NULL,
	[UserName] [varchar](100) NULL,
	[DatabaseName] [nvarchar](400) NULL,
	[DatabaseVersion] [int] NULL,
	[DatabaseCreationDate] [datetime] NULL,
	[BackupSizeInBytes] [bigint] NULL,
	[FirstLSN] [varchar](100) NULL,
	[LastLSN] [varchar](100) NULL,
	[CheckpointLSN] [varchar](100) NULL,
	[DatabaseBackupLSN] [varchar](100) NULL,
	[BackupStartDate] [datetime] NULL,
	[BackupFinishDate] [datetime] NULL,
	[SortOrder] [int] NULL,
	[CODEPAGE] [int] NULL,
	[UnicodeLocaleId] [int] NULL,
	[UnicodeComparisonStyle] [int] NULL,
	[CompatibilityLevel] [int] NULL,
	[SoftwareVendorId] [int] NULL,
	[SoftwareVersionMajor] [int] NULL,
	[SoftwareVersionMinor] [int] NULL,
	[SovtwareVersionBuild] [int] NULL,
	[MachineName] [varchar](100) NULL,
	[Flags] [int] NULL,
	[BindingID] [varchar](100) NULL,
	[RecoveryForkID] [varchar](100) NULL,
	[COLLATION] [varchar](100) NULL,
	[FamilyGUID] [varchar](100) NULL,
	[HasBulkLoggedData] [bit] NULL,
	[IsSnapshot] [bit] NULL,
	[IsReadOnly] [bit] NULL,
	[IsSingleUser] [bit] NULL,
	[HasBackupChecksums] [bit] NULL,
	[IsDamaged] [bit] NULL,
	[BeginsLogChain] [bit] NULL,
	[HasIncompleteMeatdata] [bit] NULL,
	[IsForceOffline] [bit] NULL,
	[IsCopyOnly] [bit] NULL,
	[FirstRecoveryForkID] [varchar](100) NULL,
	[ForkPointLSN] [varchar](100) NULL,
	[RecoveryModel] [varchar](15) NULL,
	[DifferentialBaseLSN] [varchar](100) NULL,
	[DifferentialBaseGUID] [varchar](100) NULL,
	[BackupTypeDescription] [varchar](25) NULL,
	[BackupSetGUID] [varchar](100) NULL,
	[CompressedBackupSize] [bigint] NULL,
	[CONTAINMENT] [tinyint] NULL
);
	WITH	CTE
			  AS ( SELECT TOP 1
							ExecutionDateTime ,
							Op ,
							Status ,
							DBName ,
							ServerLabel ,
							BackupType
				   FROM		Minion.BackupFiles
				   WHERE	IsDeleted = 0
							AND DBName = @DBName
							AND BackupType = 'Full'
							AND Status = 'Complete'
				   ORDER BY	ExecutionDateTime DESC
				 )
	
		INSERT INTO	#BackupFiles (ID, ExecutionDateTime, Op, Status, DBName, ServerLabel, NETBIOSName, BackupType, BackupLocType, BackupDrive, BackupPath, FullPath, FullFileName, FileName, DateLogic, Extension, RetHrs, IsMirror, ToBeDeleted, DeleteDateTime, IsDeleted, IsArchive, BackupSizeInMB, BackupName, BackupDescription, ExpirationDate, Compressed, POSITION, DeviceType, UserName, DatabaseName, DatabaseVersion, DatabaseCreationDate, BackupSizeInBytes, FirstLSN, LastLSN, CheckpointLSN, DatabaseBackupLSN, BackupStartDate, BackupFinishDate, SortOrder, CODEPAGE, UnicodeLocaleId, UnicodeComparisonStyle, CompatibilityLevel, SoftwareVendorId, SoftwareVersionMajor, SoftwareVersionMinor, SovtwareVersionBuild, MachineName, Flags, BindingID, RecoveryForkID, COLLATION, FamilyGUID, HasBulkLoggedData, IsSnapshot, IsReadOnly, IsSingleUser, HasBackupChecksums, IsDamaged, BeginsLogChain, HasIncompleteMeatdata, IsForceOffline, IsCopyOnly, FirstRecoveryForkID, ForkPointLSN, RecoveryModel, DifferentialBaseLSN, DifferentialBaseGUID, BackupTypeDescription, BackupSetGUID, CompressedBackupSize, CONTAINMENT)
		SELECT BF.* FROM	Minion.BackupFiles BF
				JOIN CTE ON BF.ExecutionDateTime >= CTE.ExecutionDateTime
							AND BF.ServerLabel = CTE.ServerLabel
							AND BF.DBName = @DBName;

CREATE CLUSTERED INDEX clust1 ON #BackupFiles (ExecutionDateTime);


	CREATE TABLE #BackupRestoreTuningThresholdsStmtGet
		(
		  [DBName] NVARCHAR(400) COLLATE DATABASE_DEFAULT NOT NULL ,
		  [RestoreType] [VARCHAR](4) COLLATE DATABASE_DEFAULT NULL ,
		  [SpaceType] [VARCHAR](20) COLLATE DATABASE_DEFAULT NULL ,
		  [ThresholdMeasure] [CHAR](2) COLLATE DATABASE_DEFAULT NULL ,
		  [ThresholdValue] [BIGINT] NULL ,
		  [Buffercount] [SMALLINT] NULL ,
		  [MaxTransferSize] [BIGINT] NULL ,
		  [BlockSize] [BIGINT] NULL ,
		  [Replace] BIT NULL,
		  WithFlags VARCHAR(1000) COLLATE DATABASE_DEFAULT NULL,
		  BeginTime VARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
		  EndTime VARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
		  [DayOfWeek] VARCHAR(15) COLLATE DATABASE_DEFAULT NULL,
		  [IsActive] [BIT] NULL
		);

----------------------------------------------------------------------------------------
---- 2. Delete the files we're NOT going to use: 

	-- Incomplete backups
	DELETE	#BackupFiles
	WHERE STATUS <> 'Complete';

	-- Backups of the wrong type:
	IF @BackupType = 'Full'
		DELETE	#BackupFiles
		WHERE BackupType <> 'Full';
	ELSE IF @BackupType = 'Log'
		DELETE	#BackupFiles
		WHERE BackupType <> 'Log';
	ELSE IF @BackupType = 'Diff'
	BEGIN
		DELETE	#BackupFiles
		WHERE BackupType <> 'Diff';

		-- We only want the most recent differential backup
		DELETE	#BackupFiles
		WHERE ExecutionDateTime <> (SELECT MAX(ExecutionDateTime) FROM #BackupFiles);

	END


	-- Backups from the wrong location
	IF @BackupLoc = 'Backup' OR @BackupLoc = 'PRIMARY'
		BEGIN
			DELETE	#BackupFiles
			WHERE	isMirror = 1
					OR Op NOT IN ( 'Backup', 'Move' );

		--		A database that is backed up and then Moved will have entries for
		--		Op=Backup and entries for Op=Move in the table, all with the same 
		--		ExecutionDateTime. So, if there exist any rows in #BackupFiles that 
		--		were a Move operation, we must delete the rows for the Backup operation:
			IF EXISTS ( SELECT	*
						FROM	#BackupFiles
						WHERE	Op = 'Move' ) 
				DELETE	#BackupFiles
				WHERE	Op = 'Backup';

		END	

	IF @BackupLoc = 'Mirror' 
		DELETE	#BackupFiles
		WHERE	isMirror = 0;

	IF @BackupLoc = 'Copy' 
		DELETE	#BackupFiles
		WHERE	isMirror = 1
				OR Op <> 'Copy';

	IF @BackupLoc = 'Move' 
		DELETE	#BackupFiles
		WHERE	isMirror = 1
				OR Op <> 'Move';

	
	IF ( SELECT	COUNT(*)
		 FROM	#BackupFiles
	   ) = 0 
		RAISERROR('Your backup files do not exist.', 16, 1);
	-- change this to regular logging/alert


--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------BEGIN Dynamic DBName----------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

IF @RestoreDBName IS NULL
	BEGIN

----0 = MinionDefault, >0 = DB override.
	SET @PathSettingLevel = ( SELECT	COUNT(*)
							  FROM		Minion.BackupRestoreSettingsPath
							  WHERE		ServerName = @ServerName
										AND DBName = @DBName
										AND RestoreType = 'Full'
										AND IsActive = 1
							)


IF @PathSettingLevel = 0
	BEGIN --@PathSettingLevel = 0
		SET @RestoreDBName = (SELECT TOP 1 RestoreDBName FROM Minion.BackupRestoreSettingsPath WHERE ServerName = @ServerName
										AND DBName = 'MinionDefault'
										AND RestoreType = 'Full'
										AND IsActive = 1)
	END --@PathSettingLevel = 0

IF @PathSettingLevel > 1
	BEGIN --@PathSettingLevel > 1
		SET @RestoreDBName = (SELECT TOP 1 RestoreDBName FROM Minion.BackupRestoreSettingsPath WHERE ServerName = @ServerName
										AND DBName = @DBName
										AND RestoreType = 'Full'
										AND IsActive = 1)
	END --@PathSettingLevel > 1

	END


	EXEC Minion.DBMaintInlineTokenParse @DBName, @DynamicName = @RestoreDBName OUTPUT;
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------END Dynamic DBName------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------
---- Build restore statement
	----CREATE TABLE #filelist
	----	(
	----	  LogicalName VARCHAR(255) ,
	----	  PhysicalName VARCHAR(512) ,
	----	  [Type] CHAR(1) ,
	----	  FileGroupName VARCHAR(128) ,
	----	  Size NUMERIC(38, 0) ,
	----	  MaxSize NUMERIC(38, 0) ,
	----	  FileId BIGINT ,
	----	  CreateLSN NUMERIC(38, 0) ,
	----	  DropLSN NUMERIC(38, 0) ,
	----	  UniqueID UNIQUEIDENTIFIER ,
	----	  ReadOnlyLSN NUMERIC(38, 0) ,
	----	  ReadWriteLSN NUMERIC(38, 0) ,
	----	  BackupSizeInBytes BIGINT ,
	----	  SourceBlockSize BIGINT ,
	----	  FileGroupId BIGINT ,
	----	  LogGroupGUID UNIQUEIDENTIFIER ,
	----	  DifferentialBaseLSN NUMERIC(38, 0) ,
	----	  DifferentialBaseGUID UNIQUEIDENTIFIER ,
	----	  IsReadOnly INT ,
	----	  IsPresent INT ,
	----	  TDEThumbprint VARBINARY(32)
	----	);

	CREATE TABLE #restoreCmds
		( ID INT IDENTITY(1,1),
			Cmd VARCHAR(MAX) COLLATE DATABASE_DEFAULT NULL
		);


		SET	@FileListForMove = (SELECT TOP 1 + 'DISK = ''' + BF.FullFileName + ''''
		FROM	#BackupFiles BF)

------SELECT  DISTINCT @ThisServer AS ThisServer, @ServerName AS ServerName, @ThisServerWithoutInstance AS WOInstance, ExecutionDateTime ,
------				Op ,
------				Status ,
------				DBName ,
------				ServerLabel ,
------				BackupType
------		FROM    #BackupFiles
------		ORDER BY ExecutionDateTime;

	DECLARE files CURSOR
	FOR
		SELECT  DISTINCT ExecutionDateTime ,
				Op ,
				Status ,
				DBName ,
				ServerLabel ,
				BackupType
		FROM    #BackupFiles
		ORDER BY ExecutionDateTime;
	OPEN files;
	FETCH NEXT FROM files INTO @ExecutionDateTime ,
				@Op ,
				@Status ,
				@DBName ,
				@ServerLabel ,
				@BackupType ;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @FileList = '';
		--SET @FileListForMove = '';
		SELECT	@FileList = @FileList + 'DISK = ''' + 
		CASE WHEN BF.FullFileName LIKE '\\%' THEN BF.FullFileName
			 --Default instance-Handle it differently for a default instance.
			 WHEN (@ThisServer <> @ServerName) AND @ServerName NOT LIKE '%\%' AND BF.FullFileName LIKE '[aA-zZ]:\%' 
				THEN '\\' + @ThisServerWithoutInstance + '\' + REPLACE(BF.FullFileName, ':', '$')
			 --Named instance- Need to remove the instance name from the path cause you connect to the server, not the instance for a restore.
			 WHEN (@ThisServer <> @ServerName) AND @ThisServer LIKE '%\%' AND BF.FullFileName LIKE '[aA-zZ]:\%' 
				THEN '\\' + @ThisServerWithoutInstance + '\' + REPLACE(BF.FullFileName, ':', '$')
			ELSE FullFileName
		END
		+ ''', '
		FROM	#BackupFiles BF
			WHERE BF.ExecutionDateTime = @ExecutionDateTime
				AND BF.Op = @Op
				AND BF.Status = @Status
				AND BF.DBName = @DBName
				AND BF.ServerLabel = @ServerLabel
				AND BF.BackupType = @BackupType
		ORDER BY FullFileName;

		----This has to be done a 2nd time because we need the orig filename intact 
		----so we can pass this into the MOVE SP.  This filename must match what's in
		----Minion.BackupFiles.
		----SELECT	@FileListForMove = @FileListForMove + 'DISK = ''' + BF.FullFileName + ''', '
		----FROM	#BackupFiles BF
		----	WHERE BF.ExecutionDateTime = @ExecutionDateTime
		----		AND BF.Op = @Op
		----		AND BF.Status = @Status
		----		AND BF.DBName = @DBName
		----		AND BF.ServerLabel = @ServerLabel
		----		AND BF.BackupType = @BackupType
		----ORDER BY FullFileName;

		SET @FileList = LEFT(@FileList, LEN(@FileList) - 1);
		------ @FileListForMove = LEFT(@FileListForMove, LEN(@FileListForMove) - 1);

		EXEC [Minion].[BackupRestoreMoveLocationsGet] @ServerName, @DBName, 'Full', @FileListForMove, @WithMove = @WithMove OUTPUT;
		----SELECT @WithMove AS WithMove
		----PRINT 'EXEC [Minion].[BackupRestoreMoveLocationsGet] @ServerName, ' + @DBName + ', ''Full'', ' + @FileListForMove + ', @WithMove = @WithMove OUTPUT;'

		IF @BackupType = 'Log'
			SET @RestoreCmd = 'RESTORE LOG [' + CASE WHEN @RestoreDBName IS NOT NULL THEN @RestoreDBName ELSE @DBName END + '] FROM ' + @FileList
				--+ ' WITH ' + @WithMove;
		ELSE
			SET @RestoreCmd = 'RESTORE DATABASE [' + CASE WHEN @RestoreDBName IS NOT NULL THEN @RestoreDBName ELSE @DBName END + '] FROM ' + @FileList
				+ ' WITH ' + @WithMove;

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-------------------BEGIN Dynamic Tuning-------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
BEGIN --Dynamic Tuning
DECLARE @TuningSettingLevel INT,
		@TuningTypeLevel INT,
		@DBSize INT,
		@BufferCount INT,
		@MaxTransferSize int,
		@BlockSize BIGINT,
		@Replace BIT,
		@WithFlags VARCHAR(1000);
------------------------------------------------------
------------------------------------------------------
--------------BEGIN DBSize----------------------------
------------------------------------------------------
------------------------------------------------------
DECLARE @OpName VARCHAR(20) = 'Restore';

SET @DBSize = (SELECT (SizeInMB/1024) FROM Minion.BackupLogDetails WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName AND BackupType = @BackupType);
--EXEC Minion.DBMaintDBSizeGet @Module = 'Backup', @OpName = @OpName output, @DBName = @DBName, @DBSize = @DBSize output

------------------------------------------------------
------------------------------------------------------
--------------END DBSize------------------------------
------------------------------------------------------
------------------------------------------------------

	SET @TuningSettingLevel = ( SELECT	COUNT(*)
								FROM	Minion.BackupRestoreTuningThresholds
								WHERE	DBName = @DBName
										AND IsActive = 1
							  )

---------------------
			--MinionDefault
	IF @TuningSettingLevel = 0 
		BEGIN --@TuningSettingLevel = 0
				--Find out whether you're going to be working at the 'All' level or at the override level.
				----1 = MinionDefault, BackupType. 0 = MinionDefault, All
			SET @TuningTypeLevel = ( SELECT	COUNT(*)
									 FROM	Minion.BackupRestoreTuningThresholds
									 WHERE	ServerName = 'MinionDefault'
											AND DBName = 'MinionDefault'
											AND RestoreType = @BackupType
											AND IsActive = 1
								   )
		END --@TuningSettingLevel = 0

			--DBName
	IF @TuningSettingLevel > 0 
		BEGIN --@TuningSettingLevel > 0
				--Find out whether you're going to be working at the 'All' level or at the override level.
					----1 = DBName, BackupType. 0 = DBName, All
			SET @TuningTypeLevel = ( SELECT	COUNT(*)
									 FROM	Minion.BackupRestoreTuningThresholds
									 WHERE	ServerName = @ServerName
											AND DBName = @DBName
											AND RestoreType = @BackupType
											AND IsActive = 1
								   )
		END	--@TuningSettingLevel > 0


			IF @TuningSettingLevel = 0 
				BEGIN --@TuningSettingLevel = 0

				--Level 0 is ALL.
					IF @TuningTypeLevel = 0 
						BEGIN --@TuningTypeLevel = 0
									INSERT #BackupRestoreTuningThresholdsStmtGet (DBName, RestoreType, SpaceType, ThresholdMeasure, ThresholdValue, Buffercount, MaxTransferSize, BlockSize, [Replace], WithFlags, BeginTime, EndTime, [DayOfWeek], IsActive)
									SELECT 
									@DBName,
									@BackupType,
									SpaceType,
									ThresholdMeasure,
									ThresholdValue,
									Buffercount ,
									MaxTransferSize ,
									BlockSize,
									[Replace],
									WithFlags,
									BeginTime,
									EndTime,
									[DayOfWeek],
									IsActive
							FROM	Minion.BackupRestoreTuningThresholds
							WHERE	ThresholdValue <= @DBSize
									AND DBName = 'MinionDefault'
									AND RestoreType = 'All'
									AND IsActive = 1
									--AND CONVERT(VARCHAR(20), GETDATE(), 114) BETWEEN CONVERT(VARCHAR(20), ISNULL(BeginTime, '00:00:00:000'), 114) AND CONVERT(VARCHAR(20), ISNULL(EndTime, '24:59:59:999'), 114)
									ORDER BY ThresholdValue DESC
						END --@TuningTypeLevel = 0

					IF @TuningTypeLevel > 0 
						BEGIN --@TuningTypeLevel > 0
									INSERT #BackupRestoreTuningThresholdsStmtGet (DBName, RestoreType, SpaceType, ThresholdMeasure, ThresholdValue, Buffercount, MaxTransferSize, BlockSize, [Replace], WithFlags, BeginTime, EndTime, [DayOfWeek], IsActive)
									SELECT 
									@DBName,
									@BackupType,
									SpaceType,
									ThresholdMeasure,
									ThresholdValue,
									Buffercount ,
									MaxTransferSize ,
									BlockSize,
									[Replace],
									WithFlags,
									BeginTime,
									EndTime,
									[DayOfWeek],
									IsActive
							FROM	Minion.BackupRestoreTuningThresholds
							WHERE	ThresholdValue <= @DBSize
									AND ServerName = @ServerName									
									AND DBName = 'MinionDefault'
									AND RestoreType = @BackupType
									AND IsActive = 1
									ORDER BY ThresholdValue DESC
						END --@TuningTypeLevel > 0
				END --@TuningSettingLevel = 0

			IF @TuningSettingLevel > 0 
				BEGIN --@TuningSettingLevel > 0
				
					IF @TuningTypeLevel = 0 
						BEGIN --@TuningTypeLevel = 0
									INSERT #BackupRestoreTuningThresholdsStmtGet (DBName, RestoreType, SpaceType, ThresholdMeasure, ThresholdValue, Buffercount, MaxTransferSize, BlockSize, [Replace], WithFlags, BeginTime, EndTime, [DayOfWeek], IsActive)
									SELECT 
									@DBName,
									@BackupType,
									SpaceType,
									ThresholdMeasure,
									ThresholdValue,
									Buffercount ,
									MaxTransferSize ,
									BlockSize,
									[Replace],
									WithFlags,
									BeginTime,
									EndTime,
									[DayOfWeek],
									IsActive
							FROM	Minion.BackupRestoreTuningThresholds
							WHERE	ThresholdValue <= @DBSize
									AND DBName = @DBName
									AND RestoreType = 'All'
									AND IsActive = 1
									ORDER BY ThresholdValue DESC					
						END --@TuningTypeLevel = 0

					IF @TuningTypeLevel > 0 
						BEGIN --@TuningTypeLevel > 0
									INSERT #BackupRestoreTuningThresholdsStmtGet (DBName, RestoreType, SpaceType, ThresholdMeasure, ThresholdValue, Buffercount, MaxTransferSize, BlockSize, [Replace], WithFlags, BeginTime, EndTime, [DayOfWeek], IsActive)
									SELECT 
									@DBName,
									@BackupType,
									SpaceType,
									ThresholdMeasure,
									ThresholdValue,
									Buffercount ,
									MaxTransferSize ,
									BlockSize,
									[Replace],
									WithFlags,
									BeginTime,
									EndTime,
									[DayOfWeek],
									IsActive
							FROM	Minion.BackupRestoreTuningThresholds
							WHERE	ThresholdValue <= @DBSize
							AND ServerName = @ServerName
									AND DBName = @DBName
									AND RestoreType = @BackupType
									AND IsActive = 1
									ORDER BY ThresholdValue DESC	
						END --@TuningTypeLevel > 0
				END --@TuningSettingLevel > 0


-----------------------------------------------------------
-------------BEGIN Delete Unwanted Thresholds--------------
-----------------------------------------------------------

----Delete times first.
	BEGIN
		DELETE #BackupRestoreTuningThresholdsStmtGet WHERE NOT (CONVERT(VARCHAR(20), GETDATE(), 114) BETWEEN CONVERT(VARCHAR(20), BeginTime, 114) AND CONVERT(VARCHAR(20), EndTime, 114)) AND (BeginTime IS NOT NULL AND EndTime IS NOT NULL)
	END

----If today is a Weekday of month then delete everything else.
IF (SELECT TOP 1 1 FROM #BackupRestoreTuningThresholdsStmtGet WHERE [DayOfWeek] = 'Weekday') = 1
BEGIN
	IF DATENAME(dw,GETDATE()) IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
		BEGIN
			DELETE #BackupRestoreTuningThresholdsStmtGet WHERE ([DayOfWeek] NOT IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday') AND [DayOfWeek] <> 'Weekday' OR [DayOfWeek] IS NULL)
		END
END

----If today is a Weekend of month then delete everything else.
IF (SELECT TOP 1 1 FROM #BackupRestoreTuningThresholdsStmtGet WHERE [DayOfWeek] = 'Weekend') = 1
BEGIN
	IF DATENAME(dw,GETDATE()) IN ('Saturday', 'Sunday')
		BEGIN
			DELETE #BackupRestoreTuningThresholdsStmtGet  WHERE ([DayOfWeek] NOT IN ('Saturday', 'Sunday') AND [DayOfWeek] <> 'Weekend' OR [DayOfWeek] IS NULL)
		END
END

----If there are records for today, then delete everything else.
IF EXISTS (SELECT 1 FROM #BackupRestoreTuningThresholdsStmtGet WHERE [DayOfWeek] = DATENAME(dw,GETDATE()))
	BEGIN
		DELETE #BackupRestoreTuningThresholdsStmtGet WHERE [DayOfWeek] <> DATENAME(dw,GETDATE()) OR [DayOfWeek] IS NULL
	END

------------------------BEGIN DELETE Named Days that Don't Match---------------
	--If there are named days, then delete everything that isn't the named day if the named day is today.
	--So if the named day is Friday and today is Monday, then it shouldn't be in the table.

			BEGIN
				DELETE #BackupRestoreTuningThresholdsStmtGet  WHERE ([DayOfWeek] IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') 
				AND [DayOfWeek] <> DATENAME(dw, GETDATE()))
			END
------------------------END DELETE Named Days that Don't Match-----------------

----If there are NO records for today, then delete the days that aren't null so we can be left with only NULLs.
IF EXISTS (SELECT 1 FROM #BackupRestoreTuningThresholdsStmtGet WHERE [BeginTime] IS NOT NULL)
	BEGIN
		DELETE #BackupRestoreTuningThresholdsStmtGet WHERE [BeginTime] IS NULL
	END

			SELECT TOP 1
					@BufferCount = Buffercount ,
					@MaxTransferSize = MaxTransferSize ,
					@BlockSize = BlockSize,
					@Replace = [Replace],
					@WithFlags = WithFlags
			FROM	#BackupRestoreTuningThresholdsStmtGet
			WHERE	ThresholdValue <= @DBSize
			ORDER BY ThresholdValue DESC

-----------------------------------------------------------
-------------END Delete Unwanted Thresholds----------------
-----------------------------------------------------------

IF @BufferCount > 0 OR @MaxTransferSize > 0 OR @BlockSize > 0
BEGIN
	SET @RestoreCmd = @RestoreCmd + ', ' 
END
------------------------------------------------------
------------------------------------------------------
------------------ Begin Set BufferCount -------------
------------------------------------------------------
------------------------------------------------------	
 
	IF @BufferCount IS NULL 
		BEGIN 		
			SET @BufferCount = 0		
		END 
			
--Finally, set the buffercount.			
	IF @BufferCount > 0 
		BEGIN -- Begin Set BufferCount	
			SET @RestoreCmd = @RestoreCmd + 'BufferCount = '
				+ CAST(@BufferCount AS VARCHAR(10)) + ', '		
		END -- End Set BufferCount	

------------------------------------------------------
------------------------------------------------------
------------------ End Set BufferCount ---------------
------------------------------------------------------
------------------------------------------------------


------------------------------------------------------
------------------------------------------------------
------------------ Begin Set MaxTransferSize ---------
------------------------------------------------------
------------------------------------------------------	
    -- Appends MaxTransferSize if needed

	IF @MaxTransferSize IS NULL 
		BEGIN 		
			SET @MaxTransferSize = 0		
		END

	IF @MaxTransferSize > 0 
		BEGIN 	
			SET @RestoreCmd = @RestoreCmd + 'MaxTransferSize = '
				+ CAST(@MaxTransferSize AS VARCHAR(31)) + ', '
		END 

------------------------------------------------------
------------------------------------------------------
------------------ End Set MaxTransferSize -----------
------------------------------------------------------
------------------------------------------------------


------------------------------------------------------
------------------------------------------------------
------------------ Begin Set BlockSize----------------
------------------------------------------------------
------------------------------------------------------	
    -- Appends MaxTransferSize if needed

	IF @BlockSize IS NULL 
		BEGIN 		
			SET @BlockSize = 0		
		END

	IF @BlockSize > 0 
		BEGIN 	
			SET @RestoreCmd = @RestoreCmd + 'BlockSize = '
				+ CAST(@BlockSize AS VARCHAR(31)) + ', '
		END 

------------------------------------------------------
------------------------------------------------------
------------------ End Set BlockSize------------------
------------------------------------------------------
------------------------------------------------------



------------------------------------------------------
------------------------------------------------------
------------------ Begin Set Replace------------------
------------------------------------------------------
------------------------------------------------------	
    -- Appends MaxTransferSize if needed

	IF @Replace IS NULL 
		BEGIN 		
			SET @Replace = 0		
		END

	IF ( SUBSTRING(@RestoreCmd, LEN(RTRIM(@RestoreCmd)), 1) = ',' ) 
		BEGIN  
			SET @RestoreCmd = LEFT(@RestoreCmd, LEN(@RestoreCmd) - 1)
		END

	IF @Replace > 0 
		BEGIN 
			IF ( SUBSTRING(@RestoreCmd, LEN(RTRIM(@RestoreCmd)), 1) <> ',' )
				BEGIN
					SET @RestoreCmd = @RestoreCmd + ','
				END
			SET @RestoreCmd = @RestoreCmd + ' REPLACE, '
		END 

------------------------------------------------------
------------------------------------------------------
------------------ End Set Replace--------------------
------------------------------------------------------
------------------------------------------------------


------------------------------------------------------
------------------------------------------------------
------------------ Begin WithFlags--------------------
------------------------------------------------------
------------------------------------------------------	

	IF @WithFlags IS NOT NULL 
		BEGIN 
			IF ( SUBSTRING(@RestoreCmd, LEN(RTRIM(@RestoreCmd)), 1) <> ',' ) OR ( SUBSTRING(@RestoreCmd, LEN(RTRIM(@RestoreCmd)), 1) <> ', ' )
				BEGIN 
				
					SET @RestoreCmd = @RestoreCmd + ', ';		
				END			
			SET @RestoreCmd = @RestoreCmd + @WithFlags
		END 

------------------------------------------------------
------------------------------------------------------
------------------ End WithFlags----------------------
------------------------------------------------------
------------------------------------------------------


END -- --Dynamic Tuning
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-------------------BEGIN Dynamic Tuning-------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------



----Take off the trailing comma.
	IF ( SUBSTRING(@RestoreCmd, LEN(RTRIM(@RestoreCmd)), 1) = ',' ) 
		BEGIN  
			SET @RestoreCmd = LEFT(@RestoreCmd, LEN(@RestoreCmd) - 1)
		END

		SET @RestoreCmd = @RestoreCmd + ';'

		INSERT INTO #restoreCmds ( Cmd )
		VALUES  ( @RestoreCmd );

	IF @StmtOnly = 1 
		PRINT @RestoreCmd;
	
		--TRUNCATE TABLE #filelist;
		FETCH NEXT FROM files INTO @ExecutionDateTime ,
				@Op ,
				@Status ,
				@DBName ,
				@ServerLabel ,
				@BackupType ;

	END	-- of WHILE @@FETCH_STATUS = 0
	CLOSE files;
	DEALLOCATE files;


----------------------------------------------------------------------------------------
---- Print or run the restore statement

	IF @StmtOnly = 0
		SELECT Cmd FROM #restoreCmds; -- actually we'd want to run these.



GO
