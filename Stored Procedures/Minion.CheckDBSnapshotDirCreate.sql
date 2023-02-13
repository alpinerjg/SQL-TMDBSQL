SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [Minion].[CheckDBSnapshotDirCreate]
(
@ExecutionDateTime DATETIME,
@DBName NVARCHAR(400),
@Op varchar(50)
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
                
                EXEC Minion.HELP 'CHECKDB', 'Minion.CheckDBSnapshotDirCreate';


PURPOSE: 


WALKTHROUGH: 
      1. 


CONVENTIONS:
    
    
TABLES: 
                

EXAMPLE EXECUTIONS:


REVISION HISTORY:
                

--***********************************************************************************/ 


DECLARE
@i TINYINT,
@CT TINYINT,
@FileErrors VARCHAR(MAX),
@FullPath VARCHAR(8000),
@FileExistCMD VARCHAR(8000);
SET @i = 1;
SET @CT = (SELECT COUNT(*) FROM Minion.CheckDBSnapshotLog WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName AND UPPER(OpName) = UPPER(@Op));
SET @FileErrors = '';


	CREATE TABLE #CheckDBSnapshotDirCreate(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SnapshotDBName] NVARCHAR(400) COLLATE DATABASE_DEFAULT NULL,
	[FileID] [int] NULL,
	[TypeDesc] [varchar](25) COLLATE DATABASE_DEFAULT NULL,
	[Name] [varchar](200) COLLATE DATABASE_DEFAULT NULL,
	[PhysicalName] [varchar](8000) COLLATE DATABASE_DEFAULT NULL,
	[IsReadOnly] [bit] NULL,
	[IsSparse] [bit] NULL,
	[SnapshotDrive] [varchar](100) COLLATE DATABASE_DEFAULT NULL,
	[SnapshotPath] [varchar](1000) COLLATE DATABASE_DEFAULT NULL,
	[FullPath] [varchar](8000) COLLATE DATABASE_DEFAULT NULL,
	[ServerLabel] [varchar](150) COLLATE DATABASE_DEFAULT NULL,
	[PathOrder] [int] NULL,
	[Cmd] [varchar](max) COLLATE DATABASE_DEFAULT NULL,
	[SizeInKB] [bigint] NULL,
	[MaxSizeInKB] [bigint] NULL
)

INSERT #CheckDBSnapshotDirCreate
        (SnapshotDBName, FileID, TypeDesc, Name, PhysicalName,
         IsReadOnly, IsSparse, SnapshotDrive, SnapshotPath, FullPath,
         ServerLabel, PathOrder, Cmd, SizeInKB, MaxSizeInKB)
SELECT SnapshotDBName, FileID, TypeDesc, Name, PhysicalName, IsReadOnly, IsSparse,
			 SnapshotDrive, SnapshotPath, FullPath, ServerLabel, PathOrder, Cmd, SizeInKB, MaxSizeInKB
FROM 
Minion.CheckDBSnapshotLog 
WHERE ExecutionDateTime = @ExecutionDateTime 
AND DBName = @DBName
AND UPPER(OpName) = UPPER(@Op)
ORDER BY PathOrder DESC
	--------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------
	------------------------BEGIN Create Directories--------------------------------------
	--------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------

						CREATE TABLE #DirExist
							(
							 DirExist VARCHAR(2000) COLLATE DATABASE_DEFAULT
							) 

 		--	---BEGIN Log Create Directories------
			--			BEGIN
			--				UPDATE Minion.CheckDBLogDetails
			--					SET
			--						STATUS = 'Creating Snapshot Directories'
			--					WHERE
			--						ID = @CheckDBLogDetailsID;
			--			END
			------END Log Create Directories-------

	----------------------------------------------------
	------------BEGIN Create Paths----------------------
	----------------------------------------------------

						WHILE @i <= @CT
							BEGIN --FileCreate

                            SET @FullPath = (SELECT FullPath FROM #CheckDBSnapshotDirCreate WHERE ID = @i); 
--SELECT @FullPath AS FullPath							 
	 -- -- Set folder path 
	  
                            SET @FileExistCMD = ''; 
                            SET @FileExistCMD = ' powershell "If ((test-path '''
                                + @FullPath + ''') -eq $False){MD ' + ''''
                                + @FullPath
                                + ''' -errorvariable err -erroraction silentlycontinue} If ($err.count -gt 0){$Final = $err} ELSE{$Final = ''Dir Exists''}; $Final" '
--PRINT @FileExistCMD
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

DROP TABLE #DirExist;
				--PRINT @FileErrors

	------------------------BEGIN Log File Create Errors--------------------
						--IF @FileErrors <> ''
						--	BEGIN
						--		UPDATE Minion.CheckDBLogDetails
						--			SET
						--				STATUS = 'FATAL ERROR: We were not able to create the folder in the path specified.  Make sure your settings in the Minion.BackupSnapshotPath table are correct and that you have permission to create folders on this drive. ACTUAL ERROR FOLLOWS: '
						--				+ @FileErrors
						--			WHERE
						--				ID = @CheckDBLogDetailsID;

						--		RETURN
						--	END
	------------------------END Log File Create Errors----------------------

	----------------------------------------------------
	------------END Create Paths------------------------
	----------------------------------------------------




GO
