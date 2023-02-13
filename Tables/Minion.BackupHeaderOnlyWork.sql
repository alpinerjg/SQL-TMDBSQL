CREATE TABLE [Minion].[BackupHeaderOnlyWork]
(
[ExecutionDateTime] [datetime] NULL,
[DBName] [sys].[sysname] NULL,
[BT] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BackupName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BackupDescription] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BackupType] [tinyint] NULL,
[ExpirationDate] [datetime] NULL,
[Compressed] [bit] NULL,
[POSITION] [tinyint] NULL,
[DeviceType] [tinyint] NULL,
[UserName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerLabel] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DatabaseName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DatabaseVersion] [int] NULL,
[DatabaseCreationDate] [datetime] NULL,
[BackupSize] [bigint] NULL,
[FirstLSN] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastLSN] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CheckpointLSN] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DatabaseBackupLSN] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BackupStartDate] [datetime] NULL,
[BackupFinishDate] [datetime] NULL,
[SortOrder] [int] NULL,
[CODEPAGE] [int] NULL,
[UnicodeLocaleId] [int] NULL,
[UnicodeComparisonStyle] [int] NULL,
[CompatibilityLevel] [int] NULL,
[SoftwareVendorId] [int] NULL,
[SoftwareVersionMajor] [int] NULL,
[SoftwareVersionMinor] [int] NULL,
[SovtwareVersionBuild] [int] NULL,
[MachineName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Flags] [int] NULL,
[BindingID] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RecoveryForkID] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COLLATION] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FamilyGUID] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HasBulkLoggedData] [bit] NULL,
[IsSnapshot] [bit] NULL,
[IsReadOnly] [bit] NULL,
[IsSingleUser] [bit] NULL,
[HasBackupChecksums] [bit] NULL,
[IsDamaged] [bit] NULL,
[BeginsLogChain] [bit] NULL,
[HasIncompleteMeatdata] [bit] NULL,
[IsForceOffline] [bit] NULL,
[IsCopyOnly] [bit] NULL,
[FirstRecoveryForkID] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ForkPointLSN] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RecoveryModel] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DifferentialBaseLSN] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DifferentialBaseGUID] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BackupTypeDescription] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BackupSetGUID] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CompressedBackupSize] [bigint] NULL,
[CONTAINMENT] [tinyint] NULL,
[KeyAlgorithm] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EncryptorThumbprint] [varbinary] (20) NULL,
[EncryptorType] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
