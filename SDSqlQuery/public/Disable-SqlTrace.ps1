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
