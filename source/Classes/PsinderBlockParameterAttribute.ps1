class PsinderBlockParameterAttribute : Attribute {
    # PsinderBlock Private functions this parameter should not be added to
    [bool]$ExcludeForGet = $false
    # PsinderBlock Private functions this parameter should be marked as mandatory for
    [ValidateSet('Get', 'Test', 'Set')][string[]]$MandatoryFor = @()
}