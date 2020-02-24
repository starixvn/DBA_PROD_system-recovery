USE [MonDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE	[dbo].[vnDBA_sp_Data_EmailChecksumReport]
						@to				VARCHAR(MAX)	= 'pontus@starixsoft.com'
					,	@cc				VARCHAR(MAX)	= ''
					,	@bcc			VARCHAR(MAX)	= ''
					,	@notify_repl	TINYINT			= 3
					,	@delete_repl	TINYINT			= 2
AS
/*
	Creator:	yyyymmdd@Billy
	Task:		Description - [Redmine: #00000]
	Database:	DBTP.MonDB
	
	Revisions:
		- 20170905@Billy:	Add cleanup invalid record
*/
BEGIN
	SET NOCOUNT ON;

	IF	OBJECT_ID('tempdb..#checked_date') IS NOT NULL
		DROP TABLE	#checked_date;
	IF	OBJECT_ID('tempdb..#checked_sum') IS NOT NULL
		DROP TABLE	#checked_sum;

	DECLARE	@html			NVARCHAR(MAX)
		,	@tmp_html		NVARCHAR(MAX)
		,	@subject		NVARCHAR(255)
		;
					
	DECLARE	@checked_date	DATETIME;

	CREATE TABLE	#checked_date (
						check_date		DATETIME
					,	is_done			BIT
					);
					
	CREATE TABLE	#checked_sum (
						src_name		NVARCHAR(256)
					,	dst_name		NVARCHAR(256)
					,	tbl_name		NVARCHAR(256)
					,	col_name		NVARCHAR(128)
					,	low_value		BIGINT
					,	high_value		BIGINT
					);
					
	DELETE	dbo.vnDBA_Data_Checksum 
	WHERE	src_checksum = dst_checksum;
	
	DELETE	cs
	FROM		dbo.vnDBA_Data_Checksum cs
	CROSS APPLY	(
		SELECT	MAX(ds.check_date)
		FROM	dbo.vnDBA_Data_Checksum ds
		WHERE	ds.src_name <> ''
	) m(x)
	WHERE	cs.check_date < m.x
		AND	(	cs.src_checksum IS NULL
			OR	cs.dst_checksum IS NULL
			);
		
	DELETE	cs
	FROM		dbo.vnDBA_Data_Checksum cs
	CROSS APPLY	(
		SELECT	COUNT(1)
		FROM	dbo.vnDBA_Data_Checksum ds
		WHERE	ds.check_date = cs.check_date
	) r(c)
	CROSS APPLY	(
		SELECT	MIN(ds.check_date)
		FROM	dbo.vnDBA_Data_Checksum ds
		WHERE	ds.src_name <> ''
	) m(n)
	WHERE	r.c = 1
		AND	cs.check_date < m.n;

	INSERT INTO		#checked_date
		(	check_date, is_done)
	SELECT	DISTINCT
			check_date, 0
	FROM	vnDBA_Data_Checksum WITH (NOLOCK);

	IF	(SELECT COUNT(1) FROM #checked_date) < @notify_repl
		RETURN;

	INSERT INTO		#checked_sum
		(	src_name, dst_name, tbl_name, col_name, low_value, high_value)
	SELECT	DISTINCT
			src_name, dst_name, tbl_name, col_name, low_value, high_value
	FROM	vnDBA_Data_Checksum WITH (NOLOCK)
	WHERE	tbl_name <> N'';

	IF	NOT EXISTS (SELECT 1 FROM #checked_sum)
		RETURN;

	WHILE 0 = 0
	BEGIN
		SELECT	TOP 1
				@checked_date = check_date
		FROM	#checked_date cd
		WHERE	is_done = 0
		ORDER BY check_date ASC;
		
		IF	@@ROWCOUNT = 0
			BREAK;

		WITH list AS (
			SELECT	*
			FROM		#checked_date
			CROSS JOIN	#checked_sum
		)
		,	 checked AS (
			SELECT	l.*, available = CASE WHEN dc.tbl_name IS NULL THEN 0 ELSE 1 END
			FROM		list l
			LEFT JOIN	vnDBA_Data_Checksum dc WITH (NOLOCK)
					ON	l.check_date = dc.check_date
					AND	l.src_name = dc.src_name
					AND	l.dst_name = dc.dst_name
					AND	l.tbl_name = dc.tbl_name
					AND l.col_name = dc.col_name
					AND	l.low_value = dc.low_value
					AND	l.high_value = dc.high_value
		)
		DELETE	dc
		FROM		#checked_sum cs
		CROSS APPLY (
			SELECT	CONVERT(VARCHAR, available)
			FROM	checked c
			WHERE	c.check_date <= @checked_date
				AND	c.src_name = cs.src_name
				AND	c.dst_name = cs.dst_name
				AND	c.tbl_name = cs.tbl_name
				AND c.col_name = cs.col_name
				AND	c.low_value = cs.low_value
				AND	c.high_value = cs.high_value
			ORDER BY check_date DESC
			FOR XML PATH ('')
		) chk(s)
		INNER JOIN	vnDBA_Data_Checksum dc
				ON	dc.check_date <= @checked_date
				AND	dc.src_name = cs.src_name
				AND	dc.dst_name = cs.dst_name
				AND dc.tbl_name = cs.tbl_name
				AND	dc.col_name = cs.col_name
				AND	dc.low_value = cs.low_value
				AND	dc.high_value = cs.high_value
		WHERE	LEFT(chk.s, @delete_repl) = REPLICATE('0', @delete_repl)
			AND	src_checksum IS NOT NULL
			AND	dst_checksum IS NOT NULL;
		
		UPDATE	#checked_date
		SET		is_done = 1
		WHERE	check_date = @checked_date;
	END;
				
	WITH tbl AS (
		SELECT	DISTINCT
				tbl_name
		FROM	#checked_sum
	)
	,	 list AS (
		SELECT	*
		FROM		#checked_date
		CROSS JOIN	#checked_sum
	)
	,	 checked AS (
		SELECT	l.*, available = CASE WHEN dc.tbl_name IS NULL THEN 0 ELSE 1 END
		FROM		list l
		LEFT JOIN	vnDBA_Data_Checksum dc WITH (NOLOCK)
				ON	l.check_date = dc.check_date
				AND	l.src_name = dc.src_name
				AND	l.dst_name = dc.dst_name
				AND	l.tbl_name = dc.tbl_name
				AND l.col_name = dc.col_name
				AND	l.low_value = dc.low_value
				AND	l.high_value = dc.high_value
	)
	SELECT	@html = (
		SELECT	TOP 1
				'@style'	= 'width: 100%;'
			,	'h1/@align'	= 'center'
			,	'h1'		= 'Following tables checksum FAIL'
			,	(	SELECT	'div/@style' = 'width: 95%'
						,	'div'	= html.x
					FROM		tbl
					CROSS APPLY	(
						SELECT	(
							SELECT	'h4'	= tbl.tbl_name
								,	(	SELECT	'@border'	= 2
											,	'@style'	= 'width: 100%; text-align: center;'
											,	(	SELECT	TOP 1
															'col/@style'	= 'width: 12.5%'
														,	NULL
														,	'col/@style'	= 'width: 12.5%'
														,	NULL
														,	'col/@style'	= 'width: 25%'
														,	NULL
														,	'col/@style'	= 'width: 12.5%'
														,	NULL
														,	'col/@style'	= 'width: 12.5%'
														,	NULL
														,	'col/@style'	= 'width: 12.5%'
														,	NULL
														,	'col/@style'	= 'width: 12.5%'
														,	NULL
														,	'th'	= 'Source 1'
														,	NULL
														,	'th'	= 'Source 2'
														,	NULL
														,	'th'	= 'Table Name'
														,	NULL
														,	'th'	= 'Column'
														,	NULL
														,	'th'	= 'Low Value'
														,	NULL
														,	'th'	= 'High Value'
														,	NULL
														,	'th'	= 'Check Sequence'
													FOR XML PATH ('tr')
													,	TYPE
												)
											,	(	SELECT	'td'	= cs.src_name
														,	NULL
														,	'td'	= cs.dst_name
														,	NULL
														,	'td'	= cs.tbl_name
														,	NULL
														,	'td'	= cs.col_name
														,	NULL
														,	'td'	= cs.low_value
														,	NULL
														,	'td'	= cs.high_value
														,	NULL
														,	'td'	= chk.s
													FROM		#checked_sum cs
													CROSS APPLY (
														SELECT	CONVERT(VARCHAR, available)
														FROM	checked c
														WHERE	c.src_name = cs.src_name
															AND	c.dst_name = cs.dst_name
															AND	c.tbl_name = cs.tbl_name
															AND c.col_name = cs.col_name
															AND	c.low_value = cs.low_value
															AND	c.high_value = cs.high_value
														ORDER BY check_date DESC, tbl_name ASC, low_value ASC
														FOR XML PATH ('')
													) chk(s)
													WHERE	CHARINDEX(REPLICATE('1', @notify_repl), chk.s) <> 0
															--LEFT(chk.s, @notify_repl) = REPLICATE('1', @notify_repl)
														AND	LEFT(chk.s, 1) = '1'
														AND	cs.tbl_name = tbl.tbl_name
													ORDER BY	CASE	WHEN cs.src_name LIKE '%DBMNL[.]%' THEN 1
																		WHEN cs.src_name LIKE '%DB02[.]%' THEN 2
																		WHEN cs.src_name LIKE '%DBCUST[.]%' THEN 2
																		WHEN cs.src_name LIKE '%DBTRANS[.]%' THEN 2
																		ELSE 3
																END ASC
													FOR XML PATH ('tr')
													,	TYPE
												)
										FOR XML PATH ('table')
										,	TYPE
									)
							FOR XML PATH ('')
							,	TYPE
						)
					) html(x)
					CROSS APPLY	(
						SELECT		COUNT(1)
						FROM		#checked_sum cs
						CROSS APPLY (
							SELECT	CONVERT(VARCHAR, available)
							FROM	checked c
							WHERE	c.src_name = cs.src_name
								AND	c.dst_name = cs.dst_name
								AND	c.tbl_name = cs.tbl_name
								AND c.col_name = cs.col_name
								AND	c.low_value = cs.low_value
								AND	c.high_value = cs.high_value
							ORDER BY check_date DESC
							FOR XML PATH ('')
						) chk(s)
						WHERE	CHARINDEX(REPLICATE('1', @notify_repl), chk.s) <> 0
								--LEFT(chk.s, @notify_repl) = REPLICATE('1', @notify_repl)
							AND	LEFT(chk.s, 1) = '1'
							AND	cs.tbl_name = tbl.tbl_name
					) cnt(r)
					WHERE	cnt.r <> 0
					FOR XML PATH ('')
					,	TYPE
				)
		FROM	#checked_sum
		FOR XML PATH ('body')
		,	ROOT ('html')
	);
	
	SELECT	@tmp_html = (
		SELECT	TOP 1
				'@style'	= 'width: 100%;'
			,	'h1/@align'	= 'center'
			,	'h1'		= 'Following tables checksum FAIL'
		FOR XML PATH ('body')
		,	ROOT ('html')
	);
	
	IF	@html = @tmp_html
		SELECT	@html = REPLACE(@tmp_html, 'Following tables checksum FAIL', 'Checksum SUCCESS');
			
	SELECT	@subject	= N'Table Checksum Report'
		,	@to			= CASE	WHEN	@to LIKE '%dbaadmin@starixsoft.com%'
									OR	@to LIKE '%DBAAdmin@onelab.tw%'
									OR	@to LIKE '%pontus@starixsoft.com%'
									OR	@to LIKE '%billy.bui@starixsoft.com%'
									THEN ''
								ELSE 'billy.bui@starixsoft.com;'
						  END
						+ ISNULL(@to, '')
		;
	
	EXECUTE	msdb.dbo.sp_send_dbmail
				@profile_name			= DEFAULT
			,	@recipients				= @to
			,	@copy_recipients		= @cc
			,	@blind_copy_recipients	= @bcc
			,	@subject				= @subject
			,	@body					= @html
			,	@body_format			= 'HTML'
			;
			
	DROP TABLE	#checked_date
			,	#checked_sum
			;
END;
GO

