/*
	Task - Switching bet running from db042 to db053
	1- Disable trigger

	Run on DB053
*/

USE bodb02
GO

ALTER TABLE [dbo].[bettrans] DISABLE TRIGGER [bettrans_Settled_UPDATE]
GO