USE [MonDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE	[dbo].[vnDBA_sp_Data_ChecksumManualVerify]
						@server_1		NVARCHAR(128)
					,	@database_1		NVARCHAR(128)
					,	@schema_1		NVARCHAR(128)	= N'dbo'
					,	@table_1		NVARCHAR(128)
					
					,	@server_2		NVARCHAR(128)	= @@SERVERNAME
					,	@database_2		NVARCHAR(128)
					,	@schema_2		NVARCHAR(128)	= NULL
					,	@table_2		NVARCHAR(128)	= NULL

					,	@column			NVARCHAR(128)	= N'custid'
					,	@from			NVARCHAR(MAX)
					,	@to				NVARCHAR(MAX)
					
					,	@auto_update	BIT				= 0
AS
BEGIN

	--	BEGIN STEP 1:
	--		Declare variables
	----------------------------------------------------------------------------------------------------

	SET NOCOUNT ON;

	-- Dynamic query --
	DECLARE	@query			NVARCHAR(MAX)
		,	@param			NVARCHAR(1000)
		,	@identity		BIT
		;

	DECLARE	@rowcount_1		INT
		,	@checksum_1		INT

		,	@rowcount_2		INT
		,	@checksum_2		INT
		;

	IF	@table_1 LIKE '%.%'
	BEGIN
		SELECT	@schema_1	= SUBSTRING(@table_1, 0, CHARINDEX('.', @table_1))
			,	@table_1	= REPLACE(@table_1, @schema_1 + '.', '')
			;
	END;

	SELECT	@schema_2		= ISNULL(@schema_2, @schema_1)
		,	@table_2		= ISNULL(@table_2, @table_1)
		;

	IF	@table_2 LIKE '%.%'
	BEGIN
		SELECT	@schema_2	= SUBSTRING(@table_2, 0, CHARINDEX('.', @table_2))
			,	@table_2	= REPLACE(@table_2, @schema_2 + '.', '')
			;
	END;

	-- Debug --
	DECLARE	@debug			BIT				= 1
		,	@datatype_stop	BIT				= 1
		;


	--	BEGIN STEP 2:
	--		Excluded data types & columns
	----------------------------------------------------------------------------------------------------

	IF	OBJECT_ID('tempdb..##ex_dt') IS NOT NULL
		DROP TABLE	##ex_dt;
	IF	OBJECT_ID('tempdb..##ex_col') IS NOT NULL
		DROP TABLE	##ex_col;

	CREATE TABLE	##ex_dt (
						datatype		NVARCHAR(128)
					);
	CREATE TABLE	##ex_col (
						tablename		NVARCHAR(128)
					,	colname			NVARCHAR(128)
					);

	INSERT INTO	##ex_dt
			(	datatype    )
	VALUES	(	N'timestamp')
		;

	INSERT INTO	##ex_col
		(	tablename  , colname      )
	SELECT	DISTINCT
			TableName, ColumnName
	FROM	MonDB.dbo.vnDBA_Data_CheckExcluded WITH (NOLOCK);


	--	BEGIN STEP 3:
	--		Compare datatype
	----------------------------------------------------------------------------------------------------

	IF	OBJECT_ID('tempdb..##columns_1') IS NOT NULL
		DROP TABLE	##columns_1;

	IF	OBJECT_ID('tempdb..##columns_2') IS NOT NULL
		DROP TABLE	##columns_2;

	IF	OBJECT_ID('tempdb..#_datatype') IS NOT NULL
		DROP TABLE	#_datatype;

	SELECT	@query = N'';
	SELECT	@query = @query + N'
SELECT	rn		= ROW_NUMBER() OVER(ORDER BY c.column_id)
	,	col		= c.name
	,	type	= ft.name
	,	pk		= CAST(ISNULL(idx.pk, 0) AS BIT)
INTO	##columns_1
FROM		' + @server_1 + N'.' + @database_1 + N'.sys.tables			AS t
INNER JOIN	' + @server_1 + N'.' + @database_1 + N'.sys.columns			AS c
		ON	c.object_id = t.object_id
INNER JOIN	' + @server_1 + N'.' + @database_1 + N'.sys.types			AS tp
		ON	tp.user_type_id = c.user_type_id
INNER JOIN	' + @server_1 + N'.' + @database_1 + N'.sys.schemas			AS s
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
	FROM		' + @server_1 + N'.' + @database_1 + N'.sys.indexes			AS i
	INNER JOIN	' + @server_1 + N'.' + @database_1 + N'.sys.index_columns	AS ic
			ON	ic.object_id = i.object_id
			AND	ic.index_id = i.index_id
	WHERE	i.object_id = t.object_id
		AND	ic.column_id = c.column_id
) idx(pk)
WHERE	s.name = @schema_1
	AND	t.name = @table_1
	AND	tp.name NOT IN (SELECT datatype FROM ##ex_dt)
;

SELECT	rn		= ROW_NUMBER() OVER(ORDER BY c.column_id)
	,	col		= c.name
	,	type	= ft.name
	,	pk		= CAST(ISNULL(idx.pk, 0) AS BIT)
INTO	##columns_2
FROM		' + @server_2 + N'.' + @database_2 + N'.sys.tables			AS t
INNER JOIN	' + @server_2 + N'.' + @database_2 + N'.sys.columns			AS c
		ON	c.object_id = t.object_id
INNER JOIN	' + @server_2 + N'.' + @database_2 + N'.sys.types			AS tp
		ON	tp.user_type_id = c.user_type_id
INNER JOIN	' + @server_2 + N'.' + @database_2 + N'.sys.schemas			AS s
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
	FROM		' + @server_2 + N'.' + @database_2 + N'.sys.indexes			AS i
	INNER JOIN	' + @server_2 + N'.' + @database_2 + N'.sys.index_columns	AS ic
			ON	ic.object_id = i.object_id
			AND	ic.index_id = i.index_id
	WHERE	i.object_id = t.object_id
		AND	ic.column_id = c.column_id
) idx(pk)
WHERE	s.name = @schema_2
	AND	t.name = @table_2
	AND	tp.name NOT IN (SELECT datatype FROM ##ex_dt)
;

RAISERROR(N''-- ~ COMPARE DATATYPE ~ --'', 0, 0) WITH NOWAIT;
'
	,	@param = N'@schema_1 NVARCHAR(128), @table_1 NVARCHAR(128), @schema_2 NVARCHAR(128), @table_2 NVARCHAR(128)'
	;

	EXECUTE	sys.sp_executesql @query, @param, @schema_1 = @schema_1, @table_1 = @table_1, @schema_2 = @schema_2, @table_2 = @table_2;

	SELECT	'column_1'		= _1.col
		,	'datatype_1'	= _1.type
		,	'column_2'		= _2.col
		,	'datatype_2'	= _2.col
	INTO	#_datatype
	FROM			##columns_1 _1
	FULL OUTER JOIN	##columns_2 _2
				ON	_1.col = _2.col
	WHERE	_1.col IS NULL
		OR	_2.col IS NULL
		OR	_1.col <> _2.col
	;

	IF EXISTS (SELECT 1 FROM #_datatype)
	BEGIN
		SELECT	*
		FROM	#_datatype AS d;

		IF	@datatype_stop = 1
			RETURN;
	END;
	ELSE
	BEGIN
		IF	@auto_update = 1
		BEGIN
			RAISERROR('-- ~~ Data type compare OK ~~ --', 0, 0) WITH NOWAIT;
		END;
		ELSE
		BEGIN
			SELECT	[Table]		= @schema_1 + N'.' + @table_1
				,	[Keys]		= pks.str
				,	[Columns]	= cols.str
			FROM	(
				SELECT	c.col + ', '
				FROM	##columns_1 c
				ORDER BY c.rn
				FOR XML PATH ('')
				,	TYPE
			) xcol(xml)
			CROSS APPLY (
				SELECT	LEFT(xq.str, LEN(xq.str) - 1)
				FROM	(
					SELECT	xcol.xml.value('.[1]', 'NVARCHAR(MAX)')
				) xq(str)
			) cols(str)
			CROSS APPLY	(
				SELECT	c.col + ', '
				FROM	##columns_1 c
				WHERE	pk = 1
				ORDER BY c.rn
				FOR XML PATH ('')
				,	TYPE
			) xpk(xml)
			CROSS APPLY (
				SELECT	LEFT(xq.str, LEN(xq.str) - 1)
				FROM	(
					SELECT	xpk.xml.value('.[1]', 'NVARCHAR(MAX)')
				) xq(str)
			) pks(str)
			;
		END;
	END;

	-- Delete unwanted columns --
	DELETE	c
	FROM		##columns_1 c
	INNER JOIN	##ex_col AS ec
			ON	ec.tablename = @table_1
			AND	ec.colname = c.col
	;
	DELETE	c
	FROM		##columns_2 c
	INNER JOIN	##ex_col AS ec
			ON	ec.tablename = @table_2
			AND	ec.colname = c.col
	;


	--	BEGIN STEP 4:
	--		Create temporary tables
	----------------------------------------------------------------------------------------------------

	SELECT	@query = N'';
	SELECT	@query = @query + N'CREATE TABLE ##table_1 (' + NCHAR(13) + cols.str
		+	CASE ipk.tf WHEN 1 THEN N', CONSTRAINT PK_tmp_table_1 PRIMARY KEY (' + pks.str + N')' + NCHAR(13) + N');' ELSE N');' END
	FROM (
		SELECT	c.col + ' ' + c.type + CHAR(13) + ', '
		FROM	##columns_1 c
		ORDER BY c.rn
		FOR XML PATH ('')
		,	TYPE
	) xcol(xml)
	CROSS APPLY (
		SELECT	LEFT(xq.str, LEN(xq.str) - 1)
		FROM	(
			SELECT	xcol.xml.value('.[1]', 'NVARCHAR(MAX)')
		) xq(str)
	) cols(str)
	CROSS APPLY	(
		SELECT	c.col + ', '
		FROM	##columns_1 c
		WHERE	c.pk = 1
		ORDER BY c.rn
		FOR XML PATH ('')
		,	TYPE
	) xpk(xml)
	CROSS APPLY	(
		SELECT	LEFT(xq.str, LEN(xq.str) - 1)
		FROM	(
			SELECT	xpk.xml.value('.[1]', 'NVARCHAR(MAX)')
		) xq(str)
	) pks(str)
	CROSS APPLY	(
		SELECT	MAX(CAST(c.pk AS TINYINT))
		FROM	##columns_1 c
	) ipk(tf)

	IF	OBJECT_ID('tempdb..##table_1') IS NOT NULL
		DROP TABLE	##table_1;

	EXECUTE	sys.sp_executesql @query;


	SELECT	@query = N'';
	SELECT	@query = @query + N'CREATE TABLE ##table_2 (' + NCHAR(13) + cols.str
		+	CASE ipk.tf WHEN 1 THEN N', CONSTRAINT PK_tmp_table_2 PRIMARY KEY (' + pks.str + N')' + NCHAR(13) + N');' ELSE N');' END
	FROM (
		SELECT	c.col + ' ' + c.type + CHAR(13) + ', '
		FROM	##columns_2 c
		ORDER BY c.rn
		FOR XML PATH ('')
		,	TYPE
	) xcol(xml)
	CROSS APPLY (
		SELECT	LEFT(xq.str, LEN(xq.str) - 1)
		FROM	(
			SELECT	xcol.xml.value('.[1]', 'NVARCHAR(MAX)')
		) xq(str)
	) cols(str)
	CROSS APPLY	(
		SELECT	c.col + ', '
		FROM	##columns_2 c
		WHERE	c.pk = 1
		ORDER BY c.rn
		FOR XML PATH ('')
		,	TYPE
	) xpk(xml)
	CROSS APPLY	(
		SELECT	LEFT(xq.str, LEN(xq.str) - 1)
		FROM	(
			SELECT	xpk.xml.value('.[1]', 'NVARCHAR(MAX)')
		) xq(str)
	) pks(str)
	CROSS APPLY	(
		SELECT	MAX(CAST(c.pk AS TINYINT))
		FROM	##columns_2 c
	) ipk(tf)

	IF	OBJECT_ID('tempdb..##table_2') IS NOT NULL
		DROP TABLE	##table_2;

	EXECUTE	sys.sp_executesql @query;

	RAISERROR(N'-- ~ CREATE TEMPORARY TABLES ~ --', 0, 0) WITH NOWAIT;


	--	BEGIN STEP 5:
	--		Import data to temp tables
	----------------------------------------------------------------------------------------------------

	SELECT	@query = N'';
	SELECT	@query = @query + N'
INSERT INTO	##table_2 (' + cols.str + N')
SELECT	' + cols.str + N'
FROM	' + @server_2 + N'.' + @database_2 + N'.' + @schema_2 + N'.' + @table_2 + N' WITH (NOLOCK)
WHERE	' + @column + N' BETWEEN ' + @from + N' AND ' + @to + N';

RAISERROR(N''-- ~ IMPORT TABLE 2 DATA ~ --'', 0, 0) WITH NOWAIT;
'
	FROM	(
		SELECT	c.col + ', '
		FROM	##columns_2 c
		ORDER BY c.rn
		FOR XML PATH ('')
		,	TYPE
	) xcol(xml)
	CROSS APPLY (
		SELECT	LEFT(xq.str, LEN(xq.str) - 1)
		FROM	(
			SELECT	xcol.xml.value('.[1]', 'NVARCHAR(MAX)')
		) xq(str)
	) cols(str)

	EXECUTE	sys.sp_executesql @query;


	SELECT	@query = N'';
	SELECT	@query = @query + N'
INSERT INTO	##table_1 (' + cols.str + N')
SELECT	' + cols.str + N'
FROM	' + @server_1 + N'.' + @database_1 + N'.' + @schema_1 + N'.' + @table_1 + N' WITH (NOLOCK)
WHERE	' + @column + N' BETWEEN ' + @from + N' AND ' + @to + N';

RAISERROR(N''-- ~ IMPORT TABLE 1 DATA ~ --'', 0, 0) WITH NOWAIT;
'
	FROM	(
		SELECT	c.col + ', '
		FROM	##columns_1 c
		ORDER BY c.rn
		FOR XML PATH ('')
		,	TYPE
	) xcol(xml)
	CROSS APPLY (
		SELECT	LEFT(xq.str, LEN(xq.str) - 1)
		FROM	(
			SELECT	xcol.xml.value('.[1]', 'NVARCHAR(MAX)')
		) xq(str)
	) cols(str)

	EXECUTE	sys.sp_executesql @query;


	--	BEGIN STEP 6:
	--		Re-checksum data
	----------------------------------------------------------------------------------------------------

	SELECT	@checksum_1		= CHECKSUM_AGG(BINARY_CHECKSUM(*))
	FROM	##table_1;

	SELECT	@checksum_2		= CHECKSUM_AGG(BINARY_CHECKSUM(*))
	FROM	##table_2;

	SELECT	@query = N'';
	SELECT	@query = @query + N'
SELECT	[Checksum ' + @server_1 + N'.' + @database_1 + N'] = ' + ISNULL(CAST(@checksum_1 AS NVARCHAR), N'NULL') + N'
	,	[Checksum ' + @server_2 + N'.' + @database_2 + N'] = ' + ISNULL(CAST(@checksum_2 AS NVARCHAR), N'NULL') + N'
	;

RAISERROR(N''-- ~ CHECKSUM ~ --'', 0, 0) WITH NOWAIT;
';
	
	IF	@auto_update = 0
	BEGIN
		EXECUTE	sys.sp_executesql @query;
	END;
	ELSE
	BEGIN
		RAISERROR('
-- Checksum %s.%s:	%d
-- Checksum %s.%s:	%d
', 0, 0, @server_1, @database_1, @checksum_1, @server_2, @database_2, @checksum_2) WITH NOWAIT;
	END;


	--	BEGIN STEP 7:
	--		Check and Report Rowcount
	----------------------------------------------------------------------------------------------------

	SELECT	@rowcount_1		= COUNT(1)
	FROM	##table_1;

	SELECT	@rowcount_2		= COUNT(1)
	FROM	##table_2;

	SELECT	@query = N'';
	SELECT	@query = @query + N'
SELECT	[Rowcount ' + @server_1 + N'.' + @database_1 + N'] = ' + ISNULL(CAST(@rowcount_1 AS NVARCHAR), N'NULL') + N'
	,	[Rowcount ' + @server_2 + N'.' + @database_2 + N'] = ' + ISNULL(CAST(@rowcount_2 AS NVARCHAR), N'NULL') + N'
	;

RAISERROR(N''-- ~ CHECK ROWCOUNT ~ --'', 0, 0) WITH NOWAIT;
';

	IF	@auto_update = 0
	BEGIN
		EXECUTE	sys.sp_executesql @query;
	END;
	ELSE
	BEGIN
		RAISERROR('
-- Rowcount %s.%s:	%d
-- Rowcount %s.%s:	%d
', 0, 0, @server_1, @database_1, @rowcount_1, @server_2, @database_2, @rowcount_2) WITH NOWAIT;
	END;

	-- Report different rows --
	IF	@checksum_1 <> @checksum_2 OR @rowcount_1 <> @rowcount_2
	BEGIN
		SELECT	@query = N'';
		SELECT	@query = @query + N'
SELECT	[' + @server_1 + N'.' + @database_1 + N'] = _1.' + @column + N'
	,	[' + @server_2 + N'.' + @database_2 + N'] = _2.' + @column + N'
	,	*
FROM			##table_1 _1	
FULL OUTER JOIN	##table_2 _2
			ON	' + joins.str + N'
WHERE	_1.' + @column + N' IS NULL
	OR	_2.' + @column + N' IS NULL
ORDER BY ' + REPLACE(orders.str, '~', '_1') + N', ' + REPLACE(orders.str, '~', '_2') + N';

RAISERROR(N''-- ~ REPORT DIFFERENT ROWCOUNT ~ --'', 0, 0) WITH NOWAIT;
'
		FROM	(
			SELECT	N'_1.' + c.col + N' = _2.' + c.col + N' AND '
			FROM	##columns_1 c
			WHERE	pk = 1
			ORDER BY c.rn
			FOR XML PATH ('')
			,	TYPE
		) xjoin(xml)
		CROSS APPLY (
			SELECT	LEFT(xq.str, LEN(xq.str) - 4)
			FROM	(
				SELECT	xjoin.xml.value('.[1]', 'NVARCHAR(MAX)')
			) xq(str)
		) joins(str)
		CROSS APPLY (
			SELECT	N'~.' + c.col + N' ASC, '
			FROM	##columns_1 c
			WHERE	pk = 1
			ORDER BY c.rn
			FOR XML PATH ('')
			,	TYPE
		) xorder(xml)
		CROSS APPLY (
			SELECT	LEFT(xq.str, LEN(xq.str) - 5)
			FROM	(
				SELECT	xorder.xml.value('.[1]', 'NVARCHAR(MAX)')
			) xq(str)
		) orders(str);

		IF	@auto_update = 0
		BEGIN
			EXECUTE	sys.sp_executesql @query;
		END;

		SELECT	@query = N'';
		SELECT	@query = @query + N'
IF	(SELECT COUNT(1) FROM ##table_1 _1 INNER JOIN ##table_2 _2 ON ' + joins.str + N') < ' + CAST(@rowcount_2 AS NVARCHAR) + '
BEGIN
	RAISERROR(''

------  Delete script on ' + @server_2 + N'.' + @database_2 + N'  ------
'', 0, 0) WITH NOWAIT;

	DECLARE	@iquery		NVARCHAR(MAX);

	SELECT	@iquery = N'''';
	SELECT	@iquery = @iquery + N''
IF	OBJECT_ID(''''tempdb..#deleted'''') IS NOT NULL
	DROP TABLE	#deleted;

SELECT	DISTINCT ' + REPLACE(pks.str, '~', '_2') + N'
INTO	#deleted
FROM			##table_1 _1
FULL OUTER JOIN	##table_2 _2
			ON	' + joins.str + N'
WHERE	_1.' + @column + N' IS NULL;

DELETE	_2
FROM		' + @server_2 + N'.' + @database_2 + N'.' + @schema_2 + N'.' + @table_2 + N' AS _2
INNER JOIN	#deleted AS _1
		ON	' + joins.str + N'
WHERE	_2.' + @column + N' BETWEEN ' + @from + N' AND ' + @to + N';
'';

	' + CASE @auto_update WHEN 0 THEN N'EXECUTE	MonDB.dbo.vnDBA_UI_PrintMessage @iquery;' ELSE N'EXECUTE	sys.sp_executesql @iquery;' END + N'

	RAISERROR(''
------  Delete script on ' + @server_2 + N'.' + @database_2 + N'  ------

'', 0, 0) WITH NOWAIT;
END;
'
		FROM	(
			SELECT	'~.' + c.col + ', '
			FROM	##columns_2 c
			WHERE	pk = 1
			ORDER BY c.rn
			FOR XML PATH ('')
			,	TYPE
		) xpk(xml)
		CROSS APPLY (
			SELECT	LEFT(xq.str, LEN(xq.str) - 1)
			FROM	(
				SELECT	xpk.xml.value('.[1]', 'NVARCHAR(MAX)')
			) xq(str)
		) pks(str)
		CROSS APPLY	(
			SELECT	N'_1.' + c.col + N' = _2.' + c.col + N' AND '
			FROM	##columns_2 c
			WHERE	pk = 1
			ORDER BY c.rn
			FOR XML PATH ('')
			,	TYPE
		) xjoin(xml)
		CROSS APPLY (
			SELECT	LEFT(xq.str, LEN(xq.str) - 4)
			FROM	(
				SELECT	xjoin.xml.value('.[1]', 'NVARCHAR(MAX)')
			) xq(str)
		) joins(str);
		
		EXECUTE	sys.sp_executesql @query;
		

		SELECT	@query = N'';
		SELECT	@query = @query + N'
IF	EXISTS	(	SELECT 1
				FROM		' + @database_2 + N'.sys.tables t
				INNER JOIN	' + @database_2 + N'.sys.columns c
						ON	t.object_id = c.object_id
				WHERE	t.name = ''' + @table_2 + '''
					AND	c.is_identity = 1
			)
	SELECT	@identity = 1;
ELSE
	SELECT	@identity = 0;
';

		EXECUTE	sys.sp_executesql	@stmt = @query
								,	@params = N'@identity BIT OUTPUT'
								,	@identity = @identity OUTPUT
								;
		
		
		SELECT	@query = N'';
		SELECT	@query = @query + N'
IF	(SELECT COUNT(1) FROM ##table_1 _1 INNER JOIN ##table_2 _2 ON ' + joins.str + N') < ' + CAST(@rowcount_1 AS NVARCHAR) + '
BEGIN
	RAISERROR(''

------  Insert script on ' + @server_2 + N'.' + @database_2 + N'  ------
'', 0, 0) WITH NOWAIT;

	DECLARE	@iquery		NVARCHAR(MAX);

	SELECT	@iquery = N'''';	
	SELECT	@iquery = @iquery + N''
IF	OBJECT_ID(''''tempdb..#inserted'''') IS NOT NULL
	DROP TABLE	#inserted;

SELECT	DISTINCT ' + REPLACE(pks.str, '~', '_1') + N'
INTO	#inserted
FROM			##table_1 _1
FULL OUTER JOIN	##table_2 _2
			ON	' + joins.str + N'
WHERE	_2.' + @column + N' IS NULL;
' + CASE @identity WHEN 1 THEN N'
IF	@@SERVERNAME = ''''' + @server_2 + N'''''
	SET IDENTITY_INSERT ' + @database_2 + N'.' + @schema_2 + N'.' + @table_2 + ' ON;
ELSE
BEGIN;
	RAISERROR(''''Cannot set IDENTITY_INSERT.'''', 0, 0) WITH NOWAIT;
	RETURN;
END;
' ELSE N'
' END + N'
INSERT INTO	 ' + @server_2 + N'.' + @database_2 + N'.' + @schema_2 + N'.' + @table_2 + N' (' + REPLACE(cols.str, '~.', '') + N')
SELECT	' + REPLACE(cols.str, '~', '_1') + N'
FROM		##table_1 AS _1
INNER JOIN	#inserted AS _2
		ON	' + joins.str + N';
' + CASE @identity WHEN 1 THEN N'
IF	@@SERVERNAME = ''''' + @server_2 + N'''''
	SET IDENTITY_INSERT ' + @database_2 + N'.' + @schema_2 + N'.' + @table_2 + ' OFF;
ELSE
BEGIN;
	RAISERROR(''''Cannot set IDENTITY_INSERT.'''', 0, 0) WITH NOWAIT;
	RETURN;
END;
' ELSE N'
' END + N'
'';

	' + CASE @auto_update WHEN 0 THEN N'EXECUTE	MonDB.dbo.vnDBA_UI_PrintMessage @iquery;' ELSE N'EXECUTE	sys.sp_executesql @iquery;' END + N'

	RAISERROR(''
------  Insert script on ' + @server_2 + N'.' + @database_2 + N'  ------

'', 0, 0) WITH NOWAIT;
END;
'
		FROM	(
			SELECT	'~.' + c.col + ', '
			FROM	##columns_1 c
			WHERE	pk = 1
			ORDER BY c.rn
			FOR XML PATH ('')
			,	TYPE
		) xpk(xml)
		CROSS APPLY (
			SELECT	LEFT(xq.str, LEN(xq.str) - 1)
			FROM	(
				SELECT	xpk.xml.value('.[1]', 'NVARCHAR(MAX)')
			) xq(str)
		) pks(str)
		CROSS APPLY	(
			SELECT	N'_1.' + c.col + N' = _2.' + c.col + N' AND '
			FROM	##columns_1 c
			WHERE	pk = 1
			ORDER BY c.rn
			FOR XML PATH ('')
			,	TYPE
		) xjoin(xml)
		CROSS APPLY (
			SELECT	LEFT(xq.str, LEN(xq.str) - 4)
			FROM	(
				SELECT	xjoin.xml.value('.[1]', 'NVARCHAR(MAX)')
			) xq(str)
		) joins(str)
		CROSS APPLY	(
			SELECT	'~.' + c.col + ', '
			FROM	##columns_1 c
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
		
		EXECUTE	sys.sp_executesql @query;
		
		IF	@rowcount_1 <> @rowcount_2
		BEGIN
			IF	@auto_update = 0
				RETURN;
			ELSE
			BEGIN
				EXECUTE	dbo.vnDBA_sp_Data_ChecksumManualVerify
							@server_1		= @server_1	
						,	@database_1		= @database_1	
						,	@schema_1		= @schema_1	
						,	@table_1		= @table_1	

						,	@server_2		= @server_2	
						,	@database_2		= @database_2	
						,	@schema_2		= @schema_2	
						,	@table_2		= @table_2	

						,	@column			= @column		
						,	@from			= @from		
						,	@to				= @to			

						,	@auto_update	= 1
						;
				RETURN;
			END;
		END;
	END;


	--	BEGIN STEP 8:
	--		Select Different Values
	----------------------------------------------------------------------------------------------------

	IF	OBJECT_ID('tempdb..##different') IS NOT NULL
		DROP TABLE	##different;

	IF	OBJECT_ID('tempdb..##result') IS NOT NULL
		DROP TABLE	##result;

	IF	@checksum_1 <> @checksum_2
	BEGIN
		SELECT	@query = N'';
		SELECT	@query = N'
SELECT	' + REPLACE(pks.str, '~', '_1') + N'
INTO	##different
FROM		(
	SELECT	' + REPLACE(pks.str, '~', '__1') + N', cs = BINARY_CHECKSUM(*)
	FROM	##table_1 AS __1
) _1
INNER JOIN	(
	SELECT	' + REPLACE(pks.str, '~', '__2') + N', cs = BINARY_CHECKSUM(*)
	FROM	##table_2 AS __2
) _2
		ON	' + REPLACE(REPLACE(joins.str, '~', '_1'), '`', '_2') + N'
WHERE	_1.cs <> _2.cs
	
SELECT	' + REPLACE(pks.str, '~', '_1') + N', ups.col, src = ups.val, dst = upd.val
INTO	##result
FROM		##different	dif
INNER JOIN	##table_1 AS _1
		ON	' + REPLACE(REPLACE(joins.str, '~', 'dif'), '`', '_1') + N'
OUTER APPLY	(
	VALUES	' + REPLACE(vals.str, '~', '_1') + N'
) ups(col, val)
INNER JOIN	##table_2 AS _2
OUTER APPLY	(
	VALUES	' + REPLACE(vals.str, '~', '_2') + N'
) upd(col, val)
		ON	' + REPLACE(REPLACE(joins.str, '~', '_1'), '`', '_2') + N'
		AND	ups.col = upd.col
WHERE	ups.val <> upd.val
	OR	(ups.val IS NULL AND upd.val IS NOT NULL)
	OR	(upd.val IS NULL AND ups.val IS NOT NULL);

' + CASE @auto_update WHEN 0 THEN N'
IF	EXISTS (SELECT 1 FROM ##result)
	SELECT	' + REPLACE(pks.str, '~.', '') + N', col, src, dst
	FROM	##result;
ELSE
	SELECT	Result = N''NO DIFFERENT VALUES'';
' ELSE N'
DECLARE	@count	INT;
SELECT	@count = COUNT(1)
FROM	##result;
RAISERROR(N''-- ~~ Total: %d ~~ --'', 0, 0, @count) WITH NOWAIT;
' END + N'
RAISERROR(N''-- ~ SELECT DIFFERENT COLUMNS ~ --'', 0, 0) WITH NOWAIT;
'
		FROM	(
			SELECT	'~.' + c.col + ', '
			FROM	##columns_1 c
			WHERE	c.pk = 1
			ORDER BY c.rn
			FOR XML PATH ('')
			,	TYPE
		) xpk(xml)
		CROSS APPLY (
			SELECT	LEFT(xq.str, LEN(xq.str) - 1)
			FROM	(
				SELECT	xpk.xml.value('.[1]', 'NVARCHAR(MAX)')
			) xq(str)
		) pks(str)
		CROSS APPLY (
			SELECT	'(N''' + c.col + ''', '
				+	CASE	WHEN c.type LIKE '%DATE%' OR c.type LIKE '%TIME%' THEN 'CONVERT(NVARCHAR(64), ~.' + c.col + ', 121)'
							WHEN c.type LIKE '%BINARY%' THEN 'CONVERT(NVARCHAR(MAX), ~.' + c.col + ', 1)'
							ELSE 'CONVERT(NVARCHAR(MAX), ~.' + c.col + ')'
					END
				+	'), '
			FROM	##columns_1 c
			ORDER BY c.rn
			FOR XML PATH ('')
			,	TYPE
		) xval(xml)
		CROSS APPLY (
			SELECT	LEFT(xq.str, LEN(xq.str) - 1)
			FROM	(
				SELECT	xval.xml.value('.[1]', 'NVARCHAR(MAX)')
			) xq(str)
		) vals(str)
		CROSS APPLY	(
			SELECT	N'~.' + c.col + N' = `.' + c.col + N' AND '
			FROM	##columns_1 c
			WHERE	pk = 1
			ORDER BY c.rn
			FOR XML PATH ('')
			,	TYPE
		) xjoin(xml)
		CROSS APPLY (
			SELECT	LEFT(xq.str, LEN(xq.str) - 4)
			FROM	(
				SELECT	xjoin.xml.value('.[1]', 'NVARCHAR(MAX)')
			) xq(str)
		) joins(str);
		
		EXECUTE	sys.sp_executesql @query;
	END;
	ELSE
	BEGIN
		SELECT	@query = N'';
		SELECT	@query = N'
SELECT	TOP 0
		dummy = 0
INTO	##result;
';

		EXECUTE	sys.sp_executesql @query;
	END;


	--	BEGIN STEP 9:
	--		Generate Update Script
	----------------------------------------------------------------------------------------------------

	IF	EXISTS (SELECT 1 FROM ##result)
	BEGIN
		SELECT	@query = N'';
		SELECT	@query = @query + N'
RAISERROR(''

------  Update script on ' + @server_2 + N'.' + @database_2 + N'  ------
'', 0, 0) WITH NOWAIT;

DECLARE	@iquery		NVARCHAR(MAX);

SELECT	@iquery = N'''';
	
SELECT	@iquery = @iquery + upds.str.value(''.[1]'', ''NVARCHAR(MAX)'')
FROM	(
	SELECT	N''
UPDATE	' + @database_2 + N'.' + @schema_2 + N'.' + @table_2 + N'
SET		'' + r.col + N'' = '' + CASE	WHEN r.src IS NULL THEN N''NULL''
										WHEN c.type LIKE ''%DATE%'' OR c.type LIKE ''%TIME%'' THEN '''''''' + r.src + ''''''''
										WHEN c.type LIKE ''N%CHAR%'' THEN ''N'''''' + r.src + ''''''''
										WHEN c.type LIKE ''%CHAR%'' THEN '''''''' + r.src + ''''''''
										ELSE r.src
								END
	+	N''
WHERE	' + @column + N' BETWEEN ' + @from + N' AND ' + @to + N'
	AND	' + wheres.str + '
	AND	'' + r.col + CASE	WHEN r.dst IS NULL THEN '' IS NULL''
							WHEN c.type LIKE ''%DATE%'' OR c.type LIKE ''%TIME%'' THEN '' = '''''' + r.dst + ''''''''
							WHEN c.type LIKE ''N%CHAR%'' THEN '' = N'''''' + r.dst + ''''''''
							WHEN c.type LIKE ''%CHAR%'' THEN '' = '''''' + r.dst + ''''''''
							ELSE '' = '' + r.dst
					END
	+	N'';
''
	FROM		##result AS r
	INNER JOIN	##columns_1 AS c
			ON	r.col = c.col
	FOR XML PATH
	,	TYPE
) upds(str);

' + CASE @auto_update WHEN 0 THEN N'EXECUTE	MonDB.dbo.vnDBA_UI_PrintMessage @iquery;' ELSE N'EXECUTE	sys.sp_executesql @iquery;' END + N'

RAISERROR(''
------  Update script on ' + @server_2 + N'.' + @database_2 + N'  ------

'', 0, 0) WITH NOWAIT;
'
		FROM	(
			SELECT	c.col + ' = '
				+	CASE	WHEN c.type LIKE '%DATE%' OR c.type LIKE '%TIME%' THEN ''''''''''' + CONVERT(NVARCHAR(64), r.' + c.col + ', 121) + N'''''''''''
							WHEN c.type LIKE 'N%CHAR%' THEN 'N'''''''''' + r.' + c.col + ' + N'''''''''''
							WHEN c.type LIKE '%CHAR%' THEN ''''''''''' + r.' + c.col + ' + N'''''''''''
							WHEN c.type LIKE '%BINARY%' THEN ''' + CONVERT(NVARCHAR(MAX), r.' + c.col + ', 1) + N'''
							ELSE ''' + CONVERT(NVARCHAR(MAX), r.' + c.col + ') + N'''
					END
				+	' AND '
			FROM	##columns_1 c
			WHERE	c.pk = 1
			ORDER BY c.rn
			FOR XML PATH ('')
			,	TYPE
		) xwhere(xml)
		CROSS APPLY (
			SELECT	LEFT(xq.str, LEN(xq.str) - 4)
			FROM	(
				SELECT	xwhere.xml.value('.[1]', 'NVARCHAR(MAX)')
			) xq(str)
		) wheres(str);
		
		EXECUTE	sys.sp_executesql @query;
	END;
	
	IF	@auto_update = 0
	BEGIN
		IF	@checksum_1 = @checksum_2
		BEGIN
			SELECT	[Result] = 'OK';
		END;
		ELSE
		BEGIN
			SELECT	[Result] = 'NG';
		END;

		RAISERROR('-- ~ DONE ~ --', 0, 0) WITH NOWAIT;
	END;
	ELSE
	BEGIN
		IF	@checksum_1 = @checksum_2
		BEGIN
			RAISERROR('-- ~~ OK ~~ --', 0, 0) WITH NOWAIT;
		END;
		ELSE
		BEGIN
			RAISERROR('-- ~~ NG ~~ --', 0, 0) WITH NOWAIT;
		END;
	END;
	
	IF	NOT (@checksum_1 = @checksum_2) AND @auto_update = 1
	BEGIN
		EXECUTE	dbo.vnDBA_sp_Data_ChecksumManualVerify
					@server_1		= @server_1	
				,	@database_1		= @database_1	
				,	@schema_1		= @schema_1	
				,	@table_1		= @table_1	

				,	@server_2		= @server_2	
				,	@database_2		= @database_2	
				,	@schema_2		= @schema_2	
				,	@table_2		= @table_2	

				,	@column			= @column		
				,	@from			= @from		
				,	@to				= @to			

				,	@auto_update	= 0
				;
	END;
END;
GO

