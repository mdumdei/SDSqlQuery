# Get-SqlCacheCredential

## SYNOPSIS
Retrieve an SQL credential from the session cache.

## SYNTAX

### Global (Default)
```
Get-SqlCacheCredential [-Exact] [AsPSCredential] [<CommonParameters>]
```

### Server
```
Get-SqlCacheCredential [[-Server] <String>] [-Exact] [AsPSCredential] [<CommonParameters>]
```

### Contained Database
```
Get-SqlCacheCredential [-Server] <String> [-Database] <String> [-Exact] [AsPSCredential] [<CommonParameters>]
```

## DESCRIPTION
In scripts where multiple SQL queries performed, the same credentials are often used for all queries. Set-SqlCacheCredential can be used to preset credentials avoiding the need to pass the Credential parameter to Invoke-SqlQuery on a per-call basis.

This command retrieves currently cached credentials. If specified with no parameters and a non-server specific credential was configured using Set-SqlCacheCredential, that credential is retrieved. Server and contained database specific credentials are retrieved by providing the appropriate parameters.

Invoke-SqlQuery automatically accesses cached credentials, so the main purpose of this command is to examine the contents of the cache. Note: Internally the cache contains SqlCredentials since that is the type needed for the Credential property of SqlConnection objects. Translation of PSCredentials to SqlCredentials is performed automatically. This command returns the SqlCredential unless the AsPSCredential switch is specified.

Related cmdlets: Invoke-SqlQuery, Set-SqlCacheCredential, Remove-SqlCacheCredential

## EXAMPLES

### EXAMPLE 1
```
Get-SqlCacheCredential
```
A single cached credential (a global login) may be set for all servers, all databases. If one is defined by Set-Credential, this retreives it.

### EXAMPLE 2
```
Get-SqlCacheCredential -Server $srv1
```
Retrieve the credential to use when connecting to databases on Srv1 that do not have a database specific entry in the cache. Unless the -Exact option is specified, the global credential will be returned if a server specific credential does not exist.

### EXAMPLE 3
```
Get-SqlCacheCredential -Server $srv1 -Database $db
```
Retrieve a credential for a contained database. Unless the -Exact option is specified, this will roll up to a server level lookup if a password does not exist for the named database.

## PARAMETERS

### -Server
Server name if retrieving a server specific credential.

```yaml
Type: String
Parameter Sets: DB
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: Server
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Database
Database name if retrieving credential for contained database.

```yaml
Type: String
Parameter Sets: DB
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Exact
If the exact server or server/database key does not exist, do not roll up to a more general key.

```yaml
Type: SwitchParameter
Parameter Sets: GlobalCred, DB, Server
Aliases:

Required: False
Position: 3
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsPSCredential
{{ Fill AsPSCredential Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### PSCredential.

## NOTES
Author: Mike Dumdei

## RELATED LINKS
[Invoke-SqlQuery](./Invoke-SqlQuery.md), [Clear-SqlCacheCredential](./Clear-SqlCacheCredential.md), [Set-SqlCacheCredential](./Set-SqlCacheCredential.md), [Clear-SqlCacheConnectionString](./Clear-SqlCacheConnectionString.md), [Get-SqlCacheConnectionString](./Get-SqlCacheConnectionString.md), [Set-SqlCacheConnectionString](./Set-SqlCacheConnectionString.md)
