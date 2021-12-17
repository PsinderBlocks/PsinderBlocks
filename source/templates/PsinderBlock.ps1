<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    MINIMAL GET PARAMETERS:
.EXAMPLE
    MINIMAL TEST PARAMETERS: SomeProperty 'Central Standard Time'
.EXAMPLE
    MINIMAL SET PARAMETERS: SomeProperty 'Central Standard Time'
.NOTES
    Any additional notes
#>
[PsinderBlockScript(
    # SingleInstance,
    # Modules = 'ModuleName>=x.y.z'
)]
param(
    [PsinderBlockParameter(ExcludeForGet, MandatoryFor = ('Test', 'Set'))]
    # Comment based help for SomeProperty
    [string]$SomeProperty
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
            Message = { "Changing TimeZoneId from $($PropertyInfo.TimeZoneId.CurrentState) to $($TimeZoneId)" }
            Change  = {
                # Use a Try/Catch if you need to do specific error handling;
                # Otherwise just let it throw an exception on an error
                Set-TimeZone -Id $TimeZoneId -ErrorAction Stop -Confirm:$false
            }
        }
    )
}
