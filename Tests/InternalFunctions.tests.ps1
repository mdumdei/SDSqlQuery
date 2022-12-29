InModuleScope -ModuleName SDSqlQuery -ScriptBlock {
    BeforeAll {
        $dataTbl = New-Object System.Data.DataTable
        $dataTbl.Columns.Add("col1", "string")
        $dataTbl.Columns.Add("col2", "string")
        $dataTbl.Columns.Add("col3", "int")
        $r = $dataTbl.NewRow()
        $r.col1 = "Item 1";  $r.col2 = "Data 1"; $r.col3 = 100
        $dataTbl.Rows.Add($r)

        $dataTbl2 = New-Object System.Data.DataTable
        $dataTbl2.Columns.Add("col1", "string")
        for ($i = 1; $i -lt 5; ++$i) {
            $r = $dataTbl2.NewRow()
            $r.col1 = "Item $i";  
            $dataTbl2.Rows.Add($r)            
        }

        $dataTbl3 = New-Object System.Data.DataTable
        for ($i = 1; $i -le 20; ++$i) {
            $dataTbl3.Columns.Add("col$i", "int");
        }
        $r = $dataTbl3.NewRow()        
        for ($i = 0; $i -lt 20; ++$i) {
            $r[$i] = $i + 101;  
         }
         $dataTbl3.Rows.Add($r)            
    }   

    Describe "Internal Functions Test" {
        It "DataTableSummary works as expected" {
            $v = GetDataTableSummary $dataTbl
            $v | Should -Be "[r=1,c=3] { [Item 1, Data 1, 100] }"
            for ($i = 2; $i -le 10; ++$i) {
                $r = $dataTbl.NewRow()
                $r.col1 = "Itm$i";  $r.col2 = "Data $i"; $r.col3 = $i * 100
                $dataTbl.Rows.Add($r)                   
            }
            $v = GetDataTableSummary $dataTbl
            $v | Should -Be "[r=10,c=3] { [Item 1,.], [Itm2,.], [Itm3,.], [Itm4,.], [Itm5,.], [Itm6,.], ... }"
            $v = GetDataTableSummary $dataTbl2
            $v | Should -Be "[r=4,c=1] { [Item 1], [Item 2], [Item 3], [Item 4] }"
            for ($i = 5; $i -lt 20; ++$i) {
                $r = $dataTbl2.NewRow()
                $r.col1 = "Item $i";  
                $dataTbl2.Rows.Add($r)  
            }
            $v = GetDataTableSummary $dataTbl2
            $v | Should -Be "[r=19,c=1] { [Item 1], [Item 2], [Item 3], [Item 4], [Item 5], [Item 6], ... }"
            $v = GetDataTableSummary $dataTbl3
            $v | Should -Be "[r=1,c=20] { [101, 102, 103, 104, 105, 106, 107, 108, 109, 110,...] }"
        }
        It "CSVSafe works as expected" {
            $s = " String with leading/trailing spaces  "
            $v = CsvSafe $s
            $v | Should -Be "`"$s`""
            $v = $(CsvSafe $s 'T')
            $v | Should -Be "`"$($s.TrimEnd())`""  
            $v = CsvSafe $s.Trim()
            $v | Should -Be "$($s.Trim())"
            $s = "String `"with`" quotes"
            $v = CsvSafe $s
            $v | Should -Be "`"String `"`"with`"`" quotes`""
            $s = "String, Comma"
            $v = CsvSafe $s
            $v | Should -Be "`"$s`""
        }
        It "MapColumns works as expected" {
            $cols = @("Col1","Col2","Col3","Col4")
            $map = @{ col1 = "Map1"; col2 = "Map2:|trim|"; col3="Map3:|yyyyMMdd|"; col99 = "Map99"}
            $v = MapColumns $cols $map
            $vc = $v["Map"]
            $vf = $v["Fmts"]
            $vc[0] | Should -Be "Map1"
            $vf[0] | Should -Be $null
            $vc[1] | Should -Be "Map2"
            $vf[1] | Should -Be 'T'
            $vc[2] | Should -Be "Map3"
            $vf[2] | Should -Be "yyyyMMdd"
            $vc[3] | Should -Be "Col4"
            $vf[3] | Should -Be $null
        }
        It "ConvertDataRowToCsv works as expected" {
            [string[]]$mapFmts = $null
            $r = $dataTbl.NewRow()
            $r.col1 = "Item x";  $r.col2 = "Data x"; $r.col3 = 999
            $dataTbl.Rows.Add($r)
            $v = $(ConvertDataRowToCsv $r $null ([ref]$mapFmts) 0).ToString()
            $v | Should -Be "col1,col2,col3`r`nItem x,Data x,999"
            $v = $(ConvertDataRowToCsv $r $null ([ref]$mapFmts) 1).ToString()
            $v | Should -Be "Item x,Data x,999"
            $v = $(ConvertDataRowToCsv $r @{col1 = "Map1"; col3 = "Map3:|c2|"} ([ref]$mapFmts) 0).ToString()
            $v | Should -Be "Map1,col2,Map3`r`nItem x,Data x,`$999.00"
        }
    }
}