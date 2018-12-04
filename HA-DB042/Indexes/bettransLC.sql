/*
	DB042 - Indexes for bettransLC
	Run on DB053.bodb02
*/

GRANT SELECT ON [dbo].[bettransLC] TO [bodbAdminNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[bettransLC] TO [bodbDownlineNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[bettransLC] TO [bodbDownlineNetView] AS [dbo]
GO

CREATE NONCLUSTERED INDEX [IX_betrunning_custid] ON [dbo].[bettransLC]
(
	[custid] ASC
)
INCLUDE ( 	[RefNo],
	[gameID],
	[stake],
	[actual_stake],
	[apositiontaking],
	[mpositiontaking],
	[spositiontaking],
	[discount],
	[adiscount],
	[sdiscount]) 
WHERE ([statusID] IN ((0), (1)))
WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [bettransLC_index]
GO

CREATE NONCLUSTERED INDEX [IX_betrunning_mrecommend] ON [dbo].[bettransLC]
(
	[mrecommend] ASC,
	[gameID] ASC
)
INCLUDE ( 	[mpositiontaking],
	[spositiontaking],
	[actual_stake],
	[recommend]) 
WHERE ([statusID] IN ((0), (1)))
WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [bettransLC_index]
GO

CREATE NONCLUSTERED INDEX [IX_betrunning_recommend] ON [dbo].[bettransLC]
(
	[recommend] ASC,
	[gameID] ASC
)
INCLUDE ( 	[custid],
	[apositiontaking],
	[actual_stake],
	[mpositiontaking],
	[spositiontaking]) 
WHERE ([statusID] IN ((0), (1)))
WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [bettransLC_index]
GO

CREATE NONCLUSTERED INDEX [IX_betrunning_srecommend] ON [dbo].[bettransLC]
(
	[srecommend] ASC,
	[gameID] ASC
)
INCLUDE ( 	[spositiontaking],
	[actual_stake],
	[mrecommend]) 
WHERE ([statusID] IN ((0), (1)))
WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [bettransLC_index]
GO

--CREATE NONCLUSTERED INDEX [IX_WinLostDate] ON [dbo].[bettransLC]
--(
--	[winlostdate] ASC
--)
--INCLUDE ( 	[statusID]) WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [bettransLC_index]
--GO