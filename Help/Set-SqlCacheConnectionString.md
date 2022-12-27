---
external help file: SDSqlQuery-help.xml
Module Name: SDSqlQuery
online version:
schema: 2.0.0
---

# Set-SqlCacheConnectionString

## SYNOPSIS
Set a default value for module cmdlets that take a ConnectionString parameter.

## SYNTAX

```
Set-SqlCacheConnectionString [-ConnectionString] <String> [<CommonParameters>]
```

## DESCRIPTION
Invoke-SqlQuery and Open-Connection both can take an SQL connection string as a parameter. Oftentimes, the same connection string is used for repeated calls to the same database. This command presets the value of the ConnectionString parameter so that it does not have to be specified each time Invoke-SqlQuery is called. The "cached" version is ignored if a different one is directly specified when calling Invoke-SqlQuery.

Connection strings may include an asterisk as a placeholder for the User ID and/or Password. The result is the same if the asterisk appears in either location: The string will be used to identify the server and database, but the actual 'User ID' and 'Password' will come from the Credential parameter if one is specified or a cached Credential if the calling function does not specify one directly. Using a placeholder prevents exposure of plaintext passwords. If a placeholder is used, you MUST supply a Credential or have one cached.

## EXAMPLES

### EXAMPLE 1
```
Set-SqlCacheConnectionString "Server=srv1;Database=db;User ID=*;"
```

Set a connection string where the user name and password are extracted from the Credential value at the time of the connection. Credential can either by passed as one of the parameters or pre-cached  (See Set-SqlCacheCredential).

### EXAMPLE 2
```
Set-SqlCacheConnectionString "Server=srv1;Database=db;User ID=jake;Password=pass"
```

Set a connection string that has a plain text password.

## PARAMETERS

### -ConnectionString
Default SQL connection string.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### None.
## NOTES
Author: Mike Dumdei

## RELATED LINKS
[Invoke-SqlQuery](.\Invoke-SqlQuery.md), [Clear-SqlCacheCredential](.\Clear-SqlCacheCredential.md), [Get-SqlCacheCredential](.\Get-SqlCacheCredential.md), [Set-SqlCacheCredential](.\Set-SqlCacheCredential.md), [Get-SqlCacheConnectionString](.\Get-SqlCacheConnectionString.md), [Set-SqlCacheConnectionString](.\Set-SqlCacheConnectionString.md)
