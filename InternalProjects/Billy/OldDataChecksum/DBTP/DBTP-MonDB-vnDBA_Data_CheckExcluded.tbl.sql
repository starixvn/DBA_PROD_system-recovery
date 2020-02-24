USE [MonDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[vnDBA_Data_CheckExcluded](
	[DatabaseName] [nvarchar](128) NOT NULL,
	[TableName] [nvarchar](128) NOT NULL,
	[ColumnName] [nvarchar](128) NOT NULL,
 CONSTRAINT [PK_vnDBA_Data_CheckExcluded] PRIMARY KEY CLUSTERED 
(
	[DatabaseName] ASC,
	[TableName] ASC,
	[ColumnName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

INSERT INTO	vnDBA_Data_CheckExcluded
	(	[DatabaseName], [TableName], [ColumnName])
SELECT N'bodb02', N'Customer', N'iplogin' UNION ALL
SELECT N'bodb02', N'Customer', N'lastlogged' UNION ALL
SELECT N'bodb02', N'customer', N'logincount' UNION ALL
SELECT N'bodb02', N'CustStakeLevel_Member', N'LastUpdated' UNION ALL
SELECT N'bodb02', N'Dep_CustStakeLevel_Member', N'LastUpdated' UNION ALL
SELECT N'CustDB', N'Customer', N'iplogin' UNION ALL
SELECT N'CustDB', N'Customer', N'lastlogged' UNION ALL
SELECT N'CustDB', N'customer', N'logincount' UNION ALL
SELECT N'CustDB', N'CustStakeLevel_Member', N'LastUpdated' UNION ALL
SELECT N'CustDB', N'Dep_CustStakeLevel_Member', N'LastUpdated'
