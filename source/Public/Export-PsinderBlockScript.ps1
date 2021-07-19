function Export-PsinderBlockScript {
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ParameterSetName = 'ByPsinderBlock')]
        [PSCustomObject]$PsinderBlock,
        [parameter(Mandatory, ParameterSetName = 'ByPsinderBlockPath')]
        [string]$PsinderBlockPath,
        [parameter(Mandatory, ParameterSetName = 'ByPsinderBlock')]
        [parameter(Mandatory, ParameterSetName = 'ByPsinderBlockPath')]
        [string]$ScriptPath
    )

    begin {
        $SourceFolder = Split-Path -Path $PSScriptRoot -Parent
        # $SourceFolder = $PSScriptRoot
        # ?????
        $TemplateFolder = Join-Path -Path $SourceFolder -ChildPath 'Templates'
        $PsinderBlockTemplate = [PSCustomObject]@{
            ScriptInfo = (Get-Command -Name "$TemplateFolder/PsinderBlockScript.ps1")
            HelpInfo   = (Get-Help -Name "$TemplateFolder/PsinderBlockScript.ps1" -Full)
        }
        [System.Collections.Generic.List[string]]$PsinderBlockResource = @()
    }

    process {
        if ($null -eq $PsinderBlock) {
            $PsinderBlock = Get-PsinderBlockForm -Path $PsinderBlockPath
        }
        #region Handle Requires
        Add-RequiresBlock -Array $PsinderBlockResource -Form $PsinderBlock
        #endregion
        #region Handle Using
        # NOT IMPLEMENTED
        #endregion
        #region Handle Help
        Add-CommentBasedHelp -Array $PsinderBlockResource -Form $PsinderBlock -Template $PsinderBlockTemplate
        #endregion
        #region Handle Parameters
        # TODO: Handle ConfirmImpact, HelpURI, SupportsPaging
        Add-Code -Array $PsinderBlockResource -IndentLevel 0 -Value '[CmdletBinding(SupportsShouldProcess)]'
        Add-Code -Array $PsinderBlockResource -IndentLevel 0 -Value '[OutputType([PSCustomObject])]'
        Add-Code -Array $PsinderBlockResource -IndentLevel 0 -Value 'param('
        Add-Code -Array $PsinderBlockResource -IndentLevel 1 -Value '#region PsinderBlock Resource Properties'
        $PsinderBlockParams = Get-ParamBlockCode -ParamAst $PsinderBlock.ScriptInfo.ScriptBlock.Ast.ParamBlock -AppendTrailingComma
        Add-Code -Array $PsinderBlockResource -IndentLevel 1 -Value ($PsinderBlockParams -split "`n")
        Add-Code -Array $PsinderBlockResource -IndentLevel 1 -Value '#endregion'
        $TemplateParams = Get-ParamBlockCode -ParamAst $PsinderBlockTemplate.ScriptInfo.ScriptBlock.Ast.ParamBlock
        Add-Code -Array $PsinderBlockResource -IndentLevel 1 -Value ($TemplateParams -split "`n")
        Add-Code -Array $PsinderBlockResource -IndentLevel 0 -Value ')' -AppendNewLine
        #endregion
        #region Begin Block
        Add-Code -Array $PsinderBlockResource -IndentLevel 0 -Value 'begin {'
        #region Handle Functions
        $ResourceFunctionDeclarations = $PsinderBlockTemplate.ScriptInfo.ScriptBlock.Ast.BeginBlock.Statements
        foreach ($Function in $ResourceFunctionDeclarations) {
            $FunctionInfo = $Function | Select-Object -Property Name, Parameters, Body
            $FunctionAction = $Function.Name -split '-' | Select-Object -First 1
            Add-FunctionDeclaration -FunctionInfo $FunctionInfo -FunctionAction $FunctionAction -Array $PsinderBlockResource
        }
        #endregion
        Add-Code -Array $PsinderBlockResource -IndentLevel 0 -Value '}' -AppendNewLine
        #endregion
        #region Process Block
        $ScriptProcessBlockCode = $PsinderBlockTemplate.ScriptInfo.ScriptBlock.Ast.ProcessBlock.Extent.Text
        Add-Code -Array $PsinderBlockResource -IndentLevel 0 -Value $ScriptProcessBlockCode -AppendNewLine
        #endregion
        #region End BLock
        $ScriptEndBlockCode = $PsinderBlockTemplate.ScriptInfo.ScriptBlock.Ast.EndBlock.Extent.Text
        Add-Code -Array $PsinderBlockResource -IndentLevel 0 -Value $ScriptEndBlockCode
        #endregion
        # Export the script to disk
        $FormattedPsinderBlockResource = Invoke-Formatter -ScriptDefinition ($PsinderBlockResource -join "`n")
        $FormattedPsinderBlockResource | Out-File -FilePath $ScriptPath -Force
    }

    end {}
}
