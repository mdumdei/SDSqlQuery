---
external help file: SDSqlQuery-help.xml
Module Name: SDSqlQuery
online version:
schema: 2.0.0
---

# Set-SqlCacheCredential

## SYNOPSIS
Adds a credential to the SQL credential cache.

## SYNTAX

### PSCredential
```
Set-SqlCacheCredential [-Credential] <PSCredential> [[-Server] <String>] [[-Database] <String>] [<CommonParameters>]
```

### User Name and SecureString Password
```
Set-SqlCacheCredential [-UserName] <String> [-Password] <SecureString> [[-Server] <String>]
 [[-Database] <String>] [<CommonParameters>]
```

## DESCRIPTION
In scripts where multiple SQL queries performed, the same credentials are often used for all queries. Set-SqlCacheCredential can be used to preset credentials avoiding the need to pass the Credential parameter to Invoke-SqlQuery on a per-call basis.

This command adds a credential to the credential cache. If only the credential is provided, the credential is used for all connections. When connecting to multiple server instances, that require different credentials for each instance, specify the server as well as the credential. For situations where contained databases are used with different credentials per database, specify the database parameter. When using cached credentials in environments with multiple servers or credentials are entered for a specific server and also a non-server specific server credential, Invoke-SqlQuery will use the credential that best matches the situation.

Use of cached credentials in combination with a cached connection string, minimizes the number of parameters that must be provided to Invoke-SqlQuery.

Related cmdlets: Invoke-SqlQuery, Set-SqlCacheCredential, Get-SqlCacheCredential

## EXAMPLES

### EXAMPLE 1
```
Set-SqlCacheCredential -Server Srv1 -Credential $creds
```

Add a SQL credential for logins to a specific server. Unless using contained databases, this will be the lowest level credential. Credential value may be either of type PSCredential or SqlCredential.

### EXAMPLE 2
```
Set-SqlCacheCredential -Credential $creds
```

Add a credential to the cache to use for all connections not having a server specific credential in the credential cache - a "global" credential.

## PARAMETERS

### -Credential
Credential to use for SQL connections as a PSCredential.

```yaml
Type: PSCredential
Parameter Sets: Creds
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserName
User ID to use for SQL connections.

```yaml
Type: String
Parameter Sets: UserPass
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Password
Password to use for SQL connections as a SecureString.

```yaml
Type: SecureString
Parameter Sets: UserPass
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Server
Add a server specific credential for environments with multiple servers having different credentials per server.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Database
If using contained databases, the database parameter allows adding per database credentials using this parameter.

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

### None.
## NOTES
Author: Mike Dumdei

## RELATED LINKS
[Invoke-SqlQuery](.\Invoke-SqlQuery.md), [Clear-SqlCacheCredential](.\Clear-SqlCacheCredential.md), [Get-SqlCacheCredential](.\Get-SqlCacheCredential.md), [Clear-SqlCacheConnectionString](.\Clear-SqlCacheConnectionString.md), [Get-SqlCacheConnectionString](.\Get-SqlCacheConnectionString.md), [Set-SqlCacheConnectionString](.\Set-SqlCacheConnectionString.md)
