<#
.SYNOPSIS
    Manage the TimeZone of a node by ID
.DESCRIPTION
    Manage the TimeZone of a node by ID
.FUNCTIONALITY
    TimeZone
.EXAMPLE
    MINIMAL GET PARAMETERS:
.EXAMPLE
    MINIMAL TEST PARAMETERS: -TimeZoneId 'Central Standard Time'
.EXAMPLE
    MINIMAL SET PARAMETERS: -TimeZoneId 'Central Standard Time'
.EXAMPLE
    -Action Set -TimeZoneId 'foo' -Force -PassThru

    A custom example showing and explaining bevarior. Always and only include
    parameters on the first line, not how to call the script.
.NOTES
    To see the list of available timezones on a machine, run:

    ```powershell
    Get-TimeZone -ListAvailable
    ```
#>
[PsinderBlockScript(
    SingleInstance,
    Modules = 'Microsoft.PowerShell.Management>=3.1.0.0'
)]
param(
    [ValidateScript( {
            $_ -in (Get-TimeZone -ListAvailable).Id
        })]
    [ArgumentCompleter( {
            param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            Get-TimeZone -ListAvailable | ForEach-Object -Process { $_.Id }
        })]
    [PsinderBlockParameter(ExcludeForGet, MandatoryFor = ('Test', 'Set'))]
    # Specify the TimeZone by ID
    [string]$TimeZoneId
)

[pscustomobject]@{
    GetScriptBlock  = {
        $TimeZoneInfo = Get-TimeZone -ErrorAction Stop
        $CurrentState.TimeZoneId = $TimeZoneInfo.Id
    }
    TestScriptBlock = {
        if ($CurrentState.TimeZoneId -ne $TimeZoneId) {
            $Result.InDesiredState = $false

            $Result.Properties.TimeZoneId = @{
                CurrentState = $CurrentState.TimeZoneId
                DesiredState = $TimeZoneId
            }
        }
    }
    ChangeSet       = @(
        # PsinderBlock Changes are inserted into the script in the order they are defined;
        # You need to have at least one of them.
        # This example would generate the following code:
        #     if ($Force -or $PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Changing TimeZoneId from $($PropertyInfo.TimeZoneId.CurrentState) to $($TimeZoneId)")) {
        #         Set-TimeZone -Id $TimeZoneId -ErrorAction Stop -Confirm:$false
        #     }
        [pscustomobject]@{
            Target  = { $env:COMPUTERNAME }
            Message = { "Changing TimeZoneId from $($PropertyInfo.TimeZoneId.CurrentState) to $TimeZoneId" }
            Change  = {
                # Use a Try/Catch if you need to do specific error handling;
                # Otherwise just let it throw an exception on an error
                Set-TimeZone -Id $TimeZoneId -ErrorAction Stop -Confirm:$false
            }
        }
    )
}
