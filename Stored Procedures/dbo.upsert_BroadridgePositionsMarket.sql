SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[upsert_BroadridgePositionsMarket] 
     @Timestamp DateTime
	,@UserName varchar(32)
	,@UniqKey varchar(30) 
	--,@Custodian_TradeCpty_TradeCptyName varchar(100) = NULL
	--,@CustomBloombergID varchar(100) = NULL
	--,@CustomFundName varchar(25) = NULL
	--,@CustomFundSort varchar(1) = NULL
	,@CustomMarketPrice decimal(30, 5) = NULL
	--,@CustomRiskCategoryCode varchar(10) = NULL
	--,@CustomStrategyCode varchar(10) = NULL
	--,@CustomTickerSort varchar(20) = NULL
	--,@CustomTicker varchar(20) = NULL
	--,@Fund_Currency_Currency_CurrencyID  int = NULL
	--,@Fund_TradeFund_Name varchar(30) = NULL
	--,@Position_Calculated_AverageCost decimal(30, 10) = NULL
	,@Position_Calculated_BaseLongMarketValueGain decimal(30, 8) = NULL
	,@Position_Calculated_BaseLongMarketValue decimal(30, 8) = NULL
	,@Position_Calculated_BaseMarketValueDayGain decimal(30, 8) = NULL
	,@Position_Calculated_BaseMarketValue decimal(30, 10) = NULL
	,@Position_Calculated_BasePNL_DTD decimal(30, 2) = NULL
	,@Position_Calculated_BasePNL_MTD decimal(30, 2) = NULL
	,@Position_Calculated_BasePNL_YTD decimal(30, 2) = NULL
	,@Position_Calculated_BaseShortMarketValueGain decimal(30, 8) = NULL
	,@Position_Calculated_BaseShortMarketValue decimal(30, 8) = NULL
	,@Position_Calculated_LocalMarketValue decimal(30, 8) = NULL
	,@Position_Calculated_MarketPrice decimal(30, 8) = NULL
	--,@Position_Calculated_PositionCash decimal(30, 2) = NULL
	--,@Position_Calculated_PositionValue decimal(18, 0) = NULL
	--,@Position_PositionID  int = NULL
	--,@Position_PositionTypeString varchar(1) = NULL
	--,@Security_Currency_Currency_Ccy varchar(3) = NULL
	--,@Security_Currency_Currency_CurrencyID  int = NULL
	--,@Security_Security_BloombergGlobalId varchar(12) = NULL
	--,@Security_Security_BloombergID varchar(25) = NULL
	--,@Security_Security_Code varchar(25) = NULL
	,@Security_Security_MD_RealTimePrice decimal(30, 8) = NULL
	--,@Security_Security_Name varchar(50) = NULL
	--,@Security_Security_SecurityID  int = NULL
	--,@Security_Security_Ticker varchar(20) = NULL
	--,@Security_Type_SecurityType_Name varchar(30) = NULL
	--,@Security_Underlying_Security_Code varchar(15) = NULL
	--,@Strategy_Risk_Category_RiskCategory_RiskCategoryID  int = NULL
	--,@Strategy_Risk_Category_RiskCategory_RiskName varchar(20) = NULL
	--,@Strategy_TradeStrategy_ActiveBenchmarkID  int = NULL
	--,@Strategy_TradeStrategy_CountryID_mkt  int = NULL
	--,@Strategy_TradeStrategy_Description varchar(75) = NULL
	--,@Strategy_TradeStrategy_EndDate date = NULL
	--,@Strategy_TradeStrategy_IndustryID  int = NULL
	--,@Strategy_TradeStrategy_IsClosed bit = NULL
	--,@Strategy_TradeStrategy_Leverage decimal(30, 8) = NULL
	--,@Strategy_TradeStrategy_Name varchar(10) = NULL
	--,@Strategy_TradeStrategy_PortfolioID  int = NULL
	--,@Strategy_TradeStrategy_ShortCode varchar(10) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwAcqsym varchar(10) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwAltupside decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwCanbuy  int = NULL
	--,@Strategy_TradeStrategy_UDF_tmwCashamt decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwCashelect bit = NULL
	--,@Strategy_TradeStrategy_UDF_tmwCashpct decimal(30, 15) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwCategory varchar(100) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwCharge decimal(30, 15) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwCurrency varchar(100) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwD1Date date = NULL
	--,@Strategy_TradeStrategy_UDF_tmwD2Date date = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDealamt decimal(30, 15) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDealdisp bit = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDealname varchar(100) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDealreport bit = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDealtype varchar(100) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDealtypeID  int = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDefcanbuy bit = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDefinative bit = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDefinitive bit = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDesc varchar(100) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDownprice decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs10Price decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs10Symbol varchar(10) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs1Price decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs1Symbol varchar(10) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs2Price decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs2Symbol varchar(10) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs3Price decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs3Symbol varchar(10) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs4Price decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs4Symbol varchar(10) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs5Price decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs5Symbol varchar(10) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs6Price decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs6Symbol varchar(10) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs7Price decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs7Symbol varchar(10) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs8Price decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs8Symbol varchar(10) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs9Price decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwDs9Symbol varchar(10) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwExtracash decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwHighcollar decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwHighrange decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwInitials1 varchar(1) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwInitials2 varchar(1) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwLowcollar decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwLowrange decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwNondefcanbuy  int = NULL
	--,@Strategy_TradeStrategy_UDF_tmwNumadditional  int = NULL
	--,@Strategy_TradeStrategy_UDF_tmwOrigacq decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwOrigprice decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwOther1 varchar(100) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwOther2 varchar(100) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwOther3 varchar(100) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwOutflag varchar(100) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwOutsidehigh decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwOutsidelow decimal(30, 2) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwRatio decimal(30, 10) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwStrategy varchar(8) = NULL
	--,@Strategy_TradeStrategy_UDF_tmwUndsym varchar(10) = NULL
	--,@Total_Position_Calculated_PositionCash decimal(30, 2) = NULL

		   ,@return_status INT = 0 OUTPUT 
AS
BEGIN

DECLARE @HASHBYTES_method VARCHAR
SET @HASHBYTES_method = 'SHA2_256'

-- DECLARE @return_status int;
SET @return_status = 0;

BEGIN TRANSACTION

-- Check to see if we already have the bb symbol
IF EXISTS(SELECT 1 FROM [TMDBSQL].[dbo].[BroadridgePositionsMarket] WHERE UserName = @UserName AND [UniqKey] = @UniqKey AND ts_end IS NULL)
	BEGIN
		PRINT 'upsert_BroadridgePositionsMarket("' + CAST(@UserName AS VARCHAR) + '" , "' + CAST(@UniqKey AS VARCHAR) + '") a current record exists'

	    -- We need to figure out if the records are different
		DECLARE @StagingData NVARCHAR(MAX) = CONCAT_WS('|', 
            @UserName
		   ,@UniqKey 
		   --,@Custodian_TradeCpty_TradeCptyName 
     --      ,@CustomBloombergID 
     --      ,@CustomFundName 
     --      ,@CustomFundSort 
           ,@CustomMarketPrice 
     --      ,@CustomRiskCategoryCode 
     --      ,@CustomStrategyCode 
     --      ,@CustomTicker 
     --      ,@CustomTickerSort 
           --,@Fund_Currency_Currency_CurrencyID 
           --,@Fund_TradeFund_Name 
      --     ,@Position_Calculated_AverageCost 
           ,@Position_Calculated_BaseLongMarketValueGain 
           ,@Position_Calculated_BaseLongMarketValue 
		   ,@Position_Calculated_BaseMarketValueDayGain 
           ,@Position_Calculated_BaseMarketValue 
           ,@Position_Calculated_BasePNL_DTD 
           ,@Position_Calculated_BasePNL_MTD 
           ,@Position_Calculated_BasePNL_YTD 
           ,@Position_Calculated_BaseShortMarketValueGain 
           ,@Position_Calculated_BaseShortMarketValue 
           ,@Position_Calculated_LocalMarketValue 
           ,@Position_Calculated_MarketPrice 
      --     ,@Position_Calculated_PositionCash 
      --     ,@Position_Calculated_PositionValue 
    --       ,@Position_PositionID 
     --      ,@Position_PositionTypeString 
           --,@Security_Currency_Currency_Ccy 
           --,@Security_Currency_Currency_CurrencyID 
           --,@Security_Security_BloombergGlobalId 
           --,@Security_Security_BloombergID 
           --,@Security_Security_Code 
			,@Security_Security_MD_RealTimePrice
           --,@Security_Security_Name 
           --,@Security_Security_SecurityID 
           --,@Security_Security_Ticker 
           --,@Security_Type_SecurityType_Name 
           --,@Security_Underlying_Security_Code 
           --,@Strategy_Risk_Category_RiskCategory_RiskCategoryID 
           --,@Strategy_Risk_Category_RiskCategory_RiskName 
           --,@Strategy_TradeStrategy_ActiveBenchmarkID 
           --,@Strategy_TradeStrategy_CountryID_mkt 
           --,@Strategy_TradeStrategy_Description 
           --,@Strategy_TradeStrategy_EndDate 
           --,@Strategy_TradeStrategy_IndustryID 
           --,@Strategy_TradeStrategy_IsClosed 
           --,@Strategy_TradeStrategy_Leverage 
           --,@Strategy_TradeStrategy_Name 
           --,@Strategy_TradeStrategy_PortfolioID 
           --,@Strategy_TradeStrategy_ShortCode 
           --,@Strategy_TradeStrategy_UDF_tmwAcqsym 
           --,@Strategy_TradeStrategy_UDF_tmwAltupside 
           --,@Strategy_TradeStrategy_UDF_tmwCanbuy 
           --,@Strategy_TradeStrategy_UDF_tmwCashamt 
           --,@Strategy_TradeStrategy_UDF_tmwCashelect 
           --,@Strategy_TradeStrategy_UDF_tmwCashpct 
           --,@Strategy_TradeStrategy_UDF_tmwCategory 
           --,@Strategy_TradeStrategy_UDF_tmwCharge 
           --,@Strategy_TradeStrategy_UDF_tmwCurrency 
           --,@Strategy_TradeStrategy_UDF_tmwD1Date 
           --,@Strategy_TradeStrategy_UDF_tmwD2Date 
           --,@Strategy_TradeStrategy_UDF_tmwDealamt 
           --,@Strategy_TradeStrategy_UDF_tmwDealdisp 
           --,@Strategy_TradeStrategy_UDF_tmwDealname 
           --,@Strategy_TradeStrategy_UDF_tmwDealreport 
           --,@Strategy_TradeStrategy_UDF_tmwDealtype 
           --,@Strategy_TradeStrategy_UDF_tmwDealtypeID 
           --,@Strategy_TradeStrategy_UDF_tmwDefcanbuy 
           --,@Strategy_TradeStrategy_UDF_tmwDefinative 
           --,@Strategy_TradeStrategy_UDF_tmwDefinitive 
           --,@Strategy_TradeStrategy_UDF_tmwDesc 
           --,@Strategy_TradeStrategy_UDF_tmwDownprice 
           --,@Strategy_TradeStrategy_UDF_tmwDs10Price 
           --,@Strategy_TradeStrategy_UDF_tmwDs10Symbol 
           --,@Strategy_TradeStrategy_UDF_tmwDs1Price 
           --,@Strategy_TradeStrategy_UDF_tmwDs1Symbol 
           --,@Strategy_TradeStrategy_UDF_tmwDs2Price 
           --,@Strategy_TradeStrategy_UDF_tmwDs2Symbol 
           --,@Strategy_TradeStrategy_UDF_tmwDs3Price 
           --,@Strategy_TradeStrategy_UDF_tmwDs3Symbol 
           --,@Strategy_TradeStrategy_UDF_tmwDs4Price 
           --,@Strategy_TradeStrategy_UDF_tmwDs4Symbol 
           --,@Strategy_TradeStrategy_UDF_tmwDs5Price 
           --,@Strategy_TradeStrategy_UDF_tmwDs5Symbol 
           --,@Strategy_TradeStrategy_UDF_tmwDs6Price 
           --,@Strategy_TradeStrategy_UDF_tmwDs6Symbol 
           --,@Strategy_TradeStrategy_UDF_tmwDs7Price 
           --,@Strategy_TradeStrategy_UDF_tmwDs7Symbol 
           --,@Strategy_TradeStrategy_UDF_tmwDs8Price 
           --,@Strategy_TradeStrategy_UDF_tmwDs8Symbol 
           --,@Strategy_TradeStrategy_UDF_tmwDs9Price 
           --,@Strategy_TradeStrategy_UDF_tmwDs9Symbol 
           --,@Strategy_TradeStrategy_UDF_tmwExtracash 
           --,@Strategy_TradeStrategy_UDF_tmwHighcollar 
           --,@Strategy_TradeStrategy_UDF_tmwHighrange 
           --,@Strategy_TradeStrategy_UDF_tmwInitials1 
           --,@Strategy_TradeStrategy_UDF_tmwInitials2 
           --,@Strategy_TradeStrategy_UDF_tmwLowcollar 
           --,@Strategy_TradeStrategy_UDF_tmwLowrange 
           --,@Strategy_TradeStrategy_UDF_tmwNondefcanbuy 
           --,@Strategy_TradeStrategy_UDF_tmwNumadditional 
           --,@Strategy_TradeStrategy_UDF_tmwOrigacq 
           --,@Strategy_TradeStrategy_UDF_tmwOrigprice 
           --,@Strategy_TradeStrategy_UDF_tmwOther1 
           --,@Strategy_TradeStrategy_UDF_tmwOther2 
           --,@Strategy_TradeStrategy_UDF_tmwOther3 
           --,@Strategy_TradeStrategy_UDF_tmwOutflag 
           --,@Strategy_TradeStrategy_UDF_tmwOutsidehigh 
           --,@Strategy_TradeStrategy_UDF_tmwOutsidelow 
           --,@Strategy_TradeStrategy_UDF_tmwRatio 
           --,@Strategy_TradeStrategy_UDF_tmwStrategy 
           --,@Strategy_TradeStrategy_UDF_tmwUndsym 
           --,@Total_Position_Calculated_PositionCash 
		)

		DECLARE @ActualData  NVARCHAR(MAX)	
		SELECT @ActualData = CONCAT_WS('|', 
									[UserName] ,
									[UniqKey] ,
									--[Custodian_TradeCpty_TradeCptyName] ,
									--[CustomBloombergID] ,
									--[CustomFundName] ,
									--[CustomFundSort] ,
									[CustomMarketPrice] ,
									--[CustomRiskCategoryCode] ,
									--[CustomStrategyCode] ,
									--[CustomTickerSort] ,
									--[CustomTicker] ,
									--[Fund_Currency_Currency_CurrencyID] ,
									--[Fund_TradeFund_Name] ,
							--		[Position_Calculated_AverageCost] ,
									[Position_Calculated_BaseLongMarketValueGain] ,
									[Position_Calculated_BaseLongMarketValue] ,
									[Position_Calculated_BaseMarketValueDayGain] ,
									[Position_Calculated_BaseMarketValue] ,
									[Position_Calculated_BasePNL_DTD] ,
									[Position_Calculated_BasePNL_MTD] ,
									[Position_Calculated_BasePNL_YTD] ,					
									[Position_Calculated_BaseShortMarketValueGain] ,
									[Position_Calculated_BaseShortMarketValue] ,
									[Position_Calculated_LocalMarketValue] ,
									[Position_Calculated_MarketPrice] ,
							--		[Position_Calculated_PositionCash] ,
							--		[Position_Calculated_PositionValue] ,
							--		[Position_PositionID] ,
							--		[Position_PositionTypeString] 
									--[Security_Currency_Currency_Ccy] ,
									--[Security_Currency_Currency_CurrencyID] ,
									--[Security_Security_BloombergGlobalId] ,
									--[Security_Security_BloombergID] ,
									--[Security_Security_Code] ,
									[Security_Security_MD_RealTimePrice]
									--[Security_Security_Name] ,
									--[Security_Security_SecurityID] ,
									--[Security_Security_Ticker] ,
									--[Security_Type_SecurityType_Name] ,
									--[Security_Underlying_Security_Code] ,
									--[Strategy_Risk_Category_RiskCategory_RiskCategoryID] ,
									--[Strategy_Risk_Category_RiskCategory_RiskName] ,
									--[Strategy_TradeStrategy_ActiveBenchmarkID] ,
									--[Strategy_TradeStrategy_CountryID_mkt] ,
									--[Strategy_TradeStrategy_Description] ,
									--[Strategy_TradeStrategy_EndDate] ,
									--[Strategy_TradeStrategy_IndustryID] ,
									--[Strategy_TradeStrategy_IsClosed] ,
									--[Strategy_TradeStrategy_Leverage] ,
									--[Strategy_TradeStrategy_Name] ,
									--[Strategy_TradeStrategy_PortfolioID] ,
									--[Strategy_TradeStrategy_ShortCode] ,
									--[Strategy_TradeStrategy_UDF_tmwAcqsym] ,
									--[Strategy_TradeStrategy_UDF_tmwAltupside] ,
									--[Strategy_TradeStrategy_UDF_tmwCanbuy] ,
									--[Strategy_TradeStrategy_UDF_tmwCashamt] ,
									--[Strategy_TradeStrategy_UDF_tmwCashelect] ,
									--[Strategy_TradeStrategy_UDF_tmwCashpct] ,
									--[Strategy_TradeStrategy_UDF_tmwCategory] ,
									--[Strategy_TradeStrategy_UDF_tmwCharge] ,
									--[Strategy_TradeStrategy_UDF_tmwCurrency] ,
									--[Strategy_TradeStrategy_UDF_tmwD1Date] ,
									--[Strategy_TradeStrategy_UDF_tmwD2Date] ,
									--[Strategy_TradeStrategy_UDF_tmwDealamt] ,
									--[Strategy_TradeStrategy_UDF_tmwDealdisp] ,
									--[Strategy_TradeStrategy_UDF_tmwDealname] ,
									--[Strategy_TradeStrategy_UDF_tmwDealreport] ,
									--[Strategy_TradeStrategy_UDF_tmwDealtype] ,
									--[Strategy_TradeStrategy_UDF_tmwDealtypeID] ,
									--[Strategy_TradeStrategy_UDF_tmwDefcanbuy] ,
									--[Strategy_TradeStrategy_UDF_tmwDefinative] ,
									--[Strategy_TradeStrategy_UDF_tmwDefinitive] ,
									--[Strategy_TradeStrategy_UDF_tmwDesc] ,
									--[Strategy_TradeStrategy_UDF_tmwDownprice] ,
									--[Strategy_TradeStrategy_UDF_tmwDs10Price] ,
									--[Strategy_TradeStrategy_UDF_tmwDs10Symbol] ,
									--[Strategy_TradeStrategy_UDF_tmwDs1Price] ,
									--[Strategy_TradeStrategy_UDF_tmwDs1Symbol] ,
									--[Strategy_TradeStrategy_UDF_tmwDs2Price] ,
									--[Strategy_TradeStrategy_UDF_tmwDs2Symbol] ,
									--[Strategy_TradeStrategy_UDF_tmwDs3Price] ,
									--[Strategy_TradeStrategy_UDF_tmwDs3Symbol] ,
									--[Strategy_TradeStrategy_UDF_tmwDs4Price] ,
									--[Strategy_TradeStrategy_UDF_tmwDs4Symbol] ,
									--[Strategy_TradeStrategy_UDF_tmwDs5Price] ,
									--[Strategy_TradeStrategy_UDF_tmwDs5Symbol] ,
									--[Strategy_TradeStrategy_UDF_tmwDs6Price] ,
									--[Strategy_TradeStrategy_UDF_tmwDs6Symbol] ,
									--[Strategy_TradeStrategy_UDF_tmwDs7Price] ,
									--[Strategy_TradeStrategy_UDF_tmwDs7Symbol] ,
									--[Strategy_TradeStrategy_UDF_tmwDs8Price] ,
									--[Strategy_TradeStrategy_UDF_tmwDs8Symbol] ,
									--[Strategy_TradeStrategy_UDF_tmwDs9Price] ,
									--[Strategy_TradeStrategy_UDF_tmwDs9Symbol] ,
									--[Strategy_TradeStrategy_UDF_tmwExtracash] ,
									--[Strategy_TradeStrategy_UDF_tmwHighcollar] ,
									--[Strategy_TradeStrategy_UDF_tmwHighrange] ,
									--[Strategy_TradeStrategy_UDF_tmwInitials1] ,
									--[Strategy_TradeStrategy_UDF_tmwInitials2] ,
									--[Strategy_TradeStrategy_UDF_tmwLowcollar] ,
									--[Strategy_TradeStrategy_UDF_tmwLowrange] ,
									--[Strategy_TradeStrategy_UDF_tmwNondefcanbuy] ,
									--[Strategy_TradeStrategy_UDF_tmwNumadditional] ,
									--[Strategy_TradeStrategy_UDF_tmwOrigacq] ,
									--[Strategy_TradeStrategy_UDF_tmwOrigprice] ,
									--[Strategy_TradeStrategy_UDF_tmwOther1] ,
									--[Strategy_TradeStrategy_UDF_tmwOther2] ,
									--[Strategy_TradeStrategy_UDF_tmwOther3] ,
									--[Strategy_TradeStrategy_UDF_tmwOutflag] ,
									--[Strategy_TradeStrategy_UDF_tmwOutsidehigh] ,
									--[Strategy_TradeStrategy_UDF_tmwOutsidelow] ,
									--[Strategy_TradeStrategy_UDF_tmwRatio] ,
									--[Strategy_TradeStrategy_UDF_tmwStrategy] ,
									--[Strategy_TradeStrategy_UDF_tmwUndsym] ,
									--[Total_Position_Calculated_PositionCash]
									)		
								FROM [TMDBSQL].[dbo].[BroadridgePositionsMarket] 
								WHERE (UserName = @UserName AND [UniqKey] = @UniqKey AND ts_end IS NULL)
	
				DECLARE @StagingDataHash NVARCHAR(64) = HASHBYTES('SHA2_256',@StagingData)
				DECLARE @ActualDataHash  NVARCHAR(64) = HASHBYTES('SHA2_256',@ActualData)		

		IF @StagingDataHash <> @ActualDataHash
			BEGIN
				PRINT 'upsert_BroadridgePositionsMarket("' + CAST(@UniqKey AS VARCHAR) + '") - Giant OR failed'
				PRINT 'DBG: upsert_BroadridgePositionsMarket("' + CAST(@UniqKey AS VARCHAR) + '") @StagingDataHash = ' + @StagingDataHash 
				PRINT 'DBG: upsert_BroadridgePositionsMarket("' + CAST(@UniqKey AS VARCHAR) + '") @ActualDataHash = ' + @ActualDataHash
				PRINT @StagingData
				PRINT @ActualData

				UPDATE [TMDBSQL].[dbo].[BroadridgePositionsMarket] WITH (SERIALIZABLE)
					SET
						ts_end = @Timestamp
					WHERE
						UserName = @UserName AND [UniqKey] = @UniqKey AND ts_end IS NULL

					INSERT INTO [TMDBSQL].[dbo].[BroadridgePositionsMarket]
					(	
						[UserName] ,
						[UniqKey] ,
						ts_start ,
						ts_end ,
						--[Custodian_TradeCpty_TradeCptyName] ,
						--[CustomBloombergID] ,
						--[CustomFundName] ,
						--[CustomFundSort] ,
						[CustomMarketPrice] ,
						--[CustomRiskCategoryCode] ,
						--[CustomStrategyCode] ,
						--[CustomTickerSort] ,
						--[CustomTicker] ,
						--[Fund_Currency_Currency_CurrencyID] ,
						--[Fund_TradeFund_Name] ,
						--[Position_Calculated_AverageCost] ,
						[Position_Calculated_BaseLongMarketValueGain] ,
						[Position_Calculated_BaseLongMarketValue] ,
						[Position_Calculated_BaseMarketValueDayGain] ,
						[Position_Calculated_BaseMarketValue] ,
						[Position_Calculated_BasePNL_DTD] ,
						[Position_Calculated_BasePNL_MTD] ,
						[Position_Calculated_BasePNL_YTD] ,					
						[Position_Calculated_BaseShortMarketValueGain] ,
						[Position_Calculated_BaseShortMarketValue] ,
						[Position_Calculated_LocalMarketValue] ,
						[Position_Calculated_MarketPrice] , 
					--	[Position_Calculated_PositionCash] ,
					--	[Position_Calculated_PositionValue] ,
					--	[Position_PositionID] ,
					--	[Position_PositionTypeString] 
						--[Security_Currency_Currency_Ccy] ,
						--[Security_Currency_Currency_CurrencyID] ,
						--[Security_Security_BloombergGlobalId] ,
						--[Security_Security_BloombergID] ,
						--[Security_Security_Code] ,
						[Security_Security_MD_RealTimePrice] 
						--[Security_Security_Name] ,
						--[Security_Security_SecurityID] ,
						--[Security_Security_Ticker] ,
						--[Security_Type_SecurityType_Name] ,
						--[Security_Underlying_Security_Code] ,
						--[Strategy_Risk_Category_RiskCategory_RiskCategoryID] ,
						--[Strategy_Risk_Category_RiskCategory_RiskName] ,
						--[Strategy_TradeStrategy_ActiveBenchmarkID] ,
						--[Strategy_TradeStrategy_CountryID_mkt] ,
						--[Strategy_TradeStrategy_Description] ,
						--[Strategy_TradeStrategy_EndDate] ,
						--[Strategy_TradeStrategy_IndustryID] ,
						--[Strategy_TradeStrategy_IsClosed] ,
						--[Strategy_TradeStrategy_Leverage] ,
						--[Strategy_TradeStrategy_Name] ,
						--[Strategy_TradeStrategy_PortfolioID] ,
						--[Strategy_TradeStrategy_ShortCode] ,
						--[Strategy_TradeStrategy_UDF_tmwAcqsym] ,
						--[Strategy_TradeStrategy_UDF_tmwAltupside] ,
						--[Strategy_TradeStrategy_UDF_tmwCanbuy] ,
						--[Strategy_TradeStrategy_UDF_tmwCashamt] ,
						--[Strategy_TradeStrategy_UDF_tmwCashelect] ,
						--[Strategy_TradeStrategy_UDF_tmwCashpct] ,
						--[Strategy_TradeStrategy_UDF_tmwCategory] ,
						--[Strategy_TradeStrategy_UDF_tmwCharge] ,
						--[Strategy_TradeStrategy_UDF_tmwCurrency] ,
						--[Strategy_TradeStrategy_UDF_tmwD1Date] ,
						--[Strategy_TradeStrategy_UDF_tmwD2Date] ,
						--[Strategy_TradeStrategy_UDF_tmwDealamt] ,
						--[Strategy_TradeStrategy_UDF_tmwDealdisp] ,
						--[Strategy_TradeStrategy_UDF_tmwDealname] ,
						--[Strategy_TradeStrategy_UDF_tmwDealreport] ,
						--[Strategy_TradeStrategy_UDF_tmwDealtype] ,
						--[Strategy_TradeStrategy_UDF_tmwDealtypeID] ,
						--[Strategy_TradeStrategy_UDF_tmwDefcanbuy] ,
						--[Strategy_TradeStrategy_UDF_tmwDefinative] ,
						--[Strategy_TradeStrategy_UDF_tmwDefinitive] ,
						--[Strategy_TradeStrategy_UDF_tmwDesc] ,
						--[Strategy_TradeStrategy_UDF_tmwDownprice] ,
						--[Strategy_TradeStrategy_UDF_tmwDs10Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs10Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs1Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs1Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs2Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs2Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs3Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs3Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs4Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs4Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs5Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs5Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs6Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs6Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs7Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs7Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs8Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs8Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs9Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs9Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwExtracash] ,
						--[Strategy_TradeStrategy_UDF_tmwHighcollar] ,
						--[Strategy_TradeStrategy_UDF_tmwHighrange] ,
						--[Strategy_TradeStrategy_UDF_tmwInitials1] ,
						--[Strategy_TradeStrategy_UDF_tmwInitials2] ,
						--[Strategy_TradeStrategy_UDF_tmwLowcollar] ,
						--[Strategy_TradeStrategy_UDF_tmwLowrange] ,
						--[Strategy_TradeStrategy_UDF_tmwNondefcanbuy] ,
						--[Strategy_TradeStrategy_UDF_tmwNumadditional] ,
						--[Strategy_TradeStrategy_UDF_tmwOrigacq] ,
						--[Strategy_TradeStrategy_UDF_tmwOrigprice] ,
						--[Strategy_TradeStrategy_UDF_tmwOther1] ,
						--[Strategy_TradeStrategy_UDF_tmwOther2] ,
						--[Strategy_TradeStrategy_UDF_tmwOther3] ,
						--[Strategy_TradeStrategy_UDF_tmwOutflag] ,
						--[Strategy_TradeStrategy_UDF_tmwOutsidehigh] ,
						--[Strategy_TradeStrategy_UDF_tmwOutsidelow] ,
						--[Strategy_TradeStrategy_UDF_tmwRatio] ,
						--[Strategy_TradeStrategy_UDF_tmwStrategy] ,
						--[Strategy_TradeStrategy_UDF_tmwUndsym] ,
						--[Total_Position_Calculated_PositionCash] 
						)
				VALUES
					(	 @UserName 
						,@UniqKey 
						,@Timestamp
						,NULL
						--,@Custodian_TradeCpty_TradeCptyName
						--,@CustomBloombergID
						--,@CustomFundName 
						--,@CustomFundSort 
						,@CustomMarketPrice 
						--,@CustomRiskCategoryCode 
						--,@CustomStrategyCode 
						--,@CustomTicker 
						--,@CustomTickerSort 
						--,@Fund_Currency_Currency_CurrencyID 
						--,@Fund_TradeFund_Name 
					--	,@Position_Calculated_AverageCost 
						,@Position_Calculated_BaseLongMarketValueGain 
						,@Position_Calculated_BaseLongMarketValue 
						,@Position_Calculated_BaseMarketValueDayGain 
						,@Position_Calculated_BaseMarketValue 
						,@Position_Calculated_BasePNL_DTD 
						,@Position_Calculated_BasePNL_MTD 
						,@Position_Calculated_BasePNL_YTD
						,@Position_Calculated_BaseShortMarketValueGain 
						,@Position_Calculated_BaseShortMarketValue 
						,@Position_Calculated_LocalMarketValue 
						,@Position_Calculated_MarketPrice 
				--		,@Position_Calculated_PositionCash 
				--		,@Position_Calculated_PositionValue 
				--		,@Position_PositionID 
				--		,@Position_PositionTypeString 
						--,@Security_Currency_Currency_Ccy 
						--,@Security_Currency_Currency_CurrencyID 
						--,@Security_Security_BloombergGlobalId 
						--,@Security_Security_BloombergID 
						--,@Security_Security_Code 
						,@Security_Security_MD_RealTimePrice
						--,@Security_Security_Name 
						--,@Security_Security_SecurityID 
						--,@Security_Security_Ticker 
						--,@Security_Type_SecurityType_Name 
						--,@Security_Underlying_Security_Code 
						--,@Strategy_Risk_Category_RiskCategory_RiskCategoryID 
						--,@Strategy_Risk_Category_RiskCategory_RiskName 
						--,@Strategy_TradeStrategy_ActiveBenchmarkID 
						--,@Strategy_TradeStrategy_CountryID_mkt 
						--,@Strategy_TradeStrategy_Description 
						--,@Strategy_TradeStrategy_EndDate 
						--,@Strategy_TradeStrategy_IndustryID 
						--,@Strategy_TradeStrategy_IsClosed 
						--,@Strategy_TradeStrategy_Leverage 
						--,@Strategy_TradeStrategy_Name 
						--,@Strategy_TradeStrategy_PortfolioID 
						--,@Strategy_TradeStrategy_ShortCode 
						--,@Strategy_TradeStrategy_UDF_tmwAcqsym 
						--,@Strategy_TradeStrategy_UDF_tmwAltupside 
						--,@Strategy_TradeStrategy_UDF_tmwCanbuy 
						--,@Strategy_TradeStrategy_UDF_tmwCashamt 
						--,@Strategy_TradeStrategy_UDF_tmwCashelect 
						--,@Strategy_TradeStrategy_UDF_tmwCashpct 
						--,@Strategy_TradeStrategy_UDF_tmwCategory 
						--,@Strategy_TradeStrategy_UDF_tmwCharge 
						--,@Strategy_TradeStrategy_UDF_tmwCurrency 
						--,@Strategy_TradeStrategy_UDF_tmwD1Date 
						--,@Strategy_TradeStrategy_UDF_tmwD2Date 
						--,@Strategy_TradeStrategy_UDF_tmwDealamt 
						--,@Strategy_TradeStrategy_UDF_tmwDealdisp 
						--,@Strategy_TradeStrategy_UDF_tmwDealname 
						--,@Strategy_TradeStrategy_UDF_tmwDealreport 
						--,@Strategy_TradeStrategy_UDF_tmwDealtype 
						--,@Strategy_TradeStrategy_UDF_tmwDealtypeID 
						--,@Strategy_TradeStrategy_UDF_tmwDefcanbuy 
						--,@Strategy_TradeStrategy_UDF_tmwDefinative 
						--,@Strategy_TradeStrategy_UDF_tmwDefinitive 
						--,@Strategy_TradeStrategy_UDF_tmwDesc 
						--,@Strategy_TradeStrategy_UDF_tmwDownprice 
						--,@Strategy_TradeStrategy_UDF_tmwDs10Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs10Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs1Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs1Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs2Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs2Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs3Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs3Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs4Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs4Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs5Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs5Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs6Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs6Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs7Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs7Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs8Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs8Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs9Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs9Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwExtracash 
						--,@Strategy_TradeStrategy_UDF_tmwHighcollar 
						--,@Strategy_TradeStrategy_UDF_tmwHighrange 
						--,@Strategy_TradeStrategy_UDF_tmwInitials1 
						--,@Strategy_TradeStrategy_UDF_tmwInitials2 
						--,@Strategy_TradeStrategy_UDF_tmwLowcollar 
						--,@Strategy_TradeStrategy_UDF_tmwLowrange 
						--,@Strategy_TradeStrategy_UDF_tmwNondefcanbuy 
						--,@Strategy_TradeStrategy_UDF_tmwNumadditional 
						--,@Strategy_TradeStrategy_UDF_tmwOrigacq 
						--,@Strategy_TradeStrategy_UDF_tmwOrigprice 
						--,@Strategy_TradeStrategy_UDF_tmwOther1 
						--,@Strategy_TradeStrategy_UDF_tmwOther2 
						--,@Strategy_TradeStrategy_UDF_tmwOther3 
						--,@Strategy_TradeStrategy_UDF_tmwOutflag 
						--,@Strategy_TradeStrategy_UDF_tmwOutsidehigh 
						--,@Strategy_TradeStrategy_UDF_tmwOutsidelow 
						--,@Strategy_TradeStrategy_UDF_tmwRatio 
						--,@Strategy_TradeStrategy_UDF_tmwStrategy 
						--,@Strategy_TradeStrategy_UDF_tmwUndsym 
						--,@Total_Position_Calculated_PositionCash 
						 )

				SET @return_status = 1
			END
		ELSE
			PRINT 'DBG: upsert_BroadridgePositionsMarket("' + CAST(@UniqKey AS VARCHAR) + '") No change'
	END
ELSE
	BEGIN
     -- Completely new record
					PRINT 'upsert_BroadridgePositionsMarket("' + CAST(@UniqKey AS VARCHAR) + '") - New record'

					INSERT INTO [TMDBSQL].[dbo].[BroadridgePositionsMarket]
					(	[UserName] ,
						[UniqKey] ,
						ts_start ,
						ts_end ,
						--[Custodian_TradeCpty_TradeCptyName] ,
						--[CustomBloombergID] ,
						--[CustomFundName] ,
						--[CustomFundSort] ,
						[CustomMarketPrice] ,
						--[CustomRiskCategoryCode] ,
						--[CustomStrategyCode] ,
						--[CustomTickerSort] ,
						--[CustomTicker] ,
						--[Fund_Currency_Currency_CurrencyID] ,
						--[Fund_TradeFund_Name] ,
				--		[Position_Calculated_AverageCost] ,
						[Position_Calculated_BaseLongMarketValueGain] ,
						[Position_Calculated_BaseLongMarketValue] ,
						[Position_Calculated_BaseMarketValueDayGain] ,
						[Position_Calculated_BaseMarketValue] ,
						[Position_Calculated_BasePNL_DTD] ,
						[Position_Calculated_BasePNL_MTD] ,
						[Position_Calculated_BasePNL_YTD] ,					
						[Position_Calculated_BaseShortMarketValueGain] ,
						[Position_Calculated_BaseShortMarketValue] ,
						[Position_Calculated_LocalMarketValue] ,
						[Position_Calculated_MarketPrice] ,
				--		[Position_Calculated_PositionCash] ,
				--		[Position_Calculated_PositionValue] ,
				--		[Position_PositionID] ,
				--		[Position_PositionTypeString] 
						--[Security_Currency_Currency_Ccy] ,
						--[Security_Currency_Currency_CurrencyID] ,
						--[Security_Security_BloombergGlobalId] ,
						--[Security_Security_BloombergID] ,
						--[Security_Security_Code] ,
						[Security_Security_MD_RealTimePrice]
						--[Security_Security_Name] ,
						--[Security_Security_SecurityID] ,
						--[Security_Security_Ticker] ,
						--[Security_Type_SecurityType_Name] ,
						--[Security_Underlying_Security_Code] ,
						--[Strategy_Risk_Category_RiskCategory_RiskCategoryID] ,
						--[Strategy_Risk_Category_RiskCategory_RiskName] ,
						--[Strategy_TradeStrategy_ActiveBenchmarkID] ,
						--[Strategy_TradeStrategy_CountryID_mkt] ,
						--[Strategy_TradeStrategy_Description] ,
						--[Strategy_TradeStrategy_EndDate] ,
						--[Strategy_TradeStrategy_IndustryID] ,
						--[Strategy_TradeStrategy_IsClosed] ,
						--[Strategy_TradeStrategy_Leverage] ,
						--[Strategy_TradeStrategy_Name] ,
						--[Strategy_TradeStrategy_PortfolioID] ,
						--[Strategy_TradeStrategy_ShortCode] ,
						--[Strategy_TradeStrategy_UDF_tmwAcqsym] ,
						--[Strategy_TradeStrategy_UDF_tmwAltupside] ,
						--[Strategy_TradeStrategy_UDF_tmwCanbuy] ,
						--[Strategy_TradeStrategy_UDF_tmwCashamt] ,
						--[Strategy_TradeStrategy_UDF_tmwCashelect] ,
						--[Strategy_TradeStrategy_UDF_tmwCashpct] ,
						--[Strategy_TradeStrategy_UDF_tmwCategory] ,
						--[Strategy_TradeStrategy_UDF_tmwCharge] ,
						--[Strategy_TradeStrategy_UDF_tmwCurrency] ,
						--[Strategy_TradeStrategy_UDF_tmwD1Date] ,
						--[Strategy_TradeStrategy_UDF_tmwD2Date] ,
						--[Strategy_TradeStrategy_UDF_tmwDealamt] ,
						--[Strategy_TradeStrategy_UDF_tmwDealdisp] ,
						--[Strategy_TradeStrategy_UDF_tmwDealname] ,
						--[Strategy_TradeStrategy_UDF_tmwDealreport] ,
						--[Strategy_TradeStrategy_UDF_tmwDealtype] ,
						--[Strategy_TradeStrategy_UDF_tmwDealtypeID] ,
						--[Strategy_TradeStrategy_UDF_tmwDefcanbuy] ,
						--[Strategy_TradeStrategy_UDF_tmwDefinative] ,
						--[Strategy_TradeStrategy_UDF_tmwDefinitive] ,
						--[Strategy_TradeStrategy_UDF_tmwDesc] ,
						--[Strategy_TradeStrategy_UDF_tmwDownprice] ,
						--[Strategy_TradeStrategy_UDF_tmwDs10Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs10Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs1Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs1Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs2Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs2Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs3Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs3Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs4Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs4Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs5Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs5Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs6Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs6Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs7Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs7Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs8Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs8Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwDs9Price] ,
						--[Strategy_TradeStrategy_UDF_tmwDs9Symbol] ,
						--[Strategy_TradeStrategy_UDF_tmwExtracash] ,
						--[Strategy_TradeStrategy_UDF_tmwHighcollar] ,
						--[Strategy_TradeStrategy_UDF_tmwHighrange] ,
						--[Strategy_TradeStrategy_UDF_tmwInitials1] ,
						--[Strategy_TradeStrategy_UDF_tmwInitials2] ,
						--[Strategy_TradeStrategy_UDF_tmwLowcollar] ,
						--[Strategy_TradeStrategy_UDF_tmwLowrange] ,
						--[Strategy_TradeStrategy_UDF_tmwNondefcanbuy] ,
						--[Strategy_TradeStrategy_UDF_tmwNumadditional] ,
						--[Strategy_TradeStrategy_UDF_tmwOrigacq] ,
						--[Strategy_TradeStrategy_UDF_tmwOrigprice] ,
						--[Strategy_TradeStrategy_UDF_tmwOther1] ,
						--[Strategy_TradeStrategy_UDF_tmwOther2] ,
						--[Strategy_TradeStrategy_UDF_tmwOther3] ,
						--[Strategy_TradeStrategy_UDF_tmwOutflag] ,
						--[Strategy_TradeStrategy_UDF_tmwOutsidehigh] ,
						--[Strategy_TradeStrategy_UDF_tmwOutsidelow] ,
						--[Strategy_TradeStrategy_UDF_tmwRatio] ,
						--[Strategy_TradeStrategy_UDF_tmwStrategy] ,
						--[Strategy_TradeStrategy_UDF_tmwUndsym] ,
						--[Total_Position_Calculated_PositionCash] 
						)
				VALUES
					(	
						 @UserName 
						,@UniqKey 
						,@Timestamp
						,NULL
						--,@Custodian_TradeCpty_TradeCptyName
						--,@CustomBloombergID
						--,@CustomFundName 
						--,@CustomFundSort 
						,@CustomMarketPrice 
						--,@CustomRiskCategoryCode 
						--,@CustomStrategyCode 
						--,@CustomTicker 
						--,@CustomTickerSort 
						--,@Fund_Currency_Currency_CurrencyID 
						--,@Fund_TradeFund_Name 
				--		,@Position_Calculated_AverageCost 
						,@Position_Calculated_BaseLongMarketValueGain 
						,@Position_Calculated_BaseLongMarketValue 
						,@Position_Calculated_BaseMarketValueDayGain 
						,@Position_Calculated_BaseMarketValue 
						,@Position_Calculated_BasePNL_DTD 
						,@Position_Calculated_BasePNL_MTD 
						,@Position_Calculated_BasePNL_YTD 
						,@Position_Calculated_BaseShortMarketValueGain 
						,@Position_Calculated_BaseShortMarketValue 
						,@Position_Calculated_LocalMarketValue 
						,@Position_Calculated_MarketPrice 
			--			,@Position_Calculated_PositionCash 
			--			,@Position_Calculated_PositionValue 
			--			,@Position_PositionID 
			--			,@Position_PositionTypeString 
						--,@Security_Currency_Currency_Ccy 
						--,@Security_Currency_Currency_CurrencyID 
						--,@Security_Security_BloombergGlobalId 
						--,@Security_Security_BloombergID 
						--,@Security_Security_Code
						,@Security_Security_MD_RealTimePrice
						--,@Security_Security_Name 
						--,@Security_Security_SecurityID 
						--,@Security_Security_Ticker 
						--,@Security_Type_SecurityType_Name 
						--,@Security_Underlying_Security_Code 
						--,@Strategy_Risk_Category_RiskCategory_RiskCategoryID 
						--,@Strategy_Risk_Category_RiskCategory_RiskName 
						--,@Strategy_TradeStrategy_ActiveBenchmarkID 
						--,@Strategy_TradeStrategy_CountryID_mkt 
						--,@Strategy_TradeStrategy_Description 
						--,@Strategy_TradeStrategy_EndDate 
						--,@Strategy_TradeStrategy_IndustryID 
						--,@Strategy_TradeStrategy_IsClosed 
						--,@Strategy_TradeStrategy_Leverage 
						--,@Strategy_TradeStrategy_Name 
						--,@Strategy_TradeStrategy_PortfolioID 
						--,@Strategy_TradeStrategy_ShortCode 
						--,@Strategy_TradeStrategy_UDF_tmwAcqsym 
						--,@Strategy_TradeStrategy_UDF_tmwAltupside 
						--,@Strategy_TradeStrategy_UDF_tmwCanbuy 
						--,@Strategy_TradeStrategy_UDF_tmwCashamt 
						--,@Strategy_TradeStrategy_UDF_tmwCashelect 
						--,@Strategy_TradeStrategy_UDF_tmwCashpct 
						--,@Strategy_TradeStrategy_UDF_tmwCategory 
						--,@Strategy_TradeStrategy_UDF_tmwCharge 
						--,@Strategy_TradeStrategy_UDF_tmwCurrency 
						--,@Strategy_TradeStrategy_UDF_tmwD1Date 
						--,@Strategy_TradeStrategy_UDF_tmwD2Date 
						--,@Strategy_TradeStrategy_UDF_tmwDealamt 
						--,@Strategy_TradeStrategy_UDF_tmwDealdisp 
						--,@Strategy_TradeStrategy_UDF_tmwDealname 
						--,@Strategy_TradeStrategy_UDF_tmwDealreport 
						--,@Strategy_TradeStrategy_UDF_tmwDealtype 
						--,@Strategy_TradeStrategy_UDF_tmwDealtypeID 
						--,@Strategy_TradeStrategy_UDF_tmwDefcanbuy 
						--,@Strategy_TradeStrategy_UDF_tmwDefinative 
						--,@Strategy_TradeStrategy_UDF_tmwDefinitive 
						--,@Strategy_TradeStrategy_UDF_tmwDesc 
						--,@Strategy_TradeStrategy_UDF_tmwDownprice 
						--,@Strategy_TradeStrategy_UDF_tmwDs10Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs10Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs1Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs1Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs2Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs2Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs3Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs3Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs4Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs4Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs5Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs5Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs6Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs6Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs7Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs7Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs8Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs8Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwDs9Price 
						--,@Strategy_TradeStrategy_UDF_tmwDs9Symbol 
						--,@Strategy_TradeStrategy_UDF_tmwExtracash 
						--,@Strategy_TradeStrategy_UDF_tmwHighcollar 
						--,@Strategy_TradeStrategy_UDF_tmwHighrange 
						--,@Strategy_TradeStrategy_UDF_tmwInitials1 
						--,@Strategy_TradeStrategy_UDF_tmwInitials2 
						--,@Strategy_TradeStrategy_UDF_tmwLowcollar 
						--,@Strategy_TradeStrategy_UDF_tmwLowrange 
						--,@Strategy_TradeStrategy_UDF_tmwNondefcanbuy 
						--,@Strategy_TradeStrategy_UDF_tmwNumadditional 
						--,@Strategy_TradeStrategy_UDF_tmwOrigacq 
						--,@Strategy_TradeStrategy_UDF_tmwOrigprice 
						--,@Strategy_TradeStrategy_UDF_tmwOther1 
						--,@Strategy_TradeStrategy_UDF_tmwOther2 
						--,@Strategy_TradeStrategy_UDF_tmwOther3 
						--,@Strategy_TradeStrategy_UDF_tmwOutflag 
						--,@Strategy_TradeStrategy_UDF_tmwOutsidehigh 
						--,@Strategy_TradeStrategy_UDF_tmwOutsidelow 
						--,@Strategy_TradeStrategy_UDF_tmwRatio 
						--,@Strategy_TradeStrategy_UDF_tmwStrategy 
						--,@Strategy_TradeStrategy_UDF_tmwUndsym 
						--,@Total_Position_Calculated_PositionCash 
						)
		SET @return_status = 1
	END

COMMIT TRANSACTION

PRINT 'upsert_BroadridgePositionsMarket("' + CAST(@UniqKey AS VARCHAR) + '") -------- END ---------------'

-- PRINT @bbsecurity
-- PRINT @return_status
-- RETURN @return_status

END
GO
