[CmdletBinding()]
PARAM (
  [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
  [String]$FilePath = '.\creds.xml',
  [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
  [String]$Message = 'Enter valid credential'
)

# Testing if file exists
# IF doesn't exist, prompting and saving credentials
if ((Test-Path $FilePath) -eq $False) {
    $Credential = Get-Credential -Message $Message
    $Credential | EXPORT-CLIXML $FilePath -Force
    return $Credential
}
# Importing credentials
$Credential = IMPORT-CLIXML $FilePath
# Return the stored credential
return $Credential