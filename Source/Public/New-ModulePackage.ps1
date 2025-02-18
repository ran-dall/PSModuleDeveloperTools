<#
.SYNOPSIS
Creates and optionally installs a NuGet package for a PowerShell module.

.DESCRIPTION
Creates a NuGet package (.nupkg) from a PowerShell module and optionally installs it locally.
This function follows functional programming principles by:
- Separating package creation from installation
- Using immutable data structures
- Providing clear error handling and results
- Breaking down complex operations into pure functions

.PARAMETER ModuleName
Optional. Name of the module. Defaults to the first .psd1 file found in the current directory.

.PARAMETER Install
Optional. Switch to install the package in the local PowerShell modules directory.

.PARAMETER InstallNuGet
Optional. Switch to install NuGet if not found on the system.

.EXAMPLE
New-ModulePackage -ModuleName "MyModule" -Install

.OUTPUTS
[PSCustomObject] Returns an object containing:
- Success: Boolean indicating if the operation succeeded
- PackagePath: Path to the created .nupkg file
- InstallPath: Path where the package was installed (if Install was specified)
- Error: Any error message if the operation failed
#>
function New-ModulePackage {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [string]$ModuleName = (Get-ChildItem -Path (Get-Location) -Filter *.psd1 -Recurse | 
            Select-Object -First 1 | ForEach-Object BaseName),
        
        [switch]$Install,
        [switch]$InstallNuGet
    )

    # Helper function to verify or install NuGet
    function Get-NuGetPath {
        param([switch]$InstallIfMissing)

        $nugetPath = Get-Command nuget -ErrorAction SilentlyContinue | 
        Select-Object -ExpandProperty Source

        if (-not $nugetPath -and $InstallIfMissing) {
            try {
                Write-Output 'NuGet not found. Installing via winget...'
                winget install Microsoft.NuGet -e
                $nugetPath = Get-Command nuget -ErrorAction SilentlyContinue | 
                Select-Object -ExpandProperty Source
            }
            catch {
                throw "Failed to install NuGet: $_"
            }
        }
        
        if (-not $nugetPath) {
            throw 'NuGet not installed. Use -InstallNuGet to install.'
        }

        return $nugetPath
    }

    # Helper function to find and validate module manifest
    function Get-ModuleManifest {
        param(
            [string]$ModuleName,
            [string]$RootPath
        )

        $psd1File = Get-ChildItem -Path $RootPath -Filter "$ModuleName.psd1" -Recurse | 
        Select-Object -First 1
        
        if (-not $psd1File) {
            throw "Module manifest (.psd1) not found for $ModuleName"
        }

        $manifest = Import-PowerShellDataFile -Path $psd1File.FullName
        if (-not $manifest) {
            throw 'Failed to import module manifest'
        }

        return @{
            Path = $psd1File.FullName
            Data = $manifest
        }
    }

    # Helper function to create NuGet package
    function New-NuGetPackage {
        param(
            [string]$NuGetPath,
            [string]$NuSpecPath,
            [string]$OutputDirectory
        )

        $nugetResult = & $NuGetPath pack $NuSpecPath -OutputDirectory $OutputDirectory `
            -NoDefaultExcludes -NoPackageAnalysis -NonInteractive

        if ($LASTEXITCODE -ne 0) {
            throw "NuGet package creation failed: $nugetResult"
        }

        return $nugetResult
    }

    # Helper function to install package locally
    function Install-LocalPackage {
        param(
            [string]$PackagePath,
            [string]$ModuleName
        )

        $localModulePath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) `
            -ChildPath "PowerShell\Modules\$ModuleName"

        # Clean existing installation
        if (Test-Path $localModulePath) {
            Remove-Item -Path $localModulePath -Recurse -Force
        }

        # Create directory and extract package
        $null = New-Item -ItemType Directory -Path $localModulePath -Force
        Expand-Archive -Path $PackagePath -DestinationPath $localModulePath -Force

        return $localModulePath
    }

    try {
        # Verify NuGet installation
        $nugetPath = Get-NuGetPath -InstallIfMissing:$InstallNuGet

        # Get module manifest
        $manifestInfo = Get-ModuleManifest -ModuleName $ModuleName -RootPath (Get-Location)
        $rootPath = Split-Path -Path $manifestInfo.Path -Parent

        # Create .nuspec file
        $nuspecResult = Build-NuspecFile -ModuleManifestPath $manifestInfo.Path
        if (-not $nuspecResult.Success) {
            throw "Failed to create .nuspec file: $($nuspecResult.Error)"
        }

        # Create package
        $version = $manifestInfo.Data.ModuleVersion
        $packagePath = Join-Path -Path $rootPath -ChildPath "$ModuleName.$version.nupkg"
        $null = New-NuGetPackage -NuGetPath $nugetPath `
            -NuSpecPath $nuspecResult.NuspecPath `
            -OutputDirectory $rootPath

        # Install locally if requested
        $installPath = $null
        if ($Install) {
            $installPath = Install-LocalPackage -PackagePath $packagePath -ModuleName $ModuleName
            Remove-Item -Path $packagePath -Force # Clean up package after installation
        }

        # Return success result
        [PSCustomObject]@{
            Success     = $true
            PackagePath = $Install ? $null : $packagePath
            InstallPath = $installPath
            Error       = $null
        }
    }
    catch {
        # Return failure result
        [PSCustomObject]@{
            Success     = $false
            PackagePath = $null
            InstallPath = $null
            Error       = $_.Exception.Message
        }
    }
}
