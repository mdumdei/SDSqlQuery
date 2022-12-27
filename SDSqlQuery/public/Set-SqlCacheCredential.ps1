function Set-SqlCacheCredential {
<#    
.SYNOPSIS
    Adds a credential to the SQL credential cache.
.DESCRIPTION
    In scripts where multiple SQL queries performed, the same credentials are often used for all queries. Set-SqlCacheCredential can be used to preset credentials avoiding the need to pass the Credential parameter to Invoke-SqlQuery on a per-call basis. 

    This command adds a credential to the credential cache. If only the credential is provided, the credential is used for all connections. When connecting to multiple server instances, that require different credentials for each instance, specify the server as well as the credential. For situations where contained databases are used with different credentials per database, specify the database parameter. When using cached credentials in environments with multiple servers or credentials are entered for a specific server and also a non-server specific server credential, Invoke-SqlQuery will use the credential that best matches the situation.

    Use of cached credentials in combination with a cached connection string, minimizes the number of parameters that must be provided to Invoke-SqlQuery.
    
    Related cmdlets: Invoke-SqlQuery, Set-SqlCacheCredential, Get-SqlCacheCredential
.PARAMETER Credential
    Credential to use for SQL connections as a PSCredential.
.PARAMETER UserName
    User ID to use for SQL connections.
.PARAMETER Password
    Password to use for SQL connections as a SecureString.
.PARAMETER Server
    Add a server specific credential for environments with multiple servers having different credentials per server.
.PARAMETER Database
    If using contained databases, the database parameter allows adding per database credentials using this parameter.
.EXAMPLE
    PS:\>Set-SqlCacheCredential -Server Srv1 -Credential $creds

    Add a SQL credential for logins to a specific server. Unless using contained databases, this will be the lowest level credential. Credential value may be either of type PSCredential or SqlCredential.
.EXAMPLE
    PS:\>Set-SqlCacheCredential -Credential $creds

    Add a credential to the cache to use for all connections not having a server specific credential in the credential cache - a "global" credential.
.INPUTS
    None.
.OUTPUTS
    None.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding(DefaultParameterSetName="Creds")]
    [OutputType([Void])]
    param(
        [Parameter(Position=0,ParameterSetName="Creds",Mandatory)][PScredential]$Credential,
        [Parameter(Position=0,ParameterSetName="UserPass",Mandatory)][string]$UserName,
        [Parameter(Position=1,ParameterSetName="UserPass",Mandatory)][SecureString]$Password,
        [Parameter(Position=2)][string]$Server,
        [Parameter(Position=3)][string]$Database
    )
    [string]$DEFAULT = "__DEFAULT__"
    if ($PSBoundParameters.ParameterSetName -eq "UserPass") {
        $Password.MakeReadOnly()
        $sqlCreds = New-Object System.Data.SqlClient.SqlCredential($UserName, $Password)
    } else {
        $Credential.Password.MakeReadOnly()
        $sqlCreds = New-Object System.Data.SqlClient.SqlCredential($Credential.UserName, $Credential.Password)
    }     
    if ([string]::IsNullOrEmpty($Server)) { $Server = $DEFAULT }
    if ([string]::IsNullOrEmpty($Database)) { $Database = $DEFAULT }
    $key = $Server + $Database
    if ([SqlSettings]::SqlCreds.ContainsKey($key)) {
        [SqlSettings]::SqlCreds[$key] = $sqlCreds
    } else {
        [SqlSettings]::SqlCreds.Add($key, $sqlCreds) | Out-Null
    }
}
