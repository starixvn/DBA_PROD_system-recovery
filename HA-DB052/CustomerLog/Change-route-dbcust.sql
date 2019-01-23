/*
	Task -  Switching bodb_customerLog from db052 to db054

	Run on DBCUST
*/

use bodb_customerlog
go

DROP ROUTE [Route_CustomerLog_DBCUST]
GO

CREATE ROUTE [Route_CustomerLog_DBCUST]   WITH  SERVICE_NAME  = N'Service_CustomerLog_DBLOG' ,  ADDRESS  = N'TCP://DB054:4742' 
GO