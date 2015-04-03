-- turn message off
SET NOCOUNT ON;

-- this script should not be run directly but should be run with sqlcmd.sql in SQLCMD mode
-- input variables are defined in sqlcmd.sql file

-- input variables
DECLARE @TableName		VARCHAR(50)		= '$(TableName)'		-- required
DECLARE @IncludeUsing	BIT				= $(IncludeUsing)		-- optional
DECLARE @Namespace		VARCHAR(50)		= '$(Namespace)'		-- optional
DECLARE @ClassNameModel	VARCHAR(50)	= '$(ClassNameModel)'	-- required
DECLARE @BaseClassModel	VARCHAR(50)		= '$(BaseClassModel)'	-- optional

-- cursor variables
DECLARE @Property	VARCHAR(50)	= ''
DECLARE @SqlType	VARCHAR(50)	= ''
DECLARE @Null		BIT			= 0

-- other variables
DECLARE @DotNetType		VARCHAR(50)	= ''
DECLARE @DefaultValue	VARCHAR(50)	= ''

-- using statements
IF @IncludeUsing = 1
BEGIN
	PRINT 'Imports System'
	PRINT 'Imports System.Collections.Generic'
	PRINT 'Imports System.Linq'
	PRINT 'Imports System.Text'
	PRINT ''
END

-- namespace
IF LEN(@Namespace) > 0
BEGIN
	PRINT 'Namespace ' + @Namespace
END

-- class
IF LEN(@BaseClassModel) > 0
BEGIN
	PRINT '	Public Class ' + @ClassNameModel
	PRINT '		Inherits ' + @BaseClassModel
	PRINT ''
END
ELSE
BEGIN
	PRINT '	Public Class ' + @ClassNameModel
END

PRINT '		''public properties'

-- declare cursor
DECLARE MyCursor CURSOR LOCAL FAST_FORWARD
FOR
	SELECT		'Property' = c.name,
				'SqlType' = t.name,
				'Null' = c.is_nullable
	FROM		sys.columns c
	JOIN		sys.objects o ON c.object_id = o.object_id
	JOIN		sys.types t ON c.user_type_id = t.user_type_id
	WHERE		o.type = 'U'
	AND			o.name = @TableName
	ORDER BY	c.column_id

-- open cursor
OPEN MyCursor

-- get the first result
FETCH NEXT FROM MyCursor INTO @Property, @SqlType, @Null

-- loop through results
WHILE @@FETCH_STATUS = 0
BEGIN
	-- .Net data type	
	SET @DotNetType = 
		CASE
			WHEN @SqlType = 'bit' THEN 'Boolean'
			WHEN @SqlType = 'date' THEN 'DateTime'
			WHEN @SqlType = 'datetime' THEN 'DateTime'
			WHEN @SqlType = 'decimal' THEN 'Decimal'
			WHEN @SqlType = 'int' THEN 'Integer'
			WHEN @SqlType = 'money' THEN 'Decimal'
			WHEN @SqlType = 'smalldatetime' THEN 'DateTime'
			WHEN @SqlType = 'smallint' THEN 'Integer'
			WHEN @SqlType = 'tinyint' THEN 'Integer'
			WHEN @SqlType = 'time' THEN 'TimeSpan'
			ELSE 'String'
		END
	
	-- default value based on data type
	SET @DefaultValue = 
		CASE
			WHEN @SqlType = 'bit' THEN 'False'
			WHEN @SqlType = 'date' THEN 'DateTime.MinValue'
			WHEN @SqlType = 'datetime' THEN 'DateTime.MinValue'
			WHEN @SqlType = 'decimal' THEN '0'
			WHEN @SqlType = 'int' THEN '0'
			WHEN @SqlType = 'money' THEN '0'
			WHEN @SqlType = 'smalldatetime' THEN 'DateTime.MinValue'
			WHEN @SqlType = 'smallint' THEN '0'
			WHEN @SqlType = 'tinyint' THEN '0'
			ELSE 'String.Empty'
		END
	
	-- public properties
	IF @Null = 1 AND @DotNetType != 'String'
	BEGIN
		PRINT '		Public Property ' + @Property + ' As ' + @DotNetType + '?'
	END
	ELSE
	BEGIN
		PRINT '		Public Property ' + @Property + ' As ' + @DotNetType + ' = ' + @DefaultValue
	END
	
	-- fetch the next record
	FETCH NEXT FROM MyCursor INTO @Property, @SqlType, @Null
END

-- close cursor
CLOSE		MyCursor
DEALLOCATE	MyCursor

-- class
PRINT '	End Class'

-- namespace
IF LEN(@Namespace) > 0
BEGIN
	PRINT 'End Namespace'
END

PRINT ''

-- submit batch
GO