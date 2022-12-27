---
external help file: SDSqlQuery-help.xml
Module Name: SDSqlQuery
online version:
schema: 2.0.0
---

# Clear-SqlCacheCredential

## SYNOPSIS
Remove a credential from the SQL credential cache.

## SYNTAX

### Server or Server/Database
```
Clear-SqlCacheCredential [[-Server] <Object>] [[-Database] <Object>] [<CommonParameters>]
```

### All Credentials
```
Clear-SqlCacheCredential [-All] [<CommonParameters>]
```

## DESCRIPTION
When performing multiple queries from within a script, the same login credential is often used for all connections. Set-SqlCacheCredential presets the SQL login credential so the Credential parameter may be omitted when calling Invoke-SqlQuery. This command is used to remove preset credentials set using Set-SqlCacheCredential.

Related cmdlets: Invoke-SqlQuery, Set-SqlCacheCredential, Get-SqlCacheCredential

## EXAMPLES

### EXAMPLE 1
```
Clear-SqlCacheCredential -Server Srv1
```

Remove SQL credentials for logins for a specific server. Unless using contained databases, this will be the lowest level credential.

### EXAMPLE 2
```
Clear-SqlCacheCredential
```

If a credential was set without setting a server name, that credential applies to all connections that do not have a more specific credential set. This removes the global credential.

### EXAMPLE 3
```
Clear-SqlCacheCredential -All
```

Compleletly clear the credential cache.

## PARAMETERS

### -Server
Removes a server level (true unless using contained databases) credential.

```yaml
Type: Object
Parameter Sets: SrvDB
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Database
If using contained databases, the database parameter allows removal a per database credential.

```yaml
Type: Object
Parameter Sets: SrvDB
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Remove all cached credentials.

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: 1
Default value: False
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
[Invoke-SqlQuery](.\Invoke-SqlQuery.md), [Get-SqlCacheCredential](.\Get-SqlCacheCredential.md), [Set-SqlCacheCredential](.\Set-SqlCacheCredential.md), [Clear-SqlCacheConnectionString](.\Clear-SqlCacheConnectionString.md), [Get-SqlCacheConnectionString](.\Get-SqlCacheConnectionString.md), [Set-SqlCacheConnectionString](.\Set-SqlCacheConnectionString.md)
