function ConvertObjectArrayToCsv {
# Helper function used to convert an array of PSObjects to CSV by repeatedly calling
# ConvertObjectToCsv. On rowNum 0, column names are output as well as the data and 
# the $map parameter is processed which returns a hash of 1 or 2 string arrays - one
# with the column names and the other with formats. The 2nd array is only returned if 
# formats (":|blahblah|") in a column mapping. Uses CsvSafe function to add quotes
# and apply formats. Ref passing is used to maintain persistence in the called 
# ConvertObjectToCsv function of mapped fields after rowNum 0 process and to persist 
# rowNum itself.
    [OutputType([System.Text.StringBuilder])]
    param(
        [Object[]]$objs, 
        [hashtable]$map
    )
    [System.Text.StringBuilder]$sb = New-Object System.Text.StringBuilder
    [int]$rowNum = 0
    [string[]]$mapFmts = $null
    foreach ($obj in $objs) {
        $sb.AppendLine($(ConvertObjectToCsv $obj $map ([ref]$mapFmts) ([ref]$rowNum))) | Out-Null
        $rowNum++
    }
    return $sb
}
