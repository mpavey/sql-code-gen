-- turn message off
SET NOCOUNT ON;

-- this script should not be run directly but should be run with sqlcmd.sql in SQLCMD mode
-- input variables are defined in sqlcmd.sql file

-- input variables
DECLARE @Schema				VARCHAR(50)		= '$(Schema)'				-- required
DECLARE @TableName			VARCHAR(50)		= '$(TableName)'			-- required
DECLARE @StoredProcedure	VARCHAR(50)		= @TableName + '_Delete'	-- required
DECLARE @EnterpriseLibrary	VARCHAR(10)		= '$(EnterpriseLibrary)'	-- optional

-- other variables
DECLARE @PrimaryKey			VARCHAR(50)	= ''

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

PRINT '		public int Delete(int ' + @PrimaryKey + ')'
PRINT '		{'
PRINT '			// variables'

IF @EnterpriseLibrary = '6'
BEGIN
	PRINT '			Database DB = new DatabaseProviderFactory().CreateDefault();'
END
ELSE
BEGIN
	PRINT '			Database DB = DatabaseFactory.CreateDatabase();'
END


PRINT '			int ReturnValue = -1;'
PRINT ''
PRINT '			// command'
PRINT '			using (DbCommand cmd = DB.GetStoredProcCommand("' + @Schema + '.' + @StoredProcedure + '"))'
PRINT '			{'
PRINT '				// parameters'
PRINT '				DB.AddInParameter(cmd, "@' + @PrimaryKey + '", DbType.Int32, ' + @PrimaryKey + ');'
PRINT ''
PRINT '				// return value parameter'
PRINT '				DB.AddParameter(cmd, "@ReturnValue", DbType.Int32, 4, ParameterDirection.ReturnValue, false, 0, 0, "@ReturnValue", DataRowVersion.Default, null);'
PRINT ''
PRINT '				// execute query'
PRINT '				DB.ExecuteNonQuery(cmd);'
PRINT ''
PRINT '				// get return value'
PRINT '				ReturnValue = (int)DB.GetParameterValue(cmd, "@ReturnValue");'
PRINT '			}'
PRINT ''
PRINT '			// return value'
PRINT '			return ReturnValue;'
PRINT '		}'
-- PRINT ''

-- submit batch
GO