CREATE TABLE [dbo].[TMWSECDB_audit]
(
[Package Name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Execution Instance] [uniqueidentifier] NULL,
[Machine Name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Start Time] [datetime] NULL,
[Existing Dimension Input Row Count] [int] NULL,
[Special Members Input Row Count] [int] NULL,
[Source System Input Row Count] [int] NULL,
[Unchanged Output Row Count] [int] NULL,
[New Output Row Count] [int] NULL,
[Deleted Output Row Count] [int] NULL,
[SCD2 Expired Output Row Count] [int] NULL,
[SCD2 New Output Row Count] [int] NULL,
[SCD1 Updated Output Row Count] [int] NULL,
[Invalid Input Output Row Count] [int] NULL,
[Time First Existing Dimension Row Received] [datetime] NULL,
[Time Last Existing Dimension Row Received] [datetime] NULL,
[Time First Special Members Row Received] [datetime] NULL,
[Time Last Special Members Row Received] [datetime] NULL,
[Time First Source System Row Received] [datetime] NULL,
[Time Last Source System Row Received] [datetime] NULL,
[Milliseconds until first key match] [int] NULL,
[Number of rows held in cache on first key match] [int] NULL,
[Maximum number of rows held in cache] [int] NULL,
[Average number of rows held in cache] [int] NULL,
[Milliseconds of Upstream Backpressure Generated] [int] NULL,
[Sort Optimization Cache Hit Percentage] [numeric] (5, 2) NULL,
[Time First Output Row Produced] [datetime] NULL,
[Time Last Output Row Produced] [datetime] NULL,
[Milliseconds of Downstream Backpressure Experienced] [int] NULL,
[Maximum Output Rows per Second] [int] NULL
) ON [PRIMARY]
GO