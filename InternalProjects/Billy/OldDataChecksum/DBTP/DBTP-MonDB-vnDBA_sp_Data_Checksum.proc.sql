USE [MonDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE	[dbo].[vnDBA_sp_Data_Checksum]
					@src_server			NVARCHAR(128)	= NULL
				,	@src_database		NVARCHAR(128)
				,	@dst_server			NVARCHAR(128)	= NULL
				,	@dst_database		NVARCHAR(128)
				,	@tbl_name			NVARCHAR(128)
				,	@col_name			NVARCHAR(128)
				,	@interval			BIGINT
				,	@sch_name			NVARCHAR(128)	= N'dbo'
				,	@check_date			DATETIME		= NULL		OUTPUT
				,	@debug				BIT				= 0
AS
/*
	Creator:	20160811@Billy
	Task:		Checksum table data - [Redmine: #00000]
	Database:	DBTP.MonDB & DBMNL.MonDB
	
	Revisions:
		- 20161017@Billy:	Convert debug mode into manual checksum mode - [Redmine: #00000]
		- 20170216@Billy:	Apply checksum based on specified columns -[Redmine: #71379]
		- 20170418@Billy:	Define run & stop value to make sure the checksum is correct - [Redmine: #00000]
		- 20171023@Billy:	Parameterize dynamic query - [Redmine: #84104]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	@query			NVARCHAR(MAX)
		,	@param			NVARCHAR(1000)
		,	@info			NVARCHAR(MAX)
		;

	DECLARE	@start			DATETIME
		,	@end			DATETIME
		;

	DECLARE	@src_collist	NVARCHAR(MAX)
		,	@dst_collist	NVARCHAR(MAX)
		;
		
	DECLARE	@checksum		BIGINT
		,	@maxvalue		BIGINT
		,	@tmpvalue		BIGINT
		,	@stopvalue		BIGINT
		,	@runvalue		BIGINT
		,	@maxcustid		BIGINT
		;

	IF	OBJECT_ID('tempdb..##src_columns') IS NOT NULL
		DROP TABLE	##src_columns;
		
	IF	OBJECT_ID('tempdb..##dst_columns') IS NOT NULL
		DROP TABLE	##dst_columns;

	IF	@debug = 1
	BEGIN
		IF	OBJECT_ID('tempdb..#vnDBA_Data_Checksum') IS NOT NULL
			DROP TABLE	#vnDBA_Data_Checksum;
			
		CREATE TABLE	#vnDBA_Data_Checksum (
							check_date			DATETIME		NOT NULL
						,	src_name			NVARCHAR(128)	NOT NULL
						,	dst_name			NVARCHAR(128)	NOT NULL
						,	tbl_name			NVARCHAR(128)	NOT NULL
						,	col_name			NVARCHAR(128)	NOT NULL
						,	low_value			BIGINT			NOT NULL
						,	high_value			BIGINT			NOT NULL
						,	src_checksum		BIGINT			NULL
						,	dst_checksum		BIGINT			NULL
						,	src_duration		BIGINT			NULL
						,	dst_duration		BIGINT			NULL
						,	is_done				BIT				NULL
						);
	END;
	
	IF	@check_date IS NULL
	BEGIN
		SELECT	@check_date = GETDATE();
	END;


	-- Max CustId for custid related columns --
	BEGIN TRY
		SELECT	@maxcustid = MAX(CustId)
		FROM	bodb02.dbo.custInfo WITH (NOLOCK);
	END TRY
	BEGIN CATCH
		SELECT	@maxcustid = MAX(CustId)
		FROM	CustDB.dbo.custInfo WITH (NOLOCK);
	END CATCH;

	
	-- Max value --
	SELECT	@query = N'';
	SELECT	@query = @query + N'
EXECUTE	' + ISNULL(@dst_server + N'.', '') + @dst_database + N'.sys.sp_executesql N''
			SELECT	@maxvalue = MAX(' + @col_name + N')
			FROM	' + @sch_name + N'.' + @tbl_name + N' WITH (NOLOCK);
		''
	,	N''@maxvalue BIGINT OUTPUT''
	,	@maxvalue = @maxvalue OUTPUT
	;
'
		,	@param = N'@maxvalue BIGINT OUTPUT'
		;

	EXECUTE	sys.sp_executesql @query, @param, @maxvalue = @maxvalue OUTPUT;

	-- Min value --
	SELECT	@query = N'';
	SELECT	@query = @query + N'
EXECUTE	' + ISNULL(@src_server + N'.', '') + @src_database + N'.sys.sp_executesql N''
			SELECT	@tmpvalue = MIN(' + @col_name + N')
			FROM	' + @sch_name + N'.' + @tbl_name + N' WITH (NOLOCK);
		''
	,	N''@tmpvalue BIGINT OUTPUT''
	,	@tmpvalue = @tmpvalue OUTPUT
	;
'
		,	@param = N'@tmpvalue BIGINT OUTPUT'
		;

	EXECUTE	sys.sp_executesql @query, @param, @tmpvalue = @tmpvalue OUTPUT;
	
	-- Apply maxcustid - 1000 (stable threshold) --
	SELECT	@stopvalue =	CASE WHEN @col_name IN ('custid', 'agentid') AND @maxcustid - 1000 > @tmpvalue
									THEN @maxcustid - 1000
								 WHEN @col_name IN ('custid', 'agentid') AND @maxcustid - 1000 <= @tmpvalue
									THEN @tmpvalue
								 ELSE @maxvalue
							END;
	
	-- Column list --
	SELECT	@query = N'';
	SELECT	@query = @query + N'
SELECT	@sch_name		= N''' + @sch_name + N'''
	,	@tbl_name		= N''' + @tbl_name + N'''
	,	@src_database	= N''' + @src_database + N'''
	,	@dst_database	= N''' + @dst_database + N'''
	;

SELECT	rn		= ROW_NUMBER() OVER(ORDER BY c.column_id)
	,	col		= c.name
	,	type	= ft.name
	,	pk		= CAST(ISNULL(idx.pk, 0) AS BIT)
INTO	##src_columns
FROM		' + @src_server + N'.' + @src_database + N'.sys.tables			AS t
INNER JOIN	' + @src_server + N'.' + @src_database + N'.sys.columns			AS c
		ON	c.object_id = t.object_id
INNER JOIN	' + @src_server + N'.' + @src_database + N'.sys.types			AS tp
		ON	tp.user_type_id = c.user_type_id
INNER JOIN	' + @src_server + N'.' + @src_database + N'.sys.schemas			AS s
		ON	s.schema_id = t.schema_id
CROSS APPLY	(	SELECT	name	= UPPER	(	tp.name +	CASE tp.name	WHEN N''BINARY''			THEN N''('' + CAST(c.max_length AS NVARCHAR) + N'')''
																		WHEN N''CHAR''				THEN N''('' + CAST(c.max_length AS NVARCHAR) + N'')''
																		WHEN N''DATETIME2''			THEN N''('' + CAST(c.scale AS NVARCHAR) + N'')''
																		WHEN N''DATETIMEOFFSET''	THEN N''('' + CAST(c.scale AS NVARCHAR) + N'')''
																		WHEN N''DECIMAL''			THEN N''('' + CAST(c.precision AS NVARCHAR) + N'','' + CAST(c.scale AS NVARCHAR) + N'')''
																		WHEN N''NCHAR''				THEN N''('' + CAST(c.max_length / 2 AS NVARCHAR) + N'')''
																		WHEN N''NUMERIC''			THEN N''('' + CAST(c.precision AS NVARCHAR) + N'','' + CAST(c.scale AS NVARCHAR) + N'')''
																		WHEN N''NVARCHAR''			THEN N''('' + CASE c.max_length WHEN -1 THEN N''MAX'' ELSE CAST(c.max_length / 2 AS NVARCHAR) END + N'')''
																		WHEN N''TIME''				THEN N''('' + CAST(c.scale AS NVARCHAR) + N'')''
																		WHEN N''VARBINARY''			THEN N''('' + CASE c.max_length WHEN -1 THEN N''MAX'' ELSE CAST(c.max_length AS NVARCHAR) END + N'')''
																		WHEN N''VARCHAR''			THEN N''('' + CASE c.max_length WHEN -1 THEN N''MAX'' ELSE CAST(c.max_length AS NVARCHAR) END + N'')''
																		ELSE N''''
														END
										)
			) ft
OUTER APPLY	(
	SELECT	MAX(CAST(i.is_primary_key AS TINYINT))
	FROM		' + @src_server + N'.' + @src_database + N'.sys.indexes			AS i
	INNER JOIN	' + @src_server + N'.' + @src_database + N'.sys.index_columns	AS ic
			ON	ic.object_id = i.object_id
			AND	ic.index_id = i.index_id
	WHERE	i.object_id = t.object_id
		AND	ic.column_id = c.column_id
) idx(pk)
WHERE	s.name = @sch_name
	AND	t.name = @tbl_name
	AND	tp.name NOT IN (N''timestamp'')
	AND	c.name NOT IN (SELECT ColumnName FROM dbo.vnDBA_Data_CheckExcluded WITH (NOLOCK) WHERE DatabaseName = @src_database AND TableName = @tbl_name)
;

SELECT	rn		= ROW_NUMBER() OVER(ORDER BY c.column_id)
	,	col		= c.name
	,	type	= ft.name
	,	pk		= CAST(ISNULL(idx.pk, 0) AS BIT)
INTO	##dst_columns
FROM		' + @dst_server + N'.' + @dst_database + N'.sys.tables			AS t
INNER JOIN	' + @dst_server + N'.' + @dst_database + N'.sys.columns			AS c
		ON	c.object_id = t.object_id
INNER JOIN	' + @dst_server + N'.' + @dst_database + N'.sys.types			AS tp
		ON	tp.user_type_id = c.user_type_id
INNER JOIN	' + @dst_server + N'.' + @dst_database + N'.sys.schemas			AS s
		ON	s.schema_id = t.schema_id
CROSS APPLY	(	SELECT	name	= UPPER	(	tp.name +	CASE tp.name	WHEN N''BINARY''			THEN N''('' + CAST(c.max_length AS NVARCHAR) + N'')''
																		WHEN N''CHAR''				THEN N''('' + CAST(c.max_length AS NVARCHAR) + N'')''
																		WHEN N''DATETIME2''			THEN N''('' + CAST(c.scale AS NVARCHAR) + N'')''
																		WHEN N''DATETIMEOFFSET''	THEN N''('' + CAST(c.scale AS NVARCHAR) + N'')''
																		WHEN N''DECIMAL''			THEN N''('' + CAST(c.precision AS NVARCHAR) + N'','' + CAST(c.scale AS NVARCHAR) + N'')''
																		WHEN N''NCHAR''				THEN N''('' + CAST(c.max_length / 2 AS NVARCHAR) + N'')''
																		WHEN N''NUMERIC''			THEN N''('' + CAST(c.precision AS NVARCHAR) + N'','' + CAST(c.scale AS NVARCHAR) + N'')''
																		WHEN N''NVARCHAR''			THEN N''('' + CASE c.max_length WHEN -1 THEN N''MAX'' ELSE CAST(c.max_length / 2 AS NVARCHAR) END + N'')''
																		WHEN N''TIME''				THEN N''('' + CAST(c.scale AS NVARCHAR) + N'')''
																		WHEN N''VARBINARY''			THEN N''('' + CASE c.max_length WHEN -1 THEN N''MAX'' ELSE CAST(c.max_length AS NVARCHAR) END + N'')''
																		WHEN N''VARCHAR''			THEN N''('' + CASE c.max_length WHEN -1 THEN N''MAX'' ELSE CAST(c.max_length AS NVARCHAR) END + N'')''
																		ELSE N''''
														END
										)
			) ft
OUTER APPLY	(
	SELECT	MAX(CAST(i.is_primary_key AS TINYINT))
	FROM		' + @dst_server + N'.' + @dst_database + N'.sys.indexes			AS i
	INNER JOIN	' + @dst_server + N'.' + @dst_database + N'.sys.index_columns	AS ic
			ON	ic.object_id = i.object_id
			AND	ic.index_id = i.index_id
	WHERE	i.object_id = t.object_id
		AND	ic.column_id = c.column_id
) idx(pk)
WHERE	s.name = @sch_name
	AND	t.name = @tbl_name
	AND	tp.name NOT IN (N''timestamp'')
	AND	c.name NOT IN (SELECT ColumnName FROM dbo.vnDBA_Data_CheckExcluded WITH (NOLOCK) WHERE DatabaseName = @dst_database AND TableName = @tbl_name)
;
'
		,	@param = N'@sch_name NVARCHAR(128), @tbl_name NVARCHAR(128), @src_database NVARCHAR(128), @dst_database NVARCHAR(128)';

	EXECUTE	sys.sp_executesql @query, @param, @sch_name = @sch_name, @tbl_name = @tbl_name, @src_database = @src_database, @dst_database = @dst_database;

	IF	@debug = 1
	BEGIN
		SELECT	*
		FROM	##src_columns;

		SELECT	*
		FROM	##dst_columns;
	END;
	
	WHILE	@tmpvalue <= @maxvalue
	BEGIN
		IF	@debug = 0
		BEGIN
			INSERT INTO	dbo.vnDBA_Data_Checksum
				(	 check_date, src_name, dst_name, tbl_name, col_name, low_value, high_value, is_done)
			SELECT	@check_date
				,	ISNULL(@src_server + N'.', '') + @src_database
				,	ISNULL(@dst_server + N'.', '') + @dst_database
				,	@sch_name + N'.' + @tbl_name
				,	@col_name
				,	@tmpvalue
				,	@tmpvalue + @interval - 1
				,	0
				;
		END;
		ELSE
		BEGIN
			INSERT INTO	#vnDBA_Data_Checksum
				(	 check_date, src_name, dst_name, tbl_name, col_name, low_value, high_value, is_done)
			SELECT	@check_date
				,	ISNULL(@src_server + N'.', '') + @src_database
				,	ISNULL(@dst_server + N'.', '') + @dst_database
				,	@sch_name + N'.' + @tbl_name
				,	@col_name
				,	@tmpvalue
				,	@tmpvalue + @interval - 1
				,	0
				;
		END;

		SELECT	@tmpvalue = @tmpvalue + @interval;
	END;
		
	WHILE	0 = 0
	BEGIN
		IF	@debug = 0
		BEGIN
			SELECT	TOP(1)
					@tmpvalue = tc.low_value
				,	@maxvalue = tc.high_value
			FROM	dbo.vnDBA_Data_Checksum AS tc WITH (NOLOCK)
			WHERE	tc.check_date	= @check_date
				AND	tc.is_done		= 0;
		END;
		ELSE
		BEGIN
			SELECT	TOP(1)
					@tmpvalue = tc.low_value
				,	@maxvalue = tc.high_value
			FROM	#vnDBA_Data_Checksum AS tc
			WHERE	tc.check_date	= @check_date
				AND	tc.is_done		= 0;
		END;


		IF	@@ROWCOUNT = 0
			BREAK;
			
		SELECT	@runvalue = CASE WHEN @maxvalue > @stopvalue THEN @stopvalue ELSE @maxvalue END;

		SELECT	@query = N'';
		SELECT	@query = @query + N'
EXECUTE	' + ISNULL(@src_server + N'.', '') + @src_database + N'.sys.sp_executesql N''
SELECT	@checksum = CHECKSUM_AGG(BINARY_CHECKSUM(' + cols.str + N'))
FROM	' + @sch_name + N'.' + @tbl_name + N' WITH (NOLOCK)
WHERE	' + @col_name + N' BETWEEN @_low AND @_high;
''
	,	N''@_low BIGINT, @_high BIGINT, @checksum BIGINT OUTPUT''
	,	@checksum = @checksum OUTPUT
	,	@_low = @_low
	,	@_high = @_high
	;			
'
			,	@param = N'@_low BIGINT, @_high BIGINT, @checksum BIGINT OUTPUT'
		FROM	(
			SELECT	c.col + ', '
			FROM	##src_columns c
			ORDER BY c.rn
			FOR XML PATH ('')
			,	TYPE
		) xcol(xml)
		CROSS APPLY (
			SELECT	LEFT(xq.str, LEN(xq.str) - 1)
			FROM	(
				SELECT	xcol.xml.value('.[1]', 'NVARCHAR(MAX)')
			) xq(str)
		) cols(str);
			
		SELECT	@start = GETDATE();
		EXECUTE	sys.sp_executesql @query, @param, @checksum = @checksum OUTPUT, @_low = @tmpvalue, @_high = @runvalue;
		SELECT	@end = GETDATE();
		
		IF	@debug = 0
		BEGIN
			UPDATE	vnDBA_Data_Checksum
			SET		src_checksum = ISNULL(@checksum, 0)
				,	src_duration = DATEDIFF(MILLISECOND, @start, @end)
			WHERE	check_date	= @check_date
				AND	src_name	= ISNULL(@src_server + N'.', '') + @src_database
				AND	dst_name	= ISNULL(@dst_server + N'.', '') + @dst_database
				AND	tbl_name	= @sch_name + N'.' + @tbl_name
				AND	col_name	= @col_name
				AND	low_value	= @tmpvalue
				AND	high_value	= @maxvalue;
		END;
		ELSE
		BEGIN
			UPDATE	#vnDBA_Data_Checksum
			SET		src_checksum = ISNULL(@checksum, 0)
				,	src_duration = DATEDIFF(MILLISECOND, @start, @end)
			WHERE	check_date	= @check_date
				AND	src_name	= ISNULL(@src_server + N'.', '') + @src_database
				AND	dst_name	= ISNULL(@dst_server + N'.', '') + @dst_database
				AND	tbl_name	= @sch_name + N'.' + @tbl_name
				AND	col_name	= @col_name
				AND	low_value	= @tmpvalue
				AND	high_value	= @maxvalue;
		END;

		IF	@debug = 1
		BEGIN
			SELECT	@info	= N'Done CHECKSUM ' + ISNULL(@src_server + N'.', '') + @src_database + N' - '
							+ CAST(@tmpvalue AS NVARCHAR) + N' ~ ' + CAST(@maxvalue AS NVARCHAR) + N': '
							+ CAST(DATEDIFF(MILLISECOND, @start, @end) AS NVARCHAR) + N' ms';
			RAISERROR(@info, 0, 0) WITH NOWAIT;
		END;

	    SELECT	@query = N'';
		SELECT	@query = @query + N'
EXECUTE	' + ISNULL(@dst_server + N'.', '') + @dst_database + N'.sys.sp_executesql N''
SELECT	@checksum = CHECKSUM_AGG(BINARY_CHECKSUM(' + cols.str + N'))
FROM	' + @sch_name + N'.' + @tbl_name + N' WITH (NOLOCK)
WHERE	' + @col_name + N' BETWEEN @_low AND @_high;
''
						,	N''@_low BIGINT, @_high BIGINT, @checksum BIGINT OUTPUT''
						,	@checksum = @checksum OUTPUT
						,	@_low = @_low
						,	@_high = @_high
						;			
				'
			,	@param = N'@_low BIGINT, @_high BIGINT, @checksum BIGINT OUTPUT'
		FROM	(
			SELECT	c.col + ', '
			FROM	##dst_columns c
			ORDER BY c.rn
			FOR XML PATH ('')
			,	TYPE
		) xcol(xml)
		CROSS APPLY (
			SELECT	LEFT(xq.str, LEN(xq.str) - 1)
			FROM	(
				SELECT	xcol.xml.value('.[1]', 'NVARCHAR(MAX)')
			) xq(str)
		) cols(str);
			
		SELECT	@start = GETDATE();
		EXECUTE	sys.sp_executesql @query, @param, @checksum = @checksum OUTPUT, @_low = @tmpvalue, @_high = @runvalue;
		SELECT	@end = GETDATE();
		
		IF	@debug = 0
		BEGIN
			UPDATE	dbo.vnDBA_Data_Checksum
			SET		dst_checksum = ISNULL(@checksum, 0)
				,	dst_duration = DATEDIFF(MILLISECOND, @start, @end)
			WHERE	check_date	= @check_date
				AND	src_name	= ISNULL(@src_server + N'.', '') + @src_database
				AND	dst_name	= ISNULL(@dst_server + N'.', '') + @dst_database
				AND	tbl_name	= @sch_name + N'.' + @tbl_name
				AND	col_name	= @col_name
				AND	low_value	= @tmpvalue
				AND	high_value	= @maxvalue;
		END;
		ELSE
		BEGIN
			UPDATE	#vnDBA_Data_Checksum
			SET		dst_checksum = ISNULL(@checksum, 0)
				,	dst_duration = DATEDIFF(MILLISECOND, @start, @end)
			WHERE	check_date	= @check_date
				AND	src_name	= ISNULL(@src_server + N'.', '') + @src_database
				AND	dst_name	= ISNULL(@dst_server + N'.', '') + @dst_database
				AND	tbl_name	= @sch_name + N'.' + @tbl_name
				AND	col_name	= @col_name
				AND	low_value	= @tmpvalue
				AND	high_value	= @maxvalue;
		END;
		
		IF	@debug = 1
		BEGIN
			SELECT	@info	= N'Done CHECKSUM ' + ISNULL(@dst_server + N'.', '') + @dst_database + N' - '
							+ CAST(@tmpvalue AS NVARCHAR) + N' ~ ' + CAST(@maxvalue AS NVARCHAR) + N': '
							+ CAST(DATEDIFF(MILLISECOND, @start, @end) AS NVARCHAR) + N' ms';
			RAISERROR(@info, 0, 0) WITH NOWAIT;
		END;
		
		IF	@debug = 0
		BEGIN
			UPDATE	dbo.vnDBA_Data_Checksum
			SET		is_done		= 1
			WHERE	check_date	= @check_date
				AND	src_name	= ISNULL(@src_server + N'.', '') + @src_database
				AND	dst_name	= ISNULL(@dst_server + N'.', '') + @dst_database
				AND	tbl_name	= @sch_name + N'.' + @tbl_name
				AND	col_name	= @col_name
				AND	low_value	= @tmpvalue
				AND	high_value	= @maxvalue;
		END;
		ELSE
		BEGIN
			UPDATE	#vnDBA_Data_Checksum
			SET		is_done		= 1
			WHERE	check_date	= @check_date
				AND	src_name	= ISNULL(@src_server + N'.', '') + @src_database
				AND	dst_name	= ISNULL(@dst_server + N'.', '') + @dst_database
				AND	tbl_name	= @sch_name + N'.' + @tbl_name
				AND	col_name	= @col_name
				AND	low_value	= @tmpvalue
				AND	high_value	= @maxvalue;
		END;
	END;

	IF	@debug = 1
	BEGIN
		SELECT	dc.check_date, dc.src_name, dc.dst_name, dc.tbl_name, dc.low_value, dc.high_value, dc.src_checksum, dc.dst_checksum, dc.src_duration, dc.dst_duration, dc.is_done
		FROM	#vnDBA_Data_Checksum AS dc
		WHERE	dc.src_checksum <> dc.dst_checksum;

		DROP TABLE	#vnDBA_Data_Checksum;
	END;
END;
GO

