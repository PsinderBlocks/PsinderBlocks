Function Get-ChangeSetCodeBlock {
    [CmdletBinding()]
    Param (
        [pscustomobject[]]$ChangeSet
    )

    begin {
        [System.Collections.Generic.List[string]]$FullChangeBlock = @()
    }

    process {
        ForEach ($ChangeBlock in $ChangeSet) {
            $ShouldProcessConditional = "`$PSCmdlet.ShouldProcess($($ChangeBlock.Target.ToString().Trim()), $($ChangeBlock.Message.ToString().Trim()))"
            Write-Verbose $ShouldProcessConditional
            Add-Code -Array $FullChangeBlock -IndentLevel 0 -Value "If (`$Force -or $ShouldProcessConditional) {"
            $ChangeCode = Get-TrimmedScriptBlockText -ScriptBlock $ChangeBlock.Change -TrimSurroundingBlankLines
            $ChangeCode = $ChangeCode -Split "`n" | ForEach-Object -Process { Add-Code -Array $FullChangeBlock -Value $_ -IndentLevel 1 }
            Add-Code -Array $FullChangeBlock -IndentLevel 0 -Value '}'
        }
        $FullChangeBlock -join "`n"
    }

    end {}
}
