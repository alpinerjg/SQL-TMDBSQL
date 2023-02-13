SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

                                                                                                                                                                
CREATE PROCEDURE [Minion].[BackupStmtGet]
	(
	  @DBName NVARCHAR(400),
	  @BackupType VARCHAR(20) ,
	  @DBSize DECIMAL(18, 2) = NULL -- Projected size in GB.
	)
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

Purpose: Generate the backup statement for a given database. You can also use 
		this procedure to determine what backup tuning threshold settings a
		database would use at a given size, by using the @DBSize parameter.
		 

Features:
	* 

Limitations:
	*  

Notes:
	* 

Walkthrough: 
      

Conventions:

Parameters:
-----------
    @DBName - The name of the database for which we'll generate the backup statement.
	
	@BackupType - Full, diff, or log.
	
	@DBSize - Projected size of the database, in GB. Use this to generate the backup 
			statement using the backup tuning settings at a particular size threshold.
    
Tables: 
--------
	

Example Executions:
--------------------
	-- Generate the full backup statement for database "BackupInstallTest".
	EXEC [Minion].[BackupStmtGet] @DBName = 'BackupInstallTest',
		@BackupType = 'Full', @DBSize = NULL;

Revision History:
	

***********************************************************************************/
AS 
	SET NOCOUNT ON;
	DECLARE	@Idx SMALLINT ,
		@BackupString NVARCHAR(MAX) ,
		@MirrorString NVARCHAR(4000) ,
		@Folder VARCHAR(5000) ,
		@MirrorFolder VARCHAR(5000) ,
		@DriveLetter VARCHAR(10) ,
		@DateLogic VARCHAR(50) ,
		@FileName VARCHAR(1000) ,
		@FileNameComplete VARCHAR(2000) ,
		@CodeVersion VARCHAR(10) ,
		@Version VARCHAR(50) ,
		@Edition VARCHAR(15) ,
		@MainFileList VARCHAR(MAX) ,
		@MirrorFileList VARCHAR(MAX) ,
		@BackupCMD VARCHAR(10) ,
		@SettingLevel TINYINT ,
		@PathSettingLevel TINYINT ,
		@BasePath VARCHAR(MAX) ,
		@BackupLocType VARCHAR(20) ,
		@FilePath VARCHAR(MAX) = NULL ,
		@MirrorBackup BIT = 0 ,
		@MirrorPath VARCHAR(MAX) = NULL ,
		@NumberOfFiles SMALLINT = NULL ,
		@BufferCount INT = 0 ,
		@MaxTransferSize INT = 0 ,
		@BlockSize BIGINT = 0 ,
		@Compression BIT = NULL ,
		@TuningSettingLevel SMALLINT ,
		@DynamicTuning BIT ,
		@TuningTypeLevel TINYINT ,
		@Drive VARCHAR(1000) ,
		@RetHrs INT ,
		@Path VARCHAR(MAX) ,
		@ServerLabel SYSNAME ,
		@MirrorFull BIT ,
		@MirrorDiff BIT ,
		@MirrorLog BIT ,
		@NETBIOSName VARCHAR(128) ,
		@EncryptBackup BIT ,
		@EncryptFull BIT ,
		@EncryptDiff BIT ,
		@EncryptLog BIT ,
		@BackupName VARCHAR(128) ,
		@ExpireDateInHrs INT ,
		@Descr VARCHAR(255) ,
		@RetainDays INT ,
		@Checksum BIT ,
		@Init BIT ,
		@Format BIT ,
		@CopyOnly BIT ,
		@Skip BIT ,
		@BackupErrorMgmt VARCHAR(50) ,
		@MediaName VARCHAR(128) ,
		@MediaDescription VARCHAR(255) ,
		@MinSizeForDiffInGB BIGINT ,
		@DiffReplaceAction VARCHAR(4) ,
		@ChangeBackupType BIT,
		@DBIsInAG BIT,
		@IsPrimaryReplica BIT,
		@ExecutionDateTime DATETIME,
		@BackupTypeORIG VARCHAR(20);
		
	SET @CodeVersion = 'V.1';
	SET @ChangeBackupType = 0;
---------------------------------------------------------------------------------
------------------ BEGIN Get Version Info----------------------------------------
---------------------------------------------------------------------------------

--We need to track this because as of 1.3 we can pass in a CHECKDB type right after, it'll be changed to FULL.
SET @BackupTypeORIG = @BackupType;

IF UPPER(@BackupType) = 'CHECKDB'
	BEGIN
		SET @BackupType = 'Full';
	END

SET @ExecutionDateTime = (SELECT MAX(ExecutionDateTime) FROM Minion.BackupLogDetails WHERE DBName = @DBName AND BackupType = @BackupType);


	SELECT	@Version = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(15)),
							CHARINDEX('.',
									  CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(15)),
									  1) - 1)
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

---------------------------------------------------------------------------------
------------------ END Get Version Info------------------------------------------
---------------------------------------------------------------------------------

	CREATE TABLE #BackupTableStmtGet
		(
		  Command VARCHAR(MAX) COLLATE DATABASE_DEFAULT ,
		  BackupDrive VARCHAR(100) COLLATE DATABASE_DEFAULT ,
		  BackupPath VARCHAR(1000) COLLATE DATABASE_DEFAULT ,
		  BackupLocType VARCHAR(20) COLLATE DATABASE_DEFAULT ,
		  FullPath VARCHAR(2000) COLLATE DATABASE_DEFAULT ,
		  ServerLabel VARCHAR(150) COLLATE DATABASE_DEFAULT ,
		  FullFileName VARCHAR(1000) COLLATE DATABASE_DEFAULT ,
		  FileName VARCHAR(100) COLLATE DATABASE_DEFAULT ,
		  DateLogic VARCHAR(100) COLLATE DATABASE_DEFAULT ,
		  Extension VARCHAR(5) COLLATE DATABASE_DEFAULT ,
		  MainFileList VARCHAR(MAX) COLLATE DATABASE_DEFAULT ,
		  MirrorFileList VARCHAR(MAX) COLLATE DATABASE_DEFAULT ,
		  IsMirror BIT ,
		  RetHrs INT ,
		  PathOrder TINYINT ,
		  FileNumber TINYINT ,
		  Buffercount INT ,
		  MaxTransferSize BIGINT ,
		  NumberOfFiles INT ,
		  Compression BIT
		)

--------------------------------------------------BEGIN Set Backup Options-------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

----Find out if the settings will come from the DB level or from the default level.
----If the levels are 0 then that means there's not a row fur the current DB so it gets its 
----values from the MinionDefault entry.
	SET @SettingLevel = ( SELECT	COUNT(*)
						  FROM		Minion.BackupSettings
						  WHERE		DBName = @DBName
									AND IsActive = 1
						);
	SET @TuningSettingLevel = ( SELECT	COUNT(*)
								FROM	Minion.BackupTuningThresholds
								WHERE	DBName = @DBName
										AND IsActive = 1
							  );
	SET @PathSettingLevel = ( SELECT	COUNT(*)
							  FROM		Minion.BackupSettingsPath
							  WHERE		DBName = @DBName
										AND IsActive = 1
							);
---------------------
	CREATE TABLE #BackupTuningThresholdsStmtGet
		(
		  [DBName] NVARCHAR(400) COLLATE DATABASE_DEFAULT NOT NULL ,
		  [BackupType] [VARCHAR](4) COLLATE DATABASE_DEFAULT NULL ,
		  [SpaceType] [VARCHAR](20) COLLATE DATABASE_DEFAULT NULL ,
		  [ThresholdMeasure] [CHAR](2) COLLATE DATABASE_DEFAULT NULL ,
		  [ThresholdValue] [BIGINT] NULL ,
		  [NumberOfFiles] [TINYINT] NULL ,
		  [Buffercount] [SMALLINT] NULL ,
		  [MaxTransferSize] [BIGINT] NULL ,
		  [Compression] [BIT] NULL ,
		  [BlockSize] [BIGINT] NULL ,
		  BeginTime VARCHAR(20),
		  EndTime VARCHAR(20),
		  [DayOfWeek] VARCHAR(15),
		  [IsActive] [BIT] NULL
		);

---------------------
			--MinionDefault
	IF @TuningSettingLevel = 0 
		BEGIN --@TuningSettingLevel = 0
				--Find out whether you're going to be working at the 'All' level or at the override level.
				----1 = MinionDefault, BackupType. 0 = MinionDefault, All
			SET @TuningTypeLevel = ( SELECT	COUNT(*)
									 FROM	Minion.BackupTuningThresholds
									 WHERE	DBName = 'MinionDefault'
											AND BackupType = @BackupType
											AND IsActive = 1
								   )
		END --@TuningSettingLevel = 0

			--DBName
	IF @TuningSettingLevel > 0 
		BEGIN --@TuningSettingLevel > 0
				--Find out whether you're going to be working at the 'All' level or at the override level.
					----1 = DBName, BackupType. 0 = DBName, All
			SET @TuningTypeLevel = ( SELECT	COUNT(*)
									 FROM	Minion.BackupTuningThresholds
									 WHERE	DBName = @DBName
											AND BackupType = @BackupType
											AND IsActive = 1
								   )
		END	--@TuningSettingLevel > 0

------------------------------------------------------------------------
------------------BEGIN General Settings--------------------------------
------------------------------------------------------------------------

	CREATE TABLE #BackupSettingsStmtGET
		(
		  [DynamicTuning] [BIT] NULL ,
		  [BackupType] VARCHAR(20) COLLATE DATABASE_DEFAULT ,
		  [Mirror] [BIT] NULL ,
		  [Encrypt] [BIT] NULL ,
		  [NAME] [VARCHAR](128) COLLATE DATABASE_DEFAULT NULL ,
		  [ExpireDateInHrs] [INT] NULL ,
		  [Descr] [VARCHAR](255) COLLATE DATABASE_DEFAULT NULL ,
		  [RetainDays] [INT] NULL ,
		  [Checksum] [BIT] NULL ,
		  [Init] [BIT] NULL ,
		  [Format] [BIT] NULL ,
		  [CopyOnly] [BIT] NULL ,
		  [Skip] [BIT] NULL ,
		  [BackupErrorMgmt] [VARCHAR](50) COLLATE DATABASE_DEFAULT NULL ,
		  [MediaName] [VARCHAR](128) COLLATE DATABASE_DEFAULT NULL ,
		  [MediaDescription] [VARCHAR](255) COLLATE DATABASE_DEFAULT NULL ,
		  [MinSizeForDiffInGB] BIGINT ,
		  [DiffReplaceAction] VARCHAR(4) COLLATE DATABASE_DEFAULT
		);

	IF @SettingLevel > 0 
		BEGIN
			INSERT	#BackupSettingsStmtGET
					( DynamicTuning ,
					  BackupType ,
					  Mirror ,
					  Encrypt ,
					  NAME ,
					  ExpireDateInHrs ,
					  Descr ,
					  RetainDays ,
					  Checksum ,
					  Init ,
					  Format ,
					  CopyOnly ,
					  Skip ,
					  BackupErrorMgmt ,
					  MediaName ,
					  MediaDescription ,
					  MinSizeForDiffInGB ,
					  DiffReplaceAction
					)
					SELECT	DynamicTuning ,
							BackupType ,
							Mirror ,
							Encrypt ,
							Name ,
							ExpireDateInHrs ,
							Descr ,
							[RetainDays] ,
							[Checksum] ,
							[Init] ,
							[Format] ,
							[CopyOnly] ,
							[Skip] ,
							[BackupErrorMgmt] ,
							[MediaName] ,
							[MediaDescription] ,
							[MinSizeForDiffInGB] ,
							[DiffReplaceAction]
					FROM	Minion.BackupSettings
					WHERE	DBName = @DBName
							AND (BackupType = @BackupTypeORIG
							OR BackupType = 'All')
							AND IsActive = 1
		END

	IF @SettingLevel = 0 
		BEGIN
			INSERT	#BackupSettingsStmtGET
					( DynamicTuning ,
					  BackupType ,
					  Mirror ,
					  Encrypt ,
					  NAME ,
					  ExpireDateInHrs ,
					  Descr ,
					  RetainDays ,
					  Checksum ,
					  Init ,
					  Format ,
					  CopyOnly ,
					  Skip ,
					  BackupErrorMgmt ,
					  MediaName ,
					  MediaDescription ,
					  MinSizeForDiffInGB ,
					  DiffReplaceAction
					)
					SELECT	DynamicTuning ,
							BackupType ,
							Mirror ,
							Encrypt ,
							Name ,
							ExpireDateInHrs ,
							Descr ,
							[RetainDays] ,
							[Checksum] ,
							[Init] ,
							[Format] ,
							[CopyOnly] ,
							[Skip] ,
							[BackupErrorMgmt] ,
							[MediaName] ,
							[MediaDescription] ,
							[MinSizeForDiffInGB] ,
							[DiffReplaceAction]
					FROM	Minion.BackupSettings
					WHERE	DBName = 'MinionDefault'
							AND (BackupType = @BackupTypeORIG
							OR BackupType = 'All')
							AND IsActive = 1	
		END

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
------------------------BEGIN Delete Unwanted BackupTypes--------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

-------------------------------------------------------------
-------------BEGIN Delete All--------------------------------
-------------------------------------------------------------
--If there's a current backup type we'll use it and get rid
--of the All row.
	IF ( SELECT	COUNT(*)
		 FROM	#BackupSettingsStmtGET
		 WHERE	BackupType = @BackupTypeORIG
	   ) > 0 
		BEGIN
			DELETE	#BackupSettingsStmtGET
			WHERE	BackupType <> @BackupTypeORIG
		END

-------------------------------------------------------------
-------------END Delete All----------------------------------
-------------------------------------------------------------

-------------------------------------------------------------
-------------BEGIN Delete BackupType-------------------------
-------------------------------------------------------------
--If there isn't a current backup type need to use the All row.
	IF ( SELECT	COUNT(*)
		 FROM	#BackupSettingsStmtGET
		 WHERE	BackupType = @BackupTypeORIG
	   ) = 0 
		BEGIN
			DELETE	#BackupSettingsStmtGET
			WHERE	BackupType <> 'All'
		END
-------------------------------------------------------------
-------------END Delete BackupType---------------------------
-------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
------------------------END Delete Unwanted BackupTypes----------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------


----Now we should have it down to a single row so we can assign our vars.
	SELECT	@DynamicTuning = DynamicTuning ,
			@MirrorBackup = Mirror ,
			@EncryptBackup = Encrypt ,
			@BackupName = NAME ,
			@ExpireDateInHrs = ExpireDateInHrs ,
			@Descr = Descr ,
			@RetainDays = [RetainDays] ,
			@Checksum = [Checksum] ,
			@Init = [Init] ,
			@Format = [Format] ,
			@CopyOnly = [CopyOnly] ,
			@Skip = [Skip] ,
			@BackupErrorMgmt = [BackupErrorMgmt] ,
			@MediaName = [MediaName] ,
			@MediaDescription = [MediaDescription] ,
			@MinSizeForDiffInGB = MinSizeForDiffInGB ,
			@DiffReplaceAction = DiffReplaceAction
	FROM	#BackupSettingsStmtGET 

------------------------------------------------------------------------
------------------END General Settings----------------------------------
------------------------------------------------------------------------





------------------------------------------------------------------------
------------------BEGIN ServerLabel--------------------------------------
------------------------------------------------------------------------

	IF @ServerLabel IS NULL 
		BEGIN
			SET @ServerLabel = @@ServerName;
		END

	SET @NETBIOSName = CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS VARCHAR(128))

------------------------------------------------------------------------
------------------END ServerLabel----------------------------------------
------------------------------------------------------------------------




------------------------------------------------------------------------
-------------------BEGIN Get BasePath-----------------------------------
------------------------------------------------------------------------
---Maybe add an order col so you can specify the drive order you want.
	DECLARE	@i TINYINT ,
		@FileCounter TINYINT ,
		@MaxDrives TINYINT


	CREATE TABLE #BackupPathsTempStmtGet
		(
		  ID INT IDENTITY(1, 1) ,
		  DBName NVARCHAR(400) COLLATE DATABASE_DEFAULT ,
		  BackupType VARCHAR(20) COLLATE DATABASE_DEFAULT ,
		  BackupDrive VARCHAR(100) COLLATE DATABASE_DEFAULT ,
		  BackupPath VARCHAR(1000) COLLATE DATABASE_DEFAULT ,
		  [FileName] VARCHAR(200) COLLATE DATABASE_DEFAULT ,
		  FileExtension VARCHAR(50) COLLATE DATABASE_DEFAULT ,
		  BackupLocType VARCHAR(20) COLLATE DATABASE_DEFAULT ,
		  ServerLabel VARCHAR(100) COLLATE DATABASE_DEFAULT ,
		  RetHrs INT ,
		  PathOrder TINYINT ,
		  IsMirror BIT ,
		  AzureCredential VARCHAR(100) COLLATE DATABASE_DEFAULT
		)

	CREATE TABLE #BackupPathsMainStmtGet
		(
		  ID INT IDENTITY(1, 1) ,
		  DBName NVARCHAR(400) COLLATE DATABASE_DEFAULT ,
		  BackupType VARCHAR(20) COLLATE DATABASE_DEFAULT ,
		  BackupDrive VARCHAR(100) COLLATE DATABASE_DEFAULT ,
		  BackupPath VARCHAR(1000) COLLATE DATABASE_DEFAULT ,
		  [FileName] VARCHAR(200) COLLATE DATABASE_DEFAULT ,
		  FileExtension VARCHAR(50) COLLATE DATABASE_DEFAULT ,
		  BackupLocType VARCHAR(20) COLLATE DATABASE_DEFAULT ,
		  ServerLabel VARCHAR(100) COLLATE DATABASE_DEFAULT ,
		  RetHrs INT ,
		  PathOrder TINYINT ,
		  IsMirror BIT ,
		  AzureCredential VARCHAR(100) COLLATE DATABASE_DEFAULT
		)

	CREATE TABLE #BackupPathsMirrorStmtGet
		(
		  ID INT IDENTITY(1, 1) ,
		  DBName NVARCHAR(400) COLLATE DATABASE_DEFAULT ,
		  BackupType VARCHAR(20) COLLATE DATABASE_DEFAULT ,
		  BackupDrive VARCHAR(100) COLLATE DATABASE_DEFAULT ,
		  BackupPath VARCHAR(1000) COLLATE DATABASE_DEFAULT ,
		  [FileName] VARCHAR(200) COLLATE DATABASE_DEFAULT ,
		  FileExtension VARCHAR(50) COLLATE DATABASE_DEFAULT ,
		  BackupLocType VARCHAR(20) COLLATE DATABASE_DEFAULT ,
		  ServerLabel VARCHAR(100) COLLATE DATABASE_DEFAULT ,
		  RetHrs INT ,
		  PathOrder TINYINT ,
		  IsMirror BIT ,
		  AzureCredential VARCHAR(100) COLLATE DATABASE_DEFAULT
		)

----------------------------------------------------------------------------
------------------BEGIN Get Full Drive List---------------------------------
----------------------------------------------------------------------------
--This is the full drive list for the DB.  
--It will be trimmed down based on criteria later on.

	IF @PathSettingLevel > 0 
		BEGIN --@PathSettingLevel = 1

			INSERT	#BackupPathsTempStmtGet
					( DBName ,
					  BackupType ,
					  BackupDrive ,
					  BackupPath ,
					  BackupLocType ,
					  [FileName],
					  FileExtension,
					  ServerLabel ,
					  RetHrs ,
					  PathOrder ,
					  IsMirror ,
					  AzureCredential
					)
					SELECT	DBName ,
							BackupType ,
							BackupDrive ,
							BackupPath ,
							BackupLocType ,
							[FileName],
							FileExtension,
							ISNULL(ServerLabel, @ServerLabel) ,
							RetHrs ,
							PathOrder ,
							IsMirror ,
							ISNULL(AzureCredential, '')
					FROM	Minion.BackupSettingsPath
					WHERE	DBName = @DBName
							AND IsActive = 1
							AND BackupType NOT LIKE '%Cert%'
							AND BackupType NOT IN ('Copy', 'Move')
					ORDER BY PathOrder DESC

		END --@PathSettingLevel = 1

	IF @PathSettingLevel = 0 
		BEGIN --@PathSettingLevel = 0

			INSERT	#BackupPathsTempStmtGet
					( DBName ,
					  BackupType ,
					  BackupDrive ,
					  BackupPath ,
					  BackupLocType ,
					  [FileName],
					  FileExtension,
					  ServerLabel ,
					  RetHrs ,
					  PathOrder ,
					  IsMirror ,
					  AzureCredential
					)
					SELECT	DBName ,
							BackupType ,
							BackupDrive ,
							BackupPath ,
							BackupLocType ,
							[FileName],
							FileExtension,
							ISNULL(ServerLabel, @ServerLabel) ,
							RetHrs ,
							PathOrder ,
							IsMirror ,
							ISNULL(AzureCredential, '')
					FROM	Minion.BackupSettingsPath
					WHERE	DBName = 'MinionDefault'
							AND IsActive = 1
							AND BackupType NOT LIKE '%Cert%'
							AND BackupType NOT IN ('Copy', 'Move')
					ORDER BY PathOrder DESC

		END --@PathSettingLevel = 0

----------------------------------------------------------------------------
------------------END Get Full Drive List-----------------------------------
----------------------------------------------------------------------------
  
-----------------------------------------------------------------------------------------------------------------
---------------------------------------BEGIN Drop Unwanted Drives------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

----------You can specify that a set of files is for all backup types.
----------This makes it easy to have all the backups going to one set of drives.

	IF ( SELECT	COUNT(*)
		 FROM	#BackupPathsTempStmtGet
		 WHERE	BackupType = @BackupType
	   ) > 0 
		BEGIN
			DELETE	#BackupPathsTempStmtGet
			WHERE	BackupType <> @BackupType
					AND IsMirror = 0
		END

	IF ( SELECT	COUNT(*)
		 FROM	#BackupPathsTempStmtGet
		 WHERE	BackupType = @BackupType
	   ) = 0 
		BEGIN
			DELETE	#BackupPathsTempStmtGet
			WHERE	BackupType <> 'All'
					AND IsMirror = 0
		END


--------This table is to get the ID col to start back over at 1.
--------This has to happen for the file create section below as the ID has to match the loop iterator.
	INSERT	#BackupPathsMainStmtGet
			( DBName ,
			  BackupType ,
			  BackupDrive ,
			  BackupPath ,
			  BackupLocType ,
			  [FileName],
			  FileExtension,
			  ServerLabel ,
			  RetHrs ,
			  PathOrder ,
			  IsMirror ,
			  AzureCredential
			)
			SELECT	DBName ,
					BackupType ,
					BackupDrive ,
					BackupPath ,
					BackupLocType ,
					[FileName],
					FileExtension,
					ServerLabel ,
					RetHrs ,
					PathOrder ,
					IsMirror ,
					AzureCredential
			FROM	#BackupPathsTempStmtGet
			WHERE	IsMirror = 0
			ORDER BY PathOrder DESC
------------------------------------------------------------------------
-------------------BEGIN Is Mirror--------------------------------------
------------------------------------------------------------------------

----Copy mirror paths to Mirror table.  The mirror loop below relies on the 1st drive to be numbered 1.
----So moving the mirror paths to this folder with a new ID col is the easiest way to make that happen.
	IF @MirrorBackup = 1 
		BEGIN


----------You can specify that a set of files is for all backup types.
----------This makes it easy to have all the backups going to one set of drives.

	IF ( SELECT	COUNT(*)
		 FROM	#BackupPathsTempStmtGet
		 WHERE	BackupType = @BackupType AND IsMirror = 1
	   ) > 0 
		BEGIN
			DELETE	#BackupPathsTempStmtGet
			WHERE	BackupType <> @BackupType AND IsMirror = 1
		END

	IF ( SELECT	COUNT(*)
		 FROM	#BackupPathsTempStmtGet
		 WHERE	BackupType = @BackupType AND IsMirror = 1
	   ) = 0 
		BEGIN
			DELETE	#BackupPathsTempStmtGet
			WHERE	BackupType <> 'All' AND IsMirror = 1
		END

			INSERT	#BackupPathsMirrorStmtGet
					( DBName ,
					  BackupType ,
					  BackupDrive ,
					  BackupPath ,
					  BackupLocType ,
					  [FileName],
					  FileExtension,
					  ServerLabel ,
					  RetHrs ,
					  PathOrder ,
					  IsMirror ,
					  AzureCredential
					)
					SELECT	DBName ,
							BackupType ,
							BackupDrive ,
							BackupPath ,
							BackupLocType ,
							[FileName],
							FileExtension,
							ServerLabel ,
							RetHrs ,
							PathOrder ,
							IsMirror ,
							AzureCredential
					FROM	#BackupPathsTempStmtGet
					WHERE	IsMirror = 1
					ORDER BY PathOrder DESC
		END

------------------------------------------------------------------------
-------------------END Is Mirror----------------------------------------
------------------------------------------------------------------------

----Now that paths are separated into main and mirror, we're done with this table now.
	DROP TABLE #BackupPathsTempStmtGet

------------------------------------------------------------------------
-------------------END Get BasePath-------------------------------------
------------------------------------------------------------------------

	SET @Folder = @BasePath;
			
	SET @MainFileList = '';

	SET @Idx = 0 -- Loop counter		
	SELECT	@DateLogic = CONVERT(VARCHAR(8), GETDATE(), 112)
			+ REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '') --Assign DateLogic
	SET @FileName = RTRIM(LTRIM(@DBName)) + @DateLogic -- builds filename with current database and the above DateLogic

If @BackupLocType <> 'URL' AND @BackupLocType IS NOT NULL
BEGIN
	SET @FilePath = @Folder + RTRIM(LTRIM(@DBName)) + '\'
END




------------------------------------------------------------------------
-------------------BEGIN Dynamic Tuning---------------------------------
------------------------------------------------------------------------
--You can pick between static and dynamic configs.  
--The static config will always be where ThresholdMeasure = 0 because that fits everything.
--If you want something specific then add a value for the DB and the size.
--And as usual, the values will come from MinionDefault unless there's an entry for the DB.
		  

	IF @DynamicTuning = 1 
		BEGIN --@DynamicTuning = 1

			IF @TuningSettingLevel = 0 
				BEGIN --@TuningSettingLevel = 0

				--Level 0 is ALL.
					IF @TuningTypeLevel = 0 
						BEGIN --@TuningTypeLevel = 0
									INSERT #BackupTuningThresholdsStmtGet (DBName, BackupType, SpaceType, ThresholdMeasure, ThresholdValue, NumberOfFiles, Buffercount, MaxTransferSize, Compression, BlockSize, BeginTime, EndTime, [DayOfWeek], IsActive)
									SELECT 
									@DBName,
									@BackupType,
									SpaceType,
									ThresholdMeasure,
									ThresholdValue,
									NumberOfFiles ,
									Buffercount ,
									MaxTransferSize ,
									Compression ,
									BlockSize,
									BeginTime,
									EndTime,
									[DayOfWeek],
									IsActive
							FROM	Minion.BackupTuningThresholds
							WHERE	ThresholdValue <= @DBSize
									AND DBName = 'MinionDefault'
									AND BackupType = 'All'
									AND IsActive = 1
									--AND CONVERT(VARCHAR(20), GETDATE(), 114) BETWEEN CONVERT(VARCHAR(20), ISNULL(BeginTime, '00:00:00:000'), 114) AND CONVERT(VARCHAR(20), ISNULL(EndTime, '24:59:59:999'), 114)
									ORDER BY ThresholdValue DESC
						END --@TuningTypeLevel = 0

					IF @TuningTypeLevel > 0 
						BEGIN --@TuningTypeLevel > 0
									INSERT #BackupTuningThresholdsStmtGet (DBName, BackupType, SpaceType, ThresholdMeasure, ThresholdValue, NumberOfFiles, Buffercount, MaxTransferSize, Compression, BlockSize, BeginTime, EndTime, [DayOfWeek], IsActive)
									SELECT 
									@DBName,
									@BackupType,
									SpaceType,
									ThresholdMeasure,
									ThresholdValue,
									NumberOfFiles ,
									Buffercount ,
									MaxTransferSize ,
									Compression ,
									BlockSize,
									BeginTime,
									EndTime,
									[DayOfWeek],
									IsActive
							FROM	Minion.BackupTuningThresholds
							WHERE	ThresholdValue <= @DBSize
									AND DBName = 'MinionDefault'
									AND BackupType = @BackupType
									AND IsActive = 1
									ORDER BY ThresholdValue DESC
						END --@TuningTypeLevel > 0
				END --@TuningSettingLevel = 0

			IF @TuningSettingLevel > 0 
				BEGIN --@TuningSettingLevel > 0
				
					IF @TuningTypeLevel = 0 
						BEGIN --@TuningTypeLevel = 0
									INSERT #BackupTuningThresholdsStmtGet (DBName, BackupType, SpaceType, ThresholdMeasure, ThresholdValue, NumberOfFiles, Buffercount, MaxTransferSize, Compression, BlockSize, BeginTime, EndTime, [DayOfWeek], IsActive)
									SELECT 
									@DBName,
									@BackupType,
									SpaceType,
									ThresholdMeasure,
									ThresholdValue,
									NumberOfFiles ,
									Buffercount ,
									MaxTransferSize ,
									Compression ,
									BlockSize,
									BeginTime,
									EndTime,
									[DayOfWeek],
									IsActive
							FROM	Minion.BackupTuningThresholds
							WHERE	ThresholdValue <= @DBSize
									AND DBName = @DBName
									AND BackupType = 'All'
									AND IsActive = 1
									ORDER BY ThresholdValue DESC					
						END --@TuningTypeLevel = 0

					IF @TuningTypeLevel > 0 
						BEGIN --@TuningTypeLevel > 0
									INSERT #BackupTuningThresholdsStmtGet (DBName, BackupType, SpaceType, ThresholdMeasure, ThresholdValue, NumberOfFiles, Buffercount, MaxTransferSize, Compression, BlockSize, BeginTime, EndTime, [DayOfWeek], IsActive)
									SELECT 
									@DBName,
									@BackupType,
									SpaceType,
									ThresholdMeasure,
									ThresholdValue,
									NumberOfFiles ,
									Buffercount ,
									MaxTransferSize ,
									Compression ,
									BlockSize,
									BeginTime,
									EndTime,
									[DayOfWeek],
									IsActive
							FROM	Minion.BackupTuningThresholds
							WHERE	ThresholdValue <= @DBSize
									AND DBName = @DBName
									AND BackupType = @BackupType
									AND IsActive = 1
									ORDER BY ThresholdValue DESC	
						END --@TuningTypeLevel > 0
				END --@TuningSettingLevel > 0
		END --@DynamicTuning = 1

	IF @DynamicTuning = 0 
		BEGIN --@DynamicTuning = 0	
			IF @SettingLevel > 0 
				BEGIN --@SettingLevel > 0 	  
									INSERT #BackupTuningThresholdsStmtGet (DBName, BackupType, SpaceType, ThresholdMeasure, ThresholdValue, NumberOfFiles, Buffercount, MaxTransferSize, Compression, BlockSize, BeginTime, EndTime, [DayOfWeek], IsActive)
									SELECT 
									@DBName,
									@BackupType,
									SpaceType,
									ThresholdMeasure,
									ThresholdValue,
									NumberOfFiles ,
									Buffercount ,
									MaxTransferSize ,
									Compression ,
									BlockSize,
									BeginTime,
									EndTime,
									[DayOfWeek],
									IsActive
							FROM	Minion.BackupTuningThresholds
									WHERE	DBName = @DBName
											AND ThresholdValue = 0
											AND IsActive = 1
									ORDER BY ThresholdValue DESC			
				END --@SettingLevel > 0 
			IF @SettingLevel = 0 
				BEGIN --@SettingLevel = 0 
									INSERT #BackupTuningThresholdsStmtGet (DBName, BackupType, SpaceType, ThresholdMeasure, ThresholdValue, NumberOfFiles, Buffercount, MaxTransferSize, Compression, BlockSize, BeginTime, EndTime, [DayOfWeek], IsActive)
									SELECT --TOP 1
									@DBName,
									@BackupType,
									SpaceType,
									ThresholdMeasure,
									ThresholdValue,
									NumberOfFiles ,
									Buffercount ,
									MaxTransferSize ,
									Compression ,
									BlockSize,
									BeginTime,
									EndTime,
									[DayOfWeek],
									IsActive
							FROM	Minion.BackupTuningThresholds
							WHERE	DBName = 'MinionDefault'
							AND ThresholdValue = 0
							AND IsActive = 1
									ORDER BY ThresholdValue DESC	

				END --@SettingLevel = 0 
		END --@DynamicTuning = 0

-----------------------------------------------------------
-------------BEGIN Delete Unwanted Thresholds--------------
-----------------------------------------------------------

----Delete times first.
	BEGIN
		DELETE #BackupTuningThresholdsStmtGet WHERE NOT (CONVERT(VARCHAR(20), GETDATE(), 114) BETWEEN CONVERT(VARCHAR(20), BeginTime, 114) AND CONVERT(VARCHAR(20), EndTime, 114)) AND (BeginTime IS NOT NULL AND EndTime IS NOT NULL)
	END

----If today is a Weekday of month then delete everything else.
IF (SELECT TOP 1 1 FROM #BackupTuningThresholdsStmtGet WHERE [DayOfWeek] = 'Weekday') = 1
BEGIN
	IF DATENAME(dw,GETDATE()) IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
		BEGIN
			DELETE #BackupTuningThresholdsStmtGet WHERE ([DayOfWeek] NOT IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday') AND [DayOfWeek] <> 'Weekday' OR [DayOfWeek] IS NULL)
		END
END

----If today is a Weekend of month then delete everything else.
IF (SELECT TOP 1 1 FROM #BackupTuningThresholdsStmtGet WHERE [DayOfWeek] = 'Weekend') = 1
BEGIN
	IF DATENAME(dw,GETDATE()) IN ('Saturday', 'Sunday')
		BEGIN
			DELETE #BackupTuningThresholdsStmtGet  WHERE ([DayOfWeek] NOT IN ('Saturday', 'Sunday') AND [DayOfWeek] <> 'Weekend' OR [DayOfWeek] IS NULL)
		END
END

----If there are records for today, then delete everything else.
IF EXISTS (SELECT 1 FROM #BackupTuningThresholdsStmtGet WHERE [DayOfWeek] = DATENAME(dw,GETDATE()))
	BEGIN
		DELETE #BackupTuningThresholdsStmtGet WHERE [DayOfWeek] <> DATENAME(dw,GETDATE()) OR [DayOfWeek] IS NULL
	END

------------------------BEGIN DELETE Named Days that Don't Match---------------
	--If there are named days, then delete everything that isn't the named day if the named day is today.
	--So if the named day is Friday and today is Monday, then it shouldn't be in the table.

			BEGIN
				DELETE #BackupTuningThresholdsStmtGet  WHERE ([DayOfWeek] IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') 
				AND [DayOfWeek] <> DATENAME(dw, GETDATE()))
			END
------------------------END DELETE Named Days that Don't Match-----------------

----If there are NO records for today, then delete the days that aren't null so we can be left with only NULLs.
IF EXISTS (SELECT 1 FROM #BackupTuningThresholdsStmtGet WHERE [BeginTime] IS NOT NULL)
	BEGIN
		DELETE #BackupTuningThresholdsStmtGet WHERE [BeginTime] IS NULL
	END

			SELECT TOP 1
					@BufferCount = Buffercount ,
					@MaxTransferSize = MaxTransferSize ,
					@Compression = Compression ,
					@NumberOfFiles = NumberOfFiles ,
					@BlockSize = BlockSize
			FROM	#BackupTuningThresholdsStmtGet
			WHERE	ThresholdValue <= @DBSize
			ORDER BY ThresholdValue DESC

-----------------------------------------------------------
-------------END Delete Unwanted Thresholds----------------
-----------------------------------------------------------

----------------BEGIN FailSafe-----------------------
--If you've forgotten to configure a row setting for  the current DB and size, then we still want the backup to kick off.
--Therefore if this table is empty we'll take from the MinionDefault-All-0.
--You really should configure a row for the intended backup.  This is just a failsafe in case so you can have backups.
--We're not using the BeginTime and EndTime here because it's not relevant.  This is a failsafe so nothing should get in the way of finding a row.
	IF @NumberOfFiles IS NULL 
		BEGIN --FailSafe
			SELECT TOP 1
					@BufferCount = Buffercount ,
					@MaxTransferSize = MaxTransferSize ,
					@Compression = Compression ,
					@NumberOfFiles = NumberOfFiles ,
					@BlockSize = BlockSize
			FROM	Minion.BackupTuningThresholds
			WHERE	ThresholdValue <= @DBSize
					AND DBName = 'MinionDefault'
					AND BackupType = 'All'
					AND IsActive = 1
			ORDER BY ThresholdValue DESC
		END --FailSafe
----------------END FailSafe-------------------------

------------------------------------------------------------------------
-------------------END Dynamic Tuning-----------------------------------
------------------------------------------------------------------------


------------------------------------------------------------------------
-------------------BEGIN Encryption-------------------------------------
------------------------------------------------------------------------


	IF @Version >= '12' 
		BEGIN --@Version >= 12

			DECLARE	@CertName VARCHAR(100) ,
				@EncrAlgorithm VARCHAR(20) ,
				@ThumbPrint VARBINARY(32) ,
				@EncryptionSettingLevel BIT;


			IF @EncryptBackup = 1 
				BEGIN --@EncryptBackup = 1

				CREATE TABLE #BackupEncryption
				(
					[ID] [int] IDENTITY(1,1) NOT NULL,
					[DBName] NVARCHAR(400) NOT NULL,
					[BackupType] [varchar](20) NULL,
					[CertType] [varchar](50) NULL,
					[CertName] [varchar](100) NULL,
					[EncrAlgorithm] [varchar](20) NULL,
					[ThumbPrint] [varbinary](32) NULL
				)


					BEGIN --Get Encryption Level
						SET @EncryptionSettingLevel = ( SELECT	COUNT(*)
												FROM	Minion.BackupEncryption
												WHERE	DBName = @DBName AND CertType = 'BackupEncryption' AND IsActive = 1
											  )
					END --Get Encryption Level


					IF @EncryptionSettingLevel > 0 
						BEGIN
							INSERT #BackupEncryption (DBName, BackupType, CertType, CertName, EncrAlgorithm, ThumbPrint)
							SELECT	
									@DBName,
									BackupType,
									CertType,
									CertName ,
									EncrAlgorithm ,
									ThumbPrint
							FROM	Minion.BackupEncryption
							WHERE	DBName = @DBName
									AND (BackupType = @BackupType
									OR BackupType = 'All')
									AND CertType = 'BackupEncryption'
									AND IsActive = 1
						END

					IF @EncryptionSettingLevel = 0 
						BEGIN
							INSERT #BackupEncryption (DBName, BackupType, CertType, CertName, EncrAlgorithm, ThumbPrint)
							SELECT	
									@DBName,
									BackupType,
									CertType,
									CertName ,
									EncrAlgorithm ,
									ThumbPrint
							FROM	Minion.BackupEncryption
							WHERE	DBName = 'MinionDefault'
									AND (BackupType = @BackupType
									OR BackupType = 'All')
									AND CertType = 'BackupEncryption'
									AND IsActive = 1
						END

--------------------------------------------
--------------------------------------------
------BEGIN Delete Unwanted BackupTypes-----
--------------------------------------------
--------------------------------------------

-------------------------------------------------------------
-------------BEGIN Delete All--------------------------------
-------------------------------------------------------------
--If there's a current backup type we'll use it and get rid
--of the All row.
	IF ( SELECT	COUNT(*)
		 FROM	#BackupEncryption
		 WHERE	BackupType = @BackupType
	   ) > 0 
		BEGIN
			DELETE	#BackupSettingsStmtGET
			WHERE	BackupType <> @BackupType
		END

-------------------------------------------------------------
-------------END Delete All----------------------------------
-------------------------------------------------------------

-------------------------------------------------------------
-------------BEGIN Delete BackupType-------------------------
-------------------------------------------------------------
--If there isn't a current backup type need to use the All row.
	IF ( SELECT	COUNT(*)
		 FROM	#BackupEncryption
		 WHERE	BackupType = @BackupType
	   ) = 0 
		BEGIN
			DELETE	#BackupEncryption
			WHERE	BackupType <> 'All'
		END
-------------------------------------------------------------
-------------END Delete BackupType---------------------------
-------------------------------------------------------------

------------------------------------------
------------------------------------------
------END Delete Unwanted BackupTypes-----
------------------------------------------
------------------------------------------
--We should be down to a single row now so we can select into our vars.
					SELECT	@CertName = CertName ,
							@EncrAlgorithm = EncrAlgorithm ,
							@ThumbPrint = ThumbPrint
					FROM	#BackupEncryption

				END --@EncryptBackup = 1
		END --@Version >= 12

------------------------------------------------------------------------
-------------------END Encryption---------------------------------------
------------------------------------------------------------------------


---------------------------------------------------------------
----------------BEGIN AG Info----------------------------------
---------------------------------------------------------------

		IF @Version >= 11 AND @OnlineEdition = 1
			BEGIN --@Version >= 11
							SET @DBIsInAG = (SELECT Value 
													 FROM Minion.Work 
													 WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'Backup' AND DBName = @DBName AND BackupType = @BackupType AND SPName = 'BackupMaster' AND Param = '@DBIsInAG')

					--- We HAVE to run this select statement as an EXEC; even with the IF, this'd generate an error on SQL 05/08.
					IF @DBIsInAG = 1
					BEGIN --@DBIsInAG = 1
							SET @IsPrimaryReplica = (SELECT Value 
													 FROM Minion.Work 
													 WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'Backup' AND DBName = @DBName AND BackupType = @BackupType AND SPName = 'BackupMaster' AND Param = '@IsPrimaryReplica')

					END --@DBIsInAG = 1
			END --@Version >= 11

---------------------------------------------------------------
----------------END AG Info------------------------------------
---------------------------------------------------------------



--------------------------------------------------------
------------------BEGIN Set Backup Type-----------------
--------------------------------------------------------
	IF @BackupType = 'Full'
		OR @BackupType = 'Diff' 
		BEGIN
			SET @BackupCMD = ' DATABASE '
		END

	IF @BackupType = 'Log' 
		BEGIN
			SET @BackupCMD = ' LOG '
		END
--------------------------------------------------------
------------------END Set Backup Type-------------------
--------------------------------------------------------

--BEGIN --@BackupType

--------------------------------------------------------
------------------BEGIN Set BackupStmt------------------
--------------------------------------------------------

	SET @BackupString = 'BACKUP' + @BackupCMD + '[' + @DBName + '] TO ';

--------------BEGIN Main File List--------------------
	SET @MainFileList = ''

	SET @i = 1; --# of iteration for the loop. Increments the file number ie 1of10, 2of10, 3of10, etc.
	SET @FileCounter = 1;

--@MaxDrives is the # of drives you're striping the backup to.  If you have more backup files than drives, then it will start over and round robin
--the drives.  So you can have 10 files going to 3 drives and when it gets to file 4 it'll start back over on drive 1.
	SELECT	@MaxDrives = ( SELECT	COUNT(*)
						   FROM		#BackupPathsMainStmtGet
						 ) 

	DECLARE	@FullFileName VARCHAR(2000) ,
		@BackupDrive VARCHAR(100) ,
		@BackupPath VARCHAR(1000) ,
		@Extension VARCHAR(50) ,
		@PathOrder TINYINT ,
		@FileNumber TINYINT ,
		@FullPath VARCHAR(2000) ,
		@AzureCredential VARCHAR(100),
		@FileNameToParse VARCHAR(400),
		@curi VARCHAR(2),
		@curNumberOfFiles VARCHAR(2);

	WHILE @i <= @NumberOfFiles 
		BEGIN

			SELECT	
	@BackupDrive = BackupDrive,
	--@BackupPath = BackupPath,
	@BackupLocType = BackupLocType,
	@FileName = CASE WHEN ([FileName] IS NULL OR UPPER([FileName]) = 'MINIONDEFAULT' OR [FileName] = '')  THEN CAST(@i AS VARCHAR(2)) + 'of' + CAST(@NumberOfFiles AS VARCHAR(2)) + @DBName + @BackupType + @DateLogic
				ELSE [FileName]
				END
				+ CASE WHEN FileExtension IS NULL THEN '%BackupTypeExtension%'
					   WHEN UPPER(FileExtension) = 'MINIONDEFAULT' THEN '%BackupTypeExtension%'
					   ELSE FileExtension
				  END,
	@Extension = CASE WHEN FileExtension IS NULL THEN '%BackupTypeExtension%'
					   WHEN UPPER(FileExtension) = 'MINIONDEFAULT' THEN '%BackupTypeExtension%'
					   ELSE FileExtension
				 END,
	@FullPath = 
			CASE WHEN BackupLocType <> 'URL' THEN (BackupDrive + BackupPath)
				 WHEN BackupLocType = 'URL' THEN (BackupDrive + BackupPath)
			END,
					@BackupDrive = BackupDrive ,
					@BackupPath = BackupPath ,
					@BackupLocType = BackupLocType ,
					--@FullPath = ( BackupDrive + BackupPath + ServerLabel + '\'
					--			  + RTRIM(LTRIM(@DBName)) ) ,
					@ServerLabel = ServerLabel ,
					@RetHrs = RetHrs ,
					@PathOrder = PathOrder ,
					@FileNumber = @i , --This just returns the number of the file.
					@AzureCredential = ISNULL(AzureCredential, '')
			FROM	#BackupPathsMainStmtGet
			WHERE	ID = @FileCounter

SET @curi = CAST(@i AS VARCHAR(2)); --This is just to get the char version of @i.
SET @curNumberOfFiles = CAST(@NumberOfFiles AS VARCHAR(2)); --This is just to get the char version of @NumberOfFiles.

--------Get dynamic filename.
EXEC Minion.DBMaintInlineTokenParse @DBName = @DBName, @DynamicName = @FileName OUTPUT, @Ordinal = @curi, @NumFiles = @curNumberOfFiles, @ServerLabel = @ServerLabel, @BackupType = @BackupType;

IF @FileName LIKE '%.%'
 SET @Extension = '.' + RIGHT(@FileName, CHARINDEX('.', REVERSE(@FileName)) - 1);
ELSE 
 SET @Extension = '';
--------Get dynamic path.

IF @BackupPath LIKE '%\%%' ESCAPE '\' OR @FullPath LIKE '%\%' 
	BEGIN
		EXEC Minion.DBMaintInlineTokenParse @DBName = @DBName, @DynamicName = @BackupPath OUTPUT, @Ordinal = NULL, @NumFiles = NULL, @ServerLabel = @ServerLabel, @BackupType = @BackupType;
	END

SET @FullPath = @BackupDrive + @BackupPath;
SET @FileNameComplete = @FileName;
SET	@FullFileName = @BackupDrive + @BackupPath + @FileNameComplete
		----CASE WHEN @BackupLocType = 'URL' THEN @BackupDrive + @BackupPath + @FileNameComplete
		----ELSE
		----	@BackupDrive					+
		----	@BackupPath						+
		----	@ServerLabel					+
		----	'\'								+
		----	RTRIM(LTRIM(@DBName))			+
		----	'\'	
		----END;

--SET @FullFileName = @FullFileName + @FileNameComplete;




IF @BackupDrive = 'NUL'
	BEGIN
		SET @FullFileName = 'NUL'
	END
	
			IF ( @NumberOfFiles >= 1
				 AND @i <= ( @NumberOfFiles )
			   ) 
				SET @i = @i + 1

			SET @MainFileList = @MainFileList
				+ CASE WHEN @BackupLocType = 'URL' THEN 'URL = '
					   ELSE 'DISK = '
				  END + CHAR(39) + @FullFileName + CHAR(39)
			SET @MainFileList = @MainFileList + ', '

			SET @FileCounter = @FileCounter + 1

	----The FileCounter keeps track of which file we're on. If there are 3 drives, the FileCounter can't exceed the MaxDrives because it won't have anywhere to put the file.
	----So if there are 5 files and only 3 drives, then once we reach drive-3 we need to start back over at 1. So at some point FileCounter = 4 and MaxDrives = 3, and file-4 will go to Drive-1.
			IF @FileCounter > @MaxDrives 
				SET @FileCounter = 1

			INSERT	#BackupTableStmtGet
					( BackupDrive ,
					  BackupPath ,
					  BackupLocType ,
					  FullPath ,
					  ServerLabel ,
					  FullFileName ,
					  FileName ,
					  DateLogic ,
					  Extension ,
					  MainFileList ,
					  IsMirror ,
					  RetHrs ,
					  PathOrder ,
					  FileNumber
					)
					SELECT	@BackupDrive ,
							@BackupPath ,
							@BackupLocType ,
							@FullPath ,
							@ServerLabel ,
							@FullFileName ,
							@FileNameComplete ,
							@DateLogic ,
							@Extension ,
							@MainFileList ,
							0 ,
							@RetHrs ,
							@PathOrder ,
							@FileNumber 

		END

	IF RTRIM(RIGHT(@MainFileList, 2)) = ',' 
		BEGIN
			SET @MainFileList = LEFT(@MainFileList, LEN(@MainFileList) - 1)
		END

--------------END Main File List--------------------

--------------BEGIN Mirror File List--------------------

	IF @MirrorBackup = 1 
		BEGIN -- @MirrorBackup = 1

		DECLARE @MirrorBackupDrive VARCHAR(50);

			SET @MirrorFileList = ''
			SET @MirrorString = ' MIRROR TO ';
			SET @i = 1;
			SET @FileCounter = 1;

			SELECT	@MaxDrives = ( SELECT	COUNT(*)
								   FROM		#BackupPathsMirrorStmtGet
								 ) 
    
			WHILE @i <= @NumberOfFiles 
		BEGIN

			SELECT	
	@BackupDrive = BackupDrive,
	@BackupPath = BackupPath,
	@BackupLocType = BackupLocType,
	@FileName = CASE WHEN ([FileName] IS NULL OR UPPER([FileName]) = 'MINIONDEFAULT' OR [FileName] = '')  THEN CAST(@i AS VARCHAR(2)) + 'of' + CAST(@NumberOfFiles AS VARCHAR(2)) + @DBName + @BackupType + @DateLogic
				ELSE [FileName]
				END
				+ CASE WHEN FileExtension IS NULL THEN '%BackupTypeExtension%'
					   WHEN UPPER(FileExtension) = 'MINIONDEFAULT' THEN '%BackupTypeExtension%'
					   ELSE FileExtension
				  END,
	@Extension = CASE WHEN FileExtension IS NULL THEN '%BackupTypeExtension%'
					   WHEN UPPER(FileExtension) = 'MINIONDEFAULT' THEN '%BackupTypeExtension%'
					   ELSE FileExtension
				 END,
	@FullPath = 
			CASE WHEN BackupLocType <> 'URL' THEN (BackupDrive + BackupPath)
				 WHEN BackupLocType = 'URL' THEN (BackupDrive + BackupPath)
			END,
					@MirrorBackupDrive = BackupDrive ,
					@BackupPath = BackupPath ,
					@BackupLocType = BackupLocType ,
					--@FullPath = ( BackupDrive + BackupPath + ServerLabel + '\'
					--			  + RTRIM(LTRIM(@DBName)) ) ,
					@ServerLabel = ServerLabel ,
					@RetHrs = RetHrs ,
					@PathOrder = PathOrder ,
					@FileNumber = @i , --This just returns the number of the file.
					@AzureCredential = ISNULL(AzureCredential, '')
			FROM	#BackupPathsMirrorStmtGet
			WHERE	ID = @FileCounter

			----SELECT	@FullFileName = 
			----				CASE WHEN BackupLocType = 'URL' THEN BackupDrive + BackupPath + @FileNameComplete
			----				ELSE
			----					BackupDrive						+
			----					BackupPath						+
			----					ServerLabel						+
			----					'\'								+
			----					RTRIM(LTRIM(@DBName))			+
			----					'\'								+
			----					@FileNameComplete
			----				END,
			----		@MirrorBackupDrive = BackupDrive,
			----		@BackupPath = BackupPath,
			----		@BackupLocType = BackupLocType,
			----		@FullPath = 
			----CASE WHEN BackupLocType <> 'URL' THEN (BackupDrive + BackupPath + ServerLabel + '\' + RTRIM(LTRIM(@DBName)))
			----	 WHEN BackupLocType = 'URL' THEN (BackupDrive + BackupPath)
			----END,
			----		@BackupDrive = BackupDrive ,
			----		@BackupPath = BackupPath ,
			----		@BackupLocType = BackupLocType ,
			----		@FullPath = ( BackupDrive + BackupPath + ServerLabel + '\'
			----					  + RTRIM(LTRIM(@DBName)) ) ,
			----		@Extension = ( CASE	WHEN @BackupType = 'Full' THEN '.BAK'
			----							WHEN @BackupType = 'Diff' THEN '.DIFF'
			----							WHEN @BackupType = 'Log' THEN '.TRN'
			----					   END ) ,
			----		@ServerLabel = ServerLabel ,
			----		@RetHrs = RetHrs ,
			----		@PathOrder = PathOrder ,
			----		@FileNumber = @i , --This just returns the number of the file.
			----		@AzureCredential = ISNULL(AzureCredential, '')
			----FROM	#BackupPathsMirrorStmtGet
			----WHERE	ID = @FileCounter

SET @curi = CAST(@i AS VARCHAR(2)); --This is just to get the char version of @i.
SET @curNumberOfFiles = CAST(@NumberOfFiles AS VARCHAR(2)); --This is just to get the char version of @NumberOfFiles.

--------Get dynamic filename.
EXEC Minion.DBMaintInlineTokenParse @DBName = @DBName, @DynamicName = @FileName OUTPUT, @Ordinal = @curi, @NumFiles = @curNumberOfFiles, @ServerLabel = @ServerLabel, @BackupType = @BackupType;

IF @FileName LIKE '%.%'
 SET @Extension = '.' + RIGHT(@FileName, CHARINDEX('.', REVERSE(@FileName)) - 1);
ELSE 
 SET @Extension = '';
--------Get dynamic path.
IF @BackupPath LIKE '%\%%' ESCAPE '\' OR @FullPath LIKE '%\%' 
	BEGIN
		EXEC Minion.DBMaintInlineTokenParse @DBName = @DBName, @DynamicName = @BackupPath OUTPUT, @Ordinal = NULL, @NumFiles = NULL, @ServerLabel = @ServerLabel, @BackupType = @BackupType;
	END

SET @FullPath = @BackupDrive + @BackupPath;
SET @FileNameComplete = @FileName;
SET	@FullFileName = @BackupDrive + @BackupPath + @FileNameComplete
	
			IF ( @NumberOfFiles >= 1
				 AND @i <= ( @NumberOfFiles )
			   ) 
				SET @i = @i + 1

			SET @MirrorFileList = @MirrorFileList
				+ CASE WHEN @BackupLocType = 'URL' THEN 'URL = '
					   ELSE 'DISK = '
				  END + CHAR(39) + @FullFileName + CHAR(39)
			SET @MirrorFileList = @MirrorFileList + ', '

			SET @FileCounter = @FileCounter + 1

	----The FileCounter keeps track of which file we're on. If there are 3 drives, the FileCounter can't exceed the MaxDrives because it won't have anywhere to put the file.
	----So if there are 5 files and only 3 drives, then once we reach drive-3 we need to start back over at 1. So at some point FileCounter = 4 and MaxDrives = 3, and file-4 will go to Drive-1.
			IF @FileCounter > @MaxDrives 
				SET @FileCounter = 1

			INSERT	#BackupTableStmtGet
					( BackupDrive ,
					  BackupPath ,
					  BackupLocType ,
					  FullPath ,
					  ServerLabel ,
					  FullFileName ,
					  FileName ,
					  DateLogic ,
					  Extension ,
					  MirrorFileList ,
					  IsMirror ,
					  RetHrs ,
					  PathOrder ,
					  FileNumber
					)
					SELECT	@BackupDrive ,
							@BackupPath ,
							@BackupLocType ,
							@FullPath ,
							@ServerLabel ,
							@FullFileName ,
							@FileNameComplete ,
							@DateLogic ,
							@Extension ,
							@MirrorFileList ,
							1 ,
							@RetHrs ,
							@PathOrder ,
							@FileNumber 

		END

	IF RTRIM(RIGHT(@MirrorFileList, 2)) = ',' 
		BEGIN
			SET @MirrorFileList = LEFT(@MirrorFileList, LEN(@MirrorFileList) - 1)
		END

		END -- @MirrorBackup = 1
--------------END Mirror File List--------------------


	SET @BackupString = @BackupString + @MainFileList
	IF @MirrorBackup = 1 
		BEGIN
			SET @BackupString = @BackupString + @MirrorString
				+ @MirrorFileList
		END

	SET @BackupString = @BackupString + ' WITH ' 

	IF @BackupType = 'Diff' 
		BEGIN
			SET @BackupString = @BackupString + 'DIFFERENTIAL' + ', '									
		END

	IF @BufferCount IS NULL 
		BEGIN 		
			SET @BufferCount = 0		
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
			SET @BackupString = @BackupString + 'BufferCount = '
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
			SET @BackupString = @BackupString + 'MaxTransferSize = '
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
			SET @BackupString = @BackupString + 'BlockSize = '
				+ CAST(@BlockSize AS VARCHAR(31)) + ', '
		END 

------------------------------------------------------
------------------------------------------------------
------------------ End Set BlockSize------------------
------------------------------------------------------
------------------------------------------------------


------------------------------------------------------
------------------------------------------------------
------------------ Begin Compression------------------
------------------------------------------------------
------------------------------------------------------	

--There are 3 distinct situations here.  
--1. If @Compression is NULL then we don't want to print anything because that means we want the server default to kick in.
--2. If @Compression is 0 then we want to explicitely turn compression OFF.  You would do this if you have compression turned on at the server level and you want to do an uncompressed backup.
--3. If @Compression is 1 then we want to explicitely turn compression ON.  You would do this if you have compression turned off at the server level and you want to do a compressed backup.

	IF @Version >= '10' 
		BEGIN -- @Version
			IF @Compression IS NOT NULL 
				IF @Compression = 0 
					BEGIN 	
						SET @BackupString = @BackupString + 'NO_COMPRESSION '
							+ ', '																				
					END 

			IF @Compression = 1 
				BEGIN 	
					SET @BackupString = @BackupString + 'COMPRESSION ' + ', '																				
				END 
		END -- @Version
------------------------------------------------------
------------------------------------------------------
------------------ End Compression--------------------
------------------------------------------------------
------------------------------------------------------	


------------------------------------------------------
------------------------------------------------------
------------------ Begin Encryption-------------------
------------------------------------------------------
------------------------------------------------------	

	IF @Version >= '12' 
		BEGIN -- @Version

			IF @EncryptBackup = 1 
				BEGIN 	
					SET @BackupString = @BackupString + 'ENCRYPTION (ALGORITHM = '
						+ ISNULL(@EncrAlgorithm, 'NoEncryptionAlgorithmDefined') + ', ' + 'SERVER CERTIFICATE = ['
						+ ISNULL(@CertName, 'NoEncryptionCertDefined')  + ']), '																		
				END 

		END -- @Version
------------------------------------------------------
------------------------------------------------------
------------------ End Encryption---------------------
------------------------------------------------------
------------------------------------------------------

------------------------------------------------------
------------------------------------------------------
------------------ Begin Set Name --------------------
------------------------------------------------------
------------------------------------------------------	

	IF @BackupName IS NOT NULL 
		BEGIN 	
			SET @BackupString = @BackupString + 'NAME = ' + '''' + @BackupName
				+ '''' + ', '
		END 

------------------------------------------------------
------------------------------------------------------
------------------ End Set Name ----------------------
------------------------------------------------------
------------------------------------------------------


------------------------------------------------------
------------------------------------------------------
------------------ Begin Set ExpireDate --------------
------------------------------------------------------
------------------------------------------------------	

	IF @ExpireDateInHrs IS NULL 
		BEGIN 		
			SET @ExpireDateInHrs = 0		
		END

	IF @ExpireDateInHrs > 0 
		BEGIN 	
			SET @BackupString = @BackupString + 'EXPIREDATE = ' + ''''
				+ CAST(DATEADD(HOUR, @ExpireDateInHrs, GETDATE()) AS VARCHAR(31))
				+ '''' + ', '
		END 

------------------------------------------------------
------------------------------------------------------
------------------ End Set ExpireDate ----------------
------------------------------------------------------
------------------------------------------------------

------------------------------------------------------
------------------------------------------------------
------------------ Begin Set Description -------------
------------------------------------------------------
------------------------------------------------------	

	IF @Descr IS NOT NULL 
		BEGIN 	
			SET @BackupString = @BackupString + 'DESCRIPTION = ' + ''''
				+ @Descr + '''' + ', '
		END 

------------------------------------------------------
------------------------------------------------------
------------------ End Set Description ---------------
------------------------------------------------------
------------------------------------------------------

------------------------------------------------------
------------------------------------------------------
------------------ Begin Set RetainDays --------------
------------------------------------------------------
------------------------------------------------------	

	IF @RetainDays IS NULL 
		BEGIN 		
			SET @RetainDays = 0		
		END

	IF @RetainDays > 0 
		BEGIN 	
			SET @BackupString = @BackupString + 'RETAINDAYS = '
				+ CAST(@RetainDays AS VARCHAR(31)) + ', '
		END 

------------------------------------------------------
------------------------------------------------------
------------------ End Set RetainDays ----------------
------------------------------------------------------
------------------------------------------------------

------------------------------------------------------
------------------------------------------------------
------------------ Begin Checksum---------------------
------------------------------------------------------
------------------------------------------------------	

	IF @Checksum IS NOT NULL 
		BEGIN
			IF @Checksum = 0 
				BEGIN 	
					SET @BackupString = @BackupString + 'NO_CHECKSUM ' + ', '																				
				END 

			IF @Checksum = 1 
				BEGIN 	
					SET @BackupString = @BackupString + 'CHECKSUM ' + ', '																				
				END 
		END
------------------------------------------------------
------------------------------------------------------
------------------ End Checksum-----------------------
------------------------------------------------------
------------------------------------------------------

------------------------------------------------------
------------------ Begin Init-------------------------
------------------------------------------------------
------------------------------------------------------	

	IF @Init IS NOT NULL 
		BEGIN
			IF @Init = 0 
				BEGIN 	
					SET @BackupString = @BackupString + 'NO_INIT ' + ', '																				
				END 

			IF @Init = 1 
				BEGIN 	
					SET @BackupString = @BackupString + 'INIT ' + ', '																				
				END 
		END
------------------------------------------------------
------------------------------------------------------
------------------ End Init---------------------------
------------------------------------------------------
------------------------------------------------------

------------------------------------------------------
------------------ Begin Format-----------------------
------------------------------------------------------
------------------------------------------------------	

	IF @Format IS NOT NULL 
		BEGIN
			IF @Format = 0 
				BEGIN 	
					SET @BackupString = @BackupString + 'NO_FORMAT ' + ', '																				
				END 

			IF @Format = 1 
				BEGIN 	
					SET @BackupString = @BackupString + 'FORMAT ' + ', '																				
				END 
		END
------------------------------------------------------
------------------------------------------------------
------------------ End Format-------------------------
------------------------------------------------------
------------------------------------------------------

------------------------------------------------------
------------------ Begin Copy_Only--------------------
------------------------------------------------------
------------------------------------------------------	
----If the DB is in an AG, but it's not the primary, then full backups have to be
----done with CopyOnly.
If (@DBIsInAG = 1 AND @IsPrimaryReplica = 0 AND @BackupType = 'Full')
	BEGIN
		SET @CopyOnly = 1
	END

	IF @CopyOnly IS NOT NULL
		BEGIN
			IF @CopyOnly = 1 
				BEGIN 	
					SET @BackupString = @BackupString + 'COPY_ONLY ' + ', '																				
				END 
		END
------------------------------------------------------
------------------------------------------------------
------------------ End Copy_Only----------------------
------------------------------------------------------
------------------------------------------------------

------------------------------------------------------
------------------ Begin Skip-------------------------
------------------------------------------------------
------------------------------------------------------	

	IF @Skip IS NOT NULL 
		BEGIN
			IF @Skip = 0 
				BEGIN 	
					SET @BackupString = @BackupString + 'NO_SKIP ' + ', '																				
				END 

			IF @Skip = 1 
				BEGIN 	
					SET @BackupString = @BackupString + 'SKIP ' + ', '																				
				END 
		END
------------------------------------------------------
------------------------------------------------------
------------------ End Skip---------------------------
------------------------------------------------------
------------------------------------------------------

------------------------------------------------------
------------------ Begin BackupErrorMgmt------------------
------------------------------------------------------
------------------------------------------------------	

	IF @BackupErrorMgmt IS NOT NULL 
		BEGIN
			SET @BackupString = @BackupString + @BackupErrorMgmt
						+ ', '																				
		END
------------------------------------------------------
------------------------------------------------------
------------------ End BackupErrorMgmt--------------------
------------------------------------------------------
------------------------------------------------------

------------------------------------------------------
------------------ Begin Set MediaName ---------------
------------------------------------------------------
------------------------------------------------------	

	IF @MediaName IS NOT NULL 
		BEGIN 	
			SET @BackupString = @BackupString + 'MEDIANAME = ' + ''''
				+ @MediaName + '''' + ', '
		END 

------------------------------------------------------
------------------------------------------------------
------------------ End Set MediaName -----------------
------------------------------------------------------
------------------------------------------------------

------------------------------------------------------
------------------ Begin Set MediaDescription --------
------------------------------------------------------
------------------------------------------------------	

	IF @MediaDescription IS NOT NULL 
		BEGIN 	
			SET @BackupString = @BackupString + 'MEDIADESCRIPTION = ' + ''''
				+ @MediaDescription + '''' + ', '
		END 

------------------------------------------------------
------------------------------------------------------
------------------ End Set MediaDescription ----------
------------------------------------------------------
------------------------------------------------------


------------------------------------------------------
------------------ Begin Set Credential --------------
------------------------------------------------------
------------------------------------------------------	

	IF @BackupLocType = 'URL' 
		BEGIN 	
			SET @BackupString = @BackupString + 'CREDENTIAL = ' + ''''
				+ ISNULL(@AzureCredential, '') + '''' + ', '
		END 

------------------------------------------------------
------------------------------------------------------
------------------ End Set Credential ----------------
------------------------------------------------------
------------------------------------------------------

----Take off the trailing comma.
	IF ( SUBSTRING(@BackupString, LEN(RTRIM(@BackupString)), 1) = ',' ) 
		BEGIN  
			SET @BackupString = LEFT(@BackupString, LEN(@BackupString) - 1)
		END


	UPDATE	#BackupTableStmtGet
	SET		Command = @BackupString ,
			MainFileList = @MainFileList ,
			MirrorFileList = @MirrorFileList ,
			Buffercount = @BufferCount ,
			MaxTransferSize = @MaxTransferSize ,
			NumberOfFiles = @NumberOfFiles ,
			Compression = @Compression
	WHERE	IsMirror = 0

	UPDATE	#BackupTableStmtGet
	SET		Command = @BackupString ,
			MainFileList = @MainFileList ,
			MirrorFileList = @MirrorFileList ,
			Buffercount = @BufferCount ,
			MaxTransferSize = @MaxTransferSize ,
			NumberOfFiles = @NumberOfFiles ,
			Compression = @Compression
	WHERE	IsMirror = 1


	SELECT	@ServerLabel AS ServerLabel ,
			@NETBIOSName AS NETBIOSName ,
			Command ,
			BackupDrive ,
			BackupPath ,
			BackupLocType ,
			FullPath ,
			FullFileName ,
			[FileName] ,
			DateLogic ,
			Extension ,
			MainFileList ,
			MirrorFileList ,
			IsMirror ,
			RetHrs ,
			PathOrder ,
			FileNumber ,
			[Buffercount] ,
			[MaxTransferSize] ,
			NumberOfFiles ,
			[Compression] ,
			@MirrorBackup AS MirrorBackup ,
			@DynamicTuning AS DynamicTuning ,
			@EncryptBackup AS EncryptBackup ,
			@BackupName AS BackupName ,
			@ExpireDateInHrs AS ExpireDateInHrs ,
			@Descr AS Descr ,
			@RetainDays AS [RetainDays] ,
			@Checksum AS IsChecksum ,
			@BlockSize AS [BlockSize],
			@Init AS IsInit ,
			@Format AS IsFormat ,
			@CopyOnly AS IsCopyOnly ,
			@Skip AS IsSkip ,
			@BackupErrorMgmt AS BackupErrorMgmt ,
			@MediaName AS [MediaName] ,
			@MediaDescription AS [MediaDescription],
			@CertName AS BackupEncryptionCertName,
			@EncrAlgorithm AS BackupEncryptionAlgorithm,
			@ThumbPrint AS BackupEncryptionCertThumbPrint
	FROM	#BackupTableStmtGet
	ORDER BY IsMirror ASC, FileNumber ASC
GO
