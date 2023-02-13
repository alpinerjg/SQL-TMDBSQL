SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[DBMaintLogToMinion]
(
@Module VARCHAR(25),
@DBName NVARCHAR(400),
@MinionTriggerPath NVARCHAR(2000),
@ExecutionDateTime datetime,
@ServerName VARCHAR(150),
@Folder VARCHAR(50)
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
                
                EXEC Minion.HELP 'CHECKDB', 'Minion.CheckDB';


PURPOSE: 


WALKTHROUGH: 
      1. 


CONVENTIONS:
    
    
TABLES: 
                

EXAMPLE EXECUTIONS:
Minion.DBMaintLogToMinion 'checkdb', 'CurrentMB', '\\2014test\checkdblog\', '2017-06-21 08:17:30.847', 'bendycon', 'CheckDBMaster'

REVISION HISTORY:
                

--***********************************************************************************/ 


------------------------------------------------------------------------
-------------------BEGIN CHECKDB----------------------------------------
------------------------------------------------------------------------

DECLARE @TriggerFile NVARCHAR(4000),
		@ExecutionDateTimeTxt VARCHAR(30);

SET @ExecutionDateTimeTxt = CONVERT(VARCHAR(25), @ExecutionDateTime, 21)
IF @Folder IS NULL
	BEGIN
		SET @Folder = '';
	END

IF @ServerName LIKE '%\%'
BEGIN --Begin @ServerLabel
    SET @ServerName = REPLACE(@ServerName, '\', '~')
END	--End @ServerLabel

IF UPPER(@Module) = 'CHECKDB'
	BEGIN --CheckDB
		IF UPPER(@Folder) = 'CHECKDB'
			BEGIN --CheckDB Folder
				SET @TriggerFile = 'Powershell "''' + ''''''
					+ @ExecutionDateTimeTxt + ''''''''
					+ ' | out-file ''' + @MinionTriggerPath + @Folder + '\' + @ServerName + '.'
					+ @DBName + ''' -append"' 
			END --CheckDB Folder

		IF UPPER(@Folder) = 'CHECKDBMASTER'
			BEGIN --CheckDBMaster Folder
				SET @TriggerFile = 'Powershell "''' + ''''''
					+ @ExecutionDateTimeTxt + ''''''''
					+ ' | out-file "' + @MinionTriggerPath + 'CheckDBMaster\' + @ServerName
					+ '" -append"' 
			END --CheckDBMaster Folder
	END --CheckDB
------------------------------------------------------------------------
-------------------END CHECKDB------------------------------------------
------------------------------------------------------------------------

------------------------------------------------------------------------
-------------------BEGIN Run--------------------------------------------
------------------------------------------------------------------------

----SELECT @ServerName, @MinionTriggerPath, @TriggerFile AS TriggerFile
EXEC xp_cmdshell @TriggerFile, no_output;
------------------------------------------------------------------------
-------------------END Run----------------------------------------------
------------------------------------------------------------------------
GO
