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
    }   

    Describe "Conversion Tests" {
        It "Data table has rows" {
            $dataTbl.Rows.Count | Should -Be 2
        }
        It "Data item is loaded into trace log" {
            Enable-SqlTrace 
            Clear-SqlTraceLog
            $trcObj = New-Object SqlTrace "sqlSrv1", "myDb", "select max(itm) from tbl where x = @y", @{ y = 0 }
            $trcObj.Data = $dataTbl
            $itm = Get-SqlTrace 0
            $itm | Should -Be SqlTrace
            $itm.DB | Should -Be "myDB"
            $itm.Data.GetType().Name | Should -Be "DataTable"
        }
        It "Convert-QueryToObjects produces expected result" {
            $objs = Convert-QueryToObjects (Get-SqlTraceData 0)
            $objs.Count | Should -Be 2
            $objs[0].col2 | Should -Be $(New-Object DateTime(2001,12,31))
            $r = $dataTbl.NewRow()
            $r.Key = 3; $r.col1 = "Itm3  "; $r.col2 = [DateTime]$(New-Object DateTime(2002,01,01))
            $dataTbl.Rows.Add($r)
            $v = $($r | Convert-QueryToObjects)
            $v.GetType().Name | Should -Be "PSCustomObject"
            $v.col1 | Should -Be "Itm3  "
            $v = Convert-QueryToObjects $v -MapFields @{ col1 = "Map1:|trim|"}
            $v.Map1 | Should -Be "Itm3"
        }
        It "Convert-QueryToCsv produces expected result" {
            $s = $(Get-SqlTrace 0 | Convert-QueryToCsv)
            $csv = ConvertFrom-Csv -InputObject $s
            $csv[0].Key | Should -Be 0
            $csv[1].col1 | Should -Be "Item 2"
            $r = $dataTbl.NewRow()
            $r.Key = 3; $r.col1 = "Itm3  "; $r.col2 = [DateTime]$(New-Object DateTime(2020,06,30))
            $dataTbl.Rows.Add($r)
            $v = $(Convert-QueryToCsv $r -MapFields @{ key = "ID"; col1 = "Map1:|trim|"; col2 = "Map2:|MM-dd-yy|"}).ToString()
            $v | Should -Be "ID,Map1,Map2`r`n3,Itm3,06-30-20"
        }
        IT "Convert with MapFields produces the expected results" {
            $s = Convert-QueryToCsv $(Get-SqlTraceData 0) -MapFields @{ key = "MapKey:|c2|"; col1 = "Name"; col2 = "JobTime:|yyyyMMdd|"}
            $s.Substring(0, 44) | Should -Be "MapKey,Name,JobTime`r`n`$0.00,Item 1,20011231`r`n"
        }

        It "Trace log should be cleared" {
            Clear-SqlTraceLog
            $(Get-SqlTrace).Count | Should -Be 0            
        }
    }
}