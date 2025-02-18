# PSModuleDeveloperTools 

## Overview
PSModuleDeveloperTools is a PowerShell module designed to streamline the creation, packaging, and testing of PowerShell modules. It automates the setup of a structured module project, enables packaging for distribution.

## Installation
```powershell
Install-Module -Name PSModuleDeveloperTools -Scope CurrentUser -Force
```

## Features

### Creating a New Module Project
```powershell
New-ModuleProject -ModuleName "MyModule" `
                 -Description "My custom PowerShell module" `
                 -Author "YourName" `
                 -CompanyName "YourCompany" `
                 -ModuleVersion "1.0.0" `
                 -InitializeGit `
                 -IncludePesterTests
```

Creates a new PowerShell module with:
- Standard directory structure
- Module manifest (.psd1)
- Module loader (.psm1)
- Pester tests
- Git repository (optional)
- README.md

### Directory Structure
```
MyModule/
├── Source/
│   ├── Public/    # Exported functions
│   ├── Private/   # Internal functions
├── Tests/         # Pester tests
├── MyModule.psm1  # Module loader
├── MyModule.psd1  # Module manifest
├── README.md
├── .gitignore     # If -InitializeGit is used
```

### Packaging the Module
```powershell
New-ModulePackage -ModuleName "MyModule" -Install
```
Packages your module for distribution:
- Creates NuGet specification
- Builds module package
- Optionally installs locally

### Installing Development Tools
```powershell
Install-PSDevelopmentTools [-Force]
```
Installs essential PowerShell development tools:
- PSScriptAnalyzer
- Pester
- InvokeBuild

## Requirements
- PowerShell 5.1 or later
- Windows PowerShell or PowerShell Core
- NuGet (for packaging)

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This module is licensed under the OSL-3.0 License.
