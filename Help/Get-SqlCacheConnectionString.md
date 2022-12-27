# Get-SqlCacheConnectionString

## SYNOPSIS
Retreive default value for module cmdlets that take a ConnectionString parameter.

## SYNTAX

```
Get-SqlCacheConnectionString [<CommonParameters>]
```

## DESCRIPTION
In scripts where multiple SQL queries are performed, the same connnection string is often used for all queries. Set-SqlCacheConnectionString can be used to preset a default connection string to avoid the need to pass the ConnectionString parameter to Invoke-SqlQuery on a per-call basis. This command displays the active default connection string if one is present.

See Set-SqlCacheConnectionString.

## EXAMPLES

### EXAMPLE 1
```
Get-SqlCacheConnectionString
```

Retrieve default connection string.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### String.
## NOTES
Author: Mike Dumdei

## RELATED LINKS
[Invoke-SqlQuery](./Invoke-SqlQuery.md), [Clear-SqlCacheCredential](./Clear-SqlCacheCredential.md), [Get-SqlCacheCredential](./Get-SqlCacheCredential.md), [Set-SqlCacheCredential](./Set-SqlCacheCredential.md), [Get-SqlCacheConnectionString](./Get-SqlCacheConnectionString.md), [Set-SqlCacheConnectionString](./Set-SqlCacheConnectionString.md)
