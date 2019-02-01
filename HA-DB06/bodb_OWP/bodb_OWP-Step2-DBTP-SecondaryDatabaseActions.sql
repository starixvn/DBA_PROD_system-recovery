/*
	Creator:	20190130@Billy
	Task:		HA SOP - DBTP - bodb_OWP - Step 2 - [Redmine: #000000]
	Server:		DBTP
*/


--	BEGIN STEP 1:
--		Copy last log backup that available
----------------------------------------------------------------------------------------------------

EXECUTE	msdb.dbo.sp_start_job @job_name = N'LSCopy_DB06_bodb_OWP';
GO


--	BEGIN STEP 2:
--		Restore last log backup that available
----------------------------------------------------------------------------------------------------

EXECUTE	msdb.dbo.sp_start_job @job_name = N'LSRestore_DB06_bodb_OWP';
GO


--	BEGIN STEP 3:
--		Bring secondary database online
----------------------------------------------------------------------------------------------------

RESTORE DATABASE bodb_OWP WITH RECOVERY;
GO


--	BEGIN STEP 4:
--		Mapping users
----------------------------------------------------------------------------------------------------

USE	bodb_OWP;
GO

SELECT	DB_NAME(), dp.name, dp.sid, sp.name, sp.sid, sp.is_disabled, [sid_mapped] = sp2.name
	,	[script] = N'EXECUTE sys.sp_change_users_login ''update_one'', [' + dp.name + N'], [' + dp.name + N'];'
FROM		sys.server_principals AS sp WITH (NOLOCK)
RIGHT JOIN	sys.database_principals AS dp WITH (NOLOCK)
		ON	sp.name = dp.name
LEFT JOIN	sys.server_principals AS sp2 WITH (NOLOCK)
		ON	sp2.sid = dp.sid
WHERE	dp.type IN ('S', 'U')
	AND	dp.principal_id >= 5
	AND	ISNULL(sp.sid, 0xFF) <> ISNULL(dp.sid, 0xFE);
GO


--	BEGIN STEP 5:
--		Enable related jobs on DBTP
----------------------------------------------------------------------------------------------------

EXECUTE	msdb.dbo.sp_update_job @job_name = N'bodb_OWP - job: Sync InfoSite Match', @enabled = 1;
GO