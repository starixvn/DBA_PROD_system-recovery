/*
	Creator:	20181017@Billy
	Job Name:	[SPU_FraudDetection: Del Old Data]
	Server:		DB054
	Revision:
		- 20181017@Billy:	Backup for Fraud Detection system (Fraud Sensor 1.0) - [Redmine: #103348]
*/

SET NOCOUNT ON;

USE msdb;
GO

BEGIN TRANSACTION;

DECLARE @ReturnCode		INT
	,	@jobId			BINARY(16)
	,	@loop			INT
	,	@stepname		NVARCHAR(128)
	,	@msg			NVARCHAR(MAX)
	;

-- Input --
DECLARE	@category		NVARCHAR(128)	= N'Fraud Sensor'
	,	@jobname		NVARCHAR(128)	= N'SPU_FraudDetection: Del Old Data'
	,	@description	NVARCHAR(512)	= N'Delete old bet before balance up'
	,	@emailoperator	NVARCHAR(128)	= N''
	,	@steps			INT				= 2
	;

SELECT	@ReturnCode		= 0;

IF	ISNULL(@category, N'') = N''
OR	ISNULL(@jobname, N'') = N''
BEGIN;
	RAISERROR('Invalid Input!', 16, 1) WITH NOWAIT;
	RETURN;
END;

-- Add category --
IF	NOT EXISTS (
		SELECT	ctg.name
		FROM	msdb.dbo.syscategories AS ctg WITH (NOLOCK)
		WHERE	ctg.name = @category
			AND	ctg.category_class = 1
	)
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_add_category
							@class	= N'JOB'
						,	@type	= N'LOCAL'
						,	@name	= @category
						;
	
	IF	@@ERROR <> 0 OR	@ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'CATEGORY ADDED';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

-- Add job --
SELECT	@jobId	= job.job_id
FROM	msdb.dbo.sysjobs AS job WITH (NOLOCK)
WHERE	job.name = @jobname;

IF	@@ROWCOUNT = 0 AND @jobId IS NULL
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_add_job
							@job_name					= @jobname
						,	@job_id						= @jobId OUTPUT
						;

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'JOB ADDED';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

-- Init job steps --
BEGIN;
	SELECT	@loop	= 1
		;

	WHILE	@loop <= @steps
	BEGIN;
		SELECT	@stepname	= N'Step ' + CAST(@loop AS NVARCHAR);

		EXECUTE	@ReturnCode	= msdb.dbo.sp_add_jobstep
								@job_id						= @jobId
							,	@step_name					= @stepname
							,	@step_id					= @loop
							;
					
		IF	@@ERROR <> 0 OR @ReturnCode <> 0
			GOTO QuitWithRollback;

		SELECT	@loop = @loop + 1;
	END;

	SELECT	@msg = N'INITIATED ' + CAST(@steps AS NVARCHAR) + N' STEPS';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

-- Define job --
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_update_job
							@job_id						= @jobId
						,	@new_name					= @jobname
						,	@enabled					= 1
						,	@notify_level_eventlog		= 0
						,	@notify_level_email			= 0
						,	@notify_level_netsend		= 0
						,	@notify_level_page			= 0
						,	@delete_level				= 0
						,	@description				= @description
						,	@category_name				= @category
						,	@owner_login_name			= N'sa'
						,	@notify_email_operator_name	= @emailoperator
						;

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'JOB ADDED';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

-- Define job steps --
---- Step 1 ----
BEGIN;
	SELECT	@loop = 1;

	EXECUTE	@ReturnCode	= msdb.dbo.sp_update_jobstep
							@job_id						= @jobId
						,	@step_name					= N'Del old bet IP'
						,	@step_id					= @loop
						,	@cmdexec_success_code		= 0
						,	@on_success_action			= 3
						,	@on_success_step_id			= 0
						,	@on_fail_action				= 2
						,	@on_fail_step_id			= 0
						,	@retry_attempts				= 0
						,	@retry_interval				= 0
						,	@os_run_priority			= 0
						,	@subsystem					= N'TSQL'
						,	@database_name				= N'SPU_FraudDetection'
						,	@flags						= 0
						,	@command					= N'
EXECUTE dbo.FD_TicketsRemoveBeforeBalanceUp;
';

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'STEP %d UPDATED';
	RAISERROR(@msg, 0, 0, @loop) WITH NOWAIT;
END;

---- Step 2 ----
BEGIN;
	SELECT	@loop = 2;

	EXECUTE	@ReturnCode	= msdb.dbo.sp_update_jobstep
							@job_id						= @jobId
						,	@step_name					= N'Del old userlog'
						,	@step_id					= @loop
						,	@cmdexec_success_code		= 0
						,	@on_success_action			= 1
						,	@on_success_step_id			= 0
						,	@on_fail_action				= 2
						,	@on_fail_step_id			= 0
						,	@retry_attempts				= 0
						,	@retry_interval				= 0
						,	@os_run_priority			= 0
						,	@subsystem					= N'TSQL'
						,	@database_name				= N'SPU_FraudDetection'
						,	@flags						= 0
						,	@command					= N'
EXECUTE dbo.FD_UserLogsRemove;
';

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'STEP %d UPDATED';
	RAISERROR(@msg, 0, 0, @loop) WITH NOWAIT;
END;

---- Job start at step ----
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_update_job
							@job_id						= @jobId
						,	@start_step_id				= 1
						;

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'UPDATED START STEP';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

-- Job schedule --
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_add_jobschedule
							@job_id						= @jobId
						,	@name						= N'Weekly after Bal-up'
						,	@enabled					= 1
						,	@freq_type					= 8
						,	@freq_interval				= 33
						,	@freq_subday_type			= 1
						,	@freq_subday_interval		= 0
						,	@freq_relative_interval		= 0
						,	@freq_recurrence_factor		= 1
						,	@active_start_date			= 20160711
						,	@active_end_date			= 99991231
						,	@active_start_time			= 040000
						,	@active_end_time			= 235959
						;

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'ADDED JOB SCHEDULE';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

-- Job server --
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_add_jobserver
							@job_id						= @jobId
						,	@server_name				= N'(local)'
						;

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'JOB SERVER ADDED';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

-- All success -- Commit changes --
COMMIT TRANSACTION;
SELECT	@msg = N'*** JOB CREATED SUCCESSFULLY ***';
RAISERROR(@msg, 0, 0) WITH NOWAIT;
GOTO EndSave;

-- Jump point -- Failure --
QuitWithRollback:
IF	@@TRANCOUNT > 0
	ROLLBACK TRANSACTION;

-- Jump point -- Finish --
EndSave:
GO