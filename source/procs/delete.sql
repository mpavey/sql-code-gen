-- turn message off
SET NOCOUNT ON;

-- this script should not be run directly but should be run with sqlcmd.sql in SQLCMD mode
-- input variables are defined in sqlcmd.sql file

-- input variables
DECLARE @ProcBaseName	VARCHAR(50)		= '$(ProcBaseName)'		-- required
DECLARE @TableName		VARCHAR(50)		= '$(TableName)'		-- required

-- other variables
DECLARE @PrimaryKey		VARCHAR(50)	= ''

-- get primary key
SELECT	TOP 1
		@PrimaryKey = COLUMN_NAME
FROM	information_schema.key_column_usage 
WHERE	TABLE_NAME = @TableName

PRINT 'CREATE PROCEDURE [dbo].[' + @ProcBaseName + '_Delete]'
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