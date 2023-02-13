SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Minion].[IndexMaintLogDetailsCurrent]
AS
/* This view provides a look at the latest reindex batch. 

	Use: 
	SELECT * FROM Minion.IndexMaintLogDetailsCurrent
	ORDER BY ExecutionDateTime, DBName, SchemaName, TableName;
*/
SELECT
    --CASE WHEN ISNULL(PctComplete, 0) IN ( 0, 100 ) THEN NULL
    --                 ELSE DATEDIFF(SECOND, BackupStartDateTime, GETDATE())
    --            END AS [EstRemainingSec]
    --          , CASE WHEN ISNULL(PctComplete, 0) NOT IN ( 0, 100 )
    --                 THEN DATEDIFF(SECOND, BackupStartDateTime, GETDATE())
    --                      * 100 / PctComplete
    --                 ELSE NULL
    --            END AS [EstTotalSec]
    --          , CASE WHEN ISNULL(PctComplete, 0) NOT IN ( 0, 100 )
    --                 THEN DATEADD(SECOND,
    --                              DATEDIFF(SECOND, BackupStartDateTime,
    --                                       GETDATE()) * 100 / PctComplete,
    --                              BackupStartDateTime)
    --                 ELSE NULL
    --            END AS [EstCompleteTime]
    ID,
    ExecutionDateTime,
    Status,
    DBName,
    TableID,
    SchemaName,
    TableName,
    IndexID,
    IndexName,
    IndexTypeDesc,
    IndexScanMode,
    Op,
    ONLINEopt,
    ReorgThreshold,
    RebuildThreshold,
    FILLFACTORopt,
    PadIndex,
    FragLevel,
    Stmt,
    ReindexGroupOrder,
    ReindexOrder,
    PreCode,
    PostCode,
    OpBeginDateTime,
    OpEndDateTime,
    OpRunTimeInSecs,
    TableRowCTBeginDateTime,
    TableRowCTEndDateTime,
    TableRowCTTimeInSecs,
    TableRowCT,
    PostFragBeginDateTime,
    PostFragEndDateTime,
    PostFragTimeInSecs,
    PostFragLevel,
    UpdateStatsBeginDateTime,
    UpdateStatsEndDateTime,
    UpdateStatsTimeInSecs,
    UpdateStatsStmt,
    PreCodeBeginDateTime,
    PreCodeEndDateTime,
    PreCodeRunTimeInSecs,
    PostCodeBeginDateTime,
    PostCodeEndDateTime,
    PostCodeRunTimeInSecs,
    UserSeeks,
    UserScans,
    UserLookups,
    UserUpdates,
    LastUserSeek,
    LastUserScan,
    LastUserLookup,
    LastUserUpdate,
    SystemSeeks,
    SystemScans,
    SystemLookups,
    SystemUpdates,
    LastSystemSeek,
    LastSystemScan,
    LastSystemLookup,
    LastSystemUpdate,
    Warnings
FROM Minion.IndexMaintLogDetails ID1
WHERE ExecutionDateTime IN
      (
          SELECT MAX(ID2.ExecutionDateTime)
          FROM Minion.IndexMaintLogDetails ID2
          WHERE ID1.DBName = ID2.DBName
      );


GO
