function ConvertObjectToCsv {
# Helper function used when converting an array of PSObjects to CSV. This converts
# one object. On rowNum 0, column names are output as well as the data and the $map 
# parameter is processed which returns a hash of 1 or 2 string arrays - one with 
# the column names and the other with formats. The 2nd array is only returned if 
# formats (":|blahblah|") in a column mapping. Uses CsvSafe function to add quotes
# and apply formats.    
    [OutputType([System.Text.StringBuilder])]
    param(
        [Parameter()][psobject]$obj, 
        [Parameter()][hashtable]$map, 
        [Parameter()][ref][string[]]$mapFmts,  # By ref - need persistence
        [Parameter()][ref][int]$rowNum
    )
    [System.Text.StringBuilder]$sb = New-Object System.Text.StringBuilder
    if ($rowNum.Value -eq 0) {
        $mapCols = $($obj.PSObject.Properties).Name
        $mapOut = MapColumns $mapCols $map
        $mapCols = $mapOut['Map']
        $mapFmts.Value = $mapOut['Fmts']
        for ($i = 0; $i -lt $mapCols.Count; $i++) {
            if ($i -ne 0) { $sb.Append(',') | Out-Null }
            $sb.Append($(CsvSafe $mapCols[$i])) | Out-Null
        }
        $sb.AppendLine() | Out-Null
    }
    $vals = $($obj.PSObject.Properties).Value
    for ($i = 0; $i -lt $vals.Count; $i++) {
        if ($i -ne 0) { $sb.Append(',') | Out-Null } 
        if ($null -ne $mapFmts.Value) {
            $sb.Append($(CsvSafe $vals[$i] $mapFmts.Value[$i])) | Out-Null
        } else {
        $sb.Append($(CsvSafe $vals[$i])) | Out-Null
        }
    }
    return $sb
}
