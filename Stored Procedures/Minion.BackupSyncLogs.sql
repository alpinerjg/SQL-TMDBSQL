SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[BackupSyncLogs] 
	(
	  @ExecutionDateTime DATETIME
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
	EXEC [Minion].[BackupSyncLogs] ExecutionDateTime = GetDate();

Revision History:
	

***********************************************************************************/
AS 
	SET NOCOUNT ON; 

	DECLARE	@i INT ,
		@CT INT ,
		@ExecutionBeginDateTime VARCHAR(30) ,
		@STATUS VARCHAR(MAX) ,
		@DBType VARCHAR(10) ,
		@BackupType VARCHAR(20) ,
		@StmtOnly VARCHAR(6) ,
		@NumDBsOnServer VARCHAR(10) ,
		@NumDBsProcessed VARCHAR(10) ,
		@TotalBackupSizeInMB VARCHAR(20) ,
		@ReadOnly VARCHAR(6) ,
		@ExecutionEndDateTime VARCHAR(30) ,
		@ExecutionRunTimeInSecs VARCHAR(50) ,
		@BatchPreCode VARCHAR(MAX) ,
		@BatchPostCode VARCHAR(MAX) ,
		@DBPreCode NVARCHAR(MAX) ,
		@DBPostCode NVARCHAR(MAX) ,
		@IncludeDBs VARCHAR(MAX) ,
		@ExcludeDBs VARCHAR(MAX) ,
		@RegexDBsIncluded VARCHAR(MAX) ,
		@RegexDBsExcluded VARCHAR(MAX) ,
		@ShrinkLogThresholdInMB VARCHAR(10) ,
		@ShrinkLogSizeInMB VARCHAR(10) ,
		@FileAction VARCHAR(12) ,
		@FileActionTime VARCHAR(25) ,
		@FileActionMethod VARCHAR(25) ,
		@FileActionMethodFlags VARCHAR(100) ,
		@CertPword VARCHAR(1000) ,
		@ExpireDateInHrs VARCHAR(10) ,
		@RetainDays VARCHAR(10) ,
		@Descr VARCHAR(255) ,
		@BackupErrorMgmt VARCHAR(50) ,
		@MediaName VARCHAR(128) ,
		@MediaDescription VARCHAR(255) ,
		@NumberOfFiles VARCHAR(10) ,
		@BufferCount VARCHAR(10) ,
		@Maxtransfersize VARCHAR(10) ,
		@Compression VARCHAR(6) ,
		@PctComplete VARCHAR(10) ,
		@DBName VARCHAR(150) ,
		@ServerLabel VARCHAR(150) ,
		@NETBIOSName VARCHAR(150) ,
		@IsClustered VARCHAR(6) ,
		@IsInAG VARCHAR(6) ,
		@IsPrimaryReplica VARCHAR(6) ,
		@BackupStartDateTime VARCHAR(30) ,
		@BackupEndDateTime VARCHAR(30) ,
		@BackupTimeInSecs VARCHAR(20) ,
		@MBPerSec VARCHAR(20) ,
		@BackupCmd VARCHAR(MAX) ,
		@SizeInMB VARCHAR(20) ,
		@BackupGroupOrder VARCHAR(10) ,
		@BackupGroupDBOrder VARCHAR(10) ,
		@MemoryLimitInMB VARCHAR(20) ,
		@TotalBufferSpaceInMB VARCHAR(20) ,
		@FileSystemIOAlignInKB VARCHAR(10) ,
		@SetsOfBuffers VARCHAR(10) ,
		@Verify VARCHAR(10) ,
		@VerifyStartDateTime VARCHAR(30),
		@VerifyEndDateTime VARCHAR(30),
		@VerifyTimeInSecs VARCHAR(50),
		@FileActionBeginDateTime VARCHAR(30) ,
		@FileActionEndDateTime VARCHAR(30) ,
		@FileActionTimeInSecs VARCHAR(20) ,
		@UnCompressedBackupSizeMB VARCHAR(20) ,
		@CompressedBackupSizeMB VARCHAR(20) ,
		@CompressionRatio VARCHAR(10) ,
		@COMPRESSIONPct VARCHAR(10) ,
		@BackupRetHrs VARCHAR(20) ,
		@BackupLogging VARCHAR(30) ,
		@BackupLoggingRetDays VARCHAR(10) ,
		@BackupDelFileBefore VARCHAR(10) ,
		@DBPreCodeStartDateTime VARCHAR(30) ,
		@DBPreCodeEndDateTime VARCHAR(30) ,
		@DBPreCodeTimeInSecs VARCHAR(20) ,
		@DBPostCodeStartDateTime VARCHAR(30) ,
		@DBPostCodeEndDateTime VARCHAR(30) ,
		@DBPostCodeTimeInSecs VARCHAR(20) ,
		@Verified VARCHAR(10) ,
		@IsInit VARCHAR(10) ,
		@IsFormat VARCHAR(10) ,
		@IsCheckSum VARCHAR(10) ,
		@BlockSize VARCHAR(10),
		@IsCopyOnly VARCHAR(10) ,
		@IsSkip VARCHAR(10) ,
		@BackupName VARCHAR(300) ,
		@MirrorBackup VARCHAR(10) ,
		@DynamicTuning VARCHAR(10) ,
		@ShrinkLogOnLogBackup VARCHAR(10) ,
		@PreBackupLogSizeInMB VARCHAR(10) ,
		@PreBackupLogUsedPct VARCHAR(10) ,
		@PostBackupLogSizeInMB VARCHAR(10) ,
		@PostBackupLogUsedPct VARCHAR(10) ,
		@PreBackupLogReuseWait VARCHAR(30) ,
		@PostBackupLogReuseWait VARCHAR(30) ,
		@VLFs VARCHAR(20) ,
		@FileList VARCHAR(MAX) ,
		@IsTDE VARCHAR(10) ,
		@IsEncryptedBackup VARCHAR(10) ,
		@BackupCert VARCHAR(10) ,
		@ThumbPrint VARCHAR(500) ,
		@Warnings VARCHAR(MAX) ,
		@Op VARCHAR(30) ,
		@BackupLocType VARCHAR(30) ,
		@BackupDrive VARCHAR(150) ,
		@BackupPath VARCHAR(1050) ,
		@FullPath VARCHAR(4050) ,
		@FullFileName VARCHAR(8000) ,
		@FileName VARCHAR(600) ,
		@DateLogic VARCHAR(120) ,
		@Extension VARCHAR(10) ,
		@RetHrs VARCHAR(20) ,
		@IsMirror VARCHAR(10) ,
		@ToBeDeleted VARCHAR(30) ,
		@DeleteDateTime VARCHAR(30) ,
		@IsDeleted VARCHAR(10) ,
		@IsArchive VARCHAR(10) ,
		@BackupSizeInMB VARCHAR(20) ,
		@BackupDescription VARCHAR(1000) ,
		@ExpirationDate VARCHAR(30) ,
		@Compressed VARCHAR(10) ,
		@POSITION VARCHAR(10) ,
		@DeviceType VARCHAR(10) ,
		@UserName VARCHAR(120) ,
		@DatabaseName VARCHAR(150) ,
		@DatabaseVersion VARCHAR(20) ,
		@DatabaseCreationDate VARCHAR(30) ,
		@BackupSizeInBytes VARCHAR(30) ,
		@FirstLSN VARCHAR(120) ,
		@LastLSN VARCHAR(120) ,
		@CheckpointLSN VARCHAR(120) ,
		@DatabaseBackupLSN VARCHAR(120) ,
		@BackupStartDate VARCHAR(30) ,
		@BackupFinishDate VARCHAR(30) ,
		@SortOrder VARCHAR(10) ,
		@CODEPAGE VARCHAR(10) ,
		@UnicodeLocaleId VARCHAR(20) ,
		@UnicodeComparisonStyle VARCHAR(20) ,
		@CompatibilityLevel VARCHAR(10) ,
		@SoftwareVendorId VARCHAR(10) ,
		@SoftwareVersionMajor VARCHAR(10) ,
		@SoftwareVersionMinor VARCHAR(10) ,
		@SovtwareVersionBuild VARCHAR(10) ,
		@MachineName VARCHAR(120) ,
		@Flags VARCHAR(10) ,
		@BindingID VARCHAR(120) ,
		@RecoveryForkID VARCHAR(120) ,
		@COLLATION VARCHAR(120) ,
		@FamilyGUID VARCHAR(120) ,
		@HasBulkLoggedData VARCHAR(10) ,
		@IsSnapshot VARCHAR(10) ,
		@IsReadOnly VARCHAR(10) ,
		@IsSingleUser VARCHAR(10) ,
		@HasBackupChecksums VARCHAR(10) ,
		@IsDamaged VARCHAR(10) ,
		@BeginsLogChain VARCHAR(10) ,
		@HasIncompleteMeatdata VARCHAR(10) ,
		@IsForceOffline VARCHAR(10) ,
		@FirstRecoveryForkID VARCHAR(120) ,
		@ForkPointLSN VARCHAR(120) ,
		@RecoveryModel VARCHAR(20) ,
		@DifferentialBaseLSN VARCHAR(120) ,
		@DifferentialBaseGUID VARCHAR(120) ,
		@BackupTypeDescription VARCHAR(30) ,
		@BackupSetGUID VARCHAR(120) ,
		@CompressedBackupSize VARCHAR(30) ,
		@CONTAINMENT VARCHAR(10),
		@BackupEncryptionCertName VARCHAR(150),
		@BackupEncryptionAlgorithm VARCHAR(500),
		@BackupEncryptionCertThumbPrint VARCHAR(500),
		@DeleteFilesStartDateTime VARCHAR(30),
		@DeleteFilesEndDateTime VARCHAR(30),
		@DeleteFilesTimeInSecs VARCHAR(20);

-------------------------------------------------------------------------
--------------------BEGIN BackupLog---------------------------------
-------------------------------------------------------------------------

	SET @i = 1;
	SET @CT = ( SELECT	COUNT(*)
				FROM	Minion.BackupLog
				WHERE	ExecutionDateTime = @ExecutionDateTime
			  )

	SELECT	ID = IDENTITY( INT,1,1 ),
			ExecutionDateTime ,
			STATUS ,
			DBType ,
			BackupType ,
			StmtOnly ,
			NumDBsOnServer ,
			NumDBsProcessed ,
			TotalBackupSizeInMB ,
			ReadOnly ,
			ExecutionEndDateTime ,
			ExecutionRunTimeInSecs ,
			BatchPreCode ,
			BatchPostCode ,
			IncludeDBs ,
			ExcludeDBs ,
			RegexDBsIncluded ,
			RegexDBsExcluded
	INTO	#BackupLog
	FROM	Minion.BackupLog
	WHERE	ExecutionDateTime = @ExecutionDateTime

	WHILE @i <= @CT 
		BEGIN
			SELECT	@ExecutionBeginDateTime = CASE WHEN ExecutionDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), ExecutionDateTime, 21) + '''' ELSE 'NULL' END ,
					@STATUS = ', ' + CASE WHEN [STATUS] IS NOT NULL THEN '''' + REPLACE([STATUS], '''', '''''') + '''' ELSE 'NULL' END ,
					@DBType = ', ' + CASE WHEN DBType IS NOT NULL THEN '''' + DBType + '''' ELSE 'NULL' END ,
					@BackupType = ', ' + CASE WHEN BackupType IS NOT NULL THEN '''' + BackupType + '''' ELSE 'NULL' END ,
					@StmtOnly = ', ' + CASE WHEN StmtOnly IS NOT NULL THEN CAST(StmtOnly AS VARCHAR(6)) ELSE 'NULL' END ,
					@NumDBsOnServer = ', ' + CASE WHEN NumDBsOnServer IS NOT NULL THEN CAST(NumDBsOnServer AS VARCHAR(6)) ELSE 'NULL' END ,
					@NumDBsProcessed = ', ' + CASE WHEN NumDBsProcessed IS NOT NULL THEN CAST(NumDBsProcessed AS VARCHAR(6)) ELSE 'NULL' END ,
					@TotalBackupSizeInMB = ', ' + CASE WHEN CAST(TotalBackupSizeInMB AS VARCHAR(45)) IS NOT NULL THEN CAST(TotalBackupSizeInMB AS VARCHAR(45)) ELSE 'NULL' END ,
					@ReadOnly = ', ' + CASE WHEN ReadOnly IS NOT NULL THEN CAST(ReadOnly AS VARCHAR(4)) ELSE 'NULL' END ,
					@ExecutionEndDateTime = ', ' + CASE WHEN ExecutionEndDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), ExecutionEndDateTime, 21) + '''' ELSE 'NULL' END ,
					@ExecutionRunTimeInSecs = ', ' + CASE WHEN ExecutionRunTimeInSecs IS NOT NULL THEN CAST(ExecutionRunTimeInSecs AS VARCHAR(45)) ELSE 'NULL' END ,
					@BatchPreCode = ', ' + CASE WHEN BatchPreCode IS NOT NULL THEN '''' + REPLACE(BatchPreCode, '''', '''''') ELSE 'NULL' END ,
					@BatchPostCode = ', ' + CASE WHEN BatchPostCode IS NOT NULL THEN '''' + REPLACE(BatchPostCode, '''', '''''') + '''' ELSE 'NULL' END ,
					@IncludeDBs = ', ' + CASE WHEN IncludeDBs IS NOT NULL THEN '''' + IncludeDBs + '''' ELSE 'NULL' END ,
					@ExcludeDBs = ', ' + CASE WHEN ExcludeDBs IS NOT NULL THEN '''' + ExcludeDBs + '''' ELSE 'NULL' END ,
					@RegexDBsIncluded = ', ' + CASE WHEN RegexDBsIncluded IS NOT NULL THEN RegexDBsIncluded ELSE 'NULL' END ,
					@RegexDBsExcluded = ', ' + CASE WHEN RegexDBsExcluded IS NOT NULL THEN RegexDBsExcluded ELSE 'NULL'  END
			FROM	#BackupLog
			WHERE	ID = @i
			--SELECT	@BatchPreCode
			INSERT	Minion.SyncCmds
					( ExecutionDateTime ,
					  Module ,
					  Status ,
					  ObjectName ,
					  Op ,
					  Cmd ,
					  Pushed ,
					  Attempts
					)
					SELECT	@ExecutionDateTime ,
							'Backup' ,
							'In queue' ,
							'BackupLog' ,
							'INSERT' ,
							( 'INSERT Minion.BackupLog (ExecutionDateTime, STATUS, DBType, BackupType, StmtOnly, NumDBsOnServer, NumDBsProcessed, TotalBackupSizeInMB, ReadOnly, ExecutionEndDateTime, ExecutionRunTimeInSecs, BatchPreCode, BatchPostCode, IncludeDBs, ExcludeDBs, RegexDBsIncluded, RegexDBsExcluded) SELECT '
							  + @ExecutionBeginDateTime + @STATUS + @DBType
							  + @BackupType + @StmtOnly + @NumDBsOnServer
							  + @NumDBsProcessed + @TotalBackupSizeInMB
							  + @ReadOnly + @ExecutionEndDateTime
							  + @ExecutionRunTimeInSecs + @BatchPreCode
							  + @BatchPostCode + @IncludeDBs + @ExcludeDBs
							  + @RegexDBsIncluded + @RegexDBsExcluded ) ,
							0 ,
							0;

			SET @i = @i + 1
		END

	DROP TABLE #BackupLog;
-------------------------------------------------------------------------
--------------------END BackupLog----------------------------------------
-------------------------------------------------------------------------



-------------------------------------------------------------------------
--------------------BEGIN BackupLogDetails-------------------------------
-------------------------------------------------------------------------

	SET @i = 1;
	SET @CT = ( SELECT	COUNT(*)
				FROM	Minion.BackupLogDetails
				WHERE	ExecutionDateTime = @ExecutionDateTime
			  )

	SELECT	ID = IDENTITY( INT,1,1 ),
			ExecutionDateTime ,
			STATUS ,
			PctComplete ,
			DBName ,
			ServerLabel ,
			NETBIOSName ,
			IsClustered ,
			IsInAG ,
			IsPrimaryReplica ,
			DBType ,
			BackupType ,
			BackupStartDateTime ,
			BackupEndDateTime ,
			BackupTimeInSecs ,
			MBPerSec ,
			BackupCmd ,
			SizeInMB ,
			StmtOnly ,
			READONLY ,
			BackupGroupOrder ,
			BackupGroupDBOrder ,
			NumberOfFiles ,
			Buffercount ,
			MaxTransferSize ,
			MemoryLimitInMB ,
			TotalBufferSpaceInMB ,
			FileSystemIOAlignInKB ,
			SetsOfBuffers ,
			Verify ,
			Compression ,
			FileAction ,
			FileActionTime ,
			FileActionBeginDateTime ,
			FileActionEndDateTime ,
			FileActionTimeInSecs ,
			UnCompressedBackupSizeMB ,
			CompressedBackupSizeMB ,
			CompressionRatio ,
			COMPRESSIONPct ,
			BackupRetHrs ,
			BackupLogging ,
			BackupLoggingRetDays ,
			DelFileBefore ,
			DBPreCode ,
			DBPostCode ,
			DBPreCodeStartDateTime ,
			DBPreCodeEndDateTime ,
			DBPreCodeTimeInSecs ,
			DBPostCodeStartDateTime ,
			DBPostCodeEndDateTime ,
			DBPostCodeTimeInSecs ,
			IncludeDBs ,
			ExcludeDBs ,
			RegexDBsExcluded ,
			Verified ,
			VerifyStartDateTime,
			VerifyEndDateTime,
			VerifyTimeInSecs,
			IsInit ,
			IsFormat ,
			IsCheckSum ,
			BlockSize,
			Descr ,
			IsCopyOnly ,
			IsSkip ,
			BackupName ,
			BackupErrorMgmt ,
			MediaName ,
			MediaDescription ,
			ExpireDateInHrs ,
			RetainDays ,
			MirrorBackup ,
			DynamicTuning ,
			ShrinkLogOnLogBackup ,
			ShrinkLogThresholdInMB ,
			ShrinkLogSizeInMB ,
			PreBackupLogSizeInMB ,
			PreBackupLogUsedPct ,
			PostBackupLogSizeInMB ,
			PostBackupLogUsedPct ,
			PreBackupLogReuseWait ,
			PostBackupLogReuseWait ,
			VLFs ,
			FileList ,
			IsTDE ,
			BackupCert,
			CertPword,
			IsEncryptedBackup ,
			BackupEncryptionCertName,
			BackupEncryptionAlgorithm,
			BackupEncryptionCertThumbPrint,
			DeleteFilesStartDateTime,
			DeleteFilesEndDateTime,
			DeleteFilesTimeInSecs,
			Warnings
	INTO	#BackupLogDetails
	FROM	Minion.BackupLogDetails
	WHERE	ExecutionDateTime = @ExecutionDateTime

	WHILE @i <= @CT 
		BEGIN

			SELECT	
					@ExecutionBeginDateTime = CASE WHEN ExecutionDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), ExecutionDateTime, 21) + '''' ELSE 'NULL' END ,
					@STATUS = ', ' + CASE WHEN [STATUS] IS NOT NULL THEN '''' + REPLACE([STATUS], '''', '''''') + '''' ELSE 'NULL' END ,
					@PctComplete = ', ' + CASE WHEN PctComplete IS NOT NULL THEN CAST(PctComplete AS VARCHAR(6))ELSE 'NULL' END ,
					@DBName = ', ' + CASE WHEN DBName IS NOT NULL THEN '''' + CAST(DBName AS VARCHAR(150)) + '''' ELSE 'NULL' END ,
					@ServerLabel = ', ' + CASE WHEN ServerLabel IS NOT NULL THEN '''' + CAST(ServerLabel AS VARCHAR(150)) + '''' ELSE 'NULL' END ,
					@NETBIOSName = ', ' + CASE WHEN NETBIOSName IS NOT NULL THEN '''' + CAST(NETBIOSName AS VARCHAR(150)) + '''' ELSE 'NULL' END ,
					@IsClustered = ', ' + CASE WHEN IsClustered IS NOT NULL THEN CAST(IsClustered AS VARCHAR(150)) ELSE 'NULL' END ,
					@IsInAG = ', ' + CASE WHEN IsInAG IS NOT NULL THEN CAST(IsInAG AS VARCHAR(6)) ELSE 'NULL' END ,
					@IsPrimaryReplica = ', ' + CASE WHEN IsPrimaryReplica IS NOT NULL THEN CAST(IsPrimaryReplica AS VARCHAR(6)) ELSE 'NULL' END ,
					@DBType = ', ' + CASE WHEN DBType IS NOT NULL THEN '''' + CAST(DBType AS VARCHAR(10)) + '''' ELSE 'NULL' END ,
					@BackupType = ', ' + CASE WHEN BackupType IS NOT NULL THEN '''' + CAST(BackupType AS VARCHAR(30)) + '''' ELSE 'NULL' END ,
					@BackupStartDateTime = ', ' + CASE WHEN BackupStartDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), BackupStartDateTime, 21) + '''' ELSE 'NULL' END ,
					@BackupEndDateTime = ', ' + CASE WHEN BackupEndDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), BackupEndDateTime, 21) + '''' ELSE 'NULL' END ,
					@BackupTimeInSecs = ', ' + CASE WHEN BackupTimeInSecs IS NOT NULL THEN CAST(BackupTimeInSecs AS VARCHAR(50)) ELSE 'NULL' END ,
					@MBPerSec = ', ' + CASE WHEN MBPerSec IS NOT NULL THEN CAST(MBPerSec AS VARCHAR(10)) ELSE 'NULL' END ,
					@BackupCmd = ', ' + CASE WHEN BackupCmd IS NOT NULL THEN '''' + REPLACE(BackupCmd, '''', '''''') + '''' ELSE 'NULL' END ,
					@SizeInMB = ', ' + CASE WHEN SizeInMB IS NOT NULL THEN CAST(SizeInMB AS VARCHAR(20)) ELSE 'NULL' END ,
					@StmtOnly = ', ' + CASE WHEN StmtOnly IS NOT NULL THEN CAST(StmtOnly AS VARCHAR(6)) ELSE 'NULL' END ,
					@ReadOnly = ', ' + CASE WHEN READONLY IS NOT NULL THEN CAST(READONLY AS VARCHAR(6)) ELSE 'NULL' END ,
					@BackupGroupOrder = ', ' + CASE WHEN BackupGroupOrder IS NOT NULL THEN CAST(BackupGroupOrder AS VARCHAR(6)) ELSE 'NULL' END ,
					@BackupGroupDBOrder = ', ' + CASE WHEN BackupGroupDBOrder IS NOT NULL THEN CAST(BackupGroupDBOrder AS VARCHAR(6)) ELSE 'NULL' END ,
					@NumberOfFiles = ', ' + CASE WHEN NumberOfFiles IS NOT NULL THEN CAST(NumberOfFiles AS VARCHAR(10)) ELSE 'NULL' END ,
					@BufferCount = ', ' + CASE WHEN Buffercount IS NOT NULL THEN CAST(Buffercount AS VARCHAR(10)) ELSE 'NULL' END ,
					@Maxtransfersize = ', ' + CASE WHEN MaxTransferSize IS NOT NULL THEN CAST(MaxTransferSize AS VARCHAR(15)) ELSE 'NULL' END ,
					@MemoryLimitInMB = ', ' + CASE WHEN MemoryLimitInMB IS NOT NULL THEN CAST(MemoryLimitInMB AS VARCHAR(20)) ELSE 'NULL' END ,
					@TotalBufferSpaceInMB = ', ' + CASE WHEN TotalBufferSpaceInMB IS NOT NULL THEN CAST(TotalBufferSpaceInMB AS VARCHAR(20)) ELSE 'NULL' END ,
					@FileSystemIOAlignInKB = ', ' + CASE WHEN FileSystemIOAlignInKB IS NOT NULL THEN CAST(FileSystemIOAlignInKB AS VARCHAR(10)) ELSE 'NULL' END ,
					@SetsOfBuffers = ', ' + CASE WHEN SetsOfBuffers IS NOT NULL THEN CAST(SetsOfBuffers AS VARCHAR(6)) ELSE 'NULL' END ,
					@Verify = ', ' + CASE WHEN Verify IS NOT NULL THEN CAST(Verify AS VARCHAR(6)) ELSE 'NULL' END ,
					@Compression = ', ' + CASE WHEN Compression IS NOT NULL THEN CAST(Compression AS VARCHAR(10)) ELSE 'NULL' END ,
					@FileAction = ', ' + CASE WHEN FileAction IS NOT NULL THEN '''' + CAST(FileAction AS VARCHAR(20)) + '''' ELSE 'NULL' END ,
					@FileActionTime = ', ' + CASE WHEN FileActionTime IS NOT NULL THEN '''' + CAST(FileActionTime AS VARCHAR(30)) + '''' ELSE 'NULL' END ,
					@FileActionBeginDateTime = ', ' + CASE WHEN FileActionBeginDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), FileActionBeginDateTime, 21) + '''' ELSE 'NULL' END ,
					@FileActionEndDateTime = ', ' + CASE WHEN FileActionEndDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), FileActionEndDateTime, 21) + '''' ELSE 'NULL' END ,
					@FileActionTimeInSecs = ', ' + CASE WHEN FileActionTimeInSecs IS NOT NULL THEN CAST(FileActionTimeInSecs AS VARCHAR(20)) ELSE 'NULL' END ,
					@UnCompressedBackupSizeMB = ', ' + CASE WHEN UnCompressedBackupSizeMB IS NOT NULL THEN CAST(UnCompressedBackupSizeMB AS VARCHAR(20)) ELSE 'NULL' END ,
					@CompressedBackupSizeMB = ', ' + CASE WHEN CompressedBackupSizeMB IS NOT NULL THEN CAST(CompressedBackupSizeMB AS VARCHAR(20)) ELSE 'NULL' END ,
					@CompressionRatio = ', ' + CASE WHEN CompressionRatio IS NOT NULL THEN CAST(CompressionRatio AS VARCHAR(10)) ELSE 'NULL' END ,
					@COMPRESSIONPct = ', ' + CASE WHEN COMPRESSIONPct IS NOT NULL THEN CAST(COMPRESSIONPct AS VARCHAR(10)) ELSE 'NULL' END ,
					@BackupRetHrs = ', ' + CASE WHEN BackupRetHrs IS NOT NULL THEN CAST(BackupRetHrs AS VARCHAR(10)) ELSE 'NULL' END ,
					@BackupLogging = ', ' + CASE WHEN BackupLogging IS NOT NULL THEN '''' + CAST(BackupLogging AS VARCHAR(30)) + '''' ELSE 'NULL' END ,
					@BackupLoggingRetDays = ', ' + CASE WHEN BackupLoggingRetDays IS NOT NULL THEN CAST(BackupLoggingRetDays AS VARCHAR(10)) ELSE 'NULL' END ,
					@BackupDelFileBefore = ', ' + CASE WHEN DelFileBefore IS NOT NULL THEN CAST(DelFileBefore AS VARCHAR(6)) ELSE 'NULL' END ,
					@DBPreCode = ', ' + CASE WHEN DBPreCode IS NOT NULL THEN '''' + REPLACE(DBPreCode, '''', '''''') + '''' ELSE 'NULL' END ,
					@DBPostCode = ', ' + CASE WHEN DBPostCode IS NOT NULL THEN '''' + REPLACE(DBPostCode, '''', '''''') + '''' ELSE 'NULL' END ,
					@DBPreCodeStartDateTime = ', ' + CASE WHEN DBPreCodeStartDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), DBPreCodeStartDateTime, 21) + '''' ELSE 'NULL' END ,
					@DBPreCodeEndDateTime = ', ' + CASE WHEN DBPreCodeEndDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), DBPreCodeEndDateTime, 21) + '''' ELSE 'NULL' END ,
					@DBPreCodeTimeInSecs = ', ' + CASE WHEN DBPreCodeTimeInSecs IS NOT NULL THEN CAST(DBPreCodeTimeInSecs AS VARCHAR(20)) ELSE 'NULL' END ,
					@DBPostCodeStartDateTime = ', ' + CASE WHEN DBPostCodeStartDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), DBPostCodeStartDateTime, 21) + '''' ELSE 'NULL' END ,
					@DBPostCodeEndDateTime = ', ' + CASE WHEN DBPostCodeEndDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), DBPostCodeEndDateTime, 21) + '''' ELSE 'NULL' END ,
					@DBPostCodeTimeInSecs = ', ' + CASE WHEN DBPostCodeTimeInSecs IS NOT NULL THEN CAST(DBPostCodeTimeInSecs AS VARCHAR(20)) ELSE 'NULL' END ,
					@IncludeDBs = ', ' + CASE WHEN IncludeDBs IS NOT NULL THEN '''' + IncludeDBs + '''' ELSE 'NULL' END ,
					@ExcludeDBs = ', ' + CASE WHEN ExcludeDBs IS NOT NULL THEN '''' + ExcludeDBs + '''' ELSE 'NULL' END ,
					@RegexDBsExcluded = ', ' + CASE WHEN RegexDBsExcluded IS NOT NULL THEN '''' + RegexDBsExcluded + '''' ELSE 'NULL' END ,
					@Verified = ', ' + CASE WHEN Verified IS NOT NULL THEN CAST(Verified AS VARCHAR(6)) ELSE 'NULL' END ,
					@VerifyStartDateTime = ', ' + CASE WHEN VerifyStartDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), VerifyStartDateTime, 21) + '''' ELSE 'NULL' END ,
					@VerifyEndDateTime = ', ' + CASE WHEN VerifyEndDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), VerifyEndDateTime, 21) + '''' ELSE 'NULL' END ,
					@VerifyTimeInSecs = ', ' + CASE WHEN VerifyTimeInSecs IS NOT NULL THEN CAST(VerifyTimeInSecs AS VARCHAR(20)) ELSE 'NULL' END ,
					@IsInit = ', ' + CASE WHEN IsInit IS NOT NULL THEN CAST(IsInit AS VARCHAR(6)) ELSE 'NULL' END ,
					@IsFormat = ', ' + CASE WHEN IsFormat IS NOT NULL THEN CAST(IsFormat AS VARCHAR(6)) ELSE 'NULL' END ,
					@IsCheckSum = ', ' + CASE WHEN IsCheckSum IS NOT NULL THEN CAST(IsCheckSum AS VARCHAR(6)) ELSE 'NULL' END ,
					@BlockSize = ', ' + CASE WHEN BlockSize IS NOT NULL THEN CAST(BlockSize AS VARCHAR(10)) ELSE 'NULL' END ,
					@Descr = ', ' + CASE WHEN Descr IS NOT NULL THEN '''' + REPLACE(Descr, '''',  '''''') + '''' ELSE 'NULL' END ,
					@IsCopyOnly = ', ' + CASE WHEN IsCopyOnly IS NOT NULL THEN CAST(IsCopyOnly AS VARCHAR(6)) ELSE 'NULL' END ,
					@IsSkip = ', ' + CASE WHEN IsSkip IS NOT NULL THEN CAST(IsSkip AS VARCHAR(6)) ELSE 'NULL' END ,
					@BackupName = ', ' + CASE WHEN BackupName IS NOT NULL THEN '''' + BackupName + '''' ELSE 'NULL' END ,
					@BackupErrorMgmt = ', ' + CASE WHEN BackupErrorMgmt IS NOT NULL THEN '''' + BackupErrorMgmt + '''' ELSE 'NULL' END ,
					@MediaName = ', ' + CASE WHEN MediaName IS NOT NULL THEN '''' + MediaName + '''' ELSE 'NULL' END ,
					@MediaDescription = ', ' + CASE WHEN MediaDescription IS NOT NULL THEN '''' + REPLACE(MediaDescription, '''', '''''') + '''' ELSE 'NULL' END ,
					@ExpireDateInHrs = ', ' + CASE WHEN ExpireDateInHrs IS NOT NULL THEN CAST(ExpireDateInHrs AS VARCHAR(20)) ELSE 'NULL' END ,
					@RetainDays = ', ' + CASE WHEN RetainDays IS NOT NULL THEN CAST(RetainDays AS VARCHAR(20)) ELSE 'NULL' END ,
					@MirrorBackup = ', ' + CASE WHEN MirrorBackup IS NOT NULL THEN CAST(MirrorBackup AS VARCHAR(6)) ELSE 'NULL' END ,
					@DynamicTuning = ', ' + CASE WHEN DynamicTuning IS NOT NULL THEN CAST(DynamicTuning AS VARCHAR(6)) ELSE 'NULL' END ,
					@ShrinkLogOnLogBackup = ', ' + CASE WHEN ShrinkLogOnLogBackup IS NOT NULL THEN CAST(ShrinkLogOnLogBackup AS VARCHAR(6)) ELSE 'NULL' END ,
					@ShrinkLogThresholdInMB = ', ' + CASE WHEN ShrinkLogThresholdInMB IS NOT NULL THEN CAST(ShrinkLogThresholdInMB AS VARCHAR(20)) ELSE 'NULL' END ,
					@ShrinkLogSizeInMB = ', ' + CASE WHEN ShrinkLogSizeInMB IS NOT NULL THEN CAST(ShrinkLogSizeInMB AS VARCHAR(20)) ELSE 'NULL' END ,
					@PreBackupLogSizeInMB = ', ' + CASE WHEN PreBackupLogSizeInMB IS NOT NULL THEN CAST(PreBackupLogSizeInMB AS VARCHAR(20)) ELSE 'NULL' END ,
					@PreBackupLogUsedPct = ', ' + CASE WHEN PreBackupLogUsedPct IS NOT NULL THEN CAST(PreBackupLogUsedPct AS VARCHAR(10)) ELSE 'NULL' END ,
					@PostBackupLogSizeInMB = ', ' + CASE WHEN PostBackupLogSizeInMB IS NOT NULL THEN CAST(PostBackupLogSizeInMB AS VARCHAR(10)) ELSE 'NULL' END ,
					@PostBackupLogUsedPct = ', ' + CASE WHEN PostBackupLogUsedPct IS NOT NULL THEN CAST(PostBackupLogUsedPct AS VARCHAR(10)) ELSE 'NULL' END ,
					@PreBackupLogReuseWait = ', ' + CASE WHEN PreBackupLogReuseWait IS NOT NULL THEN '''' + PreBackupLogReuseWait + '''' ELSE 'NULL' END ,
					@PostBackupLogReuseWait = ', ' + CASE WHEN PostBackupLogReuseWait IS NOT NULL THEN '''' + PostBackupLogReuseWait + '''' ELSE 'NULL' END ,
					@VLFs = ', ' + CASE WHEN VLFs IS NOT NULL THEN CAST(VLFs AS VARCHAR(20)) ELSE 'NULL' END ,
					@FileList = ', ' + CASE WHEN FileList IS NOT NULL THEN '''' + REPLACE(FileList, '''', '''''') + '''' ELSE 'NULL' END ,
					@IsTDE = ', ' + CASE WHEN IsTDE IS NOT NULL THEN CAST(IsTDE AS VARCHAR(6)) ELSE 'NULL' END ,
					@BackupCert = ', ' + CASE WHEN BackupCert IS NOT NULL THEN CAST(BackupCert AS VARCHAR(10)) ELSE 'NULL' END ,
					@CertPword = ', ' + CASE WHEN CertPword IS NOT NULL THEN master.dbo.fn_varbintohexstr(CertPword) ELSE 'NULL' END ,
					@IsEncryptedBackup = ', ' + CASE WHEN IsEncryptedBackup IS NOT NULL THEN CAST(IsEncryptedBackup AS VARCHAR(6)) ELSE 'NULL' END ,
					@Warnings = ', ' + CASE WHEN Warnings IS NOT NULL THEN '''' + Warnings + '''' ELSE 'NULL' END,
					@BackupEncryptionCertName = ', ' + CASE WHEN BackupEncryptionCertName IS NOT NULL THEN '''' + CAST(BackupEncryptionCertName AS VARCHAR(150)) + '''' ELSE 'NULL' END ,
					@BackupEncryptionAlgorithm = ', ' + CASE WHEN BackupEncryptionAlgorithm IS NOT NULL THEN '''' + BackupEncryptionAlgorithm + '''' ELSE 'NULL' END,
					@BackupEncryptionCertThumbPrint = ', ' + CASE WHEN BackupEncryptionCertThumbPrint IS NOT NULL THEN CAST(BackupEncryptionCertThumbPrint AS VARCHAR(500)) ELSE 'NULL' END ,
					@DeleteFilesStartDateTime = ', ' + CASE WHEN DeleteFilesStartDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), DeleteFilesStartDateTime, 21) + '''' ELSE 'NULL' END ,
					@DeleteFilesEndDateTime = ', ' + CASE WHEN DeleteFilesEndDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), DeleteFilesEndDateTime, 21) + '''' ELSE 'NULL' END ,
					@DeleteFilesTimeInSecs = ', ' + CASE WHEN DeleteFilesTimeInSecs IS NOT NULL THEN CAST(DeleteFilesTimeInSecs AS VARCHAR(20)) ELSE 'NULL' END 
			FROM	#BackupLogDetails
			WHERE	ID = @i

			INSERT	Minion.SyncCmds
					( ExecutionDateTime ,
					  Module ,
					  Status ,
					  ObjectName ,
					  Op ,
					  Cmd ,
					  Pushed ,
					  Attempts
					)
					SELECT	@ExecutionDateTime ,
							'Backup' ,
							'In queue' ,
							'BackupLogDetails' ,
							'INSERT' ,
							( 'INSERT Minion.BackupLogDetails (ExecutionDateTime,STATUS,PctComplete,DBName,ServerLabel,NETBIOSName,IsClustered,IsInAG,IsPrimaryReplica,DBType,BackupType,BackupStartDateTime,BackupEndDateTime,BackupTimeInSecs,MBPerSec,BackupCmd,SizeInMB,StmtOnly,READONLY,BackupGroupOrder,BackupGroupDBOrder,NumberOfFiles,Buffercount,MaxTransferSize,MemoryLimitInMB,TotalBufferSpaceInMB,FileSystemIOAlignInKB,SetsOfBuffers,Verify,Compression,FileAction,FileActionTime,FileActionBeginDateTime,FileActionEndDateTime,FileActionTimeInSecs,UnCompressedBackupSizeMB,CompressedBackupSizeMB,CompressionRatio,COMPRESSIONPct,BackupRetHrs,BackupLogging,BackupLoggingRetDays,DelFileBefore,DBPreCode,DBPostCode,DBPreCodeStartDateTime,DBPreCodeEndDateTime,DBPreCodeTimeInSecs,DBPostCodeStartDateTime,DBPostCodeEndDateTime,DBPostCodeTimeInSecs,IncludeDBs,ExcludeDBs,RegexDBsExcluded,Verified,VerifyStartDateTime,VerifyEndDateTime,VerifyTimeInSecs,IsInit,IsFormat,IsCheckSum,BlockSize,Descr,IsCopyOnly,IsSkip,BackupName,BackupErrorMgmt,MediaName,MediaDescription,ExpireDateInHrs,RetainDays,MirrorBackup,DynamicTuning,ShrinkLogOnLogBackup,ShrinkLogThresholdInMB,ShrinkLogSizeInMB,PreBackupLogSizeInMB,PreBackupLogUsedPct,PostBackupLogSizeInMB,PostBackupLogUsedPct,PreBackupLogReuseWait,PostBackupLogReuseWait,VLFs,FileList,IsTDE,BackupCert,CertPword,IsEncryptedBackup,BackupEncryptionCertName,BackupEncryptionAlgorithm,BackupEncryptionCertThumbPrint,DeleteFilesStartDateTime,DeleteFilesEndDateTime,DeleteFilesTimeInSecs,Warnings) SELECT '
							  + @ExecutionBeginDateTime + @STATUS
							  + @PctComplete + @DBName + @ServerLabel
							  + @NETBIOSName + @IsClustered + @IsInAG
							  + @IsPrimaryReplica + @DBType + @BackupType
							  + @BackupStartDateTime + @BackupEndDateTime
							  + @BackupTimeInSecs + @MBPerSec + @BackupCmd
							  + @SizeInMB + @StmtOnly + @ReadOnly
							  + @BackupGroupOrder + @BackupGroupDBOrder
							  + @NumberOfFiles + @BufferCount
							  + @Maxtransfersize + @MemoryLimitInMB
							  + @TotalBufferSpaceInMB + @FileSystemIOAlignInKB
							  + @SetsOfBuffers + @Verify + @Compression
							  + @FileAction + @FileActionTime
							  + @FileActionBeginDateTime
							  + @FileActionEndDateTime + @FileActionTimeInSecs
							  + @UnCompressedBackupSizeMB
							  + @CompressedBackupSizeMB + @CompressionRatio
							  + @COMPRESSIONPct + @BackupRetHrs
							  + @BackupLogging + @BackupLoggingRetDays
							  + @BackupDelFileBefore + @DBPreCode
							  + @DBPostCode + @DBPreCodeStartDateTime
							  + @DBPreCodeEndDateTime + @DBPreCodeTimeInSecs
							  + @DBPostCodeStartDateTime
							  + @DBPostCodeEndDateTime + @DBPostCodeTimeInSecs
							  + @IncludeDBs + @ExcludeDBs + @RegexDBsExcluded
							  + @Verified + @VerifyStartDateTime + @VerifyEndDateTime + @VerifyTimeInSecs
							  + @IsInit + @IsFormat + @IsCheckSum + @BlockSize
							  + @Descr + @IsCopyOnly + @IsSkip + @BackupName
							  + @BackupErrorMgmt + @MediaName
							  + @MediaDescription + @ExpireDateInHrs
							  + @RetainDays + @MirrorBackup
							  + @DynamicTuning + @ShrinkLogOnLogBackup
							  + @ShrinkLogThresholdInMB + @ShrinkLogSizeInMB
							  + @PreBackupLogSizeInMB + @PreBackupLogUsedPct
							  + @PostBackupLogSizeInMB + @PostBackupLogUsedPct
							  + @PreBackupLogReuseWait
							  + @PostBackupLogReuseWait + @VLFs + @FileList
							  + @IsTDE + @BackupCert + @CertPword + @IsEncryptedBackup
							  + @BackupEncryptionCertName + @BackupEncryptionAlgorithm 
							  + @BackupEncryptionCertThumbPrint + @DeleteFilesStartDateTime 
							  + @DeleteFilesEndDateTime
							  + @DeleteFilesTimeInSecs + @Warnings  ) ,
							0 ,
							0;

			SET @i = @i + 1
		END

--SELECT '#BackupLogDetails', * FROM #BackupLogDetails
	DROP TABLE #BackupLogDetails;
-------------------------------------------------------------------------
--------------------END BackupLogDetails---------------------------------
-------------------------------------------------------------------------


-------------------------------------------------------------------------
--------------------BEGIN BackupFiles------------------------------------
-------------------------------------------------------------------------

	SET @i = 1;
	SET @CT = ( SELECT	COUNT(*)
				FROM	Minion.BackupFiles
				WHERE	ExecutionDateTime = @ExecutionDateTime
			  )

	SELECT	ID = IDENTITY( INT,1,1 ),
			ExecutionDateTime ,
			Op ,
			Status ,
			DBName ,
			ServerLabel ,
			NETBIOSName ,
			BackupType ,
			BackupLocType ,
			BackupDrive ,
			BackupPath ,
			FullPath ,
			FullFileName ,
			FileName ,
			DateLogic ,
			Extension ,
			RetHrs ,
			IsMirror ,
			ToBeDeleted ,
			DeleteDateTime ,
			IsDeleted ,
			IsArchive ,
			BackupSizeInMB ,
			BackupName ,
			BackupDescription ,
			ExpirationDate ,
			Compressed ,
			POSITION ,
			DeviceType ,
			UserName ,
			DatabaseName ,
			DatabaseVersion ,
			DatabaseCreationDate ,
			BackupSizeInBytes ,
			FirstLSN ,
			LastLSN ,
			CheckpointLSN ,
			DatabaseBackupLSN ,
			BackupStartDate ,
			BackupFinishDate ,
			SortOrder ,
			CODEPAGE ,
			UnicodeLocaleId ,
			UnicodeComparisonStyle ,
			CompatibilityLevel ,
			SoftwareVendorId ,
			SoftwareVersionMajor ,
			SoftwareVersionMinor ,
			SovtwareVersionBuild ,
			MachineName ,
			Flags ,
			BindingID ,
			RecoveryForkID ,
			COLLATION ,
			FamilyGUID ,
			HasBulkLoggedData ,
			IsSnapshot ,
			IsReadOnly ,
			IsSingleUser ,
			HasBackupChecksums ,
			IsDamaged ,
			BeginsLogChain ,
			HasIncompleteMeatdata ,
			IsForceOffline ,
			IsCopyOnly ,
			FirstRecoveryForkID ,
			ForkPointLSN ,
			RecoveryModel ,
			DifferentialBaseLSN ,
			DifferentialBaseGUID ,
			BackupTypeDescription ,
			BackupSetGUID ,
			CompressedBackupSize ,
			CONTAINMENT
	INTO	#BackupFiles
	FROM	Minion.BackupFiles
	WHERE	ExecutionDateTime = @ExecutionDateTime

	WHILE @i <= @CT 
		BEGIN
			SELECT	@ExecutionBeginDateTime = CASE WHEN ExecutionDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), ExecutionDateTime, 21) + '''' ELSE 'NULL' END ,
					@Op = ', ' + CASE WHEN Op IS NOT NULL THEN '''' + Op + '''' ELSE 'NULL' END ,
					@STATUS = ', ' + CASE WHEN [Status] IS NOT NULL THEN '''' + [Status] + '''' ELSE 'NULL' END ,
					@DBName = ', ' + CASE WHEN DBName IS NOT NULL THEN '''' + DBName + '''' ELSE 'NULL' END ,
					@ServerLabel = ', ' + CASE WHEN ServerLabel IS NOT NULL THEN '''' + ServerLabel + '''' ELSE 'NULL' END ,
					@NETBIOSName = ', ' + CASE WHEN NETBIOSName IS NOT NULL THEN '''' + NETBIOSName + '''' ELSE 'NULL' END ,
					@BackupType = ', ' + CASE WHEN BackupType IS NOT NULL THEN '''' + BackupType + '''' ELSE 'NULL' END ,
					@BackupLocType = ', ' + CASE WHEN BackupLocType IS NOT NULL THEN '''' + BackupLocType + '''' ELSE 'NULL' END ,
					@BackupDrive = ', ' + CASE WHEN BackupDrive IS NOT NULL THEN '''' + BackupDrive + '''' ELSE 'NULL' END ,
					@BackupPath = ', ' + CASE WHEN BackupPath IS NOT NULL THEN '''' + BackupPath + '''' ELSE 'NULL' END ,
					@FullPath = ', ' + CASE WHEN FullPath IS NOT NULL THEN '''' + FullPath + '''' ELSE 'NULL' END ,
					@FullFileName = ', ' + CASE WHEN FullFileName IS NOT NULL THEN '''' + FullFileName + '''' ELSE 'NULL' END ,
					@FileName = ', ' + CASE WHEN FileName IS NOT NULL THEN '''' + FileName + '''' ELSE 'NULL' END ,
					@DateLogic = ', ' + CASE WHEN DateLogic IS NOT NULL THEN '''' + DateLogic + '''' ELSE 'NULL' END ,
					@Extension = ', ' + CASE WHEN Extension IS NOT NULL THEN '''' + Extension + '''' ELSE 'NULL'  END ,
					@RetHrs = ', ' + CASE WHEN RetHrs IS NOT NULL THEN '''' + CAST(RetHrs AS VARCHAR(10)) + '''' ELSE 'NULL' END ,
					@IsMirror = ', ' + CASE WHEN IsMirror IS NOT NULL THEN CAST(IsMirror AS VARCHAR(10)) ELSE 'NULL' END ,
					@ToBeDeleted = ', ' + CASE WHEN ToBeDeleted IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), ToBeDeleted, 21) + '''' ELSE 'NULL' END ,
					@DeleteDateTime = ', ' + CASE WHEN DeleteDateTime IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), DeleteDateTime, 21) + '''' ELSE 'NULL' END ,
					@IsDeleted = ', ' + CASE WHEN IsDeleted IS NOT NULL THEN CAST(IsDeleted AS VARCHAR(10)) ELSE 'NULL' END ,
					@IsArchive = ', ' + CASE WHEN IsArchive IS NOT NULL THEN CAST(IsArchive AS VARCHAR(10)) ELSE 'NULL' END ,
					@BackupSizeInMB = ', ' + CASE WHEN BackupSizeInMB IS NOT NULL THEN CAST(BackupSizeInMB AS VARCHAR(20)) ELSE 'NULL' END ,
					@BackupName = ', ' + CASE WHEN BackupName IS NOT NULL THEN '''' + BackupName + '''' ELSE 'NULL' END ,
					@BackupDescription = ', ' + CASE WHEN BackupDescription IS NOT NULL THEN '''' + REPLACE(BackupDescription, '''', '''''') + '''' ELSE 'NULL' END ,
					@ExpirationDate = ', ' + CASE WHEN ExpirationDate IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), ExpirationDate, 21) + '''' ELSE 'NULL' END ,
					@Compressed = ', ' + CASE WHEN Compressed IS NOT NULL THEN CAST(Compressed AS VARCHAR(10)) ELSE 'NULL' END ,
					@POSITION = ', ' + CASE WHEN POSITION IS NOT NULL THEN '''' + CAST(POSITION AS VARCHAR(10)) + '''' ELSE 'NULL' END ,
					@DeviceType = ', ' + CASE WHEN DeviceType IS NOT NULL THEN '''' + CAST(DeviceType AS VARCHAR(10)) + '''' ELSE 'NULL' END ,
					@UserName = ', ' + CASE WHEN UserName IS NOT NULL THEN '''' + UserName + '''' ELSE 'NULL' END ,
					@DatabaseName = ', ' + CASE WHEN DatabaseName IS NOT NULL THEN '''' + DatabaseName + '''' ELSE 'NULL' END ,
					@DatabaseVersion = ', ' + CASE WHEN DatabaseVersion IS NOT NULL THEN '''' + CAST(DatabaseVersion AS VARCHAR(20)) + '''' ELSE 'NULL' END ,
					@DatabaseCreationDate = ', ' + CASE WHEN DatabaseCreationDate IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), DatabaseCreationDate, 21) + ''''  ELSE 'NULL' END ,
					@BackupSizeInBytes = ', ' + CASE WHEN BackupSizeInBytes IS NOT NULL THEN CAST(BackupSizeInBytes AS VARCHAR(30)) ELSE 'NULL' END ,
					@FirstLSN = ', ' + CASE WHEN FirstLSN IS NOT NULL THEN '''' + FirstLSN + '''' ELSE 'NULL'  END ,
					@LastLSN = ', ' + CASE WHEN LastLSN IS NOT NULL THEN '''' + LastLSN + '''' ELSE 'NULL' END ,
					@CheckpointLSN = ', ' + CASE WHEN CheckpointLSN IS NOT NULL THEN '''' + CheckpointLSN + '''' ELSE 'NULL'  END ,
					@DatabaseBackupLSN = ', ' + CASE WHEN DatabaseBackupLSN IS NOT NULL THEN '''' + DatabaseBackupLSN + '''' ELSE 'NULL'  END ,
					@BackupStartDate = ', ' + CASE WHEN BackupStartDate IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), BackupStartDate, 21) + '''' ELSE 'NULL' END ,
					@BackupFinishDate = ', ' + CASE WHEN BackupFinishDate IS NOT NULL THEN '''' + CONVERT(VARCHAR(30), BackupFinishDate, 21) + '''' ELSE 'NULL' END ,
					@SortOrder = ', ' + CASE WHEN SortOrder IS NOT NULL THEN '''' + CAST(SortOrder AS VARCHAR(10)) + '''' ELSE 'NULL' END ,
					@CODEPAGE = ', ' + CASE WHEN CODEPAGE IS NOT NULL THEN '''' + CAST(CODEPAGE AS VARCHAR(10)) + '''' ELSE 'NULL' END ,
					@UnicodeLocaleId = ', ' + CASE WHEN UnicodeLocaleId IS NOT NULL THEN '''' + CAST(UnicodeLocaleId AS VARCHAR(10)) + '''' ELSE 'NULL' END ,
					@UnicodeComparisonStyle = ', ' + CASE WHEN UnicodeComparisonStyle IS NOT NULL THEN '''' + CAST(UnicodeComparisonStyle AS VARCHAR(10)) + ''''  ELSE 'NULL' END ,
					@CompatibilityLevel = ', ' + CASE WHEN CompatibilityLevel IS NOT NULL THEN '''' + CAST(CompatibilityLevel AS VARCHAR(10)) + '''' ELSE 'NULL' END ,
					@SoftwareVendorId = ', ' + CASE WHEN SoftwareVendorId IS NOT NULL THEN '''' + CAST(SoftwareVendorId AS VARCHAR(10)) + '''' ELSE 'NULL' END ,
					@SoftwareVersionMajor = ', ' + CASE WHEN SoftwareVersionMajor IS NOT NULL THEN '''' + CAST(SoftwareVersionMajor AS VARCHAR(10)) + '''' ELSE 'NULL' END ,
					@SoftwareVersionMinor = ', ' + CASE WHEN SoftwareVersionMinor IS NOT NULL THEN '''' + CAST(SoftwareVersionMinor AS VARCHAR(10)) + '''' ELSE 'NULL' END ,
					@SovtwareVersionBuild = ', ' + CASE WHEN SovtwareVersionBuild IS NOT NULL THEN '''' + CAST(SovtwareVersionBuild AS VARCHAR(10)) + ''''  ELSE 'NULL'  END ,
					@MachineName = ', ' + CASE WHEN MachineName IS NOT NULL THEN '''' + MachineName + '''' ELSE 'NULL' END ,
					@Flags = ', ' + CASE WHEN Flags IS NOT NULL THEN '''' + CAST(Flags AS VARCHAR(10))  + '''' ELSE 'NULL' END ,
					@BindingID = ', ' + CASE WHEN BindingID IS NOT NULL THEN '''' + BindingID + '''' ELSE 'NULL' END ,
					@RecoveryForkID = ', ' + CASE WHEN RecoveryForkID IS NOT NULL  THEN '''' + RecoveryForkID + '''' ELSE 'NULL'  END ,
					@COLLATION = ', ' + CASE WHEN COLLATION IS NOT NULL  THEN '''' + COLLATION + ''''  ELSE 'NULL'  END ,
					@FamilyGUID = ', ' + CASE WHEN FamilyGUID IS NOT NULL THEN '''' + FamilyGUID + '''' ELSE 'NULL' END ,
					@HasBulkLoggedData = ', ' + CASE WHEN HasBulkLoggedData IS NOT NULL THEN '''' + CAST(HasBulkLoggedData AS VARCHAR(10)) + '''' ELSE 'NULL' END ,
					@IsSnapshot = ', ' + CASE WHEN IsSnapshot IS NOT NULL THEN CAST(IsSnapshot AS VARCHAR(10)) ELSE 'NULL' END ,
					@IsReadOnly = ', ' + CASE WHEN IsReadOnly IS NOT NULL THEN CAST(IsReadOnly AS VARCHAR(10)) ELSE 'NULL' END ,
					@IsSingleUser = ', ' + CASE WHEN IsSingleUser IS NOT NULL THEN CAST(IsSingleUser AS VARCHAR(10)) ELSE 'NULL' END ,
					@HasBackupChecksums = ', ' + CASE WHEN HasBackupChecksums IS NOT NULL THEN CAST(HasBackupChecksums AS VARCHAR(10)) ELSE 'NULL'  END ,
					@IsDamaged = ', ' + CASE WHEN IsDamaged IS NOT NULL THEN CAST(IsDamaged AS VARCHAR(10)) ELSE 'NULL' END ,
					@BeginsLogChain = ', ' + CASE WHEN BeginsLogChain IS NOT NULL THEN CAST(BeginsLogChain AS VARCHAR(10)) ELSE 'NULL' END ,
					@HasIncompleteMeatdata = ', ' + CASE WHEN HasIncompleteMeatdata IS NOT NULL THEN CAST(HasIncompleteMeatdata AS VARCHAR(10)) ELSE 'NULL' END ,
					@IsForceOffline = ', ' + CASE WHEN IsForceOffline IS NOT NULL THEN CAST(IsForceOffline AS VARCHAR(10)) ELSE 'NULL' END ,
					@IsCopyOnly = ', ' + CASE WHEN IsCopyOnly IS NOT NULL THEN CAST(IsCopyOnly AS VARCHAR(10)) ELSE 'NULL' END ,
					@FirstRecoveryForkID = ', ' + CASE WHEN FirstRecoveryForkID IS NOT NULL THEN '''' + FirstRecoveryForkID + '''' ELSE 'NULL' END ,
					@ForkPointLSN = ', ' + CASE WHEN ForkPointLSN IS NOT NULL THEN '''' + ForkPointLSN + '''' ELSE 'NULL'  END ,
					@RecoveryModel = ', ' + CASE WHEN RecoveryModel IS NOT NULL THEN '''' + RecoveryModel + '''' ELSE 'NULL' END ,
					@DifferentialBaseLSN = ', ' + CASE WHEN DifferentialBaseLSN IS NOT NULL THEN '''' + DifferentialBaseLSN + '''' ELSE 'NULL' END ,
					@DifferentialBaseGUID = ', ' + CASE WHEN DifferentialBaseGUID IS NOT NULL THEN '''' + DifferentialBaseGUID + '''' ELSE 'NULL' END ,
					@BackupTypeDescription = ', ' + CASE WHEN BackupTypeDescription IS NOT NULL THEN '''' + REPLACE(BackupTypeDescription, '''', '''''') + '''' ELSE 'NULL' END ,
					@BackupSetGUID = ', ' + CASE WHEN BackupSetGUID IS NOT NULL THEN '''' + BackupSetGUID + '''' ELSE 'NULL' END ,
					@CompressedBackupSize = ', ' + CASE WHEN CompressedBackupSize IS NOT NULL THEN '''' + CAST(CompressedBackupSize AS VARCHAR(30)) + '''' ELSE 'NULL' END ,
					@CONTAINMENT = ', ' + CASE WHEN CONTAINMENT IS NOT NULL THEN '''' + CAST(CONTAINMENT AS VARCHAR(10)) + '''' ELSE 'NULL' END
			FROM	#BackupFiles
			WHERE	ID = @i

			--SELECT	@BatchPreCode
			INSERT	Minion.SyncCmds
					( ExecutionDateTime ,
					  Module ,
					  Status ,
					  ObjectName ,
					  Op ,
					  Cmd ,
					  Pushed ,
					  Attempts
					)
					SELECT	@ExecutionDateTime ,
							'Backup' ,
							'In queue' ,
							'BackupFiles' ,
							'INSERT' ,
							( 'INSERT Minion.BackupFiles (ExecutionDateTime, Op, Status, DBName, ServerLabel, NETBIOSName, BackupType, BackupLocType, BackupDrive, BackupPath, FullPath, FullFileName, FileName, DateLogic, Extension, RetHrs, IsMirror, ToBeDeleted, DeleteDateTime, IsDeleted, IsArchive, BackupSizeInMB, BackupName, BackupDescription, ExpirationDate, Compressed, POSITION, DeviceType, UserName, DatabaseName, DatabaseVersion, DatabaseCreationDate, BackupSizeInBytes, FirstLSN, LastLSN, CheckpointLSN, DatabaseBackupLSN, BackupStartDate, BackupFinishDate, SortOrder, CODEPAGE, UnicodeLocaleId, UnicodeComparisonStyle, CompatibilityLevel, SoftwareVendorId, SoftwareVersionMajor, SoftwareVersionMinor, SovtwareVersionBuild, MachineName, Flags, BindingID, RecoveryForkID, COLLATION, FamilyGUID, HasBulkLoggedData, IsSnapshot, IsReadOnly, IsSingleUser, HasBackupChecksums, IsDamaged, BeginsLogChain, HasIncompleteMeatdata, IsForceOffline, IsCopyOnly, FirstRecoveryForkID, ForkPointLSN, RecoveryModel, DifferentialBaseLSN, DifferentialBaseGUID, BackupTypeDescription, BackupSetGUID, CompressedBackupSize, CONTAINMENT) SELECT '
							  + @ExecutionBeginDateTime + @Op + @STATUS
							  + @DBName + @ServerLabel + @NETBIOSName
							  + @BackupType + @BackupLocType + @BackupDrive
							  + @BackupPath + @FullPath + @FullFileName
							  + @FileName + @DateLogic + @Extension + @RetHrs
							  + @IsMirror + @ToBeDeleted + @DeleteDateTime
							  + @IsDeleted + @IsArchive + @BackupSizeInMB
							  + @BackupName + @BackupDescription
							  + @ExpirationDate + @Compressed + @POSITION
							  + @DeviceType + @UserName + @DatabaseName
							  + @DatabaseVersion + @DatabaseCreationDate
							  + @BackupSizeInBytes + @FirstLSN + @LastLSN
							  + @CheckpointLSN + @DatabaseBackupLSN
							  + @BackupStartDate + @BackupFinishDate
							  + @SortOrder + @CODEPAGE + @UnicodeLocaleId
							  + @UnicodeComparisonStyle + @CompatibilityLevel
							  + @SoftwareVendorId + @SoftwareVersionMajor
							  + @SoftwareVersionMinor + @SovtwareVersionBuild
							  + @MachineName + @Flags + @BindingID
							  + @RecoveryForkID + @COLLATION + @FamilyGUID
							  + @HasBulkLoggedData + @IsSnapshot + @IsReadOnly
							  + @IsSingleUser + @HasBackupChecksums
							  + @IsDamaged + @BeginsLogChain
							  + @HasIncompleteMeatdata + @IsForceOffline
							  + @IsCopyOnly + @FirstRecoveryForkID
							  + @ForkPointLSN + @RecoveryModel
							  + @DifferentialBaseLSN + @DifferentialBaseGUID
							  + @BackupTypeDescription + @BackupSetGUID
							  + @CompressedBackupSize + @CONTAINMENT ) ,
							0 ,
							0;

			SET @i = @i + 1
		END

	DROP TABLE #BackupFiles;
-------------------------------------------------------------------------
--------------------END BackupFiles--------------------------------------
-------------------------------------------------------------------------


GO
