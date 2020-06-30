#
# Dear maintainer:
#	Only God and I knew what I was doing here to make this work, now only God knows.
#	If you thought that to improve this code was a good idea, please, increase the total counter when you realize that it wasn't a good idea at all
#	Times this file has been opened = 13
#	


<#
	Args
#>

param(
	[parameter(Mandatory=$true)]
	$ComputerList
)


<#
	Functions
#>
function Get-SNOWAssignedTo{
param(
	[parameter(Mandatory=$true)][string]$computername
	)
((Get-ServiceNowTableEntry -Table u_cmdb_ci_workstation -MatchExact @{name=$($computername)} -ErrorAction SilentlyContinue).assigned_to).display_value
}

function Get-SNOW-IsComputerSharedDevice{
param(
	[parameter(Mandatory=$true)][string]$computername
	)
	(Get-ServiceNowTableEntry -Table u_cmdb_ci_workstation -MatchExact @{name=$($computername)} -ErrorAction SilentlyContinue).u_shared_device
}

function Get-SNOW-Computer-Status{
param(
	[parameter(Mandatory=$true)][string]$computername
	)
	(Get-ServiceNowTableEntry -Table u_cmdb_ci_workstation -MatchExact @{name=$($computername)} -ErrorAction SilentlyContinue).hardware_status
}

function Get-Snow-Computer{
param(
	[parameter(Mandatory=$true)][string]$computername
	)
	Get-ServiceNowTableEntry -Table u_cmdb_ci_workstation -MatchExact @{name=$($computername)} -ErrorAction SilentlyContinue

}


<# 
	Modules
#>
if(-not (Get-Module -ListAvailable -Name ServiceNow)) {Install-Module ServiceNow -Credential (Get-Credential -Message "Use an account with administrator privileges")} #If module is not installed, install it
Import-Module ServiceNow #import the module
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 #Authenticate over TLS 

<# 
	Variables and login
#>
#Check for credentials and connect to SNOW 
$credPath = "C:\Temp\creds.xml"
# check for stored credential
if ( Test-Path $credPath ) {
    #crendetial is stored, load it 
    $cred = Import-CliXml -Path $credPath
	Set-ServiceNowAuth -url bunge.service-now.com -Credentials $cred #authenticate to snow
} else {
    # no stored credential: create store, get credential and save it
    $parent = split-path $credpath -parent
    if ( -not (test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent
    }
    $cred = get-credential -Message "Please use an account able to login into SNOW"
    $cred | Export-CliXml -Path $credPath
	Set-ServiceNowAuth -url bunge.service-now.com -Credentials $cred #authenticate to snow
}


#$APPaccount = (Get-Credential -Message "Use an account with Active Directory privileges")

<# 
	Main 
#>

	$objects = @()
foreach($computer in $ComputerList){
	$computer_SNOW= Get-Snow-Computer -computername $computer.name
	$assigned_SNOW = ($computer_Snow.assigned_to).display_value
	$isSharedDevice = $computer_Snow.u_shared_device
	$computerStatus_SNOW = $computer_Snow.hardware_status
	if($computer.description.contains("-")) {$assigned_AD=$computer.description.SubsTring(0,$computer.description.IndexOf("-")).trim()}
	else {$assigned_AD=$computer.description}
	$validateObject=0
	$object = New-Object System.Object
	$object | add-member -memberType NoteProperty -Name Computer -Value $computer.name
	$object | add-member -memberType NoteProperty -Name AD -Value $assigned_AD
	$object | add-member -memberType NoteProperty -Name SNOW -Value $assigned_SNOW
	$object | add-member -memberType NoteProperty -Name CheckBox_SharedDevice -Value $isSharedDevice
	$object | add-member -memberType NoteProperty -Name Status -Value $computerStatus_SNOW
	$object | add-member -memberType NoteProperty -Name ConflictStatus -Value '-'
	$object | add-member -memberType NoteProperty -Name ConflictCheckbox -Value '-'
	$object | add-member -memberType NoteProperty -Name ConflictAssigment -Value '-'
	if($assigned_AD -eq $assigned_SNOW){
		if(($computerStatus_SNOW -ne 'In Use') -and ($assigned_AD -ne 'In Stock'))
		{
			$object.ConflictStatus = 'Computer is not set In Use in SNOW'
			$validateObject=1
		}
	}
	if(($assigned_AD -ne $assigned_SNOW) -and ($assigned_AD -ne 'Shared DEVICE'))
	{
		$object.ConflictAssigment = 'Computer assigment missmatching'
		if($computerStatus_SNOW -ne 'In Use'){
			$object.ConflictStatus = 'Computer is not set In Use in SNOW'
			$validateObject=1
		}		
	}
	if($assigned_AD -eq 'Shared DEVICE'){
		if($isSharedDevice -eq 'False')
		{
			$object.ConflictCheckbox ='Shared Device checkbox in snow is false'
			$validateObject=1
		}
		if($computerStatus_SNOW -ne 'In Use')
		{
			$object.ConflictStatus = 'Computer is not set In Use in SNOW'
			$validateObject=1
		}
		
	}
	if($validateObject -eq 1){
	$object
	$objects +=$object
	}
	Clear-Variable object
	Clear-Variable validateObject
	Clear-Variable assigned_AD
	Clear-Variable assigned_SNOW
	Clear-Variable isSharedDevice
}
	#export to CSV
	$filename='C:\Temp\report'+$((get-date).tostring("ddMMyyyyHHmmss"))+'.csv'
	New-Item $filename | out-null
	$objects |export-csv -delimiter ';' -path $filename -notypeinformation

