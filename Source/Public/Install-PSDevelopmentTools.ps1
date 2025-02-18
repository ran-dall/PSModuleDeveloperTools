<#
.SYNOPSIS
Installs essential PowerShell development tools.

.DESCRIPTION
Installs a curated set of PowerShell development tools essential for module development.

.PARAMETER Force
Optional. Forces installation even if a module is already present.

.EXAMPLE
Install-PSDevelopmentTools

.EXAMPLE
Install-PSDevelopmentTools -Force -Verbose

.OUTPUTS
[PSCustomObject] Returns an object containing:
- Success: Boolean indicating if all installations succeeded
- InstalledModules: Array of successfully installed module names
- FailedModules: Array of modules that failed to install
- Error: Any error messages from failed installations
#>
function Install-PSDevelopmentTools {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [switch]$Force
    )

    # Define required development modules
    $requiredModules = @(
        'PSScriptAnalyzer',
        'Pester',
        'InvokeBuild'
    )

    # Helper function to check if module needs installation
    function Test-ModuleInstallRequired {
        param (
            [string]$ModuleName,
            [switch]$Force
        )

        if ($Force) {
            Write-Host "Force flag specified - will reinstall $ModuleName"
            return $true
        }

        $existing = Get-Module -Name $ModuleName -ListAvailable
        $needsInstall = -not $existing
        
        if ($needsInstall) {
            Write-Host "$ModuleName not found - will install"
        }
        else {
            Write-Host "$ModuleName already installed - skipping"
        }

        return $needsInstall
    }

    # Helper function to install a single module
    function Install-SingleModule {
        param (
            [string]$ModuleName,
            [switch]$Force
        )

        try {
            $installParams = @{
                Name        = $ModuleName
                Scope       = 'CurrentUser'
                Force       = $Force
                ErrorAction = 'Stop'
            }
            
            Install-Module @installParams
            Write-Host "Successfully installed $ModuleName"
            return $true
        }
        catch {
            Write-Host "Failed to install $ModuleName`: $_"
            return $false
        }
    }

    # Track installation results
    $results = @{
        InstalledModules = [System.Collections.ArrayList]::new()
        FailedModules    = [System.Collections.ArrayList]::new()
    }

    # Process each module
    foreach ($module in $requiredModules) {
        if ((Test-ModuleInstallRequired -ModuleName $module -Force:$Force)) {
            $success = Install-SingleModule -ModuleName $module -Force:$Force
            
            if ($success) {
                $null = $results.InstalledModules.Add($module)
            }
            else {
                $null = $results.FailedModules.Add($module)
            }
        }
    }

    # Return results
    [PSCustomObject]@{
        Success          = $results.FailedModules.Count -eq 0
        InstalledModules = $results.InstalledModules.ToArray()
        FailedModules    = $results.FailedModules.ToArray()
        Error            = if ($results.FailedModules.Count -gt 0) {
            "Failed to install modules: $($results.FailedModules -join ', ')"
        }
        else {
            $null
        }
    }
}

# Helper function to write verbose output without the VERBOSE: prefix
function Write-VerboseOutput {
    [CmdletBinding()]
    param([string]$Message)
    
    if ($VerbosePreference -ne 'SilentlyContinue') {
        Write-Host $Message
    }
}
