CREATE TABLE [dbo].[TICKDB_LAG_HISTORY]
(
[ts] [datetime] NOT NULL,
[bbsecurity] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cnt] [int] NOT NULL,
[cntlag30plus] [int] NOT NULL,
[maxlag] [int] NOT NULL,
[avgtop1pctlag] [int] NOT NULL,
[avgtop5pctlag] [int] NOT NULL,
[avgtop10pctlag] [int] NOT NULL,
[avgtop25pctlag] [int] NOT NULL,
[avglag] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TICKDB_LAG_HISTORY] ADD CONSTRAINT [PK_TICKDB_LAG_HISTORY] PRIMARY KEY CLUSTERED ([ts]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
