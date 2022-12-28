param(
    [version]$Version = "1.0.0"
)
#Requires -Module ModuleBuilder

$params = @{
    SourcePath = "$PSScriptRoot\Source\SDSqlQuery.psd1"
    CopyPaths = @("$PSScriptRoot\README.md","$PSScriptRoot\LICENSE")
    Version = $Version
    UnversionedOutputDirectory = $true
}
Build-Module @params