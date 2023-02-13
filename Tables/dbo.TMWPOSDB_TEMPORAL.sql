CREATE TABLE [dbo].[TMWPOSDB_TEMPORAL_History]
(
[account] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[strategy] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[openpos] [int] NULL,
[daypos] [int] NULL,
[ts_start] [datetime2] NOT NULL,
[ts_end] [datetime2] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ix_TMWPOSDB_TEMPORAL_History] ON [dbo].[TMWPOSDB_TEMPORAL_History] ([ts_end], [ts_start]) ON [PRIMARY]
GO
CREATE TABLE [dbo].[TMWPOSDB_TEMPORAL]
(
[account] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[strategy] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[openpos] [int] NULL,
[daypos] [int] NULL,
[ts_start] [datetime2] GENERATED ALWAYS AS ROW START NOT NULL,
[ts_end] [datetime2] GENERATED ALWAYS AS ROW END NOT NULL,
PERIOD FOR SYSTEM_TIME (ts_start, ts_end),
CONSTRAINT [PK_TMWPOSDB_TEMPORAL] PRIMARY KEY CLUSTERED ([account], [strategy], [symbol]) WITH (FILLFACTOR=90) ON [PRIMARY]
) ON [PRIMARY]
WITH
(
SYSTEM_VERSIONING = ON (HISTORY_TABLE = [dbo].[TMWPOSDB_TEMPORAL_History])
)
GO
