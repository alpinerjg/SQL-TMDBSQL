SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[vwPOSDB_staging]
AS
SELECT        TOP (100) PERCENT SecsSinceEpoch, CustomSort, CustomFundName, Strategy_Risk_Category_RiskCategory_RiskName, CustomTicker, CustomStrategyCode, Security_Security_Name, Security_Type_SecurityType_Name, 
                         Position_PositionTypeString, Position_Calculated_PositionValue, Position_Calculated_MarketPrice, Position_Calculated_LocalMarketValue, Custodian_TradeCpty_TradeCptyName, Security_Currency_Currency_Ccy, 
                         Position_Calculated_AverageCost, Position_Calculated_BasePNL_DTD, Position_Calculated_BasePNL_MTD, Position_Calculated_BasePNL_YTD, Position_Calculated_BaseLongMarketValue, 
                         Position_Calculated_BaseShortMarketValue, CustomTickerSort, Position_PositionID, Position_Calculated_BaseMarketValue, Position_Calculated_BaseMarketValueDayGain, Position_Calculated_PositionCash, 
                         Position_Calculated_BaseLongMarketValueGain, Position_Calculated_BaseShortMarketValueGain, Fund_TradeFund_ShortCode, Fund_TradeFund_Name, Fund_Currency_Currency_CurrencyID, 
                         Strategy_TradeStrategy_TradeStrategyID, Strategy_TradeStrategy_ShortCode, Strategy_TradeStrategy_Name, Strategy_TradeStrategy_Description, Strategy_TradeStrategy_StartDate, Strategy_TradeStrategy_TraderID, 
                         Strategy_TradeStrategy_RiskCategoryID, Strategy_TradeStrategy_IsClosed, Strategy_TradeStrategy_CreatedBy, Strategy_TradeStrategy_TradeStratID, Strategy_TradeStrategy_UDF_tmwRatio, 
                         Strategy_TradeStrategy_UDF_tmwDealname, Strategy_TradeStrategy_UDF_tmwUndsym, Strategy_TradeStrategy_UDF_tmwAcqsym, Strategy_TradeStrategy_UDF_tmwCashpct, Strategy_TradeStrategy_UDF_tmwStockpct, 
                         Strategy_TradeStrategy_UDF_tmwTndrpct, Strategy_TradeStrategy_UDF_tmwDealamt, Strategy_TradeStrategy_UDF_tmwOrigprice, Strategy_TradeStrategy_UDF_tmwD1Date, Strategy_TradeStrategy_UDF_tmwCanbuy, 
                         Strategy_TradeStrategy_UDF_tmwDealdisp, Strategy_TradeStrategy_UDF_tmwSecsharesflag, Strategy_TradeStrategy_UDF_tmwDefinative, Strategy_TradeStrategy_UDF_tmwDealreport, 
                         Strategy_TradeStrategy_UDF_tmwUpdate, Strategy_TradeStrategy_UDF_tmwDealtypeID, Strategy_TradeStrategy_UDF_tmwCashamt, Strategy_TradeStrategy_UDF_tmwLowcollar, Strategy_TradeStrategy_UDF_tmwHighcollar, 
                         Strategy_TradeStrategy_UDF_tmwOutsidelow, Strategy_TradeStrategy_UDF_tmwOutsidehigh, Strategy_TradeStrategy_UDF_tmwLowrange, Strategy_TradeStrategy_UDF_tmwHighrange, 
                         Strategy_TradeStrategy_UDF_tmwRevcollar, Strategy_TradeStrategy_UDF_tmwResidual, Strategy_TradeStrategy_UDF_tmwOrigacq, Strategy_TradeStrategy_UDF_tmwDownprice, Strategy_TradeStrategy_UDF_tmwDs1Symbol, 
                         Strategy_TradeStrategy_UDF_tmwDs1Price, Strategy_TradeStrategy_UDF_tmwDs2Symbol, Strategy_TradeStrategy_UDF_tmwDs2Price, Strategy_TradeStrategy_UDF_tmwDs3Symbol, 
                         Strategy_TradeStrategy_UDF_tmwDs3Price, Strategy_TradeStrategy_UDF_tmwDs4Symbol, Strategy_TradeStrategy_UDF_tmwDs4Price, Strategy_TradeStrategy_UDF_tmwDs5Price, Strategy_TradeStrategy_UDF_tmwDs6Price, 
                         Strategy_TradeStrategy_UDF_tmwDs7Price, Strategy_TradeStrategy_UDF_tmwDs8Price, Strategy_TradeStrategy_UDF_tmwDs9Price, Strategy_TradeStrategy_UDF_tmwDs10Price, Strategy_TradeStrategy_UDF_tmwDesc, 
                         Strategy_TradeStrategy_UDF_tmwCashelect, Strategy_TradeStrategy_UDF_tmwCharge, Strategy_TradeStrategy_UDF_tmwZs1Price, Strategy_TradeStrategy_UDF_tmwZs2Price, Strategy_TradeStrategy_UDF_tmwZs3Price, 
                         Strategy_TradeStrategy_UDF_tmwZs4Price, Strategy_TradeStrategy_UDF_tmwZs5Price, Strategy_TradeStrategy_UDF_tmwZs6Price, Strategy_TradeStrategy_UDF_tmwZs7Price, Strategy_TradeStrategy_UDF_tmwZs8Price, 
                         Strategy_TradeStrategy_UDF_tmwZs9Price, Strategy_TradeStrategy_UDF_tmwZs10Price, Strategy_TradeStrategy_UDF_tmwZshortprice, Strategy_TradeStrategy_UDF_tmwNumadditional, 
                         Strategy_TradeStrategy_UDF_tmwDefinitive, Strategy_TradeStrategy_UDF_tmwInitials2, Strategy_TradeStrategy_UDF_tmwNondefcanbuy, Strategy_TradeStrategy_UDF_tmwDefcanbuy, 
                         Strategy_TradeStrategy_UDF_tmwPrevdown, Strategy_TradeStrategy_UDF_tmwSecondtier, Strategy_TradeStrategy_UDF_tmwStrategy, Strategy_TradeStrategy_UDF_tmwUpsidemult, 
                         Strategy_TradeStrategy_UDF_tmwExtracash, Strategy_TradeStrategy_UDF_tmwAltupside, Strategy_TradeStrategy_UDF_tmwDealtype, Strategy_TradeStrategy_UDF_tmwRiskCategory, 
                         Strategy_Risk_Category_RiskCategory_RiskCategoryID, Security_Security_SecurityID, Security_Security_Ticker, Security_Security_BloombergID, Security_Currency_Currency_CurrencyID, 
                         Security_Base_Security_BloombergID, Total_Position_Calculated_PositionCash, CustomFundSort, CustomRiskCategoryCode
FROM            dbo.POSDB_staging
WHERE        (ts_end IS NULL)
ORDER BY CustomSort
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "POSDB_staging"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 408
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 3225
         Alias = 900
         Table = 1170
         Output = 2010
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', N'dbo', 'VIEW', N'vwPOSDB_staging', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'vwPOSDB_staging', NULL, NULL
GO
