## Tratar strings
```powershell
#Reemplazo
$name = 'paco'
Write-Host ("Hola {0}" -f  $name)
```
###

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

## Sacar todos los metodos de un objeto
```powershell
$var | Get-Member
```


## Crear una clase
```powershell
class Computer {
    [string]$name
    [string]$serial_number

    #Constructor
    Computer([string]$name,[string]$serial_number,) {
        $this.name = $name
        $this.serial_number = $serial_number
    }
}
```

## Comprobar si una ip tiene un puerto abierto
```powershell
Test-NetConnection -ComputerName x.x.x.x -port y
```
