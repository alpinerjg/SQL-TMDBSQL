SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[DBMaintServiceCheck]
(
@ServiceStatus BIT OUTPUT
)
AS

DECLARE @Version VARCHAR(50),
		--@ServiceStatus BIT,
		@CMD VARCHAR(200),
		@InstanceName VARCHAR(400);


				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------
				---------------------BEGIN PRE Service Check------------------------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------

SELECT 
@Version = [Version]
FROM Minion.DBMaintSQLInfoGet();

IF @Version <= 10.5
BEGIN --@Version <= 10.5
		CREATE TABLE #PREService (col1 VARCHAR(1000) COLLATE DATABASE_DEFAULT)

		BEGIN
					SET @CMD = 'EXEC xp_cmdshell ''powershell "'
					SET @CMD = @CMD + ' $a = (gwmi win32_service | ?{$_.Name -LIKE ''''SQLAgent$' + @InstanceName + '''''}).State; If($a -eq ''''Running''''){$a = 1} ELSE{$a = 0}"'''

					INSERT  #PREService
							( col1 )
							EXEC ( @CMD
								) 


		SET @ServiceStatus = (SELECT TOP 1 col1 FROM #PREService)
		DROP TABLE #PREService;
		END
END --@Version <= 10.5

IF @Version > 10.5
BEGIN

		SELECT @ServiceStatus = 
			CASE WHEN [status] = 4 THEN 1
			ELSE 0
			END 
		FROM sys.dm_server_services WHERE servicename LIKE '%Agent%'

END
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------
				------------------------------END PRE Service Check-----------------------------
				--------------------------------------------------------------------------------
				--------------------------------------------------------------------------------

GO
