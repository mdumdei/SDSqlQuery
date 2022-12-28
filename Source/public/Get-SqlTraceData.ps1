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
