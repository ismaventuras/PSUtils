#
# Dear maintainer:
#	Only God and I knew what I was doing here to make this work, now only God knows.
#	If you thought that to improve this code was a good idea, please, increase the total counter when you realize that it wasn't a good idea at all
#	Times this file has been opened = 1
#	

<#
	Helpers
#>
function Test-Administrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}
<#
	Args
#>

param(
	[parameter(Mandatory=$true)]
	$report,
	$computerList
)

<#
	Functions
#>

function Get-Snow-Computer{
param(	[parameter(Mandatory=$true)][string]$computername	)
	Get-ServiceNowTableEntry -Table u_cmdb_ci_workstation -MatchExact @{name=$($computername)} -ErrorAction SilentlyContinue

}

function Update-Snow-Computer-Assigment{
param(	[parameter(Mandatory=$true)][string]$computername	)
	Update-ServiceNowTableEntry -Table u_cmdb_ci_workstation -Values @{assigned_to=$object.AD} -sysId (Get-Snow-Computer -computername $computername).sys_id
}

function Update-AD-Computer{

}

function Connect-ToSNOW{
	if(-not (Get-Module -ListAvailable -Name ServiceNow)) {
		Install-Module ServiceNow -Credential (Get-Credential -Message "Use an account with administrator privileges")
	} #If module is not installed, install it
	#import the module
	Import-Module ServiceNow 
	#Check for credentials and connect to SNOW 
	$credPath = "$($env:temp)\creds.xml"
	# check for stored credential
	if ( Test-Path $credPath ) {
    #crendetial is stored, load it 
	$cred = Import-CliXml -Path $credPath
	#authenticate to snow
	Set-ServiceNowAuth -url bunge.service-now.com -Credentials $cred 
	} else {
    # no stored credential: create store, get credential and save it
	$parent = split-path $credpath -parent
	#If 
    if ( -not (test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent
    }
    $cred = get-credential -Message "Please use an account able to login into SNOW"
    $cred | Export-CliXml -Path $credPath
	Set-ServiceNowAuth -url bunge.service-now.com -Credentials $cred #authenticate to snow
}
}
<# 
	Modules Variables and login
#>
if(-not (Get-Module -ListAvailable -Name ServiceNow)) {Install-Module ServiceNow -Credential (Get-Credential -Message "Use an account with administrator privileges")} #If module is not installed, install it
Import-Module ServiceNow #import the module
Import-Module ActiveDirectory
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 #Authenticate over TLS 

Connect-ToSNOW
$APPaccount = (Get-Credential -Message "Use an account with Active Directory privileges")
<# 
	Main 
#>

$objectList = Import-Csv $report -delimiter ";"

foreach($object in $objectList){
	#Find in AD
	#$foundComputer=Get-ADComputer $object.name -properties description
	#Find in a List
	$foundComputer= $computerList | where {$_.name -eq $object.computer}
	# If found AND DESCRIPTION IS NOT NULL
	if(($foundComputer) -and ($foundComputer.description -ne '')){ 
		#format description
		$pos=$foundComputer.description.IndexOf(" -")
		$assignedAD = $foundComputer.description.Substring(0,$pos)
		$rightPart =" "+ $foundComputer.description.Substring($pos+1)
		# If object has assigment conflict
		if(($object.ConflictAssigment -ne '-') -and ($object.AD -ne 'In Stock') ){ 
			#Update Snow
			if(($object.SNOW -ne $object.AD) -and ($object.AD -ne "Shared DEVICE") ){
				Write-Host 'Object.AD:' $object.AD
				Update-ServiceNowTableEntry -Table u_cmdb_ci_workstation -Values @{assigned_to=$object.AD} -sysId (Get-Snow-Computer -computername $object.Computer).sys_id | out-null
			}
			else ##Update AD if SNOW was ok
			{
				#UpdateAD
				$Description = $object.Snow + $rightPart
				#Set-ADComputer -Identity $foundComputer -Description $description -Credential $APPaccount
				Write-Host 'Should be updating AD for' + $Description 
			}
		}
		#If shared device and checkbox is false
		if(($object.ConflictCheckbox -ne '-') -and ($assignedAD -eq "Shared DEVICE")){ 
			#Update Snow
			Update-ServiceNowTableEntry -Table u_cmdb_ci_workstation -Values @{u_shared_device=$object.CheckBox_SharedDevice} -sysId (Get-Snow-Computer -computername $object.Computer).sys_id | out-null
		}
		#If computer is not In Use
		if($object.ConflictStatus -ne '-'){
			Update-ServiceNowTableEntry -Table u_cmdb_ci_workstation -Values @{hardware_status=$object.Status} -sysId (Get-Snow-Computer -computername $object.Computer).sys_id | out-null
		}
		
	}

}