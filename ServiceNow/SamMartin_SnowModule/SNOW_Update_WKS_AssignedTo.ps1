<#
	Args
#>

param(
	[parameter(Mandatory=$true)][string[]]$ComputerList
)

<#
 Functions
#>

function Get-SNOWAssignedTo{
param(
	[parameter(Mandatory=$true)][string]$computername
	)
((Get-ServiceNowTableEntry -Table u_cmdb_ci_workstation -MatchExact @{name=$($computername)}).assigned_to).display_value
}

function Get-SNOWUserList{
#Get all users
$params =  @{source='OU=ES,DC=eu,DC=dir,DC=bunge,DC=com'}
$users = Get-ServiceNowUser -MatchContains $params -Limit 1000
$users | ?{ $_.email -NotLike "*__Terminated" -and $_.email -notlike "" -and $_.active -notlike 'false'}
}
function CreateObject {
	param(
	[parameter(Mandatory=$true)][string]$computername,
	[parameter(Mandatory=$true)][string]$user,
	[parameter(Mandatory=$true)][string]$model
	)
	return [PsCustomObject]@{
		computerName = $computername
		user = $user
		model = $model
		description = ($user + ' - ' + $model)
	}
}


function Get-SNOWComputer-SysID{
	param([string]$computername)
	(Get-ServiceNowTableEntry -Table u_cmdb_ci_workstation -MatchExact @{name=$($computer)} -ErrorAction SilentlyContinue).sys_id 
	
}

function Update-SNOWComputer{
	param(
	[Parameter(Position=0,mandatory=$true)]
	[string] $sysID,
	[Parameter(Position=1,mandatory=$true)]
	[string] $user	)
	
	Update-ServiceNowTableEntry -Table u_cmdb_ci_workstation -Values @{assigned_to=$user} -sysId $sysID | out-null
		if($?){ Write-Host 'Computer ' $computer ' has been assigned to ' $user ' in ServiceNow'}
	
}

<# 
	Variables and login
#>
if(-not (Get-Module -ListAvailable -Name ServiceNow)) {Install-Module ServiceNow -Credential (Get-Credential -Message "Use an account with administrator privileges")} #If module is not installed, install it
Import-Module ServiceNow #import the module
Set-ServiceNowAuth -url bunge.service-now.com -Credentials (Get-Credential) #authenticate to snow
$APPaccount = (Get-Credential -Message "Use an account with Active Directory privileges")

<# 
	Main 
#>
#Iteration over computer list
foreach($computer in $ComputerList)
{
	#ServiceNow
	$sysID=Get-SNOWComputer-SysID -computername $computer #Get the computer id of the computer
	if($sysID){Update-SNOWComputer -sysID $sysID -user $user } #if exists, update the assigned_to
	else { Write-Host 'Error updating ' $computer ' in ServiceNow'}#if not, write error
	#Active Directory
	#Set-ADComputer -Identity $computer -Description $description
	#	if($?){ Write-Host 'Computer ' $computer ' description updated to: ' $description ' in AciteDirectory'}
	
}
