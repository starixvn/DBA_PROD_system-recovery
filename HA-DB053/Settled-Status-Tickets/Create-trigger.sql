/*
	Task -  Switching sync settled ticket from DB53 to DB052
	1- Creatting trigger

	Run on DB052
*/

USE [bodb02]
GO

CREATE TRIGGER [dbo].[bettrans_Settled_UPDATE]
   ON  [dbo].[bettrans]
   AFTER UPDATE
AS 
/*
	Created: 20180622@Patrick
	Task: Get setttled ticket
	DB: DBAGE.bodb02
	
	- Revisions:
*/
BEGIN
	SET NOCOUNT ON

	INSERT INTO dbo.BetSettled_Transition(TransId)
	SELECT TransId 
	FROM inserted
	WHERE bettype < 19999 AND statusID NOT IN (0,1,101)
END

GO


