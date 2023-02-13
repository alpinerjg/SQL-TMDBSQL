SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[merge_TMWPOSDB] 
	@TimeStamp datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
BEGIN TRANSACTION merge_TMWPOSDB

-- ==================================================
-- Slowly Changing Dimension script by SCD Merge Wizard
-- Author: Miljan Radovic
-- Official web site: https://github.com/SQLPlayer/SCD-Merge-Wizard/
-- Version: 4.3.0.0
-- Publish date: 4/8/2021 9:05:16 AM
-- Script creation date: 4/23/2021 9:19:53 AM
-- ==================================================

-- ==================================================
-- USER VARIABLES
-- ==================================================
DECLARE @CurrentDateTime datetime
DECLARE @NullDateTime datetime

SELECT
	@CurrentDateTime = cast(getdate() as datetime),
	@NullDateTime = cast(null as datetime)




-- ==================================================
-- SCD2
-- ==================================================
INSERT INTO [dbo].[TMWPOSDB]
(
	[account],
	[currency],
	[dayaccrued],
	[daycash],
	[daycomm],
	[daycost],
	[daycppaid],
	[daycprecv],
	[daydipaid],
	[daydirecv],
	[daymark],
	[daypos],
	[dayreal],
	[daysecfee],
	[daystart],
	[daytktcharge],
	[fxrate],
	[h10longratefrac],
	[h10longrateint],
	[h10mark],
	[h10offset],
	[h10percent],
	[h10shortratefrac],
	[h10shortrateint],
	[h11longratefrac],
	[h11longrateint],
	[h11mark],
	[h11offset],
	[h11percent],
	[h11shortratefrac],
	[h11shortrateint],
	[h12longratefrac],
	[h12longrateint],
	[h12mark],
	[h12offset],
	[h12percent],
	[h12shortratefrac],
	[h12shortrateint],
	[h13longratefrac],
	[h13longrateint],
	[h13mark],
	[h13offset],
	[h13percent],
	[h13shortratefrac],
	[h13shortrateint],
	[h14longratefrac],
	[h14longrateint],
	[h14mark],
	[h14offset],
	[h14percent],
	[h14shortratefrac],
	[h14shortrateint],
	[h15longratefrac],
	[h15longrateint],
	[h15mark],
	[h15offset],
	[h15percent],
	[h15shortratefrac],
	[h15shortrateint],
	[h16longratefrac],
	[h16longrateint],
	[h16mark],
	[h16offset],
	[h16percent],
	[h16shortratefrac],
	[h16shortrateint],
	[h1longratefrac],
	[h1longrateint],
	[h1mark],
	[h1offset],
	[h1percent],
	[h1shortratefrac],
	[h1shortrateint],
	[h2longratefrac],
	[h2longrateint],
	[h2mark],
	[h2offset],
	[h2percent],
	[h2shortratefrac],
	[h2shortrateint],
	[h3longratefrac],
	[h3longrateint],
	[h3mark],
	[h3offset],
	[h3percent],
	[h3shortratefrac],
	[h3shortrateint],
	[h4longratefrac],
	[h4longrateint],
	[h4mark],
	[h4offset],
	[h4percent],
	[h4shortratefrac],
	[h4shortrateint],
	[h5longratefrac],
	[h5longrateint],
	[h5mark],
	[h5offset],
	[h5percent],
	[h5shortratefrac],
	[h5shortrateint],
	[h6longratefrac],
	[h6longrateint],
	[h6mark],
	[h6offset],
	[h6percent],
	[h6shortratefrac],
	[h6shortrateint],
	[h7longratefrac],
	[h7longrateint],
	[h7mark],
	[h7offset],
	[h7percent],
	[h7shortratefrac],
	[h7shortrateint],
	[h8longratefrac],
	[h8longrateint],
	[h8mark],
	[h8offset],
	[h8percent],
	[h8shortratefrac],
	[h8shortrateint],
	[h9longratefrac],
	[h9longrateint],
	[h9mark],
	[h9offset],
	[h9percent],
	[h9shortratefrac],
	[h9shortrateint],
	[hedge],
	[lastmonthaccrued],
	[lastmonthcash],
	[lastmonthcomm],
	[lastmonthcost],
	[lastmonthcppaid],
	[lastmonthcprecv],
	[lastmonthdipaid],
	[lastmonthdirecv],
	[lastmonthmark],
	[lastmonthpos],
	[lastmonthreal],
	[lastmonthsecfee],
	[lastmonthstart],
	[lastmonthtktcharge],
	[lastyearaccured],
	[lastyearcash],
	[lastyearcomm],
	[lastyearcost],
	[lastyearcppaid],
	[lastyearcprecv],
	[lastyeardipaid],
	[lastyeardirecv],
	[lastyearmark],
	[lastyearpos],
	[lastyearreal],
	[lastyearsecfee],
	[lastyearstart],
	[lastyeartktcharge],
	[longrate],
	[mark],
	[monthaccrued],
	[monthcash],
	[monthcomm],
	[monthcost],
	[monthcppaid],
	[monthcprecv],
	[monthdipaid],
	[monthdirecv],
	[monthmark],
	[monthpos],
	[monthreal],
	[monthsecfee],
	[monthstart],
	[monthtktcharge],
	[openaccrued],
	[opencash],
	[opencomm],
	[opencost],
	[opencppaid],
	[opencprecv],
	[opendipaid],
	[opendirecv],
	[openmark],
	[openpos],
	[openreal],
	[opensecfee],
	[openstart],
	[opentktcharge],
	[ratio],
	[shortrate],
	[shortratecode],
	[strategy],
	[symbol],
	[ts_end],
	[ts_start],
	[yearaccrued],
	[yearcash],
	[yearcomm],
	[yearcost],
	[yearcppaid],
	[yearcprecv],
	[yeardipaid],
	[yeardirecv],
	[yearmark],
	[yearpos],
	[yearreal],
	[yearsecfee],
	[yearstart],
	[yeartktcharge]
)
SELECT
	[account],
	[currency],
	[dayaccrued],
	[daycash],
	[daycomm],
	[daycost],
	[daycppaid],
	[daycprecv],
	[daydipaid],
	[daydirecv],
	[daymark],
	[daypos],
	[dayreal],
	[daysecfee],
	[daystart],
	[daytktcharge],
	[fxrate],
	[h10longratefrac],
	[h10longrateint],
	[h10mark],
	[h10offset],
	[h10percent],
	[h10shortratefrac],
	[h10shortrateint],
	[h11longratefrac],
	[h11longrateint],
	[h11mark],
	[h11offset],
	[h11percent],
	[h11shortratefrac],
	[h11shortrateint],
	[h12longratefrac],
	[h12longrateint],
	[h12mark],
	[h12offset],
	[h12percent],
	[h12shortratefrac],
	[h12shortrateint],
	[h13longratefrac],
	[h13longrateint],
	[h13mark],
	[h13offset],
	[h13percent],
	[h13shortratefrac],
	[h13shortrateint],
	[h14longratefrac],
	[h14longrateint],
	[h14mark],
	[h14offset],
	[h14percent],
	[h14shortratefrac],
	[h14shortrateint],
	[h15longratefrac],
	[h15longrateint],
	[h15mark],
	[h15offset],
	[h15percent],
	[h15shortratefrac],
	[h15shortrateint],
	[h16longratefrac],
	[h16longrateint],
	[h16mark],
	[h16offset],
	[h16percent],
	[h16shortratefrac],
	[h16shortrateint],
	[h1longratefrac],
	[h1longrateint],
	[h1mark],
	[h1offset],
	[h1percent],
	[h1shortratefrac],
	[h1shortrateint],
	[h2longratefrac],
	[h2longrateint],
	[h2mark],
	[h2offset],
	[h2percent],
	[h2shortratefrac],
	[h2shortrateint],
	[h3longratefrac],
	[h3longrateint],
	[h3mark],
	[h3offset],
	[h3percent],
	[h3shortratefrac],
	[h3shortrateint],
	[h4longratefrac],
	[h4longrateint],
	[h4mark],
	[h4offset],
	[h4percent],
	[h4shortratefrac],
	[h4shortrateint],
	[h5longratefrac],
	[h5longrateint],
	[h5mark],
	[h5offset],
	[h5percent],
	[h5shortratefrac],
	[h5shortrateint],
	[h6longratefrac],
	[h6longrateint],
	[h6mark],
	[h6offset],
	[h6percent],
	[h6shortratefrac],
	[h6shortrateint],
	[h7longratefrac],
	[h7longrateint],
	[h7mark],
	[h7offset],
	[h7percent],
	[h7shortratefrac],
	[h7shortrateint],
	[h8longratefrac],
	[h8longrateint],
	[h8mark],
	[h8offset],
	[h8percent],
	[h8shortratefrac],
	[h8shortrateint],
	[h9longratefrac],
	[h9longrateint],
	[h9mark],
	[h9offset],
	[h9percent],
	[h9shortratefrac],
	[h9shortrateint],
	[hedge],
	[lastmonthaccrued],
	[lastmonthcash],
	[lastmonthcomm],
	[lastmonthcost],
	[lastmonthcppaid],
	[lastmonthcprecv],
	[lastmonthdipaid],
	[lastmonthdirecv],
	[lastmonthmark],
	[lastmonthpos],
	[lastmonthreal],
	[lastmonthsecfee],
	[lastmonthstart],
	[lastmonthtktcharge],
	[lastyearaccured],
	[lastyearcash],
	[lastyearcomm],
	[lastyearcost],
	[lastyearcppaid],
	[lastyearcprecv],
	[lastyeardipaid],
	[lastyeardirecv],
	[lastyearmark],
	[lastyearpos],
	[lastyearreal],
	[lastyearsecfee],
	[lastyearstart],
	[lastyeartktcharge],
	[longrate],
	[mark],
	[monthaccrued],
	[monthcash],
	[monthcomm],
	[monthcost],
	[monthcppaid],
	[monthcprecv],
	[monthdipaid],
	[monthdirecv],
	[monthmark],
	[monthpos],
	[monthreal],
	[monthsecfee],
	[monthstart],
	[monthtktcharge],
	[openaccrued],
	[opencash],
	[opencomm],
	[opencost],
	[opencppaid],
	[opencprecv],
	[opendipaid],
	[opendirecv],
	[openmark],
	[openpos],
	[openreal],
	[opensecfee],
	[openstart],
	[opentktcharge],
	[ratio],
	[shortrate],
	[shortratecode],
	[strategy],
	[symbol],
	[ts_end],
	[ts_start],
	[yearaccrued],
	[yearcash],
	[yearcomm],
	[yearcost],
	[yearcppaid],
	[yearcprecv],
	[yeardipaid],
	[yeardirecv],
	[yearmark],
	[yearpos],
	[yearreal],
	[yearsecfee],
	[yearstart],
	[yeartktcharge]
FROM
(
	MERGE [dbo].[TMWPOSDB] as [target]
	USING
	(
		SELECT
			[account],
			[currency],
			[dayaccrued],
			[daycash],
			[daycomm],
			[daycost],
			[daycppaid],
			[daycprecv],
			[daydipaid],
			[daydirecv],
			[daymark],
			[daypos],
			[dayreal],
			[daysecfee],
			[daystart],
			[daytktcharge],
			[fxrate],
			[h10longratefrac],
			[h10longrateint],
			[h10mark],
			[h10offset],
			[h10percent],
			[h10shortratefrac],
			[h10shortrateint],
			[h11longratefrac],
			[h11longrateint],
			[h11mark],
			[h11offset],
			[h11percent],
			[h11shortratefrac],
			[h11shortrateint],
			[h12longratefrac],
			[h12longrateint],
			[h12mark],
			[h12offset],
			[h12percent],
			[h12shortratefrac],
			[h12shortrateint],
			[h13longratefrac],
			[h13longrateint],
			[h13mark],
			[h13offset],
			[h13percent],
			[h13shortratefrac],
			[h13shortrateint],
			[h14longratefrac],
			[h14longrateint],
			[h14mark],
			[h14offset],
			[h14percent],
			[h14shortratefrac],
			[h14shortrateint],
			[h15longratefrac],
			[h15longrateint],
			[h15mark],
			[h15offset],
			[h15percent],
			[h15shortratefrac],
			[h15shortrateint],
			[h16longratefrac],
			[h16longrateint],
			[h16mark],
			[h16offset],
			[h16percent],
			[h16shortratefrac],
			[h16shortrateint],
			[h1longratefrac],
			[h1longrateint],
			[h1mark],
			[h1offset],
			[h1percent],
			[h1shortratefrac],
			[h1shortrateint],
			[h2longratefrac],
			[h2longrateint],
			[h2mark],
			[h2offset],
			[h2percent],
			[h2shortratefrac],
			[h2shortrateint],
			[h3longratefrac],
			[h3longrateint],
			[h3mark],
			[h3offset],
			[h3percent],
			[h3shortratefrac],
			[h3shortrateint],
			[h4longratefrac],
			[h4longrateint],
			[h4mark],
			[h4offset],
			[h4percent],
			[h4shortratefrac],
			[h4shortrateint],
			[h5longratefrac],
			[h5longrateint],
			[h5mark],
			[h5offset],
			[h5percent],
			[h5shortratefrac],
			[h5shortrateint],
			[h6longratefrac],
			[h6longrateint],
			[h6mark],
			[h6offset],
			[h6percent],
			[h6shortratefrac],
			[h6shortrateint],
			[h7longratefrac],
			[h7longrateint],
			[h7mark],
			[h7offset],
			[h7percent],
			[h7shortratefrac],
			[h7shortrateint],
			[h8longratefrac],
			[h8longrateint],
			[h8mark],
			[h8offset],
			[h8percent],
			[h8shortratefrac],
			[h8shortrateint],
			[h9longratefrac],
			[h9longrateint],
			[h9mark],
			[h9offset],
			[h9percent],
			[h9shortratefrac],
			[h9shortrateint],
			[hedge],
			[lastmonthaccrued],
			[lastmonthcash],
			[lastmonthcomm],
			[lastmonthcost],
			[lastmonthcppaid],
			[lastmonthcprecv],
			[lastmonthdipaid],
			[lastmonthdirecv],
			[lastmonthmark],
			[lastmonthpos],
			[lastmonthreal],
			[lastmonthsecfee],
			[lastmonthstart],
			[lastmonthtktcharge],
			[lastyearaccured],
			[lastyearcash],
			[lastyearcomm],
			[lastyearcost],
			[lastyearcppaid],
			[lastyearcprecv],
			[lastyeardipaid],
			[lastyeardirecv],
			[lastyearmark],
			[lastyearpos],
			[lastyearreal],
			[lastyearsecfee],
			[lastyearstart],
			[lastyeartktcharge],
			[longrate],
			[mark],
			[monthaccrued],
			[monthcash],
			[monthcomm],
			[monthcost],
			[monthcppaid],
			[monthcprecv],
			[monthdipaid],
			[monthdirecv],
			[monthmark],
			[monthpos],
			[monthreal],
			[monthsecfee],
			[monthstart],
			[monthtktcharge],
			[openaccrued],
			[opencash],
			[opencomm],
			[opencost],
			[opencppaid],
			[opencprecv],
			[opendipaid],
			[opendirecv],
			[openmark],
			[openpos],
			[openreal],
			[opensecfee],
			[openstart],
			[opentktcharge],
			[ratio],
			[shortrate],
			[shortratecode],
			[strategy],
			[symbol],
			[yearaccrued],
			[yearcash],
			[yearcomm],
			[yearcost],
			[yearcppaid],
			[yearcprecv],
			[yeardipaid],
			[yeardirecv],
			[yearmark],
			[yearpos],
			[yearreal],
			[yearsecfee],
			[yearstart],
			[yeartktcharge]
		FROM [dbo].[TMWPOSDB_staging]

	) as [source]
	ON
	(
		[source].[account] = [target].[account] AND
		[source].[strategy] = [target].[strategy] AND
		[source].[symbol] = [target].[symbol]
	)

	WHEN NOT MATCHED BY TARGET
	THEN INSERT
	(
		[account],
		[currency],
		[dayaccrued],
		[daycash],
		[daycomm],
		[daycost],
		[daycppaid],
		[daycprecv],
		[daydipaid],
		[daydirecv],
		[daymark],
		[daypos],
		[dayreal],
		[daysecfee],
		[daystart],
		[daytktcharge],
		[fxrate],
		[h10longratefrac],
		[h10longrateint],
		[h10mark],
		[h10offset],
		[h10percent],
		[h10shortratefrac],
		[h10shortrateint],
		[h11longratefrac],
		[h11longrateint],
		[h11mark],
		[h11offset],
		[h11percent],
		[h11shortratefrac],
		[h11shortrateint],
		[h12longratefrac],
		[h12longrateint],
		[h12mark],
		[h12offset],
		[h12percent],
		[h12shortratefrac],
		[h12shortrateint],
		[h13longratefrac],
		[h13longrateint],
		[h13mark],
		[h13offset],
		[h13percent],
		[h13shortratefrac],
		[h13shortrateint],
		[h14longratefrac],
		[h14longrateint],
		[h14mark],
		[h14offset],
		[h14percent],
		[h14shortratefrac],
		[h14shortrateint],
		[h15longratefrac],
		[h15longrateint],
		[h15mark],
		[h15offset],
		[h15percent],
		[h15shortratefrac],
		[h15shortrateint],
		[h16longratefrac],
		[h16longrateint],
		[h16mark],
		[h16offset],
		[h16percent],
		[h16shortratefrac],
		[h16shortrateint],
		[h1longratefrac],
		[h1longrateint],
		[h1mark],
		[h1offset],
		[h1percent],
		[h1shortratefrac],
		[h1shortrateint],
		[h2longratefrac],
		[h2longrateint],
		[h2mark],
		[h2offset],
		[h2percent],
		[h2shortratefrac],
		[h2shortrateint],
		[h3longratefrac],
		[h3longrateint],
		[h3mark],
		[h3offset],
		[h3percent],
		[h3shortratefrac],
		[h3shortrateint],
		[h4longratefrac],
		[h4longrateint],
		[h4mark],
		[h4offset],
		[h4percent],
		[h4shortratefrac],
		[h4shortrateint],
		[h5longratefrac],
		[h5longrateint],
		[h5mark],
		[h5offset],
		[h5percent],
		[h5shortratefrac],
		[h5shortrateint],
		[h6longratefrac],
		[h6longrateint],
		[h6mark],
		[h6offset],
		[h6percent],
		[h6shortratefrac],
		[h6shortrateint],
		[h7longratefrac],
		[h7longrateint],
		[h7mark],
		[h7offset],
		[h7percent],
		[h7shortratefrac],
		[h7shortrateint],
		[h8longratefrac],
		[h8longrateint],
		[h8mark],
		[h8offset],
		[h8percent],
		[h8shortratefrac],
		[h8shortrateint],
		[h9longratefrac],
		[h9longrateint],
		[h9mark],
		[h9offset],
		[h9percent],
		[h9shortratefrac],
		[h9shortrateint],
		[hedge],
		[lastmonthaccrued],
		[lastmonthcash],
		[lastmonthcomm],
		[lastmonthcost],
		[lastmonthcppaid],
		[lastmonthcprecv],
		[lastmonthdipaid],
		[lastmonthdirecv],
		[lastmonthmark],
		[lastmonthpos],
		[lastmonthreal],
		[lastmonthsecfee],
		[lastmonthstart],
		[lastmonthtktcharge],
		[lastyearaccured],
		[lastyearcash],
		[lastyearcomm],
		[lastyearcost],
		[lastyearcppaid],
		[lastyearcprecv],
		[lastyeardipaid],
		[lastyeardirecv],
		[lastyearmark],
		[lastyearpos],
		[lastyearreal],
		[lastyearsecfee],
		[lastyearstart],
		[lastyeartktcharge],
		[longrate],
		[mark],
		[monthaccrued],
		[monthcash],
		[monthcomm],
		[monthcost],
		[monthcppaid],
		[monthcprecv],
		[monthdipaid],
		[monthdirecv],
		[monthmark],
		[monthpos],
		[monthreal],
		[monthsecfee],
		[monthstart],
		[monthtktcharge],
		[openaccrued],
		[opencash],
		[opencomm],
		[opencost],
		[opencppaid],
		[opencprecv],
		[opendipaid],
		[opendirecv],
		[openmark],
		[openpos],
		[openreal],
		[opensecfee],
		[openstart],
		[opentktcharge],
		[ratio],
		[shortrate],
		[shortratecode],
		[strategy],
		[symbol],
		[ts_end],
		[ts_start],
		[yearaccrued],
		[yearcash],
		[yearcomm],
		[yearcost],
		[yearcppaid],
		[yearcprecv],
		[yeardipaid],
		[yeardirecv],
		[yearmark],
		[yearpos],
		[yearreal],
		[yearsecfee],
		[yearstart],
		[yeartktcharge]
	)
	VALUES
	(
		[account],
		[currency],
		[dayaccrued],
		[daycash],
		[daycomm],
		[daycost],
		[daycppaid],
		[daycprecv],
		[daydipaid],
		[daydirecv],
		[daymark],
		[daypos],
		[dayreal],
		[daysecfee],
		[daystart],
		[daytktcharge],
		[fxrate],
		[h10longratefrac],
		[h10longrateint],
		[h10mark],
		[h10offset],
		[h10percent],
		[h10shortratefrac],
		[h10shortrateint],
		[h11longratefrac],
		[h11longrateint],
		[h11mark],
		[h11offset],
		[h11percent],
		[h11shortratefrac],
		[h11shortrateint],
		[h12longratefrac],
		[h12longrateint],
		[h12mark],
		[h12offset],
		[h12percent],
		[h12shortratefrac],
		[h12shortrateint],
		[h13longratefrac],
		[h13longrateint],
		[h13mark],
		[h13offset],
		[h13percent],
		[h13shortratefrac],
		[h13shortrateint],
		[h14longratefrac],
		[h14longrateint],
		[h14mark],
		[h14offset],
		[h14percent],
		[h14shortratefrac],
		[h14shortrateint],
		[h15longratefrac],
		[h15longrateint],
		[h15mark],
		[h15offset],
		[h15percent],
		[h15shortratefrac],
		[h15shortrateint],
		[h16longratefrac],
		[h16longrateint],
		[h16mark],
		[h16offset],
		[h16percent],
		[h16shortratefrac],
		[h16shortrateint],
		[h1longratefrac],
		[h1longrateint],
		[h1mark],
		[h1offset],
		[h1percent],
		[h1shortratefrac],
		[h1shortrateint],
		[h2longratefrac],
		[h2longrateint],
		[h2mark],
		[h2offset],
		[h2percent],
		[h2shortratefrac],
		[h2shortrateint],
		[h3longratefrac],
		[h3longrateint],
		[h3mark],
		[h3offset],
		[h3percent],
		[h3shortratefrac],
		[h3shortrateint],
		[h4longratefrac],
		[h4longrateint],
		[h4mark],
		[h4offset],
		[h4percent],
		[h4shortratefrac],
		[h4shortrateint],
		[h5longratefrac],
		[h5longrateint],
		[h5mark],
		[h5offset],
		[h5percent],
		[h5shortratefrac],
		[h5shortrateint],
		[h6longratefrac],
		[h6longrateint],
		[h6mark],
		[h6offset],
		[h6percent],
		[h6shortratefrac],
		[h6shortrateint],
		[h7longratefrac],
		[h7longrateint],
		[h7mark],
		[h7offset],
		[h7percent],
		[h7shortratefrac],
		[h7shortrateint],
		[h8longratefrac],
		[h8longrateint],
		[h8mark],
		[h8offset],
		[h8percent],
		[h8shortratefrac],
		[h8shortrateint],
		[h9longratefrac],
		[h9longrateint],
		[h9mark],
		[h9offset],
		[h9percent],
		[h9shortratefrac],
		[h9shortrateint],
		[hedge],
		[lastmonthaccrued],
		[lastmonthcash],
		[lastmonthcomm],
		[lastmonthcost],
		[lastmonthcppaid],
		[lastmonthcprecv],
		[lastmonthdipaid],
		[lastmonthdirecv],
		[lastmonthmark],
		[lastmonthpos],
		[lastmonthreal],
		[lastmonthsecfee],
		[lastmonthstart],
		[lastmonthtktcharge],
		[lastyearaccured],
		[lastyearcash],
		[lastyearcomm],
		[lastyearcost],
		[lastyearcppaid],
		[lastyearcprecv],
		[lastyeardipaid],
		[lastyeardirecv],
		[lastyearmark],
		[lastyearpos],
		[lastyearreal],
		[lastyearsecfee],
		[lastyearstart],
		[lastyeartktcharge],
		[longrate],
		[mark],
		[monthaccrued],
		[monthcash],
		[monthcomm],
		[monthcost],
		[monthcppaid],
		[monthcprecv],
		[monthdipaid],
		[monthdirecv],
		[monthmark],
		[monthpos],
		[monthreal],
		[monthsecfee],
		[monthstart],
		[monthtktcharge],
		[openaccrued],
		[opencash],
		[opencomm],
		[opencost],
		[opencppaid],
		[opencprecv],
		[opendipaid],
		[opendirecv],
		[openmark],
		[openpos],
		[openreal],
		[opensecfee],
		[openstart],
		[opentktcharge],
		[ratio],
		[shortrate],
		[shortratecode],
		[strategy],
		[symbol],
		@NullDateTime,
		@CurrentDateTime,
		[yearaccrued],
		[yearcash],
		[yearcomm],
		[yearcost],
		[yearcppaid],
		[yearcprecv],
		[yeardipaid],
		[yeardirecv],
		[yearmark],
		[yearpos],
		[yearreal],
		[yearsecfee],
		[yearstart],
		[yeartktcharge]
	)


WHEN MATCHED AND
(
	([ts_end] = @NullDateTime OR ([ts_end] IS NULL AND @NullDateTime IS NULL))
)
AND
(
	([target].[currency] <> [source].[currency] OR ([target].[currency] IS NULL AND [source].[currency] IS NOT NULL) OR ([target].[currency] IS NOT NULL AND [source].[currency] IS NULL)) OR
	([target].[dayaccrued] <> [source].[dayaccrued] OR ([target].[dayaccrued] IS NULL AND [source].[dayaccrued] IS NOT NULL) OR ([target].[dayaccrued] IS NOT NULL AND [source].[dayaccrued] IS NULL)) OR
	([target].[daycash] <> [source].[daycash] OR ([target].[daycash] IS NULL AND [source].[daycash] IS NOT NULL) OR ([target].[daycash] IS NOT NULL AND [source].[daycash] IS NULL)) OR
	([target].[daycomm] <> [source].[daycomm] OR ([target].[daycomm] IS NULL AND [source].[daycomm] IS NOT NULL) OR ([target].[daycomm] IS NOT NULL AND [source].[daycomm] IS NULL)) OR
	([target].[daycost] <> [source].[daycost] OR ([target].[daycost] IS NULL AND [source].[daycost] IS NOT NULL) OR ([target].[daycost] IS NOT NULL AND [source].[daycost] IS NULL)) OR
	([target].[daycppaid] <> [source].[daycppaid] OR ([target].[daycppaid] IS NULL AND [source].[daycppaid] IS NOT NULL) OR ([target].[daycppaid] IS NOT NULL AND [source].[daycppaid] IS NULL)) OR
	([target].[daycprecv] <> [source].[daycprecv] OR ([target].[daycprecv] IS NULL AND [source].[daycprecv] IS NOT NULL) OR ([target].[daycprecv] IS NOT NULL AND [source].[daycprecv] IS NULL)) OR
	([target].[daydipaid] <> [source].[daydipaid] OR ([target].[daydipaid] IS NULL AND [source].[daydipaid] IS NOT NULL) OR ([target].[daydipaid] IS NOT NULL AND [source].[daydipaid] IS NULL)) OR
	([target].[daydirecv] <> [source].[daydirecv] OR ([target].[daydirecv] IS NULL AND [source].[daydirecv] IS NOT NULL) OR ([target].[daydirecv] IS NOT NULL AND [source].[daydirecv] IS NULL)) OR
	([target].[daymark] <> [source].[daymark] OR ([target].[daymark] IS NULL AND [source].[daymark] IS NOT NULL) OR ([target].[daymark] IS NOT NULL AND [source].[daymark] IS NULL)) OR
	([target].[daypos] <> [source].[daypos] OR ([target].[daypos] IS NULL AND [source].[daypos] IS NOT NULL) OR ([target].[daypos] IS NOT NULL AND [source].[daypos] IS NULL)) OR
	([target].[dayreal] <> [source].[dayreal] OR ([target].[dayreal] IS NULL AND [source].[dayreal] IS NOT NULL) OR ([target].[dayreal] IS NOT NULL AND [source].[dayreal] IS NULL)) OR
	([target].[daysecfee] <> [source].[daysecfee] OR ([target].[daysecfee] IS NULL AND [source].[daysecfee] IS NOT NULL) OR ([target].[daysecfee] IS NOT NULL AND [source].[daysecfee] IS NULL)) OR
	([target].[daystart] <> [source].[daystart] OR ([target].[daystart] IS NULL AND [source].[daystart] IS NOT NULL) OR ([target].[daystart] IS NOT NULL AND [source].[daystart] IS NULL)) OR
	([target].[daytktcharge] <> [source].[daytktcharge] OR ([target].[daytktcharge] IS NULL AND [source].[daytktcharge] IS NOT NULL) OR ([target].[daytktcharge] IS NOT NULL AND [source].[daytktcharge] IS NULL)) OR
	([target].[fxrate] <> [source].[fxrate] OR ([target].[fxrate] IS NULL AND [source].[fxrate] IS NOT NULL) OR ([target].[fxrate] IS NOT NULL AND [source].[fxrate] IS NULL)) OR
	([target].[h10longratefrac] <> [source].[h10longratefrac] OR ([target].[h10longratefrac] IS NULL AND [source].[h10longratefrac] IS NOT NULL) OR ([target].[h10longratefrac] IS NOT NULL AND [source].[h10longratefrac] IS NULL)) OR
	([target].[h10longrateint] <> [source].[h10longrateint] OR ([target].[h10longrateint] IS NULL AND [source].[h10longrateint] IS NOT NULL) OR ([target].[h10longrateint] IS NOT NULL AND [source].[h10longrateint] IS NULL)) OR
	([target].[h10mark] <> [source].[h10mark] OR ([target].[h10mark] IS NULL AND [source].[h10mark] IS NOT NULL) OR ([target].[h10mark] IS NOT NULL AND [source].[h10mark] IS NULL)) OR
	([target].[h10offset] <> [source].[h10offset] OR ([target].[h10offset] IS NULL AND [source].[h10offset] IS NOT NULL) OR ([target].[h10offset] IS NOT NULL AND [source].[h10offset] IS NULL)) OR
	([target].[h10percent] <> [source].[h10percent] OR ([target].[h10percent] IS NULL AND [source].[h10percent] IS NOT NULL) OR ([target].[h10percent] IS NOT NULL AND [source].[h10percent] IS NULL)) OR
	([target].[h10shortratefrac] <> [source].[h10shortratefrac] OR ([target].[h10shortratefrac] IS NULL AND [source].[h10shortratefrac] IS NOT NULL) OR ([target].[h10shortratefrac] IS NOT NULL AND [source].[h10shortratefrac] IS NULL)) OR
	([target].[h10shortrateint] <> [source].[h10shortrateint] OR ([target].[h10shortrateint] IS NULL AND [source].[h10shortrateint] IS NOT NULL) OR ([target].[h10shortrateint] IS NOT NULL AND [source].[h10shortrateint] IS NULL)) OR
	([target].[h11longratefrac] <> [source].[h11longratefrac] OR ([target].[h11longratefrac] IS NULL AND [source].[h11longratefrac] IS NOT NULL) OR ([target].[h11longratefrac] IS NOT NULL AND [source].[h11longratefrac] IS NULL)) OR
	([target].[h11longrateint] <> [source].[h11longrateint] OR ([target].[h11longrateint] IS NULL AND [source].[h11longrateint] IS NOT NULL) OR ([target].[h11longrateint] IS NOT NULL AND [source].[h11longrateint] IS NULL)) OR
	([target].[h11mark] <> [source].[h11mark] OR ([target].[h11mark] IS NULL AND [source].[h11mark] IS NOT NULL) OR ([target].[h11mark] IS NOT NULL AND [source].[h11mark] IS NULL)) OR
	([target].[h11offset] <> [source].[h11offset] OR ([target].[h11offset] IS NULL AND [source].[h11offset] IS NOT NULL) OR ([target].[h11offset] IS NOT NULL AND [source].[h11offset] IS NULL)) OR
	([target].[h11percent] <> [source].[h11percent] OR ([target].[h11percent] IS NULL AND [source].[h11percent] IS NOT NULL) OR ([target].[h11percent] IS NOT NULL AND [source].[h11percent] IS NULL)) OR
	([target].[h11shortratefrac] <> [source].[h11shortratefrac] OR ([target].[h11shortratefrac] IS NULL AND [source].[h11shortratefrac] IS NOT NULL) OR ([target].[h11shortratefrac] IS NOT NULL AND [source].[h11shortratefrac] IS NULL)) OR
	([target].[h11shortrateint] <> [source].[h11shortrateint] OR ([target].[h11shortrateint] IS NULL AND [source].[h11shortrateint] IS NOT NULL) OR ([target].[h11shortrateint] IS NOT NULL AND [source].[h11shortrateint] IS NULL)) OR
	([target].[h12longratefrac] <> [source].[h12longratefrac] OR ([target].[h12longratefrac] IS NULL AND [source].[h12longratefrac] IS NOT NULL) OR ([target].[h12longratefrac] IS NOT NULL AND [source].[h12longratefrac] IS NULL)) OR
	([target].[h12longrateint] <> [source].[h12longrateint] OR ([target].[h12longrateint] IS NULL AND [source].[h12longrateint] IS NOT NULL) OR ([target].[h12longrateint] IS NOT NULL AND [source].[h12longrateint] IS NULL)) OR
	([target].[h12mark] <> [source].[h12mark] OR ([target].[h12mark] IS NULL AND [source].[h12mark] IS NOT NULL) OR ([target].[h12mark] IS NOT NULL AND [source].[h12mark] IS NULL)) OR
	([target].[h12offset] <> [source].[h12offset] OR ([target].[h12offset] IS NULL AND [source].[h12offset] IS NOT NULL) OR ([target].[h12offset] IS NOT NULL AND [source].[h12offset] IS NULL)) OR
	([target].[h12percent] <> [source].[h12percent] OR ([target].[h12percent] IS NULL AND [source].[h12percent] IS NOT NULL) OR ([target].[h12percent] IS NOT NULL AND [source].[h12percent] IS NULL)) OR
	([target].[h12shortratefrac] <> [source].[h12shortratefrac] OR ([target].[h12shortratefrac] IS NULL AND [source].[h12shortratefrac] IS NOT NULL) OR ([target].[h12shortratefrac] IS NOT NULL AND [source].[h12shortratefrac] IS NULL)) OR
	([target].[h12shortrateint] <> [source].[h12shortrateint] OR ([target].[h12shortrateint] IS NULL AND [source].[h12shortrateint] IS NOT NULL) OR ([target].[h12shortrateint] IS NOT NULL AND [source].[h12shortrateint] IS NULL)) OR
	([target].[h13longratefrac] <> [source].[h13longratefrac] OR ([target].[h13longratefrac] IS NULL AND [source].[h13longratefrac] IS NOT NULL) OR ([target].[h13longratefrac] IS NOT NULL AND [source].[h13longratefrac] IS NULL)) OR
	([target].[h13longrateint] <> [source].[h13longrateint] OR ([target].[h13longrateint] IS NULL AND [source].[h13longrateint] IS NOT NULL) OR ([target].[h13longrateint] IS NOT NULL AND [source].[h13longrateint] IS NULL)) OR
	([target].[h13mark] <> [source].[h13mark] OR ([target].[h13mark] IS NULL AND [source].[h13mark] IS NOT NULL) OR ([target].[h13mark] IS NOT NULL AND [source].[h13mark] IS NULL)) OR
	([target].[h13offset] <> [source].[h13offset] OR ([target].[h13offset] IS NULL AND [source].[h13offset] IS NOT NULL) OR ([target].[h13offset] IS NOT NULL AND [source].[h13offset] IS NULL)) OR
	([target].[h13percent] <> [source].[h13percent] OR ([target].[h13percent] IS NULL AND [source].[h13percent] IS NOT NULL) OR ([target].[h13percent] IS NOT NULL AND [source].[h13percent] IS NULL)) OR
	([target].[h13shortratefrac] <> [source].[h13shortratefrac] OR ([target].[h13shortratefrac] IS NULL AND [source].[h13shortratefrac] IS NOT NULL) OR ([target].[h13shortratefrac] IS NOT NULL AND [source].[h13shortratefrac] IS NULL)) OR
	([target].[h13shortrateint] <> [source].[h13shortrateint] OR ([target].[h13shortrateint] IS NULL AND [source].[h13shortrateint] IS NOT NULL) OR ([target].[h13shortrateint] IS NOT NULL AND [source].[h13shortrateint] IS NULL)) OR
	([target].[h14longratefrac] <> [source].[h14longratefrac] OR ([target].[h14longratefrac] IS NULL AND [source].[h14longratefrac] IS NOT NULL) OR ([target].[h14longratefrac] IS NOT NULL AND [source].[h14longratefrac] IS NULL)) OR
	([target].[h14longrateint] <> [source].[h14longrateint] OR ([target].[h14longrateint] IS NULL AND [source].[h14longrateint] IS NOT NULL) OR ([target].[h14longrateint] IS NOT NULL AND [source].[h14longrateint] IS NULL)) OR
	([target].[h14mark] <> [source].[h14mark] OR ([target].[h14mark] IS NULL AND [source].[h14mark] IS NOT NULL) OR ([target].[h14mark] IS NOT NULL AND [source].[h14mark] IS NULL)) OR
	([target].[h14offset] <> [source].[h14offset] OR ([target].[h14offset] IS NULL AND [source].[h14offset] IS NOT NULL) OR ([target].[h14offset] IS NOT NULL AND [source].[h14offset] IS NULL)) OR
	([target].[h14percent] <> [source].[h14percent] OR ([target].[h14percent] IS NULL AND [source].[h14percent] IS NOT NULL) OR ([target].[h14percent] IS NOT NULL AND [source].[h14percent] IS NULL)) OR
	([target].[h14shortratefrac] <> [source].[h14shortratefrac] OR ([target].[h14shortratefrac] IS NULL AND [source].[h14shortratefrac] IS NOT NULL) OR ([target].[h14shortratefrac] IS NOT NULL AND [source].[h14shortratefrac] IS NULL)) OR
	([target].[h14shortrateint] <> [source].[h14shortrateint] OR ([target].[h14shortrateint] IS NULL AND [source].[h14shortrateint] IS NOT NULL) OR ([target].[h14shortrateint] IS NOT NULL AND [source].[h14shortrateint] IS NULL)) OR
	([target].[h15longratefrac] <> [source].[h15longratefrac] OR ([target].[h15longratefrac] IS NULL AND [source].[h15longratefrac] IS NOT NULL) OR ([target].[h15longratefrac] IS NOT NULL AND [source].[h15longratefrac] IS NULL)) OR
	([target].[h15longrateint] <> [source].[h15longrateint] OR ([target].[h15longrateint] IS NULL AND [source].[h15longrateint] IS NOT NULL) OR ([target].[h15longrateint] IS NOT NULL AND [source].[h15longrateint] IS NULL)) OR
	([target].[h15mark] <> [source].[h15mark] OR ([target].[h15mark] IS NULL AND [source].[h15mark] IS NOT NULL) OR ([target].[h15mark] IS NOT NULL AND [source].[h15mark] IS NULL)) OR
	([target].[h15offset] <> [source].[h15offset] OR ([target].[h15offset] IS NULL AND [source].[h15offset] IS NOT NULL) OR ([target].[h15offset] IS NOT NULL AND [source].[h15offset] IS NULL)) OR
	([target].[h15percent] <> [source].[h15percent] OR ([target].[h15percent] IS NULL AND [source].[h15percent] IS NOT NULL) OR ([target].[h15percent] IS NOT NULL AND [source].[h15percent] IS NULL)) OR
	([target].[h15shortratefrac] <> [source].[h15shortratefrac] OR ([target].[h15shortratefrac] IS NULL AND [source].[h15shortratefrac] IS NOT NULL) OR ([target].[h15shortratefrac] IS NOT NULL AND [source].[h15shortratefrac] IS NULL)) OR
	([target].[h15shortrateint] <> [source].[h15shortrateint] OR ([target].[h15shortrateint] IS NULL AND [source].[h15shortrateint] IS NOT NULL) OR ([target].[h15shortrateint] IS NOT NULL AND [source].[h15shortrateint] IS NULL)) OR
	([target].[h16longratefrac] <> [source].[h16longratefrac] OR ([target].[h16longratefrac] IS NULL AND [source].[h16longratefrac] IS NOT NULL) OR ([target].[h16longratefrac] IS NOT NULL AND [source].[h16longratefrac] IS NULL)) OR
	([target].[h16longrateint] <> [source].[h16longrateint] OR ([target].[h16longrateint] IS NULL AND [source].[h16longrateint] IS NOT NULL) OR ([target].[h16longrateint] IS NOT NULL AND [source].[h16longrateint] IS NULL)) OR
	([target].[h16mark] <> [source].[h16mark] OR ([target].[h16mark] IS NULL AND [source].[h16mark] IS NOT NULL) OR ([target].[h16mark] IS NOT NULL AND [source].[h16mark] IS NULL)) OR
	([target].[h16offset] <> [source].[h16offset] OR ([target].[h16offset] IS NULL AND [source].[h16offset] IS NOT NULL) OR ([target].[h16offset] IS NOT NULL AND [source].[h16offset] IS NULL)) OR
	([target].[h16percent] <> [source].[h16percent] OR ([target].[h16percent] IS NULL AND [source].[h16percent] IS NOT NULL) OR ([target].[h16percent] IS NOT NULL AND [source].[h16percent] IS NULL)) OR
	([target].[h16shortratefrac] <> [source].[h16shortratefrac] OR ([target].[h16shortratefrac] IS NULL AND [source].[h16shortratefrac] IS NOT NULL) OR ([target].[h16shortratefrac] IS NOT NULL AND [source].[h16shortratefrac] IS NULL)) OR
	([target].[h16shortrateint] <> [source].[h16shortrateint] OR ([target].[h16shortrateint] IS NULL AND [source].[h16shortrateint] IS NOT NULL) OR ([target].[h16shortrateint] IS NOT NULL AND [source].[h16shortrateint] IS NULL)) OR
	([target].[h1longratefrac] <> [source].[h1longratefrac] OR ([target].[h1longratefrac] IS NULL AND [source].[h1longratefrac] IS NOT NULL) OR ([target].[h1longratefrac] IS NOT NULL AND [source].[h1longratefrac] IS NULL)) OR
	([target].[h1longrateint] <> [source].[h1longrateint] OR ([target].[h1longrateint] IS NULL AND [source].[h1longrateint] IS NOT NULL) OR ([target].[h1longrateint] IS NOT NULL AND [source].[h1longrateint] IS NULL)) OR
	([target].[h1mark] <> [source].[h1mark] OR ([target].[h1mark] IS NULL AND [source].[h1mark] IS NOT NULL) OR ([target].[h1mark] IS NOT NULL AND [source].[h1mark] IS NULL)) OR
	([target].[h1offset] <> [source].[h1offset] OR ([target].[h1offset] IS NULL AND [source].[h1offset] IS NOT NULL) OR ([target].[h1offset] IS NOT NULL AND [source].[h1offset] IS NULL)) OR
	([target].[h1percent] <> [source].[h1percent] OR ([target].[h1percent] IS NULL AND [source].[h1percent] IS NOT NULL) OR ([target].[h1percent] IS NOT NULL AND [source].[h1percent] IS NULL)) OR
	([target].[h1shortratefrac] <> [source].[h1shortratefrac] OR ([target].[h1shortratefrac] IS NULL AND [source].[h1shortratefrac] IS NOT NULL) OR ([target].[h1shortratefrac] IS NOT NULL AND [source].[h1shortratefrac] IS NULL)) OR
	([target].[h1shortrateint] <> [source].[h1shortrateint] OR ([target].[h1shortrateint] IS NULL AND [source].[h1shortrateint] IS NOT NULL) OR ([target].[h1shortrateint] IS NOT NULL AND [source].[h1shortrateint] IS NULL)) OR
	([target].[h2longratefrac] <> [source].[h2longratefrac] OR ([target].[h2longratefrac] IS NULL AND [source].[h2longratefrac] IS NOT NULL) OR ([target].[h2longratefrac] IS NOT NULL AND [source].[h2longratefrac] IS NULL)) OR
	([target].[h2longrateint] <> [source].[h2longrateint] OR ([target].[h2longrateint] IS NULL AND [source].[h2longrateint] IS NOT NULL) OR ([target].[h2longrateint] IS NOT NULL AND [source].[h2longrateint] IS NULL)) OR
	([target].[h2mark] <> [source].[h2mark] OR ([target].[h2mark] IS NULL AND [source].[h2mark] IS NOT NULL) OR ([target].[h2mark] IS NOT NULL AND [source].[h2mark] IS NULL)) OR
	([target].[h2offset] <> [source].[h2offset] OR ([target].[h2offset] IS NULL AND [source].[h2offset] IS NOT NULL) OR ([target].[h2offset] IS NOT NULL AND [source].[h2offset] IS NULL)) OR
	([target].[h2percent] <> [source].[h2percent] OR ([target].[h2percent] IS NULL AND [source].[h2percent] IS NOT NULL) OR ([target].[h2percent] IS NOT NULL AND [source].[h2percent] IS NULL)) OR
	([target].[h2shortratefrac] <> [source].[h2shortratefrac] OR ([target].[h2shortratefrac] IS NULL AND [source].[h2shortratefrac] IS NOT NULL) OR ([target].[h2shortratefrac] IS NOT NULL AND [source].[h2shortratefrac] IS NULL)) OR
	([target].[h2shortrateint] <> [source].[h2shortrateint] OR ([target].[h2shortrateint] IS NULL AND [source].[h2shortrateint] IS NOT NULL) OR ([target].[h2shortrateint] IS NOT NULL AND [source].[h2shortrateint] IS NULL)) OR
	([target].[h3longratefrac] <> [source].[h3longratefrac] OR ([target].[h3longratefrac] IS NULL AND [source].[h3longratefrac] IS NOT NULL) OR ([target].[h3longratefrac] IS NOT NULL AND [source].[h3longratefrac] IS NULL)) OR
	([target].[h3longrateint] <> [source].[h3longrateint] OR ([target].[h3longrateint] IS NULL AND [source].[h3longrateint] IS NOT NULL) OR ([target].[h3longrateint] IS NOT NULL AND [source].[h3longrateint] IS NULL)) OR
	([target].[h3mark] <> [source].[h3mark] OR ([target].[h3mark] IS NULL AND [source].[h3mark] IS NOT NULL) OR ([target].[h3mark] IS NOT NULL AND [source].[h3mark] IS NULL)) OR
	([target].[h3offset] <> [source].[h3offset] OR ([target].[h3offset] IS NULL AND [source].[h3offset] IS NOT NULL) OR ([target].[h3offset] IS NOT NULL AND [source].[h3offset] IS NULL)) OR
	([target].[h3percent] <> [source].[h3percent] OR ([target].[h3percent] IS NULL AND [source].[h3percent] IS NOT NULL) OR ([target].[h3percent] IS NOT NULL AND [source].[h3percent] IS NULL)) OR
	([target].[h3shortratefrac] <> [source].[h3shortratefrac] OR ([target].[h3shortratefrac] IS NULL AND [source].[h3shortratefrac] IS NOT NULL) OR ([target].[h3shortratefrac] IS NOT NULL AND [source].[h3shortratefrac] IS NULL)) OR
	([target].[h3shortrateint] <> [source].[h3shortrateint] OR ([target].[h3shortrateint] IS NULL AND [source].[h3shortrateint] IS NOT NULL) OR ([target].[h3shortrateint] IS NOT NULL AND [source].[h3shortrateint] IS NULL)) OR
	([target].[h4longratefrac] <> [source].[h4longratefrac] OR ([target].[h4longratefrac] IS NULL AND [source].[h4longratefrac] IS NOT NULL) OR ([target].[h4longratefrac] IS NOT NULL AND [source].[h4longratefrac] IS NULL)) OR
	([target].[h4longrateint] <> [source].[h4longrateint] OR ([target].[h4longrateint] IS NULL AND [source].[h4longrateint] IS NOT NULL) OR ([target].[h4longrateint] IS NOT NULL AND [source].[h4longrateint] IS NULL)) OR
	([target].[h4mark] <> [source].[h4mark] OR ([target].[h4mark] IS NULL AND [source].[h4mark] IS NOT NULL) OR ([target].[h4mark] IS NOT NULL AND [source].[h4mark] IS NULL)) OR
	([target].[h4offset] <> [source].[h4offset] OR ([target].[h4offset] IS NULL AND [source].[h4offset] IS NOT NULL) OR ([target].[h4offset] IS NOT NULL AND [source].[h4offset] IS NULL)) OR
	([target].[h4percent] <> [source].[h4percent] OR ([target].[h4percent] IS NULL AND [source].[h4percent] IS NOT NULL) OR ([target].[h4percent] IS NOT NULL AND [source].[h4percent] IS NULL)) OR
	([target].[h4shortratefrac] <> [source].[h4shortratefrac] OR ([target].[h4shortratefrac] IS NULL AND [source].[h4shortratefrac] IS NOT NULL) OR ([target].[h4shortratefrac] IS NOT NULL AND [source].[h4shortratefrac] IS NULL)) OR
	([target].[h4shortrateint] <> [source].[h4shortrateint] OR ([target].[h4shortrateint] IS NULL AND [source].[h4shortrateint] IS NOT NULL) OR ([target].[h4shortrateint] IS NOT NULL AND [source].[h4shortrateint] IS NULL)) OR
	([target].[h5longratefrac] <> [source].[h5longratefrac] OR ([target].[h5longratefrac] IS NULL AND [source].[h5longratefrac] IS NOT NULL) OR ([target].[h5longratefrac] IS NOT NULL AND [source].[h5longratefrac] IS NULL)) OR
	([target].[h5longrateint] <> [source].[h5longrateint] OR ([target].[h5longrateint] IS NULL AND [source].[h5longrateint] IS NOT NULL) OR ([target].[h5longrateint] IS NOT NULL AND [source].[h5longrateint] IS NULL)) OR
	([target].[h5mark] <> [source].[h5mark] OR ([target].[h5mark] IS NULL AND [source].[h5mark] IS NOT NULL) OR ([target].[h5mark] IS NOT NULL AND [source].[h5mark] IS NULL)) OR
	([target].[h5offset] <> [source].[h5offset] OR ([target].[h5offset] IS NULL AND [source].[h5offset] IS NOT NULL) OR ([target].[h5offset] IS NOT NULL AND [source].[h5offset] IS NULL)) OR
	([target].[h5percent] <> [source].[h5percent] OR ([target].[h5percent] IS NULL AND [source].[h5percent] IS NOT NULL) OR ([target].[h5percent] IS NOT NULL AND [source].[h5percent] IS NULL)) OR
	([target].[h5shortratefrac] <> [source].[h5shortratefrac] OR ([target].[h5shortratefrac] IS NULL AND [source].[h5shortratefrac] IS NOT NULL) OR ([target].[h5shortratefrac] IS NOT NULL AND [source].[h5shortratefrac] IS NULL)) OR
	([target].[h5shortrateint] <> [source].[h5shortrateint] OR ([target].[h5shortrateint] IS NULL AND [source].[h5shortrateint] IS NOT NULL) OR ([target].[h5shortrateint] IS NOT NULL AND [source].[h5shortrateint] IS NULL)) OR
	([target].[h6longratefrac] <> [source].[h6longratefrac] OR ([target].[h6longratefrac] IS NULL AND [source].[h6longratefrac] IS NOT NULL) OR ([target].[h6longratefrac] IS NOT NULL AND [source].[h6longratefrac] IS NULL)) OR
	([target].[h6longrateint] <> [source].[h6longrateint] OR ([target].[h6longrateint] IS NULL AND [source].[h6longrateint] IS NOT NULL) OR ([target].[h6longrateint] IS NOT NULL AND [source].[h6longrateint] IS NULL)) OR
	([target].[h6mark] <> [source].[h6mark] OR ([target].[h6mark] IS NULL AND [source].[h6mark] IS NOT NULL) OR ([target].[h6mark] IS NOT NULL AND [source].[h6mark] IS NULL)) OR
	([target].[h6offset] <> [source].[h6offset] OR ([target].[h6offset] IS NULL AND [source].[h6offset] IS NOT NULL) OR ([target].[h6offset] IS NOT NULL AND [source].[h6offset] IS NULL)) OR
	([target].[h6percent] <> [source].[h6percent] OR ([target].[h6percent] IS NULL AND [source].[h6percent] IS NOT NULL) OR ([target].[h6percent] IS NOT NULL AND [source].[h6percent] IS NULL)) OR
	([target].[h6shortratefrac] <> [source].[h6shortratefrac] OR ([target].[h6shortratefrac] IS NULL AND [source].[h6shortratefrac] IS NOT NULL) OR ([target].[h6shortratefrac] IS NOT NULL AND [source].[h6shortratefrac] IS NULL)) OR
	([target].[h6shortrateint] <> [source].[h6shortrateint] OR ([target].[h6shortrateint] IS NULL AND [source].[h6shortrateint] IS NOT NULL) OR ([target].[h6shortrateint] IS NOT NULL AND [source].[h6shortrateint] IS NULL)) OR
	([target].[h7longratefrac] <> [source].[h7longratefrac] OR ([target].[h7longratefrac] IS NULL AND [source].[h7longratefrac] IS NOT NULL) OR ([target].[h7longratefrac] IS NOT NULL AND [source].[h7longratefrac] IS NULL)) OR
	([target].[h7longrateint] <> [source].[h7longrateint] OR ([target].[h7longrateint] IS NULL AND [source].[h7longrateint] IS NOT NULL) OR ([target].[h7longrateint] IS NOT NULL AND [source].[h7longrateint] IS NULL)) OR
	([target].[h7mark] <> [source].[h7mark] OR ([target].[h7mark] IS NULL AND [source].[h7mark] IS NOT NULL) OR ([target].[h7mark] IS NOT NULL AND [source].[h7mark] IS NULL)) OR
	([target].[h7offset] <> [source].[h7offset] OR ([target].[h7offset] IS NULL AND [source].[h7offset] IS NOT NULL) OR ([target].[h7offset] IS NOT NULL AND [source].[h7offset] IS NULL)) OR
	([target].[h7percent] <> [source].[h7percent] OR ([target].[h7percent] IS NULL AND [source].[h7percent] IS NOT NULL) OR ([target].[h7percent] IS NOT NULL AND [source].[h7percent] IS NULL)) OR
	([target].[h7shortratefrac] <> [source].[h7shortratefrac] OR ([target].[h7shortratefrac] IS NULL AND [source].[h7shortratefrac] IS NOT NULL) OR ([target].[h7shortratefrac] IS NOT NULL AND [source].[h7shortratefrac] IS NULL)) OR
	([target].[h7shortrateint] <> [source].[h7shortrateint] OR ([target].[h7shortrateint] IS NULL AND [source].[h7shortrateint] IS NOT NULL) OR ([target].[h7shortrateint] IS NOT NULL AND [source].[h7shortrateint] IS NULL)) OR
	([target].[h8longratefrac] <> [source].[h8longratefrac] OR ([target].[h8longratefrac] IS NULL AND [source].[h8longratefrac] IS NOT NULL) OR ([target].[h8longratefrac] IS NOT NULL AND [source].[h8longratefrac] IS NULL)) OR
	([target].[h8longrateint] <> [source].[h8longrateint] OR ([target].[h8longrateint] IS NULL AND [source].[h8longrateint] IS NOT NULL) OR ([target].[h8longrateint] IS NOT NULL AND [source].[h8longrateint] IS NULL)) OR
	([target].[h8mark] <> [source].[h8mark] OR ([target].[h8mark] IS NULL AND [source].[h8mark] IS NOT NULL) OR ([target].[h8mark] IS NOT NULL AND [source].[h8mark] IS NULL)) OR
	([target].[h8offset] <> [source].[h8offset] OR ([target].[h8offset] IS NULL AND [source].[h8offset] IS NOT NULL) OR ([target].[h8offset] IS NOT NULL AND [source].[h8offset] IS NULL)) OR
	([target].[h8percent] <> [source].[h8percent] OR ([target].[h8percent] IS NULL AND [source].[h8percent] IS NOT NULL) OR ([target].[h8percent] IS NOT NULL AND [source].[h8percent] IS NULL)) OR
	([target].[h8shortratefrac] <> [source].[h8shortratefrac] OR ([target].[h8shortratefrac] IS NULL AND [source].[h8shortratefrac] IS NOT NULL) OR ([target].[h8shortratefrac] IS NOT NULL AND [source].[h8shortratefrac] IS NULL)) OR
	([target].[h8shortrateint] <> [source].[h8shortrateint] OR ([target].[h8shortrateint] IS NULL AND [source].[h8shortrateint] IS NOT NULL) OR ([target].[h8shortrateint] IS NOT NULL AND [source].[h8shortrateint] IS NULL)) OR
	([target].[h9longratefrac] <> [source].[h9longratefrac] OR ([target].[h9longratefrac] IS NULL AND [source].[h9longratefrac] IS NOT NULL) OR ([target].[h9longratefrac] IS NOT NULL AND [source].[h9longratefrac] IS NULL)) OR
	([target].[h9longrateint] <> [source].[h9longrateint] OR ([target].[h9longrateint] IS NULL AND [source].[h9longrateint] IS NOT NULL) OR ([target].[h9longrateint] IS NOT NULL AND [source].[h9longrateint] IS NULL)) OR
	([target].[h9mark] <> [source].[h9mark] OR ([target].[h9mark] IS NULL AND [source].[h9mark] IS NOT NULL) OR ([target].[h9mark] IS NOT NULL AND [source].[h9mark] IS NULL)) OR
	([target].[h9offset] <> [source].[h9offset] OR ([target].[h9offset] IS NULL AND [source].[h9offset] IS NOT NULL) OR ([target].[h9offset] IS NOT NULL AND [source].[h9offset] IS NULL)) OR
	([target].[h9percent] <> [source].[h9percent] OR ([target].[h9percent] IS NULL AND [source].[h9percent] IS NOT NULL) OR ([target].[h9percent] IS NOT NULL AND [source].[h9percent] IS NULL)) OR
	([target].[h9shortratefrac] <> [source].[h9shortratefrac] OR ([target].[h9shortratefrac] IS NULL AND [source].[h9shortratefrac] IS NOT NULL) OR ([target].[h9shortratefrac] IS NOT NULL AND [source].[h9shortratefrac] IS NULL)) OR
	([target].[h9shortrateint] <> [source].[h9shortrateint] OR ([target].[h9shortrateint] IS NULL AND [source].[h9shortrateint] IS NOT NULL) OR ([target].[h9shortrateint] IS NOT NULL AND [source].[h9shortrateint] IS NULL)) OR
	([target].[hedge] <> [source].[hedge] OR ([target].[hedge] IS NULL AND [source].[hedge] IS NOT NULL) OR ([target].[hedge] IS NOT NULL AND [source].[hedge] IS NULL)) OR
	([target].[lastmonthaccrued] <> [source].[lastmonthaccrued] OR ([target].[lastmonthaccrued] IS NULL AND [source].[lastmonthaccrued] IS NOT NULL) OR ([target].[lastmonthaccrued] IS NOT NULL AND [source].[lastmonthaccrued] IS NULL)) OR
	([target].[lastmonthcash] <> [source].[lastmonthcash] OR ([target].[lastmonthcash] IS NULL AND [source].[lastmonthcash] IS NOT NULL) OR ([target].[lastmonthcash] IS NOT NULL AND [source].[lastmonthcash] IS NULL)) OR
	([target].[lastmonthcomm] <> [source].[lastmonthcomm] OR ([target].[lastmonthcomm] IS NULL AND [source].[lastmonthcomm] IS NOT NULL) OR ([target].[lastmonthcomm] IS NOT NULL AND [source].[lastmonthcomm] IS NULL)) OR
	([target].[lastmonthcost] <> [source].[lastmonthcost] OR ([target].[lastmonthcost] IS NULL AND [source].[lastmonthcost] IS NOT NULL) OR ([target].[lastmonthcost] IS NOT NULL AND [source].[lastmonthcost] IS NULL)) OR
	([target].[lastmonthcppaid] <> [source].[lastmonthcppaid] OR ([target].[lastmonthcppaid] IS NULL AND [source].[lastmonthcppaid] IS NOT NULL) OR ([target].[lastmonthcppaid] IS NOT NULL AND [source].[lastmonthcppaid] IS NULL)) OR
	([target].[lastmonthcprecv] <> [source].[lastmonthcprecv] OR ([target].[lastmonthcprecv] IS NULL AND [source].[lastmonthcprecv] IS NOT NULL) OR ([target].[lastmonthcprecv] IS NOT NULL AND [source].[lastmonthcprecv] IS NULL)) OR
	([target].[lastmonthdipaid] <> [source].[lastmonthdipaid] OR ([target].[lastmonthdipaid] IS NULL AND [source].[lastmonthdipaid] IS NOT NULL) OR ([target].[lastmonthdipaid] IS NOT NULL AND [source].[lastmonthdipaid] IS NULL)) OR
	([target].[lastmonthdirecv] <> [source].[lastmonthdirecv] OR ([target].[lastmonthdirecv] IS NULL AND [source].[lastmonthdirecv] IS NOT NULL) OR ([target].[lastmonthdirecv] IS NOT NULL AND [source].[lastmonthdirecv] IS NULL)) OR
	([target].[lastmonthmark] <> [source].[lastmonthmark] OR ([target].[lastmonthmark] IS NULL AND [source].[lastmonthmark] IS NOT NULL) OR ([target].[lastmonthmark] IS NOT NULL AND [source].[lastmonthmark] IS NULL)) OR
	([target].[lastmonthpos] <> [source].[lastmonthpos] OR ([target].[lastmonthpos] IS NULL AND [source].[lastmonthpos] IS NOT NULL) OR ([target].[lastmonthpos] IS NOT NULL AND [source].[lastmonthpos] IS NULL)) OR
	([target].[lastmonthreal] <> [source].[lastmonthreal] OR ([target].[lastmonthreal] IS NULL AND [source].[lastmonthreal] IS NOT NULL) OR ([target].[lastmonthreal] IS NOT NULL AND [source].[lastmonthreal] IS NULL)) OR
	([target].[lastmonthsecfee] <> [source].[lastmonthsecfee] OR ([target].[lastmonthsecfee] IS NULL AND [source].[lastmonthsecfee] IS NOT NULL) OR ([target].[lastmonthsecfee] IS NOT NULL AND [source].[lastmonthsecfee] IS NULL)) OR
	([target].[lastmonthstart] <> [source].[lastmonthstart] OR ([target].[lastmonthstart] IS NULL AND [source].[lastmonthstart] IS NOT NULL) OR ([target].[lastmonthstart] IS NOT NULL AND [source].[lastmonthstart] IS NULL)) OR
	([target].[lastmonthtktcharge] <> [source].[lastmonthtktcharge] OR ([target].[lastmonthtktcharge] IS NULL AND [source].[lastmonthtktcharge] IS NOT NULL) OR ([target].[lastmonthtktcharge] IS NOT NULL AND [source].[lastmonthtktcharge] IS NULL)) OR
	([target].[lastyearaccured] <> [source].[lastyearaccured] OR ([target].[lastyearaccured] IS NULL AND [source].[lastyearaccured] IS NOT NULL) OR ([target].[lastyearaccured] IS NOT NULL AND [source].[lastyearaccured] IS NULL)) OR
	([target].[lastyearcash] <> [source].[lastyearcash] OR ([target].[lastyearcash] IS NULL AND [source].[lastyearcash] IS NOT NULL) OR ([target].[lastyearcash] IS NOT NULL AND [source].[lastyearcash] IS NULL)) OR
	([target].[lastyearcomm] <> [source].[lastyearcomm] OR ([target].[lastyearcomm] IS NULL AND [source].[lastyearcomm] IS NOT NULL) OR ([target].[lastyearcomm] IS NOT NULL AND [source].[lastyearcomm] IS NULL)) OR
	([target].[lastyearcost] <> [source].[lastyearcost] OR ([target].[lastyearcost] IS NULL AND [source].[lastyearcost] IS NOT NULL) OR ([target].[lastyearcost] IS NOT NULL AND [source].[lastyearcost] IS NULL)) OR
	([target].[lastyearcppaid] <> [source].[lastyearcppaid] OR ([target].[lastyearcppaid] IS NULL AND [source].[lastyearcppaid] IS NOT NULL) OR ([target].[lastyearcppaid] IS NOT NULL AND [source].[lastyearcppaid] IS NULL)) OR
	([target].[lastyearcprecv] <> [source].[lastyearcprecv] OR ([target].[lastyearcprecv] IS NULL AND [source].[lastyearcprecv] IS NOT NULL) OR ([target].[lastyearcprecv] IS NOT NULL AND [source].[lastyearcprecv] IS NULL)) OR
	([target].[lastyeardipaid] <> [source].[lastyeardipaid] OR ([target].[lastyeardipaid] IS NULL AND [source].[lastyeardipaid] IS NOT NULL) OR ([target].[lastyeardipaid] IS NOT NULL AND [source].[lastyeardipaid] IS NULL)) OR
	([target].[lastyeardirecv] <> [source].[lastyeardirecv] OR ([target].[lastyeardirecv] IS NULL AND [source].[lastyeardirecv] IS NOT NULL) OR ([target].[lastyeardirecv] IS NOT NULL AND [source].[lastyeardirecv] IS NULL)) OR
	([target].[lastyearmark] <> [source].[lastyearmark] OR ([target].[lastyearmark] IS NULL AND [source].[lastyearmark] IS NOT NULL) OR ([target].[lastyearmark] IS NOT NULL AND [source].[lastyearmark] IS NULL)) OR
	([target].[lastyearpos] <> [source].[lastyearpos] OR ([target].[lastyearpos] IS NULL AND [source].[lastyearpos] IS NOT NULL) OR ([target].[lastyearpos] IS NOT NULL AND [source].[lastyearpos] IS NULL)) OR
	([target].[lastyearreal] <> [source].[lastyearreal] OR ([target].[lastyearreal] IS NULL AND [source].[lastyearreal] IS NOT NULL) OR ([target].[lastyearreal] IS NOT NULL AND [source].[lastyearreal] IS NULL)) OR
	([target].[lastyearsecfee] <> [source].[lastyearsecfee] OR ([target].[lastyearsecfee] IS NULL AND [source].[lastyearsecfee] IS NOT NULL) OR ([target].[lastyearsecfee] IS NOT NULL AND [source].[lastyearsecfee] IS NULL)) OR
	([target].[lastyearstart] <> [source].[lastyearstart] OR ([target].[lastyearstart] IS NULL AND [source].[lastyearstart] IS NOT NULL) OR ([target].[lastyearstart] IS NOT NULL AND [source].[lastyearstart] IS NULL)) OR
	([target].[lastyeartktcharge] <> [source].[lastyeartktcharge] OR ([target].[lastyeartktcharge] IS NULL AND [source].[lastyeartktcharge] IS NOT NULL) OR ([target].[lastyeartktcharge] IS NOT NULL AND [source].[lastyeartktcharge] IS NULL)) OR
	([target].[longrate] <> [source].[longrate] OR ([target].[longrate] IS NULL AND [source].[longrate] IS NOT NULL) OR ([target].[longrate] IS NOT NULL AND [source].[longrate] IS NULL)) OR
	([target].[mark] <> [source].[mark] OR ([target].[mark] IS NULL AND [source].[mark] IS NOT NULL) OR ([target].[mark] IS NOT NULL AND [source].[mark] IS NULL)) OR
	([target].[monthaccrued] <> [source].[monthaccrued] OR ([target].[monthaccrued] IS NULL AND [source].[monthaccrued] IS NOT NULL) OR ([target].[monthaccrued] IS NOT NULL AND [source].[monthaccrued] IS NULL)) OR
	([target].[monthcash] <> [source].[monthcash] OR ([target].[monthcash] IS NULL AND [source].[monthcash] IS NOT NULL) OR ([target].[monthcash] IS NOT NULL AND [source].[monthcash] IS NULL)) OR
	([target].[monthcomm] <> [source].[monthcomm] OR ([target].[monthcomm] IS NULL AND [source].[monthcomm] IS NOT NULL) OR ([target].[monthcomm] IS NOT NULL AND [source].[monthcomm] IS NULL)) OR
	([target].[monthcost] <> [source].[monthcost] OR ([target].[monthcost] IS NULL AND [source].[monthcost] IS NOT NULL) OR ([target].[monthcost] IS NOT NULL AND [source].[monthcost] IS NULL)) OR
	([target].[monthcppaid] <> [source].[monthcppaid] OR ([target].[monthcppaid] IS NULL AND [source].[monthcppaid] IS NOT NULL) OR ([target].[monthcppaid] IS NOT NULL AND [source].[monthcppaid] IS NULL)) OR
	([target].[monthcprecv] <> [source].[monthcprecv] OR ([target].[monthcprecv] IS NULL AND [source].[monthcprecv] IS NOT NULL) OR ([target].[monthcprecv] IS NOT NULL AND [source].[monthcprecv] IS NULL)) OR
	([target].[monthdipaid] <> [source].[monthdipaid] OR ([target].[monthdipaid] IS NULL AND [source].[monthdipaid] IS NOT NULL) OR ([target].[monthdipaid] IS NOT NULL AND [source].[monthdipaid] IS NULL)) OR
	([target].[monthdirecv] <> [source].[monthdirecv] OR ([target].[monthdirecv] IS NULL AND [source].[monthdirecv] IS NOT NULL) OR ([target].[monthdirecv] IS NOT NULL AND [source].[monthdirecv] IS NULL)) OR
	([target].[monthmark] <> [source].[monthmark] OR ([target].[monthmark] IS NULL AND [source].[monthmark] IS NOT NULL) OR ([target].[monthmark] IS NOT NULL AND [source].[monthmark] IS NULL)) OR
	([target].[monthpos] <> [source].[monthpos] OR ([target].[monthpos] IS NULL AND [source].[monthpos] IS NOT NULL) OR ([target].[monthpos] IS NOT NULL AND [source].[monthpos] IS NULL)) OR
	([target].[monthreal] <> [source].[monthreal] OR ([target].[monthreal] IS NULL AND [source].[monthreal] IS NOT NULL) OR ([target].[monthreal] IS NOT NULL AND [source].[monthreal] IS NULL)) OR
	([target].[monthsecfee] <> [source].[monthsecfee] OR ([target].[monthsecfee] IS NULL AND [source].[monthsecfee] IS NOT NULL) OR ([target].[monthsecfee] IS NOT NULL AND [source].[monthsecfee] IS NULL)) OR
	([target].[monthstart] <> [source].[monthstart] OR ([target].[monthstart] IS NULL AND [source].[monthstart] IS NOT NULL) OR ([target].[monthstart] IS NOT NULL AND [source].[monthstart] IS NULL)) OR
	([target].[monthtktcharge] <> [source].[monthtktcharge] OR ([target].[monthtktcharge] IS NULL AND [source].[monthtktcharge] IS NOT NULL) OR ([target].[monthtktcharge] IS NOT NULL AND [source].[monthtktcharge] IS NULL)) OR
	([target].[openaccrued] <> [source].[openaccrued] OR ([target].[openaccrued] IS NULL AND [source].[openaccrued] IS NOT NULL) OR ([target].[openaccrued] IS NOT NULL AND [source].[openaccrued] IS NULL)) OR
	([target].[opencash] <> [source].[opencash] OR ([target].[opencash] IS NULL AND [source].[opencash] IS NOT NULL) OR ([target].[opencash] IS NOT NULL AND [source].[opencash] IS NULL)) OR
	([target].[opencomm] <> [source].[opencomm] OR ([target].[opencomm] IS NULL AND [source].[opencomm] IS NOT NULL) OR ([target].[opencomm] IS NOT NULL AND [source].[opencomm] IS NULL)) OR
	([target].[opencost] <> [source].[opencost] OR ([target].[opencost] IS NULL AND [source].[opencost] IS NOT NULL) OR ([target].[opencost] IS NOT NULL AND [source].[opencost] IS NULL)) OR
	([target].[opencppaid] <> [source].[opencppaid] OR ([target].[opencppaid] IS NULL AND [source].[opencppaid] IS NOT NULL) OR ([target].[opencppaid] IS NOT NULL AND [source].[opencppaid] IS NULL)) OR
	([target].[opencprecv] <> [source].[opencprecv] OR ([target].[opencprecv] IS NULL AND [source].[opencprecv] IS NOT NULL) OR ([target].[opencprecv] IS NOT NULL AND [source].[opencprecv] IS NULL)) OR
	([target].[opendipaid] <> [source].[opendipaid] OR ([target].[opendipaid] IS NULL AND [source].[opendipaid] IS NOT NULL) OR ([target].[opendipaid] IS NOT NULL AND [source].[opendipaid] IS NULL)) OR
	([target].[opendirecv] <> [source].[opendirecv] OR ([target].[opendirecv] IS NULL AND [source].[opendirecv] IS NOT NULL) OR ([target].[opendirecv] IS NOT NULL AND [source].[opendirecv] IS NULL)) OR
	([target].[openmark] <> [source].[openmark] OR ([target].[openmark] IS NULL AND [source].[openmark] IS NOT NULL) OR ([target].[openmark] IS NOT NULL AND [source].[openmark] IS NULL)) OR
	([target].[openpos] <> [source].[openpos] OR ([target].[openpos] IS NULL AND [source].[openpos] IS NOT NULL) OR ([target].[openpos] IS NOT NULL AND [source].[openpos] IS NULL)) OR
	([target].[openreal] <> [source].[openreal] OR ([target].[openreal] IS NULL AND [source].[openreal] IS NOT NULL) OR ([target].[openreal] IS NOT NULL AND [source].[openreal] IS NULL)) OR
	([target].[opensecfee] <> [source].[opensecfee] OR ([target].[opensecfee] IS NULL AND [source].[opensecfee] IS NOT NULL) OR ([target].[opensecfee] IS NOT NULL AND [source].[opensecfee] IS NULL)) OR
	([target].[openstart] <> [source].[openstart] OR ([target].[openstart] IS NULL AND [source].[openstart] IS NOT NULL) OR ([target].[openstart] IS NOT NULL AND [source].[openstart] IS NULL)) OR
	([target].[opentktcharge] <> [source].[opentktcharge] OR ([target].[opentktcharge] IS NULL AND [source].[opentktcharge] IS NOT NULL) OR ([target].[opentktcharge] IS NOT NULL AND [source].[opentktcharge] IS NULL)) OR
	([target].[ratio] <> [source].[ratio] OR ([target].[ratio] IS NULL AND [source].[ratio] IS NOT NULL) OR ([target].[ratio] IS NOT NULL AND [source].[ratio] IS NULL)) OR
	([target].[shortrate] <> [source].[shortrate] OR ([target].[shortrate] IS NULL AND [source].[shortrate] IS NOT NULL) OR ([target].[shortrate] IS NOT NULL AND [source].[shortrate] IS NULL)) OR
	([target].[shortratecode] <> [source].[shortratecode] OR ([target].[shortratecode] IS NULL AND [source].[shortratecode] IS NOT NULL) OR ([target].[shortratecode] IS NOT NULL AND [source].[shortratecode] IS NULL)) OR
	([target].[yearaccrued] <> [source].[yearaccrued] OR ([target].[yearaccrued] IS NULL AND [source].[yearaccrued] IS NOT NULL) OR ([target].[yearaccrued] IS NOT NULL AND [source].[yearaccrued] IS NULL)) OR
	([target].[yearcash] <> [source].[yearcash] OR ([target].[yearcash] IS NULL AND [source].[yearcash] IS NOT NULL) OR ([target].[yearcash] IS NOT NULL AND [source].[yearcash] IS NULL)) OR
	([target].[yearcomm] <> [source].[yearcomm] OR ([target].[yearcomm] IS NULL AND [source].[yearcomm] IS NOT NULL) OR ([target].[yearcomm] IS NOT NULL AND [source].[yearcomm] IS NULL)) OR
	([target].[yearcost] <> [source].[yearcost] OR ([target].[yearcost] IS NULL AND [source].[yearcost] IS NOT NULL) OR ([target].[yearcost] IS NOT NULL AND [source].[yearcost] IS NULL)) OR
	([target].[yearcppaid] <> [source].[yearcppaid] OR ([target].[yearcppaid] IS NULL AND [source].[yearcppaid] IS NOT NULL) OR ([target].[yearcppaid] IS NOT NULL AND [source].[yearcppaid] IS NULL)) OR
	([target].[yearcprecv] <> [source].[yearcprecv] OR ([target].[yearcprecv] IS NULL AND [source].[yearcprecv] IS NOT NULL) OR ([target].[yearcprecv] IS NOT NULL AND [source].[yearcprecv] IS NULL)) OR
	([target].[yeardipaid] <> [source].[yeardipaid] OR ([target].[yeardipaid] IS NULL AND [source].[yeardipaid] IS NOT NULL) OR ([target].[yeardipaid] IS NOT NULL AND [source].[yeardipaid] IS NULL)) OR
	([target].[yeardirecv] <> [source].[yeardirecv] OR ([target].[yeardirecv] IS NULL AND [source].[yeardirecv] IS NOT NULL) OR ([target].[yeardirecv] IS NOT NULL AND [source].[yeardirecv] IS NULL)) OR
	([target].[yearmark] <> [source].[yearmark] OR ([target].[yearmark] IS NULL AND [source].[yearmark] IS NOT NULL) OR ([target].[yearmark] IS NOT NULL AND [source].[yearmark] IS NULL)) OR
	([target].[yearpos] <> [source].[yearpos] OR ([target].[yearpos] IS NULL AND [source].[yearpos] IS NOT NULL) OR ([target].[yearpos] IS NOT NULL AND [source].[yearpos] IS NULL)) OR
	([target].[yearreal] <> [source].[yearreal] OR ([target].[yearreal] IS NULL AND [source].[yearreal] IS NOT NULL) OR ([target].[yearreal] IS NOT NULL AND [source].[yearreal] IS NULL)) OR
	([target].[yearsecfee] <> [source].[yearsecfee] OR ([target].[yearsecfee] IS NULL AND [source].[yearsecfee] IS NOT NULL) OR ([target].[yearsecfee] IS NOT NULL AND [source].[yearsecfee] IS NULL)) OR
	([target].[yearstart] <> [source].[yearstart] OR ([target].[yearstart] IS NULL AND [source].[yearstart] IS NOT NULL) OR ([target].[yearstart] IS NOT NULL AND [source].[yearstart] IS NULL)) OR
	([target].[yeartktcharge] <> [source].[yeartktcharge] OR ([target].[yeartktcharge] IS NULL AND [source].[yeartktcharge] IS NOT NULL) OR ([target].[yeartktcharge] IS NOT NULL AND [source].[yeartktcharge] IS NULL))

)
	THEN UPDATE
	SET
		[ts_end] = @CurrentDateTime


	OUTPUT
		$Action as [MERGE_ACTION_0645cb5d-91e7-48ae-8a8a-28cce2c6a801],
		[source].[account] AS [account],
		[source].[currency] AS [currency],
		[source].[dayaccrued] AS [dayaccrued],
		[source].[daycash] AS [daycash],
		[source].[daycomm] AS [daycomm],
		[source].[daycost] AS [daycost],
		[source].[daycppaid] AS [daycppaid],
		[source].[daycprecv] AS [daycprecv],
		[source].[daydipaid] AS [daydipaid],
		[source].[daydirecv] AS [daydirecv],
		[source].[daymark] AS [daymark],
		[source].[daypos] AS [daypos],
		[source].[dayreal] AS [dayreal],
		[source].[daysecfee] AS [daysecfee],
		[source].[daystart] AS [daystart],
		[source].[daytktcharge] AS [daytktcharge],
		[source].[fxrate] AS [fxrate],
		[source].[h10longratefrac] AS [h10longratefrac],
		[source].[h10longrateint] AS [h10longrateint],
		[source].[h10mark] AS [h10mark],
		[source].[h10offset] AS [h10offset],
		[source].[h10percent] AS [h10percent],
		[source].[h10shortratefrac] AS [h10shortratefrac],
		[source].[h10shortrateint] AS [h10shortrateint],
		[source].[h11longratefrac] AS [h11longratefrac],
		[source].[h11longrateint] AS [h11longrateint],
		[source].[h11mark] AS [h11mark],
		[source].[h11offset] AS [h11offset],
		[source].[h11percent] AS [h11percent],
		[source].[h11shortratefrac] AS [h11shortratefrac],
		[source].[h11shortrateint] AS [h11shortrateint],
		[source].[h12longratefrac] AS [h12longratefrac],
		[source].[h12longrateint] AS [h12longrateint],
		[source].[h12mark] AS [h12mark],
		[source].[h12offset] AS [h12offset],
		[source].[h12percent] AS [h12percent],
		[source].[h12shortratefrac] AS [h12shortratefrac],
		[source].[h12shortrateint] AS [h12shortrateint],
		[source].[h13longratefrac] AS [h13longratefrac],
		[source].[h13longrateint] AS [h13longrateint],
		[source].[h13mark] AS [h13mark],
		[source].[h13offset] AS [h13offset],
		[source].[h13percent] AS [h13percent],
		[source].[h13shortratefrac] AS [h13shortratefrac],
		[source].[h13shortrateint] AS [h13shortrateint],
		[source].[h14longratefrac] AS [h14longratefrac],
		[source].[h14longrateint] AS [h14longrateint],
		[source].[h14mark] AS [h14mark],
		[source].[h14offset] AS [h14offset],
		[source].[h14percent] AS [h14percent],
		[source].[h14shortratefrac] AS [h14shortratefrac],
		[source].[h14shortrateint] AS [h14shortrateint],
		[source].[h15longratefrac] AS [h15longratefrac],
		[source].[h15longrateint] AS [h15longrateint],
		[source].[h15mark] AS [h15mark],
		[source].[h15offset] AS [h15offset],
		[source].[h15percent] AS [h15percent],
		[source].[h15shortratefrac] AS [h15shortratefrac],
		[source].[h15shortrateint] AS [h15shortrateint],
		[source].[h16longratefrac] AS [h16longratefrac],
		[source].[h16longrateint] AS [h16longrateint],
		[source].[h16mark] AS [h16mark],
		[source].[h16offset] AS [h16offset],
		[source].[h16percent] AS [h16percent],
		[source].[h16shortratefrac] AS [h16shortratefrac],
		[source].[h16shortrateint] AS [h16shortrateint],
		[source].[h1longratefrac] AS [h1longratefrac],
		[source].[h1longrateint] AS [h1longrateint],
		[source].[h1mark] AS [h1mark],
		[source].[h1offset] AS [h1offset],
		[source].[h1percent] AS [h1percent],
		[source].[h1shortratefrac] AS [h1shortratefrac],
		[source].[h1shortrateint] AS [h1shortrateint],
		[source].[h2longratefrac] AS [h2longratefrac],
		[source].[h2longrateint] AS [h2longrateint],
		[source].[h2mark] AS [h2mark],
		[source].[h2offset] AS [h2offset],
		[source].[h2percent] AS [h2percent],
		[source].[h2shortratefrac] AS [h2shortratefrac],
		[source].[h2shortrateint] AS [h2shortrateint],
		[source].[h3longratefrac] AS [h3longratefrac],
		[source].[h3longrateint] AS [h3longrateint],
		[source].[h3mark] AS [h3mark],
		[source].[h3offset] AS [h3offset],
		[source].[h3percent] AS [h3percent],
		[source].[h3shortratefrac] AS [h3shortratefrac],
		[source].[h3shortrateint] AS [h3shortrateint],
		[source].[h4longratefrac] AS [h4longratefrac],
		[source].[h4longrateint] AS [h4longrateint],
		[source].[h4mark] AS [h4mark],
		[source].[h4offset] AS [h4offset],
		[source].[h4percent] AS [h4percent],
		[source].[h4shortratefrac] AS [h4shortratefrac],
		[source].[h4shortrateint] AS [h4shortrateint],
		[source].[h5longratefrac] AS [h5longratefrac],
		[source].[h5longrateint] AS [h5longrateint],
		[source].[h5mark] AS [h5mark],
		[source].[h5offset] AS [h5offset],
		[source].[h5percent] AS [h5percent],
		[source].[h5shortratefrac] AS [h5shortratefrac],
		[source].[h5shortrateint] AS [h5shortrateint],
		[source].[h6longratefrac] AS [h6longratefrac],
		[source].[h6longrateint] AS [h6longrateint],
		[source].[h6mark] AS [h6mark],
		[source].[h6offset] AS [h6offset],
		[source].[h6percent] AS [h6percent],
		[source].[h6shortratefrac] AS [h6shortratefrac],
		[source].[h6shortrateint] AS [h6shortrateint],
		[source].[h7longratefrac] AS [h7longratefrac],
		[source].[h7longrateint] AS [h7longrateint],
		[source].[h7mark] AS [h7mark],
		[source].[h7offset] AS [h7offset],
		[source].[h7percent] AS [h7percent],
		[source].[h7shortratefrac] AS [h7shortratefrac],
		[source].[h7shortrateint] AS [h7shortrateint],
		[source].[h8longratefrac] AS [h8longratefrac],
		[source].[h8longrateint] AS [h8longrateint],
		[source].[h8mark] AS [h8mark],
		[source].[h8offset] AS [h8offset],
		[source].[h8percent] AS [h8percent],
		[source].[h8shortratefrac] AS [h8shortratefrac],
		[source].[h8shortrateint] AS [h8shortrateint],
		[source].[h9longratefrac] AS [h9longratefrac],
		[source].[h9longrateint] AS [h9longrateint],
		[source].[h9mark] AS [h9mark],
		[source].[h9offset] AS [h9offset],
		[source].[h9percent] AS [h9percent],
		[source].[h9shortratefrac] AS [h9shortratefrac],
		[source].[h9shortrateint] AS [h9shortrateint],
		[source].[hedge] AS [hedge],
		[source].[lastmonthaccrued] AS [lastmonthaccrued],
		[source].[lastmonthcash] AS [lastmonthcash],
		[source].[lastmonthcomm] AS [lastmonthcomm],
		[source].[lastmonthcost] AS [lastmonthcost],
		[source].[lastmonthcppaid] AS [lastmonthcppaid],
		[source].[lastmonthcprecv] AS [lastmonthcprecv],
		[source].[lastmonthdipaid] AS [lastmonthdipaid],
		[source].[lastmonthdirecv] AS [lastmonthdirecv],
		[source].[lastmonthmark] AS [lastmonthmark],
		[source].[lastmonthpos] AS [lastmonthpos],
		[source].[lastmonthreal] AS [lastmonthreal],
		[source].[lastmonthsecfee] AS [lastmonthsecfee],
		[source].[lastmonthstart] AS [lastmonthstart],
		[source].[lastmonthtktcharge] AS [lastmonthtktcharge],
		[source].[lastyearaccured] AS [lastyearaccured],
		[source].[lastyearcash] AS [lastyearcash],
		[source].[lastyearcomm] AS [lastyearcomm],
		[source].[lastyearcost] AS [lastyearcost],
		[source].[lastyearcppaid] AS [lastyearcppaid],
		[source].[lastyearcprecv] AS [lastyearcprecv],
		[source].[lastyeardipaid] AS [lastyeardipaid],
		[source].[lastyeardirecv] AS [lastyeardirecv],
		[source].[lastyearmark] AS [lastyearmark],
		[source].[lastyearpos] AS [lastyearpos],
		[source].[lastyearreal] AS [lastyearreal],
		[source].[lastyearsecfee] AS [lastyearsecfee],
		[source].[lastyearstart] AS [lastyearstart],
		[source].[lastyeartktcharge] AS [lastyeartktcharge],
		[source].[longrate] AS [longrate],
		[source].[mark] AS [mark],
		[source].[monthaccrued] AS [monthaccrued],
		[source].[monthcash] AS [monthcash],
		[source].[monthcomm] AS [monthcomm],
		[source].[monthcost] AS [monthcost],
		[source].[monthcppaid] AS [monthcppaid],
		[source].[monthcprecv] AS [monthcprecv],
		[source].[monthdipaid] AS [monthdipaid],
		[source].[monthdirecv] AS [monthdirecv],
		[source].[monthmark] AS [monthmark],
		[source].[monthpos] AS [monthpos],
		[source].[monthreal] AS [monthreal],
		[source].[monthsecfee] AS [monthsecfee],
		[source].[monthstart] AS [monthstart],
		[source].[monthtktcharge] AS [monthtktcharge],
		[source].[openaccrued] AS [openaccrued],
		[source].[opencash] AS [opencash],
		[source].[opencomm] AS [opencomm],
		[source].[opencost] AS [opencost],
		[source].[opencppaid] AS [opencppaid],
		[source].[opencprecv] AS [opencprecv],
		[source].[opendipaid] AS [opendipaid],
		[source].[opendirecv] AS [opendirecv],
		[source].[openmark] AS [openmark],
		[source].[openpos] AS [openpos],
		[source].[openreal] AS [openreal],
		[source].[opensecfee] AS [opensecfee],
		[source].[openstart] AS [openstart],
		[source].[opentktcharge] AS [opentktcharge],
		[source].[ratio] AS [ratio],
		[source].[shortrate] AS [shortrate],
		[source].[shortratecode] AS [shortratecode],
		[source].[strategy] AS [strategy],
		[source].[symbol] AS [symbol],
		@NullDateTime AS [ts_end],
		@CurrentDateTime AS [ts_start],
		[source].[yearaccrued] AS [yearaccrued],
		[source].[yearcash] AS [yearcash],
		[source].[yearcomm] AS [yearcomm],
		[source].[yearcost] AS [yearcost],
		[source].[yearcppaid] AS [yearcppaid],
		[source].[yearcprecv] AS [yearcprecv],
		[source].[yeardipaid] AS [yeardipaid],
		[source].[yeardirecv] AS [yeardirecv],
		[source].[yearmark] AS [yearmark],
		[source].[yearpos] AS [yearpos],
		[source].[yearreal] AS [yearreal],
		[source].[yearsecfee] AS [yearsecfee],
		[source].[yearstart] AS [yearstart],
		[source].[yeartktcharge] AS [yeartktcharge]

)MERGE_OUTPUT
WHERE MERGE_OUTPUT.[MERGE_ACTION_0645cb5d-91e7-48ae-8a8a-28cce2c6a801] = 'UPDATE' 
	AND MERGE_OUTPUT.[account] IS NOT NULL
	AND MERGE_OUTPUT.[strategy] IS NOT NULL
	AND MERGE_OUTPUT.[symbol] IS NOT NULL
;

-- Zero out invalid accounts
UPDATE TMWPOSDB
SET ts_end = @TimeStamp 
FROM TMWPOSDB P
	LEFT JOIN TMWACCTDB A
	ON A.account = P.account
WHERE ((A.active = 'N') or (A.test = 'Y')) and P.ts_end IS NULL

-- Zero out positions that aren't from this year
UPDATE TMWPOSDB
SET ts_end = @TimeStamp 
	FROM [TMDBSQL].[dbo].[TMWPOSDB]
	WHERE openpos = 0 and daypos = 0 and monthpos = 0 and ts_end IS NULL

COMMIT TRANSACTION merge_TMWPOSDB
END
GO
