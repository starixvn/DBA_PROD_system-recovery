/*
	Task -  Switching sync settled ticket from DB53 to DB052
	1- Initialize data

	Run on DB052
*/

INSERT INTO Tickets_settled_setting(sKey, sValue) VALUES('TransitionId', '0')

INSERT INTO [sb].[ConfigurationReference]([FunctionName],[MaxReceiveMsg],[MaxReceiveTimeOut])
VALUES('BETRUNNING',100,100)

INSERT INTO [sb].[ConfigurationReferenceDetail]([FunctionName],[ContractName],[MessageType],[MinConversation],[MaxConversation])
VALUES ('BETRUNNING','Contract_Settled_Ticket','MessageType_Settled_Ticket',0,20)

--create 10 conversation
EXEC [Sb].[ConversationManagement_Upd] 
		@functionName = 'BETRUNNING'
	  , @contractName = 'Contract_Settled_Ticket'		  
	  , @fromService = 'Service_Settled_Ticket_DBAGE'
	  , @toService = 'Service_Settled_Ticket_BETRUNNING'
	  , @newCnt = 10
	  
GO

