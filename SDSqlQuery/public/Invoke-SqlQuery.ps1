function Invoke-SqlQuery  {
<#    
.SYNOPSIS
Execute a Reader, Scalar, or NonQuery SQL query with option to capture trace log.
.DESCRIPTION
The purpose of the Invoke-SqlQuery cmdlet is to centralize all SQL calls a script makes to a single function 
as well as provide a 'trace' feature. The cmdlet performs the standard 3 types of queries: Reader, Scalar, 
and NonQuery. Reader queries are returned as an array of PSObjects, Scalars return a single data item, and 
NonQuery queries return the number of affected rows. RawReader queries return a DataTable in the C# compiled
version of the module and an array of PSObjects in the PowerShell native script version.

Queries may be either 'CommandText' or 'Stored Procedure' queries with automatic detection of the type by
preceeding the -Query string with 'EXEC ' or 'EXECUTE ' if the query is to execute a stored procedure.

Query parameters are passed as a hash table, examples:

TEXT query with parameter:
  $nDel = Invoke-SqlQuery -NonQuery -Query "DELETE FROM Table1 WHERE AppDate < @date" -Params @{ date = '1/1/2020' }

Stored Procedure with parameters:
  $qryStr = "EXEC sp_SomeProc @param1, @param2"
  $parms = @{ param1 = '1/1/2023'; param2 = 'Sales' }
  $data = Invoke-SqlQuery -Reader -Query $qryStr -Params $parms ....

Columns can be renamed post-query, trailing spaces on fixed CHAR columns trimmed, and numeric/datetime formats
applied using the MapFields switch. Formatting, if specified, is enclosed in pipes ('|') and follows the target column 
name. The keyword 'trim' trims trailing spaces from CHAR fields  Example uses of MapFields:

  Invoke-SqlQuery .... -MapFields @{ 'oldColName' = "NewName"; 'Was' = "IsNowThis" } .... # Rename output columns
  Invoke-SqlQuery .... -MapFields @{ fixed_CHAR40_col = "NewNameNoSpaces:|trim|" }   .... # Trim trailing spaces
  Invoke-SqlQuery .... -MapFields @{ hiredate = "Hire Date:|yyyy-MM-dd|"; amt = "Amount:|C2|" } # Formatting

Tabular queries can be retreived with either the 'Reader' or 'RawReader' switches. The module containing Invoke-SqlQuery
is produced as both a PowerShell native script and a compiled C# version. If using the native PowerShell version,
you will find RawReader results are PSOBject arrays and queries producing a large number of rows are much slower for Reader
queries than RawReader. In the C# compiled version, there is little difference in processing time whether using Reader or 
RawReader and the results of RawReader is a DataTable object. In both versions, Reader queries convert DBNull::Value to 
PowerShell nulls and support the '-MapFields' option. RawReader does neither.

Trace logs are optional. When enabled, all queries, parameters passed, and results are captured for later review or export 
to a log file. See Set-SqlTraceOption, Get-SqlTrace, and Write-SqlTraceLog.

See Set-SqlCredential for options to preset the SQL logon credentials for Invoke-SqlQuery queries.
.PARAMETER Reader
Switch parameter identifying the query returns tabular results. DBNulls will be converted to PS nulls and
MapFields may be applied.
.PARAMETER RawReader
Switch parameter identifying the query returns tabular results. DBNull conversions are not performed
and mapping is not available. On large queries, faster then 'Reader' when using the the native PowerShell script 
vs. the compiled version.
.PARAMETER Scalar
Switch parameter identifying the query returns a single data value.
.PARAMETER NonQuery
Switch parameter identifying the query does not return values from the database. Use for INSERT, UPDATE, 
DELETE statements. Returns number of rows affected.
.PARAMETER Query
The query string for the query. Precede the 'EXEC ' or 'EXECUTE ' to run a stored procedure.
.PARAMETER Params
Parameter table if using parameterized queries or a stored procedure. Pass as key/value pairs (hashtable).
.PARAMETER MapFields
Rename columns, trim trailing spaces from strings, or apply formatting to date/time fields and 
numerics. Invoke-SqlQuery description has usage.
.PARAMETER CmdTimeOut
Time in seconds before the query times out. Use for long running queries.
.PARAMETER ConnectionString
The connection string to use to connect to SQL for the query.
.PARAMETER Connection
An existing open SqlConnection object to use for the query. If re-using connections your connection probably will
need the MulipleActiveResultSets option in the initial connection string.
.PARAMETER Server
Server to connect to for the query (in place of a connection or connection string).
.PARAMETER Database
Database to connect to for the query (in place of a connection or connection string).
.PARAMETER FileName
If specified, the output of the query will be output to this file as a CSV rather than going to the output stream. 
.PARAMETER Silent
Suppresses console warning/error messages.
.INPUTS
This cmdlet does not accept pipeline input.
.OUTPUTS
A DataTable object, list of PSObjects, CSV string, or returned object for non-tabular queries.
.EXAMPLE
PS> $qry = "SELECT FirstName, LastName, Department FROM EmpTable WHERE Department = @dept"
PS> $data = Invoke-SqlQuery -Reader -Query $qry -Params @{ 'dept' = "Finance" } -Server Srv1 -Database EmpDB

Run a 'Reader' TEXT query using a parameterized argument using Integrated Security. To connect as a specific
user, either use the 'Credential' parameter or the 'Set-SqlCacheCredential' cmdlet to pre-cache a credential.
.EXAMPLE
PS> $qry = "EXEC sp_DoStuff @yr, @dept"

PS> $connStr = "Server=srv1;Database=erpDB;Username=Jake;Password=123"
PS> $parms = @{ @yr = 2022; 'dept' = "Finance" }
PS> $data = Invoke-SqlQuery -Reader -Query $qry -Params $parms -ConnectionString $connStr

Run a 'Reader' stored procedure using a connection string. If the connection string does not include login credentials,
you can use -Credential to provide credentials or you can use the Set-Credential cmdlet to preset the login user for
the connection.
.EXAMPLE
PS> $topSal = Invoke-SqlQuery -Scalar -Query "SELECT MAX(Salary) FROM EmpTable WHERE Department = 'Sales'" -Connection $conn

Run a Scalar query to find the top salary being paid to a Sales employee using an existing open connection.
.EXAMPLE
PS> $nRows = Invoke-SqlQuery -NonQuery -Query "UPDATE Table2 SET status = '1' WHERE HireDate > '12/12/2022" -ConnectionString $connStr

Run a NonQuery query to update rows matching a criteria using a pre-defined connection string.
.EXAMPLE
PS> $connStr = "Server=srv1;Database=db1;User ID=|user|;Password=|pw|;"
PS> $results = Invoke-SqlQuery .... -ConnectionString $connStr -Credential $cred

This partial example shows using a ConnectionString with placeholder values. The placehoders "|user|" and 
"|pw|" will be replaced with the values found in the Credential parameter. The credential could also come
out of the credential cache (See Set-SqlCacheCredential). This is more secure than using plaintext passwords
in connection strings.
.EXAMPLE
PS>  # Beginning of script
PS> Set-SqlCacheConnectionString "Server=srv1;Database=db"
PS> Set-SqlCacheCredential -Credential $(Get-Credential)
...
PS>  # Subsequent calls to Invoke-SqlQuery may omit ConnectionString/Credential
PS> $data = Invoke-SqlQuery -Query $qry1 -Params $parms

This example shows pre-setting the connection string and credential to use for later calls to
Invoke-SqlQuery. Pre-setting simplifies later calls to Invoke-SqlQuery since it now only needs
SQL command values. Cached values may be overridden by supplying the parameter at the time of 
the call.
.EXAMPLE
PS> $qry = "EXEC sp_GetEmpData @dept"
PS> $parms = @{ dept = 'Accounting' }
PS> $map = @{ first_name = 'First Name:|trim|'; last_name = 'Last Name'; hire_date = 'Hire Date:|yyyy-MM-dd|' }
PS> $csv = "C:\Reports\HireDates.csv"
PS> Invoke-SqlQuery -Query $qry -Params $parms -MapFields $map -FileName $csv -Credential $creds

Execute a stored procedure and send the results to a CSV file. Rename the first_name, last_name, and hire_date 
columns and apply yyyy-MM-dd formatting to the hire date. If first_name is of type CHAR(40) vs. VARCHAR(40), trailing
spaces will be removed. Note the syntax for trims/formats - a colon after the name and the format code within pipes.
.NOTES
Author: Mike Dumdei
#>
    [CmdletBinding()]
    [OutputType([Object], ParameterSetName=("Srv_Scalar", "Conn_Scalar", "Conn_Scalar"))]    
    [OutputType([Int32], ParameterSetName=("Srv_NonQuery ", "Conn_NonQuery", "ConnStr_NonQuery"))]    
    [OutputType([PSCustomObject[]], ParameterSetName=("Srv_Reader", "Conn_Reader", "ConnStr_Reader"))]
    [OutputType([DataTable], ParameterSetName=("Srv_RawReader", "Conn_RawReader", "ConnStr_RawReader"))]
    Param (
          # Reader (query type)
        [Parameter(Position = 0, ParameterSetName = "Conn_Reader", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "ConnStr_Reader", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "Srv_Reader", Mandatory)]
        [Switch]$Reader,
          # RawReader (query type)
        [Parameter(Position = 0, ParameterSetName = "Conn_RawReader", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "ConnStr_RawReader", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "Srv_RawReader", Mandatory)]
        [Switch]$RawReader,
          # Scalar (query type)
        [Parameter(Position = 0, ParameterSetName = "Conn_Scalar", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "ConnStr_Scalar", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "Srv_Scalar", Mandatory)]
        [Switch]$Scalar,
          # NonQuery (query type)
        [Parameter(Position = 0, ParameterSetName = "Conn_NonQuery", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "ConnStr_NonQuery", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "Srv_NonQuery", Mandatory)]
        [Switch]$NonQuery,
          # Query String
        [Parameter(Position = 2, Mandatory)]
        [string]$Query,
          # Query Parameters 
        [Parameter(Position = 2)]
        [HashTable]$Params,
          # Conn
        [Parameter(Position = 3, ParameterSetName = "Conn_Reader", Mandatory)]
        [Parameter(Position = 3, ParameterSetName = "Conn_RawReader", Mandatory)]
        [Parameter(Position = 3, ParameterSetName = "Conn_Scalar", Mandatory)]
        [Parameter(Position = 3, ParameterSetName = "Conn_NonQuery", Mandatory)]
        [SqlConnection]$SqlConn, 
          # ConnString
        [Parameter(Position = 3, ParameterSetName = "ConnStr_Reader", Mandatory)]
        [Parameter(Position = 3, ParameterSetName = "ConnStr_RawReader", Mandatory)]
        [Parameter(Position = 3, ParameterSetName = "ConnStr_Scalar", Mandatory)]
        [Parameter(Position = 3, ParameterSetName = "ConnStr_NonQuery", Mandatory)]
        [string]$SqlConnString,
          # Server
        [Parameter(Position = 3, ParameterSetName = "Srv_Reader", Mandatory)]
        [Parameter(Position = 3, ParameterSetName = "Srv_RawReader", Mandatory)]
        [Parameter(Position = 3, ParameterSetName = "Srv_Scalar", Mandatory)]
        [Parameter(Position = 3, ParameterSetName = "Srv_NonQuery", Mandatory)]
        [string]$Server,
          # Database
        [Parameter(Position = 4, ParameterSetName = "Srv_Reader", Mandatory)]
        [Parameter(Position = 4, ParameterSetName = "Srv_RawReader", Mandatory)]
        [Parameter(Position = 4, ParameterSetName = "Srv_Scalar", Mandatory)]
        [Parameter(Position = 4, ParameterSetName = "Srv_NonQuery", Mandatory)]
        [string]$Database,
          # CmdTimeout
        [Parameter(Position = 5)][Int32]$CmdTimeOut,
          # Credential
        [Parameter(Position = 6, ParameterSetName = "Srv_Reader")]
        [Parameter(Position = 6, ParameterSetName = "Srv_RawReader")]
        [Parameter(Position = 6, ParameterSetName = "Srv_Scalar")]
        [Parameter(Position = 6, ParameterSetName = "Srv_NonQuery")]        
        [Parameter(Position = 6, ParameterSetName = "ConnStr_Reader")]
        [Parameter(Position = 6, ParameterSetName = "ConnStr_RawReader")]
        [Parameter(Position = 6, ParameterSetName = "ConnStr_Scalar")]
        [Parameter(Position = 6, ParameterSetName = "ConnStr_NonQuery")]
        [PSCredential]$Credential,
          # FileName
        [Parameter(Position = 7, ParameterSetName = "Srv_Reader")]
        [Parameter(Position = 7, ParameterSetName = "ConnStr_Reader")]
        [Parameter(Position = 7, ParameterSetName = "Conn_Reader")]
        [Parameter(Position = 7, ParameterSetName = "Srv_RawReader")]
        [Parameter(Position = 7, ParameterSetName = "ConnStr_RawReader")]
        [Parameter(Position = 7, ParameterSetName = "Conn_RawReader")]
        [string]$FileName,
         # MapFields
        [Parameter(Position = 8, ParameterSetName = "Srv_Reader")]
        [Parameter(Position = 8, ParameterSetName = "ConnStr_Reader")]
        [Parameter(Position = 8, ParameterSetName = "Conn_Reader")]
        [hashtable]$MapFields,
          # Silent
        [Parameter(Position = 9)][Switch]$Silent
    )

    begin {
        if ($PSBoundParameters.ContainsKey('SqlConn') -eq $false) {
            if ($null -ne $Credential) {
                $SqlConn = Get-SqlConnection -Server $Server -Database $Database -Credential $Credential
            } else {
                $SqlConn = Get-SqlConnection -Server $Server -Database $Database
            }
        } elseif ($SqlConn.State -ne [ConnectionState]::Open) {
            throw "SQL connection not in open state"
        }
        if ($PSBoundParameters.ContainsKey('MapFields') -eq $false) { 
            $MapFields = @{}
        }
    } 
    process {
        try {  
            [SqlCommand]$cmd = $SqlConn.CreateCommand()
            $Query = $Query.Trim()
            if ( $Query.Substring(0, 5) -eq 'EXEC ' -or $Query.Substring(0, 8) -eq 'EXECUTE ') {
                $cmd.CommandType = [CommandType]::StoredProcedure
                $Query = $Query.Substring($Query.IndexOf(' ') + 1)
            } else {
                $cmd.CommandType = [CommandType]::Text
            }
            $cmd.CommandText = $Query
            if ($Params.Count -gt 0) {
                $Params.GetEnumerator() | ForEach-Object {
                    $cmd.Parameters.AddWithValue("@$($_.Key)", $($_.Value)) | Out-Null
                }
            }
            if ($PSBoundParameters.ContainsKey('CmdTimeout')) {
                $cmd.CommandTimeout = $CmdTimeOut
            }
            if ($(Get-SqlTraceEnabled)) {
                [SqlTrace]$logObj = New-Object SqlTrace $Server, $Database, $Query, $SqlParams
            }
            if ($Reader -or $RawReader) {   # returns tabular data  
                [DataTable]$dt = New-Object DataTable
                $dt.Load($cmd.ExecuteReader()) | Out-Null
                if ($null -ne $logObj) { $logObj.Data = $dt }
                if ($PSBoundParameters.ContainsKey('FileName')) {
                    $(ConvertDataTableToCsv $dt $MapFields).ToString() | Out-File $FileName
                    return      # no return value for pipeline, CSV file is only output
                } elseif ($RawReader) {
                    $rval = $dt
                } else {
                    $rval = Convert-QueryToObjects -Table $dt -MapFields $MapFields
                }
            } elseif ($NonQuery) {              # returns count of rows affected
                $rowCount = $cmd.ExecuteNonQuery()
                if ($null -ne $logObj) { $logObj.Data = $rowCount }
                $rval = $rowCount
            } else {                            # pull single value
                $obj = $cmd.ExecuteScalar()
                if ($null -ne $logObj) { $logObj.Data = $obj }
                $rval = $obj
            } 
            return $rval
        } catch { 
            if ($Silent -eq $false) {
                Write-Host
                Write-Host -ForegroundColor Red '-- Error executing SQL command:'
                Write-Host $Query
                Write-Host -ForegroundColor Red '-------------------------------'
                Write-Host -ForegroundColor Red $Error[0].ToString()
            }
            if ($null -ne $logObj) { $logObj.data = $Error[0] }
            throw    # re-throw so error is propagated and script aborted if not handled
    } end {
        } finally { 
            if ($null -ne $SqlConn) { $SqlConn.Close() }
        }
    }
}
