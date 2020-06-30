#
# Dear maintainer:
#	Only God and I knew what I was doing here to make this work, now only God knows.
#	If you thought that to improve this code was a good idea, please, increase the total counter when you realize that it wasn't a good idea at all
#	Total hours wasted = 6
#	

Write-Host 'Wait while filling the AD list...'
$computerList = (get-adcomputer -f * -SearchBase "OU=ES,DC=eu,DC=dir,DC=bunge,DC=com" -properties * | select name,description)

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


<# 
	Variables and login
#>
if(-not (Get-Module -ListAvailable -Name ServiceNow)) {Install-Module ServiceNow -Credential (Get-Credential -Message "Use an account with administrator privileges")} #If module is not installed, install it
Import-Module ServiceNow #import the module
#Authenticate over TLS 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
Set-ServiceNowAuth -url bunge.service-now.com -Credentials (Get-Credential -Message "Please use an account able to login into SNOW") #authenticate to snow
#$APPaccount = (Get-Credential -Message "Use an account with Active Directory privileges")

<# 
	Main 
#>

foreach($computer in $ComputerList)
{
	$assigned_SNOW=Get-SnowAssignedTo -computername $computer.name
	$isSharedDevice=Get-SNOW-IsComputerSharedDevice -computername $computer.name
	if($computer.description){$assigned_AD=$computer.description.SubsTring(0,$computer.description.IndexOf("-")).trim()}
	
	if($assigned_SNOW -eq $assigned_AD)	{Write-Host 'Computer ' $computer.name 'is assigned to' $assigned_SNOW 'in SNOW and AD'} # Check if assigned to name in SNOW and AD are the same
	else # If not, then conflicts
	{	
		if(($isSharedDevice -eq 'false') -and ($assigned_AD -like 'Shared DEVICE')){ ## Check if computer IS NOT a shared device
				if(($isSharedDevice -eq 'true') -and ($assigned_AD -like 'Shared DEVICE')){
				Write-Host 'Computer ' $computer.name 'is a SHARED DEVICE and is assigned in AD to '$assigned_ad' and is marked as shared device in SNOW'} #Si es un shared device, imprimeix
				else{
				$conflictString = -join('CONFLICT: Computer ',$computer.name,' is a Shared Device in AD and is not assigned as Shared Device(checkbox not marked) in SNOW but is assigned to ',$assigned_SNOW,' in SNOW' )
				Add-Content -Path C:\temp\conflictReport.txt -Value $conflictString -PassThru
				}
			}
		if(($isSharedDevice -eq 'true') -and ($assigned_AD -like 'Shared DEVICE')){	Write-Host 'Computer ' $computer.name 'is a SHARED DEVICE and is assigned in AD to '$assigned_ad' and is marked as shared device in SNOW'}
		else{
			$conflictString = -join('CONFLICT: Computer ',$computer.name,' is assigned to ', $assigned_AD,' in AD and assigned to ',$assigned_SNOW,' in SNOW' )
			Add-Content -Path C:\temp\conflictReport.txt -Value $conflictString -PassThru
		}
	}
	
}