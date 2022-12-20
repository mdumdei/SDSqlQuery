function Get-SqlCacheConnectionString {
    <#    
    .SYNOPSIS
        Retreive default value for module cmdlets that take a ConnectionString parameter.
    .DESCRIPTION
        Returns the connection string currently used for Invoke-SqlQuery or Open-SqlConnection calls where no connection information is provided.

        See Set-SqlCacheConnectionString.
    .EXAMPLE
        PS> Get-SqlCacheConnectionString
    
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
        