InModuleScope -ModuleName SDSqlQuery -ScriptBlock {
    BeforeAll {
        $dataTbl = New-Object System.Data.DataTable
        $dataTbl.Columns.Add("key", "Int32")
        $dataTbl.Columns.Add("col1", "string")
        $dataTbl.Columns.Add("col2", "datetime")
        $data = @(
            @(0, "Item 1", [DateTime]$(New-Object DateTime(2001,12,31))),
            @(1, "Item 2", [DateTime]$(Get-Date))
        )
        foreach ($itm in $data) {
            $r = $dataTbl.NewRow()
            $r.key = $itm[0]; $r.col1 = $itm[1];  $r.col2 = $itm[2];
            $dataTbl.Rows.Add($r)
        }
        $fname = "TestDrive:\Data.csv"
    }   

    Describe "SDSqlQuery Trace Log Test" {
        It "Data table has rows" {
            $dataTbl.Rows.Count | Should -Be 2
        }
        It "Tracing is enabled" {
            Enable-SqlTrace 
            Get-SqlTraceEnabled | Should -Be $true
        }
        It "Trace log should be cleared" {
            Clear-SqlTraceLog
            $(Get-SqlTrace).Count | Should -Be 0
        }
        It "SqlTrace object should be returned" {
            $logObj = New-Object SqlTrace "sqlSrv1", "myDb", "select max(itm) from tbl where x = @y", @{ y = 0 }
            $logObj.Data = $dataTbl
            $logObj | Should -Be SqlTrace
        }
        It "SqlTrace item should be added to trace log" {
            $itm = Get-SqlTrace 0
            $itm | Should -Be SqlTrace
            $itm.Srv | Should -Be "sqlSrv1"
            $itm.Data.GetType().Name | Should -Be "DataTable"
        }
        It "Write-SqlTrace log produces expected result" {
            $s = $(Write-SqlTraceLog 0).ToString()
            $s.StartsWith("idx    :0`r`nsrv/db :sqlSrv1,myDb") | Should -Be $true
        }
        It "Trace log should be cleared" {
            Clear-SqlTraceLog
            $(Get-SqlTrace).Count | Should -Be 0            
        }
        It "Tracing should be disabled" {
            Disable-SqlTrace
            Get-SqlTraceEnabled | Should -Be $false
        }
        It "Trace log should not add new items" {
            $logObj = New-Object SqlTrace "sqlSrv1", "myDb", "select max(itm) from tbl where x = @y", @{ y = 0 }
            $(Get-SqlTrace).Count | Should -Be 0
            $(Get-SqlTrace 0) | Should -Be $null
        }
        It "Writing to log file creates CSV file" {
            Enable-SqlTrace
            Clear-SqlTraceLog
            $trcObj = New-Object SqlTrace "sqlSrv1", "myDb", "select itm from tbl where x = @y", @{ y = 0 }
            $trcObj.Data = $dataTbl
            Write-SqlTraceLog 0 -LogFile $fname -ExpandTables -MapFields @{ col2 = "MapDate:|MM-dd-yy|"}
            $v = Get-Content $fname -Raw
            $v.IndexOf("MapDate")  | Should -BeGreaterThan 0
            $v.IndexOf("12-31-01") | Should -BeGreaterThan 0
        }
    }
}