# Convert-QueryToObjects

## SYNOPSIS
Convert Reader/RawReader or other tabular data results to an array of PSObjects.

## SYNTAX

### DataRow
```
Convert-QueryToObjects [-Row] <DataRow> [-MapFields <Hashtable>] [<CommonParameters>]
```

### DataTable
```
Convert-QueryToObjects [-Table] <DataTable> [-MapFields <Hashtable>] [<CommonParameters>]
```

### SqlTrace
```
Convert-QueryToObjects [-SqlTraceItem] <SqlTrace> [-MapFields <Hashtable>] [<CommonParameters>]
```

### PSObjects
```
Convert-QueryToObjects [-PSObjects] <PSObject[]> [-MapFields <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
Invoke-SqlQuery produces a System.Data.DataTable object as the native result for Reader/RawReader queries. If Invoke-SqlQuery is called with the Reader switch vs. RawReader, the result returned is post-processed and returned as an array of PSObjects. Post-processing converts DBNulls to PowerShell nulls and processes the MapFields parameter. If RawReader is used, the native PowerShell version of this module produces an array of unprocessed PSObjects, however, the compiled C# version of the module returns the DataTable object. If capturing a trace, the Data property of the trace for Reader/RawReader queries will always be a DataTable. This cmdlet, Convert-QueryToObjects converts DataTables to PSCustomObject arrays. It may also be used to apply post-processing to existing PSCustomObject results by using the MapFields parameter (See Invoke-SqlQuery for details on MapFields). The set of allowed input objects enables pipeline input from various sources.

Unless working with a trace object, it is better to use the Reader vs. RawReader switch since it does some clean up and the PSCustomObject array is easier to work with than a DataTable result. An exception would be when using the native PowerShell version and working with large result sets. Post-processing has no discernable effect on the C# version of the module, but does impact performance of the native PowerShell version. Unless using MapFields, the penalty of the slowed response is only offset by having \[DBNull\]::Values automatically converted to $nulls. In that case, use RawReader for speed. This command is useful for post-processing trace data or post-processing results after their initial capture.

Related cmdlets: Invoke-SqlQuery, Get-SqlTrace, Get-SqlTraceData, Convert-QueryToCsv

## EXAMPLES

### EXAMPLE 1
```
[PSObject[]]$objs = Convert-QueryToObjects -Table $(Get-SqlTrace 0).Data
```

Convert the content of Trace item 0 from a DataTable to a PSObject array.

## PARAMETERS

### -Row
DataRow to use as input

```yaml
Type: DataRow
Parameter Sets: Row
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
Parameter Sets: Table
Aliases: DataTable

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
Parameter Sets: Trace
Aliases: SqlTrace

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
Parameter Sets: Objects
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -MapFields
Rename output field names and/or trim trailing spaces from fixed CHAR() fields. See Invoke-SqlQuery description for details. Numeric formats described there have no effect in this context.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### DataTable, DataRow, PSObjects[], or SqlTrace Object
## OUTPUTS

### CSV data as a string
## NOTES
Author: Mike Dumdei

## RELATED LINKS
