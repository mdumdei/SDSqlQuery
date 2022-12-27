function Convert-QueryToObjects {
<#    
.SYNOPSIS
    Convert DataTable results to a PSObjects array.
.DESCRIPTION
    Invoke-SqlQuery produces a System.Data.DataTable object as the native result for Reader/RawReader queries. If Invoke-SqlQuery is called with the Reader switch vs. RawReader, the result returned is post-processed and returned as an array of PSCustomObjects. Post-processing converts DBNulls to PowerShell nulls and processes the MapFields parameter. If RawReader is used, the native PowerShell version of this module produces an array of unprocessed PSCustomObjects, however, the compiled C# version of the module returns the DataTable object. If capturing a trace, the Data property of the trace for Reader/RawReader queries will always be a DataTable. This cmdlet, Convert-QueryToObjects converts DataTables to PSCustomObject arrays. It may also be used to apply post-processing to existing PSCustomObject results by using the MapFields parameter (See Invoke-SqlQuery for details on MapFields). The set of allowed input objects enables pipeline input from various sources. 

    Unless working with a trace object, it is better to use the Reader vs. RawReader switch since it does some clean up and the PSCustomObject array is easier to work with than a DataTable result. An exception would be when using the native PowerShell version and working with large result sets. Post-processing has no discernable effect on the C# version of the module, but does impact performance of the native PowerShell version. Unless using MapFields, the penalty of the slowed response is only offset by having [DBNull]::Values automatically converted to $nulls. In that case, use RawReader for speed. This command is useful for post-processing trace data or post-processing results after their initial capture.
    
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
    PS:\>[PSObject[]]$objs = Convert-QueryToObjects -Table $(Get-SqlTrace 0).Data

    Convert the content of Trace item 0 from a DataTable to a PSObject array.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding()]
    param (
        [Alias("DataRow")]
        [Parameter(Position=0,ParameterSetName="DataRow",ValueFromPipeline,Mandatory)]
        [System.Data.DataRow]$Row,        
        [Alias("DataTable")]       
        [Parameter(Position=0,ParameterSetName="DataTable",ValueFromPipeline,Mandatory)]
        [System.Data.DataTable]$Table,    
        [Alias("SqlTrace")]    
        [Parameter(Position=0,ParameterSetName="SqlTraceItem",ValueFromPipeline,Mandatory)]
        [SqlTrace]$SqlTraceItem,
        [Parameter(Position=0,ParameterSetName="PSObjects",ValueFromPipeline,Mandatory)]
        [PSObject[]]$PSObjects,
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
        } elseif ($null -ne $PSObjects) {    
            [System.Collections.Generic.List[PSObject]]$objAry = New-Object System.Collections.Generic.List[PSObject]
            for ($j = 0; $j -lt $PSObjects.Count; $j++) {
                $obj = $PSObjects[$j]
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
