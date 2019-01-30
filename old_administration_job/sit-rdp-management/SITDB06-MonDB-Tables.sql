USE [MonDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[vnDBA_RDP_Sessions](
	[ServerName] [varchar](128) NULL,
	[SessionId] [int] NULL,
	[SessionState] [varchar](128) NULL,
	[IPAddress] [varchar](64) NULL,
	[ClientName] [varchar](128) NULL,
	[WindowStationName] [varchar](128) NULL,
	[UserName] [varchar](128) NULL,
	[ConnectTime] [datetime] NULL,
	[DisconnectTime] [datetime] NULL,
	[LastInputTime] [datetime] NULL,
	[CurrentTime] [datetime] NULL,
	[SessionStatusId] [smallint] NULL,
	[SessionStatus] [varchar](128) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


USE [MonDB]
CREATE CLUSTERED INDEX [CIX_vnDBA_RDP_Sessions] ON [dbo].[vnDBA_RDP_Sessions] 
(
	[ServerName] ASC,
	[SessionId] ASC,
	[CurrentTime] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


USE [MonDB]
CREATE NONCLUSTERED INDEX [IX_vnDBA_RDP_Sessions_CurrentTime_SessionStatusId] ON [dbo].[vnDBA_RDP_Sessions] 
(
	[CurrentTime] ASC,
	[SessionStatusId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

USE [MonDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[vnDBA_RDP_Sessions_bk](
	[ServerName] [varchar](128) NULL,
	[SessionId] [int] NULL,
	[SessionState] [varchar](128) NULL,
	[IPAddress] [varchar](64) NULL,
	[ClientName] [varchar](128) NULL,
	[WindowStationName] [varchar](128) NULL,
	[UserName] [varchar](128) NULL,
	[ConnectTime] [datetime] NULL,
	[DisconnectTime] [datetime] NULL,
	[LastInputTime] [datetime] NULL,
	[CurrentTime] [datetime] NULL,
	[SessionStatusId] [smallint] NULL,
	[SessionStatus] [varchar](128) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


USE [MonDB]
CREATE CLUSTERED INDEX [CIX_vnDBA_RDP_Sessions_bk] ON [dbo].[vnDBA_RDP_Sessions_bk] 
(
	[ServerName] ASC,
	[SessionId] ASC,
	[CurrentTime] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


USE [MonDB]
CREATE NONCLUSTERED INDEX [IX_vnDBA_RDP_Sessions_bk_CurrentTime_SessionStatusId_bk] ON [dbo].[vnDBA_RDP_Sessions_bk] 
(
	[CurrentTime] ASC,
	[SessionStatusId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

USE [MonDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[vnDBA_RDP_Excluded](
	[ServerName] [varchar](128) NULL,
	[UserName] [varchar](128) NULL,
	[ClientName] [varchar](128) NULL,
	[ForcedExcluded] [bit] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


USE [MonDB]
CREATE CLUSTERED INDEX [CIX_vnDBA_RDP_Excluded] ON [dbo].[vnDBA_RDP_Excluded] 
(
	[ServerName] ASC,
	[UserName] ASC,
	[ClientName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

