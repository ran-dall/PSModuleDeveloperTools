<#
.SYNOPSIS
Creates a NuSpec file for NuGet packaging from a PowerShell module manifest.

.DESCRIPTION
Transforms a PowerShell module manifest (.psd1) into a NuSpec file for NuGet packaging. The NuSpec file is used to define metadata for the module package, such as the module ID, version, authors, and description. This function reads the module manifest file and generates a corresponding NuSpec file with the necessary metadata.

.PARAMETER ModuleManifestPath
Required. Full path to the PowerShell module manifest (.psd1) file.

.EXAMPLE
Build-NuspecFile -ModuleManifestPath "C:\Modules\MyModule\MyModule.psd1"

.OUTPUTS
[PSCustomObject] Returns an object containing:
- Success: Boolean indicating if the operation succeeded
- NuspecPath: Path to the created .nuspec file
- Error: Any error message if the operation failed
#>
function Build-NuspecFile {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$ModuleManifestPath
    )

    # Helper function to extract module ID from root module name
    function Get-ModuleIdFromManifest {
        param ([hashtable]$Manifest)
        
        if (-not $Manifest.RootModule) {
            throw 'RootModule not found in manifest'
        }

        if (-not ($Manifest.RootModule -match '\.psm1$')) {
            throw 'RootModule must be a .psm1 file'
        }

        [System.IO.Path]::GetFileNameWithoutExtension($Manifest.RootModule)
    }

    # Helper function to create nuspec content
    function New-NuspecContent {
        param (
            [string]$ModuleId,
            [string]$Version,
            [string[]]$Authors,
            [string]$Description
        )

        @"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2013/05/nuspec.xsd">
  <metadata>
    <id>$ModuleId</id>
    <version>$Version</version>
    <authors>$($Authors -join ', ')</authors>
    <owners>$($Authors -join ', ')</owners>
    <description>$Description</description>
    <tags>PowerShell</tags>
  </metadata>
</package>
"@
    }

    # Helper function to safely write content to file
    function Write-NuspecFile {
        param (
            [string]$Path,
            [string]$Content
        )

        try {
            $Content | Out-File -FilePath $Path -Encoding utf8BOM -Force
            $true
        }
        catch {
            throw "Failed to write nuspec file: $_"
        }
    }

    try {
        # Read and validate manifest
        $manifest = Import-PowerShellDataFile -Path $ModuleManifestPath
        
        # Validate required fields
        if (-not $manifest.ModuleVersion) {
            throw 'ModuleVersion missing from manifest'
        }

        # Transform data
        $moduleId = Get-ModuleIdFromManifest -Manifest $manifest
        $nuspecPath = Join-Path (Split-Path -Path $ModuleManifestPath -Parent) "$moduleId.nuspec"
        
        # Generate nuspec content
        $nuspecContent = New-NuspecContent `
            -ModuleId $moduleId `
            -Version $manifest.ModuleVersion `
            -Authors @($manifest.Author) `
            -Description $manifest.Description

        # Write the file
        $null = Write-NuspecFile -Path $nuspecPath -Content $nuspecContent

        # Return success result
        [PSCustomObject]@{
            Success    = $true
            NuspecPath = $nuspecPath
            Error      = $null
        }
    }
    catch {
        # Return failure result
        [PSCustomObject]@{
            Success    = $false
            NuspecPath = $null
            Error      = $_.Exception.Message
        }
    }
}
