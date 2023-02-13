SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[vwLive]
AS
  SELECT bbsecurity,COUNT(delayed) AS cnt_live FROM [TICKDB] WHERE delayed=0 AND markethours=1 AND src != 'rgusick' GROUP BY bbsecurity,delayed
GO
