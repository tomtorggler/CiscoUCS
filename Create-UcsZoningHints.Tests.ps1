# Dot Sourcing the ps1 file in order to have functions available
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

# Define variables for Mock runs
$global:mockedUcsPsSession = [pscustomobject] @{
        Cookie = (New-Guid).ToString()
        Name = "My Demo UCS"
        Port = 443
    }
$global:mockedUcsSP = [pscustomobject] @{
    Name = "Server-1"
    Dn = "org-root/ls-Server-1"
    Rn = "ls-Server-1"
    SrcTemplName = "Server"
}
$global:mockedUcsVHba = @(
    [pscustomobject] @{
        Name = "VHBA-A"
        Dn = "org-root/ls-Server-1/VHBA-A"
        Rn = "fc-VHBA-B"
        Addr = "20:01:00:25:B5:00:1A:01"
        SwitchId = "A"
    }
    [pscustomobject] @{
        Name = "VHBA-B"
        Dn = "org-root/ls-Server-1/VHBA-B"
        Rn = "fc-VHBA-B"
        Addr = "20:01:00:25:B5:00:1B:01"
        SwitchId = "B"
    }
)

#region Testing with mocked commands
Describe "Testing Create-UcsZoningHints" {

    Mock Get-UcsPSSession -MockWith {return $global:mockedUcsPsSession} -verifiable
    Mock Get-UcsServiceProfile -MockWith {return $global:mockedUcsSP} -Verifiable
    Mock Get-UcsVhba -MockWith {return $global:mockedUcsVHba}

    Context "Testing Prerequisites" {
        It "Test UCS PowerTool availability" {
            $module = Get-Module -Name CiscoUcsPS -ListAvailable -ErrorAction SilentlyContinue
            $module -is [PSModuleInfo] | Should be $true
        }
        It "Test UCS Connectivity" {
            $connected = Get-UcsPSSession 
            $connected | Should Not Be $null
        }
    }
    Context "Testing Output" {
        It "Test output to pipeline" {
            $output = Get-UcsServiceProfile | Create-UcsZoningHints
            (-join $output) | Should Match "! Fabric A.*! Fabric B.*"
        } 
        It "Test output to pipeline for Fabric A" {
            $output = Get-UcsServiceProfile | Create-UcsZoningHints -Fabric A
            (-join $output) | Should Match "! Fabric A.*"
            (-join $output) | Should Not Match "! Fabric B.*"
        }
        It "Test output to pipeline for Fabric B" {
            $output = Get-UcsServiceProfile | Create-UcsZoningHints -Fabric B
            (-join $output) | Should Match "! Fabric B.*"
            (-join $output) | Should Not Match "! Fabric A.*"
        }
        It "Test output to file" {
            $outfile = Join-Path -Path $TestDrive -ChildPath "out.txt"
            Get-UcsServiceProfile | Create-UcsZoningHints -OutFile $outfile
            $output = Get-Content -Path $outfile
            (-join $output) | Should Match "! Fabric A.*! Fabric B.*"
        }
    }
}