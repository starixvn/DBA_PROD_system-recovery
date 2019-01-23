/*
	Task -  Switching bodb_customerLog from db052 to db054

	Run on DB054
*/

USE [bodb_CustomerLog]
GO

DROP ROUTE [Route_CustomerLog_DBLOG_BK]
GO

CREATE ROUTE [Route_CustomerLog_DBLOG_BK]   WITH  SERVICE_NAME  = N'Service_CustomerLog_DBLOG_BK' ,  ADDRESS  = N'TCP://DB052:4741' 
GO
