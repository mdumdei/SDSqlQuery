function Convert-QueryToCsv {
<#    
.SYNOPSIS
    Convert Invoke-SqlQuery Reader/RawReader results to CSV format.
.DESCRIPTION
    This command converts result sets obtained from Invoke-SqlQuery Reader/RawReader queries to CSV format. Null values are converted to empty columns. The MapFields parameter may be used to optionally rename output columns, trim trailing spaces from fixed CHAR(x) columns, and apply formatting to date and numeric columns. 

    Invoke-SqlQuery will also produce a CSV directly which in most cases will be a better solution than using Convert-QueryToCsv. See the Invoke-SqlQuery help for MapFields syntax and the options provided by that command to generate CSV files. The primary reason this command exists is to provide a way to convert trace data to CSV.

    Related cmdlets: Invoke-SqlQuery, Convert-QueryToOBjects, Get-SqlTrace, Get-SqlTraceData
.PARAMETER FileName
    Name of CSV file if output is being sent to a file.
.PARAMETER MapFields
    Rename columns, trim trailing spaces from strings, or apply formatting to date/time fields and numerics. See Invoke-SqlQuery description for details.
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
    String (CSV Data)
.EXAMPLE
    PS:\>Get-SqlTrace 1 | Convert-QueryToCsv -MapFields @{ emp_name = 'Name'; h_date = 'HireDate:|MM-dd-yyyy|' }

    Convert the DataTable data that was captured in the 2nd trace entry (the trace log is zero-based) to CSV, rename the columns emp_name and h_date and apply date formatting to the hire date.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding()]
    param(
        [Alias("DataRow")]
        [Parameter(Position = 0, ParameterSetName = "DataRow", ValueFromPipeline, Mandatory)]
          [System.Data.DataRow]$Row,
        [Alias("DataTable")]
        [Parameter(Position = 0, ParameterSetName = "DataTable", ValueFromPipeline, Mandatory)]
          [System.Data.DataTable]$Table,
        [Parameter(Position = 0, ParameterSetName = "PSObjects", ValueFromPipeline, Mandatory)]
          [PSObject[]]$PSObjects,
        [Alias("SqlTrace")]
        [Parameter(Position = 0, ParameterSetName = "SqlTraceItem", ValueFromPipeline, Mandatory)]
          [SqlTrace]$SqlTraceItem,
        [Parameter(Position = 1)]
          [Hashtable]$MapFields,
        [Parameter(Position = 2)]
          [string]$FileName
    )
    begin {
        [string[]]$mapFmts = $null
        [int]$rowNum = 0
        if ($PSBoundParameters.ContainsKey('MapFields') -eq $false) {
            $MapFields = @{}
        }
    }
    process {
        [System.Text.StringBuilder]$sb = $null
        if ($null -ne $Row) {
            $sb = ConvertDataRowToCsv $Row $MapFields ([ref]$mapFmts) $rowNum
            $rowNum++
        }  elseif ($null -ne $Table) {
            $sb = ConvertDataTableToCsv $Table $MapFields
        } elseif ($null -ne $PSObjects) {
            if ($PSObjects.Count -eq 1) {
                $sb = ConvertObjectToCsv $PSObjects[0] $MapFields ([ref]$mapFmts) ([ref]$rowNum)
                $rowNum++
            } else {
                $sb = ConvertObjectArrayToCsv $PSObjects $MapFields
            }
        } elseif ($null -ne $SqlTraceItem -and $SqlTraceItem.Data -is [System.Data.DataTable]) {
            $sb = ConvertDataTableToCsv $SqlTraceItem.Data $MapFields
        }
        if ($null -ne $sb) {
            if ($PSBoundParameters.ContainsKey('FileName')) {
                $sb.ToString() | Out-File $FileName
            } else {
                Write-Output $sb.ToString()  
            }
        }
    }
}
