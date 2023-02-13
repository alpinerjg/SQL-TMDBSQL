SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE [dbo].[merge_TMWTRANDB] 
	@Timestamp datetime	
AS
BEGIN

-- DECLARE @Timestamp datetime
-- SELECT @Timestamp = GETDATE()
DECLARE @TimestampString CHAR(8)
SELECT @TimestampString = FORMAT(@Timestamp,'yyyyMMdd')

IF EXISTS(SELECT entrydate FROM [TMDBSQL].[dbo].[TMWTRANDB] where ts_end IS NULL and entrydate < @TimestampString)
BEGIN
	-- PRINT @TimestampString
	BEGIN TRANSACTION age_TMWTRANDB
		UPDATE [TMDBSQL].[dbo].[TMWTRANDB] SET ts_end = @Timestamp WHERE ts_end IS NULL AND ([entrydate] <> @TimestampString) AND ([tradedate] <> @TimestampString)
		-- UPDATE [TMDBSQL].[dbo].[TMWTRANDB] SET ts_end = NULL WHERE tradedate = @TimestampString
	COMMIT TRANSACTION age_TMWTRANDB
END

IF NOT EXISTS(SELECT seqnum,account,strategy,symbol,entrydate,tag FROM [TMDBSQL].[dbo].[TMWTRANDB_staging])
BEGIN
	PRINT N'PROCEDURE [dbo].[merge_TMWTRANDB]: No records exist in [TMWTRANDB_staging]. Exiting.'
	RETURN
END

BEGIN TRANSACTION merge_TMWTRANDB

UPDATE t1 
SET t1.ts_end = @Timestamp
FROM [TMDBSQL].[dbo].[TMWTRANDB] t1
LEFT JOIN [TMDBSQL].[dbo].[TMWTRANDB_staging] t2 ON 
		t2.seqnum = t1.seqnum AND 
		t2.account = t1.account AND
		t2.strategy = t1.strategy AND
		t2.symbol = t1.symbol AND
		t2.entrydate = t1.entrydate AND
		t2.tag = t1.tag
WHERE t1.ts_end IS NULL AND 
			(t2.seqnum IS NULL OR 
				t2.account IS NULL OR
				t2.strategy IS NULL OR
				t2.symbol IS NULL OR
				t2.entrydate IS NULL OR
				t2.tag IS NULL)

UPDATE [TMDBSQL].[dbo].[TMWTRANDB] SET ts_end = @Timestamp

-- ==================================================
-- Slowly Changing Dimension script by SCD Merge Wizard
-- Author: Miljan Radovic
-- Official web site: https://github.com/SQLPlayer/SCD-Merge-Wizard/
-- Version: 4.3.0.0
-- Publish date: 4/8/2021 9:05:16 AM
-- Script creation date: 4/9/2021 2:28:06 PM
-- ==================================================

-- ==================================================
-- SCD2
-- ==================================================
INSERT INTO [dbo].[TMWTRANDB]
(
	[account],
	[acctsubtype],
	[asof],
	[auth],
	[bidlist],
	[block],
	[blotter],
	[broker],
	[clearance],
	[comm],
	[comment],
	[contraacct],
	[contrabroker],
	[contracode],
	[cxlentry],
	[cxlsentflag],
	[cxltag],
	[cxltime],
	[destination],
	[entrydate],
	[entryflag],
	[exchange],
	[filler1],
	[fxmoney],
	[fxrate],
	[id],
	[interest],
	[interestflag],
	[location],
	[money],
	[openclose],
	[orderdate],
	[orderentry],
	[ordersymbol],
	[ordertag],
	[price],
	[quantity],
	[rectype],
	[regfee],
	[regid],
	[regstatus],
	[regtime],
	[reportflag],
	[route],
	[secfee],
	[seqnum],
	[seqnum2],
	[settle],
	[settleflag],
	[source],
	[status],
	[strategy],
	[symbol],
	[tag],
	[tktcharge],
	[tradedate],
	[tradeflag],
	[tradetag],
	[tradetime],
	[ts_end],
	[ts_start],
	[type],
	[undprice],
	[userid]
)
SELECT
	[account],
	[acctsubtype],
	[asof],
	[auth],
	[bidlist],
	[block],
	[blotter],
	[broker],
	[clearance],
	[comm],
	[comment],
	[contraacct],
	[contrabroker],
	[contracode],
	[cxlentry],
	[cxlsentflag],
	[cxltag],
	[cxltime],
	[destination],
	[entrydate],
	[entryflag],
	[exchange],
	[filler1],
	[fxmoney],
	[fxrate],
	[id],
	[interest],
	[interestflag],
	[location],
	[money],
	[openclose],
	[orderdate],
	[orderentry],
	[ordersymbol],
	[ordertag],
	[price],
	[quantity],
	[rectype],
	[regfee],
	[regid],
	[regstatus],
	[regtime],
	[reportflag],
	[route],
	[secfee],
	[seqnum],
	[seqnum2],
	[settle],
	[settleflag],
	[source],
	[status],
	[strategy],
	[symbol],
	[tag],
	[tktcharge],
	[tradedate],
	[tradeflag],
	[tradetag],
	[tradetime],
	[ts_end],
	[ts_start],
	[type],
	[undprice],
	[userid]
FROM
(
	MERGE [dbo].[TMWTRANDB] WITH(HOLDLOCK) as [target]
	USING
	(
		SELECT
			[account],
			[acctsubtype],
			[asof],
			[auth],
			[bidlist],
			[block],
			[blotter],
			[broker],
			[clearance],
			[comm],
			[comment],
			[contraacct],
			[contrabroker],
			[contracode],
			[cxlentry],
			[cxlsentflag],
			[cxltag],
			[cxltime],
			[destination],
			[entrydate],
			[entryflag],
			[exchange],
			[filler1],
			[fxmoney],
			[fxrate],
			[id],
			[interest],
			[interestflag],
			[location],
			[money],
			[openclose],
			[orderdate],
			[orderentry],
			[ordersymbol],
			[ordertag],
			[price],
			[quantity],
			[rectype],
			[regfee],
			[regid],
			[regstatus],
			[regtime],
			[reportflag],
			[route],
			[secfee],
			[seqnum],
			[seqnum2],
			[settle],
			[settleflag],
			[source],
			[status],
			[strategy],
			[symbol],
			[tag],
			[tktcharge],
			[tradedate],
			[tradeflag],
			[tradetag],
			[tradetime],
			[type],
			[undprice],
			[userid]
		FROM [dbo].[TMWTRANDB_staging]

	) as [source]
	ON
	(
		[source].[account] = [target].[account] AND
		[source].[entrydate] = [target].[entrydate] AND
		[source].[seqnum] = [target].[seqnum] AND
		[source].[strategy] = [target].[strategy] AND
		[source].[symbol] = [target].[symbol] AND
		[source].[tag] = [target].[tag] AND
		[source].[tradedate] = [target].[tradedate]
	)

	WHEN NOT MATCHED BY TARGET
	THEN INSERT
	(
		[account],
		[acctsubtype],
		[asof],
		[auth],
		[bidlist],
		[block],
		[blotter],
		[broker],
		[clearance],
		[comm],
		[comment],
		[contraacct],
		[contrabroker],
		[contracode],
		[cxlentry],
		[cxlsentflag],
		[cxltag],
		[cxltime],
		[destination],
		[entrydate],
		[entryflag],
		[exchange],
		[filler1],
		[fxmoney],
		[fxrate],
		[id],
		[interest],
		[interestflag],
		[location],
		[money],
		[openclose],
		[orderdate],
		[orderentry],
		[ordersymbol],
		[ordertag],
		[price],
		[quantity],
		[rectype],
		[regfee],
		[regid],
		[regstatus],
		[regtime],
		[reportflag],
		[route],
		[secfee],
		[seqnum],
		[seqnum2],
		[settle],
		[settleflag],
		[source],
		[status],
		[strategy],
		[symbol],
		[tag],
		[tktcharge],
		[tradedate],
		[tradeflag],
		[tradetag],
		[tradetime],
		[ts_end],
		[ts_start],
		[type],
		[undprice],
		[userid]
	)
	VALUES
	(
		[account],
		[acctsubtype],
		[asof],
		[auth],
		[bidlist],
		[block],
		[blotter],
		[broker],
		[clearance],
		[comm],
		[comment],
		[contraacct],
		[contrabroker],
		[contracode],
		[cxlentry],
		[cxlsentflag],
		[cxltag],
		[cxltime],
		[destination],
		[entrydate],
		[entryflag],
		[exchange],
		[filler1],
		[fxmoney],
		[fxrate],
		[id],
		[interest],
		[interestflag],
		[location],
		[money],
		[openclose],
		[orderdate],
		[orderentry],
		[ordersymbol],
		[ordertag],
		[price],
		[quantity],
		[rectype],
		[regfee],
		[regid],
		[regstatus],
		[regtime],
		[reportflag],
		[route],
		[secfee],
		[seqnum],
		[seqnum2],
		[settle],
		[settleflag],
		[source],
		[status],
		[strategy],
		[symbol],
		[tag],
		[tktcharge],
		[tradedate],
		[tradeflag],
		[tradetag],
		[tradetime],
		NULL,
		@Timestamp,
		[type],
		[undprice],
		[userid]
	)


WHEN MATCHED AND
(
	[ts_end] = NULL
)
AND
(
	([target].[acctsubtype] <> [source].[acctsubtype] OR ([target].[acctsubtype] IS NULL AND [source].[acctsubtype] IS NOT NULL) OR ([target].[acctsubtype] IS NOT NULL AND [source].[acctsubtype] IS NULL)) OR
	([target].[asof] <> [source].[asof] OR ([target].[asof] IS NULL AND [source].[asof] IS NOT NULL) OR ([target].[asof] IS NOT NULL AND [source].[asof] IS NULL)) OR
	([target].[auth] <> [source].[auth] OR ([target].[auth] IS NULL AND [source].[auth] IS NOT NULL) OR ([target].[auth] IS NOT NULL AND [source].[auth] IS NULL)) OR
	([target].[bidlist] <> [source].[bidlist] OR ([target].[bidlist] IS NULL AND [source].[bidlist] IS NOT NULL) OR ([target].[bidlist] IS NOT NULL AND [source].[bidlist] IS NULL)) OR
	([target].[block] <> [source].[block] OR ([target].[block] IS NULL AND [source].[block] IS NOT NULL) OR ([target].[block] IS NOT NULL AND [source].[block] IS NULL)) OR
	([target].[blotter] <> [source].[blotter] OR ([target].[blotter] IS NULL AND [source].[blotter] IS NOT NULL) OR ([target].[blotter] IS NOT NULL AND [source].[blotter] IS NULL)) OR
	([target].[broker] <> [source].[broker] OR ([target].[broker] IS NULL AND [source].[broker] IS NOT NULL) OR ([target].[broker] IS NOT NULL AND [source].[broker] IS NULL)) OR
	([target].[clearance] <> [source].[clearance] OR ([target].[clearance] IS NULL AND [source].[clearance] IS NOT NULL) OR ([target].[clearance] IS NOT NULL AND [source].[clearance] IS NULL)) OR
	([target].[comm] <> [source].[comm] OR ([target].[comm] IS NULL AND [source].[comm] IS NOT NULL) OR ([target].[comm] IS NOT NULL AND [source].[comm] IS NULL)) OR
	([target].[comment] <> [source].[comment] OR ([target].[comment] IS NULL AND [source].[comment] IS NOT NULL) OR ([target].[comment] IS NOT NULL AND [source].[comment] IS NULL)) OR
	([target].[contraacct] <> [source].[contraacct] OR ([target].[contraacct] IS NULL AND [source].[contraacct] IS NOT NULL) OR ([target].[contraacct] IS NOT NULL AND [source].[contraacct] IS NULL)) OR
	([target].[contrabroker] <> [source].[contrabroker] OR ([target].[contrabroker] IS NULL AND [source].[contrabroker] IS NOT NULL) OR ([target].[contrabroker] IS NOT NULL AND [source].[contrabroker] IS NULL)) OR
	([target].[contracode] <> [source].[contracode] OR ([target].[contracode] IS NULL AND [source].[contracode] IS NOT NULL) OR ([target].[contracode] IS NOT NULL AND [source].[contracode] IS NULL)) OR
	([target].[cxlentry] <> [source].[cxlentry] OR ([target].[cxlentry] IS NULL AND [source].[cxlentry] IS NOT NULL) OR ([target].[cxlentry] IS NOT NULL AND [source].[cxlentry] IS NULL)) OR
	([target].[cxlsentflag] <> [source].[cxlsentflag] OR ([target].[cxlsentflag] IS NULL AND [source].[cxlsentflag] IS NOT NULL) OR ([target].[cxlsentflag] IS NOT NULL AND [source].[cxlsentflag] IS NULL)) OR
	([target].[cxltag] <> [source].[cxltag] OR ([target].[cxltag] IS NULL AND [source].[cxltag] IS NOT NULL) OR ([target].[cxltag] IS NOT NULL AND [source].[cxltag] IS NULL)) OR
	([target].[cxltime] <> [source].[cxltime] OR ([target].[cxltime] IS NULL AND [source].[cxltime] IS NOT NULL) OR ([target].[cxltime] IS NOT NULL AND [source].[cxltime] IS NULL)) OR
	([target].[destination] <> [source].[destination] OR ([target].[destination] IS NULL AND [source].[destination] IS NOT NULL) OR ([target].[destination] IS NOT NULL AND [source].[destination] IS NULL)) OR
	([target].[entryflag] <> [source].[entryflag] OR ([target].[entryflag] IS NULL AND [source].[entryflag] IS NOT NULL) OR ([target].[entryflag] IS NOT NULL AND [source].[entryflag] IS NULL)) OR
	([target].[exchange] <> [source].[exchange] OR ([target].[exchange] IS NULL AND [source].[exchange] IS NOT NULL) OR ([target].[exchange] IS NOT NULL AND [source].[exchange] IS NULL)) OR
	([target].[filler1] <> [source].[filler1] OR ([target].[filler1] IS NULL AND [source].[filler1] IS NOT NULL) OR ([target].[filler1] IS NOT NULL AND [source].[filler1] IS NULL)) OR
	([target].[fxmoney] <> [source].[fxmoney] OR ([target].[fxmoney] IS NULL AND [source].[fxmoney] IS NOT NULL) OR ([target].[fxmoney] IS NOT NULL AND [source].[fxmoney] IS NULL)) OR
	([target].[fxrate] <> [source].[fxrate] OR ([target].[fxrate] IS NULL AND [source].[fxrate] IS NOT NULL) OR ([target].[fxrate] IS NOT NULL AND [source].[fxrate] IS NULL)) OR
	([target].[id] <> [source].[id] OR ([target].[id] IS NULL AND [source].[id] IS NOT NULL) OR ([target].[id] IS NOT NULL AND [source].[id] IS NULL)) OR
	([target].[interest] <> [source].[interest] OR ([target].[interest] IS NULL AND [source].[interest] IS NOT NULL) OR ([target].[interest] IS NOT NULL AND [source].[interest] IS NULL)) OR
	([target].[interestflag] <> [source].[interestflag] OR ([target].[interestflag] IS NULL AND [source].[interestflag] IS NOT NULL) OR ([target].[interestflag] IS NOT NULL AND [source].[interestflag] IS NULL)) OR
	([target].[location] <> [source].[location] OR ([target].[location] IS NULL AND [source].[location] IS NOT NULL) OR ([target].[location] IS NOT NULL AND [source].[location] IS NULL)) OR
	([target].[money] <> [source].[money] OR ([target].[money] IS NULL AND [source].[money] IS NOT NULL) OR ([target].[money] IS NOT NULL AND [source].[money] IS NULL)) OR
	([target].[openclose] <> [source].[openclose] OR ([target].[openclose] IS NULL AND [source].[openclose] IS NOT NULL) OR ([target].[openclose] IS NOT NULL AND [source].[openclose] IS NULL)) OR
	([target].[orderdate] <> [source].[orderdate] OR ([target].[orderdate] IS NULL AND [source].[orderdate] IS NOT NULL) OR ([target].[orderdate] IS NOT NULL AND [source].[orderdate] IS NULL)) OR
	([target].[orderentry] <> [source].[orderentry] OR ([target].[orderentry] IS NULL AND [source].[orderentry] IS NOT NULL) OR ([target].[orderentry] IS NOT NULL AND [source].[orderentry] IS NULL)) OR
	([target].[ordersymbol] <> [source].[ordersymbol] OR ([target].[ordersymbol] IS NULL AND [source].[ordersymbol] IS NOT NULL) OR ([target].[ordersymbol] IS NOT NULL AND [source].[ordersymbol] IS NULL)) OR
	([target].[ordertag] <> [source].[ordertag] OR ([target].[ordertag] IS NULL AND [source].[ordertag] IS NOT NULL) OR ([target].[ordertag] IS NOT NULL AND [source].[ordertag] IS NULL)) OR
	([target].[price] <> [source].[price] OR ([target].[price] IS NULL AND [source].[price] IS NOT NULL) OR ([target].[price] IS NOT NULL AND [source].[price] IS NULL)) OR
	([target].[quantity] <> [source].[quantity] OR ([target].[quantity] IS NULL AND [source].[quantity] IS NOT NULL) OR ([target].[quantity] IS NOT NULL AND [source].[quantity] IS NULL)) OR
	([target].[rectype] <> [source].[rectype] OR ([target].[rectype] IS NULL AND [source].[rectype] IS NOT NULL) OR ([target].[rectype] IS NOT NULL AND [source].[rectype] IS NULL)) OR
	([target].[regfee] <> [source].[regfee] OR ([target].[regfee] IS NULL AND [source].[regfee] IS NOT NULL) OR ([target].[regfee] IS NOT NULL AND [source].[regfee] IS NULL)) OR
	([target].[regid] <> [source].[regid] OR ([target].[regid] IS NULL AND [source].[regid] IS NOT NULL) OR ([target].[regid] IS NOT NULL AND [source].[regid] IS NULL)) OR
	([target].[regstatus] <> [source].[regstatus] OR ([target].[regstatus] IS NULL AND [source].[regstatus] IS NOT NULL) OR ([target].[regstatus] IS NOT NULL AND [source].[regstatus] IS NULL)) OR
	([target].[regtime] <> [source].[regtime] OR ([target].[regtime] IS NULL AND [source].[regtime] IS NOT NULL) OR ([target].[regtime] IS NOT NULL AND [source].[regtime] IS NULL)) OR
	([target].[reportflag] <> [source].[reportflag] OR ([target].[reportflag] IS NULL AND [source].[reportflag] IS NOT NULL) OR ([target].[reportflag] IS NOT NULL AND [source].[reportflag] IS NULL)) OR
	([target].[route] <> [source].[route] OR ([target].[route] IS NULL AND [source].[route] IS NOT NULL) OR ([target].[route] IS NOT NULL AND [source].[route] IS NULL)) OR
	([target].[secfee] <> [source].[secfee] OR ([target].[secfee] IS NULL AND [source].[secfee] IS NOT NULL) OR ([target].[secfee] IS NOT NULL AND [source].[secfee] IS NULL)) OR
	([target].[seqnum2] <> [source].[seqnum2] OR ([target].[seqnum2] IS NULL AND [source].[seqnum2] IS NOT NULL) OR ([target].[seqnum2] IS NOT NULL AND [source].[seqnum2] IS NULL)) OR
	([target].[settle] <> [source].[settle] OR ([target].[settle] IS NULL AND [source].[settle] IS NOT NULL) OR ([target].[settle] IS NOT NULL AND [source].[settle] IS NULL)) OR
	([target].[settleflag] <> [source].[settleflag] OR ([target].[settleflag] IS NULL AND [source].[settleflag] IS NOT NULL) OR ([target].[settleflag] IS NOT NULL AND [source].[settleflag] IS NULL)) OR
	([target].[source] <> [source].[source] OR ([target].[source] IS NULL AND [source].[source] IS NOT NULL) OR ([target].[source] IS NOT NULL AND [source].[source] IS NULL)) OR
	([target].[status] <> [source].[status] OR ([target].[status] IS NULL AND [source].[status] IS NOT NULL) OR ([target].[status] IS NOT NULL AND [source].[status] IS NULL)) OR
	([target].[tktcharge] <> [source].[tktcharge] OR ([target].[tktcharge] IS NULL AND [source].[tktcharge] IS NOT NULL) OR ([target].[tktcharge] IS NOT NULL AND [source].[tktcharge] IS NULL)) OR
	([target].[tradeflag] <> [source].[tradeflag] OR ([target].[tradeflag] IS NULL AND [source].[tradeflag] IS NOT NULL) OR ([target].[tradeflag] IS NOT NULL AND [source].[tradeflag] IS NULL)) OR
	([target].[tradetag] <> [source].[tradetag] OR ([target].[tradetag] IS NULL AND [source].[tradetag] IS NOT NULL) OR ([target].[tradetag] IS NOT NULL AND [source].[tradetag] IS NULL)) OR
	([target].[tradetime] <> [source].[tradetime] OR ([target].[tradetime] IS NULL AND [source].[tradetime] IS NOT NULL) OR ([target].[tradetime] IS NOT NULL AND [source].[tradetime] IS NULL)) OR
	([target].[type] <> [source].[type] OR ([target].[type] IS NULL AND [source].[type] IS NOT NULL) OR ([target].[type] IS NOT NULL AND [source].[type] IS NULL)) OR
	([target].[undprice] <> [source].[undprice] OR ([target].[undprice] IS NULL AND [source].[undprice] IS NOT NULL) OR ([target].[undprice] IS NOT NULL AND [source].[undprice] IS NULL)) OR
	([target].[userid] <> [source].[userid] OR ([target].[userid] IS NULL AND [source].[userid] IS NOT NULL) OR ([target].[userid] IS NOT NULL AND [source].[userid] IS NULL))

)
	THEN UPDATE
	SET
		[ts_end] = @Timestamp


	OUTPUT
		$Action as [MERGE_ACTION_4dbb23f5-2211-4586-8d5e-13d5a812724c],
		[source].[account] AS [account],
		[source].[acctsubtype] AS [acctsubtype],
		[source].[asof] AS [asof],
		[source].[auth] AS [auth],
		[source].[bidlist] AS [bidlist],
		[source].[block] AS [block],
		[source].[blotter] AS [blotter],
		[source].[broker] AS [broker],
		[source].[clearance] AS [clearance],
		[source].[comm] AS [comm],
		[source].[comment] AS [comment],
		[source].[contraacct] AS [contraacct],
		[source].[contrabroker] AS [contrabroker],
		[source].[contracode] AS [contracode],
		[source].[cxlentry] AS [cxlentry],
		[source].[cxlsentflag] AS [cxlsentflag],
		[source].[cxltag] AS [cxltag],
		[source].[cxltime] AS [cxltime],
		[source].[destination] AS [destination],
		[source].[entrydate] AS [entrydate],
		[source].[entryflag] AS [entryflag],
		[source].[exchange] AS [exchange],
		[source].[filler1] AS [filler1],
		[source].[fxmoney] AS [fxmoney],
		[source].[fxrate] AS [fxrate],
		[source].[id] AS [id],
		[source].[interest] AS [interest],
		[source].[interestflag] AS [interestflag],
		[source].[location] AS [location],
		[source].[money] AS [money],
		[source].[openclose] AS [openclose],
		[source].[orderdate] AS [orderdate],
		[source].[orderentry] AS [orderentry],
		[source].[ordersymbol] AS [ordersymbol],
		[source].[ordertag] AS [ordertag],
		[source].[price] AS [price],
		[source].[quantity] AS [quantity],
		[source].[rectype] AS [rectype],
		[source].[regfee] AS [regfee],
		[source].[regid] AS [regid],
		[source].[regstatus] AS [regstatus],
		[source].[regtime] AS [regtime],
		[source].[reportflag] AS [reportflag],
		[source].[route] AS [route],
		[source].[secfee] AS [secfee],
		[source].[seqnum] AS [seqnum],
		[source].[seqnum2] AS [seqnum2],
		[source].[settle] AS [settle],
		[source].[settleflag] AS [settleflag],
		[source].[source] AS [source],
		[source].[status] AS [status],
		[source].[strategy] AS [strategy],
		[source].[symbol] AS [symbol],
		[source].[tag] AS [tag],
		[source].[tktcharge] AS [tktcharge],
		[source].[tradedate] AS [tradedate],
		[source].[tradeflag] AS [tradeflag],
		[source].[tradetag] AS [tradetag],
		[source].[tradetime] AS [tradetime],
		NULL AS [ts_end],
		@Timestamp AS [ts_start],
		[source].[type] AS [type],
		[source].[undprice] AS [undprice],
		[source].[userid] AS [userid]

)MERGE_OUTPUT
WHERE MERGE_OUTPUT.[MERGE_ACTION_4dbb23f5-2211-4586-8d5e-13d5a812724c] = 'UPDATE' 
	AND MERGE_OUTPUT.[account] IS NOT NULL
	AND MERGE_OUTPUT.[entrydate] IS NOT NULL
	AND MERGE_OUTPUT.[seqnum] IS NOT NULL
	AND MERGE_OUTPUT.[strategy] IS NOT NULL
	AND MERGE_OUTPUT.[symbol] IS NOT NULL
	AND MERGE_OUTPUT.[tag] IS NOT NULL
	AND MERGE_OUTPUT.[tradedate] IS NOT NULL
;

UPDATE [TMDBSQL].[dbo].[TMWTRANDB] SET ts_end = NULL WHERE (tradedate = @TimestampString) OR (entrydate =  @TimestampString)

COMMIT TRANSACTION merge_TMWTRANDB
END
GO
