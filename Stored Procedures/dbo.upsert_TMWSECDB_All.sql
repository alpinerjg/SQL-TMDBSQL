SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE      PROCEDURE [dbo].[upsert_TMWSECDB_All] 
--	@return_status INT = 0 OUTPUT 

AS
BEGIN

-- DECLARE @return_status int;

	DECLARE @CursorCount INT = 1
	DECLARE @RowCnt INT = 0

	DECLARE @Timestamp datetime	

	DECLARE @ts_start datetime 
	DECLARE @ts_end datetime = NULL
	DECLARE @symbol varchar(15)
	DECLARE @cusip varchar(12)= NULL
	DECLARE @undsym varchar(15)= NULL
	DECLARE @type varchar(2)= NULL
	DECLARE @exchange varchar(2)= NULL
	DECLARE @descr varchar(40)= NULL
	DECLARE @strategy varchar(4)= NULL
	DECLARE @memo varchar(74)= NULL
	DECLARE @shortratecode varchar(1)= NULL
	DECLARE @exdate char(8)= NULL
	DECLARE @divdate char(8)= NULL
	DECLARE @coupdate char(8)= NULL
	DECLARE @divfreq smallint= NULL
	DECLARE @divamt real= NULL
	DECLARE @coupon real= NULL
	DECLARE @longrate real= NULL
	DECLARE @shortrate real= NULL
	DECLARE @ratio float= NULL
	DECLARE @cvbuyprice float= NULL
	DECLARE @face float= NULL
	DECLARE @cvprice float= NULL
	DECLARE @sizequal float= NULL
	DECLARE @longmark float= NULL
	DECLARE @shortmark float= NULL
	DECLARE @prmult float= NULL
	DECLARE @strike float= NULL
	DECLARE @lastdivdate char(8)= NULL
	DECLARE @priordivdate char(8)= NULL
	DECLARE @lastdivamt real= NULL
	DECLARE @priordivamt real= NULL
	DECLARE @coupfreq smallint= NULL
	DECLARE @lastcoupdate char(8)= NULL
	DECLARE @priorcoupdate char(8)= NULL
	DECLARE @issuedate char(8)= NULL
	DECLARE @dateddate char(8)= NULL
	DECLARE @volatility1 smallint= NULL
	DECLARE @volatility2 smallint= NULL
	DECLARE @volatility3 smallint= NULL
	DECLARE @impvol smallint= NULL
	DECLARE @investval real= NULL
	DECLARE @sharesout float= NULL
	DECLARE @rating varchar(4)= NULL
	DECLARE @investvaltype char(1)= NULL
	DECLARE @longmarkcode char(1)= NULL
	DECLARE @shortmarkcode char(1)= NULL
	DECLARE @callprice real= NULL
	DECLARE @putprice real= NULL
	DECLARE @calldate char(8)= NULL
	DECLARE @putdate char(8)= NULL
	DECLARE @sort varchar(4)= NULL
	DECLARE @currency varchar(3)= NULL
	DECLARE @country varchar(3)= NULL
	DECLARE @earnshare real= NULL
	DECLARE @cvsellprice float= NULL
	DECLARE @margin float= NULL
	DECLARE @secid varchar(12)= NULL
	DECLARE @secfeeflag char(1)= NULL
	DECLARE @hedge real= NULL
	DECLARE @cprice float= NULL	
	DECLARE @sprice float= NULL
	DECLARE @prevmark float= NULL
	DECLARE @markdate char(8)= NULL
	DECLARE @industry varchar(4)= NULL
	DECLARE @sector varchar(4)= NULL
	DECLARE @invgrade varchar(4)= NULL
	DECLARE @screwflag char(1)= NULL
	DECLARE @stockatgrade real= NULL
	DECLARE @stkpctdowngrade real= NULL
	DECLARE @puttodate char(8)= NULL
	DECLARE @condcallprice real= NULL
	DECLARE @condcalldate char(8)= NULL
	DECLARE @condcalltodate char(8)= NULL
	DECLARE @prevmark2 float= NULL
	DECLARE @markdate2 char(8)= NULL
	DECLARE @modelhedge real= NULL
	DECLARE @active char(1)= NULL
	DECLARE @liveflag char(1)= NULL
	DECLARE @cashpaydate char(8)= NULL
	DECLARE @cashpayrate real= NULL
	DECLARE @xlsymbol varchar(15)= NULL
	DECLARE @trader varchar(4)= NULL
	DECLARE @bucket varchar(4)= NULL
	DECLARE @accrualmethod varchar(2)= NULL
	DECLARE @analyst varchar(4)= NULL
	DECLARE @intsymbol varchar(20)= NULL
	DECLARE @portmgr varchar(4)= NULL
	DECLARE @prevexchange varchar(2)= NULL
	DECLARE @ratioflag char(1)= NULL
	DECLARE @subtype varchar(2)= NULL
	DECLARE @qsymbol varchar(25)= NULL
	DECLARE @livemarkflag char(1)= NULL
	DECLARE @optoverrideflag char(1)= NULL
	DECLARE @swapflag char(1)= NULL
	DECLARE @registeredflag char(1)= NULL
	DECLARE @divrollflag char(1)= NULL
	DECLARE @amountout float = NULL	


	DECLARE TMWSECDB_staging_Cursor CURSOR FOR 
		SELECT 	
			symbol ,
			cusip ,
			undsym ,
			type ,
			exchange ,
			descr ,
			strategy ,
			memo ,
			shortratecode ,
			exdate ,
			divdate ,
			coupdate ,
			divfreq ,
			divamt ,
			coupon ,
			longrate ,
			shortrate ,
			ratio ,
			cvbuyprice ,
			face ,
			cvprice ,
			sizequal ,
			longmark ,
			shortmark ,
			prmult ,
			strike ,
			lastdivdate ,
			priordivdate ,
			lastdivamt ,
			priordivamt ,
			coupfreq ,
			lastcoupdate ,
			priorcoupdate ,
			issuedate ,
			dateddate ,
			volatility1 ,
			volatility2 ,
			volatility3 ,
			impvol ,
			investval ,
			sharesout ,
			rating ,
			investvaltype ,
			longmarkcode ,
			shortmarkcode ,
			callprice ,
			putprice ,
			calldate ,
			putdate ,
			sort ,
			currency ,
			country ,
			earnshare ,
			cvsellprice ,
			margin ,
			secid ,
			secfeeflag ,
			hedge ,
			cprice ,
			sprice ,
			prevmark ,
			markdate ,
			industry ,
			sector ,
			invgrade ,
			screwflag ,
			stockatgrade ,
			stkpctdowngrade ,
			puttodate ,
			condcallprice ,
			condcalldate ,
			condcalltodate ,
			prevmark2 ,
			markdate2 ,
			modelhedge ,
			active ,
			liveflag ,
			cashpaydate ,
			cashpayrate ,
			xlsymbol ,
			trader ,
			bucket ,
			accrualmethod ,
			analyst ,
			intsymbol ,
			portmgr ,
			prevexchange ,
			ratioflag ,
			subtype ,
			qsymbol ,
			livemarkflag ,
			optoverrideflag ,
			swapflag ,
			registeredflag ,
			divrollflag ,
			amountout
		FROM [TMDBSQL].[dbo].[TMWSECDB_staging]


	-- BEGIN TRANSACTION

	SET @Timestamp = GetDate()

	OPEN TMWSECDB_staging_Cursor 

	SELECT @RowCnt = COUNT(0) FROM [TMDBSQL].[dbo].[TMWSECDB_staging]

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

			FETCH NEXT FROM TMWSECDB_staging_Cursor INTO
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

			WHILE @@FETCH_STATUS = 0  		

			BEGIN
					EXEC upsert_TMWSECDB_staging
							@Timestamp = @Timestamp ,
							@symbol = @symbol ,
							@cusip = @cusip ,
							@undsym = @undsym ,
							@type = @type ,
							@exchange = @exchange ,
							@descr = @descr ,
							@strategy = @strategy ,
							@memo = @memo ,
							@shortratecode = @shortratecode ,
							@exdate = @exdate ,
							@divdate = @divdate ,
							@coupdate = @coupdate ,
							@divfreq = @divfreq ,
							@divamt = @divamt ,
							@coupon = @coupon ,
							@longrate = @longrate ,
							@shortrate = @shortrate ,
							@ratio = @ratio ,
							@cvbuyprice = @cvbuyprice ,
							@face = @face ,
							@cvprice = @cvprice ,
							@sizequal = @sizequal ,
							@longmark = @longmark ,
							@shortmark = @shortmark ,
							@prmult = @prmult ,
							@strike = @strike ,
							@lastdivdate = @lastdivdate ,
							@priordivdate = @priordivdate ,
							@lastdivamt = @lastdivamt ,
							@priordivamt = @priordivamt ,
							@coupfreq = @coupfreq ,
							@lastcoupdate = @lastcoupdate ,
							@priorcoupdate = @priorcoupdate ,
							@issuedate = @issuedate ,
							@dateddate = @dateddate ,
							@volatility1 = @volatility1 ,
							@volatility2 = @volatility2 ,
							@volatility3 = @volatility3 ,
							@impvol = @impvol ,
							@investval = @investval ,
							@sharesout = @sharesout ,
							@rating = @rating ,
							@investvaltype = @investvaltype ,
							@longmarkcode = @longmarkcode ,
							@shortmarkcode = @shortmarkcode ,
							@callprice = @callprice ,
							@putprice = @putprice ,
							@calldate = @calldate ,
							@putdate = @putdate ,
							@sort = @sort ,
							@currency = @currency ,
							@country = @country ,
							@earnshare = @earnshare ,
							@cvsellprice = @cvsellprice ,
							@margin = @margin ,
							@secid = @secid ,
							@secfeeflag = @secfeeflag ,
							@hedge = @hedge ,
							@cprice = @cprice ,
							@sprice = @sprice ,
							@prevmark = @prevmark ,
							@markdate = @markdate ,
							@industry = @industry ,
							@sector = @sector ,
							@invgrade = @invgrade ,
							@screwflag = @screwflag ,
							@stockatgrade = @stockatgrade ,
							@stkpctdowngrade = @stkpctdowngrade ,
							@puttodate = @puttodate ,
							@condcallprice = @condcallprice ,
							@condcalldate = @condcalldate ,
							@condcalltodate = @condcalltodate ,
							@prevmark2 = @prevmark2 ,
							@markdate2 = @markdate2 ,
							@modelhedge = @modelhedge ,
							@active = @active ,
							@liveflag = @liveflag ,
							@cashpaydate = @cashpaydate ,
							@cashpayrate = @cashpayrate ,
							@xlsymbol = @xlsymbol ,
							@trader = @trader ,
							@bucket = @bucket ,
							@accrualmethod = @accrualmethod ,
							@analyst = @analyst ,
							@intsymbol = @intsymbol ,
							@portmgr = @portmgr ,
							@prevexchange = @prevexchange ,
							@ratioflag = @ratioflag ,
							@subtype = @subtype ,
							@qsymbol = @qsymbol ,
							@livemarkflag = @livemarkflag ,
							@optoverrideflag = @optoverrideflag ,
							@swapflag = @swapflag ,
							@registeredflag = @registeredflag ,
							@divrollflag = @divrollflag ,
							@amountout = @amountout

					EXEC upsert_TMWSECDB_Market
						@Timestamp = @Timestamp ,
						@symbol = @symbol ,
						@longrate = @longrate ,
						@shortrate = @shortrate ,
						@longmark = @longmark ,
						@shortmark = @shortmark

					FETCH NEXT FROM TMWSECDB_staging_Cursor INTO
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

						 SET @CursorCount  = @CursorCount  + 1 
					END
 
		END
 
		CLOSE TMWSECDB_staging_Cursor

		-- COMMIT TRANSACTION

		DEALLOCATE TMWSECDB_staging_Cursor

		-- SET @return_status = 1

	END


GO
