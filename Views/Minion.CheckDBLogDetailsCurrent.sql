SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Minion].[CheckDBLogDetailsCurrent]
AS
       SELECT   *
       FROM     Minion.CheckDBLogDetails
       WHERE    ExecutionDateTime IN ( SELECT   MAX(ExecutionDateTime)
                                       FROM     Minion.CheckDBLogDetails );
GO
