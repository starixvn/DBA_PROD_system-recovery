
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Age_TotalBets_Bullfighting_Agent    Script Date: 1/10/2019 12:06:35 AM ******/
/****** Object:  Stored Procedure dbo.Age_TotalBets_Bullfighting_Agent    Script Date: 8/1/2018 2:07:39 PM ******/

CREATE PROCEDURE [dbo].[Age_TotalBets_Bullfighting_Agent]
	@CustID INT --mrecommend
AS

/*
	Created: 
	Task: 
	DB: DB042-bodb02,DBAGE-bodb02
	Original: 
	Revisions:
		- 20171024@Paul: Create new [RedmineID: #84690]
		- 20180522@Paul: Get matches with EventStatus <> 'completed' [RedmineID: #95524]

*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @srecommend INT;

	SELECT	@srecommend = srecommend
	FROM dbo.Customer WITH(NOLOCK)
	WHERE custid = @CustID;

	SELECT	EventDate,
			Match3rdId,
			d.League3rdId,
			l.LeagueCode,
			HasLive,
			HomeId,
			AwayId,
			BetCount,
			Turnover,
			Banker,
			Player
	FROM (
		SELECT	m.EventDate,
				m.Match3rdId,
				m.League3rdId,
				m.HasLive,
				m.HomeId,
				m.AwayId,
				COUNT(1) AS BetCount,
				SUM(stake * mpositiontaking) AS Turnover,
				SUM(CASE WHEN b.custom3 = 'b' THEN stake * (CASE WHEN b.odds < 0 THEN 1 ELSE b.odds END) * mpositiontaking ELSE - b.actual_stake * mpositiontaking END) AS Banker,
				SUM(CASE WHEN b.custom3 = 'p' THEN stake * (CASE WHEN b.odds < 0 THEN 1 ELSE b.odds END) * mpositiontaking ELSE - b.actual_stake * mpositiontaking END) AS Player
		FROM dbo.translog b WITH(NOLOCK)
			JOIN dbo.match3rd m WITH(NOLOCK) ON b.eventID = m.Match3rdId
		WHERE b.mrecommend = @CustID
			AND b.gameID = 1004
			AND b.statusID IN (0, 1)
			AND b.srecommend = @srecommend
			AND m.EventStatus <> 'completed'
		GROUP BY m.EventDate, m.Match3rdId,
				m.League3rdId, m.HasLive, m.HomeId, m.AwayId
		) d
		JOIN dbo.League3rd l WITH(NOLOCK) ON d.League3rdId = l.League3rdId;

	SET NOCOUNT OFF;
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[Age_TotalBets_Bullfighting_Agent] TO [bodbDownlineNet]
GO 
 GRANT EXECUTE ON [dbo].[Age_TotalBets_Bullfighting_Agent] TO [bodbDownlineNetView]
GO 
 GRANT VIEW DEFINITION ON [dbo].[Age_TotalBets_Bullfighting_Agent] TO [vnteam]
GO 
