SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[merge_TMWDEALDB] 
	@TimeStamp datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN TRANSACTION merge_TMWDEALDB

UPDATE t1 
SET t1.ts_end = @Timestamp
FROM [TMDBSQL].[dbo].[TMWDEALDB] t1
LEFT JOIN [TMDBSQL].[dbo].[TMWDEALDB_staging] t2 ON t2.dealname = t1.dealname
WHERE t1.ts_end IS NULL and t2.[dealname] IS NULL

-- ==================================================
-- Slowly Changing Dimension script by SCD Merge Wizard
-- Author: Miljan Radovic
-- Official web site: https://github.com/SQLPlayer/SCD-Merge-Wizard/
-- Version: 4.3.0.0
-- Publish date: 4/7/2021 4:51:57 PM
-- Script creation date: 4/7/2021 7:51:43 PM
-- ==================================================


-- ==================================================
-- SCD2
-- ==================================================
INSERT INTO [dbo].[TMWDEALDB]
(
	[acqsym],
	[altclose],
	[altupside],
	[canbuy],
	[cashamt],
	[cashelect],
	[cashpct],
	[category],
	[charge],
	[currency],
	[d1date],
	[d2date],
	[dealamt],
	[dealdisp],
	[dealname],
	[dealreport],
	[defcanbuy],
	[definitive],
	[desc],
	[desc1],
	[downprice],
	[ds10price],
	[ds10symbol],
	[ds1price],
	[ds1symbol],
	[ds2price],
	[ds2symbol],
	[ds3price],
	[ds3symbol],
	[ds4price],
	[ds4symbol],
	[ds5price],
	[ds5symbol],
	[ds6price],
	[ds6symbol],
	[ds7price],
	[ds7symbol],
	[ds8price],
	[ds8symbol],
	[ds9price],
	[ds9symbol],
	[extracash],
	[highcollar],
	[highrange],
	[initials1],
	[initials2],
	[lowcollar],
	[lowrange],
	[nondefcanbuy],
	[numadditional],
	[origacq],
	[origprice],
	[other1],
	[other2],
	[other3],
	[outflag],
	[outsidehigh],
	[outsidelow],
	[prevadd1],
	[prevadd2],
	[prevadd3],
	[prevdown],
	[prevzshort],
	[ratio],
	[residual],
	[revcollar],
	[secondtier],
	[secsharesflag],
	[stockpct],
	[strategy],
	[tndrpct],
	[ts_end],
	[ts_start],
	[type],
	[undsym],
	[upsidemult],
	[zs10price],
	[zs10symbol],
	[zs1price],
	[zs1symbol],
	[zs2price],
	[zs2symbol],
	[zs3price],
	[zs3symbol],
	[zs4price],
	[zs4symbol],
	[zs5price],
	[zs5symbol],
	[zs6price],
	[zs6symbol],
	[zs7price],
	[zs7symbol],
	[zs8price],
	[zs8symbol],
	[zs9price],
	[zs9symbol],
	[zshortprice]
)
SELECT
	[acqsym],
	[altclose],
	[altupside],
	[canbuy],
	[cashamt],
	[cashelect],
	[cashpct],
	[category],
	[charge],
	[currency],
	[d1date],
	[d2date],
	[dealamt],
	[dealdisp],
	[dealname],
	[dealreport],
	[defcanbuy],
	[definitive],
	[desc],
	[desc1],
	[downprice],
	[ds10price],
	[ds10symbol],
	[ds1price],
	[ds1symbol],
	[ds2price],
	[ds2symbol],
	[ds3price],
	[ds3symbol],
	[ds4price],
	[ds4symbol],
	[ds5price],
	[ds5symbol],
	[ds6price],
	[ds6symbol],
	[ds7price],
	[ds7symbol],
	[ds8price],
	[ds8symbol],
	[ds9price],
	[ds9symbol],
	[extracash],
	[highcollar],
	[highrange],
	[initials1],
	[initials2],
	[lowcollar],
	[lowrange],
	[nondefcanbuy],
	[numadditional],
	[origacq],
	[origprice],
	[other1],
	[other2],
	[other3],
	[outflag],
	[outsidehigh],
	[outsidelow],
	[prevadd1],
	[prevadd2],
	[prevadd3],
	[prevdown],
	[prevzshort],
	[ratio],
	[residual],
	[revcollar],
	[secondtier],
	[secsharesflag],
	[stockpct],
	[strategy],
	[tndrpct],
	[ts_end],
	[ts_start],
	[type],
	[undsym],
	[upsidemult],
	[zs10price],
	[zs10symbol],
	[zs1price],
	[zs1symbol],
	[zs2price],
	[zs2symbol],
	[zs3price],
	[zs3symbol],
	[zs4price],
	[zs4symbol],
	[zs5price],
	[zs5symbol],
	[zs6price],
	[zs6symbol],
	[zs7price],
	[zs7symbol],
	[zs8price],
	[zs8symbol],
	[zs9price],
	[zs9symbol],
	[zshortprice]
FROM
(
	MERGE [dbo].[TMWDEALDB] WITH (HOLDLOCK) as [target]
	USING
	(
		SELECT
			[acqsym],
			[altclose],
			[altupside],
			[canbuy],
			[cashamt],
			[cashelect],
			[cashpct],
			[category],
			[charge],
			[currency],
			[d1date],
			[d2date],
			[dealamt],
			[dealdisp],
			[dealname],
			[dealreport],
			[defcanbuy],
			[definitive],
			[desc],
			[desc1],
			[downprice],
			[ds10price],
			[ds10symbol],
			[ds1price],
			[ds1symbol],
			[ds2price],
			[ds2symbol],
			[ds3price],
			[ds3symbol],
			[ds4price],
			[ds4symbol],
			[ds5price],
			[ds5symbol],
			[ds6price],
			[ds6symbol],
			[ds7price],
			[ds7symbol],
			[ds8price],
			[ds8symbol],
			[ds9price],
			[ds9symbol],
			[extracash],
			[highcollar],
			[highrange],
			[initials1],
			[initials2],
			[lowcollar],
			[lowrange],
			[nondefcanbuy],
			[numadditional],
			[origacq],
			[origprice],
			[other1],
			[other2],
			[other3],
			[outflag],
			[outsidehigh],
			[outsidelow],
			[prevadd1],
			[prevadd2],
			[prevadd3],
			[prevdown],
			[prevzshort],
			[ratio],
			[residual],
			[revcollar],
			[secondtier],
			[secsharesflag],
			[stockpct],
			[strategy],
			[tndrpct],
			[type],
			[undsym],
			[upsidemult],
			[zs10price],
			[zs10symbol],
			[zs1price],
			[zs1symbol],
			[zs2price],
			[zs2symbol],
			[zs3price],
			[zs3symbol],
			[zs4price],
			[zs4symbol],
			[zs5price],
			[zs5symbol],
			[zs6price],
			[zs6symbol],
			[zs7price],
			[zs7symbol],
			[zs8price],
			[zs8symbol],
			[zs9price],
			[zs9symbol],
			[zshortprice]
		FROM [dbo].[TMWDEALDB_staging]

	) as [source]
	ON
	(
		[source].[dealname] = [target].[dealname]
	)

	WHEN NOT MATCHED BY TARGET
	THEN INSERT
	(
		[acqsym],
		[altclose],
		[altupside],
		[canbuy],
		[cashamt],
		[cashelect],
		[cashpct],
		[category],
		[charge],
		[currency],
		[d1date],
		[d2date],
		[dealamt],
		[dealdisp],
		[dealname],
		[dealreport],
		[defcanbuy],
		[definitive],
		[desc],
		[desc1],
		[downprice],
		[ds10price],
		[ds10symbol],
		[ds1price],
		[ds1symbol],
		[ds2price],
		[ds2symbol],
		[ds3price],
		[ds3symbol],
		[ds4price],
		[ds4symbol],
		[ds5price],
		[ds5symbol],
		[ds6price],
		[ds6symbol],
		[ds7price],
		[ds7symbol],
		[ds8price],
		[ds8symbol],
		[ds9price],
		[ds9symbol],
		[extracash],
		[highcollar],
		[highrange],
		[initials1],
		[initials2],
		[lowcollar],
		[lowrange],
		[nondefcanbuy],
		[numadditional],
		[origacq],
		[origprice],
		[other1],
		[other2],
		[other3],
		[outflag],
		[outsidehigh],
		[outsidelow],
		[prevadd1],
		[prevadd2],
		[prevadd3],
		[prevdown],
		[prevzshort],
		[ratio],
		[residual],
		[revcollar],
		[secondtier],
		[secsharesflag],
		[stockpct],
		[strategy],
		[tndrpct],
		[ts_end],
		[ts_start],
		[type],
		[undsym],
		[upsidemult],
		[zs10price],
		[zs10symbol],
		[zs1price],
		[zs1symbol],
		[zs2price],
		[zs2symbol],
		[zs3price],
		[zs3symbol],
		[zs4price],
		[zs4symbol],
		[zs5price],
		[zs5symbol],
		[zs6price],
		[zs6symbol],
		[zs7price],
		[zs7symbol],
		[zs8price],
		[zs8symbol],
		[zs9price],
		[zs9symbol],
		[zshortprice]
	)
	VALUES
	(
		[acqsym],
		[altclose],
		[altupside],
		[canbuy],
		[cashamt],
		[cashelect],
		[cashpct],
		[category],
		[charge],
		[currency],
		[d1date],
		[d2date],
		[dealamt],
		[dealdisp],
		[dealname],
		[dealreport],
		[defcanbuy],
		[definitive],
		[desc],
		[desc1],
		[downprice],
		[ds10price],
		[ds10symbol],
		[ds1price],
		[ds1symbol],
		[ds2price],
		[ds2symbol],
		[ds3price],
		[ds3symbol],
		[ds4price],
		[ds4symbol],
		[ds5price],
		[ds5symbol],
		[ds6price],
		[ds6symbol],
		[ds7price],
		[ds7symbol],
		[ds8price],
		[ds8symbol],
		[ds9price],
		[ds9symbol],
		[extracash],
		[highcollar],
		[highrange],
		[initials1],
		[initials2],
		[lowcollar],
		[lowrange],
		[nondefcanbuy],
		[numadditional],
		[origacq],
		[origprice],
		[other1],
		[other2],
		[other3],
		[outflag],
		[outsidehigh],
		[outsidelow],
		[prevadd1],
		[prevadd2],
		[prevadd3],
		[prevdown],
		[prevzshort],
		[ratio],
		[residual],
		[revcollar],
		[secondtier],
		[secsharesflag],
		[stockpct],
		[strategy],
		[tndrpct],
		NULL,
		@TimeStamp,
		[type],
		[undsym],
		[upsidemult],
		[zs10price],
		[zs10symbol],
		[zs1price],
		[zs1symbol],
		[zs2price],
		[zs2symbol],
		[zs3price],
		[zs3symbol],
		[zs4price],
		[zs4symbol],
		[zs5price],
		[zs5symbol],
		[zs6price],
		[zs6symbol],
		[zs7price],
		[zs7symbol],
		[zs8price],
		[zs8symbol],
		[zs9price],
		[zs9symbol],
		[zshortprice]
	)


WHEN MATCHED AND
(
	[ts_end] = NULL
)
AND
(
	([target].[acqsym] <> [source].[acqsym] OR ([target].[acqsym] IS NULL AND [source].[acqsym] IS NOT NULL) OR ([target].[acqsym] IS NOT NULL AND [source].[acqsym] IS NULL)) OR
	([target].[altclose] <> [source].[altclose] OR ([target].[altclose] IS NULL AND [source].[altclose] IS NOT NULL) OR ([target].[altclose] IS NOT NULL AND [source].[altclose] IS NULL)) OR
	([target].[altupside] <> [source].[altupside] OR ([target].[altupside] IS NULL AND [source].[altupside] IS NOT NULL) OR ([target].[altupside] IS NOT NULL AND [source].[altupside] IS NULL)) OR
	([target].[canbuy] <> [source].[canbuy] OR ([target].[canbuy] IS NULL AND [source].[canbuy] IS NOT NULL) OR ([target].[canbuy] IS NOT NULL AND [source].[canbuy] IS NULL)) OR
	([target].[cashamt] <> [source].[cashamt] OR ([target].[cashamt] IS NULL AND [source].[cashamt] IS NOT NULL) OR ([target].[cashamt] IS NOT NULL AND [source].[cashamt] IS NULL)) OR
	([target].[cashelect] <> [source].[cashelect] OR ([target].[cashelect] IS NULL AND [source].[cashelect] IS NOT NULL) OR ([target].[cashelect] IS NOT NULL AND [source].[cashelect] IS NULL)) OR
	([target].[cashpct] <> [source].[cashpct] OR ([target].[cashpct] IS NULL AND [source].[cashpct] IS NOT NULL) OR ([target].[cashpct] IS NOT NULL AND [source].[cashpct] IS NULL)) OR
	([target].[category] <> [source].[category] OR ([target].[category] IS NULL AND [source].[category] IS NOT NULL) OR ([target].[category] IS NOT NULL AND [source].[category] IS NULL)) OR
	([target].[charge] <> [source].[charge] OR ([target].[charge] IS NULL AND [source].[charge] IS NOT NULL) OR ([target].[charge] IS NOT NULL AND [source].[charge] IS NULL)) OR
	([target].[currency] <> [source].[currency] OR ([target].[currency] IS NULL AND [source].[currency] IS NOT NULL) OR ([target].[currency] IS NOT NULL AND [source].[currency] IS NULL)) OR
	([target].[d1date] <> [source].[d1date] OR ([target].[d1date] IS NULL AND [source].[d1date] IS NOT NULL) OR ([target].[d1date] IS NOT NULL AND [source].[d1date] IS NULL)) OR
	([target].[d2date] <> [source].[d2date] OR ([target].[d2date] IS NULL AND [source].[d2date] IS NOT NULL) OR ([target].[d2date] IS NOT NULL AND [source].[d2date] IS NULL)) OR
	([target].[dealamt] <> [source].[dealamt] OR ([target].[dealamt] IS NULL AND [source].[dealamt] IS NOT NULL) OR ([target].[dealamt] IS NOT NULL AND [source].[dealamt] IS NULL)) OR
	([target].[dealdisp] <> [source].[dealdisp] OR ([target].[dealdisp] IS NULL AND [source].[dealdisp] IS NOT NULL) OR ([target].[dealdisp] IS NOT NULL AND [source].[dealdisp] IS NULL)) OR
	([target].[dealreport] <> [source].[dealreport] OR ([target].[dealreport] IS NULL AND [source].[dealreport] IS NOT NULL) OR ([target].[dealreport] IS NOT NULL AND [source].[dealreport] IS NULL)) OR
	([target].[defcanbuy] <> [source].[defcanbuy] OR ([target].[defcanbuy] IS NULL AND [source].[defcanbuy] IS NOT NULL) OR ([target].[defcanbuy] IS NOT NULL AND [source].[defcanbuy] IS NULL)) OR
	([target].[definitive] <> [source].[definitive] OR ([target].[definitive] IS NULL AND [source].[definitive] IS NOT NULL) OR ([target].[definitive] IS NOT NULL AND [source].[definitive] IS NULL)) OR
	([target].[desc] <> [source].[desc] OR ([target].[desc] IS NULL AND [source].[desc] IS NOT NULL) OR ([target].[desc] IS NOT NULL AND [source].[desc] IS NULL)) OR
	([target].[desc1] <> [source].[desc1] OR ([target].[desc1] IS NULL AND [source].[desc1] IS NOT NULL) OR ([target].[desc1] IS NOT NULL AND [source].[desc1] IS NULL)) OR
	([target].[downprice] <> [source].[downprice] OR ([target].[downprice] IS NULL AND [source].[downprice] IS NOT NULL) OR ([target].[downprice] IS NOT NULL AND [source].[downprice] IS NULL)) OR
	([target].[ds10price] <> [source].[ds10price] OR ([target].[ds10price] IS NULL AND [source].[ds10price] IS NOT NULL) OR ([target].[ds10price] IS NOT NULL AND [source].[ds10price] IS NULL)) OR
	([target].[ds10symbol] <> [source].[ds10symbol] OR ([target].[ds10symbol] IS NULL AND [source].[ds10symbol] IS NOT NULL) OR ([target].[ds10symbol] IS NOT NULL AND [source].[ds10symbol] IS NULL)) OR
	([target].[ds1price] <> [source].[ds1price] OR ([target].[ds1price] IS NULL AND [source].[ds1price] IS NOT NULL) OR ([target].[ds1price] IS NOT NULL AND [source].[ds1price] IS NULL)) OR
	([target].[ds1symbol] <> [source].[ds1symbol] OR ([target].[ds1symbol] IS NULL AND [source].[ds1symbol] IS NOT NULL) OR ([target].[ds1symbol] IS NOT NULL AND [source].[ds1symbol] IS NULL)) OR
	([target].[ds2price] <> [source].[ds2price] OR ([target].[ds2price] IS NULL AND [source].[ds2price] IS NOT NULL) OR ([target].[ds2price] IS NOT NULL AND [source].[ds2price] IS NULL)) OR
	([target].[ds2symbol] <> [source].[ds2symbol] OR ([target].[ds2symbol] IS NULL AND [source].[ds2symbol] IS NOT NULL) OR ([target].[ds2symbol] IS NOT NULL AND [source].[ds2symbol] IS NULL)) OR
	([target].[ds3price] <> [source].[ds3price] OR ([target].[ds3price] IS NULL AND [source].[ds3price] IS NOT NULL) OR ([target].[ds3price] IS NOT NULL AND [source].[ds3price] IS NULL)) OR
	([target].[ds3symbol] <> [source].[ds3symbol] OR ([target].[ds3symbol] IS NULL AND [source].[ds3symbol] IS NOT NULL) OR ([target].[ds3symbol] IS NOT NULL AND [source].[ds3symbol] IS NULL)) OR
	([target].[ds4price] <> [source].[ds4price] OR ([target].[ds4price] IS NULL AND [source].[ds4price] IS NOT NULL) OR ([target].[ds4price] IS NOT NULL AND [source].[ds4price] IS NULL)) OR
	([target].[ds4symbol] <> [source].[ds4symbol] OR ([target].[ds4symbol] IS NULL AND [source].[ds4symbol] IS NOT NULL) OR ([target].[ds4symbol] IS NOT NULL AND [source].[ds4symbol] IS NULL)) OR
	([target].[ds5price] <> [source].[ds5price] OR ([target].[ds5price] IS NULL AND [source].[ds5price] IS NOT NULL) OR ([target].[ds5price] IS NOT NULL AND [source].[ds5price] IS NULL)) OR
	([target].[ds5symbol] <> [source].[ds5symbol] OR ([target].[ds5symbol] IS NULL AND [source].[ds5symbol] IS NOT NULL) OR ([target].[ds5symbol] IS NOT NULL AND [source].[ds5symbol] IS NULL)) OR
	([target].[ds6price] <> [source].[ds6price] OR ([target].[ds6price] IS NULL AND [source].[ds6price] IS NOT NULL) OR ([target].[ds6price] IS NOT NULL AND [source].[ds6price] IS NULL)) OR
	([target].[ds6symbol] <> [source].[ds6symbol] OR ([target].[ds6symbol] IS NULL AND [source].[ds6symbol] IS NOT NULL) OR ([target].[ds6symbol] IS NOT NULL AND [source].[ds6symbol] IS NULL)) OR
	([target].[ds7price] <> [source].[ds7price] OR ([target].[ds7price] IS NULL AND [source].[ds7price] IS NOT NULL) OR ([target].[ds7price] IS NOT NULL AND [source].[ds7price] IS NULL)) OR
	([target].[ds7symbol] <> [source].[ds7symbol] OR ([target].[ds7symbol] IS NULL AND [source].[ds7symbol] IS NOT NULL) OR ([target].[ds7symbol] IS NOT NULL AND [source].[ds7symbol] IS NULL)) OR
	([target].[ds8price] <> [source].[ds8price] OR ([target].[ds8price] IS NULL AND [source].[ds8price] IS NOT NULL) OR ([target].[ds8price] IS NOT NULL AND [source].[ds8price] IS NULL)) OR
	([target].[ds8symbol] <> [source].[ds8symbol] OR ([target].[ds8symbol] IS NULL AND [source].[ds8symbol] IS NOT NULL) OR ([target].[ds8symbol] IS NOT NULL AND [source].[ds8symbol] IS NULL)) OR
	([target].[ds9price] <> [source].[ds9price] OR ([target].[ds9price] IS NULL AND [source].[ds9price] IS NOT NULL) OR ([target].[ds9price] IS NOT NULL AND [source].[ds9price] IS NULL)) OR
	([target].[ds9symbol] <> [source].[ds9symbol] OR ([target].[ds9symbol] IS NULL AND [source].[ds9symbol] IS NOT NULL) OR ([target].[ds9symbol] IS NOT NULL AND [source].[ds9symbol] IS NULL)) OR
	([target].[extracash] <> [source].[extracash] OR ([target].[extracash] IS NULL AND [source].[extracash] IS NOT NULL) OR ([target].[extracash] IS NOT NULL AND [source].[extracash] IS NULL)) OR
	([target].[highcollar] <> [source].[highcollar] OR ([target].[highcollar] IS NULL AND [source].[highcollar] IS NOT NULL) OR ([target].[highcollar] IS NOT NULL AND [source].[highcollar] IS NULL)) OR
	([target].[highrange] <> [source].[highrange] OR ([target].[highrange] IS NULL AND [source].[highrange] IS NOT NULL) OR ([target].[highrange] IS NOT NULL AND [source].[highrange] IS NULL)) OR
	([target].[initials1] <> [source].[initials1] OR ([target].[initials1] IS NULL AND [source].[initials1] IS NOT NULL) OR ([target].[initials1] IS NOT NULL AND [source].[initials1] IS NULL)) OR
	([target].[initials2] <> [source].[initials2] OR ([target].[initials2] IS NULL AND [source].[initials2] IS NOT NULL) OR ([target].[initials2] IS NOT NULL AND [source].[initials2] IS NULL)) OR
	([target].[lowcollar] <> [source].[lowcollar] OR ([target].[lowcollar] IS NULL AND [source].[lowcollar] IS NOT NULL) OR ([target].[lowcollar] IS NOT NULL AND [source].[lowcollar] IS NULL)) OR
	([target].[lowrange] <> [source].[lowrange] OR ([target].[lowrange] IS NULL AND [source].[lowrange] IS NOT NULL) OR ([target].[lowrange] IS NOT NULL AND [source].[lowrange] IS NULL)) OR
	([target].[nondefcanbuy] <> [source].[nondefcanbuy] OR ([target].[nondefcanbuy] IS NULL AND [source].[nondefcanbuy] IS NOT NULL) OR ([target].[nondefcanbuy] IS NOT NULL AND [source].[nondefcanbuy] IS NULL)) OR
	([target].[numadditional] <> [source].[numadditional] OR ([target].[numadditional] IS NULL AND [source].[numadditional] IS NOT NULL) OR ([target].[numadditional] IS NOT NULL AND [source].[numadditional] IS NULL)) OR
	([target].[origacq] <> [source].[origacq] OR ([target].[origacq] IS NULL AND [source].[origacq] IS NOT NULL) OR ([target].[origacq] IS NOT NULL AND [source].[origacq] IS NULL)) OR
	([target].[origprice] <> [source].[origprice] OR ([target].[origprice] IS NULL AND [source].[origprice] IS NOT NULL) OR ([target].[origprice] IS NOT NULL AND [source].[origprice] IS NULL)) OR
	([target].[other1] <> [source].[other1] OR ([target].[other1] IS NULL AND [source].[other1] IS NOT NULL) OR ([target].[other1] IS NOT NULL AND [source].[other1] IS NULL)) OR
	([target].[other2] <> [source].[other2] OR ([target].[other2] IS NULL AND [source].[other2] IS NOT NULL) OR ([target].[other2] IS NOT NULL AND [source].[other2] IS NULL)) OR
	([target].[other3] <> [source].[other3] OR ([target].[other3] IS NULL AND [source].[other3] IS NOT NULL) OR ([target].[other3] IS NOT NULL AND [source].[other3] IS NULL)) OR
	([target].[outflag] <> [source].[outflag] OR ([target].[outflag] IS NULL AND [source].[outflag] IS NOT NULL) OR ([target].[outflag] IS NOT NULL AND [source].[outflag] IS NULL)) OR
	([target].[outsidehigh] <> [source].[outsidehigh] OR ([target].[outsidehigh] IS NULL AND [source].[outsidehigh] IS NOT NULL) OR ([target].[outsidehigh] IS NOT NULL AND [source].[outsidehigh] IS NULL)) OR
	([target].[outsidelow] <> [source].[outsidelow] OR ([target].[outsidelow] IS NULL AND [source].[outsidelow] IS NOT NULL) OR ([target].[outsidelow] IS NOT NULL AND [source].[outsidelow] IS NULL)) OR
	([target].[prevadd1] <> [source].[prevadd1] OR ([target].[prevadd1] IS NULL AND [source].[prevadd1] IS NOT NULL) OR ([target].[prevadd1] IS NOT NULL AND [source].[prevadd1] IS NULL)) OR
	([target].[prevadd2] <> [source].[prevadd2] OR ([target].[prevadd2] IS NULL AND [source].[prevadd2] IS NOT NULL) OR ([target].[prevadd2] IS NOT NULL AND [source].[prevadd2] IS NULL)) OR
	([target].[prevadd3] <> [source].[prevadd3] OR ([target].[prevadd3] IS NULL AND [source].[prevadd3] IS NOT NULL) OR ([target].[prevadd3] IS NOT NULL AND [source].[prevadd3] IS NULL)) OR
	([target].[prevdown] <> [source].[prevdown] OR ([target].[prevdown] IS NULL AND [source].[prevdown] IS NOT NULL) OR ([target].[prevdown] IS NOT NULL AND [source].[prevdown] IS NULL)) OR
	([target].[prevzshort] <> [source].[prevzshort] OR ([target].[prevzshort] IS NULL AND [source].[prevzshort] IS NOT NULL) OR ([target].[prevzshort] IS NOT NULL AND [source].[prevzshort] IS NULL)) OR
	([target].[ratio] <> [source].[ratio] OR ([target].[ratio] IS NULL AND [source].[ratio] IS NOT NULL) OR ([target].[ratio] IS NOT NULL AND [source].[ratio] IS NULL)) OR
	([target].[residual] <> [source].[residual] OR ([target].[residual] IS NULL AND [source].[residual] IS NOT NULL) OR ([target].[residual] IS NOT NULL AND [source].[residual] IS NULL)) OR
	([target].[revcollar] <> [source].[revcollar] OR ([target].[revcollar] IS NULL AND [source].[revcollar] IS NOT NULL) OR ([target].[revcollar] IS NOT NULL AND [source].[revcollar] IS NULL)) OR
	([target].[secondtier] <> [source].[secondtier] OR ([target].[secondtier] IS NULL AND [source].[secondtier] IS NOT NULL) OR ([target].[secondtier] IS NOT NULL AND [source].[secondtier] IS NULL)) OR
	([target].[secsharesflag] <> [source].[secsharesflag] OR ([target].[secsharesflag] IS NULL AND [source].[secsharesflag] IS NOT NULL) OR ([target].[secsharesflag] IS NOT NULL AND [source].[secsharesflag] IS NULL)) OR
	([target].[stockpct] <> [source].[stockpct] OR ([target].[stockpct] IS NULL AND [source].[stockpct] IS NOT NULL) OR ([target].[stockpct] IS NOT NULL AND [source].[stockpct] IS NULL)) OR
	([target].[strategy] <> [source].[strategy] OR ([target].[strategy] IS NULL AND [source].[strategy] IS NOT NULL) OR ([target].[strategy] IS NOT NULL AND [source].[strategy] IS NULL)) OR
	([target].[tndrpct] <> [source].[tndrpct] OR ([target].[tndrpct] IS NULL AND [source].[tndrpct] IS NOT NULL) OR ([target].[tndrpct] IS NOT NULL AND [source].[tndrpct] IS NULL)) OR
	([target].[type] <> [source].[type] OR ([target].[type] IS NULL AND [source].[type] IS NOT NULL) OR ([target].[type] IS NOT NULL AND [source].[type] IS NULL)) OR
	([target].[undsym] <> [source].[undsym] OR ([target].[undsym] IS NULL AND [source].[undsym] IS NOT NULL) OR ([target].[undsym] IS NOT NULL AND [source].[undsym] IS NULL)) OR
	([target].[upsidemult] <> [source].[upsidemult] OR ([target].[upsidemult] IS NULL AND [source].[upsidemult] IS NOT NULL) OR ([target].[upsidemult] IS NOT NULL AND [source].[upsidemult] IS NULL)) OR
	([target].[zs10price] <> [source].[zs10price] OR ([target].[zs10price] IS NULL AND [source].[zs10price] IS NOT NULL) OR ([target].[zs10price] IS NOT NULL AND [source].[zs10price] IS NULL)) OR
	([target].[zs10symbol] <> [source].[zs10symbol] OR ([target].[zs10symbol] IS NULL AND [source].[zs10symbol] IS NOT NULL) OR ([target].[zs10symbol] IS NOT NULL AND [source].[zs10symbol] IS NULL)) OR
	([target].[zs1price] <> [source].[zs1price] OR ([target].[zs1price] IS NULL AND [source].[zs1price] IS NOT NULL) OR ([target].[zs1price] IS NOT NULL AND [source].[zs1price] IS NULL)) OR
	([target].[zs1symbol] <> [source].[zs1symbol] OR ([target].[zs1symbol] IS NULL AND [source].[zs1symbol] IS NOT NULL) OR ([target].[zs1symbol] IS NOT NULL AND [source].[zs1symbol] IS NULL)) OR
	([target].[zs2price] <> [source].[zs2price] OR ([target].[zs2price] IS NULL AND [source].[zs2price] IS NOT NULL) OR ([target].[zs2price] IS NOT NULL AND [source].[zs2price] IS NULL)) OR
	([target].[zs2symbol] <> [source].[zs2symbol] OR ([target].[zs2symbol] IS NULL AND [source].[zs2symbol] IS NOT NULL) OR ([target].[zs2symbol] IS NOT NULL AND [source].[zs2symbol] IS NULL)) OR
	([target].[zs3price] <> [source].[zs3price] OR ([target].[zs3price] IS NULL AND [source].[zs3price] IS NOT NULL) OR ([target].[zs3price] IS NOT NULL AND [source].[zs3price] IS NULL)) OR
	([target].[zs3symbol] <> [source].[zs3symbol] OR ([target].[zs3symbol] IS NULL AND [source].[zs3symbol] IS NOT NULL) OR ([target].[zs3symbol] IS NOT NULL AND [source].[zs3symbol] IS NULL)) OR
	([target].[zs4price] <> [source].[zs4price] OR ([target].[zs4price] IS NULL AND [source].[zs4price] IS NOT NULL) OR ([target].[zs4price] IS NOT NULL AND [source].[zs4price] IS NULL)) OR
	([target].[zs4symbol] <> [source].[zs4symbol] OR ([target].[zs4symbol] IS NULL AND [source].[zs4symbol] IS NOT NULL) OR ([target].[zs4symbol] IS NOT NULL AND [source].[zs4symbol] IS NULL)) OR
	([target].[zs5price] <> [source].[zs5price] OR ([target].[zs5price] IS NULL AND [source].[zs5price] IS NOT NULL) OR ([target].[zs5price] IS NOT NULL AND [source].[zs5price] IS NULL)) OR
	([target].[zs5symbol] <> [source].[zs5symbol] OR ([target].[zs5symbol] IS NULL AND [source].[zs5symbol] IS NOT NULL) OR ([target].[zs5symbol] IS NOT NULL AND [source].[zs5symbol] IS NULL)) OR
	([target].[zs6price] <> [source].[zs6price] OR ([target].[zs6price] IS NULL AND [source].[zs6price] IS NOT NULL) OR ([target].[zs6price] IS NOT NULL AND [source].[zs6price] IS NULL)) OR
	([target].[zs6symbol] <> [source].[zs6symbol] OR ([target].[zs6symbol] IS NULL AND [source].[zs6symbol] IS NOT NULL) OR ([target].[zs6symbol] IS NOT NULL AND [source].[zs6symbol] IS NULL)) OR
	([target].[zs7price] <> [source].[zs7price] OR ([target].[zs7price] IS NULL AND [source].[zs7price] IS NOT NULL) OR ([target].[zs7price] IS NOT NULL AND [source].[zs7price] IS NULL)) OR
	([target].[zs7symbol] <> [source].[zs7symbol] OR ([target].[zs7symbol] IS NULL AND [source].[zs7symbol] IS NOT NULL) OR ([target].[zs7symbol] IS NOT NULL AND [source].[zs7symbol] IS NULL)) OR
	([target].[zs8price] <> [source].[zs8price] OR ([target].[zs8price] IS NULL AND [source].[zs8price] IS NOT NULL) OR ([target].[zs8price] IS NOT NULL AND [source].[zs8price] IS NULL)) OR
	([target].[zs8symbol] <> [source].[zs8symbol] OR ([target].[zs8symbol] IS NULL AND [source].[zs8symbol] IS NOT NULL) OR ([target].[zs8symbol] IS NOT NULL AND [source].[zs8symbol] IS NULL)) OR
	([target].[zs9price] <> [source].[zs9price] OR ([target].[zs9price] IS NULL AND [source].[zs9price] IS NOT NULL) OR ([target].[zs9price] IS NOT NULL AND [source].[zs9price] IS NULL)) OR
	([target].[zs9symbol] <> [source].[zs9symbol] OR ([target].[zs9symbol] IS NULL AND [source].[zs9symbol] IS NOT NULL) OR ([target].[zs9symbol] IS NOT NULL AND [source].[zs9symbol] IS NULL)) OR
	([target].[zshortprice] <> [source].[zshortprice] OR ([target].[zshortprice] IS NULL AND [source].[zshortprice] IS NOT NULL) OR ([target].[zshortprice] IS NOT NULL AND [source].[zshortprice] IS NULL))

)
	THEN UPDATE
	SET
		[ts_end] = @TimeStamp


	OUTPUT
		$Action as [MERGE_ACTION_ee8e6b09-864f-449f-8193-086ce4f5a733],
		[source].[acqsym] AS [acqsym],
		[source].[altclose] AS [altclose],
		[source].[altupside] AS [altupside],
		[source].[canbuy] AS [canbuy],
		[source].[cashamt] AS [cashamt],
		[source].[cashelect] AS [cashelect],
		[source].[cashpct] AS [cashpct],
		[source].[category] AS [category],
		[source].[charge] AS [charge],
		[source].[currency] AS [currency],
		[source].[d1date] AS [d1date],
		[source].[d2date] AS [d2date],
		[source].[dealamt] AS [dealamt],
		[source].[dealdisp] AS [dealdisp],
		[source].[dealname] AS [dealname],
		[source].[dealreport] AS [dealreport],
		[source].[defcanbuy] AS [defcanbuy],
		[source].[definitive] AS [definitive],
		[source].[desc] AS [desc],
		[source].[desc1] AS [desc1],
		[source].[downprice] AS [downprice],
		[source].[ds10price] AS [ds10price],
		[source].[ds10symbol] AS [ds10symbol],
		[source].[ds1price] AS [ds1price],
		[source].[ds1symbol] AS [ds1symbol],
		[source].[ds2price] AS [ds2price],
		[source].[ds2symbol] AS [ds2symbol],
		[source].[ds3price] AS [ds3price],
		[source].[ds3symbol] AS [ds3symbol],
		[source].[ds4price] AS [ds4price],
		[source].[ds4symbol] AS [ds4symbol],
		[source].[ds5price] AS [ds5price],
		[source].[ds5symbol] AS [ds5symbol],
		[source].[ds6price] AS [ds6price],
		[source].[ds6symbol] AS [ds6symbol],
		[source].[ds7price] AS [ds7price],
		[source].[ds7symbol] AS [ds7symbol],
		[source].[ds8price] AS [ds8price],
		[source].[ds8symbol] AS [ds8symbol],
		[source].[ds9price] AS [ds9price],
		[source].[ds9symbol] AS [ds9symbol],
		[source].[extracash] AS [extracash],
		[source].[highcollar] AS [highcollar],
		[source].[highrange] AS [highrange],
		[source].[initials1] AS [initials1],
		[source].[initials2] AS [initials2],
		[source].[lowcollar] AS [lowcollar],
		[source].[lowrange] AS [lowrange],
		[source].[nondefcanbuy] AS [nondefcanbuy],
		[source].[numadditional] AS [numadditional],
		[source].[origacq] AS [origacq],
		[source].[origprice] AS [origprice],
		[source].[other1] AS [other1],
		[source].[other2] AS [other2],
		[source].[other3] AS [other3],
		[source].[outflag] AS [outflag],
		[source].[outsidehigh] AS [outsidehigh],
		[source].[outsidelow] AS [outsidelow],
		[source].[prevadd1] AS [prevadd1],
		[source].[prevadd2] AS [prevadd2],
		[source].[prevadd3] AS [prevadd3],
		[source].[prevdown] AS [prevdown],
		[source].[prevzshort] AS [prevzshort],
		[source].[ratio] AS [ratio],
		[source].[residual] AS [residual],
		[source].[revcollar] AS [revcollar],
		[source].[secondtier] AS [secondtier],
		[source].[secsharesflag] AS [secsharesflag],
		[source].[stockpct] AS [stockpct],
		[source].[strategy] AS [strategy],
		[source].[tndrpct] AS [tndrpct],
		NULL AS [ts_end],
		@TimeStamp AS [ts_start],
		[source].[type] AS [type],
		[source].[undsym] AS [undsym],
		[source].[upsidemult] AS [upsidemult],
		[source].[zs10price] AS [zs10price],
		[source].[zs10symbol] AS [zs10symbol],
		[source].[zs1price] AS [zs1price],
		[source].[zs1symbol] AS [zs1symbol],
		[source].[zs2price] AS [zs2price],
		[source].[zs2symbol] AS [zs2symbol],
		[source].[zs3price] AS [zs3price],
		[source].[zs3symbol] AS [zs3symbol],
		[source].[zs4price] AS [zs4price],
		[source].[zs4symbol] AS [zs4symbol],
		[source].[zs5price] AS [zs5price],
		[source].[zs5symbol] AS [zs5symbol],
		[source].[zs6price] AS [zs6price],
		[source].[zs6symbol] AS [zs6symbol],
		[source].[zs7price] AS [zs7price],
		[source].[zs7symbol] AS [zs7symbol],
		[source].[zs8price] AS [zs8price],
		[source].[zs8symbol] AS [zs8symbol],
		[source].[zs9price] AS [zs9price],
		[source].[zs9symbol] AS [zs9symbol],
		[source].[zshortprice] AS [zshortprice]

)MERGE_OUTPUT
WHERE MERGE_OUTPUT.[MERGE_ACTION_ee8e6b09-864f-449f-8193-086ce4f5a733] = 'UPDATE' 
	AND MERGE_OUTPUT.[dealname] IS NOT NULL
;
COMMIT TRANSACTION merge_TMWDEALDB
END
GO
