function MapColumns  {
# Helper function that breaks an incoming set of field columns along with the
# MapFields parameter and returns the field names that will be assigned to output
# and an option secondary value that is the formats. The column fields default to
# the incoming original name if a map value is not present. Results of this function
# are returned as an array of hashes. Key 1 is 'Map' and key 2 is 'Fmts' with the
# values being the corresponding string arrays. 'Fmts' is only returned in the set
# if formats are present.
    param(
        [Parameter(Position = 0,Mandatory)][string[]]$mapCols, 
        [Parameter(Position = 1)][Hashtable]$map
    ) 
    if ($null -eq $mapCols -or $mapCols.Length -eq 0 -or $null -eq $map -or $map.Count -eq 0)  { 
        return @{ Map = $mapCols }    
    }
    $colMap = [string[]]::new($mapCols.Count);
    $mapFmts = [string[]]::new($mapCols.Count)
    $f = $null
    for ($i = 0; $i -lt $mapCols.Count; $i++) {
        $cn = $mapCols[$i]
        if ($null -eq $map -or $null -eq $map[$cn]) { 
            $colMap[$i] = $cn
        } else {
            $s = $map[$cn]
            $j = $s.LastIndexOf(":|") + 1
            if ($j -gt 1 -and $s[-1] -eq '|') {
                $f = $s.Substring($j).Trim('|') 
                if ($f.Length -gt 0) { 
                    if ($f -eq "trim") {
                        $mapFmts[$i] = "T"
                    } else {
                        $mapFmts[$i] = $f 
                    }
                }
                $s = $s.Substring(0, $j - 1)
            }
            $colMap[$i] = $s
        }
    }
     if ($null -ne $f) {
        return @{ Map = $colMap; Fmts = $mapFmts }
    } else {
        return @{ Map = $colMap }
    }
}
