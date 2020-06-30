
Function Write-Log {
    <#
        .SYNOPSIS
        Short description

        .DESCRIPTION
        Long description

        .PARAMETER Level
        Parameter "INFO","WARN","ERROR","FATAL","DEBUG"

        .PARAMETER Message
        Parameter error message

        .PARAMETER logfile
        Parameter logfile path

        .EXAMPLE
        Write-Log -Level 'ERROR' -Message 'This is an error' -logfile '.\log.txt'

        .NOTES
        General notes
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [ValidateSet("INFO", "WARN", "ERROR", "FATAL", "DEBUG")]
        [String]
        $Level = "INFO",

        [Parameter(Mandatory = $True)]
        [string]
        $Message,

        [Parameter(Mandatory = $False)]
        [string]
        $logfile
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $Line = "$Stamp $Level $Message"
    If ($logfile) {
        Add-Content $logfile -Value $Line
    }
    Else {
        Write-Output $Line
    }
}