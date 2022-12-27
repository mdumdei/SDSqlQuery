
# Write-SqlTraceLog

## SYNOPSIS
Convert trace log object(s) to text for writing to log or console display.

## SYNTAX

```
Write-SqlTraceLog [[-Item] <Int32>] [-ExpandTables] [[-MapFields] <Hashtable>] [[-LogFile] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
This cmdlet provides a display of the contents of the SQL trace log. The trace log is an in-memory array of PS custom objects and is enabled via the Set-SqlTraceOption cmdlet. When enabled, items are placed in the array each time Invoke-SqlQuery is called.

Write-SqlTraceLog displays the list in a text format for export to a log or viewing on the console.

Use the -ExpandTables switch to display full table results instead of the default summarized view. Use the Item parameter to only display a single element, Use MapFields to rename columns, format numeric or datetime columns, or trim trailing spaces from fixed CHAR columns.

Related cmdlets: Invoke-SqlQuery, Set-SqlTraceOption, Get-SqlTrace, Get-SqlTraceData, Clear-SqlTraceLog, Get-SqlTraceOption.

## EXAMPLES

### EXAMPLE 1
```
Write-SqlTraceLog
```

Displays a summarized of all entries currently in the trace log.

### EXAMPLE 2
```
Write-SqlTraceLog 2 -MapFields @{ 'City' = 'City:|trim|' }
```

Displays a summarized list of the 3rd element in the trace log and trim trailing spaces from results in the City column (think instances where City was defined as CHAR(50) instead of as a VARCHAR or NVARCHAR).

### EXAMPLE 3
```
Write-SqlTraceLog -ExpandTables
```

Displays all trace log entries with table results fully expanded.

## PARAMETERS

### -Item
Zero-based item index of trace item to view.
Omit to display all entries.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExpandTables
Expand table results to show all rows and data retreived by the query.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
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
Default value: @{}
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogFile
{{ Fill LogFile Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### String (Trace Data).
## NOTES
Author: Mike Dumdei

## RELATED LINKS
[Invoke-SqlQuery](./Invoke-SqlQuery.md), [Clear-SqlTraceLog](./Clear-SqlTraceLog.md), [Enable-SqlTrace](./Enable-SqlTrace.md), [Disable-SqlTrace](./Disable-SqlTrace.md), [Get-SqlTraceEnabled](./Get-SqlTraceEnabled.md), [Get-SqlTrace](./Get-SqlTrace.md), [Get-SqlTraceData](./Get-SqlTraceData.md)
