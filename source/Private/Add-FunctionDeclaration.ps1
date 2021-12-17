function Add-FunctionDeclaration {
  [CmdletBinding()]
  param (
    $FunctionInfo,
    $FunctionAction,
    $Array
  )

  begin {

  }

  process {
    Add-Code -Array $Array -IndentLevel 1 -Value "Function $($FunctionInfo.Name) {"
    #region Function Param Block
    switch ($FunctionAction) {
      'Set' {
        Add-Code -Array $Array -IndentLevel 2 -Value '[CmdletBinding(SupportsShouldProcess)]'
      }
      Default {
        Add-Code -Array $Array -IndentLevel 2 -Value '[CmdletBinding()]'
      }
    }
    Add-Code -Array $Array -IndentLevel 2 -Value '[OutputType([PSCustomObject])]'
    Add-Code -Array $Array -IndentLevel 2 -Value 'param('
    $FunctionParams = Get-ParamBlockCode -ParamAst $PsinderBlock.ScriptInfo.ScriptBlock.Ast.ParamBlock -Action $FunctionAction
    Add-Code -Array $Array -IndentLevel 3 -Value $FunctionParams
    If ($FunctionAction -eq 'Set') {
      $SetFunctionParams = Get-ParamBlockCode -ParamAst $PsinderBlockTemplate.ScriptInfo.ScriptBlock.Ast.ParamBlock |
        Where-Object -FilterScript { $_ -notmatch '\$Action' }
      Add-Code -Array $Array -IndentLevel 3 -Value $SetFunctionParams
    }
    Add-Code -Array $Array -IndentLevel 2 -Value ')' -AppendNewLine
    #endregion
    #region Function Begin Block
    Add-Code -Array $Array -IndentLevel 2 -Value $FunctionInfo.Body.BeginBlock.Extent.Text -AppendNewLine
    #endregion
    #region Function Process Block
    $ProcessBlockCode = $Function.Body.ProcessBlock.Extent.Text
    $RegionLine = "#region $FunctionAction Logic from PsinderBlock"
    switch ($FunctionAction) {
      'Set' {
        $FunctionActionScriptBlock = Get-ChangeSetCodeBlock -ChangeSet $PsinderBlock.ChangeSet
      }
      Default {
        $FunctionActionScriptBlock = Get-TrimmedScriptBlockText -ScriptBlock $PsinderBlock."${FunctionAction}ScriptBlock"
      }
    }
    $InsertCodeBlock = $RegionLine, $FunctionActionScriptBlock -join "`n"
    $ProcessBlockBody = $ProcessBlockCode -replace $RegionLine, $InsertCodeBlock
    Add-Code -Array $Array -IndentLevel 2 -Value ($ProcessBlockBody -split "`n")
    #endregion
    #region Function End Block
    Add-Code -Array $Array -IndentLevel 2 -Value $FunctionInfo.Body.EndBlock.Extent.Text
    #endregion
    Add-Code -Array $Array -IndentLevel 1 -Value '}'
  }

  end {

  }
}