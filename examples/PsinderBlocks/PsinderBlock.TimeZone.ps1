<#
.SYNOPSIS
    Manage the TimeZone of a node by ID
.DESCRIPTION
    Manage the TimeZone of a node by ID
.FUNCTIONALITY
    TimeZone, Fuckery
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

    ```
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
    property, which is a hashtable where each property specified in the
    script is a key whose value is a hashtable representing the `CurrentState`
    and `DesiredState` of the specified property.

    PSCustomObject. With the `Set` action and the `PassThru` switch, returns
    the same output as from the `Test` action though with the `InDesiredState`
    property overridden to `$true` if no errors were raised when setting the
    resource to the desired state.
.NOTES
    To see the list of available timezones on a machine, run:

    ```
    Get-TimeZone -ListAvailable
    ```
#>

[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param(
    #region PsinderBlock Resource Properties
    [ValidateScript( {
            $_ -in (Get-TimeZone -ListAvailable).Id
        })]
    [ArgumentCompleter( {
            param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            Get-TimeZone -ListAvailable | ForEach-Object -Process { $_.Id }
        })]
    [string]$TimeZoneId,
    #endregion
    [Parameter(Mandatory)]
    [ValidateSet('Get', 'Set', 'Test', 'LoadOnly')]
    [string]$Action,
    [switch]$Force,
    [switch]$PassThru
)

begin {
    function Get-PsinderBlockResource {
        [CmdletBinding()]
        [OutputType([PSCustomObject])]
        param ()

        begin {
            $CurrentState = @{}
        }

        process {
            try {
                #region Get Logic from PsinderBlock
                $TimeZoneInfo = Get-TimeZone -ErrorAction Stop
                $CurrentState.TimeZoneId = $TimeZoneInfo.Id
                #endregion
            } catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
            [PSCustomObject]$CurrentState
        }

        end {}
    }
    function Test-PsinderBlockResource {
        [CmdletBinding()]
        [OutputType([PSCustomObject])]
        param (
            [Parameter(
                Mandatory = $true,
                HelpMessage = 'Specify the TimeZone by ID'
            )]
            [string]$TimeZoneId
        )

        begin {
            $Result = @{
                InDesiredState = $true
                Properties     = @{}
            }
        }

        process {
            $CurrentState = Get-PsinderBlockResource @PSBoundParameters
            #region Test Logic from PsinderBlock
            if ($CurrentState.TimeZoneId -ne $TimeZoneId) {
                $Result.InDesiredState = $false

                $Result.Properties.TimeZoneId = @{
                    CurrentState = $CurrentState.TimeZoneId
                    DesiredState = $TimeZoneId
                }
            }
            #endregion
            [PSCustomObject]$Result
        }

        end {}
    }

    function Set-PsinderBlockResource {
        [CmdletBinding(
            SupportsShouldProcess,
            ConfirmImpact = 'High'
        )]
        [OutputType([PSCustomObject])]
        param (
            [Parameter(
                Mandatory = $true,
                HelpMessage = 'Specify the TimeZone by ID'
            )]
            [string]$TimeZoneId,
            [switch]$Force,
            [switch]$PassThru
        )

        begin {}

        process {
            try {
                # Remove switches from calls to Test-PsinderBlockResource
                $null = $PSBoundParameters.Remove('PassThru')
                $null = $PSBoundParameters.Remove('Force')

                # Determine whether or not the resource is in the desired state
                $Result = Test-PsinderBlockResource @PSBoundParameters
                # PropertyInfo includes the current and desired state for each specified
                # property; use this to determine what changes are needed and execute them.
                $PropertyInfo = $Result.Properties
                if ($false -eq $Result.InDesiredState) {
                    #region ChangeSets from PsinderBlock
                    if ($Force -or $PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Changing TimeZoneId from $($PropertyInfo.TimeZoneId.CurrentState) to $($TimeZoneId)")) {
                        Set-TimeZone -Id $TimeZoneId -ErrorAction Stop -Confirm:$false
                    }
                    #endregion
                    # All changes made without errors, set InDesiredState to true
                    $Result.InDesiredState = $true
                }
            } catch {
                # Rethrow any exceptions from setting desired state
                $PSCmdlet.ThrowTerminatingError($_)
            } finally {
                if ($PassThru) { $Result }
            }
        }

        end {}
    }
}

process {
    $null = $PSBoundParameters.Remove('Action')
    $SwitchlessParameters = @('Get', 'Test', 'LoadOnly')
    if ($Action -in $SwitchlessParameters) {
        $ParameterRemovalBaseMessage = "Action specified as '$Action'; the specified PARAMETER switch will be ignored"
        foreach ($UnusedParameter in $SwitchlessParameters) {
            if ($PSBoundParameters.ContainsKey($UnusedParameter)) {
                Write-Warning ($ParameterRemovalBaseMessage -replace 'PARAMETER', $UnusedParameter)
                $null = $PSBoundParameters.Remove($UnusedParameter)
            }
        }
    }
    switch ($Action) {
        'Get' {
            Get-PsinderBlockResource @PSBoundParameters
        }
        'Test' {
            Test-PsinderBlockResource @PSBoundParameters
        }
        'Set' {
            Set-PsinderBlockResource @PSBoundParameters
        }
        default {
            Write-Verbose "Loading the *-PsinderBlockResource commands from $PSCommandPath into the current session"
        }
    }
}

end {
    if ('LoadOnly' -ne $Action) {
        foreach ($PsinderBlockAction in @('Get', 'Set', 'Test')) {
            Remove-Item -Path "Function:\$PsinderBlockAction-PsinderBlockResource"
        }
    }
}
