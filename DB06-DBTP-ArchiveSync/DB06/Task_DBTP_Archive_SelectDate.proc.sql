USE [bodb_archive]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Task_DBTP_Archive_SelectDate]
(
	@mode VARCHAR(10) = 'GEN'
)
AS
BEGIN
	IF @mode = 'GEN'
	BEGIN		
		DECLARE @minDate SMALLDATETIME,
				@maxDate SMALLDATETIME

		SELECT @maxDate = max(winlostdate) from bettrans_bk with (nolock)

		SELECT @minDate = max(winlostdate)
		from Task_DBTP_ArchiveDate with (nolock)
		--where isDone = 1

		/*
		if datediff(d, @minDate, @maxDate) <> 7
		BEGIN
			RaisError ('Wrong date count!!! Or already done the second balance up!!', 16, 1)
			RETURN
		END
		*/
		;With Calendar As
			(
			Select DateAdd(d,1,@minDate) As [Date]
			Union All
			Select DateAdd(d,1,[Date])
			From Calendar
			Where [Date] < @maxDate
			)
		INSERT INTO Task_DBTP_ArchiveDate (winlostdate)
		Select [Date]
		From Calendar    
		WHERE	[Date] <= @maxDate	-- 20170113@Billy: Prevent adding wrong date (if @minDate >= @maxDate)
		Option ( Maxrecursion 0 );
	END
	ELSE IF @mode = 'TBL' -- 20170428@Billy: New mode using compare rowcount result --
	BEGIN
		MERGE	Task_DBTP_ArchiveDate AS dst
		USING	(
			SELECT	DISTINCT winlostdate
			FROM	Task_DBTP_ArchiveCheckRowcount WITH (NOLOCK)
		) AS src
		ON	src.winlostdate = dst.winlostdate
		WHEN MATCHED		THEN UPDATE SET dst.isDone = 0
		WHEN NOT MATCHED	THEN INSERT (winlostdate) VALUES (src.winlostdate);
	END
	ELSE IF @mode = 'VAL'
	BEGIN
		IF NOT EXISTS (SELECT * FROM Task_DBTP_ArchiveDate WITH(NOLOCK) WHERE isDone = 0)
			RAISERROR('There is no available day to run.',16,1)
	END
END

GO

