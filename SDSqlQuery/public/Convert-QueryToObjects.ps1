function Convert-QueryToObjects {
<#    
.SYNOPSIS
    Convert DataTable results to a PSObjects array.
.DESCRIPTION
    The C# implementation of a call to Invoke-SqlQuery when used with the 'RawReader' switch returns a DataTable object as the result. If trace logging is enabled, the Data field for all tabular results is also a DataTable object. The Convert-QueryToObjects cmdlet converts the DataTable object into an array of PSObjects and replaces DBNulls with PowerShell nulls. MapFields may be used to change field names and strip trailing spaces from fixed CHAR() fields.

    The set of allowed input objects provided enables pipeline input from various sources. Unless you are working with a trace object, it is better to use the Reader vs. RawReader switch for tabular data making this cmdlet unnecessary.

    Related cmdlets: Invoke-SqlQuery, Get-SqlTrace, Get-SqlTraceData, Convert-QueryToCsv
.PARAMETER MapFields
    Rename output field names and/or trim trailing spaces from fixed CHAR() fields. See Invoke-SqlQuery description for details. Numeric formats described there have no effect in this context.
.PARAMETER Table
    DataTable item to use as input
.PARAMETER PSObjects
    Array of PSObjects to use as input
.PARAMETER Row
    DataRow to use as input
.PARAMETER SqlTraceItem
    Sql Trace item to use as input
.INPUTS
    DataTable, DataRow, PSObjects[], or SqlTrace Object
.OUTPUTS
    CSV data as a string
.EXAMPLE
    PS> [PSObject[]]$objs = Convert-QueryToObjects -Table $(Get-SqlTrace 0).Data

    Convert the content of Trace item 0 from a DataTable to a PSObject array.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding()]
    param (
        [Alias("DataRow")]
        [Parameter(Position=0,ParameterSetName="Row",ValueFromPipeline,Mandatory)]
        [System.Data.DataRow]$Row,        
        [Alias("DataTable")]       
        [Parameter(Position=0,ParameterSetName="Table",ValueFromPipeline,Mandatory)]
        [System.Data.DataTable]$Table,    
        [Alias("SqlTrace")]    
        [Parameter(Position=0,ParameterSetName="Trace",ValueFromPipeline,Mandatory)]
        [SqlTrace]$SqlTraceItem,
        [Parameter(Position=0,ParameterSetName="Objects",ValueFromPipeline,Mandatory)]
        [PSObject[]]$Objects,
        [Parameter()][HashTable]$MapFields
    )
    begin {
        [string[]]$mapCols = [string[]]::new(0)
        [string[]]$mapFmts = $null
        $hashCode = -1
    }
    process {
        if ($null -ne $Row) {
            [PSObject]$obj = New-Object PSObject
            for ($i = 0; $i -lt $Row.Table.Columns.Count; $i++) {
                if ($Row.Table.GetHashCode() -ne $hashCode) {
                    $mapOut = MapColumns $($($Row.Table.Columns).ColumnName) $MapFields
                    $mapCols = $mapOut['Map']
                    $mapFmts = $mapOut['Fmts']
                    $hashCode = $Row.Table.GetHashCode()
                }
                $val = $Row.ItemArray[$i]
                if ($val -eq [DBNull]::Value) { 
                    $val = $null 
                } elseif ($null -ne $mapFmts -and $mapFmts[$i] -eq 'T' -and $val -is [string]) {
                    $val = $val.TrimEnd()
                } 
                Add-Member -InputObject $obj -NotePropertyName $mapCols[$i] -NotePropertyValue $val
            }
            return $obj
        } elseif ($null -ne $Objects) {    
            [System.Collections.Generic.List[PSObject]]$objAry = New-Object System.Collections.Generic.List[PSObject]
            for ($j = 0; $j -lt $Objects.Count; $j++) {
                $obj = $Objects[$j]
                $newObj = New-Object PSObject
                if ($j -eq 0) {
                    $mapCols = $($obj.PSObject.Properties).Name
                    $mapOut = MapColumns $mapCols $MapFields
                    $mapCols = $mapOut['Map']
                    $mapFmts = $mapOut['Fmts']
                }
                $vals = $($obj.PSObject.Properties).Value
                for ($i = 0; $i -lt $vals.Count; $i++) {
                    $val = $vals[$i]
                    if ($val -eq [DBNull]::Value) { 
                        $val = $null 
                    } elseif ($null -ne $mapFmts -and $mapFmts[$i] -eq 'T' -and $val -is [string]) {
                        $val = $val.TrimEnd()
                    } 
                    Add-Member -InputObject $newObj -NotePropertyName $mapCols[$i] -NotePropertyValue $val
                }
                $objAry.Add($newObj)
            } 
            return $objAry
        } else {
            if ($null -ne $SqlTraceItem -and $SqlTraceItem.Data -is [System.Data.DataTable]) { 
                $Table = $SqlTraceItem.Data 
            }
            if ($null -ne $Table) {
                [System.Collections.Generic.List[PSObject]]$objAry = New-Object System.Collections.Generic.List[PSobject]
                foreach ($row in $Table.Rows) {
                    [PSObject]$obj = New-Object PSCustomObject
                    for ($i = 0; $i -lt $Table.Columns.Count; $i++) {
                        if ($Table.GetHashCode() -ne $hashCode) {
                            $mapOut = MapColumns $($($Table.Columns).ColumnName) $MapFields
                            $mapCols = $mapOut['Map']
                            $mapFmts = $mapOut['Fmts']
                            $hashCode = $Table.GetHashCode()
                        }
                        $val = $row[$i]
                        if ($val -eq [DBNull]::Value) { 
                            $val = $null 
                        } elseif ($null -ne $mapFmts -and $mapFmts[$i] -eq 'T' -and $val -is [string]) {
                            $val = $val.TrimEnd()
                        } 
                        Add-Member -InputObject $obj -NotePropertyName $mapCols[$i] -NotePropertyValue $val
                    }
                    $objAry.Add($obj)
                }  
                return $objAry
            }
        }
    }
}
