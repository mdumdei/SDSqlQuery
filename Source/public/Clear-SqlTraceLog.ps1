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
