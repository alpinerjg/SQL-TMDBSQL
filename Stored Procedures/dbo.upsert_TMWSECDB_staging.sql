SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[upsert_TMWSECDB_staging] 
	 @Timestamp datetime ,
	 @symbol varchar(15) ,
	 @cusip varchar(12) = NULL ,
	 @undsym varchar(15) = NULL ,
	 @type varchar(2) = NULL ,
	 @exchange varchar(2) = NULL ,
	 @descr varchar(40) = NULL ,
	 @strategy varchar(4) = NULL ,
	 @memo varchar(74) = NULL ,
	 @shortratecode varchar(1) = NULL ,
	 @exdate char(8) = NULL ,
	 @divdate char(8) = NULL ,
	 @coupdate char(8) = NULL ,
	 @divfreq smallint= NULL ,
	 @divamt real= NULL ,
	 @coupon real= NULL ,
	 @longrate real= NULL ,
	 @shortrate real= NULL ,
	 @ratio float= NULL ,
	 @cvbuyprice float= NULL ,
	 @face float= NULL ,
	 @cvprice float= NULL ,
	 @sizequal float= NULL ,
	 @longmark float= NULL ,
	 @shortmark float= NULL ,
	 @prmult float= NULL ,
	 @strike float= NULL ,
	 @lastdivdate char(8) = NULL ,
	 @priordivdate char(8) = NULL ,
	 @lastdivamt real= NULL ,
	 @priordivamt real= NULL ,
	 @coupfreq smallint= NULL ,
	 @lastcoupdate char(8) = NULL ,
	 @priorcoupdate char(8) = NULL ,
	 @issuedate char(8) = NULL ,
	 @dateddate char(8) = NULL ,
	 @volatility1 smallint= NULL ,
	 @volatility2 smallint= NULL ,
	 @volatility3 smallint= NULL ,
	 @impvol smallint= NULL ,
	 @investval real= NULL ,
	 @sharesout float= NULL ,
	 @rating varchar(4) = NULL ,
	 @investvaltype char(1) = NULL ,
	 @longmarkcode char(1) = NULL ,
	 @shortmarkcode char(1) = NULL ,
	 @callprice real= NULL ,
	 @putprice real= NULL ,
	 @calldate char(8) = NULL ,
	 @putdate char(8) = NULL ,
	 @sort varchar(4) = NULL ,
	 @currency varchar(3) = NULL ,
	 @country varchar(3) = NULL ,
	 @earnshare real= NULL ,
	 @cvsellprice float= NULL ,
	 @margin float= NULL ,
	 @secid varchar(12) = NULL ,
	 @secfeeflag char(1) = NULL ,
	 @hedge real= NULL ,
	 @cprice float= NULL ,	
	 @sprice float= NULL ,
	 @prevmark float= NULL ,
	 @markdate char(8) = NULL ,
	 @industry varchar(4) = NULL ,
	 @sector varchar(4) = NULL ,
	 @invgrade varchar(4) = NULL ,
	 @screwflag char(1) = NULL ,
	 @stockatgrade real= NULL ,
	 @stkpctdowngrade real= NULL ,
	 @puttodate char(8) = NULL ,
	 @condcallprice real= NULL ,
	 @condcalldate char(8) = NULL ,
	 @condcalltodate char(8) = NULL ,
	 @prevmark2 float= NULL ,
	 @markdate2 char(8) = NULL ,
	 @modelhedge real= NULL ,
	 @active char(1) = NULL ,
	 @liveflag char(1) = NULL ,
	 @cashpaydate char(8) = NULL ,
	 @cashpayrate real= NULL ,
	 @xlsymbol varchar(15) = NULL ,
	 @trader varchar(4) = NULL ,
	 @bucket varchar(4) = NULL ,
	 @accrualmethod varchar(2) = NULL ,
	 @analyst varchar(4) = NULL ,
	 @intsymbol varchar(20) = NULL ,
	 @portmgr varchar(4) = NULL ,
	 @prevexchange varchar(2) = NULL ,
	 @ratioflag char(1) = NULL ,
	 @subtype varchar(2) = NULL ,
	 @qsymbol varchar(25) = NULL ,
	 @livemarkflag char(1) = NULL ,
	 @optoverrideflag char(1) = NULL ,
	 @swapflag char(1) = NULL ,
	 @registeredflag char(1) = NULL ,
	 @divrollflag char(1) = NULL ,
	 @amountout float = NULL

AS
	BEGIN

			-- https://stackoverflow.com/questions/52971604/update-only-rows-that-does-not-match-rows-from-another-table
			--
			-- Any records that no longer are in staging should get closed out
			--

			 UPDATE t1 
			 SET t1.ts_end = @Timestamp
			 FROM [TMDBSQL].[dbo].[TMWSECDB] t1
			 LEFT JOIN [TMDBSQL].[dbo].[TMWSECDB_staging] t2 ON t2.symbol = t1.symbol
			 WHERE t1.ts_end IS NULL and t2.[symbol] IS NULL

				BEGIN TRANSACTION
IF EXISTS(SELECT 1 FROM [TMDBSQL].[dbo].[TMWSECDB] WHERE [symbol] = @symbol AND ts_end IS NULL)
	BEGIN
		PRINT 'upsert_TMWSECDB_staging("' + CAST(@symbol AS VARCHAR) + '") a current record exists'

		-- We need to figure out if the records are different
		DECLARE @StagingData NVARCHAR(MAX) = CONCAT_WS('|', 
				@symbol ,
				@cusip ,
				@undsym ,
				@type ,
				@exchange ,
				@descr ,
				@strategy ,
				@memo ,
				@shortratecode ,
				@exdate ,
				@divdate ,
				@coupdate ,
				@divfreq ,
				@divamt ,
				@coupon ,
				@longrate ,
				@shortrate ,
				@ratio ,
				@cvbuyprice ,
				@face ,
				@cvprice ,
				@sizequal ,
				@longmark ,
				@shortmark ,
				@prmult ,
				@strike ,
				@lastdivdate ,
				@priordivdate ,
				@lastdivamt ,
				@priordivamt ,
				@coupfreq ,
				@lastcoupdate ,
				@priorcoupdate ,
				@issuedate ,
				@dateddate ,
				@volatility1 ,
				@volatility2 ,
				@volatility3 ,
				@impvol ,
				@investval ,
				@sharesout ,
				@rating ,
				@investvaltype ,
				@longmarkcode ,
				@shortmarkcode ,
				@callprice ,
				@putprice ,
				@calldate ,
				@putdate ,
				@sort ,
				@currency ,
				@country ,
				@earnshare ,
				@cvsellprice ,
				@margin ,
				@secid ,
				@secfeeflag ,
				@hedge ,
				@cprice ,
				@sprice ,
				@prevmark ,
				@markdate ,
				@industry ,
				@sector ,
				@invgrade ,
				@screwflag ,
				@stockatgrade ,
				@stkpctdowngrade ,
				@puttodate ,
				@condcallprice ,
				@condcalldate ,
				@condcalltodate ,
				@prevmark2 ,
				@markdate2 ,
				@modelhedge ,
				@active ,
				@liveflag ,
				@cashpaydate ,
				@cashpayrate ,
				@xlsymbol ,
				@trader ,
				@bucket ,
				@accrualmethod ,
				@analyst ,
				@intsymbol ,
				@portmgr ,
				@prevexchange ,
				@ratioflag ,
				@subtype ,
				@qsymbol ,
				@livemarkflag ,
				@optoverrideflag ,
				@swapflag ,
				@registeredflag ,
				@divrollflag ,
				@amountout 
						)

		DECLARE @ActualData  NVARCHAR(MAX)	
		SELECT @ActualData = CONCAT_WS('|', 
				[symbol] ,
				[cusip] ,
				[undsym] ,
				[type] ,
				[exchange] ,
				[descr] ,
				[strategy] ,
				[memo] ,
				[shortratecode] ,
				[exdate] ,
				[divdate] ,
				[coupdate] ,
				[divfreq] ,
				[divamt] ,
				[coupon] ,
				[longrate] ,
				[shortrate] ,
				[ratio] ,
				[cvbuyprice] ,
				[face] ,
				[cvprice] ,
				[sizequal] ,
				[longmark] ,
				[shortmark] ,
				[prmult] ,
				[strike] ,
				[lastdivdate] ,
				[priordivdate] ,
				[lastdivamt] ,
				[priordivamt] ,
				[coupfreq] ,
				[lastcoupdate] ,
				[priorcoupdate] ,
				[issuedate] ,
				[dateddate] ,
				[volatility1] ,
				[volatility2] ,
				[volatility3] ,
				[impvol] ,
				[investval] ,
				[sharesout] ,
				[rating] ,
				[investvaltype] ,
				[longmarkcode] ,
				[shortmarkcode] ,
				[callprice] ,
				[putprice] ,
				[calldate] ,
				[putdate] ,
				[sort] ,
				[currency] ,
				[country] ,
				[earnshare] ,
				[cvsellprice] ,
				[margin] ,
				[secid] ,
				[secfeeflag] ,
				[hedge] ,
				[cprice] ,
				[sprice] ,
				[prevmark] ,
				[markdate] ,
				[industry] ,
				[sector] ,
				[invgrade] ,
				[screwflag] ,
				[stockatgrade] ,
				[stkpctdowngrade] ,
				[puttodate] ,
				[condcallprice] ,
				[condcalldate] ,
				[condcalltodate] ,
				[prevmark2] ,
				[markdate2] ,
				[modelhedge] ,
				[active] ,
				[liveflag] ,
				[cashpaydate] ,
				[cashpayrate] ,
				[xlsymbol] ,
				[trader] ,
				[bucket] ,
				[accrualmethod] ,
				[analyst] ,
				[intsymbol] ,
				[portmgr] ,
				[prevexchange] ,
				[ratioflag] ,
				[subtype] ,
				[qsymbol] ,
				[livemarkflag] ,
				[optoverrideflag] ,
				[swapflag] ,
				[registeredflag] ,
				[divrollflag] ,
				[amountout] )
	
			FROM [TMDBSQL].[dbo].[TMWSECDB] 
			WHERE (symbol = @symbol AND ts_end IS NULL)
	
			DECLARE @StagingDataHash NVARCHAR(64) = HASHBYTES('SHA2_256',@StagingData)
			DECLARE @ActualDataHash  NVARCHAR(64) = HASHBYTES('SHA2_256',@ActualData)
				
			PRINT 'DBG: upsert_TMWSECDB_staging("' + CAST(@symbol AS VARCHAR) + '") @StagingDataHash = ' + @StagingDataHash 
			PRINT 'DBG: upsert_TMWSECDB_staging("' + CAST(@symbol AS VARCHAR) + '") @ActualDataHash = ' + @ActualDataHash
			PRINT @StagingData
			PRINT @ActualData
		
		IF @StagingDataHash <> @ActualDataHash
			BEGIN
				PRINT 'upsert_TMWSECDB_staging("' + CAST(@symbol AS VARCHAR) + '") - Giant OR failed'
				PRINT 'DBG: upsert_TMWSECDB_staging("' + CAST(@symbol AS VARCHAR) + '") @StagingDataHash = ' + @StagingDataHash 
				PRINT 'DBG: upsert_TMWSECDB_staging("' + CAST(@symbol AS VARCHAR) + '") @ActualDataHash = ' + @ActualDataHash
				PRINT @StagingData
				PRINT @ActualData

				UPDATE [TMDBSQL].[dbo].[TMWSECDB] WITH (SERIALIZABLE)
					SET
						ts_end = @Timestamp
					WHERE
						symbol = @symbol AND ts_end IS NULL

					INSERT INTO [TMDBSQL].[dbo].[TMWSECDB]
					(	
								[symbol] ,
								[ts_start] ,
								[ts_end] ,
								[cusip] ,
								[undsym] ,
								[type] ,
								[exchange] ,
								[descr] ,
								[strategy] ,
								[memo] ,
								[shortratecode] ,
								[exdate] ,
								[divdate] ,
								[coupdate] ,
								[divfreq] ,
								[divamt] ,
								[coupon] ,
								[longrate] ,
								[shortrate] ,
								[ratio] ,
								[cvbuyprice] ,
								[face] ,
								[cvprice] ,
								[sizequal] ,
								[longmark] ,
								[shortmark] ,
								[prmult] ,
								[strike] ,
								[lastdivdate] ,
								[priordivdate] ,
								[lastdivamt] ,
								[priordivamt] ,
								[coupfreq] ,
								[lastcoupdate] ,
								[priorcoupdate] ,
								[issuedate] ,
								[dateddate] ,
								[volatility1] ,
								[volatility2] ,
								[volatility3] ,
								[impvol] ,
								[investval] ,
								[sharesout] ,
								[rating] ,
								[investvaltype] ,
								[longmarkcode] ,
								[shortmarkcode] ,
								[callprice] ,
								[putprice] ,
								[calldate] ,
								[putdate] ,
								[sort] ,
								[currency] ,
								[country] ,
								[earnshare] ,
								[cvsellprice] ,
								[margin] ,
								[secid] ,
								[secfeeflag] ,
								[hedge] ,
								[cprice] ,
								[sprice] ,
								[prevmark] ,
								[markdate] ,
								[industry] ,
								[sector] ,
								[invgrade] ,
								[screwflag] ,
								[stockatgrade] ,
								[stkpctdowngrade] ,
								[puttodate] ,
								[condcallprice] ,
								[condcalldate] ,
								[condcalltodate] ,
								[prevmark2] ,
								[markdate2] ,
								[modelhedge] ,
								[active] ,
								[liveflag] ,
								[cashpaydate] ,
								[cashpayrate] ,
								[xlsymbol] ,
								[trader] ,
								[bucket] ,
								[accrualmethod] ,
								[analyst] ,
								[intsymbol] ,
								[portmgr] ,
								[prevexchange] ,
								[ratioflag] ,
								[subtype] ,
								[qsymbol] ,
								[livemarkflag] ,
								[optoverrideflag] ,
								[swapflag] ,
								[registeredflag] ,
								[divrollflag]  ,
								[amountout]
						)
				VALUES
					(	@symbol ,
						@Timestamp ,
						NULL ,
						@cusip ,
						@undsym ,
						@type ,
						@exchange ,
						@descr ,
						@strategy ,
						@memo ,
						@shortratecode ,
						@exdate ,
						@divdate ,
						@coupdate ,
						@divfreq ,
						@divamt ,
						@coupon ,
						@longrate ,
						@shortrate ,
						@ratio ,
						@cvbuyprice ,
						@face ,
						@cvprice ,
						@sizequal ,
						@longmark ,
						@shortmark ,
						@prmult ,
						@strike ,
						@lastdivdate ,
						@priordivdate ,
						@lastdivamt ,
						@priordivamt ,
						@coupfreq ,
						@lastcoupdate ,
						@priorcoupdate ,
						@issuedate ,
						@dateddate ,
						@volatility1 ,
						@volatility2 ,
						@volatility3 ,
						@impvol ,
						@investval ,
						@sharesout ,
						@rating ,
						@investvaltype ,
						@longmarkcode ,
						@shortmarkcode ,
						@callprice ,
						@putprice ,
						@calldate ,
						@putdate ,
						@sort ,
						@currency ,
						@country ,
						@earnshare ,
						@cvsellprice ,
						@margin ,
						@secid ,
						@secfeeflag ,
						@hedge ,
						@cprice ,
						@sprice ,
						@prevmark ,
						@markdate ,
						@industry ,
						@sector ,
						@invgrade ,
						@screwflag ,
						@stockatgrade ,
						@stkpctdowngrade ,
						@puttodate ,
						@condcallprice ,
						@condcalldate ,
						@condcalltodate ,
						@prevmark2 ,
						@markdate2 ,
						@modelhedge ,
						@active ,
						@liveflag ,
						@cashpaydate ,
						@cashpayrate ,
						@xlsymbol ,
						@trader ,
						@bucket ,
						@accrualmethod ,
						@analyst ,
						@intsymbol ,
						@portmgr ,
						@prevexchange ,
						@ratioflag ,
						@subtype ,
						@qsymbol ,
						@livemarkflag ,
						@optoverrideflag ,
						@swapflag ,
						@registeredflag ,
						@divrollflag ,
						@amountout
						 )

				-- SET @return_status = 1
			END
		ELSE
			PRINT 'DBG: upsert_TMWSECDB_staging("' + CAST(@symbol AS VARCHAR) + '") No change'
	END
ELSE
	BEGIN
	 -- Completely new record
					PRINT 'upsert_TMWSECDB_staging("' + CAST(@symbol AS VARCHAR) + '") - New record'

					INSERT INTO [TMDBSQL].[dbo].[TMWSECDB]
					(	
								[symbol] ,
								[ts_start] ,
								[ts_end] ,
								[cusip] ,
								[undsym] ,
								[type] ,
								[exchange] ,
								[descr] ,
								[strategy] ,
								[memo] ,
								[shortratecode] ,
								[exdate] ,
								[divdate] ,
								[coupdate] ,
								[divfreq] ,
								[divamt] ,
								[coupon] ,
								[longrate] ,
								[shortrate] ,
								[ratio] ,
								[cvbuyprice] ,
								[face] ,
								[cvprice] ,
								[sizequal] ,
								[longmark] ,
								[shortmark] ,
								[prmult] ,
								[strike] ,
								[lastdivdate] ,
								[priordivdate] ,
								[lastdivamt] ,
								[priordivamt] ,
								[coupfreq] ,
								[lastcoupdate] ,
								[priorcoupdate] ,
								[issuedate] ,
								[dateddate] ,
								[volatility1] ,
								[volatility2] ,
								[volatility3] ,
								[impvol] ,
								[investval] ,
								[sharesout] ,
								[rating] ,
								[investvaltype] ,
								[longmarkcode] ,
								[shortmarkcode] ,
								[callprice] ,
								[putprice] ,
								[calldate] ,
								[putdate] ,
								[sort] ,
								[currency] ,
								[country] ,
								[earnshare] ,
								[cvsellprice] ,
								[margin] ,
								[secid] ,
								[secfeeflag] ,
								[hedge] ,
								[cprice] ,
								[sprice] ,
								[prevmark] ,
								[markdate] ,
								[industry] ,
								[sector] ,
								[invgrade] ,
								[screwflag] ,
								[stockatgrade] ,
								[stkpctdowngrade] ,
								[puttodate] ,
								[condcallprice] ,
								[condcalldate] ,
								[condcalltodate] ,
								[prevmark2] ,
								[markdate2] ,
								[modelhedge] ,
								[active] ,
								[liveflag] ,
								[cashpaydate] ,
								[cashpayrate] ,
								[xlsymbol] ,
								[trader] ,
								[bucket] ,
								[accrualmethod] ,
								[analyst] ,
								[intsymbol] ,
								[portmgr] ,
								[prevexchange] ,
								[ratioflag] ,
								[subtype] ,
								[qsymbol] ,
								[livemarkflag] ,
								[optoverrideflag] ,
								[swapflag] ,
								[registeredflag] ,
								[divrollflag] ,
								[amountout]
						)
				VALUES
					(	@symbol ,
						@Timestamp ,
						NULL ,
						@cusip ,
						@undsym ,
						@type ,
						@exchange ,
						@descr ,
						@strategy ,
						@memo ,
						@shortratecode ,
						@exdate ,
						@divdate ,
						@coupdate ,
						@divfreq ,
						@divamt ,
						@coupon ,
						@longrate ,
						@shortrate ,
						@ratio ,
						@cvbuyprice ,
						@face ,
						@cvprice ,
						@sizequal ,
						@longmark ,
						@shortmark ,
						@prmult ,
						@strike ,
						@lastdivdate ,
						@priordivdate ,
						@lastdivamt ,
						@priordivamt ,
						@coupfreq ,
						@lastcoupdate ,
						@priorcoupdate ,
						@issuedate ,
						@dateddate ,
						@volatility1 ,
						@volatility2 ,
						@volatility3 ,
						@impvol ,
						@investval ,
						@sharesout ,
						@rating ,
						@investvaltype ,
						@longmarkcode ,
						@shortmarkcode ,
						@callprice ,
						@putprice ,
						@calldate ,
						@putdate ,
						@sort ,
						@currency ,
						@country ,
						@earnshare ,
						@cvsellprice ,
						@margin ,
						@secid ,
						@secfeeflag ,
						@hedge ,
						@cprice ,
						@sprice ,
						@prevmark ,
						@markdate ,
						@industry ,
						@sector ,
						@invgrade ,
						@screwflag ,
						@stockatgrade ,
						@stkpctdowngrade ,
						@puttodate ,
						@condcallprice ,
						@condcalldate ,
						@condcalltodate ,
						@prevmark2 ,
						@markdate2 ,
						@modelhedge ,
						@active ,
						@liveflag ,
						@cashpaydate ,
						@cashpayrate ,
						@xlsymbol ,
						@trader ,
						@bucket ,
						@accrualmethod ,
						@analyst ,
						@intsymbol ,
						@portmgr ,
						@prevexchange ,
						@ratioflag ,
						@subtype ,
						@qsymbol ,
						@livemarkflag ,
						@optoverrideflag ,
						@swapflag ,
						@registeredflag ,
						@divrollflag ,
						@amountout
						)

		-- SET @return_status = 1
	END
				
				COMMIT TRANSACTION



					END
 
 





GO
