
#Get-ServiceNowTableEntry -Table u_cmdb_ci_workstation -MatchContains @{assigned_to="Ismael Bautista"}
<#
	Args
#>


function Connect-ToSNOW{
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
}

if(-not (Get-Module -ListAvailable -Name ServiceNow)) {Install-Module ServiceNow -Credential (Get-Credential -Message "Use an account with administrator privileges to install the ServiceNow necessary libraries")} #If module is not installed, install it
Import-Module ServiceNow #import the module
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 #Authenticate over TLS 
Connect-ToSNOW

#Get all SNOW users under Spain assigment
$params =  @{source='OU=ES,DC=eu,DC=dir,DC=bunge,DC=com'}
$userList = Get-ServiceNowUser -MatchContains $params -Limit 1000 | ?{ $_.email -NotLike "*__Terminated" -and $_.email -notlike "" -and $_.active -notlike 'false'}

$objects = New-Object System.Collections.ArrayList
foreach($user in $userlist){
	#Write-Host $user.name 
	$entries = (Get-ServiceNowTableEntry -Table u_cmdb_ci_workstation -MatchContains @{assigned_to=$($user.name)} -ErrorAction SilentlyContinue).name
	if($entries.Count -gt 1){
		$object = New-Object System.Object
		$object | add-member -memberType NoteProperty -Name User -Value $user.name
		$count=1
		<#foreach($entry in $entries){
			$propertyname = "Computer" + $count
			$object | add-member -memberType NoteProperty -Name $propertyname -Value $entry
			$count++
		}#>
		$object | add-member -memberType NoteProperty -Name Computer -Value (@($entries) -join ';')
		#if($entries.comments){$object | add-member -memberType NoteProperty -Name Comments - Value $entries.comments}
		$object
		$objects += $object
	}
}

$objects | export-csv 'C:\Temp\snowUserList.csv' -Delimiter ';'
