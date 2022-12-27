function Invoke-SqlQuery  {
<#
.SYNOPSIS
    Execute a Reader, RawReader, Scalar, or NonQuery SQL query with optional capture to a trace log.
.DESCRIPTION
    The purpose of the Invoke-SqlQuery command is 1) to centralize all SQL calls a script makes to a single function, and 2) add the ability to trace SQL commands and query results obtained during execution of the script. Invoke-SqlQuery processes all 3 of the basic query types: Reader, Scalar, and NonQuery. Reader queries are implemented as SQL ExecuteSqlReader calls, Scalars as ExecuteScalar, and NonQuerys as ExecuteNonQuery.

    Invoke-SqlQuery supports paramertized queries and both text and stored procedure query requests. To run a stored procedure, begin the query text with 'EXEC' followed by a space. To add parameters to a SQL query, use standard @arg1, @val notation in the Query text followed by a -Params @{ arg1 = 'Sales'; val = 'Qtr1' } Invoke-SqlQuery parameter to specify the values.

    -- Tracing --
    Enable-SqlTrace activates an in-memory trace of each query processed by Invoke-SqlQuery. Trace items are PSCustomObjects that contain the server (Srv) and database (DB) accessed, the query text (Cmd), query parameters (Parms), and the resulting output (Data). Trace information can be accessed as objects using Get-Trace and Get-TraceData or as string items suitable for viewing on the console or writing to a text file using Write-SqlTraceLog. 

    -- Cached ConnectionString / Credentials --
    In more complex scripts that access SQL multiple times, it is common for all queries to use the same connection string and login credential. Set-SqlCacheConnectionString and Set-SqlCacheCredential provide a way to specify those values one time vs. having them scattered throughout the script. 

    -- PlaceHolders --
    Connection strings (both cached and directly passed) can specify an asterisk as the 'User ID'. The '*' indicates the 'User ID' and password are not in the connection string, but are stored in a cached SqlCredential object or passed directly using the -Credential parameter. The goal of place holders is to keep plain text passwords out of the script code.
    
    -- MapFields --
    Invoke-SqlQuery's MapFields parameter adds the capability to rename columns post-query, remove trailing spaces, and apply formats to datetime and numeric fields. That functionality may sound more like the job of the user script than the query code, but having it built-in is nice when dealing with column names you have no control over, old databases that use fixed CHAR fields, and writing date and numeric data to a CSV file.

    To rename columns, use a hashtable specifying old name to new name mapping:

        -MapFields @{ old = "New"; internal_id_code = "IDNum"; }

    To add date and number formats follow the new name with a colon and a format code enclosed in pipes:

        -MapFields @{ sal = "Salary:|C2|"; hd = "Hire Date:|yy-MM-dd|" }

    To trim trailing spaces from string values, use the keyword 'trim' as the the format value:

        -MapFields @{ lname_char40 = "Last Name:|trim|" }

    Column renaming and trimming are always applicable. It is much easier to work with script code that reads like Item.IDNum than Item.internal_id_code or getting snared by trailing spaces on a text field. Number and date formatting only apply when results are exported to a CSV file. The reason is, numbers and dates retain their native type unless exported and formatting only applies to a string represenation. 

    -- Reader vs. RawReader --
    There are 2 modes of operation for Reader queries which are 'Reader' and 'RawReader'. Both are implemented as ExecuteSqlReader calls, however, if the -Reader switch is used Invoke-SqlQuery post-processes the output while -RawReader returns the data as is. Post-processing consists of translating DBNulls to PowerShell $nulls and processing the MapFields parameter if one is provided. In the C# version of the module, the post-processing overhead is close to zero, but in the native PowerShell version with large data sets it does introduce delay. There is a difference in output types between the native and C# versions also. RawReader queries return a DataTable in the C# compiled version of the module. The native PowerShell version returns an array of PSCustomObjects.  
.PARAMETER Reader
    Switch parameter identifying the query returns tabular results. DBNulls will be converted to PS nulls and MapFields may be applied.
.PARAMETER RawReader
    Switch parameter identifying the query returns tabular results. DBNull conversions are not performed and mapping is not available. On large queries, faster then 'Reader' when using the the native PowerShell script vs. the compiled version.
.PARAMETER Scalar
    Switch parameter identifying the query returns a single data value.
.PARAMETER NonQuery
    Switch parameter identifying the query does not return values from the database. Use for INSERT, UPDATE, DELETE statements. Returns number of rows affected.
.PARAMETER Query
    The query string for the query. Precede the 'EXEC ' or 'EXECUTE ' to run a stored procedure.
.PARAMETER Params
    Parameter table if using parameterized queries or a stored procedure. Pass as key/value pairs (hashtable).
.PARAMETER MapFields
    Rename columns, trim trailing spaces from strings, or apply formatting to date/time fields and numerics. Invoke-SqlQuery description has usage.
.PARAMETER CommandTimeOut
    Time in seconds before the query times out. Use for long running queries.
.PARAMETER ConnectionString
    The connection string to use to connect to SQL for the query.
.PARAMETER Connection
    An existing open SqlConnection object to use for the query. If re-using connections your connection may require the MulipleActiveResultSets option in the initial connection string.
.PARAMETER Server
    Server to connect to for the query (in place of a connection or connection string).
.PARAMETER Database
    Database to connect to for the query (in place of a connection or connection string).
.PARAMETER FileName
    If specified, the output of the query will be output to this file as a CSV rather than going to the output stream.
.PARAMETER TestMode
    Builds SqlCommmand object and returns it without executing. Does not open a SqlConnection.
.INPUTS
    None.
.OUTPUTS
    A DataTable object, list of PSObjects, CSV string, or returned object for non-tabular queries.
.EXAMPLE
    PS:\>$qry = "SELECT FirstName, LastName, Department FROM EmpTable WHERE Department = @dept"
    PS:\>$data = Invoke-SqlQuery -Reader -Query $qry -Params @{ 'dept' = "Finance" } -Server Srv1 -Database EmpDB

    Run a 'Reader' TEXT query using a parameterized argument and Integrated Security. To connect as a specific user, either use the 'Credential' parameter or the 'Set-SqlCacheCredential' cmdlet to pre-cache a credential.
.EXAMPLE
    PS:\># Beginning of script
    PS:\>Set-SqlCacheConnectionString "Server=srv1;Database=db;User ID=*"
    PS:\>Set-SqlCacheCredential -Credential $(Get-Credential)
    ...
    PS:\># Subsequent calls to Invoke-SqlQuery omit ConnectionString/Credential
    PS:\>$data = Invoke-SqlQuery -Query $qry1 -Params $parms

    This example shows pre-setting the connection string and credential to use for later calls to Invoke-SqlQuery. Pre-setting simplifies later calls to Invoke-SqlQuery since it now only needs SQL command values. Cached values may be overridden by supplying the parameter at the time of the call.
.EXAMPLE
    PS:\>$qry = "EXEC sp_DoStuff @yr, @dept"
    PS:\>$connStr = "Server=srv1;Database=erpDB;User ID=*"
    PS:\>$parms = @{ @yr = 2022; 'dept' = "Finance" }
    PS:\>$data = Invoke-SqlQuery -Reader -Query $qry -Params $parms -ConnectionString $connStr -Credential $cred

    Run a 'Reader' stored procedure using a connection string. Connection strings, if provided, must include authentication either: 1) directly in string - i.e., User ID=user,Password=pass, 2) including "Integrated Security=true", or 3) or specify an '*' as the User ID and supply a Credential parameter or be able to retrieve a credential from the credential cache (see Set-SqlCacheCredential).
.EXAMPLE
    PS:\>$topSal = Invoke-SqlQuery -Scalar -Query "SELECT MAX(Salary) FROM EmpTable WHERE Department = 'Sales'" -Connection $conn

    Run a Scalar query to find the top salary being paid to a Sales employee using an existing open connection.
.EXAMPLE
    PS:\>$nRows = Invoke-SqlQuery -NonQuery -Query "UPDATE Table2 SET status = '1' WHERE HireDate > '12/12/2022" -ConnectionString $connStr

    Run a NonQuery query to update rows matching a criteria using a pre-defined connection string.
.EXAMPLE
    PS:\>$qry = "EXEC sp_GetEmpData @dept"
    PS:\>$parms = @{ dept = 'Accounting' }
    PS:\>$map = @{ first_name = 'First Name:|trim|'; last_name = 'Last Name'; hire_date = 'Hire Date:|yyyy-MM-dd|' }
    PS:\>$csv = "C:\Reports\HireDates.csv"
    PS:\>Invoke-SqlQuery -Query $qry -Params $parms -MapFields $map -FileName $csv   # assumes cached connection string and credential

    Execute a stored procedure and send the results to a CSV file. Rename the first_name, last_name, and hire_date columns and apply yyyy-MM-dd formatting to the hire date. If first_name is of type CHAR(40) vs. VARCHAR(40), trailing spaces will be removed. Note the syntax for trims/formats - a colon after the name and the format code within pipes.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding()]
    [OutputType([Object], ParameterSetName=("Srv_Scalar", "Conn_Scalar", "ConnStr_Scalar","Cache_Scalar"))]
    [OutputType([Int32], ParameterSetName=("Srv_NonQuery ", "Conn_NonQuery", "ConnStr_NonQuery","Cache_NonQuery"))]
    [OutputType([PSCustomObject[]], ParameterSetName=("Srv_Reader", "Conn_Reader", "ConnStr_Reader","Cache_Reader"))]
    [OutputType([System.Data.DataTable], ParameterSetName=("Srv_RawReader", "Conn_RawReader", "ConnStr_RawReader","Cache_RawReader"))]
    Param (
          # Reader (query type)
        [Parameter(Position = 0, ParameterSetName = "Cache_Reader", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "Conn_Reader", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "ConnStr_Reader", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "Srv_Reader", Mandatory)]
        [Switch]$Reader,
          # RawReader (query type)
        [Parameter(Position = 0, ParameterSetName = "Cache_RawReader", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "Conn_RawReader", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "ConnStr_RawReader", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "Srv_RawReader", Mandatory)]
        [Switch]$RawReader,
          # Scalar (query type)
        [Parameter(Position = 0, ParameterSetName = "Cache_Scalar", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "Conn_Scalar", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "ConnStr_Scalar", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "Srv_Scalar", Mandatory)]
        [Switch]$Scalar,
          # NonQuery (query type)
        [Parameter(Position = 0, ParameterSetName = "Cache_NonQuery", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "Conn_NonQuery", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "ConnStr_NonQuery", Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "Srv_NonQuery", Mandatory)]
        [Switch]$NonQuery,
          # Query String
        [Parameter(Position = 1, Mandatory)]
        [string]$Query,
          # Query Parameters
        [Parameter(Position = 2)]
        [HashTable]$Params,
          # Conn
        [Parameter(Position = 3, ParameterSetName = "Conn_Reader", Mandatory)]
        [Parameter(Position = 3, ParameterSetName = "Conn_RawReader", Mandatory)]
        [Parameter(Position = 3, ParameterSetName = "Conn_Scalar", Mandatory)]
        [Parameter(Position = 3, ParameterSetName = "Conn_NonQuery", Mandatory)]
        [System.Data.SqlClient.SqlConnection]$Connection,
          # ConnString
        [Parameter(Position = 3, ParameterSetName = "ConnStr_Reader",Mandatory)]
        [Parameter(Position = 3, ParameterSetName = "ConnStr_RawReader",Mandatory)]
        [Parameter(Position = 3, ParameterSetName = "ConnStr_Scalar",Mandatory)]
        [Parameter(Position = 3, ParameterSetName = "ConnStr_NonQuery",Mandatory)]
        [string]$ConnectionString,
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
          # CommandTimeOut
        [Parameter(Position = 5)][Int32]$CommandTimeOut,
          # Credential
        [Parameter(Position = 6, ParameterSetName = "Cache_Reader")]
        [Parameter(Position = 6, ParameterSetName = "Cache_RawReader")]
        [Parameter(Position = 6, ParameterSetName = "Cache_Scalar")]
        [Parameter(Position = 6, ParameterSetName = "Cache_NonQuery")]
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
        [Parameter(Position = 7, ParameterSetName = "Cache_Reader")]
        [Parameter(Position = 7, ParameterSetName = "Cache_RawReader")]
        [Parameter(Position = 7, ParameterSetName = "Srv_Reader")]
        [Parameter(Position = 7, ParameterSetName = "ConnStr_Reader")]
        [Parameter(Position = 7, ParameterSetName = "Conn_Reader")]
        [Parameter(Position = 7, ParameterSetName = "Srv_RawReader")]
        [Parameter(Position = 7, ParameterSetName = "ConnStr_RawReader")]
        [Parameter(Position = 7, ParameterSetName = "Conn_RawReader")]
        [string]$FileName,
         # MapFields
        [Parameter(Position = 8, ParameterSetName = "Cache_Reader")]
        [Parameter(Position = 8, ParameterSetName = "Srv_Reader")]
        [Parameter(Position = 8, ParameterSetName = "ConnStr_Reader")]
        [Parameter(Position = 8, ParameterSetName = "Conn_Reader")]
        [hashtable]$MapFields,
          # Test
        [Parameter(Position = 9)][Switch]$TestMode
    )
    begin {
        [System.Data.SqlClient.SqlConnection]$sqlConn = $null
        if ($PSBoundParameters.ContainsKey('Connection') -eq $true) {
            $sqlConn = $Connection
            if ($SqlConn.State -ne [System.Data.ConnectionState]::Open -and !$TestMode) {
                throw "SQL connection not in open state"
            }
        } else {
            $splat = @{}
            if (![string]::IsNullOrEmpty($ConnectionString)) { $splat.Add('ConnectionString', $ConnectionString) }
            if (![string]::IsNullOrEmpty($Server)) { $splat.Add('Server', $Server) }
            if (![string]::IsNullOrEmpty($Database)) { $splat.Add('Database', $Database) }
            if ($null -ne $Credential) { $splat.Add('Credential', $Credential) }
            $SqlConn = Open-SqlConnection @splat -NoOpen:$TestMode
        } 
        $Server = $sqlConn.DataSource
        $Database = $sqlConn.Database
        if ($PSBoundParameters.ContainsKey('MapFields') -eq $false) {
            $MapFields = @{}
        }
    }
    process {
        try {
            [System.Data.SqlClient.SqlCommand]$cmd = $SqlConn.CreateCommand()
            $Query = $Query.Trim()
            if ( $Query.Substring(0, 5) -eq 'EXEC ' -or $Query.Substring(0, 8) -eq 'EXECUTE ') {
                $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
                $Query = $Query.Substring($Query.IndexOf(' ') + 1)
            } else {
                $cmd.CommandType = [System.Data.CommandType]::Text
            }
            $cmd.CommandText = $Query
            if ($Params.Count -gt 0) {
                $Params.GetEnumerator() | ForEach-Object {
                    $cmd.Parameters.AddWithValue("@$($_.Key)", $($_.Value)) | Out-Null
                }
            }
            if ($PSBoundParameters.ContainsKey('CommandTimeOut')) {
                $cmd.CommandTimeout = $CommandTimeOut
            }
            if ($(Get-SqlTraceEnabled)) {
                [SqlTrace]$logObj = New-Object SqlTrace $Server, $Database, $Query, $Params
            }
            if ($TestMode) { return $cmd }
            if ($Reader -or $RawReader) {   # returns tabular data
                [System.Data.DataTable]$dt = New-Object System.Data.DataTable
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
            Write-Verbose ''
            Write-Verbose '-- Error executing SQL command:'
            Write-Verbose $Query
            Write-Verbose '-------------------------------'
            Write-Verbose $_.Exception.Message
            if ($null -ne $logObj) { $logObj.data = $_.Exception.Message }
            throw    # re-throw so error is propagated and script aborted if not handled
        } 
        finally {
            if ($null -ne $SqlConn) { $SqlConn.Close() }
        }
    }
}
