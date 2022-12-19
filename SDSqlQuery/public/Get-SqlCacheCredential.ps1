function Get-SqlCacheCredential {
<#    
.SYNOPSIS
Retrieve an SQL credential from the session cache.
.DESCRIPTION
This cmdlet probably does not need to be called directly. If a credential is not passed 
directly to Invoke-SqlQuery, it automatically looks in the credential cache for a 
matching credential.

This cmdlet is used in conjunction with the Invoke-SqlQuery cmdlet. Invoke-SqlQuery is a
cmdlet that centralizes all SQL calls for a script to a single location. This cmdlet, along 
with related cmdlets, allow storing the credentials to use when Invoke-SqlQuery is called in
a session cache so the credential can be set once and used throughout the script without the
need to provide credentials for each call to Invoke-SqlQuery.

Related cmdlets: Invoke-SqlQuery, Set-SqlCacheCredential, Remove-SqlCacheCredential
.EXAMPLE 
PS> Get-SqlCacheCredential -Server $srv1 -Database $db

Retrieve a credential for a specific database. Unless the -Exact option is specified, this
will roll up to a server level lookup if a password does not exist for the named database.
.EXAMPLE
PS> Get-SqlCacheCredential -Server $srv1

Retrieve the credential to use when connecting to databases on Srv1 that do not have a more
specific Srv1/Database entry in the cache.
.EXAMPLE
PS> Get-SqlCacheCredential

A single cached credential (a global login) may be set for all servers, all databases.
If one is defined by Set-Credential, this retreives it.
.INPUTS
This cmdlet does not accept pipeline input.
.OUTPUTS
An SQLCredential or a PSCredential if -AsPSCredential is specified. $null if no matching
$srv/$db is found and a global credential was not specified.
.NOTES
Author: Mike Dumdei
#>    
    [CmdletBinding()]
    [OutputType([SqlCredential])]
    [OutputType([PSCredential],ParameterSetName="PSCred")]
    param(
        [Parameter(Position=0, ParameterSetName="Server")]
        [Parameter(Position=0, ParameterSetName="DB",Mandatory)]
          [string]$Server,
        [Parameter(Position=1, ParameterSetName="DB",Mandatory)]
          [string]$Database,
        [Parameter(Position=2, ParameterSetName="Server")]
        [Parameter(Position=2, ParameterSetName="DB")]
          [Switch]$Exact,
        [Parameter(Position=3, ParameterSetName="Server")]
        [Parameter(Position=3, ParameterSetName="DB")]          
        [Parameter(Position=3, ParameterSetName="PSCred")]
         [Switch]$AsPSCredential
    )
    [string]$DEFAULT = "__DEFAULT__"
    [SqlCredential]$creds = $null
    if ([string]::IsNullOrEmpty($Server)) { $Server = $DEFAULT }
    if ([string]::IsNullOrEmpty($Database)) { $Database = $DEFAULT }
    if ([SqlSettings]::SqlCreds.ContainsKey("${Server}${Database}")) {
        $creds = [SqlSettings]::SqlCreds["${Server}${Database}"]
    }
    elseif ([SqlSettings]::SqlCreds.ContainsKey("${Server}$DEFAULT" -and (!$Exact -or $Database -ne $DEFAULT))) {
        $creds = [SqlSettings]::SqlCreds["${Server}$DEFAULT"]
    }
    elseif ([SqlSettings]::SqlCreds.ContainsKey("$DEFAULT$DEFAULT" -and (!$Exact -or $Server -ne $DEFAULT))) {
        $creds = [SqlSettings]::SqlCreds["$DEFAULT$DEFAULT"]
    } else { return $null }
    if ($AsPSCredential -eq $true) {
        $creds.Password.MakeReadOnly()
        return $(New-Object PSCredential($creds.UserID, $creds.Password))
    } 
    return $creds
}
