---
external help file: SDSqlQuery-help.xml
Module Name: SDSqlQuery
online version:
schema: 2.0.0
---

# Get-SqlTrace

## SYNOPSIS
Retrieve the trace log or an item from the trace log.

## SYNTAX

```
Get-SqlTrace [[-Item] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
This cmdlet retrieves items from the trace log.
The trace log is an in-memory array of PS custom objects and is enabled via the Set-SqlTraceOption cmdlet. When enabled, items are placed in the array each time Invoke-SqlQuery is called. Object properties include the index of the entry (Idx), server (Srv) and database (DB) used for the query, the query string (Qry), any passed parameters (Parms) followed by the results of the query (Data).

For Reader/RawReader queries, the Data property will be a DataTable object. For Scalar queries, it is whatever type of object was returned by the query. For NonQuery queries, the Data property will be the number of rows affected.

Get-SqlTrace returns PSObjects composed of the data properties listed above. For a string representation suitable for displaying on the console or writing to a file, use Write-SqlTraceLog.

Related cmdlets: Invoke-SqlQuery, Enable-SqlTrace, Disable-SqlTrace, Get-SqlTraceEnabled,
Get-SqlTraceData, Write-SqlTraceLog, Clear-SqlTraceLog.

## EXAMPLES

### EXAMPLE 1
```
Get-SqlTrace 0
```

Get the first item from the trace log.

### EXAMPLE 2
```
Get-SqlTrace
```

Get all items from the trace log.

## PARAMETERS

### -Item
{{ Fill Item Description }}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### A list of SqlTrace objects or a single object if an index is provided.
## NOTES
Author: Mike Dumdei

## RELATED LINKS
[Invoke-SqlQuery](.\Invoke-SqlQuery.md), [Clear-SqlTraceLog](.\Clear-SqlTraceLog.md), [Enable-SqlTrace](.\Enable-SqlTrace.md), [Disable-SqlTrace](.\Disable-SqlTrace.md), [Get-SqlTraceEnabled](.\Get-SqlTraceEnabled.md), [Get-SqlTraceData](.\Get-SqlTraceData.md), [Write-SqlTraceLog](.\Write-SqlTraceLog.md)
