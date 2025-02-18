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
