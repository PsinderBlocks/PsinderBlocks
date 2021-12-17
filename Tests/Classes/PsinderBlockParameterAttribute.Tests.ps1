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
      [PsinderBlockParameterAttribute] | Should -Not -BeNullOrEmpty
    }
    Context 'when declared without parameters' {
      BeforeAll {
        Function Test-EmptyAttribute {
          [CmdletBinding()]
          Param(
            [PsinderBlockParameter()]$Foo
          )
        }
        $TestEmptyAttribute = (Get-Command Test-EmptyAttribute).Parameters.Foo.Attributes |
          Where-Object -FilterScript { $_.TypeID.Name -eq 'PsinderBlockParameterAttribute' }
      }
      It 'Defaults <Parameter> to <ValueString>' -ForEach @(
        @{
          Parameter   = 'ExcludeForGet'
          ValueString = '$false'
          Value       = $false
        },
        @{
          Parameter   = 'MandatoryFor'
          ValueString = 'an empty list'
          Value       = @()
        }
      ) {
        $TestEmptyAttribute.$Parameter | Should -Be $Value
      }
    }
    Context 'when declared with valid parameters' {
      BeforeAll {
        Function Test-FullAttribute {
          [CmdletBinding()]
          Param(
            [PsinderBlockParameter(ExcludeForGet, MandatoryFor = ('Test', 'Set'))]$Foo
          )
        }
        $TestFullAttribute = (Get-Command Test-FullAttribute).Parameters.Foo.Attributes |
          Where-Object -FilterScript { $_.TypeID.Name -eq 'PsinderBlockParameterAttribute' }
      }
      It 'sets <Parameter> to <ValueString>' -ForEach @(
        @{
          Parameter   = 'ExcludeForGet'
          ValueString = '$true'
          Value       = $true
        },
        @{
          Parameter   = 'MandatoryFor'
          ValueString = "@('Test', 'Set')"
          Value       = @('Test', 'Set')
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
          [CmdletBinding()]
          Param(
            [PsinderBlockParameter(MandatoryFor = ('apple'))]$Foo
          )
        }
        Test-InvalidAttribute
      } | Should -Throw 'The argument "apple" does not belong to the set*'
    }
  }
}