SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[vwDelayed]
AS
SELECT bbsecurity,COUNT(delayed) AS cnt_delayed FROM [TICKDB] WHERE delayed=1 AND markethours=1 AND src != 'rgusick' GROUP BY bbsecurity,markethours,delayed
GO
