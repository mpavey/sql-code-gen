-- turn message off
SET NOCOUNT ON;

-- this script should not be run directly but should be run with sqlcmd.sql in SQLCMD mode
-- input variables are defined in sqlcmd.sql file

-- input variables
DECLARE @Schema				VARCHAR(50)		= '$(Schema)'				-- required
DECLARE @TableName			VARCHAR(50)		= '$(TableName)'			-- required
DECLARE @StoredProcedure	VARCHAR(50)		= @TableName + '_List'		-- required
DECLARE @EnterpriseLibrary	VARCHAR(10)		= '$(EnterpriseLibrary)'	-- optional
DECLARE @AssemblyName		VARCHAR(50)		= '$(AssemblyName)'			-- required
DECLARE @ClassNameModel		VARCHAR(50)		= '$(ClassNameModel)'		-- required

-- cursor variables
DECLARE @Property	VARCHAR(50)	= ''
DECLARE @SqlType	VARCHAR(50)	= ''
DECLARE @Length		INT			= 0

-- other variables
DECLARE @DbType				VARCHAR(50)		= ''
DECLARE @DotNetType			VARCHAR(50)		= ''
DECLARE @DefaultValue		VARCHAR(50)		= ''
DECLARE @Parameters			VARCHAR(MAX)	= ''
DECLARE @PrimaryKey			VARCHAR(50)		= ''

-- get primary key
SELECT	TOP 1
		@PrimaryKey = COLUMN_NAME
FROM	INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE	TABLE_SCHEMA = @Schema
AND		TABLE_NAME = @TableName

-- declare cursor
DECLARE MyCursor CURSOR LOCAL FAST_FORWARD
FOR
	SELECT		Property = REPLACE(PARAMETER_NAME, '@', ''),
				SqlType = DATA_TYPE,
				Length = ISNULL(CHARACTER_MAXIMUM_LENGTH, 0)
	FROM		INFORMATION_SCHEMA.PARAMETERS
	WHERE		SPECIFIC_SCHEMA = @Schema
	AND			SPECIFIC_NAME = @StoredProcedure
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

-- get method
PRINT '		Public Function [Get](ByVal ' + @PrimaryKey + ' As Integer) As ' + @AssemblyName + '.' + @ClassNameModel
PRINT '			''validate'
PRINT '			If ' + @PrimaryKey + ' < 1 Then'
PRINT '				Return New ' + @AssemblyName + '.' + @ClassNameModel + '()'
PRINT '			End If'
PRINT ''
PRINT '			''lookup'
PRINT '			Dim x As List(Of ' + @AssemblyName + '.' + @ClassNameModel + ') = List(' + @PrimaryKey + ':=' + @PrimaryKey + ')'
PRINT ''
PRINT '			''return'
PRINT '			If x.Count > 0 Then'
PRINT '				Return x.First()'
PRINT '			Else'
PRINT '				Return New ' + @AssemblyName + '.' + @ClassNameModel + '()'
PRINT '			End If'
PRINT '		End Function'
PRINT ''

PRINT '		Public Function List(' + @Parameters + ') As List(Of ' + @AssemblyName + '.' + @ClassNameModel + ')'
PRINT '			''variables'

IF @EnterpriseLibrary = '6'
BEGIN
	PRINT '			Dim DB As Database = New DatabaseProviderFactory().CreateDefault()'
END
ELSE
BEGIN
	PRINT '			Dim DB As Database = DatabaseFactory.CreateDatabase()'
END

PRINT '			Dim ' + @TableName + ' As New List(Of ' + @AssemblyName + '.' + @ClassNameModel + ')'
PRINT ''
PRINT '			''command'
PRINT '			Using cmd As DbCommand = DB.GetStoredProcCommand("' + @Schema + '.' + @StoredProcedure + '")'
PRINT '				''parameters'

-- declare cursor
DECLARE MyCursor CURSOR LOCAL FAST_FORWARD
FOR
	SELECT		Property = REPLACE(PARAMETER_NAME, '@', ''),
				SqlType = DATA_TYPE,
				Length = ISNULL(CHARACTER_MAXIMUM_LENGTH, 0)
	FROM		INFORMATION_SCHEMA.PARAMETERS
	WHERE		SPECIFIC_SCHEMA = @Schema
	AND			SPECIFIC_NAME = @StoredProcedure
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
		print '				DB.AddInParameter(cmd, "@' + @Property + '", DbType.' + @DbType + ', IIf(' + @Property + '.HasValue AndAlso Not ' + @Property + '.Equals(DateTime.MinValue), ' + @Property + ', DBNull.Value))'
	END
	ELSE
	BEGIN
		PRINT '				DB.AddInParameter(cmd, "@' + @Property + '", DbType.' + @DbType + ', ' + @Property + ')'
	END	

	-- fetch the next record
	FETCH NEXT FROM MyCursor INTO @Property, @SqlType, @Length
END

-- close cursor
CLOSE		MyCursor
DEALLOCATE	MyCursor

PRINT ''
PRINT '				''execute query and get results'
PRINT '				Using DT As New DataTable()'
PRINT '					Using IDR As IDataReader = DB.ExecuteReader(cmd)'
PRINT '						If IDR IsNot Nothing Then'
PRINT '							DT.Load(IDR)'
PRINT '						End If'
PRINT '					End Using'
PRINT ''
PRINT '					''convert to business object'
PRINT '					' + @TableName + ' = DT.ToList(Of ' + @AssemblyName + '.' + @ClassNameModel + ')()'
PRINT '				End Using'
PRINT '			End Using'
PRINT ''
PRINT '			''return list'
PRINT '			Return ' + @TableName
PRINT '		End Function'
PRINT ''

-- submit batch
GO