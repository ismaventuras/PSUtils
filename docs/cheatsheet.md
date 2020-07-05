Create a class
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

Navigate registry

```powershell
#Entrar al registro
Set-Location -Path Registry::HKEY_CURRENT_USER\
Set-Location -Path Registry::HKEY_LOCAL_MACHINE\
#Obtener claves que cuelgan de una clave
Get-Item .\
#Obtener registros de una clave
Get-ItemProperty .\
```