CREATE TABLE [dbo].[TMWSECDB_Market]
(
[symbol] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ts_start] [datetime] NOT NULL,
[ts_end] [datetime] NULL,
[longrate] [real] NULL,
[shortrate] [real] NULL,
[longmark] [float] NULL,
[shortmark] [float] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TMWSECDB_Market] ADD CONSTRAINT [PK_TMWSECDB_Market] PRIMARY KEY CLUSTERED ([symbol], [ts_start] DESC) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
