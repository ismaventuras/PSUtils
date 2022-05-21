# Paths
. ./vars.ps1

### Logic
function Order-DownloadsFolder{
    param(
        [Parameter(Mandatory)]
        [string[]] $extension_list,
        [Parameter(Mandatory)]
        [string] $dest
    )

    $extension_list | ForEach-Object {
        write-host 'moving' $_ 'files'
        Get-ChildItem -Path $downloads_folder -Filter $_ | ForEach-Object {
            #Check if file already exists, in that case rename it
            if(Test-Path -Path "$($images_folder)$($_)"){
                $new_name = ($_.BaseName + $(Get-Date -f yyyy-MM-dd-hh-ss) + $_.Extension)
                $_ | Move-Item -Destination "$($dest)$($new_name)"
            }
            else {
                <# Action when all if and elseif conditions are false #>
                $_ | Move-Item -Destination $dest
            }
        }
    }

}

Order-DownloadsFolder -extension_list $image_extensions -dest $images_folder
Order-DownloadsFolder -extension_list $doc_extensions -dest $documents_folder
