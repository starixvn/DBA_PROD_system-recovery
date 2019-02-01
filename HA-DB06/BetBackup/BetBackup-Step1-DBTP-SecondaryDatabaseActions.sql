/*
	Creator:	20190130@Billy
	Task:		HA SOP - DB06 - BetBackup - Step 1 - [Redmine: #000000]
	Server:		DB06
*/


--	BEGIN STEP 1:
--		Enable triggers for BetBackup
----------------------------------------------------------------------------------------------------

USE bodb02;
GO

ENABLE TRIGGER	dbo.bettrans_afterINSERT ON dbo.bettrans;
ENABLE TRIGGER	dbo.bettransm_afterINSERT ON dbo.bettransm;
GO