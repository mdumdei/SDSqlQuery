
# Get-SqlTraceData

## SYNOPSIS
Retrieve the trace log or an item from the trace log.

## SYNTAX

### Objects (Default)
```
Get-SqlTraceData [-ItemNumber] <Int32> [-AsPSObjects] [[-MapFields] <Hashtable>] [<CommonParameters>]
```

### DataTable
```
Get-SqlTraceData [-ItemNumber] <Int32> [-AsDataTable] [[-MapFields] <Hashtable>] [<CommonParameters>]
```

### Csv
```
Get-SqlTraceData [-ItemNumber] <Int32> [-AsCsv] [[-MapFields] <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
This command retrieves just the Data property for an item in the trace log. The trace log is an in-memory array of PS custom objects and is enabled via the Set-SqlTraceOption cmdlet. When enabled, items are placed in the array each time Invoke-SqlQuery is called. Object properties include the index of the entry (Idx), server (Srv) and database (DB) used for the query, the query string (Qry), any passed parameters (Parms) followed by the results of the query (Data).

For Reader/RawReader queries, the Data property will be a DataTable object. For Scalar queries, it is whatever type of object was returned by the query. For NonQuery queries, the Data property will be the number of rows affected.

Related cmdlets: Invoke-SqlQuery, Enable-SqlTrace, Disable-SqlTrace, Get-SqlTraceEnabled, Get-SqlTrace, Write-SqlTraceLog, Clear-SqlTraceLog.

## EXAMPLES

### EXAMPLE 1
```
Get-SqlTraceData -Item 3
```

Retrieve the data property from the 4th item in the trace log.

### EXAMPLE 2
```
Get-SqlTraceData 0 -AsObjects
```

Retrieve the data property from the 1st item in the trace log. If the item is Reader/RawReader data, it will be converted to a PSObject array with DBNulls converted to $nulls. For other query types, the Data element is returned as is.

### EXAMPLE 3
```
$map = @{ employee_nbr = "EmpNbr:|000000|; hdate = "HireDate:|yyyy-MM-dd|" }
```

PS:\\\>Get-SqlTraceData -Item 0 -AsCsv -MapFields $map }

Retrieve the data property from 1st item in the trace log and, if it is Reader/RawReader data, convert it to CSV format with columns renamed and formatting applied.

## PARAMETERS

### -ItemNumber
{{ Fill ItemNumber Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsPSObjects
{{ Fill AsPSObjects Description }}

```yaml
Type: SwitchParameter
Parameter Sets: Objects
Aliases:

Required: False
Position: 2
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsDataTable
Returns Reader/RawReader data as a DataTable object (raw).

```yaml
Type: SwitchParameter
Parameter Sets: DataTable
Aliases:

Required: False
Position: 2
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsCsv
Returns tabular data a long CSV string suitable for file output.

```yaml
Type: SwitchParameter
Parameter Sets: Csv
Aliases:

Required: False
Position: 2
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -MapFields
Rename columns, trim trailing spaces from strings, or apply formatting to date/time fields and numerics. See Invoke-SqlQuery description for details.

```yaml
Type: Hashtable
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

### None.
## OUTPUTS

### DataTable, List[PSObject], String (CSV), Scalar/NonQueries: Object
## NOTES
Author: Mike Dumdei

## RELATED LINKS
[Invoke-SqlQuery](./Invoke-SqlQuery.md), [Clear-SqlTraceLog](./Clear-SqlTraceLog.md), [Enable-SqlTrace](./Enable-SqlTrace.md), [Disable-SqlTrace](./Disable-SqlTrace.md), [Get-SqlTraceEnabled](./Get-SqlTraceEnabled.md), [Get-SqlTrace](./Get-SqlTrace.md),  [Write-SqlTraceLog](./Write-SqlTraceLog.md)
