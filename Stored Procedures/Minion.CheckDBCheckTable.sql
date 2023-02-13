SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[CheckDBCheckTable]
(

@DBName NVARCHAR(400),
@Schemas NVARCHAR(max) = NULL, --Can be a list.  Will check all tables in this schema.
@Tables NVARCHAR(max) = NULL, --Does all tables
@StmtOnly BIT = 0,
@PrepOnly BIT = 0,
@RunPrepped BIT = 0,
@ExecutionDateTime DATETIME = NULL,
@Thread TINYINT	= 0,
@Debug BIT = 0

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
                
                EXEC Minion.HELP 'CHECKDB', 'Minion.CheckDBCheckTable';


PURPOSE: 


WALKTHROUGH: 
      1. 


CONVENTIONS:
    
    
TABLES: 
                

EXAMPLE EXECUTIONS:


REVISION HISTORY:
                

--***********************************************************************************/ 


SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;
DECLARE 
		@BeginTime DATETIME,
		@EndTime DATETIME,
		@Error BIT,
		@ErrorNum INT,
		@ErrorMess VARCHAR(500),
		@TriggerFile VARCHAR(8000),
		@CheckDBRetWks int,
		@DBSize DECIMAL(18, 2),
        @DBSizeCMD VARCHAR(4000),
        @SpaceType VARCHAR(20),
		@CheckDBSQL nvarchar(4000),
		@CheckDBRunSQL nvarchar(4000),
		@CheckDBSettingLevel TINYINT,
		@TableSettingLevel TINYINT,
		@Port VARCHAR(10),
		@Exclude bit,
		@GroupOrder int,
		@GroupDBOrder int,
		@OpLevel varchar(50),
		@NoIndex bit,
		@RepairOption varchar(50),
		@RepairOptionAgree bit,
		@WithRollback VARCHAR(50),
		@AllErrorMsgs bit,
		@ExtendedLogicalChecks bit,
		@NoInfoMsgs bit,
		@IsTabLock bit,
		@IntegrityCheckLevel varchar(50),
		@TuningSettingLevel smallint,
		@TuningTypeLevel SMALLINT,
		@CheckTableDOP tinyint,
		@DisableDOP bit,
		@CreateSnapshot bit,
		@LockDBMode varchar(50),
		@ResultMode VARCHAR(50),
		@HistRetDays int,
		@PushToMinion bit,
		@MinionTriggerPath varchar(1000),
		@AutoRepair varchar(50),
		@AutoRepairTime varchar(25),
		@Version VARCHAR(50),
        @Edition VARCHAR(15),
        @OnlineEdition BIT,
		@ServerInstance VARCHAR(200),
		@LogDBType VARCHAR(6),
		@IsRepair BIT,
		@SchemasRAW NVARCHAR(max),
		@currTable NVARCHAR(200),
		@currSchema NVARCHAR(200),
		@DefaultSchema NVARCHAR(200),
		@OpRAW VARCHAR(2000),
		@SnapshotCMD NVARCHAR(max),
		@CurrentSnapshotDBName NVARCHAR(400),
		@CurrentPrevSnapshotDBName NVARCHAR(400),
		@CheckDBOpBeginTime datetime,
		@CheckDBOpEndTime datetime,
		@CheckDBOpRunTimeInSecs INT,
		@CheckDBLogDetailsID INT,
		@DeleteFinalSnapshot BIT,
		@SnapshotRetDeviation INT,
		@SnapshotRetMins INT,
		@NETBIOSName VARCHAR(128),
		@IsClustered BIT,
		@DBIsInAG BIT,
		@DBIsInAGQuery NVARCHAR(4000),
		@IsPrimaryReplica BIT,
		@IsPrimaryReplicaQuery NVARCHAR(4000),
		@CheckDBAutoSettingLevel TINYINT,
		@AutoThresholdMethod VARCHAR(20),
		@AutoThresholdType VARCHAR(20),
		@AutoThresholdValue INT,
		@DBPreCode NVARCHAR(max),
		@DBPostCode nvarchar(max),
		@DBPreCodeStartDateTime DATETIME,
		@DBPostCodeStartDateTime DATETIME,
		@DBPreCodeEndDateTime DATETIME,
		@DBPostCodeEndDateTime DATETIME,
		@TablePreCode NVARCHAR(max),
		@TablePostCode NVARCHAR(max),
		@StmtPrefix NVARCHAR(500),
		@StmtSuffix NVARCHAR(500),
		@TablePreCodeStartDateTime DATETIME,
		@TablePostCodeStartDateTime DATETIME,
		@TablePreCodeEndDateTime DATETIME,
		@TablePostCodeEndDateTime DATETIME,
		@LastMinionCheckDBDate DATETIME,
		@LastMinionCheckDBResult VARCHAR(MAX),
		@PreCMD VARCHAR(1000),
		@SnapshotErrors NVARCHAR(max),
		@TotalCMD VARCHAR(8000),
		@PreppedExecutionDateTime DATETIME,
		@SnapshotDBName NVARCHAR(400),
		@SnapshotCreationOwner TINYINT,
		@PreferredServer VARCHAR(150),
		@TotalSnapshotSize BIGINT,
		@LogSkips BIT;

DECLARE @Op CHAR(10);
SET @Op = 'CHECKTABLE';
---------------------------------------------------
---------------------------------------------------
---------------BEGIN Exec Date---------------------
---------------------------------------------------
---------------------------------------------------
----Here we need to choose the right ExecutionDateTime.
----If it's a regular run then we just need to set the var to getdate.
----If it's a prepped run then we need to take a little more care to make sure that the 
----ExecutionDateTime and PreppedExecutionDateTime are what they should be.
----The table cursor uses the PreppedExecutionDateTime and since you could officially
----prep the run at any time, then we have to keep it separate from the ExecutionDateTime.
----For example, if you prepped it 2 days ago, you don't want the ExecutionDateTime in the log showing
----up as that time because it was run now, not when it was prepped.  So we have to take care about 
----which of these times we use.

IF @ExecutionDateTime IS NOT NULL AND @RunPrepped = 0
	BEGIN
		SET @PreppedExecutionDateTime = @ExecutionDateTime;
	END

IF @ExecutionDateTime IS NULL AND @RunPrepped = 0
	BEGIN
		SET @ExecutionDateTime = GETDATE();
		SET @PreppedExecutionDateTime = @ExecutionDateTime;
	END

IF @RunPrepped = 1 
BEGIN
	SET @PreppedExecutionDateTime = (SELECT MAX(ExecutionDateTime) FROM Minion.CheckDBCheckTableThreadQueue WHERE DBName = @DBName);

IF @ExecutionDateTime IS NULL
	BEGIN
		SET @ExecutionDateTime = GETDATE();
		SET @PreppedExecutionDateTime = @ExecutionDateTime;
	END
END

 SET @ServerInstance = @@ServerName;
 
---------------------------------------------------
---------------------------------------------------
---------------END Exec Date-----------------------
---------------------------------------------------
---------------------------------------------------

 DECLARE @MaintDB sysname;
SET @MaintDB = DB_NAME();
SET @NETBIOSName = CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS VARCHAR(128));
SET @IsClustered = CAST(SERVERPROPERTY('IsClustered') AS VARCHAR(128));
------------------------BEGIN Set DBType---------------------------------
        IF @DBName IN ('master', 'msdb', 'model', 'distribution')
            SET @LogDBType = 'System'

        IF @DBName NOT IN ('master', 'msdb', 'model', 'distribution')
            SET @LogDBType = 'User'
------------------------END Set DBType-----------------------------------



---------------------------------------------------------------------------------
------------------ BEGIN AG Info-------------------------------------------------
---------------------------------------------------------------------------------
SET @DBIsInAG = 0
		IF @Version >= 11 AND @OnlineEdition = 1
			BEGIN --@Version >= 11
					--- We HAVE to run this select statement as an EXEC; even with the IF, this'd generate an error on SQL 05/08.

						SET @DBIsInAGQuery = ('INSERT Minion.Work(ExecutionDateTime, Module, DBName, Param, SPName, Value) SELECT ' 
						+ '''' + CONVERT(VARCHAR(25), @ExecutionDateTime, 121) + '''' + ', ''CHECKDB'', ''' + @DBName + ''', '
						+ ', ''@DBIsInAG'', ''CheckDB''' + ', COUNT(replica_id) from sys.databases with(nolock) where Name = '''
						+ @DBName + ''' AND replica_id IS NOT NULL')
						EXEC (@DBIsInAGQuery)

						SET @DBIsInAG = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'CHECKDB' AND DBName = @DBName  AND SPName = 'CheckDBMaster' AND Param = '@DBIsInAG')
						IF @DBIsInAG IS NULL
							BEGIN
								SET @DBIsInAG = 0
							END

					----DELETE FROM @AGResults; -- We're in a loop; clear results each time.
					--- We HAVE to run this select statement as an EXEC; even with the IF, this'd generate an error on SQL 05/08.
					IF @DBIsInAG = 1
					BEGIN --@DBIsInAG = 1			
						SET @IsPrimaryReplicaQuery = ('INSERT Minion.Work(ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value) SELECT '
						+ '''' + CONVERT(VARCHAR(25), @ExecutionDateTime, 121) + '''' + ', ''Backup'', ''' + @DBName + ''', '
						+ ', ''@IsPrimaryReplica'', ''CheckDB''' + ', count(*)        
						FROM sys.databases dbs with(nolock) INNER JOIN sys.dm_hadr_availability_replica_states ars ON dbs.replica_id = ars.replica_id WHERE dbs.name = '''
						+ @DBName + ''' AND ars.role = 1')
						EXEC (@IsPrimaryReplicaQuery)

						SET @IsPrimaryReplica = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'CHECKDB' AND DBName = @DBName AND SPName = 'CheckDBMaster' AND Param = '@IsPrimaryReplica')
							IF @IsPrimaryReplica IS NULL
							BEGIN
								SET @IsPrimaryReplica = 0
							END
					END --@DBIsInAG = 1
			END --@Version >= 11
---------------------------------------------------------------------------------
------------------ END AG Info---------------------------------------------------
---------------------------------------------------------------------------------


-------------------------------------------------------------------------------
---------------- BEGIN Get Version Info----------------------------------------
-------------------------------------------------------------------------------

        SELECT
                @Version = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(15)),
                                CHARINDEX('.',
                                          CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(15)),
                                          1) - 1)
        SELECT @Edition = CAST(SERVERPROPERTY('Edition') AS VARCHAR(25));

        IF @Edition LIKE '%Enterprise%'
            OR @Edition LIKE '%Developer%'
            BEGIN
                SET @OnlineEdition = 1
            END
	
        IF @Edition NOT LIKE '%Enterprise%'
            AND @Edition NOT LIKE '%Developer%'
            BEGIN
                SET @OnlineEdition = 0
            END	

---------------------------------------------------------------------------------
------------------ END Get Version Info------------------------------------------
---------------------------------------------------------------------------------


CREATE TABLE #SnapshotDeleteResults
    (
        ID INT IDENTITY(1, 1),
        col1 VARCHAR(MAX) COLLATE DATABASE_DEFAULT
    )

CREATE TABLE #TCheckDB
    (
        ID INT IDENTITY(1, 1),
        col1 VARCHAR(MAX) COLLATE DATABASE_DEFAULT
    )

CREATE TABLE #CheckDBSettingsDB
(
	 ID   int  IDENTITY(1,1) NOT NULL,
	 Port   int  NULL,
	 Exclude   bit  NULL,
	 GroupOrder   int  NULL,
	 GroupDBOrder   int  NULL,
	 OpLevel   varchar (50) COLLATE DATABASE_DEFAULT NULL,
	 NoIndex   bit  NULL,
	 RepairOption   varchar (50) COLLATE DATABASE_DEFAULT NULL,
	 RepairOptionAgree   bit  NULL,
	 WithRollback VARCHAR(50) COLLATE DATABASE_DEFAULT NULL,
	 AllErrorMsgs   bit  NULL,
	 ExtendedLogicalChecks   bit  NULL,
	 NoInfoMsgs   bit  NULL,
	 IsTabLock   bit  NULL,
	 IntegrityCheckLevel   varchar (50) COLLATE DATABASE_DEFAULT NULL,
	 CheckTableThresholdInMB   bigint  NULL,
	 CheckTableDOP   tinyint  NULL,
	 DisableDOP   bit  NULL,
	 PreferredServer VARCHAR(150) COLLATE DATABASE_DEFAULT NULL,
	 CreateSnapshot   bit  NULL,
	 LockDBMode   varchar (50) COLLATE DATABASE_DEFAULT NULL,
	 ResultMode varchar (50) COLLATE DATABASE_DEFAULT NULL,
	 HistRetDays   int  NULL,
	 PushToMinion   varchar (25) COLLATE DATABASE_DEFAULT NULL,
	 MinionTriggerPath   varchar (1000) COLLATE DATABASE_DEFAULT NULL,
	 AutoRepair   varchar (50) COLLATE DATABASE_DEFAULT NULL,
	 AutoRepairTime   varchar (25) COLLATE DATABASE_DEFAULT NULL,
	 DefaultSchema VARCHAR(200) COLLATE DATABASE_DEFAULT NULL,
	 DBPreCode NVARCHAR(max) COLLATE DATABASE_DEFAULT NULL,
	 DBPostCode NVARCHAR(max) COLLATE DATABASE_DEFAULT NULL,
	 TablePreCode NVARCHAR(max) COLLATE DATABASE_DEFAULT NULL,
	 TablePostCode NVARCHAR(max) COLLATE DATABASE_DEFAULT NULL,
	 StmtPrefix NVARCHAR(500) COLLATE DATABASE_DEFAULT NULL,
	 StmtSuffix NVARCHAR(500) COLLATE DATABASE_DEFAULT NULL,
	 BeginTime VARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
	 EndTime VARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
	 DayOfWeek VARCHAR(10) COLLATE DATABASE_DEFAULT NULL,
	 IsActive   bit  NULL,
	 Comment   varchar (1000) COLLATE DATABASE_DEFAULT NULL
)

CREATE TABLE #CheckDBSnapshot(
[ID] [int] IDENTITY(1,1) NOT NULL,
[SnapshotDBName] NVARCHAR(200) COLLATE DATABASE_DEFAULT NULL,
[FileID] [int] NULL,
[TypeDesc] [varchar](25) COLLATE DATABASE_DEFAULT NULL,
[Name] [nvarchar](200) COLLATE DATABASE_DEFAULT NULL,
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
[MaxSizeInKB] [bigint] NULL,
)

CREATE TABLE #SnapshotResults
	(
		ID INT IDENTITY(1, 1),
		col1 NVARCHAR(MAX) COLLATE DATABASE_DEFAULT
	)

CREATE TABLE #CheckDBResults (ID INT IDENTITY(1,1), col1 VARCHAR(max));

DECLARE @DBTempTable VARCHAR(5),
		@DBTempTableDate VARCHAR(15);
SET @DBTempTableDate = CONVERT(VARCHAR(4), YEAR(@ExecutionDateTime)) + CONVERT(VARCHAR(4), MONTH(@ExecutionDateTime)) + CONVERT(VARCHAR(4), DAY(@ExecutionDateTime)) + CONVERT(VARCHAR(4), DATEPART(HOUR,@ExecutionDateTime)) + DATEPART(MINUTE,@ExecutionDateTime) + DATEPART(SECOND,@ExecutionDateTime)
SET @DBTempTable = SUBSTRING(REPLACE(@DBName, ' ', ''), 1, 5)

---------------------------------------------------------------------------------
--------------------------BEGIN Settings Level-----------------------------------
---------------------------------------------------------------------------------






--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
-------------------------------BEGIN Settings-----------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
 ----Find out if the settings will come from the DB level or from the default level.

DECLARE @SettingID INT;
EXEC Minion.DBMaintDBSettingsGet 'CHECKDB', @DBName, 'CHECKTABLE', @SettingID = @SettingID OUTPUT;

SELECT TOP 1
@Port = Port,
@Exclude = Exclude,
@GroupOrder = GroupOrder,
@GroupDBOrder = GroupDBOrder,
@OpLevel = OpLevel,
@NoIndex = NoIndex,
@RepairOption = RepairOption,
@RepairOptionAgree = RepairOptionAgree,
@WithRollback = WithRollback,
@AllErrorMsgs = AllErrorMsgs,
@ExtendedLogicalChecks = ExtendedLogicalChecks,
@NoInfoMsgs = NoInfoMsgs,
@IsTabLock = IsTabLock,
@IntegrityCheckLevel = IntegrityCheckLevel,
@DisableDOP = DisableDOP,
@PreferredServer = PreferredServer,
@LockDBMode = LockDBMode,
@ResultMode = ResultMode,
@HistRetDays = HistRetDays,
@PushToMinion = PushToMinion,
@MinionTriggerPath = MinionTriggerPath,
@AutoRepair = AutoRepair,
@AutoRepairTime = AutoRepairTime,
@DefaultSchema = DefaultSchema,
@DBPreCode = DBPreCode,
@DBPostCode = DBPostCode,
@TablePreCode = TablePreCode,
@TablePostCode = TablePostCode,
@StmtPrefix = StmtPrefix,
@StmtSuffix = StmtSuffix,
@LogSkips = LogSkips
FROM Minion.CheckDBSettingsDB
WHERE ID = @SettingID;

------------------------BEGIN Set Port--------------------------
----IF @ServerInstance NOT LIKE '%\%'
----	BEGIN
----		SET @Port = CASE WHEN @Port IS NULL AND @ServerInstance NOT LIKE '%.%' THEN '' --',' + '1433'
----						 WHEN @Port IS NULL AND @ServerInstance LIKE '%.%' THEN '' --',' + '1433'
----						 WHEN @Port = '1433' THEN '' --',' + '1433'
----						 WHEN @Port IS NOT NULL AND @Port <> '1433' AND @ServerInstance NOT LIKE '%.%' THEN ',' + @Port
----						 WHEN @Port IS NOT NULL AND @ServerInstance LIKE '%.%' THEN ''
----						 END
----	END
----IF @ServerInstance LIKE '%\%'
----	BEGIN
----			SET @Port = CASE WHEN @Port IS NULL THEN ''
----							 WHEN @Port IS NOT NULL AND @Port <> '1433' THEN ',' + @Port
----							 END
----	END
------------------------BEGIN Set Port--------------------------


 --------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------------------------
 -------------------------------END Settings-------------------------------------------------
 --------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------------------------




-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
----------------------------------BEGIN Dynamic Tuning-----------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

---------0 = MinionDefault, >0 = DBName
	SET @TuningSettingLevel = ( SELECT	COUNT(*)
								FROM	Minion.CheckDBSettingsSnapshot
								WHERE	DBName = @DBName
										AND UPPER(OpName) = UPPER(@Op)
										AND IsActive = 1
							  )

						--Tuning
                        IF @TuningSettingLevel = 0
                            BEGIN --@TuningTypeLevel = 0
                                SELECT TOP 1
                                       -- @SpaceType = SpaceType,
										@CreateSnapshot = CustomSnapshot,
										@SnapshotRetMins = SnapshotRetMins,
										@SnapshotRetDeviation = SnapshotRetDeviation,
										@DeleteFinalSnapshot = ISNULL(DeleteFinalSnapshot, 0)
                                    FROM
                                        Minion.CheckDBSettingsSnapshot
                                    WHERE
                                        DBName = 'MinionDefault'
                                        AND UPPER(OpName) = UPPER(@Op)
                                        AND IsActive = 1


                            END --@TuningTypeLevel = 0

                        IF @TuningSettingLevel > 0
                            BEGIN --@TuningTypeLevel > 0
                                SELECT TOP 1
                                        --@SpaceType = SpaceType,
										@CreateSnapshot = CustomSnapshot,
										@SnapshotRetMins = SnapshotRetMins,
										@SnapshotRetDeviation = SnapshotRetDeviation,
										@DeleteFinalSnapshot = ISNULL(DeleteFinalSnapshot, 0)
                                    FROM
                                        Minion.CheckDBSettingsSnapshot
                                    WHERE
                                        DBName = @DBName
                                        AND UPPER(OpName) = UPPER(@Op)
                                        AND IsActive = 1

                            END --@TuningTypeLevel > 0


-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
----------------------------------END Dynamic Tuning-------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------BEGIN DBPreCode-------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------	

        IF @StmtOnly = 0
            BEGIN -- @StmtOnly = 0
				IF @PrepOnly = 0
				BEGIN --@PrepOnly = 0-DBPreCode
-----BEGIN Log------

                IF @DBPreCode IS NOT NULL
                    BEGIN -- @DBPreCode
                        IF @StmtOnly = 0
                            BEGIN -- @StmtOnly = 0
                                SET @DBPreCodeStartDateTime = GETDATE();

                                ----BEGIN
                                ----    UPDATE Minion.CheckDBLogDetails
                                ----        SET
                                ----            STATUS = 'DB Precode running',
                                ----            DBPreCodeStartDateTime = @DBPreCodeStartDateTime,
                                ----            DBPreCode = @DBPreCode
                                ----        WHERE
                                ----            ID = @CheckDBLogDetailsID;
                                ----END
                            END -- @StmtOnly = 0
                    END -- @@DBPreCode
------END Log-------

                IF @DBPreCode IS NOT NULL
                    BEGIN -- @DBPreCode
-----------------BEGIN Log DBPreCode------------------
                        ----UPDATE Minion.CheckDBLogDetails
                        ----    SET
                        ----        DBPreCode = @DBPreCode,
                        ----        DBPreCodeStartDateTime = @DBPreCodeStartDateTime
                        ----    WHERE
                        ----        ID = @CheckDBLogDetailsID;
-----------------END Log DBPreCode--------------------

--------------------------------------------------
----------------BEGIN Run Precode-----------------
--------------------------------------------------
                        DECLARE
                            @PreCodeErrors VARCHAR(MAX),
                            @PreCodeErrorExist VARCHAR(MAX);
                        CREATE TABLE #PreCode
                            (
                             ID INT IDENTITY(1, 1),
                             col1 VARCHAR(MAX)
                            )

                        BEGIN TRY
                            EXEC (@DBPreCode) 
                        END TRY

                        BEGIN CATCH
                            SET @PreCodeErrors = ERROR_MESSAGE();
                        END CATCH

                        IF @PreCodeErrors IS NOT NULL
                            BEGIN
                                SELECT @PreCodeErrors = 'PRECODE ERROR: '
                                        + @PreCodeErrors
                            END	 

--------------------------------------------------
----------------END Run Precode-------------------
--------------------------------------------------
                    END -- @DBPreCode


-----BEGIN Log------

                IF @DBPreCode IS NOT NULL
                    BEGIN -- @DBPreCode
                        IF @StmtOnly = 0
                            BEGIN -- @StmtOnly = 0

-----------------------------------------------------
-------------BEGIN Log PreCode Success---------------
-----------------------------------------------------
                                IF @PreCodeErrors IS NULL
                                    BEGIN --@PreCodeErrors IS NULL
                                        SET @DBPreCodeEndDateTime = GETDATE();
                                        UPDATE Minion.CheckDBLogDetails
                                            SET
                                                DBPreCodeEndDateTime = @DBPreCodeEndDateTime,
                                                DBPreCodeTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @DBPreCodeStartDateTime, 21), CONVERT(VARCHAR(25), @DBPreCodeEndDateTime, 21))
                                            WHERE
                                                ID = @CheckDBLogDetailsID;
                                    END --@PreCodeErrors IS NULL
-----------------------------------------------------
-------------END Log PreCode Success-----------------
-----------------------------------------------------

-----------------------------------------------------
-------------BEGIN Log PreCode Failure---------------
-----------------------------------------------------
                                IF @PreCodeErrors IS NOT NULL
                                    BEGIN --@PreCodeErrors IS NULL
                                        SET @DBPreCodeEndDateTime = GETDATE();
                                        UPDATE Minion.CheckDBLogDetails
                                            SET
                                                Warnings = ISNULL(Warnings, '')
                                                + @PreCodeErrors,
                                                DBPreCodeEndDateTime = @DBPreCodeEndDateTime,
                                                DBPreCodeTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @DBPreCodeStartDateTime, 21), CONVERT(VARCHAR(25), @DBPreCodeEndDateTime, 21))
                                            WHERE
                                                ID = @CheckDBLogDetailsID;
                                    END --@PreCodeErrors IS NULL
-----------------------------------------------------
-------------END Log PreCode Failure-----------------
-----------------------------------------------------
                            END -- @StmtOnly = 0
                    END -- @@DBPreCode

------END Log-------
				END --@PrepOnly = 0-DBPreCode
            END -- @StmtOnly = 0
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------END DBPreCode---------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------	



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------BEGIN CHECKTABLE---------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF UPPER(@Op) = 'CHECKTABLE'
BEGIN --@OpRAW = 'CHECKTABLE'
--IF (@Schemas IS NOT NULL OR @Schemas <> '') OR (@Tables IS NOT NULL OR @Tables <> '')
--BEGIN --CHECKTABLE OP
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
-------------------------------BEGIN Settings-----------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

DECLARE
@TableName VARCHAR(200),
@CheckDBGroupOrder INT,
@CheckDBOrder INT,
@IsActive BIT,
@Comment VARCHAR(2000),
@TablesRAW VARCHAR(max);

IF @CheckDBSettingLevel > 0
	BEGIN
		SELECT @Port = Port,
			   @DefaultSchema = @DefaultSchema
		FROM Minion.CheckDBSettingsDB
		WHERE DBName = @DBName
			  AND UPPER(OpName) = 'CHECKTABLE'
			  AND IsActive = 1
	END

IF @CheckDBSettingLevel = 0
	BEGIN
		SELECT @Port = Port,
			   @DefaultSchema = DefaultSchema
		FROM Minion.CheckDBSettingsDB
		WHERE DBName = 'MinionDefault'
			  AND UPPER(OpName) = 'CHECKTABLE'
			  AND IsActive = 1
	END

------------------------BEGIN Set Port--------------------------
 IF @ServerInstance NOT LIKE '%\%'
	BEGIN
		SET @Port = CASE WHEN @Port IS NULL AND @ServerInstance NOT LIKE '%.%' THEN '' --',' + '1433'
						 WHEN @Port IS NULL AND @ServerInstance LIKE '%.%' THEN '' --',' + '1433'
						 WHEN @Port = '1433' THEN '' --',' + '1433'
						 WHEN @Port IS NOT NULL AND @Port <> '1433' AND @Port <> '' AND @ServerInstance NOT LIKE '%.%' THEN ',' + @Port
						 WHEN @Port IS NOT NULL AND @ServerInstance LIKE '%.%' THEN ''
						 END
	END
IF @ServerInstance LIKE '%\%'
	BEGIN
			SET @Port = CASE WHEN @Port IS NULL THEN ''
							 WHEN @Port IS NOT NULL AND @Port <> '1433' THEN  @Port
							 END
	END

	IF @Port IS NULL
	SET @Port = ''
------------------------END Set Port----------------------------

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
----------------------------BEGIN Parse Tables-------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
IF @RunPrepped = 0 OR @PrepOnly = 1
BEGIN -- Parse Tables
CREATE TABLE #Tables
(
ID INT IDENTITY(1,1),
SchemaName VARCHAR(200),
TableName varchar(200)
)


IF @Tables IS NULL AND @Schemas IS NULL
BEGIN
	DECLARE @TableSQL VARCHAR(2000);
	SET @TableSQL = 'USE [' + @DBName + ']; SELECT ''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''', ''' + @DBName + ''', SCHEMA_NAME(schema_id), name
FROM sys.objects WHERE type = ''U'''

	INSERT Minion.CheckDBCheckTableThreadQueue (ExecutionDateTime, DBName, SchemaName, TableName)
	EXEC(@TableSQL)
END


IF @Tables IS NOT NULL AND @Tables <> ''
	BEGIN --@Tables NOT NULL
		SET @TablesRAW = @Tables;
		SET @Tables = REPLACE(@Tables, ', ', ',');
			
		DECLARE @TablesTempTable TABLE ( TableName VARCHAR(500) );
		DECLARE @TableNameString VARCHAR(500);
		WHILE LEN(@Tables) > 0 
			BEGIN
				SET @TableNameString = LEFT(@Tables, ISNULL(NULLIF(CHARINDEX(',', @Tables) - 1, -1), LEN(@Tables)))
				SET @Tables = SUBSTRING(@Tables, ISNULL(NULLIF(CHARINDEX(',', @Tables), 0), LEN(@Tables)) + 1, LEN(@Tables))

				INSERT  INTO @TablesTempTable
						( TableName )
				VALUES  ( @TableNameString )
	END 

	----Since the TableName and SchemaName can be in the same entry, we need to parse it out.
	----We then insert it into #Tables as SchemaName, TableName.
	INSERT #Tables
			(SchemaName, TableName)
	SELECT
	   LEFT(TableName, CHARINDEX('.', TableName + '.') - 1) AS SchemaName,
	   CASE WHEN LEN(TableName) - LEN(REPLACE(TableName, '.', '')) > 0 THEN LTRIM(SUBSTRING(TableName, CHARINDEX('.', TableName) + 1, CHARINDEX('.', TableName + '.', CHARINDEX('.', TableName) + 1) - CHARINDEX('.', TableName) - 1))
		    ELSE NULL
		    END AS TableName
	FROM @TablesTempTable
	WHERE TableName LIKE '%.%'
	UNION ALL
	SELECT NULL AS SchemaName, TableName
	FROM @TablesTempTable
	WHERE TableName NOT LIKE '%.%'

----Set the default schema.  Each DB can have their own.  If it's NULL in the table we make it dbo.
IF @DefaultSchema IS NULL
	BEGIN
		SET @DefaultSchema = 'dbo'
	END

	UPDATE #Tables
	SET SchemaName = @DefaultSchema
	WHERE SchemaName IS NULL

DECLARE @TableNameSQL VARCHAR(MAX);
----------------Insert LIKE Include TableNames----------------
--You can mix static and LIKE table names so here's where we're processing the LIKE names.

IF @TablesRAW LIKE '%\%%' ESCAPE '\'
BEGIN --@IncludeRAW
DECLARE LikeTables CURSOR
READ_ONLY
FOR SELECT SchemaName, TableName
FROM #Tables
WHERE TableName LIKE '%\%%' ESCAPE '\' 

OPEN LikeTables

	FETCH NEXT FROM LikeTables INTO @currSchema, @currTable
	WHILE (@@fetch_status <> -1)
	BEGIN

		SET @TableNameSQL = 'USE [' + @DBName + ']; SELECT SCHEMA_NAME(schema_id) AS SchemaName, name 
		FROM sys.objects
		WHERE type = ''U''
		AND (name LIKE ''' + @currTable + 
		''' AND schema_id = SCHEMA_ID(''' + @currSchema + '''))'

--PRINT @TableNameSQL
		INSERT #Tables
		(SchemaName, TableName)
		EXEC (@TableNameSQL);

FETCH NEXT FROM LikeTables INTO @currSchema, @currTable
	END

CLOSE LikeTables
DEALLOCATE LikeTables

---Now delete the LIKE tabless that were passed into the param as the actual table names are in the table now.
DELETE #Tables
WHERE TableName LIKE '%\%%' ESCAPE '\'

END --@IncludeRAW

-------------------END LIKE Include TableNames---------------------

	END --@Tables NOT NULL

----------Finally put it into the work table.
		INSERT Minion.CheckDBCheckTableThreadQueue
		(ExecutionDateTime, DBName, SchemaName, TableName)
		SELECT @ExecutionDateTime, @DBName, SchemaName, TableName
		FROM #Tables;
END -- Parse Tables
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
----------------------------END Parse Tables---------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------




-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
----------------------------BEGIN Parse Schemas------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
IF @RunPrepped = 0 OR @PrepOnly = 1
BEGIN --Parse Schemas
CREATE TABLE #Schemas
(
ID INT IDENTITY(1,1),
SchemaName VARCHAR(200)
)

IF @Schemas IS NOT NULL AND @Schemas <> ''
	BEGIN --@Schemas NOT NULL
		SET @SchemasRAW = @Schemas;
		SET @Schemas = REPLACE(@Schemas, ', ', ',');
			
		DECLARE @SchemaNameString VARCHAR(500);
		WHILE LEN(@Schemas) > 0 
			BEGIN --While
				SET @SchemaNameString = LEFT(@Schemas, ISNULL(NULLIF(CHARINDEX(',', @Schemas) - 1, -1), LEN(@Schemas)));
				SET @Schemas = SUBSTRING(@Schemas, ISNULL(NULLIF(CHARINDEX(',', @Schemas), 0), LEN(@Schemas)) + 1, LEN(@Schemas));

				INSERT  INTO #Schemas
						( SchemaName )
				VALUES  ( @SchemaNameString )
			END --While


	END --@Schemas NOT NULL

DECLARE @SchemaNameSQL VARCHAR(MAX);

---------------------------------------------------------------
----------------Insert LIKE Include SchemaNames----------------
---------------------------------------------------------------
--You can mix static and LIKE Schema names so here's where we're processing the LIKE names.

IF @SchemasRAW LIKE '%\%%' ESCAPE '\'
BEGIN --@IncludeRAW
DECLARE LikeSchemas CURSOR
READ_ONLY
FOR SELECT SchemaName
FROM #Schemas
WHERE SchemaName LIKE '%\%%' ESCAPE '\' 

OPEN LikeSchemas

	FETCH NEXT FROM LikeSchemas INTO @currSchema
	WHILE (@@fetch_status <> -1)
	BEGIN

		SET @SchemaNameSQL = 'USE [' + @DBName + ']; SELECT name AS SchemaName
		FROM sys.schemas WHERE name LIKE ''' + @currSchema + ''''

--PRINT @SchemaNameSQL
		INSERT #Schemas
		(SchemaName)
		EXEC (@SchemaNameSQL);

FETCH NEXT FROM LikeSchemas INTO @currSchema
	END

CLOSE LikeSchemas
DEALLOCATE LikeSchemas

---Now delete the LIKE Schemas that were passed into the param as the actual Schema names are in the table now.
DELETE #Schemas
WHERE SchemaName LIKE '%\%%' ESCAPE '\'

END --@IncludeRAW
---------------------------------------------------------------
-------------------END LIKE Include SchemaNames----------------
---------------------------------------------------------------

END --Parse Schemas
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
----------------------------END Parse Schemas--------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------


------------------------------------------------
---------------BEGIN Get Schema Tables----------
------------------------------------------------
----We need to get the list of schemas and put them in a single row
----so we can use them in the select.  We couldn't do this before because
----we could have had wildcards in the input schema list and we have to get
----a list of the actual schemas first.
IF @RunPrepped = 0 OR @PrepOnly = 1
BEGIN --Get Schema Tables
DECLARE @SchemasToAdd VARCHAR(MAX);
SELECT @SchemasToAdd = STUFF(( SELECT ', ' + '''' + SchemaName + ''''
        FROM  #Schemas AS T1
        ORDER BY T1.ID
        FOR XML PATH('')), 1, 1, '')
FROM #Schemas AS T2;

SET @SchemaNameSQL = 'USE [' + @DBName + ']; SELECT ''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''',' + 'DB_NAME(), SCHEMA_NAME(schema_id) AS SchemaName, name AS TableName
FROM sys.objects WHERE type = ''U'' AND SCHEMA_NAME(schema_id) IN (' + @SchemasToAdd + ');'

		INSERT Minion.CheckDBCheckTableThreadQueue
		(ExecutionDateTime, DBName, SchemaName, TableName)
		EXEC (@SchemaNameSQL);


------------------------------------------------
---------------END Get Schema Tables------------
------------------------------------------------

        SET @TableSettingLevel = (
                             SELECT COUNT(*)
                                FROM Minion.CheckDBSettingsTable
                                WHERE
                                    DBName = @DBName
                                    AND IsActive = 1
                            )

        IF @TableSettingLevel > 0
            BEGIN		
                INSERT Minion.CheckDBCheckTableThreadQueue
                        (
							DBName,
							TableName,
							IndexName,
							Exclude,
							GroupOrder,
							GroupDBOrder,
							TimeEstimateSecs,
							NoIndex,
							RepairOption,
							RepairOptionAgree,
							AllErrorMsgs,
							ExtendedLogicalChecks,
							NoInfoMsgs,
							IsTabLock,
							IntegrityCheckLevel,
							HistRetDays,
							TablePreCode,
							TablePostCode,
							StmtPrefix,
							StmtSuffix,
							PreferredServer,
							Processing
						)
                    SELECT
							DBName,
							TableName,
							IndexName,
							Exclude,
							GroupOrder,
							GroupTableOrder,
							DefaultTimeEstimateMins*60,
							NoIndex,
							RepairOption,
							RepairOptionAgree,
							AllErrorMsgs,
							ExtendedLogicalChecks,
							NoInfoMsgs,
							IsTabLock,
							IntegrityCheckLevel,
							HistRetDays,
							TablePreCode,
							TablePostCode,
							StmtPrefix,
							StmtSuffix,
							PreferredServer,
							0
                        FROM Minion.CheckDBSettingsTable
                        WHERE
                            DBName = @DBName                             
                            AND IsActive = 1
		----------------------	  

            END
        IF @TableSettingLevel = 0
            BEGIN
                INSERT Minion.CheckDBCheckTableThreadQueue
                        (
							DBName,
							TableName,
							IndexName,
							Exclude,
							GroupOrder,
							GroupDBOrder,
							TimeEstimateSecs,
							NoIndex,
							RepairOption,
							RepairOptionAgree,
							AllErrorMsgs,
							ExtendedLogicalChecks,
							NoInfoMsgs,
							IsTabLock,
							IntegrityCheckLevel,
							HistRetDays,
							TablePreCode,
							TablePostCode,
							StmtPrefix,
							StmtSuffix,
							PreferredServer,
							Processing
						)
                    SELECT
							DBName,
							TableName,
							IndexName,
							Exclude,
							GroupOrder,
							GroupTableOrder,
							DefaultTimeEstimateMins*60,
							NoIndex,
							RepairOption,
							RepairOptionAgree,
							AllErrorMsgs,
							ExtendedLogicalChecks,
							NoInfoMsgs,
							IsTabLock,
							IntegrityCheckLevel,
							HistRetDays,
							TablePreCode,
							TablePostCode,
							StmtPrefix,
							StmtSuffix,
							PreferredServer,
							0
                        FROM
                            Minion.CheckDBSettingsTable
                        WHERE
                            DBName = 'MinionDefault'                            
                            AND IsActive = 1
            END


---------------------------------------------------------------------
---------------------------------------------------------------------
------------------BEGIN Rotation Figuring----------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
----We only want to manage a rotation if there were no Schemas or Tables passed into the job.
----As well, we can only configure it here if it an ST run.  So we check that Thread = 0.
----The MT runs can also be rotated, but that's configured in the SP that creates the MT threads.
IF @Thread = 0
BEGIN --@Thread 1
IF EXISTS (SELECT 1 FROM [Minion].[CheckDBSettingsRotation] WHERE UPPER(OpName) = 'CHECKTABLE' AND IsActive = 1)
BEGIN
	IF (@TablesRAW IS NULL OR @TablesRAW = '') AND (@SchemasRAW IS NULL OR @SchemasRAW = '')
		BEGIN
			EXEC Minion.CheckDBRotationLimiter @ExecutionDateTime = @ExecutionDateTime, @OpName = 'CHECKTABLE', @DBName = @DBName;
		END
END

DECLARE @CheckTableRotationLimiter VARCHAR(50),
		@CheckTableRotationLimiterMetric VARCHAR(10),
		@CheckTableRotationMetricValue INT,
		@CheckTableTimeLimitSecs INT;
----We query these whether we call the Limiter or not cause we still need to log it.
SET @CheckTableRotationLimiter = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'CHECKDB' AND DBName = @DBName  AND SPName = 'CheckDBRotationLimiter' AND Param = '@RotationLimiter-CHECKTABLE')
SET @CheckTableRotationLimiterMetric = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'CHECKDB' AND DBName = @DBName  AND SPName = 'CheckDBRotationLimiter' AND Param = '@RotationLimiterMetric-CHECKTABLE')
SET @CheckTableRotationMetricValue = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'CHECKDB' AND DBName = @DBName  AND SPName = 'CheckDBRotationLimiter' AND Param = '@RotationMetricValue-CHECKTABLE')
	
----SELECT @CheckTableRotationLimiter AS Limit, @CheckTableRotationLimiterMetric AS Metric, @CheckTableRotationMetricValue AS tValue

IF @CheckTableTimeLimitSecs IS NULL
	BEGIN
		SET @CheckTableTimeLimitSecs = (ISNULL(@CheckTableRotationMetricValue, 0))*60;
	END
		
----Log @TimeLimitInMins to the Work table so we can use it in the other SP.
----INSERT Minion.Work
----		(ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value)
----SELECT @ExecutionDateTime, 'CHECKDB', 'CHECKDB', 'CHECKDB', '@TimeLimitInMins', 'CheckDBMaster', ISNULL(@TimeLimitInMins, 0);
END --@Thread 1
---------------------------------------------------------------------
---------------------------------------------------------------------
------------------END Rotation Figuring------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------


----------------------------------------------
-------------BEGIN Update MinionDefault-------
----------------------------------------------
UPDATE CT
SET
CT.Exclude = CD.Exclude,
CT.GroupOrder = CD.GroupOrder,
CT.GroupDBOrder = CD.GroupDBOrder,
CT.TimeEstimateSecs = CD.DefaultTimeEstimateMins,
CT.NoIndex = CD.NoIndex,
CT.RepairOption = CD.RepairOption,
CT.RepairOptionAgree = CD.RepairOptionAgree,
CT.AllErrorMsgs = CD.AllErrorMsgs,
CT.ExtendedLogicalChecks = CD.ExtendedLogicalChecks,
CT.NoInfoMsgs = CD.NoInfoMsgs,
CT.IsTabLock = CD.IsTabLock,
CT.ResultMode = CD.ResultMode,
CT.IntegrityCheckLevel = CD.IntegrityCheckLevel,
CT.HistRetDays = CD.HistRetDays,
CT.TablePreCode = CD.TablePreCode,
CT.TablePostCode = CD.TablePostCode,
CT.StmtPrefix = CD.StmtPrefix,
CT.StmtSuffix = CD.StmtSuffix,
CT.PreferredServer = CD.PreferredServer,
CT.Processing = 0
FROM Minion.CheckDBCheckTableThreadQueue CT
INNER JOIN Minion.CheckDBSettingsDB CD ON 1 = 1
WHERE 
CT.ExecutionDateTime = @ExecutionDateTime
AND CD.DBName = 'MinionDefault'
	  AND UPPER(CD.OpName) = 'CHECKTABLE'
	  AND CD.IsActive = 1
----------------------------------------------
-------------END Update MinionDefault---------
----------------------------------------------

----------------------------------------------
-------------BEGIN Update DB Overrides--------
----------------------------------------------
UPDATE CT
SET
CT.Exclude = CD.Exclude,
CT.GroupOrder = CD.GroupOrder,
CT.GroupDBOrder = CD.GroupDBOrder,
CT.TimeEstimateSecs = CD.DefaultTimeEstimateMins,
CT.NoIndex = CD.NoIndex,
CT.RepairOption = CD.RepairOption,
CT.RepairOptionAgree = CD.RepairOptionAgree,
CT.AllErrorMsgs = CD.AllErrorMsgs,
CT.ExtendedLogicalChecks = CD.ExtendedLogicalChecks,
CT.NoInfoMsgs = CD.NoInfoMsgs,
CT.IsTabLock = CD.IsTabLock,
CT.ResultMode = CD.ResultMode,
CT.IntegrityCheckLevel = CD.IntegrityCheckLevel,
CT.HistRetDays = CD.HistRetDays,
CT.TablePreCode = CD.TablePreCode,
CT.TablePostCode = CD.TablePostCode,
CT.StmtPrefix = CD.StmtPrefix,
CT.StmtSuffix = CD.StmtSuffix,
CT.PreferredServer = CD.PreferredServer,
CT.Processing = 0
FROM Minion.CheckDBCheckTableThreadQueue CT
INNER JOIN Minion.CheckDBSettingsDB CD ON 1 = 1
WHERE CT.ExecutionDateTime = @ExecutionDateTime
AND CD.DBName = @DBName
	  AND UPPER(CD.OpName) = 'CHECKTABLE'
	  AND CD.IsActive = 1
----------------------------------------------
-------------END Update DB Overrides----------
----------------------------------------------

----------------------------------------------
-------------BEGIN Update Table Overrides-----
----------------------------------------------
UPDATE CT
SET
CT.Exclude = CD.Exclude,
CT.GroupOrder = ISNULL(CD.GroupOrder, 0),
CT.GroupDBOrder = ISNULL(CD.GroupTableOrder, 0),
CT.TimeEstimateSecs = CD.DefaultTimeEstimateMins,
CT.NoIndex = CD.NoIndex,
CT.RepairOption = CD.RepairOption,
CT.RepairOptionAgree = CD.RepairOptionAgree,
CT.AllErrorMsgs = CD.AllErrorMsgs,
CT.ExtendedLogicalChecks = CD.ExtendedLogicalChecks,
CT.NoInfoMsgs = CD.NoInfoMsgs,
CT.IsTabLock = CD.IsTabLock,
CT.ResultMode = CD.ResultMode,
CT.IntegrityCheckLevel = CD.IntegrityCheckLevel,
CT.HistRetDays = CD.HistRetDays,
CT.TablePreCode = CD.TablePreCode,
CT.TablePostCode = CD.TablePostCode,
CT.StmtPrefix = CD.StmtPrefix,
CT.StmtSuffix = CD.StmtSuffix,
CT.PreferredServer = CD.PreferredServer,
CT.Processing = 0
FROM Minion.CheckDBCheckTableThreadQueue CT
INNER JOIN Minion.CheckDBSettingsTable CD 
ON CT.DBName = CD.DBName
AND CT.SchemaName = CD.SchemaName
AND CT.TableName = CD.TableName
WHERE CT.ExecutionDateTime = @ExecutionDateTime
AND CD.DBName = @DBName
AND CD.IsActive = 1
	 -- AND UPPER(CD.OpName) = 'CHECKTABLE'

----------------------------------------------
-------------END Update Table Overrides-------
----------------------------------------------


----------------------------------------------
-------------BEGIN Excluded Tables------------
----------------------------------------------
IF @Tables IS NULL
BEGIN
	DELETE Minion.CheckDBCheckTableThreadQueue
	WHERE ExecutionDateTime = @ExecutionDateTime
	AND DBName = @DBName
	AND Exclude = 1;
END
----------------------------------------------
-------------END Excluded Tables--------------
----------------------------------------------

DECLARE @TableSizeSQL VARCHAR(2000);

SET @TableSizeSQL = 'USE [' + @DBName + ']; INSERT [' + @MaintDB + '].Minion.CheckDBTableSizeTemp(ExecutionDateTime, DBName, SchemaName, TableName, RowCT, TotalSpaceKB, UsedSpaceKB, UnusedSpaceKB)'
+ 'SELECT '
+ '''' + CONVERT(VARCHAR(25), @ExecutionDateTime, 121) + ''','
+ '''' + @DBName + ''', '	
+ ' s.name AS SchemaName,
    t.name AS TableName,
    p.rows AS RowCT,
    CASE WHEN (SUM(a.total_pages) * 8) = 0 THEN .1 ELSE (SUM(a.total_pages)) * 8 END AS TotalSpaceKB, 
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM 
sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.NAME NOT LIKE ''dt%'' 
GROUP BY 
    t.Name, s.Name, p.Rows;'
EXEC (@TableSizeSQL);

UPDATE TQ
SET TQ.SizeInMB = CAST((CASE WHEN (TS.TotalSpaceKB <= 0 OR TS.TotalSpaceKB IS NULL) THEN .1 ELSE TS.TotalSpaceKB END /1024.0) AS DECIMAL(10,2))
FROM Minion.CheckDBCheckTableThreadQueue TQ
LEFT OUTER JOIN Minion.CheckDBTableSizeTemp TS ON TQ.SchemaName = TS.SchemaName AND TQ.TableName = TS.TableName
WHERE TQ.ExecutionDateTime = @ExecutionDateTime
AND TQ.DBName = @DBName
AND TS.ExecutionDateTime = @ExecutionDateTime
AND TS.DBName = @DBName;

----------------------------------------------
-------------BEGIN Update Time Overrides------
----------------------------------------------
UPDATE CT
SET
CT.TimeEstimateSecs = CD.OpRunTimeInSecs,
--CT.EstimatedKBperMS = (CD.SizeInMB*1024.0)/(CD.OpRunTimeInSecs*1000.0),
CT.EstimatedKBperMS = ((CASE WHEN (CD.SizeInMB <= 0 OR CD.SizeInMB IS NULL) THEN 1 WHEN CD.SizeInMB > 0 THEN CD.SizeInMB ELSE 1 END)*1024/(CASE WHEN (CD.OpRunTimeInSecs <= 0 OR CD.OpRunTimeInSecs IS NULL) THEN 1 WHEN CD.OpRunTimeInSecs > 0 THEN CD.OpRunTimeInSecs ELSE 1 END) *1000.00),
CT.LastOpTimeInSecs = CD.OpRunTimeInSecs
FROM Minion.CheckDBCheckTableThreadQueue CT
LEFT OUTER JOIN Minion.CheckTableLogDetailsLatest CD 
ON CT.DBName = CD.DBName
AND CT.SchemaName = CD.SchemaName
AND CT.TableName = CD.TableName
WHERE CT.ExecutionDateTime = @ExecutionDateTime
AND CD.DBName = @DBName;

UPDATE Minion.CheckDBCheckTableThreadQueue
SET EstimatedKBperMS = 1024000,
	LastOpTimeInSecs = 1
	WHERE ExecutionDateTime = @ExecutionDateTime
	AND DBName = @DBName
	AND EstimatedKBperMS IS NULL;

----------------------------------------------
-------------END Update Time Overrides--------
----------------------------------------------
----SELECT * FROM Minion.CheckDBCheckTableThreadQueue;


END --Get Schema Tables

IF @StmtOnly = 1
	BEGIN
		SELECT DBName, SchemaName, TableName, Exclude, GroupOrder, GroupDBOrder
		FROM Minion.CheckDBCheckTableThreadQueue
		WHERE ExecutionDateTime = @ExecutionDateTime
		AND DBName = @DBName
		ORDER BY GroupOrder DESC, GroupDBOrder DESC;
	END
 --------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------------------------
 -------------------------------END Settings-------------------------------------------------
 --------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------------------------
IF @PrepOnly = 0
BEGIN --@PrepOnly = 0-Declare

----Update LogDetails with Size and Estimate info.
UPDATE CD
SET
CD.SizeInMB = CT.SizeInMB,
CD.EstimatedTimeInSecs = CT.TimeEstimateSecs/60
FROM 
Minion.CheckDBLogDetails CD
INNER JOIN Minion.CheckDBCheckTableThreadQueue CT 
ON CT.DBName = CD.DBName
AND CT.SchemaName = CD.SchemaName
AND CT.TableName = CD.TableName
WHERE CT.ExecutionDateTime = @ExecutionDateTime
AND CD.ExecutionDateTime = @ExecutionDateTime
AND CD.DBName = @DBName;

DECLARE
	@currSchemaName NVARCHAR(400),
	@currTableName NVARCHAR(400),
	@currIndexName NVARCHAR(400),
	@currExclude BIT,
	@currGroupOrder INT,
	@currGroupDBOrder INT,
	@currTimeEstimateSecs INT,
	@currEstimatedKBperMS BIGINT,
	@currLastOpTimeSecs INT,
	@currSizeInMB BIGINT,
	@currNoIndex BIT,
	@currRepairOption VARCHAR(50),
	@currDisableDOP BIT,
	@currPreferredServer VARCHAR(150),
	@currRepairOptionAgree BIT,
	@currAllErrorMsgs BIT,
	@currExtendedLogicalChecks BIT,
	@currNoInfoMsgs BIT,
	@currIsTabLock BIT,
	@currResultMode VARCHAR(50),
	@currIntegrityCheckLevel VARCHAR(50),
	@currHistRetDays INT,
	@currTablePreCode NVARCHAR(MAX),
	@currTablePostCode NVARCHAR(MAX),
	@currStmtPrefix NVARCHAR(500),
	@currStmtSuffix VARCHAR(500),
	@SQL VARCHAR(8000),
	@ViolatesTime BIT;
END --@PrepOnly = 0-Declare

 ---------------------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------------------
 -------------------------------------BEGIN Table Cursor--------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------------------


IF @PrepOnly = 0
BEGIN
CREATE TABLE #CheckTableResults (ID INT IDENTITY(1,1), col1 VARCHAR(max));
END

IF @PrepOnly = 0
BEGIN --@PrepOnly = 0-Table Cursor
 ----DECLARE curTable CURSOR
 ----READ_ONLY
 ----FOR
 DECLARE @TotalTableCT BIGINT,
		 @CurrentTableCT BIGINT,
		 @currWorkRow BIGINT;
 SET @CurrentTableCT = 0;

SET @TotalTableCT = (SELECT COUNT(*) FROM Minion.CheckDBCheckTableThreadQueue
WHERE ExecutionDateTime = @PreppedExecutionDateTime AND DBName = @DBName)

---- OPEN curTable 
---- 	FETCH NEXT FROM curTable INTO @currSchemaName, @currTableName, @currIndexName, @currExclude, @currGroupOrder, @currGroupDBOrder, @currNoIndex, @currRepairOption, @currRepairOptionAgree, @currAllErrorMsgs, @currExtendedLogicalChecks, @currNoInfoMsgs, @currIsTabLock, @currResultMode, @currIntegrityCheckLevel, @currHistRetDays, @currTablePreCode, @currTablePostCode
 	WHILE @CurrentTableCT <= @TotalTableCT ----(@@fetch_status <> -1)
 	BEGIN --curTable While

---------------BEGIN Reset Vars for current run---------------
SET @currWorkRow = NULL;		
SET @currSchemaName = NULL;
SET @currTableName = NULL;
SET @currIndexName = NULL;
SET @currExclude = NULL;
SET @currGroupOrder = NULL;
SET @currGroupDBOrder = NULL;
SET @currTimeEstimateSecs = NULL;
SET @currEstimatedKBperMS = NULL;
SET @currSizeInMB = NULL;
SET @currLastOpTimeSecs = NULL;
SET @currNoIndex = NULL;
SET @currRepairOption = NULL;
SET @currRepairOptionAgree = NULL;
SET @currAllErrorMsgs = NULL;
SET @currExtendedLogicalChecks = NULL;
SET @currPreferredServer = NULL;
SET @currNoInfoMsgs = NULL;
SET @currIsTabLock = NULL;
SET @currResultMode = NULL;
SET @currIntegrityCheckLevel = NULL;
SET @currHistRetDays = NULL;
SET @currTablePreCode = NULL;
SET @currTablePostCode = NULL;
SET @currStmtPrefix = NULL;
SET @currStmtSuffix = NULL;
SET @currDisableDOP = NULL;
---------------END Reset Vars for current run-----------------

----------------------------------------------------------
----------------------------------------------------------
---------------BEGIN Get New Row--------------------------
----------------------------------------------------------
----------------------------------------------------------
BEGIN TRAN
	 SELECT TOP 1
		@currWorkRow = ID,		
		@currSchemaName = SchemaName,
		@currTableName = TableName,
		@currIndexName = IndexName,
		@currExclude = Exclude,
		@currGroupOrder = GroupOrder,
		@currGroupDBOrder = GroupDBOrder,
		@currTimeEstimateSecs = 
						CASE WHEN (TimeEstimateSecs*60) < 1 THEN 1
							 ELSE (TimeEstimateSecs*60)
						END,
		@currEstimatedKBperMS = EstimatedKBperMS,
		@currLastOpTimeSecs = LastOpTimeInSecs,
		@currSizeInMB = SizeInMB,
		@currNoIndex = NoIndex,
		@currRepairOption = RepairOption,
		@currRepairOptionAgree = RepairOptionAgree,
		@currAllErrorMsgs = AllErrorMsgs,
		@currExtendedLogicalChecks = ExtendedLogicalChecks,
		@currNoInfoMsgs = NoInfoMsgs,
		@currIsTabLock = IsTabLock,
		@currResultMode = ResultMode,
		@currIntegrityCheckLevel = IntegrityCheckLevel,
		@currHistRetDays = HistRetDays,
		@currTablePreCode = TablePreCode,
		@currTablePostCode = TablePostCode,
		@currStmtPrefix = StmtPrefix,
		@currStmtSuffix = StmtSuffix,
		@currPreferredServer = PreferredServer
	FROM Minion.CheckDBCheckTableThreadQueue WITH (XLOCK)
	WHERE ExecutionDateTime = @PreppedExecutionDateTime
		  AND DBName = @DBName
		  AND Processing = 0
	ORDER BY GroupOrder DESC, GroupDBOrder DESC;

	UPDATE Minion.CheckDBCheckTableThreadQueue WITH (XLOCK)
	SET Processing = 1,
		ProcessingThread = @Thread
	WHERE ID = @currWorkRow

COMMIT

----------------------------------------------------------
----------------------------------------------------------
---------------END Get New Row----------------------------
----------------------------------------------------------
----------------------------------------------------------

----If there's no new row, then quit the loop because all the tables have been processed.
IF @currWorkRow IS NULL
	BREAK;
If @StmtOnly = 0
--BEGIN -- StmtOnly = 0

SET @ViolatesTime = 0;
---------------------------------------------------------------------------------
--------------------------BEGIN Timed Run ---------------------------------------
---------------------------------------------------------------------------------
--We need to figure out if we should continue based off of the estimated run time
--and when we're supposed to stop.  So if we calculate that we don't have time to run this
--table then we'll skip it and either log it or not.

----This usually gets set in Master, but if they run this SP, it needs to be set to 0 so it'll
----log the run.
IF @CheckTableTimeLimitSecs IS NULL
	BEGIN
		SET @CheckTableTimeLimitSecs = 0;
	END

IF @CheckTableTimeLimitSecs > 0
BEGIN --@CheckTableTimeLimitSecs > 0
	SET @ViolatesTime = 0;

----SELECT @currLastOpTimeSecs AS LastTime, @currSizeInMB LastSize, @CheckTableTimeLimitSecs*60 AS Limit, @currTimeEstimateSecs*60 TimeEstSecs, @currTimeEstimateSecs AS TimeEstRaw;

IF @currLastOpTimeSecs IS NULL
	BEGIN
	 SET @currLastOpTimeSecs = 1;
	END

IF @currSizeInMB IS NULL
	BEGIN
	 SET @currSizeInMB = 1;
	END

--This is the estimate based on the current size of the DB.
--The DB could have grown or shrunk significantly since the last
--checkdb so we need to get a number.
--To prevent rounding issues we convert DBSize to KB to help
--with smaller DBs, and we've already got the time in MS.
--Rounding can throw off a calculation quite a bit, so the hope
--here is to make it more accurate.  At the end we 
--Divide by 1000 again to put it back into secs.  And then
--we turn it back into mins.

	IF @CheckTableTimeLimitSecs > 0 AND @CheckTableTimeLimitSecs IS NOT NULL
	BEGIN 
		DECLARE @TimeFrameDiff INT;
		SET @TimeFrameDiff = DATEDIFF(SECOND, @ExecutionDateTime, GETDATE())
----SELECT @currLastOpTimeSecs AS LastTime, @currSizeInMB LastSize, @CheckTableTimeLimitSecs AS Limit, @currTimeEstimateSecs TimeEstSecs, @currTimeEstimateSecs AS TimeEstRaw, @TimeFrameDiff AS TimeFrameDiff;
		----SET @currTimeEstimateSecs = 5000 --!!!!!!!!!!!!!!!!!TESTING-REMOVE!!!!!!

		IF @currTimeEstimateSecs >= ((@CheckTableTimeLimitSecs) - @TimeFrameDiff)
			BEGIN
				SET @ViolatesTime = 1;
			END
	END
END --@CheckTableTimeLimitSecs > 0
---------------------------------------------------------------------------------
--------------------------END Timed Run -----------------------------------------
---------------------------------------------------------------------------------


-------------------------------------------------------------------------
-------------------BEGIN Initial Log Record------------------------------
-------------------------------------------------------------------------
--It could have already been created in the Master SP so we have to check
--If there's a record already in there.

IF (@ViolatesTime = 0 AND @CheckTableTimeLimitSecs = 0) OR (@ViolatesTime = 0 AND @CheckTableTimeLimitSecs > 0) OR (@ViolatesTime = 1 AND @CheckTableTimeLimitSecs > 0 AND (@LogSkips = 1 OR @LogSkips IS NULL))
BEGIN --ViolatesTime
	If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
			IF (
				SELECT
						ExecutionDateTime
					FROM
						Minion.CheckDBLogDetails
					WHERE
						ExecutionDateTime = @ExecutionDateTime
						AND DBName = @DBName
						AND SchemaName = @currSchemaName
						AND TableName = @currTableName
						AND UPPER(OpName) = UPPER(@Op)
			   ) IS NULL
				BEGIN
					INSERT Minion.CheckDBLogDetails
							(
							 ExecutionDateTime,
							 DBName,
							 CheckDBName,
							 IsRemote,
							 OpName,
							 DBType,
							 SchemaName,
							 TableName,
							 GroupOrder,
							 GroupDBOrder,
							 SizeInMB,
							 TimeLimitInMins,
							 EstimatedTimeInSecs,
							 EstimatedKBperMS,
							 LastOpTimeInSecs,
							 OpBeginTime,
							 NoIndex,
							 RepairOption,
							 RepairOptionAgree,
							-- WithRollback,
							 AllErrorMsgs,
							 ExtendedLogicalChecks,
							 NoInfoMsgs,
							 IsTabLock,
							 IntegrityCheckLevel,
							 DisableDOP,
							 PreferredServer,
							 --LockDBMode,
							 ResultMode,
							 HistRetDays,
							 --PushToMinion,
							 --MinionTriggerPath,
							 --AutoRepair,
							 --AutoRepairTime,
							 DBPreCodeStartDateTime,
							 DBPreCodeEndDateTime,
							 DBPreCodeTimeInSecs,
							 DBPreCode,
							 StmtPrefix,
							 StmtSuffix,
							 ProcessingThread
							)
						SELECT
								@ExecutionDateTime,
								@DBName,
								@CurrentSnapshotDBName,
								0,
								UPPER(@Op),
								@LogDBType,
								@currSchemaName,
								@currTableName,
								@currGroupOrder,
								@currGroupDBOrder,
								@currSizeInMB,
								@CheckTableTimeLimitSecs/60, --Put back into mins for the log.
								@currTimeEstimateSecs,
								@currEstimatedKBperMS,
								@currLastOpTimeSecs,
								@BeginTime,
								@currNoIndex,
								@currRepairOption,
								@currRepairOptionAgree,
								--@currWithRollback,
								@currAllErrorMsgs,
								@currExtendedLogicalChecks,
								@currNoInfoMsgs,
								@currIsTabLock,
								@currIntegrityCheckLevel,
								@currDisableDOP,
								@currPreferredServer,
								--@currLockDBMode,
								@currResultMode,
								@currHistRetDays,
								--@currPushToMinion,
								--@currMinionTriggerPath,
								--@currAutoRepair,
								--@currAutoRepairTime,
								@DBPreCodeStartDateTime,
								@DBPreCodeEndDateTime,
								DATEDIFF(s, CONVERT(VARCHAR(25), @DBPreCodeStartDateTime, 21), CONVERT(VARCHAR(25), @DBPreCodeEndDateTime, 21)),
								@DBPreCode,
								@currStmtPrefix,
								@currStmtSuffix,
								@Thread
				END

------------------------------------------------------------------------
---------------------BEGIN Get Current Log Record-----------------------
------------------------------------------------------------------------
			SET @CheckDBLogDetailsID = (
									   SELECT ID
										FROM  Minion.CheckDBLogDetails
										WHERE
											ExecutionDateTime = @ExecutionDateTime
											AND DBName = @DBName
											AND SchemaName = @currSchemaName
											AND TableName = @currTableName
											AND UPPER(OpName) = UPPER(@Op)
									  )
 END --ViolatesTime									   
------------------------------------------------------------------------
---------------------END Get Current Log Record-------------------------
------------------------------------------------------------------------



 -------------------------------------------------------------------------
-------------------BEGIN Log Time Skip-----------------------------------
-------------------------------------------------------------------------
----If the current DB violates our time constraint, then we skip it but we only log it if we 
----want it logged.
----WAITFOR DELAY '00:00:10';
IF @CheckTableTimeLimitSecs > 0 AND @CheckTableTimeLimitSecs IS NOT NULL
BEGIN --TimeLimit2
----IF (@IsRemote = 0 OR @IsRemote IS NULL) OR (@IsRemote = 1 AND @IncludeRemoteInTimeLimit = 1) 
----	BEGIN --IncludeRemote

		----SET @TimeFrameDiff = DATEDIFF(SECOND, @ExecutionDateTime, GETDATE())
		----	--SELECT @DBSize, @KBperMS, @currCheckDBTimeEstimate AS Est, (@TimeLimitInMinsCheckDB*60) - @TimeFrameDiff AS Diff
		----IF @currCheckDBTimeEstimate >= ((@TimeLimitInMinsCheckDB*60) - @TimeFrameDiff)
			IF @ViolatesTime = 1
			BEGIN --TimeLimiter
			--We're going to default to logging skipped backups, so NULL will get you logged.
				IF @LogSkips = 1 OR @LogSkips IS NULL
					BEGIN --LogSkips
						UPDATE Minion.CheckDBLogDetails
						SET STATUS = 'SKIPPED: Time constraint violation.',
							PctComplete = 0
						WHERE ID = @CheckDBLogDetailsID;

						SET @CurrentTableCT = @CurrentTableCT + 1;
						CONTINUE;
					END --LogSkips
				--If you don't want to log the skips, you still need to end the routine if it
				--violates the time constraint.
				IF @LogSkips = 0
					BEGIN
						RETURN;
					END
			END --TimeLimiter
	----END --IncludeRemote
	END --TimeLimit2
-------------------------------------------------------------------------
-------------------END Log Time Skip-------------------------------------
-------------------------------------------------------------------------



 ----------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------
 -------------------------------BEGIN Last CheckTable Result-----------------------------
 ----------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------
 SELECT TOP 1 @LastMinionCheckDBDate = OpEndTime,
			 @LastMinionCheckDBResult = STATUS
FROM Minion.CheckDBLogDetails 
WHERE DBName = @DBName AND UPPER(OpName) = 'CHECKTABLE' 
	AND SchemaName = @currSchemaName AND TableName = @currTableName
ORDER BY OpEndTime DESC
 ----------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------
 -------------------------------END Last CheckTable Result-------------------------------
 ----------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------

	----Update the CheckDBLog table for top-level logging.
			UPDATE Minion.CheckDBLog
				SET STATUS = 'Processing ' + @DBName
				WHERE ID = @CheckDBLogDetailsID;
	--END --@StmtOnly = 0	
--END --Op CheckTable				    
-------------------------------------------------------------------------
-------------------END Initial Log Record--------------------------------
-------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
------------------------------------BEGIN Create Snapshot----------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
	
IF @CreateSnapshot = 1
BEGIN --@CreateSnapshot = 1
IF @OnlineEdition = 1
	BEGIN --@OnlineEdition = 1

DECLARE @SnapshotCompareBegin DATETIME,
		@DeleteCurrentSnapshot BIT,
		@CreateNewSnapshot BIT;
-------------------------------------------------------------------------------------
---------------------------BEGIN Delete Snapshot-------------------------------------
-------------------------------------------------------------------------------------
--Reset the delete var for this run.
SET @DeleteCurrentSnapshot = 0;
----We don't want to compare against NULL.  Also, 0 will mean infinite so we won't create a new snapshot if it's 0.
IF @SnapshotRetMins IS NULL
	BEGIN
		SET @SnapshotRetMins = 0;
	END

----We need to check the table to get the last snapshot time because we have to centrally manage it across all the threads.
----Any of the threads can update this col so it needs to be checked here and we have to xlock the table so that all the threads
----can only see it one at a time. We're using the time '1/1/1900 00:00:00.000' as the control instead of NULL.
----NULL will be hit on the 1st run, but after that the threads need to know that it's being handled by another thread.
----So when a thread goes to create a snapshot it sets this col to the datetime above so that the other threads know it's 
----being handled.  After that, then we automatically know it's a real snapshot DB and it can be used to compare.
----There are 2 more considerations. 1. Once a thread sees that another thread is creating a snapshot, it must wait for it to be 
----created.  It can't just bull forward because it doesn't know what the name of the SnapshotDB will be.  So we have to put that
----inside a loop so keep checking for when the date changes.  That also means that it'll have to check to see whether there's been
----an error creating the snapshot so the threads don't just wait forever.  Maybe they'll just timeout after a while; we'll see.
----2. Once it's decided that a snapshot has timed out, then it can't just drop it because there could be other threads currently
----using it.  So we'll have to check whether there are any other threads running that are processing tables in the current DB
----and if so, then we'll have to drop into another loop and wait for them to finish and then, one of the threads will see that
----all the other threads are finished, and update the date to 1900 and then create the snapshot and everything starts all over.
IF @Thread > 0
BEGIN --@Thread > 0
	BEGIN TRAN
		SET @SnapshotCompareBegin = (SELECT LatestSnapshotDateTime FROM Minion.CheckDBTableSnapshotQueue WITH (TABLOCKX) WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName);

									-------------------DEBUG-------------------------------
									IF @Debug = 1
									BEGIN
									--SnapshotDelta is the diff between now and the last recorded snapshot.  It'll tell us at a glance if something's not right.
										INSERT Minion.CheckDBDebugSnapshotThreads (ExecutionDateTime, CurrentDateTime, RunType, DBName, SnapshotDBName, SPName, SnapshotCompareBegin, SnapshotRetMins, SnapshotDelta, Thread, SnapshotCreationOwner)
										SELECT @ExecutionDateTime, GETDATE(), 'Initial SnapshotCompareBegin Query', @DBName, @CurrentSnapshotDBName, 'CheckTable', @SnapshotCompareBegin, @SnapshotRetMins, ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0), @Thread, @SnapshotCreationOwner
									END
									-------------------DEBUG-------------------------------

	----1st run. SnapshotDate will be NULL.
		IF @SnapshotCompareBegin IS NULL
			BEGIN --1st Run
			----On the 1st run there won't be a row for this ExecutionDateTime yet. So we have to create it.
				IF NOT EXISTS (SELECT 1 FROM Minion.CheckDBTableSnapshotQueue WITH (TABLOCKX) WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName)
					BEGIN --Not Exists
						INSERT Minion.CheckDBTableSnapshotQueue WITH (TABLOCKX)
						SELECT @ExecutionDateTime, @DBName, NULL, NULL, @Thread;

						SELECT @SnapshotCompareBegin = LatestSnapshotDateTime,
							   @CurrentSnapshotDBName = SnapshotDBName,
							   @SnapshotCreationOwner = [Owner]
							   FROM Minion.CheckDBTableSnapshotQueue WITH (TABLOCKX)
							   WHERE ExecutionDateTime = @ExecutionDateTime 
							   AND DBName = @DBName;

									-------------------DEBUG-------------------------------
									IF @Debug = 1
									BEGIN
									--SnapshotDelta is the diff between now and the last recorded snapshot.  It'll tell us at a glance if something's not right.
										INSERT Minion.CheckDBDebugSnapshotThreads (ExecutionDateTime, CurrentDateTime, RunType, DBName, SnapshotDBName, SPName, SnapshotCompareBegin, SnapshotRetMins, SnapshotDelta, Thread, SnapshotCreationOwner)
										SELECT @ExecutionDateTime, GETDATE(), '1st run-Not Exist', @DBName, @SnapshotDBName, 'CheckTable', @SnapshotCompareBegin, @SnapshotRetMins, ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0), @Thread, @SnapshotCreationOwner
									END
									-------------------DEBUG-------------------------------
					END --Not Exists
				ELSE
					BEGIN -- Exists
						UPDATE Minion.CheckDBTableSnapshotQueue WITH (TABLOCKX)
						SET [Owner] = @Thread
						WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName;

						SELECT @SnapshotCompareBegin = LatestSnapshotDateTime,
							   @CurrentSnapshotDBName = SnapshotDBName,
							   @SnapshotCreationOwner = [Owner]
							   FROM Minion.CheckDBTableSnapshotQueue WITH (TABLOCKX)
							   WHERE ExecutionDateTime = @ExecutionDateTime 
							   AND DBName = @DBName;

									-------------------DEBUG-------------------------------
									IF @Debug = 1
									BEGIN
									--SnapshotDelta is the diff between now and the last recorded snapshot.  It'll tell us at a glance if something's not right.
										INSERT Minion.CheckDBDebugSnapshotThreads (ExecutionDateTime, CurrentDateTime, RunType, DBName, SnapshotDBName, SPName, SnapshotCompareBegin, SnapshotRetMins, SnapshotDelta, Thread, SnapshotCreationOwner)
										SELECT @ExecutionDateTime, GETDATE(), '1st run-Exist', @DBName, @SnapshotDBName, 'CheckTable', @SnapshotCompareBegin, @SnapshotRetMins, ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0), @Thread, @SnapshotCreationOwner
									END
									-------------------DEBUG-------------------------------
					END -- Exists
			END --1st Run

	----Normal run. This is for any run after the 1st one. Only the 1st thread will hit the above code, and everything else will hit this code.
				IF @SnapshotCompareBegin IS NOT NULL --AND @SnapshotCompareBegin <> '1/1/1900 00:00:00.000' --If there is a row for this run.				
					BEGIN --@SnapshotCompareBegin IS NOT NULL
						----You have to make sure another thread hasn't updated the snapshot date since the last loop iteration.
						----SET @SnapshotCompareBegin = (SELECT LatestSnapshotDateTime FROM Minion.CheckDBTableSnapshotQueue WITH (TABLOCKX) WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName);
						----------Snapshot is expired.
						IF ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0) >= @SnapshotRetMins
							BEGIN
							----This code will only be run if it's time for a new snapshot.
									UPDATE Minion.CheckDBTableSnapshotQueue WITH (TABLOCKX)
									SET [Owner] = @Thread
									WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName;

									SELECT @SnapshotCompareBegin = LatestSnapshotDateTime,
										   @CurrentSnapshotDBName = SnapshotDBName,
										   @SnapshotCreationOwner = [Owner]
									FROM Minion.CheckDBTableSnapshotQueue WITH (TABLOCKX)
									WHERE ExecutionDateTime = @ExecutionDateTime 
									AND DBName = @DBName;

									-------------------DEBUG-------------------------------
									IF @Debug = 1
									BEGIN
									--SnapshotDelta is the diff between now and the last recorded snapshot.  It'll tell us at a glance if something's not right.
										INSERT Minion.CheckDBDebugSnapshotThreads (ExecutionDateTime, CurrentDateTime, RunType, DBName, SnapshotDBName, SPName, SnapshotCompareBegin, SnapshotRetMins, SnapshotDelta, Thread, SnapshotCreationOwner)
										SELECT @ExecutionDateTime, GETDATE(), '@SnapshotCompareBegin IS NOT NULL', @DBName, @CurrentSnapshotDBName, 'CheckTable', @SnapshotCompareBegin, @SnapshotRetMins, ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0), @Thread, @SnapshotCreationOwner
									END
									-------------------DEBUG-------------------------------
								END
						----------Snapshot time is good.
						IF ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0) < @SnapshotRetMins
							BEGIN
									SELECT @SnapshotCompareBegin = LatestSnapshotDateTime,
										   @CurrentSnapshotDBName = SnapshotDBName,
										   @SnapshotCreationOwner = [Owner]
									FROM Minion.CheckDBTableSnapshotQueue WITH (TABLOCKX)
									WHERE ExecutionDateTime = @ExecutionDateTime 
									AND DBName = @DBName;

									-------------------DEBUG-------------------------------
									IF @Debug = 1
									BEGIN
									--SnapshotDelta is the diff between now and the last recorded snapshot.  It'll tell us at a glance if something's not right.
										INSERT Minion.CheckDBDebugSnapshotThreads (ExecutionDateTime, CurrentDateTime, RunType, DBName, SnapshotDBName, SPName, SnapshotCompareBegin, SnapshotRetMins, SnapshotDelta, Thread, SnapshotCreationOwner)
										SELECT @ExecutionDateTime, GETDATE(), 'Snapshot not expired', @DBName, @CurrentSnapshotDBName, 'CheckTable', @SnapshotCompareBegin, @SnapshotRetMins, ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0), @Thread, @SnapshotCreationOwner
									END
									-------------------DEBUG-------------------------------
								END
					END --@SnapshotCompareBegin IS NOT NULL


	----This is hit if a record was just created during the 1st run.  It is meant to be a placeholder so that other threads know which thread is the owner of this record.
	----A thread owns the record when it recognizes that a snapshot needs to be created and has already traveled down the path of doing that.
	----Once the snapshot is created and the date is switched from 1900 to the real date, the owning thread stops being the owner and a new owner isn't assigned until
	----a new snapshot needs to be created and then any thread can become the owner.  This process is designed to ensure that all of the threads have to wait their turn.
	----No 2 threads can see the table at the same time.  We have to know which thread owns because if 1900 exists then the owner will create the snapshot, and the other threads
	----will enter a loop and wait until 1900 is gone and then they'll grab the new snapshot DB and continue their processing. 
	----Therefore, you may find that there are no tables processing for a short time while the snapshot is being created.


	----The non-owning thread must wait in a loop until the owning thread has created the snapshot and updated the data.
		SET @SnapshotCreationOwner = (SELECT Owner FROM Minion.CheckDBTableSnapshotQueue WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName);

					IF (@SnapshotCreationOwner <> @Thread AND @SnapshotCreationOwner IS NOT NULL)
						BEGIN --NON-Owner
							IF ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0) >= @SnapshotRetMins
								BEGIN --Snapshot expired
									WHILE @SnapshotCreationOwner <> @Thread AND @SnapshotCreationOwner IS NOT NULL
										BEGIN --WHILE
											SELECT @SnapshotCreationOwner = [Owner],
											@CurrentSnapshotDBName = @SnapshotDBName
											FROM Minion.CheckDBTableSnapshotQueue 
											WHERE ExecutionDateTime = @ExecutionDateTime 
											AND DBName = @DBName;

									-------------------DEBUG-------------------------------
									IF @Debug = 1
									BEGIN
									--SnapshotDelta is the diff between now and the last recorded snapshot.  It'll tell us at a glance if something's not right.
										INSERT Minion.CheckDBDebugSnapshotThreads (ExecutionDateTime, CurrentDateTime, RunType, DBName, SnapshotDBName, SPName, SnapshotCompareBegin, SnapshotRetMins, SnapshotDelta, Thread, SnapshotCreationOwner)
										SELECT @ExecutionDateTime, GETDATE(), 'NON-Owner WAIT LOOP - @SnapshotCreationOwner <> @Thread AND @SnapshotCreationOwner IS NOT NULL', @DBName, @CurrentSnapshotDBName, 'CheckTable', @SnapshotCompareBegin, @SnapshotRetMins, ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0), @Thread, @SnapshotCreationOwner
									END
									-------------------DEBUG-------------------------------
											WAITFOR DELAY '00:00:05'
											IF @SnapshotCreationOwner IS NULL
												BREAK;
										END --WHILE
							END --Snapshot expired					
						END --NON-Owner

					----END -- 1900
			WAITFOR DELAY '00:00:05'
	COMMIT TRAN
END --@Thread > 0
-----Find out how long it's been since the snapshot was created.
---The 1st round throws things off because SnapshotCompareBegin is null and nothing else has gotten warmed up yet. So we need to check for that null here and below separate out the logic again,
---and make sure it's handled so that we get the initial snapshot. This null condition will only happen on the first table.
IF ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0) >= @SnapshotRetMins AND @SnapshotCompareBegin IS NOT NULL
--BEGIN --Snapshot create selection
	BEGIN
		SET @DeleteCurrentSnapshot = 1;	
		SET @CreateNewSnapshot = 1;	
	END
ELSE
	BEGIN
		SET @DeleteCurrentSnapshot = 0;
		SET @CreateNewSnapshot = 0;
	END

----This logic is pulled out of the above because on the first round 
		IF @SnapshotCompareBegin IS NULL
			BEGIN
				SET @DeleteCurrentSnapshot = 0;
				SET @CreateNewSnapshot = 1;
			END
--END --Snapshot create selection

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
--SnapshotDelta is the diff between now and the last recorded snapshot.  It'll tell us at a glance if something's not right.
	INSERT Minion.CheckDBDebugSnapshotThreads (ExecutionDateTime, CurrentDateTime, RunType, DBName, SnapshotDBName, SPName, SnapshotCompareBegin, SnapshotRetMins, SnapshotDelta, DeleteCurrentSnapshot, CreateNewSnapshot, Thread, SnapshotCreationOwner)
	SELECT @ExecutionDateTime, GETDATE(), 'Set Snapshot Create Values', @DBName, @CurrentSnapshotDBName, 'CheckTable', @SnapshotCompareBegin, @SnapshotRetMins, ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0), @DeleteCurrentSnapshot, @CreateNewSnapshot, @Thread, @SnapshotCreationOwner
END
-------------------DEBUG-------------------------------

------------------------------------------------------------------------
------------------------BEGIN Snapshot Size-----------------------------
------------------------------------------------------------------------
----Get the final size of the snapshot before we delete it.
IF @CreateSnapshot = 1
	BEGIN
		UPDATE SL 
		SET SL.SizeInKB = S.BytesOnDisk/1024
		FROM Minion.CheckDBSnapshotLog SL 
		INNER JOIN fn_virtualfilestats(db_id(@CurrentSnapshotDBName),null) S
		ON	SL.FileID = S.FileId
		WHERE SL.ExecutionDateTime = @ExecutionDateTime
		AND SL.SnapshotDBName = @CurrentSnapshotDBName;

		SET @TotalSnapshotSize = (SELECT SUM(ISNULL(SizeInKB, 0)) FROM Minion.CheckDBSnapshotLog SL
		WHERE SL.ExecutionDateTime = @ExecutionDateTime
		AND SL.SnapshotDBName = @CurrentSnapshotDBName);
	END
------------------------------------------------------------------------
------------------------END Snapshot Size-------------------------------
------------------------------------------------------------------------

-------If @SnapshotRetMins = 0 that means that we want only 1 custom snapshot for the entire run.
-------Therefore, the 1st run will still need to have the snapshot created and any subsequent run will need to use that same snapshot.
-------Hence the logic below.  The 1st run will see @SnapshotCompareBegin as NULL and any run after that will have a datetime.
-------So if we look for the datetime to be populated when we have 0 RetMins then we just set the hardcode values here.
IF @SnapshotCompareBegin IS NOT NULL AND @SnapshotRetMins = 0
	BEGIN
		SET @CreateNewSnapshot = 0;
		SET @DeleteCurrentSnapshot = 0;
	END

----SELECT @SnapshotCompareBegin AS SnapshotCompareBegin, @CreateSnapshot AS CreateSnapshot, @CreateNewSnapshot AS CreateNewSnapshot, ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0) AS SnapshotTimeMins, @DeleteCurrentSnapshot AS DeleteCurrentSnapshot, @CurrentSnapshotDBName AS CurrentSnapshotDBName, @DBName AS CurrentDBName

----SET @DeleteCurrentSnapshot = 0;--Testing
IF @DeleteCurrentSnapshot = 1
BEGIN --@DeleteCurrentSnapshot = 1
	----Delete previous snapshot----
	IF (@CurrentSnapshotDBName <> @DBName AND @CurrentSnapshotDBName IS NOT NULL)
		BEGIN --Delete Previous Snapshot
			----We can only delete snapshots. It would be very bad to delete the source DB, so test that it's a snapshot here.
			IF (SELECT COUNT(*) FROM sys.databases WHERE name = @CurrentSnapshotDBName AND source_database_id IS NOT NULL) > 0
			BEGIN --Run Snapshot Delete

			SET @SnapshotCMD = 'DROP DATABASE [' + @CurrentSnapshotDBName + '];'
-------------------------BEGIN Run Stmt-----------------------
					
                    SET @PreCMD = 'sqlcmd -r 1 -S"' + @ServerInstance
                        + CAST(@Port AS VARCHAR(6)) + '"'
						+ ' -d "master" -q "' 
                    SET @TotalCMD = @PreCMD
                        + @SnapshotCMD + '"'

                    INSERT #SnapshotDeleteResults
                            (col1)
                            EXEC xp_cmdshell @TotalCMD;

							DELETE FROM #SnapshotDeleteResults
								   WHERE col1 IS NULL
									  OR col1 = 'output'
									  OR col1 = 'NULL'
									  OR col1 LIKE '%-------------------------------------%'

							SELECT
										@SnapshotErrors = 'SNAPSHOT DELETE ERROR: '
										+ STUFF((SELECT ' ' + col1
											FROM #SnapshotResults AS T1
											ORDER BY T1.ID
											FOR XML PATH('')), 1, 1, '')
									FROM
										#SnapshotDeleteResults AS T2;

					----SET @CreateNewSnapshot = 1;
-------------------------END Run Stmt-------------------------
		END --Run Snapshot Delete
	END  --Delete Previous Snapshot
END --@DeleteCurrentSnapshot = 1
-----------------------------------------------------------------------------------
-------------------------END Delete Snapshot---------------------------------------
-----------------------------------------------------------------------------------	


----If the previous snapshot was deleted then we should be good to go to create a new one.
----At this point we don't have to worry about whether enough time has passed because that logic was
----taken care of above when we deleted.  So here we can just be concerned with creating the snapshot itself.
--SET @CreateNewSnapshot = 1;

IF @CreateNewSnapshot = 1 OR @CreateNewSnapshot IS NULL
	BEGIN --@CreateNewSnapshot = 1

	----Prepare table for current run.
	TRUNCATE TABLE #CheckDBSnapshot;

	INSERT #CheckDBSnapshot
			(SnapshotDBName, FileID, TypeDesc, Name, PhysicalName, IsReadOnly, IsSparse,
			 SnapshotDrive, SnapshotPath, FullPath, ServerLabel, PathOrder, Cmd, SizeInKB, MaxSizeInKB)
	EXEC Minion.CheckDBSnapshotGet @DBName = @DBName, @OpName = @Op;

----Here we've already decided to create a new snapshot, so setting the CurrentSnapshotDBName doesn't take any further logic.
	SELECT TOP 1 
		@SnapshotCMD = Cmd,
		@CurrentSnapshotDBName = SnapshotDBName
	FROM #CheckDBSnapshot;

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
--SnapshotDelta is the diff between now and the last recorded snapshot.  It'll tell us at a glance if something's not right.
	INSERT Minion.CheckDBDebugSnapshotThreads (ExecutionDateTime, CurrentDateTime, RunType, DBName, SnapshotDBName, SPName, SnapshotCompareBegin, SnapshotRetMins, SnapshotDelta, Thread, SnapshotCreationOwner)
	SELECT @ExecutionDateTime, GETDATE(), 'New Snapshot DBName', @DBName, @CurrentSnapshotDBName, 'CheckTable', @SnapshotCompareBegin, @SnapshotRetMins, ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0), @Thread, @SnapshotCreationOwner
END
-------------------DEBUG-------------------------------

----Here we need to pass this to a work table so other SPs can get at it easily.
INSERT Minion.CheckDBSnapshotLog (ExecutionDateTime, OpName, DBName, SnapshotDBName, FileID, TypeDesc, Name, PhysicalName, IsReadOnly, IsSparse, SnapshotDrive, SnapshotPath, FullPath, ServerLabel, PathOrder, Cmd, SizeInKB, MaxSizeInKB)
SELECT @ExecutionDateTime, @Op, @DBName, SnapshotDBName, FileID, TypeDesc, Name, PhysicalName, IsReadOnly, IsSparse, SnapshotDrive, SnapshotPath, FullPath, ServerLabel, PathOrder, Cmd, SizeInKB, MaxSizeInKB
FROM #CheckDBSnapshot
----SELECT ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0) AS SnapshotTimeMins, @DeleteCurrentSnapshot, @CurrentSnapshotDBName, @DBName


	--------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------
	------------------------BEGIN Create Directories--------------------------------------
	--------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------

		EXEC Minion.CheckDBSnapshotDirCreate @ExecutionDateTime = @ExecutionDateTime, @DBName = @DBName, @Op = @Op

	--------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------
	------------------------END Create Directories----------------------------------------
	--------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------


	--------------------------------------------------------------------------------------
	------------------------BEGIN Run Snapshot Stmt---------------------------------------
	--------------------------------------------------------------------------------------
						SET @SnapshotCompareBegin = GETDATE();					
						SET @PreCMD = 'sqlcmd -r 1 -S"' + @ServerInstance
							+ CAST(@Port AS VARCHAR(6)) + '"'
							+ ' -d "master" -q "' 
						SET @TotalCMD = @PreCMD
							+ @SnapshotCMD + '"'
--PRINT @TotalCMD
						INSERT #SnapshotResults
								(col1)
								EXEC xp_cmdshell @TotalCMD;

				-------------------DEBUG-------------------------------
				IF @Debug = 1
				BEGIN
				--SnapshotDelta is the diff between now and the last recorded snapshot.  It'll tell us at a glance if something's not right.
					INSERT Minion.CheckDBDebugSnapshotCreate (ExecutionDateTime, CurrentDateTime, DBName, SnapshotDBName, SPName, SnapshotCompareBegin, SnapshotRetMins, SnapshotDelta, Thread, SnapshotCreationOwner, CheckDBCmd)
					SELECT @ExecutionDateTime, GETDATE(), @DBName, @CurrentSnapshotDBName, 'CheckTable', @SnapshotCompareBegin, @SnapshotRetMins, ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0), @Thread, @SnapshotCreationOwner, @TotalCMD
				END
				-------------------DEBUG-------------------------------

	--------------------------------------------------------------------------------------
	------------------------END Run Snapshot Stmt-----------------------------------------
	--------------------------------------------------------------------------------------


	--------------------------------------------------------------------------------------
	------------------------BEGIN Get Snapshot Errors-------------------------------------
	--------------------------------------------------------------------------------------
								DELETE FROM #SnapshotResults
									   WHERE col1 IS NULL									 

								SELECT
									@SnapshotErrors = 'SNAPSHOT CREATE ERROR: '
									+ STUFF((SELECT ' ' + col1
										FROM #SnapshotResults AS T1
										ORDER BY T1.ID
										FOR XML PATH('')), 1, 1, '')
								FROM
									#SnapshotResults AS T2;
	--------------------------------------------------------------------------------------
	------------------------END Get Snapshot Errors---------------------------------------
	--------------------------------------------------------------------------------------

	------------------------BEGIN Log Snapshot Errors-----------------------
						IF @SnapshotErrors <> '' OR @SnapshotErrors IS NOT NULL
							BEGIN --Log Snapshot Errors
								UPDATE Minion.CheckDBLogDetails
									SET
										STATUS = 'FATAL ERROR: Snapshot creation failed.  ACTUAL ERROR FOLLOWS: '
										+ @SnapshotErrors
									WHERE
										ID = @CheckDBLogDetailsID;

								RETURN ----If the snapshot fails the job is over.
							END --Log Snapshot Errors
	------------------------END Log Snapshot Errors----------------------

END --@CreateNewSnapshot = 1
END --@OnlineEdition = 1

END --@CreateSnapshot = 1
END --@StmtOnly = 0
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
------------------------------------END Create Snapshot------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
--SnapshotDelta is the diff between now and the last recorded snapshot.  It'll tell us at a glance if something's not right.
	INSERT Minion.CheckDBDebugSnapshotThreads (ExecutionDateTime, CurrentDateTime, RunType, DBName, SnapshotDBName, SPName, SnapshotCompareBegin, SnapshotRetMins, SnapshotDelta, Thread, SnapshotCreationOwner)
	SELECT @ExecutionDateTime, GETDATE(), 'End Create Snapshot', @DBName, @CurrentSnapshotDBName, 'CheckTable', @SnapshotCompareBegin, @SnapshotRetMins, ISNULL(DATEDIFF(MINUTE, @SnapshotCompareBegin, GETDATE()), 0), @Thread, @SnapshotCreationOwner
END
-------------------DEBUG-------------------------------

	 SET @CheckDBRunSQL = '';

IF @CurrentSnapshotDBName IS NULL
	BEGIN
		SET @CurrentSnapshotDBName = @DBName;
	END

-----------------------------------------------------------------
------------------BEGIN Update SnapshotQueue---------------------
-----------------------------------------------------------------
----Now that the snapshot has been created, the info should be there so the rest of the threads can use it.
----So we update the info, and release the owner.
IF @Thread > 0
	BEGIN
		UPDATE Minion.CheckDBTableSnapshotQueue WITH (TABLOCKX)
			SET LatestSnapshotDateTime = @SnapshotCompareBegin,
				SnapshotDBName = @CurrentSnapshotDBName,
				[Owner] = NULL
			WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName;
	END
-----------------------------------------------------------------
------------------END Update SnapshotQueue-----------------------
-----------------------------------------------------------------



 --------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------------------------
 -------------------------------BEGIN Create CheckTable Stmt---------------------------------
 --------------------------------------------------------------------------------------------
 -------------------------------------------------------------------------------------------- 

SET @CheckDBSQL = ''; 

SET @CheckDBSQL = 'USE [' + @CurrentSnapshotDBName + '];' + ISNULL(@currStmtPrefix, '') + 'DBCC CHECKTABLE(''''' + @currSchemaName + '.' + @currTableName + ''''''

IF @currIndexName IS NOT NULL AND @currIndexName <> ''
	BEGIN
		SET @CheckDBSQL = @CheckDBSQL + ', ' + '''' + @currIndexName + '''';
	END

----Set initial repair option.  It will be overwritten if there's a repair option being used.
SET @IsRepair = 0;
----This is just an easy way for the rest of the routine to see if repair is being used.
IF (@RepairOption IS NOT NULL AND @RepairOption <> 'NONE')
	BEGIN
		SET @IsRepair = 1;
	END

----We want RepairOption to be more important than NoIndex, so if they're both present, 
----RepairOption will win.
IF @currNoIndex = 1 AND @IsRepair = 0
	BEGIN
		SET @CheckDBSQL = @CheckDBSQL + ', NOINDEX'
	END

IF @IsRepair = 1
	BEGIN
		IF @currRepairOptionAgree = 1
			BEGIN
				SET @CheckDBSQL = @CheckDBSQL + ', ' + @currRepairOption
			END
	END

SET @CheckDBSQL = @CheckDBSQL + ')'
SET @CheckDBSQL = @CheckDBSQL + ' WITH '

IF @currAllErrorMsgs = 1
	BEGIN
		SET @CheckDBSQL = @CheckDBSQL + 'ALL_ERRORMSGS, '
	END

IF @currExtendedLogicalChecks = 1
	BEGIN
		SET @CheckDBSQL = @CheckDBSQL + 'EXTENDED_LOGICAL_CHECKS, '
	END

IF @currNoInfoMsgs = 1
	BEGIN
		SET @CheckDBSQL = @CheckDBSQL + 'NO_INFOMSGS, '
	END

IF @currIsTabLock = 1
	BEGIN
		SET @CheckDBSQL = @CheckDBSQL + 'TABLOCK, '
	END

IF @currIntegrityCheckLevel IS NOT NULL
	BEGIN
		--IF UPPER(@currIntegrityCheckLevel) <> 'PHYSICAL_ONLY'
			BEGIN
				SET @CheckDBSQL = @CheckDBSQL + @currIntegrityCheckLevel + ', '
			END
	END

		BEGIN  
			SET @CheckDBSQL = @CheckDBSQL + 'TABLERESULTS; ' ----LEFT(@CheckDBSQL, LEN(@CheckDBSQL) - 5);
		END


----If there are no options we need to get rid of the WITH.
	IF ( SUBSTRING(@CheckDBSQL, LEN(RTRIM(@CheckDBSQL)), 5) = ' WITH ' ) 
		BEGIN  
			SET @CheckDBSQL = @CheckDBSQL + ' TABLERESULTS; ' ----LEFT(@CheckDBSQL, LEN(@CheckDBSQL) - 5);
		END

		SET @CheckDBSQL = @CheckDBSQL + ISNULL(@currStmtPrefix, '')

 --------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------------------------
 -------------------------------END Create CheckDB Stmt--------------------------------------
 --------------------------------------------------------------------------------------------
 -------------------------------------------------------------------------------------------- 



-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------BEGIN TablePreCode----------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------	

        IF @StmtOnly = 0
            BEGIN -- @StmtOnly = 0

-----BEGIN Log------
                IF @currTablePreCode IS NOT NULL
                    BEGIN -- @DBPreCode
                        IF @StmtOnly = 0
                            BEGIN -- @StmtOnly = 0
                                SET @TablePreCodeStartDateTime = GETDATE();

                                BEGIN
                                    UPDATE Minion.CheckDBLogDetails
                                        SET
                                            STATUS = 'Precode running',
                                            TablePreCodeStartDateTime = @TablePreCodeStartDateTime,
                                            TablePreCode = @currTablePreCode
                                        WHERE
                                            ID = @CheckDBLogDetailsID;
                                END
                            END -- @StmtOnly = 0
                    END -- @@DBPreCode
------END Log-------

                IF @currTablePreCode IS NOT NULL
                    BEGIN -- @DBPreCode
-----------------BEGIN Log DBPreCode------------------
                        UPDATE Minion.CheckDBLogDetails
                            SET
                                TablePreCode = @currTablePreCode,
                                TablePreCodeStartDateTime = @TablePreCodeStartDateTime
                            WHERE
                                ID = @CheckDBLogDetailsID;
-----------------END Log DBPreCode--------------------

--------------------------------------------------
----------------BEGIN Run Precode-----------------
--------------------------------------------------
                        ----DECLARE
                        ----    @PreCodeErrors VARCHAR(MAX),
                        ----    @PreCodeErrorExist VARCHAR(MAX);
                        ----CREATE TABLE #PreCode
                        ----    (
                        ----     ID INT IDENTITY(1, 1),
                        ----     col1 VARCHAR(MAX)
                        ----    )

                        BEGIN TRY
                            EXEC (@currTablePreCode) 
                        END TRY

                        BEGIN CATCH
                            SET @PreCodeErrors = ERROR_MESSAGE();
                        END CATCH

                        IF @PreCodeErrors IS NOT NULL
                            BEGIN
                                SELECT @PreCodeErrors = 'PRECODE ERROR: '
                                        + @PreCodeErrors
                            END	 

--------------------------------------------------
----------------END Run Precode-------------------
--------------------------------------------------
                    END -- @DBPreCode


-----BEGIN Log------

                IF @currTablePreCode IS NOT NULL
                    BEGIN -- @DBPreCode
                        IF @StmtOnly = 0
                            BEGIN -- @StmtOnly = 0

-----------------------------------------------------
-------------BEGIN Log PreCode Success---------------
-----------------------------------------------------
                                IF @PreCodeErrors IS NULL
                                    BEGIN --@PreCodeErrors IS NULL
                                        SET @TablePreCodeEndDateTime = GETDATE();
                                        UPDATE Minion.CheckDBLogDetails
                                            SET
                                                TablePreCodeEndDateTime = @TablePreCodeEndDateTime,
                                                TablePreCodeTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @TablePreCodeStartDateTime, 21), CONVERT(VARCHAR(25), @TablePreCodeEndDateTime, 21))
                                            WHERE
                                                ID = @CheckDBLogDetailsID;
                                    END --@PreCodeErrors IS NULL
-----------------------------------------------------
-------------END Log PreCode Success-----------------
-----------------------------------------------------

-----------------------------------------------------
-------------BEGIN Log PreCode Failure---------------
-----------------------------------------------------
                                IF @PreCodeErrors IS NOT NULL
                                    BEGIN --@PreCodeErrors IS NULL
                                        SET @TablePreCodeEndDateTime = GETDATE();
                                        UPDATE Minion.CheckDBLogDetails
                                            SET
                                                Warnings = ISNULL(Warnings, '')
                                                + @PreCodeErrors,
                                                TablePreCodeEndDateTime = @TablePreCodeEndDateTime,
                                                TablePreCodeTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @TablePreCodeStartDateTime, 21), CONVERT(VARCHAR(25), @TablePreCodeEndDateTime, 21))
                                            WHERE
                                                ID = @CheckDBLogDetailsID;
                                    END --@PreCodeErrors IS NULL
-----------------------------------------------------
-------------END Log PreCode Failure-----------------
-----------------------------------------------------
                            END -- @StmtOnly = 0
                    END -- @@DBPreCode

------END Log-------

SET @currTablePreCode = NULL;
SET @PreCodeErrors = NULL;
            END -- @StmtOnly = 0
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------END TablePreCode------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------



------------------------------------------------
----------------BEGIN PRINT---------------------
------------------------------------------------
IF @StmtOnly = 1
	BEGIN
		PRINT REPLACE(@CheckDBSQL, '''''', '''');
		--RETURN
	END
------------------------------------------------
----------------END PRINT-----------------------
------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
----------------------------------------BEGIN Run CheckTable-------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
----SELECT @DBTempTable, @DBTempTableDate, @CheckDBSQL, @MaintDB, @ExecutionDateTime, @DBName

IF @StmtOnly = 0
	BEGIN --Create Run Stmt
	 SET @BeginTime = GETDATE();
----We're creating a specific #table because if we get multithreading done we don't want any bleeding between executions. So we're hoping each DB and run can have its own #table this way.
	SET @CheckDBRunSQL = 'SET NOCOUNT ON;CREATE TABLE #' + @DBTempTable + @DBTempTableDate + '([ExecutionDateTime] [DATETIME] NULL,[DBName] [sysname] NULL,[BeginTime] [DATETIME] NULL,[EndTime] [DATETIME] NULL,[Error] [INT] NULL,[Level] [INT] NULL,[State] [INT] NULL,[MessageText] [VARCHAR](7000) NULL,[RepairLevel] [NVARCHAR](50) NULL,[Status] [INT] NULL,[DbId] [INT] NULL,[DbFragId] [INT] NULL,[ObjectId] [BIGINT] NULL,[IndexID] [INT] NULL,[PartitionId] [BIGINT] NULL,[AllocUnitId] [BIGINT] NULL,[RidDBId] [INT] NULL,[RidPruId] [INT] NULL,[File] [INT] NULL,[Page] [BIGINT] NULL,[Slot] [BIGINT] NULL,[RefDbId] [INT] NULL,[RefPruId] [INT] NULL,[RefFile] [BIGINT] NULL,[RefPage] [BIGINT] NULL,[RefSlot] [BIGINT] NULL,[Allocation] [INT] NULL);'
	+
	---------------------------BEGIN Insert for CheckDB Cmd------------------------------
	--SQL08 and below.
	CASE WHEN @Version < '11' THEN
	 'INSERT INTO #' + @DBTempTable + @DBTempTableDate + '(Error, Level, State, MessageText, RepairLevel, Status, DbId, ObjectId, IndexID, PartitionId, AllocUnitId, [File], [Page], Slot, RefFile, RefPage, RefSlot, Allocation)'
	--SQL2012 and up.
		WHEN @Version >= '11' THEN	
	+ 'INSERT INTO #' + @DBTempTable + @DBTempTableDate + '(Error, Level, State, MessageText, RepairLevel, Status, DbId, DbFragId, ObjectId, IndexID, PartitionId, AllocUnitId, RidDBId, RidPruId, [File], [Page], Slot, RefDbId, RefPruId, RefFile, RefPage, RefSlot, Allocation)'
	END
	+ 'EXEC (''' + @CheckDBSQL + ''');'
	---------------------------END Insert for CheckDB Cmd--------------------------------
	+
	---------------------------BEGIN Insert for #Table------------------------------
	--SQL08 and below.
	CASE WHEN @Version < '11' THEN	   
	'INSERT INTO [' + @MaintDB + '].Minion.CheckDBCheckTableResult(ExecutionDateTime, DBName,Error, Level, State, MessageText, RepairLevel, Status, DbId, ObjectId, IndexID, PartitionId, AllocUnitId, [File], [Page], Slot, RefFile, RefPage, RefSlot, Allocation)'
	--SQL2012 and up.
		WHEN @Version >= '11' THEN	
	'INSERT INTO [' + @MaintDB + '].Minion.CheckDBCheckTableResult(ExecutionDateTime, DBName,Error, Level, State, MessageText, RepairLevel, Status, DbId, DbFragId, ObjectId, IndexID, PartitionId, AllocUnitId, RidDBId, RidPruId, [File], [Page], Slot, RefDbId, RefPruId, RefFile, RefPage, RefSlot, Allocation)'
	END
	+ 'SELECT ''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''',' + '''' + @DBName + ''','
	+
	--SQL08 and below.
	CASE WHEN @Version < '11' THEN
	'Error, Level, State, MessageText, RepairLevel, Status, DbId, ObjectId, IndexID, PartitionId, AllocUnitId, [File], [Page], Slot, RefFile, RefPage, RefSlot, Allocation FROM #' + @DBTempTable + @DBTempTableDate 
		--SQL2012 and up.
		WHEN @Version >= '11' THEN
	'Error, Level, State, MessageText, RepairLevel, Status, DbId, DbFragId, ObjectId, IndexID, PartitionId, AllocUnitId, RidDBId, RidPruId, [File], [Page], Slot, RefDbId, RefPruId, RefFile, RefPage, RefSlot, Allocation FROM #' + @DBTempTable + @DBTempTableDate 
	END
	END --Create Run Stmt
	---------------------------END Insert for #Table--------------------------------

--------------------------------------------------------------------
----------------------BEGIN Log Op Start----------------------------
--------------------------------------------------------------------
                UPDATE Minion.CheckDBLogDetails
				SET 
					STATUS = UPPER(@Op) + ' running', 
					PctComplete = 0,
					NETBIOSName = @NETBIOSName,
					IsClustered = @IsClustered,
					CheckDBName = @CurrentSnapshotDBName,
					OpBeginTime = @BeginTime,
					CheckDBCmd = REPLACE(@CheckDBSQL, '''''', ''''),
					CustomSnapshot = @CreateSnapshot,
					MaxSnapshotSizeInKB = @TotalSnapshotSize,
					LastCheckDateTime = ISNULL(CAST(@LastMinionCheckDBDate AS DATETIME), '1/1/1900 00:00:00.000'),
					LastCheckResult = ISNULL(@LastMinionCheckDBResult, 'N/A')
                WHERE ID = @CheckDBLogDetailsID;

--------------------------------------------------------------------
----------------------END Log Op Start------------------------------
--------------------------------------------------------------------


DECLARE @CheckTableExecutionError VARCHAR(max);
SET @CheckTableExecutionError = NULL; --Reset from last run.
SET @PreCMD = '';
SET @TotalCMD = '';
	SET @PreCMD = 'sqlcmd -r 1 -S"' + @ServerInstance + '"' -- + ISNULL(@Port, '')
		+ ' -d "' + @MaintDB + '" -q "' 
	SET @TotalCMD = @PreCMD + @CheckDBRunSQL + '"'
	TRUNCATE TABLE #CheckTableResults;
--SELECT 'here'--, @TotalCMD
	INSERT #CheckTableResults(col1)
	EXEC xp_cmdshell @TotalCMD;

	SET @EndTime = GETDATE();
----WAITFOR DELAY '00:00:05'
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
----------------------------------------END Run CheckTable---------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

IF @StmtOnly = 0
	BEGIN --@StmtOnly = 0 Post-table processing
	DELETE FROM #CheckTableResults WHERE col1 IS NULL
	DELETE FROM #CheckTableResults WHERE col1 LIKE '%DBCC execution completed%'
	DELETE FROM #CheckTableResults WHERE col1 LIKE '%is the minimum repair level for the errors found by DBCC CHECKTABLE%'
	SET @CheckTableExecutionError = NULL;
	SELECT @CheckTableExecutionError = STUFF((SELECT' ' + col1
                                                FROM #CheckTableResults AS T1
                                                ORDER BY T1.ID
                                            FOR XML PATH('')), 1, 1, '')
                        FROM #CheckTableResults AS T2;

	

			--------------------BEGIN Update Begin/End times and Schema/Table names-----------------
			----As of yet the results table doesn't have the schema/table names so we need to add them.
			----This is also where we get to put in the begin and end times of each table's runtime.
			----We're keeping the data in this table too in case they choose to keep the detailed CHECKTABLE data.
			----So we're providing this to make it easier to query the data should you need.  
			----It can also be joined with the Minion log data if needed.
	SET @SQL = '';
	SET @SQL = 'USE [' + @DBName + ']; UPDATE ' + @MaintDB + '.Minion.CheckDBCheckTableResult' 
			+ ' SET BeginTime = ''' + CONVERT(VARCHAR(30), @BeginTime, 21) + ''',' 
			+ ' EndTime = ''' + CONVERT(VARCHAR(30), @EndTime, 21) + ''''
			+ ', SchemaName = OBJECT_SCHEMA_NAME(ObjectId)'
			+ ', TableName = OBJECT_NAME(ObjectId)'
			+ ' WHERE ExecutionDateTime = ''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''''
			+ ' AND DBName = ''' + @DBName + ''' AND SchemaName IS NULL;'

	EXEC(@SQL) 
			--------------------END Update Begin/End times and Schema/Table names-------------------

			--------------------BEGIN Update Index Info-----------------
			----Add index names and types so they can be logged later.
			----This is a courtesy to anyone trying to troubleshoot their process.  Give them the info they need instead of making them look it up.
	SET @SQL = '';
	SET @SQL = 'USE [' + @DBName + ']; UPDATE CT ' + 'SET CT.IndexName = si.name, '
			+ 'CT.IndexType = si.type_desc '
			+ 'FROM ' + @MaintDB + '.Minion.CheckDBCheckTableResult CT INNER JOIN sys.indexes si ON CT.ObjectId = si.object_id AND CT.IndexID = si.index_id' 
			+ ' WHERE ExecutionDateTime = ''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''''
			+ ' AND DBName = ''' + @DBName + ''' AND IndexType IS NULL;'

	EXEC(@SQL) 
			--------------------END Update Index Info-------------------


-------------------------------------------------------------------------
-------------------------------------------------------------------------
---------------BEGIN Get Error CTs---------------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------
DECLARE @CheckTableAllocationErrorCT INT,
		@CheckTableConsistencyErrorCT INT,
		@CheckTableErrorSummary varchar(1000);

SET @CheckTableErrorSummary = (SELECT MessageText FROM Minion.CheckDBCheckTableResult WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName AND SchemaName = @currSchemaName AND TableName = @currTableName AND MessageText LIKE '%CheckTable found%allocation errors and%consistency errors in table%')		

        BEGIN -- <> All
			
            DECLARE @CheckTableErrorSummaryTable TABLE ( ID TINYINT IDENTITY(1,1), DBName VARCHAR(500) );
            DECLARE @CheckTableErrorSummaryString VARCHAR(500);
            WHILE LEN(@CheckTableErrorSummary) > 0 
                BEGIN --WHILE
                    SET @CheckTableErrorSummaryString = LEFT(@CheckTableErrorSummary,
                                                    ISNULL(NULLIF(CHARINDEX(' ',
                                                              @CheckTableErrorSummary) - 1,
                                                              -1),
                                                           LEN(@CheckTableErrorSummary)))
                    SET @CheckTableErrorSummary = SUBSTRING(@CheckTableErrorSummary,
                                             ISNULL(NULLIF(CHARINDEX(' ',
                                                              @CheckTableErrorSummary), 0),
                                                    LEN(@CheckTableErrorSummary)) + 1,
                                             LEN(@CheckTableErrorSummary))

                    INSERT  INTO @CheckTableErrorSummaryTable
                            ( DBName )
                    VALUES  ( @CheckTableErrorSummaryString )
                END --WHILE 
		END -- <> All

--SELECT @currTableName, @CheckTableErrorSummary AS TableSummary
--UPDATE @CheckTableErrorSummaryTable SET DBName = 12324543 WHERE ID = 3
--UPDATE @CheckTableErrorSummaryTable SET DBName = 999898 WHERE ID = 7
SET @CheckTableAllocationErrorCT = ISNULL((SELECT DBName FROM @CheckTableErrorSummaryTable WHERE ID = 3), 0)
SET @CheckTableConsistencyErrorCT = ISNULL((SELECT DBName FROM @CheckTableErrorSummaryTable WHERE ID = 7), 0)
--SELECT @CheckTableAllocationErrorCT, @CheckTableConsistencyErrorCT
DELETE  @CheckTableErrorSummaryTable;
-------------------------------------------------------------------------
-------------------------------------------------------------------------
---------------END Get Error CTs-----------------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------
----SELECT @CheckTableExecutionError AS TableErrorVar
----Log CHECKTABLE error.
IF @CheckTableExecutionError IS NOT NULL
	BEGIN
		UPDATE Minion.CheckDBLogDetails
			SET
				STATUS = 'FATAL ERROR: ' + @CheckTableExecutionError,
				PctComplete = 100,
				OpEndTime = @EndTime,
				OpRunTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @BeginTime, 21), CONVERT(VARCHAR(25), @EndTime, 21)),
				AllocationErrors = @CheckTableAllocationErrorCT,
				ConsistencyErrors = @CheckTableConsistencyErrorCT,
				TablePostCodeStartDateTime = @TablePostCodeStartDateTime,
				TablePostCode = @currTablePostCode
			WHERE
				ID = @CheckDBLogDetailsID;
	END

END --@StmtOnly = 0 Post-table processing
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------BEGIN TablePostCode----------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------	


        IF @StmtOnly = 0
            BEGIN -- @StmtOnly = 0 Table Postcode

-------------------------------------------------------
-----------------BEGIN Log DBPostCode Start------------
-------------------------------------------------------
                IF @currTablePostCode IS NOT NULL
                    BEGIN -- @DBPostCode Log Start
							IF @CheckTableExecutionError IS NULL
								BEGIN --Error is NULL
									SET @TablePostCodeStartDateTime = GETDATE();

									BEGIN --Update
										UPDATE Minion.CheckDBLogDetails
											SET
												STATUS = 'Postcode running',
												TablePostCodeStartDateTime = @TablePostCodeStartDateTime,
												TablePostCode = @currTablePostCode
											WHERE
												ID = @CheckDBLogDetailsID;
									END --Update
								END --Error is NULL

                    END -- @@DBPostCode Log Start
-------------------------------------------------------
-----------------END Log DBPostCode Start--------------
-------------------------------------------------------


------------------------------------------------------------------------
---------------------------BEGIN Run Postcode---------------------------
------------------------------------------------------------------------
				----Only run postcode if there were no errors in the checktable execution.
				----This doesn't count for errors checktable found, just for errors in the execution itself like bad syntax, etc.

                IF @currTablePostCode IS NOT NULL
                    BEGIN -- @DBPostCode IS NOT NULL
				IF @CheckTableExecutionError IS NULL
					BEGIN --Error is NULL
							DECLARE
								@PostCodeErrors VARCHAR(MAX);

							BEGIN TRY
								EXEC (@currTablePostCode) 
							END TRY

							BEGIN CATCH
								SET @PostCodeErrors = ERROR_MESSAGE();
							END CATCH

							IF @PostCodeErrors IS NOT NULL
								BEGIN
									SELECT @PostCodeErrors = 'PostCODE ERROR: '
											+ @PostCodeErrors
								END	 
						END --Error is NULL
                    END -- @DBPostCode IS NOT NULL
------------------------------------------------------------------------
---------------------------END Run Postcode-----------------------------
------------------------------------------------------------------------

		IF @CheckTableExecutionError IS NULL
			BEGIN --CheckTable Error is NULL		
                IF @currTablePostCode IS NOT NULL
                    BEGIN -- @DBPostCode

-----------------------------------------------------
-------------BEGIN Log PostCode Success---------------
-----------------------------------------------------
                                IF @PostCodeErrors IS NULL
                                    BEGIN --@PostCodeErrors IS NULL
                                        SET @TablePostCodeEndDateTime = GETDATE();
                                        UPDATE Minion.CheckDBLogDetails
                                            SET
                                                TablePostCodeEndDateTime = @TablePostCodeEndDateTime,
                                                TablePostCodeTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @TablePostCodeStartDateTime, 21), CONVERT(VARCHAR(25), @TablePostCodeEndDateTime, 21))
                                            WHERE
                                                ID = @CheckDBLogDetailsID;
                                    END --@PostCodeErrors IS NULL
-----------------------------------------------------
-------------END Log PostCode Success-----------------
-----------------------------------------------------

-----------------------------------------------------
-------------BEGIN Log PostCode Failure---------------
-----------------------------------------------------
                                IF @PostCodeErrors IS NOT NULL
                                    BEGIN --@PostCodeErrors IS NULL
                                        SET @TablePostCodeEndDateTime = GETDATE();
                                        UPDATE Minion.CheckDBLogDetails
                                            SET
                                                Warnings = ISNULL(Warnings, '')
                                                + @PostCodeErrors,
                                                TablePostCodeEndDateTime = @TablePostCodeEndDateTime,
                                                TablePostCodeTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @TablePostCodeStartDateTime, 21), CONVERT(VARCHAR(25), @TablePostCodeEndDateTime, 21))
                                            WHERE
                                                ID = @CheckDBLogDetailsID;
                                    END --@PostCodeErrors IS NULL
-----------------------------------------------------
-------------END Log PostCode Failure-----------------
-----------------------------------------------------
                    END -- @@DBPostCode

					SET @currTablePostCode = NULL;
					SET @PostCodeErrors = NULL;
				--END -- @StmtOnly = 0 Table Postcode
			END --CheckTable Error is NULL
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------END TablePostCode------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------



--------------------------------------------------------------------
----------------------BEGIN Log Op End------------------------------
--------------------------------------------------------------------
		IF @CheckTableExecutionError IS NULL
			BEGIN --Error is NULL
                UPDATE Minion.CheckDBLogDetails
				SET 
					STATUS = CASE WHEN (STATUS NOT LIKE '%FATAL ERROR%' AND (@CheckTableAllocationErrorCT = 0 AND @CheckTableConsistencyErrorCT = 0) AND @CheckTableExecutionError IS NULL) THEN 'Complete'
								  WHEN (STATUS NOT LIKE '%FATAL ERROR%' AND (@CheckTableAllocationErrorCT > 0 OR @CheckTableConsistencyErrorCT > 0) AND @CheckTableExecutionError IS NULL) THEN 'Complete (' + CAST((@CheckTableConsistencyErrorCT + @CheckTableAllocationErrorCT) AS VARCHAR(10)) + ' ' + UPPER(@Op) + ' error' + CASE WHEN (@CheckTableConsistencyErrorCT + @CheckTableAllocationErrorCT) > 1 THEN 's' ELSE '' END + ' found)'
								  --WHEN (STATUS NOT LIKE '%FATAL ERROR%' AND @CheckTableAllocationErrorCT = 0 AND @CheckTableConsistencyErrorCT = 0 AND @CheckTableExecutionError IS NULL) THEN 'Complete'
								  --ELSE 'Complete with Errors'
							 END, 
					PctComplete = 100,
					OpEndTime = @EndTime,
					OpRunTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @BeginTime, 21), CONVERT(VARCHAR(25), @EndTime, 21)),
					AllocationErrors = @CheckTableAllocationErrorCT,
					ConsistencyErrors = @CheckTableConsistencyErrorCT
                WHERE ID = @CheckDBLogDetailsID
			END --Error is NULL
--------------------------------------------------------------------
----------------------END Log Op End--------------------------------
--------------------------------------------------------------------


---------------------------------------------------------------------
---------------------------------------------------------------------
-------- BEGIN Delete Log History------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

SET @CheckDBRetWks = (SELECT TOP 1 HistRetDays from Minion.CheckDBSettingsDB Where DBName = @DBName)

DELETE Minion.CheckDBCheckTableResult
WHERE DATEDIFF(wk, ExecutionDateTime, GETDATE()) > @CheckDBRetWks
AND DBName = @DBName
AND SchemaName = @currSchema
AND TableName = @currTableName;


DELETE Minion.CheckDBLogDetails
WHERE DATEDIFF(wk, ExecutionDateTime, GETDATE()) > @CheckDBRetWks
AND DBName = @DBName
AND UPPER(OpName) = 'CHECKTABLE'
AND SchemaName = @currSchema
AND TableName = @currTableName;
---------------------------------------------------------------------
---------------------------------------------------------------------
-------- END Delete Log History--------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

END  --curTable While

 
 --We'll turn this back on when the option comes in.
 --DELETE Minion.CheckDBCheckTableThreadQueue
 --WHERE ExecutionDateTime = @ExecutionDateTime
 --AND DBName = @DBName;


 ---------------------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------------------
 -------------------------------------END Table Cursor----------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------------------


 ----CLOSE curTable
 ----DEALLOCATE curTable
END --@OpRAW = 'CHECKTABLE'
	SET @CurrentTableCT = @CurrentTableCT + 1;
END --@PrepOnly = 0-Table Cursor

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------BEGIN DBPostCode-------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------	
----This needs to be below the multi-thread code because all the tables need to finish BEFORE
----we run the DBPostCode.  This will also only be run if @PrepOnly = 0 and @RunPrepped = 1
        IF @StmtOnly = 0
            BEGIN -- @StmtOnly = 0
			IF @PrepOnly = 0
			BEGIN --@PrepOnly = 0-DBPostCode

                IF @DBPostCode IS NOT NULL
                    BEGIN -- @DBPostCode IS NOT NULL
-------------------------------------------------------------
-----------------BEGIN Log DBPostCode Start------------------
-------------------------------------------------------------
                    IF @StmtOnly = 0
                    BEGIN -- @StmtOnly = 0
                         SET @DBPostCodeStartDateTime = GETDATE();
                        UPDATE Minion.CheckDBLogDetails
                            SET
                                DBPostCode = @DBPostCode,
                                DBPostCodeStartDateTime = @DBPostCodeStartDateTime
                            WHERE
                                ID = @CheckDBLogDetailsID;
                    END -- @StmtOnly = 0
-------------------------------------------------------------
-----------------END Log DBPostCode Start--------------------
-------------------------------------------------------------

--------------------------------------------------
----------------BEGIN Run Postcode-----------------
--------------------------------------------------
                        DECLARE
                            --@PostCodeErrors VARCHAR(MAX),
                            @PostCodeErrorExist VARCHAR(MAX);
                        CREATE TABLE #PostCode
                            (
                             ID INT IDENTITY(1, 1),
                             col1 VARCHAR(MAX)
                            )

                        BEGIN TRY
                            EXEC (@DBPostCode) 
                        END TRY

                        BEGIN CATCH
                            SET @PostCodeErrors = ERROR_MESSAGE();
                        END CATCH

                        IF @PostCodeErrors IS NOT NULL
                            BEGIN
                                SELECT @PostCodeErrors = 'PostCODE ERROR: '
                                        + @PostCodeErrors
                            END	 

--------------------------------------------------
----------------END Run Postcode-------------------
--------------------------------------------------
                    END -- @DBPostCode IS NOT NULL


                IF @DBPostCode IS NOT NULL
                    BEGIN -- @DBPostCode IS NOT NULL
                        IF @StmtOnly = 0
                            BEGIN -- @StmtOnly = 0

-----------------------------------------------------
-------------BEGIN Log PostCode Success---------------
-----------------------------------------------------
                                IF @PostCodeErrors IS NULL
                                    BEGIN --@PostCodeErrors IS NULL
                                        SET @DBPostCodeEndDateTime = GETDATE();
                                        UPDATE Minion.CheckDBLogDetails
                                            SET
												DBPostCodeStartDateTime = @DBPostCodeStartDateTime,
                                                DBPostCodeEndDateTime = @DBPostCodeEndDateTime,
                                                DBPostCodeTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @DBPostCodeStartDateTime, 21), CONVERT(VARCHAR(25), @DBPostCodeEndDateTime, 21)),
												DBPostCode = @DBPostCode
										WHERE
										ExecutionDateTime = @ExecutionDateTime
										AND DBName = @DBName
										----AND SchemaName = @currSchemaName
										----AND TableName = @currTableName
										----AND UPPER(OpName) = UPPER(@Op);
                                    END --@PostCodeErrors IS NULL
-----------------------------------------------------
-------------END Log PostCode Success-----------------
-----------------------------------------------------

-----------------------------------------------------
-------------BEGIN Log PostCode Failure---------------
-----------------------------------------------------
                                IF @PostCodeErrors IS NOT NULL
                                    BEGIN --@PostCodeErrors IS NULL
                                        SET @DBPostCodeEndDateTime = GETDATE();
                                        UPDATE Minion.CheckDBLogDetails
                                            SET
                                                Warnings = ISNULL(Warnings, '')
                                                + @PostCodeErrors,
												DBPostCodeStartDateTime = @DBPostCodeStartDateTime,
                                                DBPostCodeEndDateTime = @DBPostCodeEndDateTime,
                                                DBPostCodeTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @DBPostCodeStartDateTime, 21), CONVERT(VARCHAR(25), @DBPostCodeEndDateTime, 21)),
												DBPostCode = @DBPostCode
										WHERE
										ExecutionDateTime = @ExecutionDateTime
										AND DBName = @DBName
										----AND SchemaName = @currSchemaName
										----AND TableName = @currTableName
										----AND UPPER(OpName) = UPPER(@Op);
                                    END --@PostCodeErrors IS NULL
-----------------------------------------------------
-------------END Log PostCode Failure-----------------
-----------------------------------------------------
                            END -- @StmtOnly = 0
                    END -- @@DBPostCode IS NOT NULL


			END --@PrepOnly = 0-DBPostCode
            END -- @StmtOnly = 0

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------END DBPostCode---------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------	



END -- @OpRAW = 'CHECKTABLE'
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------END CHECKTABLE-----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------
-------------------------BEGIN Delete Snapshot-------------------------------------
-----------------------------------------------------------------------------------
IF @StmtOnly = 0
BEGIN --@StmtOnly = 0-Delete Snapshot
IF @PrepOnly = 0
BEGIN --@PrepOnly = 0-Delete Snapshot


------------------------------------------------------------------------
------------------------BEGIN Snapshot Size-----------------------------
------------------------------------------------------------------------
----Get the final size of the snapshot before we delete it.
IF @CreateSnapshot = 1
	BEGIN
		UPDATE SL 
		SET SL.SizeInKB = S.BytesOnDisk/1024
		FROM Minion.CheckDBSnapshotLog SL 
		INNER JOIN fn_virtualfilestats(db_id(@CurrentSnapshotDBName),null) S
		ON	SL.FileID = S.FileId
		WHERE SL.ExecutionDateTime = @ExecutionDateTime
		AND SL.SnapshotDBName = @CurrentSnapshotDBName;

		SET @TotalSnapshotSize = (SELECT SUM(ISNULL(SizeInKB, 0)) FROM Minion.CheckDBSnapshotLog SL
		WHERE SL.ExecutionDateTime = @ExecutionDateTime
		AND SL.SnapshotDBName = @CurrentSnapshotDBName);
	END
------------------------------------------------------------------------
------------------------END Snapshot Size-------------------------------
------------------------------------------------------------------------

IF @DeleteFinalSnapshot = 1
	BEGIN --@DeleteFinalSnapshot = 1
		----We can only delete snapshots. It would be very bad to delete the source DB, so test that it's a snapshot here.
		IF (SELECT COUNT(*) FROM sys.databases WHERE name = @CurrentSnapshotDBName AND source_database_id IS NOT NULL) > 0
			BEGIN --Run Snapshot Delete


		SET @SnapshotCMD = 'DROP DATABASE [' + @CurrentSnapshotDBName + '];'
-------------------------BEGIN Run Stmt-----------------------
					
                    SET @PreCMD = 'sqlcmd -r 1 -S"' + @ServerInstance
                        + CAST(@Port AS VARCHAR(6)) + '"'
						+ ' -d "master" -q "' 
                    SET @TotalCMD = @PreCMD
                        + @SnapshotCMD + '"'

                    INSERT #SnapshotDeleteResults
                            (col1)
                            EXEC xp_cmdshell @TotalCMD;

--SELECT '#DeleteResults', * FROM #DeleteResults

							DELETE FROM #SnapshotDeleteResults
								   WHERE col1 IS NULL
									  OR col1 = 'output'
									  OR col1 = 'NULL'
									  OR col1 LIKE '%-------------------------------------%'

							SELECT
										@SnapshotErrors = 'SNAPSHOT DELETE ERROR: '
										+ STUFF((SELECT ' ' + col1
											FROM #SnapshotResults AS T1
											ORDER BY T1.ID
											FOR XML PATH('')), 1, 1, '')
									FROM
										#SnapshotDeleteResults AS T2;
-------------------------BEGIN Run Stmt-----------------------
		END --Run Snapshot Delete
	END --@DeleteFinalSnapshot = 1
END --@PrepOnly = 0-Delete Snapshot
END --@StmtOnly = 0-Delete Snapshot
-----------------------------------------------------------------------------------
-------------------------END Delete Snapshot---------------------------------------
-----------------------------------------------------------------------------------		


--It's important that none of the trigger files have a file ext.  Just parse out the server.DBName.
--The template file is there because you can't just create a file in dos like you can in PS and 
--all the boxes can't have PS put on them.  This is the easiest low-tech way to accomplish this.
--So put an empty file called 'Template'with no ext and you rename it during the copy.


---------------------------------------------------------------------
---------------------------------------------------------------------
-------- BEGIN Delete Log History------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

IF @StmtOnly = 0
BEGIN
	SET @CheckDBRetWks = (SELECT TOP 1 HistRetDays from Minion.CheckDBSettingsDB Where DBName = @DBName)

	DELETE Minion.CheckDBLog
	WHERE DATEDIFF(wk, ExecutionDateTime, GETDATE()) > @CheckDBRetWks
	AND (UPPER(OpName) = 'CHECKTABLE' OR UPPER(OpName) = 'AUTO');
END
---------------------------------------------------------------------
---------------------------------------------------------------------
-------- END Delete Log History--------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------



GO
