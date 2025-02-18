<#
.SYNOPSIS
Creates a PowerShell module loader (.psm1) file.

.DESCRIPTION
Generates a module loader file that imports public and private functions, respecting
the module manifest's FunctionsToExport setting for proper encapsulation.

.PARAMETER ModuleName
Required. The name of the module.

.PARAMETER ModulePath
Required. The root path of the module directory.

.EXAMPLE
New-PSM1Loader -ModuleName "MyModule" -ModulePath "C:\Projects\MyModule"

.OUTPUTS
[PSCustomObject] Returns an object containing:
- Success: Boolean indicating if the operation succeeded
- LoaderPath: Path to the created .psm1 file
- Error: Any error message if the operation failed
#>
function New-PSM1Loader {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ModulePath
    )

    # Helper function to generate loader content
    function New-LoaderContent {
        @'
# Import module manifest
$manifestPath = Join-Path $PSScriptRoot "$([System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)).psd1"
$manifest = Import-PowerShellDataFile -Path $manifestPath

# Get public and private function definition files
$Public = @(Get-ChildItem -Path "$PSScriptRoot\Source\Public\*.ps1" -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Source\Private\*.ps1" -ErrorAction SilentlyContinue)

# Import all function files
foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Export only the functions listed in FunctionsToExport from the manifest
$manifest.FunctionsToExport | ForEach-Object {
    if (Get-Command -Name $_ -ErrorAction SilentlyContinue) {
        Export-ModuleMember -Function $_
    }
    else {
        Write-Warning "Function $_ listed in FunctionsToExport but not found in module"
    }
}
'@
    }

    try {
        # Define PSM1 file path
        $psm1Path = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psm1"

        # Generate and write loader content
        $loaderContent = New-LoaderContent
        $loaderContent | Out-File -FilePath $psm1Path -Encoding utf8 -Force

        # Return success result
        [PSCustomObject]@{
            Success    = $true
            LoaderPath = $psm1Path
            Error      = $null
        }
    }
    catch {
        # Return failure result
        [PSCustomObject]@{
            Success    = $false
            LoaderPath = $null
            Error      = $_.Exception.Message
        }
    }
}
