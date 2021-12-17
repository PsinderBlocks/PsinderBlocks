function Add-CommentBasedHelp {
    [CmdletBinding()]
    param (
        $Array,
        $Form,
        $Template
    )

    begin {
        $PsinderBlockName = "PsinderBlock.$($Form.ScriptInfo.Name)"
    }

    process {
        # Open the Comment-Based Help
        Add-Code -Array $Array -IndentLevel 0 -Value '<#' -PrependNewLine
        #Synopsis
        Add-Code -Array $Array -IndentLevel 1 -Value '.SYNOPSIS'
        Add-Code -Array $Array -IndentLevel 2 -Value $Form.HelpInfo.Synopsis
        #Description
        Add-Code -Array $Array -IndentLevel 1 -Value '.DESCRIPTION'
        Add-Code -Array $Array -IndentLevel 2 -Value $Form.HelpInfo.Description.Text
        #Parameters
        ForEach ($ParameterHelp in $Form.HelpInfo.Parameters.Parameter) {
            Add-Code -Array $Array -IndentLevel 1 -Value ".PARAMETER $($ParameterHelp.Name)"
            $ParameterText = $ParameterHelp.description.text -join "`n`n"
            Add-Code -Array $Array -IndentLevel 2 -Value ($ParameterText -split "`n")
        }
        ForEach ($ParameterHelp in $Template.HelpInfo.Parameters.Parameter) {
            $ParameterText = $ParameterHelp.description.text -join "`n`n"
            If (![string]::IsNullOrEmpty($ParameterText)) {
                Add-Code -Array $Array -IndentLevel 1 -Value ".PARAMETER $($ParameterHelp.Name)"
                Add-Code -Array $Array -IndentLevel 2 -Value ($ParameterText -split "`n")
            }
        }
        #Inputs
        Add-Code -Array $Array -IndentLevel 1 -Value '.INPUTS'
        Add-Code -Array $Array -IndentLevel 2 -Value $Template.HelpInfo.InputTypes.InputType.Type.Name
        #Outputs
        Add-Code -Array $Array -IndentLevel 1 -Value '.OUTPUTS'
        Add-Code -Array $Array -IndentLevel 2 -Value $Template.HelpInfo.ReturnValues.ReturnValue.Type.Name
        #Component
        Add-Code -Array $Array -IndentLevel 1 -Value '.COMPONENT'
        Add-Code -Array $Array -IndentLevel 2 -Value 'PsinderBlock'
        #Functionality
        Add-Code -Array $Array -IndentLevel 1 -Value '.FUNCTIONALITY'
        Add-Code -Array $Array -IndentLevel 2 -Value $Form.HelpInfo.Functionality
        # Examples
        ForEach ($Action in @('Get', 'Test', 'Set')) {
            $Parameters = $Form.HelpInfo.examples.example.code |
                Where-Object -FilterScript { $_ -match "MINIMAL $Action PARAMETERS:" }
            $Parameters = ($Parameters -split ':')[-1].trim()
            $TemplateExamples = $Template.HelpInfo.examples.example |
                Where-Object -FilterScript { $_.code -match "MINIMAL_${Action}_PARAMETERS" }
            $TemplateExamples | ForEach-Object -Process {
                $ExampleCode = $_.code -replace 'SCRIPTNAME.ps1', $PsinderBlockName
                $ExampleCode = $ExampleCode -replace "MINIMAL_${Action}_PARAMETERS", $Parameters
                $ExampleRemarks = ($_.remarks.text -join "`n").trim() -split "`n"
                Add-Code -Array $Array -IndentLevel 1 -Value '.EXAMPLE'
                Add-Code -Array $Array -IndentLevel 2 -Value $ExampleCode -AppendNewLine
                Add-Code -Array $Array -IndentLevel 2 -Value $ExampleRemarks
            }
        }
        $FormExamples = $Form.HelpInfo.examples.example |
            Where-Object -FilterScript { $_.code -notmatch 'MINIMAL \w+ PARAMETERS:' }
        ForEach ($Example in $FormExamples) {
            $ExampleCode = ".\$PsinderBlockName $($Example.code.trim())"
            $ExampleRemarks = ($Example.remarks.text -join "`n").trim() -split "`n"
            Add-Code -Array $Array -IndentLevel 1 -Value '.EXAMPLE'
            Add-Code -Array $Array -IndentLevel 2 -Value $ExampleCode -AppendNewLine
            Add-Code -Array $Array -IndentLevel 2 -Value $ExampleRemarks
        }
        #Notes
        Add-Code -Array $Array -IndentLevel 1 -Value '.NOTES'
        Add-Code -Array $Array -IndentLevel 2 -Value $Form.HelpInfo.AlertSet.Alert.Text
        # Close the Comment-Based Help
        Add-Code -Array $Array -IndentLevel 0 -Value '#>' -AppendNewLine
    }

    end {
    }
}