-- turn message off
SET NOCOUNT ON;

-- input variables
DECLARE @Schema				VARCHAR(50)		= 'dbo'				-- required
DECLARE @ClassName			VARCHAR(50)		= 'Field'			-- required
DECLARE @StoredProcedure	VARCHAR(50)		= 'Fields_List'		-- required
DECLARE @Namespace			VARCHAR(50)		= 'Model.Sandbox'	-- optional
DECLARE @IncludeUsing		BIT				= 0					-- optional
DECLARE @BaseClass			VARCHAR(50)		= ''				-- optional

-- cursor variables
DECLARE @Property	VARCHAR(50)	= ''
DECLARE @SqlType	VARCHAR(50)	= ''

-- other variables
DECLARE @DotNetType			VARCHAR(50)	= ''
DECLARE @DefaultValue		VARCHAR(50)	= ''

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
IF LEN(@BaseClass) > 0
BEGIN
	PRINT '	Public Class ' + @ClassName
	PRINT '		Inherits ' + @BaseClass
	PRINT ''
END
ELSE
BEGIN
	PRINT '	Public Class ' + @ClassName
END

-- public properties
PRINT '		''public properties'

-- declare cursor
DECLARE MyCursor CURSOR LOCAL FAST_FORWARD
FOR
	SELECT	Property = name,
			SqlType = system_type_name
	FROM	sys.dm_exec_describe_first_result_set(@StoredProcedure, NULL, 1)

-- open cursor
OPEN MyCursor

-- get the first result
FETCH NEXT FROM MyCursor INTO @Property, @SqlType

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
	PRINT '		Public Property ' + @Property + ' As ' + @DotNetType + ' = ' + @DefaultValue
	
	-- fetch the next record
	FETCH NEXT FROM MyCursor INTO @Property, @SqlType
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