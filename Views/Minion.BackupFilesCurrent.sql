SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Minion].[BackupFilesCurrent]
AS
       SELECT   *
       FROM     Minion.BackupFiles
       WHERE    ExecutionDateTime IN ( SELECT   MAX(ExecutionDateTime)
                                       FROM     Minion.BackupFiles);
GO
