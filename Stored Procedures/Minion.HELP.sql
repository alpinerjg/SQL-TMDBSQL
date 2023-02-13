SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[HELP]
	(
	  @Module VARCHAR(50) = NULL ,
	  @Name VARCHAR(100) = NULL,
      @Keyword BIT = 0
	)
AS 
/***********************************************************************************
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------------------Minion Reindex, Backup, CheckDB ------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Created By: MinionWare, LLC and MidnightDBA.com
http://www.MinionWare.net 

For SQL Server consulting, see our website http://www.MidnightSQL.com
No job is too big or too small.

Also, check out our FREE SQL Server training videos at http://www.MidnightDBA.com

About: 
This is a big routine with many nuances.  Our documentation is complete, but if 
you prefer, we also have videos that show you how to use each of the features.
You can find them at http://www.MinionWare.net

Minion Reindex is a free, standalone, index maintenance routine that is a component 
of the Minion Enterprise Management solution.

Minion Enterprise Management makes managing your SQL Server enterprise super easy. 
The reindex routine folds into the enterprise solution with ease.  By integrating 
your index maintenance into the Minion Enterprise Management solution, you get the 
ability to manage your reindex parameters from a central location. And, Minion 
Enterprise Management provides enterprise-level reporting and alerting.

--------------------------------------------------------------------------------

Purpose: To return help information on the Minion system and objects.

Example execution: 
	EXEC Minion.Help;				-- Returns a list of installed Minion modules.
	EXEC Minion.Help 'Backup';		-- Returns a list of topics for the Backup module.
	EXEC Minion.Help 'Backup', 'Quick Start';	-- Returns the Backup 'Quick Start' article.

	EXEC Minion.Help 'Reindex';		-- Returns a list of topics for the Reindex module.
	EXEC Minion.Help 'Reindex', 'Minion.IndexMaintDB'; -- Returns detailed help on object Minion.IndexMaintDB

Discussion:
	Help objects are currently of the following types:  
		* Information - Different types of Information require different formatting.
		
		* Procedure - ObjectName is printed first, and other features (Parameters, Discussion, 
		  Examples, etc) are printed according to their position.

		* Table - ObjectName is printed first, and other features (Column names, Discussion, 
		  Examples, etc) are printed according to their position.

Table of Contents:
	Declare varaibles
	Module help (includes cursor TopLevelHelp)
	Section help (includes cursor TopLevelHelp)
	Keyword help
	Topic help	(includes cursor HelpText)
		ObjectType='Information'
			IF @DetailHeader NOT LIKE 'Troubleshoot:%'	--!-- Removed MC 1.0
			IF @DetailHeader = 'System Requirements'	--!-- Commented this out for Reindex 1.1
				IF @DetailHeader <> 'ObjectName' 
			IF @DetailType <> 'ObjectName' 
		ObjectType='Procedure'
			IF @DetailType = 'ObjectName' 
			IF @DetailType = 'Param' 
		DetailType='Advice'	-- Advice is a DetailType of "Procedure" objects.
		ObjectType='Table'
			IF @DetailType = 'ObjectName' 
			IF @DetailHeader <> 'Column' AND @DetailType <> 'ObjectName' 
			IF @DetailType = 'Column' 


Revisions
	1.1	Updated printing process.
	1.2 Updated for Minion Backup 1.0 release; fixed SP display.
	1.3 Updated for Minion Reindex 1.2 and Minion Backup 1.1; added a more flexible graphics printing solution.
	    Also, if user inputs a module that isn't installed, help now responds with the list of installed modules.
	1.4 Updated for Minion Backup 1.2.
	1.5 Updated for MC 1.0, MB 1.3. Added @Keyword functionality, Minion.HELPbanner, different help footers, spacer between
		params/columns in printed tables, ability to print entries for views and functions.

NOTE: ASCII art generated from http://patorjk.com/software/taag/#p=display&f=Big&t=Minion%20Backup%201.0%20Help, font "Big".
***********************************************************************************/

--------------Declare varaibles
	DECLARE	@DetailName VARCHAR(100) ,
		@Position SMALLINT ,
		@DetailType SYSNAME ,
		@DetailHeader VARCHAR(100) ,
		@DetailText VARCHAR(MAX) ,
		@ObjectType VARCHAR(100) ,
		@ObjectName VARCHAR(100),
		@DataType VARCHAR(25) ,
		@DetailTextSpacer VARCHAR(100) ,
		@DataTypeSpacer VARCHAR(100) ,
		@currModule VARCHAR(50) ,
		@currObjectName VARCHAR(100) ,
		@TXTLen INT ,
		@i INT ,
		@colCT INT ,
		@colWidth INT ,
		@left NVARCHAR(4000) ,
		@breakPos TINYINT ,
		@outstr NVARCHAR(4000) ,
		@hasbreak BIT;


SET NOCOUNT ON;

IF NOT EXISTS (SELECT * FROM Minion.HELPObjects WHERE Module = @Module)
	SET @Module = NULL;

------------------------------------------------------------------------------
--------------BEGIN Print ASCII header----------------------------------------
------------------------------------------------------------------------------
    /*
Note: The ASCII text art below has long strings of spaces in rows 7 and 8, because
we're building the text art horizontally: e.g., MINION CheckDB 1.0. AND, some strings 
(namely Backup and Help) have characters in rows 7 and 8 to build letters like "p" that
extend down that far. SO, you need to build the art with those spaces in rows 7/8, so 
that the characters line up correctly later in the row. get it? -JM, 1/2017
*/
CREATE TABLE #asciiArt
       (
         ID INT IDENTITY(1, 1)
       , TitleOrder INT
       , Title VARCHAR(100)
       , TextRow NVARCHAR(4000)
       );

INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, 'Minion', N'  __  __   _           _                   ' )		,
        ( 2, 'Minion', N' |  \/  | (_)         (_)                  ' )		,
        ( 3, 'Minion', N' | \  / |  _   _ __    _    ___    _ __    ' )		,
        ( 4, 'Minion', N' | |\/| | | | | ''_ \  | |  / _ \  | ''_ \   ' )		,
        ( 5, 'Minion', N' | |  | | | | | | | | | | | (_) | | | | |  ' )		,
        ( 6, 'Minion', N' |_|  |_| |_| |_| |_| |_|  \___/  |_| |_|  ' )		,
        ( 7, 'Minion', N'                                           ' )		,
        ( 8, 'Minion', N'                                           ' );


INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, 'Backup', N' ____                   _                      ' )		,
        ( 2, 'Backup', N'|  _ \                 | |                     ' )		,
        ( 3, 'Backup', N'| |_) |   __ _    ___  | | __  _   _   _ __    ' )		,
        ( 4, 'Backup', N'|  _ <   / _` |  / __| | |/ / | | | | | ''_ \   ' )		,
        ( 5, 'Backup', N'| |_) | | (_| | | (__  |   <  | |_| | | |_) |  ' )		,
        ( 6, 'Backup', N'|____/   \__,_|  \___| |_|\_\  \__,_| | .__/   ' )		,
        ( 7, 'Backup', N'                                      | |      ' )		,
        ( 8, 'Backup', N'                                      |_|      ' );
INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, 'Reindex', N' _____           _               _                 ' ) 		,
        ( 2, 'Reindex', N'|  __ \         (_)             | |                ' ) 		,
        ( 3, 'Reindex', N'| |__) |   ___   _   _ __     __| |   ___  __  __  ' ) 		,
        ( 4, 'Reindex', N'|  _  /   / _ \ | | | ''_ \   / _` |  / _ \ \ \/ /  ' ) 		,
        ( 5, 'Reindex', N'| | \ \  |  __/ | | | | | | | (_| | |  __/  >  <   ' ) 		,
        ( 6, 'Reindex', N'|_|  \_\  \___| |_| |_| |_|  \__,_|  \___| /_/\_\  ' ) 		,
        ( 7, 'Reindex', N'                                                   ' ) 		,
        ( 8, 'Reindex', N'                                                   ' );

INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, 'CheckDB',          N'  _____   _                     _      _____    ____    ' ),
        ( 2, 'CheckDB',          N' / ____| | |                   | |    |  __ \  |  _ \   ' ),
        ( 3, 'CheckDB',          N'| |      | |__     ___    ___  | | __ | |  | | | |_) |  ' ),
        ( 4, 'CheckDB',          N'| |      | ''_ \   / _ \  / __| | |/ / | |  | | |  _ <   ' ),
        ( 5, 'CheckDB',          N'| |____  | | | | |  __/ | (__  |   <  | |__| | | |_) |  ' ),
        ( 6, 'CheckDB',          N' \_____| |_| |_|  \___|  \___| |_|\_\ |_____/  |____/   ' ),
        ( 7, 'CheckDB',          N'                                                        ' ),
        ( 8, 'CheckDB',          N'                                                        ' );

INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, 'Enterprise',          N'  ______           _                                  _                ' ),
        ( 2, 'Enterprise',          N' |  ____|         | |                                (_)               ' ),
        ( 3, 'Enterprise',          N' | |__     _ __   | |_    ___   _ __   _ __    _ __   _   ___    ___   ' ),
        ( 4, 'Enterprise',          N' |  __|   | ''_ \  | __|  / _ \ | ''__| | ''_ \  | ''__| | | / __|  / _ \  ' ),
        ( 5, 'Enterprise',          N' | |____  | | | | | |_  |  __/ | |    | |_) | | |    | | \__ \ |  __/  ' ),
        ( 6, 'Enterprise',          N' |______| |_| |_|  \__|  \___| |_|    | .__/  |_|    |_| |___/  \___|  ' ),
        ( 7, 'Enterprise',          N'                                      | |                              ' ),
        ( 8, 'Enterprise',          N'                                      |_|                              ' );


INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, '1', N' __  ' ) 		,
        ( 2, '1', N'/_ | ' ) 		,
        ( 3, '1', N' | | ' ) 		,
        ( 4, '1', N' | | ' ) 		,
        ( 5, '1', N' | | ' ) 		,
        ( 6, '1', N' |_| ' ) 		,
        ( 7, '1', N'     ' ) 		,
        ( 8, '1', N'     ' );

INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, '2', N' ___   ' ) 		,
        ( 2, '2', N'|__ \  ' ) 		,
        ( 3, '2', N'   ) | ' ) 		,
        ( 4, '2', N'  / /  ' ) 		,
        ( 5, '2', N' / /_  ' ) 		,
        ( 6, '2', N'|____| ' ) 		,
        ( 7, '2', N'       ' ) 		,
        ( 8, '2', N'       ' );

INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, '3', N' ____   ' ) 		,
        ( 2, '3', N'|___ \  ' ) 		,
        ( 3, '3', N'  __) | ' ) 		,
        ( 4, '3', N' |__ <  ' ) 		,
        ( 5, '3', N' ___) | ' ) 		,
        ( 6, '3', N'|____/  ' ) 		,
        ( 7, '3', N'       ' ) 		,
        ( 8, '3', N'       ' );


INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, '4', N' _  _    ' ) 		,
        ( 2, '4', N'| || |   ' ) 		,
        ( 3, '4', N'| || |_  ' ) 		,
        ( 4, '4', N'|__   _| ' ) 		,
        ( 5, '4', N'   | |   ' ) 		,
        ( 6, '4', N'   |_|   ' ) 		,
        ( 7, '4', N'         ' ) 		,
        ( 8, '4', N'         ' );


INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, '5', N' _____  ' ) 		,
        ( 2, '5', N'| ____| ' ) 		,
        ( 3, '5', N'| |__   ' ) 		,
        ( 4, '5', N'|___ \  ' ) 		,
        ( 5, '5', N' ___) | ' ) 		,
        ( 6, '5', N'|____/  ' ) 		,
        ( 7, '5', N'        ' ) 		,
        ( 8, '5', N'        ' );
       
INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, '6', N'   __   ' ) 		,
        ( 2, '6', N'  / /   ' ) 		,
        ( 3, '6', N' / /_   ' ) 		,
        ( 4, '6', N'| ''_ \  ' ) 		,
        ( 5, '6', N'| (_) | ' ) 		,
        ( 6, '6', N' \___/  ' ) 		,
        ( 7, '6', N'        ' ) 		,
        ( 8, '6', N'        ' );

INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, '7', N' ______  ' ) 		,
        ( 2, '7', N'|____  | ' ) 		,
        ( 3, '7', N'    / /  ' ) 		,
        ( 4, '7', N'   / /   ' ) 		,
        ( 5, '7', N'  / /    ' ) 		,
        ( 6, '7', N' /_/     ' ) 		,
        ( 7, '7', N'        ' ) 		,
        ( 8, '7', N'        ' );

INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, '8', N'  ___   ' ) 		,
        ( 2, '8', N' / _ \  ' ) 		,
        ( 3, '8', N'| (_) | ' ) 		,
        ( 4, '8', N' > _ <  ' ) 		,
        ( 5, '8', N'| (_) | ' ) 		,
        ( 6, '8', N' \___/  ' ) 		,
        ( 7, '8', N'        ' ) 		,
        ( 8, '8', N'        ' );

INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, '9', N'  ___   ' ) 		,
        ( 2, '9', N' / _ \  ' ) 		,
        ( 3, '9', N'| (_) | ' ) 		,
        ( 4, '9', N' \__, | ' ) 		,
        ( 5, '9', N'   / /  ' ) 		,
        ( 6, '9', N'  /_/   ' ) 		,
        ( 7, '9', N'        ' ) 		,
        ( 8, '9', N'        ' );
		
INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, '0', N'  ___   ' ) 		,
        ( 2, '0', N' / _ \  ' ) 		,
        ( 3, '0', N'| | | | ' ) 		,
        ( 4, '0', N'| | | | ' ) 		,
        ( 5, '0', N'| |_| | ' ) 		,
        ( 6, '0', N' \___/  ' ) 		,
        ( 7, '0', N'        ' ) 		,
        ( 8, '0', N'        ' );            

INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, '.', N'    ' ) 		,
        ( 2, '.', N'    ' ) 		,
        ( 3, '.', N'    ' ) 		,
        ( 4, '.', N'    ' ) 		,
        ( 5, '.', N' _  ' ) 		,
        ( 6, '.', N'(_) ' ) 		,
        ( 7, '.', N'    ' ) 		,
        ( 8, '.', N'    ' );

INSERT  INTO #asciiArt
        ( TitleOrder, Title, TextRow )
VALUES  ( 1, 'Help', N'   _    _          _          ' ) 		,
        ( 2, 'Help', N'  | |  | |        | |         ' ) 		,
        ( 3, 'Help', N'  | |__| |   ___  | |  _ __   ' ) 		,
        ( 4, 'Help', N'  |  __  |  / _ \ | | | ''_ \  ' ) 		,
        ( 5, 'Help', N'  | |  | | |  __/ | | | |_) | ' ) 		,
        ( 6, 'Help', N'  |_|  |_|  \___| |_| | .__/  ' ) 		,
        ( 7, 'Help', N'                      | |     ' ) 		,
        ( 8, 'Help', N'                      |_|     ' );




DECLARE @MinionVersion FLOAT
      , @MajorVersionNum SMALLINT
      , @MinorVersionNum SMALLINT
      , @isHelp BIT = 1;


-----------------------------------------------
--- Start the string graphic with "Minion":
-----------------------------------------------

CREATE TABLE #string
       (
         TitleOrder INT
       , Title VARCHAR(100)
       , TextRow NVARCHAR(4000)
       );

INSERT  INTO #string
        SELECT  TitleOrder
              , Title
              , TextRow
        FROM    #asciiArt
        WHERE   Title = 'Minion';


-----------------------------------------------
--- IF @Module is not null, add module info:
-----------------------------------------------
IF @Module IS NOT NULL
BEGIN
	SELECT  @MinionVersion = MAX(MinionVersion)
	FROM    Minion.HELPObjects
	WHERE   Module = @Module;

	-- Assign the whole number as the major version number:
	SET @MajorVersionNum = FLOOR(@MinionVersion);

	-- Get just the decimal places - converted to string, removing the "0.", and converting back - as minor version number: 
	SELECT  @MinorVersionNum = CAST(REPLACE(CAST(@MinionVersion
											- FLOOR(@MinionVersion) AS VARCHAR(100)),
											'0.', '') AS SMALLINT);

	-- If anything is null or zero, default to 1.0
	IF ( @MajorVersionNum IS NULL
		 OR @MajorVersionNum = 0
	   )
	   SELECT   @MajorVersionNum = 1
			  , @MinorVersionNum = 0;

	IF ( @MinorVersionNum IS NULL )
	   SELECT   @MinorVersionNum = 0;

	-----------------------------------------------
	--- Add the name of the module:
	-----------------------------------------------
	UPDATE  s
	SET     TextRow = s.TextRow + a.TextRow
	FROM    #string AS s
	JOIN    #asciiArt a
			ON s.TitleOrder = a.TitleOrder
			   AND a.Title = @Module;

	-----------------------------------------------
	--- Add the major version number. Could be 1 digit, 2 or more.
	-----------------------------------------------
	DECLARE @counter INT = 1
		  , @str VARCHAR(10)
		  , @char CHAR(1)
		  , @len SMALLINT;
		  --, @digit SMALLINT;

	SET @str = CAST(@MajorVersionNum AS VARCHAR(10));
	SET @len = LEN(@str);
 
	WHILE @counter <= @len
		  BEGIN
				SELECT  @char = SUBSTRING(@str, @counter, 1);

				UPDATE  s
				SET     TextRow = s.TextRow + a.TextRow
				FROM    #string AS s
				JOIN    #asciiArt a
						ON s.TitleOrder = a.TitleOrder
						   AND a.Title = @char;
	
				SET @counter = @counter + 1;
		  END;

	-----------------------------------------------
	--- Add the period between major and minor version number. 
	-----------------------------------------------

	UPDATE  s
	SET     TextRow = s.TextRow + a.TextRow
	FROM    #string AS s
	JOIN    #asciiArt a
			ON s.TitleOrder = a.TitleOrder
			   AND a.Title = '.';

	-----------------------------------------------
	--- Add the minor version number. Could be 1 digit, 2 or more.
	-----------------------------------------------

	SET @str = CAST(@MinorVersionNum AS VARCHAR(10));
	SET @len = LEN(@str);
	SET @counter = 1;
 
	WHILE @counter <= @len
		  BEGIN
				SELECT  @char = SUBSTRING(@str, @counter, 1);

				UPDATE  s
				SET     TextRow = s.TextRow + a.TextRow
				FROM    #string AS s
				JOIN    #asciiArt a
						ON s.TitleOrder = a.TitleOrder
						   AND a.Title = @char;
	
				SET @counter = @counter + 1;
		  END;
END; -- IF @Module IS NOT NULL


-----------------------------------------------
--- Add "Help"
-----------------------------------------------

   UPDATE   s
   SET      TextRow = s.TextRow + a.TextRow
   FROM     #string AS s
   JOIN     #asciiArt a
            ON s.TitleOrder = a.TitleOrder
               AND a.Title = 'Help';

-----------------------------------------------
--- Print to the screen.
-----------------------------------------------
DECLARE @printStr NVARCHAR(4000);
SET @i = 1;

WHILE @i <= ( SELECT    MAX(TitleOrder)
              FROM      #string
            )
      BEGIN
            SELECT  @printStr = TextRow
            FROM    #string
            WHERE   TitleOrder = @i;
            PRINT @printStr;
            SET @i = @i + 1;
      END;

DROP TABLE #string;
DROP TABLE #asciiArt;

------------------------------------------------------------------------------
--------------END Print ASCII header------------------------------------------
------------------------------------------------------------------------------



------------------------------------------------------------------------------
--------------BEGIN Module help-----------------------------------------------
------------------------------------------------------------------------------
----/ This prints a list of installed modules. This section runs for EXEC Minion.Help;
	IF @Module IS NULL 
		BEGIN --Module

			DECLARE TopLevelHelp CURSOR READ_ONLY
			FOR
				SELECT DISTINCT
						Module
				FROM	Minion.HELPObjects
				WHERE	Module <> 'All'
				ORDER BY Module ASC

			PRINT 'The following Minion modules are installed:'
			OPEN TopLevelHelp

			FETCH NEXT FROM TopLevelHelp INTO @currModule
			WHILE ( @@fetch_status <> -1 ) 
				BEGIN

					PRINT @currModule

					FETCH NEXT FROM TopLevelHelp INTO @currModule
				END

			CLOSE TopLevelHelp;
			DEALLOCATE TopLevelHelp;

			EXEC Minion.HELPbanner;
			
			PRINT 'Using Minion.HELP';
			PRINT '-----------------';
			PRINT '';
			PRINT 'Minion.HELP parameters: ';
			PRINT '    @Module - The name of the module, e.g. Backup, Reindex, CheckDB.';
			PRINT '    @Name - The specific name of the topic, or a keyword to search for.';
			PRINT '    @Keyword - Bit that forces @Name to behave as a keyword. Optional; if Minion.HELP does not find a topic named @Name, it will perform the keyword search anyway.';
			PRINT '';
			PRINT 'Examples: ';
			PRINT '';
			PRINT '    -- Get a list of installed modules.';
			PRINT '	EXEC Minion.HELP;';
			PRINT '';
			PRINT '	-- Get a list of topics for the Backup modules.';
			PRINT '	EXEC Minion.HELP ''Backup'';';
			PRINT '';
			PRINT '	-- Get the help topic ''Quick start'' for the CheckDB module.';
			PRINT '	EXEC Minion.HELP ''CheckDB'', ''Quick Start'';';
			PRINT '';
			PRINT '	-- Find all topis with the exact phrase ''remote CheckDB'' in the text or title:';
			PRINT '	EXEC Minion.HELP ''CheckDB'', ''remote CheckDB'';';
			PRINT '	EXEC Minion.HELP ''CheckDB'', ''remote CheckDB'', 1; -- Same thing, with @Keyword=1';
			PRINT '_____';
			PRINT 'For searchable online documentation, see http://MinionWare.Desk.com';
			PRINT 'For the most up to date version of this documentation, see http://www.MinionWare.net';
			PRINT ' ';
			PRINT '* By running this software you are agreeing to the terms of the license agreement.';
			PRINT '* You can find a copy of the license agreement here: http://www.MinionWare.net/wp-content/uploads/MinionModulesLicenseAgreement.pdf';

			RETURN;
		END --Module
------------------------------------------------------------------------------
--------------END Module help-------------------------------------------------
------------------------------------------------------------------------------


------------------------------------------------------------------------------
--------------BEGIN Section help----------------------------------------------
------------------------------------------------------------------------------
----/ This prints a list of installed sections (topics). This section runs for EXEC Minion.Help 'Reindex';
	IF @Module IS NOT NULL
		AND @Name IS NULL 
		BEGIN --Name
		
			SELECT DISTINCT
					ObjectName ,
					ObjectType ,
					GlobalPosition
			INTO	#Section
			FROM	Minion.HELPObjects
			WHERE	Module = @Module
					AND GlobalPosition IS NOT NULL
			ORDER BY GlobalPosition ASC


			DECLARE TopLevelHelp CURSOR READ_ONLY
			FOR
				SELECT	ObjectName ,
						ObjectType
				FROM	#Section
				ORDER BY GlobalPosition ASC

			PRINT 'You may get help on the following topics:'
			PRINT ''
			PRINT 'Section' + REPLICATE(' ', 100 - LEN('Section'))
				+ 'ObjectType'
			PRINT ''
			OPEN TopLevelHelp

			FETCH NEXT FROM TopLevelHelp INTO @currObjectName, @ObjectType
			WHILE ( @@fetch_status <> -1 ) 
				BEGIN

					PRINT @currObjectName + REPLICATE(' ',
													  100
													  - LEN(@currObjectName))
						+ @ObjectType

					FETCH NEXT FROM TopLevelHelp INTO @currObjectName,
						@ObjectType
				END

			CLOSE TopLevelHelp;
			DEALLOCATE TopLevelHelp;
			DROP TABLE #Section;
			
			EXEC Minion.HELPbanner;

			PRINT '';
			PRINT '';
			PRINT '';

			PRINT 'Using Minion.HELP';
			PRINT '-----------------';
			PRINT '';
			PRINT 'Minion.HELP parameters: ';
			PRINT '    @Module - The name of the module, e.g. Backup, Reindex, CheckDB.';
			PRINT '    @Name - The specific name of the topic, or a keyword to search for.';
			PRINT '    @Keyword - Bit that forces @Name to behave as a keyword. Optional; if Minion.HELP does not find a topic named @Name, it will perform the keyword search anyway.';
			PRINT '';
			PRINT 'Examples: ';
			PRINT '';
			PRINT '    -- Get a list of installed modules.';
			PRINT '	EXEC Minion.HELP;';
			PRINT '';
			PRINT '	-- Get a list of topics for the Backup modules.';
			PRINT '	EXEC Minion.HELP ''Backup'';';
			PRINT '';
			PRINT '	-- Get the help topic ''Quick start'' for the CheckDB module.';
			PRINT '	EXEC Minion.HELP ''CheckDB'', ''Quick Start'';';
			PRINT '';
			PRINT '	-- Find all topis with the exact phrase ''remote CheckDB'' in the text or title:';
			PRINT '	EXEC Minion.HELP ''CheckDB'', ''remote CheckDB'';';
			PRINT '	EXEC Minion.HELP ''CheckDB'', ''remote CheckDB'', 1; -- Same thing, with @Keyword=1';
			PRINT '_____';
			PRINT 'For searchable online documentation, see http://MinionWare.Desk.com';
			PRINT 'For the most up to date version of this documentation, see http://www.MinionWare.net';
			PRINT ' ';
			PRINT '* By running this software you are agreeing to the terms of the license agreement.';
			PRINT '* You can find a copy of the license agreement here: http://www.MinionWare.net/wp-content/uploads/MinionModulesLicenseAgreement.pdf';

			RETURN;
		END --Name

------------------------------------------------------------------------------
--------------END Section help----------------------------------------------
------------------------------------------------------------------------------



------------------------------------------------------------------------------
--------------BEGIN Keyword help----------------------------------------------
------------------------------------------------------------------------------
--/ If this is a keyword search (either because @Keyword=1, or because we couldn't
--/ find a topic by that name), provide a list of topics that have that keyword
--/ in the title or the text.
	IF @Keyword = 1
		OR
		(
			@Module IS NOT NULL
			AND @Name IS NOT NULL
			AND NOT EXISTS
	(
		SELECT *
		FROM Minion.HELPObjectDetail OD
			INNER JOIN Minion.HELPObjects O
				ON OD.ObjectID = O.ID
		WHERE O.Module = @Module
				AND LOWER(O.ObjectName) = LOWER(@Name)
	)
		)
	BEGIN --Keyword

		SET @Name = '%' + @Name + '%';

		CREATE TABLE #KeywordTopic
		(
			Module VARCHAR(100),
			ObjectName VARCHAR(100),
			ObjectType VARCHAR(100),
			GlobalPosition INT
		);

		-- Get the list of topics with the keyword in the title:
		INSERT INTO #KeywordTopic
		(
			Module,
			ObjectName,
			ObjectType,
			GlobalPosition
		)
		SELECT DISTINCT
			Module,
			ObjectName,
			ObjectType,
			GlobalPosition
		FROM Minion.HELPObjects
		WHERE GlobalPosition IS NOT NULL
				AND ObjectName LIKE @Name;

		-- Get the list of topics with the keyword in the body:
		INSERT INTO #KeywordTopic
		(
			Module,
			ObjectName,
			ObjectType,
			GlobalPosition
		)
		SELECT DISTINCT
			O.Module,
			O.ObjectName,
			O.ObjectType,
			O.GlobalPosition
		FROM Minion.HELPObjects AS O
			INNER JOIN Minion.HELPObjectDetail AS OD
				ON O.ID = OD.ObjectID
		WHERE O.GlobalPosition IS NOT NULL
				AND
				(
					OD.DetailHeader LIKE @Name
					OR OD.DetailText LIKE @Name
				);

		IF @Module IS NOT NULL
			DELETE FROM #KeywordTopic
			WHERE Module <> @Module;

		IF @Module IS NOT NULL
			PRINT 'Module: ' + UPPER(@Module);


		-- Print intro material:
		PRINT 'The following topics have the specified keyword in the title or body:';
		PRINT '';
		PRINT 'Section' + REPLICATE(' ', 100 - LEN('Section')) + 'ObjectType';
		PRINT '';

		-- Print each topic title:
		DECLARE TopLevelHelp CURSOR READ_ONLY
		FOR
		SELECT ObjectName,
			ObjectType
		FROM #KeywordTopic
		GROUP BY ObjectName,
			ObjectType
		ORDER BY MIN(GlobalPosition) ASC;

		OPEN TopLevelHelp;

		FETCH NEXT FROM TopLevelHelp
		INTO @currObjectName,
			@ObjectType;
		WHILE (@@fetch_status <> -1)
		BEGIN

			PRINT @currObjectName + REPLICATE(' ',
													100 - LEN(@currObjectName)
												) + @ObjectType;

			FETCH NEXT FROM TopLevelHelp
			INTO @currObjectName,
				@ObjectType;
		END;

		CLOSE TopLevelHelp;
		DEALLOCATE TopLevelHelp;
		DROP TABLE #KeywordTopic;

		EXEC Minion.HELPbanner;

		PRINT '';
		PRINT '';
		PRINT '';

		PRINT 'Using Minion.HELP';
		PRINT '-----------------';
		PRINT '';
		PRINT 'Minion.HELP parameters: ';
		PRINT '    @Module - The name of the module, e.g. Backup, Reindex, CheckDB.';
		PRINT '    @Name - The specific name of the topic, or a keyword to search for.';
		PRINT '    @Keyword - Bit that forces @Name to behave as a keyword. Optional; if Minion.HELP does not find a topic named @Name, it will perform the keyword search anyway.';
		PRINT '';
		PRINT 'Examples: ';
		PRINT '';
		PRINT '    -- Get a list of installed modules.';
		PRINT '	EXEC Minion.HELP;';
		PRINT '';
		PRINT '	-- Get a list of topics for the Backup modules.';
		PRINT '	EXEC Minion.HELP ''Backup'';';
		PRINT '';
		PRINT '	-- Get the help topic ''Quick start'' for the CheckDB module.';
		PRINT '	EXEC Minion.HELP ''CheckDB'', ''Quick Start'';';
		PRINT '';
		PRINT '	-- Find all topis with the exact phrase ''remote CheckDB'' in the text or title:';
		PRINT '	EXEC Minion.HELP ''CheckDB'', ''remote CheckDB'';';
		PRINT '	EXEC Minion.HELP ''CheckDB'', ''remote CheckDB'', 1; -- Same thing, with @Keyword=1';
		PRINT ' ';
		PRINT 'For searchable online documentation, see http://MinionWare.Desk.com';
		PRINT 'For the most up to date version of this documentation, see http://www.MinionWare.net';
		PRINT ' ';
		PRINT '* By running this software you are agreeing to the terms of the license agreement.';
		PRINT '* You can find a copy of the license agreement here: http://www.MinionWare.net/wp-content/uploads/MinionModulesLicenseAgreement.pdf';

		RETURN;
	END; --Keyword
------------------------------------------------------------------------------
--------------END Keyword help------------------------------------------------
------------------------------------------------------------------------------


------------------------------------------------------------------------------
--------------BEGIN Topic help------------------------------------------------
------------------------------------------------------------------------------
----/ This prints the details for a particular sections (topic). This section runs for EXEC Minion.Help 'Reindex', 'FAQ';

	IF @Module IS NOT NULL
		AND @Name IS NOT NULL 
		AND EXISTS
		(
			SELECT *
			FROM Minion.HELPObjectDetail OD
				INNER JOIN Minion.HELPObjects O
					ON OD.ObjectID = O.ID
			WHERE O.Module = @Module
					AND LOWER(O.ObjectName) = LOWER(@Name)
		)
		BEGIN --Objects

			SET @colCT = 0;

			DECLARE HelpText CURSOR READ_ONLY
			FOR
				 SELECT O.ObjectType,
					O.ObjectName,
					OD.DetailName,
					OD.Position,
					OD.DetailType,
					OD.DetailHeader,
					OD.DetailText,
					OD.DataType
				FROM	Minion.HELPObjectDetail OD
						INNER JOIN Minion.HELPObjects O ON OD.ObjectID = O.ID
				WHERE	O.Module = @Module
						AND O.ObjectName = @Name
				ORDER BY Position ASC;

			OPEN HelpText;

		FETCH NEXT FROM HelpText
		INTO @ObjectType,
			@ObjectName,
			@DetailName,
			@Position,
			@DetailType,
			@DetailHeader,
			@DetailText,
			@DataType;


		---- First things first: print the heading
		PRINT '';
		PRINT @ObjectName;
		PRINT REPLICATE('_', LEN(@ObjectName));
		PRINT '';
				
			WHILE ( @@fetch_status <> -1 ) 
				BEGIN

					-------------------------------------------------------------
					------BEGIN ObjectType='Information' ------------------------
					-------------------------------------------------------------
					IF @ObjectType = 'Information' 
						BEGIN 

							--IF @DetailHeader NOT LIKE 'Troubleshoot:%' 
							--	BEGIN --TShoot Header

							--		SET @colWidth = 100;
							--		SET @DetailText = Minion.HELPformat(@DetailText, @colWidth, 0);
										
							--	END --TShoot Header

							-- If the detail header isn't 'ObjectName', it must be a subheading, so we print it.
							IF @DetailHeader <> 'ObjectName' 
								BEGIN
									PRINT ''
									PRINT @DetailHeader
									PRINT REPLICATE('-', LEN(@DetailHeader))
								END

							-- This is straight information (no special table of columns or params), so we just print it.
							IF @DetailType <> 'ObjectName' 
								BEGIN
									SET @colWidth = 100;
									SET @DetailText = Minion.HELPformat(@DetailText, @colWidth, 0);

									PRINT @DetailText;
								END

						END --Information
					-------------------------------------------------------------
					------END ObjectType='Information' ------------------------
					-------------------------------------------------------------

					-------------------------------------------------------------
					------BEGIN ObjectType='Procedure' --------------------------
					-------------------------------------------------------------
					IF @ObjectType = 'Procedure' 
						OR @ObjectType = 'Function'
						BEGIN --ObjectType

							------ Print the section header, if a separate entry for it exists
							--IF @DetailType = 'ObjectName' 
							--	BEGIN
							--		PRINT @DetailText 
							--		PRINT REPLICATE('-', LEN(@DetailText))

							--	END
							
							---- Print the parameter
							IF @DetailType = 'Param' 
								BEGIN

									SET @colCT = @colCT + 1;
									IF @colCT = 1 
										BEGIN
											PRINT 'Parameter' + REPLICATE(' ',
															  30
															  - LEN('Parameter'))

												+ 'Data Type' + REPLICATE(' ',
															  48
															  - LEN('Parameter'
															  + 'Data Type'))
												+ 'Definition'
											PRINT '---------' + REPLICATE(' ',
															  30
															  - LEN('Parameter'))
												+ '----------' + REPLICATE(' ',
															  47
															  - LEN('Parameter'
															  + 'Data Type'))
												+ '----------'
										END
									SET @DataTypeSpacer = REPLICATE(' ',
															  30
															  - LEN(@DetailName));

									---- Replace newlines with spacer+newline, to format detail text: ----
									SET @DetailTextSpacer = char(13) + REPLICATE(' ', 69) ; -- for newlines.

									-- Replace line feeds with carriage returns
									SET @DetailText = REPLACE(@DetailText, char(10), char(13));
									
									-- Replace double carriage returns with single
									SET @DetailText = REPLACE(@DetailText, char(13)+char(13), char(13));

									-- Add a spacer after the carriage return
									SET @DetailText = REPLACE(@DetailText, char(13), @DetailTextSpacer);

									PRINT @DetailName + REPLICATE(' ', 30 - LEN(@DetailName))
										+ @DataType + REPLICATE(' ', 39 - LEN( @DataType))
										+  LTRIM(ISNULL(Minion.HELPformat(@DetailText, 100, 69), '')); 

									---- New spacer between params, MC 1.0 / MB 1.3
									PRINT '____________________________________________________________________________________________________________________________________________________________';
									PRINT '';

								END

							IF @DetailType <> 'Param'
								AND @DetailType <> 'ObjectName' 
								BEGIN
									-- Print the header/text for Purpose, Important, Discussion, Examples, etc.
									PRINT @DetailHeader
									PRINT REPLICATE('-', LEN(@DetailHeader))
									SET @DetailText = Minion.HELPformat(@DetailText,130, 0);
									PRINT @DetailText
									PRINT ''
								END
						END --ObjectType
					-------------------------------------------------------------
					------END ObjectType='Procedure' ----------------------------
					-------------------------------------------------------------
					
					
					-------------------------------------------------------------
					------BEGIN DetailType='Advice' ----------------------------
					-------------------------------------------------------------
					IF @DetailType = 'Advice' 
						BEGIN
							PRINT @DetailHeader
							PRINT @DetailText
						END
					-------------------------------------------------------------
					------END DetailType='Advice' ----------------------------
					-------------------------------------------------------------


					-------------------------------------------------------------
					------BEGIN ObjectType='Table' ------------------------------
					-------------------------------------------------------------
					IF @ObjectType = 'Table' 
						OR @ObjectType = 'View'
						BEGIN --Table

							IF @DetailType = 'ObjectName' 
								BEGIN
									PRINT @DetailText 
									PRINT REPLICATE('-', LEN(@DetailText))

								END

--------
							IF @DetailHeader <> 'Column'
								AND @DetailType <> 'Column'
								AND @DetailType <> 'ObjectName' 
								BEGIN

									-- Print the header/text for Purpose, Important, Discussion, Examples, etc.
									PRINT @DetailHeader
									PRINT REPLICATE('-', LEN(@DetailHeader))
									SET @DetailText = Minion.HELPformat(@DetailText,130, 0);
									PRINT @DetailText
									PRINT ''

								END
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
---------------------BEGIN Table Cols-----------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
							IF @DetailType = 'Column' 
								BEGIN --Column
											
									SET @colCT = @colCT + 1;
									-- If this is the first column to print, print out table headers first:
									IF @colCT = 1 
										BEGIN
											PRINT 'Column Name'
												+ REPLICATE(' ',
															40
															- LEN('Column Name'))
												+ 'Data Type' + REPLICATE(' ',
															  40
															  - LEN('Column Name'
															  + 'Data Type'))
												+ 'Definition'
											PRINT '-----------'
												+ REPLICATE(' ',
															40
															- LEN('Column Name'))
												+ '---------' + REPLICATE(' ',
															  40
															  - LEN('Column Name'
															  + 'Data Type'))
												+ '----------'
										END

									/* Discussion: Formatting text within ASCII "tables". There's a bunch we have to do.
										- First, put in proper carriage returns (not line feeds).
										- Next, take double carriage returns down to single.
										- Then, for every carriage return, turn it into a carriage return PLUS
											a string of spaces, so the next text lines up properly, like this:

											Col1	Col2
											xyz	xyz xyz xyz xyz xyz xyz xyz 
												xyz xyz xyz.

											THEN we have to make sure that long strings break properly. This gets 
											tricky, because we're counting characters, BUT we also have to deal with
											the carriage breaks inside them. Right now I'm seeing this problem:
											Col1	Col2
											xyz	xyz xyz xyz xyz xyz xyz xyz 
												xyz xyz xyz.

												xyz xyz
												xyz xyz xyz xyz xyz xyz.
											Haven't fixed it yet.
									. */

									---- Replace newlines with spacer+newline, to format detail text: ----
									SET @DetailTextSpacer = char(13) + REPLICATE(' ', 69) ; -- for newlines.

									-- Replace line feeds with carriage returns
									SET @DetailText = REPLACE(@DetailText, CHAR(10), CHAR(13));

									-- Replace double carriage returns with single
									SET @DetailText = REPLACE(@DetailText, CHAR(13)+CHAR(13), CHAR(13));
									
									-- Add a spacer after the carriage return
									SET @DetailText = REPLACE(@DetailText, CHAR(13), @DetailTextSpacer);
									
									PRINT @DetailName + REPLICATE(' ', 40 - LEN(@DetailName))
										+ @DataType + REPLICATE(' ', 29 - LEN( @DataType))
										+ LTRIM(ISNULL(Minion.HELPformat(@DetailText, 100, 69), '')); 
					
									---- New spacer between columns, MC 1.0 / MB 1.3
									PRINT '____________________________________________________________________________________________________________________________________________________________';
									PRINT '';

								END --Column
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
---------------------END Table Cols-------------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
						END --Table
					-------------------------------------------------------------
					------END ObjectType='Table' ------------------------------
					-------------------------------------------------------------

					FETCH NEXT FROM HelpText
					INTO @ObjectType,
						@ObjectName,
						@DetailName,
						@Position,
						@DetailType,
						@DetailHeader,
						@DetailText,
						@DataType;

				END

			CLOSE HelpText
			DEALLOCATE HelpText

		END --Objects
------------------------------------------------------------------------------
--------------END Topic help--------------------------------------------------
------------------------------------------------------------------------------

	PRINT '_____';
	PRINT 'For searchable online documentation, see http://MinionWare.Desk.com';
	PRINT 'For the most up to date version of this documentation, see http://www.MinionWare.net';
	PRINT ' ';
	PRINT '* By running this software you are agreeing to the terms of the license agreement.';
	PRINT '* You can find a copy of the license agreement here: http://www.MinionWare.net/wp-content/uploads/MinionModulesLicenseAgreement.pdf';

RETURN 0;
GO
