SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Minion].[DBMaintInlineTokenParse]
(
@DBName VARCHAR(400),
@DynamicName VARCHAR(400) OUTPUT,
@Ordinal VARCHAR(2) = NULL,
@NumFiles VARCHAR(2) = NULL,
@ServerLabel VARCHAR(150) = NULL,
@BackupType VARCHAR(4) = NULL,
@ExecutionDateTime DATETIME = NULL
)

AS

/***********************************************************************************

Created By: MinionWare LLC. and MidnightDBA.com

Minion CheckDB is a free, standalone, integrity check routine that is a component 
of the Minion Enterprise management solution. Home base: http://MinionWare.net/CheckDB

Minion Enterprise is an enterprise management solution that makes managing your 
SQL Server enterprise super easy. The CheckDB routine folds into the enterprise 
solution with ease.  By integrating your integration checks into the Minion 
Enterprise, you get the ability to manage your configuration from a central 
location. And, Minion Enterprise provides enterprise-level reporting and alerting.
Download a 30-day trial of Minion Enterprise at http://MinionWare.net


For SQL Server consulting, see our website http://www.MidnightSQL.com
No job is too big or too small.

Also, check out our FREE SQL Server training videos at http://www.MidnightDBA.com

This is a big routine with many nuances.  Our documentation is complete, but if 
you prefer, we also have videos that show you how to use each of the features.
You can find them at http://www.MidnightDBA.com/Minion

* By running this software you are agreeing to the terms of the license agreement.
* You can find a copy of the license agreement here: http://www.midnightsql.com/minion-end-user-license-agreement/
--------------------------------------------------------------------------------

HELP: For information on parameters and more, see the documentation at
                  http://www.MinionWare.net/CheckDB, or with the product download, or use
                
                EXEC Minion.HELP 'CHECKDB', 'Minion.DBMaintInlineTokenParse';


PURPOSE: 


WALKTHROUGH: 
      1. 


CONVENTIONS:
    
    
TABLES: 
                

EXAMPLE EXECUTIONS:
   [Minion].[DBMaintInlineTokenParse] 'Minion', '%DBName%-CheckDBRestore-From-%Server%-%Date%', NULL, NULL, 'SeansLabel', 'Full', NULL
   [Minion].[DBMaintInlineTokenParse] 'Minion', 'C:\SQLBackups\%DBName%\%BackupType%\Archives\%Year%\%MonthName%', NULL, NULL, NULL, 'Full', NULL

REVISION HISTORY:
                

--***********************************************************************************/ 


----The @RemoteRestoreMode is important here.  If the RestoreMode is NONE, then that means you don't want to take a backup on the remote system because you've already
----got a DB on the remote system you want to run the checkdb on.  In that case, @PreferredDBName is the name of the DB that already exists.  It can either be a wildcar
----that stands for the latest DB that matches the pattern, or it can be a static DBName.  However, here you're asking to restore the latest MB backup.
----Therefore, to make things easy to manage, you need to give either a DBName, or you can give a DB naming convention.
----Currently, it allows for some form of DBName, followed by some identifier, followed by a date.  These are all optional.
----An example is to set PreferredDBName in CheckDBSettingsDB to %DBName%-CheckDB-%Date%.  In this case, %DBName% will be replaced with the name of the current DB,
----and %Date% will be replaced with today's date in yyyyMD format.  So the final R@PreferredDBName for the current DBName of DB1 would be DB1-CheckDB-20161123, for example.
----You're free to change the order of the dynamic params or any static text as you like.  However, the only dynamic params currently supported are %DBName% and %Date%.
----Anything else will be treated as static text.  This is to allow you to have a dynamically-created DBName each time w/o having to manage the names yourself.

/*
Syntax currently supported:
SELECT * from Minion.DBMaintInlineTokens;

Built-in params vs. Custom params:
Built-in params are surrounded with %% while custom params are surrounded with ||.
You can build your own custom params in the table but they can only return a single value. Here's an example of a string that has static values, built-in params, and custom.
'C:\SQLBackups\%Server%\%DBName%\|MyCustomParam|\Archive\'

Code help:
After each section we set @DynamicResult = ''.
This is to help with inactive values.  If a dynamic value is in the string but not active or present in the table, then the previous value still stands and will be printed twice.
So to help with that, we reset this param to '' so that the value just doesn't show up in the final string.
*/

SET NOCOUNT ON;
DECLARE @DynamicResult NVARCHAR(50),
		@DynamicCMD NVARCHAR(1000),
		@DynamicVar VARCHAR(400);


IF @ExecutionDateTime IS NULL
	BEGIN
		SET @ExecutionDateTime = GETDATE();
	END

		IF @DynamicName LIKE '%\%%' ESCAPE '\'
	BEGIN

		----DBName
		IF @DynamicName LIKE '%\%DBName\%%' ESCAPE '\'
			BEGIN				
				SET @DynamicName = REPLACE(@DynamicName, '%DBName%', @DBName);--
			END 
--SELECT @DynamicName
		----Ordinal
		IF @DynamicName LIKE '%\%Ordinal\%%' ESCAPE '\'
			BEGIN				
				SET @DynamicName = REPLACE(@DynamicName, '%Ordinal%', ISNULL(@Ordinal, ''));
			END 

		----NumFiles
		IF @DynamicName LIKE '%\%NumFiles\%%' ESCAPE '\'
			BEGIN				
				SET @DynamicName = REPLACE(@DynamicName, '%NumFiles%', ISNULL(@NumFiles, ''));
			END 

		----BackupType
		IF @DynamicName LIKE '%\%BackupType\%%' ESCAPE '\'
			BEGIN				
				SET @DynamicName = REPLACE(@DynamicName, '%BackupType%', ISNULL(@BackupType, ''));--
			END

		----ServerORServerLabel (SoSL)
		IF @DynamicName LIKE '%\%SoSL\%%' ESCAPE '\'
			BEGIN	
				SET @DynamicName = REPLACE(@DynamicName, '%Server%', '');	
				SET @DynamicName = REPLACE(@DynamicName, '%ServerLabel%', '');	
				SET @DynamicName = REPLACE(@DynamicName, '%SoSL%', ISNULL(@ServerLabel, ''));	
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END 

		----Server
		IF @DynamicName LIKE '%\%Server\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'Server');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@DynamicResult varchar(400) OUTPUT', @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%Server%', @DynamicResult);
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END 

		----ServerLabel
		IF @DynamicName LIKE '%\%ServerLabel\%%' ESCAPE '\'
			BEGIN
				SET @DynamicName = REPLACE(@DynamicName, '%ServerLabel%', ISNULL(@ServerLabel, ''));
			END 

		----Instance
		IF @DynamicName LIKE '%\%Instance\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'Instance');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@DynamicResult varchar(400) OUTPUT', @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%Instance%', ISNULL(@DynamicResult, ''));
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END 
--SELECT @DynamicName
		----Date
		IF @DynamicName LIKE '%\%Date\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'Date');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@ExecutionDateTime datetime, @DynamicResult varchar(400) OUTPUT', @ExecutionDateTime = @ExecutionDateTime, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%Date%', @DynamicResult);
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END 
--SELECT @DynamicName
		----Year
		IF @DynamicName LIKE '%\%Year\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'Year');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@ExecutionDateTime datetime, @DynamicResult varchar(400) OUTPUT', @ExecutionDateTime = @ExecutionDateTime, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%Year%', @DynamicResult);
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END 

		----Month
		IF @DynamicName LIKE '%\%Month\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'Month');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@ExecutionDateTime datetime, @DynamicResult varchar(400) OUTPUT', @ExecutionDateTime = @ExecutionDateTime, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%Month%', @DynamicResult);
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END 

		----MonthName
		IF @DynamicName LIKE '%\%MonthName\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'MonthName');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@ExecutionDateTime datetime, @DynamicResult varchar(400) OUTPUT', @ExecutionDateTime = @ExecutionDateTime, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%MonthName%', @DynamicResult);
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END 

		----Day
		IF @DynamicName LIKE '%\%Day\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'Day');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@ExecutionDateTime datetime, @DynamicResult varchar(400) OUTPUT', @ExecutionDateTime = @ExecutionDateTime, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%Day%', @DynamicResult);
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END

		----DayName
		IF @DynamicName LIKE '%\%DayName\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'DayName');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@ExecutionDateTime datetime, @DynamicResult varchar(400) OUTPUT', @ExecutionDateTime = @ExecutionDateTime, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%DayName%', @DynamicResult);
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END

		----Time
		IF @DynamicName LIKE '%\%Time\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'Time');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@ExecutionDateTime datetime, @DynamicResult varchar(400) OUTPUT', @ExecutionDateTime = @ExecutionDateTime, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%Time%', @DynamicResult);
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END

		----Hour
		IF @DynamicName LIKE '%\%Hour\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'Hour');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@ExecutionDateTime datetime, @DynamicResult varchar(400) OUTPUT', @ExecutionDateTime = @ExecutionDateTime, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%Hour%', @DynamicResult);
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END

		----Minute
		IF @DynamicName LIKE '%\%Minute\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'Minute');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@ExecutionDateTime datetime, @DynamicResult varchar(400) OUTPUT', @ExecutionDateTime = @ExecutionDateTime, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%Minute%', @DynamicResult);
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END


		----Second
		IF @DynamicName LIKE '%\%Second\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'Second');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@ExecutionDateTime datetime, @DynamicResult varchar(400) OUTPUT', @ExecutionDateTime = @ExecutionDateTime, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%Second%', @DynamicResult);
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END
 

		----MilliSecond
		IF @DynamicName LIKE '%\%MilliSecond\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'MilliSecond');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@ExecutionDateTime datetime, @DynamicResult varchar(400) OUTPUT', @ExecutionDateTime = @ExecutionDateTime, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%MilliSecond%', @DynamicResult);
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END


		----AGName
		IF @DynamicName LIKE '%\%AGName\%%' ESCAPE '\'
			BEGIN		
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'AGName');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@DBName varchar(400), @DynamicResult varchar(400) OUTPUT', @DBName = @DBName, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%AGName%', ISNULL(@DynamicResult, ''));
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END
 

		----BackupTypeExtension
		IF @DynamicName LIKE '%\%BackupTypeExtension\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'BackupTypeExtension');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@BackupType varchar(4), @DynamicResult varchar(400) OUTPUT', @BackupType = @BackupType, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%BackupTypeExtension%', ISNULL(@DynamicResult, ''));
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END


		----SMKExtension
		IF @DynamicName LIKE '%\%SMKExtension\%%' ESCAPE '\'
			BEGIN		
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'SMKExtension');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@BackupType varchar(4), @DynamicResult varchar(400) OUTPUT', @BackupType = @BackupType, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%SMKExtension%', ISNULL(@DynamicResult, ''));
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END


		----ServerCertExtension
		IF @DynamicName LIKE '%\%ServerCertExtension\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'ServerCertExtension');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@BackupType varchar(4), @DynamicResult varchar(400) OUTPUT', @BackupType = @BackupType, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%ServerCertExtension%', ISNULL(@DynamicResult, ''));
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END

		----DBCertExtension
		IF @DynamicName LIKE '%\%DBCertExtension\%%' ESCAPE '\'
			BEGIN			
				SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintInlineTokens WHERE IsActive = 1 AND DynamicName = 'DBCertExtension');
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @DynamicCMD;
                EXEC sp_executesql @DynamicCMD, N'@BackupType varchar(4), @DynamicResult varchar(400) OUTPUT', @BackupType = @BackupType, @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '%DBCertExtension%', ISNULL(@DynamicResult, ''));
				SET @DynamicResult = ''; --This is to help with values not being active.  See flower box for details.
			END

	END

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------BEGIN Custom Params-----------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

IF @DynamicName LIKE '%|%'
	BEGIN --DynamicName


DECLARE @start INT
      , @end INT
      , @word VARCHAR(2000)
	  , @DynamicNameORIG VARCHAR(400);

SET @DynamicNameORIG = @DynamicName;

DECLARE @WordTable TABLE ( Word VARCHAR(500) );

WHILE LEN(@DynamicName) > 0
      AND @DynamicName LIKE '%|%'
      BEGIN

			-- Find the first mark
			-- Find the second mark
            SET @start = ISNULL(NULLIF(CHARINDEX('|', @DynamicName) - 1, -1),LEN(@DynamicName));
            SET @end = ISNULL(NULLIF(CHARINDEX('|', @DynamicName, @start + 2), 0),LEN(@DynamicName));

			-- Isolate the word between
            SET @word = SUBSTRING(@DynamicName, @start + 1, @end - @start - 1);
					
			-- Shorten the string up to the end mark
			SET @DynamicName = RIGHT(@DynamicName, LEN(@DynamicName) - @end);
	
			-- Insert to table:
            INSERT  INTO @WordTable
                    ( Word )
            VALUES  ( @word );
      END;

-- Get rid of the remaining pipes: 
UPDATE  @WordTable
SET     Word = REPLACE(Word, '|', ''); 

--SELECT  Word
--FROM    @WordTable;
SET @DynamicName = @DynamicNameORIG;

DECLARE @currDynamicName varchar(100),
		@currParseMethod varchar(1000),
		@currCheckValue VARCHAR(100)

DECLARE CustomParams CURSOR
READ_ONLY
FOR SELECT Word
FROM    @WordTable

OPEN CustomParams

	FETCH NEXT FROM CustomParams INTO @currDynamicName
	WHILE (@@fetch_status <> -1)
	BEGIN

		SET @currParseMethod = (SELECT ParseMethod FROM Minion.DBMaintInlineTokens WHERE DynamicName = @currDynamicName AND IsCustom = 1 AND IsActive = 1)
		SET @currCheckValue = '%|' + @currDynamicName + '|%'
		--IF @DynamicName LIKE '%|MonthDay|%'
			BEGIN			
				--SET @DynamicCMD = (SELECT TOP 1 ParseMethod FROM Minion.DBMaintDynamicParts WHERE IsActive = 1 AND DynamicName = @currDynamicName);
				SET @DynamicCMD = N'SELECT @DynamicResult = ' + @currParseMethod;
                EXEC sp_executesql @DynamicCMD, N'@DynamicResult varchar(400) OUTPUT', @DynamicResult = @DynamicResult OUTPUT
				SET @DynamicName = REPLACE(@DynamicName, '|' + @currDynamicName + '|', ISNULL(@DynamicResult, ''));
			END
		
FETCH NEXT FROM CustomParams INTO @currDynamicName
	END

CLOSE CustomParams
DEALLOCATE CustomParams

	END --DynamicName
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------END Custom Params-------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

SET @DynamicName = REPLACE(@DynamicName, '\\', '\');
--SELECT @DynamicName
GO
