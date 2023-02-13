SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [Minion].[HELPformat]
	(
	  @DetailText VARCHAR(MAX) ,
	  @colWidth TINYINT , 
	  @Indent TINYINT
	)
RETURNS VARCHAR(MAX)
AS 
	BEGIN
		DECLARE	@left NVARCHAR(4000) ,
			@breakPos TINYINT ,
			@hasbreak BIT ,
			@outStr VARCHAR(MAX), 
			@spacer VARCHAR(1000);

		SET @spacer = ISNULL(REPLICATE(' ', @Indent), '');

		SET @outStr = '';

		IF LEN(@DetailText) <= @colWidth 
			SET @outStr = @spacer + @DetailText;

		WHILE 1 = 1
			AND LEN(@DetailText) > @colWidth 
			BEGIN
				SET @hasbreak = 0;

				--*-- Find the last space (or the first line break) in the current 100 characters:  
				SET @left = LEFT(@DetailText, @colWidth);
				SET @breakPos = 1 + CHARINDEX(CHAR(13) + CHAR(10), @left); 

				IF @breakPos = 1 
					SET @breakPos = @colWidth + 1 - ( CHARINDEX(' ',
															  REVERSE(@left)) );
				ELSE 
					SET @hasbreak = 1;
											
				--*-- Set @left to the first 100 characters or so, ending at the last space:
				SET @left = LEFT(@DetailText, @breakPos);

				--*-- Add the string to @outStr. And, Remove the @left string from @DetailText:
				IF @hasbreak = 1 
					BEGIN
						SET @outStr = @outStr + @spacer + @left;
						SET @DetailText = RIGHT(@DetailText,
												LEN(@DetailText) - @breakPos
												+ 1);
					END
				ELSE 
					BEGIN
						SET @outStr = @outStr + @spacer + @left + CHAR(13) + +CHAR(10);
						SET @DetailText = LTRIM(RIGHT(@DetailText,
												LEN(@DetailText) - @breakPos + 1)); -- picky line...
					END

				--*-- Add the very last line:
				IF LEN(@DetailText) <= @colWidth 
					BEGIN
						SET @outStr = @outStr + @spacer + @DetailText;       
						BREAK;
					END
		
			END

		RETURN @outStr;

	END
    
GO
