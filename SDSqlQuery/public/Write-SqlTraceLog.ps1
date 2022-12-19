function Write-SqlTraceLog {
<#    
.SYNOPSIS
Convert trace log object(s) to text for writing to log or console display.
.DESCRIPTION
This cmdlet provides a display of the contents of the SQL trace log. The trace
log is an in-memory array of PS custom objects and is enabled via the Set-SqlTraceOption
cmdlet. When enabled, items are placed in the array each time Invoke-SqlQuery is called.

Write-SqlTraceLog displays the list in a text format for export to a log or viewing on
the console.

Use the -ExpandTables switch to display full table results instead of the default
summarized view. Use the Item parameter to only display a single element, Use MapFields
to rename columns, format numeric or datetime columns, or trim trailing spaces from fixed
CHAR columns.

Related cmdlets: Invoke-SqlQuery, Set-SqlTraceOption, Get-SqlTrace, Get-SqlTraceData,
Clear-SqlTraceLog, Get-SqlTraceOption.
.PARAMETER Item
Zero-based item index of trace item to view. Omit to display all entries.
.PARAMETER ExpandTables
Expand table results to show all rows and data retreived by the query.
.PARAMETER MapFields
Rename columns, trim trailing spaces from strings, or apply formatting to date/time
fields and numerics. See Invoke-SqlQuery description for details.
.INPUTS
This cmdlet does not accept pipeline input.
.OUTPUTS
String value of log data.
.EXAMPLE
PS> Write-SqlTraceLog

Displays a summarized of all entries currently in the trace log.
.EXAMPLE
PS> Write-SqlTraceLog 2 -MapFields @{ 'City' = 'City:|trim|' }

Displays a summarized list of the 3rd element in the trace log and trim trailing spaces
from results in the City column (think instances where City was defined as CHAR(50) instead
of as a VARCHAR or NVARCHAR).
.EXAMPLE
PS> Write-SqlTraceLog -ExpandTables

Displays all trace log entries with table results fully expanded.
.NOTES
Author: Mike Dumdei
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0)][Int32]$Item,
        [Parameter(Position = 1)][Switch]$ExpandTables,
        [Parameter(Position = 2)][hashtable]$MapFields = @{},
        [Parameter(Position = 3)][string]$LogFile
    )
    $logging = $false
    if ([SqlTrace]::Count -eq 0 -or $Item -gt [SqlTrace]::Count) { return }
    if ([string]::IsNullOrEmpty($LogFile) -eq $false) {
        try {
            "--- $(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")) ------------------" | Out-File $LogFile -Append
            [Environment]::NewLine | Out-File $LogFile -Append
        } catch {
            throw "Can't write to logfile [$LogFile]: $($Error[0].Message)"
        }
    }
    if ($PSBoundParameters.ContainsKey('Item')) {
        $from = $to = $Item
    } else {
        $from = 0; $to = [SqlTrace]::Count - 1
    }
    for ($itm = $from; $itm -le $to; $itm++) {
        [SqlTrace]$h = Get-SqlTrace $itm
        [StringBuilder]$pStr = New-Object StringBuilder
        if ($null -ne $h.Parms -and $h.Parms.Count -gt 0) {
            $pStr.Append("@{ ") | Out-Null
            foreach ($key in $h.Parms.Keys) {
                if ($pStr.Length -gt 3) { $pStr.Append("; ") | Out-Null }
                $pStr.Append("'").Append($key).Append("'=`"").Append($h.Parms[$key]).Append('"') | Out-Null
            }
            $pStr.Append(" }") | Out-Null
        }
        [StringBuilder]$sb = New-Object StringBuilder
        $sb.Append("idx    :").AppendLine($h.Idx.ToString()) | Out-Null
        $sb.Append("srv/db :").AppendLine("$($h.Srv),$($h.DB)") | Out-Null
        $sb.Append("cmd    :").AppendLine($h.Cmd) | Out-Null
        $sb.Append("parms  :").AppendLine($(ConvertHashToString $h.Parms)) | Out-Null
        $sb.Append("data   :") | Out-Null
        if ($null -ne $h.Data -and $h.Data -isnot [DataTable]) {
            $sb.AppendLine($h.Data.ToString()) | Out-Null
        } elseif ($null -ne $h.Data) {
            $sb.AppendLine($(GetDataTableSummary $h.Data)) | Out-Null
        }
        Write-Output $sb.ToString()
        if ($logging) {
            $sb.ToString() | Out-File $LogFile -Append
        }
        if ($ExpandTables -and $h.Data -is [DataTable]) {
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
