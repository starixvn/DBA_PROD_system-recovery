
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Age_TotalBets_Sel16_Ag    Script Date: 1/10/2019 12:06:36 AM ******/
/****** Object:  Stored Procedure dbo.Age_TotalBets_Sel16_Ag    Script Date: 8/7/2018 11:12:12 PM ******/
CREATE PROCEDURE [dbo].[Age_TotalBets_Sel16_Ag]
	@custid int,
	@Language varchar(2) = 'E'
AS
/*
Task: Retrieve Total Bet values for HT/FT.
DB: DB053.bodb02
Revisions:
	- 20090216@Kiwi: + Remove to select columns: oddsid, liveindicatior, bettype, leagueid, showtime
					 + Remove unnecessary condition: bettrans.liveindicator=0 and oddsid > 0
					 + Add m.matchid >0 to avoid Clustered Index Scan
	- 20100527@Henry: Change to use StatusID instead of Status in WHERE statement
	- 20111122@Sophia: Add Checktime and SecAcceptFlag to show status waiting or running
	- 20180802@Helen: Update code for adjusting indexes - [Redmine:98757] 
*/
BEGIN
	SET NOCOUNT ON
	SELECT
		bettrans.matchid,
		m.homeid,
		m.awayid,
		matchcode,
		
		sum((Case when hdp1 = 1 and hdp2 = 1 then (stake*odds)-stake else -stake end )*(bettrans.apositiontaking)) AS totalHH,
		sum((Case when hdp1 = 1 and hdp2 = 0 then (stake*odds)-stake else -stake end )*(bettrans.apositiontaking)) AS totalHD,
		sum((Case when hdp1 = 1 and hdp2 = 2 then (stake*odds)-stake else -stake end )*(bettrans.apositiontaking)) AS totalHA,
		sum((Case when hdp1 = 0 and hdp2 = 1 then (stake*odds)-stake else -stake end )*(bettrans.apositiontaking)) AS totalDH,
		
		sum((Case when hdp1 = 0 and hdp2 = 0 then (stake*odds)-stake else -stake end )*(bettrans.apositiontaking)) AS totalDD,
		sum((Case when hdp1 = 0 and hdp2 = 2 then (stake*odds)-stake else -stake end )*(bettrans.apositiontaking)) AS totalDA,
		sum((Case when hdp1 = 2 and hdp2 = 1 then (stake*odds)-stake else -stake end )*(bettrans.apositiontaking)) AS totalAH,
		sum((Case when hdp1 = 2 and hdp2 = 0 then (stake*odds)-stake else -stake end )*(bettrans.apositiontaking)) AS totalAD,
		sum((Case when hdp1 = 2 and hdp2 = 2 then (stake*odds)-stake else -stake end )*(bettrans.apositiontaking)) AS totalAA,
		isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral
		
	FROM  bettrans with (nolock)
		inner join match m with (nolock) on m.matchid = bettrans.matchid 		
	WHERE    
		bettrans.recommend=@custid AND 
		bettrans.bettype = 16 AND
		m.eventstatus='running' AND
		--bettrans.status ='running' AND
		bettrans.statusID IN (0,1) AND 
		( ISNULL(bettrans.SecAcceptFlag, 0) = 0	OR (ISNULL(bettrans.SecAcceptFlag, 0) = 1 AND ISNULL(bettrans.checktime, CURRENT_TIMESTAMP) <= CURRENT_TIMESTAMP )
		) AND 
		m.matchid>0
	group by bettrans.matchid,	
		m.homeid,
		m.awayid,	
		matchcode,
		m.isNeutral	
	order by m.matchcode
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[Age_TotalBets_Sel16_Ag] TO [bodbDownlineNet]
GO 
 GRANT EXECUTE ON [dbo].[Age_TotalBets_Sel16_Ag] TO [bodbDownlineNetView]
GO 
 GRANT EXECUTE ON [dbo].[Age_TotalBets_Sel16_Ag] TO [vnteam]
GO 
 GRANT VIEW DEFINITION ON [dbo].[Age_TotalBets_Sel16_Ag] TO [vnteam]
GO 
