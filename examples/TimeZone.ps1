#Requires -Version 5.1
#Requires -Modules @{ ModuleName = 'Microsoft.PowerShell.Management' ; ModuleVersion = '3.1.0.0' }

<#
.SYNOPSIS
  Manage the TimeZone of a node by ID
.DESCRIPTION
  Manage the TimeZone of a node by ID
.PARAMETER TimeZoneId
  Specify the TimeZone by ID
  Mandatory for: `Test`, `Set`
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
    `*-PsinderBlock` functions into memory. **Note:** hey are only made available to
    the calling scope if the script is dot-sourced.
.PARAMETER Force
  Skip all confirmation messages and change state if needed.
  Ignored if the Action is `Get`, `Test`, or `LoadOnly`.
.PARAMETER PassThru
  Return the output from calling the `Set` Action;
  by default it does not return anything to the pipeline.
  Ignored if the Action is `Get`, `Test`, or `LoadOnly`.
.EXAMPLE
  PS C:\> .\TimeZone.ps1 -Action Get
  This call will execute the `Get-PsinderBlock` private function to return the
  current state of the resource on the node.
.EXAMPLE
  PS C:\> .\TimeZone.ps1 -Action Test -TimeZoneId 'Central Standard Time
  This call will execute the `Test-PsinderBlock` private function to validate
  whether the current state of the resource on the node matches the desired
  state. If the properties specified in the script are equal to the current
  state of the resource, the return object will have the `InDesiredState`
  property set to `$true`. If the current state is anything else, the return
  object will have the `InDesiredState` property set to `$false` and the
  `Properties` property set to a hashtable with a key for each specified
  property; those keys will all have their value as a hashtable representing
  that property's `CurrentState` and `DesiredState`.
.EXAMPLE
  PS C:\> .\TimeZone.ps1 -Action Set -TimeZoneId 'Central Standard Time
  This call will execute the `Set-PsinderBlock` private function to ensure the
  desired state of the resource, changing state *only* if the resource is not
  already in the desired state. Because the `Force` switch was not specified,
  it will prompt the user for confirmation before changing system state. Because
  the `PassThru` switch was not specified, it will not return any output.
.EXAMPLE
  PS C:\> .\TimeZone.ps1 -Action Set -TimeZoneId 'Central Standard Time -Force
  This call will execute the `Set-PsinderBlock` private function to ensure the
  desired state of the resource, changing state *only* if the resource is not
  already in the desired state. Because the `Force` switch was specified, it will
  **not** prompt the user for confirmation before changing system state. Because
  the `PassThru` switch was not specified, it will not return any output.
.EXAMPLE
  PS C:\> . .\TimeZone.ps1 -Action LoadOnly
  This call will load the `Get-PsinderBlock`, `Test-PsinderBlock`, and
  `Set-PsinderBlock` functions into the current scope. This is useful for
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

.NOTES
  To see the list of available timezones on a machine, run:

  ```
  Get-TimeZone -ListAvailable
  ```
#>

[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
  [ValidateScript( {
      $_ -in (Get-TimeZone -ListAvailable).Id
    })]
  [ArgumentCompleter( {
      Param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
      Get-TimeZone -ListAvailable | ForEach-Object -Process { $_.Id }
    })]
  [string]$TimeZoneId,
  [Parameter(Mandatory = $true)]
  [ValidateSet('Get', 'Set', 'Test', 'LoadOnly')]
  [string]$Action,
  [switch]$Force,
  [switch]$PassThru
)

begin {
  function Get-PsinderBlock {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
      [string]$TimeZoneId
    )

    begin {
      $CurrentState = @{}
    }

    process {
      try {
        $CurrentState.TimeZoneId = Get-TimeZone -ErrorAction Stop | Select-Object -ExpandProperty Id
      } catch {
        $PSCmdlet.ThrowTerminatingError($_)
      }
      [PSCustomObject]$CurrentState
    }

    end {}
  }
  function Test-PsinderBlock {
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
      $CurrentState = Get-PsinderBlock @PSBoundParameters
      if ($CurrentState.TimeZoneId -ne $TimeZoneId) {
        $Result.InDesiredState = $false

        $Result.Properties.TimeZoneId = @{
          CurrentState = $CurrentState.TimeZoneId
          DesiredState = $TimeZoneId
        }
      }
      [PSCustomObject]$Result
    }

    end {}
  }

  function Set-PsinderBlock {
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
      # Remove switches from calls to Test-PsinderBlock
      $null = $PSBoundParameters.Remove('PassThru')
      $null = $PSBoundParameters.Remove('Force')

      # Determine whether or not the resource is in the desired state
      $TestResult = Test-PsinderBlock @PSBoundParameters

      if ($false -eq $TestResult.InDesiredState) {
        # PropertyInfo includes the current and desired state for each specified
        # property; use this to determine what changes are needed and execute them.
        $PropertyInfo = $TestResult.Properties
        if ($Force -or $PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Changing TimeZoneId from $($PropertyInfo.TimeZoneId.CurrentState) to $($TimeZoneId)")) {
          try {
            Set-TimeZone -Id $TimeZoneId -ErrorAction Stop -Confirm:$false
            # All changes made without errors, set InDesiredState to true
            $TestResult.InDesiredState = $true
          } catch {
            # Rethrow any exceptions from setting desired state
            $PSCmdlet.ThrowTerminatingError($_)
          } finally {
            If ($PassThru) {
              $TestResult
            }
          }
        }
      }
    }

    end {}
  }
}

# Nothing in this process block should be edited by the PsinderBlock Script author
# All custom logic should be contained in the *-PsinderBlock private functions above.
process {
  $null = $PSBoundParameters.Remove('Action')
  $SwitchlessParameters = @('Get', 'Test', 'LoadOnly')
  If ($Action -in $SwitchlessParameters) {
    $ParameterRemovalBaseMessage = "Action specified as '$Action'; the specified PARAMETER switch will be ignored"
    ForEach ($UnusedParameter in $SwitchlessParameters) {
      If ($PSBoundParameters.ContainsKey($UnusedParameter)) {
        Write-Warning ($ParameterRemovalBaseMessage -replace 'PARAMETER', $UnusedParameter)
        $null = $PSBoundParameters.Remove($UnusedParameter)
      }
    }
  }
  switch ($Action) {
    'Get' {
      Get-PsinderBlock @PSBoundParameters
    }
    'Test' {
      Test-PsinderBlock @PSBoundParameters
    }
    'Set' {
      Set-PsinderBlock @PSBoundParameters
    }
    default {
      Write-Verbose "Loading the *-PsinderBlock commands from $($PSCommandPath) into the current session"
    }
  }
}

# Nothing in this end block should be edited by the PsinderBlock Script author
# All custom logic should be contained in the *-PsinderBlock private functions above.
end {
  If ('LoadOnly' -ne $Action) {
    ForEach ($PsinderBlockAction in @('Get', 'Set', 'Test')) {
      Remove-Item -Path "Function:\$PsinderBlockAction-PsinderBlock"
    }
  }
}