# Class for holding settings values. 

class SqlSettings {
    # cached SQL credential store
    static [System.Collections.Generic.Dictionary[string,System.Data.SqlClient.SqlCredential]]$SqlCreds = $(New-Object System.Collections.Generic.Dictionary"[string,System.Data.SqlClient.SqlCredential]")
    # cached SQL connection string
    static [string]$SqlConnectionString = $null
}
