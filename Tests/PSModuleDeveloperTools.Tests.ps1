Describe 'PSModuleDeveloperTools Module' {
    BeforeAll {
        # Create a dedicated test directory
        $script:testRoot = Join-Path -Path $PSScriptRoot -ChildPath 'TestModules'
        $null = New-Item -Path $testRoot -ItemType Directory -Force
        
        # Backup and modify PSModulePath
        $script:originalPSModulePath = $env:PSModulePath
        $env:PSModulePath = "$testRoot;$env:PSModulePath"

        # Import module
        $moduleName = 'PSModuleDeveloperTools'
        if (-not (Get-Module -Name $moduleName)) {
            Import-Module -Name $moduleName -ErrorAction Stop
        }
    }

    Context 'New-ModuleProject Function' {
        BeforeEach {
            # Clean test directory before each test
            if (Test-Path $testRoot) {
                Get-ChildItem -Path $testRoot -Force | Remove-Item -Recurse -Force
            }
        }

        It 'Should create a new module project directory' {
            # Create module in test directory with verbose output
            $result = New-ModuleProject -ModuleName 'TestModule' -ModulePath $testRoot -Verbose 4>&1
            
            # Display the verbose output to help debug
            $result | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } | 
            ForEach-Object { Write-Host "VERBOSE: $($_.Message)" }
            
            # Get the actual result object
            $result = $result | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] }
            
            # Verify success
            $result | Should -Not -BeNull
            $result.Success | Should -Be $true
            $result.Error | Should -BeNull
            
            # Verify directory structure
            $modulePath = Join-Path -Path $testRoot -ChildPath 'TestModule'
            Test-Path $modulePath | Should -Be $true
        }
    }

    Context 'New-ModulePackage Function' {
        It 'Should create a module package' {
            # Create test module first
            $result = New-ModuleProject -ModuleName 'TestModule' -ModulePath $testRoot
            $modulePath = $result.ModulePath
            
            # Create package
            Push-Location $modulePath
            $packageResult = New-ModulePackage -ModuleName 'TestModule' -Install
            Pop-Location
            
            # Verify package creation
            $packageResult.Success | Should -Be $true
            $packageResult.Error | Should -BeNull
            
            # Verify nuspec was created
            Test-Path (Join-Path $modulePath 'TestModule.nuspec') | Should -Be $true
        }
    }

    Context 'Install-PSDevelopmentTools Function' {
        It 'Should install required development tools' {
            { Install-PSDevelopmentTools } | Should -Not -Throw
            Get-Module -ListAvailable | 
            Where-Object { $_.Name -in @('PSScriptAnalyzer', 'Pester', 'InvokeBuild') } | 
            Should -Not -BeNullOrEmpty
        }
    }

    AfterAll {
        # Restore original PSModulePath
        $env:PSModulePath = $script:originalPSModulePath
        
        # Clean up test directory
        if (Test-Path $testRoot) {
            Remove-Item -Path $testRoot -Recurse -Force
        }
    }
}
