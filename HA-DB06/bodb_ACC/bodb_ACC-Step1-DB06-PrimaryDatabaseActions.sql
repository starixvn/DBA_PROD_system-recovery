/*
	Creator:	20190130@Billy
	Task:		HA SOP - DB06 - bodb_ACC - Step 1 - [Redmine: #000000]
	Server:		DB06
*/


--	BEGIN STEP 1:
--		Disconnect users on primary bodb_ACC
----------------------------------------------------------------------------------------------------

USE	bodb_ACC;
GO

ALTER DATABASE bodb_ACC SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO


--	BEGIN STEP 2:
--		Run job backup log for primary bodb_ACC
----------------------------------------------------------------------------------------------------

EXECUTE	msdb.dbo.sp_start_job @job_name = N'LSBackup_bodb_ACC';
GO


--	BEGIN STEP 3:
--		Disable related jobs on DB06
----------------------------------------------------------------------------------------------------

EXECUTE	msdb.dbo.sp_update_job @job_name = N'bodb_ACC - Bet Monitoring Tool', @enabled = 0;
EXECUTE	msdb.dbo.sp_update_job @job_name = N'bodb_Acc: Update Completed Match', @enabled = 0;
GO