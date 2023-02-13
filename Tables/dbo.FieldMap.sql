CREATE TABLE [dbo].[FieldMap]
(
[table] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[column] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[shortname] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[longname] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FieldMap] ADD CONSTRAINT [PK_FIELDMAP] PRIMARY KEY CLUSTERED ([table], [column]) WITH (FILLFACTOR=90, PAD_INDEX=ON) ON [PRIMARY]
GO
