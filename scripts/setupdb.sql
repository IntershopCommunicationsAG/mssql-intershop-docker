CREATE OR ALTER PROC createIcmDB
 @DBName SYSNAME, /* required */
 @UserID SYSNAME, /* required */
 @Password NVARCHAR(128), /* required */
 @RecreateDB BIT = 0, /* recreate database if existing */
 @RecreateUser BIT = 0, /* recreate used of existing */
 @DataPath NVARCHAR(MAX) = NULL, /* data file(s) location */
 @LogPath NVARCHAR(MAX) = NULL, /* log file location */
 @NumberDataFiles INT = 1, /* Number of used data files, default is 1 */
 @Recovery NVARCHAR(30) = 'FULL' /* Recovery Model, Possible values: FULL, SIMPLE, BULK_LOGGED, default is FULL*/
AS
BEGIN
 DECLARE @Sql NVARCHAR(MAX),
 @SqlFiles NVARCHAR(MAX) = '',
 @Looper int = 1,
 @FileEnding NVARCHAR(10),
 @tempDBName SYSNAME,
 @CurrentDBUser SYSNAME;

 -- check owner of existing database
 SELECT @CurrentDBUser = SUSER_SNAME(owner_sid) FROM sys.databases WHERE name = @DBName
 IF db_id(@DBName) IS NOT NULL AND @CurrentDBUser != @UserID
 BEGIN
 print 'Cannot delete database of foreign user. Database ''' + @DBName + ''' is owned by ' + QUOTENAME(@CurrentDBUser)
 RETURN
 END

 IF @DataPath IS NULL
 SET @DataPath = CONVERT(NVARCHAR(MAX), SERVERPROPERTY('InstanceDefaultDataPath'));
 IF @LogPath IS NULL
 SET @LogPath = CONVERT(NVARCHAR(MAX), SERVERPROPERTY('InstanceDefaultLogPath'));

 -- Drop Database
 IF db_id(@DBName) IS NOT NULL AND @RecreateDB = 1
 BEGIN
 print 'Dropping existing connections to database: ' + QUOTENAME(@DBName);
 SET @Sql = 'ALTER DATABASE ' + QUOTENAME(@DBName) + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE';
 print 'Executing SQL: ' + @Sql;
 EXECUTE sp_executesql @Sql;
 
 print 'Dropping existing database: ' + QUOTENAME(@DBName);
 SET @Sql = 'DROP DATABASE ' + QUOTENAME(@DBName);
 print 'Executing SQL: ' + @Sql;
 EXECUTE sp_executesql @Sql;
 END;

 -- Drop Login
 IF EXISTS (SELECT 1 FROM [master].[sys].[server_principals] WHERE Name = @UserID) AND @RecreateUser = 1
 BEGIN
 print 'Dropping existing user: ' + QUOTENAME(@UserID);
 SET @Sql = 'DROP LOGIN ' + QUOTENAME(@UserID)
 print 'Executing SQL: ' + @Sql;
 EXECUTE sp_executesql @Sql;
 END;

 -- Create Login
 IF NOT EXISTS (SELECT 1 FROM [master].[sys].[server_principals] WHERE Name = @UserID)
 BEGIN
 print 'Creating user: ' + QUOTENAME(@UserID);
 SET @Sql = 'CREATE LOGIN
 ' + QUOTENAME(@UserID) + '
 WITH
 PASSWORD = ''' + REPLACE(@Password, '''', '''''') + '''
 , DEFAULT_DATABASE = [master]
 , DEFAULT_LANGUAGE = [us_english]
 , CHECK_EXPIRATION = OFF
 , CHECK_POLICY = OFF';
 print 'Executing SQL: ' + @Sql;
 EXECUTE sp_executesql @Sql;
 END;

 IF db_id(@DBName) IS NULL
 BEGIN
 print 'Creating database: ' + QUOTENAME(@DBName);
 SET @Sql = 'CREATE DATABASE
 ' + QUOTENAME(@DBName) + '
 CONTAINMENT = NONE
 ON PRIMARY '

 WHILE (@Looper <= @NumberDataFiles)
 BEGIN
 IF @Looper = 1
 SET @FileEnding = N'.mdf'
 ELSE
 SET @FileEnding = N'.ndf'

 IF @NumberDataFiles > 1
 SET @tempDBName = @DBName + CONVERT(varchar(10), @Looper)
 ELSE
 SET @tempDBName = @DBName

 SET @SqlFiles = @SqlFiles + '
 (NAME = ''' + @tempDBName + '''
 , FILENAME = ''' + CONCAT(@DataPath, N'\', @tempDBName, @FileEnding) + '''
 , SIZE = 8MB
 , MAXSIZE = UNLIMITED
 , FILEGROWTH = 64MB)'

 IF @Looper < @NumberDataFiles
 SET @SqlFiles = @SqlFiles + ', '

 SET @Looper = @Looper + 1
 END

 SET @Sql = @Sql + @SqlFiles

 SET @Sql = @Sql + '
 LOG ON (
 NAME = ''' + CONCAT(@DBName, N'_log') + '''
 , FILENAME = ''' + CONCAT(@LogPath, N'\', @DBName, N'_log.ldf') + '''
 , SIZE = 8MB
 , MAXSIZE = UNLIMITED
 , FILEGROWTH = 64MB )
 COLLATE Latin1_General_100_CI_AS';
 print 'Executing SQL: ' + @Sql;
 EXECUTE sp_executesql @Sql;
 END;

 IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
 BEGIN
 print 'Enabling full-text search...';
 SET @Sql = QUOTENAME(@DBName) + '.[dbo].[sp_fulltext_database] @action = ''enable''';
 print 'Executing SQL: ' + @Sql;
 EXECUTE sp_executesql @Sql;
 END;

 print 'Setting default database ...';
 SET @Sql = 'ALTER LOGIN ' + QUOTENAME(@UserID) + ' WITH DEFAULT_DATABASE = ' + QUOTENAME(@DBName);
 print 'Executing SQL: ' + @Sql;
 EXECUTE sp_executesql @Sql;

 print 'Setting database owner ...'
 SET @Sql = 'ALTER AUTHORIZATION ON DATABASE::' + QUOTENAME(@DBName) + ' TO ' +QUOTENAME(@UserID);
 print 'Executing SQL: ' + @Sql;
 EXECUTE sp_executesql @Sql;

 print 'Setting Read Committed Snapshot ...';
 SET @Sql = 'ALTER DATABASE ' + QUOTENAME(@DBName) + ' SET READ_COMMITTED_SNAPSHOT ON'
 print 'Executing SQL: ' + @Sql;
 EXECUTE sp_executesql @Sql;

 IF LEN(@Recovery) > 0
 BEGIN
 print 'Setting Recovery Model ...';
 SET @Sql = 'ALTER DATABASE ' + QUOTENAME(@DBName) + ' SET RECOVERY ' + @Recovery
 print 'Executing SQL: ' + @Sql;
 EXECUTE sp_executesql @Sql;
 END

END;
GO
