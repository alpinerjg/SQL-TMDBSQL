SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [Minion].[CheckDBThreadCreator]
(
@ExecutionDateTime datetime,
@DBName NVARCHAR(400),
@OpName varchar(50),
@ConcurrentProcesses TINYINT,
@DBInternalThreads TINYINT,
@Schemas varchar(max),
@Tables varchar(max),
@StartJobs BIT = 1,
@StartJobDelaySecs VARCHAR(20) = '0:00:02'
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
                
                EXEC Minion.HELP 'CHECKDB', 'Minion.CheckDBThreadCreator';


PURPOSE: 


WALKTHROUGH: 
      1. 


CONVENTIONS:
    
    
TABLES: 
                

EXAMPLE EXECUTIONS:


REVISION HISTORY:
                

--***********************************************************************************/ 


DECLARE @i TINYINT,
		@JobThreadSQL VARCHAR(max),
		@JobName VARCHAR(500),
		@JobStepSQL VARCHAR(max),
		@JobStartSQL VARCHAR(2000);

SET @i = 1;

IF @Schemas IS NULL
	BEGIN
		SET @Schemas = 'NULL';
	END

IF @Tables IS NULL
	BEGIN
		SET @Tables = 'NULL';
	END


--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------BEGIN CheckDB-----------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
IF UPPER(@OpName) IS NULL
BEGIN --CHECKDB
	WHILE @i <= @ConcurrentProcesses
	BEGIN --While

---------------------------------------------------------------
---------------------------------------------------------------

SET @JobStepSQL = '
DECLARE @ShouldContinue BIT,
		@currID INT,
		@currDB VARCHAR(400),
		@ExecutionDateTime datetime,
		@OpName varchar(25),
		@DBInternalThreads TINYINT,
		@CheckTableJobRunning TINYINT,
		@jobId binary(16),
		@Schemas VARCHAR(max),
		@Tables VARCHAR(max);

SET @ExecutionDateTime = ''''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''''';
SET @ShouldContinue = 1;
SET @Schemas = ''''' + @Schemas + ''''';
SET @Tables = ''''' + @Tables + ''''';

If @Schemas = ''''NULL''''
	BEGIN
		SET @Schemas = NULL;
	END

If @Tables = ''''NULL''''
	BEGIN
		SET @Tables = NULL;
	END

WHILE @ShouldContinue = 1
	BEGIN --Main WHILE

----We need to get the next ID in line but we also need to make sure the row is locked the entire time so that other threads
----do not come in and grab the same row.
			BEGIN TRANSACTION

				SET @currID = (SELECT TOP 1 ID FROM Minion.CheckDBThreadQueue WITH(XLOCK) WHERE ExecutionDateTime = @ExecutionDateTime AND Processing = 0 ORDER BY ID ASC);

				UPDATE Minion.CheckDBThreadQueue WITH(XLOCK) 
				SET Processing = 1,
					ProcessingThread = ' + CAST(@i AS VARCHAR(5)) + ' WHERE ID = @currID;

			COMMIT TRANSACTION

			IF @currID IS NOT NULL
				BEGIN
					SELECT @currDB = DBName,
							@OpName = OpName,
							@DBInternalThreads = DBInternalThreads
					FROM Minion.CheckDBThreadQueue 
					WHERE ID = @currID;

				---------------------------------------------------------------------
				--------------------------BEGIN CHECKDB------------------------------
				---------------------------------------------------------------------
				IF UPPER(@OpName) = ''''CHECKDB''''
					BEGIN
					EXEC Minion.CheckDB @currDB,  @OpName, 0, @ExecutionDateTime, 0, ' + CAST(@i AS VARCHAR(5)) + '
					END
				END
				---------------------------------------------------------------------
				---------------------------END CHECKDB-------------------------------
				---------------------------------------------------------------------


				---------------------------------------------------------------------
				--------------------------BEGIN CHECKTABLE---------------------------
				---------------------------------------------------------------------
				IF UPPER(@OpName) = ''''CHECKTABLE''''
					BEGIN --CHECKTABLE

							-------------------------------------------
							------------BEGIN PrepOnly Run-------------
							-------------------------------------------
						EXEC Minion.CheckDBCheckTable 
						@DBName = @currDB, 
						@Schemas = @Schemas,  
						@Tables = @Tables, 
						@StmtOnly = 0, 
						@PrepOnly = 1,
						@RunPrepped = 0,
						@ExecutionDateTime = @ExecutionDateTime,
						@Thread = 0;
							-------------------------------------------
							------------END PrepOnly Run---------------
							-------------------------------------------


							-------------------------------------------
							------------BEGIN Create Threads-----------
							-------------------------------------------
						BEGIN --Create Threads
							EXEC Minion.CheckDBThreadCreator 
							@ExecutionDateTime = @ExecutionDateTime, 
							@DBName = @currDB, 
							@OpName = ''''CHECKTABLE'''', 
							@ConcurrentProcesses = 1, 
							@DBInternalThreads = @DBInternalThreads, 
							@Schemas = NULL, 
							@Tables = NULL, 
							@StartJobs = 1, 
							@StartJobDelaySecs = ''''0:00:02''''
						END --Create Threads
							-------------------------------------------
							------------END Create Threads-------------
							-------------------------------------------


							-------------------------------------------
							------------BEGIN Thread Waiter------------
							-------------------------------------------
						----We need to wait for all the thread jobs to finish.
						SET @CheckTableJobRunning = 1; -- Initial set.
						WHILE @CheckTableJobRunning > 0
							BEGIN --Job Running Loop
								SET @CheckTableJobRunning = (SELECT COUNT(*)
								FROM sys.dm_exec_sessions es 
									INNER JOIN msdb.dbo.sysjobs sj 
									ON sj.job_id = CAST(CONVERT( BINARY(16), SUBSTRING(es.program_name , 30, 34), 1) AS UNIQUEIDENTIFIER) 
								WHERE program_name LIKE ''''SQLAgent - TSQL JobStep (Job % : Step %)'''' 
								AND sj.name LIKE ''''MinionCheckDB-CHECKTABLE-'''' + @currDB +  ''''-ThreadWorker-%'''')

								WAITFOR DELAY ''''0:0:05''''
							END --Job Running Loop

							-------------------------------------------
							------------END Thread Waiter--------------
							-------------------------------------------

									---------------------------------------
									------------BEGIN Delete Jobs----------
									---------------------------------------
							IF @CheckTableJobRunning = 0
								BEGIN --@CheckTableJobRunning = 0
									--------Cleanup jobs from current run. The jobs are only meant to be temp so we are assuming we are ending cleanly here which means we are free to kill them.
									--------If something happens and they do not get cleaned up then they are deleted above so the next run starts clean. 
									WHILE (1=1)
									BEGIN --Delete Jobs WHILE Loop
										SET @jobId = NULL
										SELECT TOP 1 @jobId = job_id FROM msdb.dbo.sysjobs WHERE (name like ''''MinionCheckDB-CHECKTABLE-'''' + @currDB +  ''''-ThreadWorker-%'''') 

										IF @@ROWCOUNT = 0
											BREAK

										IF (@jobId IS NOT NULL) 
											BEGIN     
												EXEC msdb.dbo.sp_delete_job @jobId 
											END 
									END --Delete Jobs WHILE Loop
									---------------------------------------
									------------END Delete Jobs------------
									---------------------------------------
									BREAK;
							END --@CheckTableJobRunning = 0

					END --CHECKTABLE

				---------------------------------------------------------------------
				---------------------------END CHECKTABLE----------------------------
				---------------------------------------------------------------------

			IF @currID IS NULL
			BEGIN --No more DBs.
				--SET @ShouldContinue = 0;
				BREAK;
			END --No more DBs.

END --Main WHILE
'	


			SET @JobName = 'MinionCheckDBThreadWorker-' + CAST(@i AS VARCHAR(5));

			SET @JobThreadSQL = '
			BEGIN TRANSACTION
			DECLARE @jobId BINARY(16)

			EXEC msdb.dbo.sp_add_job @job_name=N''' + @JobName +  ''', 
					@enabled=1, 
					@notify_level_eventlog=0, 
					@notify_level_email=0, 
					@notify_level_netsend=0, 
					@notify_level_page=0, 
					@delete_level=0, 
					@description=N''No description available.'', 
					@category_name=N''[Uncategorized (Local)]'', 
					@job_id = @jobId OUTPUT

			EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run CheckDB'', 
					@step_id=1, 
					@cmdexec_success_code=0, 
					@on_success_action=1, 
					@on_success_step_id=0, 
					@on_fail_action=2, 
					@on_fail_step_id=0, 
					@retry_attempts=0, 
					@retry_interval=0, 
					@os_run_priority=0, @subsystem=N''TSQL'', 
					@command=N''' + @JobStepSQL + ''',
					@database_name=N''' + DB_NAME() + ''', 
					@flags=0
			EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
			COMMIT TRANSACTION
			GO
			'
			EXEC(@JobThreadSQL)
			--PRINT @JobThreadSQL
		SET @i = @i + 1;
		SET @JobStartSQL = 'EXEC msdb.dbo.sp_start_job @job_name = ''' + @JobName + ''''

		IF @StartJobs = 1
			BEGIN
				EXEC(@JobStartSQL)
			END	

		IF @StartJobDelaySecs IS NOT NULL
			BEGIN
				WAITFOR DELAY @StartJobDelaySecs
			END

	END --While

END --CHECKDB
						--------------------------------------------------------------
						--------------------------------------------------------------
						-----------------BEGIN MT CheckTable--------------------------
						--------------------------------------------------------------
						--------------------------------------------------------------

IF UPPER(@OpName) = 'CHECKTABLE'
	BEGIN --CHECKTABLE
	
							--------------------------------------------------------------------------------------------------------
							--------------------------------------------------------------------------------------------------------
							-------------------------------BEGIN MultiThread Job Create---------------------------------------------
							--------------------------------------------------------------------------------------------------------
							--------------------------------------------------------------------------------------------------------
								BEGIN --MultiThread Job Create

							--!!!!!!!!!!!!!!ExecutionDateTime below needs to be made Int'l.!!!!!!!!!!!!!!!!!!!!!!!!!!!

							SET @i = 1;

							WHILE @i <= @DBInternalThreads
							BEGIN --While

SET @JobStepSQL = '
DECLARE @ExecutionDateTime datetime,
		@DBName nvarchar(400);
SET @ExecutionDateTime = ''''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''''';
SET @DBName = ''''' + @DBName + ''''';

EXEC Minion.CheckDBCheckTable 
@DBName = @DBName, 
@Schemas = NULL, 
@Tables = NULL, 
@StmtOnly = 0, 
@PrepOnly = 0, ' + --CAST(@PrepOnly AS VARCHAR(5)) + ',' +
'
@RunPrepped = 1, ' + --CAST(@i AS VARCHAR(5)) + ',' +
'
@ExecutionDateTime = @ExecutionDateTime,
@Thread = ' + CAST(@i AS VARCHAR(5)) + ';'
		
									SET @JobName = 'MinionCheckDB-CHECKTABLE-' + @DBName +  '-ThreadWorker-' + CAST(@i AS VARCHAR(5));

									SET @JobThreadSQL = '
									BEGIN TRANSACTION
									DECLARE @jobId BINARY(16)

									EXEC msdb.dbo.sp_add_job @job_name=N''' + @JobName +  ''', 
											@enabled=1, 
											@notify_level_eventlog=0, 
											@notify_level_email=0, 
											@notify_level_netsend=0, 
											@notify_level_page=0, 
											@delete_level=0, 
											@description=N''No description available.'', 
											@category_name=N''[Uncategorized (Local)]'', 
											@job_id = @jobId OUTPUT

									EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run CheckDB'', 
											@step_id=1, 
											@cmdexec_success_code=0, 
											@on_success_action=1, 
											@on_success_step_id=0, 
											@on_fail_action=2, 
											@on_fail_step_id=0, 
											@retry_attempts=0, 
											@retry_interval=0, 
											@os_run_priority=0, @subsystem=N''TSQL'', 
											@command=N''' + @JobStepSQL + ''',
											@database_name=N''' + DB_NAME() + ''', 
											@flags=0
									EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
									COMMIT TRANSACTION
									GO
									'
								EXEC(@JobThreadSQL)
								SET @i = @i + 1;
								SET @JobStartSQL = 'EXEC msdb.dbo.sp_start_job @job_name = ''' + @JobName + ''''
								--PRINT @JobStartSQL
								EXEC(@JobStartSQL)	
								WAITFOR DELAY '0:0:02'
							END --While

							END --MultiThread Job Create
END --CHECKTABLE


						--------------------------------------------------------------
						--------------------------------------------------------------
						-----------------END MT CheckTable----------------------------
						--------------------------------------------------------------
						--------------------------------------------------------------


GO
