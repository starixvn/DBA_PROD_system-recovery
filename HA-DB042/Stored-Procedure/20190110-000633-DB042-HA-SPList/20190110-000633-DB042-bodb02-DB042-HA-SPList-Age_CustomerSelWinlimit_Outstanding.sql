
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Age_CustomerSelWinlimit_Outstanding    Script Date: 1/10/2019 12:06:34 AM ******/
/****** Object:  Stored Procedure dbo.Age_CustomerSelWinlimit_Outstanding    Script Date: 9/6/2018 1:57:44 AM ******/
/****** Object:  Stored Procedure dbo.Age_CustomerSelWinlimit_Outstanding    Script Date: 9/1/2018 1:32:53 PM ******/
CREATE PROCEDURE dbo.Age_CustomerSelWinlimit_Outstanding
					@CustId			INT
				,	@MinCustId		INT
				,	@MaxCustID		INT
				,	@SportType		SMALLINT
				,	@BetType		SMALLINT
				,	@ProductID		TINYINT
				,	@username		NVARCHAR(50)	= ''
				,	@PlayerId_IBC	INT				= NULL
				,	@mrecommend		INT				= 0
				,	@recommend		INT				= 0
AS
/*
	Create:	20180717@Elodie
	Task:	Outstanding of Customer
	DB:		DB042/bodb02

	Revisions:
		- 20180717@Elodie: Get outstanding of customer
	Param's Explanation:
		- @CustID: SAgentID
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @RoleId TINYINT, @srecommend INT
	CREATE TABLE #MemberBalance (CustId INT)

	SELECT @RoleId = RoleId, @srecommend = srecommend
	FROM dbo.CustInfo c WITH(NOLOCK)
	WHERE CustId = @CustId

	IF	@username = ''
		SELECT @username = NULL
	
	IF @RoleId = 4
	BEGIN
		INSERT INTO #MemberBalance(CustId)
		SELECT c.custid
		FROM dbo.CustInfo c WITH(NOLOCK)
		WHERE c.srecommend = @CustId
			AND roleid = 1
			AND c.mrecommend = @mrecommend
			AND (@recommend = 0 OR (@recommend <> 0 AND c.recommend = @recommend))
			AND	c.username LIKE '%' + ISNULL(@username, c.username) + '%'
			AND	c.custid = ISNULL(@PlayerId_IBC, c.custid)
			AND c.custid BETWEEN @MinCustId AND @MaxCustID
			AND c.Enabled = 1
		GROUP BY c.custid
	END
	ELSE IF @RoleId = 3
	BEGIN
		INSERT INTO #MemberBalance(CustId)
		SELECT c.custid
		FROM dbo.CustInfo c WITH(NOLOCK)
		WHERE c.mrecommend = @CustId
			AND roleid = 1
			AND c.srecommend = @srecommend 
			AND c.recommend = @recommend
			AND	c.username LIKE '%' + ISNULL(@username, c.username) + '%'
			AND	c.custid = ISNULL(@PlayerId_IBC, c.custid)
			AND c.custid BETWEEN @MinCustId AND @MaxCustID
			AND c.Enabled = 1
		GROUP BY c.custid
	END
	ELSE IF @RoleId = 2
	BEGIN
		INSERT INTO #MemberBalance(CustId)
		SELECT c.custid
		FROM dbo.CustInfo c WITH(NOLOCK)
		WHERE c.recommend = @CustId
			AND roleid = 1
			AND c.srecommend = @srecommend
			AND	c.username LIKE '%' + ISNULL(@username, c.username) + '%'
			AND	c.custid = ISNULL(@PlayerId_IBC, c.custid)
			AND c.custid BETWEEN @MinCustId AND @MaxCustID
			AND c.Enabled = 1
		GROUP BY c.custid
	END
	
	SELECT	mb.CustId
		,	SUM(b.actual_stake) AS Outstanding
	FROM #MemberBalance mb
		INNER JOIN	dbo.bettrans AS b WITH (NOLOCK) ON mb.CustId = b.CustId 
	WHERE b.statusID = 0 AND b.matchid = @SportType
		AND b.BetType BETWEEN 1401 AND 1499
	GROUP BY mb.custid

	DROP TABLE #MemberBalance
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[Age_CustomerSelWinlimit_Outstanding] TO [bodbDownlineNet]
GO 
 GRANT EXECUTE ON [dbo].[Age_CustomerSelWinlimit_Outstanding] TO [bodbDownlineNetView]
GO 
 GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelWinlimit_Outstanding] TO [vnteam]
GO 
