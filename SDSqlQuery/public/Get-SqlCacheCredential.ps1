function Get-SqlCacheCredential {
<#    
.SYNOPSIS
    Retrieve an SQL credential from the session cache.
.DESCRIPTION
    In scripts where multiple SQL queries performed, the same credentials are often used for all queries. Set-SqlCacheCredential can be used to preset credentials avoiding the need to pass the Credential parameter to Invoke-SqlQuery on a per-call basis. 

    This command retrieves currently cached credentials. If specified with no parameters and a non-server specific credential was configured using Set-SqlCacheCredential, that credential is retrieved. Server and contained database specific credentials are retrieved by providing the appropriate parameters.

    Invoke-SqlQuery automatically accesses cached credentials, so the main purpose of this command is to examine the contents of the cache.
    
    Related cmdlets: Invoke-SqlQuery, Set-SqlCacheCredential, Remove-SqlCacheCredential
.EXAMPLE 
    PS:\>Get-SqlCacheCredential -Server $srv1 -Database $db

    Retrieve a credential for a specific database. Unless the -Exact option is specified, this will roll up to a server level lookup if a password does not exist for the named database.
.EXAMPLE
    PS:\>Get-SqlCacheCredential -Server $srv1

    Retrieve the credential to use when connecting to databases on Srv1 that do not have a more specific Srv1/Database entry in the cache.
.EXAMPLE
    PS:\>Get-SqlCacheCredential

    A single cached credential (a global login) may be set for all servers, all databases. If one is defined by Set-Credential, this retreives it.
.INPUTS
    None.
.OUTPUTS
    An SQLCredential or a PSCredential if -AsPSCredential is specified. $null if no matching $srv/$db is found and a global credential was not specified.
.NOTES
    Author: Mike Dumdei
#>    
    [CmdletBinding(DefaultParameterSetName="GlobalCred")]
    [OutputType([System.Data.SqlClient.SqlCredential])]
    [OutputType([PSCredential],ParameterSetName="PSCred")]
    param(
        [Parameter(Position=0, ParameterSetName="Server")]
        [Parameter(Position=0, ParameterSetName="DB",Mandatory)]
          [string]$Server,
        [Parameter(Position=1, ParameterSetName="DB",Mandatory)]
          [string]$Database,
        [Parameter(Position=2, ParameterSetName="GlobalCred")]
        [Parameter(Position=2, ParameterSetName="Server")]
        [Parameter(Position=2, ParameterSetName="DB")]
          [Switch]$Exact,
        [Parameter(Position=3, ParameterSetName="GlobalCred")]
        [Parameter(Position=3, ParameterSetName="Server")]
        [Parameter(Position=3, ParameterSetName="DB")]          
        [Parameter(Position=3, ParameterSetName="PSCred")]
         [Switch]$AsPSCredential
    )
    [string]$DEFAULT = "__DEFAULT__"
    [System.Data.SqlClient.SqlCredential]$creds = $null
    if ([string]::IsNullOrEmpty($Server)) { $Server = $DEFAULT }
    if ([string]::IsNullOrEmpty($Database)) { $Database = $DEFAULT }
    if ([SqlSettings]::SqlCreds.ContainsKey("${Server}${Database}")) {
        $creds = [SqlSettings]::SqlCreds["${Server}${Database}"]
    }
    elseif ([SqlSettings]::SqlCreds.ContainsKey("${Server}$DEFAULT") -and (!$Exact -or $Database -eq $DEFAULT)) {
        $creds = [SqlSettings]::SqlCreds["${Server}$DEFAULT"]
    }
    elseif ([SqlSettings]::SqlCreds.ContainsKey("$DEFAULT$DEFAULT") -and (!$Exact -or $Server -eq $DEFAULT)) {
        $creds = [SqlSettings]::SqlCreds["$DEFAULT$DEFAULT"]
    } else { return $null }
    if ($AsPSCredential -eq $true) {
        $creds.Password.MakeReadOnly()
        return $(New-Object PSCredential($creds.UserID, $creds.Password))
    } 
    return $creds
}
