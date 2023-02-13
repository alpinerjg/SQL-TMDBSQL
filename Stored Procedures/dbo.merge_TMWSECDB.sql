SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE   PROCEDURE [dbo].[merge_TMWSECDB] 
	@Timestamp datetime	
AS
BEGIN
BEGIN TRANSACTION merge_TMWSECDB

UPDATE t1 
SET t1.ts_end = @Timestamp
FROM [TMDBSQL].[dbo].[TMWSECDB] t1
LEFT JOIN [TMDBSQL].[dbo].[TMWSECDB_staging] t2 ON t2.symbol = t1.symbol
WHERE t1.ts_end IS NULL and t2.[symbol] IS NULL

-- ==================================================
-- Slowly Changing Dimension script by SCD Merge Wizard
-- Author: Miljan Radovic
-- Official web site: https://scdmergewizard.codeplex.com/
-- Version: 4.0.0.0
-- Publish date: 7/27/2013 10:29:11 AM
-- Script creation date: 4/7/2021 4:43:17 PM
-- ==================================================

-- ==================================================
-- SCD2
-- ==================================================

-- ==================================================
-- SCD1
-- ==================================================
MERGE [dbo].[TMWSECDB] as [target]
USING
(
	SELECT
		[accrualmethod],
		[active],
		[amountout],
		[analyst],
		[bucket],
		[calldate],
		[callprice],
		[cashpaydate],
		[cashpayrate],
		[condcalldate],
		[condcallprice],
		[condcalltodate],
		[country],
		[coupdate],
		[coupfreq],
		[coupon],
		[cprice],
		[currency],
		[cusip],
		[cvbuyprice],
		[cvprice],
		[cvsellprice],
		[dateddate],
		[descr],
		[divamt],
		[divdate],
		[divfreq],
		[divrollflag],
		[earnshare],
		[exchange],
		[exdate],
		[face],
		[hedge],
		[impvol],
		[industry],
		[intsymbol],
		[investval],
		[investvaltype],
		[invgrade],
		[issuedate],
		[lastcoupdate],
		[lastdivamt],
		[lastdivdate],
		[liveflag],
		[livemarkflag],
		[longmark],
		[longmarkcode],
		[longrate],
		[margin],
		[markdate],
		[markdate2],
		[memo],
		[modelhedge],
		[optoverrideflag],
		[portmgr],
		[prevexchange],
		[prevmark],
		[prevmark2],
		[priorcoupdate],
		[priordivamt],
		[priordivdate],
		[prmult],
		[putdate],
		[putprice],
		[puttodate],
		[qsymbol],
		[rating],
		[ratio],
		[ratioflag],
		[registeredflag],
		[screwflag],
		[secfeeflag],
		[secid],
		[sector],
		[sharesout],
		[shortmark],
		[shortmarkcode],
		[shortrate],
		[shortratecode],
		[sizequal],
		[sort],
		[sprice],
		[stkpctdowngrade],
		[stockatgrade],
		[strategy],
		[strike],
		[subtype],
		[swapflag],
		[symbol],
		[trader],
		[type],
		[undsym],
		[volatility1],
		[volatility2],
		[volatility3],
		[xlsymbol]
	FROM [dbo].[TMWSECDB_staging]
) as [source]
ON
(
	[source].[symbol] = [target].[symbol]
)

WHEN MATCHED AND
(
	[target].[ts_end] = NULL
)
AND
(
	([source].[longmark] <> [target].[longmark] OR ([source].[longmark] IS NULL AND [target].[longmark] IS NOT NULL) OR ([source].[longmark] IS NOT NULL AND [target].[longmark] IS NULL)) OR
	([source].[longrate] <> [target].[longrate] OR ([source].[longrate] IS NULL AND [target].[longrate] IS NOT NULL) OR ([source].[longrate] IS NOT NULL AND [target].[longrate] IS NULL)) OR
	([source].[shortmark] <> [target].[shortmark] OR ([source].[shortmark] IS NULL AND [target].[shortmark] IS NOT NULL) OR ([source].[shortmark] IS NOT NULL AND [target].[shortmark] IS NULL)) OR
	([source].[shortrate] <> [target].[shortrate] OR ([source].[shortrate] IS NULL AND [target].[shortrate] IS NOT NULL) OR ([source].[shortrate] IS NOT NULL AND [target].[shortrate] IS NULL))
)
AND
(
	([source].[accrualmethod] = [target].[accrualmethod] OR ([source].[accrualmethod] IS NULL AND [target].[accrualmethod] IS NULL)) AND
	([source].[active] = [target].[active] OR ([source].[active] IS NULL AND [target].[active] IS NULL)) AND
	([source].[amountout] = [target].[amountout] OR ([source].[amountout] IS NULL AND [target].[amountout] IS NULL)) AND
	([source].[analyst] = [target].[analyst] OR ([source].[analyst] IS NULL AND [target].[analyst] IS NULL)) AND
	([source].[bucket] = [target].[bucket] OR ([source].[bucket] IS NULL AND [target].[bucket] IS NULL)) AND
	([source].[calldate] = [target].[calldate] OR ([source].[calldate] IS NULL AND [target].[calldate] IS NULL)) AND
	([source].[callprice] = [target].[callprice] OR ([source].[callprice] IS NULL AND [target].[callprice] IS NULL)) AND
	([source].[cashpaydate] = [target].[cashpaydate] OR ([source].[cashpaydate] IS NULL AND [target].[cashpaydate] IS NULL)) AND
	([source].[cashpayrate] = [target].[cashpayrate] OR ([source].[cashpayrate] IS NULL AND [target].[cashpayrate] IS NULL)) AND
	([source].[condcalldate] = [target].[condcalldate] OR ([source].[condcalldate] IS NULL AND [target].[condcalldate] IS NULL)) AND
	([source].[condcallprice] = [target].[condcallprice] OR ([source].[condcallprice] IS NULL AND [target].[condcallprice] IS NULL)) AND
	([source].[condcalltodate] = [target].[condcalltodate] OR ([source].[condcalltodate] IS NULL AND [target].[condcalltodate] IS NULL)) AND
	([source].[country] = [target].[country] OR ([source].[country] IS NULL AND [target].[country] IS NULL)) AND
	([source].[coupdate] = [target].[coupdate] OR ([source].[coupdate] IS NULL AND [target].[coupdate] IS NULL)) AND
	([source].[coupfreq] = [target].[coupfreq] OR ([source].[coupfreq] IS NULL AND [target].[coupfreq] IS NULL)) AND
	([source].[coupon] = [target].[coupon] OR ([source].[coupon] IS NULL AND [target].[coupon] IS NULL)) AND
	([source].[cprice] = [target].[cprice] OR ([source].[cprice] IS NULL AND [target].[cprice] IS NULL)) AND
	([source].[currency] = [target].[currency] OR ([source].[currency] IS NULL AND [target].[currency] IS NULL)) AND
	([source].[cusip] = [target].[cusip] OR ([source].[cusip] IS NULL AND [target].[cusip] IS NULL)) AND
	([source].[cvbuyprice] = [target].[cvbuyprice] OR ([source].[cvbuyprice] IS NULL AND [target].[cvbuyprice] IS NULL)) AND
	([source].[cvprice] = [target].[cvprice] OR ([source].[cvprice] IS NULL AND [target].[cvprice] IS NULL)) AND
	([source].[cvsellprice] = [target].[cvsellprice] OR ([source].[cvsellprice] IS NULL AND [target].[cvsellprice] IS NULL)) AND
	([source].[dateddate] = [target].[dateddate] OR ([source].[dateddate] IS NULL AND [target].[dateddate] IS NULL)) AND
	([source].[descr] = [target].[descr] OR ([source].[descr] IS NULL AND [target].[descr] IS NULL)) AND
	([source].[divamt] = [target].[divamt] OR ([source].[divamt] IS NULL AND [target].[divamt] IS NULL)) AND
	([source].[divdate] = [target].[divdate] OR ([source].[divdate] IS NULL AND [target].[divdate] IS NULL)) AND
	([source].[divfreq] = [target].[divfreq] OR ([source].[divfreq] IS NULL AND [target].[divfreq] IS NULL)) AND
	([source].[divrollflag] = [target].[divrollflag] OR ([source].[divrollflag] IS NULL AND [target].[divrollflag] IS NULL)) AND
	([source].[earnshare] = [target].[earnshare] OR ([source].[earnshare] IS NULL AND [target].[earnshare] IS NULL)) AND
	([source].[exchange] = [target].[exchange] OR ([source].[exchange] IS NULL AND [target].[exchange] IS NULL)) AND
	([source].[exdate] = [target].[exdate] OR ([source].[exdate] IS NULL AND [target].[exdate] IS NULL)) AND
	([source].[face] = [target].[face] OR ([source].[face] IS NULL AND [target].[face] IS NULL)) AND
	([source].[hedge] = [target].[hedge] OR ([source].[hedge] IS NULL AND [target].[hedge] IS NULL)) AND
	([source].[impvol] = [target].[impvol] OR ([source].[impvol] IS NULL AND [target].[impvol] IS NULL)) AND
	([source].[industry] = [target].[industry] OR ([source].[industry] IS NULL AND [target].[industry] IS NULL)) AND
	([source].[intsymbol] = [target].[intsymbol] OR ([source].[intsymbol] IS NULL AND [target].[intsymbol] IS NULL)) AND
	([source].[investval] = [target].[investval] OR ([source].[investval] IS NULL AND [target].[investval] IS NULL)) AND
	([source].[investvaltype] = [target].[investvaltype] OR ([source].[investvaltype] IS NULL AND [target].[investvaltype] IS NULL)) AND
	([source].[invgrade] = [target].[invgrade] OR ([source].[invgrade] IS NULL AND [target].[invgrade] IS NULL)) AND
	([source].[issuedate] = [target].[issuedate] OR ([source].[issuedate] IS NULL AND [target].[issuedate] IS NULL)) AND
	([source].[lastcoupdate] = [target].[lastcoupdate] OR ([source].[lastcoupdate] IS NULL AND [target].[lastcoupdate] IS NULL)) AND
	([source].[lastdivamt] = [target].[lastdivamt] OR ([source].[lastdivamt] IS NULL AND [target].[lastdivamt] IS NULL)) AND
	([source].[lastdivdate] = [target].[lastdivdate] OR ([source].[lastdivdate] IS NULL AND [target].[lastdivdate] IS NULL)) AND
	([source].[liveflag] = [target].[liveflag] OR ([source].[liveflag] IS NULL AND [target].[liveflag] IS NULL)) AND
	([source].[livemarkflag] = [target].[livemarkflag] OR ([source].[livemarkflag] IS NULL AND [target].[livemarkflag] IS NULL)) AND
	([source].[longmarkcode] = [target].[longmarkcode] OR ([source].[longmarkcode] IS NULL AND [target].[longmarkcode] IS NULL)) AND
	([source].[margin] = [target].[margin] OR ([source].[margin] IS NULL AND [target].[margin] IS NULL)) AND
	([source].[markdate] = [target].[markdate] OR ([source].[markdate] IS NULL AND [target].[markdate] IS NULL)) AND
	([source].[markdate2] = [target].[markdate2] OR ([source].[markdate2] IS NULL AND [target].[markdate2] IS NULL)) AND
	([source].[memo] = [target].[memo] OR ([source].[memo] IS NULL AND [target].[memo] IS NULL)) AND
	([source].[modelhedge] = [target].[modelhedge] OR ([source].[modelhedge] IS NULL AND [target].[modelhedge] IS NULL)) AND
	([source].[optoverrideflag] = [target].[optoverrideflag] OR ([source].[optoverrideflag] IS NULL AND [target].[optoverrideflag] IS NULL)) AND
	([source].[portmgr] = [target].[portmgr] OR ([source].[portmgr] IS NULL AND [target].[portmgr] IS NULL)) AND
	([source].[prevexchange] = [target].[prevexchange] OR ([source].[prevexchange] IS NULL AND [target].[prevexchange] IS NULL)) AND
	([source].[prevmark] = [target].[prevmark] OR ([source].[prevmark] IS NULL AND [target].[prevmark] IS NULL)) AND
	([source].[prevmark2] = [target].[prevmark2] OR ([source].[prevmark2] IS NULL AND [target].[prevmark2] IS NULL)) AND
	([source].[priorcoupdate] = [target].[priorcoupdate] OR ([source].[priorcoupdate] IS NULL AND [target].[priorcoupdate] IS NULL)) AND
	([source].[priordivamt] = [target].[priordivamt] OR ([source].[priordivamt] IS NULL AND [target].[priordivamt] IS NULL)) AND
	([source].[priordivdate] = [target].[priordivdate] OR ([source].[priordivdate] IS NULL AND [target].[priordivdate] IS NULL)) AND
	([source].[prmult] = [target].[prmult] OR ([source].[prmult] IS NULL AND [target].[prmult] IS NULL)) AND
	([source].[putdate] = [target].[putdate] OR ([source].[putdate] IS NULL AND [target].[putdate] IS NULL)) AND
	([source].[putprice] = [target].[putprice] OR ([source].[putprice] IS NULL AND [target].[putprice] IS NULL)) AND
	([source].[puttodate] = [target].[puttodate] OR ([source].[puttodate] IS NULL AND [target].[puttodate] IS NULL)) AND
	([source].[qsymbol] = [target].[qsymbol] OR ([source].[qsymbol] IS NULL AND [target].[qsymbol] IS NULL)) AND
	([source].[rating] = [target].[rating] OR ([source].[rating] IS NULL AND [target].[rating] IS NULL)) AND
	([source].[ratio] = [target].[ratio] OR ([source].[ratio] IS NULL AND [target].[ratio] IS NULL)) AND
	([source].[ratioflag] = [target].[ratioflag] OR ([source].[ratioflag] IS NULL AND [target].[ratioflag] IS NULL)) AND
	([source].[registeredflag] = [target].[registeredflag] OR ([source].[registeredflag] IS NULL AND [target].[registeredflag] IS NULL)) AND
	([source].[screwflag] = [target].[screwflag] OR ([source].[screwflag] IS NULL AND [target].[screwflag] IS NULL)) AND
	([source].[secfeeflag] = [target].[secfeeflag] OR ([source].[secfeeflag] IS NULL AND [target].[secfeeflag] IS NULL)) AND
	([source].[secid] = [target].[secid] OR ([source].[secid] IS NULL AND [target].[secid] IS NULL)) AND
	([source].[sector] = [target].[sector] OR ([source].[sector] IS NULL AND [target].[sector] IS NULL)) AND
	([source].[sharesout] = [target].[sharesout] OR ([source].[sharesout] IS NULL AND [target].[sharesout] IS NULL)) AND
	([source].[shortmarkcode] = [target].[shortmarkcode] OR ([source].[shortmarkcode] IS NULL AND [target].[shortmarkcode] IS NULL)) AND
	([source].[shortratecode] = [target].[shortratecode] OR ([source].[shortratecode] IS NULL AND [target].[shortratecode] IS NULL)) AND
	([source].[sizequal] = [target].[sizequal] OR ([source].[sizequal] IS NULL AND [target].[sizequal] IS NULL)) AND
	([source].[sort] = [target].[sort] OR ([source].[sort] IS NULL AND [target].[sort] IS NULL)) AND
	([source].[sprice] = [target].[sprice] OR ([source].[sprice] IS NULL AND [target].[sprice] IS NULL)) AND
	([source].[stkpctdowngrade] = [target].[stkpctdowngrade] OR ([source].[stkpctdowngrade] IS NULL AND [target].[stkpctdowngrade] IS NULL)) AND
	([source].[stockatgrade] = [target].[stockatgrade] OR ([source].[stockatgrade] IS NULL AND [target].[stockatgrade] IS NULL)) AND
	([source].[strategy] = [target].[strategy] OR ([source].[strategy] IS NULL AND [target].[strategy] IS NULL)) AND
	([source].[strike] = [target].[strike] OR ([source].[strike] IS NULL AND [target].[strike] IS NULL)) AND
	([source].[subtype] = [target].[subtype] OR ([source].[subtype] IS NULL AND [target].[subtype] IS NULL)) AND
	([source].[swapflag] = [target].[swapflag] OR ([source].[swapflag] IS NULL AND [target].[swapflag] IS NULL)) AND
	([source].[trader] = [target].[trader] OR ([source].[trader] IS NULL AND [target].[trader] IS NULL)) AND
	([source].[type] = [target].[type] OR ([source].[type] IS NULL AND [target].[type] IS NULL)) AND
	([source].[undsym] = [target].[undsym] OR ([source].[undsym] IS NULL AND [target].[undsym] IS NULL)) AND
	([source].[volatility1] = [target].[volatility1] OR ([source].[volatility1] IS NULL AND [target].[volatility1] IS NULL)) AND
	([source].[volatility2] = [target].[volatility2] OR ([source].[volatility2] IS NULL AND [target].[volatility2] IS NULL)) AND
	([source].[volatility3] = [target].[volatility3] OR ([source].[volatility3] IS NULL AND [target].[volatility3] IS NULL)) AND
	([source].[xlsymbol] = [target].[xlsymbol] OR ([source].[xlsymbol] IS NULL AND [target].[xlsymbol] IS NULL))
)
THEN UPDATE
SET
	[target].[longmark] = [source].[longmark] ,
	[target].[longrate] = [source].[longrate] ,
	[target].[shortmark] = [source].[shortmark] ,
	[target].[shortrate] = [source].[shortrate]
;


-- ==================================================
-- SCD2
-- ==================================================
INSERT INTO [dbo].[TMWSECDB]
(
	[accrualmethod],
	[active],
	[amountout],
	[analyst],
	[bucket],
	[calldate],
	[callprice],
	[cashpaydate],
	[cashpayrate],
	[condcalldate],
	[condcallprice],
	[condcalltodate],
	[country],
	[coupdate],
	[coupfreq],
	[coupon],
	[cprice],
	[currency],
	[cusip],
	[cvbuyprice],
	[cvprice],
	[cvsellprice],
	[dateddate],
	[descr],
	[divamt],
	[divdate],
	[divfreq],
	[divrollflag],
	[earnshare],
	[exchange],
	[exdate],
	[face],
	[hedge],
	[impvol],
	[industry],
	[intsymbol],
	[investval],
	[investvaltype],
	[invgrade],
	[issuedate],
	[lastcoupdate],
	[lastdivamt],
	[lastdivdate],
	[liveflag],
	[livemarkflag],
	[longmark],
	[longmarkcode],
	[longrate],
	[margin],
	[markdate],
	[markdate2],
	[memo],
	[modelhedge],
	[optoverrideflag],
	[portmgr],
	[prevexchange],
	[prevmark],
	[prevmark2],
	[priorcoupdate],
	[priordivamt],
	[priordivdate],
	[prmult],
	[putdate],
	[putprice],
	[puttodate],
	[qsymbol],
	[rating],
	[ratio],
	[ratioflag],
	[registeredflag],
	[screwflag],
	[secfeeflag],
	[secid],
	[sector],
	[sharesout],
	[shortmark],
	[shortmarkcode],
	[shortrate],
	[shortratecode],
	[sizequal],
	[sort],
	[sprice],
	[stkpctdowngrade],
	[stockatgrade],
	[strategy],
	[strike],
	[subtype],
	[swapflag],
	[symbol],
	[trader],
	[ts_end],
	[ts_start],
	[type],
	[undsym],
	[volatility1],
	[volatility2],
	[volatility3],
	[xlsymbol]
)
SELECT
	[accrualmethod],
	[active],
	[amountout],
	[analyst],
	[bucket],
	[calldate],
	[callprice],
	[cashpaydate],
	[cashpayrate],
	[condcalldate],
	[condcallprice],
	[condcalltodate],
	[country],
	[coupdate],
	[coupfreq],
	[coupon],
	[cprice],
	[currency],
	[cusip],
	[cvbuyprice],
	[cvprice],
	[cvsellprice],
	[dateddate],
	[descr],
	[divamt],
	[divdate],
	[divfreq],
	[divrollflag],
	[earnshare],
	[exchange],
	[exdate],
	[face],
	[hedge],
	[impvol],
	[industry],
	[intsymbol],
	[investval],
	[investvaltype],
	[invgrade],
	[issuedate],
	[lastcoupdate],
	[lastdivamt],
	[lastdivdate],
	[liveflag],
	[livemarkflag],
	[longmark],
	[longmarkcode],
	[longrate],
	[margin],
	[markdate],
	[markdate2],
	[memo],
	[modelhedge],
	[optoverrideflag],
	[portmgr],
	[prevexchange],
	[prevmark],
	[prevmark2],
	[priorcoupdate],
	[priordivamt],
	[priordivdate],
	[prmult],
	[putdate],
	[putprice],
	[puttodate],
	[qsymbol],
	[rating],
	[ratio],
	[ratioflag],
	[registeredflag],
	[screwflag],
	[secfeeflag],
	[secid],
	[sector],
	[sharesout],
	[shortmark],
	[shortmarkcode],
	[shortrate],
	[shortratecode],
	[sizequal],
	[sort],
	[sprice],
	[stkpctdowngrade],
	[stockatgrade],
	[strategy],
	[strike],
	[subtype],
	[swapflag],
	[symbol],
	[trader],
	[ts_end],
	[ts_start],
	[type],
	[undsym],
	[volatility1],
	[volatility2],
	[volatility3],
	[xlsymbol]
FROM
(
	MERGE [dbo].[TMWSECDB] WITH (HOLDLOCK) as [target]
	USING
	(
		SELECT
			[accrualmethod],
			[active],
			[amountout],
			[analyst],
			[bucket],
			[calldate],
			[callprice],
			[cashpaydate],
			[cashpayrate],
			[condcalldate],
			[condcallprice],
			[condcalltodate],
			[country],
			[coupdate],
			[coupfreq],
			[coupon],
			[cprice],
			[currency],
			[cusip],
			[cvbuyprice],
			[cvprice],
			[cvsellprice],
			[dateddate],
			[descr],
			[divamt],
			[divdate],
			[divfreq],
			[divrollflag],
			[earnshare],
			[exchange],
			[exdate],
			[face],
			[hedge],
			[impvol],
			[industry],
			[intsymbol],
			[investval],
			[investvaltype],
			[invgrade],
			[issuedate],
			[lastcoupdate],
			[lastdivamt],
			[lastdivdate],
			[liveflag],
			[livemarkflag],
			[longmark],
			[longmarkcode],
			[longrate],
			[margin],
			[markdate],
			[markdate2],
			[memo],
			[modelhedge],
			[optoverrideflag],
			[portmgr],
			[prevexchange],
			[prevmark],
			[prevmark2],
			[priorcoupdate],
			[priordivamt],
			[priordivdate],
			[prmult],
			[putdate],
			[putprice],
			[puttodate],
			[qsymbol],
			[rating],
			[ratio],
			[ratioflag],
			[registeredflag],
			[screwflag],
			[secfeeflag],
			[secid],
			[sector],
			[sharesout],
			[shortmark],
			[shortmarkcode],
			[shortrate],
			[shortratecode],
			[sizequal],
			[sort],
			[sprice],
			[stkpctdowngrade],
			[stockatgrade],
			[strategy],
			[strike],
			[subtype],
			[swapflag],
			[symbol],
			[trader],
			[type],
			[undsym],
			[volatility1],
			[volatility2],
			[volatility3],
			[xlsymbol]
		FROM [dbo].[TMWSECDB_staging]

	) as [source]
	ON
	(
		[source].[symbol] = [target].[symbol]
	)

	WHEN NOT MATCHED BY TARGET
	THEN INSERT
	(
		[accrualmethod],
		[active],
		[amountout],
		[analyst],
		[bucket],
		[calldate],
		[callprice],
		[cashpaydate],
		[cashpayrate],
		[condcalldate],
		[condcallprice],
		[condcalltodate],
		[country],
		[coupdate],
		[coupfreq],
		[coupon],
		[cprice],
		[currency],
		[cusip],
		[cvbuyprice],
		[cvprice],
		[cvsellprice],
		[dateddate],
		[descr],
		[divamt],
		[divdate],
		[divfreq],
		[divrollflag],
		[earnshare],
		[exchange],
		[exdate],
		[face],
		[hedge],
		[impvol],
		[industry],
		[intsymbol],
		[investval],
		[investvaltype],
		[invgrade],
		[issuedate],
		[lastcoupdate],
		[lastdivamt],
		[lastdivdate],
		[liveflag],
		[livemarkflag],
		[longmark],
		[longmarkcode],
		[longrate],
		[margin],
		[markdate],
		[markdate2],
		[memo],
		[modelhedge],
		[optoverrideflag],
		[portmgr],
		[prevexchange],
		[prevmark],
		[prevmark2],
		[priorcoupdate],
		[priordivamt],
		[priordivdate],
		[prmult],
		[putdate],
		[putprice],
		[puttodate],
		[qsymbol],
		[rating],
		[ratio],
		[ratioflag],
		[registeredflag],
		[screwflag],
		[secfeeflag],
		[secid],
		[sector],
		[sharesout],
		[shortmark],
		[shortmarkcode],
		[shortrate],
		[shortratecode],
		[sizequal],
		[sort],
		[sprice],
		[stkpctdowngrade],
		[stockatgrade],
		[strategy],
		[strike],
		[subtype],
		[swapflag],
		[symbol],
		[trader],
		[ts_end],
		[ts_start],
		[type],
		[undsym],
		[volatility1],
		[volatility2],
		[volatility3],
		[xlsymbol]
	)
	VALUES
	(
		[accrualmethod],
		[active],
		[amountout],
		[analyst],
		[bucket],
		[calldate],
		[callprice],
		[cashpaydate],
		[cashpayrate],
		[condcalldate],
		[condcallprice],
		[condcalltodate],
		[country],
		[coupdate],
		[coupfreq],
		[coupon],
		[cprice],
		[currency],
		[cusip],
		[cvbuyprice],
		[cvprice],
		[cvsellprice],
		[dateddate],
		[descr],
		[divamt],
		[divdate],
		[divfreq],
		[divrollflag],
		[earnshare],
		[exchange],
		[exdate],
		[face],
		[hedge],
		[impvol],
		[industry],
		[intsymbol],
		[investval],
		[investvaltype],
		[invgrade],
		[issuedate],
		[lastcoupdate],
		[lastdivamt],
		[lastdivdate],
		[liveflag],
		[livemarkflag],
		[longmark],
		[longmarkcode],
		[longrate],
		[margin],
		[markdate],
		[markdate2],
		[memo],
		[modelhedge],
		[optoverrideflag],
		[portmgr],
		[prevexchange],
		[prevmark],
		[prevmark2],
		[priorcoupdate],
		[priordivamt],
		[priordivdate],
		[prmult],
		[putdate],
		[putprice],
		[puttodate],
		[qsymbol],
		[rating],
		[ratio],
		[ratioflag],
		[registeredflag],
		[screwflag],
		[secfeeflag],
		[secid],
		[sector],
		[sharesout],
		[shortmark],
		[shortmarkcode],
		[shortrate],
		[shortratecode],
		[sizequal],
		[sort],
		[sprice],
		[stkpctdowngrade],
		[stockatgrade],
		[strategy],
		[strike],
		[subtype],
		[swapflag],
		[symbol],
		[trader],
		NULL,
		@TimeStamp,
		[type],
		[undsym],
		[volatility1],
		[volatility2],
		[volatility3],
		[xlsymbol]
	)


WHEN MATCHED AND
(
	[ts_end] = NULL
)
AND
(
	([target].[accrualmethod] <> [source].[accrualmethod] OR ([target].[accrualmethod] IS NULL AND [source].[accrualmethod] IS NOT NULL) OR ([target].[accrualmethod] IS NOT NULL AND [source].[accrualmethod] IS NULL)) OR
	([target].[active] <> [source].[active] OR ([target].[active] IS NULL AND [source].[active] IS NOT NULL) OR ([target].[active] IS NOT NULL AND [source].[active] IS NULL)) OR
	([target].[amountout] <> [source].[amountout] OR ([target].[amountout] IS NULL AND [source].[amountout] IS NOT NULL) OR ([target].[amountout] IS NOT NULL AND [source].[amountout] IS NULL)) OR
	([target].[analyst] <> [source].[analyst] OR ([target].[analyst] IS NULL AND [source].[analyst] IS NOT NULL) OR ([target].[analyst] IS NOT NULL AND [source].[analyst] IS NULL)) OR
	([target].[bucket] <> [source].[bucket] OR ([target].[bucket] IS NULL AND [source].[bucket] IS NOT NULL) OR ([target].[bucket] IS NOT NULL AND [source].[bucket] IS NULL)) OR
	([target].[calldate] <> [source].[calldate] OR ([target].[calldate] IS NULL AND [source].[calldate] IS NOT NULL) OR ([target].[calldate] IS NOT NULL AND [source].[calldate] IS NULL)) OR
	([target].[callprice] <> [source].[callprice] OR ([target].[callprice] IS NULL AND [source].[callprice] IS NOT NULL) OR ([target].[callprice] IS NOT NULL AND [source].[callprice] IS NULL)) OR
	([target].[cashpaydate] <> [source].[cashpaydate] OR ([target].[cashpaydate] IS NULL AND [source].[cashpaydate] IS NOT NULL) OR ([target].[cashpaydate] IS NOT NULL AND [source].[cashpaydate] IS NULL)) OR
	([target].[cashpayrate] <> [source].[cashpayrate] OR ([target].[cashpayrate] IS NULL AND [source].[cashpayrate] IS NOT NULL) OR ([target].[cashpayrate] IS NOT NULL AND [source].[cashpayrate] IS NULL)) OR
	([target].[condcalldate] <> [source].[condcalldate] OR ([target].[condcalldate] IS NULL AND [source].[condcalldate] IS NOT NULL) OR ([target].[condcalldate] IS NOT NULL AND [source].[condcalldate] IS NULL)) OR
	([target].[condcallprice] <> [source].[condcallprice] OR ([target].[condcallprice] IS NULL AND [source].[condcallprice] IS NOT NULL) OR ([target].[condcallprice] IS NOT NULL AND [source].[condcallprice] IS NULL)) OR
	([target].[condcalltodate] <> [source].[condcalltodate] OR ([target].[condcalltodate] IS NULL AND [source].[condcalltodate] IS NOT NULL) OR ([target].[condcalltodate] IS NOT NULL AND [source].[condcalltodate] IS NULL)) OR
	([target].[country] <> [source].[country] OR ([target].[country] IS NULL AND [source].[country] IS NOT NULL) OR ([target].[country] IS NOT NULL AND [source].[country] IS NULL)) OR
	([target].[coupdate] <> [source].[coupdate] OR ([target].[coupdate] IS NULL AND [source].[coupdate] IS NOT NULL) OR ([target].[coupdate] IS NOT NULL AND [source].[coupdate] IS NULL)) OR
	([target].[coupfreq] <> [source].[coupfreq] OR ([target].[coupfreq] IS NULL AND [source].[coupfreq] IS NOT NULL) OR ([target].[coupfreq] IS NOT NULL AND [source].[coupfreq] IS NULL)) OR
	([target].[coupon] <> [source].[coupon] OR ([target].[coupon] IS NULL AND [source].[coupon] IS NOT NULL) OR ([target].[coupon] IS NOT NULL AND [source].[coupon] IS NULL)) OR
	([target].[cprice] <> [source].[cprice] OR ([target].[cprice] IS NULL AND [source].[cprice] IS NOT NULL) OR ([target].[cprice] IS NOT NULL AND [source].[cprice] IS NULL)) OR
	([target].[currency] <> [source].[currency] OR ([target].[currency] IS NULL AND [source].[currency] IS NOT NULL) OR ([target].[currency] IS NOT NULL AND [source].[currency] IS NULL)) OR
	([target].[cusip] <> [source].[cusip] OR ([target].[cusip] IS NULL AND [source].[cusip] IS NOT NULL) OR ([target].[cusip] IS NOT NULL AND [source].[cusip] IS NULL)) OR
	([target].[cvbuyprice] <> [source].[cvbuyprice] OR ([target].[cvbuyprice] IS NULL AND [source].[cvbuyprice] IS NOT NULL) OR ([target].[cvbuyprice] IS NOT NULL AND [source].[cvbuyprice] IS NULL)) OR
	([target].[cvprice] <> [source].[cvprice] OR ([target].[cvprice] IS NULL AND [source].[cvprice] IS NOT NULL) OR ([target].[cvprice] IS NOT NULL AND [source].[cvprice] IS NULL)) OR
	([target].[cvsellprice] <> [source].[cvsellprice] OR ([target].[cvsellprice] IS NULL AND [source].[cvsellprice] IS NOT NULL) OR ([target].[cvsellprice] IS NOT NULL AND [source].[cvsellprice] IS NULL)) OR
	([target].[dateddate] <> [source].[dateddate] OR ([target].[dateddate] IS NULL AND [source].[dateddate] IS NOT NULL) OR ([target].[dateddate] IS NOT NULL AND [source].[dateddate] IS NULL)) OR
	([target].[descr] <> [source].[descr] OR ([target].[descr] IS NULL AND [source].[descr] IS NOT NULL) OR ([target].[descr] IS NOT NULL AND [source].[descr] IS NULL)) OR
	([target].[divamt] <> [source].[divamt] OR ([target].[divamt] IS NULL AND [source].[divamt] IS NOT NULL) OR ([target].[divamt] IS NOT NULL AND [source].[divamt] IS NULL)) OR
	([target].[divdate] <> [source].[divdate] OR ([target].[divdate] IS NULL AND [source].[divdate] IS NOT NULL) OR ([target].[divdate] IS NOT NULL AND [source].[divdate] IS NULL)) OR
	([target].[divfreq] <> [source].[divfreq] OR ([target].[divfreq] IS NULL AND [source].[divfreq] IS NOT NULL) OR ([target].[divfreq] IS NOT NULL AND [source].[divfreq] IS NULL)) OR
	([target].[divrollflag] <> [source].[divrollflag] OR ([target].[divrollflag] IS NULL AND [source].[divrollflag] IS NOT NULL) OR ([target].[divrollflag] IS NOT NULL AND [source].[divrollflag] IS NULL)) OR
	([target].[earnshare] <> [source].[earnshare] OR ([target].[earnshare] IS NULL AND [source].[earnshare] IS NOT NULL) OR ([target].[earnshare] IS NOT NULL AND [source].[earnshare] IS NULL)) OR
	([target].[exchange] <> [source].[exchange] OR ([target].[exchange] IS NULL AND [source].[exchange] IS NOT NULL) OR ([target].[exchange] IS NOT NULL AND [source].[exchange] IS NULL)) OR
	([target].[exdate] <> [source].[exdate] OR ([target].[exdate] IS NULL AND [source].[exdate] IS NOT NULL) OR ([target].[exdate] IS NOT NULL AND [source].[exdate] IS NULL)) OR
	([target].[face] <> [source].[face] OR ([target].[face] IS NULL AND [source].[face] IS NOT NULL) OR ([target].[face] IS NOT NULL AND [source].[face] IS NULL)) OR
	([target].[hedge] <> [source].[hedge] OR ([target].[hedge] IS NULL AND [source].[hedge] IS NOT NULL) OR ([target].[hedge] IS NOT NULL AND [source].[hedge] IS NULL)) OR
	([target].[impvol] <> [source].[impvol] OR ([target].[impvol] IS NULL AND [source].[impvol] IS NOT NULL) OR ([target].[impvol] IS NOT NULL AND [source].[impvol] IS NULL)) OR
	([target].[industry] <> [source].[industry] OR ([target].[industry] IS NULL AND [source].[industry] IS NOT NULL) OR ([target].[industry] IS NOT NULL AND [source].[industry] IS NULL)) OR
	([target].[intsymbol] <> [source].[intsymbol] OR ([target].[intsymbol] IS NULL AND [source].[intsymbol] IS NOT NULL) OR ([target].[intsymbol] IS NOT NULL AND [source].[intsymbol] IS NULL)) OR
	([target].[investval] <> [source].[investval] OR ([target].[investval] IS NULL AND [source].[investval] IS NOT NULL) OR ([target].[investval] IS NOT NULL AND [source].[investval] IS NULL)) OR
	([target].[investvaltype] <> [source].[investvaltype] OR ([target].[investvaltype] IS NULL AND [source].[investvaltype] IS NOT NULL) OR ([target].[investvaltype] IS NOT NULL AND [source].[investvaltype] IS NULL)) OR
	([target].[invgrade] <> [source].[invgrade] OR ([target].[invgrade] IS NULL AND [source].[invgrade] IS NOT NULL) OR ([target].[invgrade] IS NOT NULL AND [source].[invgrade] IS NULL)) OR
	([target].[issuedate] <> [source].[issuedate] OR ([target].[issuedate] IS NULL AND [source].[issuedate] IS NOT NULL) OR ([target].[issuedate] IS NOT NULL AND [source].[issuedate] IS NULL)) OR
	([target].[lastcoupdate] <> [source].[lastcoupdate] OR ([target].[lastcoupdate] IS NULL AND [source].[lastcoupdate] IS NOT NULL) OR ([target].[lastcoupdate] IS NOT NULL AND [source].[lastcoupdate] IS NULL)) OR
	([target].[lastdivamt] <> [source].[lastdivamt] OR ([target].[lastdivamt] IS NULL AND [source].[lastdivamt] IS NOT NULL) OR ([target].[lastdivamt] IS NOT NULL AND [source].[lastdivamt] IS NULL)) OR
	([target].[lastdivdate] <> [source].[lastdivdate] OR ([target].[lastdivdate] IS NULL AND [source].[lastdivdate] IS NOT NULL) OR ([target].[lastdivdate] IS NOT NULL AND [source].[lastdivdate] IS NULL)) OR
	([target].[liveflag] <> [source].[liveflag] OR ([target].[liveflag] IS NULL AND [source].[liveflag] IS NOT NULL) OR ([target].[liveflag] IS NOT NULL AND [source].[liveflag] IS NULL)) OR
	([target].[livemarkflag] <> [source].[livemarkflag] OR ([target].[livemarkflag] IS NULL AND [source].[livemarkflag] IS NOT NULL) OR ([target].[livemarkflag] IS NOT NULL AND [source].[livemarkflag] IS NULL)) OR
	([target].[longmarkcode] <> [source].[longmarkcode] OR ([target].[longmarkcode] IS NULL AND [source].[longmarkcode] IS NOT NULL) OR ([target].[longmarkcode] IS NOT NULL AND [source].[longmarkcode] IS NULL)) OR
	([target].[margin] <> [source].[margin] OR ([target].[margin] IS NULL AND [source].[margin] IS NOT NULL) OR ([target].[margin] IS NOT NULL AND [source].[margin] IS NULL)) OR
	([target].[markdate] <> [source].[markdate] OR ([target].[markdate] IS NULL AND [source].[markdate] IS NOT NULL) OR ([target].[markdate] IS NOT NULL AND [source].[markdate] IS NULL)) OR
	([target].[markdate2] <> [source].[markdate2] OR ([target].[markdate2] IS NULL AND [source].[markdate2] IS NOT NULL) OR ([target].[markdate2] IS NOT NULL AND [source].[markdate2] IS NULL)) OR
	([target].[memo] <> [source].[memo] OR ([target].[memo] IS NULL AND [source].[memo] IS NOT NULL) OR ([target].[memo] IS NOT NULL AND [source].[memo] IS NULL)) OR
	([target].[modelhedge] <> [source].[modelhedge] OR ([target].[modelhedge] IS NULL AND [source].[modelhedge] IS NOT NULL) OR ([target].[modelhedge] IS NOT NULL AND [source].[modelhedge] IS NULL)) OR
	([target].[optoverrideflag] <> [source].[optoverrideflag] OR ([target].[optoverrideflag] IS NULL AND [source].[optoverrideflag] IS NOT NULL) OR ([target].[optoverrideflag] IS NOT NULL AND [source].[optoverrideflag] IS NULL)) OR
	([target].[portmgr] <> [source].[portmgr] OR ([target].[portmgr] IS NULL AND [source].[portmgr] IS NOT NULL) OR ([target].[portmgr] IS NOT NULL AND [source].[portmgr] IS NULL)) OR
	([target].[prevexchange] <> [source].[prevexchange] OR ([target].[prevexchange] IS NULL AND [source].[prevexchange] IS NOT NULL) OR ([target].[prevexchange] IS NOT NULL AND [source].[prevexchange] IS NULL)) OR
	([target].[prevmark] <> [source].[prevmark] OR ([target].[prevmark] IS NULL AND [source].[prevmark] IS NOT NULL) OR ([target].[prevmark] IS NOT NULL AND [source].[prevmark] IS NULL)) OR
	([target].[prevmark2] <> [source].[prevmark2] OR ([target].[prevmark2] IS NULL AND [source].[prevmark2] IS NOT NULL) OR ([target].[prevmark2] IS NOT NULL AND [source].[prevmark2] IS NULL)) OR
	([target].[priorcoupdate] <> [source].[priorcoupdate] OR ([target].[priorcoupdate] IS NULL AND [source].[priorcoupdate] IS NOT NULL) OR ([target].[priorcoupdate] IS NOT NULL AND [source].[priorcoupdate] IS NULL)) OR
	([target].[priordivamt] <> [source].[priordivamt] OR ([target].[priordivamt] IS NULL AND [source].[priordivamt] IS NOT NULL) OR ([target].[priordivamt] IS NOT NULL AND [source].[priordivamt] IS NULL)) OR
	([target].[priordivdate] <> [source].[priordivdate] OR ([target].[priordivdate] IS NULL AND [source].[priordivdate] IS NOT NULL) OR ([target].[priordivdate] IS NOT NULL AND [source].[priordivdate] IS NULL)) OR
	([target].[prmult] <> [source].[prmult] OR ([target].[prmult] IS NULL AND [source].[prmult] IS NOT NULL) OR ([target].[prmult] IS NOT NULL AND [source].[prmult] IS NULL)) OR
	([target].[putdate] <> [source].[putdate] OR ([target].[putdate] IS NULL AND [source].[putdate] IS NOT NULL) OR ([target].[putdate] IS NOT NULL AND [source].[putdate] IS NULL)) OR
	([target].[putprice] <> [source].[putprice] OR ([target].[putprice] IS NULL AND [source].[putprice] IS NOT NULL) OR ([target].[putprice] IS NOT NULL AND [source].[putprice] IS NULL)) OR
	([target].[puttodate] <> [source].[puttodate] OR ([target].[puttodate] IS NULL AND [source].[puttodate] IS NOT NULL) OR ([target].[puttodate] IS NOT NULL AND [source].[puttodate] IS NULL)) OR
	([target].[qsymbol] <> [source].[qsymbol] OR ([target].[qsymbol] IS NULL AND [source].[qsymbol] IS NOT NULL) OR ([target].[qsymbol] IS NOT NULL AND [source].[qsymbol] IS NULL)) OR
	([target].[rating] <> [source].[rating] OR ([target].[rating] IS NULL AND [source].[rating] IS NOT NULL) OR ([target].[rating] IS NOT NULL AND [source].[rating] IS NULL)) OR
	([target].[ratio] <> [source].[ratio] OR ([target].[ratio] IS NULL AND [source].[ratio] IS NOT NULL) OR ([target].[ratio] IS NOT NULL AND [source].[ratio] IS NULL)) OR
	([target].[ratioflag] <> [source].[ratioflag] OR ([target].[ratioflag] IS NULL AND [source].[ratioflag] IS NOT NULL) OR ([target].[ratioflag] IS NOT NULL AND [source].[ratioflag] IS NULL)) OR
	([target].[registeredflag] <> [source].[registeredflag] OR ([target].[registeredflag] IS NULL AND [source].[registeredflag] IS NOT NULL) OR ([target].[registeredflag] IS NOT NULL AND [source].[registeredflag] IS NULL)) OR
	([target].[screwflag] <> [source].[screwflag] OR ([target].[screwflag] IS NULL AND [source].[screwflag] IS NOT NULL) OR ([target].[screwflag] IS NOT NULL AND [source].[screwflag] IS NULL)) OR
	([target].[secfeeflag] <> [source].[secfeeflag] OR ([target].[secfeeflag] IS NULL AND [source].[secfeeflag] IS NOT NULL) OR ([target].[secfeeflag] IS NOT NULL AND [source].[secfeeflag] IS NULL)) OR
	([target].[secid] <> [source].[secid] OR ([target].[secid] IS NULL AND [source].[secid] IS NOT NULL) OR ([target].[secid] IS NOT NULL AND [source].[secid] IS NULL)) OR
	([target].[sector] <> [source].[sector] OR ([target].[sector] IS NULL AND [source].[sector] IS NOT NULL) OR ([target].[sector] IS NOT NULL AND [source].[sector] IS NULL)) OR
	([target].[sharesout] <> [source].[sharesout] OR ([target].[sharesout] IS NULL AND [source].[sharesout] IS NOT NULL) OR ([target].[sharesout] IS NOT NULL AND [source].[sharesout] IS NULL)) OR
	([target].[shortmarkcode] <> [source].[shortmarkcode] OR ([target].[shortmarkcode] IS NULL AND [source].[shortmarkcode] IS NOT NULL) OR ([target].[shortmarkcode] IS NOT NULL AND [source].[shortmarkcode] IS NULL)) OR
	([target].[shortratecode] <> [source].[shortratecode] OR ([target].[shortratecode] IS NULL AND [source].[shortratecode] IS NOT NULL) OR ([target].[shortratecode] IS NOT NULL AND [source].[shortratecode] IS NULL)) OR
	([target].[sizequal] <> [source].[sizequal] OR ([target].[sizequal] IS NULL AND [source].[sizequal] IS NOT NULL) OR ([target].[sizequal] IS NOT NULL AND [source].[sizequal] IS NULL)) OR
	([target].[sort] <> [source].[sort] OR ([target].[sort] IS NULL AND [source].[sort] IS NOT NULL) OR ([target].[sort] IS NOT NULL AND [source].[sort] IS NULL)) OR
	([target].[sprice] <> [source].[sprice] OR ([target].[sprice] IS NULL AND [source].[sprice] IS NOT NULL) OR ([target].[sprice] IS NOT NULL AND [source].[sprice] IS NULL)) OR
	([target].[stkpctdowngrade] <> [source].[stkpctdowngrade] OR ([target].[stkpctdowngrade] IS NULL AND [source].[stkpctdowngrade] IS NOT NULL) OR ([target].[stkpctdowngrade] IS NOT NULL AND [source].[stkpctdowngrade] IS NULL)) OR
	([target].[stockatgrade] <> [source].[stockatgrade] OR ([target].[stockatgrade] IS NULL AND [source].[stockatgrade] IS NOT NULL) OR ([target].[stockatgrade] IS NOT NULL AND [source].[stockatgrade] IS NULL)) OR
	([target].[strategy] <> [source].[strategy] OR ([target].[strategy] IS NULL AND [source].[strategy] IS NOT NULL) OR ([target].[strategy] IS NOT NULL AND [source].[strategy] IS NULL)) OR
	([target].[strike] <> [source].[strike] OR ([target].[strike] IS NULL AND [source].[strike] IS NOT NULL) OR ([target].[strike] IS NOT NULL AND [source].[strike] IS NULL)) OR
	([target].[subtype] <> [source].[subtype] OR ([target].[subtype] IS NULL AND [source].[subtype] IS NOT NULL) OR ([target].[subtype] IS NOT NULL AND [source].[subtype] IS NULL)) OR
	([target].[swapflag] <> [source].[swapflag] OR ([target].[swapflag] IS NULL AND [source].[swapflag] IS NOT NULL) OR ([target].[swapflag] IS NOT NULL AND [source].[swapflag] IS NULL)) OR
	([target].[trader] <> [source].[trader] OR ([target].[trader] IS NULL AND [source].[trader] IS NOT NULL) OR ([target].[trader] IS NOT NULL AND [source].[trader] IS NULL)) OR
	([target].[type] <> [source].[type] OR ([target].[type] IS NULL AND [source].[type] IS NOT NULL) OR ([target].[type] IS NOT NULL AND [source].[type] IS NULL)) OR
	([target].[undsym] <> [source].[undsym] OR ([target].[undsym] IS NULL AND [source].[undsym] IS NOT NULL) OR ([target].[undsym] IS NOT NULL AND [source].[undsym] IS NULL)) OR
	([target].[volatility1] <> [source].[volatility1] OR ([target].[volatility1] IS NULL AND [source].[volatility1] IS NOT NULL) OR ([target].[volatility1] IS NOT NULL AND [source].[volatility1] IS NULL)) OR
	([target].[volatility2] <> [source].[volatility2] OR ([target].[volatility2] IS NULL AND [source].[volatility2] IS NOT NULL) OR ([target].[volatility2] IS NOT NULL AND [source].[volatility2] IS NULL)) OR
	([target].[volatility3] <> [source].[volatility3] OR ([target].[volatility3] IS NULL AND [source].[volatility3] IS NOT NULL) OR ([target].[volatility3] IS NOT NULL AND [source].[volatility3] IS NULL)) OR
	([target].[xlsymbol] <> [source].[xlsymbol] OR ([target].[xlsymbol] IS NULL AND [source].[xlsymbol] IS NOT NULL) OR ([target].[xlsymbol] IS NOT NULL AND [source].[xlsymbol] IS NULL))

)
	THEN UPDATE
	SET
		[ts_end] = @TimeStamp


	OUTPUT
		$Action as [MERGE_ACTION_fac14995-ec53-4856-b97b-0a85698d6b4f],
		[source].[accrualmethod] AS [accrualmethod],
		[source].[active] AS [active],
		[source].[amountout] AS [amountout],
		[source].[analyst] AS [analyst],
		[source].[bucket] AS [bucket],
		[source].[calldate] AS [calldate],
		[source].[callprice] AS [callprice],
		[source].[cashpaydate] AS [cashpaydate],
		[source].[cashpayrate] AS [cashpayrate],
		[source].[condcalldate] AS [condcalldate],
		[source].[condcallprice] AS [condcallprice],
		[source].[condcalltodate] AS [condcalltodate],
		[source].[country] AS [country],
		[source].[coupdate] AS [coupdate],
		[source].[coupfreq] AS [coupfreq],
		[source].[coupon] AS [coupon],
		[source].[cprice] AS [cprice],
		[source].[currency] AS [currency],
		[source].[cusip] AS [cusip],
		[source].[cvbuyprice] AS [cvbuyprice],
		[source].[cvprice] AS [cvprice],
		[source].[cvsellprice] AS [cvsellprice],
		[source].[dateddate] AS [dateddate],
		[source].[descr] AS [descr],
		[source].[divamt] AS [divamt],
		[source].[divdate] AS [divdate],
		[source].[divfreq] AS [divfreq],
		[source].[divrollflag] AS [divrollflag],
		[source].[earnshare] AS [earnshare],
		[source].[exchange] AS [exchange],
		[source].[exdate] AS [exdate],
		[source].[face] AS [face],
		[source].[hedge] AS [hedge],
		[source].[impvol] AS [impvol],
		[source].[industry] AS [industry],
		[source].[intsymbol] AS [intsymbol],
		[source].[investval] AS [investval],
		[source].[investvaltype] AS [investvaltype],
		[source].[invgrade] AS [invgrade],
		[source].[issuedate] AS [issuedate],
		[source].[lastcoupdate] AS [lastcoupdate],
		[source].[lastdivamt] AS [lastdivamt],
		[source].[lastdivdate] AS [lastdivdate],
		[source].[liveflag] AS [liveflag],
		[source].[livemarkflag] AS [livemarkflag],
		[source].[longmark] AS [longmark],
		[source].[longmarkcode] AS [longmarkcode],
		[source].[longrate] AS [longrate],
		[source].[margin] AS [margin],
		[source].[markdate] AS [markdate],
		[source].[markdate2] AS [markdate2],
		[source].[memo] AS [memo],
		[source].[modelhedge] AS [modelhedge],
		[source].[optoverrideflag] AS [optoverrideflag],
		[source].[portmgr] AS [portmgr],
		[source].[prevexchange] AS [prevexchange],
		[source].[prevmark] AS [prevmark],
		[source].[prevmark2] AS [prevmark2],
		[source].[priorcoupdate] AS [priorcoupdate],
		[source].[priordivamt] AS [priordivamt],
		[source].[priordivdate] AS [priordivdate],
		[source].[prmult] AS [prmult],
		[source].[putdate] AS [putdate],
		[source].[putprice] AS [putprice],
		[source].[puttodate] AS [puttodate],
		[source].[qsymbol] AS [qsymbol],
		[source].[rating] AS [rating],
		[source].[ratio] AS [ratio],
		[source].[ratioflag] AS [ratioflag],
		[source].[registeredflag] AS [registeredflag],
		[source].[screwflag] AS [screwflag],
		[source].[secfeeflag] AS [secfeeflag],
		[source].[secid] AS [secid],
		[source].[sector] AS [sector],
		[source].[sharesout] AS [sharesout],
		[source].[shortmark] AS [shortmark],
		[source].[shortmarkcode] AS [shortmarkcode],
		[source].[shortrate] AS [shortrate],
		[source].[shortratecode] AS [shortratecode],
		[source].[sizequal] AS [sizequal],
		[source].[sort] AS [sort],
		[source].[sprice] AS [sprice],
		[source].[stkpctdowngrade] AS [stkpctdowngrade],
		[source].[stockatgrade] AS [stockatgrade],
		[source].[strategy] AS [strategy],
		[source].[strike] AS [strike],
		[source].[subtype] AS [subtype],
		[source].[swapflag] AS [swapflag],
		[source].[symbol] AS [symbol],
		[source].[trader] AS [trader],
		NULL AS [ts_end],
		@TimeStamp AS [ts_start],
		[source].[type] AS [type],
		[source].[undsym] AS [undsym],
		[source].[volatility1] AS [volatility1],
		[source].[volatility2] AS [volatility2],
		[source].[volatility3] AS [volatility3],
		[source].[xlsymbol] AS [xlsymbol]

)MERGE_OUTPUT
WHERE MERGE_OUTPUT.[MERGE_ACTION_fac14995-ec53-4856-b97b-0a85698d6b4f] = 'UPDATE' 
	AND MERGE_OUTPUT.[symbol] IS NOT NULL
;
COMMIT TRANSACTION merge_TMWSECDB
END
GO
