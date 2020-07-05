## Tratar strings
```powershell

```


## Utilizar el registro de Windows
```powershell
#Entrar al registro
Set-Location -Path Registry::HKEY_CURRENT_USER\
Set-Location -Path Registry::HKEY_LOCAL_MACHINE\
#Obtener claves que cuelgan de una clave
Get-Item -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion
#Obtener entradas de una clave
Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion
#Obtener una entrada  concreto de una clave
Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion -Name DevicePath
#Añadir una entrada
Set-ItemProperty -Path HKCU:\Environment -Name Path -Value $newpath
#Añadir una clave
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion -Name PowerShellPath -PropertyType String -Value $PSHome
#Renombrar una entrada
Rename-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion -Name PowerShellPath -NewName PSHome -passthru
#Eliminar una entrada
Remove-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion -Name PSHome
```

## Crear una clase
```powershell
class Computer {
    [string]$snow_name
    [string]$snow_serial_number
    [string]$snow_assigned_to
    [string]$snow_hardware_status
    [string]$snow_u_shared_device

    #Constructor
    Computer(
        [string]$snow_name,
        [string]$snow_serial_number,
        [string]$snow_assigned_to,
        [string]$snow_hardware_status,
        [string]$snow_u_shared_device,
    ) {
        $this.snow_name = $snow_name
        $this.snow_serial_number = $snow_serial_number
        $this.snow_assigned_to = $snow_assigned_to
        $this.snow_hardware_status = $snow_hardware_status
        $this.snow_u_shared_device = $snow_u_shared_device


}
```
