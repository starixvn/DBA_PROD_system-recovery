/*
	Task -  Switching bodb_customerLog from db052 to db054

	Run on DBCUST
*/

--deploy sp first
--https://gitlab.nexcel.vn/DBA_PROD/database-administration/blob/98302-Troubleshoot-checklist/scripts/servicebroker/DBA_ConversationManagement.sql

-- #1.3 - WRITELOG - DBCUST/bodb_CustomerLog
EXEC [Sb].[DBA_ConversationManagement] 
		@functionName = 'Login'
	  , @contractName = 'Contract_CustomerLog_UserLog_Login'		  
	  , @fromService = 'Service_CustomerLog_DBCUST'
	  , @toService = 'Service_CustomerLog_DBLOG'
	  , @Coversation_number = 10
	  , @Mode = 'Reset'	
	  
EXEC [Sb].[DBA_ConversationManagement] 
		@functionName = 'Login'
	  , @contractName = 'Contract_CustomerLog_eaUserLog_Login'		  
	  , @fromService = 'Service_CustomerLog_DBCUST'
	  , @toService = 'Service_CustomerLog_DBLOG'
	  , @Coversation_number = 5
	  , @Mode = 'Reset'
