CREATE TABLE [dbo].[TICKDB_TYPE]
(
[bbsecurity] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[value] [decimal] (12, 6) NOT NULL,
[delayed] [bit] NOT NULL,
[markethours] [bit] NOT NULL,
[tsbb] [datetime2] NOT NULL,
[ts] [datetime2] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TICKDB_TYPE] ADD CONSTRAINT [PK_TICKDB_TYPE_QA] PRIMARY KEY CLUSTERED ([bbsecurity], [type], [src]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
