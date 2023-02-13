SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[CloneAllSettings]
	@Module VARCHAR(50) = NULL
AS
SET  NOCOUNT ON;


/***********************************************************************************
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------------------Minion Backup------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Created By: MinionWare LLC. and MidnightDBA.com

For SQL Server consulting, see our website http://www.MidnightSQL.com
No job is too big or too small.

Also, check out our FREE SQL Server training videos at http://www.MidnightDBA.com

This is a big routine with many nuances.  Our documentation is complete, but if 
you prefer, we also have videos that show you how to use each of the features.
You can find them at http://www.MidnightDBA.com/Minion

Minion Backup is a free, standalone, backup routine that is a component 
of the Minion Enterprise Management solution.

Minion Enterprise is an enterprise management solution that makes managing your 
SQL Server enterprise super easy. The backup routine folds into the enterprise 
solution with ease.  By integrating your backups into the Minion Enterprise, you 
get the ability to manage your backup parameters from a central location. And, 
Minion Enterprise provides enterprise-level reporting and alerting.
Download a 90-day trial of Minion Enterprise at http://MinionWare.net

* By running this software you are agreeing to the terms of the license agreement.
* You can find a copy of the license agreement here: http://www.midnightsql.com/minion-end-user-license-agreement/
--------------------------------------------------------------------------------

Purpose: Generate an insert statement for all settings tables. Can be limited by module, optionally.

WARNING: This generates clone of alll existing settings rows. Make sure you PAY ATTENTION 
		 before running the generated statements anywhere. If you generate these, for example,
		 then run them against the same database, you'll be doubling your settings in each
		 table to no purpose.

Features:
	* Generate INSERT statements for all Minion settings tables, in all modules.

	* Alternately, generate INSERT statements for all Minion settings tables, for ONE module.

Limitations:
	*  You may have to edit the generated INSERT statements, if values contain single quotes.

Notes:
		* This SP will get all of the shared "DBMaint" modules, whether you run it 
		  for all modules, or for just one.
		* This isn't meant to work with Minion Enterprise; it's an entirely different 
		  kind of system, altogether!
		  (Crowd responds, deadpan: "It's an entirely different kind of system.")
		* Right now we have one settings table with a special case - no ID column.
		  So, we deal with that separately.

Walkthrough:  --!--

 1. 
 2. 
 3. 
 4. 


Parameters:
-----------
	@Module		Leave this NULL to clone all modules' settings. Or, specify a single module.

Tables:
-----------


Example Execution: 
-----------
	-- Clone settings for CheckDB module:
	EXEC Minion.CloneAllSettings 'CheckDB';
	
	-- Clone settings for all modules:
	EXEC Minion.CloneAllSettings;

Revision History:  
-----------
	1.0		5/4/2017	Brand new. -JM
*/

BEGIN
	DECLARE @currModule VARCHAR(50),
		@TableName VARCHAR(200),
		@LastRowID INT,
		@RowID INT,
		@SQL NVARCHAR(MAX),
		@INSERTsql NVARCHAR(MAX);

	CREATE TABLE #tables (tableName NVARCHAR(200));
	CREATE TABLE #statements (stmt NVARCHAR(max));

    -------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------
	------------------------------BEGIN Loop through each module ------------------------------
	-------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------
	--SET @currModule = @Module;

	IF @Module IS NULL
		SET @Module = '%';

	DECLARE moduleCrs CURSOR FOR 
	SELECT Module
	FROM Minion.HELPObjects 
	WHERE Module LIKE @Module
	GROUP BY Module
	ORDER BY Module;
	
	OPEN moduleCrs;

	FETCH NEXT FROM moduleCrs INTO @currModule;
	WHILE @@FETCH_STATUS = 0
	BEGIN 	-- @@FETCH_STATUS = 0 - moduleCrs
	
		-------------------------------------------------------------------------------------------
		-- BEGIN get the settings tables
		-------------------------------------------------------------------------------------------
		IF @currModule = 'Backup'
		BEGIN
			INSERT INTO #tables (tableName) VALUES ('Minion.BackupSettings'			);
			INSERT INTO #tables (tableName) VALUES ('Minion.BackupSettingsPath'		);
			INSERT INTO #tables (tableName) VALUES ('Minion.BackupSettingsServer'	);
			INSERT INTO #tables (tableName) VALUES ('Minion.BackupTuningThresholds' );
		END;

		IF @currModule = 'Reindex'
		BEGIN
			INSERT INTO #tables (tableName) 
			SELECT 'Minion.' + name AS tableName
			FROM sys.tables WHERE name LIKE 'IndexSettings%';

			INSERT INTO #tables (tableName) 
			SELECT 'Minion.' + name AS tableName
			FROM sys.tables WHERE name LIKE 'IndexMaintSettings%';
	
		END;

		IF @currModule = 'CheckDB'
		BEGIN
			INSERT INTO #tables (tableName) 
			SELECT 'Minion.' + name AS tableName
			FROM sys.tables WHERE name LIKE 'CheckDBSettings%';

			INSERT INTO #tables (tableName) VALUES ( 'Minion.CheckDBSnapshotPath'	 );
		END;

		-- And, universal tables: 
		INSERT INTO #tables (tableName) 
		SELECT 'Minion.' + name AS tableName
		FROM sys.tables WHERE name LIKE 'DBMaint%'
			AND name NOT LIKE '%temp'
			AND name NOT LIKE '%Log'
			AND name NOT LIKE '%LogDetails';

		DELETE FROM #tables WHERE tableName = 'Minion.DBMaintRegexLookup'; -- Special case, no ID

		-------------------------------------------------------------------------------------------
		-- END get the settings tables
		-------------------------------------------------------------------------------------------

		-------------------------------------------------------------------------------------------
		-- BEGIN Loop through each settings table
		-------------------------------------------------------------------------------------------
	
		DECLARE tableCrs CURSOR FOR 
		SELECT tableName FROM #tables;

		OPEN tableCrs;

		FETCH NEXT FROM tableCrs INTO @TableName;

		WHILE @@FETCH_STATUS = 0
		BEGIN	-- while @@FETCH_STATUS = 0, tableCrs
			
			-------------------------------
			-- BEGIN Loop through each row
			-------------------------------
			SET @LastRowID = 0;
			SET @RowID = 0;

			WHILE 1 = 1
			BEGIN
				SET @SQL = 'SELECT @RowIDOUT = MIN(ID) FROM ' + @TableName + ' WHERE ID > @ID;';
		
				EXEC sp_executesql @SQL,
					N'@ID INT, @RowIDOUT INT OUTPUT',
					@ID = @RowID,
					@RowIDOUT = @RowID OUTPUT;
		
				IF @RowID = @LastRowID
				   OR @RowID IS NULL
					BREAK;

				EXEC Minion.CloneSettings @TableName = @TableName,
					@ID = @RowID,
					@WithTrans = 0,
					@SelectStmt = 0,
					@INSERTsql = @INSERTsql output;
		
				INSERT INTO #statements
				(
					stmt
				)
				VALUES (@INSERTsql);
			END;
			/*	Discussion/explanation: So we need to loop through each row in a table, right? But the table name is in a
				var, because we're looping through those too, right? That's gotta be dynamic TSQL. In order to make it work,
				for each row in the table we 
					- get the next minimum ID,
					- return that to the session,
					- and if it's different than the last time, run Minion.CloneSettings
					- (if not different, then we're done with the table so we break out of the loop)
				It gets a little bit mucky-looking because we're using sp_executeSQL with parameters, but what're ya gonna do?
				-JM
			*/
			-------------------------------
			-- END Loop through each row
			-------------------------------
		
			FETCH NEXT FROM tableCrs INTO @TableName;

		END; 	-- while @@FETCH_STATUS = 0, tableCrs

		CLOSE tableCrs;
		DEALLOCATE tableCrs;

		-------------------------------------------------------------------------------------------
		-- END Loop through each settings table
		-------------------------------------------------------------------------------------------

		FETCH NEXT FROM moduleCrs INTO @currModule;

	END;	-- @@FETCH_STATUS = 0 - moduleCrs
	
	CLOSE moduleCrs;
	DEALLOCATE moduleCrs;
    -------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------
	------------------------------END Loop through each module ------------------------------
	-------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------

	-------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------
	------------------------------BEGIN special cases -----------------------------------------
	-------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------
	
	-------------------------------------------------------------------------------------------
	-- BEGIN Minion.DBMaintRegexLookup 
	-------------------------------------------------------------------------------------------
	DECLARE @currAction VARCHAR(10),
		@currMaintType VARCHAR(20),
		@currRegex NVARCHAR(4000);

	DECLARE myCrs CURSOR FOR
	SELECT [Action]
         , MaintType
         , Regex 
	FROM Minion.DBMaintRegexLookup;
	
	OPEN myCrs;
	FETCH NEXT FROM myCrs INTO @currAction, @currMaintType, @currRegex;
	WHILE @@FETCH_STATUS = 0
	BEGIN -- @@FETCH_STATUS = 0 - myCrs
		
		SET @currAction  = REPLACE(@currAction, '''', '''''');
		SET @currMaintType  = REPLACE(@currMaintType, '''', '''''');
		SET @currRegex = REPLACE(@currRegex, '''', '''''');

		INSERT INTO Minion.DBMaintRegexLookup ([Action], [MaintType], [Regex]) 
		SELECT @currAction AS [Action], @currMaintType AS [MaintType], @currRegex AS [Regex];
			
		FETCH NEXT FROM myCrs INTO @currAction, @currMaintType, @currRegex;
	END; -- @@FETCH_STATUS = 0 - myCrs

	CLOSE myCrs;
	DEALLOCATE myCrs;

	DELETE FROM #tables WHERE tableName = 'Minion.DBMaintRegexLookup'; -- Special case, no ID
	
	-------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------
	------------------------------END special cases -----------------------------------------
	-------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------
	

	SELECT stmt
	FROM #statements
	ORDER BY stmt;
END;

GO
