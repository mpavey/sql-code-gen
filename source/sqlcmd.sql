/*
--------------------------------------------------
REQUIRED SETTINGS
--------------------------------------------------
*/

-- the local path that you extracted the the sql-code-gen scripts to
-- this is the path where the sqlcmd.sql file is located
:setvar scriptspath "C:\Users\matt\Dropbox\projects\sql-code-gen\source"

-- the programming language for the model classes and data classes
-- supported options are "cs" and "vb"
:setvar language "cs"

-- the local path where you want the output files created
-- if output folders do not exist they will be created
:setvar outputpath "C:\Users\matt\Desktop\temp\codegen"

-- the database schema
-- Recommended: dbo, but this depends on your database design and requirements
:setvar Schema "dbo"

-- the name of the table you are generating code for
:setvar TableName "Users"

-- base name for stored procedures, e.g. Entity_List, Entity_Save, Entity_Delete
-- Recommended: Typically the same as the TableName
:setvar ProcBaseName "Users"

-- the name of the model class
-- Recommended: Typically the singular version of the TableName
:setvar ClassNameModel "User"

-- the name of the data class
-- Recommended: Typically the same as the TableName
:setvar ClassNameData "Users"

-- the namespace name of the model layer project
-- Recommended: Model
:setvar AssemblyName "Model"

/*
--------------------------------------------------
OPTIONAL SETTINGS
--------------------------------------------------
*/

-- indicates whether or not to include import/using statements for model class
-- Recommended: 0
:setvar IncludeUsing 0

-- the namespace of the project
-- Recommended: This value should be set specific to your project
:setvar Namespace "MySafeInfo"

-- the name of the base class for the model class
-- Recommended: This value is only required if your model classes derive from a base class
:setvar BaseClassModel ""

-- the name of the base class for the data class
-- Recommended: This value is only required if your data classes derive from a base class
:setvar BaseClassData ""

-- indicates if list stored procedure should have optional filters for all fields, or just primary key
-- Recommended: 0 (set to 1 if you want all fields in list stored procedure to have optional filters)
:setvar FilterAll 0

-- the version of the enterprise library data access application blocks
-- Recommended: 5 (default) or 6, this simply determines how the Database DB variable is initialized
:setvar EnterpriseLibrary "6"

/*
--------------------------------------------------
DO NOT MODIFY VALUES BELOW THIS COMMENT
--------------------------------------------------
*/

-- if output folders do not exist, create them
:!! if not exist $(outputpath) mkdir $(outputpath)
:!! if not exist $(outputpath)\model mkdir $(outputpath)\model
:!! if not exist $(outputpath)\data mkdir $(outputpath)\data
:!! if not exist $(outputpath)\sql mkdir $(outputpath)\sql

-- model
:out $(outputpath)"\model\"$(ClassNameModel)"."$(language)
:r $(scriptspath)\model"\"$(language)\model-table.sql

-- procs
:out $(outputpath)\sql\procs.sql
:r $(scriptspath)\procs\list.sql
:r $(scriptspath)\procs\save.sql
:r $(scriptspath)\procs\delete.sql

-- data
:out $(outputpath)"\data\"$(ClassNameData)"."$(language)
:r $(scriptspath)\data"\"$(language)\shell-start.sql
:r $(scriptspath)\data"\"$(language)\list.sql
:r $(scriptspath)\data"\"$(language)\save.sql
:r $(scriptspath)\data"\"$(language)\delete.sql
:r $(scriptspath)\data"\"$(language)\shell-end.sql

-- debug
:out stdout
!! ECHO $(outputpath)\sql\procs.sql
!! ECHO $(outputpath)\model\$(ClassNameModel).$(language)
!! ECHO $(outputpath)\data\$(ClassNameData).$(language)