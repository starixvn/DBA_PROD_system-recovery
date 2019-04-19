USE [bodb_archive]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Task_DBTP_ArchiveCheckRowcount](
	[tablename] [nvarchar](128) NULL,
	[winlostdate] [datetime] NULL,
	[DB06_rowcount] [bigint] NULL,
	[DBTP_rowcount] [bigint] NULL,
	[timetype] [varchar](10) NULL,
	[databasename] [nvarchar](128) NOT NULL
) ON [DATA]

GO

SET ANSI_PADDING ON

GO

CREATE CLUSTERED INDEX [CIX_Task_DBTP_ArchiveCheckRowcount] ON [dbo].[Task_DBTP_ArchiveCheckRowcount]
(
	[tablename] ASC,
	[winlostdate] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
GO

USE [bodb_archive]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Task_DBTP_ArchiveDate](
	[winlostdate] [smalldatetime] NOT NULL,
	[isDone] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[winlostdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]

GO

ALTER TABLE [dbo].[Task_DBTP_ArchiveDate] ADD  CONSTRAINT [DF_Task_DBTP_ArchiveDate_isDone]  DEFAULT ((0)) FOR [isDone]
GO

USE [bodb_archive]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Task_DBTP_ArchiveTables](
	[db] [nvarchar](128) NOT NULL,
	[name] [nvarchar](128) NOT NULL,
	[tabletype] [int] NULL
) ON [DATA]

GO

SET ANSI_PADDING ON

GO

CREATE CLUSTERED INDEX [CIX_Task_DBTP_ArchiveTables] ON [dbo].[Task_DBTP_ArchiveTables]
(
	[db] ASC,
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
GO

