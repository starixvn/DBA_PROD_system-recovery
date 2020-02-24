USE [msdb]
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'vnDBA : Checksum table', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'vnDBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Checksum', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @check_date		DATETIME
	,	@msg			NVARCHAR(MAX)
	;

SELECT	@check_date = DATEADD(MINUTE, DATEDIFF(MINUTE, 0, GETDATE()), 0);

INSERT INTO	dbo.vnDBA_Data_Checksum
		(	 check_date, src_name, dst_name, tbl_name, col_name, low_value, high_value, src_checksum, dst_checksum, src_duration, dst_duration, is_done)
VALUES	(	@check_date, N''''     , N''''     , N''''     , N''''     , 0        , 0         , 0           , 1           , 0           , 0           , 1      );

CREATE TABLE	#checklist (
					scm_name		NVARCHAR(128)
				,	tbl_name		NVARCHAR(128)
				,	col_name		NVARCHAR(128)
				,	col_type		NVARCHAR(128)
				,	interval		BIGINT
				,	src_server		NVARCHAR(128)
				,	src_database	NVARCHAR(128)
				,	dst_server		NVARCHAR(128)
				,	dst_database	NVARCHAR(128)
				,	is_done			BIT
				)

DECLARE	@scm_name		NVARCHAR(128)
	,	@tbl_name		NVARCHAR(128)
	,	@col_name		NVARCHAR(128)
	,	@interval		BIGINT
	,	@src_server		NVARCHAR(128)
	,	@src_database	NVARCHAR(128)
	,	@dst_server		NVARCHAR(128)
	,	@dst_database	NVARCHAR(128)
	;

INSERT INTO	#checklist
	(	scm_name, tbl_name, col_name, col_type, interval, src_server, src_database, dst_server, dst_database, is_done)
SELECT	scm_name, tbl_name, col_name, col_type, interval, src_server, src_database, dst_server, dst_database, 0
FROM	MonDB.dbo.vnDBA_Data_Checklist WITH (NOLOCK)
WHERE	is_active = 1;

WHILE	0 = 0
BEGIN
	UPDATE	TOP(1) #checklist
	SET		@scm_name		= scm_name
		,	@tbl_name		= tbl_name
		,	@col_name		= CASE	WHEN col_type LIKE ''%INT%'' THEN col_name
									WHEN col_type LIKE ''%DATE%'' OR col_type LIKE ''%TIME%'' THEN N''DATEDIFF(MINUTE, 0, '' + col_name + N'')''
									ELSE col_name
							  END
		,	@interval		= interval
		,	@src_server		= src_server
		,	@src_database	= src_database
		,	@dst_server		= dst_server
		,	@dst_database	= dst_database
		,	is_done = 1
	WHERE	is_done = 0;
	
	IF	@@ROWCOUNT = 0
		BREAK;

	EXECUTE	MonDB.dbo.vnDBA_sp_Data_Checksum
				@src_server		= @src_server
			,	@src_database	= @src_database
			,	@dst_server		= @dst_server
			,	@dst_database	= @dst_database
			,	@tbl_name		= @tbl_name
			,	@col_name		= @col_name
			,	@interval		= @interval
			,	@sch_name		= @scm_name
			,	@check_date		= @check_date
			;
  
	IF	EXISTS(
		SELECT	1
		FROM	MonDB.dbo.vnDBA_Data_Checksum WITH (NOLOCK)
		WHERE	check_date = @check_date
			AND	src_name	= ISNULL(@src_server + N''.'', '''') + @src_database
			AND	dst_name	= ISNULL(@dst_server + N''.'', '''') + @dst_database
			AND	tbl_name	= @scm_name + N''.'' + @tbl_name
			AND	col_name	= @col_name
			AND	src_checksum <> dst_checksum
	)
	BEGIN
		SELECT	@msg = N''Table '' + @scm_name + N''.'' + @tbl_name + N'' Checksum FAIL!!!''
	
		RAISERROR(@msg, 0, 0) WITH NOWAIT;
	END;
END;', 
		@database_name=N'MonDB', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Email', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE	vnDBA_sp_Data_EmailChecksumReport
			@to = ''DBAAdmin@starixsoft.com;vivi.kao@onelab.tw''', 
		@database_name=N'MonDB', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Checksum', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=27, 
		@freq_subday_type=1, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20160811, 
		@active_end_date=99991231, 
		@active_start_time=190000, 
		@active_end_time=235959, 
		@schedule_uid=N'33d701d9-5f82-422a-b58c-32c974d166f4'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

