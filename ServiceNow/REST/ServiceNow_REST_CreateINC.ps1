# System constants
Set-Variable LOG_FILE -Value '.\logs.txt'
# SNOW GLOBALS
Set-Variable SNOW_INSTANCE -Option Constant -Value 'https://bunge.service-now.com/'
Set-Variable SNOW_CREDENTIALS_FILE -Value '.\SNOWCredentials.xml'

<#
        INCIDENT SETTINGS
#>

# Funcion maestra para llamar al script, el resto de funciones y el script en si ir'a en esta funci'on
function Main {
    $computerList = 'BRC-S4CDGE3','BRC-S4AY7017'
    foreach($computer in $computerList){
        $data = FetchData -caller_id 'Ismael Bautista' -cmdb_ci $computer -short_description ('GranToPetit - Replace {0}' -f $computer) -description ('Replace the big desktop computer with name {0} with a tiny desktop.' -f $computer )
        $data
    }

}


# Functions
function FetchData {
    param (
        [Parameter()]
        [string] $table = 'incident',
        [Parameter(Mandatory=$true)]
        [string] $caller_id,
        [Parameter(Mandatory=$true)]
        [string] $short_description,
        [Parameter(Mandatory=$true)]
        [string] $description,
        [Parameter(Mandatory=$true)]
        [string] $cmdb_ci
        
    )

    # Pedir al usuario las credenciales de SNOW o importarlas del archivo, luego generar las cabeceras HTTP
    $header, $type , $SNOWusername = CreateCredential
    # API URL desde donde descargamos la informacion de SNOW
    $API_URL = "{0}api/now/table/{1}" -f $SNOW_INSTANCE, $table
    $Body = @{
        caller_id            = $caller_id
        priority             = '3'
        u_business_service   = 'Computer'
        short_description    = $short_description
        cmdb_ci              = $cmdb_ci
        u_service_desk_group = 'SD-SPAIN'
        assigment_group      = 'SD-SPAIN'
        description = $description
        category = 'service'
    }
    Write-Log -Message ('Trying to query {0}' -f $API_URL)
    Try {
        $dataJSON = Invoke-RestMethod -Method POST -Uri $API_URL -Body ($Body | ConvertTo-Json) -TimeoutSec 100 -Headers $header -ContentType $type
        $dataJSON.result
       
    }
    Catch {
        # Si el usuario o el password son incorrectos, devuelve un mensaje de no autorizado
        if ($_.Exception.Response.StatusCode.Value__ -eq 401) {
            Write-Host $_.Exception.Message.ToString() -ForeGroundColor Black -BackgroundColor Red
            Write-Log -Level 'INFO' -Message $_.Exception.Message.ToString()
            RemoveCredential
        }
        # Si es otro error, devuelve el mensaje
        else {
            Write-Host $_.Exception.Message.ToString()
            Write-Log -Level 'ERROR' -Message $_.Exception.Message.ToString() 
        }
    }
}
function SetHeaders {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SNOWUsername,
        [Parameter(Mandatory = $true)]        
        [string] $SNOWPassword
    )
    $HeaderAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $SNOWUsername, $SNOWPassword)))
    $SNOWSessionHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $SNOWSessionHeader.Add('Authorization', ('Basic {0}' -f $HeaderAuth))
    $SNOWSessionHeader.Add('Accept', 'application/json')
    $Type = "application/json"
    return $SNOWSessionHeader , $Type , $SNOWUsername
}

function CreateCredential {
    # Testing if file exists
    $SNOW_CREDENTIALS_FILETest = Test-Path $SNOW_CREDENTIALS_FILE
    # IF doesn't exist, prompting and saving credentials
    IF ($SNOW_CREDENTIALS_FILETest -eq $False) {
        $SNOWCredentials = Get-Credential -Message "Enter SNOW login credentials"
        $SNOWCredentials | EXPORT-CLIXML $SNOW_CREDENTIALS_FILE -Force
    }
    # Importing credentials
    $SNOWCredentials = IMPORT-CLIXML $SNOW_CREDENTIALS_FILE
    # Setting the username and password from the credential file (run at the start of each script)
    SetHeaders -SNOWUsername $SNOWCredentials.UserName -SNOWPassword $SNOWCredentials.GetNetworkCredential().Password
}
function RemoveCredential {
    if (Test-Path $SNOW_CREDENTIALS_FILE) {
        Remove-Item $SNOW_CREDENTIALS_FILE
        Write-Host 'Credential removed.' -ForeGroundColor White -BackgroundColor Black
    }
    else {
        Write-Host 'No credential remove.' -ForeGroundColor White -BackgroundColor Black
    }
}


Function Write-Log {
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
        $logfile = $LOG_FILE
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

#Call Main program
Main