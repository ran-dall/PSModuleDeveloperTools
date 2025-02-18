<#
.SYNOPSIS
Creates a PowerShell module manifest with specified parameters.

.DESCRIPTION
Builds a PowerShell module manifest (.psd1) file with provided configuration parameters. This function is a wrapper around New-ModuleManifest that simplifies the process of creating a module manifest by providing default values for common parameters and allowing you to specify only the parameters you need.

.PARAMETER ModuleName
Required. The name of your PowerShell module.

.PARAMETER ModulePath
Required. The directory path where module files will be created.

.PARAMETER ModuleVersion
Optional. The version number for your module. Defaults to "1.0.0".

.PARAMETER Author
Optional. The module author's name. Defaults to "Name".

.PARAMETER CompanyName
Optional. The company or organization name.

.PARAMETER Description
Optional. A description of what your module does. Defaults to a basic description using the module name.

.PARAMETER PowerShellVersion
Optional. Minimum PowerShell version required. Defaults to "5.1".

.PARAMETER FunctionsToExport
Optional. Array of function names to export. Defaults to @("Get-Greeting").

.PARAMETER HelpInfoURI
Optional. URI for online help documentation.

.PARAMETER Copyright
Optional. Copyright notice. Defaults to "(c) {Author}. All rights reserved."

.PARAMETER CompatiblePSEditions
Optional. Array of compatible PowerShell editions (e.g., 'Desktop', 'Core').

.PARAMETER RequiredModules
Optional. Array of module names that your module depends on.

.PARAMETER CmdletsToExport
Optional. Array of cmdlet names to export.

.PARAMETER VariablesToExport
Optional. Array of variable names to export.

.PARAMETER AliasesToExport
Optional. Array of alias names to export.

.PARAMETER DefaultCommandPrefix
Optional. Prefix to add to all exported commands.

.EXAMPLE
$manifestParams = @{
    ModuleName = "MyModule"
    ModulePath = "."
    Author = "Randall"
    Description = "A module that does amazing things"
}
Build-ModuleManifest @manifestParams
#>
function Build-ModuleManifest {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ModulePath,

        [ValidatePattern('^\d+\.\d+\.\d+$')]
        [string]$ModuleVersion = '1.0.0',

        [ValidateNotNullOrEmpty()]
        [string]$Author = 'Name',

        [string]$CompanyName,

        [ValidateNotNullOrEmpty()]
        [string]$Description = "A description of $ModuleName",

        [ValidatePattern('^\d+\.\d+$')]
        [string]$PowerShellVersion = '5.1',

        [string[]]$FunctionsToExport = @('Get-Greeting'),

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

    # Create an immutable parameter set for New-ModuleManifest
    $manifestParams = @{
        Path              = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"
        RootModule        = "$ModuleName.psm1"
        ModuleVersion     = $ModuleVersion
        Author            = $Author
        Description       = $Description
        PowerShellVersion = $PowerShellVersion
        FunctionsToExport = $FunctionsToExport
        CmdletsToExport   = $CmdletsToExport
        VariablesToExport = $VariablesToExport
        AliasesToExport   = $AliasesToExport
        Copyright         = $Copyright
    }

    # Add optional parameters only if they have values
    $optionalParams = @{
        CompanyName          = $CompanyName
        CompatiblePSEditions = $CompatiblePSEditions
        RequiredModules      = $RequiredModules
        HelpInfoURI          = $HelpInfoURI
        DefaultCommandPrefix = $DefaultCommandPrefix
    }

    # Functionally merge optional parameters that have values
    $manifestParams = $optionalParams.GetEnumerator() |
    Where-Object { $null -ne $_.Value -and $_.Value -ne '' } |
    ForEach-Object -Begin { $manifestParams } -Process {
        $manifestParams[$_.Key] = $_.Value
        $manifestParams
    } |
    Select-Object -Last 1

    # Create the manifest and capture the result
    try {
        $null = New-ModuleManifest @manifestParams
        $result = @{
            Success = $true
            Path    = $manifestParams.Path
            Error   = $null
        }
    }
    catch {
        $result = @{
            Success = $false
            Path    = $manifestParams.Path
            Error   = $_.Exception.Message
        }
    }

    # Return an immutable result object
    [PSCustomObject]$result
}
