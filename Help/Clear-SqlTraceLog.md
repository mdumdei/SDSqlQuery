
# Clear-SqlTraceLog

## SYNOPSIS
Clear the SQL trace log.

## SYNTAX

```
Clear-SqlTraceLog
```

## DESCRIPTION
Invoke-SqlQuery has an option to track queries, capturing the server and database accessed, the query command text, query parameters if present, and the results of the query. The captured data is stored in an in-memory log that may be later viewed or written to disk. This command clears the in-memory data.

Related cmdlets: Invoke-SqlQuery, Set-SqlTraceOption, Get-SqlTrace, Get-SqlTraceData, Write-SqlTraceLog, Get-SqlTraceOption.

## EXAMPLES

### EXAMPLE 1
```
Clear-SqlTraceLog
```

Clear all existing in-memory log entries.

## PARAMETERS

## INPUTS

### None.
## OUTPUTS

### None
## NOTES
Author: Mike Dumdei

## RELATED LINKS
[Invoke-SqlQuery](./Invoke-SqlQuery.md), [Enable-SqlTrace](./Enable-SqlTrace.md), [Disable-SqlTrace](./Disable-SqlTrace.md), [Get-SqlTraceEnabled](./Get-SqlTraceEnabled.md), [Get-SqlTrace](./Get-SqlTrace.md), [Get-SqlTraceData](./Get-SqlTraceData.md), [Write-SqlTraceLog](./Write-SqlTraceLog.md)


