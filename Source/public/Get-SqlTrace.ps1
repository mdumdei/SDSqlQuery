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
