SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[vwTMWPOSDB]
AS

SELECT CONCAT(P.account,'|',P.strategy,'|',P.symbol) as UniqKey,P.* FROM TMWPOSDB P
LEFT JOIN TMWACCTDB A
ON A.account = P.account
WHERE (A.active = 'Y') and (A.test = 'N') and P.ts_end IS NULL

GO
