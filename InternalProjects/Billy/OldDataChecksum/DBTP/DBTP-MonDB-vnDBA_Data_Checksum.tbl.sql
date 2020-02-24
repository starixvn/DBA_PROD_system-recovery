USE [MonDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[vnDBA_Data_Checksum](
	[check_date] [datetime] NOT NULL,
	[src_name] [nvarchar](128) NOT NULL,
	[dst_name] [nvarchar](128) NOT NULL,
	[tbl_name] [nvarchar](128) NOT NULL,
	[col_name] [nvarchar](128) NOT NULL,
	[low_value] [bigint] NOT NULL,
	[high_value] [bigint] NOT NULL,
	[src_checksum] [bigint] NULL,
	[dst_checksum] [bigint] NULL,
	[src_duration] [bigint] NULL,
	[dst_duration] [bigint] NULL,
	[is_done] [bit] NULL,
 CONSTRAINT [PK_vnDBA_Data_Checksum] PRIMARY KEY CLUSTERED 
(
	[check_date] DESC,
	[src_name] ASC,
	[dst_name] ASC,
	[tbl_name] ASC,
	[low_value] ASC,
	[high_value] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

