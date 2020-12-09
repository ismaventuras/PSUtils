function Get-WindowsVersion {
    param (
        [Parameter(
            ValueFromPipeLine=$True
        )]
        [string[]]$computerList = 'localhost'
    )
    $objectCollection=@()

    foreach($computer in $computerList){
        <# Other Ways to get the info
            #$OSBuild = (Get-WmiObject -class Win32_OperatingSystem | select -expand buildnumber)
            #$OSBuildByRegistry = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId
            #$OSInstallTime = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name InstallTime).InstallTime
            #$OSBuildByRegistryAndInvokeCommand = Invoke-command -computer $computer {(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId}
        #>
        try {
            $OSVersion = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer).OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue("ReleaseID")
            $Object = New-Object psobject -Property @{
                ComputerName = $computer
                OSVersion = $OSVersion
            }
            $objectCollection += $Object
        }
        catch{}
    Clear-Variable -Name "OSVersion"
    }
    return $objectCollection    
  
}