/*
	Task -  Switching bodb_customerLog from db052 to db054

	Run on DBCUST
*/

use bodb_customerlog
go

select * into pendding_messages
from sys.transmission_queue

go
