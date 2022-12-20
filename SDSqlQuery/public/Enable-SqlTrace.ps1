function Enable-SqlTrace {
<#    
.SYNOPSIS
    Enable in-memory log of Invoke-SqlQuery SQL queries and results.
.DESCRIPTION
    Turn on tracing, enabling an in-memory trace log of calls to Invoke-SqlQuery.

    Related cmdlets: Invoke-SqlQuery, Disable-SqlTrace, Get-SqlTraceEnabled, Get-SqlTrace, Get-SqlTraceData, Write-SqlTraceLog, Clear-SqlTraceLog.
.EXAMPLE
    PS> Enable-SqlTrace

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
