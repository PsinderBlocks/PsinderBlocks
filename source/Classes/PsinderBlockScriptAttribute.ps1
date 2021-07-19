class PsinderBlockScriptAttribute : Attribute {
    # The minimum PowerShell version supported, must major or major.minor
    [string]$PowerShellVersion = '5.1'
    # Whether or not the get action can only return a single resource object
    [bool]$SingleInstance = $false
    # Whether or not the script needs to run elevated.
    [bool]$RunAsAdministrator = $false
    # Which PSEdition is supported
    [ValidateSet('Core', 'Desktop')][string]$PSEdition
    # Which assemblies, if any, need to be loaded.
    [string[]]$Assemblies
    # Which modules, if any, need to be loaded.
    [string[]]$Modules
}
