InModuleScope -ModuleName SDSqlQuery -ScriptBlock {
    BeforeAll {
        $user = "someone"
        $pw = ConvertTo-SecureString "myPw" -AsPlainText -Force
        $pw.MakeReadOnly()
        $psCred = New-Object PSCredential($user, $pw)
        $sqlCred = New-Object System.Data.SqlClient.SqlCredential($user, $pw)
    }

    Describe "OpenSqlConnection Tests" {
        It "Connection string with integrated security is ok" {
            $conn = Open-SqlConnection -ConnectionString "Server=srv1;Database=db1;Integrated Security=true" -NoOpen
            $conn.DataSource | Should -Be "srv1"
            $conn.Database | Should -Be "db1"
            $conn.ConnectionString | Should -BeLike "*Integrated Security*"
        }
        It "Connection string with place holder is ok" {
            Set-SqlCacheCredential $psCred
            $conn = Open-SqlConnection -ConnectionString "Server=srv1;Database=db1;User ID=*" -NoOpen
            $conn.DataSource | Should -Be "srv1"
            $conn.Database | Should -Be "db1"
            $conn.Credential.UserId | Should -Be $psCred.UserName
        }
        It "Srv/DB and no cache is ok" {
            Clear-SqlCacheCredential -All
            $conn = Open-SqlConnection -Server "srv1" -Database "db1" -NoOpen
            $conn.DataSource | Should -Be "srv1"
            $conn.Database | Should -Be "db1"
            $conn.ConnectionString | Should -BeLike "*Integrated Security*"
        }
        It "Srv/DB and cache is ok" {
            Set-SqlCacheCredential $psCred
            $conn = Open-SqlConnection -Server "srv1" -Database "db1" -NoOpen
            $conn.DataSource | Should -Be "srv1"
            $conn.Database | Should -Be "db1"
            $conn.Credential.UserId | Should -Be $sqlCred.UserId
        }
        It "Srv/DB and missed cache is ok" {
            Clear-SqlCacheCredential -All
            Set-SqlCacheCredential -Server "srv2" -Credential $psCred
            $conn = Open-SqlConnection -Server "srv1" -Database "db1" -NoOpen
            $conn.DataSource | Should -Be "srv1"
            $conn.Database | Should -Be "db1"
            $conn.ConnectionString | Should -BeLike "*Integrated Security*"
        }
        It "Cache connection string is ok" {
            Set-SqlCacheConnectionString "Server=srv2;Database=db2;User ID=*"
            Set-SqlCacheCredential -Server "srv2" -Credential $psCred
            $conn = Open-SqlConnection -NoOpen
            $conn.DataSource | Should -Be "srv2"
            $conn.Database | Should -Be "db2"
            $conn.Credential.UserId | Should -Be $psCred.UserName
        }
    }
}