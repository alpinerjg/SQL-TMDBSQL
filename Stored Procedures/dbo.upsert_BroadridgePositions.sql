SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE   PROCEDURE [dbo].[upsert_BroadridgePositions] 
    @UserName VARCHAR(32),
	@return_status INT = 0 OUTPUT 

AS
BEGIN

-- DECLARE @return_status int;

	DECLARE @CursorCount INT = 1
	DECLARE @RowCnt INT = 0

	DECLARE @Timestamp datetime	
	-- DECLARE @UserName varchar(32)
	DECLARE @UniqKey varchar(100)
		
	DECLARE @Custodian_TradeCpty_TradeCptyName varchar(100) = NULL
	DECLARE @CustomAccount varchar(10) = NULL
	DECLARE @CustomBloombergID varchar(100) = NULL
	DECLARE @CustomFundName varchar(100) = NULL
	DECLARE @CustomFundSort varchar(100) = NULL
	DECLARE @CustomPartnershipID varchar(1) = NULL
	-- DECLARE @CustomMarketPrice decimal(30,15) = NULL
	DECLARE @CustomRiskCategoryCode varchar(100) = NULL
	DECLARE @CustomStrategyCode varchar(100) = NULL
	DECLARE @CustomTicker varchar(100) = NULL
	DECLARE @CustomTickerSort varchar(100) = NULL
	DECLARE @Fund_Currency_Currency_CurrencyID int = NULL
	DECLARE @Fund_TradeFund_Name varchar(100) = NULL
	DECLARE @Position_Calculated_AverageCost decimal(30,15) = NULL
	DECLARE @Position_Calculated_BaseLongMarketValue decimal(30,15) = NULL
	DECLARE @Position_Calculated_BaseLongMarketValueGain decimal(30,15) = NULL
	DECLARE @Position_Calculated_BaseMarketValueDayGain decimal(30,15) = NULL
	DECLARE @Position_Calculated_BaseMarketValue decimal(30,15) = NULL
	DECLARE @Position_Calculated_BasePNL_DTD decimal(30,15) = NULL
	DECLARE @Position_Calculated_BasePNL_MTD decimal(30,15) = NULL
	DECLARE @Position_Calculated_BasePNL_YTD decimal(30,15) = NULL
	DECLARE @Position_Calculated_BaseShortMarketValue decimal(30,15) = NULL
	DECLARE @Position_Calculated_BaseShortMarketValueGain decimal(30,15) = NULL
	DECLARE @Position_Calculated_LocalMarketValue decimal(30,15) = NULL
	DECLARE @Position_Calculated_MarketPrice decimal(30,15) = NULL
	DECLARE @Position_Calculated_PositionCash decimal(30,15) = NULL
	DECLARE @Position_Calculated_PositionValue decimal(18,0) = NULL
	DECLARE @Position_PositionID int = NULL
	DECLARE @Position_PositionTypeString varchar(100) = NULL
	DECLARE @Security_Currency_Currency_Ccy varchar(100) = NULL
	DECLARE @Security_Currency_Currency_CurrencyID int = NULL
	DECLARE @Security_Security_BloombergGlobalId varchar(100) = NULL
	DECLARE @Security_Security_BloombergID varchar(100) = NULL
	DECLARE @Security_Security_Code varchar(100) = NULL
	DECLARE @Security_Security_ConversionRatio decimal(30, 5) = NULL
	DECLARE @Security_Security_MD_RealTimePrice decimal(30, 8) = NULL
	DECLARE @Security_Security_Name varchar(100) = NULL
	DECLARE @Security_Security_SecurityID int = NULL
	DECLARE @Security_Security_Ticker varchar(100) = NULL
	DECLARE @Security_Type_SecurityType_Name varchar(100) = NULL
	DECLARE @Security_Underlying_Security_Code varchar(100) = NULL
	DECLARE @Strategy_Risk_Category_RiskCategory_RiskCategoryID int = NULL
	DECLARE @Strategy_Risk_Category_RiskCategory_RiskName varchar(100) = NULL
	DECLARE @Strategy_TradeStrategy_ActiveBenchmarkID int = NULL
	DECLARE @Strategy_TradeStrategy_CountryID_mkt int = NULL
	DECLARE @Strategy_TradeStrategy_Description varchar(100) = NULL
	DECLARE @Strategy_TradeStrategy_EndDate date = NULL
	DECLARE @Strategy_TradeStrategy_IndustryID int = NULL
	DECLARE @Strategy_TradeStrategy_IsClosed bit = NULL
	DECLARE @Strategy_TradeStrategy_Leverage decimal(30,15) = NULL
	DECLARE @Strategy_TradeStrategy_Name varchar(100) = NULL
	DECLARE @Strategy_TradeStrategy_PortfolioID int = NULL
	DECLARE @Strategy_TradeStrategy_ShortCode varchar(100) = NULL
	DECLARE @Total_Position_Calculated_PositionCash decimal(30,15) = NULL

	DECLARE BroadridgePositions_staging_Cursor CURSOR FOR 
		SELECT 				
						UserName ,
						UniqKey ,
						Custodian_TradeCpty_TradeCptyName ,
						CustomAccount ,
						CustomBloombergID ,
						CustomFundName ,
						CustomFundSort ,
						CustomPartnershipID ,
						-- CustomMarketPrice ,
						CustomRiskCategoryCode ,
						CustomStrategyCode ,
						CustomTicker ,
						CustomTickerSort ,
						Fund_Currency_Currency_CurrencyID ,
						Fund_TradeFund_Name ,
						Position_Calculated_AverageCost ,
						Position_Calculated_BaseLongMarketValue ,
						Position_Calculated_BaseLongMarketValueGain ,
						Position_Calculated_BaseMarketValueDayGain ,
						Position_Calculated_BaseMarketValue ,
						Position_Calculated_BasePNL_DTD ,
						Position_Calculated_BasePNL_MTD ,
						Position_Calculated_BasePNL_YTD ,					
						Position_Calculated_BaseShortMarketValue ,
						Position_Calculated_BaseShortMarketValueGain ,
						Position_Calculated_LocalMarketValue ,
						Position_Calculated_MarketPrice ,
						Position_Calculated_PositionCash ,
						Position_Calculated_PositionValue ,
						Position_PositionID ,
						Position_PositionTypeString ,
						Security_Currency_Currency_Ccy ,
						Security_Currency_Currency_CurrencyID ,
						Security_Security_BloombergGlobalId ,
						Security_Security_BloombergID ,
						Security_Security_Code ,
						Security_Security_ConversionRatio ,
						Security_Security_MD_RealTimePrice ,
						Security_Security_Name ,
						Security_Security_SecurityID ,
						Security_Security_Ticker ,
						Security_Type_SecurityType_Name ,
						Security_Underlying_Security_Code ,
						Strategy_Risk_Category_RiskCategory_RiskCategoryID ,
						Strategy_Risk_Category_RiskCategory_RiskName ,
						Strategy_TradeStrategy_ActiveBenchmarkID ,
						Strategy_TradeStrategy_CountryID_mkt ,
						Strategy_TradeStrategy_Description ,
						Strategy_TradeStrategy_EndDate ,
						Strategy_TradeStrategy_IndustryID ,
						Strategy_TradeStrategy_IsClosed ,
						Strategy_TradeStrategy_Leverage ,
						Strategy_TradeStrategy_Name ,
						Strategy_TradeStrategy_PortfolioID ,
						Strategy_TradeStrategy_ShortCode ,
						Total_Position_Calculated_PositionCash 
						FROM BroadridgePositions_staging
						WHERE UserName = @UserName


	-- BEGIN TRANSACTION

	-- ETL
	UPDATE [TMDBSQL].[dbo].[BroadridgePositions_staging]
	SET CustomStrategyCode = CONCAT(' ' , CustomStrategyCode)
	WHERE CustomStrategyCode like '[0-9][0-9][0-9]'

	SET @Timestamp = GetDate()

	OPEN BroadridgePositions_staging_Cursor 

	SELECT @RowCnt = COUNT(0) FROM dbo.BroadridgePositions_staging

	BEGIN
			-- https://stackoverflow.com/questions/52971604/update-only-rows-that-does-not-match-rows-from-another-table
			--
			-- Any records that no longer are in staging should get closed out
			--

			UPDATE t1 
			SET t1.ts_end = @Timestamp
			FROM [TMDBSQL].[dbo].[BroadridgePositions] t1
			LEFT JOIN [TMDBSQL].[dbo].[BroadridgePositions_staging] t2 ON t2.UserName = t1.UserName AND t2.[UniqKey] = t1.[UniqKey] 
			WHERE t1.ts_end IS NULL and t2.[UniqKey] IS NULL

			UPDATE t1 
			SET t1.ts_end = @Timestamp
			FROM [TMDBSQL].[dbo].[BroadridgePositionsCustom] t1
			LEFT JOIN [TMDBSQL].[dbo].[BroadridgePositions_staging] t2 ON t2.UserName = t1.UserName AND t2.[UniqKey] = t1.[UniqKey] 
			WHERE t1.ts_end IS NULL and t2.[UniqKey] IS NULL

			UPDATE t1 
			SET t1.ts_end = @Timestamp
			FROM [TMDBSQL].[dbo].[BroadridgePositionsPosition] t1
			LEFT JOIN [TMDBSQL].[dbo].[BroadridgePositions_staging] t2 ON t2.UserName = t1.UserName AND t2.[UniqKey] = t1.[UniqKey] 
			WHERE t1.ts_end IS NULL and t2.[UniqKey] IS NULL

			UPDATE t1 
			SET t1.ts_end = @Timestamp
			FROM [TMDBSQL].[dbo].[BroadridgePositionsMarket] t1
			LEFT JOIN [TMDBSQL].[dbo].[BroadridgePositions_staging] t2 ON t2.UserName = t1.UserName AND t2.[UniqKey] = t1.[UniqKey] 
			WHERE t1.ts_end IS NULL and t2.[UniqKey] IS NULL

			UPDATE t1 
			SET t1.ts_end = @Timestamp
			FROM [TMDBSQL].[dbo].[BroadridgePositionsSecurity] t1
			LEFT JOIN [TMDBSQL].[dbo].[BroadridgePositions_staging] t2 ON t2.UserName = t1.UserName AND t2.[UniqKey] = t1.[UniqKey] 
			WHERE t1.ts_end IS NULL and t2.[UniqKey] IS NULL

			UPDATE t1 
			SET t1.ts_end = @Timestamp
			FROM [TMDBSQL].[dbo].[BroadridgePositionsStrategy] t1
			LEFT JOIN [TMDBSQL].[dbo].[BroadridgePositions_staging] t2 ON t2.UserName = t1.UserName AND t2.[UniqKey] = t1.[UniqKey] 
			WHERE t1.ts_end IS NULL and t2.[UniqKey] IS NULL

			UPDATE t1 
			SET t1.ts_end = @Timestamp
			FROM [TMDBSQL].[dbo].[BroadridgePositionsOther] t1
			LEFT JOIN [TMDBSQL].[dbo].[BroadridgePositions_staging] t2 ON t2.UserName = t1.UserName AND t2.[UniqKey] = t1.[UniqKey] 
			WHERE t1.ts_end IS NULL and t2.[UniqKey] IS NULL

			FETCH NEXT FROM BroadridgePositions_staging_Cursor INTO
			 @UserName ,
			 @UniqKey ,
			 @Custodian_TradeCpty_TradeCptyName ,
			 @CustomAccount ,
			 @CustomBloombergID ,
			 @CustomFundName ,
			 @CustomFundSort ,
			 @CustomPartnershipID ,
			 -- @CustomMarketPrice ,
			 @CustomRiskCategoryCode ,
			 @CustomStrategyCode ,
			 @CustomTicker ,
			 @CustomTickerSort ,
			 @Fund_Currency_Currency_CurrencyID ,
			 @Fund_TradeFund_Name ,
			 @Position_Calculated_AverageCost ,
			 @Position_Calculated_BaseLongMarketValue ,
			 @Position_Calculated_BaseLongMarketValueGain ,
			 @Position_Calculated_BaseMarketValueDayGain ,
			 @Position_Calculated_BaseMarketValue ,
			 @Position_Calculated_BasePNL_DTD ,
			 @Position_Calculated_BasePNL_MTD ,
			 @Position_Calculated_BasePNL_YTD ,
			 @Position_Calculated_BaseShortMarketValue ,
			 @Position_Calculated_BaseShortMarketValueGain ,
			 @Position_Calculated_LocalMarketValue ,
			 @Position_Calculated_MarketPrice ,
			 @Position_Calculated_PositionCash ,
			 @Position_Calculated_PositionValue ,
			 @Position_PositionID ,
			 @Position_PositionTypeString ,
			 @Security_Currency_Currency_Ccy ,
			 @Security_Currency_Currency_CurrencyID ,
			 @Security_Security_BloombergGlobalId ,
			 @Security_Security_BloombergID ,
			 @Security_Security_Code ,
			 @Security_Security_ConversionRatio ,
			 @Security_Security_MD_RealTimePrice ,
			 @Security_Security_Name ,
			 @Security_Security_SecurityID ,
			 @Security_Security_Ticker ,
			 @Security_Type_SecurityType_Name ,
			 @Security_Underlying_Security_Code ,
			 @Strategy_Risk_Category_RiskCategory_RiskCategoryID ,
			 @Strategy_Risk_Category_RiskCategory_RiskName ,
			 @Strategy_TradeStrategy_ActiveBenchmarkID ,
			 @Strategy_TradeStrategy_CountryID_mkt ,
			 @Strategy_TradeStrategy_Description ,
			 @Strategy_TradeStrategy_EndDate ,
			 @Strategy_TradeStrategy_IndustryID ,
			 @Strategy_TradeStrategy_IsClosed ,
			 @Strategy_TradeStrategy_Leverage ,
			 @Strategy_TradeStrategy_Name ,
			 @Strategy_TradeStrategy_PortfolioID ,
			 @Strategy_TradeStrategy_ShortCode ,
			 @Total_Position_Calculated_PositionCash 

			WHILE @@FETCH_STATUS = 0  		

			BEGIN
				-- PRINT 'upsert_BroadridgePositions("' + CAST(@UniqKey AS VARCHAR) + '")'
				IF @UniqKey = '7|TSHT|TSHT|SPY|5C'
					BEGIN
				  PRINT '@Position_Calculated_BaseMarketValueDayGain = ' + CAST(@Position_Calculated_BaseMarketValueDayGain AS VARCHAR)
				  PRINT '@Position_Calculated_BaseMarketValue = ' + CAST(@Position_Calculated_BaseMarketValue AS VARCHAR)
				  END

				EXEC upsert_BroadridgePositions_staging 
						 @Timestamp = @Timestamp ,
						 @UserName = @UserName ,
						 @UniqKey = @UniqKey ,
						 @Custodian_TradeCpty_TradeCptyName = @Custodian_TradeCpty_TradeCptyName ,
						 @CustomAccount = @CustomAccount ,
						 @CustomBloombergID = @CustomBloombergID ,
						 @CustomFundName = @CustomFundName ,
						 @CustomFundSort = @CustomFundSort ,
						 @CustomPartnershipID = @CustomPartnershipID ,
						 -- @CustomMarketPrice = @CustomMarketPrice ,
						 @CustomRiskCategoryCode = @CustomRiskCategoryCode ,
						 @CustomStrategyCode = @CustomStrategyCode ,
						 @CustomTicker = @CustomTicker ,
						 @CustomTickerSort = @CustomTickerSort ,
						 @Fund_Currency_Currency_CurrencyID = @Fund_Currency_Currency_CurrencyID ,
						 @Fund_TradeFund_Name = @Fund_TradeFund_Name ,
						 @Position_Calculated_AverageCost = @Position_Calculated_AverageCost ,
						 @Position_Calculated_BaseLongMarketValue = @Position_Calculated_BaseLongMarketValue ,
						 @Position_Calculated_BaseLongMarketValueGain = @Position_Calculated_BaseLongMarketValueGain ,
						 @Position_Calculated_BaseMarketValueDayGain = @Position_Calculated_BaseMarketValueDayGain ,
						 @Position_Calculated_BaseMarketValue = @Position_Calculated_BaseMarketValue ,
						 @Position_Calculated_BasePNL_DTD = @Position_Calculated_BasePNL_DTD ,
						 @Position_Calculated_BasePNL_MTD = @Position_Calculated_BasePNL_MTD ,
						 @Position_Calculated_BasePNL_YTD = @Position_Calculated_BasePNL_YTD ,
						 @Position_Calculated_BaseShortMarketValue = @Position_Calculated_BaseShortMarketValue ,
						 @Position_Calculated_BaseShortMarketValueGain = @Position_Calculated_BaseShortMarketValueGain ,
						 @Position_Calculated_LocalMarketValue = @Position_Calculated_LocalMarketValue ,
						 @Position_Calculated_MarketPrice = @Position_Calculated_MarketPrice ,
						 @Position_Calculated_PositionCash = @Position_Calculated_PositionCash ,
						 @Position_Calculated_PositionValue = @Position_Calculated_PositionValue ,
						 @Position_PositionID = @Position_PositionID ,
						 @Position_PositionTypeString = @Position_PositionTypeString ,
						 @Security_Currency_Currency_Ccy = @Security_Currency_Currency_Ccy ,
						 @Security_Currency_Currency_CurrencyID = @Security_Currency_Currency_CurrencyID ,
						 @Security_Security_BloombergGlobalId = @Security_Security_BloombergGlobalId ,
						 @Security_Security_BloombergID = @Security_Security_BloombergID ,
						 @Security_Security_Code = @Security_Security_Code ,
						 @Security_Security_ConversionRatio = @Security_Security_ConversionRatio ,
						 @Security_Security_MD_RealTimePrice = @Security_Security_MD_RealTimePrice ,
						 @Security_Security_Name = @Security_Security_Name ,
						 @Security_Security_SecurityID = @Security_Security_SecurityID ,
						 @Security_Security_Ticker = @Security_Security_Ticker ,
						 @Security_Type_SecurityType_Name = @Security_Type_SecurityType_Name ,
						 @Security_Underlying_Security_Code = @Security_Underlying_Security_Code ,
						 @Strategy_Risk_Category_RiskCategory_RiskCategoryID = @Strategy_Risk_Category_RiskCategory_RiskCategoryID ,
						 @Strategy_Risk_Category_RiskCategory_RiskName = @Strategy_Risk_Category_RiskCategory_RiskName ,
						 @Strategy_TradeStrategy_ActiveBenchmarkID = @Strategy_TradeStrategy_ActiveBenchmarkID ,
						 @Strategy_TradeStrategy_CountryID_mkt = @Strategy_TradeStrategy_CountryID_mkt ,
						 @Strategy_TradeStrategy_Description = @Strategy_TradeStrategy_Description ,
						 @Strategy_TradeStrategy_EndDate = @Strategy_TradeStrategy_EndDate ,
						 @Strategy_TradeStrategy_IndustryID = @Strategy_TradeStrategy_IndustryID ,
						 @Strategy_TradeStrategy_IsClosed = @Strategy_TradeStrategy_IsClosed ,
						 @Strategy_TradeStrategy_Leverage = @Strategy_TradeStrategy_Leverage ,
						 @Strategy_TradeStrategy_Name = @Strategy_TradeStrategy_Name ,
						 @Strategy_TradeStrategy_PortfolioID = @Strategy_TradeStrategy_PortfolioID ,
						 @Strategy_TradeStrategy_ShortCode = @Strategy_TradeStrategy_ShortCode ,
						 @Total_Position_Calculated_PositionCash = @Total_Position_Calculated_PositionCash

				EXEC upsert_BroadridgePositionsCustom 
						 @Timestamp = @Timestamp ,
						 @UserName = @UserName ,
						 @UniqKey = @UniqKey ,
--						 @Custodian_TradeCpty_TradeCptyName = @Custodian_TradeCpty_TradeCptyName ,
						 @CustomAccount = @CustomAccount ,
						 @CustomBloombergID = @CustomBloombergID ,
						 @CustomFundName = @CustomFundName ,
						 @CustomFundSort = @CustomFundSort ,
						 @CustomPartnershipID = @CustomPartnershipID ,
--						 @CustomMarketPrice = @CustomMarketPrice ,
						 @CustomRiskCategoryCode = @CustomRiskCategoryCode ,
						 @CustomStrategyCode = @CustomStrategyCode ,
						 @CustomTicker = @CustomTicker ,
						 @CustomTickerSort = @CustomTickerSort 
						 --@Fund_Currency_Currency_CurrencyID = @Fund_Currency_Currency_CurrencyID ,
						 --@Fund_TradeFund_Name = @Fund_TradeFund_Name ,
						 --@Position_Calculated_AverageCost = @Position_Calculated_AverageCost ,
						 --@Position_Calculated_BaseLongMarketValue = @Position_Calculated_BaseLongMarketValue ,
						 --@Position_Calculated_BaseLongMarketValueGain = @Position_Calculated_BaseLongMarketValueGain ,
						 --@Position_Calculated_BaseMarketValueDayGain = @Position_Calculated_BaseMarketValueDayGain ,
						 --@Position_Calculated_BaseMarketValue = @Position_Calculated_BaseMarketValue ,
						 --@Position_Calculated_BasePNL_DTD = @Position_Calculated_BasePNL_DTD ,
						 --@Position_Calculated_BasePNL_MTD = @Position_Calculated_BasePNL_MTD ,
						 --@Position_Calculated_BasePNL_YTD = @Position_Calculated_BasePNL_YTD ,
						 --@Position_Calculated_BaseShortMarketValue = @Position_Calculated_BaseShortMarketValue ,
						 --@Position_Calculated_BaseShortMarketValueGain = @Position_Calculated_BaseShortMarketValueGain ,
						 --@Position_Calculated_LocalMarketValue = @Position_Calculated_LocalMarketValue ,
						 --@Position_Calculated_MarketPrice = @Position_Calculated_MarketPrice ,
						 --@Position_Calculated_PositionCash = @Position_Calculated_PositionCash ,
						 --@Position_Calculated_PositionValue = @Position_Calculated_PositionValue ,
						 --@Position_PositionID = @Position_PositionID ,
						 --@Position_PositionTypeString = @Position_PositionTypeString ,
						 --@Security_Currency_Currency_Ccy = @Security_Currency_Currency_Ccy ,
						 --@Security_Currency_Currency_CurrencyID = @Security_Currency_Currency_CurrencyID ,
						 --@Security_Security_BloombergGlobalId = @Security_Security_BloombergGlobalId ,
						 --@Security_Security_BloombergID = @Security_Security_BloombergID ,
						 --@Security_Security_Code = @Security_Security_Code ,
						 --@Security_Security_Name = @Security_Security_Name ,
						 --@Security_Security_SecurityID = @Security_Security_SecurityID ,
						 --@Security_Security_Ticker = @Security_Security_Ticker ,
						 --@Security_Type_SecurityType_Name = @Security_Type_SecurityType_Name ,
						 --@Security_Underlying_Security_Code = @Security_Underlying_Security_Code ,
						 --@Strategy_Risk_Category_RiskCategory_RiskCategoryID = @Strategy_Risk_Category_RiskCategory_RiskCategoryID ,
						 --@Strategy_Risk_Category_RiskCategory_RiskName = @Strategy_Risk_Category_RiskCategory_RiskName ,
						 --@Strategy_TradeStrategy_ActiveBenchmarkID = @Strategy_TradeStrategy_ActiveBenchmarkID ,
						 --@Strategy_TradeStrategy_CountryID_mkt = @Strategy_TradeStrategy_CountryID_mkt ,
						 --@Strategy_TradeStrategy_Description = @Strategy_TradeStrategy_Description ,
						 --@Strategy_TradeStrategy_EndDate = @Strategy_TradeStrategy_EndDate ,
						 --@Strategy_TradeStrategy_IndustryID = @Strategy_TradeStrategy_IndustryID ,
						 --@Strategy_TradeStrategy_IsClosed = @Strategy_TradeStrategy_IsClosed ,
						 --@Strategy_TradeStrategy_Leverage = @Strategy_TradeStrategy_Leverage ,
						 --@Strategy_TradeStrategy_Name = @Strategy_TradeStrategy_Name ,
						 --@Strategy_TradeStrategy_PortfolioID = @Strategy_TradeStrategy_PortfolioID ,
						 --@Strategy_TradeStrategy_ShortCode = @Strategy_TradeStrategy_ShortCode ,
						 --@Total_Position_Calculated_PositionCash = @Total_Position_Calculated_PositionCash

				EXEC upsert_BroadridgePositionsPosition 
						 @Timestamp = @Timestamp ,
						 @UserName = @UserName ,
						 @UniqKey = @UniqKey ,
						 --@Custodian_TradeCpty_TradeCptyName = @Custodian_TradeCpty_TradeCptyName ,
						 --@CustomBloombergID = @CustomBloombergID ,
						 --@CustomFundName = @CustomFundName ,
						 --@CustomFundSort = @CustomFundSort ,
						 --@CustomMarketPrice = @CustomMarketPrice ,
						 --@CustomRiskCategoryCode = @CustomRiskCategoryCode ,
						 --@CustomStrategyCode = @CustomStrategyCode ,
						 --@CustomTicker = @CustomTicker ,
						 --@CustomTickerSort = @CustomTickerSort 
						 --@Fund_Currency_Currency_CurrencyID = @Fund_Currency_Currency_CurrencyID ,
						 --@Fund_TradeFund_Name = @Fund_TradeFund_Name ,
						 @Position_Calculated_AverageCost = @Position_Calculated_AverageCost ,
						 --@Position_Calculated_BaseLongMarketValue = @Position_Calculated_BaseLongMarketValue ,
						 --@Position_Calculated_BaseLongMarketValueGain = @Position_Calculated_BaseLongMarketValueGain ,
						 --@Position_Calculated_BaseMarketValueDayGain = @Position_Calculated_BaseMarketValueDayGain ,
						 --@Position_Calculated_BaseMarketValue = @Position_Calculated_BaseMarketValue ,
						 --@Position_Calculated_BasePNL_DTD = @Position_Calculated_BasePNL_DTD ,
						 --@Position_Calculated_BasePNL_MTD = @Position_Calculated_BasePNL_MTD ,
						 --@Position_Calculated_BasePNL_YTD = @Position_Calculated_BasePNL_YTD ,
						 --@Position_Calculated_BaseShortMarketValue = @Position_Calculated_BaseShortMarketValue ,
						 --@Position_Calculated_BaseShortMarketValueGain = @Position_Calculated_BaseShortMarketValueGain ,
						 --@Position_Calculated_LocalMarketValue = @Position_Calculated_LocalMarketValue ,
						 --@Position_Calculated_MarketPrice = @Position_Calculated_MarketPrice ,
						 @Position_Calculated_PositionCash = @Position_Calculated_PositionCash ,
						 @Position_Calculated_PositionValue = @Position_Calculated_PositionValue ,
						 @Position_PositionID = @Position_PositionID ,
						 @Position_PositionTypeString = @Position_PositionTypeString 
						 --@Security_Currency_Currency_Ccy = @Security_Currency_Currency_Ccy ,
						 --@Security_Currency_Currency_CurrencyID = @Security_Currency_Currency_CurrencyID ,
						 --@Security_Security_BloombergGlobalId = @Security_Security_BloombergGlobalId ,
						 --@Security_Security_BloombergID = @Security_Security_BloombergID ,
						 --@Security_Security_Code = @Security_Security_Code ,
						 --@Security_Security_Name = @Security_Security_Name ,
						 --@Security_Security_SecurityID = @Security_Security_SecurityID ,
						 --@Security_Security_Ticker = @Security_Security_Ticker ,
						 --@Security_Type_SecurityType_Name = @Security_Type_SecurityType_Name ,
						 --@Security_Underlying_Security_Code = @Security_Underlying_Security_Code ,
						 --@Strategy_Risk_Category_RiskCategory_RiskCategoryID = @Strategy_Risk_Category_RiskCategory_RiskCategoryID ,
						 --@Strategy_Risk_Category_RiskCategory_RiskName = @Strategy_Risk_Category_RiskCategory_RiskName ,
						 --@Strategy_TradeStrategy_ActiveBenchmarkID = @Strategy_TradeStrategy_ActiveBenchmarkID ,
						 --@Strategy_TradeStrategy_CountryID_mkt = @Strategy_TradeStrategy_CountryID_mkt ,
						 --@Strategy_TradeStrategy_Description = @Strategy_TradeStrategy_Description ,
						 --@Strategy_TradeStrategy_EndDate = @Strategy_TradeStrategy_EndDate ,
						 --@Strategy_TradeStrategy_IndustryID = @Strategy_TradeStrategy_IndustryID ,
						 --@Strategy_TradeStrategy_IsClosed = @Strategy_TradeStrategy_IsClosed ,
						 --@Strategy_TradeStrategy_Leverage = @Strategy_TradeStrategy_Leverage ,
						 --@Strategy_TradeStrategy_Name = @Strategy_TradeStrategy_Name ,
						 --@Strategy_TradeStrategy_PortfolioID = @Strategy_TradeStrategy_PortfolioID ,
						 --@Strategy_TradeStrategy_ShortCode = @Strategy_TradeStrategy_ShortCode ,
						 --@Total_Position_Calculated_PositionCash = @Total_Position_Calculated_PositionCash


				EXEC upsert_BroadridgePositionsMarket 
						 @Timestamp = @Timestamp ,
						 @UserName = @UserName ,
						 @UniqKey = @UniqKey ,
						 --@Custodian_TradeCpty_TradeCptyName = @Custodian_TradeCpty_TradeCptyName ,
						 --@CustomBloombergID = @CustomBloombergID ,
						 --@CustomFundName = @CustomFundName ,
						 --@CustomFundSort = @CustomFundSort ,
						 --@CustomMarketPrice = @CustomMarketPrice ,
						 --@CustomRiskCategoryCode = @CustomRiskCategoryCode ,
						 --@CustomStrategyCode = @CustomStrategyCode ,
						 --@CustomTicker = @CustomTicker ,
						 --@CustomTickerSort = @CustomTickerSort 
						 --@Fund_Currency_Currency_CurrencyID = @Fund_Currency_Currency_CurrencyID ,
						 --@Fund_TradeFund_Name = @Fund_TradeFund_Name ,
						 --@Position_Calculated_AverageCost = @Position_Calculated_AverageCost ,
						 @Position_Calculated_BaseLongMarketValue = @Position_Calculated_BaseLongMarketValue ,
						 @Position_Calculated_BaseLongMarketValueGain = @Position_Calculated_BaseLongMarketValueGain ,
						 @Position_Calculated_BaseMarketValueDayGain = @Position_Calculated_BaseMarketValueDayGain ,
						 @Position_Calculated_BaseMarketValue = @Position_Calculated_BaseMarketValue ,
						 @Position_Calculated_BasePNL_DTD = @Position_Calculated_BasePNL_DTD ,
						 @Position_Calculated_BasePNL_MTD = @Position_Calculated_BasePNL_MTD ,
						 @Position_Calculated_BasePNL_YTD = @Position_Calculated_BasePNL_YTD ,
						 @Position_Calculated_BaseShortMarketValue = @Position_Calculated_BaseShortMarketValue ,
						 @Position_Calculated_BaseShortMarketValueGain = @Position_Calculated_BaseShortMarketValueGain ,
						 @Position_Calculated_LocalMarketValue = @Position_Calculated_LocalMarketValue ,
						 @Position_Calculated_MarketPrice = @Position_Calculated_MarketPrice ,
						 --@Position_Calculated_PositionCash = @Position_Calculated_PositionCash ,
						 --@Position_Calculated_PositionValue = @Position_Calculated_PositionValue ,
						 --@Position_PositionID = @Position_PositionID ,
						 --@Position_PositionTypeString = @Position_PositionTypeString 
						 --@Security_Currency_Currency_Ccy = @Security_Currency_Currency_Ccy ,
						 --@Security_Currency_Currency_CurrencyID = @Security_Currency_Currency_CurrencyID ,
						 --@Security_Security_BloombergGlobalId = @Security_Security_BloombergGlobalId ,
						 --@Security_Security_BloombergID = @Security_Security_BloombergID ,
						 --@Security_Security_Code = @Security_Security_Code ,
						  @Security_Security_MD_RealTimePrice = @Security_Security_MD_RealTimePrice 
						 --@Security_Security_Name = @Security_Security_Name ,
						 --@Security_Security_SecurityID = @Security_Security_SecurityID ,
						 --@Security_Security_Ticker = @Security_Security_Ticker ,
						 --@Security_Type_SecurityType_Name = @Security_Type_SecurityType_Name ,
						 --@Security_Underlying_Security_Code = @Security_Underlying_Security_Code ,
						 --@Strategy_Risk_Category_RiskCategory_RiskCategoryID = @Strategy_Risk_Category_RiskCategory_RiskCategoryID ,
						 --@Strategy_Risk_Category_RiskCategory_RiskName = @Strategy_Risk_Category_RiskCategory_RiskName ,
						 --@Strategy_TradeStrategy_ActiveBenchmarkID = @Strategy_TradeStrategy_ActiveBenchmarkID ,
						 --@Strategy_TradeStrategy_CountryID_mkt = @Strategy_TradeStrategy_CountryID_mkt ,
						 --@Strategy_TradeStrategy_Description = @Strategy_TradeStrategy_Description ,
						 --@Strategy_TradeStrategy_EndDate = @Strategy_TradeStrategy_EndDate ,
						 --@Strategy_TradeStrategy_IndustryID = @Strategy_TradeStrategy_IndustryID ,
						 --@Strategy_TradeStrategy_IsClosed = @Strategy_TradeStrategy_IsClosed ,
						 --@Strategy_TradeStrategy_Leverage = @Strategy_TradeStrategy_Leverage ,
						 --@Strategy_TradeStrategy_Name = @Strategy_TradeStrategy_Name ,
						 --@Strategy_TradeStrategy_PortfolioID = @Strategy_TradeStrategy_PortfolioID ,
						 --@Strategy_TradeStrategy_ShortCode = @Strategy_TradeStrategy_ShortCode ,
						 --@Total_Position_Calculated_PositionCash = @Total_Position_Calculated_PositionCash


				EXEC upsert_BroadridgePositionsSecurity 
						 @Timestamp = @Timestamp ,
						 @UserName = @UserName ,
						 @UniqKey = @UniqKey ,
						 --@Custodian_TradeCpty_TradeCptyName = @Custodian_TradeCpty_TradeCptyName ,
						 --@CustomBloombergID = @CustomBloombergID ,
						 --@CustomFundName = @CustomFundName ,
						 --@CustomFundSort = @CustomFundSort ,
						 --@CustomMarketPrice = @CustomMarketPrice ,
						 --@CustomRiskCategoryCode = @CustomRiskCategoryCode ,
						 --@CustomStrategyCode = @CustomStrategyCode ,
						 --@CustomTicker = @CustomTicker ,
						 --@CustomTickerSort = @CustomTickerSort 
						 --@Fund_Currency_Currency_CurrencyID = @Fund_Currency_Currency_CurrencyID ,
						 --@Fund_TradeFund_Name = @Fund_TradeFund_Name ,
						 --@Position_Calculated_AverageCost = @Position_Calculated_AverageCost ,
						 --@Position_Calculated_BaseLongMarketValue = @Position_Calculated_BaseLongMarketValue ,
						 --@Position_Calculated_BaseLongMarketValueGain = @Position_Calculated_BaseLongMarketValueGain ,
						 --@Position_Calculated_BaseMarketValueDayGain = @Position_Calculated_BaseMarketValueDayGain ,
						 --@Position_Calculated_BaseMarketValue = @Position_Calculated_BaseMarketValue ,
						 --@Position_Calculated_BasePNL_DTD = @Position_Calculated_BasePNL_DTD ,
						 --@Position_Calculated_BasePNL_MTD = @Position_Calculated_BasePNL_MTD ,
						 --@Position_Calculated_BasePNL_YTD = @Position_Calculated_BasePNL_YTD ,
						 --@Position_Calculated_BaseShortMarketValue = @Position_Calculated_BaseShortMarketValue ,
						 --@Position_Calculated_BaseShortMarketValueGain = @Position_Calculated_BaseShortMarketValueGain ,
						 --@Position_Calculated_LocalMarketValue = @Position_Calculated_LocalMarketValue ,
						 --@Position_Calculated_MarketPrice = @Position_Calculated_MarketPrice ,
						 --@Position_Calculated_PositionCash = @Position_Calculated_PositionCash ,
						 --@Position_Calculated_PositionValue = @Position_Calculated_PositionValue ,
						 --@Position_PositionID = @Position_PositionID ,
						 --@Position_PositionTypeString = @Position_PositionTypeString 
						 @Security_Currency_Currency_Ccy = @Security_Currency_Currency_Ccy ,
						 @Security_Currency_Currency_CurrencyID = @Security_Currency_Currency_CurrencyID ,
						 @Security_Security_BloombergGlobalId = @Security_Security_BloombergGlobalId ,
						 @Security_Security_BloombergID = @Security_Security_BloombergID ,
						 @Security_Security_Code = @Security_Security_Code ,
						 @Security_Security_ConversionRatio = @Security_Security_ConversionRatio ,
						 @Security_Security_Name = @Security_Security_Name ,
						 @Security_Security_SecurityID = @Security_Security_SecurityID ,
						 @Security_Security_Ticker = @Security_Security_Ticker ,
						 @Security_Type_SecurityType_Name = @Security_Type_SecurityType_Name ,
						 @Security_Underlying_Security_Code = @Security_Underlying_Security_Code 
						 --@Strategy_Risk_Category_RiskCategory_RiskCategoryID = @Strategy_Risk_Category_RiskCategory_RiskCategoryID ,
						 --@Strategy_Risk_Category_RiskCategory_RiskName = @Strategy_Risk_Category_RiskCategory_RiskName ,
						 --@Strategy_TradeStrategy_ActiveBenchmarkID = @Strategy_TradeStrategy_ActiveBenchmarkID ,
						 --@Strategy_TradeStrategy_CountryID_mkt = @Strategy_TradeStrategy_CountryID_mkt ,
						 --@Strategy_TradeStrategy_Description = @Strategy_TradeStrategy_Description ,
						 --@Strategy_TradeStrategy_EndDate = @Strategy_TradeStrategy_EndDate ,
						 --@Strategy_TradeStrategy_IndustryID = @Strategy_TradeStrategy_IndustryID ,
						 --@Strategy_TradeStrategy_IsClosed = @Strategy_TradeStrategy_IsClosed ,
						 --@Strategy_TradeStrategy_Leverage = @Strategy_TradeStrategy_Leverage ,
						 --@Strategy_TradeStrategy_Name = @Strategy_TradeStrategy_Name ,
						 --@Strategy_TradeStrategy_PortfolioID = @Strategy_TradeStrategy_PortfolioID ,
						 --@Strategy_TradeStrategy_ShortCode = @Strategy_TradeStrategy_ShortCode ,
						 --@Total_Position_Calculated_PositionCash = @Total_Position_Calculated_PositionCash

				EXEC upsert_BroadridgePositionsStrategy 
						 @Timestamp = @Timestamp ,
						 @UserName = @UserName ,
						 @UniqKey = @UniqKey ,
						 --@Custodian_TradeCpty_TradeCptyName = @Custodian_TradeCpty_TradeCptyName ,
						 --@CustomBloombergID = @CustomBloombergID ,
						 --@CustomFundName = @CustomFundName ,
						 --@CustomFundSort = @CustomFundSort ,
						 --@CustomMarketPrice = @CustomMarketPrice ,
						 --@CustomRiskCategoryCode = @CustomRiskCategoryCode ,
						 --@CustomStrategyCode = @CustomStrategyCode ,
						 --@CustomTicker = @CustomTicker ,
						 --@CustomTickerSort = @CustomTickerSort 
						 --@Fund_Currency_Currency_CurrencyID = @Fund_Currency_Currency_CurrencyID ,
						 --@Fund_TradeFund_Name = @Fund_TradeFund_Name ,
						 --@Position_Calculated_AverageCost = @Position_Calculated_AverageCost ,
						 --@Position_Calculated_BaseLongMarketValue = @Position_Calculated_BaseLongMarketValue ,
						 --@Position_Calculated_BaseLongMarketValueGain = @Position_Calculated_BaseLongMarketValueGain ,
						 --@Position_Calculated_BaseMarketValueDayGain = @Position_Calculated_BaseMarketValueDayGain ,
						 --@Position_Calculated_BaseMarketValue = @Position_Calculated_BaseMarketValue ,
						 --@Position_Calculated_BasePNL_DTD = @Position_Calculated_BasePNL_DTD ,
						 --@Position_Calculated_BasePNL_MTD = @Position_Calculated_BasePNL_MTD ,
						 --@Position_Calculated_BasePNL_YTD = @Position_Calculated_BasePNL_YTD ,
						 --@Position_Calculated_BaseShortMarketValue = @Position_Calculated_BaseShortMarketValue ,
						 --@Position_Calculated_BaseShortMarketValueGain = @Position_Calculated_BaseShortMarketValueGain ,
						 --@Position_Calculated_LocalMarketValue = @Position_Calculated_LocalMarketValue ,
						 --@Position_Calculated_MarketPrice = @Position_Calculated_MarketPrice ,
						 --@Position_Calculated_PositionCash = @Position_Calculated_PositionCash ,
						 --@Position_Calculated_PositionValue = @Position_Calculated_PositionValue ,
						 --@Position_PositionID = @Position_PositionID ,
						 --@Position_PositionTypeString = @Position_PositionTypeString 
						 --@Security_Currency_Currency_Ccy = @Security_Currency_Currency_Ccy ,
						 --@Security_Currency_Currency_CurrencyID = @Security_Currency_Currency_CurrencyID ,
						 --@Security_Security_BloombergGlobalId = @Security_Security_BloombergGlobalId ,
						 --@Security_Security_BloombergID = @Security_Security_BloombergID ,
						 --@Security_Security_Code = @Security_Security_Code ,
						 --@Security_Security_Name = @Security_Security_Name ,
						 --@Security_Security_SecurityID = @Security_Security_SecurityID ,
						 --@Security_Security_Ticker = @Security_Security_Ticker ,
						 --@Security_Type_SecurityType_Name = @Security_Type_SecurityType_Name ,
						 --@Security_Underlying_Security_Code = @Security_Underlying_Security_Code 
						 @Strategy_Risk_Category_RiskCategory_RiskCategoryID = @Strategy_Risk_Category_RiskCategory_RiskCategoryID ,
						 @Strategy_Risk_Category_RiskCategory_RiskName = @Strategy_Risk_Category_RiskCategory_RiskName ,
						 @Strategy_TradeStrategy_ActiveBenchmarkID = @Strategy_TradeStrategy_ActiveBenchmarkID ,
						 @Strategy_TradeStrategy_CountryID_mkt = @Strategy_TradeStrategy_CountryID_mkt ,
						 @Strategy_TradeStrategy_Description = @Strategy_TradeStrategy_Description ,
						 @Strategy_TradeStrategy_EndDate = @Strategy_TradeStrategy_EndDate ,
						 @Strategy_TradeStrategy_IndustryID = @Strategy_TradeStrategy_IndustryID ,
						 @Strategy_TradeStrategy_IsClosed = @Strategy_TradeStrategy_IsClosed ,
						 @Strategy_TradeStrategy_Leverage = @Strategy_TradeStrategy_Leverage ,
						 @Strategy_TradeStrategy_Name = @Strategy_TradeStrategy_Name ,
						 @Strategy_TradeStrategy_PortfolioID = @Strategy_TradeStrategy_PortfolioID ,
						 @Strategy_TradeStrategy_ShortCode = @Strategy_TradeStrategy_ShortCode 
						 --@Total_Position_Calculated_PositionCash = @Total_Position_Calculated_PositionCash

				EXEC upsert_BroadridgePositionsOther 
						 @Timestamp = @Timestamp ,
						 @UserName = @UserName ,
						 @UniqKey = @UniqKey ,
						 @Custodian_TradeCpty_TradeCptyName = @Custodian_TradeCpty_TradeCptyName ,
						 --@CustomBloombergID = @CustomBloombergID ,
						 --@CustomFundName = @CustomFundName ,
						 --@CustomFundSort = @CustomFundSort ,
						 --@CustomMarketPrice = @CustomMarketPrice ,
						 --@CustomRiskCategoryCode = @CustomRiskCategoryCode ,
						 --@CustomStrategyCode = @CustomStrategyCode ,
						 --@CustomTicker = @CustomTicker ,
						 --@CustomTickerSort = @CustomTickerSort 
						 @Fund_Currency_Currency_CurrencyID = @Fund_Currency_Currency_CurrencyID ,
						 @Fund_TradeFund_Name = @Fund_TradeFund_Name ,
						 --@Position_Calculated_AverageCost = @Position_Calculated_AverageCost ,
						 --@Position_Calculated_BaseLongMarketValue = @Position_Calculated_BaseLongMarketValue ,
						 --@Position_Calculated_BaseLongMarketValueGain = @Position_Calculated_BaseLongMarketValueGain ,
						 --@Position_Calculated_BaseMarketValueDayGain = @Position_Calculated_BaseMarketValueDayGain ,
						 --@Position_Calculated_BaseMarketValue = @Position_Calculated_BaseMarketValue ,
						 --@Position_Calculated_BasePNL_DTD = @Position_Calculated_BasePNL_DTD ,
						 --@Position_Calculated_BasePNL_MTD = @Position_Calculated_BasePNL_MTD ,
						 --@Position_Calculated_BasePNL_YTD = @Position_Calculated_BasePNL_YTD ,
						 --@Position_Calculated_BaseShortMarketValue = @Position_Calculated_BaseShortMarketValue ,
						 --@Position_Calculated_BaseShortMarketValueGain = @Position_Calculated_BaseShortMarketValueGain ,
						 --@Position_Calculated_LocalMarketValue = @Position_Calculated_LocalMarketValue ,
						 --@Position_Calculated_MarketPrice = @Position_Calculated_MarketPrice ,
						 --@Position_Calculated_PositionCash = @Position_Calculated_PositionCash ,
						 --@Position_Calculated_PositionValue = @Position_Calculated_PositionValue ,
						 --@Position_PositionID = @Position_PositionID ,
						 --@Position_PositionTypeString = @Position_PositionTypeString 
						 --@Security_Currency_Currency_Ccy = @Security_Currency_Currency_Ccy ,
						 --@Security_Currency_Currency_CurrencyID = @Security_Currency_Currency_CurrencyID ,
						 --@Security_Security_BloombergGlobalId = @Security_Security_BloombergGlobalId ,
						 --@Security_Security_BloombergID = @Security_Security_BloombergID ,
						 --@Security_Security_Code = @Security_Security_Code ,
						 --@Security_Security_Name = @Security_Security_Name ,
						 --@Security_Security_SecurityID = @Security_Security_SecurityID ,
						 --@Security_Security_Ticker = @Security_Security_Ticker ,
						 --@Security_Type_SecurityType_Name = @Security_Type_SecurityType_Name ,
						 --@Security_Underlying_Security_Code = @Security_Underlying_Security_Code 
						 --@Strategy_Risk_Category_RiskCategory_RiskCategoryID = @Strategy_Risk_Category_RiskCategory_RiskCategoryID ,
						 --@Strategy_Risk_Category_RiskCategory_RiskName = @Strategy_Risk_Category_RiskCategory_RiskName ,
						 --@Strategy_TradeStrategy_ActiveBenchmarkID = @Strategy_TradeStrategy_ActiveBenchmarkID ,
						 --@Strategy_TradeStrategy_CountryID_mkt = @Strategy_TradeStrategy_CountryID_mkt ,
						 --@Strategy_TradeStrategy_Description = @Strategy_TradeStrategy_Description ,
						 --@Strategy_TradeStrategy_EndDate = @Strategy_TradeStrategy_EndDate ,
						 --@Strategy_TradeStrategy_IndustryID = @Strategy_TradeStrategy_IndustryID ,
						 --@Strategy_TradeStrategy_IsClosed = @Strategy_TradeStrategy_IsClosed ,
						 --@Strategy_TradeStrategy_Leverage = @Strategy_TradeStrategy_Leverage ,
						 --@Strategy_TradeStrategy_Name = @Strategy_TradeStrategy_Name ,
						 --@Strategy_TradeStrategy_PortfolioID = @Strategy_TradeStrategy_PortfolioID ,
						 --@Strategy_TradeStrategy_ShortCode = @Strategy_TradeStrategy_ShortCode ,
						 @Total_Position_Calculated_PositionCash = @Total_Position_Calculated_PositionCash

					FETCH NEXT FROM BroadridgePositions_staging_Cursor INTO
						 @UserName ,
 						 @UniqKey ,
						 @Custodian_TradeCpty_TradeCptyName ,
						 @CustomAccount ,
						 @CustomBloombergID ,
						 @CustomFundName ,
						 @CustomFundSort ,
						 @CustomPartnershipID ,
						 --@CustomMarketPrice ,
						 @CustomRiskCategoryCode ,
						 @CustomStrategyCode ,
						 @CustomTicker ,
						 @CustomTickerSort ,
						 @Fund_Currency_Currency_CurrencyID ,
						 @Fund_TradeFund_Name ,
						 @Position_Calculated_AverageCost ,
						 @Position_Calculated_BaseLongMarketValue ,
						 @Position_Calculated_BaseLongMarketValueGain ,
						 @Position_Calculated_BaseMarketValueDayGain ,
						 @Position_Calculated_BaseMarketValue ,
						 @Position_Calculated_BasePNL_DTD ,
						 @Position_Calculated_BasePNL_MTD ,
						 @Position_Calculated_BasePNL_YTD ,
						 @Position_Calculated_BaseShortMarketValue ,
						 @Position_Calculated_BaseShortMarketValueGain ,
						 @Position_Calculated_LocalMarketValue ,
						 @Position_Calculated_MarketPrice ,
						 @Position_Calculated_PositionCash ,
						 @Position_Calculated_PositionValue ,
						 @Position_PositionID ,
						 @Position_PositionTypeString ,
						 @Security_Currency_Currency_Ccy ,
						 @Security_Currency_Currency_CurrencyID ,
						 @Security_Security_BloombergGlobalId ,
						 @Security_Security_BloombergID ,
						 @Security_Security_Code ,
						 @Security_Security_ConversionRatio ,
						 @Security_Security_MD_RealTimePrice ,
						 @Security_Security_Name ,
						 @Security_Security_SecurityID ,
						 @Security_Security_Ticker ,
						 @Security_Type_SecurityType_Name ,
						 @Security_Underlying_Security_Code ,
						 @Strategy_Risk_Category_RiskCategory_RiskCategoryID ,
						 @Strategy_Risk_Category_RiskCategory_RiskName ,
						 @Strategy_TradeStrategy_ActiveBenchmarkID ,
						 @Strategy_TradeStrategy_CountryID_mkt ,
						 @Strategy_TradeStrategy_Description ,
						 @Strategy_TradeStrategy_EndDate ,
						 @Strategy_TradeStrategy_IndustryID ,
						 @Strategy_TradeStrategy_IsClosed ,
						 @Strategy_TradeStrategy_Leverage ,
						 @Strategy_TradeStrategy_Name ,
						 @Strategy_TradeStrategy_PortfolioID ,
						 @Strategy_TradeStrategy_ShortCode ,
						 @Total_Position_Calculated_PositionCash 

						 SET @CursorCount  = @CursorCount  + 1 
					END
 
		END
 
		CLOSE BroadridgePositions_staging_Cursor

		-- COMMIT TRANSACTION

		DEALLOCATE BroadridgePositions_staging_Cursor

		SET @return_status = 1

	END


GO
