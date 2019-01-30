/*
	Creator:	20190130@Billy
	Task:		HA SOP - DB06 - bodb_TGRS - Step 1 - [Redmine: #000000]
	Server:		DB06
*/


--	BEGIN STEP 1:
--		Disconnect users on primary bodb_TGRS
----------------------------------------------------------------------------------------------------

USE	bodb_TGRS;
GO

ALTER DATABASE bodb_TGRS SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO


--	BEGIN STEP 2:
--		Run job backup log for primary bodb_TGRS
----------------------------------------------------------------------------------------------------

EXECUTE	msdb.dbo.sp_start_job @job_name = N'LSBackup_bodb_TGRS';
GO


--	BEGIN STEP 3:
--		Disable related jobs on DB06
----------------------------------------------------------------------------------------------------

EXECUTE	msdb.dbo.sp_update_job @job_name = N'TGRS-Staging Data Daily', @enabled = 0;
EXECUTE	msdb.dbo.sp_update_job @job_name = N'TGRS-Staging Data Hourly', @enabled = 0;
EXECUTE	msdb.dbo.sp_update_job @job_name = N'TGRS-Staging OS Data Daily', @enabled = 0;
GO