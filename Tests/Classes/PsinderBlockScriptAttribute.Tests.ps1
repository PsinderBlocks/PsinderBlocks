BeforeDiscovery {
  $ProjectRoot = Split-Path -Path $PSScriptRoot -Parent |
    Split-Path -Parent
  $RelativeSourceFilePath = $PSCommandPath.Substring($ProjectRoot.Length) -Replace 'Tests(\.|\\)*', ''
  $SourceFilePath = Join-Path -Path $ProjectRoot -ChildPath 'Source' -AdditionalChildPath $RelativeSourceFilePath
  $TestTargetName = Split-Path $SourceFilePath -LeafBase
}

BeforeAll {
  $ProjectRoot = Split-Path -Path $PSScriptRoot -Parent |
    Split-Path -Parent
  $RelativeSourceFilePath = $PSCommandPath.Substring($ProjectRoot.Length) -Replace 'Tests(\.|\\)*', ''
  $SourceFilePath = Join-Path -Path $ProjectRoot -ChildPath 'Source' -AdditionalChildPath $RelativeSourceFilePath
  . $SourceFilePath
}

Describe $TestTargetName {
  Context 'Basic Functionality' {
    It 'Loads without error' {
      [PsinderBlockScriptAttribute] | Should -Not -BeNullOrEmpty
    }

    Context 'when declared without parameters' {
      BeforeAll {
        Function Test-EmptyAttribute {
          [PsinderBlockScript()]
          Param()
        }
        $TestEmptyAttribute = (Get-Command Test-EmptyAttribute).ScriptBlock.Attributes |
          Where-Object -FilterScript { $_.TypeID.Name -eq 'PsinderBlockScriptAttribute' }
      }

      It 'Defaults <Parameter> to <ValueString>' -ForEach @(
        @{
          Parameter   = 'PowerShellVersion'
          ValueString = '"5.1"'
          Value       = '5.1'
        }
        @{
          Parameter   = 'SingleInstance'
          ValueString = '$false'
          Value       = $false
        }
        @{
          Parameter   = 'RunAsAdministrator'
          ValueString = '$false'
          Value       = $False
        }
      ) {
        $TestEmptyAttribute.$Parameter | Should -Be $Value
      }

      It 'Does not set <_>' -ForEach @('PSEdition', 'Assemblies', 'Modules') {
        $TestEmptyAttribute.$_ | Should -BeNullOrEmpty
      }
    }

    Context 'when declared with valid parameters' {
      BeforeAll {
        Function Test-FullAttribute {
          [PsinderBlockScript(
            PowerShellVersion = '7.1',
            SingleInstance,
            RunAsAdministrator,
            PSEdition = 'Core',
            Assemblies = 'C:\foo.dll',
            Modules = ('Foo>=1.2.3', 'Bar==3.2.1')
          )]
          Param()
        }
        $TestFullAttribute = (Get-Command Test-FullAttribute).ScriptBlock.Attributes |
          Where-Object -FilterScript { $_.TypeID.Name -eq 'PsinderBlockScriptAttribute' }
      }

      It 'sets <Parameter> to <ValueString>' -ForEach @(
        @{
          Parameter   = 'PowerShellVersion'
          ValueString = '"7.1"'
          Value       = '7.1'
        }
        @{
          Parameter   = 'SingleInstance'
          ValueString = '$true'
          Value       = $true
        }
        @{
          Parameter   = 'RunAsAdministrator'
          ValueString = '$true'
          Value       = $true
        }
        @{
          Parameter   = 'PSEdition'
          ValueString = '"Core"'
          Value       = 'Core'
        }
        @{
          Parameter   = 'Assemblies'
          ValueString = '@("C:\foo.dll")'
          Value       = @('C:\foo.dll')
        }
        @{
          Parameter   = 'Modules'
          ValueString = '@("Foo>=1.2.3", "Bar==3.2.1")'
          Value       = @('Foo>=1.2.3', 'Bar==3.2.1')
        }
      ) {
        $TestFullAttribute.$Parameter | Should -Be $Value
      }
    }
  }

  Context 'when declared with invalid parameters' {
    It 'errors' {
      {
        $ErrorActionPreference = 'Stop'
        Function Test-InvalidAttribute {
          [PsinderBlockScript(PSEdition = 'apple')]
          Param()
        }
        Test-InvalidAttribute
      } | Should -Throw 'The argument "apple" does not belong to the set*'
    }
  }
}