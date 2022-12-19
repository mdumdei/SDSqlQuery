function CsvSafe {
# Helper function that does 3 things. The primary function is to examine string values
# looking for commas, quotes, or leading/trailing spaces in string values to determine
# if they need to be quote delimited. Second, it converts any DBNulls or PS nulls it
# finds to empty strings. Finally if the $fmt parameter is not null, it trims trailing 
# spaces form string output if $fmt is a 'T' (trim), or applies a numeric format if one
# is present. These may come in from the $MapFields parameter to some of the cmdlets.
# Only trailing spaces are removed, because the goal of 'trim' is to clean up trailing
# spaces on fixed CHAR() SQL columns, not do arbitrary data manipluation. Similarly, the
# numeric formatting goal was so dates for CSV files could be set in the desired format
# (like be able to strip off the time component), and since that was there, why not
# allow other formatting as well, so I did. Other than trimming, formats only apply
# when converting to CSV, since in other cases the objects retain their existing type.
    [OutputType([string])]   
    param (
        [Parameter(Position = 0,Mandatory)][Object] $val,
        [Parameter(Position = 1)]$fmt = $null
    )
    if ($null -ne $val -and [DBNull]::Value -ne $val) {
        if ($null -eq $fmt) {
            $val = $val.ToString()
        } else {
            if ($val -isnot [string]) {
                $val = "{0:$fmt}" -f $val
            } elseif ($fmt -eq 'T') {
                $val = ([string]$val).TrimEnd()
            }
        }
        if ($val.IndexOf('"') -ge 0) { return "`"$($val.Replace('`"','`"`"'))`"" }
        if ($val[0] -eq ' ' -or $val[-1] -eq ' ' -or $val.Contains(',')) {
            return "`"$val`""
        } else { 
            return $val 
        }
    }
    return ''
}
