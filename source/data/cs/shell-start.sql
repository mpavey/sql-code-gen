-- turn message off
SET NOCOUNT ON;

-- this script should not be run directly but should be run with sqlcmd.sql in SQLCMD mode
-- input variables are defined in sqlcmd.sql file

-- input variables
DECLARE @IncludeUsing	BIT				= $(IncludeUsing)		-- optional
DECLARE @Namespace		VARCHAR(50)		= '$(Namespace)'		-- optional
DECLARE @ClassNameData	VARCHAR(50)		= '$(ClassNameData)'	-- required
DECLARE @BaseClassData	VARCHAR(50)		= '$(BaseClassData)'	-- optional

PRINT 'using System;'
PRINT 'using System.Collections.Generic;'
PRINT 'using System.Linq;'
PRINT 'using System.Text;'
PRINT 'using System.Data;'
PRINT 'using System.Data.Common;'
PRINT 'using Microsoft.Practices.EnterpriseLibrary.Data;'
PRINT 'using ' + @Namespace + '.Utilities;'
PRINT ''

-- namespace
IF LEN(@Namespace) > 0
BEGIN
	PRINT 'namespace ' + @Namespace
	PRINT '{'
END

-- class
IF LEN(@BaseClassData) > 0
BEGIN
	PRINT '	public class ' + @ClassNameData + ' : ' + @BaseClassData 
	PRINT '	{'
END
ELSE
BEGIN
	PRINT '	public class ' + @ClassNameData
	PRINT '	{'
END

-- process batch
GO