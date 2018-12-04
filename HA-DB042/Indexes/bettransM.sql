/*
	DB042 - Indexes for bettransM
	Run on DB053.bodb02
*/

GRANT SELECT ON [dbo].[bettransm] TO [bodbDownlineNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[bettransm] TO [bodbDownlineNetView] AS [dbo]
GO

--> no need to deploy clustered index
--CREATE CLUSTERED INDEX [IX_bettransm] ON [dbo].[bettransm]
--(
--	[custid] ASC,
--	[refno] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [BettransM_table]
--GO

GO

--CREATE NONCLUSTERED INDEX [IX_matchid] ON [dbo].[bettransm]
--(
--	[matchid] ASC
--)
--INCLUDE ( 	[statuswinlost],
--	[refno],
--	[transid],
--	[status],
--	[bettype],
--	[statusID],
--	[winlostdate]) WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [BettransM_index]
--GO

--CREATE NONCLUSTERED INDEX [IX_refno_bettype] ON [dbo].[bettransm]
--(
--	[refno] ASC,
--	[bettype] ASC
--)
--INCLUDE ( 	[odds],
--	[stake],
--	[status],
--	[apositiontaking],
--	[mpositiontaking],
--	[spositiontaking]) WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [BettransM_index]
--GO
