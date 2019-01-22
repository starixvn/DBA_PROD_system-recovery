/*
	Task -  Switching sync settled ticket from DB53 to DB052
	1- Creatting tables

	Run on DB052
*/

--//Tickets_settled_setting
CREATE TABLE [dbo].[Tickets_settled_setting](
	[sKey] [varchar](30) NOT NULL,
	[sValue] [bigint] NOT NULL
) ON [PRIMARY]

GO

CREATE UNIQUE CLUSTERED INDEX [CIX_Tickets_settled_setting] ON [dbo].[Tickets_settled_setting]
(
	[sKey] ASC
)WITH (DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO

--//BetSettled_Transition
CREATE TABLE [dbo].[BetSettled_Transition](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[TransId] [bigint] NULL
) ON [Others_table]

GO

CREATE CLUSTERED INDEX [CIX_BetSettled_Transition] ON [dbo].[BetSettled_Transition]
(
	[RowId] ASC
)WITH (DROP_EXISTING = OFF, ONLINE = OFF) ON [Others_table]
GO

--//======================ssb===============================
CREATE TABLE [sb].[ConfigurationReference](
	[FunctionName] [varchar](50) NOT NULL,
	[MaxReceiveMsg] [int] NULL,
	[MaxReceiveTimeOut] [int] NULL,
	[IsExistingTarget] [bit] NULL,
 CONSTRAINT [PK_ConfigurationReference_FunctionName] PRIMARY KEY CLUSTERED 
(
	[FunctionName] ASC
) ON [ServiceBroker]
) ON [ServiceBroker]

GO

ALTER TABLE [sb].[ConfigurationReference] ADD  CONSTRAINT [DF_ConfigurationReference_MaxReceiveMsg]  DEFAULT ((1)) FOR [MaxReceiveMsg]
GO

ALTER TABLE [sb].[ConfigurationReference] ADD  CONSTRAINT [DF_ConfigurationReference_MaxReceiveTimeOut]  DEFAULT ((1)) FOR [MaxReceiveTimeOut]
GO

CREATE TABLE [sb].[ConfigurationReferenceDetail](
	[FunctionName] [varchar](50) NOT NULL,
	[ContractName] [varchar](200) NOT NULL,
	[MessageType] [varchar](200) NULL,
	[MinConversation] [int] NULL,
	[MaxConversation] [int] NULL,
 CONSTRAINT [PK_ConfigurationReferenceDetail_FunctionName_ContractName] PRIMARY KEY CLUSTERED 
(
	[FunctionName] ASC,
	[ContractName] ASC
) ON [ServiceBroker],
 CONSTRAINT [UN_ContractName_MessageType] UNIQUE NONCLUSTERED 
(
	[ContractName] ASC,
	[MessageType] ASC
) ON [ServiceBroker]
) ON [ServiceBroker]

GO

ALTER TABLE [sb].[ConfigurationReferenceDetail] ADD  CONSTRAINT [DF_ConfigurationReferenceDetail_MinConversation]  DEFAULT ((5)) FOR [MinConversation]
GO

ALTER TABLE [sb].[ConfigurationReferenceDetail] ADD  CONSTRAINT [DF_ConfigurationReferenceDetail_MaxConversation]  DEFAULT ((20)) FOR [MaxConversation]
GO

CREATE TABLE [sb].[ConversationCount](
	[FunctionName] [varchar](100) NOT NULL,
	[ContractName] [varchar](200) NOT NULL,
	[Cnt] [int] NULL,
 CONSTRAINT [PK_ConversationCount_FunctionName_ContractName] PRIMARY KEY CLUSTERED 
(
	[FunctionName] ASC,
	[ContractName] ASC
) ON [ServiceBroker]
) ON [ServiceBroker]

GO
CREATE TABLE [sb].[ConversationManagement](
	[FunctionName] [varchar](50) NOT NULL,
	[ContractName] [varchar](100) NOT NULL,
	[ConversationNo] [int] NOT NULL,
	[ConversationHandle] [uniqueidentifier] NULL,
	[CreatedDate] [datetime] NULL,
	[IsValid] [bit] NULL,
 CONSTRAINT [PK_ConversationManagement_FunctionName_ContractName_ConversationNo] PRIMARY KEY CLUSTERED 
(
	[FunctionName] ASC,
	[ContractName] ASC,
	[ConversationNo] ASC
) ON [ServiceBroker]
) ON [ServiceBroker]

GO

CREATE TABLE [sb].[ProcessingErrors](
	[error_conversation] [uniqueidentifier] NULL,
	[error_number] [int] NULL,
	[error_message] [varchar](4000) NULL,
	[error_severity] [int] NULL,
	[error_state] [int] NULL,
	[error_procedure] [sysname] NULL,
	[error_line] [int] NULL,
	[doomed_transaction] [tinyint] NULL,
	[updatedtime] [datetime] NOT NULL,
	[message] [nvarchar](max) NULL
) ON [ServiceBroker] TEXTIMAGE_ON [ServiceBroker]

GO
ALTER TABLE [sb].[ProcessingErrors] ADD  CONSTRAINT [DF_ProcessingErrors_updatedtime]  DEFAULT (getdate()) FOR [updatedtime]
GO
