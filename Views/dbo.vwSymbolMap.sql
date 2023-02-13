SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vwSymbolMap]
WITH SCHEMABINDING
AS
SELECT        symbol, bbsecurity, ts_start AS ts
FROM            dbo.SymbolMap
WHERE        (ts_end IS NULL)
GO
CREATE UNIQUE CLUSTERED INDEX [ClusteredIndex-20200827-155237] ON [dbo].[vwSymbolMap] ([symbol]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
