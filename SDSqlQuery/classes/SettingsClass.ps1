using namespace System
using namespace System.Text
using namespace System.Collections.Generic
using namespace System.Data
using namespace System.Data.SqlClient

# Class for holding settings values. 

class SqlSettings {
    # cached SQL credential store
    static [Dictionary[string,SqlCredential]]$SqlCreds = $(New-Object Dictionary"[string,SqlCredential]")
    # cached SQL connection string
    static [string]$SqlConnectionString = $null
}
