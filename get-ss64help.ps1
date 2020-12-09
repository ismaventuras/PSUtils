[CmdletBinding()]
param 
(
	[string]$commandEntry
)

Function Get-SS64Help
{
	[CmdletBinding()]
	param 
	(
		[string]$commandEntry
	)

	if($verbose)
	{
		$verbosePreference = SilentlyContinue
	}

	$baseUrl = "https://ss64.com/ps"

    $commandEntry = ($commandEntry).ToLower()
	$fullUrl = "$baseUrl/$commandEntry.html"

	Write-Verbose "$fullUrl"

	try

	{
		$resp = Invoke-WebRequest -Uri $fullUrl -ErrorAction Stop

		Write-Verbose $resp
	}

	catch

	{

		Write-Host "Invoke-WebRequest: Error contacting $fullUrl"

		Write-Verbose $_

	}

	$overview = $resp.AllElements | Where {$_.TagName -eq "pre"}

	$syntax = $overview.innerText

	$examplesOverview = $resp.AllElements | Where {$_.TagName -eq "p" -and $_.Class -match "code"}

	$examples = $examplesOverview.innerText

	$returnObj = @{

		Syntax = $syntax

		Examples = $examples

	}

	return $returnObj

}

$result = Get-SS64Help -commandEntry $commandEntry

$result.Syntax
""
$result.Examples

#To use `.\get-ss64help.ps1 -commandEntry "get-acl"`