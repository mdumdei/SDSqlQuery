# Convert-QueryToCsv

## SYNOPSIS
Convert Invoke-SqlQuery Reader/RawReader results to CSV format.

## SYNTAX

### DataRow
```
Convert-QueryToCsv [-Row] <DataRow> [[-MapFields] <Hashtable>] [[-FileName] <String>] [<CommonParameters>]
```

### DataTable
```
Convert-QueryToCsv [-Table] <DataTable> [[-MapFields] <Hashtable>] [[-FileName] <String>] [<CommonParameters>]
```

### PSObjects
```
Convert-QueryToCsv [-PSObjects] <PSObject[]> [[-MapFields] <Hashtable>] [[-FileName] <String>]
 [<CommonParameters>]
```

### SqlTraceItem
```
Convert-QueryToCsv [-SqlTraceItem] <SqlTrace> [[-MapFields] <Hashtable>] [[-FileName] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
This command converts result sets obtained from Invoke-SqlQuery Reader/RawReader queries to CSV format. Null values are converted to empty columns. The MapFields parameter may be used to optionally rename output columns, trim trailing spaces from fixed CHAR(x) columns, and apply formatting to date and numeric columns.

Invoke-SqlQuery will also produce a CSV directly which in most cases will be a better solution than using Convert-QueryToCsv. See the Invoke-SqlQuery help for MapFields syntax and the options provided by that command to generate CSV files. The primary reason this command exists is to provide a way to convert trace data to CSV.

Related cmdlets: Invoke-SqlQuery, Convert-QueryToOBjects, Get-SqlTrace, Get-SqlTraceData

## EXAMPLES

### EXAMPLE 1
```
Get-SqlTrace 1 | Convert-QueryToCsv -MapFields @{ emp_name = 'Name'; h_date = 'HireDate:|MM-dd-yyyy|' }
```

Convert the DataTable data that was captured in the 2nd trace entry (the trace log is zero-based) to CSV, rename the columns emp_name and h_date and apply date formatting to the hire date.

## PARAMETERS

### -Row
DataRow to use as input

```yaml
Type: DataRow
Parameter Sets: DataRow
Aliases: DataRow

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Table
DataTable item to use as input

```yaml
Type: DataTable
Parameter Sets: DataTable
Aliases: DataTable

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -PSObjects
Array of PSObjects to use as input

```yaml
Type: PSObject[]
Parameter Sets: PSObjects
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SqlTraceItem
Sql Trace item to use as input

```yaml
Type: SqlTrace
Parameter Sets: SqlTraceItem
Aliases: SqlTrace

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -MapFields
Rename columns, trim trailing spaces from strings, or apply formatting to date/time fields and numerics. See Invoke-SqlQuery description for details.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileName
Name of CSV file if output is being sent to a file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### DataTable, DataRow, PSObjects[], or SqlTrace Object
## OUTPUTS

### String (CSV Data)
## NOTES
Author: Mike Dumdei

## RELATED LINKS
[Invoke-SqlQuery]("./Invoke-SqlQuery.md"), [Convert-QueryToOBjects]("./Convert-QueryToOBjects"), [Get-SqlTrace]("./Get-SqlTrace.md"), [Get-SqlTraceData]("./Get-SqlTraceData.md")