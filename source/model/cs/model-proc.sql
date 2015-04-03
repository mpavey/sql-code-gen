-- turn message off
SET NOCOUNT ON;

-- this script should not be run directly but should be run with sqlcmd.sql in SQLCMD mode
-- input variables are defined in sqlcmd.sql file

-- input variables
/*
DECLARE @ClassName			VARCHAR(50)		= 'Fertilizer'			-- required
DECLARE @StoredProcedure	VARCHAR(50)		= 'Fertilizers_List'	-- required
DECLARE @Namespace			VARCHAR(50)		= 'Model.Sandbox'		-- optional
DECLARE @IncludeUsing		BIT				= 1						-- optional
DECLARE @BaseClass			VARCHAR(50)		= 'BaseModel'			-- optional
*/

-- cursor variables
DECLARE @Property	VARCHAR(50)	= ''
DECLARE @SqlType	VARCHAR(50)	= ''

-- other variables
DECLARE @DotNetType			VARCHAR(50)	= ''
DECLARE @DefaultValue		VARCHAR(50)	= ''

-- using statements
IF @IncludeUsing = 1
BEGIN
	PRINT 'using System;'
	PRINT 'using System.Collections.Generic;'
	PRINT 'using System.Linq;'
	PRINT 'using System.Text;'
	PRINT ''
END

-- namespace
IF LEN(@Namespace) > 0
BEGIN
	PRINT 'namespace ' + @Namespace
	PRINT '{'
END

-- class
IF LEN(@BaseClass) > 0
BEGIN
	PRINT '	public class ' + @ClassName + ' : ' + @BaseClass 
	PRINT '	{'
END
ELSE
BEGIN
	PRINT '	public class ' + @ClassName
	PRINT '	{'
END

-- constructor
PRINT '		// constructor'
PRINT '		public ' + @ClassName + '()'
PRINT '		{'

-- declare cursor
DECLARE MyCursor CURSOR LOCAL FAST_FORWARD
FOR
	SELECT	'Property' = name,
			'SqlType' = system_type_name
	FROM	sys.dm_exec_describe_first_result_set(@StoredProcedure, NULL, 1);

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
			WHEN @SqlType = 'bit' THEN 'bool'
			WHEN @SqlType = 'date' THEN 'DateTime'
			WHEN @SqlType = 'datetime' THEN 'DateTime'
			WHEN @SqlType LIKE 'decimal%' THEN 'decimal'
			WHEN @SqlType = 'int' THEN 'int'
			WHEN @SqlType = 'money' THEN 'decimal'
			WHEN @SqlType = 'smalldatetime' THEN 'DateTime'
			WHEN @SqlType = 'smallint' THEN 'int'
			WHEN @SqlType = 'tinyint' THEN 'int'
			WHEN @SqlType = 'time' THEN 'TimeSpan'
			WHEN @SqlType = 'float' THEN 'double'
			ELSE 'string'
		END
		
	-- default value based on data type
	SET @DefaultValue = 
		CASE
			WHEN @SqlType = 'bit' THEN 'false'
			WHEN @SqlType = 'date' THEN 'DateTime.MinValue'
			WHEN @SqlType = 'datetime' THEN 'DateTime.MinValue'
			WHEN @SqlType LIKE 'decimal%' THEN '0'
			WHEN @SqlType = 'int' THEN '0'
			WHEN @SqlType = 'money' THEN '0'
			WHEN @SqlType = 'smalldatetime' THEN 'DateTime.MinValue'
			WHEN @SqlType = 'smallint' THEN '0'
			WHEN @SqlType = 'tinyint' THEN '0'
			WHEN @SqlType = 'float' THEN '0'
			ELSE 'string.Empty'
		END
	
	-- public properties
	PRINT '			' + @Property + ' = ' + @DefaultValue + ';'
	
	-- fetch the next record
	FETCH NEXT FROM MyCursor INTO @Property, @SqlType
END

-- close cursor
CLOSE		MyCursor
DEALLOCATE	MyCursor

PRINT '		}'

-- public properties
PRINT ''
PRINT '		// public properties'

-- declare cursor
DECLARE MyCursor CURSOR LOCAL FAST_FORWARD
FOR
	SELECT	'Property' = name,
			'SqlType' = system_type_name
	FROM	sys.dm_exec_describe_first_result_set(@StoredProcedure, NULL, 1);

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
			WHEN @SqlType = 'bit' THEN 'bool'
			WHEN @SqlType = 'date' THEN 'DateTime'
			WHEN @SqlType = 'datetime' THEN 'DateTime'
			WHEN @SqlType LIKE 'decimal%' THEN 'decimal'
			WHEN @SqlType = 'int' THEN 'int'
			WHEN @SqlType = 'money' THEN 'decimal'
			WHEN @SqlType = 'smalldatetime' THEN 'DateTime'
			WHEN @SqlType = 'smallint' THEN 'int'
			WHEN @SqlType = 'tinyint' THEN 'int'
			WHEN @SqlType = 'time' THEN 'TimeSpan'
			WHEN @SqlType = 'float' THEN 'double'
			ELSE 'string'
		END
	
	-- default value based on data type
	SET @DefaultValue = 
		CASE
			WHEN @SqlType = 'bit' THEN 'false'
			WHEN @SqlType = 'date' THEN 'DateTime.MinValue'
			WHEN @SqlType = 'datetime' THEN 'DateTime.MinValue'
			WHEN @SqlType = 'decimal' THEN '0'
			WHEN @SqlType = 'int' THEN '0'
			WHEN @SqlType = 'money' THEN '0'
			WHEN @SqlType = 'smalldatetime' THEN 'DateTime.MinValue'
			WHEN @SqlType = 'smallint' THEN '0'
			WHEN @SqlType = 'tinyint' THEN '0'
			ELSE 'string.Empty'
		END
	
	-- public properties
	PRINT '		public ' + @DotNetType + ' ' + @Property + ' { get; set; }'
	
	-- fetch the next record
	FETCH NEXT FROM MyCursor INTO @Property, @SqlType
END

-- close cursor
CLOSE		MyCursor
DEALLOCATE	MyCursor

-- class
PRINT '	}'

-- namespace
IF LEN(@Namespace) > 0
BEGIN
	PRINT '}'
END

PRINT ''

-- submit batch
GO