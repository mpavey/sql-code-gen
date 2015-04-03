# sql-code-gen
SQL Code Generation Tool

- Copy the scripts to your local drive
- Open SQL Server Management Studio
- Connect to your SQL server
- Select your database
- Open sqlcmd.sql (in the root of the source folder)
- Go to the Query menu and choose SQLCMD Mode
- Set the path to the path where you copied the scripts
- Set the language to cs or vb depending on what type of files you are generating
- Set the output folder where you want the output files created
- Set the required/optional variables as needed for the table you are code-generating

The scripts will run and create the output files, for example:

- C:\Users\matt\Desktop\temp\procs.sql
- C:\Users\matt\Desktop\temp\model.cs
- C:\Users\matt\Desktop\temp\data.cs
