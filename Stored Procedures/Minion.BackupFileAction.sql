SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[BackupFileAction] 
	( 
	  @DBName NVARCHAR(400), 
	  @DateLogic VARCHAR(50), 
	  @BackupType VARCHAR(10), 
	  @ManualRun BIT = 0 
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
 
Purpose: This SP performs the backup file action you specified in the table.   
		 By backup file action we mean that currently it'll MOVE or COPY any number if files to any number 
		 of locations.  You should be careful as this can run for a very long time and could increase 
		 the time of your backups if you run this inline.   
		 
Features: 
	*  
 
Limitations: 
	*  ___ 
 
Notes: 
	* ___ 
 
 
Walkthrough:  
	1.  
 
Conventions: 
 
 
Parameters: 
----------- 
 
	@DBName	- Database name on which to perform copy and/or move.  
 
	@DateLogic -  
	 
	@BackupType -  
 
	@ManualRun -  
 
Tables: 
----------- 
	#DirExist			Temp table used to hold info returned from xp_fileexist.  
						The DirExist col is really the only important one. If it is '0'  
						then the dir does not exist, and it will be created. 
	 
	#OSVersion			Holds the result of a Powershell query for operating system version. 
	 
	#FilesToCopy		Holds the data on files to copy, retrieved from Minion.BackupFiles. 
	 
	#BackupPathsTemp	Holds backup path, type, retention, etc. information for move and copy 
						operations, retrieved from Minion.BackupSettingsPath. 
	 
	#ExecResults		Holds results of executed move/copy commands (e.g., COPY, XCOPY,  
						ROBOCOPY, etc.). 
	 
	#DistinctPaths		Holds the concatenated full path destination path for the [?] copy/move 
						operations. 
	 
	#DirExist			Holds the result of a Powershell test for existing directory. 
 
Example Execution: 
	--  
 
Revision History: 
 
 
***********************************************************************************/ 
AS  
	SET NOCOUNT ON; 
	DECLARE	@PathSettingLevel INT , 
		@i TINYINT , 
		@FileCounter TINYINT , 
		@MaxDrives TINYINT , 
		@Action VARCHAR(10) , 
		@FileAction VARCHAR(20) , 
		@FileActionMethod VARCHAR(25) , 
		@FileActionMethodFlags VARCHAR(100) , 
		@FileActionErrors VARCHAR(MAX) , 
		@ExecutionDateTime DATETIME , 
		@OSVersionTemp VARCHAR(20) , 
		@OSVersion FLOAT , 
		@OSVersionCMD NVARCHAR(200) , 
		@ServerLabel VARCHAR(140) , 
		@BackupLocType VARCHAR(20),
		@str VARCHAR(1000),
		@left VARCHAR(1000),
		@right VARCHAR(1000); 
 
	SET @PathSettingLevel = ( SELECT	COUNT(*) 
							  FROM		Minion.BackupSettingsPath 
							  WHERE		DBName = @DBName 
								AND BackupType IN ( 'Move', 'Copy' ) 
							); 
 
------------------------------------------------------------------------- 
------------------------------------------------------------------------- 
-------------------BEGIN OS Version-------------------------------------- 
------------------------------------------------------------------------- 
------------------------------------------------------------------------- 
	CREATE TABLE #OSVersion 
		( 
		  OSVersion VARCHAR(2000) 
		)  
 
	SET @OSVersionCMD = '';  
	SET @OSVersionCMD = ' powershell "$Final = (gwmi win32_operatingsystem).version; $Final" ' 
 
	INSERT	#OSVersion 
			EXEC master..xp_cmdshell @OSVersionCMD 
	DELETE	#OSVersion 
	WHERE	OSVersion IS NULL 
	SET @OSVersionTemp = ( SELECT TOP ( 1 ) 
									OSVersion 
						   FROM		#OSVersion 
						 ) 
 
	SET @OSVersion = CAST(LEFT(@OSVersionTemp, 3) AS FLOAT) 
	DROP TABLE #OSVersion 
 
------------------------------------------------------------------------- 
------------------------------------------------------------------------- 
-------------------END OS Version---------------------------------------- 
------------------------------------------------------------------------- 
------------------------------------------------------------------------- 
 
 
 
--------------------BEGIN Get List of Files to Copy--------------- 
 
	CREATE TABLE #FilesToCopy 
		( 
		  [ID] [BIGINT] NOT NULL , 
		  [ExecutionDateTime] [DATETIME] NULL , 
		  [Op] [VARCHAR](20) NULL , 
		  [Status] [VARCHAR](MAX) NULL , 
		  [DBName] NVARCHAR(400) NOT NULL , 
		  [ServerLabel] [VARCHAR](150) NULL , 
		  [NETBIOSName] [VARCHAR](128) NULL , 
		  [BackupType] [VARCHAR](20) NULL , 
		  [BackupLocType] [VARCHAR](20) NULL , 
		  [BackupDrive] [VARCHAR](100) NULL , 
		  [BackupPath] [VARCHAR](1000) NULL , 
		  [FullPath] [VARCHAR](4000) NULL , 
		  [FullFileName] [VARCHAR](8000) NULL , 
		  [FileName] [VARCHAR](500) NULL , 
		  [DateLogic] [VARCHAR](100) NULL , 
		  [Extension] [VARCHAR](50) NULL , 
		  [RetHrs] [INT] NULL , 
		  [IsMirror] [BIT] NULL , 
		  [ToBeDeleted] [DATETIME] NULL , 
		  [DeleteDateTime] [DATETIME] NULL , 
		  [IsDeleted] [BIT] NULL , 
		  [IsArchive] [BIT] NULL , 
		  [BackupSizeInMB] [NUMERIC](15, 3) NULL , 
		  [BackupName] [VARCHAR](100) NULL , 
		  [BackupDescription] [VARCHAR](1000) NULL , 
		  [ExpirationDate] [DATETIME] NULL , 
		  [Compressed] [BIT] NULL , 
		  [POSITION] [TINYINT] NULL , 
		  [DeviceType] [TINYINT] NULL , 
		  [UserName] [VARCHAR](100) NULL , 
		  [DatabaseName] [sysname] NULL , 
		  [DatabaseVersion] [INT] NULL , 
		  [DatabaseCreationDate] [DATETIME] NULL , 
		  [BackupSizeInBytes] [BIGINT] NULL , 
		  [FirstLSN] [VARCHAR](100) NULL , 
		  [LastLSN] [VARCHAR](100) NULL , 
		  [CheckpointLSN] [VARCHAR](100) NULL , 
		  [DatabaseBackupLSN] [VARCHAR](100) NULL , 
		  [BackupStartDate] [DATETIME] NULL , 
		  [BackupFinishDate] [DATETIME] NULL , 
		  [SortOrder] [INT] NULL , 
		  [CODEPAGE] [INT] NULL , 
		  [UnicodeLocaleId] [INT] NULL , 
		  [UnicodeComparisonStyle] [INT] NULL , 
		  [CompatibilityLevel] [INT] NULL , 
		  [SoftwareVendorId] [INT] NULL , 
		  [SoftwareVersionMajor] [INT] NULL , 
		  [SoftwareVersionMinor] [INT] NULL , 
		  [SovtwareVersionBuild] [INT] NULL , 
		  [MachineName] [VARCHAR](100) NULL , 
		  [Flags] [INT] NULL , 
		  [BindingID] [VARCHAR](100) NULL , 
		  [RecoveryForkID] [VARCHAR](100) NULL , 
		  [COLLATION] [VARCHAR](100) NULL , 
		  [FamilyGUID] [VARCHAR](100) NULL , 
		  [HasBulkLoggedData] [BIT] NULL , 
		  [IsSnapshot] [BIT] NULL , 
		  [IsReadOnly] [BIT] NULL , 
		  [IsSingleUser] [BIT] NULL , 
		  [HasBackupChecksums] [BIT] NULL , 
		  [IsDamaged] [BIT] NULL , 
		  [BeginsLogChain] [BIT] NULL , 
		  [HasIncompleteMeatdata] [BIT] NULL , 
		  [IsForceOffline] [BIT] NULL , 
		  [IsCopyOnly] [BIT] NULL , 
		  [FirstRecoveryForkID] [VARCHAR](100) NULL , 
		  [ForkPointLSN] [VARCHAR](100) NULL , 
		  [RecoveryModel] [VARCHAR](15) NULL , 
		  [DifferentialBaseLSN] [VARCHAR](100) NULL , 
		  [DifferentialBaseGUID] [VARCHAR](100) NULL , 
		  [BackupTypeDescription] [VARCHAR](25) NULL , 
		  [BackupSetGUID] [VARCHAR](100) NULL , 
		  [CompressedBackupSize] [BIGINT] NULL , 
		  [CONTAINMENT] [TINYINT] NULL 
		) 
 
	INSERT	#FilesToCopy 
			( ID , 
			  ExecutionDateTime , 
			  Op , 
			  Status , 
			  DBName , 
			  ServerLabel , 
			  NETBIOSName , 
			  BackupType , 
			  BackupLocType , 
			  BackupDrive , 
			  BackupPath , 
			  FullPath , 
			  FullFileName , 
			  FileName , 
			  DateLogic , 
			  Extension , 
			  RetHrs , 
			  IsMirror , 
			  ToBeDeleted , 
			  DeleteDateTime , 
			  IsDeleted , 
			  IsArchive , 
			  BackupSizeInMB , 
			  BackupName , 
			  BackupDescription , 
			  ExpirationDate , 
			  Compressed , 
			  POSITION , 
			  DeviceType , 
			  UserName , 
			  DatabaseName , 
			  DatabaseVersion , 
			  DatabaseCreationDate , 
			  BackupSizeInBytes , 
			  FirstLSN , 
			  LastLSN , 
			  CheckpointLSN , 
			  DatabaseBackupLSN , 
			  BackupStartDate , 
			  BackupFinishDate , 
			  SortOrder , 
			  CODEPAGE , 
			  UnicodeLocaleId , 
			  UnicodeComparisonStyle , 
			  CompatibilityLevel , 
			  SoftwareVendorId , 
			  SoftwareVersionMajor , 
			  SoftwareVersionMinor , 
			  SovtwareVersionBuild , 
			  MachineName , 
			  Flags , 
			  BindingID , 
			  RecoveryForkID , 
			  COLLATION , 
			  FamilyGUID , 
			  HasBulkLoggedData , 
			  IsSnapshot , 
			  IsReadOnly , 
			  IsSingleUser , 
			  HasBackupChecksums , 
			  IsDamaged , 
			  BeginsLogChain , 
			  HasIncompleteMeatdata , 
			  IsForceOffline , 
			  IsCopyOnly , 
			  FirstRecoveryForkID , 
			  ForkPointLSN , 
			  RecoveryModel , 
			  DifferentialBaseLSN , 
			  DifferentialBaseGUID , 
			  BackupTypeDescription , 
			  BackupSetGUID , 
			  CompressedBackupSize , 
			  CONTAINMENT 
			) 
			SELECT	ID , 
					ExecutionDateTime , 
					Op , 
					Status , 
					DBName , 
					ServerLabel , 
					NETBIOSName , 
					BackupType , 
					BackupLocType , 
					BackupDrive , 
					BackupPath , 
					FullPath , 
					FullFileName , 
					FileName , 
					DateLogic , 
					Extension , 
					RetHrs , 
					IsMirror , 
					ToBeDeleted , 
					DeleteDateTime , 
					IsDeleted , 
					IsArchive , 
					BackupSizeInMB , 
					BackupName , 
					BackupDescription , 
					ExpirationDate , 
					Compressed , 
					POSITION , 
					DeviceType , 
					UserName , 
					DatabaseName , 
					DatabaseVersion , 
					DatabaseCreationDate , 
					BackupSizeInBytes , 
					FirstLSN , 
					LastLSN , 
					CheckpointLSN , 
					DatabaseBackupLSN , 
					BackupStartDate , 
					BackupFinishDate , 
					SortOrder , 
					CODEPAGE , 
					UnicodeLocaleId , 
					UnicodeComparisonStyle , 
					CompatibilityLevel , 
					SoftwareVendorId , 
					SoftwareVersionMajor , 
					SoftwareVersionMinor , 
					SovtwareVersionBuild , 
					MachineName , 
					Flags , 
					BindingID , 
					RecoveryForkID , 
					COLLATION , 
					FamilyGUID , 
					HasBulkLoggedData , 
					IsSnapshot , 
					IsReadOnly , 
					IsSingleUser , 
					HasBackupChecksums , 
					IsDamaged , 
					BeginsLogChain , 
					HasIncompleteMeatdata , 
					IsForceOffline , 
					IsCopyOnly , 
					FirstRecoveryForkID , 
					ForkPointLSN , 
					RecoveryModel , 
					DifferentialBaseLSN , 
					DifferentialBaseGUID , 
					BackupTypeDescription , 
					BackupSetGUID , 
					CompressedBackupSize , 
					CONTAINMENT 
			FROM	Minion.BackupFiles 
			WHERE	DateLogic = @DateLogic 
					AND DBName = @DBName 
					AND BackupType = @BackupType 
					AND IsMirror = 0 
					AND Op = 'Backup' 
----SELECT 'FilesToCopy', * FROM #FilesToCopy 
UPDATE #FilesToCopy
SET Extension = '%BackupTypeExtension%'
WHERE Extension IS NULL OR UPPER(Extension) = 'MINIONDEFAULT' OR Extension = '';

--1.4 fix. MB wasn't able to copy files cause sometimes in the BackupFiles table this col didn't have a '\' at the end.
UPDATE #FilesToCopy
SET FullPath = FullPath + '\'
WHERE RIGHT(FullPath, 1) <> '\';
--------------------END Get List of Files to Copy----------------- 
 
	SET @ExecutionDateTime = ( SELECT TOP ( 1 ) 
										ExecutionDateTime 
							   FROM		#FilesToCopy 
							 ) 
 
	CREATE TABLE #ExecResults 
		( 
		  ID INT IDENTITY(1, 1) , 
		  col1 VARCHAR(MAX) 
		) 
 
	CREATE TABLE #BackupPathsTemp 
		( 
		  ID INT IDENTITY(1, 1) , 
		  DBName NVARCHAR(400), 
		  BackupType VARCHAR(4) , 
		  BackupDrive VARCHAR(100) , 
		  BackupPath VARCHAR(1000) , 
		  BackupLocType VARCHAR(20) , 
		  ServerLabel VARCHAR(100) , 
		  RetHrs INT , 
		  FileActionMethod VARCHAR(25), 
		  FileActionMethodFlags VARCHAR(100), 
		  PathOrder TINYINT , 
		  IsMirror BIT 
		) 
 
	IF @PathSettingLevel > 0 
		BEGIN --@PathSettingLevel = 1 
 
			INSERT	#BackupPathsTemp 
					( DBName , 
					  BackupType , 
					  BackupDrive , 
					  BackupPath , 
					  BackupLocType , 
					  ServerLabel , 
					  RetHrs , 
					  FileActionMethod, 
					  FileActionMethodFlags, 
					  PathOrder , 
					  IsMirror 
					) 
					SELECT	DBName , 
							BackupType , 
							BackupDrive , 
							BackupPath , 
							BackupLocType , 
							ISNULL(ServerLabel, @@SERVERNAME) AS ServerLabel , 
							RetHrs , 
							FileActionMethod, 
							FileActionMethodFlags, 
							PathOrder , 
							IsMirror 
					FROM	Minion.BackupSettingsPath 
					WHERE	DBName = @DBName 
							AND BackupType IN ( 'Move', 'Copy' ) 
							AND IsActive = 1 
							AND BackupType NOT IN ( 'TDECert' ) 
					ORDER BY BackupType ASC , 
							PathOrder DESC 
 
		END --@PathSettingLevel = 1 
 
	IF @PathSettingLevel = 0  
		BEGIN --@PathSettingLevel = 0 
 
			INSERT	#BackupPathsTemp 
					( DBName , 
					  BackupType , 
					  BackupDrive , 
					  BackupPath , 
					  BackupLocType , 
					  ServerLabel , 
					  RetHrs , 
					  FileActionMethod, 
					  FileActionMethodFlags, 
					  PathOrder , 
					  IsMirror 
					) 
					SELECT	DBName , 
							BackupType , 
							BackupDrive , 
							BackupPath , 
							BackupLocType , 
							ISNULL(ServerLabel, @@SERVERNAME) AS ServerLabel , 
							RetHrs , 
							FileActionMethod, 
							FileActionMethodFlags, 
							PathOrder , 
							IsMirror 
					FROM	Minion.BackupSettingsPath 
					WHERE	DBName = 'MinionDefault' 
							AND BackupType IN ( 'Move', 'Copy' ) 
							AND IsActive = 1 
							AND BackupType NOT IN ( 'TDECert' ) 
					ORDER BY BackupType ASC , 
							PathOrder DESC 
 
		END 

------------------------------------------------------------------------- 
------------------------------------------------------------------------- 
---------------BEGIN Action Params--------------------------------------- 
------------------------------------------------------------------------- 
------------------------------------------------------------------------- 
 
	SELECT	@FileAction = FileAction --, 
			--@FileActionMethod = FileActionMethod , 
			--@FileActionMethodFlags = FileActionMethodFlags 
	FROM	Minion.BackupLogDetails 
	WHERE	ExecutionDateTime = @ExecutionDateTime 
			AND DBName = @DBName 
			AND BackupType = @BackupType; 
 
------------------------------------------------------------------------- 
------------------------------------------------------------------------- 
---------------END Action Params----------------------------------------- 
------------------------------------------------------------------------- 
------------------------------------------------------------------------- 
 
 
------------------------------------------------------------------------- 
------------------------------------------------------------------------- 
---------------BEGIN Delete Unwanted Actions----------------------------- 
------------------------------------------------------------------------- 
------------------------------------------------------------------------- 
	IF @FileAction = 'Copy'  
		BEGIN 
			DELETE	FROM #BackupPathsTemp 
			WHERE	BackupType = 'Move' 
		END 
 
	IF @FileAction = 'Move'  
		BEGIN 
			DELETE	FROM #BackupPathsTemp 
			WHERE	BackupType = 'Copy' 
		END 
 
------------------------------------------------------------------------- 
------------------------------------------------------------------------- 
---------------END Delete Unwanted Actions------------------------------- 
------------------------------------------------------------------------- 
------------------------------------------------------------------------- 
 
 
---------------------------------------------------- 
------------BEGIN Parse Dynamic Paths--------------- 
---------------------------------------------------- 
--We currently support a dynamic BackpPath, but not the filename. 
--This is because the filename should remain a constant wherever it is,  
--but the path can be as dynamic as you need it.  Who knows, maybe users will 
--start requesting dynamic filenames for copies.  We'll see. 
 
DECLARE @currBackupPath varchar(1000), 
		@currDynamicID INT, 
		@currServerLabel VARCHAR(140); 
 
DECLARE DynamicPaths CURSOR 
READ_ONLY 
FOR SELECT ID, BackupPath, ServerLabel from #BackupPathsTemp 
WHERE BackupPath LIKE '%\%%' ESCAPE '\' 
 
 
OPEN DynamicPaths 
 
	FETCH NEXT FROM DynamicPaths INTO @currDynamicID, @currBackupPath, @currServerLabel 
	WHILE (@@fetch_status <> -1) 
	BEGIN 
	      
		--EXEC Minion.BackupDynamicNameParse @DBName, @DynamicName = @currBackupPath OUTPUT; 
		EXEC Minion.DBMaintInlineTokenParse @DBName = @DBName, @DynamicName = @currBackupPath OUTPUT, @Ordinal = NULL, @NumFiles = NULL, @ServerLabel = @currServerLabel, @BackupType = @BackupType; 
		UPDATE #BackupPathsTemp 
		SET BackupPath = @currBackupPath 
		WHERE ID = @currDynamicID; 
 
FETCH NEXT FROM DynamicPaths INTO @currDynamicID, @currBackupPath, @currServerLabel 
	END 
 
CLOSE DynamicPaths 
DEALLOCATE DynamicPaths 
 
---------------------------------------------------- 
------------END Parse Dynamic Paths----------------- 
---------------------------------------------------- 
 
 
 
---------------------------------------------------- 
------------BEGIN Create Paths---------------------- 
---------------------------------------------------- 
	CREATE TABLE #DistinctPaths 
		( 
		  ID TINYINT IDENTITY(1, 1) , 
		  FullPath VARCHAR(4000) 
		) 
	INSERT	INTO #DistinctPaths 
			( FullPath 
			) 
			SELECT	( BackupDrive + BackupPath) 
			FROM	#BackupPathsTemp 
 
	CREATE TABLE #DirExist ( DirExist VARCHAR(2000) )  
 
	DECLARE --@i TINYINT, 
		@CT TINYINT , 
		@FileActionPathErrors VARCHAR(MAX) , 
		@FullPath VARCHAR(4000) , 
		@FileExistCMD NVARCHAR(4000); 
	SET @i = 1; 
	SET @CT = ( SELECT	COUNT(*) 
				FROM	#DistinctPaths 
			  ); 
	SET @FileActionPathErrors = ''; 
	WHILE @i <= @CT  
		BEGIN --FileCreate 
 
			SET @FullPath = ( SELECT	FullPath 
							  FROM		#DistinctPaths 
							  WHERE		ID = @i 
							);   
	 -- -- Set folder path  
	   
			SET @FileExistCMD = '';  
			SET @FileExistCMD = ' powershell "If ((test-path ''' + @FullPath 
				+ ''') -eq $False){MD ' + '''' + @FullPath 
				+ ''' -errorvariable err -erroraction silentlycontinue} If ($err.count -gt 0){$Final = $err} ELSE{$Final = ''Dir Exists''}; $Final" ' 
			--SELECT	@FileExistCMD AS FileExistCMDFILES 
			INSERT	#DirExist 
					EXEC master..xp_cmdshell @FileExistCMD 
 
			IF ( SELECT TOP 1 
						DirExist 
				 FROM	#DirExist 
			   ) <> 'Dir Exists'  
				BEGIN 
					SELECT	@FileActionPathErrors = @FileActionPathErrors 
							+ 'FILE ACTION ERROR: ' + ( SELECT TOP 1 
															  DirExist 
														FROM  #DirExist 
													  ) + '  ' 
				END	  
 
			TRUNCATE TABLE #DirExist; 
			SET @i = @i + 1;       
		END --FileCreate 
 
---- Reset table so the mirror backups can use it. 
	TRUNCATE TABLE #DirExist 
	--PRINT @FileActionPathErrors 
 
	IF @FileActionPathErrors <> ''  
		BEGIN 
			UPDATE	Minion.BackupLogDetails 
			SET		Warnings = ISNULL(Warnings, '') + '  FATAL ERROR: ' 
					+ @FileActionPathErrors 
			WHERE	ExecutionDateTime = @ExecutionDateTime 
					AND DBName = @DBName; 
 
			RETURN 
		END 
---------------------------------------------------- 
------------END Create Paths------------------------ 
---------------------------------------------------- 
 
 
	SET @i = 1; 
--SET @FileCounter = 1; 
 
	SELECT	@MaxDrives = ( SELECT	COUNT(*) 
						   FROM		#BackupPathsTemp 
						 )  
 
	DECLARE	@FullFileName VARCHAR(2000) , 
		@BackupDrive VARCHAR(100) , 
		@BackupPath VARCHAR(1000) , 
		@Extension VARCHAR(50) , 
		@PathOrder TINYINT , 
		@FileNumber TINYINT , 
		--@FullPath VARCHAR(2000), 
		@NumberOfFiles TINYINT , 
		@FileCMD VARCHAR(4000) , 
		@FileRetHrs INT; 
 
	WHILE @i <= @MaxDrives  
		BEGIN --WHILE 
---------------------------------------------------------- 
---Here at the top of the loop we're getting the path details for where we're going to copy the files. 
---There can be several paths as a backup can be copied/moved to as many locations as you like. 
---So for each target path, it will copy/move all the backup files to that location, then move on to the next target path and process all the 
---files to that location, and on and on. 
			SELECT	@FullPath = ( BackupDrive + BackupPath), 
								  --+ @DBName ) , --This is the FullPath for where the files will be copied. 
					@BackupDrive = BackupDrive , 
					@BackupPath = BackupPath , 
					@BackupLocType = BackupLocType , 
					--@ServerLabel = ISNULL(ServerLabel, @@SERVERNAME) , 
					@Action = BackupType , 
					@FileRetHrs = RetHrs , 
					@FileActionMethod = FileActionMethod, 
					@FileActionMethodFlags = FileActionMethodFlags, 
					----@Extension = ( CASE	WHEN @BackupType = 'Full' THEN '.BAK' 
					----					WHEN @BackupType = 'Diff' THEN '.DIFF' 
					----					WHEN @BackupType = 'Log' THEN '.TRN' 
					----			   END ) , 
					@FileNumber = @i 
			FROM	#BackupPathsTemp 
			WHERE	ID = @i 
 
----BEGIN Cursor----- 
			DECLARE	@currID INT , 
				@currFilename VARCHAR(1000) , 
				@currExtension VARCHAR(10) , 
				@currFileToCopy VARCHAR(2000) , 
				@currOrigPath VARCHAR(1000) , 
				@LogVerb VARCHAR(20) , 
				@FileActionBeginDateTime DATETIME , 
				@FileActionEndDateTime DATETIME , 
				@FileActionResults VARCHAR(MAX); 
----SELECT 'FilesToCopy', ID, FileName, Extension, FullFileName, FullPath FROM #FilesToCopy 
			DECLARE Files CURSOR READ_ONLY 
			FOR 
				SELECT	ID , 
						FileName , 
						Extension , 
						FullFileName , 
						FullPath 
				FROM	#FilesToCopy 
 
			OPEN Files 
 
			FETCH NEXT FROM Files INTO @currID, @currFilename, @currExtension, 
				@currFileToCopy, @currOrigPath 
			WHILE ( @@fetch_status <> -1 )  
				BEGIN 
 
					IF @ManualRun = 0  
						BEGIN --@ManualRun = 0 
							SET @FileActionBeginDateTime = GETDATE(); 
							SET @LogVerb = CASE	WHEN @Action = 'Copy' 
												THEN 'Copying' 
												WHEN @Action = 'Move' 
												THEN 'Moving' 
										   END 
		-------------Begin Log Current File Action------------------- 
 
							BEGIN --Log 
								UPDATE	Minion.BackupLog 
								SET		STATUS = @LogVerb + ' ' 
										+ @currFileToCopy + ' TO ' + @FullPath 
								WHERE	ID = ( SELECT	MAX(ID) 
											   FROM		Minion.BackupLogDetails 
											   WHERE	DBName = @DBName 
														AND STATUS = 'Beginning file actions' 
														AND BackupType = @BackupType 
											 ); 
							END --Log  
						END --@ManualRun = 0 
		-------------End Log Current File Action--------------------- 
					--SELECT	@currFileToCopy AS FileToCopy , 
					--		@FullPath 
					SET @FileCMD = ''; 
	   ----If @OSVersion < 6.0 

----	   -------------------Get Dynamic Extension-----------------------
----EXEC [Minion].[BackupDynamicNameParse] @DBName = @DBName, @DynamicName = @currExtension OUTPUT, @Ordinal = NULL, @NumFiles = NULL, @ServerLabel = @currServerLabel, @BackupType = @BackupType; 

	   ----------Begin Powershell methods---------- 
					IF @FileActionMethod = 'COPY' OR @FileActionMethod IS NULL  
						BEGIN 
							SET @FileCMD = ' powershell "' + @Action + ' ''' 
								+ @currFileToCopy + '''' + ' ''' + @FullPath 
								+ '''" ' 
						END 
 
					IF @FileActionMethod = 'MOVE' OR @FileActionMethod IS NULL  
						BEGIN 
							SET @FileCMD = ' powershell "' + @Action + ' ''' 
								+ @currFileToCopy + '''' + ' ''' + @FullPath 
								+ '''" ' 
						END 
	   ----------End Powershell methods------------ 

  	   ----If @OSVersion >= 6.0 
	   ----------Begin RoboCopy methods---------- 
					IF @FileActionMethod = 'ROBOCOPY' 
						BEGIN 
						SET @currOrigPath = LEFT(@currOrigPath, LEN(@currOrigPath) - 1); --Robocopy doesn't like trailing '\' in the path.
						
						IF @FullPath LIKE '%\'
							BEGIN
								----1.4 xmas tree fix. If we don't put this in an IF then the path will lose 1 char for each file.
								SET @FullPath = LEFT(@FullPath, LEN(@FullPath) - 1); --Robocopy doesn't like trailing '\' in the path.
							END
						----1.4 the CASE for @currFilename was added cause of an issue created in 1.3.
						-----This is that the FileName col in BackupFiles didn't have an extension in it, and that
						-----was breaking robocopy. So here we're testing whether the var has the extension, and if not
						-----it puts it in.
						SET @FileCMD = 'ROBOCOPY ' + ' "' + @currOrigPath 
							+ '"' + ' "' + @FullPath + '" ' + '"' 
							+ CASE  WHEN @currFilename NOT LIKE ('%' + @currExtension) THEN + @currFilename + ISNULL(@currExtension, '')
									ELSE @currFilename
							END + '" '
						IF @FileAction = 'Move'  
							BEGIN 
								SET @FileCMD = @FileCMD + ' /MOV' 
							END 
					SET @FileCMD = @FileCMD + ' /NP /NS /NC /NJH /NJS /NFL' 
					END  
----SELECT @currOrigPath, @FullPath, @currFilename, @currExtension, @FileCMD
 --SELECT @FileActionMethod, @Action, @currFileToCopy, @FullPath, @FileCMD AS FullPath  
	   ----------End RoboCopy methods------------  

	   ----------Begin Reset Paths---------- 
	   --1.4
----robocopy is different in that it doesn't like the trailing \.  So we reset it here for the others.
----Reset with \ at the end so it logs correctly in the Files table.
----It's untested, but not having it may cause the files to not be deleted cause there's not a \.
  IF RTRIM(RIGHT(@currOrigPath, 1)) <> '\'
	BEGIN
		SET @currOrigPath = @currOrigPath + '\';
	END

	  IF RTRIM(RIGHT(@FullPath, 1)) <> '\'
	BEGIN
		SET @FullPath = @FullPath + '\';
	END
	   ----------End Reset Paths------------ 

	   ----------Begin XCOPY methods---------- 
	   --There is no MOVE method for XCOPY so it can only copy. 
					IF @FileActionMethod = 'XCOPY'  
						BEGIN 
							SET @FileCMD = 'XCOPY "' + '"' + @currFileToCopy 
								+ '"' + ' "' + @FullPath + '" ' 
								+ ISNULL(@FileActionMethodFlags, '') 
						END 
	   ----------End XCOPY methods------------ 
 
	   ----------Begin ESEUTIL methods---------- 
	   --There is no MOVE method for ESEUTIL so it can only copy. 
					IF @FileActionMethod = 'ESEUTIL'  
						BEGIN 
							SET @FileCMD = 'C:\MinionBackup\ESEUTIL /y "' + @currOrigPath + '\' + @currFilename + @currExtension + '"' 
								+ ' /d ' + ' "' + @FullPath + '\' + @currFilename + '" ' 
								+ ISNULL(@FileActionMethodFlags, '') 
						END 
	   ----------End ESEUTIL methods------------ 
 
					DECLARE	@currCopyBeginTime DATETIME , 
							@currCopyEndTime DATETIME; 
 
					SET @currCopyBeginTime = GETDATE(); 
					--SELECT @FileCMD 
					INSERT	#ExecResults 
					EXEC master..xp_cmdshell @FileCMD 
 
					SET @currCopyEndTime = GETDATE(); 
 
----------------BEGIN Delete Unwanted Rows--------------------- 
					DELETE	#ExecResults 
					WHERE	col1 LIKE '%~~%' 
							OR col1 IS NULL 
							OR col1 LIKE '%Line:%char:%' 
 
 
----------------END Delete Unwanted Rows----------------------- 
 
 
----------------------------------------------------------------- 
----------------------------------------------------------------- 
--------------------BEGIN Log Current File Action---------------- 
----------------------------------------------------------------- 
----------------------------------------------------------------- 

-----------------------BEGIN Path Formatting-----------------------
--We need to make sure there are no \\ in the string, except maybe the 1st one.
--If it's a UNC path, then we'll need to keep the leading \\ and get rid of the rest.

					SET @FullFileName = @FullPath + @currFilename;
					SET @left = LEFT(@FullFileName, 2);
					SET @right = RIGHT(@FullFileName, LEN(@FullFileName)-2);
					SET @FullFileName = @left + REPLACE(@right, '\\', '\'); 
-----------------------END Path Formatting-------------------------

					INSERT	Minion.BackupFiles 
							( ExecutionDateTime , 
							  Op , 
							  Status , 
							  DBName , 
							  ServerLabel , 
							  NETBIOSName , 
							  BackupType , 
							  BackupLocType , 
							  BackupDrive , 
							  BackupPath , 
							  FullPath , 
							  FullFileName , 
							  FileName , 
							  DateLogic , 
							  Extension , 
							  RetHrs , 
							  IsMirror , 
							  ToBeDeleted , 
							  DeleteDateTime , 
							  IsDeleted , 
							  IsArchive , 
							  BackupSizeInMB , 
							  BackupName , 
							  BackupDescription , 
							  ExpirationDate , 
							  Compressed , 
							  POSITION , 
							  DeviceType , 
							  UserName , 
							  DatabaseName , 
							  DatabaseVersion , 
							  DatabaseCreationDate , 
							  BackupSizeInBytes , 
							  FirstLSN , 
							  LastLSN , 
							  CheckpointLSN , 
							  DatabaseBackupLSN , 
							  BackupStartDate , 
							  BackupFinishDate , 
							  SortOrder , 
							  CODEPAGE , 
							  UnicodeLocaleId , 
							  UnicodeComparisonStyle , 
							  CompatibilityLevel , 
							  SoftwareVendorId , 
							  SoftwareVersionMajor , 
							  SoftwareVersionMinor , 
							  SovtwareVersionBuild , 
							  MachineName , 
							  Flags , 
							  BindingID , 
							  RecoveryForkID , 
							  COLLATION , 
							  FamilyGUID , 
							  HasBulkLoggedData , 
							  IsSnapshot , 
							  IsReadOnly , 
							  IsSingleUser , 
							  HasBackupChecksums , 
							  IsDamaged , 
							  BeginsLogChain , 
							  HasIncompleteMeatdata , 
							  IsForceOffline , 
							  IsCopyOnly , 
							  FirstRecoveryForkID , 
							  ForkPointLSN , 
							  RecoveryModel , 
							  DifferentialBaseLSN , 
							  DifferentialBaseGUID , 
							  BackupTypeDescription , 
							  BackupSetGUID , 
							  CompressedBackupSize , 
							  CONTAINMENT 
							) 
							SELECT	ExecutionDateTime , 
									@Action , 
									'Complete' , 
									DBName , 
									@ServerLabel , 
									NETBIOSName , 
									BackupType , 
									@BackupLocType , 
									@BackupDrive , 
									@BackupPath , 
									@FullPath , 
									@FullFileName , 
									FileName , 
									DateLogic , 
									Extension , 
									@FileRetHrs , 
									IsMirror , 
									DATEADD(hh, @FileRetHrs, ExecutionDateTime) , 
									DeleteDateTime , 
									IsDeleted , 
									IsArchive , 
									BackupSizeInMB , 
									BackupName , 
									BackupDescription , 
									ExpirationDate , 
									Compressed , 
									POSITION , 
									DeviceType , 
									UserName , 
									DatabaseName , 
									DatabaseVersion , 
									DatabaseCreationDate , 
									BackupSizeInBytes , 
									FirstLSN , 
									LastLSN , 
									CheckpointLSN , 
									DatabaseBackupLSN , 
									BackupStartDate , 
									BackupFinishDate , 
									SortOrder , 
									CODEPAGE , 
									UnicodeLocaleId , 
									UnicodeComparisonStyle , 
									CompatibilityLevel , 
									SoftwareVendorId , 
									SoftwareVersionMajor , 
									SoftwareVersionMinor , 
									SovtwareVersionBuild , 
									MachineName , 
									Flags , 
									BindingID , 
									RecoveryForkID , 
									COLLATION , 
									FamilyGUID , 
									HasBulkLoggedData , 
									IsSnapshot , 
									IsReadOnly , 
									IsSingleUser , 
									HasBackupChecksums , 
									IsDamaged , 
									BeginsLogChain , 
									HasIncompleteMeatdata , 
									IsForceOffline , 
									IsCopyOnly , 
									FirstRecoveryForkID , 
									ForkPointLSN , 
									RecoveryModel , 
									DifferentialBaseLSN , 
									DifferentialBaseGUID , 
									BackupTypeDescription , 
									BackupSetGUID , 
									CompressedBackupSize , 
									CONTAINMENT 
							FROM	#FilesToCopy 
							WHERE	ID = @currID 
 
----------------------------------------------------------------- 
----------------------------------------------------------------- 
--------------------BEGIN Log Current File Action---------------- 
----------------------------------------------------------------- 
----------------------------------------------------------------- 
				----For ESEUTIL we're only interested in the failure line so we delete the rest and then let it process as usual. 
				IF @FileActionMethod = 'ESEUTIL'  
					BEGIN 
						IF EXISTS (SELECT col1 FROM #ExecResults WHERE col1 LIKE '%FAILURE%') 
							BEGIN 
								DELETE #ExecResults 
								WHERE col1 NOT LIKE '%FAILURE%' 
							END 
					END 
 
				--IF @FileActionErrors LIKE '%ERROR%' 
				IF EXISTS (SELECT col1 FROM #ExecResults WHERE col1 LIKE '%ERROR%' OR col1 LIKE '%FAILURE%') 
					BEGIN 
						SELECT	@FileActionErrors = 'FILE ACTION ERROR: ' 
								+ STUFF(( SELECT	' ' + col1 
										  FROM		#ExecResults AS T1 
										  ORDER BY	T1.ID 
										FOR 
										  XML PATH('') 
										), 1, 1, '') 
						FROM	#ExecResults AS T2; 
					END 
 
WAITFOR DELAY '00:00:05' 
 
					FETCH NEXT FROM Files INTO @currID, @currFilename, 
						@currExtension, @currFileToCopy, @currOrigPath 
				END 
 
			CLOSE Files 
			DEALLOCATE Files 
----END Cursor------- 
 
UPDATE Minion.BackupLogDetails 
	   SET Warnings = ISNULL(Warnings, '') + @FileActionErrors 
WHERE ExecutionDateTime = @ExecutionDateTime 
	  AND DBName = @DBName 
	  AND BackupType = @BackupType; 
--!!!!!!!!!!!!!!!!This is the error code for the file copy call. 
--use it to log any errors... this is also where the copy completion could be logged. 
			SET @i = @i + 1 
 
		END --WHILE 
 
GO
