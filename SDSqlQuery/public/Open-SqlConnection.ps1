function Open-SqlConnection {
<#
.SYNOPSIS
    Open a connection to a SQL server.
.DESCRIPTION
    Open an SQL connection to a server. Invoke-SqlQuery automatically opens and closes connections using its ConnectionString parameter or Server and Database parameters, so calling this directly is only necessary if you want to pass Invoke-SqlQuery an open connection via the SqlConnection parameter.

    Connection strings may include placeholders for username and/or password fields. A placeholder is simply entering an '*' for either the User ID or Password fields. If an '*' is placed in either, the connection will connect to the server and database specified in the connection string. The credentials will come from the Credential parameter if present and from a SqlCacheCredential if the function itself does not specify the parameter. An error is thrown if a placeholder is specified and no credential can be located. See Set-SqlCacheCredential.

    The 'NoOpen' switch does everything except actually Open the connection. If specified, the return value is an unopened SqlConnection object vs. an opened SqlConnection object. The purpose of the switch is primarily for unit tests and debugging, but it does provide a final hook before the Open call if needed for other purposes.
.PARAMETER ConnectionString
    Connection string to use for the connection. Credential may be embedded or passed in the Credential parameter.
.PARAMETER Credential
    Credential for connection, if not provided and not in session cache uses Integrated Security.
.PARAMETER Server
    If not using a connection string, this is the server for the connection.
.PARAMETER Database
    If not using a connection string, this is the database for the connection.
.PARAMETER NoOpen
    Return an unopened SqlConnection object ready for the Open call. 
.INPUTS
    None.
.OUTPUTS
    SqlConnection, Exception.
.EXAMPLE
    PS> $connStr = "Server=$srv1;Database=$db;MultipleActiveResultSets=true;User ID=$user;Password=$pass;"
    PS> [SqlConnection]$conn = Open-SqlConnection -ConnectionString $connStr

    Open an SQL connection using a connection string and a plaintext password stored in a PS variable.
.EXAMPLE
    PS>  # At beginning of script - at least that is the idea - set once and forget
    PS> Set-SqlCacheConnectionString "Server=sqlSrv;Database=myDB;User ID=*;"
    PS> Set-SqlCacheCredential $creds
    PS>  # Remaining parts of the script unless an override is needed, BUT let Invoke-SqlQuery handle connections unless there is a reaon not to.
    PS> [SqlConnection]$conn = Open-SqlConnection

    Open a connection using cached values. The '*' in the connection string signifies the User ID and Password values are to be retrieved from a passed Credential parameter or from the credential cache (see Set-SqlCacheCredential).
.EXAMPLE
    PS> $connStr = "Server=$srv1;Database=$db;"
    PS> [SqlConnection]$conn = Open-SqlConnection -ConnectionString $connStr -Credential $creds

    Open an SQL connection using a connection string. The difference between this example and the previous one is this example directly specifies the connection string and credentials where in the previous example they were pulled from the cache.
.EXAMPLE
    PS> [SqlConnection]$conn = Open-SqlConnection -Server Srv1 -Database DB1 -Credential $creds

    Open an SQL connection to Srv1 with the default database set to DB1.
.NOTES
    Author: Mike Dumdei
#>
    [CmdletBinding(DefaultParameterSetName="UseCache")]
    [OutputType([System.Data.SqlClient.SqlConnection])]
    param (
        [Parameter(Position = 0, ParameterSetName="ConnStr", Mandatory)][string]$ConnectionString,
        [Parameter(Position = 0, ParameterSetName="SrvDB", Mandatory)][string]$Server,
        [Parameter(Position = 1, ParameterSetName="SrvDB", Mandatory)][string]$Database,
        [Parameter(Position = 2)][Object]$Credential,
        [Parameter(Position = 3)][Switch]$NoOpen
    )
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $scb = $null
    $sqlCreds = $null
    $havePlaceHolders = $false; $isSrvDB = $false
    $cstr = $ConnectionString
    if ([string]::IsNullOrEmpty($cstr) -and [string]::IsNullOrEmpty($Server)) {
        if ([string]::IsNullOrEmpty([SqlSettings]::SqlConnectionString) -eq $false) {
            $cstr = [SqlSettings]::SqlConnectionString
        } else {
            throw "ConnectionString or Server/Database not provided and not in cache"
        }
    }
    if ([string]::IsNullOrEmpty($Database)) {
        $scb = New-Object System.Data.SqlClient.SqlConnectionStringBuilder($cstr)
        $havePlaceHolders = $($scb.UserID -eq "*" -or $scb.Password -eq "*")
    } else {
        $scb = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
        $scb.Add("Data Source", $Server)
        $scb.Add("Initial Catalog", $Database)
        $isSrvDB = $true
    }
    if ($Credential -is [System.Data.SqlClient.SqlCredential]) {
        $sqlCreds = $Credential
    } elseif ($Credential -is [PSCredential]) {
        $Credential.Password.MakeReadOnly()
        $sqlCreds = New-Object System.Data.SqlClient.SqlCredential($Credential.UserName, $Credential.Password)
    } elseif ($null -ne $Credential) {
        throw "Credential must be PSCredential or SqlCredential"
    }
    if ($null -eq $sqlCreds -and ($isSrvDB -or $havePlaceHolders)) {
        $sqlCreds = Get-SqlCacheCredential $scb.DataSource $scb.InitialCatalog
        if ($null -eq $sqlCreds) {
            if ($havePlaceHolders) {
                throw "ConnectionString uses placeholders but credential not provided or in cache"
            } else {
                $scb.Add("Integrated Security", $true)
            }
        }
    }
    if ($null -ne $sqlCreds) {
        foreach ($k in @("User ID","Password","Integrated Security")) {
            $scb.Remove($k) | Out-Null
        }
        $conn.Credential = $sqlCreds
    }
   try {
        $conn.ConnectionString = $scb.ConnectionString
        if ($NoOpen -eq $false) {
            $conn.Open()            
        }
        return $conn
    } catch {
        throw "SQL connection failed: $($_.Exception.Message)"
    }
}
