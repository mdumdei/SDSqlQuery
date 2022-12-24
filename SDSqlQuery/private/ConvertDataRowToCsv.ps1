function ConvertDataRowToCsv {
# Helper function to convert a DataRow to CSV. On rowNum 0, column names are output
# as well as the data and the $map parameter is processed which returns a hash of
# 1 or 2 string arrays - one with the column names and the other with formats. The
# 2nd array is only returned if formats (":|blahblah|") in a column mapping. Uses
# CsvSafe function to add quotes and apply formats. 
    [CmdletBinding()]
    [OutputType([System.Text.StringBuilder])]
    param (
        [Parameter(Position=0)][System.Data.DataRow]$row, 
        [Parameter(Position=1)][hashtable]$map, 
        [Parameter(Position=2)][ref][string[]]$mapFmts, # by Ref - need persistence
        [Parameter(Position=3)][int]$rowNum
    )
    [System.Text.StringBuilder]$sb = New-Object System.Text.StringBuilder
    $nCols = $Row.Table.Columns.Count
    if ($rowNum -eq 0) {
        $mapOut = MapColumns $($($Row.Table.Columns).ColumnName) $map
        $mapCols = $mapOut['Map']
        $mapFmts.Value = $mapOut['Fmts']
        for ($i = 0; $i -lt $nCols; $i++) {
            if ($i -ne 0) { $sb.Append(',') | Out-Null }
            $sb.Append($(CsvSafe $mapCols[$i])) | Out-Null
        }
        $sb.AppendLine() | Out-Null
    }
    for ($i = 0; $i -lt $nCols; $i++) {
        if ($i -ne 0) { $sb.Append(',') | Out-Null }
        if ($null -ne $mapFmts.Value) {
            $sb.Append($(CsvSafe $row[$i] $mapFmts.Value[$i])) | Out-Null
        } else {
            $sb.Append($(CsvSafe $row[$i])) | Out-Null
        }
    }
    return $sb
}
