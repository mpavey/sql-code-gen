-- variables
:setvar path "C:\Users\matt\Dropbox\scripts\codegen\v3.0"
:setvar language "cs"
:setvar output "C:\Users\matt\Desktop\temp"

:setvar TableName "Fields"			-- required (the name of the table you are generating code for)
:setvar ProcBaseName "Fields"		-- required (base name for stored procedures, e.g. Entity_List, Entity_Save, Entity_Delete)
:setvar ClassNameModel "Field"		-- required (the name of the model class)
:setvar ClassNameData "Fields"		-- required (the name of the data class)
:setvar AssemblyName "Model"		-- required (the name of the namespace where the model classes are stored within the project)

:setvar IncludeUsing 0				-- optional (indicates whether or not to include import/using statements for model class)
:setvar Namespace "Sandbox"			-- optional (the namespace of the project)
:setvar BaseClassModel ""			-- optional (the name of the base class for the model class)
:setvar BaseClassData ""			-- optional (the name of the base class for the data class)
:setvar FilterAll 0					-- optional (indicates if list stored procedure should have optional filters for all fields, or just primary key)
:setvar EnterpriseLibrary "5"		-- optional (the version of the enterprise library data access application blocks, e.g. 5 or 6)

-- model
:out $(output)\model"."$(language)
:r $(path)\model"\"$(language)\model-table.sql

-- procs
:out $(output)\procs.sql
:r $(path)\procs\list.sql
:r $(path)\procs\save.sql
:r $(path)\procs\delete.sql

-- data layer
:out $(output)\data"."$(language)
:r $(path)\data"\"$(language)\shell-start.sql
:r $(path)\data"\"$(language)\list.sql
:r $(path)\data"\"$(language)\save.sql
:r $(path)\data"\"$(language)\delete.sql
:r $(path)\data"\"$(language)\shell-end.sql

-- debug
:out stdout
!! ECHO $(output)
!! ECHO $(output)\procs.sql
!! ECHO $(output)\model.$(language)
!! ECHO $(output)\data.$(language)
--!! ECHO $(path)
--!! ECHO $(language)
--!! ECHO $(path)\step-01-model\$(language)
--!! ECHO $(path)\step-01-model\$(language)\model-table.sql