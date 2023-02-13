SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [Minion].[CheckDB]
(
@DBName NVARCHAR(400),
@Op varchar(2000) = 'CHECKDB',
@StmtOnly BIT = 0,
@ExecutionDateTime DATETIME = NULL,
@Debug BIT = 0,
@Thread TINYINT = 0

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


REVISION HISTORY:
                

--***********************************************************************************/ 

SET NOCOUNT ON
DECLARE 
		@BeginTime DATETIME,
		@EndTime DATETIME,
		@Error BIT,
		@ErrorNum INT,
		@ErrorMess VARCHAR(500),
		@TriggerFile VARCHAR(8000),
		@CheckDBLoggingPath nvarchar(4000),
		@CheckDBRetWks int,
		@DBSize DECIMAL(18, 2),
        @DBSizeCMD VARCHAR(4000),
        @SpaceType VARCHAR(20),
		@CheckDBSQL nvarchar(4000),
		@CheckDBRunSQL nvarchar(4000),
		@CheckDBSettingLevel TINYINT,
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
		@DisableDOP bit,
		@CreateSnapshot bit,
		@SnapshotFailAction VARCHAR(50),
		@LockDBMode varchar(50),
		@ResultMode VARCHAR(50),
		@HistRetDays int,
		@PushToMinion varchar(25),
		@MinionTriggerPath varchar(1000),
		@AutoRepair varchar(50),
		@AutoRepairTime varchar(25),
		@Version DECIMAL(4,2),
		@VersionRaw VARCHAR(50),
		@Instance NVARCHAR(128),
		@InstanceName NVARCHAR(128),
		@ServerAndInstance NVARCHAR(400),
        @Edition VARCHAR(15),
        @OnlineEdition BIT,
		@ServerInstance VARCHAR(200),
		@LogDBType VARCHAR(6),
		@IsRepair BIT,
		@SchemasRAW VARCHAR(max),
		@currTable VARCHAR(200),
		@currSchema VARCHAR(200),
		@DefaultSchema VARCHAR(200),
		@OpRAW VARCHAR(2000),
		@SnapshotCMD VARCHAR(max),
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
		@DBIsInAGQuery VARCHAR(4000),
		@IsPrimaryReplica BIT,
		@IsPrimaryReplicaQuery VARCHAR(4000),
		@CheckDBAutoSettingLevel TINYINT,
		@AutoThresholdMethod VARCHAR(20),
		@AutoThresholdType VARCHAR(20),
		@AutoThresholdValue INT,
		@DBPreCode VARCHAR(max),
		@DBPostCode varchar(max),
		@DBPreCodeStartDateTime DATETIME,
		@DBPostCodeStartDateTime DATETIME,
		@DBPreCodeEndDateTime DATETIME,
		@DBPostCodeEndDateTime DATETIME,
		@PreferredServer VARCHAR(150),
		@PreferredServerPort VARCHAR(10),
		@PreferredDBName NVARCHAR(400),
		@LocalServer VARCHAR(150),
		@IsRemote BIT,
		@RemoteCheckDBMode VARCHAR(25),
		@RemoteRestoreMode varchar(50),
		@RemoteRestoreDBName NVARCHAR(400),
		@RemoteRestoreLocation varchar(20),
		@DropRemoteDB BIT,
		@RemoteJobName VARCHAR(400),
		@DropRemoteJob BIT,
		@LogSkips BIT,
		@DefaultTimeEstimateMins INT,
		@IncludeRemoteInTimeLimit BIT,
		@ViolatesTime BIT,
		@StmtPrefix NVARCHAR(500),
		@StmtSuffix NVARCHAR(500),
		@IsAutoRemote BIT,
		@TotalSnapshotSize bigint;

SET @ViolatesTime = 0;
IF @ExecutionDateTime IS NULL
	BEGIN
		SET @ExecutionDateTime = GETDATE();
	END
 SET @ServerInstance = @@ServerName;
 SET @IsRemote = 0;

DECLARE @MaintDB VARCHAR(400);
SET @MaintDB = DB_NAME();
SET @NETBIOSName = CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS VARCHAR(128));
SET @IsClustered = CAST(SERVERPROPERTY('IsClustered') AS VARCHAR(128));
------------------------BEGIN Set DBType---------------------------------
        IF @DBName IN ('master', 'msdb', 'model', 'distribution')
            SET @LogDBType = 'System'

        IF @DBName NOT IN ('master', 'msdb', 'model', 'distribution')
            SET @LogDBType = 'User'
------------------------END Set DBType-----------------------------------

SELECT 
@VersionRaw = VersionRaw,
@Version = [Version],
@Edition = Edition,
@OnlineEdition = OnlineEdition,
@Instance = Instance,
@InstanceName = InstanceName,
@ServerAndInstance = ServerAndInstance
FROM Minion.DBMaintSQLInfoGet();

----We always want the local server to be the local instance.
SET @LocalServer = @ServerInstance;

---------------------------------------------------------------------------------
------------------ BEGIN AG Info-------------------------------------------------
---------------------------------------------------------------------------------
----SET @DBIsInAG = 0
		IF @Version >= 11.0 AND @OnlineEdition = 1
			BEGIN --@Version >= 11
					--- We HAVE to run this select statement as an EXEC; even with the IF, this'd generate an error on SQL 05/08.

						SET @DBIsInAGQuery = ('INSERT Minion.Work(ExecutionDateTime, Module, DBName, Param, SPName, Value) SELECT ' 
						+ '''' + CONVERT(VARCHAR(25), @ExecutionDateTime, 121) + '''' + ', ''CHECKDB'', ''' + @DBName + ''', '
						+ '''@DBIsInAG'', ''CheckDB''' + ', COUNT(replica_id) from sys.databases with(nolock) where Name = '''
						+ @DBName + ''' AND replica_id IS NOT NULL')
						EXEC (@DBIsInAGQuery)

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.CheckDBDebug (ExecutionDateTime, DBName, OpName, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @Op, 'CheckDB', '@DBIsInAGQuery', @DBIsInAGQuery
END
-------------------DEBUG-------------------------------

						SET @DBIsInAG = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'CHECKDB' AND DBName = @DBName  AND SPName = 'CheckDB' AND Param = '@DBIsInAG')
						IF @DBIsInAG IS NULL
							BEGIN
								SET @DBIsInAG = 0
							END

					----DELETE FROM @AGResults; -- We're in a loop; clear results each time.
					--- We HAVE to run this select statement as an EXEC; even with the IF, this'd generate an error on SQL 05/08.
					IF @DBIsInAG = 1
					BEGIN --@DBIsInAG = 1			
						SET @IsPrimaryReplicaQuery = ('INSERT Minion.Work(ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value) SELECT '
						+ '''' + CONVERT(VARCHAR(25), @ExecutionDateTime, 121) + '''' + ', ''CheckDB'', ''' + @DBName + ''', '''''
						+ ', ''@IsPrimaryReplica'', ''CheckDB''' + ', count(*)        
						FROM sys.databases dbs with(nolock) INNER JOIN sys.dm_hadr_availability_replica_states ars ON dbs.replica_id = ars.replica_id WHERE dbs.name = '''
						+ @DBName + ''' AND ars.role = 1')
						EXEC (@IsPrimaryReplicaQuery)

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.CheckDBDebug (ExecutionDateTime, DBName, OpName, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @Op, 'CheckDB', '@IsPrimaryReplicaQuery', @IsPrimaryReplicaQuery
END
-------------------DEBUG-------------------------------

						SET @IsPrimaryReplica = (SELECT Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND Module = 'CHECKDB' AND DBName = @DBName AND SPName = 'CheckDB' AND Param = '@IsPrimaryReplica')
							IF @IsPrimaryReplica IS NULL
							BEGIN
								SET @IsPrimaryReplica = 0
							END
					END --@DBIsInAG = 1
			END --@Version >= 11
---------------------------------------------------------------------------------
------------------ END AG Info---------------------------------------------------
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
	 IsRemote BIT NULL,
	 IncludeRemoteInTimeLimit BIT NULL,
	 PreferredServer VARCHAR(150) COLLATE DATABASE_DEFAULT NULL,
	 PreferredServerPort VARCHAR(150) COLLATE DATABASE_DEFAULT NULL,
	 PreferredDBName VARCHAR(400) COLLATE DATABASE_DEFAULT NULL,
	 RemoteJobName VARCHAR(400) COLLATE DATABASE_DEFAULT NULL,
	 RemoteCheckDBMode VARCHAR(400) COLLATE DATABASE_DEFAULT NULL,
	 RemoteRestoreMode VARCHAR(400) COLLATE DATABASE_DEFAULT NULL,
	 RemoteRestoreDBName VARCHAR(400) COLLATE DATABASE_DEFAULT NULL,
	 DropRemoteDB BIT NULL,
	 DropRemoteJob BIT NULL,
	 CreateSnapshot   bit  NULL,
	 LockDBMode   varchar (50) COLLATE DATABASE_DEFAULT NULL,
	 ResultMode varchar (50) COLLATE DATABASE_DEFAULT NULL,
	 HistRetDays   int  NULL,
	 PushToMinion   varchar (25) COLLATE DATABASE_DEFAULT NULL,
	 MinionTriggerPath   varchar (1000) COLLATE DATABASE_DEFAULT NULL,
	 AutoRepair   varchar (50) COLLATE DATABASE_DEFAULT NULL,
	 AutoRepairTime   varchar (25) COLLATE DATABASE_DEFAULT NULL,
	 DefaultSchema VARCHAR(200) COLLATE DATABASE_DEFAULT NULL,
	 DBPreCode VARCHAR(max) COLLATE DATABASE_DEFAULT NULL,
	 DBPostCode VARCHAR(max) COLLATE DATABASE_DEFAULT NULL,
	 StmtPrefix NVARCHAR(500) COLLATE DATABASE_DEFAULT NULL,
	 StmtSuffix NVARCHAR(500) COLLATE DATABASE_DEFAULT NULL,
	 DefaultTimeEstimateMins INT NULL,
	 LogSkips BIT NULL,
	 BeginTime VARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
	 EndTime VARCHAR(20) COLLATE DATABASE_DEFAULT NULL,
	 DayOfWeek VARCHAR(15) COLLATE DATABASE_DEFAULT NULL,
	 IsActive   bit  NULL,
	 Comment   varchar (1000) COLLATE DATABASE_DEFAULT NULL
)

CREATE TABLE #CheckDBSnapshot(
[ID] [int] IDENTITY(1,1) NOT NULL,
[SnapshotDBName] VARCHAR(200) COLLATE DATABASE_DEFAULT NULL,
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
SizeInKB bigint,
MaxSizeInKB BIGINT
);

CREATE TABLE #SnapshotResults
	(
		ID INT IDENTITY(1, 1),
		col1 VARCHAR(MAX) COLLATE DATABASE_DEFAULT
	);

CREATE TABLE #CheckDBResults (ID INT IDENTITY(1,1), col1 VARCHAR(max));


	
DECLARE @DBTempTable VARCHAR(5),
		@DBTempTableDate VARCHAR(15);
SET @DBTempTableDate = CONVERT(VARCHAR(4), YEAR(@ExecutionDateTime)) + CONVERT(VARCHAR(4), MONTH(@ExecutionDateTime)) + CONVERT(VARCHAR(4), DAY(@ExecutionDateTime)) + CONVERT(VARCHAR(4), DATEPART(HOUR,@ExecutionDateTime)) + DATEPART(MINUTE,@ExecutionDateTime) + DATEPART(SECOND,@ExecutionDateTime);
SET @DBTempTable = SUBSTRING(REPLACE(@DBName, ' ', ''), 1, 5);

---------------------------------------------------------------------------------
--------------------------BEGIN Settings Level-----------------------------------
---------------------------------------------------------------------------------

----------------------------------------------------
-------------------Begin AUTO-----------------------
----------------------------------------------------
----0 = MinionDefault, > 0 = DBName.
IF UPPER(@Op) = 'AUTO' OR @Op IS NULL
	BEGIN --AUTO Params
			SET @CheckDBAutoSettingLevel = (
									SELECT COUNT(*)
									FROM Minion.CheckDBSettingsAutoThresholds
									WHERE
										DBName = @DBName
										AND IsActive = 1
								);

                        IF @CheckDBAutoSettingLevel = 0
                            BEGIN --@TuningTypeLevel = 0
                                SELECT TOP 1
                                        @AutoThresholdMethod = ThresholdMethod,
										@AutoThresholdType = ThresholdType,
										@AutoThresholdValue = ThresholdValue
                                    FROM
                                        Minion.CheckDBSettingsAutoThresholds
                                    WHERE
                                        DBName = 'MinionDefault'
                                        AND IsActive = 1

                            END --@TuningTypeLevel = 0

                        IF @CheckDBAutoSettingLevel > 0
                            BEGIN --@TuningTypeLevel > 0
                                SELECT TOP 1
                                        @AutoThresholdMethod = ThresholdMethod,
										@AutoThresholdType = ThresholdType,
										@AutoThresholdValue = ThresholdValue
                                    FROM
                                        Minion.CheckDBSettingsAutoThresholds
                                    WHERE
                                        DBName = @DBName
                                        AND IsActive = 1
                            END --@TuningTypeLevel > 0
END --AUTO Params
----------------------------------------------------
-------------------End AUTO--------------------------
----------------------------------------------------

----Here we're checking to see whether settings will come from 
----the DB level or the MinionDefault level.

SET @CheckDBSettingLevel = (
                        SELECT COUNT(*)
                        FROM Minion.CheckDBSettingsDB
                        WHERE
                            DBName = @DBName
                            AND IsActive = 1
                    );

---------------------------------------------------------------------------------
--------------------------END Settings Level-------------------------------------
---------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------BEGIN CHECKDB------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--IF (@Schemas IS NULL OR @Schemas = '') AND (@Tables IS NULL OR @Tables = '') AND UPPER(@Op) <> 'CHECKTABLE'
IF UPPER(@Op) = 'CHECKDB' OR UPPER(@Op) = 'CHECKALLOC'
BEGIN --CHECKDB OP


--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
-------------------------------BEGIN Settings-----------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
 ----Find out if the settings will come from the DB level or from the default level.

        IF @CheckDBSettingLevel > 0
            BEGIN		
                INSERT #CheckDBSettingsDB
                        (
							Port,
							Exclude,
							GroupOrder,
							GroupDBOrder,
							OpLevel,
							NoIndex,
							RepairOption,
							RepairOptionAgree,
							WithRollback,
							AllErrorMsgs,
							ExtendedLogicalChecks,
							NoInfoMsgs,
							IsTabLock,
							IntegrityCheckLevel,
							DisableDOP,
							IsRemote,
							IncludeRemoteInTimeLimit,
							PreferredServer,
							PreferredServerPort,
							PreferredDBName,
							RemoteJobName,
							RemoteCheckDBMode,
							RemoteRestoreMode,
							DropRemoteDB,
							DropRemoteJob,
							LockDBMode,
							ResultMode,
							HistRetDays,
							PushToMinion,
							MinionTriggerPath,
							AutoRepair,
							AutoRepairTime,
							DefaultSchema,
							DBPreCode,
							DBPostCode,
							StmtPrefix,
							StmtSuffix,
							DefaultTimeEstimateMins,
							LogSkips,
							BeginTime,
							EndTime,
							DayOfWeek
						)
                    SELECT
							Port,
							Exclude,
							GroupOrder,
							GroupDBOrder,
							OpLevel,
							NoIndex,
							RepairOption,
							RepairOptionAgree,
							WithRollback,
							AllErrorMsgs,
							ExtendedLogicalChecks,
							NoInfoMsgs,
							IsTabLock,
							IntegrityCheckLevel,
							DisableDOP,
							IsRemote,
							IncludeRemoteInTimeLimit,
							PreferredServer,
							PreferredServerPort,
							PreferredDBName,
							RemoteJobName,
							RemoteCheckDBMode,
							RemoteRestoreMode,
							DropRemoteDB,
							DropRemoteJob,
							LockDBMode,
							ResultMode,
							HistRetDays,
							PushToMinion,
							MinionTriggerPath,
							AutoRepair,
							AutoRepairTime,
							DefaultSchema,
							DBPreCode,
							DBPostCode,
							StmtPrefix,
							StmtSuffix,
							DefaultTimeEstimateMins,
							LogSkips,
							BeginTime,
							EndTime,
							DayOfWeek
                        FROM
                            Minion.CheckDBSettingsDB
                        WHERE
                            DBName = @DBName 
							AND UPPER(OpName) = UPPER(@Op)                           
                            AND IsActive = 1
		----------------------	  

            END
        IF @CheckDBSettingLevel = 0
            BEGIN
                INSERT #CheckDBSettingsDB
                        (
							Port,
							Exclude,
							GroupOrder,
							GroupDBOrder,
							OpLevel,
							NoIndex,
							RepairOption,
							RepairOptionAgree,
							WithRollback,
							AllErrorMsgs,
							ExtendedLogicalChecks,
							NoInfoMsgs,
							IsTabLock,
							IntegrityCheckLevel,
							DisableDOP,
							IsRemote,
							IncludeRemoteInTimeLimit,
							PreferredServer,
							PreferredServerPort,
							PreferredDBName,
							RemoteJobName,
							RemoteCheckDBMode,
							RemoteRestoreMode,
							DropRemoteDB,
							DropRemoteJob,
							LockDBMode,
							ResultMode,
							HistRetDays,
							PushToMinion,
							MinionTriggerPath,
							AutoRepair,
							AutoRepairTime,
							DefaultSchema,
							DBPreCode,
							DBPostCode,
							StmtPrefix,
							StmtSuffix,
							DefaultTimeEstimateMins,
							LogSkips,
							BeginTime,
							EndTime,
							DayOfWeek
						)
                    SELECT
							Port,
							Exclude,
							GroupOrder,
							GroupDBOrder,
							OpLevel,
							NoIndex,
							RepairOption,
							RepairOptionAgree,
							WithRollback,
							AllErrorMsgs,
							ExtendedLogicalChecks,
							NoInfoMsgs,
							IsTabLock,
							IntegrityCheckLevel,
							DisableDOP,
							IsRemote,
							IncludeRemoteInTimeLimit,
							PreferredServer,
							PreferredServerPort,
							PreferredDBName,
							RemoteJobName,
							RemoteCheckDBMode,
							RemoteRestoreMode,
							DropRemoteDB,
							DropRemoteJob,
							LockDBMode,
							ResultMode,
							HistRetDays,
							PushToMinion,
							MinionTriggerPath,
							AutoRepair,
							AutoRepairTime,
							DefaultSchema,
							DBPreCode,
							DBPostCode,
							StmtPrefix,
							StmtSuffix,
							DefaultTimeEstimateMins,
							LogSkips,
							BeginTime,
							EndTime,
							DayOfWeek
                        FROM
                            Minion.CheckDBSettingsDB
                        WHERE
                            DBName = 'MinionDefault' 
							AND UPPER(OpName) = UPPER(@Op)                           
                            AND IsActive = 1;
            END

DECLARE @SettingID INT;
EXEC Minion.DBMaintDBSettingsGet 'CHECKDB', @DBName, @Op, @SettingID = @SettingID OUTPUT;

SELECT
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
@IsRemote = ISNULL(IsRemote, 0),
@IncludeRemoteInTimeLimit = IncludeRemoteInTimeLimit,
@PreferredServer = PreferredServer,
@PreferredServerPort = PreferredServerPort,
@PreferredDBName = PreferredDBName,
@RemoteJobName = RemoteJobName,
@RemoteCheckDBMode = RemoteCheckDBMode,
@RemoteRestoreMode = RemoteRestoreMode,
@DropRemoteDB = DropRemoteDB,
@DropRemoteJob = DropRemoteJob,
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
@StmtPrefix = StmtPrefix,
@StmtSuffix = StmtSuffix,
@DefaultTimeEstimateMins = DefaultTimeEstimateMins,
@LogSkips = LogSkips
FROM Minion.CheckDBSettingsDB
WHERE ID = @SettingID;


---------------------------------------------------------------------------------
--------------------------BEGIN TriggerPath Get ---------------------------------
---------------------------------------------------------------------------------
----This is above so we can prob get rid of this code.
------SET @PushToMinion = (SELECT TOP 1 PushToMinion FROM Minion.CheckDBSettingsDB WHERE IsActive = 1);
------IF @PushToMinion = 1
------	BEGIN
------		SET @MinionTriggerPath = (SELECT TOP 1 MinionTriggerPath FROM Minion.CheckDBSettingsDB WHERE IsActive = 1);
------	END

    IF @LocalServer LIKE '%\%'
        BEGIN --Begin @ServerLabel
            SET @LocalServer = REPLACE(@LocalServer, '\', '~')
        END	--End @ServerLabel
---------------------------------------------------------------------------------
--------------------------END TriggerPath Get -----------------------------------
---------------------------------------------------------------------------------


---------------------------------------------------------------------------------
--------------------------BEGIN Auto Remote -------------------------------------
---------------------------------------------------------------------------------
----You can set it up so that MC will switch to remote runs if the DB is over a certain size.
----However, this only needs to be done if it's not already set for a remote run.
----0 = MinionDefault, > 0 = DBName.
IF @IsRemote = 0
	BEGIN --AUTO Remote
		DECLARE @CheckDBAutoRemoteSettingLevel INT,
				@RemoteThresholdMeasure varchar(5),
				@RemoteThresholdType VARCHAR(20),
				@RemoteThresholdValue INT;
			SET @CheckDBAutoRemoteSettingLevel = (
									SELECT COUNT(*)
									FROM Minion.CheckDBSettingsRemoteThresholds
									WHERE
										DBName = @DBName
										AND IsActive = 1
								);

                        IF @CheckDBAutoRemoteSettingLevel = 0
                            BEGIN --@RemoteTypeLevel = 0
                                SELECT TOP 1
                                        @RemoteThresholdMeasure = ThresholdMeasure,
										@RemoteThresholdType = ThresholdType,
										@RemoteThresholdValue = ThresholdValue
                                    FROM
                                        Minion.CheckDBSettingsRemoteThresholds
                                    WHERE
                                        DBName = 'MinionDefault'
                                        AND IsActive = 1

                            END --@RemoteTypeLevel = 0

                        IF @CheckDBAutoRemoteSettingLevel > 0
                            BEGIN --@RemoteTypeLevel > 0
                                SELECT TOP 1
                                        @RemoteThresholdMeasure = ThresholdMeasure,
										@RemoteThresholdType = ThresholdType,
										@RemoteThresholdValue = ThresholdValue
                                    FROM
                                        Minion.CheckDBSettingsRemoteThresholds
                                    WHERE
                                        DBName = @DBName
                                        AND IsActive = 1
                            END --@RemoteTypeLevel > 0

	IF @RemoteThresholdType IS NOT NULL
		BEGIN --TypeNotNULL
			EXEC Minion.DBMaintDBSizeGet @Module = 'CHECKDB', @OpName = @Op OUTPUT, @DBName = @DBName, @DBSize = @DBSize OUTPUT;


			IF @DBSize > @RemoteThresholdValue
				BEGIN
					SET @IsRemote = 1;
				END
		END --TypeNotNULL

END --AUTO Remote


---------------------------------------------------------------------------------
--------------------------END Auto Remote ---------------------------------------
---------------------------------------------------------------------------------



---------------------------------------------------------------------------------
--------------------------BEGIN Timed Run ---------------------------------------
---------------------------------------------------------------------------------
--We need to figure out if we should continue based off of the estimated run time
--and when we're supposed to stop.  So if we calculate that we don't have time to run this
--DB then we'll skip it and either log it or not.

DECLARE @TimeLimitInMinsCheckDB INT,
		@currCheckDBTimeEstimate BIGINT,
		@LastOpTime BIGINT,
		@LastDBSize FLOAT,
		@KBperMS BIGINT, --KB per millisecond from the last run.
		@UseDefaultTime BIT;
SET @TimeLimitInMinsCheckDB = (SELECT TOP 1 Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND SPName = 'CheckDBMaster' AND Param = '@TimeLimitInMins')

----This usually gets set in Master, but if they run this SP, it needs to be set to 0 so it'll
----log the run.
IF @TimeLimitInMinsCheckDB IS NULL
	BEGIN
		SET @TimeLimitInMinsCheckDB = 0;
	END
----IF @TimeLimitInMinsCheckDB > 0 AND @TimeLimitInMinsCheckDB IS NOT NULL
----BEGIN --TimeLimit
BEGIN				
	EXEC Minion.DBMaintDBSizeGet @Module = 'CHECKDB', @OpName = @Op OUTPUT, @DBName = @DBName, @DBSize = @DBSize OUTPUT;
END


SELECT @LastOpTime = CASE WHEN (OpRunTimeInSecs < 1 OR OpRunTimeInSecs IS NULL) THEN 1 ELSE OpRunTimeInSecs END
	  ,@LastDBSize = CASE WHEN SizeInMB < 1 THEN 1 ELSE SizeInMB END
FROM Minion.CheckDBLogDetailsLatest WHERE DBName = @DBName;
--SELECT @LastOpTime AS LastTime, @LastDBSize LastSize;
SET @UseDefaultTime = 0;
IF @LastOpTime IS NULL
	BEGIN
		SET @UseDefaultTime = 1;
	 --SET @LastOpTime = @DefaultTimeEstimateMins;

		SET @currCheckDBTimeEstimate = @DefaultTimeEstimateMins*60;

	END

IF @LastDBSize IS NULL
	BEGIN
	 SET @LastDBSize = 1;
	END
----Get the last KB/MS by converting MB to KB and Secs to MS.

IF @LastDBSize IS NOT NULL OR @LastOpTime IS NOT NULL
	BEGIN
		SET @KBperMS = ((@LastDBSize*1024)/@LastOpTime*1000.00)
	END
----SELECT @DBName, @LastOpTime AS OpTime, @LastDBSize*1024 AS LastSize, @KBperMS AS MB
--This is the estimate based on the current size of the DB.
--The DB could have grown or shrunk significantly since the last
--checkdb so we need to get a number.
--To prevent rounding issues we convert DBSize to KB to help
--with smaller DBs, and we've already got the time in MS.
--Rounding can throw off a calculation quite a bit, so the hope
--here is to make it more accurate.  At the end we 
--Divide by 1000 again to put it back into secs.  And then
--we turn it back into mins.
IF @UseDefaultTime = 0
	BEGIN --@UseDefaultTime = 0
		IF @DBSize IS NOT NULL OR @DBSize > 0
			BEGIN
				--@DBSize is in GB here and needs to be converted to KB.
				SET @currCheckDBTimeEstimate = (((@DBSize*1024*1024)/@KBperMS)*1000);
			END
	END --@UseDefaultTime = 0
IF @currCheckDBTimeEstimate IS NULL
	BEGIN
		SET @currCheckDBTimeEstimate = @DefaultTimeEstimateMins*60;
	END
----SELECT @UseDefaultTime AS UseDefault, @DBName, @LastOpTime AS OpTime, @LastDBSize AS LastSize, @KBperMS AS KBperMS, @currCheckDBTimeEstimate AS TimeEst
----END --TimeLimit
IF @TimeLimitInMinsCheckDB > 0 AND @TimeLimitInMinsCheckDB IS NOT NULL
BEGIN 
	DECLARE @TimeFrameDiff INT;
	SET @TimeFrameDiff = DATEDIFF(SECOND, @ExecutionDateTime, GETDATE())
	----SET @currCheckDBTimeEstimate = 5000 --!!!!!!!!!!!!!!!!!TESTING-REMOVE!!!!!!

	IF @currCheckDBTimeEstimate >= ((@TimeLimitInMinsCheckDB*60) - @TimeFrameDiff)
		BEGIN
			SET @ViolatesTime = 1;
		END
END
---------------------------------------------------------------------------------
--------------------------END Timed Run -----------------------------------------
---------------------------------------------------------------------------------


-------------------------------------------------------------------------
-------------------BEGIN Initial Log Record------------------------------
-------------------------------------------------------------------------
--It could have already been created in the Master SP so we have to check
--If there's a record already in there.

IF (@ViolatesTime = 0 AND @TimeLimitInMinsCheckDB = 0) OR (@ViolatesTime = 0 AND @TimeLimitInMinsCheckDB > 0) OR (@ViolatesTime = 1 AND @TimeLimitInMinsCheckDB > 0 AND (@LogSkips = 1 OR @LogSkips IS NULL))
BEGIN --ViolatesTime
IF UPPER(@Op) = 'CHECKDB' OR UPPER(@Op) = 'CHECKALLOC'
BEGIN --CHECKDB
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
						AND UPPER(OpName) = UPPER(@Op)
			   ) IS NULL
				BEGIN
					INSERT Minion.CheckDBLogDetails
							(
							 ExecutionDateTime,
							 DBName,
							 OpName,
							 DBType,
							 PreferredServer,
							 PreferredDBName,
							 RemoteCheckDBMode,
							 RemoteRestoreMode,
							 SizeInMB,
							 TimeLimitInMins,
							 EstimatedTimeInSecs,
							 EstimatedKBperMS,
							 LastOpTimeInSecs,
							 IsRemote,
							 IncludeRemoteInTimeLimit,
							 StmtPrefix,
							 StmtSuffix,
							 ProcessingThread
							)
						SELECT
								@ExecutionDateTime,
								@DBName,
								@Op,
								@LogDBType,
								@PreferredServer,
								@PreferredDBName,
								@RemoteCheckDBMode,
								@RemoteRestoreMode,
								@DBSize*1024.0, --Needs converting to MB for log.
								@TimeLimitInMinsCheckDB,
								@currCheckDBTimeEstimate,
								@KBperMS,
								@LastOpTime,
								@IsRemote,
								@IncludeRemoteInTimeLimit,
								@StmtPrefix,
								@StmtSuffix,
								@Thread
				END

	-----Get the log record we just created, or the one that was created in the Master SP.


------------------------------------------------------------------------
---------------------BEGIN Get Current Log Record-----------------------
------------------------------------------------------------------------
--Get current log record to make updates easier.
			SET @CheckDBLogDetailsID = (
									   SELECT ID
										FROM  Minion.CheckDBLogDetails
										WHERE
											ExecutionDateTime = @ExecutionDateTime
											AND DBName = @DBName
											AND UPPER(OpName) = UPPER(@Op)
									  ) 

	--------Send @CheckDBLogDetailsID to Minion.Work so it can be seen by the Monitor.
	----INSERT Minion.Work (ExecutionDateTime, Module, DBName, BackupType, Param, SPName, Value)
	----SELECT @ExecutionDateTime, 'CheckDB', @DBName, NULL, '@CheckDBLogDetailsID', 'CheckDB', @CheckDBLogDetailsID;

------------------------------------------------------------------------
---------------------END Get Current Log Record-------------------------
------------------------------------------------------------------------

	END --@StmtOnly = 0		
END --CHECKDB
END --ViolatesTime			    
-------------------------------------------------------------------------
-------------------END Initial Log Record--------------------------------
-------------------------------------------------------------------------

----SELECT @ViolatesTime, @DBName, @CheckDBLogDetailsID

-------------------------------------------------------------------------
-------------------BEGIN Log Time Skip-----------------------------------
-------------------------------------------------------------------------
----If the current DB violates our time constraint, then we skip it but we only log it if we 
----want it logged.
----WAITFOR DELAY '00:00:10';
IF @TimeLimitInMinsCheckDB > 0 AND @TimeLimitInMinsCheckDB IS NOT NULL
BEGIN --TimeLimit2
IF (@IsRemote = 0 OR @IsRemote IS NULL) OR (@IsRemote = 1 AND @IncludeRemoteInTimeLimit = 1) 
	BEGIN --IncludeRemote

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

						--------------BEGIN Log to Minion---------
						EXEC Minion.DBMaintLogToMinion @Module = 'CHECKDB', @DBName = @DBName, @MinionTriggerPath = @MinionTriggerPath, @ExecutionDateTime = @ExecutionDateTime, @ServerName = @LocalServer, @Folder = 'CheckDB'
						--------------END Log to Minion-----------
						RETURN;
					END --LogSkips
				--If you don't want to log the skips, you still need to end the routine if it
				--violates the time constraint.
				IF @LogSkips = 0
					BEGIN
						--------------BEGIN Log to Minion---------
						EXEC Minion.DBMaintLogToMinion @Module = 'CHECKDB', @DBName = @DBName, @MinionTriggerPath = @MinionTriggerPath, @ExecutionDateTime = @ExecutionDateTime, @ServerName = @LocalServer, @Folder = 'CheckDB'
						--------------END Log to Minion-----------
						RETURN;
					END
			END --TimeLimiter
	END --IncludeRemote
	END --TimeLimit2
-------------------------------------------------------------------------
-------------------END Log Time Skip-------------------------------------
-------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------BEGIN DBPreCode-------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------	
        IF @StmtOnly = 0
            BEGIN -- @StmtOnly = 0

                IF @DBPreCode IS NOT NULL
                    BEGIN -- @DBPreCode
------------------------------------------------------
-----------------BEGIN Log DBPreCode------------------
------------------------------------------------------
						SET @DBPreCodeStartDateTime = GETDATE();
                        UPDATE Minion.CheckDBLogDetails
                            SET
                                STATUS = 'Precode running',
                                DBPreCodeStartDateTime = @DBPreCodeStartDateTime,
                                DBPreCode = @DBPreCode
                            WHERE
                                ID = @CheckDBLogDetailsID;
------------------------------------------------------
-----------------END Log DBPreCode--------------------
------------------------------------------------------

--------------------------------------------------
----------------BEGIN Run Precode-----------------
--------------------------------------------------
                        DECLARE
                            @PreCodeErrors VARCHAR(MAX),
                            @PreCodeErrorExist VARCHAR(MAX);
                        CREATE TABLE #PreCode
                            (
                             ID INT IDENTITY(1, 1),
                             col1 VARCHAR(MAX) COLLATE DATABASE_DEFAULT
                            )

                        BEGIN TRY
                            EXEC (@DBPreCode) 
                        END TRY



                        BEGIN CATCH
                            SET @PreCodeErrors = ERROR_MESSAGE();
                        END CATCH
-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.CheckDBDebug (ExecutionDateTime, DBName, OpName, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @Op, 'CheckDB', 'Execute Precode', @DBPreCode
END
-------------------DEBUG-------------------------------

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
                                                + ISNULL(@PreCodeErrors, ''),
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

            END -- @StmtOnly = 0
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------END DBPreCode---------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------



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
										@DeleteFinalSnapshot = ISNULL(DeleteFinalSnapshot, 0),
										@SnapshotFailAction = SnapshotFailAction
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
										@DeleteFinalSnapshot = ISNULL(DeleteFinalSnapshot, 0),
										@SnapshotFailAction = SnapshotFailAction
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


----------------------------------------------------------------
------------------------BEGIN Set Port--------------------------
----------------------------------------------------------------
----If ServerInstance is '.' then it's to avoid possibly overloading the DNS server.
BEGIN --Ports
IF @ServerInstance NOT LIKE '%\%'
	BEGIN
		SET @Port = CASE WHEN @Port IS NULL AND @ServerInstance NOT LIKE '%.%' THEN '' --',' + '1433'
						 WHEN @Port IS NULL AND @ServerInstance LIKE '%.%' THEN '' --',' + '1433'
						 WHEN @Port = '1433' THEN '' --',' + '1433'
						 WHEN @Port IS NOT NULL AND @Port <> '1433' AND @ServerInstance NOT LIKE '%.%' THEN ',' + @Port
						 WHEN @Port IS NOT NULL AND @ServerInstance LIKE '%.%' THEN ''
						 END
	END
IF @ServerInstance LIKE '%\%'
	BEGIN
			SET @Port = CASE WHEN @Port IS NULL THEN ''
							 WHEN @Port IS NOT NULL AND @Port <> '1433' THEN ',' + @Port
							 END
	END

IF @LocalServer NOT LIKE '%\%'
	BEGIN
		SET @Port = CASE WHEN @Port IS NULL AND @LocalServer NOT LIKE '%.%' THEN '' --',' + '1433'
						 WHEN @Port IS NULL AND @LocalServer LIKE '%.%' THEN '' --',' + '1433'
						 WHEN @Port = '1433' THEN '' --',' + '1433'
						 WHEN @Port IS NOT NULL AND @Port <> '1433' AND @LocalServer NOT LIKE '%.%' THEN ',' + @Port
						 WHEN @Port IS NOT NULL AND @LocalServer LIKE '%.%' THEN ''
						 END
	END
IF @LocalServer LIKE '%\%'
	BEGIN
			SET @Port = CASE WHEN @Port IS NULL THEN ''
							 WHEN @Port IS NOT NULL AND @Port <> '1433' THEN ',' + @Port
							 END
	END

IF @ServerInstance NOT LIKE '%\%'
	BEGIN
		SET @PreferredServerPort = CASE WHEN @PreferredServerPort IS NULL AND @ServerInstance NOT LIKE '%.%' THEN '' --',' + '1433'
						 WHEN @PreferredServerPort IS NULL AND @ServerInstance LIKE '%.%' THEN '' --',' + '1433'
						 WHEN @PreferredServerPort = '1433' THEN '' --',' + '1433'
						 WHEN @PreferredServerPort IS NOT NULL AND @PreferredServerPort <> '1433' AND @ServerInstance NOT LIKE '%.%' THEN ',' + @Port
						 WHEN @PreferredServerPort IS NOT NULL AND @ServerInstance LIKE '%.%' THEN ''
						 END
	END
IF @ServerInstance LIKE '%\%'
	BEGIN
			SET @PreferredServerPort = CASE WHEN @PreferredServerPort IS NULL THEN ''
							 WHEN @PreferredServerPort IS NOT NULL AND @PreferredServerPort <> '1433' THEN ',' + @Port
							 END
	END
END --Ports
----------------------------------------------------------------
------------------------SET Set Port----------------------------
----------------------------------------------------------------

DECLARE @PreCMD VARCHAR(1000),
		@TotalCMD VARCHAR(8000);

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
------------------------------------BEGIN Remote Restore--------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

IF @IsRemote = 1
	BEGIN
		SET @ServerInstance = @PreferredServer;
		--SET @IsRemote = 1;
	END



----------------------------------------------------------------
----------------------------------------------------------------
--------------BEGIN Remote Restore DB Name----------------------
----------------------------------------------------------------
----------------------------------------------------------------
----Connected mode means that the operation is run remotely from the current server.
----So consider this to be like running it from SSMS, so if anything at all happens to the connection
----between the 2 servers, then the op will fail.
----This section doesn't run the op on the remote server.  It merely sets the remote server and the remote DBName.
----The actual run happens when the normal run happens for a local run.
----The way this works... if SettingsDB.PreferredDBName has a wildcard, then we're assuming you have a DB restored on the remote server,
----and you're wanting us to follow your naming convention.  So we'll lookup the latest DB by that name and use it.
----So say you've got a DB that gets restored every day or every week called Minion20161007, and next wk it's called Minion20161014.
----You'd put 'Minion%' as a setting and we'll go lookup on the remote server and see which DB is the newest and use that.
----That's what we're doing here.

IF @IsRemote = 1 AND UPPER(@RemoteRestoreMode) = 'NONE'
	BEGIN

        CREATE TABLE #PreferredDB
            (
                ID INT IDENTITY(1, 1),
                col1 VARCHAR(MAX) COLLATE DATABASE_DEFAULT
            )

		IF @PreferredDBName LIKE '%\%%' ESCAPE '\'
			BEGIN--@PreferredDBName
			
				EXEC Minion.DBMaintInlineTokenParse @DBName = @DBName, @DynamicName = @PreferredDBName OUTPUT;
			END--@PreferredDBName

		IF @PreferredDBName LIKE '%\%' ESCAPE '\'
			BEGIN--@PreferredDBName
				DECLARE @PreferredDBNameCMD VARCHAR(500);
				SET @PreferredDBNameCMD = 'EXEC xp_cmdshell ''powershell "';
			
                        IF @Version = 10
                            BEGIN
                                SET @PreferredDBNameCMD = @PreferredDBNameCMD
                                    + 'ADD-PSSNAPIN SQLServerProviderSnapin100; ';
                            END

                        IF @Version >= 11
                            BEGIN
                                SET @PreferredDBNameCMD = @PreferredDBNameCMD
                                    + 'IMPORT-MODULE SQLPS -DisableNameChecking 3> $null; '
							END

       --                 IF @Version >= 13
       --                     BEGIN
       --                         SET @PreferredDBNameCMD = @PreferredDBNameCMD
       --                             + 'IMPORT-MODULE SQLPS -DisableNameChecking -WarningAction SilentlyContinue; '
							--END

				SET @PreferredDBNameCMD = @PreferredDBNameCMD + 
                + '(Invoke-sqlcmd -ServerInstance """' + @PreferredServer + CASE WHEN (@PreferredServerPort IS NOT NULL AND @PreferredServerPort <> '') THEN ','  ELSE '' END
				+ ISNULL(CAST(@PreferredServerPort AS VARCHAR(10)), '')
				+ '""" -Database """master""" -Query """SELECT TOP 1 name from sys.databases WHERE NAME LIKE ''''' + @PreferredDBName + ''''' ORDER BY create_date DESC""").name;'
				+ '"'''
				----SELECT @PreferredDBNameCMD AS PCmd
				INSERT #PreferredDB
                EXEC (@PreferredDBNameCMD)
SELECT @PreferredDBNameCMD
-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.CheckDBDebug (ExecutionDateTime, DBName, OpName, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @Op, 'CheckDB', 'Get Remote Restore DB', @PreferredDBNameCMD
END
-------------------DEBUG-------------------------------

				DELETE FROM #PreferredDB WHERE col1 IS NULL;
				SET @PreferredDBName = (SELECT TOP 1 col1 FROM #PreferredDB)
			END--@PreferredDBName

		--SET @IsRemote = 1;
	END
----------------------------------------------------------------
----------------------------------------------------------------
--------------END Remote Restore DB Name------------------------
----------------------------------------------------------------
----------------------------------------------------------------


--------------------------------------------------------------------------
-------------------------BEGIN NewMinionBackup----------------------------
--------------------------------------------------------------------------
----We need to take a new backup for this op.  We only support using Minion Backup as a backup mechanism internally, but
----others can be used.  See the documentation for more info.  However, the backup mechanism here relies on MB 1.3 or higher,
----and MB must be in the same DB as MC.  That said, we're really just inserting a backup process into the mix.
----So once we're done with the backup, we change the @RemoteRestoreMode to 'LastMinionBackup' so it'll then be restored.
IF @IsRemote = 1
BEGIN -- IsRemote NewBackup
IF UPPER(@RemoteRestoreMode) = 'NEWMINIONBACKUP'
	BEGIN --NewMinionBackup

		DECLARE @RemoteRestoreModeORIG varchar(50),
				@BackupResult VARCHAR(max);
		SET @RemoteRestoreModeORIG = 'NewMinionBackup';
		SET @RemoteRestoreMode = 'LastMinionBackup';
		EXEC Minion.DBMaintInlineTokenParse @DBName = @DBName, @DynamicName = @PreferredDBName OUTPUT;
		---------------------------------------------
		------------BEGIN Log Backup Start-----------
		---------------------------------------------

				UPDATE Minion.CheckDBLogDetails
				SET STATUS = 'Running Minion Backup',
				PctComplete = 0
				WHERE ID = @CheckDBLogDetailsID;

		---------------------------------------------
		------------END Log Backup Start-------------
		---------------------------------------------

		---------------------------------------------
		------------BEGIN Minion Backup--------------
		---------------------------------------------
		EXEC Minion.BackupMaster 
			@DBType = 'User',
		    @BackupType = 'CheckDB',
		    @StmtOnly = 0,
		    @Include = @DBName;

		SET @BackupResult = (SELECT STATUS FROM Minion.BackupLogDetails WHERE DBName = @DBName AND ExecutionDateTime = (SELECT MAX(ExecutionDateTime) FROM Minion.BackupLogDetails WHERE DBName = @DBName AND UPPER(BackupType) = 'CHECKDB'))
		---------------------------------------------
		------------END Minion Backup----------------
		---------------------------------------------


		---------------------------------------------
		------------BEGIN Log Backup Success---------
		---------------------------------------------
		----If the backup fails then we're dead and there's no sense continuing.
		IF @BackupResult NOT LIKE '%FATAL ERROR%'
			BEGIN
				UPDATE Minion.CheckDBLogDetails
				SET STATUS = 'Minion Backup Complete',
					PctComplete = 100
				WHERE ID = @CheckDBLogDetailsID;
			END
		---------------------------------------------
		------------END Log Backup Success-----------
		---------------------------------------------	

		---------------------------------------------
		------------BEGIN Log Error and End----------
		---------------------------------------------
		----If the backup fails then we're dead and there's no sense continuing.
		IF @BackupResult LIKE '%FATAL ERROR%'
			BEGIN
				UPDATE Minion.CheckDBLogDetails
				SET STATUS = 'FATAL ERROR: The Minion Backup failed: ACTUAL ERROR FOLLOWS: ' + ISNULL(@BackupResult, '')
				WHERE ID = @CheckDBLogDetailsID;

				--------------BEGIN Log to Minion---------
				EXEC Minion.DBMaintLogToMinion @Module = 'CHECKDB', @DBName = @DBName, @MinionTriggerPath = @MinionTriggerPath, @ExecutionDateTime = @ExecutionDateTime, @ServerName = @LocalServer, @Folder = 'CheckDB'
				--------------END Log to Minion-----------
				RETURN;
			END
		---------------------------------------------
		------------END Log Error and End------------
		---------------------------------------------		
	END --NewMinionBackup
END -- IsRemote NewBackup
--------------------------------------------------------------------------
-------------------------END NewMinionBackup------------------------------
--------------------------------------------------------------------------

------------------------------------------
---------BEGIN LastMinionBackup-----------
------------------------------------------
IF @IsRemote = 1
BEGIN -- IsRemote LastBackup
IF UPPER(@RemoteRestoreMode) = 'LASTMINIONBACKUP'
	BEGIN --LastMinionBackup
		DECLARE @RestoreCMD VARCHAR(max),
				@RestorePreCMD VARCHAR(500),
				@RestoreTotalCMD VARCHAR(8000);

		CREATE TABLE #RestoreCmd (col1 VARCHAR(max) COLLATE DATABASE_DEFAULT);

		-------------------------------------------
		----------BEGIN Get Restore CMD------------
		-------------------------------------------

----The @RemoteRestoreMode is important here.  If the RestoreMode is NONE, then that means you don't want to take a backup on the remote system because you've already
----got a DB on the remote system you want to run the checkdb on.  In that case, @PreferredDBName is the name of the DB that already exists.  It can either be a wildcar
----that stands for the latest DB that matches the pattern, or it can be a static DBName.  However, here you're asking to restore the latest MB backup.
----Therefore, to make things easy to manage, you need to give either a DBName, or you can give a DB naming convention.
----Currently, it allows for some form of DBName, followed by some identifier, followed by a date.  These are all optional.
----An example is to set PreferredDBName in CheckDBSettingsDB to %DBName%-CheckDB-%Date%.  In this case, %DBName% will be replaced with the name of the current DB,
----and %Date% will be replaced with today's date in yyyyMD format.  So the final R@PreferredDBName for the current DBName of DB1 would be DB1-CheckDB-20161123, for example.
----You're free to change the order of the dynamic params or any static text as you like.  However, the only dynamic params currently supported are %DBName% and %Date%.
----Anything else will be treated as static text.  This is to allow you to have a dynamically-created DBName each time w/o having to manage the names yourself.

		EXEC Minion.DBMaintInlineTokenParse @DBName = @DBName, @DynamicName = @PreferredDBName OUTPUT;

		INSERT #RestoreCmd (col1)
		EXEC Minion.BackupRestoreDB @ServerName = @PreferredServer,@DBName = @DBName, @BackupLoc = @RemoteRestoreLocation, @RestoreDBName = @PreferredDBName

		SET @RestoreCMD = (SELECT TOP 1 col1 FROM #RestoreCmd)
		-------------------------------------------
		----------BEGIN Get Restore CMD------------
		-------------------------------------------

		---------------------------------------------------------------------
		----------------------BEGIN Run Remote Restore-----------------------
		---------------------------------------------------------------------			

		------------------------------------------
		----------BEGIN Log Restore Start---------
		------------------------------------------
					UPDATE Minion.CheckDBLogDetails
						SET
							STATUS = 'Restoring DB on ' + @PreferredServer + ' (' + @RemoteCheckDBMode + ')',
							PctComplete = 0,
							CheckDBName = @PreferredDBName,
							PreferredServer = @PreferredServer
						WHERE
							ID = @CheckDBLogDetailsID;
		------------------------------------------
		----------END Log Restore Start-----------
		------------------------------------------

IF UPPER(@RemoteCheckDBMode) = 'CONNECTED'
	BEGIN --Connected
		SET @RestorePreCMD = 'sqlcmd -r 1 -S"' + @PreferredServer + '"'
			--+ CASE WHEN (@PreferredServerPort IS NOT NULL AND @PreferredServerPort <> '') THEN ','  ELSE '' END
				+ ISNULL(CAST(@PreferredServerPort AS VARCHAR(10)), '')
			+ ' -d "master" -q "' 
		SET @RestoreTotalCMD = @RestorePreCMD
			+ @RestoreCMD + '"'
--PRINT @RestoreTotalCMD
		CREATE TABLE #RestoreResults (ID INT IDENTITY(1,1), col1 VARCHAR(max) COLLATE DATABASE_DEFAULT);
		DECLARE @RestoreErrors VARCHAR(max);
		INSERT #RestoreResults
				(col1)
				EXEC xp_cmdshell @RestoreTotalCMD;

				DELETE FROM #RestoreResults
						WHERE col1 IS NULL OR UPPER(col1) LIKE '%PROCESSED%'

		SELECT @RestoreErrors = STUFF((SELECT ' ' + col1
						FROM #RestoreResults AS T1
						ORDER BY T1.ID
						FOR XML PATH('')), 1, 1, '')
				FROM
					#RestoreResults AS T2;
	END --Connected

---!!!Remote job stuff was here!!!!

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.CheckDBDebug (ExecutionDateTime, DBName, OpName, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @Op, 'CheckDB', 'Remote Restore', @RestoreTotalCMD
END
-------------------DEBUG-------------------------------

		----------------------------------------------------------------------------
		----------------------BEGIN Log Remote Restore Error------------------------
		----------------------------------------------------------------------------
               IF @RestoreErrors IS NOT NULL OR @RestoreErrors <> ''
				BEGIN
					UPDATE Minion.CheckDBLogDetails
						SET
							STATUS = 'FATAL ERROR WITH REMOTE RESTORE:  ' + @RestoreErrors
						WHERE
							ID = @CheckDBLogDetailsID;

					--------------BEGIN Log to Minion---------
					EXEC Minion.DBMaintLogToMinion @Module = 'CHECKDB', @DBName = @DBName, @MinionTriggerPath = @MinionTriggerPath, @ExecutionDateTime = @ExecutionDateTime, @ServerName = @LocalServer, @Folder = 'CheckDB'
					--------------END Log to Minion-----------

					RETURN; --There's no need to continue of the restore failed.
				END
		----------------------------------------------------------------------------
		----------------------END Log Remote Restore Error--------------------------
		----------------------------------------------------------------------------

		---------------------------------------------------------------------
		----------------------END Run Remote Restore-------------------------
		---------------------------------------------------------------------
						
	END --LastMinionBackup
END -- IsRemote LastBackup
------------------------------------------
---------END LastMinionBackup-------------
------------------------------------------

IF @IsRemote = 1 AND UPPER(@RemoteCheckDBMode) = 'DISCONNECTED'
	BEGIN --Remote Job

IF UPPER(@RemoteCheckDBMode) = 'DISCONNECTED'
	BEGIN --Disconnected

	----Send @Remoterun to Minion.Work so it can be seen by the Monitor.
	----INSERT Minion.Work
	----SELECT @ExecutionDateTime, 'CheckDB', @DBName, NULL, '@RemoteRun-Disconnected', 'CheckDB', @RemoteRun

--------------------------------------------------
--------------BEGIN Set Remote JobName------------
--------------------------------------------------
----If the JobName is NULL we have to have something there.
IF @RemoteJobName IS NULL
	BEGIN
		SET @RemoteJobName = 'MinionCheckDB-REMOTE' + @DBName + '-From-' + @LocalServer;
	END

IF @RemoteJobName LIKE '%\%%' ESCAPE '\'
	BEGIN
		EXEC Minion.DBMaintInlineTokenParse @DBName = @DBName, @DynamicName = @RemoteJobName OUTPUT;
	END

--------------------------------------------------
--------------END Set Remote JobName--------------
--------------------------------------------------
----SELECT @DBName, @PreferredServer, @PreferredServerPort, @LocalServer, @Port, @MaintDB, @PreferredDBName, @RestoreCMD, @ExecutionDateTime, @RemoteJobName, @RemoteRestoreMode;

		------------------------------------------
		----------BEGIN Log Remote Start----------
		------------------------------------------
					UPDATE Minion.CheckDBLogDetails
						SET
							STATUS = 'Preparing run on ' + @PreferredServer,
							CheckDBName = @PreferredDBName,
							PreferredServer = @PreferredServer
						WHERE
							ID = @CheckDBLogDetailsID;
		------------------------------------------
		----------END Log Remote Start------------
		------------------------------------------

		------------------------------------------------------------
		---------------BEGIN Create and Run Remote Job--------------
		------------------------------------------------------------
EXEC Minion.CheckDBRemoteRunner @DBName, @PreferredServer, @PreferredServerPort, @LocalServer, @Port, @MaintDB, @PreferredDBName, @RestoreCMD, @ExecutionDateTime, @RemoteJobName, @RemoteRestoreMode;
		------------------------------------------------------------
		---------------END Create and Run Remote Job----------------
		------------------------------------------------------------

DECLARE @RemoteJobErrors VARCHAR(MAX);
SET @RemoteJobErrors = (SELECT TOP 1 Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName AND SPName = 'CheckDBRemoteRunner' AND Param LIKE '@RemoteJobErrors%')

IF @RemoteJobErrors IS NOT NULL
	BEGIN
		--------------BEGIN Log to Minion---------
		EXEC Minion.DBMaintLogToMinion @Module = 'CHECKDB', @DBName = @DBName, @MinionTriggerPath = @MinionTriggerPath, @ExecutionDateTime = @ExecutionDateTime, @ServerName = @LocalServer, @Folder = 'CheckDB'
		--------------END Log to Minion-----------
		RETURN; --This is a fatal error for a remote job. If something goes wrong in the create or the start then we have to stop.
	END

----------------------------------------------------------------
----------------------BEGIN Remote Job Monitor Loop-------------
----------------------------------------------------------------
DECLARE @Remotei TINYINT;
DECLARE @RemoteJobRunning TABLE(col1 VARCHAR(max))
SET @Remotei = 1;

		DECLARE @JobRunSQL VARCHAR(500),
				@JobRunCMD VARCHAR(1000),
				@RemoteJobStatusCMD VARCHAR(8000),
				@RemoteJobStatusSQL VARCHAR(2000),
				@JobName VARCHAR(400);

SET @JobName = (SELECT TOP 1 Value FROM Minion.Work WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @PreferredDBName AND Param = '@JobName')

WHILE @Remotei > 0
	BEGIN

		WAITFOR DELAY '00:00:10';
		SET @JobRunSQL = 'SELECT COUNT(*) AS CT FROM sys.dm_exec_sessions es INNER JOIN msdb.dbo.sysjobs sj ON sj.job_id = CAST(CONVERT( BINARY(16), SUBSTRING(es.program_name , 30, 34), 1) AS UNIQUEIDENTIFIER) WHERE program_name LIKE ''''SQLAgent - TSQL JobStep (Job % : Step %)'''' AND sj.name = ''''' + @JobName + ''''';';
		
		SET @RemoteJobStatusCMD = 'xp_cmdshell ''powershell "';
		SET @RemoteJobStatusSQL = '$RemoteBox = "' + @PreferredServer + CASE WHEN (@PreferredServerPort IS NOT NULL AND @PreferredServerPort <> '') THEN ','  ELSE '' END
				--+ ISNULL(CAST(@PreferredServerPort AS VARCHAR(10)), '') 
				+ '";'
		+ '$MainBox = "' + @LocalServer + CASE WHEN (@Port IS NOT NULL AND @Port <> '') THEN ','  ELSE '' END
				+ ISNULL(CAST(@Port AS VARCHAR(10)), '') + '";'
		+ '$DB = "' + @MaintDB + '";'
		+ '$fmt = "MM-dd-yyyy %H:m:ss.fff";'
		+ '$CheckDBName = "' + @PreferredDBName + '";'
		+ '$RemoteQuery = "' + @JobRunSQL + '";'
		+ '$RemoteConnString = "Data Source=$RemoteBox;Initial Catalog=$DB;Integrated Security=SSPI;";'
		+  '$RemoteConn  = New-Object System.Data.SqlClient.SQLConnection($RemoteConnString);'
		+  '$SqlCMD = New-Object system.Data.SqlClient.SqlCommand;'
		+  '$SqlCMD.CommandText = $RemoteQuery;'
		+  '$SqlCMD.connection = $RemoteConn;'
		+  '$SqlCMD.CommandTimeout = 0;'
		+  '$MainConnString = "Data Source=$MainBox;Initial Catalog=$DB;Integrated Security=SSPI;";'
		+  '$da = New-Object System.Data.SqlClient.SqlDataAdapter;'
		+  '$da.SelectCommand = $SqlCMD;'
		+  '$ds = New-Object System.Data.DataSet;'
		+  '$da.Fill($ds, "RemoteJobStatus") | Out-Null;'
		+  '$RemoteConn.close();'
		+  'foreach ($row in $ds.tables["RemoteJobStatus"].rows)'
		+  '{'
		+ '[string]$CT = $row.CT;'
		+ '$CT;'
  		+   '}';
SET @RemoteJobStatusSQL = REPLACE(@RemoteJobStatusSQL, '"', '"""');
SET @RemoteJobStatusSQL = @RemoteJobStatusSQL + '" '''
SET @RemoteJobStatusCMD = @RemoteJobStatusCMD + @RemoteJobStatusSQL;
---SELECT @RemoteJobStatusCMD AS RemoteJobStatusCMD
		INSERT @RemoteJobRunning
		EXEC (@RemoteJobStatusCMD)

		DELETE @RemoteJobRunning WHERE col1 IS NULL;
		SET @Remotei = (SELECT TOP 1 col1 FROM @RemoteJobRunning)
		DELETE @RemoteJobRunning;

	END
----------------------------------------------------------------
----------------------END Remote Job Monitor Loop---------------
----------------------------------------------------------------

	END --Disconnected
	
	END	--Remote Job

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
------------------------------------END Remote Restore----------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------



 --------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------------------------
 -------------------------------END Settings-------------------------------------------------
 --------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------------------------

 

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
----------------------------------BEGIN Create Snapshot----------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
IF @IsRemote = 0
BEGIN --RemoteRun 0
IF @CreateSnapshot = 1
BEGIN --@CreateSnapshot = 1
IF @OnlineEdition = 1
	BEGIN --Snapshot


	INSERT #CheckDBSnapshot
			(SnapshotDBName, FileID, TypeDesc, Name, PhysicalName, IsReadOnly, IsSparse,
			 SnapshotDrive, SnapshotPath, FullPath, ServerLabel, PathOrder, Cmd, SizeInKB, MaxSizeInKB)
	EXEC Minion.CheckDBSnapshotGet @DBName = @DBName, @OpName = @Op;

----Here we need to pass this to a work table so other SPs can get at it easily.
INSERT Minion.CheckDBSnapshotLog (ExecutionDateTime, OpName, DBName, SnapshotDBName, FileID, TypeDesc, Name, PhysicalName, IsReadOnly, IsSparse, SnapshotDrive, SnapshotPath, FullPath, ServerLabel, PathOrder, Cmd, SizeInKB, MaxSizeInKB)
SELECT @ExecutionDateTime, @Op, @DBName, SnapshotDBName, FileID, TypeDesc, Name, PhysicalName, IsReadOnly, IsSparse, SnapshotDrive, SnapshotPath, FullPath, ServerLabel, PathOrder, Cmd, SizeInKB, MaxSizeInKB
FROM #CheckDBSnapshot

	SELECT TOP 1 
		@SnapshotCMD = Cmd,
		@CurrentSnapshotDBName = SnapshotDBName
	FROM #CheckDBSnapshot;


	--------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------
	------------------------BEGIN Create Directories--------------------------------------
	--------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------
	 If @StmtOnly = 0
		BEGIN --@StmtOnly = 0

		EXEC Minion.CheckDBSnapshotDirCreate @ExecutionDateTime = @ExecutionDateTime, @DBName = @DBName, @Op = @Op

	----------------------------------------------------
	------------END Create Paths------------------------
	----------------------------------------------------

	END --@StmtOnly = 0
	--------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------
	------------------------END Create Directories----------------------------------------
	--------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------


	-------------------------BEGIN Run Stmt-----------------------


						DECLARE @DeleteCMD VARCHAR(2000);
					
						SET @PreCMD = 'sqlcmd -r 1 -S"' + @ServerInstance + '"'
							+ CAST(@Port AS VARCHAR(6))
							+ ' -d "master" -q "' 
						SET @TotalCMD = @PreCMD
							+ @SnapshotCMD + '"'

						DECLARE @SnapshotErrors VARCHAR(max);
						INSERT #SnapshotResults
								(col1)
								EXEC xp_cmdshell @TotalCMD;

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.CheckDBDebug (ExecutionDateTime, DBName, OpName, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @Op, 'CheckDB', 'Create Snapshot', @TotalCMD
END
-------------------DEBUG-------------------------------

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

	-------------------------END Run Stmt-------------------------


	--------------------BEGIN Snapshot Create Fail Action-------------------------
----You may want to run the op anyway if the snapshot fails.
IF @SnapshotErrors LIKE 'SNAPSHOT CREATE ERROR%' AND (UPPER(@SnapshotFailAction) = 'CONTINUE' OR UPPER(@SnapshotFailAction) = 'CONTINUEWITHTABLOCK')
	BEGIN
		UPDATE Minion.CheckDBLogDetails
		SET Warnings = ISNULL(Warnings, '') + @SnapshotErrors + ' SnapshotFailAction in Minion.CheckDBSettingsDB is set to ' + @SnapshotFailAction + '. Error Message Follows: '
		WHERE ID = @CheckDBLogDetailsID;

		SET @SnapshotErrors = NULL;
		SET @CurrentSnapshotDBName = NULL; --If this is NULL it'll get set to the DBName below.
	END

IF UPPER(@SnapshotFailAction) = 'CONTINUEWITHTABLOCK'
	BEGIN
		SET @IsTabLock = 1;
	END

	--------------------END Snapshot Create Fail Action---------------------------

	------------------------BEGIN Log Create Snapshot Errors-----------------------
						IF @SnapshotErrors <> '' OR @SnapshotErrors IS NOT NULL
							BEGIN
								UPDATE Minion.CheckDBLogDetails
									SET
										STATUS = 'FATAL ERROR: We were not able to create the folder in the path specified.  Make sure your settings in the Minion.BackupSnapshotPath table are correct and that you have permission to create folders on this drive. ACTUAL ERROR FOLLOWS: '
										+ @SnapshotErrors
									WHERE
										ID = @CheckDBLogDetailsID;
								--------------BEGIN Log to Minion---------
								EXEC Minion.DBMaintLogToMinion @Module = 'CHECKDB', @DBName = @DBName, @MinionTriggerPath = @MinionTriggerPath, @ExecutionDateTime = @ExecutionDateTime, @ServerName = @LocalServer, @Folder = 'CheckDB'
								--------------END Log to Minion-----------
								RETURN
							END
	------------------------END Log Log Create Snapshot Errors----------------------
		TRUNCATE TABLE #CheckDBSnapshot;
	END -- Snapshot
END --@CreateSnapshot = 1
END --RemoteRun 0
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
----------------------------------END Create Snapshot------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
 
----If we created a snapshot then we run the checkdb against that instead so we merge the 2 DB names here.
----If there's a snapshotdbname then we use it and it gets plugged into the stmts below.  Otherwise,
----we use the DBName passed into the routine.  We still need both of them for different purposes though, including logging.

IF @IsRemote = 0
BEGIN
	IF @CurrentSnapshotDBName IS NULL
		BEGIN
			SET @CurrentSnapshotDBName = @DBName;
		END
END
 --------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------------------------
 -------------------------------BEGIN Create CheckDB Stmt------------------------------------
 --------------------------------------------------------------------------------------------
 -------------------------------------------------------------------------------------------- 

---------------------------------------------
----------BEGIN Set Remote Run DB------------
---------------------------------------------
IF @IsRemote = 1
	BEGIN
		SET @CurrentSnapshotDBName = @PreferredDBName;
	END
---------------------------------------------
----------END Set Remote Run DB--------------
---------------------------------------------
IF @IsRemote = 0 OR (@IsRemote = 1 AND UPPER(@RemoteCheckDBMode) = 'CONNECTED')
BEGIN --CHECKDB STMT 
SET @CheckDBSQL = CASE WHEN @DisableDOP = 1 THEN 'DBCC TRACEON(2528);' ELSE '' END + ISNULL(@StmtPrefix, '') + 'DBCC ' + UPPER(@Op) + '(''''' + @CurrentSnapshotDBName + ''''''

----Set initial repair option.  It will be overwritten if there's a repair option being used.
SET @IsRepair = 0;
----This is just an easy way for the rest of the routine to see if repair is being used.
IF (@RepairOption IS NOT NULL AND @RepairOption <> 'NONE')
	BEGIN
		SET @IsRepair = 1;
	END

----We want RepairOption to be more important than NoIndex, so if they're both present, 
----RepairOption will win.
IF @NoIndex = 1 AND @IsRepair = 0
	BEGIN
		SET @CheckDBSQL = @CheckDBSQL + ', NOINDEX'
	END

IF @IsRepair = 1
	BEGIN
		IF @RepairOptionAgree = 1
			BEGIN
				SET @CheckDBSQL = @CheckDBSQL + ', ' + @RepairOption
			END
	END

SET @CheckDBSQL = @CheckDBSQL + ')';
SET @CheckDBSQL = @CheckDBSQL + ' WITH ';

IF @AllErrorMsgs = 1
	BEGIN
		SET @CheckDBSQL = @CheckDBSQL + 'ALL_ERRORMSGS, ';
	END

IF @ExtendedLogicalChecks = 1
	BEGIN
		SET @CheckDBSQL = @CheckDBSQL + 'EXTENDED_LOGICAL_CHECKS, ';
	END

IF @NoInfoMsgs = 1
	BEGIN
		SET @CheckDBSQL = @CheckDBSQL + 'NO_INFOMSGS, ';
	END

IF @IsTabLock = 1
	BEGIN
		SET @CheckDBSQL = @CheckDBSQL + 'TABLOCK, ';
	END

IF @IntegrityCheckLevel IS NOT NULL
	BEGIN
		--IF UPPER(@IntegrityCheckLevel) <> 'PHYSICAL_ONLY'
			BEGIN
				SET @CheckDBSQL = @CheckDBSQL + UPPER(@IntegrityCheckLevel) + ', ';
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

		SET @CheckDBSQL = @CheckDBSQL + ISNULL(@StmtSuffix, '')
END --CHECKDB STMT

 --------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------------------------
 -------------------------------END Create CheckDB Stmt--------------------------------------
 --------------------------------------------------------------------------------------------
 -------------------------------------------------------------------------------------------- 



-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------BEGIN Last Good CheckDB-------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----We can provide this info easily and it may make the world of difference when investigating a server
----because you can easily see how long between each checkdb. This only handles a good checkdb though.
----Not only does it not have to have been done in the Minion system, but it only gets the last one that actually had no errors.
----So if checkdb has been running for months and has had any errors, then it won't change this date.
----To combat this, we're also going to check our LogDetails table so we can see if there have been any failures.
----If there have been, then we'll display them in the table as well.  We'll also check the LogDetails table for the latest
----checkdb and result. The date we log won't match the one returned by the system exactly because we've got a small amount of
----housekeeping before we get a chance to log the operation.  It should be really close to the system timestamp though.
----Also, we'll always take the later date between the 2.  So if our date is later, and it probably will be slightly later, then
----we'll use that date so we can get the result and display it as well.  We clearly can't display the last result in our log
----and the timestamp from the system because they won't match up if you need to go find that entry in the log.
----So if there isn't an entry in LogDetails becasue the checkdb was rum from another process, then we'll display N/A for the 
----LastCheckDBResult.
----This also only checks the last checkdb. It may be necessary in the future to make it check for the last of the current operation.
----So if we're only running a checkalloc then this still shows the last checkdb instead of the last of the current operation.
----This is because I don't think SQL stores that info.  There may also be some DBs that always have checktable run instead in which case,
----this will be misleading if it always shows a really low date. The individual tables will be taken care of in the checktable section.
----!!!!!!!!!!!!!There's also a special situation where if you're on Ent and you're creating your own snapshots and running the checkDB against those, then
----			 it won't update the flag in the DB.  So if you've always run checkdb against custom snapshots then it'll look like checkdb has never been run.
----			 This is another reason why I compare it with the LogDetails table as well; so i can get an accurate reading of when you've run checkdb.
If @StmtOnly = 0
BEGIN -- StmtOnly = 0
CREATE TABLE #DBTemp (
       Id INT IDENTITY(1,1), 
       ParentObject VARCHAR(255) COLLATE DATABASE_DEFAULT,
       [Object] VARCHAR(255) COLLATE DATABASE_DEFAULT,
       Field VARCHAR(255) COLLATE DATABASE_DEFAULT,
       [VALUE] VARCHAR(255) COLLATE DATABASE_DEFAULT
)

CREATE TABLE #DBCCResult (
      -- Id INT IDENTITY(1,1)PRIMARY KEY CLUSTERED, 
       --DBName sysname ,
       LastKnownGood DATETIME,
      -- RowNum	INT
)

DECLARE
	@LastCheckDBSQL VARCHAR(4000),
	@LastCheckDBDate DATETIME,
	@LastMinionCheckDBDate DATETIME,
	@LastMinionCheckDBResult VARCHAR(max);

	SET @LastCheckDBSQL = 'Use [' + @DBName +'];' + CHAR(10)+ CHAR(13)
	SET @LastCheckDBSQL = @LastCheckDBSQL + 'DBCC Page ( ['+ @DBName +'],1,9,3) WITH TABLERESULTS;' + CHAR(10)+ CHAR(13)

	INSERT INTO #DBTemp
		EXECUTE (@LastCheckDBSQL);

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.CheckDBDebug (ExecutionDateTime, DBName, OpName, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @Op, 'CheckDB', 'Get last CHECKDB', @LastCheckDBSQL
END
-------------------DEBUG-------------------------------

	SET @LastCheckDBSQL = ''

	INSERT INTO #DBCCResult (LastKnownGood)
	SELECT VALUE 
	FROM #DBTemp
	WHERE Field = 'dbi_dbccLastKnownGood';

SET @LastCheckDBDate = (SELECT TOP 1 LastKnownGood FROM #DBCCResult)
DROP TABLE #DBTemp
DROP TABLE #DBCCResult

----SELECT @LastMinionCheckDBDate = (SELECT TOP 1 OpEndTime FROM Minion.CheckDBLogDetails WHERE DBName = @DBName AND UPPER(OpName) = 'CHECKDB' ORDER BY ExecutionDateTime DESC)
SELECT TOP 1 @LastMinionCheckDBDate = OpEndTime,
			 @LastMinionCheckDBResult = STATUS
FROM Minion.CheckDBLogDetails 
WHERE DBName = @DBName AND UPPER(OpName) = 'CHECKDB' 
ORDER BY OpEndTime DESC

----SELECT @LastMinionCheckDBDate, @LastMinionCheckDBResult
----I explained at the top of this section why we're setting the date like this.
SET @LastCheckDBDate = CASE 
						WHEN ISNULL(@LastMinionCheckDBDate, '1900-01-01 00:00:00.000') >= @LastCheckDBDate THEN @LastMinionCheckDBDate
						WHEN ISNULL(@LastMinionCheckDBDate, '1900-01-01 00:00:00.000') < @LastCheckDBDate THEN @LastCheckDBDate
					   END

SET @LastMinionCheckDBResult = CASE
								WHEN @LastMinionCheckDBResult IS NULL THEN 'N/A'
								WHEN @LastMinionCheckDBResult IS NOT NULL THEN @LastMinionCheckDBResult
							   END

END -- StmtOnly = 0
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------END Last Good CheckDB---------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

If @StmtOnly = 1
	BEGIN
		PRINT @CheckDBSQL
	END	

If @StmtOnly = 0
BEGIN -- StmtOnly = 0
	 SET @BeginTime = GETDATE();
----We're creating a specific #table because if we get multithreading done we don't want any bleeding between executions. So we're hoping each DB and run can have its own #table this way.
	SET @CheckDBRunSQL = 'SET NOCOUNT ON;CREATE TABLE [#' + @DBTempTable + @DBTempTableDate + '] ([ExecutionDateTime] [DATETIME] NULL,[DBName] [sysname] NULL,[BeginTime] [DATETIME] NULL,[EndTime] [DATETIME] NULL,[Error] [INT] NULL,[Level] [INT] NULL,[State] [INT] NULL,[MessageText] [VARCHAR](7000) NULL,[RepairLevel] [NVARCHAR](50) NULL,[Status] [INT] NULL,[DbId] [INT] NULL,[DbFragId] [INT] NULL,[ObjectId] [BIGINT] NULL,[IndexID] [INT] NULL,[PartitionId] [BIGINT] NULL,[AllocUnitId] [BIGINT] NULL,[RidDBId] [INT] NULL,[RidPruId] [INT] NULL,[File] [INT] NULL,[Page] [BIGINT] NULL,[Slot] [BIGINT] NULL,[RefDbId] [INT] NULL,[RefPruId] [INT] NULL,[RefFile] [INT] NULL,[RefPage] [INT] NULL,[RefSlot] [INT] NULL,[Allocation] [INT] NULL);'
	+ 
	---------------------------BEGIN Insert for CheckDB Cmd------------------------------
	--SQL08 and below.
	CASE WHEN @Version < '11' THEN
	'INSERT INTO [#' + @DBTempTable + @DBTempTableDate + '] (Error,[Level],[State],MessageText,RepairLevel,[Status],[DbId],ObjectId,IndexID,PartitionId,AllocUnitId,[File],Page,Slot,RefFile,RefPage,RefSlot,Allocation)'
	--SQL2012 and up.
		WHEN @Version >= '11' THEN
	'INSERT INTO [#' + @DBTempTable + @DBTempTableDate + '] (Error,[Level],[State],MessageText,RepairLevel,[Status],[DbId],DbFragId,ObjectId,IndexID,PartitionId,AllocUnitId,RidDBId,RidPruId,[File],Page,Slot,RefDbId,RefPruId,RefFile,RefPage,RefSlot,Allocation)'
	END
	---------------------------END Insert for CheckDB Cmd--------------------------------
	+ 'EXEC (''' + @CheckDBSQL + ''');' 
	+ 
	---------------------------BEGIN Insert for #Table------------------------------
	--SQL08 and below.
	CASE WHEN @Version < '11' THEN
	'INSERT INTO [' + @MaintDB + '].Minion.CheckDBResult(ExecutionDateTime,DBName,Error,[Level],[State],MessageText,RepairLevel,[Status],[DbId],ObjectId,IndexID,PartitionId,AllocUnitId,[File],Page,Slot,RefFile,RefPage,RefSlot,Allocation)'
	--SQL2012 and up.
		WHEN @Version >= '11' THEN
	+ 'INSERT INTO [' + @MaintDB + '].Minion.CheckDBResult(ExecutionDateTime,DBName,Error,[Level],[State],MessageText,RepairLevel,[Status],[DbId],DbFragId,ObjectId,IndexID,PartitionId,AllocUnitId,RidDBId,RidPruId,[File],Page,Slot,RefDbId,RefPruId,RefFile,RefPage,RefSlot,Allocation)'
	END

	+ 'SELECT ''' + CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + ''',' + '''' + @DBName + ''','
	+	
	--SQL08 and below.
	CASE WHEN @Version < '11' THEN		
 'Error,[Level],[State],MessageText,RepairLevel,[Status],[DbId],ObjectId,IndexID,PartitionId,AllocUnitId,[File],Page,Slot,RefFile,RefPage,RefSlot,Allocation FROM [#' + @DBTempTable + @DBTempTableDate + ']'
		WHEN @Version >= '11' THEN		
 'Error,[Level],[State],MessageText,RepairLevel,[Status],[DbId],DbFragId,ObjectId,IndexID,PartitionId,AllocUnitId,RidDBId,RidPruId,[File],Page,Slot,RefDbId,RefPruId,RefFile,RefPage,RefSlot,Allocation FROM [#' + @DBTempTable + @DBTempTableDate + ']'
	END
	---------------------------END Insert for #Table--------------------------------
----SELECT @CheckDBRunSQL
SET @CheckDBOpBeginTime = GETDATE();
--------------------------------------------------------------------
----------------------BEGIN Log Op Run Start------------------------
--------------------------------------------------------------------

                UPDATE Minion.CheckDBLogDetails
				SET 
					STATUS = UPPER(@Op) + ' running' + CASE WHEN @IsRemote = 1 THEN ' on ' + @PreferredServer + ' (' + @RemoteCheckDBMode + ')' WHEN @IsRemote = 0 THEN '' END,
					CheckDBName = CASE WHEN @IsRemote = 1 THEN @PreferredDBName WHEN @IsRemote = 0 THEN @CurrentSnapshotDBName END,
					NETBIOSName = @NETBIOSName,
					IsClustered = @IsClustered,
					IsInAG = @DBIsInAG,
					IsPrimaryReplica = ISNULL(@IsPrimaryReplica, 0),
					OpBeginTime = @CheckDBOpBeginTime,
					CustomSnapshot = @CreateSnapshot,
					CheckDBCmd = CASE WHEN (@IsRemote = 1 AND UPPER(@RemoteCheckDBMode) = 'DISCONNECTED') THEN CheckDBCmd ELSE REPLACE(@CheckDBSQL, '''''', '''') END,
					LastCheckDateTime = @LastCheckDBDate,
					LastCheckResult = @LastMinionCheckDBResult,
					PreferredServer = @PreferredServer
                WHERE ID = @CheckDBLogDetailsID;

--------------------------------------------------------------------
----------------------END Log Op Run Start--------------------------
--------------------------------------------------------------------

IF (@IsRemote = 1 AND @RemoteCheckDBMode = 'Connected') OR @IsRemote = 0
	BEGIN --Run Remote, Connected
		SET @PreCMD = 'sqlcmd -r 1 -S"' + @ServerInstance + '"' -- + ISNULL(@Port, '')
			+ ' -d "' + @MaintDB + '" -q "' 
		SET @TotalCMD = @PreCMD + @CheckDBRunSQL + '"'
----PRINT @TotalCMD
		INSERT #CheckDBResults(col1)
		EXEC xp_cmdshell @TotalCMD;
		----SELECT @TotalCMD AS Run
		SET @EndTime = GETDATE();
	END  --Run Remote, Connected


-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.CheckDBDebug (ExecutionDateTime, DBName, OpName, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @Op, 'CheckDB', 'Run CheckDB', @TotalCMD
END
-------------------DEBUG-------------------------------
      
	DECLARE @CheckDBRunError VARCHAR(MAX);

    DELETE FROM #CheckDBResults WHERE col1 IS NULL OR col1 LIKE 'DBCC execution completed%'
    SELECT @CheckDBRunError = STUFF((
                                    SELECT ' ' + col1
                                    FROM #CheckDBResults AS T1
                                    ORDER BY T1.ID
                                FOR XML PATH('')), 1, 1, '')
        FROM #CheckDBResults AS T2;

	----SELECT 'Call Results', * FROM #CheckDBResults;

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-------------------------BEGIN Get Remote Results---------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

IF @IsRemote = 1 --AND UPPER(@RemoteCheckDBMode) = 'CONNECTED'
	BEGIN --Remote Results

		CREATE TABLE #RemoteResults (ID INT IDENTITY(1,1), col1 VARCHAR(max) COLLATE DATABASE_DEFAULT);

		DECLARE @RemoteSQL VARCHAR(4000),
				@RemoteCMD VARCHAR (8000),
				@RemoteResultsError VARCHAR(MAX);
		SET @RemoteCMD = 'EXEC xp_cmdshell ''powershell "';
		SET @RemoteSQL = '$RemoteBox = """' + @PreferredServer + CASE WHEN (@PreferredServerPort IS NOT NULL AND @PreferredServerPort <> '') THEN ','  ELSE '' END
				+ ISNULL(CAST(@PreferredServerPort AS VARCHAR(10)), '') + '""";'
		+ '$MainBox = """' + @LocalServer + CASE WHEN (@Port IS NOT NULL AND @Port <> '') THEN ','  ELSE '' END
				+ ISNULL(CAST(@Port AS VARCHAR(10)), '') + '""";'
		+ '$Table = """Minion.CheckDBResult""";'
		+ '$DB = """' + @MaintDB + '""";'
		+ '$RemoteQuery = """SELECT ExecutionDateTime,DBName,BeginTime,EndTime,Error,Level,State,MessageText,RepairLevel,Status,DbId,DbFragId,ObjectId,IndexID,PartitionId,AllocUnitId,RidDBId,RidPruId,[File],Page,Slot,RefDbId,RefPruId,RefFile,RefPage,RefSlot,Allocation FROM Minion.CheckDBResult WHERE ExecutionDateTime = ''''' 
		+ CONVERT(VARCHAR(30), @ExecutionDateTime, 21) + '''''' + 'AND DBName = ''''' + @DBName + ''''';""";'
		+ '$RemoteConnString = """Data Source=$RemoteBox;Initial Catalog=$DB;Integrated Security=SSPI;""";'
		+ '$RemoteConn  = New-Object System.Data.SqlClient.SQLConnection($RemoteConnString);'
		+ '$SqlCMD = New-Object system.Data.SqlClient.SqlCommand($RemoteQuery, $RemoteConn);'
		+ '$RemoteConn.Open();'
		+ '[System.Data.SqlClient.SqlDataReader] $SqlReader = $SqlCMD.ExecuteReader();'
		+ '$MainConnString = """Data Source=$MainBox;Initial Catalog=$DB;Integrated Security=SSPI;""";'
		+ '$BC = New-Object Data.SqlClient.SqlBulkCopy($MainConnString, [System.Data.SqlClient.SqlBulkCopyOptions]::Default);'
		+ '$BC.DestinationTableName = $Table;' 
		+ '$BC.WriteToServer($sqlReader); ' 
		+ '$SqlReader.close();' 
		+ '$RemoteConn.Close();' 
		+ '$RemoteConn.Dispose();' 
		+ '$BC.Close();';

		SET @RemoteCMD = @RemoteCMD + @RemoteSQL;
		SET @RemoteCMD = @RemoteCMD + '"''';
----SELECT @RemoteCMD AS RemoteResults
		 INSERT #RemoteResults
		 EXEC (@RemoteCMD)

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.CheckDBDebug (ExecutionDateTime, DBName, OpName, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @Op, 'CheckDB', 'Get Remote CheckDB Results', @RemoteCMD
END
-------------------DEBUG-------------------------------

    DELETE FROM #RemoteResults WHERE col1 IS NULL --OR col1 LIKE 'DBCC execution completed%'
    SELECT @RemoteResultsError = STUFF((
                                    SELECT ' ' + col1
                                    FROM #RemoteResults AS T1
                                    ORDER BY T1.ID
                                FOR XML PATH('')), 1, 1, '')
        FROM #RemoteResults AS T2;
	END --Remote Results

UPDATE Minion.CheckDBResult
	   SET BeginTime = @BeginTime,
		   EndTime = @EndTime
WHERE ExecutionDateTime = @ExecutionDateTime
AND DBName = @DBName

SET @CheckDBOpEndTime = GETDATE();
	 	 
END -- StmtOnly = 0

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-------------------------END Get Remote Results-----------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------


-------------------------------------------------------------------------
-------------------------------------------------------------------------
---------------BEGIN Delete Remote DB and Job----------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------
IF @IsRemote = 1
BEGIN --Delete Remote DB and Job
	DECLARE @DropRemoteDBSQL VARCHAR(1000),
			@DropRemoteJobSQL VARCHAR(1000),
			@RemoteDropCMD VARCHAR(8000),
			@RemoteDropErrors VARCHAR(max);

	CREATE TABLE #DropRemoteObjects
	(
	ID INT IDENTITY(1,1),
	col1 VARCHAR(MAX)
	);

	SET @PreCMD = '';
	SET @DropRemoteDBSQL = '';
	SET @DropRemoteJobSQL = '';

	IF @DropRemoteDB = 1
		BEGIN
			SET @DropRemoteDBSQL = 'DROP DATABASE [' + @PreferredDBName + ']; ';
		END
	IF @DropRemoteJob = 1
		BEGIN
			SET @DropRemoteJobSQL = 'EXEC msdb..sp_delete_job @job_name = ''' + @RemoteJobName + '''';
		END

IF @DropRemoteDB = 1 OR @DropRemoteJob = 1
	BEGIN --@DropRemoteDB = 1 OR @DropRemoteJob = 1
		SET @PreCMD = 'sqlcmd -r 1 -S"' + @ServerInstance + '"' -- + ISNULL(@Port, '')
			+ ' -d "master" -q "' 
		SET @RemoteDropCMD = @PreCMD + @DropRemoteDBSQL + @DropRemoteJobSQL + '"'
		INSERT #DropRemoteObjects(col1)
		EXEC xp_cmdshell @RemoteDropCMD;
----SELECT @RemoteDropCMD AS DropRemote
							DELETE FROM #DropRemoteObjects
								   WHERE col1 IS NULL

						IF @RemoteDropErrors IS NOT NULL
							BEGIN --Delete Snapshot Errors
								SELECT
									@RemoteDropErrors = 'REMOTE DROP ERROR: '
									+ STUFF((SELECT ' ' + col1
										FROM #DropRemoteObjects AS T1
										ORDER BY T1.ID
										FOR XML PATH('')), 1, 1, '')
										FROM #DropRemoteObjects AS T2;
								----------------------------------------------------
								------------BEGIN Log Remote Drop Errors------------
								----------------------------------------------------
								UPDATE Minion.CheckDBLogDetails
								SET Warnings = ISNULL(Warnings, '') + ISNULL(@RemoteDropErrors, '')
								WHERE ID = @CheckDBLogDetailsID;
								----------------------------------------------------
								------------END Log Remote Drop Errors--------------
								----------------------------------------------------
							END --Delete Snapshot Errors
	END --@DropRemoteDB = 1 OR @DropRemoteJob = 1
END --Delete Remote DB and Job
-------------------------------------------------------------------------
-------------------------------------------------------------------------
---------------END Delete Remote DB and Job----------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------


-------------------------------------------------------------------------
-------------------------------------------------------------------------
---------------BEGIN Delete Results--------------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------



-------------------------------------------------------------------------
-------------------------------------------------------------------------
---------------BEGIN Get Error CTs---------------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------
DECLARE @CheckDBAllocationErrorCT INT,
		@CheckDBConsistencyErrorCT INT,
		@CheckDBErrorSummary varchar(1000);

----SELECT @IsRemote AS IsRemote, @DBName AS DBName, @PreferredDBName AS PDB, @RemoteCheckDBMode AS Mode

----Here, if you're running remote/connected on the same box you will get more
----than 1 summary line so we have to use top 1.    
IF @IsRemote = 0 OR (@IsRemote = 1 AND @DBName = @PreferredDBName) OR (@IsRemote = 1 AND UPPER(@RemoteCheckDBMode) = 'CONNECTED')
	BEGIN

		SET @CheckDBErrorSummary = (SELECT TOP 1 MessageText FROM Minion.CheckDBResult WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @DBName AND MessageText LIKE UPPER(@Op) + ' found%allocation errors and%consistency errors in database%')		
	END
IF @IsRemote = 1 AND (UPPER(@RemoteCheckDBMode) = 'DISCONNECTED' AND @DBName <> @PreferredDBName)
	BEGIN

		SET @CheckDBErrorSummary = (SELECT TOP 1 MessageText FROM Minion.CheckDBResult WHERE ExecutionDateTime = @ExecutionDateTime AND DBName = @PreferredDBName AND MessageText LIKE UPPER(@Op) + ' found%allocation errors and%consistency errors in database%')		
	END

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.CheckDBDebug (ExecutionDateTime, DBName, OpName, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @Op, 'CheckDB', 'CheckDB Error Summary', @CheckDBErrorSummary
END
-------------------DEBUG-------------------------------

----SELECT @CheckDBErrorSummary AS summary
        BEGIN -- <> All
			
            DECLARE @CheckDBErrorSummaryTable TABLE ( ID TINYINT IDENTITY(1,1), DBName VARCHAR(500) );
            DECLARE @CheckDBErrorSummaryString VARCHAR(500);
            WHILE LEN(@CheckDBErrorSummary) > 0 
                BEGIN
                    SET @CheckDBErrorSummaryString = LEFT(@CheckDBErrorSummary,
                                                    ISNULL(NULLIF(CHARINDEX(' ',
                                                              @CheckDBErrorSummary) - 1,
                                                              -1),
                                                           LEN(@CheckDBErrorSummary)))
                    SET @CheckDBErrorSummary = SUBSTRING(@CheckDBErrorSummary,
                                             ISNULL(NULLIF(CHARINDEX(' ',
                                                              @CheckDBErrorSummary), 0),
                                                    LEN(@CheckDBErrorSummary)) + 1,
                                             LEN(@CheckDBErrorSummary))

                    INSERT  INTO @CheckDBErrorSummaryTable
                            ( DBName )
                    VALUES  ( @CheckDBErrorSummaryString )
                END 
END

--UPDATE @CheckDBErrorSummaryTable SET DBName = 12324543 WHERE ID = 3
--UPDATE @CheckDBErrorSummaryTable SET DBName = 999898 WHERE ID = 7
SET @CheckDBAllocationErrorCT = (SELECT DBName FROM @CheckDBErrorSummaryTable WHERE ID = 3)
SET @CheckDBConsistencyErrorCT = (SELECT DBName FROM @CheckDBErrorSummaryTable WHERE ID = 7)
----SELECT @CheckDBAllocationErrorCT AS CheckDBAllocationErrorCT, @CheckDBConsistencyErrorCT AS CheckDBConsistencyErrorCT

-------------------------------------------------------------------------
-------------------------------------------------------------------------
---------------END Get Error CTs-----------------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------




-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------BEGIN DBPostCode-------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------	

        IF @StmtOnly = 0
            BEGIN -- @StmtOnly = 0

                IF @DBPostCode IS NOT NULL
                    BEGIN -- @DBPostCode
-------------------------------------------------------------
-----------------BEGIN Log DBPostCode Start------------------
-------------------------------------------------------------
						SET @DBPostCodeStartDateTime = GETDATE();
                        UPDATE Minion.CheckDBLogDetails
                            SET
                                STATUS = 'Postcode running',
                                DBPostCodeStartDateTime = @DBPostCodeStartDateTime,
                                DBPostCode = @DBPostCode
                            WHERE
                                ID = @CheckDBLogDetailsID;
-------------------------------------------------------------
-----------------END Log DBPostCode Start--------------------
-------------------------------------------------------------

--------------------------------------------------
----------------BEGIN Run Postcode----------------
--------------------------------------------------
                        DECLARE
                            @PostCodeErrors VARCHAR(MAX),
                            @PostCodeErrorExist VARCHAR(MAX);
                        CREATE TABLE #PostCode
                            (
                             ID INT IDENTITY(1, 1),
                             col1 VARCHAR(MAX) COLLATE DATABASE_DEFAULT
                            )

                        BEGIN TRY
                            EXEC (@DBPostCode) 
                        END TRY

                        BEGIN CATCH
                            SET @PostCodeErrors = ERROR_MESSAGE();
                        END CATCH

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.CheckDBDebug (ExecutionDateTime, DBName, OpName, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @Op, 'CheckDB', 'Run Postcode', @DBPostCode
END
-------------------DEBUG-------------------------------

                        IF @PostCodeErrors IS NOT NULL
                            BEGIN
                                SELECT @PostCodeErrors = 'PostCODE ERROR: '
                                        + @PostCodeErrors
                            END	 

--------------------------------------------------
----------------END Run Postcode------------------
--------------------------------------------------
                    END -- @DBPostCode


-----BEGIN Log------

                IF @DBPostCode IS NOT NULL
                    BEGIN -- @DBPostCode
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
                                                DBPostCodeEndDateTime = @DBPostCodeEndDateTime,
                                                DBPostCodeTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @DBPostCodeStartDateTime, 21), CONVERT(VARCHAR(25), @DBPostCodeEndDateTime, 21))
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
											SET @DBPostCodeEndDateTime = GETDATE();

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.CheckDBDebug (ExecutionDateTime, DBName, OpName, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @Op, 'CheckDB', 'Postcode Errors', @PostCodeErrors
END
-------------------DEBUG-------------------------------

                                        UPDATE Minion.CheckDBLogDetails
                                            SET
                                                Warnings = ISNULL(Warnings, '')
                                                + ISNULL(@PostCodeErrors, ''),
                                                DBPostCodeEndDateTime = @DBPostCodeEndDateTime,
                                                DBPostCodeTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @DBPostCodeStartDateTime, 21), CONVERT(VARCHAR(25), @DBPostCodeEndDateTime, 21))
                                            WHERE
                                                ID = @CheckDBLogDetailsID;
                                    END --@PostCodeErrors IS NULL

-----------------------------------------------------
-------------END Log PostCode Failure-----------------
-----------------------------------------------------
                            END -- @StmtOnly = 0
                    END -- @@DBPostCode

------END Log-------

            END -- @StmtOnly = 0
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------END DBPostCode---------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------	


------------------------------------------------------------------------
------------------------BEGIN Snapshot Size-----------------------------
------------------------------------------------------------------------
----Get the final size of the snapshot before we delete it.

IF @IsRemote = 0 AND @CreateSnapshot = 1 AND (@DBName <> @CurrentSnapshotDBName)
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

 
----SELECT @CheckDBAllocationErrorCT AS CheckDBAllocationErrorCT,
----		@CheckDBConsistencyErrorCT AS CheckDBConsistencyErrorCT,
----		@PreferredDBName AS DBName
--------------------------------------------------------------------
----------------------BEGIN Log Complete Status---------------------
--------------------------------------------------------------------

                UPDATE Minion.CheckDBLogDetails
				SET 
					STATUS = CASE WHEN (@CheckDBAllocationErrorCT = 0 AND @CheckDBConsistencyErrorCT = 0 AND (Warnings IS NULL OR Warnings = '')) THEN 'Complete'
								  WHEN (@CheckDBAllocationErrorCT > 0 OR @CheckDBConsistencyErrorCT > 0 AND (Warnings IS NULL OR Warnings = '')) THEN 'Complete (' + CAST((@CheckDBConsistencyErrorCT + @CheckDBAllocationErrorCT) AS VARCHAR(10)) + ' ' + UPPER(@Op) + ' error' + CASE WHEN (@CheckDBConsistencyErrorCT + @CheckDBAllocationErrorCT) > 1 THEN 's' ELSE '' END + ' found)'
								  WHEN (@CheckDBAllocationErrorCT = 0 AND @CheckDBConsistencyErrorCT = 0 AND (Warnings IS NOT NULL OR Warnings <> '') OR @RemoteResultsError IS NOT NULL) THEN 'Complete with Warnings' 
								  WHEN (@CheckDBAllocationErrorCT > 0 OR @CheckDBConsistencyErrorCT > 0 AND (Warnings IS NOT NULL OR Warnings <> '')) THEN 'Complete with Errors and Warnings'
								  WHEN @CheckDBRunError IS NOT NULL THEN 'FATAL CHECKDB ERROR: ' + @CheckDBRunError
								  ELSE 'Complete with No Status'
							 END, 
					PctComplete = 100,
					MaxSnapshotSizeInKB = @TotalSnapshotSize,
					OpEndTime = @CheckDBOpEndTime,
					OpRunTimeInSecs = DATEDIFF(s, CONVERT(VARCHAR(25), @CheckDBOpBeginTime, 21), CONVERT(VARCHAR(25), @CheckDBOpEndTime, 21)),
					AllocationErrors = @CheckDBAllocationErrorCT,
					ConsistencyErrors = @CheckDBConsistencyErrorCT,
					Warnings = ISNULL(Warnings, '') + ISNULL(@RemoteResultsError, '')
                WHERE ID = @CheckDBLogDetailsID;
--------------------------------------------------------------------
----------------------END Log Complete Status-----------------------
--------------------------------------------------------------------


-------------------------------------------------------------------------
-------------------------------------------------------------------------
---------------BEGIN Delete Results--------------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------
----Only keep summary data.
IF UPPER(@ResultMode) = 'SUMMARY' OR @ResultMode IS NULL
	BEGIN
		DELETE Minion.CheckDBResult
		WHERE ExecutionDateTime = @ExecutionDateTime
		AND DBName = @DBName
		AND MessageText NOT LIKE 'CHECKDB found%allocation errors and%consistency errors in database%'
	END

----Delete all data.
IF UPPER(@ResultMode) = 'NONE'
	BEGIN
		DELETE Minion.CheckDBResult
		WHERE ExecutionDateTime = @ExecutionDateTime
		AND DBName = @DBName
	END
-------------------------------------------------------------------------
-------------------------------------------------------------------------
---------------END Delete Results----------------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------



END --CHECKDB OP
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------END CHECKDB--------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



-----------------------------------------------------------------------------------
-------------------------BEGIN Delete Snapshot-------------------------------------
-----------------------------------------------------------------------------------
BEGIN --Delete Snapshot
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

-------------------DEBUG-------------------------------
IF @Debug = 1
BEGIN
	INSERT Minion.CheckDBDebug (ExecutionDateTime, DBName, OpName, SPName, StepName, StepValue)
	SELECT @ExecutionDateTime, @DBName, @Op, 'CheckDB', 'Delete Snapshot Stmt', @TotalCMD
END
-------------------DEBUG-------------------------------

							DELETE FROM #SnapshotDeleteResults
								   WHERE col1 IS NULL
									  OR col1 = 'output'
									  OR col1 = 'NULL'
									  OR col1 LIKE '%-------------------------------------%'


						IF @SnapshotErrors IS NOT NULL
							BEGIN --Delete Snapshot Errors
							SELECT
										@SnapshotErrors = 'SNAPSHOT DELETE ERROR: '
										+ STUFF((SELECT ' ' + col1
											FROM #SnapshotResults AS T1
											ORDER BY T1.ID
											FOR XML PATH('')), 1, 1, '')
									FROM
										#SnapshotDeleteResults AS T2;
						END --Delete Snapshot Errors
-------------------------END Run Stmt-------------------------


		END --Run Snapshot Delete
	END --@DeleteFinalSnapshot = 1
END --Delete Snapshot
-----------------------------------------------------------------------------------
-------------------------END Delete Snapshot---------------------------------------
-----------------------------------------------------------------------------------		




---------------------------------------------------------------------
---------------------------------------------------------------------
-------- BEGIN Delete Log History------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

SET @CheckDBRetWks = (SELECT TOP 1 HistRetDays from Minion.CheckDBSettingsDB Where DBName = @DBName)

DELETE Minion.CheckDBResult
WHERE DATEDIFF(DAY, ExecutionDateTime, GETDATE()) > @HistRetDays
AND DBName = @DBName;

DELETE Minion.CheckDBLog
WHERE DATEDIFF(DAY, ExecutionDateTime, GETDATE()) > @HistRetDays
AND (UPPER(OpName) = 'CHECKDB' OR UPPER(OpName) = 'AUTO');

DELETE Minion.CheckDBLogDetails
WHERE DATEDIFF(DAY, ExecutionDateTime, GETDATE()) > @HistRetDays
AND DBName = @DBName
AND UPPER(OpName) = 'CHECKDB';

DELETE Minion.CheckDBSnapshotLog
WHERE DATEDIFF(DAY, ExecutionDateTime, GETDATE()) > @HistRetDays
AND DBName = @DBName
AND UPPER(OpName) = 'CHECKDB';

DELETE Minion.Work 
WHERE ExecutionDateTime = @ExecutionDateTime 
AND DBName = @PreferredDBName 
AND Param = '@JobName';
---------------------------------------------------------------------
---------------------------------------------------------------------
-------- END Delete Log History--------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------


------------------------------------------------------------------------
-------------------BEGIN Log to Minion----------------------------------
------------------------------------------------------------------------
If @StmtOnly = 0
	BEGIN --@StmtOnly = 0
		EXEC Minion.DBMaintLogToMinion @Module = 'CHECKDB', @DBName = @DBName, @MinionTriggerPath = @MinionTriggerPath, @ExecutionDateTime = @ExecutionDateTime, @ServerName = @LocalServer, @Folder = 'CheckDB'

----            SET @TriggerFile = 'Powershell "''' + ''''''
----                + CONVERT(VARCHAR(25), @ExecutionDateTime, 21) + ''''''''
----                + ' | out-file ''' + @MinionTriggerPath + 'CheckDB\' + @LocalServer + '.'
----                + @DBName + ''' -append"' 
--------SELECT @LocalServer, @MinionTriggerPath, @TriggerFile AS TriggerFile
----            EXEC xp_cmdshell @TriggerFile, no_output;
	END --@StmtOnly = 0

------------------------------------------------------------------------
-------------------END Log to Minion------------------------------------
------------------------------------------------------------------------
GO
