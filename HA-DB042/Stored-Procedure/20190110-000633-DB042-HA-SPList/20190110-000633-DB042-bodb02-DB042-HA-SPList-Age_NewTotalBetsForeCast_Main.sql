
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Age_NewTotalBetsForeCast_Main    Script Date: 1/10/2019 12:06:35 AM ******/
/****** Object:  Stored Procedure dbo.Age_NewTotalBetsForeCast_Main    Script Date: 8/7/2018 11:12:24 PM ******/
CREATE PROCEDURE [dbo].[Age_NewTotalBetsForeCast_Main]   
    @CustID INT  
    , @MatchIDList  VARCHAR (MAX)
    , @IsLive BIT = 1  
AS  
/*  
	Created By: Helen  
	Created Date: 20151223  
	Task: New Total Bet & Forecast [Redmine: 42116]   
	DB: DBAGE/bodb02  
	  
	Revisions:  
		- 20180802@Helen: Update code for adjusting indexes - [Redmine:98757] 
	
	For testing
		exec Age_NewTotalBetsForeCast_Main @MatchIDList='17354067,17354069,17354078,17354080,17354085,17354087,17354099,17354101',@IsLive=0,@CustID=18364243

*/
BEGIN  
	SET NOCOUNT ON
	 
	DECLARE @roleID INT, @srecommend INT, @mrecommend INT, @IsEndOfHalfTime BIT = 0
	
	SELECT @roleID = roleID, @srecommend = srecommend, @mrecommend = mrecommend   
	FROM custInfo WITH (NOLOCK)  
	WHERE custid = @CustID  
	
	CREATE TABLE #MatchInfo (MatchID INT PRIMARY KEY, homeid INT, awayid INT, livehomescore  INT
							, liveawayscore INT
							, HasLive BIT
							, kickofftime DATETIME
							, leagueid INT
							, showtime NVARCHAR(50)
							, scorediff INT
							, TotalGoals INT
							, IsEndOfHalfTime BIT )
	
	DECLARE @MatchSQL NVARCHAR(2000) = ''
	DECLARE @BetTypeSQL NVARCHAR(2000) = ''
	
	SET @MatchSQL = 'INSERT INTO #MatchInfo (MatchID, homeid, awayid, livehomescore, liveawayscore, HasLive, kickofftime, leagueid, showtime,scorediff,totalGoals, IsEndOfHalfTime)
	SELECT m.matchid, m.homeid, m.awayid  
		, m.livehomescore  
		, m.liveawayscore
		, m.HasLive
		, m.kickofftime
		, m.leagueid
		, m.showtime
		, m.livehomescore - m.liveawayscore as scorediff
		, m.livehomescore + m.liveawayscore as TotalGoals
		, CASE WHEN DATEADD(MINUTE,45,kickofftime) < GETDATE() THEN 1 ELSE 0 END AS IsEndOfHalfTime 
	FROM match m WITH (NOLOCK)
	WHERE M.matchid IN (' +  @MatchIDList + ')'
	
	EXEC sp_executeSQL @MatchSQL
	
	CREATE TABLE #ForecastTbl (MatchID INT,BettypeID SMALLINT,F1 SMALLINT, F2 SMALLINT,F3 SMALLINT,F4 SMALLINT,F5 SMALLINT,HighlightValue_3_8 SMALLINT, PRIMARY KEY CLUSTERED (BettypeID,MatchID))
	
	IF @IsLive = 1
	BEGIN
		INSERT INTO #ForecastTbl (MatchID ,BettypeID ,F1, F2 , F3 , F4 , F5 )  
		SELECT DISTINCT od.MatchID,od.bettype
				, CASE 
						WHEN od.bettype IN (1,7) THEN m.scorediff + 2
						WHEN od.bettype IN (3,8) THEN m.TotalGoals + 4
						ELSE 0
				  END F1
				, CASE 
						WHEN od.bettype IN (1,7) THEN m.scorediff + 1
						WHEN od.bettype IN (3,8) THEN m.TotalGoals + 3
						ELSE 0
				  END F2
			  , CASE 
					WHEN od.bettype IN (1,7) THEN m.scorediff 
					WHEN od.bettype IN (3,8) THEN m.TotalGoals + 2 
					ELSE 0
			  END F3
			  , CASE 
					WHEN od.bettype IN (1,7) THEN m.scorediff - 1
					WHEN od.bettype IN (3,8) THEN m.TotalGoals + 1
					ELSE 0
			  END F4
			  , CASE 
					WHEN od.bettype IN (1,7) THEN m.scorediff - 2
					WHEN od.bettype IN (3,8) THEN m.TotalGoals 
					ELSE 0
			  END F5	
						
		FROM odds od WITH (NOLOCK) 
			INNER JOIN #MatchInfo M ON M.MatchID = OD.matchid --AND od.oddsstatus = 'running'
		WHERE (M.IsEndOfHalfTime = 0 AND od.bettype IN (1,3,7,8,5,15)) OR (M.IsEndOfHalfTime = 1 AND od.bettype IN (1,3,5))
		
	END
	ELSE IF @IsLive = 0
	BEGIN
		INSERT INTO #ForecastTbl (MatchID ,BettypeID ,F1, F2 , F3 , F4 , F5, HighlightValue_3_8 )  
		SELECT F.matchid, F.bettype 
				, CASE WHEN F.bettype IN (5,15) THEN 0 ELSE ForecastScore + 2 END AS	F1
				, CASE WHEN F.bettype IN (5,15) THEN 0 ELSE ForecastScore + 1 END AS	F2
				, CASE WHEN F.bettype IN (5,15) THEN 0 ELSE ForecastScore	END AS	F3
				, CASE WHEN F.bettype IN (5,15) THEN 0 ELSE ForecastScore - 1 END AS	F4
				, CASE WHEN F.bettype IN (5,15) THEN 0 ELSE ForecastScore - 2 END AS	F5
				, CASE WHEN F.bettype IN (3,8) THEN HighlightValue_3_8 ELSE 0 END AS HighlightValue_3_8
			  
		FROM (
			SELECT DISTINCT od.MatchID,od.bettype
					, CASE WHEN od.bettype IN (1,7) THEN CAST(AVG (od.hdp1 - od.hdp2) AS SMALLINT)
						   WHEN od.bettype IN (3,8) THEN 
								CASE WHEN AVG (od.hdp1) < = 2  THEN 2  ELSE CAST (AVG (od.hdp1) AS SMALLINT)
								END
							ELSE 0	
						END AS ForecastScore
					, AVG (od.hdp1) AS HighlightValue_3_8		
			FROM odds od WITH (NOLOCK) 
				INNER JOIN #MatchInfo M ON M.MatchID = OD.matchid AND od.oddsstatus = 'running'
			WHERE (M.IsEndOfHalfTime = 0 AND od.bettype IN (1,3,7,8)) OR (M.IsEndOfHalfTime = 1 AND od.bettype IN (1,3))
			GROUP BY od.matchid,od.bettype
			
			UNION ALL
			
			SELECT DISTINCT od.MatchID,od.bettype
					, 0 ForecastScore
					, 0 AS HighlightValue_3_8		
			FROM odds od WITH (NOLOCK) 
				INNER JOIN #MatchInfo M ON M.MatchID = OD.matchid 
			WHERE (M.IsEndOfHalfTime = 0 AND od.bettype IN (5,15)) OR (M.IsEndOfHalfTime = 1 AND od.bettype IN (5))
			
		) AS F
	END
	
	CREATE TABLE #bettrans_1_7_3_8 (ID INT IDENTITY, matchid INT, bettype SMALLINT, betteam NVARCHAR(10),livehomescore_B SMALLINT, liveawayscore_B SMALLINT,hdp1 SMALLMONEY,hdp2 SMALLMONEY
							, Betcount INT,TurnOver_stake MONEY, TurnOver_Actualstake MONEY,Odds SMALLMONEY, PRIMARY KEY CLUSTERED (bettype,matchid,id))  
	
	CREATE TABLE #bettrans_5_15 (ID INT IDENTITY,matchid INT,bettype SMALLINT, positiontaking SMALLMONEY,stake MONEY,betteam NVARCHAR(10),Odds SMALLMONEY, PRIMARY KEY CLUSTERED (bettype,matchid,id))  
	
	DECLARE @Bettype_1_7_3_8_tmp AS TABLE (bettype SMALLINT,IsEndOfHalfTime BIT )					
	DECLARE @Bettype_5_15_tmp AS TABLE (bettype SMALLINT,IsEndOfHalfTime BIT )					
	
	INSERT INTO @Bettype_1_7_3_8_tmp (bettype,IsEndOfHalfTime)
	VALUES (1,0), (3,0),(7,0),(8,0), (1,1), (3,1)
	
	INSERT INTO @Bettype_5_15_tmp  (bettype,IsEndOfHalfTime)
	VALUES (5,0), (15,0), (5,1)
	
	IF @roleID = 2
	BEGIN
		
		INSERT INTO #bettrans_1_7_3_8 (b.matchid,bettype,betteam,livehomescore_B,liveawayscore_B,hdp1,hdp2,Betcount,TurnOver_stake,TurnOver_Actualstake,Odds)  
		SELECT b.matchid, b.bettype,b.betteam, b.livehomescore,b.liveawayscore,b.hdp1,b.hdp2
			, COUNT(1) AS Betcount
			, SUM(b.apositiontaking*b.stake) AS TurnOver_stake
			, SUM(b.apositiontaking*b.actual_stake) AS TurnOver_Actualstake
			, CASE WHEN b.odds < 0 THEN 1 ELSE b.odds END Odds
			
		FROM dbo.bettrans b WITH (NOLOCK,INDEX=IX_betrunning_recommend)  
			INNER JOIN #MatchInfo M ON b.matchid = m.MatchID
			INNER JOIN @Bettype_1_7_3_8_tmp bt ON bt.bettype = b.bettype AND M.IsEndOfHalfTime = bt.IsEndOfHalfTime
		WHERE b.recommend = @CustID 
			AND b.statusID IN (0,1)
		GROUP BY b.matchid, b.bettype,b.betteam, b.livehomescore,b.liveawayscore,b.hdp1,b.hdp2
			, CASE WHEN b.odds < 0 THEN 1 ELSE b.odds END
		
		INSERT INTO #bettrans_5_15 (matchid,bettype,positiontaking,stake,betteam ,odds)  
		SELECT 
			 b.matchid
			, b.bettype  
			, b.apositiontaking AS positiontaking 
			, b.stake, b.betteam  
			, b.odds  
		FROM dbo.bettrans b WITH (NOLOCK,INDEX=IX_betrunning_recommend)  
			INNER JOIN #MatchInfo M ON b.matchid = m.MatchID
			INNER JOIN @Bettype_5_15_tmp bt ON bt.bettype = b.bettype AND M.IsEndOfHalfTime = bt.IsEndOfHalfTime
		WHERE b.recommend = @CustID 
			AND b.statusID IN (0,1) 
		  
	END
	ELSE 
	IF @roleID = 3
	BEGIN
		INSERT INTO #bettrans_1_7_3_8 (matchid,bettype,betteam,livehomescore_B,liveawayscore_B,hdp1,hdp2,Betcount,TurnOver_stake,TurnOver_Actualstake,Odds)  
		SELECT b.matchid, b.bettype,b.betteam, b.livehomescore,b.liveawayscore,b.hdp1,b.hdp2
				, COUNT(1) AS Betcount
				, SUM(b.mpositiontaking*b.stake) AS TurnOver_stake
				, SUM(b.mpositiontaking*b.actual_stake) AS TurnOver_Actualstake
				, CASE WHEN b.odds < 0 THEN 1 ELSE b.odds END
		FROM dbo.bettrans b WITH (NOLOCK,INDEX=IX_betrunning_mrecommend)  
			INNER JOIN #MatchInfo M ON b.matchid = m.MatchID
			INNER JOIN @Bettype_1_7_3_8_tmp bt ON bt.bettype = b.bettype AND M.IsEndOfHalfTime = bt.IsEndOfHalfTime
		WHERE b.mrecommend = @CustID 
			AND b.statusID IN (0,1)
		GROUP BY b.matchid,b.bettype,b.betteam, b.livehomescore,b.liveawayscore,b.hdp1,b.hdp2
				, CASE WHEN b.odds < 0 THEN 1 ELSE b.odds END
		
		INSERT INTO #bettrans_5_15 (matchid,bettype,positiontaking,stake,betteam ,odds)  
		SELECT 
			 b.matchid
			, b.bettype  
			, b.mpositiontaking AS positiontaking 
			, b.stake, b.betteam  
			, b.odds  
		FROM dbo.bettrans b WITH (NOLOCK,INDEX=IX_betrunning_mrecommend)  
			INNER JOIN #MatchInfo M ON b.matchid = m.MatchID
			INNER JOIN @Bettype_5_15_tmp bt ON bt.bettype = b.bettype AND M.IsEndOfHalfTime = bt.IsEndOfHalfTime
		WHERE b.srecommend = @srecommend AND b.mrecommend = @CustID 
			AND b.statusID IN (0,1)
			
	END
	ELSE IF @roleID = 4
	BEGIN
		INSERT INTO #bettrans_1_7_3_8 (matchid,bettype,betteam,livehomescore_B,liveawayscore_B,hdp1,hdp2,Betcount,TurnOver_stake,TurnOver_Actualstake,Odds)  
		SELECT b.matchid, b.bettype,b.betteam, b.livehomescore,b.liveawayscore,b.hdp1,b.hdp2
			, COUNT(1) Betcount
			, SUM(b.spositiontaking*b.stake) AS TurnOver_stake
			, SUM(b.spositiontaking*b.actual_stake) AS TurnOver_Actualstake
			, CASE WHEN b.odds < 0 THEN 1 ELSE b.odds END
		FROM dbo.bettrans b WITH (NOLOCK,INDEX=IX_betrunning_srecommend)
			INNER JOIN #MatchInfo M ON b.matchid = m.MatchID  
			INNER JOIN @Bettype_1_7_3_8_tmp bt ON bt.bettype = b.bettype AND M.IsEndOfHalfTime = bt.IsEndOfHalfTime
		WHERE b.srecommend = @CustID 
			AND b.statusID IN (0,1)
		GROUP BY b.matchid,b.bettype,b.betteam, b.livehomescore,b.liveawayscore,b.hdp1,b.hdp2
			, CASE WHEN b.odds < 0 THEN 1 ELSE b.odds END
		
		INSERT INTO #bettrans_5_15 (matchid,bettype,positiontaking,stake,betteam,odds)  
		SELECT	b.matchid
			, b.bettype  
			, b.spositiontaking AS positiontaking 
			, b.stake, b.betteam  
			, b.odds  
		FROM dbo.bettrans b WITH (NOLOCK,INDEX=IX_betrunning_srecommend)  
			INNER JOIN #MatchInfo M ON b.matchid = m.MatchID
			INNER JOIN @Bettype_5_15_tmp bt ON bt.bettype = b.bettype AND M.IsEndOfHalfTime = bt.IsEndOfHalfTime
		WHERE b.srecommend = @CustID 
			AND b.statusID IN (0,1)
		
	END
	
	-- Match info
	SELECT m.matchid, m.homeid, m.awayid  
		, m.livehomescore  
		, m.liveawayscore
		, m.HasLive
		, m.kickofftime
		, m.leagueid
		, m.showtime
		, @IsLive AS IsLive
	FROM #MatchInfo M
	
	-- Forecast winloss	
	-- Bettype HDP
	SELECT F1.matchid,F1.BettypeID, ISNULL(SUM (F1),0) AS Winloss1, ISNULL(SUM(F2),0) Winloss2, ISNULL(SUM(F3),0) Winloss3, ISNULL(SUM(F4),0) Winloss4, ISNULL(SUM(F5),0) as Winloss5
	FROM (
		SELECT f.matchid,f.BettypeID
			, (SELECT outputNumber FROM dbo.f_NewTotalBetsForecast_GetWinLost_HDP(F1,b.livehomescore_B,b.liveawayscore_B,b.hdp1,b.hdp2,b.betteam,b.TurnOver_Actualstake,b.TurnOver_stake,odds)) AS F1 
			, (SELECT outputNumber FROM dbo.f_NewTotalBetsForecast_GetWinLost_HDP(F2,b.livehomescore_B,b.liveawayscore_B,b.hdp1,b.hdp2,b.betteam,b.TurnOver_Actualstake,b.TurnOver_stake,odds)) AS F2 
			, (SELECT outputNumber FROM dbo.f_NewTotalBetsForecast_GetWinLost_HDP(F3 ,b.livehomescore_B,b.liveawayscore_B,b.hdp1,b.hdp2,b.betteam,b.TurnOver_Actualstake,b.TurnOver_stake,odds))  AS F3
			, (SELECT outputNumber FROM dbo.f_NewTotalBetsForecast_GetWinLost_HDP(F4,b.livehomescore_B,b.liveawayscore_B,b.hdp1,b.hdp2,b.betteam,b.TurnOver_Actualstake,b.TurnOver_stake,odds))  AS F4
			, (SELECT outputNumber FROM dbo.f_NewTotalBetsForecast_GetWinLost_HDP(F5 ,b.livehomescore_B,b.liveawayscore_B,b.hdp1,b.hdp2,b.betteam,b.TurnOver_Actualstake,b.TurnOver_stake,odds))  AS F5
		FROM #ForecastTbl F 
			LEFT JOIN #bettrans_1_7_3_8 b ON b.matchid = f.MatchID AND b.bettype = f.BettypeID
		WHERE f.bettypeid IN (1,7)
	) AS F1
	
	GROUP BY F1.matchid,F1.BettypeID
	
	UNION ALL
	-- Bettype O/U
	SELECT F2.matchid,F2.BettypeID, ISNULL(SUM (F1),0) AS Winloss1, ISNULL(SUM(F2),0) Winloss2, ISNULL(SUM(F3),0) Winloss3, ISNULL(SUM(F4),0) Winloss4, ISNULL(SUM(F5),0) as Winloss5
	FROM (
		SELECT f.matchid,f.BettypeID
			, (SELECT outputNumber FROM dbo.f_NewTotalBetsForecast_GetWinLost_OU(b.hdp1,b.hdp2,b.betteam,F1,b.TurnOver_Actualstake,b.TurnOver_stake,odds)) AS F1
			, (SELECT outputNumber FROM dbo.f_NewTotalBetsForecast_GetWinLost_OU(b.hdp1,b.hdp2,b.betteam,F2,b.TurnOver_Actualstake,b.TurnOver_stake,odds)) AS F2
			, (SELECT outputNumber FROM dbo.f_NewTotalBetsForecast_GetWinLost_OU(b.hdp1,b.hdp2,b.betteam,F3,b.TurnOver_Actualstake,b.TurnOver_stake,odds)) AS F3
			, (SELECT outputNumber FROM dbo.f_NewTotalBetsForecast_GetWinLost_OU(b.hdp1,b.hdp2,b.betteam,F4,b.TurnOver_Actualstake,b.TurnOver_stake,odds)) AS F4
			, (SELECT outputNumber FROM dbo.f_NewTotalBetsForecast_GetWinLost_OU(b.hdp1,b.hdp2,b.betteam,F5 , b.TurnOver_Actualstake,b.TurnOver_stake,odds)) AS F5
		FROM #ForecastTbl F 
			LEFT JOIN #bettrans_1_7_3_8 b ON b.matchid = f.MatchID AND b.bettype = f.BettypeID
		WHERE f.bettypeid IN (3,8) 
	) AS F2
	GROUP BY F2.matchid,F2.bettypeid

	UNION ALL
	
	-- Bettype 1X2
	SELECT matchid, BettypeID,   
		-- Member View
		--Negative number in black indicates the amount SMA may win and Members may lose.	
		--Positive number in red indicates the amount SMA may lose and Members may win.
		(x.homewin - x.awaylose - x.drawlose) 'w1',
		(x.drawwin - x.awaylose - x.homelose) 'wx',  
		(x.awaywin - x.homelose - x.drawlose) 'w2',0,0  -- away win, agent lose
		
		
	FROM(SELECT  F.matchid, F.BettypeID,
			SUM(CASE WHEN betteam='1' THEN (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) * stake * (positiontaking) ELSE 0 END) homewin,  
			SUM(CASE WHEN betteam='2' THEN (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) * stake * (positiontaking) ELSE 0 END) awaywin,  
			SUM(CASE WHEN betteam='x' THEN (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) * stake * (positiontaking) ELSE 0 END) drawwin,  

			SUM(CASE WHEN betteam='1' THEN (CASE WHEN odds < 0 THEN ABS(odds - 1) ELSE 1 END)  * stake * (positiontaking) ELSE 0 END) homelose,  
			SUM(CASE WHEN betteam='2' THEN (CASE WHEN odds < 0 THEN ABS(odds - 1) ELSE 1 END)  * stake * (positiontaking) ELSE 0 END) awaylose,  
			SUM(CASE WHEN betteam='x' THEN (CASE WHEN odds < 0 THEN ABS(odds - 1) ELSE 1 END)  * stake * (positiontaking) ELSE 0 END) drawlose

		FROM #ForecastTbl F
			LEFT JOIN #bettrans_5_15 b ON F.matchid = b.matchid AND F.bettypeid = b.bettype
		WHERE f.BettypeID IN (5,15)	
		GROUP BY F.matchid,F.BettypeID
		)x   

	-- Forecast Score Definition
	SELECT f.matchid,f.BettypeID
			, ISNULL(T.TurnOver,0) AS TurnOver,ISNULL(T.BetCount,0) AS BetCount
			, f.F1 AS column1	
			, f.F2 AS column2	
			, f.F3 AS column3	
			, f.F4 AS column4	
			, f.F5 AS column5	
			, ISNULL(f.HighlightValue_3_8,0) AS HighlightValue_3_8
			
	FROM #ForecastTbl f 
		LEFT JOIN ( SELECT Matchid,BetType, SUM(Betcount) AS BetCount, SUM (TurnOver_stake) AS TurnOver
					FROM #bettrans_1_7_3_8
					GROUP BY Matchid,BetType
					UNION ALL
					SELECT Matchid,BetType, COUNT(1) AS BetCount, SUM (positiontaking * stake) AS TurnOver
					FROM #bettrans_5_15
					GROUP BY Matchid,BetType
					
					) AS T ON T.BetType = f.BetTypeID AND T.matchid = F.MatchID
	
	-- FOR BetType 1x2
		
	DROP TABLE #bettrans_1_7_3_8
	DROP TABLE #bettrans_5_15
	DROP TABLE #ForecastTbl
	
	SET NOCOUNT OFF	
	
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[Age_NewTotalBetsForeCast_Main] TO [bodbDownlineNet]
GO 
 GRANT EXECUTE ON [dbo].[Age_NewTotalBetsForeCast_Main] TO [bodbDownlineNetView]
GO 
 GRANT EXECUTE ON [dbo].[Age_NewTotalBetsForeCast_Main] TO [vnteam]
GO 
 GRANT VIEW DEFINITION ON [dbo].[Age_NewTotalBetsForeCast_Main] TO [vnteam]
GO 
