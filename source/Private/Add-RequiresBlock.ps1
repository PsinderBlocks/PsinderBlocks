function Add-RequiresBlock {
    [CmdletBinding()]
    param (
        $Array,
        $Form
    )

    begin {
        $FormMetadata = $Form.ScriptInfo.ScriptBlock.Attributes |
            Where-Object -FilterScript { $_.TypeId.Name -eq 'PsinderBlockScriptAttribute' }
    }

    process {
        If ($FormMetadata.RunAsAdministrator) {
            Add-Code -Array $Array -IndentLevel 0 -Value '#Requires -RunAsAdministrator'
        }
        If ($null -ne $FormMetadata.PowerShellVersion) {
            Add-Code -Array $Array -IndentLevel 0 -Value "#Requires -Version $($FormMetadata.PowerShellVersion)"
        }
        If ($null -ne $FormMetadata.PSEdition) {
            Add-Code -Array $Array -IndentLevel 0 -Value "#Requires -PSEdition $($FormMetadata.PSEdition)"
        }
        foreach ($AssemblyRequirement in $FormMetadata.Assemblies) {
            Add-Code -Array $Array -IndentLevel 0 -Value "#Requires -Assembly '$AssemblyRequirement'"
        }
        foreach ($ModuleRequirement in $FormMetadata.Modules) {
            if ($ModuleRequirement -notmatch '=') {
                Add-Code -Array $Array -IndentLevel 0 -Value "#Requires -Module $ModuleRequirement"
            } else {
                if ($ModuleRequirement -match '(?<ModuleName>^\S+)(?<Pin>(<|=|>)=)(?<Version>\S+$)') {
                    $ModuleName = $Matches.ModuleName
                    $Pin = switch ($Matches.Pin) {
                        '==' { 'RequiredVersion' }
                        '<=' { 'MaximumVersion' }
                        Default { 'ModuleVersion' }
                    }
                    $Version = $Matches.Version
                    Add-Code -Array $Array -IndentLevel 0 -Value "#Requires -Module @{ ModuleName = '$ModuleName'; $Pin = '$Version' }"
                } else {
                    Throw "Specified a module pin as '$ModuleRequirement' which is invalid; see docs"
                }
            }
        }
    }

    end {

    }
}