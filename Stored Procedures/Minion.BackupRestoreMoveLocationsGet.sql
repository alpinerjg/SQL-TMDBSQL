SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [Minion].[BackupRestoreMoveLocationsGet]
(
@ServerName varchar(400),
@DBName NVARCHAR(400),
@RestoreType VARCHAR(50),
@FileList varchar(MAX),
@WithMove varchar(max) OUTPUT 

)

AS

/*

Minion.BackupMoveLocationsGet 'RestoreTestMultiFiles', 'checktable'
Minion.BackupMoveLocationsGet 'BIT', 'checktable'

Purpose: Gets the WITH MOVE locations for MB restores.

Features:
* You can have a drive for each file or put them all onto a single drive.
* You can override just one file location if you need. Just put that filename into the Path table and leave the rest at MinionDefault.
* If you have several DB files, and only 1 override for a specific filename and no MinionDefault row then you'll be in trouble.

BackupLocation - Backup / Primary, Mirror, Copy, or Move. Where you want to get the backup file from.
*/

SET NOCOUNT ON;
DECLARE @PathSettingLevel TINYINT,
		@RestoreSettingLevel	TINYINT,
		@ServerLabel VARCHAR(400),
		@NETBIOSName VARCHAR(128),
		@DBId INT,
		@NumberOfFiles SMALLINT,
		@CmdSQL VARCHAR(max),
		@RestoreDBName NVARCHAR(400),
		@MaintDB varchar(400),
		@Version VARCHAR(50);

SET @MaintDB = DB_NAME();
SET @DBId = DB_ID(@DBName);
------------------------------------------------------------------------
------------------BEGIN ServerLabel--------------------------------------
------------------------------------------------------------------------

SELECT @Version = [Version] FROM Minion.DBMaintSQLInfoGet();


	IF @ServerLabel IS NULL 
		BEGIN
			SET @ServerLabel = @@ServerName;
		END

	SET @NETBIOSName = CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS VARCHAR(128))

------------------------------------------------------------------------
------------------END ServerLabel----------------------------------------
------------------------------------------------------------------------

----0 = MinionDefault, >0 = DB override.
	SET @PathSettingLevel = ( SELECT	COUNT(*)
							  FROM		Minion.BackupRestoreSettingsPath
							  WHERE		ServerName = @ServerName
										AND DBName = @DBName
										AND IsActive = 1
							)


CREATE TABLE #RestoreLocationPath(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DBName] NVARCHAR(400) COLLATE DATABASE_DEFAULT NOT NULL,
	[RestoreType] [varchar](50) COLLATE DATABASE_DEFAULT NULL,
	[FileType] [varchar](10) COLLATE DATABASE_DEFAULT NULL,
	[TypeName] [varchar](400) COLLATE DATABASE_DEFAULT NULL,
	[RestoreDrive] [varchar](100) COLLATE DATABASE_DEFAULT NULL,
	[RestorePath] [varchar](1000) COLLATE DATABASE_DEFAULT NULL,
	[RestoreFileName] [varchar](500) COLLATE DATABASE_DEFAULT NULL,
	[RestoreFileExtension] [varchar](50) COLLATE DATABASE_DEFAULT NULL,
	[ServerLabel] [varchar](150) COLLATE DATABASE_DEFAULT NULL,
	[PathOrder] [int] NULL
)

----------------------------------------------------------------------------
------------------BEGIN Get Full Drive List---------------------------------
----------------------------------------------------------------------------
--This is the full drive list for the DB.  
--It will be trimmed down based on criteria later on.

	IF @PathSettingLevel > 0 
		BEGIN --@PathSettingLevel = 1

			INSERT	#RestoreLocationPath
					( 
						DBName,
						RestoreType,
						FileType,
						TypeName,
						RestoreDrive,
						RestorePath,
						RestoreFileName,
						RestoreFileExtension,
						ServerLabel,
						PathOrder
					)
					SELECT	
					DBName,
						RestoreType,
						FileType,
						TypeName,
						RestoreDrive,
						RestorePath,
						RestoreFileName,
						RestoreFileExtension,
						ISNULL(ServerLabel, @ServerLabel),
						PathOrder					
					FROM	Minion.BackupRestoreSettingsPath
					WHERE	ServerName = @ServerName
							AND DBName = @DBName
							AND IsActive = 1
					ORDER BY PathOrder DESC

		END --@PathSettingLevel = 1

	IF @PathSettingLevel = 0 
		BEGIN --@PathSettingLevel = 0

			INSERT	#RestoreLocationPath
					(
						DBName,
						RestoreType,
						FileType,
						TypeName,
						RestoreDrive,
						RestorePath,
						RestoreFileName,
						RestoreFileExtension,
						ServerLabel,
						PathOrder
					)
					SELECT	
						DBName,
						RestoreType,
						FileType,
						TypeName,
						RestoreDrive,
						RestorePath,
						RestoreFileName,
						RestoreFileExtension,
						ISNULL(ServerLabel, @ServerLabel),
						PathOrder
					FROM	Minion.BackupRestoreSettingsPath
					WHERE	ServerName = @ServerName
							AND DBName = 'MinionDefault'
							AND IsActive = 1
					ORDER BY PathOrder DESC

		END --@PathSettingLevel = 0


----------------BEGIN NULL Switch--------------------

--We want to allow for NULLs in a couple cols to help prevent a NULL stmt being returned.
--If you forget to put a value you should at least get a default value and then you can look into why it's not what you want.
UPDATE #RestoreLocationPath
SET RestorePath = 'MinionDefault' WHERE RestorePath IS NULL;

UPDATE #RestoreLocationPath
SET RestoreFileName = 'MinionDefault' WHERE RestoreFileName IS NULL;

UPDATE #RestoreLocationPath
SET RestoreFileExtension = 'MinionDefault' WHERE RestoreFileExtension IS NULL;
----------------END NULL Switch----------------------

----------------------------------------------------------------------------
------------------END Get Full Drive List-----------------------------------
----------------------------------------------------------------------------

----------------------------------------------------------------------------
------------------BEGIN Delete Unwanted RestoreTypes------------------------
----------------------------------------------------------------------------
----0 = All, >0 = @RestoreType.
	SET @RestoreSettingLevel = ( SELECT	COUNT(*)
							  FROM		#RestoreLocationPath
							  WHERE		RestoreType = @RestoreType										
							)
----If there are rows that match the current @RestoreType, then we'll delete everything else and use those rows.
IF @RestoreSettingLevel > 0
	BEGIN
		DELETE #RestoreLocationPath
		WHERE RestoreType <> @RestoreType;
	END

----If there are NOT rows that match the current @RestoreType, then we only want to keep the ALL rows.
----We still have to do a delete here because you could still have rows that aren't ALL or @RestoreType and we need to get rid of those extra ones.
IF @RestoreSettingLevel = 0
	BEGIN
		DELETE #RestoreLocationPath
		WHERE UPPER(RestoreType) <> 'ALL';
	END
----------------------------------------------------------------------------
------------------END Delete Unwanted RestoreTypes--------------------------
----------------------------------------------------------------------------
--SELECT * FROM #RestoreLocationPath

----------------------------------------------------------------------------
------------------BEGIN Get DB File List------------------------------------
----------------------------------------------------------------------------
----Now that we have the settings we're going to use, we need to get a list of DB files
----if this is a DB override. We could have files in the list that need to go to specific
----locations so we'll get a list of the files here, and then update them below.
----Even if we don't have a DB override here, we'll still need the list of files so we can
----use them in the CREATE DATABASE stmt when we get there.

	CREATE TABLE #LocFilePath
		(
		  ID INT IDENTITY(1,1),
		  LogicalName VARCHAR(255) COLLATE DATABASE_DEFAULT ,
		  PhysicalName VARCHAR(512) COLLATE DATABASE_DEFAULT ,
		  [Type] CHAR(1) ,
		  FileGroupName VARCHAR(128) ,
		  Size NUMERIC(38, 0) ,
		  MaxSize NUMERIC(38, 0) ,
		  FileId BIGINT ,
		  CreateLSN NUMERIC(38, 0) ,
		  DropLSN NUMERIC(38, 0) ,
		  UniqueID UNIQUEIDENTIFIER ,
		  ReadOnlyLSN NUMERIC(38, 0) ,
		  ReadWriteLSN NUMERIC(38, 0) ,
		  BackupSizeInBytes BIGINT ,
		  SourceBlockSize BIGINT ,
		  FileGroupId BIGINT ,
		  LogGroupGUID UNIQUEIDENTIFIER ,
		  DifferentialBaseLSN NUMERIC(38, 0) ,
		  DifferentialBaseGUID UNIQUEIDENTIFIER ,
		  IsReadOnly INT ,
		  IsPresent INT ,
		  TDEThumbprint VARBINARY(32),
		  FilePath VARCHAR(8000) COLLATE DATABASE_DEFAULT,
		  FileName VARCHAR(400) COLLATE DATABASE_DEFAULT,
		  Extension VARCHAR(50) COLLATE DATABASE_DEFAULT
		);

DECLARE @FileListOnlyCMD NVARCHAR(max),
		@FileListOnlyPreCMD varchar(1000),
		@FileListOnlyTotalCMD VARCHAR(8000),
		@Port VARCHAR(10);

----!!!!!!This port needs to be put back in, but it can't rely on checkDB.  We'll have to get it from somewhere else somehow.  Need to think this through.
SET @Port = NULL ----(SELECT TOP 1 Port FROM Minion.CheckDBSettingsDB);


BEGIN --Ports
IF @ServerName NOT LIKE '%\%'
	BEGIN
		SET @Port = CASE WHEN @Port IS NULL AND @ServerName NOT LIKE '%.%' THEN '' --',' + '1433'
						 WHEN @Port IS NULL AND @ServerName LIKE '%.%' THEN '' --',' + '1433'
						 WHEN @Port = '1433' THEN '' --',' + '1433'
						 WHEN @Port IS NOT NULL AND @Port <> '1433' AND @ServerName NOT LIKE '%.%' THEN ',' + @Port
						 WHEN @Port IS NOT NULL AND @ServerName LIKE '%.%' THEN ''
						 END
	END
IF @ServerName LIKE '%\%'
	BEGIN
			SET @Port = CASE WHEN @Port IS NULL THEN ''
							 WHEN @Port IS NOT NULL AND @Port <> '1433' THEN ',' + @Port
							 END
	END
END

		--Getting around INSERT/EXEC syntax.  We delete the temp data as soon as we load it into our #table.
----SELECT @FileList AS filelist			
IF @Version < '13'
	BEGIN		
		SET @FileListOnlyCMD = N'SET NOCOUNT ON; INSERT INTO [' + @MaintDB + '].Minion.BackupRestoreFileListOnlyTemp(LogicalName,PhysicalName,[Type],FileGroupName ,Size,MaxSize,FileId,CreateLSN,DropLSN,UniqueID,ReadOnlyLSN,ReadWriteLSN,BackupSizeInBytes,SourceBlockSize,FileGroupId,LogGroupGUID,DifferentialBaseLSN,DifferentialBaseGUID,IsReadOnly,IsPresent,TDEThumbprint) '
	END		

IF @Version >= '13'
	BEGIN		
		SET @FileListOnlyCMD = N'SET NOCOUNT ON; INSERT INTO [' + @MaintDB + '].Minion.BackupRestoreFileListOnlyTemp(LogicalName,PhysicalName,[Type],FileGroupName ,Size,MaxSize,FileId,CreateLSN,DropLSN,UniqueID,ReadOnlyLSN,ReadWriteLSN,BackupSizeInBytes,SourceBlockSize,FileGroupId,LogGroupGUID,DifferentialBaseLSN,DifferentialBaseGUID,IsReadOnly,IsPresent,TDEThumbprint,SnapshotURL) '
	END	
SET @FileListOnlyCMD = @FileListOnlyCMD + 'EXEC (''''RESTORE FILELISTONLY FROM ' + REPLACE(@FileList, '''', '''''''''') + ''''');UPDATE [' + @MaintDB + '].Minion.BackupRestoreFileListOnlyTemp SET DBName = ''''' + @DBName + ''''' WHERE DBName IS NULL'

		SET @FileListOnlyPreCMD = 'EXEC xp_cmdshell '''
		SET @FileListOnlyPreCMD = @FileListOnlyPreCMD + 'sqlcmd -r 1 -S"' + CAST(SERVERPROPERTY('ServerName') AS VARCHAR(200)) + '"'
			--+ CASE WHEN (@Port IS NOT NULL AND @Port <> '') THEN ','  ELSE '' END
			--	+ ISNULL(CAST(@Port AS VARCHAR(10)), '')
			+ ' -d "master" -Q "' 
		SET @FileListOnlyTotalCMD = @FileListOnlyPreCMD
			+ @FileListOnlyCMD + '"'' , no_output'

		EXEC (@FileListOnlyTotalCMD) --WITH RESULT SETS NONE;

----SELECT @FileListOnlyTotalCMD AS FileListOnlyTotalCMD

		INSERT #LocFilePath
		        (LogicalName, PhysicalName, Type, FileGroupName, Size, MaxSize, FileId,
		         CreateLSN, DropLSN, UniqueID, ReadOnlyLSN, ReadWriteLSN,
		         BackupSizeInBytes, SourceBlockSize, FileGroupId, LogGroupGUID,
		         DifferentialBaseLSN, DifferentialBaseGUID, IsReadOnly, IsPresent,
		         TDEThumbprint, FilePath, FileName, Extension)
		SELECT   LogicalName, PhysicalName, Type, FileGroupName, Size, MaxSize, FileId,
		         CreateLSN, DropLSN, UniqueID, ReadOnlyLSN, ReadWriteLSN,
		         BackupSizeInBytes, SourceBlockSize, FileGroupId, LogGroupGUID,
		         DifferentialBaseLSN, DifferentialBaseGUID, IsReadOnly, IsPresent,
		         TDEThumbprint, FilePath, FileName, Extension
				 FROM Minion.BackupRestoreFileListOnlyTemp
				 WHERE DBName = @DBName;

--SELECT 'HERE', * FROM Minion.BackupRestoreFileListOnlyTemp
		DELETE Minion.BackupRestoreFileListOnlyTemp
				 WHERE DBName = @DBName;

--SELECT 'Here', * FROM #LocFilePath 
----------------------------------------
-------------BEGIN Parse Path-----------
----------------------------------------
----Parse filepath into pieces.
UPDATE #LocFilePath
SET FilePath = LEFT(PhysicalName,LEN(PhysicalName) - charindex('\',reverse(PhysicalName),1) + 1),
	FileName = REVERSE(LEFT(REVERSE(PhysicalName),CHARINDEX('\', REVERSE(PhysicalName), 1) - 1));
	
--Set extension separately so we can check for a '.'
--The path itself can have a '.' in it so we have to get that out of there first.
UPDATE #LocFilePath
SET	Extension = CASE WHEN FileName LIKE '%.%' THEN REVERSE(LEFT(REVERSE(FileName),CHARINDEX('.', REVERSE(FileName), 1) - 1))
ELSE '' END;

--Now set the filename.
UPDATE #LocFilePath
SET FileName = 
CASE WHEN FileName LIKE '%.%' THEN REPLACE(FileName, REVERSE(LEFT(REVERSE(PhysicalName),CHARINDEX('.', REVERSE(PhysicalName), 1) - 1)), '')
ELSE FileName END;

--Now get rid of the '.' that's left over in the filename.
UPDATE #LocFilePath
SET FileName = REPLACE(FileName, '.', '');

----------------------------------------
-------------END Parse Path-------------
----------------------------------------
--SELECT 'here', * FROM #LocFilePath;

----------------------------------------
-------------BEGIN Set New Path---------
----------------------------------------
--Here's where we set the new path based off of the
--table settings.
----SELECT 'Now', * FROM #RestoreLocationPath;
----SELECT 'here', * FROM #LocFilePath;
--Update for All
UPDATE FL
SET 
FL.FilePath = CASE WHEN RP.RestoreDrive <> 'MinionDefault' AND RP.RestorePath <> 'MinionDefault' THEN RP.RestoreDrive + RP.RestorePath ELSE FL.FilePath END,
FL.FileName = CASE WHEN RP.RestoreFileName = 'MinionDefault' THEN FL.FileName ELSE RP.RestoreFileName END,
FL.Extension = CASE WHEN RP.RestoreFileExtension = 'MinionDefault' THEN FL.Extension ELSE RP.RestoreFileExtension END
FROM #LocFilePath FL
INNER JOIN #RestoreLocationPath RP
ON 1=1
WHERE UPPER(RP.FileType) = 'FILETYPE' AND UPPER(RP.TypeName) = 'ALL';
--SELECT 'here', * FROM #LocFilePath;
--Update for MDF
UPDATE FL
SET
FL.FilePath = CASE WHEN RP.RestoreDrive <> 'MinionDefault' AND RP.RestorePath <> 'MinionDefault' THEN RP.RestoreDrive + RP.RestorePath ELSE FL.FilePath END,
FL.FileName = CASE WHEN RP.RestoreFileName = 'MinionDefault' THEN FL.FileName ELSE RP.RestoreFileName END,
FL.Extension = CASE WHEN RP.RestoreFileExtension = 'MinionDefault' THEN FL.Extension ELSE RP.RestoreFileExtension END
FROM #LocFilePath FL
INNER JOIN #RestoreLocationPath RP
ON 1=1
WHERE UPPER(RP.FileType) = 'FILETYPE' AND UPPER(RP.TypeName) = 'MDF'
AND UPPER(FL.Extension) = 'MDF';

--Update for NDF
UPDATE FL
SET
FL.FilePath = CASE WHEN RP.RestoreDrive <> 'MinionDefault' AND RP.RestorePath <> 'MinionDefault' THEN RP.RestoreDrive + RP.RestorePath ELSE FL.FilePath END,
FL.FileName = CASE WHEN RP.RestoreFileName = 'MinionDefault' THEN FL.FileName ELSE RP.RestoreFileName END,
FL.Extension = CASE WHEN RP.RestoreFileExtension = 'MinionDefault' THEN FL.Extension ELSE RP.RestoreFileExtension END
FROM #LocFilePath FL
INNER JOIN #RestoreLocationPath RP
ON 1=1
WHERE UPPER(RP.FileType) = 'FILETYPE' AND UPPER(RP.TypeName) = 'NDF'
AND UPPER(FL.Extension) = 'NDF';

--Update for LDF
UPDATE FL
SET
FL.FilePath = CASE WHEN RP.RestoreDrive <> 'MinionDefault' AND RP.RestorePath <> 'MinionDefault' THEN RP.RestoreDrive + RP.RestorePath ELSE FL.FilePath END,
FL.FileName = CASE WHEN RP.RestoreFileName = 'MinionDefault' THEN FL.FileName ELSE RP.RestoreFileName END,
FL.Extension = CASE WHEN RP.RestoreFileExtension = 'MinionDefault' THEN FL.Extension ELSE RP.RestoreFileExtension END
FROM #LocFilePath FL
INNER JOIN #RestoreLocationPath RP
ON 1=1
WHERE UPPER(RP.FileType) = 'FILETYPE' AND UPPER(RP.TypeName) = 'LDF'
AND UPPER(FL.Extension) = 'LDF';

--Update for FileName
UPDATE FL
SET
FL.FilePath = CASE WHEN RP.RestoreDrive <> 'MinionDefault' AND RP.RestorePath <> 'MinionDefault' THEN RP.RestoreDrive + RP.RestorePath ELSE FL.FilePath END,
FL.FileName = CASE WHEN RP.RestoreFileName = 'MinionDefault' THEN FL.FileName ELSE RP.RestoreFileName END,
FL.Extension = CASE WHEN RP.RestoreFileExtension = 'MinionDefault' THEN FL.Extension ELSE RP.RestoreFileExtension END
FROM #LocFilePath FL
INNER JOIN #RestoreLocationPath RP
ON FL.LogicalName = RP.TypeName
WHERE UPPER(RP.FileType) = 'FILENAME';
----------------------------------------
-------------END Set New Path-----------
----------------------------------------



---------------------------------------------------------------------------------															          
---------------------------------------------------------------------------------
------------------ BEGIN Dynamic Name Parse--------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

DECLARE @currID int,
		@currFilePath nvarchar(1000),
		@currFileName NVARCHAR(500),
		@currFileExtension NVARCHAR(50);

DECLARE DynamicNames CURSOR
READ_ONLY
FOR select ID, FilePath, FileName, Extension from #LocFilePath

OPEN DynamicNames

	FETCH NEXT FROM DynamicNames INTO @currID, @currFilePath, @currFileName, @currFileExtension
	WHILE (@@fetch_status <> -1)
	BEGIN

		--------------------------------------------
		-----------BEGIN FilePath-------------------
		--------------------------------------------
		IF @currFilePath LIKE '%\%%' ESCAPE '\' 
			BEGIN
				EXEC Minion.DBMaintInlineTokenParse @DBName = @DBName, @DynamicName = @currFilePath OUTPUT, @Ordinal = NULL, @NumFiles = NULL, @ServerLabel = @ServerLabel, @BackupType = @RestoreType;
			
				UPDATE #LocFilePath
				SET FilePath = @currFilePath
				WHERE ID = @currID;
			END
		--------------------------------------------
		-----------END FilePath---------------------
		--------------------------------------------
		
		--------------------------------------------
		-----------BEGIN FileName-------------------
		--------------------------------------------
		IF @currFileName LIKE '%\%%' ESCAPE '\' 
			BEGIN
				EXEC Minion.DBMaintInlineTokenParse @DBName = @DBName, @DynamicName = @currFileName OUTPUT, @Ordinal = NULL, @NumFiles = NULL, @ServerLabel = @ServerLabel, @BackupType = @RestoreType;
			
				UPDATE #LocFilePath
				SET FileName = @currFileName
				WHERE ID = @currID;
			END
		--------------------------------------------
		-----------END FileExtension----------------
		--------------------------------------------		

		--------------------------------------------
		-----------BEGIN FileExtension--------------
		--------------------------------------------
		IF @currFileExtension LIKE '%\%%' ESCAPE '\' 
			BEGIN
				EXEC Minion.DBMaintInlineTokenParse @DBName = @DBName, @DynamicName = @currFileExtension OUTPUT, @Ordinal = NULL, @NumFiles = NULL, @ServerLabel = @ServerLabel, @BackupType = @RestoreType;
			
				UPDATE #LocFilePath
				SET Extension = @currFileExtension
				WHERE ID = @currID;
			END
		--------------------------------------------
		-----------END FileName---------------------
		--------------------------------------------
				
	FETCH NEXT FROM DynamicNames INTO @currID, @currFilePath, @currFileName, @currFileExtension
	END

CLOSE DynamicNames
DEALLOCATE DynamicNames

---------------------------------------------------------------------------------															          
---------------------------------------------------------------------------------
------------------ END Dynamic Name Parse----------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

----DECLARE @WithMove VARCHAR(MAX);
----If there isn't an extension then we don't want to include the '.' so the CASE handles that.
		SET @WithMove = ' ';
		SELECT	@WithMove = @WithMove + 'Move ''' + LogicalName + ''' TO '''
				+ (FilePath + FileName + CASE WHEN Extension <> '' THEN '.' + Extension WHEN Extension = '' THEN Extension END) + ''', '
		FROM	#LocFilePath
		ORDER BY FileId;

	IF ( SUBSTRING(@WithMove, LEN(RTRIM(@WithMove)), 1) = ',' ) 
		BEGIN  
			SET @WithMove = LEFT(@WithMove, LEN(@WithMove) - 1)
		END

--SELECT * FROM #LocFilePath;
GO
