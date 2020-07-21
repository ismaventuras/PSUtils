[CmdletBinding()]
PARAM (
  [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
  [String]$API_URL,
  [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
  [pscredential]$Credential
)
    # Headers for API request, Basic auth
    $HeaderAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Credential.Username, $Credential.GetNetworkCredential().Password)))
    $SessionHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $SessionHeader.Add('Authorization', ('Basic {0}' -f $HeaderAuth))
    $SessionHeader.Add('Accept', 'application/json')


    Write-Log -Message ('Trying to query {0}' -f $API_URL)

    Try {
        $dataJSON = Invoke-RestMethod -Method GET -Uri $API_URL -TimeoutSec 100 -Headers $SessionHeader -ContentType "application/json"
        return $dataJSON.result
    }
    Catch {
        # Si el usuario o el password son incorrectos, devuelve un mensaje de no autorizado
        if ($_.Exception.Response.StatusCode.Value__ -eq 401) {
            Write-Host $_.Exception.Message.ToString() -ForeGroundColor Black -BackgroundColor Red
            Write-Log -Level 'INFO' -Message $_.Exception.Message.ToString()
        }
        # Si es otro error, devuelve el mensaje
        else {
            Write-Host $_.Exception.Message.ToString()
            Write-Log -Level 'ERROR' -Message $_.Exception.Message.ToString() 
        }
    }
