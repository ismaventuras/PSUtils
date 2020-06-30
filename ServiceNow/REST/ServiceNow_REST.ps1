# System constants
Set-Variable LOG_FILE -Value '.\logs.txt'
# SNOW GLOBALS
Set-Variable SNOW_INSTANCE -Option Constant -Value 'https://bunge.service-now.com/'
Set-Variable SNOW_CREDENTIALS_FILE -Value '.\SNOWCredentials.xml'
Set-Variable SNOW_COMPUTERS_FILE -Value '.\SNOW_computers.xml'
Set-Variable SD_SPAIN -Option Constant -Value '9aaed21a41a13000cb006c211ca6ef1e'


<#
    $hashtable = @{
        Serialnumber
        SNOW_name
        AD_name
        AD_assigned_to
        Assigned_to = {
            value
            name
        }
    }
#>



# Funcion maestra para llamar al script, el resto de funciones y el script en si ir'a en esta funci'on
function Main {
    #FetchComputerList_ServiceNOW
    FetchUserList_ActiveDirectory
    CompareData
    $snowdata = FetchComputerList_ServiceNOW
    $table = Replace_AssignedTo_SNOW -Computer_List $snowdata
    $table
    #$data = SNOW-FindUserBySysID -sys_id '06ff901f4f578600fc02cda28110c7a8' 
    #$data
}

function CompareData {

}

function CreateSnowUserHashTable{
    
}
function Replace_AssignedTo_SNOW{
    param(
        [Parameter(Mandatory=$true)]
        [object] $Computer_List
    )
    $Computer_hashtable = @()
    foreach ($computer in $Computer_List) {
        if($computer.assigned_to){
        $user = FindUserBySysID_SNOW -sys_id $computer.assigned_to.value
        $name = $user | select name
        $Computer_hashtable +=
           @{
                serial_number =  $computer.serial_number
                SNOW_name = @{ 
                    sys_id = $computer.assigned_to.value
                    name = $name
                } 
                isSharedDevice = $computer.u_shared_device
            }    
        }
        }
        $Computer_hashtable
}
function FindUserBySysID_SNOW{
    param(
        [Parameter()]
        [string] $sys_id
    )
    $displayname = FetchData -table 'sys_user' -query ('sys_id={0}' -f $sys_id)
    $displayname | select name,sys_id
}
function FetchComputerList_ServiceNOW {
    Write-Host "================ Fetching ServiceNow Data ================" -BackgroundColor Blue -ForeGroundColor White             
    ## Get computer Data from SNOW
    if((Test-Path -Path '.\SNOW_computers.xml') -eq $false){
        #$table = Read-Host "Table name (u_cmdb_ci_workstation for computers):"
        #$query = Read-Host "Query:"
        $query = 'support_group={0}' -f $SD_SPAIN
        $data = FetchData -query $query
        $data | select name , assigned_to , u_shared_device , serial_number , u_ad_source | Export-Clixml -Path $SNOW_COMPUTERS_FILE
    }
    $SNOW_Computers_Data = Import-Clixml -Path $SNOW_COMPUTERS_FILE
    $SNOW_Computers_Data

}

function FetchUserList_ActiveDirectory {
    
}
# Functions
function FetchData {
    param (
        [Parameter()]
        [string] $table = 'u_cmdb_ci_workstation',
        [Parameter(Mandatory=$true)]        
        [string] $query
    )

   # Pedir al usuario las credenciales de SNOW o importarlas del archivo, luego generar las cabeceras HTTP
   $header, $type = CreateCredential
   # API URL desde donde descargamos la informacion de SNOW
   $API_URL = "{0}api/now/table/{1}?sysparm_query={2}" -f $SNOW_INSTANCE, $table , $query

   Write-Log -Message ('Trying to query {0}' -f $API_URL)
   Try {
       $dataJSON = Invoke-RestMethod -Method GET -Uri $API_URL -TimeoutSec 100 -Headers $header -ContentType $type
       $dataJSON.result
       
   }
   Catch {
       # Si el usuario o el password son incorrectos, devuelve un mensaje de no autorizado
       if($_.Exception.Response.StatusCode.Value__ -eq 401){
           Write-Host $_.Exception.Message.ToString() -ForeGroundColor Black -BackgroundColor Red
           Write-Log -Level 'INFO' -Message $_.Exception.Message.ToString()
           RemoveCredential
       }
       # Si es otro error, devuelve el mensaje
       else{
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
    return $SNOWSessionHeader , $Type
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
    if(Test-Path $SNOW_CREDENTIALS_FILE){
        Remove-Item $SNOW_CREDENTIALS_FILE
        Write-Host 'Credential removed.' -ForeGroundColor White -BackgroundColor Black
    }
    else
    {
        Write-Host 'No credential remove.' -ForeGroundColor White -BackgroundColor Black
    }
}
function RemoveSNOWComputersFile {
    if(Test-Path $SNOW_COMPUTERS_FILE){
        Remove-Item $SNOW_COMPUTERS_FILE
        Write-Host 'Removed list of SNOW computers.' -ForeGroundColor White -BackgroundColor Black
    }
    else
    {
        Write-Host 'No list to remove' -ForeGroundColor White -BackgroundColor Black
    }
}

function Show-Menu{
    #  param (
    #        [string]$Title = 'My Menu'
    #  )
     cls
     Write-Host "================ ServiceNow Active Directory Inventory ================" -BackgroundColor Blue -ForeGroundColor White
    
     Write-Host "1: Fetch data."
     Write-Host "2: Remove credentials."
     Write-Host "Q: Press 'Q' to quit."
}

Function Write-Log {
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False)]
    [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG")]
    [String]
    $Level = "INFO",

    [Parameter(Mandatory=$True)]
    [string]
    $Message,

    [Parameter(Mandatory=$False)]
    [string]
    $logfile = $LOG_FILE
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $Line = "$Stamp $Level $Message"
    If($logfile) {
        Add-Content $logfile -Value $Line
    }
    Else {
        Write-Output $Line
    }
}

#Call Main program
Main