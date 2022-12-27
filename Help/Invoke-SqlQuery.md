
# Invoke-SqlQuery

## SYNOPSIS
Execute a Reader, RawReader, Scalar, or NonQuery SQL query with optional capture to a trace log.

## SYNTAX

### Reader (Server/Database, ConnectionString, Open Connection, Cached ConnectionString)
```
Invoke-SqlQuery [-Reader] [-Query] <String> [[-Params] <Hashtable>] [-Server] <String> [-Database] <String>
 [[-CommandTimeOut] <Int32>] [[-Credential] <PSCredential>] [[-FileName] <String>] [[-MapFields] <Hashtable>]
 [-TestMode] [<CommonParameters>]

Invoke-SqlQuery [-Reader] [-Query] <String> [[-Params] <Hashtable>] [-ConnectionString] <String>
 [[-CommandTimeOut] <Int32>] [[-Credential] <PSCredential>] [[-FileName] <String>] [[-MapFields] <Hashtable>]
 [-TestMode] [<CommonParameters>]

Invoke-SqlQuery [-Reader] [-Query] <String> [[-Params] <Hashtable>] [-Connection] <SqlConnection>
 [[-CommandTimeOut] <Int32>] [[-FileName] <String>] [[-MapFields] <Hashtable>] [-TestMode] [<CommonParameters>]

Invoke-SqlQuery [-Reader] [-Query] <String> [[-Params] <Hashtable>] [[-CommandTimeOut] <Int32>]
 [[-Credential] <PSCredential>] [[-FileName] <String>] [[-MapFields] <Hashtable>] [-TestMode]
 [<CommonParameters>]
```

### RawReader (Server/Database, ConnectionString, Open Connection, Cached ConnectionString)
```
Invoke-SqlQuery [-RawReader] [-Query] <String> [[-Params] <Hashtable>] [-Server] <String> [-Database] <String>
 [[-CommandTimeOut] <Int32>] [[-Credential] <PSCredential>] [[-FileName] <String>] [-TestMode]
 [<CommonParameters>]

Invoke-SqlQuery [-RawReader] [-Query] <String> [[-Params] <Hashtable>] [-ConnectionString] <String>
 [[-CommandTimeOut] <Int32>] [[-Credential] <PSCredential>] [[-FileName] <String>] [-TestMode]
 [<CommonParameters>]

Invoke-SqlQuery [-RawReader] [-Query] <String> [[-Params] <Hashtable>] [-Connection] <SqlConnection>
 [[-CommandTimeOut] <Int32>] [[-FileName] <String>] [-TestMode] [<CommonParameters>]

Invoke-SqlQuery [-RawReader] [-Query] <String> [[-Params] <Hashtable>] [[-CommandTimeOut] <Int32>]
 [[-Credential] <PSCredential>] [[-FileName] <String>] [-TestMode] [<CommonParameters>]
```

### Scalar (Server/Database, ConnectionString, Open Connection, Cached ConnectionString)
```
Invoke-SqlQuery [-Scalar] [-Query] <String> [[-Params] <Hashtable>] [-Server] <String> [-Database] <String>
 [[-CommandTimeOut] <Int32>] [[-Credential] <PSCredential>] [-TestMode] [<CommonParameters>]

Invoke-SqlQuery [-Scalar] [-Query] <String> [[-Params] <Hashtable>] [-ConnectionString] <String>
 [[-CommandTimeOut] <Int32>] [[-Credential] <PSCredential>] [-TestMode] [<CommonParameters>]

Invoke-SqlQuery [-Scalar] [-Query] <String> [[-Params] <Hashtable>] [-Connection] <SqlConnection>
 [[-CommandTimeOut] <Int32>] [-TestMode] [<CommonParameters>]

Invoke-SqlQuery [-Scalar] [-Query] <String> [[-Params] <Hashtable>] [[-CommandTimeOut] <Int32>]
 [[-Credential] <PSCredential>] [-TestMode] [<CommonParameters>]
```

### NonQuery (Server/Database, ConnectionString, Open Connection, Cached ConnectionString)
```
Invoke-SqlQuery [-NonQuery] [-Query] <String> [[-Params] <Hashtable>] [-Server] <String> [-Database] <String>
 [[-CommandTimeOut] <Int32>] [[-Credential] <PSCredential>] [-TestMode] [<CommonParameters>]

Invoke-SqlQuery [-NonQuery] [-Query] <String> [[-Params] <Hashtable>] [-ConnectionString] <String>
 [[-CommandTimeOut] <Int32>] [[-Credential] <PSCredential>] [-TestMode] [<CommonParameters>]

Invoke-SqlQuery [-NonQuery] [-Query] <String> [[-Params] <Hashtable>] [-Connection] <SqlConnection>
 [[-CommandTimeOut] <Int32>] [-TestMode] [<CommonParameters>]

Invoke-SqlQuery [-NonQuery] [-Query] <String> [[-Params] <Hashtable>] [[-CommandTimeOut] <Int32>]
 [[-Credential] <PSCredential>] [-TestMode] [<CommonParameters>]
```

## DESCRIPTION
The purpose of the Invoke-SqlQuery command is 1) to centralize all SQL calls a script makes to a single function, and 2) add the ability to trace SQL commands and query results obtained during execution of the script. Invoke-SqlQuery processes all 3 of the basic query types: Reader, Scalar, and NonQuery. Reader queries are implemented as SQL ExecuteSqlReader calls, Scalars as ExecuteScalar, and NonQuerys as ExecuteNonQuery.

Invoke-SqlQuery supports paramertized queries and both text and stored procedure query requests. To run a stored procedure, begin the query text with 'EXEC' followed by a space. To add parameters to a SQL query, use standard @arg1, @val notation in the Query text followed by a -Params @{ arg1 = 'Sales'; val = 'Qtr1' } Invoke-SqlQuery parameter to specify the values.

**Tracing**

Enable-SqlTrace activates an in-memory trace of each query processed by Invoke-SqlQuery. Trace items are PSObjects that contain the server (Srv) and database (DB) accessed, the query text (Cmd), query parameters (Parms), and the resulting output (Data). Trace information can be accessed as objects using Get-Trace and Get-TraceData or as string items suitable for viewing on the console or writing to a text file using Write-SqlTraceLog.

**Cached ConnectionString / Credentials**

In more complex scripts that access SQL multiple times, it is common for all queries to use the same connection string and login credential. Set-SqlCacheConnectionString and Set-SqlCacheCredential provide a way to specify those values one time vs.
having them scattered throughout the script.

**PlaceHolders**

Connection strings (both cached and directly passed) can specify an asterisk as the 'User ID'. The '*' indicates the 'User ID' and password are not in the connection string, but are stored in a cached SqlCredential object or passed directly using the -Credential parameter. The goal of place holders is to keep plain text passwords out of the script code.

**MapFields**

Invoke-SqlQuery's MapFields parameter adds the capability to rename columns post-query, remove trailing spaces, and apply formats to datetime and numeric fields. That functionality may sound more like the job of the user script than the query code, but having it built-in is nice when dealing with column names you have no control over, old databases that use fixed CHAR fields, and writing date and numeric data to a CSV file.

To rename columns, use a hashtable specifying old name to new name mapping:
```
    -MapFields @{ old = "New"; internal_id_code = "IDNum"; }
```
To add date and number formats follow the new name with a colon and a format code enclosed in pipes:
```
    -MapFields @{ sal = "Salary:|C2|"; hd = "Hire Date:|yy-MM-dd|" }
```
To trim trailing spaces from string values, use the keyword 'trim' as the the format value:
```
    -MapFields @{ lname_char40 = "Last Name:|trim|" }
```
Column renaming and trimming are always applicable. It is much easier to work with script code that reads like Item.IDNum than Item.internal_id_code or getting snared by trailing spaces on a text field. Number and date formatting only apply when results are exported to a CSV file. The reason is, numbers and dates retain their native type unless exported and formatting only applies to a string represenation.

**Reader vs. RawReader**

There are 2 modes of operation for Reader queries which are 'Reader' and 'RawReader'. Both are implemented as ExecuteSqlReader calls, however, if the -Reader switch is used Invoke-SqlQuery post-processes the output while -RawReader returns the data as is. Post-processing consists of translating DBNulls to PowerShell $nulls and processing the MapFields parameter if one is provided. In the C# version of the module, the post-processing overhead is close to zero, but in the native PowerShell version with large data sets it does introduce delay. There is a difference in output types between the native and C# versions also. RawReader queries return a DataTable in the C# compiled version of the module. The native PowerShell version returns an array of PSObjects.

## EXAMPLES

### EXAMPLE 1
```
$qry = "SELECT FirstName, LastName, Department FROM EmpTable WHERE Department = @dept"
$data = Invoke-SqlQuery -Reader -Query $qry -Params @{ 'dept' = "Finance" } -Server Srv1 -Database EmpDB
```
Run a 'Reader' TEXT query using a parameterized argument and Integrated Security.
To connect as a specific user, either use the 'Credential' parameter or the 'Set-SqlCacheCredential' cmdlet to pre-cache a credential.

### EXAMPLE 2
```
# -- Placed at beginning of script
Set-SqlCacheConnectionString "Server=srv1;Database=db;User ID=*"
Set-SqlCacheCredential -Credential $(Get-Credential)

...
# -- Subsequent calls to Invoke-SqlQuery omit ConnectionString/Credential
$data = Invoke-SqlQuery -Query $qry1 -Params $parms
```
This example shows pre-setting the connection string and credential to use for later calls to Invoke-SqlQuery. Pre-setting simplifies later calls to Invoke-SqlQuery since it now only needs SQL command values. Cached values may be overridden by supplying the parameter at the time of the call.

### EXAMPLE 3
```
$qry = "EXEC sp_DoStuff @yr, @dept"
$connStr = "Server=srv1;Database=erpDB;User ID=*"
$parms = @{ @yr = 2022; 'dept' = "Finance" }
$data = Invoke-SqlQuery -Reader -Query $qry -Params $parms -ConnectionString $connStr -Credential $cred
```
Run a 'Reader' stored procedure using a connection string. Connection strings, if provided, must include authentication either: 1) directly in string - i.e., User ID=user,Password=pass, 2) including "Integrated Security=true", or 3) or specify an '*' as the User ID and supply a Credential parameter or be able to retrieve a credential from the credential cache (see Set-SqlCacheCredential).

### EXAMPLE 4
```
$topSal = Invoke-SqlQuery -Scalar -Query "SELECT MAX(Salary) FROM EmpTable WHERE Department = 'Sales'" -Connection $conn
```
Run a Scalar query to find the top salary being paid to a Sales employee using an existing open connection.

### EXAMPLE 5
```
$nRows = Invoke-SqlQuery -NonQuery -Query "UPDATE Table2 SET status = '1' WHERE HireDate > '12/12/2022" -ConnectionString $connStr
```

Run a NonQuery query to update rows matching a criteria using a pre-defined connection string.

### EXAMPLE 7
```
$qry = "EXEC sp_GetEmpData @dept"
$parms = @{ dept = 'Accounting' }
$map = @{ first_name = 'First Name:|trim|'; last_name = 'Last Name'; hire_date = 'Hire Date:|yyyy-MM-dd|' }
$csv = "C:\Reports\HireDates.csv"
Invoke-SqlQuery -Query $qry -Params $parms -MapFields $map -FileName $csv   # assumes cached connection string and credential
```
Execute a stored procedure and send the results to a CSV file. Rename the first_name, last_name, and hire_date columns and apply yyyy-MM-dd formatting to the hire date. If first_name is of type CHAR(40) vs. VARCHAR(40), trailing spaces will be removed. Note the syntax for trims/formats - a colon after the name and the format code within pipes.

## PARAMETERS

### -Reader
Switch parameter identifying the query returns tabular results. DBNulls will be converted to PS nulls and MapFields may be applied.

```yaml
Type: SwitchParameter
Parameter Sets: Srv_Reader, ConnStr_Reader, Conn_Reader, Cache_Reader
Aliases:

Required: True
Position: 1
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -RawReader
Switch parameter identifying the query returns tabular results. DBNull conversions are not performed and mapping is not available. On large queries, faster then 'Reader' when using the the native PowerShell script vs. the compiled version.

```yaml
Type: SwitchParameter
Parameter Sets: Srv_RawReader, ConnStr_RawReader, Conn_RawReader, Cache_RawReader
Aliases:

Required: True
Position: 1
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Scalar
Switch parameter identifying the query returns a single data value.

```yaml
Type: SwitchParameter
Parameter Sets: Srv_Scalar, ConnStr_Scalar, Conn_Scalar, Cache_Scalar
Aliases:

Required: True
Position: 1
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NonQuery
Switch parameter identifying the query does not return values from the database. Use for INSERT, UPDATE, DELETE statements. Returns number of rows affected.

```yaml
Type: SwitchParameter
Parameter Sets: Srv_NonQuery, ConnStr_NonQuery, Conn_NonQuery, Cache_NonQuery
Aliases:

Required: True
Position: 1
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Query
The query string for the query.
Precede the 'EXEC ' or 'EXECUTE ' to run a stored procedure.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Params
Parameter table if using parameterized queries or a stored procedure. Pass as key/value pairs (hashtable).

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Connection
An existing open SqlConnection object to use for the query. If re-using connections your connection may require the MulipleActiveResultSets option in the initial connection string.

```yaml
Type: SqlConnection
Parameter Sets: Conn_Reader, Conn_RawReader, Conn_Scalar, Conn_NonQuery
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConnectionString
The connection string to use to connect to SQL for the query.

```yaml
Type: String
Parameter Sets: ConnStr_Reader, ConnStr_RawReader, ConnStr_Scalar, ConnStr_NonQuery
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Server
Server to connect to for the query (in place of a connection or connection string).

```yaml
Type: String
Parameter Sets: Srv_Reader, Srv_RawReader, Srv_Scalar, Srv_NonQuery
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Database
Database to connect to for the query (in place of a connection or connection string).

```yaml
Type: String
Parameter Sets: Srv_Reader, Srv_RawReader, Srv_Scalar, Srv_NonQuery
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CommandTimeOut
Time in seconds before the query times out.
Use for long running queries.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Credential

```yaml
Type: PSCredential
Parameter Sets: Srv_Reader, ConnStr_Reader, Cache_Reader, Srv_RawReader, ConnStr_RawReader, Cache_RawReader, Srv_Scalar, ConnStr_Scalar, Cache_Scalar, Srv_NonQuery, ConnStr_NonQuery, Cache_NonQuery
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileName
If specified, the output of the query will be output to this file as a CSV rather than going to the output stream.

```yaml
Type: String
Parameter Sets: Srv_Reader, ConnStr_Reader, Conn_Reader, Cache_Reader, Srv_RawReader, ConnStr_RawReader, Conn_RawReader, Cache_RawReader
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MapFields
Rename columns, trim trailing spaces from strings, or apply formatting to date/time fields and numerics. Invoke-SqlQuery description has usage.

```yaml
Type: Hashtable
Parameter Sets: Srv_Reader, ConnStr_Reader, Conn_Reader, Cache_Reader
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TestMode
Builds SqlCommmand object and returns it without executing. Does not open a SqlConnection.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### A DataTable object, list of PSObjects, CSV string, or returned object for non-tabular queries.
## NOTES
Author: Mike Dumdei

## RELATED LINKS
[Set-SqlCacheCredential](./Set-SqlCacheCredential.md), [Set-SqlCacheConnectionString](./Set-SqlCacheConnectionString.md),
[Enable-SqlTrace](./Enable-SqlTrace.md)

