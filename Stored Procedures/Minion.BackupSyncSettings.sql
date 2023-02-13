SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [Minion].[BackupSyncSettings] 
    (
     @ExecutionDateTime DATETIME = NULL
	)
/***********************************************************************************
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------------------Minion Backup------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Created By: MidnightSQL Consulting LLC. and MidnightDBA.com

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
	EXEC [Minion].[BackupSyncSettings] ExecutionDateTime = GetDate();

Revision History:
	

***********************************************************************************/
AS
SET NOCOUNT ON;

IF @ExecutionDateTime IS NULL
    BEGIN
        SET @ExecutionDateTime = GETDATE(); END

DECLARE
    @i INT,
    @CT INT,
    @DBName VARCHAR(150),
    @Port VARCHAR(25),
    @BackupType VARCHAR(20),
    @Exclude VARCHAR(25),
    @GroupOrder VARCHAR(25),
    @GroupDBOrder VARCHAR(25),
    @Mirror VARCHAR(25),
    @DelFileBefore VARCHAR(25),
    @DelFileBeforeAgree VARCHAR(25),
    @LogLoc VARCHAR(25),
    @HistRetDays VARCHAR(25),
    @MinionTriggerPath VARCHAR(1000),
    @DBPreCode NVARCHAR(MAX),
    @DBPostCode NVARCHAR(MAX),
    @PushToMinion VARCHAR(25),
    @DynamicTuning VARCHAR(25),
    @Verify VARCHAR(25),
    @ShrinkLogOnLogBackup VARCHAR(25),
    @ShrinkLogThresholdInMB VARCHAR(25),
    @ShrinkLogSizeInMB VARCHAR(25),
    @MinSizeForDiffInGB VARCHAR(25),
    @DiffReplaceAction VARCHAR(25),
    @LogProgress VARCHAR(25),
    @FileAction VARCHAR(12),
    @FileActionTime VARCHAR(25),
    @FileActionMethod VARCHAR(25),
    @FileActionMethodFlags VARCHAR(100),
    @Encrypt VARCHAR(25),
    @Name VARCHAR(128),
    @ExpireDateInHrs VARCHAR(25),
    @RetainDays VARCHAR(25),
    @Descr VARCHAR(255),
    @Checksum VARCHAR(25),
    @Init VARCHAR(25),
    @Format VARCHAR(25),
    @CopyOnly VARCHAR(25),
    @Skip VARCHAR(25),
    @BackupErrorMgmt VARCHAR(50),
    @MediaName VARCHAR(128),
    @MediaDescription VARCHAR(255),
    @IsActive VARCHAR(25),
    @SyncServerName VARCHAR(140),
    @SyncDBName VARCHAR(140),
    @SyncSettings VARCHAR(25),
    @SyncLogs VARCHAR(25),
    @BatchPreCode VARCHAR(MAX),
    @BatchPostCode VARCHAR(MAX),
    @SpaceType VARCHAR(25),
    @ThresholdMeasure VARCHAR(25),
    @ThresholdValue VARCHAR(25),
    @NumberOfFiles VARCHAR(25),
    @BufferCount VARCHAR(25),
    @Maxtransfersize VARCHAR(25),
    @Compression VARCHAR(25),
    @BlockSize VARCHAR(25),
    @Comment VARCHAR(2000),
	@CertPword VARCHAR(1000),
	@CertName VARCHAR(120),
	@CertType VARCHAR(50),
	@BackupCert VARCHAR(10),
    @EncrAlgorithm VARCHAR(25),
    @ThumbPrint NVARCHAR(2000),
	@Day varchar(15),
	@ReadOnly varchar(15),
	@BeginTime varchar(25),
	@EndTime varchar(25),
	@MaxForTimeframe varchar(20),
	@CurrentNumBackups varchar(20),
	@Include varchar(2500),
	@DBType VARCHAR(20),
	@Debug VARCHAR(10),
	@LastRunDateTime VARCHAR(35),
	@DayOfWeek VARCHAR(25),
	@GroupName VARCHAR(200),
	@GroupDef VARCHAR(400),
	@Escape CHAR(1),
	@Action VARCHAR(15),
    @MaintType VARCHAR(25),
    @Regex VARCHAR(2000),
	@FrequencyMins VARCHAR(20),
	@FailJobOnError VARCHAR(20),
	@ServerName VARCHAR(50),
	@FailJobOnWarning VARCHAR(20);


-------------------------------------------------------------------------
--------------------BEGIN BackupCert-------------------------------------
-------------------------------------------------------------------------
---1st, truncate the existing data on the foreign server.  There's no need to try to figure out what's changed.
---The easiest is to just dump all the data and reload it.  There won't be thousands of rows in most cases so this won't be an issue.
INSERT  Minion.SyncCmds
        (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd, Pushed,
         Attempts)
SELECT
    @ExecutionDateTime, 'Backup', 'In queue', 'BackupCert',
    'TRUNCATE', 'TRUNCATE TABLE Minion.BackupCert;', 0, 0;

SET @i = 1;
SET @CT = (
           SELECT COUNT (*) FROM Minion.BackupCert
          )

SELECT
    ID = IDENTITY( INT,1,1), CertType, CertPword, BackupCert
INTO
    #BackupCertSettSync
FROM
    Minion.BackupCert ORDER BY ID ASC

WHILE @i <= @CT
    BEGIN

        SELECT
            @CertType =	CASE WHEN CertType IS NOT NULL THEN '''' + CertType + '''' ELSE 'NULL' END,
            @CertPword = ', ' + CASE WHEN CertPword IS NOT NULL THEN master.dbo.fn_varbintohexstr(CertPword) ELSE 'NULL' END,
            @BackupCert = ', ' + CASE WHEN BackupCert IS NOT NULL THEN CAST(BackupCert AS VARCHAR(10)) ELSE 'NULL' END
        FROM
            #BackupCertSettSync
        WHERE
            ID = @i

        INSERT  Minion.SyncCmds
                (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd,
                 Pushed, Attempts)
        SELECT
            @ExecutionDateTime, 'Backup', 'In queue', 'BackupCert',
            'INSERT',
            ('INSERT Minion.BackupCert (CertType, CertPword, BackupCert) SELECT '
             + @CertType + @CertPword + @BackupCert), 0,
            0;

        SET @i = @i + 1
 END

DROP TABLE #BackupCertSettSync;
-------------------------------------------------------------------------
--------------------END BackupCert---------------------------------------
-------------------------------------------------------------------------



-------------------------------------------------------------------------
--------------------BEGIN BackupSettingsServer---------------------------
-------------------------------------------------------------------------
---1st, truncate the existing data on the foreign server.  There's no need to try to figure out what's changed.
---The easiest is to just dump all the data and reload it.  There won't be thousands of rows in most cases so this won't be an issue.
INSERT  Minion.SyncCmds
        (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd, Pushed,
         Attempts)
SELECT
    @ExecutionDateTime, 'Backup', 'In queue', 'BackupSettingsServer',
    'TRUNCATE', 'TRUNCATE TABLE Minion.BackupSettingsServer;', 0, 0;

SET @i = 1;
SET @CT = (
           SELECT COUNT (*) FROM Minion.BackupSettingsServer
          )

SELECT
    ID = IDENTITY( INT,1,1), BackupType, Day, ReadOnly, BeginTime, EndTime, MaxForTimeframe, FrequencyMins, CurrentNumBackups, Include, Exclude, SyncSettings, SyncLogs, BatchPreCode, BatchPostCode, Debug, FailJobOnError, FailJobOnWarning, IsActive, Comment
INTO
    #BackupSettingsServerSettSync
FROM
    Minion.BackupSettingsServer
	ORDER BY ID ASC
WHILE @i <= @CT
    BEGIN

        SELECT
            @BackupType = CASE WHEN BackupType IS NOT NULL THEN '''' + BackupType + '''' ELSE 'NULL' END,
            @Day = ', ' + CASE WHEN [DAY] IS NOT NULL THEN '''' + [DAY] + '''' ELSE 'NULL' END,
            @ReadOnly = ', ' + CASE WHEN ReadOnly IS NOT NULL THEN CAST(ReadOnly AS VARCHAR(10)) ELSE 'NULL' END,
			@BeginTime = ', ' + CASE WHEN BeginTime IS NOT NULL THEN '''' + BeginTime + '''' ELSE 'NULL' END ,
			@EndTime = ', ' + CASE WHEN EndTime IS NOT NULL THEN '''' + EndTime + '''' ELSE 'NULL' END ,
            @MaxForTimeframe = ', ' + CASE WHEN MaxForTimeframe IS NOT NULL THEN CAST(MaxForTimeframe AS VARCHAR(10)) ELSE 'NULL' END,
			@FrequencyMins = ', ' + CASE WHEN FrequencyMins IS NOT NULL THEN CAST(FrequencyMins AS VARCHAR(10)) ELSE 'NULL' END,
            @CurrentNumBackups = ', ' + CASE WHEN CurrentNumBackups IS NOT NULL THEN CAST(CurrentNumBackups AS VARCHAR(10)) ELSE 'NULL' END,
            @Include = ', ' + CASE WHEN Include IS NOT NULL THEN '''' + Include + '''' ELSE 'NULL' END,
            @Exclude = ', ' + CASE WHEN Exclude IS NOT NULL THEN '''' + Exclude + '''' ELSE 'NULL' END,
            @SyncSettings = ', ' + CASE WHEN SyncSettings IS NOT NULL THEN CAST(SyncSettings AS VARCHAR(10)) ELSE 'NULL' END,
            @SyncLogs = ', ' + CASE WHEN SyncLogs IS NOT NULL THEN CAST(SyncLogs AS VARCHAR(10)) ELSE 'NULL' END,
            @BatchPreCode = ', ' + CASE WHEN BatchPreCode IS NOT NULL THEN '''' + BatchPreCode + '''' ELSE 'NULL' END,
            @BatchPostCode = ', ' + CASE WHEN BatchPostCode IS NOT NULL THEN '''' + BatchPostCode + '''' ELSE 'NULL' END,            
			@Debug = ', ' + CASE WHEN Debug IS NOT NULL THEN CAST(Debug AS VARCHAR(10)) ELSE 'NULL' END,
			@FailJobOnError = ', ' + CASE WHEN FailJobOnError IS NOT NULL THEN CAST(FailJobOnError AS VARCHAR(10)) ELSE 'NULL' END,
			@FailJobOnWarning = ', ' + CASE WHEN FailJobOnWarning IS NOT NULL THEN CAST(FailJobOnWarning AS VARCHAR(10)) ELSE 'NULL' END,
            @IsActive = ', ' + CASE WHEN IsActive IS NOT NULL THEN CAST(IsActive AS VARCHAR(10)) ELSE 'NULL' END,
            @Comment = ', ' + CASE WHEN Comment IS NOT NULL THEN '''' + Comment + '''' ELSE 'NULL' END
        FROM
            #BackupSettingsServerSettSync
        WHERE
            ID = @i

        INSERT  Minion.SyncCmds
                (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd,
                 Pushed, Attempts)
        SELECT
            @ExecutionDateTime, 'Backup', 'In queue', 'BackupSettingsServer',
            'INSERT',
            ('INSERT Minion.BackupSettingsServer (BackupType, [Day], [ReadOnly], BeginTime, EndTime, MaxForTimeframe, FrequencyMins, CurrentNumBackups, [Include], Exclude, SyncSettings, SyncLogs, BatchPreCode, BatchPostCode, Debug, FailJobOnError, FailJobOnWarning, IsActive, Comment) SELECT '
             + @BackupType + @Day + @ReadOnly + @BeginTime + @EndTime + @MaxForTimeframe + @FrequencyMins + @CurrentNumBackups
			 + @Include + @Exclude + @SyncSettings + @SyncLogs + @BatchPreCode + @BatchPostCode + @Debug + @FailJobOnError + @FailJobOnWarning + @IsActive + @Comment), 0,
            0;

        SET @i = @i + 1
 END

DROP TABLE #BackupSettingsServerSettSync;
-------------------------------------------------------------------------
--------------------END BackupSettingsServer-----------------------------
-------------------------------------------------------------------------




-------------------------------------------------------------------------
--------------------BEGIN BackupSettings---------------------------------
-------------------------------------------------------------------------


---1st, truncate the existing data on the foreign server.  There's no need to try to figure out what's changed.
---The easiest is to just dump all the data and reload it.  There won't be thousands of rows in most cases so this won't be an issue.
INSERT  Minion.SyncCmds
        (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd, Pushed,
         Attempts)
SELECT
    @ExecutionDateTime, 'Backup', 'In queue', 'BackupSettings', 'TRUNCATE',
    'TRUNCATE TABLE Minion.BackupSettings;', 0, 0;

SET @i = 1;
SET @CT = (
           SELECT COUNT (*) FROM Minion.BackupSettings
          )

SELECT
    ID = IDENTITY( INT,1,1), DBName, Port, BackupType, Exclude, GroupOrder,
    GroupDBOrder, Mirror, DelFileBefore, DelFileBeforeAgree,
    LogLoc, HistRetDays, MinionTriggerPath, DBPreCode, DBPostCode,
    PushToMinion, DynamicTuning, Verify, ShrinkLogOnLogBackup,
    ShrinkLogThresholdInMB, ShrinkLogSizeInMB, MinSizeForDiffInGB,
    DiffReplaceAction, LogProgress, FileAction, FileActionTime, Encrypt,
    Name, ExpireDateInHrs, RetainDays, Descr, Checksum, Init, Format, CopyOnly,
    Skip, BackupErrorMgmt, MediaName, MediaDescription, IsActive
INTO
    #BackupSettingsSettSync
FROM
    Minion.BackupSettings
ORDER BY ID ASC

WHILE @i <= @CT
    BEGIN
        SELECT
            @DBName = '''' + DBName + '''',
            @Port = ', ' + ISNULL(CAST(Port AS VARCHAR(25)), 'NULL'),
            @BackupType = ', ' + CASE WHEN BackupType IS NOT NULL THEN '''' + BackupType + '''' ELSE 'NULL' END,
            @Exclude = ', '  + CASE WHEN Exclude IS NOT NULL THEN CAST(Exclude AS VARCHAR(25)) ELSE 'NULL' END,
            @GroupOrder = ', ' + CASE WHEN GroupOrder IS NOT NULL THEN CAST(GroupOrder AS VARCHAR(25)) ELSE 'NULL' END,
            @GroupDBOrder = ', ' + CASE WHEN GroupDBOrder IS NOT NULL THEN CAST(GroupDBOrder AS VARCHAR(25)) ELSE 'NULL' END,
            @Mirror = ', ' + CASE WHEN Mirror IS NOT NULL THEN CAST(Mirror AS VARCHAR(25)) ELSE 'NULL' END,
            @DelFileBefore = ', ' + CASE WHEN DelFileBefore IS NOT NULL THEN CAST(DelFileBefore AS VARCHAR(25)) ELSE 'NULL' END,
            @DelFileBeforeAgree = ', ' + CASE WHEN DelFileBeforeAgree IS NOT NULL THEN CAST(DelFileBeforeAgree AS VARCHAR(4)) ELSE 'NULL' END,
            @LogLoc = ', ' + CASE WHEN LogLoc IS NOT NULL THEN '''' + LogLoc + '''' ELSE 'NULL' END,
            @HistRetDays = ', ' + CASE WHEN HistRetDays IS NOT NULL THEN CAST(HistRetDays AS VARCHAR(25)) ELSE 'NULL' END,
            @MinionTriggerPath = ', ' + CASE WHEN MinionTriggerPath IS NOT NULL THEN '''' + MinionTriggerPath + '''' ELSE 'NULL' END,
            @DBPreCode = ', ' + CASE WHEN DBPreCode IS NOT NULL THEN '''' + DBPreCode + '''' ELSE 'NULL' END,
            @DBPostCode = ', ' + CASE WHEN DBPostCode IS NOT NULL THEN '''' + DBPostCode + '''' ELSE 'NULL' END,
            @PushToMinion = ', ' + CASE WHEN PushToMinion IS NOT NULL THEN CAST(PushToMinion AS VARCHAR(25)) ELSE 'NULL' END,
            @DynamicTuning = ', ' + CASE WHEN DynamicTuning IS NOT NULL THEN CAST(DynamicTuning AS VARCHAR(25)) ELSE 'NULL' END,
            @Verify = ', ' + CASE WHEN Verify IS NOT NULL THEN '''' + CAST(Verify AS VARCHAR(25)) + '''' ELSE 'NULL' END,
            @ShrinkLogOnLogBackup = ', ' + CASE WHEN ShrinkLogOnLogBackup IS NOT NULL THEN CAST(ShrinkLogOnLogBackup AS VARCHAR(25)) ELSE 'NULL' END,
            @ShrinkLogThresholdInMB = ', ' + CASE WHEN ShrinkLogThresholdInMB IS NOT NULL THEN CAST(ShrinkLogThresholdInMB AS VARCHAR(25)) ELSE 'NULL' END,
            @ShrinkLogSizeInMB = ', ' + CASE WHEN ShrinkLogSizeInMB IS NOT NULL THEN CAST(ShrinkLogSizeInMB AS VARCHAR(25)) ELSE 'NULL' END,
            @MinSizeForDiffInGB = ', ' + CASE WHEN MinSizeForDiffInGB IS NOT NULL THEN CAST(MinSizeForDiffInGB AS VARCHAR(25)) ELSE 'NULL' END,
            @DiffReplaceAction = ', ' + CASE WHEN DiffReplaceAction IS NOT NULL THEN '''' + DiffReplaceAction + '''' ELSE 'NULL' END,
            @LogProgress = ', ' + CASE WHEN LogProgress IS NOT NULL THEN CAST(LogProgress AS VARCHAR(25)) ELSE 'NULL' END,
            @FileAction = ', ' + CASE WHEN FileAction IS NOT NULL THEN '''' + FileAction + '''' ELSE 'NULL' END,
            @FileActionTime = ', ' + CASE WHEN FileActionTime IS NOT NULL THEN '''' + CAST(FileActionTime AS VARCHAR(25)) + '''' ELSE 'NULL' END,
            @Encrypt = ', ' + CASE WHEN Encrypt IS NOT NULL THEN CAST(Encrypt AS VARCHAR(25)) ELSE 'NULL' END,
            @Name = ', ' + CASE WHEN Name IS NOT NULL THEN '''' + Name + '''' ELSE 'NULL' END,
            @ExpireDateInHrs = ', ' + CASE WHEN ExpireDateInHrs IS NOT NULL THEN CAST(ExpireDateInHrs AS VARCHAR(25)) ELSE 'NULL' END,
            @RetainDays = ', ' + CASE WHEN RetainDays IS NOT NULL THEN CAST(RetainDays AS VARCHAR(25)) ELSE 'NULL' END,
            @Descr = ', ' + CASE WHEN Descr IS NOT NULL THEN '''' + Descr + '''' ELSE 'NULL' END,
            @Checksum = ', ' + CASE WHEN Checksum IS NOT NULL THEN CAST(Checksum AS VARCHAR(25)) ELSE 'NULL' END,
            @Init = ', ' + CASE WHEN Init IS NOT NULL THEN CAST(Init AS VARCHAR(25)) ELSE 'NULL' END,
            @Format = ', ' + CASE WHEN Format IS NOT NULL THEN CAST(Format AS VARCHAR(25)) ELSE 'NULL' END,
            @CopyOnly = ', ' + CASE WHEN CopyOnly IS NOT NULL THEN CAST(CopyOnly AS VARCHAR(25)) ELSE 'NULL' END,
            @Skip = ', ' + CASE WHEN Skip IS NOT NULL THEN CAST(Skip AS VARCHAR(25)) ELSE 'NULL' END,
            @BackupErrorMgmt = ', ' + CASE WHEN BackupErrorMgmt IS NOT NULL THEN '''' + BackupErrorMgmt + '''' ELSE 'NULL' END,
            @MediaName = ', ' + CASE WHEN MediaName IS NOT NULL THEN '''' + MediaName + '''' ELSE 'NULL' END,
            @MediaDescription = ', ' + CASE WHEN MediaDescription IS NOT NULL THEN '''' + MediaDescription + '''' ELSE 'NULL' END,
            @IsActive = ', ' + CASE WHEN IsActive IS NOT NULL THEN CAST(IsActive AS VARCHAR(25)) ELSE 'NULL' END
        FROM
            #BackupSettingsSettSync
        WHERE
            ID = @i

        INSERT  Minion.SyncCmds
                (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd,
                 Pushed, Attempts)
        SELECT
            @ExecutionDateTime, 'Backup', 'In queue', 'BackupSettings',
            'INSERT',
            ('INSERT Minion.BackupSettings (DBName, Port, BackupType, Exclude, GroupOrder, GroupDBOrder, Mirror, DelFileBefore, DelFileBeforeAgree, LogLoc, HistRetDays, MinionTriggerPath, DBPreCode, DBPostCode, PushToMinion, DynamicTuning, Verify, ShrinkLogOnLogBackup, ShrinkLogThresholdInMB, ShrinkLogSizeInMB, MinSizeForDiffInGB, DiffReplaceAction, LogProgress, FileAction, FileActionTime, Encrypt, Name, ExpireDateInHrs, RetainDays, Descr, Checksum, Init, Format, CopyOnly, Skip, BackupErrorMgmt, MediaName, MediaDescription, IsActive) SELECT '
             + @DBName + @Port + @BackupType + @Exclude + @GroupOrder
             + @GroupDBOrder + @Mirror + @DelFileBefore
             + @DelFileBeforeAgree + @LogLoc + @HistRetDays
             + @MinionTriggerPath + @DBPreCode + @DBPostCode + @PushToMinion
             + @DynamicTuning + @Verify + @ShrinkLogOnLogBackup
             + @ShrinkLogThresholdInMB + @ShrinkLogSizeInMB
             + @MinSizeForDiffInGB + @DiffReplaceAction + @LogProgress
             + @FileAction + @FileActionTime --+ @FileActionMethod
             --+ @FileActionMethodFlags 
			 + @Encrypt
             + @Name + @ExpireDateInHrs + @RetainDays + @Descr + @Checksum
             + @Init + @Format + @CopyOnly + @Skip + @BackupErrorMgmt
             + @MediaName + @MediaDescription + @IsActive), 0, 0;

        SET @i = @i + 1 END

DROP TABLE #BackupSettingsSettSync;
-------------------------------------------------------------------------
--------------------END BackupSettings-----------------------------------
-------------------------------------------------------------------------


-------------------------------------------------------------------------
--------------------BEGIN BackupSettingsPath-----------------------------
-------------------------------------------------------------------------
---1st, truncate the existing data on the foreign server.  There's no need to try to figure out what's changed.
---The easiest is to just dump all the data and reload it.  There won't be thousands of rows in most cases so this won't be an issue.
INSERT  Minion.SyncCmds
        (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd, Pushed,
         Attempts)
SELECT
    @ExecutionDateTime, 'Backup', 'In queue', 'BackupSettingsPath', 'TRUNCATE',
    'TRUNCATE TABLE Minion.BackupSettingsPath;', 0, 0;

SET @i = 1;
SET @CT = (
           SELECT COUNT (*) FROM Minion.BackupSettingsPath
          )

SELECT
    ID = IDENTITY( INT,1,1), DBName, IsMirror, BackupType, BackupLocType,
    BackupDrive, BackupPath, [FileName], FileExtension, ServerLabel, RetHrs, FileActionMethod, FileActionMethodFlags, PathOrder, IsActive,
    AzureCredential, Comment
INTO
    #BackupSettingsPathSettSync
FROM
    Minion.BackupSettingsPath ORDER BY ID ASC

WHILE @i <= @CT
    BEGIN
        DECLARE
            @IsMirror VARCHAR(6),
            @BackupLocType VARCHAR(20),
            @BackupDrive VARCHAR(100),
            @BackupPath VARCHAR(1000),
			@FileName VARCHAR(500),
			@FileExtension VARCHAR(50),
            @ServerLabel VARCHAR(150),
            @RetHrs VARCHAR(25),
            @PathOrder VARCHAR(25),
            @AzureCredential VARCHAR(100);


        SELECT
            @DBName = '''' + DBName + '''',
            @IsMirror = ', ' + ISNULL(CAST(IsMirror AS VARCHAR(25)), 'NULL'),
            @BackupType = ', ' + CASE WHEN BackupType IS NOT NULL THEN '''' + BackupType + '''' ELSE 'NULL' END,
            @BackupLocType = ', ' + CASE WHEN BackupLocType IS NOT NULL THEN '''' + BackupLocType + '''' ELSE 'NULL' END,
            @BackupDrive = ', ' + CASE WHEN BackupDrive IS NOT NULL THEN '''' + BackupDrive + '''' ELSE 'NULL' END,
            @BackupPath = ', ' + CASE WHEN BackupPath IS NOT NULL THEN '''' + BackupPath + '''' ELSE 'NULL' END,
			@FileName = ', ' + CASE WHEN [FileName] IS NOT NULL THEN '''' + [FileName] + '''' ELSE 'NULL' END,
			@FileExtension = ', ' + CASE WHEN FileExtension IS NOT NULL THEN '''' + FileExtension + '''' ELSE 'NULL' END,
            @ServerLabel = ', ' + CASE WHEN ServerLabel IS NOT NULL THEN '''' + ServerLabel + '''' ELSE 'NULL' END,
            @RetHrs = ', ' + CASE WHEN RetHrs IS NOT NULL THEN CAST(RetHrs AS VARCHAR(6)) ELSE 'NULL' END,
            @FileActionMethod = ', ' + CASE WHEN FileActionMethod IS NOT NULL THEN '''' + FileActionMethod + '''' ELSE 'NULL' END,
            @FileActionMethodFlags = ', ' + CASE WHEN FileActionMethodFlags IS NOT NULL THEN '''' + FileActionMethodFlags + '''' ELSE 'NULL' END,
            @PathOrder = ', ' + CASE WHEN PathOrder IS NOT NULL THEN CAST(PathOrder AS VARCHAR(6)) ELSE 'NULL' END,
            @IsActive = ', ' + CASE WHEN IsActive IS NOT NULL THEN CAST(IsActive AS VARCHAR(6)) ELSE 'NULL' END,
            @AzureCredential = ', ' + CASE WHEN AzureCredential IS NOT NULL THEN '''' + AzureCredential + '''' ELSE 'NULL' END,
            @Comment = ', ' + CASE WHEN Comment IS NOT NULL THEN '''' + Comment + '''' ELSE 'NULL' END
        FROM
            #BackupSettingsPathSettSync
        WHERE
            ID = @i

        INSERT  Minion.SyncCmds
                (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd,
                 Pushed, Attempts)
        SELECT
            @ExecutionDateTime, 'Backup', 'In queue', 'BackupSettingsPath',
            'INSERT',
            ('INSERT Minion.BackupSettingsPath (DBName, isMirror, BackupType, BackupLocType, BackupDrive, BackupPath, FileName, FileExtension, ServerLabel, RetHrs, FileActionMethod, FileActionMethodFlags, PathOrder, IsActive, AzureCredential, Comment) SELECT '
             + @DBName + @IsMirror + @BackupType + @BackupLocType
             + @BackupDrive + @BackupPath + @FileName + @FileExtension + @ServerLabel + @RetHrs + @FileActionMethod + @FileActionMethodFlags
             + @PathOrder + @IsActive + @AzureCredential + @Comment), 0, 0;

        SET @i = @i + 1
 END

DROP TABLE #BackupSettingsPathSettSync;
-------------------------------------------------------------------------
--------------------END BackupSettingsPath-------------------------------
-------------------------------------------------------------------------



-------------------------------------------------------------------------
--------------------BEGIN BackupRestoreSettingsPath----------------------
-------------------------------------------------------------------------
---1st, truncate the existing data on the foreign server.  There's no need to try to figure out what's changed.
---The easiest is to just dump all the data and reload it.  There won't be thousands of rows in most cases so this won't be an issue.
INSERT  Minion.SyncCmds
        (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd, Pushed,
         Attempts)
SELECT
    @ExecutionDateTime, 'Backup', 'In queue', 'BackupRestoreSettingsPath', 'TRUNCATE',
    'TRUNCATE TABLE Minion.BackupRestoreSettingsPath;', 0, 0;

SET @i = 1;
SET @CT = (
           SELECT COUNT (*) FROM Minion.BackupRestoreSettingsPath
          )

SELECT
    ID = IDENTITY( INT,1,1), DBName, ServerName, RestoreType, FileType, TypeName,
    RestoreDrive, RestorePath, [RestoreFileName], RestoreFileExtension, BackupLocation, RestoreDBName, ServerLabel, PathOrder, IsActive,
    Comment
INTO
    #BackupRestoreSettingsPathSettSync
FROM
    Minion.BackupRestoreSettingsPath ORDER BY ID ASC

WHILE @i <= @CT
    BEGIN
        DECLARE
			@RestoreDBName NVARCHAR(400),
			@RestoreType VARCHAR(15),
            @BackupLocation VARCHAR(8000),
            @RestoreDrive VARCHAR(100),
			@FileType VARCHAR(10),
			@TypeName VARCHAR(400),
            @RestorePath VARCHAR(1000),
			@RestoreFileName VARCHAR(500),
			@RestoreFileExtension VARCHAR(50);


        SELECT
            @DBName = '''' + DBName + '''',
			@ServerName = '''' + ServerName + '''',
            @RestoreType = ', ' + CASE WHEN RestoreType IS NOT NULL THEN '''' + RestoreType + '''' ELSE 'NULL' END,
			@FileType = ', ' + CASE WHEN FileType IS NOT NULL THEN '''' + FileType + '''' ELSE 'NULL' END,
			@TypeName = ', ' + CASE WHEN TypeName IS NOT NULL THEN '''' + TypeName + '''' ELSE 'NULL' END,
            @RestoreDrive = ', ' + CASE WHEN RestoreDrive IS NOT NULL THEN '''' + RestoreDrive + '''' ELSE 'NULL' END,
            @RestorePath = ', ' + CASE WHEN RestorePath IS NOT NULL THEN '''' + RestorePath + '''' ELSE 'NULL' END,
			@RestoreFileName = ', ' + CASE WHEN RestoreFileName IS NOT NULL THEN '''' + RestoreFileName + '''' ELSE 'NULL' END,
			@RestoreFileExtension = ', ' + CASE WHEN RestoreFileExtension IS NOT NULL THEN '''' + RestoreFileExtension + '''' ELSE 'NULL' END,
            @BackupLocation = ', ' + CASE WHEN BackupLocation IS NOT NULL THEN '''' + BackupLocation + '''' ELSE 'NULL' END,
			@RestoreDBName = ', ' + CASE WHEN RestoreDBName IS NOT NULL THEN '''' + RestoreDBName + '''' ELSE 'NULL' END,
			@ServerLabel = ', ' + CASE WHEN ServerLabel IS NOT NULL THEN '''' + ServerLabel + '''' ELSE 'NULL' END,
            @PathOrder = ', ' + CASE WHEN PathOrder IS NOT NULL THEN CAST(PathOrder AS VARCHAR(6)) ELSE 'NULL' END,
            @IsActive = ', ' + CASE WHEN IsActive IS NOT NULL THEN CAST(IsActive AS VARCHAR(6)) ELSE 'NULL' END,
            @Comment = ', ' + CASE WHEN Comment IS NOT NULL THEN '''' + Comment + '''' ELSE 'NULL' END
        FROM
            #BackupRestoreSettingsPathSettSync
        WHERE
            ID = @i

        INSERT  Minion.SyncCmds
                (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd,
                 Pushed, Attempts)
        SELECT
            @ExecutionDateTime, 'Backup', 'In queue', 'BackupRestoreSettingsPath',
            'INSERT',
            ('INSERT Minion.BackupRestoreSettingsPath (DBName, ServerName, RestoreType, FileType, TypeName, RestoreDrive, RestorePath, RestoreFileName, RestoreFileExtension, BackupLocation, RestoreDBName, ServerLabel, PathOrder, IsActive, Comment) SELECT '
             + @DBName + @ServerName + @RestoreType + @FileType + @TypeName
             + @RestoreDrive + @RestorePath + @RestoreFileName + @RestoreFileExtension 
			 + @BackupLocation + @RestoreDBName + @ServerLabel 
             + @PathOrder + @IsActive + @Comment), 0, 0;

        SET @i = @i + 1
 END

DROP TABLE #BackupRestoreSettingsPathSettSync;
-------------------------------------------------------------------------
--------------------END BackupRestoreSettingsPath------------------------
-------------------------------------------------------------------------



-------------------------------------------------------------------------
--------------------BEGIN BackupTuningThresholds-------------------------
-------------------------------------------------------------------------
---1st, truncate the existing data on the foreign server.  There's no need to try to figure out what's changed.
---The easiest is to just dump all the data and reload it.  There won't be thousands of rows in most cases so this won't be an issue.
INSERT  Minion.SyncCmds
        (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd, Pushed,
         Attempts)
SELECT
    @ExecutionDateTime, 'Backup', 'In queue', 'BackupTuningThresholds',
    'TRUNCATE', 'TRUNCATE TABLE Minion.BackupTuningThresholds;', 0, 0;

SET @i = 1;
SET @CT = (
           SELECT COUNT (*) FROM Minion.BackupTuningThresholds
          )

SELECT
    ID = IDENTITY( INT,1,1), DBName, BackupType, SpaceType, ThresholdMeasure, ThresholdValue, 
	NumberOfFiles, Buffercount, MaxTransferSize, Compression, BlockSize, BeginTime, EndTime, [DayOfWeek], IsActive, Comment
INTO
    #BackupTuningThresholdsSettSync
FROM
    Minion.BackupTuningThresholds
	 ORDER BY ID ASC



WHILE @i <= @CT
    BEGIN
        SELECT
            @DBName = CASE WHEN DBName IS NOT NULL THEN '''' + DBName + '''' ELSE 'NULL' END,
            @BackupType = ', ' + CASE WHEN BackupType IS NOT NULL THEN '''' + BackupType + '''' ELSE 'NULL' END,
            @SpaceType = ', ' + CASE WHEN SpaceType IS NOT NULL THEN '''' + SpaceType + '''' ELSE 'NULL' END,
            @ThresholdMeasure = ', ' + CASE WHEN ThresholdMeasure IS NOT NULL THEN '''' + ThresholdMeasure + '''' ELSE 'NULL' END,
            @ThresholdValue = ', ' + ISNULL(CAST(ThresholdValue AS VARCHAR(25)), 'NULL'),
            @NumberOfFiles = ', ' + ISNULL(CAST(NumberOfFiles AS VARCHAR(25)), 'NULL'),
            @BufferCount = ', ' + ISNULL(CAST(Buffercount AS VARCHAR(25)), 'NULL'),
            @Maxtransfersize = ', ' + ISNULL(CAST(MaxTransferSize AS VARCHAR(25)), 'NULL'),
            @Compression = ', ' + ISNULL(CAST(Compression AS VARCHAR(25)), 'NULL'),
            @BlockSize = ', ' + ISNULL(CAST(BlockSize AS VARCHAR(25)), 'NULL'),
			@BeginTime = ', ' + CASE WHEN BeginTime IS NOT NULL THEN '''' + BeginTime + '''' ELSE 'NULL' END,
			@EndTime = ', ' + CASE WHEN EndTime IS NOT NULL THEN '''' + EndTime + '''' ELSE 'NULL' END,
			@DayOfWeek = ', ' + CASE WHEN [DayOfWeek] IS NOT NULL THEN '''' + [DayOfWeek] + '''' ELSE 'NULL' END,
            @IsActive = ', ' + ISNULL(CAST(IsActive AS VARCHAR(25)), 'NULL'),
            @Comment = ', ' + CASE WHEN Comment IS NOT NULL THEN '''' + Comment + '''' ELSE 'NULL' END
        FROM
            #BackupTuningThresholdsSettSync --', ' +  
        WHERE
            ID = @i

        INSERT  Minion.SyncCmds
                (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd,
                 Pushed, Attempts)
        SELECT
            @ExecutionDateTime, 'Backup', 'In queue', 'BackupTuningThresholds',
            'INSERT',
            ('INSERT Minion.BackupTuningThresholds (DBName, BackupType, SpaceType, ThresholdMeasure, ThresholdValue, NumberOfFiles, Buffercount, MaxTransferSize, Compression, BlockSize, BeginTime, EndTime, [DayOfWeek], IsActive, Comment) SELECT '
             + @DBName + @BackupType + @SpaceType + @ThresholdMeasure
             + @ThresholdValue + @NumberOfFiles + @BufferCount
             + @Maxtransfersize + @Compression + @BlockSize + @BeginTime + @EndTime + @DayOfWeek + @IsActive
             + @Comment), 0, 0;

        SET @i = @i + 1
 END

DROP TABLE #BackupTuningThresholdsSettSync;
-------------------------------------------------------------------------
--------------------END BackupTuningThresholds---------------------------
-------------------------------------------------------------------------



-------------------------------------------------------------------------
--------------------BEGIN BackupRestoreTuningThresholds------------------
-------------------------------------------------------------------------
---1st, truncate the existing data on the foreign server.  There's no need to try to figure out what's changed.
---The easiest is to just dump all the data and reload it.  There won't be thousands of rows in most cases so this won't be an issue.
INSERT  Minion.SyncCmds
        (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd, Pushed,
         Attempts)
SELECT
    @ExecutionDateTime, 'Backup', 'In queue', 'BackupRestoreTuningThresholds',
    'TRUNCATE', 'TRUNCATE TABLE Minion.BackupRestoreTuningThresholds;', 0, 0;

DECLARE 
		@Replace VARCHAR(6),
		@WithFlags VARCHAR(1000);

SET @i = 1;
SET @CT = (
           SELECT COUNT (*) FROM Minion.BackupRestoreTuningThresholds
          )

SELECT
    ID = IDENTITY( INT,1,1), ServerName, DBName, RestoreType, SpaceType, ThresholdMeasure, ThresholdValue, 
	Buffercount, MaxTransferSize, BlockSize, Replace, WithFlags, BeginTime, EndTime, [DayOfWeek], IsActive, Comment
INTO
    #BackupRestoreTuningThresholdsSettSync
FROM
    Minion.BackupRestoreTuningThresholds
	 ORDER BY ID ASC



WHILE @i <= @CT
    BEGIN
        SELECT
			@ServerName = CASE WHEN ServerName IS NOT NULL THEN '''' + ServerName + '''' ELSE 'NULL' END,
            @DBName = CASE WHEN DBName IS NOT NULL THEN '''' + DBName + '''' ELSE 'NULL' END,
            @RestoreType = ', ' + CASE WHEN RestoreType IS NOT NULL THEN '''' + RestoreType + '''' ELSE 'NULL' END,
            @SpaceType = ', ' + CASE WHEN SpaceType IS NOT NULL THEN '''' + SpaceType + '''' ELSE 'NULL' END,
            @ThresholdMeasure = ', ' + CASE WHEN ThresholdMeasure IS NOT NULL THEN '''' + ThresholdMeasure + '''' ELSE 'NULL' END,
            @ThresholdValue = ', ' + ISNULL(CAST(ThresholdValue AS VARCHAR(25)), 'NULL'),
            @BufferCount = ', ' + ISNULL(CAST(Buffercount AS VARCHAR(25)), 'NULL'),
            @Maxtransfersize = ', ' + ISNULL(CAST(MaxTransferSize AS VARCHAR(25)), 'NULL'),
            @BlockSize = ', ' + ISNULL(CAST(BlockSize AS VARCHAR(25)), 'NULL'),
			@Replace = ', ' + ISNULL(CAST([Replace] AS VARCHAR(25)), 'NULL'),
			@BeginTime = ', ' + CASE WHEN BeginTime IS NOT NULL THEN '''' + BeginTime + '''' ELSE 'NULL' END,
			@EndTime = ', ' + CASE WHEN EndTime IS NOT NULL THEN '''' + EndTime + '''' ELSE 'NULL' END,
			@DayOfWeek = ', ' + CASE WHEN [DayOfWeek] IS NOT NULL THEN '''' + [DayOfWeek] + '''' ELSE 'NULL' END,
            @IsActive = ', ' + ISNULL(CAST(IsActive AS VARCHAR(25)), 'NULL'),
            @Comment = ', ' + CASE WHEN Comment IS NOT NULL THEN '''' + Comment + '''' ELSE 'NULL' END
        FROM
            #BackupRestoreTuningThresholdsSettSync --', ' +  
        WHERE
            ID = @i

        INSERT  Minion.SyncCmds
                (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd,
                 Pushed, Attempts)
        SELECT
            @ExecutionDateTime, 'Backup', 'In queue', 'BackupRestoreTuningThresholds',
            'INSERT',
            ('INSERT Minion.BackupRestoreTuningThresholds (DBName, BackupType, SpaceType, ThresholdMeasure, ThresholdValue, NumberOfFiles, Buffercount, MaxTransferSize, Compression, BlockSize, BeginTime, EndTime, [DayOfWeek], IsActive, Comment) SELECT '
             + @ServerName + @DBName + @RestoreType + @SpaceType + @ThresholdMeasure
             + @ThresholdValue + @BufferCount
             + @Maxtransfersize + @BlockSize + @Replace + @WithFlags + @BeginTime + @EndTime + @DayOfWeek + @IsActive
             + @Comment), 0, 0;

        SET @i = @i + 1
 END

DROP TABLE #BackupRestoreTuningThresholdsSettSync;
-------------------------------------------------------------------------
--------------------END BackupRestoreTuningThresholds--------------------
-------------------------------------------------------------------------


-------------------------------------------------------------------------
--------------------BEGIN DBMaintRegexLookup-------------------------------
-------------------------------------------------------------------------
---1st, truncate the existing data on the foreign server.  There's no need to try to figure out what's changed.
---The easiest is to just dump all the data and reload it.  There won't be thousands of rows in most cases so this won't be an issue.
INSERT  Minion.SyncCmds
        (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd, Pushed,
         Attempts)
SELECT
    @ExecutionDateTime, 'Backup', 'In queue', 'DBMaintRegexLookup', 'TRUNCATE',
    'TRUNCATE TABLE Minion.DBMaintRegexLookup;', 0, 0;


SET @i = 1;
SET @CT = (
           SELECT COUNT (*) FROM Minion.DBMaintRegexLookup
          )

SELECT
    ID = IDENTITY( INT,1,1), Action, MaintType, Regex
INTO
    #DBMaintRegexLookupSettSync
FROM
    Minion.DBMaintRegexLookup
	 ORDER BY ID ASC

WHILE @i <= @CT
    BEGIN
        SELECT
            @Action = CASE WHEN Action IS NOT NULL THEN '''' + Action + '''' ELSE 'NULL' END,
            @MaintType = ', ' + CASE WHEN MaintType IS NOT NULL THEN '''' + MaintType + '''' ELSE 'NULL' END,
            @Regex = ', ' + CASE WHEN Regex IS NOT NULL THEN '''' + Regex + '''' ELSE 'NULL' END
        FROM
            #DBMaintRegexLookupSettSync
        WHERE
            ID = @i

        INSERT  Minion.SyncCmds
                (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd,
                 Pushed, Attempts)
        SELECT
            @ExecutionDateTime, 'Backup', 'In queue', 'DBMaintRegexLookup',
            'INSERT',
            ('INSERT Minion.DBMaintRegexLookup (Action, MaintType, Regex) SELECT '
             + @Action + @MaintType + @Regex), 0, 0;

        SET @i = @i + 1
 END

DROP TABLE #DBMaintRegexLookupSettSync;
-------------------------------------------------------------------------
--------------------END DBMaintRegexLookup-------------------------------
-------------------------------------------------------------------------



-------------------------------------------------------------------------
--------------------BEGIN BackupEncryption-------------------------------
-------------------------------------------------------------------------
---1st, truncate the existing data on the foreign server.  There's no need to try to figure out what's changed.
---The easiest is to just dump all the data and reload it.  There won't be thousands of rows in most cases so this won't be an issue.
INSERT  Minion.SyncCmds
        (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd, Pushed,
         Attempts)
SELECT
    @ExecutionDateTime, 'Backup', 'In queue', 'BackupEncryption', 'TRUNCATE',
    'TRUNCATE TABLE Minion.BackupEncryption;', 0, 0;



SET @i = 1;
SET @CT = (
           SELECT COUNT (*) FROM Minion.BackupEncryption
          )

SELECT
    ID = IDENTITY( INT,1,1), DBName, CertType, CertName, EncrAlgorithm,
    ThumbPrint, IsActive
INTO
    #BackupEncryptionSettSync
FROM
    Minion.BackupEncryption
	 ORDER BY ID ASC

WHILE @i <= @CT
    BEGIN
        SELECT
            @DBName = CASE WHEN DBName IS NOT NULL THEN '''' + DBName + '''' ELSE 'NULL' END,
            @CertType = ', ' + CASE WHEN CertType IS NOT NULL THEN '''' + CertType + '''' ELSE 'NULL' END,
            @CertName = ', ' + CASE WHEN CertName IS NOT NULL THEN '''' + CertName + '''' ELSE 'NULL' END,
            @EncrAlgorithm = ', ' + CASE WHEN EncrAlgorithm IS NOT NULL THEN '''' + EncrAlgorithm + '''' ELSE 'NULL' END,
            @ThumbPrint = ', ' + CASE WHEN ThumbPrint IS NOT NULL THEN +master.dbo.fn_varbintohexstr(ThumbPrint) ELSE 'NULL' END,
            @IsActive = ', ' + CASE WHEN IsActive IS NOT NULL THEN CAST(IsActive AS VARCHAR(6)) ELSE 'NULL' END
        FROM
            #BackupEncryptionSettSync
        WHERE
            ID = @i

        INSERT  Minion.SyncCmds
                (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd,
                 Pushed, Attempts)
        SELECT
            @ExecutionDateTime, 'Backup', 'In queue', 'BackupEncryption',
            'INSERT',
            ('INSERT Minion.BackupEncryption (DBName, CertType, CertName, EncrAlgorithm, ThumbPrint, IsActive) SELECT '
             + @DBName + @CertType + @CertName + @EncrAlgorithm + @ThumbPrint
             + @IsActive), 0, 0;

        SET @i = @i + 1
 END

DROP TABLE #BackupEncryptionSettSync;
-------------------------------------------------------------------------
--------------------END BackupEncryption---------------------------------
-------------------------------------------------------------------------



-------------------------------------------------------------------------
--------------------BEGIN DBMaintDBGroups--------------------------------
-------------------------------------------------------------------------
---1st, truncate the existing data on the foreign server.  There's no need to try to figure out what's changed.
---The easiest is to just dump all the data and reload it.  There won't be thousands of rows in most cases so this won't be an issue.
INSERT  Minion.SyncCmds
        (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd, Pushed,
         Attempts)
SELECT
    @ExecutionDateTime, 'Backup', 'In queue', 'BackupEncryption', 'TRUNCATE',
    'TRUNCATE TABLE Minion.BackupEncryption;', 0, 0;



SET @i = 1;
SET @CT = (
           SELECT COUNT (*) FROM Minion.DBMaintDBGroups
          )

SELECT
    ID = IDENTITY( INT,1,1), [Action], MaintType, GroupName, GroupDef, [Escape], IsActive, Comment
INTO
    #DBMaintDBGroups
FROM
    Minion.DBMaintDBGroups
	 ORDER BY ID ASC

WHILE @i <= @CT
    BEGIN
        SELECT
            @Action = CASE WHEN DBName IS NOT NULL THEN '''' + Action + '''' ELSE 'NULL' END,
            @MaintType = ', ' + CASE WHEN MaintType IS NOT NULL THEN '''' + MaintType + '''' ELSE 'NULL' END,
            @GroupName = ', ' + CASE WHEN GroupName IS NOT NULL THEN '''' + GroupName + '''' ELSE 'NULL' END,
            @GroupDef = ', ' + CASE WHEN GroupDef IS NOT NULL THEN '''' + GroupDef + '''' ELSE 'NULL' END,
            @Escape = ', ' + CASE WHEN [Escape] IS NOT NULL THEN '''' + [Escape] + '''' ELSE 'NULL' END,
            @IsActive = ', ' + CASE WHEN IsActive IS NOT NULL THEN CAST(IsActive AS VARCHAR(6)) ELSE 'NULL' END,
			@Comment = ', ' + CASE WHEN Comment IS NOT NULL THEN '''' + Comment + '''' ELSE 'NULL' END
        FROM
            #DBMaintDBGroups
        WHERE
            ID = @i

        INSERT  Minion.SyncCmds
                (ExecutionDateTime, Module, Status, ObjectName, Op, Cmd,
                 Pushed, Attempts)
        SELECT
            @ExecutionDateTime, 'Backup', 'In queue', 'DBMaintDBGroups',
            'INSERT',
            ('INSERT Minion.DBMaintDBGroups ([Action], MaintType, GroupName, GroupDef, [Escape], IsActive, Comment) SELECT '
             + @Action + @MaintType + @GroupName + @GroupDef + @Escape
             + @IsActive + @Comment), 0, 0;

        SET @i = @i + 1
 END

DROP TABLE #DBMaintDBGroups;
-------------------------------------------------------------------------
--------------------END DBMaintDBGroups----------------------------------
-------------------------------------------------------------------------

GO
