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
