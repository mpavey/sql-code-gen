-- turn message off
SET NOCOUNT ON;

-- this script should not be run directly but should be run with sqlcmd.sql in SQLCMD mode
-- input variables are defined in sqlcmd.sql file

-- input variables
DECLARE @Schema			VARCHAR(50)		= '$(Schema)'			-- required
DECLARE @ProcBaseName	VARCHAR(50)		= '$(ProcBaseName)'		-- required
DECLARE @TableName		VARCHAR(50)		= '$(TableName)'		-- required

-- other variables
DECLARE @PrimaryKey		VARCHAR(50)	= ''

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

PRINT 'CREATE PROCEDURE [' + @Schema +  '].[' + @ProcBaseName + '_Delete]'
PRINT '('
PRINT '	@' + @PrimaryKey + '	INT'
PRINT ')'
PRINT 'AS'
PRINT 'BEGIN'
PRINT '	DELETE'
PRINT '	FROM	' + @TableName
PRINT '	WHERE	' + @PrimaryKey + ' = @' + @PrimaryKey
PRINT 'END'
PRINT 'GO'
PRINT ''

-- submit batch
GO