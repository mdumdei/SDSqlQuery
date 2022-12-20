function Open-SqlConnection {
<#
.SYNOPSIS
    Open a connection to a SQL server.
.DESCRIPTION
    Open an SQL connection to a server. Invoke-SqlQuery automatically opens and closes connections using its ConnectionString parameter or Server and Database parameters, so calling this directly is only necessary if you want to pass Invoke-SqlQuery an open connection via the SqlConnection parameter.

    Connection strings may include placeholders for username and password fields. Placeholder values are "|user|" and "|pw|". When using place holders, the  values for "|user|" and "|pw|" are extracted from the passed Credential parameter or a cached credential if using cached credentials.
.PARAMETER ConnectionString
    Connection string to use for the connection. Credential may be embedded or passed in the Credential parameter.
.PARAMETER Credential
    Credential for connection, if not provided and not in session cache uses Integrated Security.
.PARAMETER Server
    If not using a connection string, this is the server for the connection.
.PARAMETER Database
    If not using a connection string, this is the database for the connection.
.INPUTS
    None.
.OUTPUTS
    SqlConnection, Exception.
.EXAMPLE
    PS> $connStr = "Server=$srv1;Database=$db;MultipleActiveResultSets=true;User ID=$user;Password=$pass;"
    PS> [SqlConnection]$conn = Open-SqlConnection -ConnectionString $connStr

    Open an SQL connection using a connection string and a plaintext password stored in a PS variable.
.EXAMPLE
    PS> $connStr = "Server=$srv1;Database=$db;MultipleActiveResultSets=true;User ID=|user|;Password=|pw|;"
    PS> [SqlConnection]$conn = Open-SqlConnection -ConnectionString $connStr -Credential $creds

    Open a connection with the user name and password extracted from the Credential value. Credential can either by passed as one of the parameters or pre-cached (See Set-SqlCacheCredential).
.EXAMPLE
    PS> $connStr = "Server=$srv1;Database=$db;"
    PS> [SqlConnection]$conn = Open-SqlConnection -ConnectionString $connStr -Credential $creds

    Open an SQL connection using a connection string. The difference between this and the previous example is this example assigns the $creds value to the SqlConnection object's password property vs. embedding it in the connection string. The credential could also be retrieved from the credential cache (see Set-SqlCacheCredential).
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
        [Parameter(Position = 2)][Object]$Credential
    )
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $cstr = $ConnectionString
    if ([string]::IsNullOrEmpty($cstr) -and [string]::IsNullOrEmpty($Server)) {
        $cstr = [SqlSettings]::SqlConnectionString
    }
    elseif ([string]::IsNullOrEmpty($Server) -eq $false) {
        $cstr = "Server=$Server;Database=$Database;"
    }
    if ($null -eq $cstr) {
        throw "Connection string not provided and no value found in cache"
    }
    $conn.ConnectionString = $cstr
    $srv = $conn.DataSource
    $db = $conn.Database
    if ($null -ne $Credential) {
        if ($Credential -is [System.Data.SqlClient.SqlCredential]) {
            $psCreds = $null
            $sqlCreds = $Credential
        } elseif ($Credential -is [PSCredential]) {
            $Credential.Password.MakeReadOnly()
            $sqlCreds = New-Object System.Data.SqlClient.SqlCredential($Credential.UserName, $Credential.Password)
        } else {
            throw "Connect-Sql: Credential must be PSCredential or SqlCredential"
        }
    } else {
        $sqlCreds = Get-SqlCacheCredential -Server $srv -Database $db
    }
    if ($null -eq $sqlCreds -and [string]::IsNullOrEmpty($Server) -eq $false) {
        $semi = @(';','')[$cstr.EndsWith(';')]
        $conn.ConnectionString = "${cstr}${semi}Integrated Security=true;"
    } elseif ($null -ne $sqlCreds) {
        if ($cstr.Contains("|user|") -or $cstr.Contains("|pw|")) {
            if ($null -eq $psCreds) {
                $sqlCreds.Password.MakeReadOnly()
                $psCreds = New-Object PSCredential($sqlCreds.UserID, $sqlCreds.Password)
            }
            $cstr = $cstr.Replace("|user|", $psCreds.UserName)
            $conn.ConnectionString = $cstr.Replace("|pw|", $psCreds.GetNetworkCredential().Password)
        } else {
            $conn.Credential = $sqlCreds
        }
    }
    try {
        $conn.Open()
        return $conn
    } catch {
        throw "SQL connection failed: $($_.Exception.Message)"
    }
}
