SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [Minion].[CheckDBSnapshotGet]
(
@DBName NVARCHAR(400),
@OpName VARCHAR(50)
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
                
                EXEC Minion.HELP 'CHECKDB', 'Minion.CheckDBSnapshotGet';


PURPOSE: 
Creates the snapshot stmt to create manual snapshots for checkdb or checktable. Most versions of sql only allow this for Ent version. Need to test if that's still true for all.
	Features:
	* You can have a drive for each file or put them all onto a single drive.
	* You can override just one file location if you need. Just put that filename into the Path table and leave the rest at MinionDefault.
	* If you have several DB files, and only 1 override for a specific filename and no MinionDefault row then you'll be in trouble.


WALKTHROUGH: 
      1. 


CONVENTIONS:
    
    
TABLES: 
                

EXAMPLE EXECUTIONS:
Minion.CheckDBSnapshotGet 'SnapShotTestMultiFiles', 'checkdb'
Minion.CheckDBSnapshotGet 'SnapShotTestMultiFiles', 'checktable'
Minion.CheckDBSnapshotGet 'BIT', 'checktable'

REVISION HISTORY:
                

--***********************************************************************************/ 

SET NOCOUNT ON;

DECLARE @PathSettingLevel TINYINT,
		@OpSettingLevel	TINYINT,
		@ServerLabel VARCHAR(400),
		@NETBIOSName VARCHAR(128),
		@DBId INT,
		@NumberOfFiles SMALLINT,
		@CmdSQL VARCHAR(max),
		@SnapshotDBName NVARCHAR(400);

SET @DBId = DB_ID(@DBName);
------------------------------------------------------------------------
------------------BEGIN ServerLabel--------------------------------------
------------------------------------------------------------------------

	IF @ServerLabel IS NULL 
		BEGIN
			SET @ServerLabel = @@ServerName;
		END

	SET @NETBIOSName = CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS VARCHAR(128));

------------------------------------------------------------------------
------------------END ServerLabel----------------------------------------
------------------------------------------------------------------------

----0 = MinionDefault, >0 = DB override.
	SET @PathSettingLevel = ( SELECT	COUNT(*)
							  FROM		Minion.CheckDBSnapshotPath
							  WHERE		DBName = @DBName
										AND IsActive = 1
							);

----SELECT @PathSettingLevel AS PathSettingLevel

CREATE TABLE #SnapshotGetCheckDBSnapshotPath(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DBName] NVARCHAR(400) COLLATE DATABASE_DEFAULT NOT NULL,
	[OpName] [varchar](50) COLLATE DATABASE_DEFAULT NULL,
	[FileName] [varchar](400) COLLATE DATABASE_DEFAULT NULL,
	[SnapshotDrive] [varchar](100) COLLATE DATABASE_DEFAULT NULL,
	[SnapshotPath] [varchar](1000) COLLATE DATABASE_DEFAULT NULL,
	[ServerLabel] [varchar](150) COLLATE DATABASE_DEFAULT NULL,
	[PathOrder] [int] NULL
);

----------------------------------------------------------------------------
------------------BEGIN Get Full Drive List---------------------------------
----------------------------------------------------------------------------
--This is the full drive list for the DB.  
--It will be trimmed down based on criteria later on.

	IF @PathSettingLevel > 0 
		BEGIN --@PathSettingLevel = 1

			INSERT	#SnapshotGetCheckDBSnapshotPath
					( 
						DBName,
						OpName,
						FileName,
						SnapshotDrive,
						SnapshotPath,
						ServerLabel,
						PathOrder
					)
					SELECT	
						DBName,
						OpName,
						FileName,
						SnapshotDrive,
						SnapshotPath,
						ISNULL(ServerLabel, @ServerLabel),
						PathOrder					
					FROM	Minion.CheckDBSnapshotPath
					WHERE	DBName = @DBName
							AND IsActive = 1
					ORDER BY PathOrder DESC;

		END --@PathSettingLevel = 1

	IF @PathSettingLevel = 0 
		BEGIN --@PathSettingLevel = 0

			INSERT	#SnapshotGetCheckDBSnapshotPath
					(
						DBName,
						OpName,
						FileName,
						SnapshotDrive,
						SnapshotPath,
						ServerLabel,
						PathOrder
					)
					SELECT	
						DBName,
						OpName,
						FileName,
						SnapshotDrive,
						SnapshotPath,
						ISNULL(ServerLabel, @ServerLabel),
						PathOrder
					FROM	Minion.CheckDBSnapshotPath
					WHERE	DBName = 'MinionDefault'
							AND IsActive = 1
					ORDER BY PathOrder DESC;

		END --@PathSettingLevel = 0

----------------------------------------------------------------------------
------------------END Get Full Drive List-----------------------------------
----------------------------------------------------------------------------

----------------------------------------------------------------------------
------------------BEGIN Delete Unwanted Ops---------------------------------
----------------------------------------------------------------------------
----0 = All, >0 = @OpName.
	SET @OpSettingLevel = ( SELECT	COUNT(*)
							  FROM		#SnapshotGetCheckDBSnapshotPath
							  WHERE		OpName = @OpName										
							)
----If there are rows that match the current @OpName, then we'll delete everything else and use those rows.
IF @OpSettingLevel > 0
	BEGIN
		DELETE #SnapshotGetCheckDBSnapshotPath
		WHERE OpName <> @OpName;
	END

----If there are NOT rows that match the current @OpName, then we only want to keep the ALL rows.
----We still have to do a delete here because you could still have rows that aren't ALL or @OpName and we need to get rid of those extra ones.
IF @OpSettingLevel = 0
	BEGIN
		DELETE #SnapshotGetCheckDBSnapshotPath
		WHERE UPPER(OpName) <> 'ALL';
	END
----------------------------------------------------------------------------
------------------END Delete Unwanted Ops-----------------------------------
----------------------------------------------------------------------------

----------------------------------------------------------------------------
------------------BEGIN Get DB File List------------------------------------
----------------------------------------------------------------------------
----Now that we have the settings we're going to use, we need to get a list of DB files
----if this is a DB override. We could have files in the list that need to go to specific
----locations so we'll get a list of the files here, and then update them below.
----Even if we don't have a DB override here, we'll still need the list of files so we can
----use them in the CREATE DATABASE stmt when we get there.

CREATE TABLE #SnapshotGetDBFileList
(
ID INT IDENTITY(1,1),
FileID INT,
TypeDesc VARCHAR(25) COLLATE DATABASE_DEFAULT,
Name VARCHAR(200) COLLATE DATABASE_DEFAULT,
PhysicalName VARCHAR(8000) COLLATE DATABASE_DEFAULT NULL,
IsReadOnly BIT NULL,
IsSparse BIT NULL,
SnapshotDrive varchar(100) COLLATE DATABASE_DEFAULT NULL,
SnapshotPath varchar(1000) COLLATE DATABASE_DEFAULT NULL,
FullPath VARCHAR(2000) COLLATE DATABASE_DEFAULT NULL, 
ServerLabel varchar(150) COLLATE DATABASE_DEFAULT NULL,
PathOrder int NULL,
Cmd VARCHAR(max) COLLATE DATABASE_DEFAULT NULL,
SizeInKB BIGINT NULL,
MaxSizeInKB BIGINT NULL,
)

INSERT #SnapshotGetDBFileList
        (FileID, TypeDesc, Name, PhysicalName, IsReadOnly, IsSparse, SnapshotDrive, SnapshotPath, ServerLabel, PathOrder, SizeInKB, MaxSizeInKB)
SELECT file_id, type_desc, name, NULL, is_read_only, is_sparse, NULL, NULL, NULL, 0, NULL, (size*8)
FROM sys.master_files
WHERE database_id = @DBId;
--AND UPPER(type_desc) <> 'LOG';

----This just sets the file locations if there are named files in the Path table.  So if there have been specific locations defined for specific files
----they'll get updated here.  The rest will still be NULL.  Since we can have a rotation system for the paths and they must be done in order then we can't
----just update them all to the same drive.  They'll need to be put into a loop to get them going to the proper path.  We'll do that next.
BEGIN
	UPDATE FL
	SET FL.SnapShotDrive = SP.SnapshotDrive,
		FL.SnapshotPath = SP.SnapshotPath,
		FL.ServerLabel = SP.ServerLabel
	FROM #SnapshotGetDBFileList FL
	INNER JOIN #SnapshotGetCheckDBSnapshotPath SP
	ON FL.Name = SP.FileName;
END

----SELECT 'here', * FROM #SnapshotGetDBFileList
----------------------------------------------------------------------------
------------------END Get DB File List--------------------------------------
----------------------------------------------------------------------------


----------------------------------------------------------------------------
------------------BEGIN Dynamic File List-----------------------------------
----------------------------------------------------------------------------

----We're going to move these files to a work table because we need the IDs to be reset to 1.
----Sure, we could have re-seeded the IDs, but this is less effort and most of the time there won't be enough files in a 
----DB for this to be a burden on the system.
SELECT ID = IDENTITY(INT,1,1), DBName, OpName, FileName, SnapshotDrive, SnapshotPath, ServerLabel, PathOrder
INTO #SnapshotGetPathWork
FROM #SnapshotGetCheckDBSnapshotPath
WHERE FileName = 'MinionDefault'
ORDER BY PathOrder DESC;

DECLARE @i INT,
		@curSnapshotDrive VARCHAR(100),
		@curSnapshotPath VARCHAR(1000),
		@curServerLabel VARCHAR(200),
		@curID INT,--RowID that comes from #SnapshotGetCheckDBSnapshotPath so we can find the row we chose.
		@curFileID INT,--RowID of the current top file in #SnapshotGetDBFileList. This is the row we're currently trying to update.
		@FileCounter INT,--We need to know how many files we've gone through so we'll know when to start back over with the drives when we run out of them.
		@MaxDrives INT;--We need to know how many drives we have to play with here.

----Start by getting the # of files we need to assign the drives to.
SET @NumberOfFiles = (SELECT COUNT(*) FROM #SnapshotGetDBFileList WHERE SnapshotPath IS NULL);
	SELECT	@MaxDrives = ( SELECT COUNT(*) FROM #SnapshotGetPathWork);

SET @i = 1;
SET @FileCounter = 1;


WHILE @i <= @NumberOfFiles
	BEGIN
		SELECT 
			   @curSnapshotDrive = SnapshotDrive,
			   @curSnapshotPath = SnapshotPath,
			   @curServerLabel = ServerLabel,
			   @curID = ID
		FROM #SnapshotGetPathWork
		WHERE ID = @FileCounter;


----We need to get the current top file that doesn't have a SnapshotDrive value.  This will be used in the UPDATE below.
		SET @curFileID = (SELECT TOP 1 ID FROM #SnapshotGetDBFileList WHERE SnapshotDrive IS NULL);

UPDATE #SnapshotGetDBFileList
		SET 
			SnapshotDrive = @curSnapshotDrive,
			SnapshotPath = @curSnapshotPath,
			ServerLabel = ISNULL(@curServerLabel, @ServerLabel)
		WHERE ID = @curFileID;

----Now we have to delete the top row so we have a new top row for the next iteration of the loop.  That means we're going to slowly destroy the rows
----in #SnapshotGetCheckDBSnapshotPath so they won't be available after this.
		--DELETE TOP (1)
		--FROM #SnapshotGetCheckDBSnapshotPath 
		--WHERE ID = @curID

		IF ( @NumberOfFiles >= 1
				AND @i <= ( @NumberOfFiles )
			) 
			SET @i = @i + 1;
			SET @FileCounter = @FileCounter + 1
			IF @FileCounter > @MaxDrives 
				SET @FileCounter = 1;
	END
----------------------------------------------------------------------------
------------------END Dynamic File List-------------------------------------
----------------------------------------------------------------------------


----------------------------------------------------------------------------
------------------BEGIN Set PhysicalName------------------------------------
----------------------------------------------------------------------------
----Now we need to set the full physical path name.
----We didn't do it above because we were only dealing with dynamic drive assignments and now we've got all of them so we shouldn't have any problem 
----setting PhysicalName for all of them.
--If we wanted to have some custom filenames this is where it should be done... once everything else is finished.
--Maybe we'll add built-in ways to customize it later.

DECLARE @FileNameSuffix VARCHAR(50),
		@FullPath VARCHAR(2000);

SET @FileNameSuffix = CAST( DATEPART(MINUTE, GETDATE()) AS varchar(25)) + CAST( DATEPART(SECOND, GETDATE()) AS varchar(25)) + CAST( DATEPART(MILLISECOND, GETDATE()) AS varchar(25));
SET @FullPath = @curSnapshotDrive + @curSnapshotPath;


--UPDATE #SnapshotGetDBFileList
--		SET PhysicalName = @FullPath + Name + @FileNameSuffix + '.ss',
--			FullPath = @FullPath
UPDATE #SnapshotGetDBFileList
		SET PhysicalName = SnapshotDrive + SnapshotPath + Name + @FileNameSuffix + '.ss',
			FullPath = SnapshotDrive + SnapshotPath;
----------------------------------------------------------------------------
------------------END Set PhysicalName--------------------------------------
----------------------------------------------------------------------------


----------------------------------------------------------------------------
------------------BEGIN Build Create Database-------------------------------
----------------------------------------------------------------------------

CREATE TABLE #SnapshotGetDBFileListTEMP(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[FileID] [int] NULL,
	[TypeDesc] [varchar](25) NULL,
	[Name] [varchar](200) NULL,
	[PhysicalName] [varchar](8000) NULL,
	[SizeInKB] [bigint] NULL,
	[IsReadOnly] [bit] NULL,
	[IsSparse] [bit] NULL,
	[SnapshotDrive] [varchar](100) NULL,
	[SnapshotPath] [varchar](1000) NULL,
	[FullPath] [varchar](2000) NULL,
	[ServerLabel] [varchar](150) NULL,
	[PathOrder] [int] NULL,
	[Cmd] [varchar](max) NULL,
	[MaxSizeInKB] [bigint] NULL,
);

----We need this w/o the LOG files so we can get an accurate count for the loop below.
----Log files can't be specified in the CREATE stmt for a snapshot DB so that's why we can't have it in here.
INSERT #SnapshotGetDBFileListTEMP(FileID, TypeDesc, Name, PhysicalName, IsReadOnly, IsSparse, SnapshotDrive, SnapshotPath, FullPath, ServerLabel, PathOrder, Cmd, SizeInKB, MaxSizeInKB)
SELECT FileID, TypeDesc, Name, PhysicalName, IsReadOnly, IsSparse, SnapshotDrive, SnapshotPath, FullPath, ServerLabel, PathOrder, Cmd, SizeInKB, MaxSizeInKB
FROM #SnapshotGetDBFileList
WHERE UPPER(TypeDesc) NOT IN ('LOG', 'FILESTREAM');

SET @SnapshotDBName = @DBName + @FileNameSuffix;

SET @CmdSQL = 'CREATE DATABASE [' + @SnapshotDBName + '] ON ';


SET @NumberOfFiles = (SELECT COUNT(*) FROM #SnapshotGetDBFileListTEMP);
SET @i = 1;

WHILE @i < = @NumberOfFiles
	BEGIN
		SELECT @CmdSQL = @CmdSQL
			+ '(NAME = [' + Name + '], '
			+ 'FILENAME = ' + '''' + PhysicalName + '''' + '), '
			FROM #SnapshotGetDBFileListTEMP
			WHERE ID = @i;

		SET @i = @i + 1;
	END

----Take off the trailing comma.
	IF ( SUBSTRING(@CmdSQL, LEN(RTRIM(@CmdSQL)), 2) = ', ' ) 
		BEGIN  
			SET @CmdSQL = LEFT(@CmdSQL, LEN(@CmdSQL) - 2);
		END

SET @CmdSQL = @CmdSQL + ') AS SNAPSHOT OF [' + @DBName + '];';

----------------------------------------------------------------------------
------------------END Build Create Database---------------------------------
----------------------------------------------------------------------------

----------------------------------------------------------------------------
------------------BEGIN Update Stmt in Table--------------------------------
----------------------------------------------------------------------------

UPDATE #SnapshotGetDBFileList
	SET Cmd = @CmdSQL;

----------------------------------------------------------------------------
------------------END Update Stmt in Table----------------------------------
----------------------------------------------------------------------------

----We want the log files in this list so we can log them in the table.
----This allows us to get a full view of the DB size before it's deleted.
SELECT @SnapshotDBName AS SnapshotDBName, FileID, TypeDesc, Name, PhysicalName, IsReadOnly, IsSparse,
         SnapshotDrive, SnapshotPath, FullPath, ServerLabel, PathOrder, Cmd, SizeInKB, MaxSizeInKB
FROM #SnapshotGetDBFileList;


GO
