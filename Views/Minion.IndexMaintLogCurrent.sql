SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [Minion].[IndexMaintLogCurrent]
AS
/* This view provides a look at the latest reindex batch. 

	Use: 
	SELECT * FROM Minion.IndexMaintLogCurrent
	ORDER BY ExecutionDateTime, DBName;

	SELECT * FROM Minion.IndexMaintLogCurrent
	ORDER BY DBName;
*/
SELECT I1.ID,
    I1.ExecutionDateTime,
    I1.Status,
    I1.DBName,
    I1.Tables,
    I1.RunPrepped,
    I1.PrepOnly,
    I1.ReorgMode,
    I1.NumTablesProcessed,
    I1.NumIndexesProcessed,
    I1.NumIndexesRebuilt,
    I1.NumIndexesReorged,
    I1.RecoveryModelChanged,
    I1.RecoveryModelCurrent,
    I1.RecoveryModelReindex,
    I1.SQLVersion,
    I1.SQLEdition,
    I1.DBPreCode,
    I1.DBPostCode,
    I1.DBPreCodeBeginDateTime,
    I1.DBPreCodeEndDateTime,
    I1.DBPostCodeBeginDateTime,
    I1.DBPostCodeEndDateTime,
    I1.DBPreCodeRunTimeInSecs,
    I1.DBPostCodeRunTimeInSecs,
    I1.ExecutionFinishTime,
    I1.ExecutionRunTimeInSecs,
    I1.IncludeDBs,
    I1.ExcludeDBs,
    I1.RegexDBsIncluded,
    I1.RegexDBsExcluded,
    I1.Warnings
FROM Minion.IndexMaintLog I1
WHERE ExecutionDateTime IN
      (
          SELECT MAX(I2.ExecutionDateTime)
          FROM Minion.IndexMaintLog I2
          WHERE I1.DBName = I2.DBName
      );


GO
