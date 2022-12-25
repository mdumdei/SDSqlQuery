function Get-SqlCacheConnectionString {
    <#    
    .SYNOPSIS
        Retreive default value for module cmdlets that take a ConnectionString parameter.
    .DESCRIPTION
        In scripts where multiple SQL queries are performed, the same connnection string is often used for all queries. Set-SqlCacheConnectionString can be used to preset a default connection string to avoid the need to pass the ConnectionString parameter to Invoke-SqlQuery on a per-call basis. This command displays the active default connection string if one is present.

        See Set-SqlCacheConnectionString.
    .EXAMPLE
        PS:\>Get-SqlCacheConnectionString
    
        Retrieve default connection string.
    .INPUTS
        None.
    .OUTPUTS
        String.
    .NOTES
        Author: Mike Dumdei
    #>
        [CmdletBinding()]
        [OutputType([string])]
        param()
        return [SqlSettings]::SqlConnectionString
    }
        