# Enable-SqlTrace

## SYNOPSIS
Enable in-memory log of Invoke-SqlQuery SQL queries and results.

## SYNTAX

```
Enable-SqlTrace [<CommonParameters>]
```

## DESCRIPTION
Enables an in-memory trace of SQL commands. When trace is enabled, Invoke-SqlQuery creates a log entry each time it is called containing the server and database accessed, the command query text, query parameters for paramertized queries and stored procedure calls, and the results of query. Data in the trace log can be later viewed or written to disk.

Related cmdlets: Invoke-SqlQuery, Disable-SqlTrace, Get-SqlTraceEnabled, Get-SqlTrace, Get-SqlTraceData, Write-SqlTraceLog, Clear-SqlTraceLog.

## EXAMPLES

### EXAMPLE 1
```
Enable-SqlTrace
```

Turn on tracing of calls to Invoke-SqlQuery.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### None
## NOTES
Author: Mike Dumdei

## RELATED LINKS
[Invoke-SqlQuery](./Invoke-SqlQuery.md), [Clear-SqlTraceLog](./Clear-SqlTraceLog.md), [Disable-SqlTrace](./Disable-SqlTrace.md), [Get-SqlTraceEnabled](./Get-SqlTraceEnabled.md), [Get-SqlTrace](./Get-SqlTrace.md), [Get-SqlTraceData](./Get-SqlTraceData.md), [Write-SqlTraceLog](./Write-SqlTraceLog.md)
