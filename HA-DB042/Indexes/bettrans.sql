/*
	DB042 - Indexes for bettrans
	Run on DB053.bodb02
*/

GRANT SELECT ON [dbo].[bettrans] TO [bodbDownlineNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[bettrans] TO [bodbDownlineNetView] AS [dbo]
GO

GRANT SELECT ON [dbo].[bettrans] TO [bodbLicenseeNet] AS [dbo]
GO

--> no need to create clustered index
--CREATE CLUSTERED INDEX [CIX_matchid_bettype] ON [dbo].[bettrans]
--(
--	[matchid] ASC,
--	[bettype] ASC,
--	[custid] ASC
--)WITH (DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, FILLFACTOR = 90) ON [bettrans_table]
--GO

CREATE NONCLUSTERED INDEX [IX_betrunning_custid] ON [dbo].[bettrans]
(
	[custid] ASC,
	[bettype] ASC
)
INCLUDE ( 	[actual_stake],
	[adiscount],
	[apositiontaking],
	[betcheck],
	[betid],
	[betteam],
	[checktime],
	[comstatus],
	[discount],
	[hdp1],
	[hdp2],
	[ip],
	[liveawayscore],
	[livehomescore],
	[liveindicator],
	[matchid],
	[modds],
	[mpositiontaking],
	[odds],
	[oddsid],
	[oddsspread],
	[oddstype],
	[refno],
	[sdiscount],
	[SecAcceptFlag],
	[spositiontaking],
	[stake],
	[status],
	[statusID],
	[transdate],
	[transid],
	[transdesc],
	[ExtraInfo]) 
WHERE ([statusID] IN ((0), (1)))
WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [bettrans_index1]
GO

CREATE NONCLUSTERED INDEX [IX_betrunning_mrecommend] ON [dbo].[bettrans]
(
	[mrecommend] ASC,
	[bettype] ASC,
	[matchid] ASC
)
INCLUDE ( 	[odds],
	[stake],
	[mpositiontaking],
	[livehomescore],
	[liveawayscore],
	[liveindicator],
	[betteam],
	[spositiontaking],
	[actual_stake],
	[recommend],
	[custid],
	[Username],
	[refno],
	[transid],
	[betid],
	[hdp1],
	[hdp2],
	[modds],
	[SecAcceptFlag],
	[checktime],
	[status],
	[transdate],
	[apositiontaking],
	[tpositiontaking],
	[discount],
	[adiscount],
	[sdiscount],
	[ip],
	[oddstype],
	[comstatus],
	[betcheck],
	[oddsspread],
	[currency]) 
WHERE ([statusID] IN ((0), (1)))
WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [bettrans_index1]
GO

CREATE NONCLUSTERED INDEX [IX_betrunning_recommend] ON [dbo].[bettrans]
(
	[recommend] ASC,
	[bettype] ASC,
	[matchid] ASC
)
INCLUDE ( 	[odds],
	[stake],
	[apositiontaking],
	[livehomescore],
	[liveawayscore],
	[liveindicator],
	[betteam],
	[custid],
	[actual_stake],
	[mpositiontaking],
	[spositiontaking],
	[Username],
	[refno],
	[transid],
	[betid],
	[hdp1],
	[hdp2],
	[modds],
	[SecAcceptFlag],
	[checktime],
	[status],
	[transdate],
	[tpositiontaking],
	[discount],
	[adiscount],
	[sdiscount],
	[ip],
	[oddstype],
	[comstatus],
	[betcheck],
	[oddsspread],
	[currency]) 
WHERE ([statusID] IN ((0), (1)))
WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [bettrans_index1]
GO

CREATE NONCLUSTERED INDEX [IX_betrunning_srecommend] ON [dbo].[bettrans]
(
	[srecommend] ASC,
	[bettype] ASC,
	[matchid] ASC
)
INCLUDE ( 	[odds],
	[stake],
	[livehomescore],
	[liveawayscore],
	[liveindicator],
	[betteam],
	[spositiontaking],
	[custid],
	[mpositiontaking],
	[actual_stake],
	[mrecommend],
	[recommend],
	[Username],
	[refno],
	[transid],
	[betid],
	[hdp1],
	[hdp2],
	[modds],
	[SecAcceptFlag],
	[checktime],
	[status],
	[transdate],
	[apositiontaking],
	[tpositiontaking],
	[discount],
	[adiscount],
	[sdiscount],
	[ip],
	[oddstype],
	[comstatus],
	[betcheck],
	[oddsspread],
	[currency]) 
WHERE ([statusID] IN ((0), (1)))
WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [bettrans_index1]
GO

CREATE NONCLUSTERED INDEX [IX_monitor_recommend] ON [dbo].[bettrans]
(
	[recommend] ASC,
	[transid] DESC
)
INCLUDE ( 	[odds],
	[stake],
	[livehomescore],
	[liveawayscore],
	[liveindicator],
	[betteam],
	[custid],
	[actual_stake],
	[Username],
	[matchid],
	[refno],
	[transdate],
	[oddsid],
	[betid],
	[hdp1],
	[hdp2],
	[status],
	[ip],
	[oddstype],
	[betcheck],
	[transdesc],
	[oddsspread],
	[SecAcceptFlag],
	[checktime],
	[bettype],
	[betdaqid],
	[ExtraInfo],
	[WalletType],
	[RefCode],
	[betfrom],
	[currency]) 
WHERE ([statusID] IN ((0), (1)))
WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [bettrans_index1]
GO

--CREATE NONCLUSTERED INDEX [IX_winlostdate] ON [dbo].[bettrans]
--(
--	[winlostdate] ASC
--)
--INCLUDE ( 	[statusID]) WITH (DROP_EXISTING = OFF, ONLINE = OFF) ON [bettrans_index1]
--GO