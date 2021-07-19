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
        BeforeEach {
            [System.Collections.Generic.List[string]]$Array = @()
        }

        It 'Returns no output itself' {
            Add-Code -Array $Array -Value 'Line One' | Should -BeNullOrEmpty
        }

        It 'Adds strings to an array' {
            Add-Code -Array $Array -Value 'Line One', 'Line Two'
            $Array | Should -Be @('Line One', 'Line Two')
        }

        It 'Indents strings four spaces per indent level' {
            Add-Code -Array $Array -Indent 1 -Value 'Line One'
            Add-Code -Array $Array -Indent 2 -Value 'Line Two'
            $Array[0] | Should -Be '    Line One'
            $Array[1] | Should -Be '        Line Two'
        }

        It 'Prepends a newline if specified' {
            Add-Code -Array $Array -PrependNewLine -Value 'Line One'
            $Array[0] | Should -Be ''
            $Array[1] | Should -Be 'Line One'
        }

        It 'Appends a newline if specified' {
            Add-Code -Array $Array -AppendNewLine -Value 'Line One'
            $Array[0] | Should -Be 'Line One'
            $Array[1] | Should -Be ''
        }
    }
}