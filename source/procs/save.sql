-- turn message off
SET NOCOUNT ON;

-- this script should not be run directly but should be run with sqlcmd.sql in SQLCMD mode
-- input variables are defined in sqlcmd.sql file

-- input variables
DECLARE @Schema			VARCHAR(50)		= '$(Schema)'			-- required
DECLARE @ProcBaseName	VARCHAR(50)		= '$(ProcBaseName)'		-- required
DECLARE @TableName		VARCHAR(50)		= '$(TableName)'		-- required

-- cursor variables
DECLARE @Property	VARCHAR(50)	= ''
DECLARE @SqlType	VARCHAR(50)	= ''
DECLARE @Length		INT			= 0
DECLARE @Row		INT			= 0
DECLARE @Precision	TINYINT		= 0
DECLARE @Scale		TINYINT		= 0
DECLARE @Columns	INT			= 0

-- other variables
DECLARE @PrimaryKey		VARCHAR(50)		= ''
DECLARE @Fields			VARCHAR(MAX)	= ''
DECLARE @Values			VARCHAR(MAX)	= ''

-- get primary key
SELECT		TOP 1
			@PrimaryKey = c.name
FROM		sys.columns c
JOIN		sys.tables t ON c.object_id = t.object_id
JOIN		sys.schemas s ON t.schema_id = s.schema_id
JOIN		sys.types x ON c.user_type_id = x.user_type_id
JOIN		INFORMATION_SCHEMA.COLUMNS i ON i.TABLE_SCHEMA = s.name AND i.TABLE_NAME = t.name AND i.COLUMN_NAME = c.name
WHERE		s.name = @Schema
AND			t.name = @TableName
AND			c.is_identity = 1
ORDER BY	i.ORDINAL_POSITION

-- number of columns
SELECT	@Columns = COUNT(*)
FROM	sys.columns c
JOIN	sys.objects o ON c.object_id = o.object_id
JOIN	sys.types t ON c.user_type_id = t.user_type_id
JOIN	sys.schemas s ON o.schema_id = s.schema_id
WHERE	o.type = 'U'
AND		s.name = @Schema
AND		o.name = @TableName

-- create procedure
PRINT 'CREATE PROCEDURE [' + @Schema + '].[' + @ProcBaseName + '_Save]'
PRINT '('

-- input parameters
DECLARE MyCursor CURSOR LOCAL FAST_FORWARD
FOR
	SELECT		Property = c.name,
				SqlType = t.name,
				Length = c.max_length,
				Row = ROW_NUMBER() OVER (ORDER BY c.column_id),
				Precision = c.precision,
				Scale = c.scale
	FROM		sys.columns c
	JOIN		sys.objects o ON c.object_id = o.object_id
	JOIN		sys.types t ON c.user_type_id = t.user_type_id
	JOIN		sys.schemas s ON o.schema_id = s.schema_id
	WHERE		o.type = 'U'
	AND			s.name = @Schema
	AND			o.name = @TableName
	ORDER BY	c.column_id

-- open cursor
OPEN MyCursor

-- get the first result
FETCH NEXT FROM MyCursor INTO @Property, @SqlType, @Length, @Row, @Precision, @Scale

-- loop through results
WHILE @@FETCH_STATUS = 0
BEGIN
	-- type/size
	DECLARE @TypeSize VARCHAR(50)
	
	SET @TypeSize = 
		CASE
			WHEN @SqlType LIKE '%char%' AND @Length > 0 THEN '			' + UPPER(@SqlType) + '(' + CONVERT(VARCHAR, @Length) + ')'
			WHEN @SqlType LIKE '%char%' THEN '			' + UPPER(@SqlType) + '(MAX)'
			WHEN @SqlType LIKE '%decimal%' THEN '			' + UPPER(@SqlType) + '(' + CONVERT(VARCHAR, @Precision) + ', ' + CONVERT(VARCHAR, @Scale) + ')'
			ELSE '			' + UPPER(@SqlType)
		END

	-- parameter
	IF @Row != @Columns
	BEGIN
		PRINT '	@' + @Property + ' ' + @TypeSize + ','
	END
	ELSE
	BEGIN
		PRINT '	@' + @Property + ' ' + @TypeSize
	END
		
	-- fetch the next record
	FETCH NEXT FROM MyCursor INTO @Property, @SqlType, @Length, @Row, @Precision, @Scale
END

-- close cursor
CLOSE		MyCursor
DEALLOCATE	MyCursor

PRINT ')'
PRINT 'AS'
PRINT 'BEGIN'
PRINT '	-- check to see if record exists'
PRINT '	IF EXISTS (SELECT ' + @PrimaryKey + ' FROM ' + @TableName + ' WHERE ' + @PrimaryKey + ' = @' + @PrimaryKey + ')'
PRINT '	BEGIN'

-- get total rows (minus primary key)
SELECT	@Columns = COUNT(*)
FROM	sys.columns c
JOIN	sys.objects o ON c.object_id = o.object_id
JOIN	sys.types t ON c.user_type_id = t.user_type_id
JOIN	sys.schemas s ON o.schema_id = s.schema_id
WHERE	o.type = 'U'
AND		s.name = @Schema
AND		o.name = @TableName
AND		c.name != @PrimaryKey

-- UPDATE
PRINT '		-- update'
PRINT '		UPDATE	' + @TableName

DECLARE MyCursor CURSOR LOCAL FAST_FORWARD
FOR
	SELECT		Property = c.name,
				Row = ROW_NUMBER() OVER (ORDER BY c.column_id)
	FROM		sys.columns c
	JOIN		sys.objects o ON c.object_id = o.object_id
	JOIN		sys.schemas s ON o.schema_id = s.schema_id
	WHERE		o.type = 'U'
	AND			s.name = @Schema
	AND			o.name = @TableName
	AND			c.name != @PrimaryKey
	ORDER BY	c.column_id

-- open cursor
OPEN MyCursor

-- get the first result
FETCH NEXT FROM MyCursor INTO @Property, @Row

-- loop through results
WHILE @@FETCH_STATUS = 0
BEGIN
	-- update field
	IF @Row = 1 AND @Columns = 1
	BEGIN
		PRINT '		SET		' + @Property + ' = @' + @Property
		SET @Fields += @Property
		SET @Values += '@' + @Property
	END
	ELSE IF @Row = 1
	BEGIN
		PRINT '		SET		' + @Property + ' = @' + @Property + ','
		SET @Fields += @Property + ', '
		SET @Values += '@' + @Property + ', '
	END
	ELSE IF @Row != @Columns
	BEGIN
		PRINT '				' + @Property + ' = @' + @Property + ','
		SET @Fields += @Property + ', '
		SET @Values += '@' + @Property + ', '
	END
	ELSE
	BEGIN
		PRINT '				' + @Property + ' = @' + @Property
		SET @Fields += @Property
		SET @Values += '@' + @Property
	END
		
	-- fetch the next record
	FETCH NEXT FROM MyCursor INTO @Property, @Row
END

-- close cursor
CLOSE		MyCursor
DEALLOCATE	MyCursor

-- WHERE clause for UPDATE
PRINT '		WHERE	' + @PrimaryKey + ' = @' + @PrimaryKey
PRINT '	END'
PRINT '	ELSE'
PRINT '	BEGIN'

-- INSERT
PRINT '		-- insert'
PRINT '		INSERT INTO	' + @TableName
PRINT '			(' + @Fields + ')'
PRINT '		VALUES'
PRINT '			(' + @Values + ')'
PRINT ''
PRINT '		-- get identity value'
PRINT '		SET @' + @PrimaryKey + ' = SCOPE_IDENTITY()'
PRINT '	END'
PRINT ''

-- RETURN
PRINT '	-- return value'
PRINT '	RETURN @' + @PrimaryKey
PRINT 'END'
PRINT 'GO'
PRINT ''

-- submit batch
GO