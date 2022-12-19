function Set-SqlCacheConnectionString {
    <#    
    .SYNOPSIS
    Set a default value for module cmdlets that take a ConnectionString parameter.
    .DESCRIPTION
    Invoke-SqlQuery and Open-Connection both take an SQL connection string as a 
    parameter. Oftentimes, the same connection string is used for repeated calls
    to the same database. This cmdlet pre-sets the value of the ConnectionString
    parameter so that it does not have to be specified on a per query basis. The
    "cached" version is ignored if one is directly specified when invoking either
    of these functions.

    Connection strings may include placeholders for username and password fields.
    Placeholder values are "|user|" and "|pw|". When using place holders, the 
    values for "|user|" and "|pw|" are extracted from the  passed Credential 
    parameter or a cached credential if using cached credentials.
    .PARAMETER ConnectionString
    Default SQL connection string.
    .EXAMPLE
    PS> Set-SqlCacheConnectionString "Server=srv1;Database=db;User ID=jake;Password=pass"
    
    Set a connection string that has a plain text password.
    .EXAMPLE
    PS> Set-SqlCacheConnectionString "Server=srv1;Database=db;User ID=|user|;Password=|pw|"
    
    Set a connection string where the user name and password are extracted from the Credential
    value at the time of the connection. Credential can either by passed as one of the 
    parameters or pre-cached as well (See Set-SqlCacheCredential).
    .INPUTS
    None.
    .OUTPUTS
    None.
    .NOTES
    Author: Mike Dumdei
    #>
        [CmdletBinding()]
        [OutputType([Void])]
        param(
            [Parameter(Position=0,Mandatory)][string]$ConnectionString
        )
        [SqlSettings]::SqlConnectionString = $ConnectionString
    }
    