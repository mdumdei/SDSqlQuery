function GetDataTableSummary {
    # Helper function that builds a line of data that summarizes the content of DataTable
    # objects when viewing Trace data.
        [OutputType([string])]
        param (
            [System.Data.Datatable]$tbl,
            [int]$linelen = 70,
            [int]$sumItemIdx = 0
        )
        [System.Text.StringBuilder]$sb = New-Object System.Text.StringBuilder
        $nRows = $tbl.Rows.Count
        $nCols = $tbl.Columns.Count
        $sb.Append("[r=").Append($nRows).Append(",c=").Append($nCols).Append("] { ") | Out-Null
        if ($nRows -gt 1) {
            if ($nCols -eq 1) { $more = "]" } else { $more = ",.]" }
            for ($i = 0; $i -lt $nRows -and $sb.Length -lt $linelen; $i++) {
                if ($i -gt 0) { $sb.Append(", ") | Out-Null }
                $sb.Append('[').Append($tbl.Rows[$i][$sumItemIdx]).Append($more) | Out-Null
            }
            if ($i -lt $nRows) { $sb.Append(", ...")  | Out-Null }
        } elseif ($nRows -eq 1) {
            $sb.Append('[') | Out-Null
            for ($i = 0; $i -lt $nCols -and $sb.Length -lt ($linelen - 10); $i++) {
                if ($i -gt 0) { $sb.Append(", ") | Out-Null }
                $sb.Append($tbl.Rows[0].ItemArray[$i]) | Out-Null
            }
            if ($i -eq $nCols) { $sb.Append(']') | Out-Null } else { $sb.Append(",...]") | Out-Null }
        }
        $sb.Append(" }") | Out-Null
        return $sb.ToString()
    }
