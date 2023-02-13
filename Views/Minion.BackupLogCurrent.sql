SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Minion].[BackupLogCurrent]
AS
       SELECT   *
       FROM     Minion.BackupLog
       WHERE    ExecutionDateTime IN ( SELECT   MAX(ExecutionDateTime)
                                       FROM     Minion.BackupLog);

GO
