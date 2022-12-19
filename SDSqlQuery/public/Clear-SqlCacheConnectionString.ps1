function Set-SqlCacheConnectionString {
    <#    
    .SYNOPSIS
    Clear the default connection string.
    .DESCRIPTION
    Clear the default connection string used for SQL connections.

    Related cmdlets: Invoke-SqlQuery, Open-SqlConnection, Set-SqlCacheConnectionString
    .EXAMPLE
    PS> Clear-SqlCacheConnectionString
    
    Removes any existing default value for ConnectionString parameter of Invoke-SqlQuery 
    and/or Open-SqlConnection.
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
        [SqlSettings]::SqlConnectionString = $null
    }
    