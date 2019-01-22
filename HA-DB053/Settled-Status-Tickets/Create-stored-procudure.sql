/*
	Task -  Switching sync settled ticket from DB53 to DB052
	1- Creatting stored procedure

	Run on DB052
*/

USE [bodb02]
GO

CREATE PROCEDURE [dbo].[Task_Get_Tickets_settled2]
	@batchSize int = 500
AS
/*
	20180621 @ Viet
	DB053.bodb02
*/
BEGIN
	--RETURN
	SET NOCOUNT ON

	DECLARE @MaxRowId BIGINT, @LastRowId BIGINT, @TransIDs VARCHAR(MAX)
	
	SELECT @LastRowId = sValue
	FROM dbo.Tickets_settled_setting WITH(NOLOCK)
	WHERE sKey = 'TransitionId'
	
	SELECT @MaxRowId = MAX(RowId)
	FROM dbo.BetSettled_Transition WITH(NOLOCK)

	SELECT @LastRowId = ISNULL(@LastRowId, 0), @MaxRowId = ISNULL(@MaxRowId, 0)
	IF (@LastRowId = @MaxRowId) RETURN -- no row

	--wait for all trans can commit
	WAITFOR DELAY '00:00:00:280'

	DECLARE @RowIds TABLE (TransId BIGINT)

	INSERT INTO @RowIds(TransId)
	SELECT TransId
	FROM dbo.BetSettled_Transition WITH(NOLOCK)
	WHERE RowId > @LastRowId AND RowId <= @MaxRowId
	GROUP BY TransId
			
	DECLARE @__TmpIds TABLE(TransId BIGINT)
	DECLARE @MessageData NVARCHAR(MAX), @ErrorCode BIT = 0, @Retry INT = 0, @xml XML
	WHILE 1 = 1
	BEGIN
		DELETE @__TmpIds
		SELECT @TransIDs = NULL, @ErrorCode = 0, @Retry = 0, @xml = NULL

		DELETE TOP(@batchSize) @RowIds
		OUTPUT DELETED.TransId INTO @__TmpIds

		IF @@ROWCOUNT = 0
			BREAK

		SELECT @TransIDs = COALESCE(@TransIDs + ',' + CAST(TransId AS VARCHAR(50)), CAST(TransId AS VARCHAR(50)))
		FROM @__TmpIds

		SET @xml = N'<root><r>' + REPLACE(@TransIDs, ',', '</r><r>') + '</r></root>'
		
		Retry:
		EXEC sb.Settled_Ticket_SendMessage @xml = @xml, @ContractName = 'Contract_Settled_Ticket', @SB_error = @ErrorCode OUTPUT
		
		IF @ErrorCode > 0
		BEGIN

			SET @Retry = @Retry + 1
			IF @Retry > 10
				BREAK

			WAITFOR DELAY '00:00:00:280'
			GOTO Retry
			
		END
		--wait for all trans can commit
		WAITFOR DELAY '00:00:00:010'
	END

	IF @ErrorCode = 0
	BEGIN
		UPDATE dbo.Tickets_settled_setting WITH(ROWLOCK, UPDLOCK) 
		SET sValue = @MaxRowId
		WHERE sKey = 'TransitionId'
	END
END
GO

CREATE PROCEDURE [sb].[Settled_Ticket_SendMessage]
(	
		@Xml XML = NULL
	,	@FunctionName VARCHAR(100) = 'BETRUNNING'
	,	@ContractName VARCHAR(100) = ''
	,	@SB_error BIT = 0 OUTPUT
)
AS
/*
	Create By: 20180625@Patrick
	Task: Apply Service Broker for Bet Running function
	DB: DBAGE.bodb02 
		
	Revision
		- 20180508@Helen: Hardcode messagetype to have better performance [Redmine: N/A]
		
	Para's explaination
*/

BEGIN
	
	SET NOCOUNT ON
	DECLARE @Handle UNIQUEIDENTIFIER, @MessageType VARCHAR (200)
	DECLARE @ErrorCode INT = 0, @ErrorMessage VARCHAR(MAX) = ''
	
	IF @ContractName = 'Contract_Settled_Ticket' 
		SET @MessageType = 'MessageType_Settled_Ticket'
	
	EXEC sb.ConversationPick @FunctionName = @FunctionName, @ContractName = @ContractName, @Handle = @Handle OUT
	
	IF @Handle IS NULL
	BEGIN
		SET @SB_error = 1
		RETURN
	END
	ELSE
	BEGIN
		EXEC sb.MsgSent @Handle = @Handle, @Xml = @Xml, @MessageType = @MessageType , @ErrorCode = @ErrorCode OUT, @ErrorMessage =  @ErrorMessage OUT
		IF @ErrorCode <> 0
			SET @SB_error = 1
		ELSE 
			SET @SB_error = 0	
	END
	
END


--==========================================

GO
CREATE PROCEDURE [sb].[ConversationManagement_Del]
        @FunctionName VARCHAR(100)
    ,    @ContractName VARCHAR(100)    
    ,    @NewCnt INT 
AS
/*
    Create By: Don
    Created Date: 2017-03-22
    Task: Apply Service Broker for Turnover Control function
    DB: DBAGE.bodb02
    
    Para's explaination
*/
BEGIN 
    SET NOCOUNT ON 
                       
    DECLARE @ErrorMessage NVARCHAR(4000) 
          , @ErrorSeverity INT
          , @ErrorState INT
    
    SELECT @ErrorSeverity = 10, @ErrorState = 1                    
    
    SET @ErrorMessage = '=============================================== Begin decrease process ==============================================='
    RAISERROR (@ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
              );
                              
    UPDATE sb.ConversationCount WITH (ROWLOCK)
        SET Cnt = @NewCnt
    WHERE FunctionName = @FunctionName
      AND ContractName = @ContractName    
    
    SET @ErrorMessage = '=============================================== End decrease process ==============================================='
    RAISERROR (@ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
              )
    
END

GO

CREATE PROCEDURE [sb].[ConversationManagement_End]
        @FunctionName VARCHAR(100) = 'TOControl'
    ,    @ContractName VARCHAR(200) = ''
AS
/*
    Create By: Don
    Created Date: 2017-03-22
    Task: Apply Service Broker for Turnover Control function
    DB: DBAGE.bodb02
    
    Para's explaination
*/
BEGIN
    SET NOCOUNT ON 

    DECLARE @Conversation_tmp AS TABLE (ID INT IDENTITY(1,1), handle UNIQUEIDENTIFIER)    
    DECLARE @max_conversation INT, @min_Conversation INT = 1, @cnt INT, @handle UNIQUEIDENTIFIER
    
    SELECT @cnt = Cnt
    FROM sb.ConversationCount WITH (NOLOCK)
    WHERE FunctionName = @functionName AND ContractName = @ContractName
    
    INSERT INTO @Conversation_tmp (handle)
    SELECT ConversationHandle
    FROM sb.ConversationManagement WITH (NOLOCK)
    WHERE FunctionName = @functionName AND ContractName = @ContractName AND ConversationNo > @cnt 
    
    IF EXISTS (SELECT 1 FROM @Conversation_tmp)
    BEGIN
        SET @max_conversation = (SELECT MAX(ID) FROM @Conversation_tmp)
        WHILE @min_Conversation <= @max_conversation
        BEGIN
            SELECT @handle = handle
            FROM @Conversation_tmp
            WHERE ID = @min_Conversation
            
            BEGIN TRY
                END CONVERSATION @handle
            END TRY
            
            BEGIN CATCH
                PRINT ' Invalid Handle'
            END CATCH
            SET @min_Conversation = @min_Conversation + 1
        END
        
        DELETE FROM sb.ConversationManagement WITH(ROWLOCK)
        WHERE FunctionName = @functionName
              AND ContractName = @ContractName
              AND ConversationNo > @cnt 
    END    
    
END

GO


CREATE PROCEDURE [sb].[ConversationManagement_Ins]
        @FunctionName VARCHAR(100)
    ,    @ContractName VARCHAR(100)  
    ,    @FromService VARCHAR(100)
    ,    @ToService VARCHAR(100)
    ,    @NewCnt INT  
AS
/*
    Create By: Don
    Created Date: 2017-03-22
    Task: Apply Service Broker for Turnover Control function
    DB: DBAGE.bodb02
    
    Para's explaination
    
        - @NewCnt: expected conversation for this contract
*/
BEGIN 
    SET NOCOUNT ON 
    
    DECLARE @Cnt INT
          , @i INT
          , @handle UNIQUEIDENTIFIER
          , @ConversationNo INT
          , @SendSequence BIGINT
          , @CurrentSendSequence BIGINT          
          , @CurrentDate DATETIME          
          , @MaxID INT              
    DECLARE @ErrorMessage NVARCHAR(4000) 
          , @ErrorSeverity INT
          , @ErrorState INT          
    DECLARE @t TABLE(ID BIGINT IDENTITY(1, 1), Handle UNIQUEIDENTIFIER, ConversationNo INT, SendSequence BIGINT)
    
    SELECT @ErrorSeverity = 10, @ErrorState = 1                             
              
    SET @Cnt = (SELECT Cnt
                FROM sb.ConversationCount WITH (NOLOCK)
                WHERE FunctionName = @functionName
                        AND ContractName = @contractName)
    
    IF @Cnt IS NULL 
    BEGIN
        INSERT INTO sb.ConversationCount (functionName,ContractName,Cnt) 
        VALUES (@functionName,@contractName,0)
    END        
    
    SET @Cnt = ISNULL(@Cnt,0)
    SET @CurrentDate =  GETDATE()        
        
    SET @ErrorMessage = '=============================================== Begin increase process ==============================================='
    RAISERROR (@ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
              )
              
    SET @i = @Cnt + 1
            
    WHILE @i <= @newCnt
    BEGIN
        BEGIN DIALOG CONVERSATION @handle
        FROM SERVICE  @fromService 
        TO SERVICE  @toService 
        on contract @contractName 
        WITH ENCRYPTION = OFF                                
        
        INSERT INTO sb.ConversationManagement(FunctionName, ContractName, ConversationNo, ConversationHandle,CreatedDate,IsValid)
        VALUES(@functionName, @contractName, @i, @handle,@CurrentDate,1)
        
        SET @ErrorMessage = 'Begin conversation ' + CAST(@handle AS VARCHAR(200)) + ' successfully'
        RAISERROR (@ErrorMessage, -- Message text.  
                   @ErrorSeverity, -- Severity.  
                   @ErrorState -- State.  
                  )
        
        SET @i = @i + 1                    
    END
    
    UPDATE sb.ConversationCount WITH (ROWLOCK)
        SET Cnt = @newCnt
    WHERE FunctionName = @functionName
      AND ContractName = @contractName
    
    SET @ErrorMessage = '=============================================== End increase process ==============================================='
    RAISERROR (@ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
              )
    
END

GO
CREATE PROCEDURE [sb].[ConversationManagement_Upd]
( 
        @FunctionName VARCHAR(100) 
    ,    @ContractName VARCHAR(100) = NULL  
    ,    @FromService VARCHAR(100)
    ,    @ToService VARCHAR(100)
    ,    @NewCnt INT   
)
AS
/*
    Create By: Don
    Created Date: 2017-03-22
    Task: Apply Service Broker for Turnover Control function
    DB: DBAGE.bodb02
    
    Para's explaination
*/
BEGIN 
    SET NOCOUNT ON 
    
    DECLARE @Cnt INT
          , @i BIGINT          
          , @MinConversation INT
          , @MaxConversation INT
          , @Count BIGINT
          , @IsError BIT
          
    DECLARE @ErrorMessage NVARCHAR(4000) 
          , @ErrorSeverity INT = 10 -- Information No
          , @ErrorState INT = 1
    DECLARE @t TABLE(ID BIGINT IDENTITY(1, 1), ContractName VARCHAR(100))
    
    IF @contractName IS NOT NULL
        INSERT INTO @t(ContractName) VALUES(@contractName)
    ELSE -- FOR ALL CONTRACTS PROCESS
    BEGIN
        INSERT INTO @t(ContractName) 
        SELECT ContractName
        FROM sb.ConfigurationReferenceDetail WITH (NOLOCK)
        WHERE FunctionName = @functionName
    END            
            
    SET @Count = @@ROWCOUNT        
    
    SET @IsError = 0
    SET @i = 1    
    WHILE @i <= @Count
    BEGIN    
        SELECT @contractName = ContractName
        FROM @t
        WHERE ID = @i
      
        SELECT @MinConversation = MinConversation
             , @MaxConversation = MaxConversation
        FROM sb.ConfigurationReferenceDetail WITH (NOLOCK)
        WHERE FunctionName = @functionName
          AND ContractName = @contractName
          
        IF @newCnt NOT BETWEEN @MinConversation AND @MaxConversation
        BEGIN
            SET @ErrorMessage = 'Contract name ' + @contractName + ' : @newCnt must be between ' + CAST(@MinConversation AS VARCHAR(100)) + ' and ' + CAST(@MaxConversation AS VARCHAR(100))
            RAISERROR (@ErrorMessage, -- Message text.  
                       @ErrorSeverity, -- Severity.  
                       @ErrorState -- State.  
                      );
            SET @IsError = 1                  
        END
        
        SET @i = @i + 1
    END    
    
    IF @IsError = 1
        RETURN                    
    
    SET @i = 1    
    WHILE @i <= @Count
    BEGIN    
        SELECT @contractName = ContractName
        FROM @t
        WHERE ID = @i
        
        SET @Cnt = NULL
        SET @Cnt = (SELECT Cnt
                    FROM sb.ConversationCount WITH (NOLOCK)
                    WHERE FunctionName = @functionName
                      AND ContractName = @contractName)
        SET @Cnt = ISNULL(@Cnt, 0)                              
        
        IF @Cnt <> @newCnt
        BEGIN              
            IF @Cnt < @newCnt -- Open new conversations for specific contract
                EXEC [sb].[ConversationManagement_Ins]
                        @functionName = @functionName
                      , @contractName = @contractName  
                      , @fromService = @fromService
                      , @toService = @toService
                      , @newCnt = @newCnt
            ELSE -- Close existing conversations for specific contract
                EXEC [sb].[ConversationManagement_Del]
                        @functionName = @functionName
                      , @contractName = @contractName    
                      , @newCnt = @newCnt             
        END
        
        SET @i = @i + 1
    END        
          
    -- warning all contracts without conversation if any for DBA to have more info
    SELECT cfd.ContractName AS ContractWithoutConversation
    FROM sb.ConfigurationReferenceDetail cfd WITH (NOLOCK)
         LEFT JOIN sb.ConversationCount cc WITH (NOLOCK)
                ON cfd.FunctionName = cc.FunctionName
                   AND cfd.ContractName = cc.ContractName
    WHERE cfd.FunctionName = @functionName 
      AND ISNULL(cc.Cnt, 0) = 0
    
END

GO
CREATE PROCEDURE [sb].[ConversationPick]
( 
		@FunctionName VARCHAR(100)
	,	@ContractName VARCHAR(200)
	,	@Handle UNIQUEIDENTIFIER OUT
)
AS
/*
	Create By: Don
	Created Date: 2017-03-22
	Task: Apply Service Broker for Turnover Control function
	DB: DBAGE.bodb02 
	
	Revision
		- 20180626@Helen: Tuning trigger - [Redmine:97313]
	Para's explaination
*/
BEGIN 
	
	SET NOCOUNT ON 
	DECLARE @ConversationNo INT
			, @Cnt INT
			  
	SELECT @Cnt = Cnt
	FROM sb.ConversationCount WITH (NOLOCK)
	WHERE FunctionName = @functionName AND contractName = @ContractName
	
	SET @Cnt = ISNULL(@Cnt, 0) 
	
	IF @Cnt = 0
	BEGIN
		SET @handle = NULL
		RETURN
	END
	
	SET @ConversationNo = RAND() * @Cnt + 1
	
	IF @ConversationNo > @Cnt 
		SET @ConversationNo = @Cnt
		
	SELECT @handle = ConversationHandle
	FROM sb.ConversationManagement WITH (NOLOCK)
	WHERE FunctionName = @functionName
			AND contractName = @ContractName
			AND ConversationNo = @ConversationNo 
			AND IsValid = 1  

END

GO
CREATE PROCEDURE [sb].[MsgSent]
(
        @Xml XML
    ,    @Handle UNIQUEIDENTIFIER
    ,    @MessageType VARCHAR(200)
    ,    @ErrorCode INT = 0 OUT
    ,    @ErrorMessage VARCHAR(MAX) = '' OUT
)
AS
/*
    Create By: Don
    Created Date: 2017-03-22
    Task: Apply Service Broker for Turnover Control function
    DB: DBAGE.bodb02 
    
    Revision

    Para's explaination
*/

BEGIN
    
    SET NOCOUNT ON

    DECLARE @sql_string NVARCHAR(MAX) = ''
    SET @sql_string='SEND ON CONVERSATION @handle
                     MESSAGE TYPE ' + @MessageType + '(@xml)'
    BEGIN TRY
        EXEC SP_EXECUTESQL @sql_string,N'@handle uniqueidentifier, @xml xml', @Handle, @Xml
        --PRINT @sql_string
    END TRY
    
    BEGIN CATCH
        SET @ErrorCode = ERROR_NUMBER()
        SET @ErrorMessage = ERROR_MESSAGE()
    END CATCH
    
END

GO