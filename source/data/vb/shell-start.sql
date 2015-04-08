-- turn message off
SET NOCOUNT ON;

-- this script should not be run directly but should be run with sqlcmd.sql in SQLCMD mode
-- input variables are defined in sqlcmd.sql file

-- input variables
DECLARE @IncludeUsing	BIT				= $(IncludeUsing)		-- optional
DECLARE @Namespace		VARCHAR(50)		= '$(Namespace)'		-- optional
DECLARE @ClassNameData	VARCHAR(50)		= '$(ClassNameData)'	-- required
DECLARE @BaseClassData	VARCHAR(50)		= '$(BaseClassData)'	-- optional

PRINT 'Imports Microsoft.Practices.EnterpriseLibrary.Data'
PRINT 'Imports System.Data.Common'
PRINT 'Imports ' + @Namespace + '.Utilities.Extensions'
PRINT ''

-- namespace
IF LEN(@Namespace) > 0
BEGIN
	PRINT 'Namespace ' + @Namespace
END

-- class
IF LEN(@BaseClassData) > 0
BEGIN
	PRINT '	Public Class ' + @ClassNameData
	PRINT '		Inherits ' + @BaseClassData
	PRINT ''
END
ELSE
BEGIN
	PRINT '	Public Class ' + @ClassNameData
END

-- process batch
GO