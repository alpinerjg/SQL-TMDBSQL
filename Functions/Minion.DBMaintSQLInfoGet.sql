SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [Minion].[DBMaintSQLInfoGet]()
RETURNS @Info TABLE 
(
VersionRaw VARCHAR(50),
Version DECIMAL(3,1),
Edition VARCHAR(15),
OnlineEdition BIT,
Instance VARCHAR(400),
InstanceName VARCHAR(200),
ServerAndInstance VARCHAR(400)
)
AS

BEGIN

---------------------------------------------------------------------------------
------------------ BEGIN Get Version Info----------------------------------------
---------------------------------------------------------------------------------
DECLARE 
		@VersionRaw VARCHAR(50),
		@Version DECIMAL(3,1),
		@Edition VARCHAR(15),
		@ServerAndInstance VARCHAR(400);
																	          
	SELECT	@VersionRaw = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(15)), 4);

	SET @Version = @VersionRaw;
	SELECT	@Edition = CAST(SERVERPROPERTY('Edition') AS VARCHAR(25));

	DECLARE	@OnlineEdition BIT
	IF @Edition LIKE '%Enterprise%'
		OR @Edition LIKE '%Developer%' 
		BEGIN
			SET @OnlineEdition = 1
		END
	
	IF @Edition NOT LIKE '%Enterprise%'
		AND @Edition NOT LIKE '%Developer%' 
		BEGIN
			SET @OnlineEdition = 0
		END	

DECLARE @Instance NVARCHAR(128);
SET @Instance = (SELECT CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)));

DECLARE @InstanceName NVARCHAR(128);
SET @InstanceName = (SELECT CAST(SERVERPROPERTY('InstanceName') AS NVARCHAR(128)));

IF @InstanceName IS NOT NULL
BEGIN
	SET @ServerAndInstance = @Instance
END
IF @InstanceName IS NULL
BEGIN
	SET @InstanceName = 'Default'
	SET @ServerAndInstance = @Instance + '\' + @InstanceName
END

-------------BEGIN 2016 update------------
IF @Version >= 13.0
	BEGIN
		DECLARE @MinorVersion INT;
		SET @MinorVersion = CAST(SERVERPROPERTY('ProductBuild') AS INT);
		IF @MinorVersion >= 4001
			BEGIN
				SET @OnlineEdition = 1;
			END
		IF @MinorVersion < 4001 AND @Edition NOT LIKE 'Enterprise%'
			BEGIN
				SET @OnlineEdition = 0;
			END
		
	END
-------------END 2016 update--------------

-------------BEGIN Future update--------------
---- If ever SQL allows online operations in all editions....
--IF (	@Version >= 14.0
--		AND CAST(SERVERPROPERTY('ProductBuild') AS VARCHAR(15)) >= 4001 )
--	OR @Version > 14.0
--BEGIN
--    SET @OnlineEdition = 1;
--END;
-------------END Future update--------------

INSERT @Info
        (VersionRaw, Version, Edition, OnlineEdition, Instance, InstanceName, ServerAndInstance)
SELECT @VersionRaw, @Version, @Edition, @OnlineEdition, @Instance, @InstanceName, @ServerAndInstance
RETURN
---------------------------------------------------------------------------------
------------------ END Get Version Info------------------------------------------
---------------------------------------------------------------------------------
END


GO
