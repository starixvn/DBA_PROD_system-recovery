/*
	DB042 - Indexes for bettransG
	Run on DB053.bodb02
*/

--GRANT SELECT ON [dbo].[bettransG] TO [bodbDownlineNet] AS [dbo]
--GO

--GRANT SELECT ON [dbo].[bettransG] TO [bodbDownlineNetView] AS [dbo]
--GO

--> no need to deploy clustered index
--CREATE CLUSTERED INDEX [IX_bettransG] ON [dbo].[bettransG]
--(
--	[custid] ASC,
--	[refno] ASC
--)WITH (DROP_EXISTING = OFF, ONLINE = OFF) ON [BettransG]
--GO

--CREATE NONCLUSTERED INDEX [_MS_Sys_16_25040500] ON [dbo].[bettransG]
--(
--	[refno] ASC
--)WITH (ONLINE = OFF, ALLOW_ROW_LOCKS = ON) ON [BettransG]
--GO

--CREATE NONCLUSTERED INDEX [IX_matchid] ON [dbo].[bettransG]
--(
--	[matchid] ASC
--)
--INCLUDE ( 	[refno],
--	[statuswinlost]) WITH (DROP_EXISTING = OFF, ONLINE = ON) ON [BettransG]
--GO
