
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Age_TotalBets_Bullfighting_Master    Script Date: 1/10/2019 12:06:36 AM ******/
/****** Object:  Stored Procedure dbo.Age_TotalBets_Bullfighting_Master    Script Date: 8/1/2018 2:07:39 PM ******/

CREATE PROCEDURE [dbo].[Age_TotalBets_Bullfighting_Master]
	@CustID INT --srecommend
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
				SUM(stake * spositiontaking) AS Turnover,
				SUM(CASE WHEN b.custom3 = 'b' THEN stake * (CASE WHEN b.odds < 0 THEN 1 ELSE b.odds END) * spositiontaking ELSE - b.actual_stake * spositiontaking END) AS Banker,
				SUM(CASE WHEN b.custom3 = 'p' THEN stake * (CASE WHEN b.odds < 0 THEN 1 ELSE b.odds END) * spositiontaking ELSE - b.actual_stake * spositiontaking END) AS Player
		FROM dbo.translog b WITH(NOLOCK)
			JOIN dbo.match3rd m WITH(NOLOCK) ON b.eventID = m.Match3rdId
		WHERE b.srecommend = @CustID
			AND b.gameID = 1004
			AND b.statusID IN (0, 1)
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
 GRANT EXECUTE ON [dbo].[Age_TotalBets_Bullfighting_Master] TO [bodbDownlineNet]
GO 
 GRANT EXECUTE ON [dbo].[Age_TotalBets_Bullfighting_Master] TO [bodbDownlineNetView]
GO 
 GRANT VIEW DEFINITION ON [dbo].[Age_TotalBets_Bullfighting_Master] TO [vnteam]
GO 
