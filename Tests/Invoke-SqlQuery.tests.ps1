InModuleScope -ModuleName SDSqlQuery -ScriptBlock {
    BeforeAll {
        $user = "someone"
        $pw = ConvertTo-SecureString "myPw" -AsPlainText -Force
        $pw.MakeReadOnly()
        $psCred = New-Object PSCredential($user, $pw)
        $sqlCred = New-Object System.Data.SqlClient.SqlCredential($user, $pw)
        $psCred2 = New-Object PSCredential("override", $pw)
    }

    Describe "Invoke-SqlQuery Tests" {
        It "Reader query works as expected" {
            $cmd = Invoke-SqlQuery -TestMode `
                    -Server "srv1" `
                    -Database "db1" `
                    -Reader `
                    -Query "select * from tbl where x > @y" `
                    -Params @{ y = 100 } 
            $cmd.CommandText | Should -Be "select * from tbl where x > @y"
            $cmd.Parameters.Value | Should -Be 100
            $cmd.Connection.Database | Should -Be "db1"
        }
        It "Scalar query works as expected" {
            Set-SqlCacheConnectionString "Server=srv2;Database=db2;User ID=*"
            Set-SqlCacheCredential $psCred
            $cmd = Invoke-SqlQuery -TestMode -Scalar -Query "select max(val) from tbl" -CommandTimeOut 8
            $cmd.CommandTimeOut | Should -Be 8
            $cmd.Connection.DataSource | Should -Be "srv2"
            $cmd.Connection.Credential.UserId | Should -Be "someone"
        }
        It "NonQuery stored procedure works as expected" {
            Set-SqlCacheConnectionString "Server=srv2;Database=db2;User ID=*"
            Set-SqlCacheCredential $psCred
            $cmd = Invoke-SqlQuery -TestMode -NonQuery -Query "exec sp_stuff @x, @y" -Params @{ x = "parm1"; y = 100 } -Credential $psCred2
            $cmd.CommandText | Should -Be "sp_stuff @x, @y"
            $cmd.CommandType.ToString() | Should -Be "StoredProcedure"
            $cmd.Connection.Credential.UserId | Should -Be "override"
            if ($cmd.Parameters[0].ParameterName -eq "@x") {
                $cmd.Parameters[0].Value | Should -Be "parm1"
                $cmd.Parameters[1].Value | Should -Be 100
            } else {
                $cmd.Parameters[0].ParameterName | Should -Be "@y"
                $cmd.Parameters[0].Value | Should -Be 100
                $cmd.Parameters[1].Value | Should -Be "parm1"
            }
        }
        It "Throws exception if placeholder used and no cred" {
            Clear-SqlCacheConnectionString
            Clear-SqlCacheCredential
            Set-SqlCacheConnectionString "Server=srv1;Database=db1;User ID=*"
            { Invoke-SqlQuery -Reader -Query "select * from tbl" } | Should -Throw "ConnectionString uses placeholders*"
        }
    }
}