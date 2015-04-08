# SQL Code Generation Tool

These scripts started in late 2010 when I simply got tired of manually coding VB.Net model classes. Over time, I added additional scripts to code gen the basic stored procedures, model classes, and data layer classes that I generally needed for each entity in my project. The stored procedureds are the basic list/save/delete variety. Initially the scripts only generated VB.Net code for the model/data layers; however, they now support both `VB.Net` and `C#`.

The scripts have went through 3 major rewrites/refactoring to get to their current version (v3.0) and now work with `SQLCMD`, which makes generating your files (procs, model, data) very simple.

Please keep in mind these scripts were written for a specific style of n-tier architecture, so they may or may not fit your needs out of the box. For most of the applications I work on there is a `Web` layer, `Model` layer, `Data` layer, and a backend `SQL Server` database (business/data).

These scripts more or less automated 90% of the routine tasks I would encounter after designing a database/table. I almost exclusively use these scripts to create the `initial` set of [stored procedures](https://github.com/mpavey/sql-code-gen/wiki/Example-SQL-Output), model classes ([C#](https://github.com/mpavey/sql-code-gen/wiki/Example-Model-Class-(C%23)), [VB.Net](https://github.com/mpavey/sql-code-gen/wiki/Example-Model-Class-(VB.Net))), and data layer classes ([C#](https://github.com/mpavey/sql-code-gen/wiki/Example-Data-Class-(C%23)), [VB.Net](https://github.com/mpavey/sql-code-gen/wiki/Example-Data-Class-(VB.Net))). Once generated I customize them as-needed to fit the project's needs (e.g. adding advanced filtering to stored procedures, adding derived properties to the model class, etc).

Requirements
-----------
- `Microsoft SQL Server` (2008, 2012, 2014)
- `Microsoft Enterprise Library Data Access Application Block` (5.0, 6.0)
- Assumes the table(s) you are generating code for have a single `primary key column`
- Extension methods to convert `DataTable` to `ToList<T>` (`Extensions.cs` and `Extensions.vb` are located in `/source/extensions`)

Instructions
-----------
- Use the `Download ZIP` button from the `sql-code-gen` repository to download the full set of files
- Extract the scripts from the ZIP file to your local drive
- Open `SQL Server Management Studio`
- Connect to your SQL server
- Select your database
- Open the `sqlcmd.sql` file from where you extracted the scripts
- Go to the `Query` menu and choose `SQLCMD Mode`
- Set the `REQUIRED SETTINGS` as needed
- Set the `OPTIONAL SETTINGS` as needed

The scripts will run and create the output files, for example:

- C:\Users\matt\Desktop\temp\codegen\sql\procs.sql
- C:\Users\matt\Desktop\temp\codegen\model\model.cs
- C:\Users\matt\Desktop\temp\codegen\data\data.cs

Author
------------
[Matt Pavey](http://www.pavey.me) is a Microsoft Certified software developer who specializes in ASP.Net, VB.Net, C#, AJAX, LINQ, XML, XSL, Web Services, SQL, jQuery, and more. Follow on Twitter [@matthewpavey](https://twitter.com/matthewpavey)
