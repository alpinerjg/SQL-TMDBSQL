SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [Minion].[SyncPush]
(

@Tables VARCHAR(50), -- Valid values: Settings|Logs|All. If you pass in NULL then all tables will be processed.
@SyncServerName VARCHAR(140) = NULL, --This is the name of the new server you want to push the data to.
@SyncDBName VARCHAR(140) = NULL, -- This is the name of the DB on the new server that holds the Minion tables.
@Port VARCHAR(10) = NULL, -- The port to be used for the connection to the new SQL box.
@Process VARCHAR(10) = 'New', -- Valid values: All|New.  This means which records to you want to process?  Just the new ones, or all of them?  All is used for bringing on new servers when you want to push all the records in the table to that server.
@Module VARCHAR(20) = 'Backup'
)

AS

SET NOCOUNT ON;

DECLARE 
@SyncSettings VARCHAR(10),
@SyncLogs VARCHAR(10),
@ServerList VARCHAR(2000),
@ServerListString VARCHAR(100),
@currSyncServerName sysname,
@currSyncDBName sysname,
@currPort VARCHAR(10),
@currConnTimeout INT,
@PreCMD VARCHAR(1000),
@InsertCMD VARCHAR(4000),
@TotalCMD VARCHAR(8000),
@currCmd VARCHAR(8000),
@currID INT,
@Error VARCHAR(2000),
@ConnTimeout INT;


CREATE TABLE #Servers
(
ID INT IDENTITY(1,1),
SyncServerName VARCHAR(100),
SyncDBName sysname,
Port INT,
ConnectionTimeoutInSecs INT
)

CREATE TABLE #Cmds
(
ID INT,
Cmd NVARCHAR(MAX)
)


CREATE TABLE #CmdSyncT
(
	ID INT IDENTITY(1, 1) ,
	col1 VARCHAR(MAX)
)

DECLARE @FailoverServersTable TABLE (ServerName VARCHAR(100));
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
------------------BEGIN Servers Cursor----------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
----This is mostly an automated process, but it can be run manually to bring a new server online,
----or to repair an existing server.  This section will run the process based off of the config table if you didn't pass in any values.
----If you did pass in values, then this entire section is skipped and the values passed in are used.

	IF @SyncServerName IS NULL 
		BEGIN --@SyncServerName IS NULL
			INSERT	#Servers
					( SyncServerName ,
					  SyncDBName ,
					  Port,
					  ConnectionTimeoutInSecs
					)
					SELECT	SyncServerName ,
							SyncDBName ,
							Port,
							ConnectionTimeoutInSecs
					FROM	Minion.SyncServer
					WHERE	SyncServerName NOT IN ( 'AGReplica',
													'MirrorPartner',
													'LogShippingPartner' )
							AND SyncServerName NOT LIKE ( '%|%' )
							AND (Module = 'Backup'
							OR Module = 'All');

		----------------BEGIN Load Replica Servers------------------
			SELECT	
					@SyncServerName = SyncServerName ,
					@SyncDBName = SyncDBName ,
					@Port = Port,
					@ConnTimeout = ConnectionTimeoutInSecs
			FROM	Minion.SyncServer
			WHERE	SyncServerName = 'AGReplica'
					AND (Module = 'Backup'
					OR Module = 'All');

			IF @SyncServerName IS NOT NULL 
				BEGIN
					INSERT	#Servers
							SELECT DISTINCT
									replica_server_name,
									@SyncDBName,
									@Port,
									@ConnTimeout
							FROM	sys.availability_replicas;
				END

		----------------END Load Replica Servers--------------------

		----------------BEGIN Load Mirror Servers------------------
			SELECT	@SyncServerName = SyncServerName ,
					@SyncDBName = SyncDBName ,
					@Port = Port, 
					@ConnTimeout = ConnectionTimeoutInSecs
			FROM	Minion.SyncServer
			WHERE	SyncServerName = 'MirrorPartner'
					AND Module = 'Backup'
					OR Module = 'All';

			IF @SyncServerName IS NOT NULL 
				BEGIN
					INSERT	#Servers
							SELECT DISTINCT
									mirroring_partner_instance,
									@SyncDBName,
									@Port,
									@ConnTimeout
							FROM	sys.database_mirroring;
				END
		----------------END Load Mirror Servers--------------------


		----------------BEGIN Load Log Shipping Servers------------------

			SELECT
					@SyncServerName = SyncServerName ,
					@SyncDBName = SyncDBName ,
					@Port = Port,
					@ConnTimeout = ConnectionTimeoutInSecs
			FROM	Minion.SyncServer
			WHERE	SyncServerName = 'LogShippingPartner'
					AND (Module = 'Backup'
					OR Module = 'All')

			IF @SyncServerName IS NOT NULL 
				BEGIN
					INSERT	#Servers
							SELECT DISTINCT
									secondary_server ,
									@SyncDBName ,
									@Port,
									@ConnTimeout
							FROM	msdb..log_shipping_primary_secondaries;
				END
		----------------END Load Log Shipping Servers--------------------


		----------------BEGIN Sync Partners---------------------------
		---Here we have a special situation where a set of servers isn't in an AG, or mirror, or LS, but you want them to stay in sync
		---anyway.  So you put them in the same column separated by "|".  This way you can sync as many servers as you like.
		---The important thing here is that the current server is removed from the sync list because you're already here.
		---And you want to be able to fail it over to the other box if you want and have it sync the settings to all the other servers.
		---So basically you want to have Minion discover which server you're on and sync the logs to the others.  And if you change
		---servers, then it'll detect that one too and sync the settings to the other servers.

			SELECT	
					@ServerList = SyncServerName ,
					@SyncDBName = SyncDBName ,
					@Port = Port,
					@ConnTimeout = ConnectionTimeoutInSecs
			FROM	Minion.SyncServer
			WHERE	SyncServerName LIKE '%|%'
					AND Module = 'Backup';

			BEGIN 
			
				WHILE LEN(@ServerList) > 0 
					BEGIN
						SET @ServerListString = LEFT(@ServerList,
													 ISNULL(NULLIF(CHARINDEX('|',
															  @ServerList) - 1,
															  -1),
															LEN(@ServerList)))
						SET @ServerList = SUBSTRING(@ServerList,
													ISNULL(NULLIF(CHARINDEX('|',
															  @ServerList), 0),
														   LEN(@ServerList))
													+ 1, LEN(@ServerList))

						INSERT	#Servers
								( SyncServerName ,
								  SyncDBName ,
								  Port,
								  ConnectionTimeoutInSecs
								)
						VALUES	( @ServerListString ,
								  @SyncDBName ,
								  @Port,
								  @ConnTimeout
								)
					END 
			END
		--SELECT 'SyncPartners' AS SyncPartners, * FROM @FailoverServersTable				 
		----------------END Sync Partners-----------------------------


		----------BEGIN Delete Current Server-------------
			---We're not going to ship the settings to the current server cause we're already here.
			---So delete it from the list.
			DELETE	#Servers
			WHERE	SyncServerName = @@ServerName;

			---Now Delete any NULL Servers
			DELETE #Servers
			WHERE SyncServerName IS NULL;
		----------END Delete Current Server---------------

		END --@SyncServerName IS NULL

	IF @SyncServerName IS NOT NULL AND (@SyncServerName <> 'AGReplica' AND @SyncServerName <> 'LogShippingPartner' AND @SyncServerName <> 'MirrorPartner')
		BEGIN
			INSERT	#Servers
					( SyncServerName ,
					  SyncDBName ,
					  Port
					)
					SELECT	@SyncServerName ,
							@SyncDBName ,
							@Port
		END

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------END Servers Cursor------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------BEGIN Get Cmds----------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

IF @Process = 'New'
BEGIN --@Process = 'New'

	IF @Tables = 'Logs'
		BEGIN --@Tables = 'Logs'
			INSERT #Cmds (ID, Cmd)
			SELECT ID, Cmd 
			FROM Minion.SyncCmds
			WHERE --ExecutionDateTime = @ExecutionDateTime
				  ObjectName IN ('BackupLog', 'BackupLogDetails', 'BackupFiles', 'BackupFileListOnly')
				  AND Pushed = 0
				  AND Module = 'Backup'
				  ORDER BY ID ASC;
		END --@Tables = 'Logs'

	IF @Tables = 'All'
		BEGIN --@Tables IS NULL
			INSERT #Cmds (ID, Cmd)
			SELECT ID, Cmd 
			FROM Minion.SyncCmds
			WHERE
				  Pushed = 0
				  AND Module = 'Backup'
				  ORDER BY ID ASC;
		END --@Tables IS NULL

	IF @Tables = 'Settings'
		BEGIN --@Tables = 'Settings'
			INSERT #Cmds (ID, Cmd)
			SELECT ID, Cmd 
			FROM Minion.SyncCmds
			WHERE --ExecutionDateTime = @ExecutionDateTime
				  ObjectName IN ('BackupSettings', 'BackupSettingsPath', 'BackupSettingsServer', 'SyncServer', 'BackupTuningThresholds', 'DBMaintRegexLookup', 'BackupEncryption', 'BackupCert')
				  AND Pushed = 0
				  AND Module = 'Backup'
				  ORDER BY ID ASC;
		END --@Tables = 'Settings'

END --@Process = 'New'

IF @Process = 'All'
BEGIN --@Process = 'New'

	IF @Tables = 'Logs'
		BEGIN --@Tables = 'Logs'
			INSERT #Cmds (ID, Cmd)
			SELECT ID, Cmd 
			FROM Minion.SyncCmds
			WHERE 
				  ObjectName IN ('BackupLog', 'BackupLogDetails', 'BackupFiles', 'BackupFileListOnly')
				  AND Module = 'Backup'
				  ORDER BY ID ASC;
		END --@Tables = 'Logs'

	IF @Tables = 'All'
		BEGIN --@Tables IS NULL
			INSERT #Cmds (ID, Cmd)
			SELECT ID, Cmd 
			FROM Minion.SyncCmds
			WHERE Module = 'Backup'
				  ORDER BY ID ASC;
		END --@Tables IS NULL

	IF @Tables = 'Settings'
		BEGIN --@Tables = 'Settings'
			INSERT #Cmds (ID, Cmd)
			SELECT ID, Cmd 
			FROM Minion.SyncCmds
			WHERE
				  ObjectName IN ('BackupSettings', 'BackupSettingsPath', 'BackupSettingsServer', 'SyncServer', 'BackupTuningThresholds', 'DBMaintRegexLookup', 'BackupEncryption', 'BackupCert')
				  AND Module = 'Backup'
				  ORDER BY ID ASC;
		END --@Tables = 'Settings'

END --@Process = 'New'

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------END Get Cmds------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------BEGIN Reprocess Errored Cmds--------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

CREATE TABLE #ErroredCmds
(
ID INT IDENTITY(1,1),
SyncErrorID BIGINT, --ID from the SyncErrorCmds table.
SyncServerName VARCHAR(140),
SyncDBName VARCHAR(140),
Port VARCHAR(10),
SyncCmdID BIGINT,
SyncCmd VARCHAR(MAX)
)

CREATE TABLE #ReproCmdResults
(ID INT IDENTITY(1,1),
 col1 VARCHAR(MAX)
)

INSERT #ErroredCmds (SyncServerName, SyncErrorID, SyncDBName, Port, SyncCmdID, SyncCmd)
SELECT sec.SyncServerName,
	   sec.ID,
	   sec.SyncDBName,
	   sec.Port,
	   sec.SyncCmdID,
	   sc.Cmd
FROM Minion.SyncErrorCmds sec
INNER JOIN Minion.SyncCmds sc
ON sec.SyncCmdID = sc.ID
WHERE sc.Module = @Module
ORDER BY sc.ID
--SELECT * FROM #ErroredCmds

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
----------------------------BEGIN Test Conn--------------------------------------------
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
------If the errored boxes are still down, then each row will have to timeout.
------This can take a long time to get through all the rows as each one has to timeout.
------So instead, we'll check whether the box is alive first, and if not, then we'll remove 
------its rows here so they won't be processed.  This way we've only got 1 timeout to worry about.
DECLARE @currErrorServerName varchar(150),
		@currErrorDBName varchar(200),
		@currErrorPort varchar(10),
		@SQL nvarchar(200),
		@ErrorReproPreCMD varchar(1000),
		@ErrorTotalReproCMD varchar(4000),
		@ErrorReproCmd varchar(100),
		@ErrorReproError varchar(max);

CREATE TABLE #ErrorReproCmdResults (ID int identity(1,1), col1 varchar(max));

DECLARE TestConn CURSOR
READ_ONLY
FOR SELECT DISTINCT SyncServerName, SyncDBName, Port from #ErroredCmds

OPEN TestConn

	FETCH NEXT FROM TestConn INTO @currErrorServerName, @currErrorDBName, @currErrorPort
	WHILE (@@fetch_status <> -1)
	BEGIN


		 IF @currErrorServerName NOT LIKE '%\%'
			BEGIN
				SET @currErrorPort = CASE WHEN @currErrorPort IS NULL THEN '' --',' + '1433'
								 WHEN @currErrorPort = '1433' THEN '' --',' + '1433'
								 WHEN @currErrorPort IS NOT NULL THEN ',' + @currErrorPort
								 END
			END
	IF @currErrorServerName LIKE '%\%'
		BEGIN
				SET @currErrorPort = CASE WHEN @currErrorPort IS NULL THEN ''
								 WHEN @currErrorPort IS NOT NULL THEN ',' + @currErrorPort
								 END
		END


		SET @ErrorReproCmd = 'SELECT 1';
		SET @ErrorReproPreCMD = 'sqlcmd -S "' + ISNULL(@currErrorServerName, '') + ISNULL(CAST(@currErrorPort AS VARCHAR(10)), '') + '" -d "' + ISNULL(@currErrorDBName, '1433') + '"'	
		SET @ErrorTotalReproCMD = @ErrorReproPreCMD + ' -q "' + @ErrorReproCmd +  '"'
SELECT @ErrorTotalReproCMD AS HERE2
		INSERT #ErrorReproCmdResults (col1)
		EXEC xp_cmdshell @ErrorTotalReproCMD;

		DELETE FROM #ErrorReproCmdResults
		WHERE col1 IS NULL;

        SELECT
                @ErrorReproError = STUFF((SELECT ' ' + col1
                                        FROM #ErrorReproCmdResults AS T1
                                        ORDER BY T1.ID
                                    FOR XML PATH('')
                                    ), 1, 1, '')
            FROM
                #ErrorReproCmdResults AS T2;

		-----------BEGIN Log Error-----------
		IF (@ErrorReproError NOT LIKE '%1 rows affected%')	
		BEGIN
		--There's no need to re-write the record, just update it for the next try.
		--We want to give plenty of chances to see what the problem is if it keeps erroring.
		DELETE #ErroredCmds
		WHERE SyncServerName = @currErrorServerName;
		
		UPDATE Minion.SyncErrorCmds
		SET STATUS = @ErrorReproError,
			LastAttemptDateTime = GETDATE()
		WHERE SyncServerName = @currErrorServerName;

		END	
		-----------END Log Error-------------
		TRUNCATE TABLE #ErrorReproCmdResults;	
			
	FETCH NEXT FROM TestConn INTO @currErrorServerName, @currErrorDBName, @currErrorPort
	END

CLOSE TestConn
DEALLOCATE TestConn
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
----------------------------END Test Conn----------------------------------------------
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------


DECLARE @CT INT,
		@i  INT,
		@ReproID INT,
		@ReproSyncServerName VARCHAR(140),
		@ReproSyncDBName VARCHAR(140),
		@ReproPort VARCHAR(10),
		@ReproSyncCmdID BIGINT,
		@ReproCmd VARCHAR(4000),
		@TotalReproCMD VARCHAR(8000),
		@ReproPreCMD VARCHAR(1000),
		@ReproError VARCHAR(MAX),
		@SyncErrorID bigint;
SET @CT = (SELECT COUNT(*) FROM #ErroredCmds);
SET @i = 1;
WHILE @i <= @CT
	BEGIN

	SELECT 
		@ReproID = ID,
		@SyncErrorID = SyncErrorID,
		@ReproSyncServerName = SyncServerName,
	    @ReproSyncDBName = SyncDBName,
	    @ReproPort = Port,
	    @ReproSyncCmdID = SyncCmdID,
	    @ReproCmd = SyncCmd
		FROM #ErroredCmds
		WHERE ID = @i


		 IF @ReproSyncServerName NOT LIKE '%\%'
			BEGIN
				SET @ReproPort = CASE WHEN @ReproPort IS NULL THEN '' --',' + '1433'
								 WHEN @ReproPort = '1433' THEN '' --',' + '1433'
								 WHEN @ReproPort IS NOT NULL THEN ',' + @currErrorPort
								 END
			END
	IF @ReproSyncServerName LIKE '%\%'
		BEGIN
				SET @ReproPort = CASE WHEN @ReproPort IS NULL THEN ''
								 WHEN @ReproPort IS NOT NULL THEN ',' + @ReproPort
								 END
		END

	SET @ReproPreCMD = 'sqlcmd -S "' + ISNULL(@ReproSyncServerName, '') + ISNULL(CAST(@ReproPort AS VARCHAR(6)), '') + '" -d "' + ISNULL(@ReproSyncDBName, '1433') + '"'	

	IF @ConnTimeout IS NOT NULL
		BEGIN
			SET @ReproPreCMD = @ReproPreCMD + ' -l ' + CAST(@ConnTimeout AS VARCHAR(6))
		END
			
	SET @TotalReproCMD = @ReproPreCMD + ' -q "' + @ReproCmd +  '"'
SELECT @TotalReproCMD AS HERE3
		INSERT #ReproCmdResults (col1)
		EXEC xp_cmdshell @TotalReproCMD;	

		DELETE FROM #ReproCmdResults
		WHERE col1 IS NULL;

        SELECT
                @ReproError = STUFF((SELECT ' ' + col1
                                        FROM #ReproCmdResults AS T1
                                        ORDER BY T1.ID
                                    FOR XML PATH('')
                                    ), 1, 1, '')
            FROM
                #ReproCmdResults AS T2;

		TRUNCATE TABLE #ReproCmdResults;
-------------------------------------------------------------------
--------------------BEGIN Process Error----------------------------
-------------------------------------------------------------------
		-----------BEGIN Log Error-----------
		IF (@ReproError NOT LIKE '%1 rows affected%' AND @ReproError NOT LIKE '%completed successfully%') OR (@ReproCmd LIKE 'TRUNCATE%' AND @ReproError IS NOT NULL)	
		BEGIN
		--There's no need to re-write the record, just update it for the next try.
		--We want to give plenty of chances to see what the problem is if it keeps erroring.
		UPDATE Minion.SyncErrorCmds
		SET STATUS = @ReproError,
			LastAttemptDateTime = GETDATE()
		WHERE ID = @SyncErrorID;

		END	
		-----------END Log Error-------------

-------------------------------------------------------------------
--------------------END Process Error------------------------------
-------------------------------------------------------------------

-------------------------------------------------------------------
--------------------BEGIN Process Success--------------------------
-------------------------------------------------------------------	
	DELETE FROM Minion.SyncErrorCmds 
	WHERE ID = @SyncErrorID

	UPDATE Minion.SyncCmds
	SET ErroredServers = CASE WHEN ErroredServers NOT LIKE @ReproSyncServerName + '|' THEN ISNULL(ErroredServers, '') + @ReproSyncServerName + '|'
							  WHEN ErroredServers LIKE @ReproSyncServerName + '|' THEN ErroredServers
						 END,
		Pushed = 1 --Currently, this sets it even if there are other boxes that still need this row.
	WHERE ID = @ReproSyncCmdID
-------------------------------------------------------------------
--------------------END Process Success----------------------------
-------------------------------------------------------------------	
	SET @i = @i + 1;
END

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------END Reprocess Errored Cmds----------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
----------------------------BEGIN Test Conn--------------------------------------------
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
------If the errored boxes are still down, then each row will have to timeout.
------This can take a long time to get through all the rows as each one has to timeout.
------So instead, we'll check whether the box is alive first, and if not, then we'll remove 
------its rows here so they won't be processed.  This way we've only got 1 timeout to worry about.
------We can't use the results from above because there may not be any errored boxes at all, or there could
------be a new box in the mix.

DECLARE TestConn CURSOR
READ_ONLY
FOR SELECT SyncServerName, SyncDBName, Port, ConnectionTimeoutInSecs
FROM #Servers

OPEN TestConn

	FETCH NEXT FROM TestConn INTO @currSyncServerName, @currSyncDBName, @currPort, @currConnTimeout
	WHILE (@@fetch_status <> -1)
	BEGIN

		 IF @currSyncServerName NOT LIKE '%\%'
			BEGIN
				SET @currPort = CASE WHEN @currPort IS NULL THEN '' --',' + '1433'
								 WHEN @currPort = '1433' THEN '' --',' + '1433'
								 WHEN @currPort IS NOT NULL THEN ',' + @currPort
								 END
			END
	IF @currSyncServerName LIKE '%\%'
		BEGIN
				SET @currPort = CASE WHEN @currPort IS NULL THEN ''
								 WHEN @currPort IS NOT NULL THEN ',' + @currPort
								 END
		END


		SET @PreCMD = 'sqlcmd -S "' + ISNULL(@currSyncServerName, '') + ISNULL(CAST(@currPort AS VARCHAR(6)), '') + '" -d "' + ISNULL(@currSyncDBName, '') + '"'
	
		IF @currConnTimeout IS NOT NULL
			BEGIN
				SET @PreCMD = @PreCMD + ' -l ' + ISNULL(CAST(@currConnTimeout AS VARCHAR(6)), '')
			END

		SET @ReproCmd = 'SELECT 1';	
		SET @TotalReproCMD = @PreCMD + ' -q "' + @ReproCmd +  '"'
SELECT @TotalReproCMD AS HERE5		
		INSERT #ReproCmdResults (col1)
		EXEC xp_cmdshell @TotalReproCMD;

		DELETE FROM #ReproCmdResults
		WHERE col1 IS NULL;

        SELECT @ReproError = STUFF((SELECT ' ' + col1
                                        FROM #ReproCmdResults AS T1
                                        ORDER BY T1.ID
										FOR XML PATH('')), 1, 1, '')
            FROM
                #ReproCmdResults AS T2;
		-----------BEGIN Log Error-----------

		IF (@ReproError NOT LIKE '%1 rows affected%')	
		BEGIN
		--If the conn test fails, then remove that server from the list.
		--This means that none of the current rows will be processed for that server.
		DELETE #Servers
		WHERE SyncServerName = @currSyncServerName;

		UPDATE Minion.SyncCmds
		SET Status = 
					CASE 
					WHEN Status IS NULL THEN 'FATAL ERROR on "' + @currSyncServerName + '".  ' + @ReproError + '  ' 
					WHEN Status NOT LIKE '%' + @currSyncServerName + '%' THEN ISNULL(Status, '') + 'FATAL ERROR on "' + @currSyncServerName + '".  ' + @ReproError + '  '
					WHEN Status LIKE '%' + @currSyncServerName + '%' THEN REPLACE(Status, (@currSyncServerName + '".  ' + @ReproError + '  '), @currSyncServerName + '".  ' + @ReproError + '  ')
					END,
			Pushed = 0,
			Attempts = Attempts + 1,
			ErroredServers = CASE WHEN ErroredServers NOT LIKE @currSyncServerName + '|' THEN ISNULL(ErroredServers, '') + @currSyncServerName + '|'
								  WHEN ErroredServers LIKE @currSyncServerName + '|' THEN ErroredServers
								  WHEN ErroredServers IS NULL THEN ISNULL(ErroredServers, '') + @currSyncServerName + '|'
							  END
		WHERE Module = 'Backup'
			  AND Pushed = 0;
		
		END	
		-----------END Log Error-------------
		
	FETCH NEXT FROM TestConn INTO @currSyncServerName, @currSyncDBName, @currPort, @currConnTimeout
	END

CLOSE TestConn
DEALLOCATE TestConn
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
----------------------------END Test Conn----------------------------------------------
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------BEGIN Push Data Cursor--------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

DECLARE Servers CURSOR
READ_ONLY
FOR SELECT SyncServerName, SyncDBName, Port, ConnectionTimeoutInSecs
FROM #Servers

OPEN Servers

	FETCH NEXT FROM Servers INTO @currSyncServerName, @currSyncDBName, @currPort, @currConnTimeout
	WHILE (@@fetch_STATUS <> -1)
	BEGIN

			IF @currSyncServerName NOT LIKE '%\%'
		BEGIN
			SET @currPort = CASE WHEN @currPort IS NULL THEN ',' + '1433'
								WHEN @currPort IS NOT NULL THEN ',' + @currPort
						END
		END
		IF @currSyncServerName LIKE '%\%'
		BEGIN
			SET @currPort = ISNULL(@currPort, '');
		END

		SET @PreCMD = 'sqlcmd -S "' + ISNULL(@currSyncServerName, '') + ISNULL(CAST(@currPort AS VARCHAR(6)), '') + '" -d "' + ISNULL(@currSyncDBName, '') + '"'
			IF @currConnTimeout IS NOT NULL
		BEGIN
			SET @PreCMD = @PreCMD + ' -l ' + CAST(@currConnTimeout AS VARCHAR(6))
		END
			-------------------------------------------------
			-------------------------------------------------
			----------------BEGIN CMD Cursor-----------------
			-------------------------------------------------
			-------------------------------------------------

							DECLARE CMD CURSOR
							READ_ONLY
							FOR SELECT ID, Cmd 
							FROM #Cmds ORDER BY ID ASC
					
							OPEN CMD

								FETCH NEXT FROM CMD INTO @currID, @currCmd
								WHILE (@@fetch_STATUS <> -1)
								BEGIN

								SET @currCmd = REPLACE(@currCmd, '"', '""')
								SET @TotalCMD = @PreCMD + ' -q "' + @currCmd +  '"'
								IF @TotalCMD IS NULL
								BEGIN
									SET @TotalCMD = 'exit'
								END

								INSERT #CmdSyncT (col1)
								 EXEC xp_cmdshell @TotalCMD;
SELECT @TotalCMD AS HERE6
						DELETE FROM #CmdSyncT
						WHERE col1 IS NULL;

						SELECT @Error = STUFF((SELECT ' ' + col1
												FROM #CmdSyncT AS T1
												ORDER BY T1.ID
												FOR XML PATH('')), 1, 1, '')
							FROM #CmdSyncT AS T2;

						TRUNCATE TABLE #CmdSyncT;
						--SELECT @currID, @PreCMD, @currCmd, @Error
						--PRINT @Error
						-----------BEGIN Log Error-----------
						IF (@Error NOT LIKE '%1 rows affected%' AND @Error NOT LIKE '%completed successfully%') OR (@currCmd LIKE '%TRUNCATE%' AND (@Error IS NOT NULL AND @Error NOT LIKE '%1 rows affected%'))	
						BEGIN
						--Here we write the error to the STATUS col.  If the current server already has an error for the current row
						--then we detect that and we overwrite it with the new error value.  This assumes that the error will be the same though.
						--If the error is different then it'll probably be appended to the STATUS col.
						UPDATE Minion.SyncCmds
						SET Status = 
									CASE 
									WHEN Status IS NULL THEN 'FATAL ERROR on "' + @currSyncServerName + '".  ' + @Error + '  ' 
									WHEN Status NOT LIKE '%' + @currSyncServerName + '%' THEN ISNULL(Status, '') + 'FATAL ERROR on "' + @currSyncServerName + '".  ' + @Error + '  '
									WHEN Status LIKE '%' + @currSyncServerName + '%' THEN REPLACE(Status, (@currSyncServerName + '".  ' + @Error + '  '), @currSyncServerName + '".  ' + @Error + '  ')
									END,
							Pushed = 0,
							Attempts = Attempts + 1,
										ErroredServers = CASE WHEN ErroredServers NOT LIKE @currSyncServerName + '|' THEN ISNULL(ErroredServers, '') + @currSyncServerName + '|'
															  WHEN ErroredServers LIKE @currSyncServerName + '|' THEN ErroredServers
															  WHEN ErroredServers IS NULL THEN ISNULL(ErroredServers, '') + @currSyncServerName + '|'
														  END
						WHERE ID = @currID
						AND Module = 'Backup';

						-----BEGIN Write errored row to Minion.SyncErrorCmds------
						INSERT Minion.SyncErrorCmds (SyncServerName, SyncDBName, Port, SyncCmdID, STATUS, LastAttemptDateTime)
						SELECT @currSyncServerName, @currSyncDBName, @currPort, @currID, 'Initial attempt failed.', GETDATE()
						-----END Write errored row to Minion.SyncErrorCmds--------
						END	
						-----------END Log Error-------------

						-----------BEGIN Log Complete-----------
						IF @Error LIKE '%1 rows affected%' OR @Error LIKE '%completed successfully%' OR (@currCmd LIKE 'TRUNCATE%' AND @Error IS NULL)
						BEGIN
							UPDATE Minion.SyncCmds
							SET Status = 
										CASE WHEN ErroredServers IS NULL THEN 'Complete'
											 WHEN ErroredServers IS NOT NULL THEN ISNULL(Status, '') + 'FATAL ERROR on "' + @currSyncServerName + '".  ' + @Error + '  '
											 WHEN ErroredServers IS NULL THEN ISNULL(ErroredServers, '') + @currSyncServerName + '|'
										END,
								Pushed = 1,
								Attempts = Attempts + 1,
								ErroredServers =  REPLACE(ErroredServers, (@currSyncServerName + '|'), '')
							WHERE ID = @currID
							AND Module = 'Backup';
						END	
						-----------END Log Complete-------------							
							FETCH NEXT FROM CMD INTO @currID, @currCmd
								END

							CLOSE CMD
							DEALLOCATE CMD
			-------------------------------------------------
			-------------------------------------------------
			----------------END CMD Cursor-------------------
			-------------------------------------------------
			-------------------------------------------------
		
	FETCH NEXT FROM Servers INTO @currSyncServerName, @currSyncDBName, @currPort, @currConnTimeout
	END

CLOSE Servers
DEALLOCATE Servers

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------END Push Data Cursor----------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------





GO
