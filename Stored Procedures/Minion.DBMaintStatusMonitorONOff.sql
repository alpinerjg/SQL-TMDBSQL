SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[DBMaintStatusMonitorONOff]
(
@Module VARCHAR(25),
@Flip VARCHAR(3), -- ON|OFF
@Version DECIMAL(3,1),
@InstanceName NVARCHAR(128)
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
                
                EXEC Minion.HELP 'CHECKDB', 'Minion.DBMaintStatusMonitorONOFF';


PURPOSE: 


WALKTHROUGH: 
      1. 


CONVENTIONS:
    
    
TABLES: 
                

EXAMPLE EXECUTIONS:
Minion.DBMaintStatusMonitorONOff 'CHECKDB', 'ON', '12', NULL
Minion.DBMaintStatusMonitorONOff 'CHECKDB', 'OFF', '12', NULL

REVISION HISTORY:
                

--***********************************************************************************/ 

DECLARE @RegexCMD VARCHAR(2000),
		@ServiceStatus BIT,
		@MonitorJobRunning BIT,
		@ExecutionDateTime datetime; --Remove after tshooting
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------
				---------------------BEGIN PRE Service Check------------------------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------
SET @ExecutionDateTime = GETDATE();

IF @Version <= 10.5
BEGIN --@Version <= 10.5
		CREATE TABLE #PREService (col1 VARCHAR(1000) COLLATE DATABASE_DEFAULT)

		BEGIN
					SET @RegexCMD = 'EXEC xp_cmdshell ''powershell "'
					SET @RegexCMD = @RegexCMD + ' $a = (gwmi win32_service | ?{$_.Name -LIKE ''''SQLAgent$' + @InstanceName + '''''}).State; If($a -eq ''''Running''''){$a = 1} ELSE{$a = 0}"'''

					INSERT  #PREService
							( col1 )
							EXEC ( @RegexCMD
								) 



-------------------DEBUG-------------------------------
--IF @Debug = 1
--BEGIN
--	INSERT Minion.BackupDebug (ExecutionDateTime, DBName, BackupType, SPName, StepName, StepValue)
--	SELECT @ExecutionDateTime, @DBName, @BackupType, 'BackupMaster', 'PreService cmd', @RegexCMD
--END
-------------------DEBUG-------------------------------

		SET @ServiceStatus = (SELECT TOP 1 col1 FROM #PREService)
		DROP TABLE #PREService;
		END
END --@Version <= 10.5

IF @Version > 10.5
BEGIN

		SELECT @ServiceStatus = 
			CASE WHEN [status] = 4 THEN 1
			ELSE 0
			END 
		FROM sys.dm_server_services WHERE servicename LIKE '%Agent%'

END


----INSERT Minion.CheckDBMonitorTshoot (ExecutionDateTime, LocalVar, Value)
----SELECT @ExecutionDateTime, '@Version', CAST(@Version AS VARCHAR(10))
----INSERT Minion.CheckDBMonitorTshoot (ExecutionDateTime, LocalVar, Value)
----SELECT @ExecutionDateTime, '@RegexCMD', @RegexCMD
----INSERT Minion.CheckDBMonitorTshoot (ExecutionDateTime, LocalVar, Value)
----SELECT @ExecutionDateTime, '@InstanceName', @InstanceName
----INSERT Minion.CheckDBMonitorTshoot (ExecutionDateTime, LocalVar, Value)
----SELECT @ExecutionDateTime, '@ServiceStatus', @ServiceStatus
----INSERT Minion.CheckDBMonitorTshoot (ExecutionDateTime, LocalVar, Value)
----SELECT @ExecutionDateTime, '@Flip', @Flip

				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------
				------------------------------END PRE Service Check-----------------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------BEGIN FLIP ON--------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Flip = 'ON'
BEGIN --@Flip = 'ON'

-------------------------------------------------------------
-------------------------------------------------------------
--------------------BEGIN CHECKDB----------------------------
-------------------------------------------------------------
-------------------------------------------------------------

IF @Module = 'CHECKDB'
BEGIN --@Module = 'CHECKDB'
	IF @ServiceStatus = 1
		BEGIN --@ServiceStatus = 1

			SET @MonitorJobRunning = (SELECT COUNT(*)
			FROM sys.dm_exec_sessions es 
				INNER JOIN msdb.dbo.sysjobs sj 
				ON sj.job_id = CAST(CONVERT( BINARY(16), SUBSTRING(es.program_name , 30, 34), 1) AS UNIQUEIDENTIFIER) 
			WHERE program_name LIKE 'SQLAgent - TSQL JobStep (Job % : Step %)' 
			AND sj.name = 'MinionCheckDBStatusMonitor')

		END --@ServiceStatus = 1

			IF @ServiceStatus = 1
			BEGIN --@ServiceStatus = 1
				IF @MonitorJobRunning = 0
				BEGIN --@MonitorJobRunning = 0
					BEGIN
						EXEC msdb.dbo.sp_start_job 'MinionCheckDBStatusMonitor'
					END
				END --@MonitorJobRunning = 0
	END --@ServiceStatus = 1
END --@Module = 'CHECKDB'

------INSERT Minion.CheckDBMonitorTshoot (ExecutionDateTime, LocalVar, Value)
------SELECT @ExecutionDateTime, '@MonitorJobRunning', @MonitorJobRunning 
-------------------------------------------------------------
-------------------------------------------------------------
--------------------END CHECKDB------------------------------
-------------------------------------------------------------
-------------------------------------------------------------


END --@Flip = 'ON'

------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------END FLIP ON----------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------





------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------BEGIN FLIP OFF-------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------
-------------------------------------------------------------
--------------------BEGIN CHECKDB----------------------------
-------------------------------------------------------------
-------------------------------------------------------------

IF @Module = 'CHECKDB'
BEGIN --@Module = 'CHECKDB'
	IF @ServiceStatus = 1
		BEGIN --@ServiceStatus = 1

			SET @MonitorJobRunning = (SELECT COUNT(*)
			FROM sys.dm_exec_sessions es 
				INNER JOIN msdb.dbo.sysjobs sj 
				ON sj.job_id = CAST(CONVERT( BINARY(16), SUBSTRING(es.program_name , 30, 34), 1) AS UNIQUEIDENTIFIER) 
			WHERE program_name LIKE 'SQLAgent - TSQL JobStep (Job % : Step %)' 
			AND sj.name = 'MinionCheckDBStatusMonitor')

		END --@ServiceStatus = 1


	IF @MonitorJobRunning > 0
	BEGIN --@MonitorJobRunning > 0
		DECLARE @i TINYINT;
		SET @i = 1;
		WHILE @MonitorJobRunning > 0 AND @i <= 5
		BEGIN
			EXEC msdb.dbo.sp_stop_job 'MinionCheckDBStatusMonitor';
			----Give it time to actually stop and get reported to SQL.
			WAITFOR DELAY '00:00:05';
			----We have to check to see if it's actually stopped.
			SET @MonitorJobRunning = (SELECT COUNT(*)
			FROM sys.dm_exec_sessions es 
				INNER JOIN msdb.dbo.sysjobs sj 
				ON sj.job_id = CAST(CONVERT( BINARY(16), SUBSTRING(es.program_name , 30, 34), 1) AS UNIQUEIDENTIFIER) 
			WHERE program_name LIKE 'SQLAgent - TSQL JobStep (Job % : Step %)' 
			AND sj.name = 'MinionCheckDBStatusMonitor')

			SET @i = @i + 1;
		END
	END --@MonitorJobRunning > 0
END --@Module = 'CHECKDB'

-------------------------------------------------------------
-------------------------------------------------------------
--------------------END CHECKDB------------------------------
-------------------------------------------------------------
-------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------END FLIP OFF---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

GO
