-- turn message off
SET NOCOUNT ON;

-- this script should not be run directly but should be run with sqlcmd.sql in SQLCMD mode
-- input variables are defined in sqlcmd.sql file

-- input variables
DECLARE @Namespace		VARCHAR(50)		= '$(Namespace)'		-- optional

-- class
PRINT '	}'

-- namespace
IF LEN(@Namespace) > 0
BEGIN
	PRINT '}'
END

-- process batch
GO