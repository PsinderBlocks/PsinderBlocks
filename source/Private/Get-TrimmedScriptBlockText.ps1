Function Get-TrimmedScriptBlockText {
    [CmdletBinding()]
    Param(
        [string]$ScriptBlock,
        [switch]$TrimSurroundingBlankLines
    )

    begin {
        [System.Collections.Generic.List[string]]$TrimmedLines = @()
    }

    process {
        $Lines = $ScriptBlock -split "`n"
        # Ensure only unneccessary leading whitespace is stripped so whitespace
        # necessary for making blocks easier to read isn't removed
        $FirstLineWithText = $Lines -match '\S' | Select-Object -First 1
        $null = $FirstLineWithText -match '(?<LeadingWhiteSpace>^\s+)'
        # Using Pattern.Replace() ensures we only strip the desired lead spaces
        [regex]$Pattern = $Matches.LeadingWhiteSpace
        $Lines | ForEach-Object -Process { $TrimmedLines.Add($Pattern.Replace($_.TrimEnd(), '', 1)) }
        # Recombine as a single block with newlines
        If ($TrimSurroundingBlankLines) {
            If ([string]::IsNullOrEmpty($TrimmedLines[0])) { $TrimmedLines.RemoveAt(0) }
            If ([string]::IsNullOrEmpty($TrimmedLines[-1])) { $TrimmedLines.RemoveAt(($TrimmedLines.Count - 1)) }
        }
        $TrimmedLines -join "`n"
    }

    end {}
}
