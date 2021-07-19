<#
.PARAMETER Force
    Skip all confirmation messages and change state if needed.
    Ignored if the Action is `Get`, `Test`, or `LoadOnly`.
.PARAMETER PassThru
    Return the output from calling the `Set` Action;
    by default it does not return anything to the pipeline.
    Ignored if the Action is `Get`, `Test`, or `LoadOnly`.
.PARAMETER Action
    The action to take:
    - `Get` retrieves the current state of the resource.
    - `Test` compares the current state of the resource to the desired state,
        using the properties specified in the script call.
    - `Set` compares the current state of the resource to the desired state,
        using the properties specified in the script call; if the resource is
        **not** in the desired state, the script will attempt to set it to the
        defined desired state.
    - `LoadOnly` does not perform any actions on the system except to load the
        `*-PsinderBlockResource` functions into memory. **Note:** hey are only made available to
        the calling scope if the script is dot-sourced.
.EXAMPLE
    .\SCRIPTNAME.ps1 -Action Get MINIMAL_GET_PARAMETERS

    This call will execute the `Get-PsinderBlockResource` private function to return the
    current state of the resource on the node.
.EXAMPLE
    .\SCRIPTNAME.ps1 -Action Test MINIMAL_TEST_PARAMETERS

    This call will execute the `Test-PsinderBlockResource` private function to
    validate whether the current state of the resource on the node matches the
    desired state. If the properties specified in the script are equal to the
    current state of the resource, the return object will have the
    `InDesiredState` property set to `$true`.

    If the current state is anything else, the return object will have the
    `InDesiredState` property set to `$false` and the `Properties` property set
    to a hashtable with a key for each specified property; those keys will all
    have their value as a hashtable representing that property's `CurrentState`
    and `DesiredState`.
.EXAMPLE
    .\SCRIPTNAME.ps1 -Action Set MINIMAL_SET_PARAMETERS

    This call will execute the `Set-PsinderBlockResource` private function to ensure the
    desired state of the resource, changing state *only* if the resource is not
    already in the desired state. Because the `Force` switch was not specified,
    it will prompt the user for confirmation before changing system state. Because
    the `PassThru` switch was not specified, it will not return any output.
.EXAMPLE
    .\SCRIPTNAME.ps1 -Action Set -Force MINIMAL_SET_PARAMETERS

    This call will execute the `Set-PsinderBlockResource` private function to ensure the
    desired state of the resource, changing state *only* if the resource is not
    already in the desired state. Because the `Force` switch was specified, it will
    **not** prompt the user for confirmation before changing system state. Because
    the `PassThru` switch was not specified, it will not return any output.
.EXAMPLE
    .\SCRIPTNAME.ps1 -Action LoadOnly

    This call will load the `Get-PsinderBlockResource`, `Test-PsinderBlockResource`, and
    `Set-PsinderBlockResource` functions into the current scope. This is useful for
    testing the functions and validating behavior outside of the script.
.INPUTS
    None. You cannot pipe objects to this script.
.OUTPUTS
    PSCustomObject. With the `Get` action, returns an object representing the
    current state of all retrievable properties for the resource.

    PSCustomObject. With the `Test` action, returns an object with the
    `InDesiredState` property which is set to `$true` if all specified
    properties are in the desired state and otherwise `$false`. If the
    `InDesiredState` property is `$false`, it also includes the `Properties`
    property, which is a hashtable where each property specified in the
    script is a key whose value is a hashtable representing the `CurrentState`
    and `DesiredState` of the specified property.

    PSCustomObject. With the `Set` action and the `PassThru` switch, returns
    the same output as from the `Test` action though with the `InDesiredState`
    property overridden to `$true` if no errors were raised when setting the
    resource to the desired state.
#>

[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $true)]
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
            #region PsinderBlock Resource Properties
            #endregion
        )

        begin {
            $Result = @{
                InDesiredState = $true
                Properties     = @{}
            }
        }

        process {
            $ValidGetParameters = Get-Command -Name Get-PsinderBlockResource | Select-Object -ExpandProperty Parameters
            $ParametersToRemove = $PSBoundParameters.Keys | Where-Object -FilterScript { $_ -notin $ValidGetParameters.Keys }
            $ParametersToRemove | ForEach-Object -Process { $null = $PSBoundParameters.Remove($_) }
            $CurrentState = Get-PsinderBlockResource @PSBoundParameters
            #region Test Logic from PsinderBlock
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
            #region PsinderBlock Resource Properties
            #endregion
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
                    #region Set Logic from PsinderBlock
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
            $ValidGetParameters = Get-Command -Name Get-PsinderBlockResource | Select-Object -ExpandProperty Parameters
            $ParametersToRemove = $PSBoundParameters.Keys | Where-Object -FilterScript { $_ -notin $ValidGetParameters.Keys }
            $ParametersToRemove | ForEach-Object -Process { $null = $PSBoundParameters.Remove($_) }
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
