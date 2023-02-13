SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[merge_TMWACCTDB] 
	@TimeStamp datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN TRANSACTION merge_TMWACCTDB

-- ==================================================
-- Slowly Changing Dimension script by SCD Merge Wizard
-- Author: Miljan Radovic
-- Official web site: https://github.com/SQLPlayer/SCD-Merge-Wizard/
-- Version: 4.3.0.0
-- Publish date: 4/8/2021 9:05:16 AM
-- Script creation date: 5/3/2021 8:26:47 AM
-- ==================================================

-- ==================================================
-- USER VARIABLES
-- ==================================================


-- ==================================================
-- SCD2
-- ==================================================
INSERT INTO [dbo].[TMWACCTDB]
(
	[account],
	[active],
	[b10backaccount],
	[b10type1],
	[b10type2],
	[b10type3],
	[b10type4],
	[b10type5],
	[b1backaccount],
	[b1type1],
	[b1type2],
	[b1type3],
	[b1type4],
	[b1type5],
	[b2backaccount],
	[b2type1],
	[b2type2],
	[b2type3],
	[b2type4],
	[b2type5],
	[b3backaccount],
	[b3type1],
	[b3type2],
	[b3type3],
	[b3type4],
	[b3type5],
	[b4backaccount],
	[b4type1],
	[b4type2],
	[b4type3],
	[b4type4],
	[b4type5],
	[b5backaccount],
	[b5type1],
	[b5type2],
	[b5type3],
	[b5type4],
	[b5type5],
	[b6backaccount],
	[b6type1],
	[b6type2],
	[b6type3],
	[b6type4],
	[b6type5],
	[b7backaccount],
	[b7type1],
	[b7type2],
	[b7type3],
	[b7type4],
	[b7type5],
	[b8backaccount],
	[b8type1],
	[b8type2],
	[b8type3],
	[b8type4],
	[b8type5],
	[b9backaccount],
	[b9type1],
	[b9type2],
	[b9type3],
	[b9type4],
	[b9type5],
	[capital],
	[closedate],
	[country],
	[cppaid_percent],
	[currency],
	[defbackacct],
	[descr],
	[group1],
	[group10],
	[group11],
	[group12],
	[group13],
	[group14],
	[group15],
	[group16],
	[group17],
	[group18],
	[group19],
	[group2],
	[group20],
	[group3],
	[group4],
	[group5],
	[group6],
	[group7],
	[group8],
	[group9],
	[intercode],
	[longrate],
	[opendate],
	[shortrate],
	[shortratecode],
	[sort],
	[test],
	[trader],
	[ts_end],
	[ts_start],
	[type]
)
SELECT
	[account],
	[active],
	[b10backaccount],
	[b10type1],
	[b10type2],
	[b10type3],
	[b10type4],
	[b10type5],
	[b1backaccount],
	[b1type1],
	[b1type2],
	[b1type3],
	[b1type4],
	[b1type5],
	[b2backaccount],
	[b2type1],
	[b2type2],
	[b2type3],
	[b2type4],
	[b2type5],
	[b3backaccount],
	[b3type1],
	[b3type2],
	[b3type3],
	[b3type4],
	[b3type5],
	[b4backaccount],
	[b4type1],
	[b4type2],
	[b4type3],
	[b4type4],
	[b4type5],
	[b5backaccount],
	[b5type1],
	[b5type2],
	[b5type3],
	[b5type4],
	[b5type5],
	[b6backaccount],
	[b6type1],
	[b6type2],
	[b6type3],
	[b6type4],
	[b6type5],
	[b7backaccount],
	[b7type1],
	[b7type2],
	[b7type3],
	[b7type4],
	[b7type5],
	[b8backaccount],
	[b8type1],
	[b8type2],
	[b8type3],
	[b8type4],
	[b8type5],
	[b9backaccount],
	[b9type1],
	[b9type2],
	[b9type3],
	[b9type4],
	[b9type5],
	[capital],
	[closedate],
	[country],
	[cppaid_percent],
	[currency],
	[defbackacct],
	[descr],
	[group1],
	[group10],
	[group11],
	[group12],
	[group13],
	[group14],
	[group15],
	[group16],
	[group17],
	[group18],
	[group19],
	[group2],
	[group20],
	[group3],
	[group4],
	[group5],
	[group6],
	[group7],
	[group8],
	[group9],
	[intercode],
	[longrate],
	[opendate],
	[shortrate],
	[shortratecode],
	[sort],
	[test],
	[trader],
	[ts_end],
	[ts_start],
	[type]
FROM
(
	MERGE [dbo].[TMWACCTDB] as [target]
	USING
	(
		SELECT
			[account],
			[active],
			[b10backaccount],
			[b10type1],
			[b10type2],
			[b10type3],
			[b10type4],
			[b10type5],
			[b1backaccount],
			[b1type1],
			[b1type2],
			[b1type3],
			[b1type4],
			[b1type5],
			[b2backaccount],
			[b2type1],
			[b2type2],
			[b2type3],
			[b2type4],
			[b2type5],
			[b3backaccount],
			[b3type1],
			[b3type2],
			[b3type3],
			[b3type4],
			[b3type5],
			[b4backaccount],
			[b4type1],
			[b4type2],
			[b4type3],
			[b4type4],
			[b4type5],
			[b5backaccount],
			[b5type1],
			[b5type2],
			[b5type3],
			[b5type4],
			[b5type5],
			[b6backaccount],
			[b6type1],
			[b6type2],
			[b6type3],
			[b6type4],
			[b6type5],
			[b7backaccount],
			[b7type1],
			[b7type2],
			[b7type3],
			[b7type4],
			[b7type5],
			[b8backaccount],
			[b8type1],
			[b8type2],
			[b8type3],
			[b8type4],
			[b8type5],
			[b9backaccount],
			[b9type1],
			[b9type2],
			[b9type3],
			[b9type4],
			[b9type5],
			[capital],
			[closedate],
			[country],
			[cppaid_percent],
			[currency],
			[defbackacct],
			[descr],
			[group1],
			[group10],
			[group11],
			[group12],
			[group13],
			[group14],
			[group15],
			[group16],
			[group17],
			[group18],
			[group19],
			[group2],
			[group20],
			[group3],
			[group4],
			[group5],
			[group6],
			[group7],
			[group8],
			[group9],
			[intercode],
			[longrate],
			[opendate],
			[shortrate],
			[shortratecode],
			[sort],
			[test],
			[trader],
			[type]
		FROM [dbo].[TMWACCTDB_staging]

	) as [source]
	ON
	(
		[source].[account] = [target].[account]
	)

	WHEN NOT MATCHED BY TARGET
	THEN INSERT
	(
		[account],
		[active],
		[b10backaccount],
		[b10type1],
		[b10type2],
		[b10type3],
		[b10type4],
		[b10type5],
		[b1backaccount],
		[b1type1],
		[b1type2],
		[b1type3],
		[b1type4],
		[b1type5],
		[b2backaccount],
		[b2type1],
		[b2type2],
		[b2type3],
		[b2type4],
		[b2type5],
		[b3backaccount],
		[b3type1],
		[b3type2],
		[b3type3],
		[b3type4],
		[b3type5],
		[b4backaccount],
		[b4type1],
		[b4type2],
		[b4type3],
		[b4type4],
		[b4type5],
		[b5backaccount],
		[b5type1],
		[b5type2],
		[b5type3],
		[b5type4],
		[b5type5],
		[b6backaccount],
		[b6type1],
		[b6type2],
		[b6type3],
		[b6type4],
		[b6type5],
		[b7backaccount],
		[b7type1],
		[b7type2],
		[b7type3],
		[b7type4],
		[b7type5],
		[b8backaccount],
		[b8type1],
		[b8type2],
		[b8type3],
		[b8type4],
		[b8type5],
		[b9backaccount],
		[b9type1],
		[b9type2],
		[b9type3],
		[b9type4],
		[b9type5],
		[capital],
		[closedate],
		[country],
		[cppaid_percent],
		[currency],
		[defbackacct],
		[descr],
		[group1],
		[group10],
		[group11],
		[group12],
		[group13],
		[group14],
		[group15],
		[group16],
		[group17],
		[group18],
		[group19],
		[group2],
		[group20],
		[group3],
		[group4],
		[group5],
		[group6],
		[group7],
		[group8],
		[group9],
		[intercode],
		[longrate],
		[opendate],
		[shortrate],
		[shortratecode],
		[sort],
		[test],
		[trader],
		[ts_end],
		[ts_start],
		[type]
	)
	VALUES
	(
		[account],
		[active],
		[b10backaccount],
		[b10type1],
		[b10type2],
		[b10type3],
		[b10type4],
		[b10type5],
		[b1backaccount],
		[b1type1],
		[b1type2],
		[b1type3],
		[b1type4],
		[b1type5],
		[b2backaccount],
		[b2type1],
		[b2type2],
		[b2type3],
		[b2type4],
		[b2type5],
		[b3backaccount],
		[b3type1],
		[b3type2],
		[b3type3],
		[b3type4],
		[b3type5],
		[b4backaccount],
		[b4type1],
		[b4type2],
		[b4type3],
		[b4type4],
		[b4type5],
		[b5backaccount],
		[b5type1],
		[b5type2],
		[b5type3],
		[b5type4],
		[b5type5],
		[b6backaccount],
		[b6type1],
		[b6type2],
		[b6type3],
		[b6type4],
		[b6type5],
		[b7backaccount],
		[b7type1],
		[b7type2],
		[b7type3],
		[b7type4],
		[b7type5],
		[b8backaccount],
		[b8type1],
		[b8type2],
		[b8type3],
		[b8type4],
		[b8type5],
		[b9backaccount],
		[b9type1],
		[b9type2],
		[b9type3],
		[b9type4],
		[b9type5],
		[capital],
		[closedate],
		[country],
		[cppaid_percent],
		[currency],
		[defbackacct],
		[descr],
		[group1],
		[group10],
		[group11],
		[group12],
		[group13],
		[group14],
		[group15],
		[group16],
		[group17],
		[group18],
		[group19],
		[group2],
		[group20],
		[group3],
		[group4],
		[group5],
		[group6],
		[group7],
		[group8],
		[group9],
		[intercode],
		[longrate],
		[opendate],
		[shortrate],
		[shortratecode],
		[sort],
		[test],
		[trader],
		NULL,
		@TimeStamp,
		[type]
	)


WHEN MATCHED AND
(
	([ts_end] IS NULL)
)
AND
(
	([target].[active] <> [source].[active] OR ([target].[active] IS NULL AND [source].[active] IS NOT NULL) OR ([target].[active] IS NOT NULL AND [source].[active] IS NULL)) OR
	([target].[b10backaccount] <> [source].[b10backaccount] OR ([target].[b10backaccount] IS NULL AND [source].[b10backaccount] IS NOT NULL) OR ([target].[b10backaccount] IS NOT NULL AND [source].[b10backaccount] IS NULL)) OR
	([target].[b10type1] <> [source].[b10type1] OR ([target].[b10type1] IS NULL AND [source].[b10type1] IS NOT NULL) OR ([target].[b10type1] IS NOT NULL AND [source].[b10type1] IS NULL)) OR
	([target].[b10type2] <> [source].[b10type2] OR ([target].[b10type2] IS NULL AND [source].[b10type2] IS NOT NULL) OR ([target].[b10type2] IS NOT NULL AND [source].[b10type2] IS NULL)) OR
	([target].[b10type3] <> [source].[b10type3] OR ([target].[b10type3] IS NULL AND [source].[b10type3] IS NOT NULL) OR ([target].[b10type3] IS NOT NULL AND [source].[b10type3] IS NULL)) OR
	([target].[b10type4] <> [source].[b10type4] OR ([target].[b10type4] IS NULL AND [source].[b10type4] IS NOT NULL) OR ([target].[b10type4] IS NOT NULL AND [source].[b10type4] IS NULL)) OR
	([target].[b10type5] <> [source].[b10type5] OR ([target].[b10type5] IS NULL AND [source].[b10type5] IS NOT NULL) OR ([target].[b10type5] IS NOT NULL AND [source].[b10type5] IS NULL)) OR
	([target].[b1backaccount] <> [source].[b1backaccount] OR ([target].[b1backaccount] IS NULL AND [source].[b1backaccount] IS NOT NULL) OR ([target].[b1backaccount] IS NOT NULL AND [source].[b1backaccount] IS NULL)) OR
	([target].[b1type1] <> [source].[b1type1] OR ([target].[b1type1] IS NULL AND [source].[b1type1] IS NOT NULL) OR ([target].[b1type1] IS NOT NULL AND [source].[b1type1] IS NULL)) OR
	([target].[b1type2] <> [source].[b1type2] OR ([target].[b1type2] IS NULL AND [source].[b1type2] IS NOT NULL) OR ([target].[b1type2] IS NOT NULL AND [source].[b1type2] IS NULL)) OR
	([target].[b1type3] <> [source].[b1type3] OR ([target].[b1type3] IS NULL AND [source].[b1type3] IS NOT NULL) OR ([target].[b1type3] IS NOT NULL AND [source].[b1type3] IS NULL)) OR
	([target].[b1type4] <> [source].[b1type4] OR ([target].[b1type4] IS NULL AND [source].[b1type4] IS NOT NULL) OR ([target].[b1type4] IS NOT NULL AND [source].[b1type4] IS NULL)) OR
	([target].[b1type5] <> [source].[b1type5] OR ([target].[b1type5] IS NULL AND [source].[b1type5] IS NOT NULL) OR ([target].[b1type5] IS NOT NULL AND [source].[b1type5] IS NULL)) OR
	([target].[b2backaccount] <> [source].[b2backaccount] OR ([target].[b2backaccount] IS NULL AND [source].[b2backaccount] IS NOT NULL) OR ([target].[b2backaccount] IS NOT NULL AND [source].[b2backaccount] IS NULL)) OR
	([target].[b2type1] <> [source].[b2type1] OR ([target].[b2type1] IS NULL AND [source].[b2type1] IS NOT NULL) OR ([target].[b2type1] IS NOT NULL AND [source].[b2type1] IS NULL)) OR
	([target].[b2type2] <> [source].[b2type2] OR ([target].[b2type2] IS NULL AND [source].[b2type2] IS NOT NULL) OR ([target].[b2type2] IS NOT NULL AND [source].[b2type2] IS NULL)) OR
	([target].[b2type3] <> [source].[b2type3] OR ([target].[b2type3] IS NULL AND [source].[b2type3] IS NOT NULL) OR ([target].[b2type3] IS NOT NULL AND [source].[b2type3] IS NULL)) OR
	([target].[b2type4] <> [source].[b2type4] OR ([target].[b2type4] IS NULL AND [source].[b2type4] IS NOT NULL) OR ([target].[b2type4] IS NOT NULL AND [source].[b2type4] IS NULL)) OR
	([target].[b2type5] <> [source].[b2type5] OR ([target].[b2type5] IS NULL AND [source].[b2type5] IS NOT NULL) OR ([target].[b2type5] IS NOT NULL AND [source].[b2type5] IS NULL)) OR
	([target].[b3backaccount] <> [source].[b3backaccount] OR ([target].[b3backaccount] IS NULL AND [source].[b3backaccount] IS NOT NULL) OR ([target].[b3backaccount] IS NOT NULL AND [source].[b3backaccount] IS NULL)) OR
	([target].[b3type1] <> [source].[b3type1] OR ([target].[b3type1] IS NULL AND [source].[b3type1] IS NOT NULL) OR ([target].[b3type1] IS NOT NULL AND [source].[b3type1] IS NULL)) OR
	([target].[b3type2] <> [source].[b3type2] OR ([target].[b3type2] IS NULL AND [source].[b3type2] IS NOT NULL) OR ([target].[b3type2] IS NOT NULL AND [source].[b3type2] IS NULL)) OR
	([target].[b3type3] <> [source].[b3type3] OR ([target].[b3type3] IS NULL AND [source].[b3type3] IS NOT NULL) OR ([target].[b3type3] IS NOT NULL AND [source].[b3type3] IS NULL)) OR
	([target].[b3type4] <> [source].[b3type4] OR ([target].[b3type4] IS NULL AND [source].[b3type4] IS NOT NULL) OR ([target].[b3type4] IS NOT NULL AND [source].[b3type4] IS NULL)) OR
	([target].[b3type5] <> [source].[b3type5] OR ([target].[b3type5] IS NULL AND [source].[b3type5] IS NOT NULL) OR ([target].[b3type5] IS NOT NULL AND [source].[b3type5] IS NULL)) OR
	([target].[b4backaccount] <> [source].[b4backaccount] OR ([target].[b4backaccount] IS NULL AND [source].[b4backaccount] IS NOT NULL) OR ([target].[b4backaccount] IS NOT NULL AND [source].[b4backaccount] IS NULL)) OR
	([target].[b4type1] <> [source].[b4type1] OR ([target].[b4type1] IS NULL AND [source].[b4type1] IS NOT NULL) OR ([target].[b4type1] IS NOT NULL AND [source].[b4type1] IS NULL)) OR
	([target].[b4type2] <> [source].[b4type2] OR ([target].[b4type2] IS NULL AND [source].[b4type2] IS NOT NULL) OR ([target].[b4type2] IS NOT NULL AND [source].[b4type2] IS NULL)) OR
	([target].[b4type3] <> [source].[b4type3] OR ([target].[b4type3] IS NULL AND [source].[b4type3] IS NOT NULL) OR ([target].[b4type3] IS NOT NULL AND [source].[b4type3] IS NULL)) OR
	([target].[b4type4] <> [source].[b4type4] OR ([target].[b4type4] IS NULL AND [source].[b4type4] IS NOT NULL) OR ([target].[b4type4] IS NOT NULL AND [source].[b4type4] IS NULL)) OR
	([target].[b4type5] <> [source].[b4type5] OR ([target].[b4type5] IS NULL AND [source].[b4type5] IS NOT NULL) OR ([target].[b4type5] IS NOT NULL AND [source].[b4type5] IS NULL)) OR
	([target].[b5backaccount] <> [source].[b5backaccount] OR ([target].[b5backaccount] IS NULL AND [source].[b5backaccount] IS NOT NULL) OR ([target].[b5backaccount] IS NOT NULL AND [source].[b5backaccount] IS NULL)) OR
	([target].[b5type1] <> [source].[b5type1] OR ([target].[b5type1] IS NULL AND [source].[b5type1] IS NOT NULL) OR ([target].[b5type1] IS NOT NULL AND [source].[b5type1] IS NULL)) OR
	([target].[b5type2] <> [source].[b5type2] OR ([target].[b5type2] IS NULL AND [source].[b5type2] IS NOT NULL) OR ([target].[b5type2] IS NOT NULL AND [source].[b5type2] IS NULL)) OR
	([target].[b5type3] <> [source].[b5type3] OR ([target].[b5type3] IS NULL AND [source].[b5type3] IS NOT NULL) OR ([target].[b5type3] IS NOT NULL AND [source].[b5type3] IS NULL)) OR
	([target].[b5type4] <> [source].[b5type4] OR ([target].[b5type4] IS NULL AND [source].[b5type4] IS NOT NULL) OR ([target].[b5type4] IS NOT NULL AND [source].[b5type4] IS NULL)) OR
	([target].[b5type5] <> [source].[b5type5] OR ([target].[b5type5] IS NULL AND [source].[b5type5] IS NOT NULL) OR ([target].[b5type5] IS NOT NULL AND [source].[b5type5] IS NULL)) OR
	([target].[b6backaccount] <> [source].[b6backaccount] OR ([target].[b6backaccount] IS NULL AND [source].[b6backaccount] IS NOT NULL) OR ([target].[b6backaccount] IS NOT NULL AND [source].[b6backaccount] IS NULL)) OR
	([target].[b6type1] <> [source].[b6type1] OR ([target].[b6type1] IS NULL AND [source].[b6type1] IS NOT NULL) OR ([target].[b6type1] IS NOT NULL AND [source].[b6type1] IS NULL)) OR
	([target].[b6type2] <> [source].[b6type2] OR ([target].[b6type2] IS NULL AND [source].[b6type2] IS NOT NULL) OR ([target].[b6type2] IS NOT NULL AND [source].[b6type2] IS NULL)) OR
	([target].[b6type3] <> [source].[b6type3] OR ([target].[b6type3] IS NULL AND [source].[b6type3] IS NOT NULL) OR ([target].[b6type3] IS NOT NULL AND [source].[b6type3] IS NULL)) OR
	([target].[b6type4] <> [source].[b6type4] OR ([target].[b6type4] IS NULL AND [source].[b6type4] IS NOT NULL) OR ([target].[b6type4] IS NOT NULL AND [source].[b6type4] IS NULL)) OR
	([target].[b6type5] <> [source].[b6type5] OR ([target].[b6type5] IS NULL AND [source].[b6type5] IS NOT NULL) OR ([target].[b6type5] IS NOT NULL AND [source].[b6type5] IS NULL)) OR
	([target].[b7backaccount] <> [source].[b7backaccount] OR ([target].[b7backaccount] IS NULL AND [source].[b7backaccount] IS NOT NULL) OR ([target].[b7backaccount] IS NOT NULL AND [source].[b7backaccount] IS NULL)) OR
	([target].[b7type1] <> [source].[b7type1] OR ([target].[b7type1] IS NULL AND [source].[b7type1] IS NOT NULL) OR ([target].[b7type1] IS NOT NULL AND [source].[b7type1] IS NULL)) OR
	([target].[b7type2] <> [source].[b7type2] OR ([target].[b7type2] IS NULL AND [source].[b7type2] IS NOT NULL) OR ([target].[b7type2] IS NOT NULL AND [source].[b7type2] IS NULL)) OR
	([target].[b7type3] <> [source].[b7type3] OR ([target].[b7type3] IS NULL AND [source].[b7type3] IS NOT NULL) OR ([target].[b7type3] IS NOT NULL AND [source].[b7type3] IS NULL)) OR
	([target].[b7type4] <> [source].[b7type4] OR ([target].[b7type4] IS NULL AND [source].[b7type4] IS NOT NULL) OR ([target].[b7type4] IS NOT NULL AND [source].[b7type4] IS NULL)) OR
	([target].[b7type5] <> [source].[b7type5] OR ([target].[b7type5] IS NULL AND [source].[b7type5] IS NOT NULL) OR ([target].[b7type5] IS NOT NULL AND [source].[b7type5] IS NULL)) OR
	([target].[b8backaccount] <> [source].[b8backaccount] OR ([target].[b8backaccount] IS NULL AND [source].[b8backaccount] IS NOT NULL) OR ([target].[b8backaccount] IS NOT NULL AND [source].[b8backaccount] IS NULL)) OR
	([target].[b8type1] <> [source].[b8type1] OR ([target].[b8type1] IS NULL AND [source].[b8type1] IS NOT NULL) OR ([target].[b8type1] IS NOT NULL AND [source].[b8type1] IS NULL)) OR
	([target].[b8type2] <> [source].[b8type2] OR ([target].[b8type2] IS NULL AND [source].[b8type2] IS NOT NULL) OR ([target].[b8type2] IS NOT NULL AND [source].[b8type2] IS NULL)) OR
	([target].[b8type3] <> [source].[b8type3] OR ([target].[b8type3] IS NULL AND [source].[b8type3] IS NOT NULL) OR ([target].[b8type3] IS NOT NULL AND [source].[b8type3] IS NULL)) OR
	([target].[b8type4] <> [source].[b8type4] OR ([target].[b8type4] IS NULL AND [source].[b8type4] IS NOT NULL) OR ([target].[b8type4] IS NOT NULL AND [source].[b8type4] IS NULL)) OR
	([target].[b8type5] <> [source].[b8type5] OR ([target].[b8type5] IS NULL AND [source].[b8type5] IS NOT NULL) OR ([target].[b8type5] IS NOT NULL AND [source].[b8type5] IS NULL)) OR
	([target].[b9backaccount] <> [source].[b9backaccount] OR ([target].[b9backaccount] IS NULL AND [source].[b9backaccount] IS NOT NULL) OR ([target].[b9backaccount] IS NOT NULL AND [source].[b9backaccount] IS NULL)) OR
	([target].[b9type1] <> [source].[b9type1] OR ([target].[b9type1] IS NULL AND [source].[b9type1] IS NOT NULL) OR ([target].[b9type1] IS NOT NULL AND [source].[b9type1] IS NULL)) OR
	([target].[b9type2] <> [source].[b9type2] OR ([target].[b9type2] IS NULL AND [source].[b9type2] IS NOT NULL) OR ([target].[b9type2] IS NOT NULL AND [source].[b9type2] IS NULL)) OR
	([target].[b9type3] <> [source].[b9type3] OR ([target].[b9type3] IS NULL AND [source].[b9type3] IS NOT NULL) OR ([target].[b9type3] IS NOT NULL AND [source].[b9type3] IS NULL)) OR
	([target].[b9type4] <> [source].[b9type4] OR ([target].[b9type4] IS NULL AND [source].[b9type4] IS NOT NULL) OR ([target].[b9type4] IS NOT NULL AND [source].[b9type4] IS NULL)) OR
	([target].[b9type5] <> [source].[b9type5] OR ([target].[b9type5] IS NULL AND [source].[b9type5] IS NOT NULL) OR ([target].[b9type5] IS NOT NULL AND [source].[b9type5] IS NULL)) OR
	([target].[capital] <> [source].[capital] OR ([target].[capital] IS NULL AND [source].[capital] IS NOT NULL) OR ([target].[capital] IS NOT NULL AND [source].[capital] IS NULL)) OR
	([target].[closedate] <> [source].[closedate] OR ([target].[closedate] IS NULL AND [source].[closedate] IS NOT NULL) OR ([target].[closedate] IS NOT NULL AND [source].[closedate] IS NULL)) OR
	([target].[country] <> [source].[country] OR ([target].[country] IS NULL AND [source].[country] IS NOT NULL) OR ([target].[country] IS NOT NULL AND [source].[country] IS NULL)) OR
	([target].[cppaid_percent] <> [source].[cppaid_percent] OR ([target].[cppaid_percent] IS NULL AND [source].[cppaid_percent] IS NOT NULL) OR ([target].[cppaid_percent] IS NOT NULL AND [source].[cppaid_percent] IS NULL)) OR
	([target].[currency] <> [source].[currency] OR ([target].[currency] IS NULL AND [source].[currency] IS NOT NULL) OR ([target].[currency] IS NOT NULL AND [source].[currency] IS NULL)) OR
	([target].[defbackacct] <> [source].[defbackacct] OR ([target].[defbackacct] IS NULL AND [source].[defbackacct] IS NOT NULL) OR ([target].[defbackacct] IS NOT NULL AND [source].[defbackacct] IS NULL)) OR
	([target].[descr] <> [source].[descr] OR ([target].[descr] IS NULL AND [source].[descr] IS NOT NULL) OR ([target].[descr] IS NOT NULL AND [source].[descr] IS NULL)) OR
	([target].[group1] <> [source].[group1] OR ([target].[group1] IS NULL AND [source].[group1] IS NOT NULL) OR ([target].[group1] IS NOT NULL AND [source].[group1] IS NULL)) OR
	([target].[group10] <> [source].[group10] OR ([target].[group10] IS NULL AND [source].[group10] IS NOT NULL) OR ([target].[group10] IS NOT NULL AND [source].[group10] IS NULL)) OR
	([target].[group11] <> [source].[group11] OR ([target].[group11] IS NULL AND [source].[group11] IS NOT NULL) OR ([target].[group11] IS NOT NULL AND [source].[group11] IS NULL)) OR
	([target].[group12] <> [source].[group12] OR ([target].[group12] IS NULL AND [source].[group12] IS NOT NULL) OR ([target].[group12] IS NOT NULL AND [source].[group12] IS NULL)) OR
	([target].[group13] <> [source].[group13] OR ([target].[group13] IS NULL AND [source].[group13] IS NOT NULL) OR ([target].[group13] IS NOT NULL AND [source].[group13] IS NULL)) OR
	([target].[group14] <> [source].[group14] OR ([target].[group14] IS NULL AND [source].[group14] IS NOT NULL) OR ([target].[group14] IS NOT NULL AND [source].[group14] IS NULL)) OR
	([target].[group15] <> [source].[group15] OR ([target].[group15] IS NULL AND [source].[group15] IS NOT NULL) OR ([target].[group15] IS NOT NULL AND [source].[group15] IS NULL)) OR
	([target].[group16] <> [source].[group16] OR ([target].[group16] IS NULL AND [source].[group16] IS NOT NULL) OR ([target].[group16] IS NOT NULL AND [source].[group16] IS NULL)) OR
	([target].[group17] <> [source].[group17] OR ([target].[group17] IS NULL AND [source].[group17] IS NOT NULL) OR ([target].[group17] IS NOT NULL AND [source].[group17] IS NULL)) OR
	([target].[group18] <> [source].[group18] OR ([target].[group18] IS NULL AND [source].[group18] IS NOT NULL) OR ([target].[group18] IS NOT NULL AND [source].[group18] IS NULL)) OR
	([target].[group19] <> [source].[group19] OR ([target].[group19] IS NULL AND [source].[group19] IS NOT NULL) OR ([target].[group19] IS NOT NULL AND [source].[group19] IS NULL)) OR
	([target].[group2] <> [source].[group2] OR ([target].[group2] IS NULL AND [source].[group2] IS NOT NULL) OR ([target].[group2] IS NOT NULL AND [source].[group2] IS NULL)) OR
	([target].[group20] <> [source].[group20] OR ([target].[group20] IS NULL AND [source].[group20] IS NOT NULL) OR ([target].[group20] IS NOT NULL AND [source].[group20] IS NULL)) OR
	([target].[group3] <> [source].[group3] OR ([target].[group3] IS NULL AND [source].[group3] IS NOT NULL) OR ([target].[group3] IS NOT NULL AND [source].[group3] IS NULL)) OR
	([target].[group4] <> [source].[group4] OR ([target].[group4] IS NULL AND [source].[group4] IS NOT NULL) OR ([target].[group4] IS NOT NULL AND [source].[group4] IS NULL)) OR
	([target].[group5] <> [source].[group5] OR ([target].[group5] IS NULL AND [source].[group5] IS NOT NULL) OR ([target].[group5] IS NOT NULL AND [source].[group5] IS NULL)) OR
	([target].[group6] <> [source].[group6] OR ([target].[group6] IS NULL AND [source].[group6] IS NOT NULL) OR ([target].[group6] IS NOT NULL AND [source].[group6] IS NULL)) OR
	([target].[group7] <> [source].[group7] OR ([target].[group7] IS NULL AND [source].[group7] IS NOT NULL) OR ([target].[group7] IS NOT NULL AND [source].[group7] IS NULL)) OR
	([target].[group8] <> [source].[group8] OR ([target].[group8] IS NULL AND [source].[group8] IS NOT NULL) OR ([target].[group8] IS NOT NULL AND [source].[group8] IS NULL)) OR
	([target].[group9] <> [source].[group9] OR ([target].[group9] IS NULL AND [source].[group9] IS NOT NULL) OR ([target].[group9] IS NOT NULL AND [source].[group9] IS NULL)) OR
	([target].[intercode] <> [source].[intercode] OR ([target].[intercode] IS NULL AND [source].[intercode] IS NOT NULL) OR ([target].[intercode] IS NOT NULL AND [source].[intercode] IS NULL)) OR
	([target].[longrate] <> [source].[longrate] OR ([target].[longrate] IS NULL AND [source].[longrate] IS NOT NULL) OR ([target].[longrate] IS NOT NULL AND [source].[longrate] IS NULL)) OR
	([target].[opendate] <> [source].[opendate] OR ([target].[opendate] IS NULL AND [source].[opendate] IS NOT NULL) OR ([target].[opendate] IS NOT NULL AND [source].[opendate] IS NULL)) OR
	([target].[shortrate] <> [source].[shortrate] OR ([target].[shortrate] IS NULL AND [source].[shortrate] IS NOT NULL) OR ([target].[shortrate] IS NOT NULL AND [source].[shortrate] IS NULL)) OR
	([target].[shortratecode] <> [source].[shortratecode] OR ([target].[shortratecode] IS NULL AND [source].[shortratecode] IS NOT NULL) OR ([target].[shortratecode] IS NOT NULL AND [source].[shortratecode] IS NULL)) OR
	([target].[sort] <> [source].[sort] OR ([target].[sort] IS NULL AND [source].[sort] IS NOT NULL) OR ([target].[sort] IS NOT NULL AND [source].[sort] IS NULL)) OR
	([target].[test] <> [source].[test] OR ([target].[test] IS NULL AND [source].[test] IS NOT NULL) OR ([target].[test] IS NOT NULL AND [source].[test] IS NULL)) OR
	([target].[trader] <> [source].[trader] OR ([target].[trader] IS NULL AND [source].[trader] IS NOT NULL) OR ([target].[trader] IS NOT NULL AND [source].[trader] IS NULL)) OR
	([target].[type] <> [source].[type] OR ([target].[type] IS NULL AND [source].[type] IS NOT NULL) OR ([target].[type] IS NOT NULL AND [source].[type] IS NULL))

)
	THEN UPDATE
	SET
		[ts_end] = @TimeStamp


	OUTPUT
		$Action as [MERGE_ACTION_6e39c236-dece-4789-b637-e16fddf96dbe],
		[source].[account] AS [account],
		[source].[active] AS [active],
		[source].[b10backaccount] AS [b10backaccount],
		[source].[b10type1] AS [b10type1],
		[source].[b10type2] AS [b10type2],
		[source].[b10type3] AS [b10type3],
		[source].[b10type4] AS [b10type4],
		[source].[b10type5] AS [b10type5],
		[source].[b1backaccount] AS [b1backaccount],
		[source].[b1type1] AS [b1type1],
		[source].[b1type2] AS [b1type2],
		[source].[b1type3] AS [b1type3],
		[source].[b1type4] AS [b1type4],
		[source].[b1type5] AS [b1type5],
		[source].[b2backaccount] AS [b2backaccount],
		[source].[b2type1] AS [b2type1],
		[source].[b2type2] AS [b2type2],
		[source].[b2type3] AS [b2type3],
		[source].[b2type4] AS [b2type4],
		[source].[b2type5] AS [b2type5],
		[source].[b3backaccount] AS [b3backaccount],
		[source].[b3type1] AS [b3type1],
		[source].[b3type2] AS [b3type2],
		[source].[b3type3] AS [b3type3],
		[source].[b3type4] AS [b3type4],
		[source].[b3type5] AS [b3type5],
		[source].[b4backaccount] AS [b4backaccount],
		[source].[b4type1] AS [b4type1],
		[source].[b4type2] AS [b4type2],
		[source].[b4type3] AS [b4type3],
		[source].[b4type4] AS [b4type4],
		[source].[b4type5] AS [b4type5],
		[source].[b5backaccount] AS [b5backaccount],
		[source].[b5type1] AS [b5type1],
		[source].[b5type2] AS [b5type2],
		[source].[b5type3] AS [b5type3],
		[source].[b5type4] AS [b5type4],
		[source].[b5type5] AS [b5type5],
		[source].[b6backaccount] AS [b6backaccount],
		[source].[b6type1] AS [b6type1],
		[source].[b6type2] AS [b6type2],
		[source].[b6type3] AS [b6type3],
		[source].[b6type4] AS [b6type4],
		[source].[b6type5] AS [b6type5],
		[source].[b7backaccount] AS [b7backaccount],
		[source].[b7type1] AS [b7type1],
		[source].[b7type2] AS [b7type2],
		[source].[b7type3] AS [b7type3],
		[source].[b7type4] AS [b7type4],
		[source].[b7type5] AS [b7type5],
		[source].[b8backaccount] AS [b8backaccount],
		[source].[b8type1] AS [b8type1],
		[source].[b8type2] AS [b8type2],
		[source].[b8type3] AS [b8type3],
		[source].[b8type4] AS [b8type4],
		[source].[b8type5] AS [b8type5],
		[source].[b9backaccount] AS [b9backaccount],
		[source].[b9type1] AS [b9type1],
		[source].[b9type2] AS [b9type2],
		[source].[b9type3] AS [b9type3],
		[source].[b9type4] AS [b9type4],
		[source].[b9type5] AS [b9type5],
		[source].[capital] AS [capital],
		[source].[closedate] AS [closedate],
		[source].[country] AS [country],
		[source].[cppaid_percent] AS [cppaid_percent],
		[source].[currency] AS [currency],
		[source].[defbackacct] AS [defbackacct],
		[source].[descr] AS [descr],
		[source].[group1] AS [group1],
		[source].[group10] AS [group10],
		[source].[group11] AS [group11],
		[source].[group12] AS [group12],
		[source].[group13] AS [group13],
		[source].[group14] AS [group14],
		[source].[group15] AS [group15],
		[source].[group16] AS [group16],
		[source].[group17] AS [group17],
		[source].[group18] AS [group18],
		[source].[group19] AS [group19],
		[source].[group2] AS [group2],
		[source].[group20] AS [group20],
		[source].[group3] AS [group3],
		[source].[group4] AS [group4],
		[source].[group5] AS [group5],
		[source].[group6] AS [group6],
		[source].[group7] AS [group7],
		[source].[group8] AS [group8],
		[source].[group9] AS [group9],
		[source].[intercode] AS [intercode],
		[source].[longrate] AS [longrate],
		[source].[opendate] AS [opendate],
		[source].[shortrate] AS [shortrate],
		[source].[shortratecode] AS [shortratecode],
		[source].[sort] AS [sort],
		[source].[test] AS [test],
		[source].[trader] AS [trader],
		NULL AS [ts_end],
		@TimeStamp AS [ts_start],
		[source].[type] AS [type]

)MERGE_OUTPUT
WHERE MERGE_OUTPUT.[MERGE_ACTION_6e39c236-dece-4789-b637-e16fddf96dbe] = 'UPDATE' 
	AND MERGE_OUTPUT.[account] IS NOT NULL
;

COMMIT TRANSACTION merge_TMWACCTDB
END
GO
