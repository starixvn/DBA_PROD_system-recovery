/*
	Task -  Switching sync settled ticket from DB53 to DB052
	1- Restoring certificate from db052
	2- Changing route from db053 to db052

	Run on DB042
*/

USE master
GO

--Resotring target certificates so that message received
--from target can be decrypted
CREATE CERTIFICATE SSBS_LOG_Cert
   AUTHORIZATION dba_cert_User
   FROM FILE = N'D:\\SSBSQLCertificates\SSBS_LOG_Cert.cer'
GO

USE [ServiceBrokerDB]
GO

DROP ROUTE [Route_Settled_Ticket_BETRUNNING]
GO

CREATE ROUTE [Route_Settled_Ticket_BETRUNNING]   WITH  SERVICE_NAME  = N'Service_Settled_Ticket_DBAGE' ,  ADDRESS  = N'TCP://DB052:4741'
GO
