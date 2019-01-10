
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Age_TotalBets_Sel2021_SAg    Script Date: 1/10/2019 12:06:36 AM ******/
/****** Object:  Stored Procedure dbo.Age_TotalBets_Sel2021_SAg    Script Date: 8/7/2018 11:12:17 PM ******/
CREATE PROCEDURE [dbo].[Age_TotalBets_Sel2021_SAg]
	@custid int,
	@Language varchar(2) = 'E'
AS
/*
Task: Retrieve Total Bet values for MoneyLine.
DB: DB053.bodb02
Revisions:
	- 20090216@Kiwi: Remove unnecessary condition: a.custid <> 0
	- 20100527@Henry: Change to use StatusID instead of Status in WHERE statement
	- 20100817@Henry: Allow to show 1st Half Money Line
	- 20100821@Jamie: Remove @ruben in filter 
	- 20111122@Sophia: Add Checktime and SecAcceptFlag to show status waiting or running
	- 20180802@Helen: Update code for adjusting indexes - [Redmine:98757] 
*/

SET NOCOUNT ON

SELECT
	m.showtime, 
	m.leagueid,
	m.matchcode,
	a.liveindicator,
	m.matchid,
	m.homeid,
	m.awayid,
	a.livehomescore,
	a.liveawayscore,
	sum((Case when bettype = 20 then (case when betteam = 'h' then (a.spositiontaking)*stake else 0 end)*(case when abs(odds) <1 then 1 else abs(odds) end) else 0 end )) AS home_odds,
	sum((Case when bettype = 20 then (case when betteam = 'a' then (a.spositiontaking)*stake else 0 end)*(case when abs(odds) <1 then 1 else abs(odds) end) else 0 end )) AS away_odds,
	
	sum(Case when bettype = 20 then (case when betteam = 'h' then stake*(case when odds<0 then 1 else odds end)* spositiontaking else -actual_stake*spositiontaking end) else 0 end) AS WinLost_home,
	sum(Case when bettype = 20 then (case when betteam = 'a' then stake*(case when odds<0 then 1 else odds end)* spositiontaking else -actual_stake*spositiontaking end) else 0 end) AS WinLost_away,
	
	sum((Case when bettype = 21 then (case when betteam = 'h' then (a.spositiontaking)*stake else 0 end)*(case when abs(odds) <1 then 1 else abs(odds) end) else 0 end)) AS home_odds_HT,
	sum((Case when bettype = 21 then (case when betteam = 'a' then (a.spositiontaking)*stake else 0 end)*(case when abs(odds) <1 then 1 else abs(odds) end) else 0 end)) AS away_odds_HT,
	
	sum(Case when bettype = 21 then (case when betteam = 'h' then stake*(case when odds<0 then 1 else odds end)* spositiontaking else -actual_stake*spositiontaking end) else 0 end) AS WinLost_home_HT,
	sum(Case when bettype = 21 then (case when betteam = 'a' then stake*(case when odds<0 then 1 else odds end)* spositiontaking else -actual_stake*spositiontaking end) else 0 end) AS WinLost_away_HT,
	
	
	isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral
FROM
	bettrans 		a  WITH (NOLOCK, INDEX = IX_betrunning_srecommend)
	INNER JOIN match 	m  WITH (NOLOCK) ON m.matchid = a.matchid 
WHERE 
	a.bettype IN (20,21) AND
	a.srecommend = @custid AND
	m.eventstatus = 'running'  AND
	a.statusID IN (0,1) AND
	(	ISNULL(a.SecAcceptFlag, 0) = 0	
		OR (ISNULL(a.SecAcceptFlag, 0) = 1 AND ISNULL(a.checktime, CURRENT_TIMESTAMP) <= CURRENT_TIMESTAMP )
	)
	
GROUP BY
	a.liveindicator,
	m.homeid,
	m.awayid,	
	m.matchid,
	m.matchcode,
	m.leagueid,
	a.livehomescore,
	a.liveawayscore,
	m.showtime,
	m.isNeutral
ORDER BY
	m.matchcode, a.liveindicator desc
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[Age_TotalBets_Sel2021_SAg] TO [bodbDownlineNet]
GO 
 GRANT EXECUTE ON [dbo].[Age_TotalBets_Sel2021_SAg] TO [bodbDownlineNetView]
GO 
 GRANT EXECUTE ON [dbo].[Age_TotalBets_Sel2021_SAg] TO [vnteam]
GO 
 GRANT VIEW DEFINITION ON [dbo].[Age_TotalBets_Sel2021_SAg] TO [vnteam]
GO 
