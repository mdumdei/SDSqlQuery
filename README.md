# SDSqlQuery Module

The primary goal of this module is to provide scripts a single function through which all SQL queries are routed vs. having SQL connects and queries scattered throughout the script. The primary cmdlet, **Invoke-SqlQuery**, processes the three main types of queries: **Reader**, **Scalar**, and **NonQuery**, and distinguishes between **CommandText** and **Stored Procedure** types. Query command text can be single statements, multi-line blocks, transactions, include try/catch - anything supported by the target server. Query parameters are passed as a hash table (key/value pairs).

Additional supporting cmdlets within the module add functionality related to keeping a running trace of SQL activity, caching connnection strings and credentials, generating CSV output, and post-query manipulation of tabular results. The cmdlets to set a default connection string and pre-cache credentials allow for calls within the script to require only the query text and necessary parameters (compare the first example below to the remaining queries).

### Invoke-SqlQuery Examples
    $dat = Invoke-SqlQuery -Reader 
            -Query "SELECT col1, col2 FROM tbl WHERE x = @a AND z < @b"
            -Params @{ x = "Sales"; z = 10000 }
            -ConnectionString "Server=$srv;Database=$db"
            -Credential $creds

    $val = Invoke-SqlQuery -Scalar 
            -Query "SELECT max(amount) FROM tbl WHERE category = @cat" 
            -Params @{ cat = "Pets" }
    
     # using a PS variable as parameter value
    $nRw = Invoke-SqlQuery -NonQuery
            -Query "DELETE FROM tbl WHERE date < '$cutOffDate'"
    
    $spX = Invoke-SqlQuery -Reader 
            -Query "EXEC sp_getStuff @yr, @qtr"
            -Params @{ yr = "2023", qtr = "Fall" }
            
To access tabular results (i.e., first example):

    foreach ($r in $dat) {
        Write-Output "$($r.col1), $($r.col2)"
    }


A **trace option** is provided that, if enabled, keeps a history of all commands, parameters, and results processed by Invoke-SqlHistory. Trace is useful for debugging or logging purposes. 

### Mapping and CSV File Output
Two other features to note are a mapping function and the ablity to route results directly to a CSV file without piping output through ConvertTo-Csv. The mapping function provides on-the-fly renaming of column names coming from the query and application of date and number formats when saving as a CSV.

In the example that follows, the columns from the query are mapped to new names and the output is sent to 'TheData.csv' instead of being returned by the function. The **MapFields** parameter controls output column names and optional formatting. For the purpose of the example assume the 'ch100' field is defined as CHAR(100). Since the column is not NVARCHAR or VARCHAR it will have spaces to pad the it out to 100 characters. Using 'trim' in the MapFields parameter for that column trims the trailing spaces. Dates and numeric fields of any sort can be formatted with standard format codes. To trim or apply numeric formats, follow the mapped column name with a colon and put the code between pipe symbols. For queries sent to a CSV file, Invoke-SqlQuery does not return a value.

    Invoke-SqlQuery -Reader 
     -Query "SELECT col1, col2, ch100, hdate, FROM tbl WHERE x = @a AND z < @b"
     -Params @{ x = 'Sales'; z = 10000 }
     -MapFields { col1 = "FirstName"; col2 = "LastName"; ch100 = "Title:|trim|"; hdate = "HireDate:|MM/dd/yyyy|" }
     -FileName TheData.csv
     
Using MapFields to rename columns is also useful when working with data that comes back from the query with native names you just don't want to work with in your script. For instance, the DB design team likes column names like appxyz_datetime_hiredate, but you prefer to reference it as $dat.HireDate instead of $dat.appxyz_datetime_hiredate in your code.


## Performance
The module comes as either a **native PowerShell** or a **compiled C#** module. Both take the same parameters, but there are some differences related to performance and return values of tabular results. Queries that run a '**SqlReader**' query can be invoked with one of two Invoke-SqlQuery switches. The first is **-Reader** and the other is **-RawReader**. A summary of differences comparing native vs. C# / Reader vs. RawReader is outlined in the table below:

||Native PowerShell|Compiled C#|
|:---|:---|:---|
|**Reader**|- Returns PSObject[]|- Returns PSObject[]
||- Slow performance on large result sets|- Fast performance
||- Converts DBNull to PS null|- Converts DBNull to PS null
||- MapFields supported|- MapFields supported
||||
|**RawReader**|- Returns PSObject[]|- Returns DataTable object
||- Fast performance|- Fast performance
||- Leaves DBNull as DBNull|- Leave DBNull as DBNull
||- MapFields not available|- MapFields not available

Unless you are dealing with large result sets and using the native PowerShell version of the module, use Reader. RawReader has two applications: 1) you are using the native script module and have large result sets and, 2) you want a DataTable instead of PSObject array and are using the C# module. All versions store tabular trace data as DataTable objects, so that is an option if you must have a DataTable.


