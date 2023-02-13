CREATE TABLE [dbo].[BADSECURITY]
(
[bbsecurity] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[firstseen] [date] NOT NULL,
[mostrecent] [date] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BADSECURITY] ADD CONSTRAINT [PK_BADSECURITY] PRIMARY KEY CLUSTERED ([bbsecurity], [symbol]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
