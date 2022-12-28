function Set-SqlCacheConnectionString {
    <#    
    .SYNOPSIS
    Set a default value for module cmdlets that take a ConnectionString parameter.
    .DESCRIPTION
    Invoke-SqlQuery and Open-Connection both can take an SQL connection string as a parameter. Oftentimes, the same connection string is used for repeated calls to the same database. This command presets the value of the ConnectionString parameter so that it does not have to be specified each time Invoke-SqlQuery is called. The "cached" version is ignored if a different one is directly specified when calling Invoke-SqlQuery.

    Connection strings may include an asterisk as a placeholder for the User ID and/or Password. The result is the same if the asterisk appears in either location: The string will be used to identify the server and database, but the actual 'User ID' and 'Password' will come from the Credential parameter if one is specified or a cached Credential if the calling function does not specify one directly. Using a placeholder prevents exposure of plaintext passwords. If a placeholder is used, you MUST supply a Credential or have one cached.
    .PARAMETER ConnectionString
    Default SQL connection string.
    .EXAMPLE
    PS:\>Set-SqlCacheConnectionString "Server=srv1;Database=db;User ID=*;"
    
    Set a connection string where the user name and password are extracted from the Credential value at the time of the connection. Credential can either by passed as one of the parameters or pre-cached  (See Set-SqlCacheCredential).
    .EXAMPLE
    PS:\>Set-SqlCacheConnectionString "Server=srv1;Database=db;User ID=jake;Password=pass"
    
    Set a connection string that has a plain text password.
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
    