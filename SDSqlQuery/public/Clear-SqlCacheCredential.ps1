function Clear-SqlCacheCredential {
<#    
.SYNOPSIS
    Remove a credential from the SQL credential cache.
.DESCRIPTION
    When performing multiple queries from within a script, the same login credential is often used for all connections. Set-SqlCacheCredential presets the SQL login credential so the Credential parameter may be omitted when calling Invoke-SqlQuery. This command is used to remove preset credentials set using Set-SqlCacheCredential.

    Related cmdlets: Invoke-SqlQuery, Set-SqlCacheCredential, Get-SqlCacheCredential
.PARAMETER Server
    Removes a server level (true unless using contained databases) credential.
.PARAMETER Database
    If using contained databases, the database parameter allows removal a per database credential.
.PARAMETER All
    Remove all cached credentials.
.EXAMPLE
    PS:\>Clear-SqlCacheCredential -Server Srv1

    Remove SQL credentials for logins for a specific server. Unless using contained databases, this will be the lowest level credential.
.EXAMPLE
    PS:\>Clear-SqlCacheCredential

    If a credential was set without setting a server name, that credential applies to all connections that do not have a more specific credential set. This removes that one "global" credential.
.EXAMPLE
    PS:\>Clear-SqlCacheCredential -All

    Compleletly clear the credential cache.
.INPUTS
    None.
.OUTPUTS
    None.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding(DefaultParameterSetName = "SrvDB")]
    [OutputType([Void])]
    param(
        [Parameter(Position=0, ParameterSetName = 'SrvDB')]$Server,
        [Parameter(Position=1, ParameterSetName = 'SrvDB')]$Database,
        [Parameter(Position=0,ParameterSetName='All')][Switch]$All
    )
    if ($All) {
        [SqlSettings]::SqlCreds.Clear()
    } else {
        [string]$DEFAULT = "__DEFAULT__"
        if ([string]::IsNullOrEmpty($Server)) { $Server = $DEFAULT }
        if ([string]::IsNullOrEmpty($Database)) { $Database = $DEFAULT }
        $key = "${Server}${Database}"
        if ([SqlSettings]::SqlCreds.ContainsKey($key)) {
            [SqlSettings]::SqlCreds.Remove($key)
        }
    }
}
