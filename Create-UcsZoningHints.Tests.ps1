# Dot Sourcing the ps1 file in order to have the functions available
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Testing Create-UcsZoningHints" {
    Context "Testing Prerequisites" {
        It "Test UCS PowerTool availability" {

        }
        It "Test UCS Connectivity" {

        }
    }
    Context "Test UCS Connectivity" {
        It "bla" {
        
        }
    
    }
}
