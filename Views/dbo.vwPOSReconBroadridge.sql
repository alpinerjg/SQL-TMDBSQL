SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE VIEW [dbo].[vwPOSReconBroadridge]
AS
SELECT CONCAT(CustomAccount,'|',CustomStrategyCode,'|',CustomTickerSort) as UniqKey,CustomAccount as account,CustomStrategyCode strategy,CustomTickerSort as symbol, Position_Calculated_PositionValue as daypos FROM [TMDBSQL].[dbo].[vwBroadridgePositions] B
LEFT JOIN TMWACCTDB A
ON A.account = B.CustomAccount
WHERE (A.active = 'Y') and (A.test = 'N') and B.ts_end IS NULL
GO
