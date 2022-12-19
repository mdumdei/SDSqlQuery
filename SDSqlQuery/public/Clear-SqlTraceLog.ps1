function Clear-SqlTraceLog {
<#    
.SYNOPSIS
Clear the SQL trace log.
.DESCRIPTION
Clear trace log entries created by Invoke-SqlQuery. Unless Set-SqlTraceOption has been enabled, no log will exist.

Related cmdlets: Invoke-SqlQuery, Set-SqlTraceOption, Get-SqlTrace, Get-SqlTraceData, Write-SqlTraceLog, Get-SqlTraceOption.
.EXAMPLE
PS> Clear-SqlTraceLog
.INPUTS
This cmdlet does not accept pipeline input.
.OUTPUTS
None
.NOTES
Author: Mike Dumdei
#> 
    [SqlTrace]::SqlTraceLog.Clear()
    [SqlTrace]::Count = 0
}
