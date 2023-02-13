SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- dbo.vwSymbolMap

CREATE VIEW [dbo].[vwTICKDB_SYMBOL]
--   WITH SCHEMABINDING
AS
SELECT        vSM.symbol, TT.bbsecurity, TT.type, TT.src, TT.value, TT.delayed, TT.markethours, TT.tsbb, TT.ts, TT.lag, TT.tsdiff
FROM            dbo.vwTICKDB_TYPE AS TT INNER JOIN
                         dbo.vwSymbolMap AS vSM ON TT.bbsecurity = vSM.bbsecurity
GO
