CREATE TABLE [dbo].[SymbolMap]
(
[symbol] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bbsecurity] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ts_start] [datetime2] NOT NULL,
[ts_end] [datetime2] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20200827-131356] ON [dbo].[SymbolMap] ([bbsecurity]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ClusteredIndex-20200827-131343] ON [dbo].[SymbolMap] ([symbol]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
