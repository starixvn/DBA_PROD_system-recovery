
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Age_TotalBets_Sel14_Ag    Script Date: 1/10/2019 12:06:36 AM ******/
/****** Object:  Stored Procedure dbo.Age_TotalBets_Sel14_Ag    Script Date: 8/7/2018 11:12:06 PM ******/
CREATE PROCEDURE [dbo].[Age_TotalBets_Sel14_Ag]
	@custid int,
	@Language varchar(2) = 'E'
AS
/*
Task: Retrieve Total Bet values for First Goal/Last Goal.
DB: DB053.bodb02
Revisions:
	- 20090216@Kiwi: Remove unnecessary condition a.custid <> 0
	- 20100527@Henry: Change to use StatusID instead of Status in WHERE statement
	- 20111122@Sophia: Add Checktime and SecAcceptFlag to show status waiting or running
	- 20140416@Dom: Add First Half First Goal/ Last Goal (1H FG/LG) (127)
	- 20180802@Helen: Update code for adjusting indexes - [Redmine:98757] 	
*/
BEGIN
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
		sum(Case when hdp1 = 1 and hdp2 = 1 and a.bettype = 14 then stake*(case when odds<0 then 1 else odds-1 end)* apositiontaking else case when a.bettype=127 then 0 else -actual_stake*apositiontaking end end) AS [14_WinLost_HomeFG],
		sum(Case when hdp1 = 1 and hdp2 = 2 and a.bettype = 14 then stake*(case when odds<0 then 1 else odds-1 end)* apositiontaking else case when a.bettype=127 then 0 else -actual_stake*apositiontaking end end) AS [14_WinLost_HomeLG],
		sum(Case when hdp1 = 2 and hdp2 = 1 and a.bettype = 14 then stake*(case when odds<0 then 1 else odds-1 end)* apositiontaking else case when a.bettype=127 then 0 else -actual_stake*apositiontaking end end) AS [14_WinLost_AwayFG],
		sum(Case when hdp1 = 2 and hdp2 = 2 and a.bettype = 14 then stake*(case when odds<0 then 1 else odds-1 end)* apositiontaking else case when a.bettype=127 then 0 else -actual_stake*apositiontaking end end) AS [14_WinLost_AwayLG],
		sum(Case when hdp1 = 0 and hdp2 = 0 and a.bettype = 14 then stake*(case when odds<0 then 1 else odds-1 end)* apositiontaking else case when a.bettype=127 then 0 else -actual_stake*apositiontaking end end) AS [14_WinLost_NoGoal],

		sum(Case when hdp1 = 1 and hdp2 = 1 and a.bettype = 127 then stake*(case when odds<0 then 1 else odds-1 end)* apositiontaking else case when a.bettype=14 then 0 else -actual_stake*apositiontaking end end) AS [127_WinLost_HomeFG],
		sum(Case when hdp1 = 1 and hdp2 = 2 and a.bettype = 127 then stake*(case when odds<0 then 1 else odds-1 end)* apositiontaking else case when a.bettype=14 then 0 else -actual_stake*apositiontaking end end) AS [127_WinLost_HomeLG],
		sum(Case when hdp1 = 2 and hdp2 = 1 and a.bettype = 127 then stake*(case when odds<0 then 1 else odds-1 end)* apositiontaking else case when a.bettype=14 then 0 else -actual_stake*apositiontaking end end) AS [127_WinLost_AwayFG],
		sum(Case when hdp1 = 2 and hdp2 = 2 and a.bettype = 127 then stake*(case when odds<0 then 1 else odds-1 end)* apositiontaking else case when a.bettype=14 then 0 else -actual_stake*apositiontaking end end) AS [127_WinLost_AwayLG],
		sum(Case when hdp1 = 0 and hdp2 = 0 and a.bettype = 127 then stake*(case when odds<0 then 1 else odds-1 end)* apositiontaking else case when a.bettype=14 then 0 else -actual_stake*apositiontaking end end) AS [127_WinLost_NoGoal],

		sum(case when bettype=14 then 1 else 0 end) [betcount_14],
		sum(case when bettype=127 then 1 else 0 end) [betcount_127],

		isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral
	FROM
		bettrans a  WITH (NOLOCK)
		INNER JOIN match 	m  WITH (NOLOCK) ON m.matchid = a.matchid 	
	WHERE 
		a.recommend = @custid AND
		m.eventstatus = 'running'  AND
		a.bettype IN (14,127) AND
		a.statusID IN (0,1) 
		AND (   ISNULL(a.SecAcceptFlag, 0) = 0	
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
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[Age_TotalBets_Sel14_Ag] TO [bodbDownlineNet]
GO 
 GRANT EXECUTE ON [dbo].[Age_TotalBets_Sel14_Ag] TO [bodbDownlineNetView]
GO 
 GRANT EXECUTE ON [dbo].[Age_TotalBets_Sel14_Ag] TO [vnteam]
GO 
 GRANT VIEW DEFINITION ON [dbo].[Age_TotalBets_Sel14_Ag] TO [vnteam]
GO 
