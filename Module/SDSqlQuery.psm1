# Class for holding settings values.

class SqlSettings {
    # cached SQL credential store
    static [System.Collections.Generic.Dictionary[string,System.Data.SqlClient.SqlCredential]]$SqlCreds = $(New-Object System.Collections.Generic.Dictionary"[string,System.Data.SqlClient.SqlCredential]")
    # cached SQL connection string
    static [string]$SqlConnectionString = $null
}

# Class for containing trace data on queries performed by Invoke-SqlQuery

Class SqlTrace { $Idx; $Srv; $DB; $Cmd; $Parms;  $Data
    static [System.Collections.Generic.List[SqlTrace]]$SqlTraceLog = $(New-Object System.Collections.Generic.List[SqlTrace])
    static [bool]$Enabled = $false
    static [int]$Count = 0
    SqlTrace($srv, $db, $c, $p) {
        if ([SqlTrace]::Enabled) {
            $this.Idx = [SqlTrace]::SqlTraceLog.Count; $this.Data = $null;
            $this.Srv = $srv; $this.DB = $db; $this.Cmd = $c; $this.Parms = $p;
            [SqlTrace]::SqlTraceLog.Add($this)
            [SqlTrace]::Count++
        }
    }
}

function CsvSafe {
# Helper function that does 3 things. The primary function is to examine string values
# looking for commas, quotes, or leading/trailing spaces in string values to determine
# if they need to be quote delimited. Second, it converts any DBNulls or PS nulls it
# finds to empty strings. Finally if the $fmt parameter is not null, it trims trailing
# spaces form string output if $fmt is a 'T' (trim), or applies a numeric format if one
# is present. These may come in from the $MapFields parameter to some of the cmdlets.
# Only trailing spaces are removed, because the goal of 'trim' is to clean up trailing
# spaces on fixed CHAR() SQL columns, not do arbitrary data manipluation. Similarly, the
# numeric formatting goal was so dates for CSV files could be set in the desired format
# (like be able to strip off the time component), and since that was there, why not
# allow other formatting as well, so I did. Other than trimming, formats only apply
# when converting to CSV, since in other cases the objects retain their existing type.
    [OutputType([string])]
    param (
        [Parameter(Position = 0,Mandatory)][Object] $val,
        [Parameter(Position = 1)]$fmt = $null
    )
    if ($null -ne $val -and [DBNull]::Value -ne $val) {
        if ($null -eq $fmt) {
            $val = $val.ToString()
        } else {
            if ($val -isnot [string]) {
                $val = "{0:$fmt}" -f $val
            } elseif ($fmt -eq 'T') {
                $val = ([string]$val).TrimEnd()
            }
        }
        if ($val.IndexOf('"') -ge 0) { return "`"$($val.Replace('`"','`"`"'))`"" }
        if ($val[0] -eq ' ' -or $val[-1] -eq ' ' -or $val.Contains(',')) {
            return "`"$val`""
        } else {
            return $val
        }
    }
    return ''
}

function ConvertObjectToCsv {
# Helper function used when converting an array of PSObjects to CSV. This converts
# one object. On rowNum 0, column names are output as well as the data and the $map
# parameter is processed which returns a hash of 1 or 2 string arrays - one with
# the column names and the other with formats. The 2nd array is only returned if
# formats (":|blahblah|") in a column mapping. Uses CsvSafe function to add quotes
# and apply formats.
    [OutputType([System.Text.StringBuilder])]
    param(
        [Parameter(Position=0)][psobject]$obj,
        [Parameter(Position=1)][hashtable]$map,
        [Parameter(Position=2)][ref][string[]]$mapFmts,  # By ref - need persistence
        [Parameter(Position=3)][ref][int]$rowNum
    )
    [System.Text.StringBuilder]$sb = New-Object System.Text.StringBuilder
    if ($rowNum.Value -eq 0) {
        $mapCols = $($obj.PSObject.Properties).Name
        $mapOut = MapColumns $mapCols $map
        $mapCols = $mapOut['Map']
        $mapFmts.Value = $mapOut['Fmts']
        for ($i = 0; $i -lt $mapCols.Count; $i++) {
            if ($i -ne 0) { $sb.Append(',') | Out-Null }
            $sb.Append($(CsvSafe $mapCols[$i])) | Out-Null
        }
        $sb.AppendLine() | Out-Null
    }
    $vals = $($obj.PSObject.Properties).Value
    for ($i = 0; $i -lt $vals.Count; $i++) {
        if ($i -ne 0) { $sb.Append(',') | Out-Null }
        if ($null -ne $mapFmts.Value) {
            $sb.Append($(CsvSafe $vals[$i] $mapFmts.Value[$i])) | Out-Null
        } else {
        $sb.Append($(CsvSafe $vals[$i])) | Out-Null
        }
    }
    return $sb
}

function MapColumns  {
# Helper function that breaks an incoming set of field columns along with the
# MapFields parameter and returns the field names that will be assigned to output
# and an option secondary value that is the formats. The column fields default to
# the incoming original name if a map value is not present. Results of this function
# are returned as an array of hashes. Key 1 is 'Map' and key 2 is 'Fmts' with the
# values being the corresponding string arrays. 'Fmts' is only returned in the set
# if formats are present.
    param(
        [Parameter(Position = 0,Mandatory)][string[]]$mapCols,
        [Parameter(Position = 1)][Hashtable]$map
    )
    if ($null -eq $mapCols -or $mapCols.Length -eq 0 -or $null -eq $map -or $map.Count -eq 0)  {
        return @{ Map = $mapCols }
    }
    $colMap = [string[]]::new($mapCols.Count);
    $mapFmts = [string[]]::new($mapCols.Count)
    $f = $null
    for ($i = 0; $i -lt $mapCols.Count; $i++) {
        $cn = $mapCols[$i]
        if ($null -eq $map -or $null -eq $map[$cn]) {
            $colMap[$i] = $cn
        } else {
            $s = $map[$cn]
            $j = $s.LastIndexOf(":|") + 1
            if ($j -gt 1 -and $s[-1] -eq '|') {
                $f = $s.Substring($j).Trim('|')
                if ($f.Length -gt 0) {
                    if ($f -eq "trim") {
                        $mapFmts[$i] = "T"
                    } else {
                        $mapFmts[$i] = $f
                    }
                }
                $s = $s.Substring(0, $j - 1)
            }
            $colMap[$i] = $s
        }
    }
     if ($null -ne $f) {
        return @{ Map = $colMap; Fmts = $mapFmts }
    } else {
        return @{ Map = $colMap }
    }
}

function GetDataTableSummary {
    # Helper function that builds a line of data that summarizes the content of DataTable
    # objects when viewing Trace data.
        [OutputType([string])]
        param (
            [System.Data.Datatable]$tbl,
            [int]$linelen = 70,
            [int]$sumItemIdx = 0
        )
        [System.Text.StringBuilder]$sb = New-Object System.Text.StringBuilder
        $nRows = $tbl.Rows.Count
        $nCols = $tbl.Columns.Count
        $sb.Append("[r=").Append($nRows).Append(",c=").Append($nCols).Append("] { ") | Out-Null
        if ($nRows -gt 1) {
            if ($nCols -eq 1) { $more = "]" } else { $more = ",.]" }
            for ($i = 0; $i -lt $nRows -and $sb.Length -lt $linelen; $i++) {
                if ($i -gt 0) { $sb.Append(", ") | Out-Null }
                $sb.Append('[').Append($tbl.Rows[$i][$sumItemIdx]).Append($more) | Out-Null
            }
            if ($i -lt $nRows) { $sb.Append(", ...")  | Out-Null }
        } elseif ($nRows -eq 1) {
            $sb.Append('[') | Out-Null
            for ($i = 0; $i -lt $nCols -and $sb.Length -lt ($linelen - 10); $i++) {
                if ($i -gt 0) { $sb.Append(", ") | Out-Null }
                $sb.Append($tbl.Rows[0].ItemArray[$i]) | Out-Null
            }
            if ($i -eq $nCols) { $sb.Append(']') | Out-Null } else { $sb.Append(",...]") | Out-Null }
        }
        $sb.Append(" }") | Out-Null
        return $sb.ToString()
    }

function ConvertDataTableToCsv {
# Helper function to convert a DataTable to CSV. On rowNum 0, column names are output
# as well as the data and the $map parameter is processed which returns a hash of
# 1 or 2 string arrays - one with the column names and the other with formats. The
# 2nd array is only returned if formats (":|blahblah|") in a column mapping. Uses
# CsvSafe function to add quotes and apply formats.
    [OutputType([System.Text.StringBuilder])]
    param (
        [Parameter(Position=0)][System.Data.DataTable]$tbl,
        [Parameter(Position=1)][hashtable]$map = @{}
    )
    $mapOut = MapColumns $($($tbl.Columns).ColumnName) $map
    $mapCols = $mapOut['Map']
    $mapFmts = $mapOut['Fmts']
    $nCols = $mapCols.Count
    [System.Text.StringBuilder]$sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $nCols; $i++) {
        if ($i -ne 0) { $sb.Append(',') | Out-Null }
        $sb.Append($(CsvSafe $mapCols[$i])) | Out-Null
    }
    $sb.AppendLine() | Out-Null
    $lastRow = $tbl.Rows.Count - 1
    for ($j = 0; $j -le $lastRow; $j++) {
        $row = $tbl.Rows[$j]
        for ($i = 0; $i -lt $nCols; $i++) {
            if ($i -ne 0) { $sb.Append(',') | Out-Null }
            if ($null -eq $mapFmts) {
                $sb.Append($(CsvSafe $row[$i])) | Out-Null
            } else {
                $sb.Append($(CsvSafe $row[$i] $mapFmts[$i])) | Out-Null
            }
        }
        if ($j -lt $lastRow) { $sb.AppendLine() | Out-Null }
    }
    return $sb
}

function ConvertDataRowToCsv {
# Helper function to convert a DataRow to CSV. On rowNum 0, column names are output
# as well as the data and the $map parameter is processed which returns a hash of
# 1 or 2 string arrays - one with the column names and the other with formats. The
# 2nd array is only returned if formats (":|blahblah|") in a column mapping. Uses
# CsvSafe function to add quotes and apply formats.
    [CmdletBinding()]
    [OutputType([System.Text.StringBuilder])]
    param (
        [Parameter(Position=0)][System.Data.DataRow]$row,
        [Parameter(Position=1)][hashtable]$map,
        [Parameter(Position=2)][ref][string[]]$mapFmts, # by Ref - need persistence
        [Parameter(Position=3)][int]$rowNum
    )
    [System.Text.StringBuilder]$sb = New-Object System.Text.StringBuilder
    $nCols = $Row.Table.Columns.Count
    if ($rowNum -eq 0) {
        $mapOut = MapColumns $($($Row.Table.Columns).ColumnName) $map
        $mapCols = $mapOut['Map']
        $mapFmts.Value = $mapOut['Fmts']
        for ($i = 0; $i -lt $nCols; $i++) {
            if ($i -ne 0) { $sb.Append(',') | Out-Null }
            $sb.Append($(CsvSafe $mapCols[$i])) | Out-Null
        }
        $sb.AppendLine() | Out-Null
    }
    for ($i = 0; $i -lt $nCols; $i++) {
        if ($i -ne 0) { $sb.Append(',') | Out-Null }
        if ($null -ne $mapFmts.Value) {
            $sb.Append($(CsvSafe $row[$i] $mapFmts.Value[$i])) | Out-Null
        } else {
            $sb.Append($(CsvSafe $row[$i])) | Out-Null
        }
    }
    return $sb
}

function ConvertObjectArrayToCsv {
# Helper function used to convert an array of PSObjects to CSV by repeatedly calling
# ConvertObjectToCsv. On rowNum 0, column names are output as well as the data and
# the $map parameter is processed which returns a hash of 1 or 2 string arrays - one
# with the column names and the other with formats. The 2nd array is only returned if
# formats (":|blahblah|") in a column mapping. Uses CsvSafe function to add quotes
# and apply formats. Ref passing is used to maintain persistence in the called
# ConvertObjectToCsv function of mapped fields after rowNum 0 process and to persist
# rowNum itself.
    [OutputType([System.Text.StringBuilder])]
    param(
        [Object[]]$objs,
        [hashtable]$map
    )
    [System.Text.StringBuilder]$sb = New-Object System.Text.StringBuilder
    [int]$rowNum = 0
    [string[]]$mapFmts = $null
    foreach ($obj in $objs) {
        $sb.AppendLine($(ConvertObjectToCsv $obj $map ([ref]$mapFmts) ([ref]$rowNum))) | Out-Null
        $rowNum++
    }
    return $sb
}

function ConvertHashToString {
# Helper function that converts a Hashtble to a hashtable looking string.
    [OutputType([string])]
    param(
        [hashtable]$p
    )
    if ($null -eq $p -or $p.Count -eq 0) { return '' }
    [System.Text.StringBuilder]$sb = New-Object System.Text.StringBuilder
    $sb.Append('@{ ') | Out-Null
    $p.GetEnumerator() | ForEach-Object {
        if ($sb.Length -gt 3) { $sb.Append("; ") | Out-Null }
        $sb.Append("'").Append($_.Key).Append("'=`"").Append($_.Value).Append('"') | Out-Null
    }
    $sb.Append(" }") | Out-Null
    return $($sb.ToString())
}

function Get-SqlTraceEnabled {
<#
.SYNOPSIS
    Retrieve status indicating on/off state of trace mode.
.DESCRIPTION
    Retrieves true/false value indicating if tracing Invoke-SqlQuery queries and results to an in-memory log is enabled or disabled.

    Related cmdlets: Invoke-SqlQuery, Enable-SqlTrace, Disable-SqlTrace, Get-SqlTrace, Get-SqlTraceData, Write-SqlTraceLog, Clear-SqlTraceLog.
.EXAMPLE
    PS:\>[bool]$traceEnabled = Get-SqlTraceEnabled

    Check if tracing is currently enabled.
.INPUTS
    None.
.OUTPUTS
    Boolean.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    return [SqlTrace]::Enabled
}

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

function Get-SqlTrace  {
<#
.SYNOPSIS
    Retrieve the trace log or an item from the trace log.
.DESCRIPTION
    This cmdlet retrieves items from the trace log. The trace log is an in-memory array of PS custom objects and is enabled via the Set-SqlTraceOption cmdlet. When enabled, items are placed in the array each time Invoke-SqlQuery is called. Object properties include the index of the entry (Idx), server (Srv) and database (DB) used for the query, the query string (Qry), any passed parameters (Parms) followed by the results of the query (Data).

    For Reader/RawReader queries, the Data property will be a DataTable object. For Scalar queries, it is whatever type of object was returned by the query. For NonQuery queries, the Data property will be the number of rows affected.

    Get-SqlTrace returns PSCustomObjects composed of the data properties listed above. For a string representation suitable for displaying on the console or writing to a file, use Write-SqlTraceLog.

    Related cmdlets: Invoke-SqlQuery, Enable-SqlTrace, Disable-SqlTrace, Get-SqlTraceEnabled,
    Get-SqlTraceData, Write-SqlTraceLog, Clear-SqlTraceLog.
.PARAMETER Index
    Zero-based index of trace log item to retrieve. If an index is not provided, all items in the log are returned.
.INPUTS
    None.
.OUTPUTS
    A list of SqlTrace objects or a single object if an index is provided.
.EXAMPLE
    PS:\>Get-SqlTrace 0

    Get the first item from the trace log.
.EXAMPLE
    PS:\>Get-SqlTrace

    Get all items from the trace log.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding()]
    [OutputType([SqlTrace[]])]
    [OutputType([SqlTrace], ParameterSetName="Item")]
    param (
        [Parameter(Position=0,ParameterSetName="Item")][int]$Item
    )
    if ($PSBoundParameters.ContainsKey('Item')) {
        return [SqlTrace]::SqlTraceLog[$Item]
    } else {
        return [SqlTrace]::SqlTraceLog
    }
}

function Get-SqlTraceData  {
<#
.SYNOPSIS
    Retrieve the trace log or an item from the trace log.
.DESCRIPTION
    This command retrieves just the Data property for an item in the trace log. The trace log is an in-memory array of PS custom objects and is enabled via the Set-SqlTraceOption cmdlet. When enabled, items are placed in the array each time Invoke-SqlQuery is called. Object properties include the index of the entry (Idx), server (Srv) and database (DB) used for the query, the query string (Qry), any passed parameters (Parms) followed by the results of the query (Data).

    For Reader/RawReader queries, the Data property will be a DataTable object. For Scalar queries, it is whatever type of object was returned by the query. For NonQuery queries, the Data property will be the number of rows affected.

    Related cmdlets: Invoke-SqlQuery, Enable-SqlTrace, Disable-SqlTrace, Get-SqlTraceEnabled, Get-SqlTrace, Write-SqlTraceLog, Clear-SqlTraceLog.
.PARAMETER Index
    Zero-based index of trace log item to retrieve. Required.
.PARAMETER AsDataTable
    Returns Reader/RawReader data as a DataTable object (raw).
.PARAMETER As PSObjects
    Returns Reader/RawReader data as an array of PSObjects. DBNulls will be converted to PowerShell nulls. If trim is specified for a fixed CHAR() column via MapFields, trailing spaces will be removed from the column.
.PARAMETER MapFields
    Rename columns, trim trailing spaces from strings, or apply formatting to date/time fields and numerics. See Invoke-SqlQuery description for details.
.PARAMETER AsCsv
    Returns tabular data a long CSV string suitable for file output.
.INPUTS
    None.
.OUTPUTS
    DataTable, List[PSObject], String (CSV), Scalar/NonQueries: Object
.EXAMPLE
    PS:\>Get-SqlTraceData -Item 3

    Retrieve the data property from the 4th item in the trace log.
.EXAMPLE
    PS:\>Get-SqlTraceData 0 -AsObjects

    Retrieve the data property from the 1st item in the trace log. If the item is Reader/RawReader data, it will be converted to a PSObject array with DBNulls converted to $nulls. For other query types, the Data element is returned as is.
.EXAMPLE
    PS:\>$map = @{ employee_nbr = "EmpNbr:|000000|; hdate = "HireDate:|yyyy-MM-dd|" }
    PS:\>Get-SqlTraceData -Item 0 -AsCsv -MapFields $map }

    Retrieve the data property from 1st item in the trace log and, if it is Reader/RawReader data, convert it to CSV format with columns renamed and formatting applied.
 .NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding(DefaultParameterSetName='Objects')]
    [OutputType([PSObject[]],ParameterSetName="Objects")]
    [OutputType([System.Data.DataTable],ParameterSetName="DataTable")]
    [OutputType([string],ParameterSetName="Csv")]
    param (
        [Parameter(Position=0,Mandatory)]
        [int]$ItemNumber,
        [Parameter(Position=1,ParameterSetName='Objects')][Switch]$AsPSObjects,
        [Parameter(Position=1,ParameterSetName='DataTable')][Switch]$AsDataTable,
        [Parameter(Position=1,ParameterSetName='Csv')][Switch]$AsCsv,
        [Parameter(Position=2)][hashtable]$MapFields
    )
    begin {
        if (!$PSBoundParameters.ContainsKey('MapFields')) { $MapFields = @{} }
    } process {
        $val = $(Get-SqlTrace $Item).Data
        if ($val -isnot [System.Data.DataTable] -or $AsDataTable) {
            Write-Output $val;
        } elseif ($AsCsv) {
            Write-Output $(Convert-QueryToCsv $val -MapFields $MapFields)
        } else {
            Write-Output $(Convert-QueryToObjects -Table $val -MapFields $MapFields)
        }
    }
}

function Set-SqlCacheCredential {
<#
.SYNOPSIS
    Adds a credential to the SQL credential cache.
.DESCRIPTION
    In scripts where multiple SQL queries performed, the same credentials are often used for all queries. Set-SqlCacheCredential can be used to preset credentials avoiding the need to pass the Credential parameter to Invoke-SqlQuery on a per-call basis.

    This command adds a credential to the credential cache. If only the credential is provided, the credential is used for all connections. When connecting to multiple server instances, that require different credentials for each instance, specify the server as well as the credential. For situations where contained databases are used with different credentials per database, specify the database parameter. When using cached credentials in environments with multiple servers or credentials are entered for a specific server and also a non-server specific server credential, Invoke-SqlQuery will use the credential that best matches the situation.

    Use of cached credentials in combination with a cached connection string, minimizes the number of parameters that must be provided to Invoke-SqlQuery.

    Related cmdlets: Invoke-SqlQuery, Set-SqlCacheCredential, Get-SqlCacheCredential
.PARAMETER Credential
    Credential to use for SQL connections as a PSCredential.
.PARAMETER UserName
    User ID to use for SQL connections.
.PARAMETER Password
    Password to use for SQL connections as a SecureString.
.PARAMETER Server
    Add a server specific credential for environments with multiple servers having different credentials per server.
.PARAMETER Database
    If using contained databases, the database parameter allows adding per database credentials using this parameter.
.EXAMPLE
    PS:\>Set-SqlCacheCredential -Server Srv1 -Credential $creds

    Add a SQL credential for logins to a specific server. Unless using contained databases, this will be the lowest level credential. Credential value may be either of type PSCredential or SqlCredential.
.EXAMPLE
    PS:\>Set-SqlCacheCredential -Credential $creds

    Add a credential to the cache to use for all connections not having a server specific credential in the credential cache - a "global" credential.
.INPUTS
    None.
.OUTPUTS
    None.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding(DefaultParameterSetName="Creds")]
    [OutputType([Void])]
    param(
        [Parameter(Position=0,ParameterSetName="Creds",Mandatory)][PScredential]$Credential,
        [Parameter(Position=0,ParameterSetName="UserPass",Mandatory)][string]$UserName,
        [Parameter(Position=1,ParameterSetName="UserPass",Mandatory)][SecureString]$Password,
        [Parameter(Position=2)][string]$Server,
        [Parameter(Position=3)][string]$Database
    )
    [string]$DEFAULT = "__DEFAULT__"
    if ($PSBoundParameters.ParameterSetName -eq "UserPass") {
        $Password.MakeReadOnly()
        $sqlCreds = New-Object System.Data.SqlClient.SqlCredential($UserName, $Password)
    } else {
        $Credential.Password.MakeReadOnly()
        $sqlCreds = New-Object System.Data.SqlClient.SqlCredential($Credential.UserName, $Credential.Password)
    }
    if ([string]::IsNullOrEmpty($Server)) { $Server = $DEFAULT }
    if ([string]::IsNullOrEmpty($Database)) { $Database = $DEFAULT }
    $key = $Server + $Database
    if ([SqlSettings]::SqlCreds.ContainsKey($key)) {
        [SqlSettings]::SqlCreds[$key] = $sqlCreds
    } else {
        [SqlSettings]::SqlCreds.Add($key, $sqlCreds) | Out-Null
    }
}

function Write-SqlTraceLog {
<#
.SYNOPSIS
    Convert trace log object(s) to text for writing to log or console display.
.DESCRIPTION
    This cmdlet provides a display of the contents of the SQL trace log. The trace log is an in-memory array of PS custom objects and is enabled via the Set-SqlTraceOption cmdlet. When enabled, items are placed in the array each time Invoke-SqlQuery is called.

    Write-SqlTraceLog displays the list in a text format for export to a log or viewing on the console.

    Use the -ExpandTables switch to display full table results instead of the default summarized view. Use the Item parameter to only display a single element, Use MapFields to rename columns, format numeric or datetime columns, or trim trailing spaces from fixed CHAR columns.

    Related cmdlets: Invoke-SqlQuery, Set-SqlTraceOption, Get-SqlTrace, Get-SqlTraceData, Clear-SqlTraceLog, Get-SqlTraceOption.
.PARAMETER Item
    Zero-based item index of trace item to view. Omit to display all entries.
.PARAMETER ExpandTables
    Expand table results to show all rows and data retreived by the query.
.PARAMETER MapFields
    Rename columns, trim trailing spaces from strings, or apply formatting to date/time fields and numerics. See Invoke-SqlQuery description for details.
.INPUTS
    None.
.OUTPUTS
    String (Trace Data).
.EXAMPLE
    PS:\>Write-SqlTraceLog

    Displays a summarized of all entries currently in the trace log.
.EXAMPLE
    PS:\>Write-SqlTraceLog 2 -MapFields @{ 'City' = 'City:|trim|' }

    Displays a summarized list of the 3rd element in the trace log and trim trailing spaces from results in the City column (think instances where City was defined as CHAR(50) instead of as a VARCHAR or NVARCHAR).
.EXAMPLE
    PS:\>Write-SqlTraceLog -ExpandTables

    Displays all trace log entries with table results fully expanded.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0)][int]$Item,
        [Parameter(Position = 1)][Switch]$ExpandTables,
        [Parameter(Position = 2)][hashtable]$MapFields = @{},
        [Parameter(Position = 3)][string]$LogFile
    )
    $logging = $false
    if ([SqlTrace]::Count -eq 0 -or $Item -gt [SqlTrace]::Count) { return }
    if ([string]::IsNullOrEmpty($LogFile) -eq $false) {
        try {
            "--- $([DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss")) ------------------" | Out-File $LogFile -Append
            [Environment]::NewLine | Out-File $LogFile -Append
            $logging = $true
        } catch {
            throw "Can't write to logfile [$LogFile]: $($_.Exception.Message)"
        }
    }
    if ($PSBoundParameters.ContainsKey('Item')) {
        $from = $to = $Item
    } else {
        $from = 0; $to = [SqlTrace]::Count - 1
    }
    for ($itm = $from; $itm -le $to; $itm++) {
        [SqlTrace]$h = Get-SqlTrace $itm
        [System.Text.StringBuilder]$pStr = New-Object System.Text.StringBuilder
        if ($null -ne $h.Parms -and $h.Parms.Count -gt 0) {
            $pStr.Append("@{ ") | Out-Null
            foreach ($key in $h.Parms.Keys) {
                if ($pStr.Length -gt 3) { $pStr.Append("; ") | Out-Null }
                $pStr.Append("'").Append($key).Append("'=`"").Append($h.Parms[$key]).Append('"') | Out-Null
            }
            $pStr.Append(" }") | Out-Null
        }
        [System.Text.StringBuilder]$sb = New-Object System.Text.StringBuilder
        $sb.Append("idx    :").AppendLine($h.Idx.ToString()) | Out-Null
        $sb.Append("srv/db :").AppendLine("$($h.Srv),$($h.DB)") | Out-Null
        $sb.Append("cmd    :").AppendLine($h.Cmd) | Out-Null
        $sb.Append("parms  :").AppendLine($(ConvertHashToString $h.Parms)) | Out-Null
        $sb.Append("data   :") | Out-Null
        if ($null -ne $h.Data -and $h.Data -isnot [System.Data.DataTable]) {
            $sb.AppendLine($h.Data.ToString()) | Out-Null
        } elseif ($null -ne $h.Data) {
            $sb.AppendLine($(GetDataTableSummary $h.Data)) | Out-Null
        }
        Write-Output $sb.ToString()
        if ($logging) {
            $sb.ToString() | Out-File $LogFile -Append
        }
        if ($ExpandTables -and $h.Data -is [System.Data.DataTable]) {
            $sb = ConvertDataTableToCsv $h.Data $MapFields
            $sb.AppendLine() | Out-Null
            Write-Output $sb.ToString()
            if ($logging) {
                $sb.AppendLine() | Out-Null
                $sb.ToString() | Out-File $LogFile -Append
            }
        }
    }
    if ($logging) {
        [Environment]::NewLine | Out-File $LogFile -Append
    }
}

function Open-SqlConnection {
<#
.SYNOPSIS
    Open a connection to a SQL server.
.DESCRIPTION
    Open an SQL connection to a server. Invoke-SqlQuery automatically opens and closes connections using 1) the ConnectionString parameter, or 2) the Server and Database parameters, or 3) a connection preset using Set-SqlCacheConnectionString. Calling Open-SqlConnection directly is only necessary if you want to pass Invoke-SqlQuery an open connection via the -Connection parameter.

    Connection strings may include placeholders for username and/or password fields. A placeholder simply refers to using an asterisk in place of the User ID or Password. If an asterisk is placed in either, the connection will connect to the server and database specified in the connection string with the credentials coming from the Credential parameter if present or from a SqlCacheCredential if the Credential was not directly specified. An error is thrown if a placeholder is specified in the connection string and no credential can be located.

    The 'NoOpen' switch does everything except actually Open the connection. When specified, the return value is an unopened SqlConnection object vs. an opened SqlConnection object. The purpose of the switch is primarily for unit tests and debugging, but it does provide a final hook before the Open call if needed for other purposes.
.PARAMETER ConnectionString
    Connection string to use for the connection. Credential may be embedded or passed in the Credential parameter.
.PARAMETER Credential
    Credential for connection, if not provided and not in session cache uses Integrated Security.
.PARAMETER Server
    If not using a connection string, this is the server for the connection.
.PARAMETER Database
    If not using a connection string, this is the database for the connection.
.PARAMETER NoOpen
    Return an unopened SqlConnection object ready for the Open call.
.INPUTS
    None.
.OUTPUTS
    SqlConnection, Exception.
.EXAMPLE
    PS:\> # At beginning of script - at least that is the idea - set once and forget
    PS:\>Set-SqlCacheConnectionString "Server=sqlSrv;Database=myDB;User ID=*;"
    PS:\>Set-SqlCacheCredential $creds
    PS:\> # Remaining parts of the script unless an override is needed, BUT let Invoke-SqlQuery handle connections unless there is a reaon not to.
    PS:\>[SqlConnection]$conn = Open-SqlConnection

    Open a connection using cached values. The '*' in the connection string signifies the User ID and Password values are to be retrieved from a passed Credential parameter or from the credential cache (see Set-SqlCacheCredential).
.EXAMPLE
    PS:\>$connStr = "Server=$srv1;Database=$db;"
    PS:\>[SqlConnection]$conn = Open-SqlConnection -ConnectionString $connStr -Credential $creds

    Open an SQL connection using a connection string. The difference between this example and the previous one is this example directly specifies the connection string and credentials where in the previous example they were pulled from the cache.
.EXAMPLE
    PS:\>[SqlConnection]$conn = Open-SqlConnection -Server Srv1 -Database DB1 -Credential $creds

    Open an SQL connection to Srv1 with the default database set to DB1.
.EXAMPLE
    PS:\>$connStr = "Server=$srv1;Database=$db;MultipleActiveResultSets=true;User ID=$user;Password=$pass;"
    PS:\>[SqlConnection]$conn = Open-SqlConnection -ConnectionString $connStr

    Open an SQL connection using a connection string and a plaintext password stored in a PS variable.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding(DefaultParameterSetName="UseCache")]
    [OutputType([System.Data.SqlClient.SqlConnection])]
    param (
        [Parameter(Position = 0, ParameterSetName="ConnStr", Mandatory)][string]$ConnectionString,
        [Parameter(Position = 0, ParameterSetName="SrvDB", Mandatory)][string]$Server,
        [Parameter(Position = 1, ParameterSetName="SrvDB", Mandatory)][string]$Database,
        [Parameter(Position = 2)][PSCredential]$Credential,
        [Parameter(Position = 3)][Switch]$NoOpen
    )
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $scb = $null
    $sqlCreds = $null
    $havePlaceHolders = $false; $isSrvDB = $false
    $cstr = $ConnectionString
    if ([string]::IsNullOrEmpty($cstr) -and [string]::IsNullOrEmpty($Server)) {
        if ([string]::IsNullOrEmpty([SqlSettings]::SqlConnectionString) -eq $false) {
            $cstr = [SqlSettings]::SqlConnectionString
        } else {
            throw "ConnectionString or Server/Database not provided and not in cache"
        }
    }
    if ([string]::IsNullOrEmpty($Database)) {
        $scb = New-Object System.Data.SqlClient.SqlConnectionStringBuilder($cstr)
        $havePlaceHolders = $($scb.UserID -eq "*" -or $scb.Password -eq "*")
    } else {
        $scb = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
        $scb.Add("Data Source", $Server)
        $scb.Add("Initial Catalog", $Database)
        $isSrvDB = $true
    }
    if ($null -ne $Credential) {
        $Credential.Password.MakeReadOnly()
        $sqlCreds = New-Object System.Data.SqlClient.SqlCredential($Credential.UserName, $Credential.Password)
    }
    if ($null -eq $sqlCreds -and ($isSrvDB -or $havePlaceHolders)) {
        $sqlCreds = Get-SqlCacheCredential $scb.DataSource $scb.InitialCatalog
        if ($null -eq $sqlCreds) {
            if ($havePlaceHolders) {
                throw "ConnectionString uses placeholders but credential not provided or in cache"
            } else {
                $scb.Add("Integrated Security", $true)
            }
        }
    }
    if ($null -ne $sqlCreds) {
        foreach ($k in @("User ID","Password","Integrated Security")) {
            $scb.Remove($k) | Out-Null
        }
        $conn.Credential = $sqlCreds
    }
   try {
        $conn.ConnectionString = $scb.ConnectionString
        if ($NoOpen -eq $false) {
            $conn.Open()
        }
        return $conn
    } catch {
        throw "SQL connection failed: $($_.Exception.Message)"
    }
}

function Set-SqlCacheConnectionString {
    <#
    .SYNOPSIS
    Set a default value for module cmdlets that take a ConnectionString parameter.
    .DESCRIPTION
    Invoke-SqlQuery and Open-Connection both can take an SQL connection string as a parameter. Oftentimes, the same connection string is used for repeated calls to the same database. This command presets the value of the ConnectionString parameter so that it does not have to be specified each time Invoke-SqlQuery is called. The "cached" version is ignored if a different one is directly specified when calling Invoke-SqlQuery.

    Connection strings may include an asterisk as a placeholder for the User ID and/or Password. The result is the same if the asterisk appears in either location: The string will be used to identify the server and database, but the actual 'User ID' and 'Password' will come from the Credential parameter if one is specified or a cached Credential if the calling function does not specify one directly. Using a placeholder prevents exposure of plaintext passwords. If a placeholder is used, you MUST supply a Credential or have one cached.
    .PARAMETER ConnectionString
    Default SQL connection string.
    .EXAMPLE
    PS:\>Set-SqlCacheConnectionString "Server=srv1;Database=db;User ID=*;"

    Set a connection string where the user name and password are extracted from the Credential value at the time of the connection. Credential can either by passed as one of the parameters or pre-cached  (See Set-SqlCacheCredential).
    .EXAMPLE
    PS:\>Set-SqlCacheConnectionString "Server=srv1;Database=db;User ID=jake;Password=pass"

    Set a connection string that has a plain text password.
    .INPUTS
    None.
    .OUTPUTS
    None.
    .NOTES
    Author: Mike Dumdei
    #>
        [CmdletBinding()]
        [OutputType([Void])]
        param(
            [Parameter(Position=0,Mandatory)][string]$ConnectionString
        )
        [SqlSettings]::SqlConnectionString = $ConnectionString
    }

function Get-SqlCacheCredential {
<#
.SYNOPSIS
    Retrieve an SQL credential from the session cache.
.DESCRIPTION
    In scripts where multiple SQL queries performed, the same credentials are often used for all queries. Set-SqlCacheCredential can be used to preset credentials avoiding the need to pass the Credential parameter to Invoke-SqlQuery on a per-call basis.

    This command retrieves currently cached credentials. If specified with no parameters and a non-server specific credential was configured using Set-SqlCacheCredential, that credential is retrieved. Server and contained database specific credentials are retrieved by providing the appropriate parameters.

    Invoke-SqlQuery automatically accesses cached credentials, so the main purpose of this command is to examine the contents of the cache. Note: Internally the cache contains SqlCredentials since that is the type needed for the Credential property of SqlConnection objects. Translation of PSCredentials to SqlCredentials is performed automatically. This command returns the SqlCredential unless the AsPSCredential switch is specified.

    Related cmdlets: Invoke-SqlQuery, Set-SqlCacheCredential, Remove-SqlCacheCredential
.PARAMETER Server
    Server name if retrieving a server specific credential.
.PARAMETER Database
    Database name if retrieving credential for contained database.
.PARAMETER Exact
    If the exact server or server/database key does not exist, do not roll up to a more general key.
.PARAMETER AsPSCredential

.EXAMPLE
    PS:\>Get-SqlCacheCredential

    A single cached credential (a global login) may be set for all servers, all databases. If one is defined by Set-Credential, this retreives it.
.EXAMPLE
    PS:\>Get-SqlCacheCredential -Server $srv1

    Retrieve the credential to use when connecting to databases on Srv1 that do not have a database specific entry in the cache. Unless the -Exact option is specified, the global credential will be returned if a server specific credential does not exist.
.EXAMPLE
    PS:\>Get-SqlCacheCredential -Server $srv1 -Database $db

    Retrieve a credential for a contained database. Unless the -Exact option is specified, this will roll up to a server level lookup if a password does not exist for the named database.
.INPUTS
    None.
.OUTPUTS
    An SQLCredential or a PSCredential if -AsPSCredential is specified. Null if no matching $srv/$db is found and a global credential was not specified.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding(DefaultParameterSetName="Server")]
    [OutputType([System.Data.SqlClient.SqlCredential])]
    [OutputType([PSCredential],ParameterSetName="PSCred")]
    param(
        [Parameter(Position=0, ParameterSetName="Server")]
        [Parameter(Position=0, ParameterSetName="DB",Mandatory)]
          [string]$Server,
        [Parameter(Position=1, ParameterSetName="DB",Mandatory)]
          [string]$Database,
        [Parameter(Position=2, ParameterSetName="Server")]
        [Parameter(Position=2, ParameterSetName="DB")]
          [Switch]$Exact,
        [Parameter(Position=3, ParameterSetName="Server")]
        [Parameter(Position=3, ParameterSetName="DB")]
        [Parameter(Position=3, ParameterSetName="PSCred")]
         [Switch]$AsPSCredential
    )
    [string]$DEFAULT = "__DEFAULT__"
    [System.Data.SqlClient.SqlCredential]$creds = $null
    if ([string]::IsNullOrEmpty($Server)) { $Server = $DEFAULT }
    if ([string]::IsNullOrEmpty($Database)) { $Database = $DEFAULT }
    if ([SqlSettings]::SqlCreds.ContainsKey("${Server}${Database}")) {
        $creds = [SqlSettings]::SqlCreds["${Server}${Database}"]
    }
    elseif ([SqlSettings]::SqlCreds.ContainsKey("${Server}$DEFAULT") -and (!$Exact -or $Database -eq $DEFAULT)) {
        $creds = [SqlSettings]::SqlCreds["${Server}$DEFAULT"]
    }
    elseif ([SqlSettings]::SqlCreds.ContainsKey("$DEFAULT$DEFAULT") -and (!$Exact -or $Server -eq $DEFAULT)) {
        $creds = [SqlSettings]::SqlCreds["$DEFAULT$DEFAULT"]
    } else { return $null }
    if ($AsPSCredential -eq $true) {
        $creds.Password.MakeReadOnly()
        return $(New-Object PSCredential($creds.UserID, $creds.Password))
    }
    return $creds
}

function Clear-SqlTraceLog {
<#
.SYNOPSIS
    Clear the SQL trace log.
.DESCRIPTION
    Invoke-SqlQuery has an option to track queries, capturing the server and database accessed, the query command text, query parameters if present, and the results of the query. The captured data is stored in an in-memory log that may be later viewed or written to disk. This command clears the in-memory data.

    Related cmdlets: Invoke-SqlQuery, Set-SqlTraceOption, Get-SqlTrace, Get-SqlTraceData, Write-SqlTraceLog, Get-SqlTraceOption.
.EXAMPLE
    PS:\>Clear-SqlTraceLog

    Clear all existing in-memory log entries.
.INPUTS
    None.
.OUTPUTS
    None
.NOTES
    Author: Mike Dumdei
#>
    [SqlTrace]::SqlTraceLog.Clear()
    [SqlTrace]::Count = 0
}

function Convert-QueryToCsv {
<#
.SYNOPSIS
    Convert Invoke-SqlQuery Reader/RawReader results to CSV format.
.DESCRIPTION
    This command converts result sets obtained from Invoke-SqlQuery Reader/RawReader queries to CSV format. Null values are converted to empty columns. The MapFields parameter may be used to optionally rename output columns, trim trailing spaces from fixed CHAR(x) columns, and apply formatting to date and numeric columns.

    Invoke-SqlQuery will also produce a CSV directly which in most cases will be a better solution than using Convert-QueryToCsv. See the Invoke-SqlQuery help for MapFields syntax and the options provided by that command to generate CSV files. The primary reason this command exists is to provide a way to convert trace data to CSV.

    Related cmdlets: Invoke-SqlQuery, Convert-QueryToOBjects, Get-SqlTrace, Get-SqlTraceData
.PARAMETER FileName
    Name of CSV file if output is being sent to a file.
.PARAMETER MapFields
    Rename columns, trim trailing spaces from strings, or apply formatting to date/time fields and numerics. See Invoke-SqlQuery description for details.
.PARAMETER Table
    DataTable item to use as input
.PARAMETER PSObjects
    Array of PSObjects to use as input
.PARAMETER Row
    DataRow to use as input
.PARAMETER SqlTraceItem
    Sql Trace item to use as input
.INPUTS
    DataTable, DataRow, PSObjects[], or SqlTrace Object
.OUTPUTS
    String (CSV Data)
.EXAMPLE
    PS:\>Get-SqlTrace 1 | Convert-QueryToCsv -MapFields @{ emp_name = 'Name'; h_date = 'HireDate:|MM-dd-yyyy|' }

    Convert the DataTable data that was captured in the 2nd trace entry (the trace log is zero-based) to CSV, rename the columns emp_name and h_date and apply date formatting to the hire date.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding()]
    param(
        [Alias("DataRow")]
        [Parameter(Position = 0, ParameterSetName = "DataRow", ValueFromPipeline, Mandatory)]
          [System.Data.DataRow]$Row,
        [Alias("DataTable")]
        [Parameter(Position = 0, ParameterSetName = "DataTable", ValueFromPipeline, Mandatory)]
          [System.Data.DataTable]$Table,
        [Parameter(Position = 0, ParameterSetName = "PSObjects", ValueFromPipeline, Mandatory)]
          [PSObject[]]$PSObjects,
        [Alias("SqlTrace")]
        [Parameter(Position = 0, ParameterSetName = "SqlTraceItem", ValueFromPipeline, Mandatory)]
          [SqlTrace]$SqlTraceItem,
        [Parameter(Position = 1)]
          [Hashtable]$MapFields,
        [Parameter(Position = 2)]
          [string]$FileName
    )
    begin {
        [string[]]$mapFmts = $null
        [int]$rowNum = 0
        if ($PSBoundParameters.ContainsKey('MapFields') -eq $false) {
            $MapFields = @{}
        }
    }
    process {
        [System.Text.StringBuilder]$sb = $null
        if ($null -ne $Row) {
            $sb = ConvertDataRowToCsv $Row $MapFields ([ref]$mapFmts) $rowNum
            $rowNum++
        }  elseif ($null -ne $Table) {
            $sb = ConvertDataTableToCsv $Table $MapFields
        } elseif ($null -ne $PSObjects) {
            if ($PSObjects.Count -eq 1) {
                $sb = ConvertObjectToCsv $PSObjects[0] $MapFields ([ref]$mapFmts) ([ref]$rowNum)
                $rowNum++
            } else {
                $sb = ConvertObjectArrayToCsv $PSObjects $MapFields
            }
        } elseif ($null -ne $SqlTraceItem -and $SqlTraceItem.Data -is [System.Data.DataTable]) {
            $sb = ConvertDataTableToCsv $SqlTraceItem.Data $MapFields
        }
        if ($null -ne $sb) {
            if ($PSBoundParameters.ContainsKey('FileName')) {
                $sb.ToString() | Out-File $FileName
            } else {
                Write-Output $sb.ToString()
            }
        }
    }
}

function Clear-SqlCacheConnectionString {
<#
.SYNOPSIS
    Clear the default connection string if one is set.
.DESCRIPTION
    In scripts where multiple SQL queries are performed, the same connnection string is often used for all queries. Set-SqlCacheConnectionString can be used to preset a default connection string to avoid the need to pass the ConnectionString parameter to Invoke-SqlQuery on a per-call basis. This command clears the default connection string if one is present.

    Related cmdlets: Invoke-SqlQuery, Open-SqlConnection, Set-SqlCacheConnectionString
.EXAMPLE
    PS:\>Clear-SqlCacheConnectionString

    Removes any existing default value for the ConnectionString parameter of Invoke-SqlQuery and/or Open-SqlConnection.
.INPUTS
    None.
.OUTPUTS
    None.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding()]
    [OutputType([Void])]
    param()
    [SqlSettings]::SqlConnectionString = $null
}

function Clear-SqlCacheCredential {
<#
.SYNOPSIS
    Remove a credential from the SQL credential cache.
.DESCRIPTION
    When performing multiple queries from within a script, the same login credential is often used for all connections. Set-SqlCacheCredential presets the SQL login credential so the Credential parameter may be omitted when calling Invoke-SqlQuery. This command is used to remove preset credentials set using Set-SqlCacheCredential.

    Related cmdlets: Invoke-SqlQuery, Set-SqlCacheCredential, Get-SqlCacheCredential
.PARAMETER Server
    Removes a server level (true unless using contained databases) credential.
.PARAMETER Database
    If using contained databases, the database parameter allows removal a per database credential.
.PARAMETER All
    Remove all cached credentials.
.EXAMPLE
    PS:\>Clear-SqlCacheCredential -Server Srv1

    Remove SQL credentials for logins for a specific server. Unless using contained databases, this will be the lowest level credential.
.EXAMPLE
    PS:\>Clear-SqlCacheCredential

    If a credential was set without setting a server name, that credential applies to all connections that do not have a more specific credential set. This removes that one "global" credential.
.EXAMPLE
    PS:\>Clear-SqlCacheCredential -All

    Compleletly clear the credential cache.
.INPUTS
    None.
.OUTPUTS
    None.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding(DefaultParameterSetName = "SrvDB")]
    [OutputType([Void])]
    param(
        [Parameter(Position=0, ParameterSetName = 'SrvDB')]$Server,
        [Parameter(Position=1, ParameterSetName = 'SrvDB')]$Database,
        [Parameter(Position=0,ParameterSetName='All')][Switch]$All
    )
    if ($All) {
        [SqlSettings]::SqlCreds.Clear()
    } else {
        [string]$DEFAULT = "__DEFAULT__"
        if ([string]::IsNullOrEmpty($Server)) { $Server = $DEFAULT }
        if ([string]::IsNullOrEmpty($Database)) { $Database = $DEFAULT }
        $key = "${Server}${Database}"
        if ([SqlSettings]::SqlCreds.ContainsKey($key)) {
            [SqlSettings]::SqlCreds.Remove($key)
        }
    }
}

function Enable-SqlTrace {
<#
.SYNOPSIS
    Enable in-memory log of Invoke-SqlQuery SQL queries and results.
.DESCRIPTION
    Enables an in-memory trace of SQL commands. When trace is enabled, Invoke-SqlQuery creates a log entry each time it is called containing the server and database accessed, the command query text, query parameters for paramertized queries and stored procedure calls, and the results of query. Data in the trace log can be later viewed or written to disk.

    Related cmdlets: Invoke-SqlQuery, Disable-SqlTrace, Get-SqlTraceEnabled, Get-SqlTrace, Get-SqlTraceData, Write-SqlTraceLog, Clear-SqlTraceLog.
.EXAMPLE
    PS:\>Enable-SqlTrace

    Turn on tracing of calls to Invoke-SqlQuery.
.INPUTS
    None.
.OUTPUTS
    None
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding()]
    [OutputType([Void])]
    param()
    [SqlTrace]::Enabled = $true
}

function Get-SqlCacheConnectionString {
    <#
    .SYNOPSIS
        Retreive default value for module cmdlets that take a ConnectionString parameter.
    .DESCRIPTION
        In scripts where multiple SQL queries are performed, the same connnection string is often used for all queries. Set-SqlCacheConnectionString can be used to preset a default connection string to avoid the need to pass the ConnectionString parameter to Invoke-SqlQuery on a per-call basis. This command displays the active default connection string if one is present.

        See Set-SqlCacheConnectionString.
    .EXAMPLE
        PS:\>Get-SqlCacheConnectionString

        Retrieve default connection string.
    .INPUTS
        None.
    .OUTPUTS
        String.
    .NOTES
        Author: Mike Dumdei
    #>
        [CmdletBinding()]
        [OutputType([string])]
        param()
        return [SqlSettings]::SqlConnectionString
    }

function Convert-QueryToObjects {
<#
.SYNOPSIS
    Convert DataTable results to a PSObjects array.
.DESCRIPTION
    Invoke-SqlQuery produces a System.Data.DataTable object as the native result for Reader/RawReader queries. If Invoke-SqlQuery is called with the Reader switch vs. RawReader, the result returned is post-processed and returned as an array of PSCustomObjects. Post-processing converts DBNulls to PowerShell nulls and processes the MapFields parameter. If RawReader is used, the native PowerShell version of this module produces an array of unprocessed PSCustomObjects, however, the compiled C# version of the module returns the DataTable object. If capturing a trace, the Data property of the trace for Reader/RawReader queries will always be a DataTable. This cmdlet, Convert-QueryToObjects converts DataTables to PSCustomObject arrays. It may also be used to apply post-processing to existing PSCustomObject results by using the MapFields parameter (See Invoke-SqlQuery for details on MapFields). The set of allowed input objects enables pipeline input from various sources.

    Unless working with a trace object, it is better to use the Reader vs. RawReader switch since it does some clean up and the PSCustomObject array is easier to work with than a DataTable result. An exception would be when using the native PowerShell version and working with large result sets. Post-processing has no discernable effect on the C# version of the module, but does impact performance of the native PowerShell version. Unless using MapFields, the penalty of the slowed response is only offset by having [DBNull]::Values automatically converted to $nulls. In that case, use RawReader for speed. This command is useful for post-processing trace data or post-processing results after their initial capture.

    Related cmdlets: Invoke-SqlQuery, Get-SqlTrace, Get-SqlTraceData, Convert-QueryToCsv
.PARAMETER MapFields
    Rename output field names and/or trim trailing spaces from fixed CHAR() fields. See Invoke-SqlQuery description for details. Numeric formats described there have no effect in this context.
.PARAMETER Table
    DataTable item to use as input
.PARAMETER PSObjects
    Array of PSObjects to use as input
.PARAMETER Row
    DataRow to use as input
.PARAMETER SqlTraceItem
    Sql Trace item to use as input
.INPUTS
    DataTable, DataRow, PSObjects[], or SqlTrace Object
.OUTPUTS
    CSV data as a string
.EXAMPLE
    PS:\>[PSObject[]]$objs = Convert-QueryToObjects -Table $(Get-SqlTrace 0).Data

    Convert the content of Trace item 0 from a DataTable to a PSObject array.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding()]
    param (
        [Alias("DataRow")]
        [Parameter(Position=0,ParameterSetName="DataRow",ValueFromPipeline,Mandatory)]
        [System.Data.DataRow]$Row,
        [Alias("DataTable")]
        [Parameter(Position=0,ParameterSetName="DataTable",ValueFromPipeline,Mandatory)]
        [System.Data.DataTable]$Table,
        [Alias("SqlTrace")]
        [Parameter(Position=0,ParameterSetName="SqlTraceItem",ValueFromPipeline,Mandatory)]
        [SqlTrace]$SqlTraceItem,
        [Parameter(Position=0,ParameterSetName="PSObjects",ValueFromPipeline,Mandatory)]
        [PSObject[]]$PSObjects,
        [Parameter()][HashTable]$MapFields
    )
    begin {
        [string[]]$mapCols = [string[]]::new(0)
        [string[]]$mapFmts = $null
        $hashCode = -1
    }
    process {
        if ($null -ne $Row) {
            [PSObject]$obj = New-Object PSObject
            for ($i = 0; $i -lt $Row.Table.Columns.Count; $i++) {
                if ($Row.Table.GetHashCode() -ne $hashCode) {
                    $mapOut = MapColumns $($($Row.Table.Columns).ColumnName) $MapFields
                    $mapCols = $mapOut['Map']
                    $mapFmts = $mapOut['Fmts']
                    $hashCode = $Row.Table.GetHashCode()
                }
                $val = $Row.ItemArray[$i]
                if ($val -eq [DBNull]::Value) {
                    $val = $null
                } elseif ($null -ne $mapFmts -and $mapFmts[$i] -eq 'T' -and $val -is [string]) {
                    $val = $val.TrimEnd()
                }
                Add-Member -InputObject $obj -NotePropertyName $mapCols[$i] -NotePropertyValue $val
            }
            return $obj
        } elseif ($null -ne $PSObjects) {
            [System.Collections.Generic.List[PSObject]]$objAry = New-Object System.Collections.Generic.List[PSObject]
            for ($j = 0; $j -lt $PSObjects.Count; $j++) {
                $obj = $PSObjects[$j]
                $newObj = New-Object PSObject
                if ($j -eq 0) {
                    $mapCols = $($obj.PSObject.Properties).Name
                    $mapOut = MapColumns $mapCols $MapFields
                    $mapCols = $mapOut['Map']
                    $mapFmts = $mapOut['Fmts']
                }
                $vals = $($obj.PSObject.Properties).Value
                for ($i = 0; $i -lt $vals.Count; $i++) {
                    $val = $vals[$i]
                    if ($val -eq [DBNull]::Value) {
                        $val = $null
                    } elseif ($null -ne $mapFmts -and $mapFmts[$i] -eq 'T' -and $val -is [string]) {
                        $val = $val.TrimEnd()
                    }
                    Add-Member -InputObject $newObj -NotePropertyName $mapCols[$i] -NotePropertyValue $val
                }
                $objAry.Add($newObj)
            }
            return $objAry
        } else {
            if ($null -ne $SqlTraceItem -and $SqlTraceItem.Data -is [System.Data.DataTable]) {
                $Table = $SqlTraceItem.Data
            }
            if ($null -ne $Table) {
                [System.Collections.Generic.List[PSObject]]$objAry = New-Object System.Collections.Generic.List[PSobject]
                foreach ($row in $Table.Rows) {
                    [PSObject]$obj = New-Object PSCustomObject
                    for ($i = 0; $i -lt $Table.Columns.Count; $i++) {
                        if ($Table.GetHashCode() -ne $hashCode) {
                            $mapOut = MapColumns $($($Table.Columns).ColumnName) $MapFields
                            $mapCols = $mapOut['Map']
                            $mapFmts = $mapOut['Fmts']
                            $hashCode = $Table.GetHashCode()
                        }
                        $val = $row[$i]
                        if ($val -eq [DBNull]::Value) {
                            $val = $null
                        } elseif ($null -ne $mapFmts -and $mapFmts[$i] -eq 'T' -and $val -is [string]) {
                            $val = $val.TrimEnd()
                        }
                        Add-Member -InputObject $obj -NotePropertyName $mapCols[$i] -NotePropertyValue $val
                    }
                    $objAry.Add($obj)
                }
                return $objAry
            }
        }
    }
}

function Disable-SqlTrace {
<#
.SYNOPSIS
    Disable in-memory log of Invoke-SqlQuery SQL queries and results.
.DESCRIPTION
    Turns off tracing, if enabled, so calls to Invoke-SqlQuery are no longer captured to the in-memory trace log. The data is not cleared - tracing is paused.

    Related cmdlets: Invoke-SqlQuery, Enable-SqlTrace, Get-SqlTraceEnabled, Get-SqlTrace, Get-SqlTraceData, Write-SqlTraceLog, Clear-SqlTraceLog.
.EXAMPLE
    PS:\>Disable-SqlTrace

    Turn off tracing of calls to Invoke-SqlQuery.
.INPUTS
    None.
.OUTPUTS
    None
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding()]
    [OutputType([Void])]
    param()
    [SqlTrace]::Enabled = $false
}


