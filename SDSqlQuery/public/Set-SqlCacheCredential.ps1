function Set-SqlCacheCredential {
<#    
.SYNOPSIS
Adds a credential to the SQL credential cache.
.DESCRIPTION
Credentials may be preset at the start of a script using a credential cache so that
a script does not have to pass credentials to Invoke-SqlQuery for each call. This
cmdlet adds a credential to the credential cache. Unless using contained databases,
set a Server specific credential or a "global" credential. A "global" credential
is set by specifying only the Credential parameter and is used for all connections
that do not have a more specific overriding match.

Credentials passed to Invoke-SqlQuery via that cmdlet's Credential parameter 
override any stored in the cache.

Related cmdlets: Invoke-SqlQuery, Set-SqlCacheCredential, Get-SqlCacheCredential
.PARAMETER Server
Add a server level (true unless using contained databases) credential.
.PARAMETER Database
If using contained databases, the database parameter allows adding per database
credentials using this parameter.
.EXAMPLE
PS> Set-SqlCacheCredential -Server Srv1 -Credential $creds

Add a SQL credential for logins to a specific server. Unless using contained
databases, this will be the lowest level credential. Credential value may be
either of type PSCredential or SqlCredential.
.EXAMPLE
PS> Set-SqlCacheCredential -Credential $creds

Add a credential to the cache that will be used connections to all servers that do
not have a server specific credential in the credential cache - a "global" credential.
.INPUTS
This cmdlet does not accept pipeline input.
.OUTPUTS
None.
.NOTES
Author: Mike Dumdei
#>
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Position=0)][string]$Server,
        [Parameter(Position=1,ParameterSetName="Creds",Mandatory)][Object]$Credential,
        [Parameter(Position=1,ParameterSetName="UserPass",Mandatory)][string]$UserName,
        [Parameter(Position=2,ParameterSetName="UserPass",Mandatory)][SecureString]$Password,
        [Parameter(Position=3)][string]$Database
    )
    [string]$DEFAULT = "__DEFAULT__"
    if ($PSBoundParameters.ParameterSetName -eq "UserPass") {
        $Password.MakeReadOnly()
        $cred = New-Object SqlCredential($UserName, $Password)
    } else {
        if ($Credential -is [SqlCredential]) {
            $cred = $Credential
        } elseif ($Credential -is [PSCredential]) {
            $Credential.Password.MakeReadOnly()
            $cred = New-Object SqlCredential($Credential.UserName, $Credential.Password)
        } else {
            throw "Credential must be PSCredential or SqlCredential"
        }
    }     
    if ([string]::IsNullOrEmpty($Server)) { $Server = $DEFAULT }
    if ([string]::IsNullOrEmpty($Database)) { $Database = $DEFAULT }
    $key = $Server + $Database
    if ([SqlSettings]::SqlCreds.ContainsKey($key)) {
        [SqlSettings]::SqlCreds[$key] = $cred
    } else {
        [SqlSettings]::SqlCreds.Add($key, $cred) | Out-Null
    }
}
