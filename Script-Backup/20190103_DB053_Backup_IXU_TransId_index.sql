USE [bodb02]
GO

/****** Object:  Index [IXU_transid]    Script Date: 1/2/2019 11:16:20 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IXU_transid] ON [dbo].[bettrans]
(
	[transid] ASC
)
INCLUDE ( 	[winlostdate],
	[liveawayscore],
	[liveindicator],
	[matchid],
	[betteam],
	[bettype],
	[currency],
	[ruben],
	[livehomescore],
	[tpositiontaking],
	[status],
	[stake],
	[custid],
	[oddsid],
	[hdp1],
	[hdp2],
	[odds],
	[transdate],
	[refno],
	[comstatus],
	[betid],
	[ip],
	[transdesc],
	[Username],
	[winlost],
	[awinlost],
	[mwinlost],
	[playercomm],
	[comm],
	[acomm],
	[apositiontaking],
	[mpositiontaking],
	[discount],
	[adiscount],
	[actual_stake],
	[sdiscount],
	[scomm],
	[spositiontaking],
	[swinlost],
	[betcheck],
	[oddsspread],
	[modds],
	[betdaqid],
	[oddstype],
	[checktime],
	[SecAcceptFlag]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [Bettrans_index1]
GO


