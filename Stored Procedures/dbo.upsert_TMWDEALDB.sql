SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[upsert_TMWDEALDB] 
--	@return_status INT = 0 OUTPUT 

AS
BEGIN

-- DECLARE @return_status int;

	DECLARE @CursorCount INT = 1
	DECLARE @RowCnt INT = 0

	DECLARE @Timestamp datetime	

	DECLARE @dealname varchar(15) 
	DECLARE @ts_start datetime 
	DECLARE @ts_end datetime = NULL
	DECLARE @undsym varchar(15) = NULL
	DECLARE @acqsym varchar(15) = NULL
	DECLARE @type smallint = NULL
	DECLARE @cashpct real = NULL
	DECLARE @stockpct real = NULL
	DECLARE @tndrpct real = NULL
	DECLARE @cashamt float = NULL
	DECLARE @ratio float = NULL
	DECLARE @lowcollar float = NULL
	DECLARE @highcollar float = NULL
	DECLARE @outsidelow float = NULL
	DECLARE @outsidehigh float = NULL
	DECLARE @dealamt float = NULL
	DECLARE @lowrange float = NULL
	DECLARE @highrange float = NULL
	DECLARE @revcollar char(1) = NULL
	DECLARE @outflag char(1) = NULL
	DECLARE @residual float = NULL
	DECLARE @origprice float = NULL
	DECLARE @origacq float = NULL
	DECLARE @downprice float = NULL
	DECLARE @d1date char(8) = NULL
	DECLARE @d2date char(8) = NULL
	DECLARE @ds1symbol varchar(7) = NULL
	DECLARE @ds1price real = NULL
	DECLARE @ds2symbol varchar(7) = NULL
	DECLARE @ds2price real = NULL
	DECLARE @ds3symbol varchar(7) = NULL
	DECLARE @ds3price real = NULL
	DECLARE @ds4symbol varchar(7) = NULL
	DECLARE @ds4price real = NULL
	DECLARE @ds5symbol varchar(7) = NULL
	DECLARE @ds5price real = NULL
	DECLARE @ds6symbol varchar(7) = NULL
	DECLARE @ds6price real = NULL
	DECLARE @ds7symbol varchar(7) = NULL
	DECLARE @ds7price real = NULL
	DECLARE @ds8symbol varchar(7) = NULL
	DECLARE @ds8price real = NULL
	DECLARE @ds9symbol varchar(7) = NULL
	DECLARE @ds9price real = NULL
	DECLARE @ds10symbol varchar(7) = NULL
	DECLARE @ds10price real = NULL
	DECLARE @desc varchar(80) = NULL
	DECLARE @cashelect char(1) = NULL
	DECLARE @canbuy int = NULL
	DECLARE @charge float = NULL
	DECLARE @dealdisp char(1) = NULL
	DECLARE @zs1symbol varchar(7) = NULL
	DECLARE @zs1price real = NULL
	DECLARE @zs2symbol varchar(7) = NULL
	DECLARE @zs2price real = NULL
	DECLARE @zs3symbol varchar(7) = NULL
	DECLARE @zs3price real = NULL
	DECLARE @zs4symbol varchar(7) = NULL
	DECLARE @zs4price real = NULL
	DECLARE @zs5symbol varchar(7) = NULL
	DECLARE @zs5price real = NULL
	DECLARE @zs6symbol varchar(7) = NULL
	DECLARE @zs6price real = NULL
	DECLARE @zs7symbol varchar(7) = NULL
	DECLARE @zs7price real = NULL
	DECLARE @zs8symbol varchar(7) = NULL
	DECLARE @zs8price real = NULL
	DECLARE @zs9symbol varchar(7) = NULL
	DECLARE @zs9price real = NULL
	DECLARE @zs10symbol varchar(7) = NULL
	DECLARE @zs10price real = NULL
	DECLARE @zshortprice float = NULL
	DECLARE @other1 char(214) = NULL
	DECLARE @other2 char(214) = NULL
	DECLARE @other3 char(214) = NULL
	DECLARE @numadditional smallint = NULL
	DECLARE @secsharesflag char(1) = NULL
	DECLARE @definitive char(1) = NULL
	DECLARE @initials1 char(2) = NULL
	DECLARE @initials2 char(2) = NULL
	DECLARE @dealreport char(1) = NULL
	DECLARE @nondefcanbuy int = NULL
	DECLARE @defcanbuy char(1) = NULL
	DECLARE @category varchar(2) = NULL
	DECLARE @prevdown char(120) = NULL
	DECLARE @prevzshort char(120) = NULL
	DECLARE @prevadd1 char(120) = NULL
	DECLARE @prevadd2 char(120) = NULL
	DECLARE @prevadd3 char(120) = NULL
	DECLARE @secondtier char(1) = NULL
	DECLARE @strategy varchar(4) = NULL
	DECLARE @currency varchar(3) = NULL
	DECLARE @upsidemult float = NULL
	DECLARE @extracash float = NULL
	DECLARE @altclose varchar(8) = NULL
	DECLARE @altupside float = NULL
	DECLARE @desc1 varchar(214) = NULL


	DECLARE TMWDEALDB_staging_Cursor CURSOR FOR 
		SELECT 	
						dealname ,
						undsym ,
						acqsym ,
						type ,
						cashpct ,
						stockpct ,
						tndrpct ,
						cashamt ,
						ratio ,
						lowcollar ,
						highcollar ,
						outsidelow ,
						outsidehigh ,
						dealamt ,
						lowrange ,
						highrange ,
						revcollar ,
						outflag ,
						residual ,
						origprice ,
						origacq ,
						downprice ,
						d1date ,
						d2date ,
						ds1symbol ,
						ds1price ,
						ds2symbol ,
						ds2price ,
						ds3symbol ,
						ds3price ,
						ds4symbol ,
						ds4price ,
						ds5symbol ,
						ds5price ,
						ds6symbol ,
						ds6price ,
						ds7symbol ,
						ds7price ,
						ds8symbol ,
						ds8price ,
						ds9symbol ,
						ds9price ,
						ds10symbol ,
						ds10price ,
						[desc] ,
						cashelect ,
						canbuy ,
						charge ,
						dealdisp ,
						zs1symbol ,
						zs1price ,
						zs2symbol ,
						zs2price ,
						zs3symbol ,
						zs3price ,
						zs4symbol ,
						zs4price ,
						zs5symbol ,
						zs5price ,
						zs6symbol ,
						zs6price ,
						zs7symbol ,
						zs7price ,
						zs8symbol ,
						zs8price ,
						zs9symbol ,
						zs9price ,
						zs10symbol ,
						zs10price ,
						zshortprice ,
						other1 ,
						other2 ,
						other3 ,
						numadditional ,
						secsharesflag ,
						definitive ,
						initials1 ,
						initials2 ,
						dealreport ,
						nondefcanbuy ,
						defcanbuy ,
						category ,
						prevdown ,
						prevzshort ,
						prevadd1 ,
						prevadd2 ,
						prevadd3 ,
						secondtier ,
						strategy ,
						currency ,
						upsidemult ,
						extracash ,
						altclose ,
						altupside ,
						desc1
		FROM [TMDBSQL].[dbo].[TMWDEALDB_staging]


	-- BEGIN TRANSACTION

	SET @Timestamp = GetDate()

	OPEN TMWDEALDB_staging_Cursor 

	SELECT @RowCnt = COUNT(0) FROM [TMDBSQL].[dbo].[TMWDEALDB_staging]

	BEGIN

			-- https://stackoverflow.com/questions/52971604/update-only-rows-that-does-not-match-rows-from-another-table
			--
			-- Any records that no longer are in staging should get closed out
			--

			UPDATE t1 
			SET t1.ts_end = @Timestamp
			FROM [TMDBSQL].[dbo].[TMWDEALDB] t1
			LEFT JOIN [TMDBSQL].[dbo].[TMWDEALDB_staging] t2 ON t2.dealname = t1.dealname
			WHERE t1.ts_end IS NULL and t2.[dealname] IS NULL

			FETCH NEXT FROM TMWDEALDB_staging_Cursor INTO
						@dealname ,
						@undsym ,
						@acqsym ,
						@type ,
						@cashpct ,
						@stockpct ,
						@tndrpct ,
						@cashamt ,
						@ratio ,
						@lowcollar ,
						@highcollar ,
						@outsidelow ,
						@outsidehigh ,
						@dealamt ,
						@lowrange ,
						@highrange ,
						@revcollar ,
						@outflag ,
						@residual ,
						@origprice ,
						@origacq ,
						@downprice ,
						@d1date ,
						@d2date ,
						@ds1symbol ,
						@ds1price ,
						@ds2symbol ,
						@ds2price ,
						@ds3symbol ,
						@ds3price ,
						@ds4symbol ,
						@ds4price ,
						@ds5symbol ,
						@ds5price ,
						@ds6symbol ,
						@ds6price ,
						@ds7symbol ,
						@ds7price ,
						@ds8symbol ,
						@ds8price ,
						@ds9symbol ,
						@ds9price ,
						@ds10symbol ,
						@ds10price ,
						@desc ,
						@cashelect ,
						@canbuy ,
						@charge ,
						@dealdisp ,
						@zs1symbol ,
						@zs1price ,
						@zs2symbol ,
						@zs2price ,
						@zs3symbol ,
						@zs3price ,
						@zs4symbol ,
						@zs4price ,
						@zs5symbol ,
						@zs5price ,
						@zs6symbol ,
						@zs6price ,
						@zs7symbol ,
						@zs7price ,
						@zs8symbol ,
						@zs8price ,
						@zs9symbol ,
						@zs9price ,
						@zs10symbol ,
						@zs10price ,
						@zshortprice ,
						@other1 ,
						@other2 ,
						@other3 ,
						@numadditional ,
						@secsharesflag ,
						@definitive ,
						@initials1 ,
						@initials2 ,
						@dealreport ,
						@nondefcanbuy ,
						@defcanbuy ,
						@category ,
						@prevdown ,
						@prevzshort ,
						@prevadd1 ,
						@prevadd2 ,
						@prevadd3 ,
						@secondtier ,
						@strategy ,
						@currency ,
						@upsidemult ,
						@extracash ,
						@altclose ,
						@altupside ,
						@desc1 

			WHILE @@FETCH_STATUS = 0  		

			BEGIN
				-- PRINT 'upsert_TMWDEALDB("' + CAST(@dealname AS VARCHAR) + '")'

				DECLARE @HASHBYTES_method VARCHAR
				SET @HASHBYTES_method = 'SHA2_256'

				-- DECLARE @return_status int;
				-- SET @return_status = 0;

				BEGIN TRANSACTION
IF EXISTS(SELECT 1 FROM [TMDBSQL].[dbo].[TMWDEALDB] WHERE [dealname] = @dealname AND ts_end IS NULL)
	BEGIN
		PRINT 'upsert_TMWDEALDB_staging("' + CAST(@dealname AS VARCHAR) + '") a current record exists'

		-- We need to figure out if the records are different
		DECLARE @StagingData NVARCHAR(MAX) = CONCAT_WS('|', 
						@dealname ,
						@undsym ,
						@acqsym ,
						@type ,
						@cashpct ,
						@stockpct ,
						@tndrpct ,
						@cashamt ,
						@ratio ,
						@lowcollar ,
						@highcollar ,
						@outsidelow ,
						@outsidehigh ,
						@dealamt ,
						@lowrange ,
						@highrange ,
						@revcollar ,
						@outflag ,
						@residual ,
						@origprice ,
						@origacq ,
						@downprice ,
						@d1date ,
						@d2date ,
						@ds1symbol ,
						@ds1price ,
						@ds2symbol ,
						@ds2price ,
						@ds3symbol ,
						@ds3price ,
						@ds4symbol ,
						@ds4price ,
						@ds5symbol ,
						@ds5price ,
						@ds6symbol ,
						@ds6price ,
						@ds7symbol ,
						@ds7price ,
						@ds8symbol ,
						@ds8price ,
						@ds9symbol ,
						@ds9price ,
						@ds10symbol ,
						@ds10price ,
						@desc ,
						@cashelect ,
						@canbuy ,
						@charge ,
						@dealdisp ,
						@zs1symbol ,
						@zs1price ,
						@zs2symbol ,
						@zs2price ,
						@zs3symbol ,
						@zs3price ,
						@zs4symbol ,
						@zs4price ,
						@zs5symbol ,
						@zs5price ,
						@zs6symbol ,
						@zs6price ,
						@zs7symbol ,
						@zs7price ,
						@zs8symbol ,
						@zs8price ,
						@zs9symbol ,
						@zs9price ,
						@zs10symbol ,
						@zs10price ,
						@zshortprice ,
						@other1 ,
						@other2 ,
						@other3 ,
						@numadditional ,
						@secsharesflag ,
						@definitive ,
						@initials1 ,
						@initials2 ,
						@dealreport ,
						@nondefcanbuy ,
						@defcanbuy ,
						@category ,
						@prevdown ,
						@prevzshort ,
						@prevadd1 ,
						@prevadd2 ,
						@prevadd3 ,
						@secondtier ,
						@strategy ,
						@currency ,
						@upsidemult ,
						@extracash ,
						@altclose ,
						@altupside ,
							@desc1 
		)

		DECLARE @ActualData  NVARCHAR(MAX)	
		SELECT @ActualData = CONCAT_WS('|', 
								[dealname] ,
								[undsym] ,
								[acqsym] ,
								[type] ,
								[cashpct] ,
								[stockpct] ,
								[tndrpct] ,
								[cashamt] ,
								[ratio] ,
								[lowcollar] ,
								[highcollar] ,
								[outsidelow] ,
								[outsidehigh] ,
								[dealamt] ,
								[lowrange] ,
								[highrange] ,
								[revcollar] ,
								[outflag] ,
								[residual] ,
								[origprice] ,
								[origacq] ,
								[downprice] ,
								[d1date] ,
								[d2date] ,
								[ds1symbol] ,
								[ds1price] ,
								[ds2symbol] ,
								[ds2price] ,
								[ds3symbol] ,
								[ds3price] ,
								[ds4symbol] ,
								[ds4price] ,
								[ds5symbol] ,
								[ds5price] ,
								[ds6symbol] ,
								[ds6price] ,
								[ds7symbol] ,
								[ds7price] ,
								[ds8symbol] ,
								[ds8price] ,
								[ds9symbol] ,
								[ds9price] ,
								[ds10symbol] ,
								[ds10price] ,
								[desc] ,
								[cashelect] ,
								[canbuy] ,
								[charge] ,
								[dealdisp] ,
								[zs1symbol] ,
								[zs1price] ,
								[zs2symbol] ,
								[zs2price] ,
								[zs3symbol] ,
								[zs3price] ,
								[zs4symbol] ,
								[zs4price] ,
								[zs5symbol] ,
								[zs5price] ,
								[zs6symbol] ,
								[zs6price] ,
								[zs7symbol] ,
								[zs7price] ,
								[zs8symbol] ,
								[zs8price] ,
								[zs9symbol] ,
								[zs9price] ,
								[zs10symbol] ,
								[zs10price] ,
								[zshortprice] ,
								[other1] ,
								[other2] ,
								[other3] ,
								[numadditional] ,
								[secsharesflag] ,
								[definitive] ,
								[initials1] ,
								[initials2] ,
								[dealreport] ,
								[nondefcanbuy] ,
								[defcanbuy] ,
								[category] ,
								[prevdown] ,
								[prevzshort] ,
								[prevadd1] ,
								[prevadd2] ,
								[prevadd3] ,
								[secondtier] ,
								[strategy] ,
								[currency] ,
								[upsidemult] ,
								[extracash] ,
								[altclose] ,
								[altupside] ,
								[desc1]  )
	
								FROM [TMDBSQL].[dbo].[TMWDEALDB] 
								WHERE (dealname = @dealname AND ts_end IS NULL)
	
				DECLARE @StagingDataHash NVARCHAR(64) = HASHBYTES('SHA2_256',@StagingData)
				DECLARE @ActualDataHash  NVARCHAR(64) = HASHBYTES('SHA2_256',@ActualData)
				
						PRINT 'DBG: upsert_TMWDEALDB_staging("' + CAST(@dealname AS VARCHAR) + '") @StagingDataHash = ' + @StagingDataHash 
						PRINT 'DBG: upsert_TMWDEALDB_staging("' + CAST(@dealname AS VARCHAR) + '") @ActualDataHash = ' + @ActualDataHash
						PRINT @StagingData
						PRINT @ActualData
		
		IF @StagingDataHash <> @ActualDataHash
			BEGIN
				PRINT 'upsert_TMWDEALDB_staging("' + CAST(@dealname AS VARCHAR) + '") - Giant OR failed'
				PRINT 'DBG: upsert_TMWDEALDB_staging("' + CAST(@dealname AS VARCHAR) + '") @StagingDataHash = ' + @StagingDataHash 
				PRINT 'DBG: upsert_TMWDEALDB_staging("' + CAST(@dealname AS VARCHAR) + '") @ActualDataHash = ' + @ActualDataHash
				PRINT @StagingData
				PRINT @ActualData

				UPDATE [TMDBSQL].[dbo].[TMWDEALDB] WITH (SERIALIZABLE)
					SET
						ts_end = @Timestamp
					WHERE
						dealname = @dealname AND ts_end IS NULL

					INSERT INTO [TMDBSQL].[dbo].[TMWDEALDB]
					(	
								[dealname] ,
								[ts_start] ,
								[ts_end] ,
								[undsym] ,
								[acqsym] ,
								[type] ,
								[cashpct] ,
								[stockpct] ,
								[tndrpct] ,
								[cashamt] ,
								[ratio] ,
								[lowcollar] ,
								[highcollar] ,
								[outsidelow] ,
								[outsidehigh] ,
								[dealamt] ,
								[lowrange] ,
								[highrange] ,
								[revcollar] ,
								[outflag] ,
								[residual] ,
								[origprice] ,
								[origacq] ,
								[downprice] ,
								[d1date] ,
								[d2date] ,
								[ds1symbol] ,
								[ds1price] ,
								[ds2symbol] ,
								[ds2price] ,
								[ds3symbol] ,
								[ds3price] ,
								[ds4symbol] ,
								[ds4price] ,
								[ds5symbol] ,
								[ds5price] ,
								[ds6symbol] ,
								[ds6price] ,
								[ds7symbol] ,
								[ds7price] ,
								[ds8symbol] ,
								[ds8price] ,
								[ds9symbol] ,
								[ds9price] ,
								[ds10symbol] ,
								[ds10price] ,
								[desc] ,
								[cashelect] ,
								[canbuy] ,
								[charge] ,
								[dealdisp] ,
								[zs1symbol] ,
								[zs1price] ,
								[zs2symbol] ,
								[zs2price] ,
								[zs3symbol] ,
								[zs3price] ,
								[zs4symbol] ,
								[zs4price] ,
								[zs5symbol] ,
								[zs5price] ,
								[zs6symbol] ,
								[zs6price] ,
								[zs7symbol] ,
								[zs7price] ,
								[zs8symbol] ,
								[zs8price] ,
								[zs9symbol] ,
								[zs9price] ,
								[zs10symbol] ,
								[zs10price] ,
								[zshortprice] ,
								[other1] ,
								[other2] ,
								[other3] ,
								[numadditional] ,
								[secsharesflag] ,
								[definitive] ,
								[initials1] ,
								[initials2] ,
								[dealreport] ,
								[nondefcanbuy] ,
								[defcanbuy] ,
								[category] ,
								[prevdown] ,
								[prevzshort] ,
								[prevadd1] ,
								[prevadd2] ,
								[prevadd3] ,
								[secondtier] ,
								[strategy] ,
								[currency] ,
								[upsidemult] ,
								[extracash] ,
								[altclose] ,
								[altupside] ,
								[desc1] 
						)
				VALUES
					(	@dealname ,
						@Timestamp ,
						NULL ,
						@undsym ,
						@acqsym ,
						@type ,
						@cashpct ,
						@stockpct ,
						@tndrpct ,
						@cashamt ,
						@ratio ,
						@lowcollar ,
						@highcollar ,
						@outsidelow ,
						@outsidehigh ,
						@dealamt ,
						@lowrange ,
						@highrange ,
						@revcollar ,
						@outflag ,
						@residual ,
						@origprice ,
						@origacq ,
						@downprice ,
						@d1date ,
						@d2date ,
						@ds1symbol ,
						@ds1price ,
						@ds2symbol ,
						@ds2price ,
						@ds3symbol ,
						@ds3price ,
						@ds4symbol ,
						@ds4price ,
						@ds5symbol ,
						@ds5price ,
						@ds6symbol ,
						@ds6price ,
						@ds7symbol ,
						@ds7price ,
						@ds8symbol ,
						@ds8price ,
						@ds9symbol ,
						@ds9price ,
						@ds10symbol ,
						@ds10price ,
						@desc ,
						@cashelect ,
						@canbuy ,
						@charge ,
						@dealdisp ,
						@zs1symbol ,
						@zs1price ,
						@zs2symbol ,
						@zs2price ,
						@zs3symbol ,
						@zs3price ,
						@zs4symbol ,
						@zs4price ,
						@zs5symbol ,
						@zs5price ,
						@zs6symbol ,
						@zs6price ,
						@zs7symbol ,
						@zs7price ,
						@zs8symbol ,
						@zs8price ,
						@zs9symbol ,
						@zs9price ,
						@zs10symbol ,
						@zs10price ,
						@zshortprice ,
						@other1 ,
						@other2 ,
						@other3 ,
						@numadditional ,
						@secsharesflag ,
						@definitive ,
						@initials1 ,
						@initials2 ,
						@dealreport ,
						@nondefcanbuy ,
						@defcanbuy ,
						@category ,
						@prevdown ,
						@prevzshort ,
						@prevadd1 ,
						@prevadd2 ,
						@prevadd3 ,
						@secondtier ,
						@strategy ,
						@currency ,
						@upsidemult ,
						@extracash ,
						@altclose ,
						@altupside ,
						@desc1 
						 )

				-- SET @return_status = 1
			END
		ELSE
			PRINT 'DBG: upsert_TMWDEALDB_staging("' + CAST(@dealname AS VARCHAR) + '") No change'
	END
ELSE
	BEGIN
	 -- Completely new record
					PRINT 'upsert_TMWDEALDB_staging("' + CAST(@dealname AS VARCHAR) + '") - New record'

					INSERT INTO [TMDBSQL].[dbo].[TMWDEALDB]
					(	
								[dealname] ,
								[ts_start] ,
								[ts_end] ,
								[undsym] ,
								[acqsym] ,
								[type] ,
								[cashpct] ,
								[stockpct] ,
								[tndrpct] ,
								[cashamt] ,
								[ratio] ,
								[lowcollar] ,
								[highcollar] ,
								[outsidelow] ,
								[outsidehigh] ,
								[dealamt] ,
								[lowrange] ,
								[highrange] ,
								[revcollar] ,
								[outflag] ,
								[residual] ,
								[origprice] ,
								[origacq] ,
								[downprice] ,
								[d1date] ,
								[d2date] ,
								[ds1symbol] ,
								[ds1price] ,
								[ds2symbol] ,
								[ds2price] ,
								[ds3symbol] ,
								[ds3price] ,
								[ds4symbol] ,
								[ds4price] ,
								[ds5symbol] ,
								[ds5price] ,
								[ds6symbol] ,
								[ds6price] ,
								[ds7symbol] ,
								[ds7price] ,
								[ds8symbol] ,
								[ds8price] ,
								[ds9symbol] ,
								[ds9price] ,
								[ds10symbol] ,
								[ds10price] ,
								[desc] ,
								[cashelect] ,
								[canbuy] ,
								[charge] ,
								[dealdisp] ,
								[zs1symbol] ,
								[zs1price] ,
								[zs2symbol] ,
								[zs2price] ,
								[zs3symbol] ,
								[zs3price] ,
								[zs4symbol] ,
								[zs4price] ,
								[zs5symbol] ,
								[zs5price] ,
								[zs6symbol] ,
								[zs6price] ,
								[zs7symbol] ,
								[zs7price] ,
								[zs8symbol] ,
								[zs8price] ,
								[zs9symbol] ,
								[zs9price] ,
								[zs10symbol] ,
								[zs10price] ,
								[zshortprice] ,
								[other1] ,
								[other2] ,
								[other3] ,
								[numadditional] ,
								[secsharesflag] ,
								[definitive] ,
								[initials1] ,
								[initials2] ,
								[dealreport] ,
								[nondefcanbuy] ,
								[defcanbuy] ,
								[category] ,
								[prevdown] ,
								[prevzshort] ,
								[prevadd1] ,
								[prevadd2] ,
								[prevadd3] ,
								[secondtier] ,
								[strategy] ,
								[currency] ,
								[upsidemult] ,
								[extracash] ,
								[altclose] ,
								[altupside] ,
									[desc1]
						)
				VALUES
					(	@dealname ,
						@Timestamp ,
						NULL ,
						@undsym ,
						@acqsym ,
						@type ,
						@cashpct ,
						@stockpct ,
						@tndrpct ,
						@cashamt ,
						@ratio ,
						@lowcollar ,
						@highcollar ,
						@outsidelow ,
						@outsidehigh ,
						@dealamt ,
						@lowrange ,
						@highrange ,
						@revcollar ,
						@outflag ,
						@residual ,
						@origprice ,
						@origacq ,
						@downprice ,
						@d1date ,
						@d2date ,
						@ds1symbol ,
						@ds1price ,
						@ds2symbol ,
						@ds2price ,
						@ds3symbol ,
						@ds3price ,
						@ds4symbol ,
						@ds4price ,
						@ds5symbol ,
						@ds5price ,
						@ds6symbol ,
						@ds6price ,
						@ds7symbol ,
						@ds7price ,
						@ds8symbol ,
						@ds8price ,
						@ds9symbol ,
						@ds9price ,
						@ds10symbol ,
						@ds10price ,
						@desc ,
						@cashelect ,
						@canbuy ,
						@charge ,
						@dealdisp ,
						@zs1symbol ,
						@zs1price ,
						@zs2symbol ,
						@zs2price ,
						@zs3symbol ,
						@zs3price ,
						@zs4symbol ,
						@zs4price ,
						@zs5symbol ,
						@zs5price ,
						@zs6symbol ,
						@zs6price ,
						@zs7symbol ,
						@zs7price ,
						@zs8symbol ,
						@zs8price ,
						@zs9symbol ,
						@zs9price ,
						@zs10symbol ,
						@zs10price ,
						@zshortprice ,
						@other1 ,
						@other2 ,
						@other3 ,
						@numadditional ,
						@secsharesflag ,
						@definitive ,
						@initials1 ,
						@initials2 ,
						@dealreport ,
						@nondefcanbuy ,
						@defcanbuy ,
						@category ,
						@prevdown ,
						@prevzshort ,
						@prevadd1 ,
						@prevadd2 ,
						@prevadd3 ,
						@secondtier ,
						@strategy ,
						@currency ,
						@upsidemult ,
						@extracash ,
						@altclose ,
						@altupside ,
						@desc1
						)

		-- SET @return_status = 1
	END
				
				COMMIT TRANSACTION

					FETCH NEXT FROM TMWDEALDB_staging_Cursor INTO
						@dealname ,
						@undsym ,
						@acqsym ,
						@type ,
						@cashpct ,
						@stockpct ,
						@tndrpct ,
						@cashamt ,
						@ratio ,
						@lowcollar ,
						@highcollar ,
						@outsidelow ,
						@outsidehigh ,
						@dealamt ,
						@lowrange ,
						@highrange ,
						@revcollar ,
						@outflag ,
						@residual ,
						@origprice ,
						@origacq ,
						@downprice ,
						@d1date ,
						@d2date ,
						@ds1symbol ,
						@ds1price ,
						@ds2symbol ,
						@ds2price ,
						@ds3symbol ,
						@ds3price ,
						@ds4symbol ,
						@ds4price ,
						@ds5symbol ,
						@ds5price ,
						@ds6symbol ,
						@ds6price ,
						@ds7symbol ,
						@ds7price ,
						@ds8symbol ,
						@ds8price ,
						@ds9symbol ,
						@ds9price ,
						@ds10symbol ,
						@ds10price ,
						@desc ,
						@cashelect ,
						@canbuy ,
						@charge ,
						@dealdisp ,
						@zs1symbol ,
						@zs1price ,
						@zs2symbol ,
						@zs2price ,
						@zs3symbol ,
						@zs3price ,
						@zs4symbol ,
						@zs4price ,
						@zs5symbol ,
						@zs5price ,
						@zs6symbol ,
						@zs6price ,
						@zs7symbol ,
						@zs7price ,
						@zs8symbol ,
						@zs8price ,
						@zs9symbol ,
						@zs9price ,
						@zs10symbol ,
						@zs10price ,
						@zshortprice ,
						@other1 ,
						@other2 ,
						@other3 ,
						@numadditional ,
						@secsharesflag ,
						@definitive ,
						@initials1 ,
						@initials2 ,
						@dealreport ,
						@nondefcanbuy ,
						@defcanbuy ,
						@category ,
						@prevdown ,
						@prevzshort ,
						@prevadd1 ,
						@prevadd2 ,
						@prevadd3 ,
						@secondtier ,
						@strategy ,
						@currency ,
						@upsidemult ,
						@extracash ,
						@altclose ,
						@altupside ,
						@desc1 

						 SET @CursorCount  = @CursorCount  + 1 
					END
 
		END
 
		CLOSE TMWDEALDB_staging_Cursor

		-- COMMIT TRANSACTION

		DEALLOCATE TMWDEALDB_staging_Cursor

		-- SET @return_status = 1

	END


GO
