/*
	Creator:	20180529@Billy
	Task:		Database schema of bodb_playtechCS_archive - [Redmine: #96050]
	Server:		DB06
*/


USE master;
GO
CREATE DATABASE bodb_playtechCS_archive
	ON PRIMARY (
		NAME = N'PTCS_Archive'
	,	FILENAME = N'\bodb_PlaytechCS_archive\ptcs_archive_data.mdf'
	,	SIZE = 3072KB
	,	MAXSIZE = UNLIMITED
	,	FILEGROWTH = 32768KB
	)
	,	FILEGROUP PlaytechCS_Archive_Data (
		NAME = N'PlaytechCS_Archive_Data_01'
	,	FILENAME = N'\bodb_PlaytechCS_archive\PlaytechCS_Archive_Data_01.ndf'
	,	SIZE = 2048KB
	,	MAXSIZE = UNLIMITED
	,	FILEGROWTH = 32768KB
	)
	,	FILEGROUP PlaytechCS_Archive_Index (
		NAME = N'PlaytechCS_Archive_Index_01'
	,	FILENAME = N'\bodb_PlaytechCS_archive\PlaytechCS_Archive_Index_01.ndf'
	,	SIZE = 2048KB
	,	MAXSIZE = UNLIMITED
	,	FILEGROWTH = 32768KB
	)
	,	FILEGROUP PlaytechCS_Archive_Table (
		NAME = N'PlaytechCS_Archive_Table_01'
	,	FILENAME = N'\bodb_PlaytechCS_archive\PlaytechCS_Archive_Table_01.ndf'
	,	SIZE = 2048KB
	,	MAXSIZE = UNLIMITED
	,	FILEGROWTH = 32768KB
	)
	LOG ON (
		NAME = N'PTCS_Archive_log'
	,	FILENAME = N'\bodb_PlaytechCS_archive\ptcs_archive_log.ldf'
	,	SIZE = 2048KB
	,	MAXSIZE = 2048GB
	,	FILEGROWTH = 32768KB
	);
GO
ALTER DATABASE bodb_playtechCS_archive SET COMPATIBILITY_LEVEL = 100;
GO
IF	(1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
BEGIN
	EXEC bodb_playtechCS_archive.dbo.sp_fulltext_database @action = 'enable';
END;
GO
ALTER DATABASE bodb_playtechCS_archive SET ANSI_NULL_DEFAULT OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET ANSI_NULLS OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET ANSI_PADDING OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET ANSI_WARNINGS OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET ARITHABORT OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET AUTO_CLOSE OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET AUTO_CREATE_STATISTICS ON;
GO
ALTER DATABASE bodb_playtechCS_archive SET AUTO_SHRINK OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET AUTO_UPDATE_STATISTICS ON;
GO
ALTER DATABASE bodb_playtechCS_archive SET CURSOR_CLOSE_ON_COMMIT OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET CURSOR_DEFAULT GLOBAL;
GO
ALTER DATABASE bodb_playtechCS_archive SET CONCAT_NULL_YIELDS_NULL OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET NUMERIC_ROUNDABORT OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET QUOTED_IDENTIFIER OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET RECURSIVE_TRIGGERS OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET DISABLE_BROKER;
GO
ALTER DATABASE bodb_playtechCS_archive SET AUTO_UPDATE_STATISTICS_ASYNC OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET DATE_CORRELATION_OPTIMIZATION OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET TRUSTWORTHY OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET ALLOW_SNAPSHOT_ISOLATION OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET PARAMETERIZATION SIMPLE;
GO
ALTER DATABASE bodb_playtechCS_archive SET READ_COMMITTED_SNAPSHOT OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET HONOR_BROKER_PRIORITY OFF;
GO
ALTER DATABASE bodb_playtechCS_archive SET RECOVERY SIMPLE;
GO
ALTER DATABASE bodb_playtechCS_archive SET MULTI_USER;
GO
ALTER DATABASE bodb_playtechCS_archive SET PAGE_VERIFY CHECKSUM;
GO
ALTER DATABASE bodb_playtechCS_archive SET DB_CHAINING OFF;
GO
EXEC sys.sp_db_vardecimal_storage_format N'bodb_playtechCS_archive', N'ON';
GO
USE bodb_playtechCS_archive;
GO
CREATE USER vnteam FOR LOGIN vnteam WITH DEFAULT_SCHEMA = dbo;
GO
CREATE USER vnDBA FOR LOGIN vnDBA WITH DEFAULT_SCHEMA = dbo;
GO
CREATE USER SqlLink FOR LOGIN SqlLink WITH DEFAULT_SCHEMA = dbo;
GO
ALTER ROLE db_owner ADD MEMBER vnDBA;
GO
ALTER ROLE db_owner ADD MEMBER SqlLink;
GO
GRANT CONNECT TO SqlLink AS dbo;
GO
GRANT CONNECT TO vnDBA AS dbo;
GO
GRANT CONNECT TO vnteam AS dbo;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE	TABLE dbo.bettrans_PlaytechCS_bk (
	TicketID				BIGINT			NOT NULL
,	CustID					INT				NULL
,	Transdate				DATETIME		NULL
,	SessionID				BIGINT			NULL
,	GameID					INT				NULL
,	Windowcode				INT				NULL
,	GameName				VARCHAR(50)		NULL
,	Stake					MONEY			NULL
,	Actual_Stake			MONEY			NULL
,	Winlost					MONEY			NULL
,	Status					NVARCHAR(10)	NULL
,	StatusID				INT				NULL
,	Username				VARCHAR(50)		NULL
,	Winlostdate				DATETIME		NULL
,	PlaytechChagrePercent	DECIMAL(6, 3)	NULL
,	PlaytechChargeAmount	MONEY			NULL
,	PlaytechBalance			MONEY			NULL
,	BrokenGameBet			MONEY			NULL
,	LiveNetwork				VARCHAR(50)		NULL
,	recommend				INT				NULL
,	mrecommend				INT				NULL
,	srecommend				INT				NULL
,	currency				TINYINT			NULL
,	CONSTRAINT pk_TicketID
		PRIMARY KEY CLUSTERED (TicketID ASC)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON
		,	ALLOW_PAGE_LOCKS = ON
		) ON PlaytechCS_Archive_Data
) ON PlaytechCS_Archive_Data;

GO
GRANT SELECT ON dbo.bettrans_PlaytechCS_bk TO vnteam AS dbo;
GO
USE master;
GO
ALTER DATABASE bodb_playtechCS_archive SET READ_WRITE;
GO
