SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[upsert_POSDB] 
	@Timestamp DateTime,
	@customSort varchar(100) ,
	@cash decimal(18, 2) ,
	@ccy varchar(3) ,
	@custodianName varchar(50) ,
	@customBloombergID varchar(25) ,
	@customFundName varchar(25) ,
	@customFundSort varchar(1) ,
	@customMarketPrice decimal(18, 5) ,
	@customRiskCategoryCode varchar(10) ,
	@customStrategyCode varchar(10) ,
	@customTicker varchar(15) ,
	@customTickerSort varchar(15) ,
	@dayGainLongPct decimal(18, 5) ,
	@dayGainShortPct decimal(18, 5) ,
	@dayGainTotalPct decimal(18, 5) ,
	@dtdPL decimal(18, 2) ,
	@fundCurrencyID int ,
	@fundName varchar(30) ,
	@lS varchar(1) ,
	@longMarketValue decimal(18, 2) ,
	@longMarketValueGL decimal(18, 5) ,
	@marketPrice decimal(18, 5) ,
	@marketValue decimal(18, 5) ,
	@marketValueDayGL decimal(18, 5) ,
	@marketValueLocal decimal(18, 2) ,
	@mtdPL decimal(18, 2) ,
	@position int ,
	@positionID int ,
	@realtimePositionCash decimal(18, 2) ,
	@riskCategoryID int ,
	@riskCategoryName varchar(20) ,
	@securityBloombergGlobalID varchar(15) ,
	@securityBloombergID varchar(25) ,
	@securityCurrencyID int ,
	@securityID int ,
	@securityName varchar(50) ,
	@securitySymbol varchar(25) ,
	@securityTicker varchar(20) ,
	@securityTypeName varchar(30) ,
	@shortMarketValue decimal(18, 2) ,
	@shortMarketValueGL decimal(18, 5) ,
	@strategy varchar(8) ,
	@strategyAcquirerSymbol varchar(8) ,
	@strategyActiveBenchmark int ,
	@strategyAlternateCloseDate date ,
	@strategyAlternateUpside decimal(18, 2) ,
	@strategyAmountRatioOutsideRange varchar(10) ,
	@strategyCanBuyAmount int ,
	@strategyCashPct decimal(18, 5) ,
	@strategyCashAmount decimal(18, 2) ,
	@strategyCashElection bit ,
	@strategyCategory varchar(10) ,
	@strategyCharge decimal(18, 2) ,
	@strategyCloseDate date ,
	@strategyCode varchar(10) ,
	@strategyCountry int ,
	@strategyCurrency varchar(3) ,
	@strategyDealAmount decimal(18, 2) ,
	@strategyDealType varchar(15) ,
	@strategyDealTypeID int ,
	@strategyDealname varchar(12) ,
	@strategyDefinitive bit ,
	@strategyDefinitiveCanBuyShares bit ,
	@strategyDefinitiveQ bit ,
	@strategyDescription varchar(75) ,
	@strategyDescription_1 varchar(75) ,
	@strategyDisplayonMonitor bit ,
	@strategyDisplayonReport bit ,
	@strategyDownsidePrice decimal(18, 2) ,
	@strategyDownsidePrice1 decimal(18, 2) ,
	@strategyDownsidePrice10 decimal(18, 2) ,
	@strategyDownsidePrice2 decimal(18, 2) ,
	@strategyDownsidePrice3 decimal(18, 2) ,
	@strategyDownsidePrice4 decimal(18, 2) ,
	@strategyDownsidePrice5 decimal(18, 2) ,
	@strategyDownsidePrice6 decimal(18, 2) ,
	@strategyDownsidePrice7 decimal(18, 2) ,
	@strategyDownsidePrice8 decimal(18, 2) ,
	@strategyDownsidePrice9 decimal(18, 2) ,
	@strategyDowsideSymbol1 varchar(10) ,
	@strategyDowsideSymbol10 varchar(10) ,
	@strategyDowsideSymbol2 varchar(10) ,
	@strategyDowsideSymbol3 varchar(10) ,
	@strategyDowsideSymbol4 varchar(10) ,
	@strategyDowsideSymbol5 varchar(10) ,
	@strategyDowsideSymbol6 varchar(10) ,
	@strategyDowsideSymbol7 varchar(10) ,
	@strategyDowsideSymbol8 varchar(10) ,
	@strategyDowsideSymbol9 varchar(10) ,
	@strategyEndDate date ,
	@strategyExtraCash decimal(18, 2) ,
	@strategyHighCollar decimal(18, 2) ,
	@strategyHighRange decimal(18, 2) ,
	@strategyIndustry int ,
	@strategyInitials1 varchar(1) ,
	@strategyInitials2 varchar(1) ,
	@strategyIsClosed bit ,
	@strategyLeverage decimal(18, 5) ,
	@strategyLowCollar decimal(18, 2) ,
	@strategyLowRange decimal(18, 2) ,
	@strategyName varchar(10) ,
	@strategyNonDefinitiveCanBuyShares int ,
	@strategyNumberAdditionalShares int ,
	@strategyOriginalAcqurerPrice decimal(18, 2) ,
	@strategyOriginalPrice decimal(18, 2) ,
	@strategyOther1 varchar(10) ,
	@strategyOther2 varchar(10) ,
	@strategyOther3 varchar(10) ,
	@strategyOutsideHigh decimal(18, 2) ,
	@strategyOutsideLow decimal(18, 2) ,
	@strategyPortfolio int ,
	@strategyRatio decimal(18, 5) ,
	@strategyUnderlyingSymbol varchar(12) ,
	@underlyingSymbol varchar(12) ,
	@unitCost decimal(18, 8) ,
	@ytdPL decimal(18, 2) ,
	@return_status INT = 0 OUTPUT 
AS
BEGIN

-- DECLARE @return_status int;
SET @return_status = 0;

BEGIN TRANSACTION

-- Check to see if we already have the bb symbol
IF EXISTS(SELECT 1 FROM [TMDBSQL].dbo.[POSDB])
	BEGIN
	    -- Only update if it has changed
		IF EXISTS(SELECT 1 FROM dbo.POSDB WHERE (CustomSort = @CustomSort AND ts_max IS NULL) AND
		(	
			@cash <> [cash] OR
			@ccy <> [ccy] OR
			@custodianName <> [custodian Name] OR
			@customBloombergID <> [customBloombergID] OR
			@customFundName <> [customFundName] OR
			@customFundSort <> [customFundSort] OR
			@customMarketPrice <> [customMarketPrice] OR
			@customRiskCategoryCode <> [customRiskCategoryCode] OR
			@customStrategyCode <> [customStrategyCode] OR
			@customTicker <> [customTicker] OR
			@customTickerSort <> [customTickerSort] OR
			@dayGainLongPct <> [day Gain Long %] OR
			@dayGainShortPct <> [day Gain Short %] OR
			@dayGainTotalPct <> [day Gain Total %] OR
			@dtdPL <> [dtd P/L] OR
			@fundCurrencyID <> [fund Currency ID] OR
			@fundName <> [fund Name] OR
			@lS <> [l/S] OR
			@longMarketValue <> [long Market Value] OR
			@longMarketValueGL <> [long Market Value G/L] OR
			@marketPrice <> [market Price] OR
			@marketValue <> [market Value] OR
			@marketValueDayGL <> [market Value Day G/L] OR
			@marketValueLocal <> [market Value Local] OR
			@mtdPL <> [mtd P/L] OR
			@position <> [position] OR
			@positionID <> [position ID] OR
			@realtimePositionCash <> [realtime Position Cash] OR
			@riskCategoryID <> [risk Category ID] OR
			@riskCategoryName <> [risk Category Name] OR
			@securityBloombergGlobalID <> [security Bloomberg Global ID] OR
			@securityBloombergID <> [security Bloomberg ID] OR
			@securityCurrencyID <> [security Currency ID] OR
			@securityID <> [security ID] OR
			@securityName <> [security Name] OR
			@securitySymbol <> [security Symbol] OR
			@securityTicker <> [security Ticker] OR
			@securityTypeName <> [security Type Name] OR
			@shortMarketValue <> [short Market Value] OR
			@shortMarketValueGL <> [short Market Value G/L] OR
			@strategy <> [strategy] OR
			@strategyAcquirerSymbol <> [strategy Acquirer Symbol] OR
			@strategyActiveBenchmark <> [strategy Active Benchmark] OR
			@strategyAlternateCloseDate <> [strategy Alternate Close Date] OR
			@strategyAlternateUpside <> [strategy Alternate Upside] OR
			@strategyAmountRatioOutsideRange <> [strategy Amount/Ratio Outside Range] OR
			@strategyCanBuyAmount <> [strategy Can Buy Amount] OR
			@strategyCashPct <> [strategy Cash %] OR
			@strategyCashAmount <> [strategy Cash Amount] OR
			@strategyCashElection <> [strategy Cash Election?] OR
			@strategyCategory <> [strategy Category] OR
			@strategyCharge <> [strategy Charge] OR
			@strategyCloseDate <> [strategy Close Date] OR
			@strategyCode <> [strategy Code] OR
			@strategyCountry <> [strategy Country] OR
			@strategyCurrency <> [strategy Currency] OR
			@strategyDealAmount <> [strategy Deal Amount] OR
			@strategyDealType <> [strategy Deal Type] OR
			@strategyDealTypeID <> [strategy Deal Type ID] OR
			@strategyDealname <> [strategy Dealname] OR
			@strategyDefinitive <> [strategy Definitive] OR
			@strategyDefinitiveCanBuyShares <> [strategy Definitive Can Buy Shares] OR
			@strategyDefinitiveQ <> [strategy Definitive?] OR
			@strategyDescription <> [strategy Description] OR
			@strategyDescription_1 <> [strategy Description_1] OR
			@strategyDisplayonMonitor <> [strategy Display on Monitor?] OR
			@strategyDisplayonReport <> [strategy Display on Report?] OR
			@strategyDownsidePrice<> [strategy Downside Price] OR
			@strategyDownsidePrice1<> [strategy Downside Price 1] OR
			@strategyDownsidePrice10 <> [strategy Downside Price 10] OR
			@strategyDownsidePrice2 <> [strategy Downside Price 2] OR
			@strategyDownsidePrice3 <> [strategy Downside Price 3] OR
			@strategyDownsidePrice4 <> [strategy Downside Price 4] OR
			@strategyDownsidePrice5 <> [strategy Downside Price 5] OR
			@strategyDownsidePrice6 <> [strategy Downside Price 6] OR
			@strategyDownsidePrice7 <> [strategy Downside Price 7] OR
			@strategyDownsidePrice8 <> [strategy Downside Price 8] OR
			@strategyDownsidePrice9 <> [strategy Downside Price 9] OR
			@strategyDowsideSymbol1 <> [strategy Dowside Symbol 1] OR
			@strategyDowsideSymbol10 <> [strategy Dowside Symbol 10] OR
			@strategyDowsideSymbol2 <> [strategy Dowside Symbol 2] OR
			@strategyDowsideSymbol3 <> [strategy Dowside Symbol 3] OR
			@strategyDowsideSymbol4 <> [strategy Dowside Symbol 4] OR
			@strategyDowsideSymbol5 <> [strategy Dowside Symbol 5] OR
			@strategyDowsideSymbol6 <> [strategy Dowside Symbol 6] OR
			@strategyDowsideSymbol7 <> [strategy Dowside Symbol 7] OR
			@strategyDowsideSymbol8 <> [strategy Dowside Symbol 8] OR
			@strategyDowsideSymbol9 <> [strategy Dowside Symbol 9] OR
			@strategyEndDate <> [strategy End Date] OR
			@strategyExtraCash <> [strategy Extra Cash] OR
			@strategyHighCollar <> [strategy High Collar] OR
			@strategyHighRange <> [strategy High Range] OR
			@strategyIndustry <> [strategy Industry] OR
			@strategyInitials1 <> [strategy Initials 1] OR
			@strategyInitials2 <> [strategy Initials 2] OR
			@strategyIsClosed <> [strategy Is Closed] OR
			@strategyLeverage <> [strategy Leverage] OR
			@strategyLowCollar <> [strategy Low Collar] OR
			@strategyLowRange <> [strategy Low Range] OR
			@strategyName <> [strategy Name] OR
			@strategyNonDefinitiveCanBuyShares <> [strategy Non-Definitive Can Buy Shares] OR
			@strategyNumberAdditionalShares <> [strategy Number Additional Shares] OR
			@strategyOriginalAcqurerPrice <> [strategy Original Acqurer Price] OR
			@strategyOriginalPrice <> [strategy Original Price] OR
			@strategyOther1 <> [strategy Other 1] OR
			@strategyOther2 <> [strategy Other 2] OR
			@strategyOther3 <> [strategy Other 3] OR
			@strategyOutsideHigh <> [strategy Outside High] OR
			@strategyOutsideLow <> [strategy Outside Low] OR
			@strategyPortfolio <> [strategy Portfolio] OR
			@strategyRatio <> [strategy Ratio] OR
			@strategyUnderlyingSymbol <> [strategy Underlying Symbol] OR
			@underlyingSymbol <> [underlying Symbol] OR
			@unitCost <> [unit Cost] OR
			@ytdPL <> [ytd P/L]  )
		)
			BEGIN
				UPDATE [TMDBSQL].[dbo].[POSDB] WITH (SERIALIZABLE)
					SET
						ts_max = @Timestamp
					WHERE
						CustomSort = @CustomSort and ts_max IS NULL

					INSERT INTO dbo.POSDB
					(
						[customSort] ,
						[ts_min] ,
						[ts_max] ,
						[cash] ,
						[ccy] ,
						[custodian Name] ,
						[customBloombergID] ,
						[customFundName] ,
						[customFundSort] ,
						[customMarketPrice] ,
						[customRiskCategoryCode] ,
						[customStrategyCode] ,
						[customTicker] ,
						[customTickerSort] ,
						[day Gain Long %] ,
						[day Gain Short %] ,
						[day Gain Total %] ,
						[dtd P/L] ,
						[fund Currency ID] ,
						[fund Name] ,
						[l/S] ,
						[long Market Value] ,
						[long Market Value G/L] ,
						[market Price] ,
						[market Value] ,
						[market Value Day G/L] ,
						[market Value Local] ,
						[mtd P/L] ,
						[position] ,
						[position ID] ,
						[realtime Position Cash] ,
						[risk Category ID] ,
						[risk Category Name] ,
						[security Bloomberg Global ID] ,
						[security Bloomberg ID] ,
						[security Currency ID] ,
						[security ID] ,
						[security Name] ,
						[security Symbol] ,
						[security Ticker] ,
						[security Type Name] ,
						[short Market Value] ,
						[short Market Value G/L] ,
						[strategy] ,
						[strategy Acquirer Symbol] ,
						[strategy Active Benchmark] ,
						[strategy Alternate Close Date] ,
						[strategy Alternate Upside] ,
						[strategy Amount/Ratio Outside Range] ,
						[strategy Can Buy Amount] ,
						[strategy Cash %] ,
						[strategy Cash Amount] ,
						[strategy Cash Election?] ,
						[strategy Category] ,
						[strategy Charge] ,
						[strategy Close Date] ,
						[strategy Code] ,
						[strategy Country] ,
						[strategy Currency] ,
						[strategy Deal Amount] ,
						[strategy Deal Type] ,
						[strategy Deal Type ID] ,
						[strategy Dealname] ,
						[strategy Definitive] ,
						[strategy Definitive Can Buy Shares] ,
						[strategy Definitive?] ,
						[strategy Description] ,
						[strategy Description_1] ,
						[strategy Display on Monitor?] ,
						[strategy Display on Report?] ,
						[strategy Downside Price] ,
						[strategy Downside Price 1] ,
						[strategy Downside Price 10] ,
						[strategy Downside Price 2] ,
						[strategy Downside Price 3] ,
						[strategy Downside Price 4] ,
						[strategy Downside Price 5] ,
						[strategy Downside Price 6] ,
						[strategy Downside Price 7] ,
						[strategy Downside Price 8] ,
						[strategy Downside Price 9] ,
						[strategy Dowside Symbol 1] ,
						[strategy Dowside Symbol 10] ,
						[strategy Dowside Symbol 2] ,
						[strategy Dowside Symbol 3] ,
						[strategy Dowside Symbol 4] ,
						[strategy Dowside Symbol 5] ,
						[strategy Dowside Symbol 6] ,
						[strategy Dowside Symbol 7] ,
						[strategy Dowside Symbol 8] ,
						[strategy Dowside Symbol 9] ,
						[strategy End Date] ,
						[strategy Extra Cash] ,
						[strategy High Collar] ,
						[strategy High Range] ,
						[strategy Industry] ,
						[strategy Initials 1] ,
						[strategy Initials 2] ,
						[strategy Is Closed] ,
						[strategy Leverage] ,
						[strategy Low Collar] ,
						[strategy Low Range] ,
						[strategy Name] ,
						[strategy Non-Definitive Can Buy Shares] ,
						[strategy Number Additional Shares] ,
						[strategy Original Acqurer Price] ,
						[strategy Original Price] ,
						[strategy Other 1] ,
						[strategy Other 2] ,
						[strategy Other 3] ,
						[strategy Outside High] ,
						[strategy Outside Low] ,
						[strategy Portfolio] ,
						[strategy Ratio] ,
						[strategy Underlying Symbol] ,
						[underlying Symbol] ,
						[unit Cost] ,
						[ytd P/L] 
 )
				VALUES
					(							
						@customSort ,
						@Timestamp ,
						NULL ,
						@cash,
						@ccy,
						@custodianName,
						@customBloombergID,
						@customFundName,
						@customFundSort,
						@customMarketPrice,
						@customRiskCategoryCode,
						@customStrategyCode,
						@customTicker,
						@customTickerSort,
						@dayGainLongPct,
						@dayGainShortPct,
						@dayGainTotalPct,
						@dtdPL,
						@fundCurrencyID,
						@fundName,
						@lS,
						@longMarketValue,
						@longMarketValueGL,
						@marketPrice,
						@marketValue,
						@marketValueDayGL,
						@marketValueLocal,
						@mtdPL,
						@position,
						@positionID,
						@realtimePositionCash,
						@riskCategoryID,
						@riskCategoryName,
						@securityBloombergGlobalID,
						@securityBloombergID,
						@securityCurrencyID,
						@securityID,
						@securityName,
						@securitySymbol,
						@securityTicker,
						@securityTypeName,
						@shortMarketValue,
						@shortMarketValueGL,
						@strategy,
						@strategyAcquirerSymbol,
						@strategyActiveBenchmark,
						@strategyAlternateCloseDate,
						@strategyAlternateUpside,
						@strategyAmountRatioOutsideRange,
						@strategyCanBuyAmount,
						@strategyCashPct,
						@strategyCashAmount,
						@strategyCashElection,
						@strategyCategory,
						@strategyCharge,
						@strategyCloseDate,
						@strategyCode,
						@strategyCountry,
						@strategyCurrency,
						@strategyDealAmount,
						@strategyDealType,
						@strategyDealTypeID,
						@strategyDealname,
						@strategyDefinitive,
						@strategyDefinitiveCanBuyShares,
						@strategyDefinitiveQ,
						@strategyDescription,
						@strategyDescription_1,
						@strategyDisplayonMonitor,
						@strategyDisplayonReport,
						@strategyDownsidePrice,
						@strategyDownsidePrice1,
						@strategyDownsidePrice10,
						@strategyDownsidePrice2,
						@strategyDownsidePrice3,
						@strategyDownsidePrice4,
						@strategyDownsidePrice5,
						@strategyDownsidePrice6,
						@strategyDownsidePrice7,
						@strategyDownsidePrice8,
						@strategyDownsidePrice9,
						@strategyDowsideSymbol1,
						@strategyDowsideSymbol10,
						@strategyDowsideSymbol2,
						@strategyDowsideSymbol3,
						@strategyDowsideSymbol4,
						@strategyDowsideSymbol5,
						@strategyDowsideSymbol6,
						@strategyDowsideSymbol7,
						@strategyDowsideSymbol8,
						@strategyDowsideSymbol9,
						@strategyEndDate,
						@strategyExtraCash,
						@strategyHighCollar,
						@strategyHighRange,
						@strategyIndustry,
						@strategyInitials1,
						@strategyInitials2,
						@strategyIsClosed,
						@strategyLeverage,
						@strategyLowCollar,
						@strategyLowRange,
						@strategyName,
						@strategyNonDefinitiveCanBuyShares,
						@strategyNumberAdditionalShares,
						@strategyOriginalAcqurerPrice,
						@strategyOriginalPrice,
						@strategyOther1,
						@strategyOther2,
						@strategyOther3,
						@strategyOutsideHigh,
						@strategyOutsideLow,
						@strategyPortfolio,
						@strategyRatio,
						@strategyUnderlyingSymbol,
						@underlyingSymbol,
						@unitCost,
						@ytdPL 
						)

				SET @return_status = 1
			END
	END
ELSE
	BEGIN
     -- Completely new record
	 INSERT INTO dbo.POSDB
					(
					[customSort] ,
					[ts_min] ,
					[ts_max] ,
					[cash] ,
					[ccy] ,
					[custodian Name] ,
					[customBloombergID] ,
					[customFundName] ,
					[customFundSort] ,
					[customMarketPrice] ,
					[customRiskCategoryCode] ,
					[customStrategyCode] ,
					[customTicker] ,
					[customTickerSort] ,
					[day Gain Long %] ,
					[day Gain Short %] ,
					[day Gain Total %] ,
					[dtd P/L] ,
					[fund Currency ID] ,
					[fund Name] ,
					[l/S] ,
					[long Market Value] ,
					[long Market Value G/L] ,
					[market Price] ,
					[market Value] ,
					[market Value Day G/L] ,
					[market Value Local] ,
					[mtd P/L] ,
					[position] ,
					[position ID] ,
					[realtime Position Cash] ,
					[risk Category ID] ,
					[risk Category Name] ,
					[security Bloomberg Global ID] ,
					[security Bloomberg ID] ,
					[security Currency ID] ,
					[security ID] ,
					[security Name] ,
					[security Symbol] ,
					[security Ticker] ,
					[security Type Name] ,
					[short Market Value] ,
					[short Market Value G/L] ,
					[strategy] ,
					[strategy Acquirer Symbol] ,
					[strategy Active Benchmark] ,
					[strategy Alternate Close Date] ,
					[strategy Alternate Upside] ,
					[strategy Amount/Ratio Outside Range] ,
					[strategy Can Buy Amount] ,
					[strategy Cash %] ,
					[strategy Cash Amount] ,
					[strategy Cash Election?] ,
					[strategy Category] ,
					[strategy Charge] ,
					[strategy Close Date] ,
					[strategy Code] ,
					[strategy Country] ,
					[strategy Currency] ,
					[strategy Deal Amount] ,
					[strategy Deal Type] ,
					[strategy Deal Type ID] ,
					[strategy Dealname] ,
					[strategy Definitive] ,
					[strategy Definitive Can Buy Shares] ,
					[strategy Definitive?] ,
					[strategy Description] ,
					[strategy Description_1] ,
					[strategy Display on Monitor?] ,
					[strategy Display on Report?] ,
					[strategy Downside Price] ,
					[strategy Downside Price 1] ,
					[strategy Downside Price 10] ,
					[strategy Downside Price 2] ,
					[strategy Downside Price 3] ,
					[strategy Downside Price 4] ,
					[strategy Downside Price 5] ,
					[strategy Downside Price 6] ,
					[strategy Downside Price 7] ,
					[strategy Downside Price 8] ,
					[strategy Downside Price 9] ,
					[strategy Dowside Symbol 1] ,
					[strategy Dowside Symbol 10] ,
					[strategy Dowside Symbol 2] ,
					[strategy Dowside Symbol 3] ,
					[strategy Dowside Symbol 4] ,
					[strategy Dowside Symbol 5] ,
					[strategy Dowside Symbol 6] ,
					[strategy Dowside Symbol 7] ,
					[strategy Dowside Symbol 8] ,
					[strategy Dowside Symbol 9] ,
					[strategy End Date] ,
					[strategy Extra Cash] ,
					[strategy High Collar] ,
					[strategy High Range] ,
					[strategy Industry] ,
					[strategy Initials 1] ,
					[strategy Initials 2] ,
					[strategy Is Closed] ,
					[strategy Leverage] ,
					[strategy Low Collar] ,
					[strategy Low Range] ,
					[strategy Name] ,
					[strategy Non-Definitive Can Buy Shares] ,
					[strategy Number Additional Shares] ,
					[strategy Original Acqurer Price] ,
					[strategy Original Price] ,
					[strategy Other 1] ,
					[strategy Other 2] ,
					[strategy Other 3] ,
					[strategy Outside High] ,
					[strategy Outside Low] ,
					[strategy Portfolio] ,
					[strategy Ratio] ,
					[strategy Underlying Symbol] ,
					[underlying Symbol] ,
					[unit Cost] ,
					[ytd P/L] 
			 )
				VALUES
					(							
						@customSort ,
						DATEADD(d, 0, DATEDIFF(d, 0, @Timestamp)) ,
						NULL ,
						@cash,
						@ccy,
						@custodianName,
						@customBloombergID,
						@customFundName,
						@customFundSort,
						@customMarketPrice,
						@customRiskCategoryCode,
						@customStrategyCode,
						@customTicker,
						@customTickerSort,
						@dayGainLongPct,
						@dayGainShortPct,
						@dayGainTotalPct,
						@dtdPL,
						@fundCurrencyID,
						@fundName,
						@lS,
						@longMarketValue,
						@longMarketValueGL,
						@marketPrice,
						@marketValue,
						@marketValueDayGL,
						@marketValueLocal,
						@mtdPL,
						@position,
						@positionID,
						@realtimePositionCash,
						@riskCategoryID,
						@riskCategoryName,
						@securityBloombergGlobalID,
						@securityBloombergID,
						@securityCurrencyID,
						@securityID,
						@securityName,
						@securitySymbol,
						@securityTicker,
						@securityTypeName,
						@shortMarketValue,
						@shortMarketValueGL,
						@strategy,
						@strategyAcquirerSymbol,
						@strategyActiveBenchmark,
						@strategyAlternateCloseDate,
						@strategyAlternateUpside,
						@strategyAmountRatioOutsideRange,
						@strategyCanBuyAmount,
						@strategyCashPct,
						@strategyCashAmount,
						@strategyCashElection,
						@strategyCategory,
						@strategyCharge,
						@strategyCloseDate,
						@strategyCode,
						@strategyCountry,
						@strategyCurrency,
						@strategyDealAmount,
						@strategyDealType,
						@strategyDealTypeID,
						@strategyDealname,
						@strategyDefinitive,
						@strategyDefinitiveCanBuyShares,
						@strategyDefinitiveQ,
						@strategyDescription,
						@strategyDescription_1,
						@strategyDisplayonMonitor,
						@strategyDisplayonReport,
						@strategyDownsidePrice,
						@strategyDownsidePrice1,
						@strategyDownsidePrice10,
						@strategyDownsidePrice2,
						@strategyDownsidePrice3,
						@strategyDownsidePrice4,
						@strategyDownsidePrice5,
						@strategyDownsidePrice6,
						@strategyDownsidePrice7,
						@strategyDownsidePrice8,
						@strategyDownsidePrice9,
						@strategyDowsideSymbol1,
						@strategyDowsideSymbol10,
						@strategyDowsideSymbol2,
						@strategyDowsideSymbol3,
						@strategyDowsideSymbol4,
						@strategyDowsideSymbol5,
						@strategyDowsideSymbol6,
						@strategyDowsideSymbol7,
						@strategyDowsideSymbol8,
						@strategyDowsideSymbol9,
						@strategyEndDate,
						@strategyExtraCash,
						@strategyHighCollar,
						@strategyHighRange,
						@strategyIndustry,
						@strategyInitials1,
						@strategyInitials2,
						@strategyIsClosed,
						@strategyLeverage,
						@strategyLowCollar,
						@strategyLowRange,
						@strategyName,
						@strategyNonDefinitiveCanBuyShares,
						@strategyNumberAdditionalShares,
						@strategyOriginalAcqurerPrice,
						@strategyOriginalPrice,
						@strategyOther1,
						@strategyOther2,
						@strategyOther3,
						@strategyOutsideHigh,
						@strategyOutsideLow,
						@strategyPortfolio,
						@strategyRatio,
						@strategyUnderlyingSymbol,
						@underlyingSymbol,
						@unitCost,
						@ytdPL 
						)

		SET @return_status = 1
	END

COMMIT TRANSACTION

-- PRINT @bbsecurity
-- PRINT @return_status
-- RETURN @return_status

END
GO
