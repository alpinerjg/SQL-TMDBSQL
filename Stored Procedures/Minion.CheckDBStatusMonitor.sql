SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[CheckDBStatusMonitor]
	(
	  @Interval VARCHAR(20) = '00:00:05'
	)
/***********************************************************************************
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------------------Minion CheckDB------------------------------------------------
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
  
Purpose: Update the PctComplete and status of running backups, in Minion.BackupLogDetails.

Features:
	* 

Limitations:
	*  ___

Notes:
	* This procedure is automatically started at the start of a backup, and 
	  automatically stopped at the end of the last running backup.

Walkthrough: 
      This is a single step update that repeats in a loop, every [@Interval] seconds/minutes/hours.

Conventions:

Parameters:
-----------
    @Interval - The amount of time to wait before updating the table again (in the
				format '0:0:05').
    
    
Tables: 
--------
	

Example Executions:
--------------------
	-- Update the status and percent complete every 5 seconds.
	EXEC  [Minion].[CheckDBStatusMonitor]
	  @Interval = '0:0:05';

Revision History:
	

***********************************************************************************/
AS 

SET NOCOUNT ON;
DECLARE @RemoteStatusSQL VARCHAR(500),
		@RemoteStatusCMD VARCHAR(4000),
		@CheckDBStatusSQL VARCHAR(1000),
		@IsRemoteRun TINYINT,
		@ExecutionDateTime DATETIME,
		@PreferredServerPort varchar(10),
		@PreferredServer VARCHAR(400),
		@MaintDB VARCHAR(400),
		@LocalServer VARCHAR(400),
		@Port VARCHAR(10),
		@ExecutionDateTimeTXT VARCHAR(30);

SET @MaintDB = DB_NAME();
SET @LocalServer = CAST(SERVERPROPERTY('MachineName') AS VARCHAR(100));
SET @Port = (SELECT TOP 1 Port FROM Minion.CheckDBSettingsDB);

CREATE TABLE #CheckTablePctComplete
(
DBName VARCHAR(4200),
CheckDBName VARCHAR(400),
TableName VARCHAR(400),
percent_complete TINYINT
);

CREATE TABLE #RemoteServers
(
PreferredServer VARCHAR(400),
PreferredDBName VARCHAR(400),
PreferredServerPort VARCHAR(10),
RemoteMode VARCHAR(25)
);

SET @ExecutionDateTime = (SELECT MAX(ExecutionDateTime) FROM Minion.CheckDBLogDetails);
SET @ExecutionDateTimeTXT = CONVERT(VARCHAR(30), @ExecutionDateTime, 121);

DECLARE @currPreferredServer varchar(400),
		@currPreferredServerPort varchar(10),
		@currPreferredDBName varchar(400),
		@currRemoteMode VARCHAR(25),
		@RemoteStatusPS VARCHAR(8000);

	WHILE 1 = 1 
		BEGIN --While

			BEGIN
------------------------------------------------------			
------------------BEGIN CHECKDB-----------------------
------------------------------------------------------
				UPDATE	BL
				SET		BL.PctComplete = ER.percent_complete ,
						BL.STATUS = 'CHECKDB running'
				FROM	Minion.CheckDBLogDetails BL
						INNER JOIN sys.dm_exec_requests ER WITH ( NOLOCK ) ON BL.CheckDBName = DB_NAME(ER.database_id)
				WHERE	BL.ExecutionDateTime IN (
						SELECT	MAX(ExecutionDateTime)
						FROM	Minion.CheckDBLogDetails AS BL2
						WHERE	BL2.CheckDBName = BL.CheckDBName
								AND DB_NAME(ER.database_id) = BL.CheckDBName
								AND (ER.command LIKE '%CHECKDB%' OR ER.command LIKE '%DBCC%TABLE%')
								AND BL.STATUS LIKE 'CHECKDB running%'
								AND BL2.STATUS LIKE 'CHECKDB running%');
------------------------------------------------------			
------------------END CHECKDB-------------------------
------------------------------------------------------


------------------------------------------------------			
------------------BEGIN CHECKTABLE--------------------
------------------------------------------------------
INSERT #CheckTablePctComplete (DBName, CheckDBName, TableName, percent_complete)
SELECT ISNULL(DB_NAME(SD.source_database_id), DB_NAME(TL.resource_database_id)) AS DBName, 
DB_NAME(TL.resource_database_id) AS CheckDBName, 
OBJECT_NAME(TL.resource_associated_entity_id, (SELECT ISNULL(source_database_id, SD.database_id) FROM sys.databases SD WHERE SD.database_id = TL.resource_database_id)) AS TableName, ER.percent_complete
FROM sys.dm_tran_locks TL WITH ( NOLOCK ) 
INNER JOIN sys.dm_exec_requests ER WITH ( NOLOCK ) 
ON TL.request_session_id = ER.session_id
INNER JOIN sys.databases SD WITH ( NOLOCK ) 
ON SD.database_id = TL.resource_database_id
WHERE resource_type = 'OBJECT'
AND TL.resource_associated_entity_id > 0
AND TL.resource_database_id > 4

				UPDATE	BL
				SET		BL.PctComplete = ER.percent_complete ,
						BL.STATUS = 'CHECKTABLE running'
				FROM	Minion.CheckDBLogDetails BL
						INNER JOIN #CheckTablePctComplete ER WITH ( NOLOCK ) 
						ON BL.CheckDBName = ER.CheckDBName AND BL.TableName = ER.TableName
				WHERE	BL.ExecutionDateTime IN (
						SELECT	MAX(ExecutionDateTime)
						FROM	Minion.CheckDBLogDetails AS BL2
						WHERE	BL2.CheckDBName = BL.CheckDBName
								AND BL.CheckDBName = ER.CheckDBName
								AND BL.STATUS LIKE '%CHECKTABLE%'
								AND BL2.STATUS LIKE '%CHECKTABLE%');
------------------------------------------------------			
------------------END CHECKTABLE----------------------
------------------------------------------------------


------------------------------------------------------			
------------------BEGIN Minion Backup-----------------
------------------------------------------------------
----UPDATE CLD
----SET 
----CLD.STATUS = 'Running Minion Backup',
----PctComplete = BLD.PctComplete

----SELECT CLD.DBName, CLD.Status, BLD.PctComplete
----FROM Minion.CheckDBLogDetails CLD
----INNER JOIN Minion.BackupLogDetails BLD
----ON BLD.DBName = CLD.DBName
----WHERE UPPER(BLD.BackupType) = 'CHECKDB'
---- AND BLD.ExecutionDateTime IN (SELECT MAX(ExecutionDateTime) FROM Minion.BackupLogDetails WHERE DBName = CLD.DBName AND UPPER(BackupType) = 'CHECKDB')
---- AND CLD.ExecutionDateTime IN (SELECT MAX(ExecutionDateTime) FROM Minion.CheckDBLogDetails) 
---- AND BLD.PctComplete < 100
------------------------------------------------------			
------------------END Minion Backup-------------------
------------------------------------------------------


----------------------------------------------------------------
---------------------BEGIN Remote Monitor-----------------------
----------------------------------------------------------------

----SELECT PreferredDBName 
----FROM Minion.CheckDBLogDetails
----WHERE NETBIOSName <> PreferredDBName OR PreferredDBName IS NOT NULL
----AND ExecutionDateTime IN (SELECT MAX(ExecutionDateTime SELECT PreferredDBName 
----FROM Minion.CheckDBLogDetails))

--!!!!!Cant pass in the port, etc cause the monitor may be started after the routine is going so they'll be blank.

INSERT #RemoteServers (PreferredServer, PreferredDBName, RemoteMode)
SELECT PreferredServer, PreferredDBName, RemoteCheckDBMode
FROM Minion.CheckDBLogDetailsCurrent
WHERE PreferredServer IS NOT NULL;

UPDATE RS
SET RS.PreferredServerPort = CS.PreferredServerPort
FROM #RemoteServers RS
INNER JOIN Minion.CheckDBSettingsDB CS
ON RS.PreferredServer = CS.PreferredServer

SET @IsRemoteRun = (SELECT COUNT(*) FROM #RemoteServers);

IF @IsRemoteRun > 0 AND @IsRemoteRun IS NOT NULL
	BEGIN
		DECLARE @RemoteResults TABLE (DBName VARCHAR(400), Cmd VARCHAR(50), PctComplete TINYINT);
	END

----SET @IsRemoteRun = 1; --Testing, remove.
----!!!!!Go to other sp and save those values to Work
IF @IsRemoteRun > 0
	BEGIN --Remote Run
		---- Remote Restores


DECLARE RemoteCursor CURSOR
READ_ONLY
FOR SELECT PreferredServer, PreferredDBName, PreferredServerPort, RemoteMode
FROM #RemoteServers

OPEN RemoteCursor

	FETCH NEXT FROM RemoteCursor INTO @currPreferredServer, @currPreferredDBName, @currPreferredServerPort, @currRemoteMode
	WHILE (@@fetch_status <> -1)
	BEGIN


----SET @currPreferredServer = 'MinionDevcon';
----SET @currPreferredDBName = 'MinionDev';
----SET @currPreferredServerPort = NULL;

	----------------------------------------------------------------------------------
	----------------------------------------------------------------------------------
	---------------------------BEGIN CHECKDB------------------------------------------
	----------------------------------------------------------------------------------
	----------------------------------------------------------------------------------

----Here we're checking the remote server for the status of the CHECKDB ops we're running against it.
----The code updates CheckDBLogDetails itself so this is the only call that needs to be made.
----It currently doesn't support CHECKTABLE updates and I'm not sure it ever will.  That would be a lot of updates on a large DB.  We'll have to see how things play out with the users.
		SET @RemoteStatusSQL = 'SELECT DB_NAME(database_id) AS DBName, command, percent_complete AS PctComplete FROM sys.dm_exec_requests WITH (NOLOCK) WHERE (command LIKE ''''%CHECKDB%'''' OR command LIKE ''''%DBCC%TABLE%'''' OR command LIKE ''''%DBCC%ALLOC%'''');';
	
		SET @RemoteStatusCMD = 'xp_cmdshell ''powershell "';
		SET @RemoteStatusPS = '$RemoteBox = "' + @currPreferredServer + CASE WHEN (@currPreferredServerPort IS NOT NULL AND @currPreferredServerPort <> '') THEN ','  ELSE '' END
				+ ISNULL(CAST(@currPreferredServerPort AS VARCHAR(10)), '') + '";'
		+ '$MainBox = "' + @LocalServer + CASE WHEN (@Port IS NOT NULL AND @Port <> '') THEN ','  ELSE '' END
				+ ISNULL(CAST(@Port AS VARCHAR(10)), '') + '";'
		+ '$DB = "' + @MaintDB + '";' 
		+ '$fmt = "MM-dd-yyyy %H:m:ss.fff";'
		+ '$DBNull = [System.DBNull]::Value;'
		+ '$ExecutionDateTime = "' + @ExecutionDateTimeTXT + '";' --get this value from other job runner.
		+ '$CheckDBName = "' + @currPreferredDBName + '";'
		+ '$RemoteQuery = "' + @RemoteStatusSQL + '";'
		+ '$RemoteConnString = "Data Source=$RemoteBox;Initial Catalog=$DB;Integrated Security=SSPI;";'
		+  '$RemoteConn  = New-Object System.Data.SqlClient.SQLConnection($RemoteConnString);'
		+  '$SqlCMD = New-Object system.Data.SqlClient.SqlCommand;'
		+  '$SqlCMD.CommandText = $RemoteQuery;'
		+  '$SqlCMD.connection = $RemoteConn;'
		+  '$MainConnString = "Data Source=$MainBox;Initial Catalog=$DB;Integrated Security=SSPI;";'
		+  '$da = New-Object System.Data.SqlClient.SqlDataAdapter;'
		+  '$da.SelectCommand = $SqlCMD;'
		+  '$ds = New-Object System.Data.DataSet;'
		+  '$da.Fill($ds, "RemoteStatus") | Out-Null;'
		+  '$RemoteConn.close();'
		+  'foreach ($row in $ds.tables["RemoteStatus"].rows)'
		+  '{'
		+ '[string]$CheckDBName = $row.DBName; $PctComplete = $row.PctComplete;'
		+ '$Status = "Running CheckDB on $RemoteBox (' + ISNULL(@currRemoteMode, 'No Mode Detected') + ')";'
  		+   '$UpdateQuery = "SET NOCOUNT ON; UPDATE Minion.CheckDBLogDetails SET STATUS = ''''$Status'''', PctComplete = $PctComplete WHERE ExecutionDateTime = ''''$ExecutionDateTime'''' AND CheckDBName = ''''$CheckDBName'''' AND UPPER(OpName) = ''''CHECKDB'''';";'
  		--+ '$UpdateQuery;'
		+ 'If ($PctComplete -ne $DBNull){'
		+   'SQLCMD -S "$MainBox" -E -d "$DB" -Q "$UpdateQuery";'
  		+   '}'
  		+   '}';

		-----------BEGIN Set Quotes-----------------
		SET @RemoteStatusPS = REPLACE(@RemoteStatusPS, '"', '"""');
		SET @RemoteStatusCMD = @RemoteStatusCMD + @RemoteStatusPS;
		SET @RemoteStatusCMD = @RemoteStatusCMD + '" '''
		-----------END Set Quotes-------------------
		--INSERT @RemoteResults
		EXEC (@RemoteStatusCMD)
		--PRINT @RemoteStatusCMD	

	----------------------------------------------------------------------------------
	----------------------------------------------------------------------------------
	---------------------------END CHECKDB--------------------------------------------
	----------------------------------------------------------------------------------
	----------------------------------------------------------------------------------


	----------------------------------------------------------------------------------
	----------------------------------------------------------------------------------
	---------------------------BEGIN RESTORE------------------------------------------
	----------------------------------------------------------------------------------
	----------------------------------------------------------------------------------

----Here we're checking the remote server for the status of the RESTORE ops we're running against it.
----The code updates CheckDBLogDetails itself so this is the only call that needs to be made.
		SET @RemoteStatusSQL = 'SELECT DB_NAME(TL.resource_database_id) AS DBName, ER.percent_complete AS PctComplete FROM sys.dm_tran_locks TL WITH (NOLOCK) INNER JOIN sys.dm_exec_requests ER WITH ( NOLOCK ) ON TL.request_session_id = ER.session_id WHERE resource_type = ''''DATABASE'''' AND TL.request_mode = ''''X'''';';
	
		SET @RemoteStatusCMD = 'xp_cmdshell ''powershell "';
		SET @RemoteStatusPS = '$RemoteBox = "' + @currPreferredServer + CASE WHEN (@currPreferredServerPort IS NOT NULL AND @currPreferredServerPort <> '') THEN ','  ELSE '' END
				+ ISNULL(CAST(@currPreferredServerPort AS VARCHAR(10)), '') + '";'
		+ '$MainBox = "' + @LocalServer + CASE WHEN (@Port IS NOT NULL AND @Port <> '') THEN ','  ELSE '' END
				+ ISNULL(CAST(@Port AS VARCHAR(10)), '') + '";'
		+ '$DB = "' + @MaintDB + '";' 
		+ '$fmt = "MM-dd-yyyy %H:m:ss.fff";'
		+ '$DBNull = [System.DBNull]::Value;'
		+ '$ExecutionDateTime = "' + @ExecutionDateTimeTXT + '";' --get this value from other job runner.
		+ '$CheckDBName = "' + @currPreferredDBName + '";'
		+ '$RemoteQuery = "' + @RemoteStatusSQL + '";'
		+ '$RemoteConnString = "Data Source=$RemoteBox;Initial Catalog=$DB;Integrated Security=SSPI;";'
		+  '$RemoteConn  = New-Object System.Data.SqlClient.SQLConnection($RemoteConnString);'
		+  '$SqlCMD = New-Object system.Data.SqlClient.SqlCommand;'
		+  '$SqlCMD.CommandText = $RemoteQuery;'
		+  '$SqlCMD.connection = $RemoteConn;'
		+  '$MainConnString = "Data Source=$MainBox;Initial Catalog=$DB;Integrated Security=SSPI;";'
		+  '$da = New-Object System.Data.SqlClient.SqlDataAdapter;'
		+  '$da.SelectCommand = $SqlCMD;'
		+  '$ds = New-Object System.Data.DataSet;'
		+  '$da.Fill($ds, "RemoteStatus") | Out-Null;'
		+  '$RemoteConn.close();'
		+  'foreach ($row in $ds.tables["RemoteStatus"].rows)'
		+  '{'
		+ '[string]$CheckDBName = $row.DBName; $PctComplete = $row.PctComplete;'
		+ '$Status = "Restoring DB on $RemoteBox (' + ISNULL(@currRemoteMode, 'No Mode Detected') + ')";'
  		+   '$UpdateQuery = "SET NOCOUNT ON; UPDATE Minion.CheckDBLogDetails SET STATUS = ''''$Status'''', PctComplete = $PctComplete WHERE ExecutionDateTime = ''''$ExecutionDateTime'''' AND CheckDBName = ''''$CheckDBName'''' AND UPPER(OpName) = ''''CHECKDB'''';";'
  		--+ '$UpdateQuery;'
		+ 'If ($PctComplete -ne $DBNull){'
		+   'SQLCMD -S "$MainBox" -E -d "$DB" -Q "$UpdateQuery";'
		+ '}'
  		+   '}';

		-----------BEGIN Set Quotes-----------------
		SET @RemoteStatusPS = REPLACE(@RemoteStatusPS, '"', '"""');
		SET @RemoteStatusCMD = @RemoteStatusCMD + @RemoteStatusPS;
		SET @RemoteStatusCMD = @RemoteStatusCMD + '" '''
		-----------END Set Quotes-------------------
		--INSERT @RemoteResults
		EXEC (@RemoteStatusCMD)
		--PRINT @RemoteStatusCMD	

	----------------------------------------------------------------------------------
	----------------------------------------------------------------------------------
	---------------------------END RESTORE--------------------------------------------
	----------------------------------------------------------------------------------
	----------------------------------------------------------------------------------
	
FETCH NEXT FROM RemoteCursor INTO @currPreferredServer, @currPreferredDBName, @currPreferredServerPort
	END

CLOSE RemoteCursor
DEALLOCATE RemoteCursor


	END --Remote Run
--------Get checkDB op
--SELECT DB_NAME(database_id) AS DBName, command, percent_complete, * FROM sys.dm_exec_requests WITH (NOLOCK) WHERE (command LIKE '%CHECKDB%' OR command LIKE '%DBCC%TABLE%' OR command LIKE '%DBCC%ALLOC%')

--------Get restore op
----SELECT DB_NAME(TL.resource_database_id) AS DBName, ER.percent_complete FROM sys.dm_tran_locks TL WITH ( NOLOCK ) INNER JOIN sys.dm_exec_requests ER WITH ( NOLOCK ) ON TL.request_session_id = ER.session_id WHERE resource_type = 'DATABASE' AND TL.request_mode = 'X'
------AND TL.resource_associated_entity_id > 0
------AND TL.resource_database_id > 4
----------------------------------------------------------------
---------------------END Remote Monitor-------------------------
----------------------------------------------------------------

TRUNCATE TABLE #CheckTablePctComplete;
			END
			WAITFOR DELAY @Interval;
		END --While



GO
