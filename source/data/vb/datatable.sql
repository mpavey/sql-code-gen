-- turn message off
SET NOCOUNT ON;

-- input variables
DECLARE @Schema				VARCHAR(50)		= 'dbo'				-- required
DECLARE @StoredProcedure	VARCHAR(MAX)	= 'Fields_List'		-- required
DECLARE @EnterpriseLibrary	VARCHAR(10)		= '5'				-- optional; 5 (default); 6

-- cursor variables
DECLARE @Property	VARCHAR(50)	= ''
DECLARE @SqlType	VARCHAR(50)	= ''
DECLARE @Length		INT			= 0

-- other variables
DECLARE @DbType				VARCHAR(50)		= ''
DECLARE @DotNetType			VARCHAR(50)		= ''
DECLARE @DefaultValue		VARCHAR(50)		= ''
DECLARE @Parameters			VARCHAR(MAX)	= ''

-- declare cursor
DECLARE MyCursor CURSOR LOCAL FAST_FORWARD
FOR
	SELECT		'Property' = REPLACE(PARAMETER_NAME, '@', ''),
				'SqlType' = DATA_TYPE,
				'Length' = ISNULL(CHARACTER_MAXIMUM_LENGTH, 0)
	FROM		INFORMATION_SCHEMA.PARAMETERS
	WHERE		SPECIFIC_NAME = @StoredProcedure
	AND			PARAMETER_MODE = 'IN'
	ORDER BY	ORDINAL_POSITION

-- open cursor
OPEN MyCursor

-- get the first result
FETCH NEXT FROM MyCursor INTO @Property, @SqlType, @Length

-- loop through results
WHILE @@FETCH_STATUS = 0
BEGIN
	-- .Net data type		
	SET @DotNetType = 
		CASE
			WHEN @SqlType = 'bigint' THEN 'Int64'
			WHEN @SqlType = 'bit' THEN 'Boolean'
			WHEN @SqlType = 'date' THEN 'DateTime'
			WHEN @SqlType = 'datetime' THEN 'DateTime'
			WHEN @SqlType = 'datetime2' THEN 'DateTime'
			WHEN @SqlType = 'datetimeoffset' THEN 'DateTimeOffset'
			WHEN @SqlType = 'decimal' THEN 'Decimal'
			WHEN @SqlType = 'float' THEN 'Double'
			WHEN @SqlType = 'int' THEN 'Int32'
			WHEN @SqlType = 'money' THEN 'Decimal'
			WHEN @SqlType = 'numeric' THEN 'Decimal'
			WHEN @SqlType = 'real' THEN 'Single'
			WHEN @SqlType = 'smalldatetime' THEN 'DateTime'
			WHEN @SqlType = 'smallint' THEN 'Int16'
			WHEN @SqlType = 'smallmoney' THEN 'Decimal'
			WHEN @SqlType = 'tinyint' THEN 'Byte'
			ELSE 'String'
		END
	
	-- default value based on data type
	SET @DefaultValue =
		CASE
			WHEN @SqlType = 'bigint' THEN '0'
			WHEN @SqlType = 'bit' THEN 'Nothing'
			WHEN @SqlType = 'date' THEN 'Nothing'
			WHEN @SqlType = 'datetime' THEN 'Nothing'
			WHEN @SqlType = 'datetime2' THEN 'Nothing'
			WHEN @SqlType = 'datetimeoffset' THEN 'Nothing'
			WHEN @SqlType = 'decimal' THEN '0'
			WHEN @SqlType = 'float' THEN '0'
			WHEN @SqlType = 'int' THEN '0'
			WHEN @SqlType = 'money' THEN '0'
			WHEN @SqlType = 'numeric' THEN '0'
			WHEN @SqlType = 'real' THEN '0'
			WHEN @SqlType = 'smalldatetime' THEN 'Nothing'
			WHEN @SqlType = 'smallint' THEN '0'
			WHEN @SqlType = 'smallmoney' THEN '0'
			WHEN @SqlType = 'tinyint' THEN '0'
			ELSE '""'
		END

	IF LEN(@Parameters) > 0
	BEGIN
		SET @Parameters = @Parameters + ', '
	END
	
	-- add parameter
	IF @DefaultValue = 'Nothing'
	BEGIN
		SET @Parameters = @Parameters + 'Optional ByVal ' + @Property + ' As ' + @DotNetType + '? = ' + @DefaultValue
	END
	ELSE
	BEGIN
		SET @Parameters = @Parameters + 'Optional ByVal ' + @Property + ' As ' + @DotNetType + ' = ' + @DefaultValue
	END
	
	-- fetch the next record
	FETCH NEXT FROM MyCursor INTO @Property, @SqlType, @Length
END

-- close cursor
CLOSE		MyCursor
DEALLOCATE	MyCursor

PRINT 'Public Function GetDataTable(' + @Parameters + ') As DataTable'
PRINT '	''variables'

IF @EnterpriseLibrary = '6'
BEGIN
	PRINT '	Dim DB As Database = New DatabaseProviderFactory().CreateDefault()'
END
ELSE
BEGIN
	PRINT '	Dim DB As Database = DatabaseFactory.CreateDatabase()'
END

PRINT '	Dim DT As New DataTable()'
PRINT ''
PRINT '	''command'
PRINT '	Using cmd As DbCommand = DB.GetStoredProcCommand("' + @Schema + '.' + @StoredProcedure + '")'
PRINT '		''parameters'

-- declare cursor
DECLARE MyCursor CURSOR LOCAL FAST_FORWARD
FOR
	SELECT		'Property' = REPLACE(PARAMETER_NAME, '@', ''),
				'SqlType' = DATA_TYPE,
				'Length' = ISNULL(CHARACTER_MAXIMUM_LENGTH, 0)
	FROM		INFORMATION_SCHEMA.PARAMETERS
	WHERE		SPECIFIC_NAME = @StoredProcedure
	AND			PARAMETER_MODE = 'IN'
	ORDER BY	ORDINAL_POSITION

-- open cursor
OPEN MyCursor

-- get the first result
FETCH NEXT FROM MyCursor INTO @Property, @SqlType, @Length

-- loop through results
WHILE @@FETCH_STATUS = 0
BEGIN
	-- DB type	
	SET @DbType = 
		CASE
			WHEN @SqlType = 'bigint' THEN 'Int64'
			WHEN @SqlType = 'bit' THEN 'Boolean'
			WHEN @SqlType = 'date' THEN 'DateTime'
			WHEN @SqlType = 'datetime' THEN 'DateTime'
			WHEN @SqlType = 'datetime2' THEN 'DateTime2'
			WHEN @SqlType = 'datetimeoffset' THEN 'DateTimeOffset'
			WHEN @SqlType = 'decimal' THEN 'Decimal'
			WHEN @SqlType = 'float' THEN 'Double'
			WHEN @SqlType = 'int' THEN 'Int32'
			WHEN @SqlType = 'money' THEN 'Currency'
			WHEN @SqlType = 'numeric' THEN 'Decimal'
			WHEN @SqlType = 'real' THEN 'Single'
			WHEN @SqlType = 'smalldatetime' THEN 'DateTime'
			WHEN @SqlType = 'smallint' THEN 'Int16'
			WHEN @SqlType = 'smallmoney' THEN 'Currency'
			WHEN @SqlType = 'tinyint' THEN 'Byte'
			ELSE 'String'
		END
		
	-- add parameter
	IF @SqlType LIKE '%date%'
	BEGIN
		print '		DB.AddInParameter(cmd, "@' + @Property + '", DbType.' + @DbType + ', IIf(' + @Property + '.HasValue AndAlso Not ' + @Property + '.Equals(DateTime.MinValue), ' + @Property + ', DBNull.Value))'
	END
	ELSE
	BEGIN
		PRINT '		DB.AddInParameter(cmd, "@' + @Property + '", DbType.' + @DbType + ', ' + @Property + ')'
	END	

	-- fetch the next record
	FETCH NEXT FROM MyCursor INTO @Property, @SqlType, @Length
END

-- close cursor
CLOSE		MyCursor
DEALLOCATE	MyCursor

PRINT ''
PRINT '		''execute query and get results'
PRINT '		Using IDR As IDataReader = DB.ExecuteReader(cmd)'
PRINT '			If IDR IsNot Nothing Then'
PRINT '				DT.Load(IDR)'
PRINT '			End If'
PRINT '		End Using'
PRINT '	End Using'
PRINT ''
PRINT '	''return data'
PRINT '	Return DT'
PRINT 'End Function'
PRINT ''

-- submit batch
GO