SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[BackupVerify] 
(
@ExecutionDateTime DATETIME,
@DBName NVARCHAR(400) = NULL
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

Purpose: 
		 

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
    @ExecutionDateTime - 
    
Tables: 
--------
	

Example Executions:
--------------------
	-- 

Revision History:
	

***********************************************************************************/
AS

DECLARE @currDB sysname,
		@currID BIGINT,
		@currFileList VARCHAR(max),
		@VerifyErrors VARCHAR(MAX),
		@BackupCmd VARCHAR(8000),
		@PreCMD VARCHAR(2000),
		@TotalCMD VARCHAR(8000),
		@ServerInstance VARCHAR(50),
		@Port VARCHAR(10),
		@VerifyStartDateTime DATETIME,
		@VerifyEndDateTime DATETIME,
		@VerifyTimeInSecs INT;


SET @ServerInstance = @@ServerName;
------------------------------------------------------------
------------------------------------------------------------
-------------BEGIN DB Selection-----------------------------
------------------------------------------------------------
------------------------------------------------------------


/*
Currently the FileAction happens first.  So if you move the file as part of the FileAction then it won't be there for the verify because
Verify looks at the FileList in the LogDetails table.  
In the future we might be able to verify it from its moved location but currently this is just a byproduct of having moved the file.
*/


CREATE TABLE #VerifyDBs
(
ID INT IDENTITY(1,1),
DBName NVARCHAR(400) COLLATE DATABASE_DEFAULT
)

--Single DB
IF @DBName IS NOT NULL
BEGIN
	INSERT #VerifyDBs(DBName)
	SELECT @DBName
END

--Mult. DBs
IF @DBName IS NULL
BEGIN
	INSERT #VerifyDBs(DBName)
	SELECT DBName COLLATE DATABASE_DEFAULT
	FROM Minion.BackupLogDetails
	WHERE STATUS LIKE '%Complete%'
		  AND Verify = 'AfterBatch'
		  AND ExecutionDateTime = @ExecutionDateTime
END

------------------------------------------------------------
------------------------------------------------------------
-------------END DB Selection-------------------------------
------------------------------------------------------------
------------------------------------------------------------


SET @Port = (SELECT TOP 1 Port FROM Minion.BackupSettings)

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
---------------------------BEGIN Run Verify------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

CREATE TABLE #Verify
    (
        ID INT IDENTITY(1, 1),
        col1 VARCHAR(MAX) COLLATE DATABASE_DEFAULT
    )

DECLARE VerifyDBs CURSOR READ_ONLY
FOR
	SELECT	ID, DBName COLLATE DATABASE_DEFAULT, FileList COLLATE DATABASE_DEFAULT
	FROM	Minion.BackupLogDetails WITH (NOLOCK)
	WHERE   ExecutionDateTime = @ExecutionDateTime
			AND DBName IN (SELECT DBName COLLATE DATABASE_DEFAULT FROM #VerifyDBs)

OPEN VerifyDBs

FETCH NEXT FROM VerifyDBs INTO @currID, @currDB, @currFileList
WHILE ( @@fetch_status <> -1 ) 
	BEGIN




-----------------------------------------------
----------BEGIN  Log --------------------------
-----------------------------------------------

UPDATE Minion.BackupLogDetails
SET STATUS = 'Verifying Files'
WHERE ID = @currID

-----------------------------------------------
----------END  Log ----------------------------
-----------------------------------------------

 IF @ServerInstance NOT LIKE '%\%'
	BEGIN
		SET @Port = CASE WHEN @Port IS NULL THEN ',' + '1433'
						 WHEN @Port IS NOT NULL THEN ',' + @Port
						 END
	END
IF @ServerInstance LIKE '%\%'
	BEGIN
			SET @Port = CASE WHEN @Port IS NULL THEN ''
							 WHEN @Port IS NOT NULL THEN ',' + @Port
							 END
	END



					SET @VerifyStartDateTime = GETDATE();
					SET @BackupCmd = 'RESTORE VERIFYONLY FROM ' + @currFileList

                    SET @PreCMD = 'sqlcmd -r 1 -S' + @ServerInstance + CAST(@Port AS VARCHAR(6))
                    SET @TotalCMD = @PreCMD
                        + ' -q "' + @BackupCmd + '"'

                    INSERT #Verify
                            (col1)
                            EXEC xp_cmdshell @TotalCMD;

                    DELETE FROM
                            #Verify
                        WHERE
                            col1 IS NULL;

SELECT
    @VerifyErrors = STUFF((
                            SELECT
                                ' ' + col1
                            FROM #Verify AS T1
                            ORDER BY
                                T1.ID
                        FOR XML PATH('') ), 1, 1, '')
						FROM
							#Verify AS T2;

					SET @VerifyEndDateTime = GETDATE();					


-----------------------------------------------
----------BEGIN  Log Results-------------------
-----------------------------------------------

UPDATE Minion.BackupLogDetails
SET 
STATUS = 'Verify Complete',
Verified = CASE
					WHEN @VerifyErrors LIKE '%is valid%' THEN 1
					WHEN @VerifyErrors NOT LIKE '%is valid%' THEN 0
			   END,
	Warnings = CASE
					--WHEN @VerifyErrors LIKE '%is valid%' THEN Warnings
					WHEN @VerifyErrors NOT LIKE '%is valid%' THEN ISNULL(Warnings, '') + ' VERIFY ERRORS: ' + @VerifyErrors
					ELSE Warnings
			   END,
			   VerifyStartDateTime = @VerifyStartDateTime,
			   VerifyEndDateTime = @VerifyEndDateTime,
			   VerifyTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @VerifyStartDateTime, 21), CONVERT(VARCHAR(25), @VerifyEndDateTime, 21))
WHERE ID = @currID



-----------------------------------------------
----------END  Log Results---------------------
-----------------------------------------------


FETCH NEXT FROM VerifyDBs INTO @currID, @currDB, @currFileList
	END

CLOSE VerifyDBs
DEALLOCATE VerifyDBs

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
---------------------------END Run Verify--------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------












GO
