<#
.SYNOPSIS
Creates a new PowerShell module project with a standard structure.

.DESCRIPTION
Creates a structured PowerShell module project including source directories, manifest, module loader, and optional components like tests and Git initialization. This function is designed to help automate the creation of new modules with consistent structure and content.

.PARAMETER ModuleName
Required. Name of the module to create.

.PARAMETER ModulePath
Optional. Base path where the module will be created. Defaults to current location.

.PARAMETER InitializeGit
Optional. Initialize a Git repository in the module directory.

.PARAMETER InstallDevelopmentTools
Optional. Install recommended PowerShell development tools.

.PARAMETER IncludePesterTests
Optional. Include initial Pester test file.

.PARAMETER ModuleVersion
Optional. Version number for the module. Defaults to "1.0.0".

.PARAMETER Author
Optional. Module author's name. Defaults to "Your Name".

.PARAMETER CompanyName
Optional. Company or organization name.

.PARAMETER Description
Optional. Description of the module's purpose.

.PARAMETER PowerShellVersion
Optional. Minimum PowerShell version required. Defaults to "5.1".

.PARAMETER FunctionsToExport
Optional. Array of function names to export.

.PARAMETER HelpInfoURI
Optional. URI for online help documentation.

.PARAMETER Copyright
Optional. Copyright statement.

.PARAMETER CompatiblePSEditions
Optional. Array of compatible PowerShell editions.

.PARAMETER RequiredModules
Optional. Array of required module names.

.PARAMETER CmdletsToExport
Optional. Array of cmdlet names to export.

.PARAMETER VariablesToExport
Optional. Array of variable names to export.

.PARAMETER AliasesToExport
Optional. Array of alias names to export.

.PARAMETER DefaultCommandPrefix
Optional. Prefix for exported commands.

.EXAMPLE
New-ModuleProject -ModuleName "MyTools" -Author "John Doe" -Description "Collection of helpful tools"

.OUTPUTS
[PSCustomObject] Returns an object containing:
- Success: Boolean indicating if the operation succeeded
- ModulePath: Path to the created module
- Error: Any error message if the operation failed
#>
function New-ModuleProject {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,

        [ValidateNotNullOrEmpty()]
        [string]$ModulePath = (Get-Location).Path,

        [switch]$InitializeGit,
        [switch]$InstallDevelopmentTools,
        [switch]$IncludePesterTests,

        [ValidatePattern('^\d+\.\d+\.\d+$')]
        [string]$ModuleVersion = '1.0.0',

        [ValidateNotNullOrEmpty()]
        [string]$Author = 'Your Name',

        [string]$CompanyName,

        [ValidateNotNullOrEmpty()]
        [string]$Description = "A description of $ModuleName",

        [ValidatePattern('^\d+\.\d+$')]
        [string]$PowerShellVersion = '5.1',

        [string[]]$FunctionsToExport = @(),

        [ValidateScript({ 
                $_ -eq '' -or $null -eq $_ -or $_ -match '^https?://'
            })]
        [string]$HelpInfoURI,

        [ValidateNotNullOrEmpty()]
        [string]$Copyright = "(c) $Author. All rights reserved.",

        [string[]]$CompatiblePSEditions = @(),
        [string[]]$RequiredModules = @(),
        [string[]]$CmdletsToExport = @(),
        [string[]]$VariablesToExport = @(),
        [string[]]$AliasesToExport = @(),
        [string]$DefaultCommandPrefix
    )

    # Helper function to create the module directory structure
    function New-ModuleStructure {
        param (
            [string]$BasePath,
            [string]$ModuleName
        )

        $fullPath = Join-Path -Path $BasePath -ChildPath $ModuleName
        
        if (Test-Path $fullPath) {
            throw "Module directory already exists at $fullPath"
        }

        # Define required paths
        $paths = @(
            "$fullPath\Source\Public",
            "$fullPath\Source\Private",
            "$fullPath\Tests"
        )

        # Create directories
        foreach ($path in $paths) {
            $null = New-Item -Path $path -ItemType Directory -Force
        }

        # Create initial README
        $readmePath = Join-Path $fullPath 'README.md'
        @"
# $ModuleName

## Description
$Description

## Installation
``````powershell
Install-Module -Name $ModuleName
Usage
[Add usage examples here]
"@ | Out-File -FilePath $readmePath -Encoding utf8
        return $fullPath
    }

    # Helper function to initialize Git repository
    function Initialize-GitRepository {
        param ([string]$Path)

        if (Get-Command git -ErrorAction SilentlyContinue) {
            Set-Location $Path
            $null = git init
        
            # Create initial .gitignore
            @'
#Build outputs
*.nupkg
*.zip
PowerShell
*.pssproj
*.psess
*.vspx
*.ps1xml
Module packaging
*.nuspec
IDE files
.vs/
.vscode/
*.suo
*.user
*.userosscache
*.sln.docstates
Logs
*.log
*.trace
Local testing files
test-results.xml
'@ | Out-File -FilePath (Join-Path $Path '.gitignore') -Encoding utf8
            return $true
        }
    
        Write-Host 'Git not found in PATH. Skipping repository initialization.'
        return $false
    }

    try {
        Write-Host "Creating new module '$ModuleName' at path '$ModulePath'"
    
        # Create module structure
        $modulePath = New-ModuleStructure -BasePath $ModulePath -ModuleName $ModuleName
        Write-Host 'Created module structure'

        # Create module manifest
        $manifestParams = @{}
        foreach ($key in $PSBoundParameters.Keys) {
            $manifestParams[$key] = $PSBoundParameters[$key]
        }
        $manifestParams['ModulePath'] = $modulePath
    
        $manifestResult = Build-ModuleManifest @manifestParams
        if (-not $manifestResult.Success) {
            throw "Failed to create module manifest: $($manifestResult.Error)"
        }
        Write-Host 'Created module manifest'

        # Create module loader
        $loaderResult = New-PSM1Loader -ModuleName $ModuleName -ModulePath $modulePath
        if (-not $loaderResult.Success) {
            throw "Failed to create module loader: $($loaderResult.Error)"
        }
        Write-Host 'Created module loader'

        # Optional components
        if ($IncludePesterTests) {
            $pesterResult = New-PesterTest -ModuleName $ModuleName -ModulePath $modulePath
            if (-not $pesterResult.Success) {
                Write-Warning "Failed to create Pester tests: $($pesterResult.Error)"
            }
            else {
                Write-Host 'Created Pester tests'
            }
        }

        if ($InstallDevelopmentTools) {
            Install-PSDevelopmentTools
            Write-Host 'Installed development tools'
        }

        if ($InitializeGit) {
            $null = Initialize-GitRepository -Path $modulePath
            Write-Host 'Initialized Git repository'
        }

        [PSCustomObject]@{
            Success    = $true
            ModulePath = $modulePath
            Error      = $null
        }
    }
    catch {
        Write-Host "Failed to create module: $($_.Exception.Message)"
        [PSCustomObject]@{
            Success    = $false
            ModulePath = $null
            Error      = $_.Exception.Message
        }
    }
    finally {
        # Ensure we return to the original location
        if ($InitializeGit) {
            Set-Location $ModulePath
        }
    }
}
