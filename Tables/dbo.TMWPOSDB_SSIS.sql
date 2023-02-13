CREATE TABLE [dbo].[TMWPOSDB_SSIS]
(
[account] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[strategy] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ts_start] [datetime] NOT NULL,
[ts_end] [datetime] NULL,
[openpos] [int] NULL,
[daypos] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TMWPOSDB_SSIS] ADD CONSTRAINT [PK_TMWPOSDB_SSIS] PRIMARY KEY CLUSTERED ([account], [strategy], [symbol], [ts_start] DESC) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
