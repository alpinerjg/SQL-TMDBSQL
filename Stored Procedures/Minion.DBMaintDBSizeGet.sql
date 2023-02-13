SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [Minion].[DBMaintDBSizeGet]
(
@Module VARCHAR(20),
@OpName VARCHAR(20) OUTPUT,
@DBName VARCHAR(400),
@DBSize DECIMAL(18, 2) OUTPUT
)

AS


DECLARE	@Version DECIMAL(3,1),
		@SQL nvarchar(2000),
		@DBMaintDB VARCHAR(400);

SET @DBMaintDB = DB_NAME();

CREATE TABLE #DBSize
(
DBName VARCHAR(200),
Size FLOAT,
SpaceUsed FLOAT,
DataSpaceUsed FLOAT,
IndexSpaceUsed FLOAT
);


SELECT @Version = Version 
FROM Minion.DBMaintSQLInfoGet()

-----------------------------------------------------
-------------------BEGIN AUTO------------------------
-----------------------------------------------------

IF @Module = 'CHECKDB'
	BEGIN --CheckDB Op
DECLARE @CheckDBAutoSettingLevel INT,
		@AutoThresholdMethod VARCHAR(20),
		@AutoThresholdType VARCHAR(20),
		@AutoThresholdValue INT;




----0 = MinionDefault, > 0 = DBName.
IF UPPER(@OpName) = 'AUTO' OR @OpName IS NULL
	BEGIN --AUTO Params
			SET @CheckDBAutoSettingLevel = (
									SELECT COUNT(*)
									FROM Minion.CheckDBSettingsAutoThresholds
									WHERE
										DBName = @DBName
										AND IsActive = 1
								);

                        IF @CheckDBAutoSettingLevel = 0
                            BEGIN --@TuningTypeLevel = 0
                                SELECT TOP 1
                                        @AutoThresholdMethod = ThresholdMethod,
										@AutoThresholdType = ThresholdType,
										@AutoThresholdValue = ThresholdValue
                                    FROM
                                        Minion.CheckDBSettingsAutoThresholds
                                    WHERE
                                        DBName = 'MinionDefault'
                                        AND IsActive = 1

                            END --@TuningTypeLevel = 0

                        IF @CheckDBAutoSettingLevel > 0
                            BEGIN --@TuningTypeLevel > 0
                                SELECT TOP 1
                                        @AutoThresholdMethod = ThresholdMethod,
										@AutoThresholdType = ThresholdType,
										@AutoThresholdValue = ThresholdValue
                                    FROM
                                        Minion.CheckDBSettingsAutoThresholds
                                    WHERE
                                        DBName = @DBName
                                        AND IsActive = 1
                            END --@TuningTypeLevel > 0
END --AUTO Params
END --CheckDB Op
-----------------------------------------------------
-------------------END AUTO--------------------------
-----------------------------------------------------


------------------------------------------------------------------------
------------------------------------------------------------------------
-------------------------BEGIN DBSize-----------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------

/*
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
the reason we have the Auto table is because the thresholds table holds values for each op type and we
wouldn't have a solid place to keep the values. So where do we do it, or checkdb or checktable, etc?
So this is a clean settings table to say when to switch from checkdb to checktable w/o any of the hassle
of figuring out which row to use for each DB.
Also, we should prob rename checkdbthresholds to checkdbsnapsotsettings. it's more fitting.
in our auto table we prob need to give the unit of measure for each value so it's clear what we're doing.
we're also currently using the threshold setting from Settings and I think that needs to stop.
We also need to add in table count to the auto table so we can do more than just size.
*/

CREATE TABLE #TSizeGet
    (
        ID INT IDENTITY(1, 1),
        col1 VARCHAR(MAX) COLLATE DATABASE_DEFAULT
    )

DECLARE @SpaceType VARCHAR(20),
		@DBSizeCMD VARCHAR(8000)--,
		--@DBSize DECIMAL(18, 2);
		

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
----------------------------------BEGIN Maint Type-------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
----Here we're getting space the same way we did in MB.
BEGIN --DBSize
IF @Module = 'CHECKDB'
	BEGIN --CheckDB Op
		IF UPPER(@AutoThresholdMethod) = 'SIZE'
			BEGIN
				SET @SpaceType = @AutoThresholdType;
	END
	END --CheckDB Op
                        IF @SpaceType IS NULL
                            BEGIN
                                SET @SpaceType = 'DataAndIndex';
                            END

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
----------------------------------END Maint Type---------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
----------------------------------BEGIN Get Size Data----------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

--Here we're avoiding the Insert/Exec syntax so we can use this in mult. SPs.
--We don't need to keep this data long at all so we delete it as soon as we get it into our #table.

SET @SQL = 'USE [' + @DBName + ']; INSERT [' + @DBMaintDB + '].Minion.DBMaintDBSizeTemp (DBName,Size,SpaceUsed,DataSpaceUsed,IndexSpaceUsed) SELECT DB_Name() AS DBName,
(SELECT SUM(CAST(df.size as float)) FROM sys.database_files AS df WHERE df.type in ( 0, 2, 4 ) )*8 AS [Size],
SUM(a.total_pages)*8 AS [SpaceUsed],
SUM(CASE When it.internal_type IN (202,204,207,211,212,213,214,215,216) Then 0 When a.type <> 1 Then a.used_pages	When p.index_id < 2 Then a.data_pages	Else 0	END)*8 AS [DataSpaceUsage],
SUM(a.used_pages)*8 AS [IndexSpaceTotal]
FROM
sys.partitions p join sys.allocation_units a on p.partition_id = a.container_id left join sys.internal_tables it on p.object_id = it.object_id;'
		EXEC (@SQL)
INSERT #DBSize
		(DBName, Size, SpaceUsed, DataSpaceUsed, IndexSpaceUsed)
SELECT TOP 1 * FROM Minion.DBMaintDBSizeTemp WHERE DBName = @DBName;

DELETE Minion.DBMaintDBSizeTemp WHERE DBName = @DBName;

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
----------------------------------END Get Size Data------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
----------------------------------BEGIN Set Size Type----------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

			IF @SpaceType = 'File'
				BEGIN	
					SET @DBSize = (SELECT CAST(Size/1024.0/1024.0 AS DECIMAL(5,2)) FROM #DBSize);			 
				END

			IF @SpaceType = 'Data'
				BEGIN
					SET @DBSize = (SELECT CAST(Size/1024.0/1024.0 AS DECIMAL(5,2)) FROM #DBSize);
				END

			IF @SpaceType = 'DataAndIndex'
				BEGIN --DataAndIndex
					SET @DBSize = (SELECT CAST(Size/1024.0/1024.0 AS DECIMAL(5,2)) FROM #DBSize);
				END --DataAndIndex

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
----------------------------------END Set Size Type------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------


-------------------------------------------------------------------
--------------------BEGIN Size Format------------------------------
-------------------------------------------------------------------
----If something happens with the above call then the @DBSize var won't be able to be assigned so this is an excellent place to put in the error handling.
							--Sometimes on int'l systems we get a , back from PS so we have to change it back to a decimal point.
							
							--(SELECT REPLACE(col1, ',', '.') FROM #TSizeGet)
							SET @DBSize = REPLACE(@DBSize, ',', '.');
							DROP TABLE #DBSize;

----If DBSize is under 0 it won't trigger the NumberOfFiles so it has to be at least 0.
                        IF @DBSize < 1
                            BEGIN
                                SET @DBSize = 1;
                            END
-------------------------------------------------------------------
--------------------BEGIN Size Format------------------------------
-------------------------------------------------------------------


-------------------------------------------------------------------
--------------------BEGIN Op Type----------------------------------
-------------------------------------------------------------------
	IF @Module = 'CHECKDB'
		BEGIN --CheckDB Op
			IF @OpName IS NULL OR UPPER(@OpName) = 'AUTO'
			BEGIN --@Op IS NULL
				IF @DBSize >= @AutoThresholdValue
					BEGIN
						SET @OpName = 'CHECKTABLE'
					END

				IF @DBSize < @AutoThresholdValue
					BEGIN
						SET @OpName = 'CHECKDB'
					END
			 END--@Op IS NULL
		 END --CheckDB Op
-------------------------------------------------------------------
--------------------END Op Type------------------------------------
-------------------------------------------------------------------

 END --DBSize
------------------------------------------------------------------------
------------------------------------------------------------------------
-------------------------END DBSize-------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------



GO
