USE [bodb_archive]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE	[dbo].[Task_DBTP_CheckRowcount]
AS
/*
	Creator:	20170427@Billy
	Task:		Check bodb_Archive tables' rowcount - [Redmine: #00000]
	Database:	DB06.bodb_Archive
		
	Revisions:
		- 20170627@Billy:	Add table type 5: MatchEventDate - [Redmine: #79047]
		- 20171222@Billy:	Add dynamic database support & Bring DB06 rowcount check to Child SP
							Add table type 6: accdate
							Add table type 7: ArchiveDate
							[Redmine: #88591]
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE	@18months		DATETIME
		,	@databasename	NVARCHAR(128)
		,	@tablename		NVARCHAR(128)
		,	@winlostdate	DATETIME
		,	@query			NVARCHAR(MAX)
		;

	CREATE TABLE	#DBTP (
						databasename	NVARCHAR(128)
					,	tablename		NVARCHAR(128)
					,	winlostdate		DATETIME
					,	DBTP_rowcount	BIGINT
					,	timetype		VARCHAR(10)
					);

	CREATE TABLE	#DB06 (
						databasename	NVARCHAR(128)
					,	tablename		NVARCHAR(128)
					,	winlostdate		DATETIME
					,	DB06_rowcount	BIGINT
					,	timetype		VARCHAR(10)
					);

	-- Truncate rowcount table --
	TRUNCATE TABLE	Task_DBTP_ArchiveCheckRowcount;

	-- Select 18 months ago date --
	SELECT	@18months = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 17, 0);

	-- Import data from DBTP --
	INSERT INTO	#DBTP (databasename, tablename, winlostdate, DBTP_rowcount, timetype)
	SELECT	databasename, tablename, winlostdate, DBTP_rowcount, timetype
	FROM	OPENQUERY(DBTP, 'EXECUTE bodb_Archive.dbo.Task_DBTP_CheckRowcount_Child @step = 1;')
	WHERE	ISNULL(winlostdate, @18months) >= @18months;
	
	-- Import data from DB06 --
	INSERT INTO	#DB06 (databasename, tablename, winlostdate, DB06_rowcount, timetype)
	EXECUTE	bodb_Archive.dbo.Task_DBTP_CheckRowcount_Child @step = 1;

	DELETE	#DB06
	WHERE	winlostdate < @18months;

	-- Insert day level rowcount --
	INSERT INTO	Task_DBTP_ArchiveCheckRowcount (databasename, tablename, winlostdate, DB06_rowcount, DBTP_rowcount, timetype)
	SELECT	ISNULL(_06.databasename, _tp.databasename)
		,	ISNULL(_06.tablename, _tp.tablename)
		,	ISNULL(_06.winlostdate, _tp.winlostdate)
		,	ISNULL(_06.DB06_rowcount, 0)
		,	ISNULL(_tp.DBTP_rowcount, 0)
		,	ISNULL(_06.timetype, _tp.timetype)
	FROM			#DB06 _06
	FULL OUTER JOIN	#DBTP _tp 
				ON	_06.databasename = _tp.databasename
				AND	_06.tablename = _tp.tablename
				AND	ISNULL(_06.winlostdate, 0) = ISNULL(_tp.winlostdate, 0)
				AND	_06.timetype = _tp.timetype;

	-- Keep only mismatch result --
	DELETE	tbl
	FROM	Task_DBTP_ArchiveCheckRowcount tbl
	WHERE	tbl.DB06_rowcount = tbl.DBTP_rowcount;

	-- Clear temp table data --
	TRUNCATE TABLE	#DB06;
	TRUNCATE TABLE	#DBTP;

	-- Count number of rows --
	WHILE	0 = 0
	BEGIN
		SELECT	@databasename	= NULL
			,	@tablename		= NULL
			,	@winlostdate	= NULL
			;

		SELECT	TOP(1)
				@databasename	= databasename
			,	@tablename		= tablename
			,	@winlostdate	= winlostdate
		FROM	Task_DBTP_ArchiveCheckRowcount WITH (NOLOCK)
		WHERE	timetype		= 'PROCESSING';

		IF	@tablename IS NULL AND @winlostdate IS NULL
		BEGIN
			UPDATE	TOP(1) Task_DBTP_ArchiveCheckRowcount
			SET		@databasename	= databasename
				,	@tablename		= tablename
				,	@winlostdate	= winlostdate
				,	timetype		= 'PROCESSING'
			WHERE	timetype		= 'MONTH';
		END;

		IF	@tablename IS NULL AND @winlostdate IS NULL
			BREAK;

		INSERT INTO	#DB06 (databasename, tablename, winlostdate, DB06_rowcount, timetype)
		EXECUTE bodb_Archive.dbo.Task_DBTP_CheckRowcount_Child @step = 2;

		INSERT INTO	#DBTP (databasename, tablename, winlostdate, DBTP_rowcount, timetype)
		SELECT	databasename, tablename, winlostdate, DBTP_rowcount, timetype
		FROM	OPENQUERY(DBTP, 'EXECUTE bodb_Archive.dbo.Task_DBTP_CheckRowcount_Child @step = 2;');

		UPDATE	TOP(1) Task_DBTP_ArchiveCheckRowcount
		SET		timetype		= NULL
		WHERE	timetype		= 'PROCESSING'
			AND	databasename	= @databasename
			AND	tablename		= @tablename
			AND	ISNULL(winlostdate, 0) = ISNULL(@winlostdate, 0);
	END;

	-- Delete processed data --
	DELETE	tbl
	FROM	Task_DBTP_ArchiveCheckRowcount tbl
	WHERE	timetype IS NULL;
	
	-- Insert day level rowcount --
	INSERT INTO	Task_DBTP_ArchiveCheckRowcount (databasename, tablename, winlostdate, DB06_rowcount, DBTP_rowcount, timetype)
	SELECT	ISNULL(_06.databasename, _tp.databasename)
		,	ISNULL(_06.tablename, _tp.tablename)
		,	ISNULL(_06.winlostdate, _tp.winlostdate)
		,	ISNULL(_06.DB06_rowcount, 0)
		,	ISNULL(_tp.DBTP_rowcount, 0)
		,	ISNULL(_06.timetype, _tp.timetype)
	FROM			#DB06 _06
	FULL OUTER JOIN	#DBTP _tp 
				ON	_06.databasename = _tp.databasename
				AND	_06.tablename = _tp.tablename
				AND	ISNULL(_06.winlostdate, 0) = ISNULL(_tp.winlostdate, 0)
				AND	_06.timetype = _tp.timetype;

	-- Keep only mismatch result --
	DELETE	tbl
	FROM	Task_DBTP_ArchiveCheckRowcount tbl
	WHERE	tbl.DBTP_rowcount = tbl.DB06_rowcount
		OR	tbl.DB06_rowcount = 0;
END;

GO

