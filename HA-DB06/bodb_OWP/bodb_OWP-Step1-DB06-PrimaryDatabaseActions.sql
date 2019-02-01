/*
	Creator:	20190130@Billy
	Task:		HA SOP - DB06 - bodb_OWP - Step 1 - [Redmine: #000000]
	Server:		DB06
*/


--	BEGIN STEP 1:
--		Disconnect users on primary bodb_OWP
----------------------------------------------------------------------------------------------------

USE	bodb_OWP;
GO

ALTER DATABASE bodb_OWP SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO


--	BEGIN STEP 2:
--		Run job backup log for primary bodb_OWP
----------------------------------------------------------------------------------------------------

EXECUTE	msdb.dbo.sp_start_job @job_name = N'LSBackup_bodb_OWP';
GO


--	BEGIN STEP 3:
--		Disable related jobs on DB06
----------------------------------------------------------------------------------------------------

EXECUTE	msdb.dbo.sp_update_job @job_name = N'bodb_OWP - job: Sync InfoSite Match', @enabled = 0;
GO