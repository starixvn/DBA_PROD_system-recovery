/*
	Task -  Switching sync settled ticket from DB53 to DB052
	1- Restoring certificate from db042
	2- Creating ssb objects

	Run on DB052
*/

USE master
GO
--Resotring target certificates so that message received
--from target can be decrypted
CREATE CERTIFICATE SSBS_BET_RUNNING_Cert 
   AUTHORIZATION dba_cert_User
   FROM FILE = N'D:\\SSBSQLCertificates\SSBS_BET_RUNNING_Cert.cer'
GO


USE bodb02
GO

CREATE MESSAGE TYPE [MessageType_Settled_Ticket] VALIDATION = NONE
GO

CREATE CONTRACT [Contract_Settled_Ticket] ([MessageType_Settled_Ticket] SENT BY ANY)
GO

CREATE QUEUE [dbo].[Queue_Settled_Ticket_DBAGE] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = ON)  ON [ServiceBroker] 
GO

CREATE SERVICE [Service_Settled_Ticket_DBAGE]  ON QUEUE [dbo].[Queue_Settled_Ticket_DBAGE] ([Contract_Settled_Ticket])
GO

GRANT SEND ON SERVICE::[Service_Settled_Ticket_DBAGE] TO [public] AS [dbo]
GO

CREATE ROUTE [Route_Settled_Ticket_DBAGE] WITH SERVICE_NAME = N'Service_Settled_Ticket_BETRUNNING', ADDRESS = N'TCP://DB042:4743'
GO