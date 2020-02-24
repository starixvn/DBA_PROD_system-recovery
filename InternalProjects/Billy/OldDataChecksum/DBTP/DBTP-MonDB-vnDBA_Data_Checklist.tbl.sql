USE [MonDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[vnDBA_Data_Checklist](
	[scm_name] [nvarchar](128) NOT NULL,
	[tbl_name] [nvarchar](128) NOT NULL,
	[col_name] [nvarchar](128) NOT NULL,
	[col_type] [nvarchar](128) NOT NULL,
	[interval] [bigint] NOT NULL,
	[src_server] [nvarchar](128) NOT NULL,
	[src_database] [nvarchar](128) NOT NULL,
	[dst_server] [nvarchar](128) NOT NULL,
	[dst_database] [nvarchar](128) NOT NULL,
	[is_active] [bit] NOT NULL,
 CONSTRAINT [PK_vnDBA_Data_Checklist] PRIMARY KEY CLUSTERED 
(
	[src_server] ASC,
	[src_database] ASC,
	[dst_server] ASC,
	[dst_database] ASC,
	[tbl_name] ASC,
	[col_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[vnDBA_Data_Checklist] ADD  CONSTRAINT [DF_vnDBA_Data_Checklist]  DEFAULT (N'dbo') FOR [scm_name]
GO


INSERT INTO	vnDBA_Data_Checklist
	(	[scm_name], [tbl_name], [col_name], [col_type], [interval], [src_server], [src_database], [dst_server], [dst_database], [is_active])
SELECT N'dbo', N'CustBetSetting3rd_Agent', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustBetSetting3rd_Member', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustDiscount3rd_Agent', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustDiscount3rd_Member', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'custinfo', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'customer', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'custOverride', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'custOverride3rd', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustOverrideGame', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustProductStatus', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustPTGroupSetting3rd_Member', N'agentid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustPTSetting3rd_Agent', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustPTSetting3rd_Member', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'custSetting', N'custid', N'BIGINT', 50000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustSetting3rd', N'custid', N'BIGINT', 50000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustSettingGame', N'custid', N'BIGINT', 50000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustStakeLevel_Agent', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustStakeLevel_Member', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustVirtualSetting', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustWinlossLimit_Agent', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustWinlossLimit_Member', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustBetSetting_Agent', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustBetSetting_Member', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustDiscountSetting_Agent', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustDiscountSetting_Member', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustProductSetting', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustProductStatus', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustPTSetting_Agent', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustPTSetting_Member', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustSetting', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustSetting3rd', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustSettingGame', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustStakeLevel_Agent', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustStakeLevel_Member', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DB06', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustBetSetting3rd_Agent', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustBetSetting3rd_Member', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustDiscount3rd_Agent', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustDiscount3rd_Member', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'custinfo', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'customer', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'custOverride', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'custOverride3rd', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustOverrideGame', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustProductStatus', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustPTGroupSetting3rd_Member', N'agentid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustPTSetting3rd_Agent', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustPTSetting3rd_Member', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'custSetting', N'custid', N'BIGINT', 50000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustSetting3rd', N'custid', N'BIGINT', 50000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustSettingGame', N'custid', N'BIGINT', 50000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustStakeLevel_Agent', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustStakeLevel_Member', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustVirtualSetting', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustWinlossLimit_Agent', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'CustWinlossLimit_Member', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustBetSetting_Agent', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustBetSetting_Member', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustDiscountSetting_Agent', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustDiscountSetting_Member', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustProductSetting', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustProductStatus', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustPTSetting_Agent', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustPTSetting_Member', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustSetting', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustSetting3rd', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustSettingGame', N'custid', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustStakeLevel_Agent', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1 UNION ALL
SELECT N'dbo', N'Dep_CustStakeLevel_Member', N'CustID', N'BIGINT', 200000, N'DBCUST', N'CustDB', N'DBTP', N'bodb02', 1
