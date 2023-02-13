SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Minion].[BackupLogDetailsCurrent]
AS
       SELECT   *
       FROM     Minion.BackupLogDetails
       WHERE    ExecutionDateTime IN ( SELECT   MAX(ExecutionDateTime)
                                       FROM     Minion.BackupLogDetails );

GO
