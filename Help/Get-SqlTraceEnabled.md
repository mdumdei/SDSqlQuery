
# Get-SqlTraceEnabled

## SYNOPSIS
Retrieve status indicating on/off state of trace mode.

## SYNTAX

```
Get-SqlTraceEnabled [<CommonParameters>]
```

## DESCRIPTION
Retrieves true/false value indicating if tracing Invoke-SqlQuery queries and results to an in-memory log is enabled or disabled.

Related cmdlets: Invoke-SqlQuery, Enable-SqlTrace, Disable-SqlTrace, Get-SqlTrace, Get-SqlTraceData, Write-SqlTraceLog, Clear-SqlTraceLog.

## EXAMPLES

### EXAMPLE 1
```
[bool]$traceEnabled = Get-SqlTraceEnabled
```

Check if tracing is currently enabled.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### Boolean.
## NOTES
Author: Mike Dumdei

## RELATED LINKS
[Invoke-SqlQuery](./Invoke-SqlQuery.md), [Clear-SqlTraceLog](./Clear-SqlTraceLog.md), [Enable-SqlTrace](./Enable-SqlTrace.md), [Disable-SqlTrace](./Disable-SqlTrace.md), [Get-SqlTrace](./Get-SqlTrace.md), [Get-SqlTraceData](./Get-SqlTraceData.md), [Write-SqlTraceLog](./Write-SqlTraceLog.md)
