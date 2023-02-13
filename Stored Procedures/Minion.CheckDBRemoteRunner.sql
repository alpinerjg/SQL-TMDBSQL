SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [Minion].[CheckDBRemoteRunner]
(
@DBName NVARCHAR(400),
@PreferredServer VARCHAR(200),
@PreferredServerPort VARCHAR(10),
@LocalServer VARCHAR(400),
@Port VARCHAR(10),
@MaintDB VARCHAR(50),
@PreferredDBName NVARCHAR(400),
@RestoreCMD varchar(MAX),
@ExecutionDateTime DATETIME,
@JobName VARCHAR(400),
@RestoreMode VARCHAR(20)
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
                
                EXEC Minion.HELP 'CHECKDB', 'Minion.CheckDBRemoteRunner';


PURPOSE: 
**The public should never need to run this SP that I can think of.
This SP creates the remote job for remote mode and runs it.
There are some reqs:
1. Both servers must have MC installed.
2. Both servers must be on same version of MC.
3. MC must be installed in same DB on both servers.
4. Remote server Agent account must have UPDATE rights to the Log tables on Source box.  It's advised to give it full rights to all MC tables or even db_owner cause you never know what this'll do in the future and
you don't want to incur problems after an upgrade.

WALKTHROUGH: 
      1. 


CONVENTIONS:
    
    
TABLES: 
                

EXAMPLE EXECUTIONS:


REVISION HISTORY:
                

--***********************************************************************************/ 

SET NOCOUNT ON;
DECLARE 
		@JobStepSQL VARCHAR(4000),
		@JobCreateSQL VARCHAR(8000),
		@RemoteUpdateSQL VARCHAR(4000),
		@RemoteUpdateCMD VARCHAR (8000),
		@RemoteUpdateJobStepSQL VARCHAR(8000),
		@RemoteResultsError VARCHAR(MAX),
		@CheckDBJobStepSQL VARCHAR(1000),
		@RestoreJobStepSQL VARCHAR(MAX),
		@JobCreateCMD varchar(8000),
		@ExecutionDateTimeTXT VARCHAR(30);


----SET @ExecutionDateTime = (SELECT MAX(ExecutionDateTime) FROM Minion.CheckDBLogDetails);
SET @ExecutionDateTimeTXT = CONVERT(VARCHAR(30), @ExecutionDateTime, 121);

------------------------------------------------------------------------------
-----------------------BEGIN Format Restore Job SQL---------------------------
------------------------------------------------------------------------------
IF @RestoreCMD IS NULL
	BEGIN
		SET @RestoreCMD = '';
	END
SET @RestoreJobStepSQL = REPLACE(@RestoreCMD, '''', '''''');
------------------------------------------------------------------------------
-----------------------END Format Restore Job SQL-----------------------------
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-----------------------BEGIN Format CheckDB Job SQL---------------------------
------------------------------------------------------------------------------
SET @CheckDBJobStepSQL = 'EXEC [Minion].[CheckDBMaster] '
+ '@DBType = ''User'', '
+ '@OpName = ''CHECKDB'', '
+ '@StmtOnly = 0, '
+ '@Schemas = NULL, '
+ '@Tables = NULL, '
+ '@Include = ''' + @PreferredDBName + ''','  
+ '@Exclude = NULL , ' 
+ '@NumConcurrentProcesses = 1, '
+ '@DBInternalThreads = 1, '
+ '@TestDateTime = ''' + @ExecutionDateTimeTXT + ''';';

SET @CheckDBJobStepSQL = REPLACE(@CheckDBJobStepSQL, '''', '''''');

------------------------------------------------------------------------------
-----------------------END Format CheckDB Job SQL-----------------------------
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-----------------------BEGIN Format Remote Update Job SQL---------------------
------------------------------------------------------------------------------
--SET @RemoteUpdateCMD = 'EXEC xp_cmdshell ''powershell "';

--The SqlCmd subsystem doesn't like certain char combos in PS.  Even when they're valid PS syntax that
--run just fine when run manually in the same manner as the job, it still won't run from within a job.
--So we've had to avoid using certain code constructs.  Currently we've found the combo $(.
--Therefore, 

SET @RemoteUpdateCMD = 'powershell ""';
		SET @RemoteUpdateSQL = '$RemoteBox = "' + @PreferredServer + CASE WHEN (@PreferredServerPort IS NOT NULL AND @PreferredServerPort <> '') THEN ','  ELSE '' END
				----+ ISNULL(CAST(@PreferredServerPort AS VARCHAR(10)), '') 
				+ '";'
		+ '$MainBox = "' + @LocalServer + CASE WHEN (@Port IS NOT NULL AND @Port <> '') THEN ','  ELSE '' END
				+ ISNULL(CAST(@Port AS VARCHAR(10)), '') + '";'
		+ '$DB = "' + @MaintDB + '";'
		+ '$fmt = "MM-dd-yyyy %H:m:ss.fff";'
		+ '$CheckDBName = "' + @PreferredDBName + '";'
		+ '$RemoteQuery = "SELECT ExecutionDateTime, CheckDBCmd, STATUS, Warnings FROM Minion.CheckDBLogDetails WHERE ExecutionDateTime = ' + '''''' + @ExecutionDateTimeTXT + '''''' + ' AND CheckDBName = ' + '''''$CheckDBName''''";'
		+ '$RemoteConnString = "Data Source=$RemoteBox;Initial Catalog=$DB;Integrated Security=SSPI;";'
		+  '$RemoteConn  = New-Object System.Data.SqlClient.SQLConnection($RemoteConnString);'
		+  '$SqlCMD = New-Object system.Data.SqlClient.SqlCommand;'
		+  '$SqlCMD.CommandText = $RemoteQuery;'
		+  '$SqlCMD.connection = $RemoteConn;'
		+  '$MainConnString = "Data Source=$MainBox;Initial Catalog=$DB;Integrated Security=SSPI;";'
		+  '$da = New-Object System.Data.SqlClient.SqlDataAdapter;'
		+  '$da.SelectCommand = $SqlCMD;'
		+  '$ds = New-Object System.Data.DataSet;'
		+  '$da.Fill($ds, "CheckDBLogDetails") | Out-Null;'
		+  '$RemoteConn.close();'
		+  'foreach ($row in $ds.tables["CheckDBLogDetails"].rows)'
		+  '{'
		+ '[string]$ExecutionDateTimeRaw = (get-date $row.ExecutionDateTime -format $fmt);'
		+ '[string]$CheckDBCmd = $row.CheckDBCmd;'
		+ '[string]$StatusRaw = $row.Status;'
		+ '[string]$WarningsRaw = $row.Warnings;'
		+  'If ([System.DBNull]::Value.Equals($row.ExecutionDateTime)) { [string]$ExecutionDateTime = ''''NULL'''' }'
		+   'ELSE { $ExecutionDateTime = "''''$ExecutionDateTimeRaw''''" };' 
  		+   'If ([System.DBNull]::Value.Equals($row.Status)) { [string]$Status = ''''NULL'''' }'
		+   'ELSE { $Status = $StatusRaw };'
  		+   '$Status = $Status.replace("$", "`$");'
		+   '$Status = $Status.replace("''''", "''''''''");'
		+   '$Status = "''''$Status''''";'
		+   '$CheckDBCmd = $CheckDBCmd.replace("''''", "''''''''");'
		+   '$CheckDBCmd = "''''$CheckDBCmd''''";'
  		+   'If ([System.DBNull]::Value.Equals($row.Warnings)) { [string]$Warnings = ''''NULL'''' }'
		+   'ELSE { $Warnings = $WarningsRaw };'
  		+   '$Warnings = $Warnings.replace("$", "`$");'
		+   '$Warnings = $Warnings.replace("''''", "''''''''");'
		+   '$Warnings = "''''$Warnings''''";'
  		+   '$UpdateQuery = "SET NOCOUNT ON; UPDATE Minion.CheckDBLogDetails SET STATUS = $Status, CheckDBCmd = $CheckDBCmd, Warnings = $Warnings WHERE ExecutionDateTime = $ExecutionDateTime AND CheckDBName = ''''$CheckDBName'''' AND UPPER(OpName) = ''''CHECKDB'''';";'
  		+   'SQLCMD -S "$MainBox" -E -d "$DB" -Q "$UpdateQuery";'
  		+   '}';
SET @RemoteUpdateSQL = REPLACE(@RemoteUpdateSQL, '"', '""""""');

			SET @RemoteUpdateSQL = @RemoteUpdateSQL + '""'

--SET @RemoteUpdateSQL = REPLACE(@RemoteUpdateSQL, '''', '''''');
SET @RemoteUpdateCMD = @RemoteUpdateCMD + @RemoteUpdateSQL;
		--SET @RemoteUpdateCMD = @RemoteUpdateCMD + '"''';

--SET @RemoteUpdateCMD = REPLACE(@RemoteUpdateCMD, '''', '''''''''');

------------------------------------------------------------------------------
-----------------------END Format Remote Update Job SQL-----------------------
------------------------------------------------------------------------------
--PRINT @RemoteCMD
----EXEC (@RemoteCMD)

------------------------------------------------------------------------------
-----------------------BEGIN Format JobName-----------------------------------
------------------------------------------------------------------------------
--SET @JobName = 'MinionCheckDB-REMOTE-From-' + @LocalServer;

INSERT Minion.Work
SELECT @ExecutionDateTime, 'CheckDB', @PreferredDBName, NULL, '@JobName', 'CheckDBRemoteRunner', @JobName

------------------------------------------------------------------------------
-----------------------END Format JobName-------------------------------------
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-----------------------BEGIN Format Create Job--------------------------------
------------------------------------------------------------------------------
SET @JobCreateSQL = 'BEGIN TRANSACTION '
+ ' DECLARE @jobId BINARY(16);'
+ 'EXEC msdb.dbo.sp_add_job @job_name=N''' + @JobName +  ''', '
+ '@enabled=1, '
+ '@notify_level_eventlog=0, '
+ '@notify_level_email=0, '
+ '@notify_level_netsend=0, '
+ '@notify_level_page=0, '
+ '@delete_level=0, '
+ '@description=N''Runs CHECKDB as a remote run for the configured server.'', '
+ '@category_name=N''[Uncategorized (Local)]'', '
+ '@job_id = @jobId OUTPUT;'
+ 'EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Restore DB'', '
+ '@step_id=1, '
+ '@cmdexec_success_code=0, '
+ '@on_success_action=3, '
+ '@on_success_step_id=0, '
+ '@on_fail_action=2, '
+ '@on_fail_step_id=0, '
+ '@retry_attempts=0, '
+ '@retry_interval=0, '
+ '@os_run_priority=0, @subsystem=N''Tsql'', '
+ '@command=N''' + @RestoreJobStepSQL + ''', '
+ '@database_name=N''' + DB_NAME() + ''', '
+ '@flags=0;'
+ 'EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)'';'
+ 'COMMIT TRANSACTION; '

----SET @JobCreateSQL = REPLACE(@JobCreateSQL, '''', '''''');
-------------------BEGIN Add CheckDB Step---------------------
SET @JobCreateSQL =  @JobCreateSQL + ' EXEC msdb.dbo.sp_add_jobstep @job_name=''' + @JobName + ''', @step_name=N''Run CheckDB'', '
+ '@step_id=2, '
+ '@cmdexec_success_code=0, '
+ '@on_success_action=3, '
+ '@on_success_step_id=0, '
+ '@on_fail_action=2, '
+ '@on_fail_step_id=0, '
+ '@retry_attempts=0, '
+ '@retry_interval=0, '
+ '@os_run_priority=0, @subsystem=N''TSQL'', '
+ '@command=N''' + @CheckDBJobStepSQL + ''','
+ '@database_name=N''' + @MaintDB + ''', '
+ '@flags=0;'

----SET @JobCreateSQL = REPLACE(@JobCreateSQL, '''', '''''');
-------------------END Add CheckDB Step-----------------------

-------------------BEGIN Add Update Host Step---------------------
SET @JobCreateSQL =  @JobCreateSQL + ' EXEC msdb.dbo.sp_add_jobstep @job_name=''' + @JobName + ''', @step_name=N''Update Host Server'', '
+ '@step_id=3, '
+ '@cmdexec_success_code=0, '
+ '@on_success_action=1, '
+ '@on_success_step_id=0, '
+ '@on_fail_action=2, '
+ '@on_fail_step_id=0, '
+ '@retry_attempts=0, '
+ '@retry_interval=0, '
+ '@os_run_priority=0, @subsystem=N''CmdExec'', '
+ '@command=N''' + @RemoteUpdateCMD + ''','
+ '@database_name=N''master'', '
+ '@flags=0;'

--SET @JobCreateSQL = REPLACE(@JobCreateSQL, '''', '''''');
-------------------END Add Update Host Step-----------------------


-------------------BEGIN Set First Job Step---------------------
SET @JobCreateSQL =  @JobCreateSQL + 'EXEC msdb.dbo.sp_update_job @job_name=''' + @JobName + ''', @start_step_id = 1;';
-------------------END Set First Job Step-----------------------


SET @JobCreateSQL = REPLACE(@JobCreateSQL, '''', '''''');
------------------------------------------------------------------------------
-----------------------END Format Create Job----------------------------------
------------------------------------------------------------------------------
								--EXEC(@JobThreadSQL)
								--PRINT @JobCreateSQL;


----------------------------------------------------------------
----------------------BEGIN Create Remote Job-------------------
----------------------------------------------------------------
		SET @JobCreateCMD = 'xp_cmdshell ''';
		SET @JobCreateCMD = @JobCreateCMD + 'sqlcmd -r 1 -S"' + @PreferredServer + '"'
				+ ISNULL(CAST(@PreferredServerPort AS VARCHAR(10)), '')
			+ ' -d "master" -q "' 
		SET @JobCreateCMD = @JobCreateCMD + @JobCreateSQL --+ '"'; --@JobCreateSQL
		SET @JobCreateCMD = @JobCreateCMD + '"''';

		----SET @JobCreateCMD = 'xp_cmdshell ''powershell "';
		----SET @JobCreateCMD = @JobCreateCMD + 'sqlcmd -r 1 -S"""' + @PreferredServer + '"""'
		----		+ ISNULL(CAST(@PreferredServerPort AS VARCHAR(10)), '')
		----	+ ' -d """master""" -q """' 
		----SET @JobCreateCMD = @JobCreateCMD + @JobCreateSQL + '"""'; --@JobCreateSQL
		----SET @JobCreateCMD = @JobCreateCMD + '"''';


								--SET @JobStartSQL = 'EXEC msdb.dbo.sp_start_job @job_name = ''' + @JobName + ''''
								--PRINT @JobStartSQL

					DECLARE @RemoteJobCreateErrorTable TABLE (ID INT IDENTITY(1,1), col1 VARCHAR(MAX));
					DECLARE @RemoteJobStartErrorTable TABLE (ID INT IDENTITY(1,1), col1 VARCHAR(MAX));
					DECLARE @RemoteJobErrors VARCHAR(MAX);
								INSERT @RemoteJobCreateErrorTable
								EXEC (@JobCreateCMD);
--SELECT * FROM @RemoteJobCreateErrorTable AS RemoteJob
								DELETE FROM @RemoteJobCreateErrorTable
									   WHERE col1 IS NULL									 

								SELECT @RemoteJobErrors = 'REMOTE JOB CREATE ERROR: '
											+ STUFF((SELECT ' ' + col1
												FROM @RemoteJobCreateErrorTable AS T1
												ORDER BY T1.ID
												FOR XML PATH('')), 1, 1, '')
										FROM
											@RemoteJobCreateErrorTable AS T2;

									IF @RemoteJobErrors IS NOT NULL
										BEGIN
										--We'll need this info in CheckDB so we can return the SP if there's an error.
  										INSERT Minion.Work (ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value)
										SELECT @ExecutionDateTime, 'CheckDB', @DBName, NULL, '@RemoteJobErrors-Create job', 'CheckDBRemoteRunner', @RemoteJobErrors;
	                                 
									    UPDATE Minion.CheckDBLogDetails
                                            SET Status = 'FATAL ERROR: ' + @RemoteJobErrors
                                            WHERE
                                                 ExecutionDateTime = @ExecutionDateTime 
												 AND CheckDBName = @PreferredDBName;
										RETURN; --For a remote run, not having the right job is death so we need to stop.
										END
----------------------------------------------------------------
----------------------END Create Remote Job---------------------
----------------------------------------------------------------

----------------------------------------------------------------
----------------------BEGIN Start Remote Job--------------------
----------------------------------------------------------------
DECLARE @JobRunSQL VARCHAR(500),
		@JobRunCMD VARCHAR(1000);

IF @RestoreMode = 'LastMinionBackup'
	BEGIN
		SET @JobRunSQL = 'EXEC msdb.dbo.sp_start_job @job_name = ''''' + @JobName + '''''';
	END	

IF @RestoreMode = 'NONE'
	BEGIN
		SET @JobRunSQL = 'EXEC msdb.dbo.sp_start_job @job_name = ''''' + @JobName + ''''', @step_name = ''''' + 'Run CheckDB''''';
	END	

SET @JobRunCMD = 'xp_cmdshell ''';
SET @JobRunCMD = @JobRunCMD + 'sqlcmd -r 1 -S"' + @PreferredServer + '"'
		+ ISNULL(CAST(@PreferredServerPort AS VARCHAR(10)), '')
	+ ' -d "master" -q "';
SET @JobRunCMD = @JobRunCMD + @JobRunSQL ;
SET @JobRunCMD = @JobRunCMD + '"''';
INSERT @RemoteJobStartErrorTable
EXEC (@JobRunCMD);

								DELETE FROM @RemoteJobStartErrorTable
									   WHERE col1 IS NULL OR col1 LIKE '%started successfully%'								 
								SET @RemoteJobErrors = NULL;
								SELECT @RemoteJobErrors = 'REMOTE JOB START ERROR: '
											+ STUFF((SELECT ' ' + col1
												FROM @RemoteJobStartErrorTable AS T1
												ORDER BY T1.ID
												FOR XML PATH('')), 1, 1, '')
										FROM
											@RemoteJobStartErrorTable AS T2;

									IF @RemoteJobErrors IS NOT NULL
										BEGIN
										--We'll need this info in CheckDB so we can return the SP if there's an error.
  										INSERT Minion.Work (ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value)
										SELECT @ExecutionDateTime, 'CheckDB', @DBName, NULL, '@RemoteJobErrors- Start job', 'CheckDBRemoteRunner', @RemoteJobErrors;
	                                 
									    UPDATE Minion.CheckDBLogDetails
                                            SET Status = 'FATAL ERROR: ' + @RemoteJobErrors
                                            WHERE
                                                 ExecutionDateTime = @ExecutionDateTime 
												 AND CheckDBName = @PreferredDBName;
										RETURN; --For a remote run, not having the right job is death so we need to stop.
										END
----------------------------------------------------------------
----------------------END Start Remote Job----------------------
----------------------------------------------------------------

GO
