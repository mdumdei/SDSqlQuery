function ConvertDataTableToCsv {
# Helper function to convert a DataTable to CSV. On rowNum 0, column names are output
# as well as the data and the $map parameter is processed which returns a hash of
# 1 or 2 string arrays - one with the column names and the other with formats. The
# 2nd array is only returned if formats (":|blahblah|") in a column mapping. Uses
# CsvSafe function to add quotes and apply formats.    
    [OutputType([System.Text.StringBuilder])]
    param (
        [Parameter(Position=0)][System.Data.DataTable]$tbl, 
        [Parameter(Position=1)][hashtable]$map = @{}
    )
    $mapOut = MapColumns $($($tbl.Columns).ColumnName) $map
    $mapCols = $mapOut['Map']
    $mapFmts = $mapOut['Fmts']
    $nCols = $mapCols.Count
    [System.Text.StringBuilder]$sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $nCols; $i++) {
        if ($i -ne 0) { $sb.Append(',') | Out-Null }
        $sb.Append($(CsvSafe $mapCols[$i])) | Out-Null
    }
    $sb.AppendLine() | Out-Null
    $lastRow = $tbl.Rows.Count - 1
    for ($j = 0; $j -le $lastRow; $j++) {
        $row = $tbl.Rows[$j]
        for ($i = 0; $i -lt $nCols; $i++) {
            if ($i -ne 0) { $sb.Append(',') | Out-Null }
            if ($null -eq $mapFmts) {
                $sb.Append($(CsvSafe $row[$i])) | Out-Null
            } else {
                $sb.Append($(CsvSafe $row[$i] $mapFmts[$i])) | Out-Null
            }
        }
        if ($j -lt $lastRow) { $sb.AppendLine() | Out-Null }
    }
    return $sb
}
