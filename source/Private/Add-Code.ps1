Function Add-Code {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        # Wish there was a generic enumerable 🤔
        [object]$Array,
        [string[]]$Value,
        [int]$IndentLevel,
        [switch]$AppendNewLine,
        [switch]$PrependNewLine
    )

    begin {}

    process {
        If ($PrependNewLine) { $Array.Add('') }
        foreach ($Entry in $Value) {
            $Entry -split "`n" | ForEach-Object -Process {
                $LineEntry = "$('    ' * $IndentLevel)$_"
                $Array.Add($LineEntry)
            }
        }
        If ($AppendNewLine) { $Array.Add('') }
    }

    end {}
}