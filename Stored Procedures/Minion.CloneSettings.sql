SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[CloneSettings]
	@TableName VARCHAR(512) = 'Minion.BackupSettings' ,
	@ID INT ,
	@WithTrans BIT = 1,
	@SelectStmt BIT = 1,
	@INSERTsql NVARCHAR(max) = NULL OUTPUT

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

Purpose: Generate an insert statement for a table, based on a particular row.

WARNING: This generates a clone of an existing row. Make sure you change key identifying 
		 information - e.g., the DBName - before you run the INSERT statement; you would
		 not want to insert a completely identical row.



Features:
	* When you want to change the settings for a database in the settings table, you 
		have to insert a row for that database. From then on, the system takes ALL 
		configuration for that database from that row. So, if you want to change just one 
		setting, you still have to fill out 40 columns.

	* This "helper" procedure lets you pass in the ID of the row you want to model the new settings
		off of, and it returns an insert statement so you can change the one or two values you want.

	* We made this SP flexible; you can enter in the name of any Minion table, and a row ID, and 
		it will generate the insert statement for you.

Limitations:
	*  

Notes:
		* This SP was made to work with Minion code; it can be easily modified to
		  work with ANY table; you just need to deal with the schema name.
		* While the SP assumes that the target table has an identity column, it
		  does not assume that the name is ID: it will find the name of the identity
		  column. 
		* In the case of a table with no identity column, Minion.CloneSettings 
		  will generate a template INSERT statement with more or less random values 
		  pulled from the target table.
		* If a target table has no rows, Minion.CloneSettings will generate a 
		  template INSERT statement with all NULL values.

Walkthrough:  --!--

 1. Make sure the table is a Minion table, and that it exists.
 2. Variables and temp tables
 3. Loop through each column in the table to build the insert statement.
 4. Complete and return the insert statement.


Parameters:
-----------
	@TableName	The name of the table you'd like an insert statement for. This can be in the format 
				"Minion.BackupSettings" or just "BackupSettings"
	
	@ID			The ID number of the row you'd like to clone.

	@WithTrans	Add "BEGIN TRAN" and "COMMIT TRAN / ROLLBACK TRAN" before and after the INSERT statement.


Tables:
-----------
	#ColValue			Temp table used to hold the current column value.   



Example Execution: 
-----------
	-- Generate an insert statement for Minion.BackupSettings based on row ID=2
	EXEC Minion.CloneSettings @ID = 2;		

	-- Generate an insert statement for Minion.BackupTuningThresholds based on row ID=1
	EXEC Minion.CloneSettings 'BackupTuningThresholds',  1;

	-- Generate an insert statement, fail to capture it at all:
	EXEC Minion.CloneSettings 'BackupTuningThresholds',  1, 0;
	-- (See? No output param, and you set @SelectStmt=0. Silly DBA.)

	-- Generate an insert statement, capture it with an output variable:
	DECLARE @stmt nvarchar(max);
	EXEC Minion.CloneSettings 'BackupTuningThresholds',  1, 0, @stmt output;
	PRINT @stmt;

Revision History:  
-----------
	1.0		New
	1.1		5/4/2017	Modified to work with Minion.CloneAllSettings. Added params 
			@SelectStmt and @INSERTsql, added a warning at the end (because if you 
			choose @SelectStmt = 0 and don't use @INSERTsql, it looks like there's
			no output).
*/
AS ----------------------------------------------------------------------
	---- Make sure the table is a Minion table, and that it exists.
	----------------------------------------------------------------------
	
	IF @TableName NOT LIKE 'Minion.%'
		AND @TableName NOT LIKE '[Minion].%' 
		SET @TableName = '[Minion].' + @TableName;

	IF NOT EXISTS ( SELECT	OBJECT_ID(@TableName) ) 
		BEGIN
			RAISERROR ('Table does not exist.', 16, 1);
			RETURN;
		END

	----------------------------------------------------------------------
	----------------------------------------------------------------------
	----------------------------- Variables ------------------------------
	----------------------------------------------------------------------
	----------------------------------------------------------------------

	DECLARE	--@INSERTsql VARCHAR(MAX) ,		-- Holds the first part of the INSERT statement
		@SELECTsql VARCHAR(MAX) ,			-- Holds the SELECT part of the INSERT statement
		@VALsql VARCHAR(MAX);				-- Holds the dynamic query to get the current column value

	DECLARE	@i INT ,				-- Counter for the loop.
		@max INT ,					-- The max column_id for the table.
		@FirstColumn BIT;			-- This is a flag that keeps us from planting a comma before the first column.
		

	DECLARE	@ColName AS VARCHAR(256) ,	-- Current column name
		@TypeName AS VARCHAR(256) ,		-- Current column's type name
		@ColValue VARCHAR(8000) ,		-- Current column value
		@cnt INT,						-- "Count" var, of rows in @TableName
		@identityCol sysname;			-- Name of the table's identity column, if any

	CREATE TABLE #ColValue
		(
		  ColValue VARCHAR(8000) NULL
		);


	SET @FirstColumn = 1;
	SET @INSERTsql = 'INSERT INTO ' + @TableName + ' (';
	SET @SELECTsql = 'SELECT ';

	CREATE TABLE #cnt ( cnt INT );
	INSERT	INTO #cnt
			( cnt
			)
			EXEC ( 'SELECT COUNT(*) FROM ' + @TableName
				);
	
	SELECT	@cnt = cnt
	FROM	#cnt;
	DROP TABLE #cnt;

----------------------------------------------------------------------
----------------------------------------------------------------------
---------------------- Gather column information ---------------------
----------------------------------------------------------------------
----------------------------------------------------------------------
CREATE TABLE #Columns
	( OBJECT_ID INT,
	  column_id INT ,
	  ColName sysname ,
	  TypeName sysname ,
	  system_type_id INT,
	  is_identity BIT
	);

INSERT INTO #Columns (OBJECT_ID, column_id, ColName, TypeName, system_type_id, is_identity)
SELECT	c.object_id, 
		column_id,
		c.name AS ColName ,
		t.name AS TypeName,
		c.system_type_id, 
		is_identity
FROM	sys.COLUMNS c
		JOIN sys.objects o ON c.object_id = o.object_id
		JOIN sys.types t ON c.system_type_id = t.system_type_id
WHERE	o.object_id = OBJECT_ID(@TableName);

SELECT	@identityCol = ColName
FROM	#Columns
WHERE	is_identity = 1;

----------------------------------------------------------------------
----------------------------------------------------------------------
---------------- Loop through each column in the table ---------------
----------------------------------------------------------------------
----------------------------------------------------------------------

	SELECT	@i = 1 ,
			@max = MAX(c.column_id)
	FROM	#Columns c
			JOIN sys.objects o ON c.OBJECT_ID = o.object_id
	WHERE	o.object_id = OBJECT_ID(@TableName);


	WHILE @i <= @max 
		BEGIN

			SELECT	@ColName = c.ColName ,
					@TypeName = c.TypeName
			FROM	#Columns c
					JOIN sys.objects o ON c.OBJECT_ID = o.object_id
			WHERE	o.object_id = OBJECT_ID(@TableName)
					AND c.column_id = @i
					AND c.is_identity = 0;

		-- We ignore identity column fields. If this was one, skip to the next iteration:
			IF @ColName IS NULL 
				BEGIN
					SET @i = @i + 1;
					CONTINUE;
				END
		
		-- Get the current column value:
			IF @identityCol IS NULL
				-- If there is no identity column, just get a random value.
				SET @VALsql = 'SELECT TOP 1 CAST([' + @ColName
					+ '] as VARCHAR(8000)) FROM ' + @TableName + ';';
			ELSE
				-- If there is an identity column, get the value where identity col = @ID
				SET @VALsql = 'SELECT CAST([' + @ColName
					+ '] as VARCHAR(8000)) FROM ' + @TableName + ' WHERE [' 
					+ @identityCol + '] = '
					+ CAST(@ID AS VARCHAR(10));			
			
			          
			INSERT	INTO #ColValue
					( ColValue )
					EXEC ( @VALsql
						);

			SELECT	@ColValue = ColValue
			FROM	#ColValue;

			IF @FirstColumn = 0 
				BEGIN
					SET @INSERTsql = @INSERTsql + ', ';
					SET @SELECTsql = @SELECTsql + ', ';
				END
	
			SET @INSERTsql = @INSERTsql + '[' + @ColName + ']';

			SET @SELECTsql = @SELECTsql
				+ CASE WHEN @ColValue IS NULL
					   THEN 'NULL AS ' + '[' + @ColName + ']'
					   WHEN @TypeName LIKE '%char'
					   THEN '''' + @ColValue + ''' AS ' + '[' + @ColName + ']'
					   WHEN @TypeName LIKE 'date%'
					   THEN '''' + @ColValue + ''' AS ' + '[' + @ColName + ']'
					   WHEN @TypeName IN ( 'text', 'ntext', 'uniqueidentifier',
										   'time', 'sysname', 'xml' )
					   THEN '''' + @ColValue + ''' AS ' + '[' + @ColName + ']'
					   WHEN @TypeName = 'varbinary'
					   THEN ' CAST(''' + @ColValue + ''' AS VARBINARY) AS '
							+ '[' + @ColName + ']'
					   WHEN @TypeName = 'BINARY'
					   THEN ' CAST(''' + @ColValue + ''' AS BINARY) AS ' + '['
							+ @ColName + ']'
					   ELSE CAST(@ColValue AS VARCHAR(MAX)) + ' AS ' + '['
							+ @ColName + ']'
				  END;
	
			SET @i = @i + 1;
	
			TRUNCATE TABLE #ColValue;

			SET @FirstColumn = 0;
		END

	DROP TABLE #ColValue;

----------------------------------------------------------------------
----------------------------------------------------------------------
-------------- Complete and return the insert statement --------------
----------------------------------------------------------------------
----------------------------------------------------------------------

	SET @INSERTsql = @INSERTsql + ') ' + @SELECTsql;

	IF @WithTrans = 1 
		SET @INSERTsql = 'BEGIN TRAN; 
' + @INSERTsql + '
-- ROLLBACK TRAN;
COMMIT TRAN;';

	-- Return the statement:
	IF @SelectStmt = 1
		SELECT	@INSERTsql;
	
	-- Warn them if there's no output
	IF @SelectStmt = 0
		PRINT '@SelectStmt is 0. Use the @INSERTsql output parameter, or use @SelectStmt = 1.'
	RETURN;





GO
