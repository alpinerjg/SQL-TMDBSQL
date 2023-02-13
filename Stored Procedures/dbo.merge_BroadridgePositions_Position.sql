SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[merge_BroadridgePositions_Position] 
     @Timestamp DateTime
AS
BEGIN
BEGIN TRANSACTION merge_BroadridgePositions_Pos
UPDATE t1 
SET t1.ts_end = @Timestamp
FROM [TMDBSQL].[dbo].[BroadridgePositionsPosition] t1
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

INSERT INTO [dbo].[BroadridgePositionsPosition]
(
	[Position_Calculated_AverageCost],
	[Position_Calculated_PositionCash],
	[Position_Calculated_PositionValue],
	[Position_PositionID],
	[Position_PositionTypeString],
	[ts_end],
	[ts_start],
	[UniqKey],
	[UserName]
)
SELECT
	[Position_Calculated_AverageCost],
	[Position_Calculated_PositionCash],
	[Position_Calculated_PositionValue],
	[Position_PositionID],
	[Position_PositionTypeString],
	[ts_end],
	[ts_start],
	[UniqKey],
	[UserName]
FROM
(
	MERGE [dbo].[BroadridgePositionsPosition] WITH(HOLDLOCK) as [target]
	USING
	(
		SELECT
			[Position_Calculated_AverageCost],
			[Position_Calculated_PositionCash],
			[Position_Calculated_PositionValue],
			[Position_PositionID],
			[Position_PositionTypeString],
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
		[Position_Calculated_AverageCost],
		[Position_Calculated_PositionCash],
		[Position_Calculated_PositionValue],
		[Position_PositionID],
		[Position_PositionTypeString],
		[ts_end],
		[ts_start],
		[UniqKey],
		[UserName]
	)
	VALUES
	(
		[Position_Calculated_AverageCost],
		[Position_Calculated_PositionCash],
		[Position_Calculated_PositionValue],
		[Position_PositionID],
		[Position_PositionTypeString],
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
	([target].[Position_Calculated_AverageCost] <> [source].[Position_Calculated_AverageCost] OR ([target].[Position_Calculated_AverageCost] IS NULL AND [source].[Position_Calculated_AverageCost] IS NOT NULL) OR ([target].[Position_Calculated_AverageCost] IS NOT NULL AND [source].[Position_Calculated_AverageCost] IS NULL)) OR
	([target].[Position_Calculated_PositionCash] <> [source].[Position_Calculated_PositionCash] OR ([target].[Position_Calculated_PositionCash] IS NULL AND [source].[Position_Calculated_PositionCash] IS NOT NULL) OR ([target].[Position_Calculated_PositionCash] IS NOT NULL AND [source].[Position_Calculated_PositionCash] IS NULL)) OR
	([target].[Position_Calculated_PositionValue] <> [source].[Position_Calculated_PositionValue] OR ([target].[Position_Calculated_PositionValue] IS NULL AND [source].[Position_Calculated_PositionValue] IS NOT NULL) OR ([target].[Position_Calculated_PositionValue] IS NOT NULL AND [source].[Position_Calculated_PositionValue] IS NULL)) OR
	([target].[Position_PositionID] <> [source].[Position_PositionID] OR ([target].[Position_PositionID] IS NULL AND [source].[Position_PositionID] IS NOT NULL) OR ([target].[Position_PositionID] IS NOT NULL AND [source].[Position_PositionID] IS NULL)) OR
	([target].[Position_PositionTypeString] <> [source].[Position_PositionTypeString] OR ([target].[Position_PositionTypeString] IS NULL AND [source].[Position_PositionTypeString] IS NOT NULL) OR ([target].[Position_PositionTypeString] IS NOT NULL AND [source].[Position_PositionTypeString] IS NULL))

)
	THEN UPDATE
	SET
		[ts_end] = @TimeStamp


	OUTPUT
		$Action as [MERGE_ACTION_1d4a55e5-89e8-4a6c-aafc-dd08c51bd3c2],
		[source].[Position_Calculated_AverageCost] AS [Position_Calculated_AverageCost],
		[source].[Position_Calculated_PositionCash] AS [Position_Calculated_PositionCash],
		[source].[Position_Calculated_PositionValue] AS [Position_Calculated_PositionValue],
		[source].[Position_PositionID] AS [Position_PositionID],
		[source].[Position_PositionTypeString] AS [Position_PositionTypeString],
		NULL AS [ts_end],
		@TimeStamp AS [ts_start],
		[source].[UniqKey] AS [UniqKey],
		[source].[UserName] AS [UserName]

)MERGE_OUTPUT
WHERE MERGE_OUTPUT.[MERGE_ACTION_1d4a55e5-89e8-4a6c-aafc-dd08c51bd3c2] = 'UPDATE' 
	AND MERGE_OUTPUT.[UniqKey] IS NOT NULL
	AND MERGE_OUTPUT.[UserName] IS NOT NULL
;
COMMIT TRANSACTION merge_BroadridgePositions_Pos
END
GO
