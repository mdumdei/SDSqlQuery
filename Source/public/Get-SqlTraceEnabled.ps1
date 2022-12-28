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
