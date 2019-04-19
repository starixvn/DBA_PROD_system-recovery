USE [bodb_archive]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Task_DBTP_CheckRowcount_Child]
					@step		INT
AS
/*
	Creator:	20171222@Billy
	Task:		Check bodb_Archive tables' rowcount - [Redmine: #88591]
	Database:	DB06.bodb_Archive
		
	Revisions:
		- 20171222@Billy:	Take DB06 rowcount check into Child SP - [Redmine: #88591]
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE	@databases	TABLE (
							name			NVARCHAR(128)
						,	done			BIT
						);

	CREATE TABLE	#result	(
						databasename	NVARCHAR(128)
					,	tablename		NVARCHAR(128)
					,	winlostdate		DATETIME
					,	DB06_rowcount	BIGINT
					,	timetype		VARCHAR(10)
					);

	DECLARE	@query			NVARCHAR(MAX)
		,	@databasename	NVARCHAR(128)
		,	@tablename		NVARCHAR(128)
		,	@fromdate		DATETIME
		,	@todate			DATETIME
		,	@type			INT
		;

	IF	@step = 1
	BEGIN
		INSERT INTO	@databases (name, done)
		SELECT	DISTINCT
				at.db, 0
		FROM	bodb_Archive.dbo.Task_DBTP_ArchiveTables at WITH (NOLOCK)
		WHERE	at.tabletype IS NOT NULL;
			
		WHILE	0 = 0
		BEGIN
			SELECT	@databasename	= NULL;
		
			UPDATE	TOP(1) @databases
			SET		@databasename = name
				,	done = 1
			WHERE	done = 0;
			
			IF	@@ROWCOUNT = 0
				BREAK;
			
			SELECT	@query = N'';
			SELECT	@query = @query + N'
INSERT INTO	#result (databasename, tablename, winlostdate, DB06_rowcount, timetype)
SELECT	''datbasename''	= N''' + @databasename + N'''
	,	''tablename''		= tbl.name
	,	''winlostdate''	= pt.right_value
	,	''DB06_rowcount''	= p.rows
	,	''timetype''		= CAST(''MONTH'' AS VARCHAR(10))
FROM		bodb_Archive.dbo.Task_DBTP_ArchiveTables at WITH (NOLOCK)
INNER JOIN	' + @databasename + N'.sys.tables tbl WITH (NOLOCK)
		ON	at.name = tbl.name
INNER JOIN	' + @databasename + N'.sys.indexes idx WITH (NOLOCK)
		ON	tbl.object_id = idx.object_id
		AND	idx.type = 1 -- Clustered Index
INNER JOIN	' + @databasename + N'.sys.partitions p WITH (NOLOCK)
		ON	idx.object_id = p.object_id
		AND	idx.index_id = p.index_id
LEFT JOIN	' + @databasename + N'.sys.partition_schemes ps WITH (NOLOCK)
		ON	idx.data_space_id = ps.data_space_id
LEFT JOIN	' + @databasename + N'.sys.partition_range_values rvr WITH (NOLOCK)
		ON	ps.function_id = rvr.function_id
		AND	p.partition_number = rvr.boundary_id
OUTER APPLY	(
	SELECT	''right_value''	= DATEADD(MONTH, DATEDIFF(MONTH, 0, CAST(rvr.value AS DATETIME)), 0)
) pt
WHERE	at.db = N''' + @databasename + N'''
ORDER BY tbl.name, p.partition_number;
';

				EXECUTE	sys.sp_executesql @query;
		END;

		DELETE	tbl
		FROM	#result AS tbl
		WHERE	tbl.winlostdate IS NULL
			AND	EXISTS (SELECT 1 FROM #result AS r WHERE r.tablename = tbl.tablename AND r.winlostdate IS NOT NULL);
	END;
	
	IF	@step = 2
	BEGIN
		SELECT	@databasename	= rc.databasename
			,	@tablename		= rc.tablename
			,	@fromdate		= rc.winlostdate
			,	@type			= t.tabletype
		FROM		bodb_Archive.dbo.Task_DBTP_ArchiveCheckRowcount rc WITH (NOLOCK)
		INNER JOIN	bodb_Archive.dbo.Task_DBTP_ArchiveTables t WITH (NOLOCK)
				ON	rc.tablename = t.name
				AND	rc.databasename = t.db
		WHERE	rc.timetype = 'PROCESSING';

		IF	@tablename IS NOT NULL AND @type IS NOT NULL
		BEGIN
			IF	@fromdate IS NULL
			BEGIN
				SELECT	@fromdate	= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 17, 0)
					,	@todate		= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 12, 0)
					;
			END;
			ELSE
			BEGIN
				SELECT	@todate		= DATEADD(MONTH, 1, @fromdate)
					;
			END;

			-- Table with winlostdate column --
			IF	@type = 1
			BEGIN
				SELECT	@query = N'';
				SELECT	@query = @query + N'
DECLARE	@from	DATETIME = ''' + CONVERT(NVARCHAR, @fromdate, 121) + N'''
	,	@to		DATETIME = ''' + CONVERT(NVARCHAR, @todate, 121) + N'''
	;

INSERT INTO	#result (databasename, tablename, winlostdate, DB06_rowcount, timetype)
SELECT	databasename	= CAST(''' + @databasename + N''' AS NVARCHAR(128))
	,	tablename		= CAST(''' + @tablename + N''' AS NVARCHAR(128))
	,	winlostdate		= tbl.winlostdate
	,	DB06_rowcount	= COUNT(1)
	,	timetype		= CAST(''DAY'' AS VARCHAR(10))
FROM	' + @databasename + N'.dbo.' + @tablename + N' tbl WITH (NOLOCK)
WHERE	tbl.winlostdate >= @from
	AND	tbl.winlostdate <= @to
GROUP BY tbl.winlostdate;
';
			END;

			-- Table with eventdate column --
			IF	@type = 2
			BEGIN
				SELECT	@query = N'';
				SELECT	@query = @query + N'
DECLARE	@from	DATETIME = ''' + CONVERT(NVARCHAR, @fromdate, 121) + N'''
	,	@to		DATETIME = ''' + CONVERT(NVARCHAR, @todate, 121) + N'''
	;

INSERT INTO	#result (databasename, tablename, winlostdate, DB06_rowcount, timetype)
SELECT	databasename	= CAST(''' + @databasename + N''' AS NVARCHAR(128))
	,	tablename		= CAST(''' + @tablename + N''' AS NVARCHAR(128))
	,	winlostdate		= tbl.eventdate
	,	DB06_rowcount	= COUNT(1)
	,	timetype		= CAST(''DAY'' AS VARCHAR(10))
FROM	' + @databasename + N'.dbo.' + @tablename + N' tbl WITH (NOLOCK)
WHERE	tbl.eventdate >= @from
	AND	tbl.eventdate <= @to
GROUP BY tbl.eventdate;
';
			END;

			-- Table with matchid column --
			IF	@type = 3
			BEGIN
				SELECT	@query = N'';
				SELECT	@query = @query + N'
DECLARE	@from	DATETIME = ''' + CONVERT(NVARCHAR, @fromdate, 121) + N'''
	,	@to		DATETIME = ''' + CONVERT(NVARCHAR, @todate, 121) + N'''
	;

INSERT INTO	#result (databasename, tablename, winlostdate, DB06_rowcount, timetype)
SELECT	databasename	= CAST(''' + @databasename + N''' AS NVARCHAR(128))
	,	tablename		= CAST(''' + @tablename + N''' AS NVARCHAR(128))
	,	winlostdate		= m.eventdate
	,	DB06_rowcount	= COUNT(1)
	,	timetype		= CAST(''DAY'' AS VARCHAR(10))
FROM		' + @databasename + N'.dbo.' + @tablename + ' tbl WITH (NOLOCK)
INNER JOIN	bodb_Archive.dbo.match_bk m WITH (NOLOCK)
		ON	tbl.matchid = m.matchid
WHERE	m.eventdate >= @from
	AND	m.eventdate <= @to
GROUP BY m.eventdate;
';
			END;

			-- Table with transtime column -- Dot_Admin_LiveLog --
			IF	@type = 4
			BEGIN
				SELECT	@fromdate	= DATEADD(MONTH, -2, @fromdate);
				SELECT	@todate		= DATEADD(MONTH, 3, @fromdate);

				SELECT	@query = N'';
				SELECT	@query = @query + N'
DECLARE	@from	DATETIME = ''' + CONVERT(NVARCHAR, @fromdate, 121) + N'''
	,	@to		DATETIME = ''' + CONVERT(NVARCHAR, @todate, 121) + N'''
	;

INSERT INTO	#result (databasename, tablename, winlostdate, DB06_rowcount, timetype)
SELECT	databasename	= CAST(''' + @databasename + N''' AS NVARCHAR(128))
	,	tablename		= CAST(''' + @tablename + N''' AS NVARCHAR(128))
	,	winlostdate		= DATEADD(DAY, DATEDIFF(DAY, 0, tbl.transtime), 0)
	,	DB06_rowcount	= COUNT(1)
	,	timetype		= CAST(''DAY'' AS VARCHAR(10))
FROM	' + @databasename + N'.dbo.' + @tablename + ' tbl WITH (NOLOCK)
WHERE	tbl.transtime >= @from
	AND	tbl.transtime <= @to
GROUP BY DATEADD(DAY, DATEDIFF(DAY, 0, tbl.transtime), 0);
';
			END;

			-- Table with MatchEventDate column --
			IF	@type = 5
			BEGIN
				SELECT	@query = N'';
				SELECT	@query = @query + N'
DECLARE	@from	DATETIME = ''' + CONVERT(NVARCHAR, @fromdate, 121) + N'''
	,	@to		DATETIME = ''' + CONVERT(NVARCHAR, @todate, 121) + N'''
	;

INSERT INTO	#result (databasename, tablename, winlostdate, DB06_rowcount, timetype)
SELECT	databasename	= CAST(''' + @databasename + N''' AS NVARCHAR(128))
	,	tablename		= CAST(''' + @tablename + N''' AS NVARCHAR(128))
	,	winlostdate		= tbl.MatchEventDate
	,	DB06_rowcount	= COUNT(1)
	,	timetype		= CAST(''DAY'' AS VARCHAR(10))
FROM	' + @databasename + N'.dbo.' + @tablename + ' tbl WITH (NOLOCK)
WHERE	tbl.MatchEventDate >= @from
	AND	tbl.MatchEventDate <= @to
GROUP BY tbl.MatchEventDate;
';
			END;

			-- Table with accdate column -- Statement --
			IF	@type = 6
			BEGIN
				SELECT	@query = N'';
				SELECT	@query = @query + N'
DECLARE	@from	DATETIME = ''' + CONVERT(NVARCHAR, @fromdate, 121) + N'''
	,	@to		DATETIME = ''' + CONVERT(NVARCHAR, @todate, 121) + N'''
	;

INSERT INTO	#result (databasename, tablename, winlostdate, DB06_rowcount, timetype)
SELECT	databasename	= CAST(''' + @databasename + N''' AS NVARCHAR(128))
	,	tablename		= CAST(''' + @tablename + N''' AS NVARCHAR(128))
	,	winlostdate		= DATEADD(DAY, DATEDIFF(DAY, 0, tbl.accdate), 0)
	,	DB06_rowcount	= COUNT(1)
	,	timetype		= CAST(''DAY'' AS VARCHAR(10))
FROM	' + @databasename + N'.dbo.' + @tablename + ' tbl WITH (NOLOCK)
WHERE	tbl.accdate >= @from
	AND	tbl.accdate <= @to
GROUP BY DATEADD(DAY, DATEDIFF(DAY, 0, tbl.accdate), 0);
';
			END;

			-- Table with ArchiveDate column --
			IF	@type = 7
			BEGIN
				SELECT	@query = N'';
				SELECT	@query = @query + N'
DECLARE	@from	DATETIME = ''' + CONVERT(NVARCHAR, @fromdate, 121) + N'''
	,	@to		DATETIME = ''' + CONVERT(NVARCHAR, @todate, 121) + N'''
	;

INSERT INTO	#result (databasename, tablename, winlostdate, DB06_rowcount, timetype)
SELECT	databasename	= CAST(''' + @databasename + N''' AS NVARCHAR(128))
	,	tablename		= CAST(''' + @tablename + N''' AS NVARCHAR(128))
	,	winlostdate		= tbl.ArchiveDate
	,	DB06_rowcount	= COUNT(1)
	,	timetype		= CAST(''DAY'' AS VARCHAR(10))
FROM	' + @databasename + N'.dbo.' + @tablename + ' tbl WITH (NOLOCK)
WHERE	tbl.ArchiveDate >= @from
	AND	tbl.ArchiveDate <= @to
GROUP BY tbl.ArchiveDate;
';
			END;

			EXECUTE	sys.sp_executesql @query;
			
			IF	@tablename = N'Dot_Admin_Assignment_Operator_bk'
			BEGIN
				SELECT	@query = N'';
				SELECT	@query = @query + N'
DECLARE	@from	DATETIME = ''' + CONVERT(NVARCHAR, @fromdate, 121) + N'''
	,	@to		DATETIME = ''' + CONVERT(NVARCHAR, @todate, 121) + N'''
;

INSERT INTO	#result (databasename, tablename, winlostdate, DB06_rowcount, timetype)
SELECT	databasename	= CAST(''' + @databasename + N''' AS NVARCHAR(128))
	,	tablename		= CAST(''' + @tablename + N''' AS NVARCHAR(128))
	,	winlostdate		= m.eventdate
	,	DB06_rowcount	= COUNT(1)
	,	timetype		= CAST(''DAY'' AS VARCHAR(10))
FROM		' + @databasename + N'.dbo.' + @tablename + ' tbl WITH (NOLOCK)
INNER JOIN	bodb02.dbo.match14 m WITH (NOLOCK)
	ON	tbl.matchid = m.matchid
WHERE	m.eventdate >= @from
AND	m.eventdate <= @to
GROUP BY m.eventdate;
';
			EXECUTE	sys.sp_executesql @query;
			END;
		END;
	END;
	
	SELECT	databasename, tablename, winlostdate, DB06_rowcount, timetype
	FROM	#result;
END;
GO

