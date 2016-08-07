# Define variables for Mock runs
$global:mockedUcsPsSession = [pscustomobject] @{
        Cookie = (New-Guid).ToString()
        Name = "My Demo UCS"
        Port = 443
    }
$global:mockedUcsMSP = [pscustomobject] @{
    Name = "Server-1"
    Dn = "org-root/ls-Server-1"
    Rn = "ls-Server-1"
    SrcTemplName = "Server"
}
$global:mockedUcsCSP = [pscustomobject] @{
    Name = "Server-2"
    Dn = "org-root/ls-Server-1"
    Rn = "ls-Server-1"
    SrcTemplName = "Server"
}
$global:mockedUcsMVHba = @(
    [pscustomobject] @{
        Name = "VHBA-A"
        Dn = "org-root/ls-Server-1/VHBA-A"
        Rn = "fc-VHBA-A"
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
$global:mockedUcsCVHba = @(
    [pscustomobject] @{
        Name = "VHBA-A"
        Dn = "org-root/ls-Server-1/VHBA-A"
        Rn = "fc-VHBA-A"
        Addr = "20:01:00:25:B5:00:1A:11"
        SwitchId = "A"
    }
    [pscustomobject] @{
        Name = "VHBA-B"
        Dn = "org-root/ls-Server-1/VHBA-B"
        Rn = "fc-VHBA-B"
        Addr = "20:01:00:25:B5:00:1B:11"
        SwitchId = "B"
    }
)

# Testing with mocked commands
Describe "Testing Create-UcsZoningHints" {
            
    Mock Get-UcsPSSession -MockWith {return $global:mockedUcsPsSession} -verifiable
    Mock Get-UcsServiceProfile -MockWith {return $global:mockedUcsMSP} -Verifiable
    Mock Get-UcsCentralServiceProfile -MockWith {return $global:mockedUcsCSP} -Verifiable
    Mock Get-UcsVhba -MockWith {return $global:mockedUcsMVHba}
    Mock Get-UcsCentralVhba -MockWith {return $global:mockedUcsCVHba}

    $vsan = 12
    $ZoneSet = "cfg-prod"
    $Target = "vnx-sp-a"

    Context "Testing Prerequisites" {
        It "Test UCS PowerTool availability" {
            $module = Get-Module -Name Cisco.UCS.Core,Cisco.UCSCentral,Cisco.UCSManager -ListAvailable -ErrorAction SilentlyContinue
            @($module)[0] -is [PSModuleInfo] | Should be $true
        }
        It "Test UCS Connectivity" {
            $connected = Get-UcsPSSession 
            $connected | Should Not Be $null
        }
    }
    Context "Testing Output for UCS Manager" {
        It "Test output to pipeline for Fabric A" {
            $output = Get-UcsServiceProfile | .\Create-UcsZoningHints.ps1 -Fabric A
            $output | select -First 1 | Should Match "! Fabric A.*"
            $output | select -First 1 | Should Not Match "! Fabric B.*"
            $output | select -ExpandProperty CommandLine | select -Last 1 | Should Match "! zoneset"
        }
        It "Test output to pipeline for Fabric B" {
            $output = Get-UcsServiceProfile | .\Create-UcsZoningHints.ps1 -Fabric B
            $output | select -First 1 | Should Match "! Fabric B.*"
            $output | select -First 1 | Should Not Match "! Fabric A.*"
            $output | select -ExpandProperty CommandLine | select -Last 1 | Should Match "! zoneset"
        }
        It "Test output to pipeline for Fabric A with Parameters" {
            $output = Get-UcsServiceProfile | .\Create-UcsZoningHints.ps1 -Fabric A -ZoneSet $ZoneSet -Target $Target -vsan $vsan
            $output | select -First 1 | Should Match "! Fabric A.*"
            $output | select -First 1 | Should Not Match "! Fabric B.*"
            $output | select -ExpandProperty CommandLine | select -Last 1 | Should Match "! zoneset activate name $ZoneSet vsan $vsan"
        }
        It "Test output to pipeline for Fabric B with Parameters" {
            $output = Get-UcsServiceProfile | .\Create-UcsZoningHints.ps1 -Fabric B -ZoneSet $ZoneSet -Target $Target -vsan $vsan
            $output | select -First 1 | Should Match "! Fabric B.*"
            $output | select -First 1 | Should Not Match "! Fabric A.*"
            $output | select -ExpandProperty CommandLine | select -Last 1 | Should Match "! zoneset activate name $ZoneSet vsan $vsan"
        }
        It "Test output to file for Fabric A" {
            $OutFile = Join-Path -Path $TestDrive -ChildPath "out.txt"
            Get-UcsServiceProfile | .\Create-UcsZoningHints.ps1 -OutFile $OutFile
            $output = Get-Content -Path $OutFile
            (-join $output) | Should Match "! Fabric A.*"
        }
        It "Test output to file for Fabric B" {
            $OutFile = Join-Path -Path $TestDrive -ChildPath "out.txt"
            Get-UcsServiceProfile | .\Create-UcsZoningHints.ps1 -Fabric B -OutFile $OutFile
            $output = Get-Content -Path $OutFile
            (-join $output) | Should Match "! Fabric B.*"
        }
        It "Test output to file for Fabric A with Parameters " {
            $OutFile = Join-Path -Path $TestDrive -ChildPath "out.txt"
            Get-UcsServiceProfile | .\Create-UcsZoningHints.ps1 -ZoneSet $ZoneSet -Target $Target -vsan $vsan -OutFile $OutFile
            $output = Get-Content -Path $OutFile
            (-join $output) | Should Match "^! Fabric A.*"
            (-join $output) | Should Match ".*zoneset activate name $ZoneSet vsan $vsan"
        }
        It "Test output to file for Fabric B with Parameters " {
            $OutFile = Join-Path -Path $TestDrive -ChildPath "out.txt"
            Get-UcsServiceProfile | .\Create-UcsZoningHints.ps1 -Fabric B -ZoneSet $ZoneSet -Target $Target -vsan $vsan -OutFile $OutFile
            $output = Get-Content -Path $OutFile
            (-join $output) | Should Match "^! Fabric B.*"
            (-join $output) | Should Match ".*zoneset activate name $ZoneSet vsan $vsan"
        }
    }
    Context "Testing Output for UCS Central" {
        It "Test output to pipeline for Fabric A" {
            $output = Get-UcsCentralServiceProfile | .\Create-UcsZoningHints.ps1 -UcsCentral -Fabric A
            $output | select -First 1 | Should Match "! Fabric A.*"
            $output | select -First 1 | Should Not Match "! Fabric B.*"
            $output | select -ExpandProperty CommandLine | select -Last 1 | Should Match "! zoneset"
        }
        It "Test output to pipeline for Fabric B" {
            $output = Get-UcsCentralServiceProfile | .\Create-UcsZoningHints.ps1 -UcsCentral -Fabric B
            $output | select -First 1 | Should Match "! Fabric B.*"
            $output | select -First 1 | Should Not Match "! Fabric A.*"
            $output | select -ExpandProperty CommandLine | select -Last 1 | Should Match "! zoneset"
        }
        It "Test output to pipeline for Fabric A with Parameters" {
            $output = Get-UcsCentralServiceProfile | .\Create-UcsZoningHints.ps1 -UcsCentral -Fabric A -ZoneSet $ZoneSet -Target $Target -vsan $vsan
            $output | select -First 1 | Should Match "! Fabric A.*"
            $output | select -First 1 | Should Not Match "! Fabric B.*"
            $output | select -ExpandProperty CommandLine | select -Last 1 | Should Match "! zoneset activate name $ZoneSet vsan $vsan"
        }
        It "Test output to pipeline for Fabric B with Parameters" {
            $output = Get-UcsCentralServiceProfile | .\Create-UcsZoningHints.ps1 -UcsCentral -Fabric B -ZoneSet $ZoneSet -Target $Target -vsan $vsan
            $output | select -First 1 | Should Match "! Fabric B.*"
            $output | select -First 1 | Should Not Match "! Fabric A.*"
            $output | select -ExpandProperty CommandLine | select -Last 1 | Should Match "! zoneset activate name $ZoneSet vsan $vsan"
        }
        It "Test output to file for Fabric A" {
            $OutFile = Join-Path -Path $TestDrive -ChildPath "out.txt"
            Get-UcsCentralServiceProfile | .\Create-UcsZoningHints.ps1 -UcsCentral -OutFile $OutFile
            $output = Get-Content -Path $OutFile
            (-join $output) | Should Match "! Fabric A.*"
        }
        It "Test output to file for Fabric B" {
            $OutFile = Join-Path -Path $TestDrive -ChildPath "out.txt"
            Get-UcsCentralServiceProfile | .\Create-UcsZoningHints.ps1 -UcsCentral -Fabric B -OutFile $OutFile
            $output = Get-Content -Path $OutFile
            (-join $output) | Should Match "! Fabric B.*"
        }
        It "Test output to file for Fabric A with Parameters " {
            $OutFile = Join-Path -Path $TestDrive -ChildPath "out.txt"
            Get-UcsCentralServiceProfile | .\Create-UcsZoningHints.ps1 -UcsCentral -ZoneSet $ZoneSet -Target $Target -vsan $vsan -OutFile $OutFile
            $output = Get-Content -Path $OutFile
            (-join $output) | Should Match "^! Fabric A.*"
            (-join $output) | Should Match ".*zoneset activate name $ZoneSet vsan $vsan"
        }
        It "Test output to file for Fabric B with Parameters " {
            $OutFile = Join-Path -Path $TestDrive -ChildPath "out.txt"
            Get-UcsCentralServiceProfile | .\Create-UcsZoningHints.ps1 -UcsCentral -Fabric B -ZoneSet $ZoneSet -Target $Target -vsan $vsan -OutFile $OutFile
            $output = Get-Content -Path $OutFile
            (-join $output) | Should Match "^! Fabric B.*"
            (-join $output) | Should Match ".*zoneset activate name $ZoneSet vsan $vsan"            
        }
    }
    Assert-VerifiableMocks
}