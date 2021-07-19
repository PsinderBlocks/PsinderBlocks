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
    BeforeAll {
        $AddCodeFunctionFilePath = Join-Path -Path $ProjectRoot -ChildPath 'Source' -AdditionalChildPath 'Private', 'Add-Code.ps1'
        . $AddCodeFunctionFilePath
        Mock -CommandName Add-Code

        [System.Collections.Generic.List[string]]$Array = @()
        $FixtureFormPath = Join-Path -Path $ProjectRoot -ChildPath 'Tests' -AdditionalChildPath 'Fixtures', 'Form.xml'
        $FixtureTemplatePath = Join-Path -Path $ProjectRoot -ChildPath 'Tests' -AdditionalChildPath 'Fixtures', 'Template.xml'
        $Parameters = @{
            Array    = $Array
            Form     = Import-Clixml -Path $FixtureFormPath
            Template = Import-Clixml -Path $FixtureTemplatePath
        }
        Add-CommentBasedHelp @Parameters
    }
    It 'Opens with a comment block' {
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq '<#'
        }
    }
    It 'Adds the synopsis' {
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq '.SYNOPSIS'
        }
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq $Parameters.Form.HelpInfo.Synopsis
        }
    }
    It 'Adds the description' {
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq '.DESCRIPTION'
        }
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq $Parameters.Form.HelpInfo.Description.Text
        }
    }
    It 'Adds the inputs' {
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq '.INPUTS'
        }
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq $Parameters.Template.HelpInfo.InputTypes.InputType.Type.Name
        }
    }
    It 'Adds the outputs' {
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq '.OUTPUTS'
        }
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq $Parameters.Template.HelpInfo.ReturnValues.ReturnValue.Type.Name
        }
    }
    It 'Adds the component' {
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq '.COMPONENT'
        }
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq 'PsinderBlock'
        }
    }
    It 'Adds the functionality keys from the Form' {
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq '.FUNCTIONALITY'
        }
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq $Parameters.Form.HelpInfo.Functionality
        }
    }
    It 'Adds the Form notes' {
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq '.NOTES'
        }
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq $Parameters.Form.HelpInfo.AlertSet.Alert.Text
        }
    }
    It 'Ends the comment block' {
        Should -Invoke Add-Code -Scope Describe -ParameterFilter {
            $Value -eq '#>'
        }
    }
    Context 'Parameters' {
        BeforeDiscovery {
            $FormParameters = @(
                @{
                    Name        = 'TimeZoneId'
                    Description = 'Specify the TimeZone by ID'
                }
            )
            $StandardParameters = @(
                @{
                    Name      = 'Action'
                    FirstLine = 'The action to take:'
                }
                @{
                    Name      = 'Force'
                    FirstLine = 'Skip all confirmation messages and change state if needed.'
                }
                @{
                    Name      = 'PassThru'
                    FirstLine = 'Return the output from calling the `Set` Action;'
                }
            )
        }
        It 'Adds the help for the Form param "<Name>"' -Foreach $FormParameters {
            Should -Invoke Add-Code -Scope Describe -ParameterFilter {
                $Value -eq ".PARAMETER $Name"
            }
            Should -Invoke Add-Code -Scope Describe -ParameterFilter {
                $Value -eq $Description
            }
        }
        It 'Adds the help for the standard param "<Name>"' -Foreach $StandardParameters {
            Should -Invoke Add-Code -Scope Describe -ParameterFilter {
                $Value -eq ".PARAMETER $Name"
            }
            Should -Invoke Add-Code -Scope Describe -ParameterFilter {
                $Value[0] -eq $FirstLine
            }
        }
    }
    Context 'Examples' {
        BeforeDiscovery {
            $MinimumParamterExamples = @(
                @{
                    Name      = 'Get action'
                    # This trailing space needs to be cleared 🤔
                    Code      = '.\PsinderBlock.TimeZone.ps1 -Action Get '
                    BodyMatch = 'Get-PsinderBlockResource'
                }
                @{
                    Name      = 'Test action'
                    Code      = ".\PsinderBlock.TimeZone.ps1 -Action Test -TimeZoneId 'Central Standard Time'"
                    BodyMatch = 'Test-PsinderBlockResource'
                }
                @{
                    Name      = 'unforced Set action'
                    Code      = ".\PsinderBlock.TimeZone.ps1 -Action Set -TimeZoneId 'Central Standard Time'"
                    BodyMatch = 'Because the `Force` switch was not specified'
                }
                @{
                    Name      = 'forced Set action'
                    Code      = ".\PsinderBlock.TimeZone.ps1 -Action Set -Force -TimeZoneId 'Central Standard Time'"
                    BodyMatch = 'Because the `Force` switch was specified'
                }
            )
            $FormSpecificExamples = @(
                @{
                    Name      = 'arbitrary'
                    Code      = ".\PsinderBlock.TimeZone.ps1 -Action Set -TimeZoneId 'foo' -Force -PassThru"
                    BodyMatch = 'A custom example'
                }
            )
        }
        It 'Adds the minimum parameter example for the <Name>' -Foreach $MinimumParamterExamples {
            Should -Invoke Add-Code -Scope Describe -ParameterFilter {
                $Value -eq $Code
            }
            Should -Invoke Add-Code -Scope Describe -ParameterFilter {
                $Value -match $BodyMatch
            }
        }
        It 'Adds the specific Form example: <Name>' -Foreach $FormSpecificExamples {
            Should -Invoke Add-Code -Scope Describe -ParameterFilter {
                $Value -eq $Code
            }
            Should -Invoke Add-Code -Scope Describe -ParameterFilter {
                $Value -match $BodyMatch
            }
        }
    }
}