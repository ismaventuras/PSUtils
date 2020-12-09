function Get-BIOSInfo {
    param (
        $computername = 'localhost'
    )
    Get-WmiObject -Class Win32_BIOS -ComputerName $computername
}