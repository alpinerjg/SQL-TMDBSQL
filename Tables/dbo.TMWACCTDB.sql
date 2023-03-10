CREATE TABLE [dbo].[TMWACCTDB]
(
[account] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ts_start] [datetime] NOT NULL,
[ts_end] [datetime] NULL,
[descr] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trader] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[defbackacct] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[active] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[test] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[opendate] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[closedate] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[longrate] [real] NULL,
[shortrate] [real] NULL,
[shortratecode] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[capital] [float] NULL,
[sort] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[currency] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cppaid_percent] [real] NULL,
[group1] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group2] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group3] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group4] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group5] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group6] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group7] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group8] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group9] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group10] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group11] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group12] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group13] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group14] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group15] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group16] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group17] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group18] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group19] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group20] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[intercode] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b1type1] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b1type2] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b1type3] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b1type4] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b1type5] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b1backaccount] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b2type1] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b2type2] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b2type3] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b2type4] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b2type5] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b2backaccount] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b3type1] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b3type2] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b3type3] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b3type4] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b3type5] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b3backaccount] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b4type1] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b4type2] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b4type3] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b4type4] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b4type5] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b4backaccount] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b5type1] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b5type2] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b5type3] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b5type4] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b5type5] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b5backaccount] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b6type1] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b6type2] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b6type3] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b6type4] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b6type5] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b6backaccount] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b7type1] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b7type2] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b7type3] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b7type4] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b7type5] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b7backaccount] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b8type1] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b8type2] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b8type3] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b8type4] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b8type5] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b8backaccount] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b9type1] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b9type2] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b9type3] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b9type4] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b9type5] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b9backaccount] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b10type1] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b10type2] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b10type3] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b10type4] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b10type5] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b10backaccount] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TMWACCTDB] ADD CONSTRAINT [PK_TMWACCTDB] PRIMARY KEY CLUSTERED ([account], [ts_start] DESC) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [index_active] ON [dbo].[TMWACCTDB] ([active]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [index_test] ON [dbo].[TMWACCTDB] ([test]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
