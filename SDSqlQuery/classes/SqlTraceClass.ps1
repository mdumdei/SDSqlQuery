# Class for containing trace data on queries performed by Invoke-SqlQuery

Class SqlTrace { $Idx; $Srv; $DB; $Cmd; $Parms;  $Data
    static [System.Collections.Generic.List[SqlTrace]]$SqlTraceLog = $(New-Object System.Collections.Generic.List[SqlTrace])
    static [bool]$Enabled = $false
    static [int]$Count = 0
    SqlTrace($srv, $db, $c, $p) { 
        if ([SqlTrace]::Enabled) {
            $this.Idx = [SqlTrace]::SqlTraceLog.Count; $this.Data = $null;
            $this.Srv = $srv; $this.DB = $db; $this.Cmd = $c; $this.Parms = $p; 
            [SqlTrace]::SqlTraceLog.Add($this)
            [SqlTrace]::Count++
        } 
    } 
}
