<#
    Global variables
#>
Set-Variable workstation_table -Option Constant -Value 'u_cmdb_ci_workstation'
Set-Variable ServiceNow_URL -Option Constant -Value 'instance.service-now.com'
#Authenticate over TLS 
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
<# 
    Functions 
#>

<#
    .SYNOPSIS
    Connects via REST API to ServiceNow 
    .DESCRIPTION
    
    .INPUTS
    None.
    .OUTPUTS
    Boolean
    .EXAMPLE
    Connect-ToSNOW

#>
function Connect-ToSNOW{
    #If servicenow powershell module is not installed, install it
    if(-not (Get-Module -ListAvailable -Name ServiceNow)) {
		Install-Module ServiceNow #-Credential (Get-Credential -Message "Use an account with administrator privileges")
    } 
	#import the module
	Import-Module ServiceNow 
	#Check for credentials and connect to SNOW 
	$credPath = "$($env:temp)\creds.xml"
	# check for stored credential
	if ( Test-Path $credPath ) {
    #crendetial is stored, load it 
	$cred = Import-CliXml -Path $credPath
	#authenticate to snow
	Set-ServiceNowAuth -url $ServiceNow_URL -Credentials $cred 
	} else {
    # no stored credential: create, store, get credential and save it
	$parent = split-path $credpath -parent
    if ( -not (test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent
    }
    $cred = get-credential -Message "Please use an account able to login into SNOW"
    $cred | Export-CliXml -Path $credPath
	Set-ServiceNowAuth -url $ServiceNow_URL -Credentials $cred #authenticate to snow
}
}
<#
    .SYNOPSIS
    Get a workstation from ServiceNow workstation table 
    .DESCRIPTION

    .PARAMETER ComputerName
    Specifies the workstation Name attribute.
    .INPUTS
    None.
    .OUTPUTS
    A ServiceNowTableEntry object containing
    .EXAMPLE
    Get-Snow-Computer "Workstation-NINJA"
    .EXAMPLE
    Get-Snow-Computer $computer
#>
function Get-Snow-Computer{
    param(	[parameter(Mandatory=$true)][string]$ComputerName	)
        Get-ServiceNowTableEntry -Table workstation_table -MatchExact @{name=$($computername)} 
    return
}
<#
    .SYNOPSIS
    Get a workstation's Assigned To value from ServiceNow workstation table 
    .DESCRIPTION

    .PARAMETER ComputerName
    Specifies the workstation Name attribute.
    .INPUTS
    None.
    .OUTPUTS
    A string containing the name of the user
    .EXAMPLE
    Get-SNOWAssignedTo "Workstation-NINJA"
    .EXAMPLE
    Get-SNOWAssignedTo $computer
#>
function Get-SNOWAssignedTo{
    param(
        [parameter(Mandatory=$true)][string]$computername
        )
    ((Get-ServiceNowTableEntry -Table workstation_table -MatchExact @{name=$($computername)} -ErrorAction SilentlyContinue).assigned_to).display_value
    }
<#
    .SYNOPSIS
    Get a workstation's Share device value from ServiceNow workstation table 
    .DESCRIPTION

    .PARAMETER ComputerName
    Specifies the workstation Name attribute.
    .INPUTS
    None.
    .OUTPUTS
    A boolean,
        True : Shared Device checkbox is ACTIVE
        False : Shared Device checkbox is NOT ACTIVE
    .EXAMPLE
    Get-SNOW-IsComputerSharedDevice "Workstation-NINJA"
    .EXAMPLE
    Get-SNOW-IsComputerSharedDevice $computer
#>
function Get-SNOW-IsComputerSharedDevice{
    param(
        [parameter(Mandatory=$true)][string]$computername
        )
        (Get-ServiceNowTableEntry -Table u_cmdb_ci_workstation -MatchExact @{name=$($computername)} -ErrorAction SilentlyContinue).u_shared_device
}
<#
    .SYNOPSIS
    Get a workstation's SysID value from ServiceNow workstation table 
    .DESCRIPTION
    SysID is the unique identifier for the computer
    .PARAMETER ComputerName
    Specifies the workstation Name attribute.
    .INPUTS
    None.
    .OUTPUTS
    An integer with the workstation's SysId
    .EXAMPLE
    Get-SNOWComputer-SysID "Workstation-NINJA"
    .EXAMPLE
    Get-SNOWComputer-SysID $computer
#>
function Get-SNOWComputer-SysID{
	param([string]$computername)
	(Get-ServiceNowTableEntry -Table u_cmdb_ci_workstation -MatchExact @{name=$($computer)} -ErrorAction SilentlyContinue).sys_id 
}

<#
    .SYNOPSIS
    Updates workstation's Assigned To value from ServiceNow workstation table 
    .DESCRIPTION

    .PARAMETER sysID
    Specifies the workstation SysID attribute.
    .PARAMETER user
    Specifies the workstation Assigned To attribute.
    .INPUTS
    None.
    .OUTPUTS
    A boolean,
        True : If record has been updated
        False : If record has not been updated
    .EXAMPLE
    Update-SNOWComputer "Workstation-NINJA"
    .EXAMPLE
    Update-SNOWComputer $computer
#>
function Update-SNOWComputer{
	param(
	[Parameter(Position=0,mandatory=$true)]
	[string] $sysID,
	[Parameter(Position=1,mandatory=$true)]
	[string] $user	)
	
	Update-ServiceNowTableEntry -Table workstation_table -Values @{assigned_to=$user} -sysId $sysID
        if($?) {return $true}# Write-Host 'Computer ' $computer ' has been assigned to ' $user ' in ServiceNow'}
        return $false
}