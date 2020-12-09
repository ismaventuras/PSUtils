
function Restart-NetAdapters {
  <#
    .SYNOPSIS
    Get all the network adapters and restart them
  #>
  Get-NetAdapter | Restart-NetAdapter
}


