SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[merge_BroadridgePositions_Other] 
     @Timestamp DateTime
AS
BEGIN
BEGIN TRANSACTION merge_BroadridgePositions_Other
UPDATE t1 
SET t1.ts_end = @Timestamp
FROM [TMDBSQL].[dbo].[BroadridgePositionsOther] t1
LEFT JOIN [TMDBSQL].[dbo].[BroadridgePositions_staging] t2 ON t2.UserName = t1.UserName AND t2.[UniqKey] = t1.[UniqKey] 
WHERE t1.ts_end IS NULL and t2.[UniqKey] IS NULL

-- ==================================================
-- Slowly Changing Dimension script by SCD Merge Wizard
-- Author: Miljan Radovic
-- Official web site: https://github.com/SQLPlayer/SCD-Merge-Wizard/
-- Version: 4.3.0.0
-- Publish date: 4/7/2021 4:51:57 PM
-- Script creation date: 4/7/2021 8:57:31 PM
-- ==================================================


-- ==================================================
-- SCD2
-- ==================================================
INSERT INTO [dbo].[BroadridgePositionsOther]
(
	[Custodian_TradeCpty_TradeCptyName],
	[Fund_Currency_Currency_CurrencyID],
	[Fund_TradeFund_Name],
	[Total_Position_Calculated_PositionCash],
	[ts_end],
	[ts_start],
	[UniqKey],
	[UserName]
)
SELECT
	[Custodian_TradeCpty_TradeCptyName],
	[Fund_Currency_Currency_CurrencyID],
	[Fund_TradeFund_Name],
	[Total_Position_Calculated_PositionCash],
	[ts_end],
	[ts_start],
	[UniqKey],
	[UserName]
FROM
(
	MERGE [dbo].[BroadridgePositionsOther] WITH (HOLDLOCK) as [target]
	USING
	(
		SELECT
			[Custodian_TradeCpty_TradeCptyName],
			[Fund_Currency_Currency_CurrencyID],
			[Fund_TradeFund_Name],
			[Total_Position_Calculated_PositionCash],
			[UniqKey],
			[UserName]
		FROM [dbo].[BroadridgePositions_staging]

	) as [source]
	ON
	(
		[source].[UniqKey] = [target].[UniqKey] AND
		[source].[UserName] = [target].[UserName]
	)

	WHEN NOT MATCHED BY TARGET
	THEN INSERT
	(
		[Custodian_TradeCpty_TradeCptyName],
		[Fund_Currency_Currency_CurrencyID],
		[Fund_TradeFund_Name],
		[Total_Position_Calculated_PositionCash],
		[ts_end],
		[ts_start],
		[UniqKey],
		[UserName]
	)
	VALUES
	(
		[Custodian_TradeCpty_TradeCptyName],
		[Fund_Currency_Currency_CurrencyID],
		[Fund_TradeFund_Name],
		[Total_Position_Calculated_PositionCash],
		NULL,
		@TimeStamp,
		[UniqKey],
		[UserName]
	)


WHEN MATCHED AND
(
	[ts_end] = NULL
)
AND
(
	([target].[Custodian_TradeCpty_TradeCptyName] <> [source].[Custodian_TradeCpty_TradeCptyName] OR ([target].[Custodian_TradeCpty_TradeCptyName] IS NULL AND [source].[Custodian_TradeCpty_TradeCptyName] IS NOT NULL) OR ([target].[Custodian_TradeCpty_TradeCptyName] IS NOT NULL AND [source].[Custodian_TradeCpty_TradeCptyName] IS NULL)) OR
	([target].[Fund_Currency_Currency_CurrencyID] <> [source].[Fund_Currency_Currency_CurrencyID] OR ([target].[Fund_Currency_Currency_CurrencyID] IS NULL AND [source].[Fund_Currency_Currency_CurrencyID] IS NOT NULL) OR ([target].[Fund_Currency_Currency_CurrencyID] IS NOT NULL AND [source].[Fund_Currency_Currency_CurrencyID] IS NULL)) OR
	([target].[Fund_TradeFund_Name] <> [source].[Fund_TradeFund_Name] OR ([target].[Fund_TradeFund_Name] IS NULL AND [source].[Fund_TradeFund_Name] IS NOT NULL) OR ([target].[Fund_TradeFund_Name] IS NOT NULL AND [source].[Fund_TradeFund_Name] IS NULL)) OR
	([target].[Total_Position_Calculated_PositionCash] <> [source].[Total_Position_Calculated_PositionCash] OR ([target].[Total_Position_Calculated_PositionCash] IS NULL AND [source].[Total_Position_Calculated_PositionCash] IS NOT NULL) OR ([target].[Total_Position_Calculated_PositionCash] IS NOT NULL AND [source].[Total_Position_Calculated_PositionCash] IS NULL))

)
	THEN UPDATE
	SET
		[ts_end] = @TimeStamp


	OUTPUT
		$Action as [MERGE_ACTION_fb87bbfa-782a-4172-be1c-c4b412da44e5],
		[source].[Custodian_TradeCpty_TradeCptyName] AS [Custodian_TradeCpty_TradeCptyName],
		[source].[Fund_Currency_Currency_CurrencyID] AS [Fund_Currency_Currency_CurrencyID],
		[source].[Fund_TradeFund_Name] AS [Fund_TradeFund_Name],
		[source].[Total_Position_Calculated_PositionCash] AS [Total_Position_Calculated_PositionCash],
		NULL AS [ts_end],
		@TimeStamp AS [ts_start],
		[source].[UniqKey] AS [UniqKey],
		[source].[UserName] AS [UserName]

)MERGE_OUTPUT
WHERE MERGE_OUTPUT.[MERGE_ACTION_fb87bbfa-782a-4172-be1c-c4b412da44e5] = 'UPDATE' 
	AND MERGE_OUTPUT.[UniqKey] IS NOT NULL
	AND MERGE_OUTPUT.[UserName] IS NOT NULL
;
COMMIT TRANSACTION merge_BroadridgePositions_Other
END
GO
