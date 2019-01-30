ductri~`7121

INSERT INTO	vnDBA_RDP_Excluded
	(	[ServerName], [UserName], [ClientName], [ForcedExcluded])
SELECT 'SIE-RDP02', '', '', 1 UNION ALL
SELECT 'SIE-RDP02', 'RD%', 'TW%', 1 UNION ALL
SELECT 'SIE-RDP02', 'sk%', 'IT%', 1 UNION ALL
SELECT 'SIE-RDP02', 'vnBilly', 'NB009-BILLY', 1
