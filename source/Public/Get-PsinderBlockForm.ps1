Function Get-PsinderBlockForm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    begin {}

    process {
        $PsinderBlock = & $Path
        $PsinderBlock | Add-Member -MemberType NoteProperty -Name ScriptInfo -Value (Get-Command -Name $Path)
        $PsinderBlock | Add-Member -MemberType NoteProperty -Name HelpInfo -Value (Get-Help -Name $Path -Full)
        $PsinderBlock
    }

    end {}
}
