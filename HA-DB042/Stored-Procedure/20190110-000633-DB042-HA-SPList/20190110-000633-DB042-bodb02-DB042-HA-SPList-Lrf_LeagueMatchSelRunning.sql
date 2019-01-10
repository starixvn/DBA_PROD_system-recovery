
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Lrf_LeagueMatchSelRunning    Script Date: 1/10/2019 12:06:37 AM ******/
CREATE PROCEDURE Lrf_LeagueMatchSelRunning   
 @sporttype tinyint=1,
 @IsIncludeTestLeague 	BIT = 0  
AS    
        
/*          
Created: 20130418@Scott        
Task: Get league, match running        
DB: DB042.bodb02          
Revisions:        
- 20190104@Joseph: Add param @IsIncludeTestLeague to exclude test leagues[Redmine: #107473]
*/    
          
BEGIN        
        
SET NOCOUNT ON          
        
SELECT  match.sporttype, match.leagueid, match.matchid, match.homeid, match.awayid    
FROM league WITH ( NOLOCK )          
  INNER JOIN match WITH ( NOLOCK ) ON league.leagueid = match.leagueid          
WHERE 
  (@IsIncludeTestLeague = 1 OR league.isTest = 0 ) and
  match.sporttype =  @sporttype and        
  match.eventstatus ='running' and      
  match.matchcode not like '%hedge%' --and match.eventdate= CONVERT(VARCHAR(10), getdate(), 111)      

UNION ALL

SELECT l.sporttype, o.leagueid,o.orid ,o.teamid, 0
FROM outright o WITH(NOLOCK)
	INNER JOIN  League l With(nolock) on o.leagueid = l.leagueid AND (@IsIncludeTestLeague = 1 OR l.isTest = 0 )
WHERE l.sporttype =  @sporttype  and   	
	o.oddsstatus = 'running'
         
END          
       

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[Lrf_LeagueMatchSelRunning] TO [bodbLicenseeNet]
GO 
 GRANT EXECUTE ON [dbo].[Lrf_LeagueMatchSelRunning] TO [bodbAdminNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[Lrf_LeagueMatchSelRunning] TO [vnteam]
GO 
