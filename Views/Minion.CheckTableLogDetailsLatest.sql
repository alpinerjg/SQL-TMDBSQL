SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Minion].[CheckTableLogDetailsLatest]
AS
--Gets the latest checkdb run for each DB. This is different from the Current view
--in that the Current view gets the latest run regardless of what was in it.
--Here we're interested in the last time a DB was run.
       SELECT   *
       FROM     Minion.CheckDBLogDetails CLD1
       WHERE    ExecutionDateTime IN ( SELECT   MAX(CLD2.ExecutionDateTime)
                                       FROM     Minion.CheckDBLogDetails CLD2 WHERE CLD1.DBName = CLD2.DBName AND UPPER(CLD2.OpName) = 'CHECKTABLE' AND STATUS LIKE 'Complete%');





GO
