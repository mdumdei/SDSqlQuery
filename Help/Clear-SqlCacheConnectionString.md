
# Clear-SqlCacheConnectionString

## SYNOPSIS
Clear the default connection string if one is set.

## SYNTAX

```
Clear-SqlCacheConnectionString [<CommonParameters>]
```

## DESCRIPTION
In scripts where multiple SQL queries are performed, the same connnection string is often used for all queries. Set-SqlCacheConnectionString can be used to preset a default connection string to avoid the need to pass the ConnectionString parameter to Invoke-SqlQuery on a per-call basis. This command clears the default connection string if one is present.

Related cmdlets: Invoke-SqlQuery, Open-SqlConnection, Set-SqlCacheConnectionString

## EXAMPLES

### EXAMPLE 1
```
Clear-SqlCacheConnectionString
```

Removes any existing default value for the ConnectionString parameter of Invoke-SqlQuery and/or Open-SqlConnection.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### None.
## NOTES
Author: Mike Dumdei

## RELATED LINKS
[Invoke-SqlQuery](./Invoke-SqlQuery.md), [Clear-SqlCacheCredential](./Clear-SqlCacheCredential.md), [Get-SqlCacheCredential](./Get-SqlCacheCredential.md), [Set-SqlCacheCredential](./Set-SqlCacheCredential.md),  [Get-SqlCacheConnectionString](./Get-SqlCacheConnectionString.md), [Set-SqlCacheConnectionString](./Set-SqlCacheConnectionString.md)

