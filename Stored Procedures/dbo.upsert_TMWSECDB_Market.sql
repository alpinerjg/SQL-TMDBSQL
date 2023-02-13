SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[upsert_TMWSECDB_Market] 
	 @Timestamp datetime ,
	 @symbol varchar(15) ,
	 @longrate real= NULL ,
	 @shortrate real= NULL ,
	 @longmark float= NULL ,
	 @shortmark float= NULL

AS
	BEGIN
			-- https://stackoverflow.com/questions/52971604/update-only-rows-that-does-not-match-rows-from-another-table
			--
			-- Any records that no longer are in staging should get closed out
			--

			UPDATE t1 
			SET t1.ts_end = @Timestamp
			FROM [TMDBSQL].[dbo].[TMWSECDB_Market] t1
			LEFT JOIN [TMDBSQL].[dbo].[TMWSECDB_staging] t2 ON t2.symbol = t1.symbol
			WHERE t1.ts_end IS NULL and t2.[symbol] IS NULL

			BEGIN TRANSACTION
				IF EXISTS(SELECT 1 FROM [TMDBSQL].[dbo].[TMWSECDB_Market] WHERE [symbol] = @symbol AND ts_end IS NULL)
					BEGIN
						PRINT 'upsert_TMWSECDB_Market("' + CAST(@symbol AS VARCHAR) + '") a current record exists'

						-- We need to figure out if the records are different
						DECLARE @StagingData NVARCHAR(MAX) = CONCAT_WS('|', 
								@symbol ,
								@longrate ,
								@shortrate ,
								@longmark ,
								@shortmark
										)

						DECLARE @ActualData  NVARCHAR(MAX)	

						SELECT @ActualData = CONCAT_WS('|', 
								[symbol] ,
								[longrate] ,
								[shortrate] ,
								[longmark] ,
								[shortmark] )
							FROM [TMDBSQL].[dbo].[TMWSECDB_Market] 
							WHERE (symbol = @symbol AND ts_end IS NULL)
	
						DECLARE @StagingDataHash NVARCHAR(64) = HASHBYTES('SHA2_256',@StagingData)
						DECLARE @ActualDataHash  NVARCHAR(64) = HASHBYTES('SHA2_256',@ActualData)
				
						PRINT 'DBG: upsert_TMWSECDB_Market("' + CAST(@symbol AS VARCHAR) + '") @StagingDataHash = ' + @StagingDataHash 
						PRINT 'DBG: upsert_TMWSECDB_Market("' + CAST(@symbol AS VARCHAR) + '") @ActualDataHash = ' + @ActualDataHash
						PRINT @StagingData
						PRINT @ActualData
		
						IF @StagingDataHash <> @ActualDataHash
							BEGIN
								PRINT 'upsert_TMWSECDB_Market("' + CAST(@symbol AS VARCHAR) + '") - Giant OR failed'
								PRINT 'DBG: upsert_TMWSECDB_Market("' + CAST(@symbol AS VARCHAR) + '") @StagingDataHash = ' + @StagingDataHash 
								PRINT 'DBG: upsert_TMWSECDB_Market("' + CAST(@symbol AS VARCHAR) + '") @ActualDataHash = ' + @ActualDataHash
								PRINT @StagingData
								PRINT @ActualData

								UPDATE [TMDBSQL].[dbo].[TMWSECDB_Market] WITH (SERIALIZABLE)
									SET
										ts_end = @Timestamp
								WHERE
										symbol = @symbol AND ts_end IS NULL

								INSERT INTO [TMDBSQL].[dbo].[TMWSECDB_Market]
									(	
												[symbol] ,
												[ts_start] ,
												[ts_end] ,
												[longrate] ,
												[shortrate] ,
												[longmark] ,
												[shortmark]
										)
								VALUES
									(	@symbol ,
										@Timestamp ,
										NULL ,
										@longrate ,
										@shortrate ,
										@longmark ,
										@shortmark
									)

								-- SET @return_status = 1
							END
						ELSE
							PRINT 'DBG: upsert_TMWSECDB_Market("' + CAST(@symbol AS VARCHAR) + '") No change'
					END
				ELSE
					BEGIN
					 -- Completely new record
						PRINT 'upsert_TMWSECDB_Market("' + CAST(@symbol AS VARCHAR) + '") - New record'

						INSERT INTO [TMDBSQL].[dbo].[TMWSECDB_Market]
						(	
									[symbol] ,
									[ts_start] ,
									[ts_end] ,
									[longrate] ,
									[shortrate] ,
									[longmark] ,
									[shortmark]
							)
						VALUES
							(	@symbol ,
								@Timestamp ,
								NULL ,
								@longrate ,
								@shortrate ,
								@longmark ,
								@shortmark 
								)

					END
				
			COMMIT TRANSACTION
	END
 
GO
