function Clear-SqlCacheConnectionString {
<#    
.SYNOPSIS
    Clear the default connection string if one is set.
.DESCRIPTION
    In scripts where multiple SQL queries are performed, the same connnection string is often used for all queries. Set-SqlCacheConnectionString can be used to preset a default connection string to avoid the need to pass the ConnectionString parameter to Invoke-SqlQuery on a per-call basis. This command clears the default connection string if one is present.
    
    Related cmdlets: Invoke-SqlQuery, Open-SqlConnection, Set-SqlCacheConnectionString
.EXAMPLE
    PS:\>Clear-SqlCacheConnectionString

    Removes any existing default value for the ConnectionString parameter of Invoke-SqlQuery and/or Open-SqlConnection.
.INPUTS
    None.
.OUTPUTS
    None.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding()]
    [OutputType([Void])]
    param()
    [SqlSettings]::SqlConnectionString = $null
}
    