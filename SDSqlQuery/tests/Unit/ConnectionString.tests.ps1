InModuleScope -ModuleName SDSqlQuery -ScriptBlock {
    Describe "ConnectionString Tests" {
        It "Test set default ConnectionString" {
            Set-SqlCacheConnectionString "Server=srv1;Database=db1;User ID=*"
            $s = Get-SqlCacheConnectionString
            $s | Should -Be "Server=srv1;Database=db1;User ID=*"
        }

        It "Test clear ConnectionString" {
            $s = Get-SqlCacheConnectionString
            $s | Should -Be "Server=srv1;Database=db1;User ID=*"
            Clear-SqlCacheConnectionString
            $s = Get-SqlCacheConnectionString
            [string]::IsNullOrEmpty($s) | Should -Be $true
        }
    }
}