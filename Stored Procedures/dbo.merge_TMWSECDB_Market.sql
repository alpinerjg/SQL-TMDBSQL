SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE   PROCEDURE [dbo].[merge_TMWSECDB_Market] 
	 @Timestamp datetime 

AS
BEGIN TRANSACTION merge_TMWSECDB_Market

UPDATE t1 
SET t1.ts_end = @Timestamp
FROM [TMDBSQL].[dbo].[TMWSECDB_Market] t1
LEFT JOIN [TMDBSQL].[dbo].[TMWSECDB_staging] t2 ON t2.symbol = t1.symbol
WHERE t1.ts_end IS NULL and t2.[symbol] IS NULL

-- ==================================================
-- Slowly Changing Dimension script by SCD Merge Wizard
-- Author: Miljan Radovic
-- Official web site: https://github.com/SQLPlayer/SCD-Merge-Wizard/
-- Version: 4.3.0.0
-- Publish date: 4/7/2021 4:51:57 PM
-- Script creation date: 4/7/2021 4:56:52 PM
-- ==================================================

-- ==================================================
-- SCD2
-- ==================================================
INSERT INTO [dbo].[TMWSECDB_Market]
(
	[symbol],
	[ts_end],
	[ts_start],
	[longmark],
	[longrate],
	[shortmark],
	[shortrate]
)
SELECT
	[symbol],
	[ts_end],
	[ts_start],
	[longmark],
	[longrate],
	[shortmark],
	[shortrate]

FROM
(
	MERGE [dbo].[TMWSECDB_Market] WITH (HOLDLOCK) as [target]
	USING
	(
		SELECT
			[longmark],
			[longrate],
			[shortmark],
			[shortrate],
			[symbol]
		FROM [dbo].[TMWSECDB_staging]

	) as [source]
	ON
	(
		[source].[symbol] = [target].[symbol]
	)

	WHEN NOT MATCHED BY TARGET
	THEN INSERT
	(
		[longmark],
		[longrate],
		[shortmark],
		[shortrate],
		[symbol],
		[ts_end],
		[ts_start]
	)
	VALUES
	(
		[longmark],
		[longrate],
		[shortmark],
		[shortrate],
		[symbol],
		NULL,
		@Timestamp
	)


WHEN MATCHED AND
(
	[ts_end] IS NULL
)
AND
(
	([target].[longmark] <> [source].[longmark] OR ([target].[longmark] IS NULL AND [source].[longmark] IS NOT NULL) OR ([target].[longmark] IS NOT NULL AND [source].[longmark] IS NULL)) OR
	([target].[longrate] <> [source].[longrate] OR ([target].[longrate] IS NULL AND [source].[longrate] IS NOT NULL) OR ([target].[longrate] IS NOT NULL AND [source].[longrate] IS NULL)) OR
	([target].[shortmark] <> [source].[shortmark] OR ([target].[shortmark] IS NULL AND [source].[shortmark] IS NOT NULL) OR ([target].[shortmark] IS NOT NULL AND [source].[shortmark] IS NULL)) OR
	([target].[shortrate] <> [source].[shortrate] OR ([target].[shortrate] IS NULL AND [source].[shortrate] IS NOT NULL) OR ([target].[shortrate] IS NOT NULL AND [source].[shortrate] IS NULL))

)
	THEN UPDATE
	SET
		[ts_end] = @Timestamp
	OUTPUT
		$Action as [MERGE_ACTION_901fd1f1-3621-48c4-ad24-6c77f330045a],
		[source].[longmark] AS [longmark],
		[source].[longrate] AS [longrate],
		[source].[shortmark] AS [shortmark],
		[source].[shortrate] AS [shortrate],
		[source].[symbol] AS [symbol],
		NULL AS [ts_end],
		@Timestamp AS [ts_start]

)MERGE_OUTPUT
WHERE MERGE_OUTPUT.[MERGE_ACTION_901fd1f1-3621-48c4-ad24-6c77f330045a] = 'UPDATE' 
	AND MERGE_OUTPUT.[symbol] IS NOT NULL
;
COMMIT TRANSACTION merge_TMWSECDB_Market
GO
