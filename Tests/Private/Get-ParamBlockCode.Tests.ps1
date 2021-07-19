BeforeDiscovery {
  $ProjectRoot = Split-Path -Path $PSScriptRoot -Parent |
    Split-Path -Parent
  $RelativeSourceFilePath = $PSCommandPath.Substring($ProjectRoot.Length) -Replace 'Tests(\.|\\)*', ''
  $SourceFilePath = Join-Path -Path $ProjectRoot -ChildPath 'Source' -AdditionalChildPath $RelativeSourceFilePath
  $TestTargetName = Split-Path $SourceFilePath -LeafBase
}

BeforeAll {
  $ProjectRoot = Split-Path -Path $PSScriptRoot -Parent |
    Split-Path -Parent
  $RelativeSourceFilePath = $PSCommandPath.Substring($ProjectRoot.Length) -Replace 'Tests(\.|\\)*', ''
  $SourceFilePath = Join-Path -Path $ProjectRoot -ChildPath 'Source' -AdditionalChildPath $RelativeSourceFilePath
  . $SourceFilePath
}

Describe $TestTargetName {
  Context 'Basic Functionality' {
    It 'Does things' {
      $true | Should -Be $false
    }
  }
}