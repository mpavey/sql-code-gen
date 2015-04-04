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
DECLARE @Null		BIT			= ''

-- other variables
DECLARE @DbType				VARCHAR(50)	= ''

-- declare temp table so we can determine the input parameters
DECLARE @Fields TABLE
(
	Property	VARCHAR(50),
	SqlType		VARCHAR(50),
	[Null]		BIT
)

-- if the save stored procedure has already been defined with input parameters use those
-- otherwise we will just use all of the fields for the specified table as input parameters
INSERT INTO @Fields
	(Property, SqlType, [Null])
	SELECT		'Property' = REPLACE(p.PARAMETER_NAME, '@', ''),
				'SqlType' = p.DATA_TYPE,
				'Null' = ISNULL(c.is_nullable, 0)
	FROM		INFORMATION_SCHEMA.PARAMETERS p
	JOIN		sys.objects o ON o.type = 'U' AND o.name = @TableName
	LEFT JOIN	sys.columns c ON o.object_id = c.object_id AND REPLACE(p.PARAMETER_NAME, '@', '') = c.name
	LEFT JOIN	sys.types t ON c.user_type_id = t.user_type_id
	WHERE		p.SPECIFIC_NAME = @StoredProcedure
	AND			p.PARAMETER_MODE = 'IN'
	ORDER BY	p.ORDINAL_POSITION

IF NOT EXISTS(SELECT Property FROM @Fields)
BEGIN
	INSERT INTO @Fields
		(Property, SqlType, [Null])
		SELECT		'Property' = c.name,
					'SqlType' = t.name,
					'Null' = c.is_nullable
		FROM		sys.columns c
		JOIN		sys.objects o ON c.object_id = o.object_id
		JOIN		sys.types t ON c.user_type_id = t.user_type_id
		WHERE		o.type = 'U'
		AND			o.name = @TableName
		ORDER BY	c.column_id
END

-- function declaration
PRINT '		Public Function Save(ByVal ' + @ClassNameModel + ' As ' + @AssemblyName + '.' + @ClassNameModel + ') As Integer'
PRINT '			''variables'

IF @EnterpriseLibrary = '6'
BEGIN
	PRINT '			Dim DB As Database = New DatabaseProviderFactory().CreateDefault()'
END
ELSE
BEGIN
	PRINT '			Dim DB As Database = DatabaseFactory.CreateDatabase()'
END

PRINT '			Dim ReturnValue As Integer = -1'
PRINT ''
PRINT '			''command'
PRINT '			Using cmd As DbCommand = DB.GetStoredProcCommand("' + @Schema + '.' + @StoredProcedure + '")'
PRINT '				''parameters'
PRINT '				With ' + @ClassNameModel

-- declare cursor
DECLARE MyCursor CURSOR LOCAL FAST_FORWARD
FOR
	SELECT	Property,
			SqlType,
			[Null]
	FROM	@Fields

-- open cursor
OPEN MyCursor

-- get the first result
FETCH NEXT FROM MyCursor INTO @Property, @SqlType, @Null

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
			WHEN @SqlType = 'time' THEN 'Time'
			ELSE 'String'
		END
		
	-- add parameter
	IF @Null = 1 AND @SqlType IN ('date', 'datetime', 'datetime2', 'datetimeoffset', 'smalldatetime')
	BEGIN
		print '					DB.AddInParameter(cmd, "@' + @Property + '", DbType.' + @DbType + ', IIf(.' + @Property + '.HasValue AndAlso Not .' + @Property + '.Equals(DateTime.MinValue), .' + @Property + ', DBNull.Value))'
	END
	ELSE IF @Null = 1 AND @SqlType IN ('time')
	BEGIN
		print '					DB.AddInParameter(cmd, "@' + @Property + '", DbType.' + @DbType + ', IIf(.' + @Property + '.HasValue AndAlso Not .' + @Property + '.Equals(DateTime.MinValue), .' + @Property + ', DBNull.Value))'
	END
	ELSE
	BEGIN
		PRINT '					DB.AddInParameter(cmd, "@' + @Property + '", DbType.' + @DbType + ', .' + @Property + ')'
	END	

	-- fetch the next record
	FETCH NEXT FROM MyCursor INTO @Property, @SqlType, @Null
END

-- close cursor
CLOSE		MyCursor
DEALLOCATE	MyCursor

-- end function
PRINT '				End With'
PRINT ''
PRINT '				''return value parameter'
PRINT '				DB.AddParameter(cmd, "@ReturnValue", DbType.Int32, 4, ParameterDirection.ReturnValue, False, 0, 0, "@ReturnValue", DataRowVersion.Default, Nothing)'
PRINT ''
PRINT '				''execute query'
PRINT '				DB.ExecuteNonQuery(cmd)'
PRINT ''
PRINT '				''get return value'
PRINT '				ReturnValue = DB.GetParameterValue(cmd, "@ReturnValue")'
PRINT '			End Using'
PRINT ''
PRINT '			''return value'
PRINT '			Return ReturnValue'
PRINT '		End Function'
PRINT ''

-- submit batch
GO