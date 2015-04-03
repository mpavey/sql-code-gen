-- turn message off
SET NOCOUNT ON;

-- this script should not be run directly but should be run with sqlcmd.sql in SQLCMD mode
-- input variables are defined in sqlcmd.sql file

-- input variables
DECLARE @ProcBaseName	VARCHAR(50)		= '$(ProcBaseName)'		-- required
DECLARE @TableName		VARCHAR(50)		= '$(TableName)'		-- required
DECLARE @FilterAll		BIT				= $(FilterAll)			-- optional

-- cursor variables
DECLARE @Property	VARCHAR(50)	= ''
DECLARE @SqlType	VARCHAR(50)	= ''
DECLARE @Length		INT			= 0
DECLARE @Row		INT			= 0
DECLARE @Precision	TINYINT		= 0
DECLARE @Scale		TINYINT		= 0
DECLARE @Columns	INT			= 0
DECLARE @Filters	INT			= 0

-- other variables
DECLARE @PrimaryKey		VARCHAR(50)	= ''
DECLARE @DefaultValue	VARCHAR(50)	= ''

-- get primary key
SELECT	TOP 1
		@PrimaryKey = COLUMN_NAME
FROM	INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
WHERE	TABLE_NAME = @TableName

-- number of columns
SELECT	@Columns = COUNT(*)
FROM	sys.columns c
JOIN	sys.objects o ON c.object_id = o.object_id
JOIN	sys.types t ON c.user_type_id = t.user_type_id
WHERE	o.type = 'U'
AND		o.name = @TableName

-- number of filters
SELECT	@Filters = COUNT(*)
FROM	sys.columns c
JOIN	sys.objects o ON c.object_id = o.object_id
JOIN	sys.types t ON c.user_type_id = t.user_type_id
WHERE	o.type = 'U'
AND		o.name = @TableName
AND		c.name = 
			CASE
				WHEN @FilterAll = 1 THEN c.name
				ELSE @PrimaryKey
			END

-- create procedure
PRINT 'CREATE PROCEDURE [dbo].[' + @ProcBaseName + '_List]'
PRINT '('

-- input parameters
DECLARE MyCursor CURSOR LOCAL FAST_FORWARD
FOR
	SELECT		'Property' = c.name,
				'SqlType' = t.name,
				'Length' = c.max_length,
				'Row' = ROW_NUMBER() OVER (ORDER BY c.column_id),
				'Precision' = c.precision,
				'Scale' = c.scale
	FROM		sys.columns c
	JOIN		sys.objects o ON c.object_id = o.object_id
	JOIN		sys.types t ON c.user_type_id = t.user_type_id
	WHERE		o.type = 'U'
	AND			o.name = @TableName
	AND			c.name = 
					CASE
						WHEN @FilterAll = 1 THEN c.name
						ELSE @PrimaryKey
					END
	ORDER BY	c.column_id

-- open cursor
OPEN MyCursor

-- get the first result
FETCH NEXT FROM MyCursor INTO @Property, @SqlType, @Length, @Row, @Precision, @Scale

-- loop through results
WHILE @@FETCH_STATUS = 0
BEGIN
	-- variables
	DECLARE @TypeSize		VARCHAR(50)		= ''
	
	SET @TypeSize = 
		CASE
			WHEN @SqlType LIKE '%char%' AND @Length > 0 THEN '			' + UPPER(@SqlType) + '(' + CONVERT(VARCHAR, @Length) + ')'
			WHEN @SqlType LIKE '%char%' THEN '			' + UPPER(@SqlType) + '(MAX)'
			WHEN @SqlType LIKE '%decimal%' THEN '			' + UPPER(@SqlType) + '(' + CONVERT(VARCHAR, @Precision) + ', ' + CONVERT(VARCHAR, @Scale) + ')'
			ELSE '			' + UPPER(@SqlType)
		END

	-- default value based on data type
	SET @DefaultValue =
		CASE
			WHEN @SqlType = 'bigint' THEN '0'
			WHEN @SqlType = 'bit' THEN 'NULL'
			WHEN @SqlType = 'date' THEN 'NULL'
			WHEN @SqlType = 'datetime' THEN 'NULL'
			WHEN @SqlType = 'datetime2' THEN 'NULL'
			WHEN @SqlType = 'datetimeoffset' THEN 'NULL'
			WHEN @SqlType = 'decimal' THEN '0'
			WHEN @SqlType = 'float' THEN '0'
			WHEN @SqlType = 'int' THEN '0'
			WHEN @SqlType = 'money' THEN '0'
			WHEN @SqlType = 'numeric' THEN '0'
			WHEN @SqlType = 'real' THEN '0'
			WHEN @SqlType = 'smalldatetime' THEN 'NULL'
			WHEN @SqlType = 'smallint' THEN '0'
			WHEN @SqlType = 'smallmoney' THEN '0'
			WHEN @SqlType = 'tinyint' THEN '0'
			WHEN @SqlType = 'time' THEN 'NULL'
			ELSE ''''''
		END

	-- parameter
	IF @Row != @Filters
	BEGIN
		PRINT '	@' + @Property + ' ' + @TypeSize + ' = ' + @DefaultValue + ','
	END
	ELSE
	BEGIN
		PRINT '	@' + @Property + ' ' + @TypeSize + ' = ' + @DefaultValue
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
PRINT '	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.'
PRINT '	SET NOCOUNT ON;'
PRINT ''
PRINT '	-- get data'

-- declare cursor
DECLARE MyCursor CURSOR LOCAL FAST_FORWARD
FOR
	SELECT		'Property' = c.name,
				'Row' = ROW_NUMBER() OVER (ORDER BY c.column_id)
	FROM		sys.columns c
	JOIN		sys.objects o ON c.object_id = o.object_id
	WHERE		o.type = 'U'
	AND			o.name = @TableName
	ORDER BY	c.column_id

-- open cursor
OPEN MyCursor

-- get the first result
FETCH NEXT FROM MyCursor INTO @Property, @Row

-- loop through results
WHILE @@FETCH_STATUS = 0
BEGIN
	-- select field
	IF @Row = 1
	BEGIN
		PRINT '	SELECT		' + @Property + ','
	END
	ELSE IF @Row != @Columns
	BEGIN
		PRINT '				' + @Property + ','
	END
	ELSE
	BEGIN
		PRINT '				' + @Property
	END
		
	-- fetch the next record
	FETCH NEXT FROM MyCursor INTO @Property, @Row
END

-- close cursor
CLOSE		MyCursor
DEALLOCATE	MyCursor

-- from
PRINT '	FROM		' + @TableName

-- filters
-- input parameters
DECLARE MyCursor CURSOR LOCAL FAST_FORWARD
FOR
	SELECT		'Property' = c.name,
				'SqlType' = t.name,
				'Length' = c.max_length,
				'Row' = ROW_NUMBER() OVER (ORDER BY c.column_id)
	FROM		sys.columns c
	JOIN		sys.objects o ON c.object_id = o.object_id
	JOIN		sys.types t ON c.user_type_id = t.user_type_id
	WHERE		o.type = 'U'
	AND			o.name = @TableName
	AND			c.name = 
					CASE
						WHEN @FilterAll = 1 THEN c.name
						ELSE @PrimaryKey
					END
	ORDER BY	c.column_id

-- open cursor
OPEN MyCursor

-- get the first result
FETCH NEXT FROM MyCursor INTO @Property, @SqlType, @Length, @Row

-- loop through results
WHILE @@FETCH_STATUS = 0
BEGIN
	-- default value based on data type
	SET @DefaultValue =
		CASE
			WHEN @SqlType = 'bigint' THEN '0'
			WHEN @SqlType = 'bit' THEN 'NULL'
			WHEN @SqlType = 'date' THEN 'NULL'
			WHEN @SqlType = 'datetime' THEN 'NULL'
			WHEN @SqlType = 'datetime2' THEN 'NULL'
			WHEN @SqlType = 'datetimeoffset' THEN 'NULL'
			WHEN @SqlType = 'decimal' THEN '0'
			WHEN @SqlType = 'float' THEN '0'
			WHEN @SqlType = 'int' THEN '0'
			WHEN @SqlType = 'money' THEN '0'
			WHEN @SqlType = 'numeric' THEN '0'
			WHEN @SqlType = 'real' THEN '0'
			WHEN @SqlType = 'smalldatetime' THEN 'NULL'
			WHEN @SqlType = 'smallint' THEN '0'
			WHEN @SqlType = 'smallmoney' THEN '0'
			WHEN @SqlType = 'tinyint' THEN '0'
			WHEN @SqlType = 'time' THEN 'NULL'
			ELSE ''''''
		END

	-- parameter
	IF @Row = 1
	BEGIN
		PRINT '	WHERE		' + @Property + ' = '
	END
	ELSE
	BEGIN
		PRINT '	AND			' + @Property + ' = '
	END

	PRINT '					CASE'

	IF @SqlType IN ('bigint', 'decimal', 'float', 'int', 'money', 'numeric', 'real', 'smallint', 'smallmoney', 'tinyint')
	BEGIN
		PRINT '						WHEN @' + @Property + ' > 0 THEN @' + @Property
	END
	ELSE IF @SqlType IN ('bit', 'date', 'datetime', 'datetime2', 'datetimeoffset', 'smalldatetime', 'time')
	BEGIN
		PRINT '						WHEN @' + @Property + ' IS NOT NULL THEN @' + @Property
	END
	ELSE
	BEGIN
		PRINT '						WHEN LEN(@' + @Property + ') > 0 THEN @' + @Property
	END

	PRINT '						ELSE ' + @Property
	PRINT '					END'
		
	-- fetch the next record
	FETCH NEXT FROM MyCursor INTO @Property, @SqlType, @Length, @Row
END

-- close cursor
CLOSE		MyCursor
DEALLOCATE	MyCursor

-- order by
PRINT '	ORDER BY	' + @PrimaryKey
PRINT 'END'
PRINT 'GO'
PRINT ''

-- submit batch
GO