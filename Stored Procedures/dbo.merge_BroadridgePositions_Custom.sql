SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[merge_BroadridgePositions_Custom] 
     @Timestamp DateTime

	 AS
BEGIN
   SET NOCOUNT ON
    SET XACT_ABORT ON

	IF (@Timestamp is NULL)
	BEGIN
		SET @Timestamp = GETDATE()
	END

BEGIN TRANSACTION trans_BroadridgePositions_Custom

	UPDATE t1 
	SET t1.ts_end = @Timestamp
	FROM [TMDBSQL].[dbo].[BroadridgePositionsCustom] t1
	LEFT JOIN [TMDBSQL].[dbo].[BroadridgePositions_staging] t2 ON t2.UserName = t1.UserName AND t2.[UniqKey] = t1.[UniqKey] 
	WHERE t1.ts_end IS NULL and t2.[UniqKey] IS NULL

	-- ==================================================
	-- Slowly Changing Dimension script by SCD Merge Wizard
	-- Author: Miljan Radovic
	-- Official web site: https://github.com/SQLPlayer/SCD-Merge-Wizard/
	-- Version: 4.3.0.0
	-- Publish date: 4/8/2021 9:05:16 AM
	-- Script creation date: 4/8/2021 4:05:04 PM
	-- ==================================================

	-- ==================================================
	-- SCD2
	-- ==================================================
	INSERT INTO [dbo].[BroadridgePositionsCustom]
	(
		[CustomAccount],
		[CustomBloombergID],
		[CustomFundName],
		[CustomFundSort],
		[CustomPartnershipID],
		[CustomRiskCategoryCode],
		[CustomStrategyCode],
		[CustomTicker],
		[CustomTickerSort],
		[ts_end],
		[ts_start],
		[UniqKey],
		[UserName]
	)
	SELECT
		[CustomAccount],
		[CustomBloombergID],
		[CustomFundName],
		[CustomFundSort],
		[CustomPartnershipID],
		[CustomRiskCategoryCode],
		[CustomStrategyCode],
		[CustomTicker],
		[CustomTickerSort],
		[ts_end],
		[ts_start],
		[UniqKey],
		[UserName]
	FROM
	(
		MERGE [dbo].[BroadridgePositionsCustom] WITH (HOLDLOCK) as [target]
		USING
		(
			SELECT
				[CustomAccount],
				[CustomBloombergID],
				[CustomFundName],
				[CustomFundSort],
				[CustomPartnershipID],
				[CustomRiskCategoryCode],
				[CustomStrategyCode],
				[CustomTicker],
				[CustomTickerSort],
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
			[CustomAccount],
			[CustomBloombergID],
			[CustomFundName],
			[CustomFundSort],
			[CustomPartnershipID],
			[CustomRiskCategoryCode],
			[CustomStrategyCode],
			[CustomTicker],
			[CustomTickerSort],
			[ts_end],
			[ts_start],
			[UniqKey],
			[UserName]
		)
		VALUES
		(
			[CustomAccount],
			[CustomBloombergID],
			[CustomFundName],
			[CustomFundSort],
			[CustomPartnershipID],
			[CustomRiskCategoryCode],
			[CustomStrategyCode],
			[CustomTicker],
			[CustomTickerSort],
			NULL,
			@TimeStamp,
			[UniqKey],
			[UserName]
		)


	WHEN MATCHED AND
	(
		[ts_start] = NULL
	)
	AND
	(
		([target].[CustomAccount] <> [source].[CustomAccount] OR ([target].[CustomAccount] IS NULL AND [source].[CustomAccount] IS NOT NULL) OR ([target].[CustomAccount] IS NOT NULL AND [source].[CustomAccount] IS NULL)) OR
		([target].[CustomBloombergID] <> [source].[CustomBloombergID] OR ([target].[CustomBloombergID] IS NULL AND [source].[CustomBloombergID] IS NOT NULL) OR ([target].[CustomBloombergID] IS NOT NULL AND [source].[CustomBloombergID] IS NULL)) OR
		([target].[CustomFundName] <> [source].[CustomFundName] OR ([target].[CustomFundName] IS NULL AND [source].[CustomFundName] IS NOT NULL) OR ([target].[CustomFundName] IS NOT NULL AND [source].[CustomFundName] IS NULL)) OR
		([target].[CustomFundSort] <> [source].[CustomFundSort] OR ([target].[CustomFundSort] IS NULL AND [source].[CustomFundSort] IS NOT NULL) OR ([target].[CustomFundSort] IS NOT NULL AND [source].[CustomFundSort] IS NULL)) OR
		([target].[CustomPartnershipID] <> [source].[CustomPartnershipID] OR ([target].[CustomPartnershipID] IS NULL AND [source].[CustomPartnershipID] IS NOT NULL) OR ([target].[CustomPartnershipID] IS NOT NULL AND [source].[CustomPartnershipID] IS NULL)) OR
		([target].[CustomRiskCategoryCode] <> [source].[CustomRiskCategoryCode] OR ([target].[CustomRiskCategoryCode] IS NULL AND [source].[CustomRiskCategoryCode] IS NOT NULL) OR ([target].[CustomRiskCategoryCode] IS NOT NULL AND [source].[CustomRiskCategoryCode] IS NULL)) OR
		([target].[CustomStrategyCode] <> [source].[CustomStrategyCode] OR ([target].[CustomStrategyCode] IS NULL AND [source].[CustomStrategyCode] IS NOT NULL) OR ([target].[CustomStrategyCode] IS NOT NULL AND [source].[CustomStrategyCode] IS NULL)) OR
		([target].[CustomTicker] <> [source].[CustomTicker] OR ([target].[CustomTicker] IS NULL AND [source].[CustomTicker] IS NOT NULL) OR ([target].[CustomTicker] IS NOT NULL AND [source].[CustomTicker] IS NULL)) OR
		([target].[CustomTickerSort] <> [source].[CustomTickerSort] OR ([target].[CustomTickerSort] IS NULL AND [source].[CustomTickerSort] IS NOT NULL) OR ([target].[CustomTickerSort] IS NOT NULL AND [source].[CustomTickerSort] IS NULL))

	)
		THEN UPDATE
		SET
			[ts_start] = @TimeStamp

		OUTPUT
			$Action as [MERGE_ACTION_46006962-52b1-4124-bdb0-426c628f18ce],
			[source].[CustomAccount] AS [CustomAccount],
			[source].[CustomBloombergID] AS [CustomBloombergID],
			[source].[CustomFundName] AS [CustomFundName],
			[source].[CustomFundSort] AS [CustomFundSort],
			[source].[CustomPartnershipID] AS [CustomPartnershipID],
			[source].[CustomRiskCategoryCode] AS [CustomRiskCategoryCode],
			[source].[CustomStrategyCode] AS [CustomStrategyCode],
			[source].[CustomTicker] AS [CustomTicker],
			[source].[CustomTickerSort] AS [CustomTickerSort],
			@TimeStamp AS [ts_end],
			NULL AS [ts_start],
			[source].[UniqKey] AS [UniqKey],
			[source].[UserName] AS [UserName]

	)MERGE_OUTPUT
	WHERE MERGE_OUTPUT.[MERGE_ACTION_46006962-52b1-4124-bdb0-426c628f18ce] = 'UPDATE' 
		AND MERGE_OUTPUT.[UniqKey] IS NOT NULL
		AND MERGE_OUTPUT.[UserName] IS NOT NULL
	;

COMMIT TRANSACTION trans_BroadridgePositions_Custom
END
GO
