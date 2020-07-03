    <#
    .SYNOPSIS
        Test if application has been run with elevated rights
    .DESCRIPTION
        Long description
    .EXAMPLE
        PS C:\> Test-Administrator
    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Boolean Returns true if is admin, returns false if not
    .NOTES
        General notes
    #>
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
