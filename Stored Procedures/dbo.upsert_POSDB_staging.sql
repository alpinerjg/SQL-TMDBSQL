SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Robert Gusick>
-- Create date: <Create Date,,June 1, 2020>
-- Description:	<Description,,Persist BB prices to SQL>
-- =============================================
CREATE PROCEDURE [dbo].[upsert_POSDB_staging] 
	@SecsSinceEpoch bigint,
	@Timestamp DateTime,
	@CustomSort varchar(32),
	@Custodian_TradeCpty_TradeCptyName varchar(32) = NULL,
	@CustomFundName varchar(25),
	@CustomFundSort char(1),
	@CustomRiskCategoryCode varchar(7),
	@CustomStrategyCode varchar(10),
	@CustomTicker varchar(12),
	@CustomTickerSort varchar(16),
	@Fund_Currency_Currency_CurrencyID int,
	@Fund_TradeFund_Name varchar(30),
	@Fund_TradeFund_ShortCode varchar(25),
	@Position_Calculated_AverageCost decimal(18, 9) = NULL,
	@Position_Calculated_BaseLongMarketValue decimal(18, 2) = NULL,
	@Position_Calculated_BaseLongMarketValueGain decimal(18, 2) = NULL,
	@Position_Calculated_BaseMarketValue decimal(18, 2) = NULL,
	@Position_Calculated_BaseMarketValueDayGain decimal(18, 2) = NULL,
	@Position_Calculated_BasePNL_DTD decimal(18, 2) = NULL,
	@Position_Calculated_BasePNL_MTD decimal(18, 2) = NULL,
	@Position_Calculated_BasePNL_YTD decimal(18, 2) = NULL,
	@Position_Calculated_BaseShortMarketValue decimal(18, 2) = NULL,
	@Position_Calculated_BaseShortMarketValueGain decimal(18, 2) = NULL,
	@Position_Calculated_LocalMarketValue decimal(18, 2) = NULL,
	@Position_Calculated_MarketPrice decimal(12, 2) = NULL,
	@Position_Calculated_PositionCash decimal(12, 2) = NULL,
	@Position_Calculated_PositionValue int = NULL,
	@Position_PositionID int,
	@Position_PositionTypeString varchar(1) = NULL,
	@Security_Base_Security_BloombergID varchar(10) = NULL,
	@Security_Currency_Currency_Ccy varchar(3) = NULL,
	@Security_Currency_Currency_CurrencyID int = NULL,
	@Security_Security_BloombergID varchar(10) = NULL,
	@Security_Security_Name varchar(50),
	@Security_Security_SecurityID int,
	@Security_Security_Ticker varchar(16),
	@Security_Type_SecurityType_Name varchar(25) = NULL,
	@Security_Underlying_Security_BloombergID varchar(10) = NULL,
	@Security_Underlying_Security_Code varchar(10) = NULL,
	@Strategy_Risk_Category_RiskCategory_RiskCategoryID int = NULL,
	@Strategy_Risk_Category_RiskCategory_RiskName varchar(16) = NULL,
	@Strategy_TradeStrategy_CreatedBy int = NULL,
	@Strategy_TradeStrategy_Description varchar(64) = NULL,
	@Strategy_TradeStrategy_IsClosed bit,
	@Strategy_TradeStrategy_Name varchar(10),
	@Strategy_TradeStrategy_RiskCategoryID int,
	@Strategy_TradeStrategy_ShortCode varchar(10),
	@Strategy_TradeStrategy_StartDate date = NULL,
	@Strategy_TradeStrategy_TradeStratID int = NULL,
	@Strategy_TradeStrategy_TradeStrategyID int,
	@Strategy_TradeStrategy_TraderID int,
	@Strategy_TradeStrategy_UDF_tmwAcqsym varchar(16) = NULL,
	@Strategy_TradeStrategy_UDF_tmwAltupside decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwCanbuy decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwCashamt decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwCashelect bit= NULL,
	@Strategy_TradeStrategy_UDF_tmwCashpct decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwCharge decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwD1Date date = NULL,
	@Strategy_TradeStrategy_UDF_tmwDealamt decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDealdisp bit = NULL,
	@Strategy_TradeStrategy_UDF_tmwDealname varchar(12),
	@Strategy_TradeStrategy_UDF_tmwDealreport bit = NULL,
	@Strategy_TradeStrategy_UDF_tmwDealtype varchar(16) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDealtypeID int = NULL,
	@Strategy_TradeStrategy_UDF_tmwDefcanbuy bit= NULL,
	@Strategy_TradeStrategy_UDF_tmwDefinative bit = NULL,
	@Strategy_TradeStrategy_UDF_tmwDefinitive bit= NULL,
	@Strategy_TradeStrategy_UDF_tmwDesc varchar(64) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDownprice decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDs10Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDs1Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDs1Symbol varchar(16) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDs2Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDs2Symbol varchar(6) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDs3Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDs3Symbol varchar(6) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDs4Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDs4Symbol varchar(6) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDs5Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDs6Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDs7Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDs8Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwDs9Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwExtracash decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwHighcollar decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwHighrange decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwInitials2 varchar(1) = NULL,
	@Strategy_TradeStrategy_UDF_tmwLowcollar decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwLowrange decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwNondefcanbuy int = NULL,
	@Strategy_TradeStrategy_UDF_tmwNumadditional int = NULL,
	@Strategy_TradeStrategy_UDF_tmwOrigacq decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwOrigprice int = NULL,
	@Strategy_TradeStrategy_UDF_tmwOutsidehigh decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwOutsidelow decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwPrevdown varchar(12) = NULL,
	@Strategy_TradeStrategy_UDF_tmwRatio decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwResidual decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwRevcollar bit= NULL,
	@Strategy_TradeStrategy_UDF_tmwRiskCategory varchar(1) = NULL,
	@Strategy_TradeStrategy_UDF_tmwSecondtier varchar(1) = NULL,
	@Strategy_TradeStrategy_UDF_tmwSecsharesflag bit = NULL,
	@Strategy_TradeStrategy_UDF_tmwStockpct decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwStrategy varchar(12) = NULL,
	@Strategy_TradeStrategy_UDF_tmwTndrpct decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwUndsym varchar(12),
	@Strategy_TradeStrategy_UDF_tmwUpdate date = NULL,
	@Strategy_TradeStrategy_UDF_tmwUpsidemult decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwZs10Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwZs1Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwZs2Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwZs3Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwZs4Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwZs5Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwZs6Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwZs7Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwZs8Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwZs9Price decimal(12, 2) = NULL,
	@Strategy_TradeStrategy_UDF_tmwZshortprice decimal(12, 2) = NULL,
	@Total_Position_Calculated_PositionCash decimal(12, 2) = NULL,
	@return_status INT = 0 OUTPUT 
AS
BEGIN

-- DECLARE @return_status int;
SET @return_status = 0;

BEGIN TRANSACTION

-- Check to see if we already have the bb symbol
IF EXISTS(SELECT 1 FROM [TMDBSQL].[dbo].[POSDB_staging] WHERE CustomSort = @CustomSort)
	BEGIN
	    -- Only update if it has changed
		IF EXISTS(SELECT 1 FROM dbo.POSDB_staging WHERE (CustomSort = @CustomSort AND ts_end IS NULL) AND
		(	CustomTickerSort <> @CustomTickerSort OR
			Position_PositionID <> @Position_PositionID OR
			Position_Calculated_AverageCost <> @Position_Calculated_AverageCost OR
			Position_Calculated_BasePNL_DTD <> @Position_Calculated_BasePNL_DTD OR
			Position_Calculated_BasePNL_MTD <> @Position_Calculated_BasePNL_MTD OR
			Position_Calculated_BasePNL_YTD <> @Position_Calculated_BasePNL_YTD OR
			Position_Calculated_BaseMarketValue <> @Position_Calculated_BaseMarketValue OR
			Position_Calculated_BaseMarketValueDayGain <> @Position_Calculated_BaseMarketValueDayGain OR
			Position_Calculated_LocalMarketValue <> @Position_Calculated_LocalMarketValue OR
			Position_Calculated_MarketPrice <> @Position_Calculated_MarketPrice OR
			Position_Calculated_PositionValue <> @Position_Calculated_PositionValue OR
			Position_Calculated_PositionCash <> @Position_Calculated_PositionCash OR
			Position_PositionTypeString <> @Position_PositionTypeString OR
			Position_Calculated_BaseLongMarketValue <> @Position_Calculated_BaseLongMarketValue OR
			Position_Calculated_BaseShortMarketValue <> @Position_Calculated_BaseShortMarketValue OR
			Position_Calculated_BaseLongMarketValueGain <> @Position_Calculated_BaseLongMarketValueGain OR
			Position_Calculated_BaseShortMarketValueGain <> @Position_Calculated_BaseShortMarketValueGain OR
			Fund_TradeFund_ShortCode <> @Fund_TradeFund_ShortCode OR
			Fund_TradeFund_Name <> @Fund_TradeFund_Name OR
			Fund_Currency_Currency_CurrencyID <> @Fund_Currency_Currency_CurrencyID OR
			Strategy_TradeStrategy_TradeStrategyID <> @Strategy_TradeStrategy_TradeStrategyID OR
			Strategy_TradeStrategy_ShortCode <> @Strategy_TradeStrategy_ShortCode OR
			Strategy_TradeStrategy_Name <> @Strategy_TradeStrategy_Name OR
			Strategy_TradeStrategy_Description <> @Strategy_TradeStrategy_Description OR
			Strategy_TradeStrategy_StartDate <> @Strategy_TradeStrategy_StartDate OR
			Strategy_TradeStrategy_TraderID <> @Strategy_TradeStrategy_TraderID OR
			Strategy_TradeStrategy_RiskCategoryID <> @Strategy_TradeStrategy_RiskCategoryID OR
			Strategy_TradeStrategy_IsClosed <> @Strategy_TradeStrategy_IsClosed OR
			Strategy_TradeStrategy_CreatedBy <> @Strategy_TradeStrategy_CreatedBy OR
			Strategy_TradeStrategy_TradeStratID <> @Strategy_TradeStrategy_TradeStratID OR
			Strategy_TradeStrategy_UDF_tmwRatio <> @Strategy_TradeStrategy_UDF_tmwRatio OR
			Strategy_TradeStrategy_UDF_tmwDealname <> @Strategy_TradeStrategy_UDF_tmwDealname OR
			Strategy_TradeStrategy_UDF_tmwUndsym <> @Strategy_TradeStrategy_UDF_tmwUndsym OR
			Strategy_TradeStrategy_UDF_tmwAcqsym <> @Strategy_TradeStrategy_UDF_tmwAcqsym OR
			Strategy_TradeStrategy_UDF_tmwCashpct <> @Strategy_TradeStrategy_UDF_tmwCashpct OR
			Strategy_TradeStrategy_UDF_tmwStockpct <> @Strategy_TradeStrategy_UDF_tmwStockpct OR
			Strategy_TradeStrategy_UDF_tmwTndrpct <> @Strategy_TradeStrategy_UDF_tmwTndrpct OR
			Strategy_TradeStrategy_UDF_tmwDealamt <> @Strategy_TradeStrategy_UDF_tmwDealamt OR
			Strategy_TradeStrategy_UDF_tmwOrigprice <> @Strategy_TradeStrategy_UDF_tmwOrigprice OR
			Strategy_TradeStrategy_UDF_tmwD1Date <> @Strategy_TradeStrategy_UDF_tmwD1Date OR
			Strategy_TradeStrategy_UDF_tmwCanbuy <> @Strategy_TradeStrategy_UDF_tmwCanbuy OR
			Strategy_TradeStrategy_UDF_tmwDealdisp <> @Strategy_TradeStrategy_UDF_tmwDealdisp OR
			Strategy_TradeStrategy_UDF_tmwSecsharesflag <> @Strategy_TradeStrategy_UDF_tmwSecsharesflag OR
			Strategy_TradeStrategy_UDF_tmwDefinative <> @Strategy_TradeStrategy_UDF_tmwDefinative OR
			Strategy_TradeStrategy_UDF_tmwDealreport <> @Strategy_TradeStrategy_UDF_tmwDealreport OR
			Strategy_TradeStrategy_UDF_tmwUpdate <> @Strategy_TradeStrategy_UDF_tmwUpdate OR
			Strategy_TradeStrategy_UDF_tmwDealtypeID <> @Strategy_TradeStrategy_UDF_tmwDealtypeID OR
			Strategy_TradeStrategy_UDF_tmwCashamt <> @Strategy_TradeStrategy_UDF_tmwCashamt OR
			Strategy_TradeStrategy_UDF_tmwLowcollar <> @Strategy_TradeStrategy_UDF_tmwLowcollar OR
			Strategy_TradeStrategy_UDF_tmwHighcollar <> @Strategy_TradeStrategy_UDF_tmwHighcollar OR
			Strategy_TradeStrategy_UDF_tmwOutsidelow <> @Strategy_TradeStrategy_UDF_tmwOutsidelow OR
			Strategy_TradeStrategy_UDF_tmwOutsidehigh <> @Strategy_TradeStrategy_UDF_tmwOutsidehigh OR
			Strategy_TradeStrategy_UDF_tmwLowrange <> @Strategy_TradeStrategy_UDF_tmwLowrange OR
			Strategy_TradeStrategy_UDF_tmwHighrange <> @Strategy_TradeStrategy_UDF_tmwHighrange OR
			Strategy_TradeStrategy_UDF_tmwRevcollar <> @Strategy_TradeStrategy_UDF_tmwRevcollar OR
			Strategy_TradeStrategy_UDF_tmwResidual <> @Strategy_TradeStrategy_UDF_tmwResidual OR
			Strategy_TradeStrategy_UDF_tmwOrigacq <> @Strategy_TradeStrategy_UDF_tmwOrigacq OR
			Strategy_TradeStrategy_UDF_tmwDownprice <> @Strategy_TradeStrategy_UDF_tmwDownprice OR
			Strategy_TradeStrategy_UDF_tmwDs1Symbol <> @Strategy_TradeStrategy_UDF_tmwDs1Symbol OR
			Strategy_TradeStrategy_UDF_tmwDs1Price <> @Strategy_TradeStrategy_UDF_tmwDs1Price OR
			Strategy_TradeStrategy_UDF_tmwDs2Symbol <> @Strategy_TradeStrategy_UDF_tmwDs2Symbol OR
			Strategy_TradeStrategy_UDF_tmwDs2Price <> @Strategy_TradeStrategy_UDF_tmwDs2Price OR
			Strategy_TradeStrategy_UDF_tmwDs3Symbol <> @Strategy_TradeStrategy_UDF_tmwDs3Symbol OR
			Strategy_TradeStrategy_UDF_tmwDs3Price <> @Strategy_TradeStrategy_UDF_tmwDs3Price OR
			Strategy_TradeStrategy_UDF_tmwDs4Symbol <> @Strategy_TradeStrategy_UDF_tmwDs4Symbol OR
			Strategy_TradeStrategy_UDF_tmwDs4Price <> @Strategy_TradeStrategy_UDF_tmwDs4Price OR
			Strategy_TradeStrategy_UDF_tmwDs5Price <> @Strategy_TradeStrategy_UDF_tmwDs5Price OR
			Strategy_TradeStrategy_UDF_tmwDs6Price <> @Strategy_TradeStrategy_UDF_tmwDs6Price OR
			Strategy_TradeStrategy_UDF_tmwDs7Price <> @Strategy_TradeStrategy_UDF_tmwDs7Price OR
			Strategy_TradeStrategy_UDF_tmwDs8Price <> @Strategy_TradeStrategy_UDF_tmwDs8Price OR
			Strategy_TradeStrategy_UDF_tmwDs9Price <> @Strategy_TradeStrategy_UDF_tmwDs9Price OR
			Strategy_TradeStrategy_UDF_tmwDs10Price <> @Strategy_TradeStrategy_UDF_tmwDs10Price OR
			Strategy_TradeStrategy_UDF_tmwDesc <> @Strategy_TradeStrategy_UDF_tmwDesc OR
			Strategy_TradeStrategy_UDF_tmwCashelect <> @Strategy_TradeStrategy_UDF_tmwCashelect OR
			Strategy_TradeStrategy_UDF_tmwCharge <> @Strategy_TradeStrategy_UDF_tmwCharge OR
			Strategy_TradeStrategy_UDF_tmwZs1Price <> @Strategy_TradeStrategy_UDF_tmwZs1Price OR
			Strategy_TradeStrategy_UDF_tmwZs2Price <> @Strategy_TradeStrategy_UDF_tmwZs2Price OR
			Strategy_TradeStrategy_UDF_tmwZs3Price <> @Strategy_TradeStrategy_UDF_tmwZs3Price OR
			Strategy_TradeStrategy_UDF_tmwZs4Price <> @Strategy_TradeStrategy_UDF_tmwZs4Price OR
			Strategy_TradeStrategy_UDF_tmwZs5Price <> @Strategy_TradeStrategy_UDF_tmwZs5Price OR
			Strategy_TradeStrategy_UDF_tmwZs6Price <> @Strategy_TradeStrategy_UDF_tmwZs6Price OR
			Strategy_TradeStrategy_UDF_tmwZs7Price <> @Strategy_TradeStrategy_UDF_tmwZs7Price OR
			Strategy_TradeStrategy_UDF_tmwZs8Price <> @Strategy_TradeStrategy_UDF_tmwZs8Price OR
			Strategy_TradeStrategy_UDF_tmwZs9Price <> @Strategy_TradeStrategy_UDF_tmwZs9Price OR
			Strategy_TradeStrategy_UDF_tmwZs10Price <> @Strategy_TradeStrategy_UDF_tmwZs10Price OR
			Strategy_TradeStrategy_UDF_tmwZshortprice <> @Strategy_TradeStrategy_UDF_tmwZshortprice OR
			Strategy_TradeStrategy_UDF_tmwNumadditional <> @Strategy_TradeStrategy_UDF_tmwNumadditional OR
			Strategy_TradeStrategy_UDF_tmwDefinitive <> @Strategy_TradeStrategy_UDF_tmwDefinitive OR
			Strategy_TradeStrategy_UDF_tmwInitials2 <> @Strategy_TradeStrategy_UDF_tmwInitials2 OR
			Strategy_TradeStrategy_UDF_tmwNondefcanbuy <> @Strategy_TradeStrategy_UDF_tmwNondefcanbuy OR
			Strategy_TradeStrategy_UDF_tmwDefcanbuy <> @Strategy_TradeStrategy_UDF_tmwDefcanbuy OR
			Strategy_TradeStrategy_UDF_tmwPrevdown <> @Strategy_TradeStrategy_UDF_tmwPrevdown OR
			Strategy_TradeStrategy_UDF_tmwSecondtier <> @Strategy_TradeStrategy_UDF_tmwSecondtier OR
			Strategy_TradeStrategy_UDF_tmwStrategy <> @Strategy_TradeStrategy_UDF_tmwStrategy OR
			Strategy_TradeStrategy_UDF_tmwUpsidemult <> @Strategy_TradeStrategy_UDF_tmwUpsidemult OR
			Strategy_TradeStrategy_UDF_tmwExtracash <> @Strategy_TradeStrategy_UDF_tmwExtracash OR
			Strategy_TradeStrategy_UDF_tmwAltupside <> @Strategy_TradeStrategy_UDF_tmwAltupside OR
			Strategy_TradeStrategy_UDF_tmwDealtype <> @Strategy_TradeStrategy_UDF_tmwDealtype OR
			Strategy_TradeStrategy_UDF_tmwRiskCategory <> @Strategy_TradeStrategy_UDF_tmwRiskCategory OR
			Strategy_Risk_Category_RiskCategory_RiskCategoryID <> @Strategy_Risk_Category_RiskCategory_RiskCategoryID OR
			Strategy_Risk_Category_RiskCategory_RiskName <> @Strategy_Risk_Category_RiskCategory_RiskName OR
			Security_Security_SecurityID <> @Security_Security_SecurityID OR
			Security_Security_Name <> @Security_Security_Name OR
			Security_Security_Ticker <> @Security_Security_Ticker OR
			Security_Security_BloombergID <> @Security_Security_BloombergID OR
			Security_Type_SecurityType_Name <> @Security_Type_SecurityType_Name OR
			Security_Underlying_Security_BloombergID <> @Security_Underlying_Security_BloombergID OR
			Security_Underlying_Security_Code <> @Security_Underlying_Security_Code OR
			Security_Currency_Currency_CurrencyID <> @Security_Currency_Currency_CurrencyID OR
			Security_Currency_Currency_Ccy <> @Security_Currency_Currency_Ccy OR
			Security_Base_Security_BloombergID <> @Security_Base_Security_BloombergID OR
			Custodian_TradeCpty_TradeCptyName <> @Custodian_TradeCpty_TradeCptyName OR
			Total_Position_Calculated_PositionCash <> @Total_Position_Calculated_PositionCash OR
			CustomFundName <> @CustomFundName OR
			CustomTicker <> @CustomTicker OR
			CustomStrategyCode <> @CustomStrategyCode OR
			CustomFundSort <> @CustomFundSort OR
			CustomRiskCategoryCode <> @CustomRiskCategoryCode )
		)
			BEGIN
				UPDATE [TMDBSQL].[dbo].[POSDB_staging] WITH (SERIALIZABLE)
					SET
						ts_end = @Timestamp
					WHERE
						CustomSort = @CustomSort and ts_end IS NULL

					INSERT INTO dbo.POSDB_staging
					(	SecsSinceEpoch ,
						CustomSort ,
						CustomTickerSort ,
						Position_PositionID ,
						Position_Calculated_AverageCost ,
						Position_Calculated_BasePNL_DTD ,
						Position_Calculated_BasePNL_MTD ,
						Position_Calculated_BasePNL_YTD ,
						Position_Calculated_BaseMarketValue ,
						Position_Calculated_BaseMarketValueDayGain ,
						Position_Calculated_LocalMarketValue ,
						Position_Calculated_MarketPrice ,
						Position_Calculated_PositionValue ,
						Position_Calculated_PositionCash ,
						Position_PositionTypeString ,
						Position_Calculated_BaseLongMarketValue ,
						Position_Calculated_BaseShortMarketValue ,
						Position_Calculated_BaseLongMarketValueGain ,
						Position_Calculated_BaseShortMarketValueGain ,
						Fund_TradeFund_ShortCode ,
						Fund_TradeFund_Name ,
						Fund_Currency_Currency_CurrencyID ,
						Strategy_TradeStrategy_TradeStrategyID ,
						Strategy_TradeStrategy_ShortCode ,
						Strategy_TradeStrategy_Name ,
						Strategy_TradeStrategy_Description ,
						Strategy_TradeStrategy_StartDate ,
						Strategy_TradeStrategy_TraderID ,
						Strategy_TradeStrategy_RiskCategoryID ,
						Strategy_TradeStrategy_IsClosed ,
						Strategy_TradeStrategy_CreatedBy ,
						Strategy_TradeStrategy_TradeStratID ,
						Strategy_TradeStrategy_UDF_tmwRatio ,
						Strategy_TradeStrategy_UDF_tmwDealname ,
						Strategy_TradeStrategy_UDF_tmwUndsym ,
						Strategy_TradeStrategy_UDF_tmwAcqsym ,
						Strategy_TradeStrategy_UDF_tmwCashpct ,
						Strategy_TradeStrategy_UDF_tmwStockpct ,
						Strategy_TradeStrategy_UDF_tmwTndrpct ,
						Strategy_TradeStrategy_UDF_tmwDealamt ,
						Strategy_TradeStrategy_UDF_tmwOrigprice ,
						Strategy_TradeStrategy_UDF_tmwD1Date ,
						Strategy_TradeStrategy_UDF_tmwCanbuy ,
						Strategy_TradeStrategy_UDF_tmwDealdisp ,
						Strategy_TradeStrategy_UDF_tmwSecsharesflag ,
						Strategy_TradeStrategy_UDF_tmwDefinative ,
						Strategy_TradeStrategy_UDF_tmwDealreport ,
						Strategy_TradeStrategy_UDF_tmwUpdate ,
						Strategy_TradeStrategy_UDF_tmwDealtypeID ,
						Strategy_TradeStrategy_UDF_tmwCashamt ,
						Strategy_TradeStrategy_UDF_tmwLowcollar ,
						Strategy_TradeStrategy_UDF_tmwHighcollar ,
						Strategy_TradeStrategy_UDF_tmwOutsidelow ,
						Strategy_TradeStrategy_UDF_tmwOutsidehigh ,
						Strategy_TradeStrategy_UDF_tmwLowrange ,
						Strategy_TradeStrategy_UDF_tmwHighrange ,
						Strategy_TradeStrategy_UDF_tmwRevcollar ,
						Strategy_TradeStrategy_UDF_tmwResidual ,
						Strategy_TradeStrategy_UDF_tmwOrigacq ,
						Strategy_TradeStrategy_UDF_tmwDownprice ,
						Strategy_TradeStrategy_UDF_tmwDs1Symbol ,
						Strategy_TradeStrategy_UDF_tmwDs1Price ,
						Strategy_TradeStrategy_UDF_tmwDs2Symbol ,
						Strategy_TradeStrategy_UDF_tmwDs2Price ,
						Strategy_TradeStrategy_UDF_tmwDs3Symbol ,
						Strategy_TradeStrategy_UDF_tmwDs3Price ,
						Strategy_TradeStrategy_UDF_tmwDs4Symbol ,
						Strategy_TradeStrategy_UDF_tmwDs4Price ,
						Strategy_TradeStrategy_UDF_tmwDs5Price ,
						Strategy_TradeStrategy_UDF_tmwDs6Price ,
						Strategy_TradeStrategy_UDF_tmwDs7Price ,
						Strategy_TradeStrategy_UDF_tmwDs8Price ,
						Strategy_TradeStrategy_UDF_tmwDs9Price ,
						Strategy_TradeStrategy_UDF_tmwDs10Price ,
						Strategy_TradeStrategy_UDF_tmwDesc ,
						Strategy_TradeStrategy_UDF_tmwCashelect ,
						Strategy_TradeStrategy_UDF_tmwCharge ,
						Strategy_TradeStrategy_UDF_tmwZs1Price ,
						Strategy_TradeStrategy_UDF_tmwZs2Price ,
						Strategy_TradeStrategy_UDF_tmwZs3Price ,
						Strategy_TradeStrategy_UDF_tmwZs4Price ,
						Strategy_TradeStrategy_UDF_tmwZs5Price ,
						Strategy_TradeStrategy_UDF_tmwZs6Price ,
						Strategy_TradeStrategy_UDF_tmwZs7Price ,
						Strategy_TradeStrategy_UDF_tmwZs8Price ,
						Strategy_TradeStrategy_UDF_tmwZs9Price ,
						Strategy_TradeStrategy_UDF_tmwZs10Price ,
						Strategy_TradeStrategy_UDF_tmwZshortprice ,
						Strategy_TradeStrategy_UDF_tmwNumadditional ,
						Strategy_TradeStrategy_UDF_tmwDefinitive ,
						Strategy_TradeStrategy_UDF_tmwInitials2 ,
						Strategy_TradeStrategy_UDF_tmwNondefcanbuy ,
						Strategy_TradeStrategy_UDF_tmwDefcanbuy ,
						Strategy_TradeStrategy_UDF_tmwPrevdown ,
						Strategy_TradeStrategy_UDF_tmwSecondtier ,
						Strategy_TradeStrategy_UDF_tmwStrategy ,
						Strategy_TradeStrategy_UDF_tmwUpsidemult ,
						Strategy_TradeStrategy_UDF_tmwExtracash ,
						Strategy_TradeStrategy_UDF_tmwAltupside ,
						Strategy_TradeStrategy_UDF_tmwDealtype ,
						Strategy_TradeStrategy_UDF_tmwRiskCategory ,
						Strategy_Risk_Category_RiskCategory_RiskCategoryID ,
						Strategy_Risk_Category_RiskCategory_RiskName ,
						Security_Security_SecurityID ,
						Security_Security_Name ,
						Security_Security_Ticker ,
						Security_Security_BloombergID ,
						Security_Type_SecurityType_Name ,
						Security_Underlying_Security_BloombergID ,
						Security_Underlying_Security_Code ,
						Security_Currency_Currency_CurrencyID ,
						Security_Currency_Currency_Ccy ,
						Security_Base_Security_BloombergID ,
						Custodian_TradeCpty_TradeCptyName ,
						Total_Position_Calculated_PositionCash ,
						CustomFundName ,
						CustomTicker ,
						CustomStrategyCode ,
						CustomFundSort ,
						CustomRiskCategoryCode ,
						ts_start ,
						ts_end )
				VALUES
					(	@SecsSinceEpoch ,
						@CustomSort ,
						@CustomTickerSort ,
						@Position_PositionID ,
						@Position_Calculated_AverageCost ,
						@Position_Calculated_BasePNL_DTD ,
						@Position_Calculated_BasePNL_MTD ,
						@Position_Calculated_BasePNL_YTD ,
						@Position_Calculated_BaseMarketValue ,
						@Position_Calculated_BaseMarketValueDayGain ,
						@Position_Calculated_LocalMarketValue ,
						@Position_Calculated_MarketPrice ,
						@Position_Calculated_PositionValue ,
						@Position_Calculated_PositionCash ,
						@Position_PositionTypeString ,
						@Position_Calculated_BaseLongMarketValue ,
						@Position_Calculated_BaseShortMarketValue ,
						@Position_Calculated_BaseLongMarketValueGain ,
						@Position_Calculated_BaseShortMarketValueGain ,
						@Fund_TradeFund_ShortCode ,
						@Fund_TradeFund_Name ,
						@Fund_Currency_Currency_CurrencyID ,
						@Strategy_TradeStrategy_TradeStrategyID ,
						@Strategy_TradeStrategy_ShortCode ,
						@Strategy_TradeStrategy_Name ,
						@Strategy_TradeStrategy_Description ,
						@Strategy_TradeStrategy_StartDate ,
						@Strategy_TradeStrategy_TraderID ,
						@Strategy_TradeStrategy_RiskCategoryID ,
						@Strategy_TradeStrategy_IsClosed ,
						@Strategy_TradeStrategy_CreatedBy ,
						@Strategy_TradeStrategy_TradeStratID ,
						@Strategy_TradeStrategy_UDF_tmwRatio ,
						@Strategy_TradeStrategy_UDF_tmwDealname ,
						@Strategy_TradeStrategy_UDF_tmwUndsym ,
						@Strategy_TradeStrategy_UDF_tmwAcqsym ,
						@Strategy_TradeStrategy_UDF_tmwCashpct ,
						@Strategy_TradeStrategy_UDF_tmwStockpct ,
						@Strategy_TradeStrategy_UDF_tmwTndrpct ,
						@Strategy_TradeStrategy_UDF_tmwDealamt ,
						@Strategy_TradeStrategy_UDF_tmwOrigprice ,
						@Strategy_TradeStrategy_UDF_tmwD1Date ,
						@Strategy_TradeStrategy_UDF_tmwCanbuy ,
						@Strategy_TradeStrategy_UDF_tmwDealdisp ,
						@Strategy_TradeStrategy_UDF_tmwSecsharesflag ,
						@Strategy_TradeStrategy_UDF_tmwDefinative ,
						@Strategy_TradeStrategy_UDF_tmwDealreport ,
						@Strategy_TradeStrategy_UDF_tmwUpdate ,
						@Strategy_TradeStrategy_UDF_tmwDealtypeID ,
						@Strategy_TradeStrategy_UDF_tmwCashamt ,
						@Strategy_TradeStrategy_UDF_tmwLowcollar ,
						@Strategy_TradeStrategy_UDF_tmwHighcollar ,
						@Strategy_TradeStrategy_UDF_tmwOutsidelow ,
						@Strategy_TradeStrategy_UDF_tmwOutsidehigh ,
						@Strategy_TradeStrategy_UDF_tmwLowrange ,
						@Strategy_TradeStrategy_UDF_tmwHighrange ,
						@Strategy_TradeStrategy_UDF_tmwRevcollar ,
						@Strategy_TradeStrategy_UDF_tmwResidual ,
						@Strategy_TradeStrategy_UDF_tmwOrigacq ,
						@Strategy_TradeStrategy_UDF_tmwDownprice ,
						@Strategy_TradeStrategy_UDF_tmwDs1Symbol ,
						@Strategy_TradeStrategy_UDF_tmwDs1Price ,
						@Strategy_TradeStrategy_UDF_tmwDs2Symbol ,
						@Strategy_TradeStrategy_UDF_tmwDs2Price ,
						@Strategy_TradeStrategy_UDF_tmwDs3Symbol ,
						@Strategy_TradeStrategy_UDF_tmwDs3Price ,
						@Strategy_TradeStrategy_UDF_tmwDs4Symbol ,
						@Strategy_TradeStrategy_UDF_tmwDs4Price ,
						@Strategy_TradeStrategy_UDF_tmwDs5Price ,
						@Strategy_TradeStrategy_UDF_tmwDs6Price ,
						@Strategy_TradeStrategy_UDF_tmwDs7Price ,
						@Strategy_TradeStrategy_UDF_tmwDs8Price ,
						@Strategy_TradeStrategy_UDF_tmwDs9Price ,
						@Strategy_TradeStrategy_UDF_tmwDs10Price ,
						@Strategy_TradeStrategy_UDF_tmwDesc ,
						@Strategy_TradeStrategy_UDF_tmwCashelect ,
						@Strategy_TradeStrategy_UDF_tmwCharge ,
						@Strategy_TradeStrategy_UDF_tmwZs1Price ,
						@Strategy_TradeStrategy_UDF_tmwZs2Price ,
						@Strategy_TradeStrategy_UDF_tmwZs3Price ,
						@Strategy_TradeStrategy_UDF_tmwZs4Price ,
						@Strategy_TradeStrategy_UDF_tmwZs5Price ,
						@Strategy_TradeStrategy_UDF_tmwZs6Price ,
						@Strategy_TradeStrategy_UDF_tmwZs7Price ,
						@Strategy_TradeStrategy_UDF_tmwZs8Price ,
						@Strategy_TradeStrategy_UDF_tmwZs9Price ,
						@Strategy_TradeStrategy_UDF_tmwZs10Price ,
						@Strategy_TradeStrategy_UDF_tmwZshortprice ,
						@Strategy_TradeStrategy_UDF_tmwNumadditional ,
						@Strategy_TradeStrategy_UDF_tmwDefinitive ,
						@Strategy_TradeStrategy_UDF_tmwInitials2 ,
						@Strategy_TradeStrategy_UDF_tmwNondefcanbuy ,
						@Strategy_TradeStrategy_UDF_tmwDefcanbuy ,
						@Strategy_TradeStrategy_UDF_tmwPrevdown ,
						@Strategy_TradeStrategy_UDF_tmwSecondtier ,
						@Strategy_TradeStrategy_UDF_tmwStrategy ,
						@Strategy_TradeStrategy_UDF_tmwUpsidemult ,
						@Strategy_TradeStrategy_UDF_tmwExtracash ,
						@Strategy_TradeStrategy_UDF_tmwAltupside ,
						@Strategy_TradeStrategy_UDF_tmwDealtype ,
						@Strategy_TradeStrategy_UDF_tmwRiskCategory ,
						@Strategy_Risk_Category_RiskCategory_RiskCategoryID ,
						@Strategy_Risk_Category_RiskCategory_RiskName ,
						@Security_Security_SecurityID ,
						@Security_Security_Name ,
						@Security_Security_Ticker ,
						@Security_Security_BloombergID ,
						@Security_Type_SecurityType_Name ,
						@Security_Underlying_Security_BloombergID ,
						@Security_Underlying_Security_Code ,
						@Security_Currency_Currency_CurrencyID ,
						@Security_Currency_Currency_Ccy ,
						@Security_Base_Security_BloombergID ,
						@Custodian_TradeCpty_TradeCptyName ,
						@Total_Position_Calculated_PositionCash ,
						@CustomFundName ,
						@CustomTicker ,
						@CustomStrategyCode ,
						@CustomFundSort ,
						@CustomRiskCategoryCode ,
						@Timestamp ,
						NULL )

				SET @return_status = 1
			END
	END
ELSE
	BEGIN
     -- Completely new record
		INSERT INTO dbo.POSDB_staging
			(	SecsSinceEpoch ,
				CustomSort ,
				CustomTickerSort ,
				Position_PositionID ,
				Position_Calculated_AverageCost ,
				Position_Calculated_BasePNL_DTD ,
				Position_Calculated_BasePNL_MTD ,
				Position_Calculated_BasePNL_YTD ,
				Position_Calculated_BaseMarketValue ,
				Position_Calculated_BaseMarketValueDayGain ,
				Position_Calculated_LocalMarketValue ,
				Position_Calculated_MarketPrice ,
				Position_Calculated_PositionValue ,
				Position_Calculated_PositionCash ,
				Position_PositionTypeString ,
				Position_Calculated_BaseLongMarketValue ,
				Position_Calculated_BaseShortMarketValue ,
				Position_Calculated_BaseLongMarketValueGain ,
				Position_Calculated_BaseShortMarketValueGain ,
				Fund_TradeFund_ShortCode ,
				Fund_TradeFund_Name ,
				Fund_Currency_Currency_CurrencyID ,
				Strategy_TradeStrategy_TradeStrategyID ,
				Strategy_TradeStrategy_ShortCode ,
				Strategy_TradeStrategy_Name ,
				Strategy_TradeStrategy_Description ,
				Strategy_TradeStrategy_StartDate ,
				Strategy_TradeStrategy_TraderID ,
				Strategy_TradeStrategy_RiskCategoryID ,
				Strategy_TradeStrategy_IsClosed ,
				Strategy_TradeStrategy_CreatedBy ,
				Strategy_TradeStrategy_TradeStratID ,
				Strategy_TradeStrategy_UDF_tmwRatio ,
				Strategy_TradeStrategy_UDF_tmwDealname ,
				Strategy_TradeStrategy_UDF_tmwUndsym ,
				Strategy_TradeStrategy_UDF_tmwAcqsym ,
				Strategy_TradeStrategy_UDF_tmwCashpct ,
				Strategy_TradeStrategy_UDF_tmwStockpct ,
				Strategy_TradeStrategy_UDF_tmwTndrpct ,
				Strategy_TradeStrategy_UDF_tmwDealamt ,
				Strategy_TradeStrategy_UDF_tmwOrigprice ,
				Strategy_TradeStrategy_UDF_tmwD1Date ,
				Strategy_TradeStrategy_UDF_tmwCanbuy ,
				Strategy_TradeStrategy_UDF_tmwDealdisp ,
				Strategy_TradeStrategy_UDF_tmwSecsharesflag ,
				Strategy_TradeStrategy_UDF_tmwDefinative ,
				Strategy_TradeStrategy_UDF_tmwDealreport ,
				Strategy_TradeStrategy_UDF_tmwUpdate ,
				Strategy_TradeStrategy_UDF_tmwDealtypeID ,
				Strategy_TradeStrategy_UDF_tmwCashamt ,
				Strategy_TradeStrategy_UDF_tmwLowcollar ,
				Strategy_TradeStrategy_UDF_tmwHighcollar ,
				Strategy_TradeStrategy_UDF_tmwOutsidelow ,
				Strategy_TradeStrategy_UDF_tmwOutsidehigh ,
				Strategy_TradeStrategy_UDF_tmwLowrange ,
				Strategy_TradeStrategy_UDF_tmwHighrange ,
				Strategy_TradeStrategy_UDF_tmwRevcollar ,
				Strategy_TradeStrategy_UDF_tmwResidual ,
				Strategy_TradeStrategy_UDF_tmwOrigacq ,
				Strategy_TradeStrategy_UDF_tmwDownprice ,
				Strategy_TradeStrategy_UDF_tmwDs1Symbol ,
				Strategy_TradeStrategy_UDF_tmwDs1Price ,
				Strategy_TradeStrategy_UDF_tmwDs2Symbol ,
				Strategy_TradeStrategy_UDF_tmwDs2Price ,
				Strategy_TradeStrategy_UDF_tmwDs3Symbol ,
				Strategy_TradeStrategy_UDF_tmwDs3Price ,
				Strategy_TradeStrategy_UDF_tmwDs4Symbol ,
				Strategy_TradeStrategy_UDF_tmwDs4Price ,
				Strategy_TradeStrategy_UDF_tmwDs5Price ,
				Strategy_TradeStrategy_UDF_tmwDs6Price ,
				Strategy_TradeStrategy_UDF_tmwDs7Price ,
				Strategy_TradeStrategy_UDF_tmwDs8Price ,
				Strategy_TradeStrategy_UDF_tmwDs9Price ,
				Strategy_TradeStrategy_UDF_tmwDs10Price ,
				Strategy_TradeStrategy_UDF_tmwDesc ,
				Strategy_TradeStrategy_UDF_tmwCashelect ,
				Strategy_TradeStrategy_UDF_tmwCharge ,
				Strategy_TradeStrategy_UDF_tmwZs1Price ,
				Strategy_TradeStrategy_UDF_tmwZs2Price ,
				Strategy_TradeStrategy_UDF_tmwZs3Price ,
				Strategy_TradeStrategy_UDF_tmwZs4Price ,
				Strategy_TradeStrategy_UDF_tmwZs5Price ,
				Strategy_TradeStrategy_UDF_tmwZs6Price ,
				Strategy_TradeStrategy_UDF_tmwZs7Price ,
				Strategy_TradeStrategy_UDF_tmwZs8Price ,
				Strategy_TradeStrategy_UDF_tmwZs9Price ,
				Strategy_TradeStrategy_UDF_tmwZs10Price ,
				Strategy_TradeStrategy_UDF_tmwZshortprice ,
				Strategy_TradeStrategy_UDF_tmwNumadditional ,
				Strategy_TradeStrategy_UDF_tmwDefinitive ,
				Strategy_TradeStrategy_UDF_tmwInitials2 ,
				Strategy_TradeStrategy_UDF_tmwNondefcanbuy ,
				Strategy_TradeStrategy_UDF_tmwDefcanbuy ,
				Strategy_TradeStrategy_UDF_tmwPrevdown ,
				Strategy_TradeStrategy_UDF_tmwSecondtier ,
				Strategy_TradeStrategy_UDF_tmwStrategy ,
				Strategy_TradeStrategy_UDF_tmwUpsidemult ,
				Strategy_TradeStrategy_UDF_tmwExtracash ,
				Strategy_TradeStrategy_UDF_tmwAltupside ,
				Strategy_TradeStrategy_UDF_tmwDealtype ,
				Strategy_TradeStrategy_UDF_tmwRiskCategory ,
				Strategy_Risk_Category_RiskCategory_RiskCategoryID ,
				Strategy_Risk_Category_RiskCategory_RiskName ,
				Security_Security_SecurityID ,
				Security_Security_Name ,
				Security_Security_Ticker ,
				Security_Security_BloombergID ,
				Security_Type_SecurityType_Name ,
				Security_Underlying_Security_BloombergID ,
				Security_Underlying_Security_Code ,
				Security_Currency_Currency_CurrencyID ,
				Security_Currency_Currency_Ccy ,
				Security_Base_Security_BloombergID ,
				Custodian_TradeCpty_TradeCptyName ,
				Total_Position_Calculated_PositionCash ,
				CustomFundName ,
				CustomTicker ,
				CustomStrategyCode ,
				CustomFundSort ,
				CustomRiskCategoryCode ,
				ts_start ,
				ts_end )
		VALUES
			(	@SecsSinceEpoch ,
				@CustomSort ,
				@CustomTickerSort ,
				@Position_PositionID ,
				@Position_Calculated_AverageCost ,
				@Position_Calculated_BasePNL_DTD ,
				@Position_Calculated_BasePNL_MTD ,
				@Position_Calculated_BasePNL_YTD ,
				@Position_Calculated_BaseMarketValue ,
				@Position_Calculated_BaseMarketValueDayGain ,
				@Position_Calculated_LocalMarketValue ,
				@Position_Calculated_MarketPrice ,
				@Position_Calculated_PositionValue ,
				@Position_Calculated_PositionCash ,
				@Position_PositionTypeString ,
				@Position_Calculated_BaseLongMarketValue ,
				@Position_Calculated_BaseShortMarketValue ,
				@Position_Calculated_BaseLongMarketValueGain ,
				@Position_Calculated_BaseShortMarketValueGain ,
				@Fund_TradeFund_ShortCode ,
				@Fund_TradeFund_Name ,
				@Fund_Currency_Currency_CurrencyID ,
				@Strategy_TradeStrategy_TradeStrategyID ,
				@Strategy_TradeStrategy_ShortCode ,
				@Strategy_TradeStrategy_Name ,
				@Strategy_TradeStrategy_Description ,
				@Strategy_TradeStrategy_StartDate ,
				@Strategy_TradeStrategy_TraderID ,
				@Strategy_TradeStrategy_RiskCategoryID ,
				@Strategy_TradeStrategy_IsClosed ,
				@Strategy_TradeStrategy_CreatedBy ,
				@Strategy_TradeStrategy_TradeStratID ,
				@Strategy_TradeStrategy_UDF_tmwRatio ,
				@Strategy_TradeStrategy_UDF_tmwDealname ,
				@Strategy_TradeStrategy_UDF_tmwUndsym ,
				@Strategy_TradeStrategy_UDF_tmwAcqsym ,
				@Strategy_TradeStrategy_UDF_tmwCashpct ,
				@Strategy_TradeStrategy_UDF_tmwStockpct ,
				@Strategy_TradeStrategy_UDF_tmwTndrpct ,
				@Strategy_TradeStrategy_UDF_tmwDealamt ,
				@Strategy_TradeStrategy_UDF_tmwOrigprice ,
				@Strategy_TradeStrategy_UDF_tmwD1Date ,
				@Strategy_TradeStrategy_UDF_tmwCanbuy ,
				@Strategy_TradeStrategy_UDF_tmwDealdisp ,
				@Strategy_TradeStrategy_UDF_tmwSecsharesflag ,
				@Strategy_TradeStrategy_UDF_tmwDefinative ,
				@Strategy_TradeStrategy_UDF_tmwDealreport ,
				@Strategy_TradeStrategy_UDF_tmwUpdate ,
				@Strategy_TradeStrategy_UDF_tmwDealtypeID ,
				@Strategy_TradeStrategy_UDF_tmwCashamt ,
				@Strategy_TradeStrategy_UDF_tmwLowcollar ,
				@Strategy_TradeStrategy_UDF_tmwHighcollar ,
				@Strategy_TradeStrategy_UDF_tmwOutsidelow ,
				@Strategy_TradeStrategy_UDF_tmwOutsidehigh ,
				@Strategy_TradeStrategy_UDF_tmwLowrange ,
				@Strategy_TradeStrategy_UDF_tmwHighrange ,
				@Strategy_TradeStrategy_UDF_tmwRevcollar ,
				@Strategy_TradeStrategy_UDF_tmwResidual ,
				@Strategy_TradeStrategy_UDF_tmwOrigacq ,
				@Strategy_TradeStrategy_UDF_tmwDownprice ,
				@Strategy_TradeStrategy_UDF_tmwDs1Symbol ,
				@Strategy_TradeStrategy_UDF_tmwDs1Price ,
				@Strategy_TradeStrategy_UDF_tmwDs2Symbol ,
				@Strategy_TradeStrategy_UDF_tmwDs2Price ,
				@Strategy_TradeStrategy_UDF_tmwDs3Symbol ,
				@Strategy_TradeStrategy_UDF_tmwDs3Price ,
				@Strategy_TradeStrategy_UDF_tmwDs4Symbol ,
				@Strategy_TradeStrategy_UDF_tmwDs4Price ,
				@Strategy_TradeStrategy_UDF_tmwDs5Price ,
				@Strategy_TradeStrategy_UDF_tmwDs6Price ,
				@Strategy_TradeStrategy_UDF_tmwDs7Price ,
				@Strategy_TradeStrategy_UDF_tmwDs8Price ,
				@Strategy_TradeStrategy_UDF_tmwDs9Price ,
				@Strategy_TradeStrategy_UDF_tmwDs10Price ,
				@Strategy_TradeStrategy_UDF_tmwDesc ,
				@Strategy_TradeStrategy_UDF_tmwCashelect ,
				@Strategy_TradeStrategy_UDF_tmwCharge ,
				@Strategy_TradeStrategy_UDF_tmwZs1Price ,
				@Strategy_TradeStrategy_UDF_tmwZs2Price ,
				@Strategy_TradeStrategy_UDF_tmwZs3Price ,
				@Strategy_TradeStrategy_UDF_tmwZs4Price ,
				@Strategy_TradeStrategy_UDF_tmwZs5Price ,
				@Strategy_TradeStrategy_UDF_tmwZs6Price ,
				@Strategy_TradeStrategy_UDF_tmwZs7Price ,
				@Strategy_TradeStrategy_UDF_tmwZs8Price ,
				@Strategy_TradeStrategy_UDF_tmwZs9Price ,
				@Strategy_TradeStrategy_UDF_tmwZs10Price ,
				@Strategy_TradeStrategy_UDF_tmwZshortprice ,
				@Strategy_TradeStrategy_UDF_tmwNumadditional ,
				@Strategy_TradeStrategy_UDF_tmwDefinitive ,
				@Strategy_TradeStrategy_UDF_tmwInitials2 ,
				@Strategy_TradeStrategy_UDF_tmwNondefcanbuy ,
				@Strategy_TradeStrategy_UDF_tmwDefcanbuy ,
				@Strategy_TradeStrategy_UDF_tmwPrevdown ,
				@Strategy_TradeStrategy_UDF_tmwSecondtier ,
				@Strategy_TradeStrategy_UDF_tmwStrategy ,
				@Strategy_TradeStrategy_UDF_tmwUpsidemult ,
				@Strategy_TradeStrategy_UDF_tmwExtracash ,
				@Strategy_TradeStrategy_UDF_tmwAltupside ,
				@Strategy_TradeStrategy_UDF_tmwDealtype ,
				@Strategy_TradeStrategy_UDF_tmwRiskCategory ,
				@Strategy_Risk_Category_RiskCategory_RiskCategoryID ,
				@Strategy_Risk_Category_RiskCategory_RiskName ,
				@Security_Security_SecurityID ,
				@Security_Security_Name ,
				@Security_Security_Ticker ,
				@Security_Security_BloombergID ,
				@Security_Type_SecurityType_Name ,
				@Security_Underlying_Security_BloombergID ,
				@Security_Underlying_Security_Code ,
				@Security_Currency_Currency_CurrencyID ,
				@Security_Currency_Currency_Ccy ,
				@Security_Base_Security_BloombergID ,
				@Custodian_TradeCpty_TradeCptyName ,
				@Total_Position_Calculated_PositionCash ,
				@CustomFundName ,
				@CustomTicker ,
				@CustomStrategyCode ,
				@CustomFundSort ,
				@CustomRiskCategoryCode ,
				DATEADD(d, 0, DATEDIFF(d, 0, @Timestamp)) ,
				NULL )
		SET @return_status = 1
	END

COMMIT TRANSACTION

-- PRINT @bbsecurity
-- PRINT @return_status
-- RETURN @return_status

END
GO
