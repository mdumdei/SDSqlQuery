InModuleScope -ModuleName SDSqlQuery -ScriptBlock {
    BeforeAll {
        $user = "someone"
        $pw = ConvertTo-SecureString "myPw" -AsPlainText -Force
        $pw.MakeReadOnly()
        $cred1 = New-Object PSCredential($user, $pw)
        $cred2 = New-Object System.Data.SqlClient.SqlCredential("user2", $pw)
    }

    Describe "Credential Tests" {
        It "Test set global cred" {
            Set-SqlCacheCredential $cred1
            $cred = Get-SqlCacheCredential
            $cred | Should -Be System.Data.SqlClient.SqlCredential
            $cred.UserId | Should -Be "someone"
        }

        It "Test server specific credentials" {
            Set-SqlCacheCredential -Server "srv2" -Credential $cred2
            $cred = Get-SqlCacheCredential -Server "srv1"
            $cred.UserId | Should -Be "someone"
            $cred = Get-SqlCacheCredential -Server "srv2"
            $cred.UserId | Should -Be "user2"
        }

        It "Test clear global credential" {
            Clear-SqlCacheCredential 
            $cred = Get-SqlCacheCredential
            $cred | Should -Be $null
            $cred = Get-SqlCacheCredential -Server "srv2"
            $cred.UserId | Should -Be "user2"
        }

        It "Test clear all credentials" {
            Set-SqlCacheCredential $cred1
            Clear-SqlCacheCredential -All
            $cred = Get-SqlCacheCredential -Server "srv2"
            $cred | Should -Be $null
            $cred = Get-SqlCacheCredential
            $cred | Should -Be $null
        }
    }
}