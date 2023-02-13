SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[BackupStatusMonitor]
	(
	  @Interval VARCHAR(20) = '00:00:05'
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
	EXEC  [Minion].[BackupStatusMonitor]
	  @Interval = '0:0:05';

Revision History:
	

***********************************************************************************/
AS 
	CREATE TABLE #BackupPct
		(
		  DBName SYSNAME ,
		  Pct TINYINT
		);


	WHILE 1 = 1 
		BEGIN --While

			BEGIN
				UPDATE	BL
				SET		BL.PctComplete = ER.percent_complete ,
						BL.STATUS = 'Backup running'
				FROM	Minion.BackupLogDetails BL
						INNER JOIN sys.dm_exec_requests ER WITH ( NOLOCK ) ON BL.DBName = DB_NAME(ER.database_id)
				WHERE	BL.ExecutionDateTime IN (
						SELECT	MAX(ExecutionDateTime)
						FROM	Minion.BackupLogDetails AS BL2
						WHERE	BL2.DBName = BL.DBName
								AND DB_NAME(ER.database_id) = BL.DBName
								AND ER.command LIKE 'BACKUP%'
								AND BL.STATUS LIKE 'Backup running%'
								AND BL2.STATUS LIKE 'Backup running%' );
			END
			WAITFOR DELAY @Interval;
		END --While






GO
