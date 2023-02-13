CREATE TABLE [dbo].[TICKDB]
(
[bbsecurity] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price] [decimal] (12, 6) NOT NULL,
[bid] [decimal] (12, 6) NULL,
[ask] [decimal] (12, 6) NULL,
[delayed] [bit] NOT NULL,
[markethours] [bit] NOT NULL,
[src] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ts] [datetime2] NOT NULL,
[tsbb] [datetime2] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TICKDB] ADD CONSTRAINT [PK_TICKDB] PRIMARY KEY CLUSTERED ([bbsecurity], [src]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
