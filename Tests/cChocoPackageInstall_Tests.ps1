#----------------------------------------# 
# Pester tests for cChocoPackageInstall  # 
#----------------------------------------# 
$ResourceName = ((Split-Path -Path $MyInvocation.MyCommand.Path -Leaf) -split '_')[0]
$ResourceFile = (Get-DscResource -Name $ResourceName).Path

$TestsPath    = (split-path -path $MyInvocation.MyCommand.Path -Parent)
$ResourceFile = Get-ChildItem -Recurse $TestsPath\.. -File | Where-Object {$_.name -eq "$ResourceName.psm1"}

Import-Module -Name $ResourceFile.FullName

Describe -Name "Testing $ResourceName loaded from $ResourceFile" -Fixture {
    Context -Name "Package is not installed" -Fixture {
        # this mock is always evaluated last, so we don't side-effect the local pc running the tests, see: https://github.com/pester/Pester/wiki/Mock.
        Mock Invoke-Choco -ModuleName 'cChocoPackageInstall' -MockWith {[pscustomobject]@{ 'Output'  = @('output'); 'Success' = $false;}}
        Mock Invoke-Choco -ModuleName 'cChocoPackageInstall'`
                          -ParameterFilter { $Parameters[0] -eq "list" }`
                          -MockWith {
                            return [pscustomobject]@{
                                'Output'  = @('Chocolatey v0.10.7', 'NotGoogleChrome 1.0.0', '1 packages installed');
                                'Success' = $true;
                            }
                          }
        Mock Test-Command -ModuleName 'cChocoPackageInstall' -MockWith { return $True; }
        
        $Scenario1 = @{
            Name   = 'GoogleChrome'
            Ensure = 'Present'
        }
        It -name "Test-TargetResource -ensure 'Present' should return False" -test {
            Test-TargetResource @Scenario1 | Should Be $False
        }
       
        It -name "Set-TargetResource -ensure 'Present' shoudl install package" {
            Mock Invoke-Choco -ModuleName 'cChocoPackageInstall'`
                        -MockWith {
                            return [pscustomobject]@{
                                'Output'  = @('output');
                                'Success' = $true;
                            }
                        }`
                        -ParameterFilter { -not (Compare-Object $Parameters "install", "GoogleChrome", "-y") }`
                        -Verifiable
            Set-TargetResource @Scenario1
            Assert-VerifiableMocks
        }

        $Scenario2 = @{
            Name   = 'GoogleChrome'
            Ensure = 'Absent'
        }
        It -name "Test-TargetResource -ensure 'Absent' should return True" -test {
            Test-TargetResource @Scenario2 | Should Be $True
        }
        
        $Scenario3 = @{
            Name    = 'GoogleChrome'
            Ensure  = 'Absent'
            Version = '1.0.0'
        }     
        It -name "Test-TargetResource -ensure 'Absent' -version '1.0.0' should return True" -test {
            Test-TargetResource @Scenario3 | Should Be $True
        }

        $Scenario4 = @{
            Name        = 'GoogleChrome'
            Ensure      = 'Absent'
            AutoUpgrade = $True
        }
        It -name "Test-TargetResource -ensure 'Absent' -AutoUpgrade should return True" -test {
            Test-TargetResource @Scenario4 | Should Be $True
        }

        $Scenario5 = @{
            Name        = 'GoogleChrome'
            Ensure      = 'Absent'
            Version     = '1.0'
            AutoUpgrade = $True
        }
        It -name "Test-TargetResource -ensure 'Absent' -version '1.0.0' -AutoUpgrade should return True" -test {
            Test-TargetResource @Scenario5 | Should Be $True
        }
    }

    Context -Name "Package is installed with version 1.0.0" -Fixture {
        # this mock is always evaluated last, so we don't side-effect the local pc running the tests, see: https://github.com/pester/Pester/wiki/Mock.
        Mock Invoke-Choco -ModuleName 'cChocoPackageInstall' -MockWith {[pscustomobject]@{ 'Output'  = @('output'); 'Success' = $false;}}
        Mock Invoke-Choco -ModuleName 'cChocoPackageInstall'`
                          -ParameterFilter { $Parameters[0] -eq "list" }`
                          -MockWith {
                            return [pscustomobject]@{
                                'Output'  = @(
                                    'Chocolatey v0.10.7',
                                    'GoogleChrome 1.0.0',
                                    '1 packages installed',
                                    '',
                                    'Did you know Pro / Business automatically syncs with Programs and',
                                    ' Features? Learn more about Package Synchronizer at ',
                                    ' https://chocolatey.org/compare'
                                );
                                'Success' = $true;
                            }
                          }
        Mock Test-Command -ModuleName 'cChocoPackageInstall' -MockWith { return $True; }      

        $Scenario1 = @{
            Name   = 'GoogleChrome'
            Ensure = 'Present'
        }
        It -name "Test-TargetResource -ensure 'Present' should return True" -test {
            Test-TargetResource @Scenario1 | Should Be $True            
        }

        $Scenario2 = @{
            Name   = 'GoogleChrome'
            Ensure = 'Absent'
        }
        It -name "Test-TargetResource -ensure 'Absent' should return False" -test {
            Test-TargetResource @Scenario2 | Should Be $False
        }
        It -name "Set-TargetResource -ensure 'Absent' should install package" -test {
             Mock Invoke-Choco -ModuleName 'cChocoPackageInstall'`
                        -MockWith {
                            return [pscustomobject]@{
                                'Output'  = @('output');
                                'Success' = $true;
                            }
                        }`
                        -ParameterFilter { -not (Compare-Object $Parameters "uninstall", "GoogleChrome", "-y") }`
                        -Verifiable
            Set-TargetResource @Scenario2
            Assert-VerifiableMocks
        }

        $Scenario3 = @{
            Name    = 'GoogleChrome'
            Ensure  = 'Present'
            Version = '1.0.0'
        }
        
        It -name "Test-TargetResource -ensure 'Present' -version '1.0.0' should return True" -test {
            Test-TargetResource @Scenario3 | Should Be $True
        }

        $Scenario4 = @{
            Name    = 'GoogleChrome'
            Ensure  = 'Present'
            Version = '1.0.1'
        }
        
        It -name "Test-TargetResource -ensure 'Present' -version '1.0.1' should return False" -test {
            Test-TargetResource @Scenario4 | Should Be $False
        }
    }
}

#Clean-up
Remove-Module cChocoPackageInstall