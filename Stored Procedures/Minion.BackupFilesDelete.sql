SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[BackupFilesDelete]
	(
	  @DBName NVARCHAR(400) ,
	  @RetHrs INT = NULL , --Pass in specific hrs to do a custom delete.
	  @Delete BIT = 1 , -- 1: delete files. 0: report files that will be deleted.
	  @EvalDateTime DATETIME = NULL
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

Purpose: This SP deletes backup files whose retention periods have expired.
		
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

	@DBName	- Database name for which we delete files. 'All' is a valid input.

	@RetHrs - Pass in specific hours to do a custom delete.
	
	@Delete - 1: delete files. 0: report files that will be deleted.
	
	@EvalDateTime - []

Tables:
-----------
	
	#FilesToDelete		Holds the data on files to delete, retrieved from Minion.BackupFiles.
	
	#DeleteResults		Holds the results of the Powershell delete command.


Example Execution:
	-- 

Revision History:


***********************************************************************************/
AS 
	SET NOCOUNT ON;

	CREATE TABLE #FilesToDelete
		(
		  ID BIGINT ,
		  ExecutionDateTime DATETIME ,
		  DBName NVARCHAR(400) ,
		  Op VARCHAR(20) ,
		  FullPath VARCHAR(4000) COLLATE DATABASE_DEFAULT ,
		  FullFileName VARCHAR(1000) COLLATE DATABASE_DEFAULT ,
		  BackupType VARCHAR(20) COLLATE DATABASE_DEFAULT ,
		  BackupLocType VARCHAR(20) COLLATE DATABASE_DEFAULT ,
		  IsMirror BIT ,
		  BackupSizeInMB NUMERIC(15, 3)
		)

	CREATE TABLE #DeleteResults
		(
		  col1 VARCHAR(MAX) COLLATE DATABASE_DEFAULT
		)


	DECLARE	@currFile VARCHAR(4000) ,
			@DeleteSQL VARCHAR(8000) ,
			@currFileExist BIT ,
			@currError VARCHAR(MAX) ,
			@currBackupType VARCHAR(20) ,
			@currBackupLocType VARCHAR(20) ,
			@currOp VARCHAR(20) ,
			@currIsDeleted VARCHAR(10) ,
			@currExecutionDateTime VARCHAR(40) ,
			@DeleteDateTime DATETIME ,
			@currDeleteDateTime VARCHAR(30) ,
			@currID BIGINT ,
			@Status VARCHAR(MAX) ,
			@IsDeleted BIT;

	SET @DeleteDateTime = GETDATE();

	IF @EvalDateTime IS NULL 
		BEGIN
			SET @EvalDateTime = GETDATE();
		END


----Put in a time so you can delete files as of a certain time of day...
----So say it's noon and you want to know if files will be deleted at 11p...
----Here's where you'd pass in the date you want to eval as of.

--------------------------------------------------------------------------------------------------------------------------
----------------------------------------------BEGIN Choose Files----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
----Single DB
	IF @DBName <> 'All' 
		BEGIN --<> 'All'
			IF @RetHrs IS NULL 
				BEGIN --@RetHrs IS NULL
					BEGIN
						INSERT	#FilesToDelete
								SELECT	ID ,
										ExecutionDateTime ,
										DBName ,
										Op ,
										FullPath ,
										FullFileName ,
										BackupType ,
										BackupLocType ,
										IsMirror ,
										BackupSizeInMB
								FROM	Minion.BackupFiles
								WHERE	DATEDIFF(hh, ExecutionDateTime, @EvalDateTime) >= RetHrs
										AND (IsDeleted = 0 OR IsDeleted IS NULL)
										AND IsArchive = 0
										AND FullFileName IS NOT NULL
										AND DBName = @DBName		
					END
				END --@RetHrs IS NULL

			IF @RetHrs IS NOT NULL 
				BEGIN --@RetHrs IS NOT NULL
					BEGIN
						INSERT	#FilesToDelete
								SELECT	ID ,
										ExecutionDateTime ,
										DBName ,
										Op ,
										FullPath ,
										FullFileName ,
										BackupType ,
										BackupLocType ,
										IsMirror ,
										BackupSizeInMB
								FROM	Minion.BackupFiles
								WHERE	DATEDIFF(hh, ExecutionDateTime, @EvalDateTime) >= @RetHrs
										AND (IsDeleted = 0 OR IsDeleted IS NULL)
										AND IsArchive = 0
										AND FullFileName IS NOT NULL
										AND DBName = @DBName		
					END
				END --@RetHrs IS NOT NULL
		END --<> 'All'

--All DBs
	IF @DBName = 'All' 
		BEGIN --@DBName = 'All'
			IF @RetHrs IS NULL 
				BEGIN --@RetHrs IS NULL
					BEGIN
						INSERT	#FilesToDelete
								SELECT	ID ,
										ExecutionDateTime ,
										DBName ,
										Op ,
										FullPath ,
										FullFileName ,
										BackupType ,
										BackupLocType ,
										IsMirror ,
										BackupSizeInMB
								FROM	Minion.BackupFiles
								WHERE	DATEDIFF(hh, ExecutionDateTime, @EvalDateTime) >= RetHrs
										AND (IsDeleted = 0 OR IsDeleted IS NULL)
										AND IsArchive = 0
										AND FullFileName IS NOT NULL		
					END
				END --@RetHrs IS NULL

			IF @RetHrs IS NOT NULL 
				BEGIN --@RetHrs IS NOT NULL
					BEGIN
						INSERT	#FilesToDelete
								SELECT	ID ,
										ExecutionDateTime ,
										DBName ,
										Op ,
										FullPath,
										FullFileName ,
										BackupType ,
										BackupLocType ,
										IsMirror ,
										BackupSizeInMB
								FROM	Minion.BackupFiles
								WHERE	DATEDIFF(hh, ExecutionDateTime, @EvalDateTime) >= @RetHrs
										AND (IsDeleted = 0 OR IsDeleted IS NULL)
										AND IsArchive = 0
										AND FullFileName IS NOT NULL		
					END
				END --@RetHrs IS NOT NULL
		END --@DBName = 'All'

--------------------------------------------------------------------------------------------------------------------------
----------------------------------------------END Choose Files------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------

	IF @Delete = 1 
		BEGIN --@Delete = 1

			DECLARE Files CURSOR READ_ONLY
			FOR
				SELECT	ID ,
						ExecutionDateTime ,
						Op ,
						FullFileName ,
						BackupType ,
						BackupLocType
				FROM	#FilesToDelete

			OPEN Files

			FETCH NEXT FROM Files INTO @currID, @currExecutionDateTime, @currOp, @currFile, @currBackupType, @currBackupLocType
			WHILE ( @@fetch_status <> -1 ) 
				BEGIN --Files

					IF @currBackupLocType <> 'NUL'
					BEGIN --@currBackupLocType <> 'NUL'
						SET @DeleteSQL = ' powershell "[int]$FileExist = (test-path '''
							+ @currFile + '''); '
							+ 'If ($FileExist = 1) {Remove-Item ''' + @currFile
							+ ''' -ErrorAction ''SilentlyContinue'' -ErrorVariable err}; If ($err.count -eq 0) { [string]$FilesDeleted = ''Complete'' }; If($err.count -gt 0){[string]$FilesDeleted = $err}; $Total = [string]$FileExist, $FilesDeleted; $Total"'
PRINT @DeleteSQL
						INSERT	#DeleteResults
						EXEC master..xp_cmdshell @DeleteSQL;
					END --@currBackupLocType <> 'NUL'

----Get rid of NULL values; they're useless.
					DELETE	FROM #DeleteResults
					WHERE	col1 IS NULL

-----------------BEGIN Insert into #DeleteResults-----------------
					SET @currFileExist = (SELECT TOP (1) col1 FROM	#DeleteResults)
					DELETE TOP (1)
					FROM	#DeleteResults

					SET @currError = (SELECT TOP (1) col1 FROM #DeleteResults)
					DELETE TOP (1)
					FROM #DeleteResults	

---Get anything left in #DeleteResults.  This has to be empty for the next file.
					TRUNCATE TABLE #DeleteResults;
-----------------END Insert into #DeleteResults--------------------

----If it's a NUL file you have to set the Error to Complete so the file will show deleted in the BackupFile table.
					IF @currBackupLocType = 'NUL'
						BEGIN
							SET @currError = 'Complete'
						END

--------------------------------------------------
-------------BEGIN Write to Log-------------------
--------------------------------------------------

					UPDATE	Minion.BackupFiles
					SET		Status = CASE WHEN @currError LIKE 'Complete%' THEN 'Complete'
										  WHEN @currError LIKE '%Cannot find path%' THEN 'Complete: Deleted out-of-process. SPECIFIC ERROR:' + @currError
										  WHEN @currError NOT LIKE 'Complete%' THEN 'FATAL ERROR: ' + @currError
									 END ,
							IsDeleted = CASE WHEN ( @currError LIKE 'Complete%' ) THEN 1
											 WHEN ( @currError LIKE '%Cannot find path%' ) THEN 1
											 WHEN @currError NOT LIKE 'Complete%' THEN 0
											 WHEN @currFileExist = 0 THEN 1
										END ,
							DeleteDateTime = @DeleteDateTime
					WHERE	ID = @currID;

					SET @currDeleteDateTime = @DeleteDateTime;
--------------------------------------------
--------BEGIN Write to SyncServer-----------
--------------------------------------------
IF (SELECT Value 
	FROM Minion.Work 
	WHERE ExecutionDateTime = @EvalDateTime AND Module = 'Backup' AND DBName = 'MinionBatch' AND SPName = 'BackupMaster' AND Param = '@SyncLogs') = 1
	BEGIN
					SELECT	@currExecutionDateTime = CASE WHEN @currExecutionDateTime IS NOT NULL
														  THEN ''''
															  + CONVERT(VARCHAR(40), @currExecutionDateTime, 21)
															  + ''''
														  ELSE 'NULL'
													 END ,
							@Status = 'Status' ,--'''' + ISNULL(REPLACE(@Status, '''', ''''''), 'NULL') + '''',
							@currIsDeleted = CASE WHEN @IsDeleted IS NOT NULL
												  THEN CAST(@IsDeleted AS VARCHAR(10))
												  ELSE 'NULL'
											 END ,
							@currDeleteDateTime = CASE WHEN @DeleteDateTime IS NOT NULL
													   THEN ''''
															+ CONVERT(VARCHAR(30), @DeleteDateTime, 21)
															+ ''''
													   ELSE 'NULL'
												  END ,
							@currFile = '''' + REPLACE(@currFile, '''', '''''')
							+ '''' ,
							@currOp = '''' + REPLACE(@currOp, '''', '''''')
							+ '''' ,
							@currBackupType = CASE WHEN @currBackupType IS NOT NULL
												   THEN '''' + @currBackupType
														+ ''''
												   ELSE 'NULL'
											  END

					INSERT	Minion.SyncCmds
							( ExecutionDateTime ,
							  Module ,
							  Status ,
							  ObjectName ,
							  Op ,
							  Cmd ,
							  Pushed ,
							  Attempts
							)
							SELECT	REPLACE(@currExecutionDateTime, '''', '') ,
									'Backup' ,
									'In queue' ,
									'BackupFiles' ,
									'UPDATE' ,
									( 'UPDATE Minion.BackupFiles SET STATUS = '
									  + @Status + ', IsDeleted = '
									  + @currIsDeleted + ', DeleteDateTime = '
									  + @currDeleteDateTime
									  + ' WHERE FullFileName = ' + @currFile
									  + ' AND BackupType = ' + @currBackupType
									  + ' AND Op = ' + @currOp ) ,
									0 ,
									0;
	END
--------------------------------------------
--------END Write to SyncServer-------------
--------------------------------------------


--------------------------------------------------
-------------END Write to Log---------------------
--------------------------------------------------

					FETCH NEXT FROM Files INTO @currID, @currExecutionDateTime, @currOp, @currFile, @currBackupType, @currBackupLocType

				END --Files

			CLOSE Files
			DEALLOCATE Files

		END --@Delete = 1
--------------------------------------------------------------------------------------------------------------------------
----------------------------------------------END Delete Files------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------
----------------------------------------------BEGIN Delete Folders--------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------

--SELECT DISTINCT FullPath
--	FROM	#FilesToDelete

----DECLARE @currFullPath VARCHAR(1000);
----DECLARE Folders CURSOR READ_ONLY
----FOR
----	SELECT	DISTINCT FullPath
----	FROM	#FilesToDelete

----OPEN Folders

----FETCH NEXT FROM Folders INTO @currFullPath
----WHILE ( @@fetch_status <> -1 ) 
----	BEGIN --Folders

----		SET @DeleteSQL = ' powershell "$CT = (get-childitem ''' + @currFullPath + ''' -recurse | ?{$_.PSIsContainer -eq 0}).count; If($CT -eq 0){Remove-Item ''' + @currFullPath + '''}"'
----		--SELECT @DeleteSQL
----		INSERT	#DeleteResults
----		EXEC master..xp_cmdshell @DeleteSQL;
		
----		FETCH NEXT FROM Folders INTO @currFullPath
----	END --Folders

----CLOSE Folders
----DEALLOCATE Folders

--------------------------------------------------------------------------------------------------------------------------
----------------------------------------------END Delete Folders----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------




--------------------------------------------------------------------------------------------------------------------------
----------------------------------------------BEGIN Report Files----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
	IF @Delete = 0 
		BEGIN --@Delete = 0
----SELECT * 
----FROM #FilesToDelete
----ORDER BY ExecutionDateTime ASC

			SELECT	DBName ,
					[FullFileName] ,
					BackupSizeInMB AS SizeInMB ,
					BackupType ,
					SUM(BackupSizeInMB) OVER ( PARTITION BY BackupType ) AS TotalSizeInMBPerBackupType ,
					SUM(BackupSizeInMB) OVER ( ) AS TotalSizeInMB
			FROM #FilesToDelete
			WHERE
				ExecutionDateTime <= DATEADD(HOUR, @RetHrs, @EvalDateTime)
				AND BackupLocType <> 'NUL'

		END --@Delete = 0

--------------------------------------------------------------------------------------------------------------------------
----------------------------------------------END Report Files------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


GO
