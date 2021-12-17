Function Get-ParamBlockCode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ParamBlockAst]$ParamAst,
        [ValidateSet('Get', 'Test', 'Set')]
        [string]$Action,
        [switch]$AppendTrailingComma
    )

    begin {}

    process {
        $Parameters = $ParamAst.Parameters.Copy()
        [System.Collections.Generic.List[string]]$Declaration = @()
        foreach ($Parameter in $Parameters) {
            $Parameter.Attributes |
                Where-Object -Property TypeName -Match 'PsinderBlockParameter' |
                Select-Object -ExpandProperty NamedArguments |
                Select-Object -Property ArgumentName, Argument |
                ForEach-Object -Process {
                    $MemberParams = @{
                        MemberType = 'NoteProperty'
                        Name       = $_.ArgumentName
                        Value      = $_.Argument.Extent.Text
                    }
                    $Parameter | Add-Member @MemberParams
                }
        }
        $ParametersToDeclare = $Parameters
        if ($Action -eq 'Get') {
            $ParametersToDeclare = $ParametersToDeclare |
                Where-Object -FilterScript { -not $_.ExcludeForGet }
        }
        # Assemble the Parameters
        foreach ($Parameter in $ParametersToDeclare) {
            [System.Collections.Generic.List[string]]$ParameterDeclaration = $Parameter.Extent.Text -split "`n" | Where-Object -FilterScript {
                $_ -notmatch 'PsinderBlockParameter' -and
                $_ -notmatch '^\s+#'
            }
            Write-Verbose $Parameter.Name
            Write-Verbose "Action: $Action"
            Write-Verbose "MandatoryFor: $($Parameter.MandatoryFor)"
            Write-Verbose ('$null -ne $Parameter.MandatoryFor = ' + ($null -ne $Parameter.MandatoryFor))
            Write-Verbose ('![string]::IsNullOrEmpty($Action) = ' + (![string]::IsNullOrEmpty($Action)))
            Write-Verbose ('$Parameter.MandatoryFor -match $Action = ' + ($Parameter.MandatoryFor -match $Action))
            If ($null -ne $Parameter.MandatoryFor -and ![string]::IsNullOrEmpty($Action) -and $Parameter.MandatoryFor -match $Action) {
                $ParameterDeclaration[0] = "    $($ParameterDeclaration[0])"
                $ParameterDeclaration.Insert(0, '[Parameter(Mandatory)]')
            }
            $Declaration.Add(($ParameterDeclaration -join "`n"))
        }
        # Return the joined string
        If ($AppendTrailingComma) {
            "$($Declaration -join ",`n"),"
        } Else {
            $Declaration -join ",`n"
        }
    }

    end {}
}
