CREATE TABLE [dbo].[TFSampleDimEmployee]
(
[EmployeeID] [int] NOT NULL IDENTITY(1, 1),
[EmployeeKey] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FirstName] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastName] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Address] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[City] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[State] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Zip] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Salary] [money] NULL,
[JobTitle] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StartDate] [datetime] NOT NULL,
[EndDate] [datetime] NULL
) ON [PRIMARY]
GO
