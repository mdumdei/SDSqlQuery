---
external help file: SDSqlQuery-help.xml
Module Name: SDSqlQuery
online version:
schema: 2.0.0
---

# Open-SqlConnection

## SYNOPSIS
Open a connection to a SQL server.

## SYNTAX

### UseCache (Default)
```
Open-SqlConnection [[-Credential] <PSCredential>] [-NoOpen] [<CommonParameters>]
```

### ConnStr
```
Open-SqlConnection [-ConnectionString] <String> [[-Credential] <PSCredential>] [-NoOpen] [<CommonParameters>]
```

### SrvDB
```
Open-SqlConnection [-Server] <String> [-Database] <String> [[-Credential] <PSCredential>] [-NoOpen]
 [<CommonParameters>]
```

## DESCRIPTION
Open an SQL connection to a server. Invoke-SqlQuery automatically opens and closes connections using 1) the ConnectionString parameter, or 2) the Server and Database parameters, or 3) a connection preset using Set-SqlCacheConnectionString. Calling Open-SqlConnection directly is only necessary if you want to pass Invoke-SqlQuery an open connection via the -Connection parameter.

Connection strings may include placeholders for username and/or password fields. A placeholder simply refers to using an asterisk in place of the User ID or Password. If an asterisk is placed in either, the connection will connect to the server and database specified in the connection string with the credentials coming from the Credential parameter if present or from a SqlCacheCredential if the Credential was not directly specified. An error is thrown if a placeholder is specified in the connection string and no credential can be located.

The 'NoOpen' switch does everything except actually Open the connection. When specified, the return value is an unopened SqlConnection object vs. an opened SqlConnection object. The purpose of the switch is primarily for unit tests and debugging, but it does provide a final hook before the Open call if needed for other purposes.

## EXAMPLES

### EXAMPLE 1
```
# At beginning of script - at least that is the idea - set once and forget
```

PS:\\\>Set-SqlCacheConnectionString "Server=sqlSrv;Database=myDB;User ID=*;"
PS:\\\>Set-SqlCacheCredential $creds
PS:\\\> # Remaining parts of the script unless an override is needed, BUT let Invoke-SqlQuery handle connections unless there is a reaon not to.
PS:\\\>\[SqlConnection\]$conn = Open-SqlConnection

Open a connection using cached values. The '*' in the connection string signifies the User ID and Password values are to be retrieved from a passed Credential parameter or from the credential cache (see Set-SqlCacheCredential).

### EXAMPLE 2
```
$connStr = "Server=$srv1;Database=$db;"
```

PS:\\\>\[SqlConnection\]$conn = Open-SqlConnection -ConnectionString $connStr -Credential $creds

Open an SQL connection using a connection string. The difference between this example and the previous one is this example directly specifies the connection string and credentials where in the previous example they were pulled from the cache.

### EXAMPLE 3
```
[SqlConnection]$conn = Open-SqlConnection -Server Srv1 -Database DB1 -Credential $creds
```

Open an SQL connection to Srv1 with the default database set to DB1.

### EXAMPLE 4
```
$connStr = "Server=$srv1;Database=$db;MultipleActiveResultSets=true;User ID=$user;Password=$pass;"
```

PS:\\\>\[SqlConnection\]$conn = Open-SqlConnection -ConnectionString $connStr

Open an SQL connection using a connection string and a plaintext password stored in a PS variable.

## PARAMETERS

### -ConnectionString
Connection string to use for the connection. Credential may be embedded or passed in the Credential parameter.

```yaml
Type: String
Parameter Sets: ConnStr
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Server
If not using a connection string, this is the server for the connection.

```yaml
Type: String
Parameter Sets: SrvDB
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Database
If not using a connection string, this is the database for the connection.

```yaml
Type: String
Parameter Sets: SrvDB
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Credential for connection, if not provided and not in session cache uses Integrated Security.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoOpen
Return an unopened SqlConnection object ready for the Open call.

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

### SqlConnection, Exception.
## NOTES
Author: Mike Dumdei

## RELATED LINKS
