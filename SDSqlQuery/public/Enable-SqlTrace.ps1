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
