SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[vwDelayedCount]
AS
    SELECT ISNULL(L.bbsecurity,D.bbsecurity) as bbsecurity,ISNULL(L.cnt_live,0) as cnt_live,ISNULL(D.cnt_delayed,0) as cnt_delayed from vwLive L FULL OUTER JOIN vwDelayed D ON L.bbsecurity = D.bbsecurity 
GO
