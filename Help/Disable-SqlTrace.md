---
external help file: SDSqlQuery-help.xml
Module Name: SDSqlQuery
online version:
schema: 2.0.0
---

# Disable-SqlTrace

## SYNOPSIS
Disable in-memory logging of Invoke-SqlQuery SQL queries and results.

## SYNTAX

```
Disable-SqlTrace [<CommonParameters>]
```

## DESCRIPTION
Turns off tracing, if enabled, so calls to Invoke-SqlQuery are no longer captured to the in-memory trace log. The data is not cleared - tracing is paused.

Related cmdlets: Invoke-SqlQuery, Enable-SqlTrace, Get-SqlTraceEnabled, Get-SqlTrace, Get-SqlTraceData, Write-SqlTraceLog, Clear-SqlTraceLog.

## EXAMPLES

### EXAMPLE 1
```
Disable-SqlTrace
```

Turn off tracing of calls to Invoke-SqlQuery.

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
[Invoke-SqlQuery](.\Invoke-SqlQuery.md), [Clear-SqlTraceLog](.\Clear-SqlTraceLog.md), [Enable-SqlTrace](.\Enable-SqlTrace.md), [Get-SqlTraceEnabled](.\Get-SqlTraceEnabled.md), [Get-SqlTrace](.\Get-SqlTrace.md), [Get-SqlTraceData](.\Get-SqlTraceData.md), [Write-SqlTraceLog](.\Write-SqlTraceLog.md)
