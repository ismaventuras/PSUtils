[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $toFind
)
Get-Content (Get-PSReadlineOption).HistorySavePath | Select-String -Pattern $toFind