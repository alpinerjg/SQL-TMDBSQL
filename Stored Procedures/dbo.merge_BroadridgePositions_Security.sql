SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[merge_BroadridgePositions_Security] 
     @Timestamp DateTime
AS
BEGIN
BEGIN TRANSACTION merge_BroadridgePositions_Scrty
UPDATE t1 
SET t1.ts_end = @Timestamp
FROM [TMDBSQL].[dbo].[BroadridgePositionsSecurity] t1
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

INSERT INTO [dbo].[BroadridgePositionsSecurity]
(
	[Security_Currency_Currency_Ccy],
	[Security_Currency_Currency_CurrencyID],
	[Security_Security_BloombergGlobalId],
	[Security_Security_BloombergID],
	[Security_Security_Code],
	[Security_Security_ConversionRatio],
	[Security_Security_Name],
	[Security_Security_SecurityID],
	[Security_Security_Ticker],
	[Security_Type_SecurityType_Name],
	[Security_Underlying_Security_Code],
	[ts_end],
	[ts_start],
	[UniqKey],
	[UserName]
)
SELECT
	[Security_Currency_Currency_Ccy],
	[Security_Currency_Currency_CurrencyID],
	[Security_Security_BloombergGlobalId],
	[Security_Security_BloombergID],
	[Security_Security_Code],
	[Security_Security_ConversionRatio],
	[Security_Security_Name],
	[Security_Security_SecurityID],
	[Security_Security_Ticker],
	[Security_Type_SecurityType_Name],
	[Security_Underlying_Security_Code],
	[ts_end],
	[ts_start],
	[UniqKey],
	[UserName]
FROM
(
	MERGE [dbo].[BroadridgePositionsSecurity] WITH (HOLDLOCK) as [target]
	USING
	(
		SELECT
			[Security_Currency_Currency_Ccy],
			[Security_Currency_Currency_CurrencyID],
			[Security_Security_BloombergGlobalId],
			[Security_Security_BloombergID],
			[Security_Security_Code],
			[Security_Security_ConversionRatio],
			[Security_Security_Name],
			[Security_Security_SecurityID],
			[Security_Security_Ticker],
			[Security_Type_SecurityType_Name],
			[Security_Underlying_Security_Code],
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
		[Security_Currency_Currency_Ccy],
		[Security_Currency_Currency_CurrencyID],
		[Security_Security_BloombergGlobalId],
		[Security_Security_BloombergID],
		[Security_Security_Code],
		[Security_Security_ConversionRatio],
		[Security_Security_Name],
		[Security_Security_SecurityID],
		[Security_Security_Ticker],
		[Security_Type_SecurityType_Name],
		[Security_Underlying_Security_Code],
		[ts_end],
		[ts_start],
		[UniqKey],
		[UserName]
	)
	VALUES
	(
		[Security_Currency_Currency_Ccy],
		[Security_Currency_Currency_CurrencyID],
		[Security_Security_BloombergGlobalId],
		[Security_Security_BloombergID],
		[Security_Security_Code],
		[Security_Security_ConversionRatio],
		[Security_Security_Name],
		[Security_Security_SecurityID],
		[Security_Security_Ticker],
		[Security_Type_SecurityType_Name],
		[Security_Underlying_Security_Code],
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
	([target].[Security_Currency_Currency_Ccy] <> [source].[Security_Currency_Currency_Ccy] OR ([target].[Security_Currency_Currency_Ccy] IS NULL AND [source].[Security_Currency_Currency_Ccy] IS NOT NULL) OR ([target].[Security_Currency_Currency_Ccy] IS NOT NULL AND [source].[Security_Currency_Currency_Ccy] IS NULL)) OR
	([target].[Security_Currency_Currency_CurrencyID] <> [source].[Security_Currency_Currency_CurrencyID] OR ([target].[Security_Currency_Currency_CurrencyID] IS NULL AND [source].[Security_Currency_Currency_CurrencyID] IS NOT NULL) OR ([target].[Security_Currency_Currency_CurrencyID] IS NOT NULL AND [source].[Security_Currency_Currency_CurrencyID] IS NULL)) OR
	([target].[Security_Security_BloombergGlobalId] <> [source].[Security_Security_BloombergGlobalId] OR ([target].[Security_Security_BloombergGlobalId] IS NULL AND [source].[Security_Security_BloombergGlobalId] IS NOT NULL) OR ([target].[Security_Security_BloombergGlobalId] IS NOT NULL AND [source].[Security_Security_BloombergGlobalId] IS NULL)) OR
	([target].[Security_Security_BloombergID] <> [source].[Security_Security_BloombergID] OR ([target].[Security_Security_BloombergID] IS NULL AND [source].[Security_Security_BloombergID] IS NOT NULL) OR ([target].[Security_Security_BloombergID] IS NOT NULL AND [source].[Security_Security_BloombergID] IS NULL)) OR
	([target].[Security_Security_Code] <> [source].[Security_Security_Code] OR ([target].[Security_Security_Code] IS NULL AND [source].[Security_Security_Code] IS NOT NULL) OR ([target].[Security_Security_Code] IS NOT NULL AND [source].[Security_Security_Code] IS NULL)) OR
	([target].[Security_Security_ConversionRatio] <> [source].[Security_Security_ConversionRatio] OR ([target].[Security_Security_ConversionRatio] IS NULL AND [source].[Security_Security_ConversionRatio] IS NOT NULL) OR ([target].[Security_Security_ConversionRatio] IS NOT NULL AND [source].[Security_Security_ConversionRatio] IS NULL)) OR
	([target].[Security_Security_Name] <> [source].[Security_Security_Name] OR ([target].[Security_Security_Name] IS NULL AND [source].[Security_Security_Name] IS NOT NULL) OR ([target].[Security_Security_Name] IS NOT NULL AND [source].[Security_Security_Name] IS NULL)) OR
	([target].[Security_Security_SecurityID] <> [source].[Security_Security_SecurityID] OR ([target].[Security_Security_SecurityID] IS NULL AND [source].[Security_Security_SecurityID] IS NOT NULL) OR ([target].[Security_Security_SecurityID] IS NOT NULL AND [source].[Security_Security_SecurityID] IS NULL)) OR
	([target].[Security_Security_Ticker] <> [source].[Security_Security_Ticker] OR ([target].[Security_Security_Ticker] IS NULL AND [source].[Security_Security_Ticker] IS NOT NULL) OR ([target].[Security_Security_Ticker] IS NOT NULL AND [source].[Security_Security_Ticker] IS NULL)) OR
	([target].[Security_Type_SecurityType_Name] <> [source].[Security_Type_SecurityType_Name] OR ([target].[Security_Type_SecurityType_Name] IS NULL AND [source].[Security_Type_SecurityType_Name] IS NOT NULL) OR ([target].[Security_Type_SecurityType_Name] IS NOT NULL AND [source].[Security_Type_SecurityType_Name] IS NULL)) OR
	([target].[Security_Underlying_Security_Code] <> [source].[Security_Underlying_Security_Code] OR ([target].[Security_Underlying_Security_Code] IS NULL AND [source].[Security_Underlying_Security_Code] IS NOT NULL) OR ([target].[Security_Underlying_Security_Code] IS NOT NULL AND [source].[Security_Underlying_Security_Code] IS NULL))

)
	THEN UPDATE
	SET
		[ts_end] = @TimeStamp


	OUTPUT
		$Action as [MERGE_ACTION_3297e627-5591-41d5-8192-5d66b41006c9],
		[source].[Security_Currency_Currency_Ccy] AS [Security_Currency_Currency_Ccy],
		[source].[Security_Currency_Currency_CurrencyID] AS [Security_Currency_Currency_CurrencyID],
		[source].[Security_Security_BloombergGlobalId] AS [Security_Security_BloombergGlobalId],
		[source].[Security_Security_BloombergID] AS [Security_Security_BloombergID],
		[source].[Security_Security_Code] AS [Security_Security_Code],
		[source].[Security_Security_ConversionRatio] AS [Security_Security_ConversionRatio],
		[source].[Security_Security_Name] AS [Security_Security_Name],
		[source].[Security_Security_SecurityID] AS [Security_Security_SecurityID],
		[source].[Security_Security_Ticker] AS [Security_Security_Ticker],
		[source].[Security_Type_SecurityType_Name] AS [Security_Type_SecurityType_Name],
		[source].[Security_Underlying_Security_Code] AS [Security_Underlying_Security_Code],
		NULL AS [ts_end],
		@TimeStamp AS [ts_start],
		[source].[UniqKey] AS [UniqKey],
		[source].[UserName] AS [UserName]

)MERGE_OUTPUT
WHERE MERGE_OUTPUT.[MERGE_ACTION_3297e627-5591-41d5-8192-5d66b41006c9] = 'UPDATE' 
	AND MERGE_OUTPUT.[UniqKey] IS NOT NULL
	AND MERGE_OUTPUT.[UserName] IS NOT NULL
;
COMMIT TRANSACTION merge_BroadridgePositions_Scrty
END
GO
