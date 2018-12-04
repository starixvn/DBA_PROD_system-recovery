/*
	DB042 - Indexes for translog
	Run on DB053.bodb02
*/


GRANT SELECT ON [dbo].[translog] TO [bodbDownlineNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[translog] TO [bodbDownlineNetView] AS [dbo]
GO

-->> need to review before apllying this index
CREATE NONCLUSTERED INDEX [IX_betrunning_custid] ON [dbo].[translog]
(
	[custid] ASC,
	[gameID] ASC
)
INCLUDE ( 	[translogid],
	[eventID],
	[odds],
	[status],
	[stake],
	[actual_stake],
	[transdate],
	[apositiontaking],
	[mpositiontaking],
	[spositiontaking],
	[discount],
	[adiscount],
	[sdiscount],
	[ip],
	[custom1],
	[custom2],
	[custom3],
	[transdesc],
	[GameId3rd],
	[TranId3rd],
	[LiveIndicator]) 
WHERE ([statusID] IN ((0), (1)))
WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [translog_index]
GO

--CREATE NONCLUSTERED INDEX [IX_betrunning_mrecommend] ON [dbo].[translog]
--(
--	[mrecommend] ASC,
--	[gameID] ASC
--)
--INCLUDE ( 	[mpositiontaking],
--	[spositiontaking],
--	[actual_stake],
--	[recommend]) 
--WHERE ([statusID] IN ((0), (1)))
--WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [translog_index]
--GO

--CREATE NONCLUSTERED INDEX [IX_betrunning_recommend] ON [dbo].[translog]
--(
--	[recommend] ASC,
--	[gameID] ASC
--)
--INCLUDE ( 	[custid],
--	[apositiontaking],
--	[actual_stake],
--	[mpositiontaking],
--	[spositiontaking]) 
--WHERE ([statusID] IN ((0), (1)))
--WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [translog_index]
--GO

--CREATE NONCLUSTERED INDEX [IX_betrunning_srecommend] ON [dbo].[translog]
--(
--	[srecommend] ASC,
--	[gameID] ASC
--)
--INCLUDE ( 	[spositiontaking],
--	[actual_stake],
--	[mrecommend]) 
--WHERE ([statusID] IN ((0), (1)))
--WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [translog_index]
--GO