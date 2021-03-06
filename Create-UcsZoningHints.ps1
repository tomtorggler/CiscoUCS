<#PSScriptInfo

.VERSION 1.2.0

.GUID 37efbb5e-37a8-49d1-9fab-345e0cb2bdbd

.AUTHOR @torggler

.TAGS CiscoUCS

.PROJECTURI http://www.ntsystems.it/page/PS-Create-UcsZoningHintsps1.aspx

.EXTERNALMODULEDEPENDENCIES Cisco.UCS.Core,Cisco.UCSCentral,Cisco.UCSManager

#>

<#
.Synopsis
    Creates zoning configuration for UCS service profiles.

.DESCRIPTION
    This script uses the CiscoUcs PowerTool to get information about one or more service profiles
    and creates SIST zoning configuration for NX-OS. The Targets device-aliases as well as the name
    for the ZoneSet and the VSAN can be specified with parameters.
    Zone names will be automatically created. Now supports multiple targets and UCS Central.
    Get the latest version of Cisco PowerTool Suite at: https://communities.cisco.com/docs/DOC-37154

.INPUTS
    Cisco.Ucsm.LsServer
    
    Cisco.UcsCentral.LsServer

    You can pipe objects of the above types to this script.
.OUTPUTS
    System.Management.Automation.PSObject

    System.String

    Depending on the parameters used, this script writes a custom PSObject or a System.String to the pipeline.

.EXAMPLE
    PS Scripts:\> Connect-Ucs 192.168.1.100
    PS Scripts:\> Get-UcsServiceProfile -Name HVSV02 | .\Create-UcsZoningHints.ps1 -TargetAlias vnx-a

    Id CommandLine
    -- -----------
     0 ! Fabric A
     1 device-alias database
     2  device-alias name HVSV02-vHba-A pwwn 20:01:00:25:B5:00:0A:41
     3 device-alias commit
     4 ! Zones
     5 zone name HVSV02-vHba-A_vnx-a vsan 1
     6  member device-alias vnx-a
     7  member device-alias HVSV02-vHba-A
     8 ! Zoneset
     9 zoneset name myZoneSet vsan 1
    10  member HVSV02-vHba-A_vnx-a
    11 ! zoneset activate name myZoneSet vsan 1

    In this example, we use Connect-Ucs to connect to an instance of UCS Manager. Using Get-UcsServiceProfile
    we get the Service Profile with a name of "HVSV02", piping the Service Profile object to this script, 
    creates the output shown above. The -TargetAlias parameter specifies the device-alias to use as zone target.
    Lines 1-3 create a device-alias for the vHBA of Fabric A in the NX-OS configuration.
    Lines 5-7 create a zone create a SIST zone and adds the vHBA's and the target's device-aliases as members.
    Lines 9 and 10 add the newly created zone to an existing zoneset configuration.
    Line 11 can be uncommented to activate the updated zoneset.

.EXAMPLE
    PS Scripts:\> Connect-UcsCentral 192.168.1.102
    PS Scripts:\> Get-UcsCentralServiceProfile -Name HVSV02 | .\Create-UcsZoningHints.ps1 -TargetAlias vnx-a -UcsCentral

    Id CommandLine
    -- -----------
     0 ! Fabric A
     1 device-alias database
     2  device-alias name HVSV02-vHba-A pwwn 20:01:00:25:B5:00:0A:41
     3 device-alias commit
     4 ! Zones
     5 zone name HVSV02-vHba-A_vnx-a vsan 1
     6  member device-alias vnx-a
     7  member device-alias HVSV02-vHba-A
     8 ! Zoneset
     9 zoneset name myZoneSet vsan 1
    10  member HVSV02-vHba-A_vnx-a
    11 ! zoneset activate name myZoneSet vsan 1

    In this example, we use Connect-UcsCentral to connect to an instance of UCS Central. Using Get-UcsCentralServiceProfile
    we get the Service Profile with a name of "HVSV02", piping the Service Profile object to this script, using the Parameter -UcsCentral
    creates the output shown above.
    

.EXAMPLE
    Get-UcsServiceProfile -AssignState assigned | .\Create-UcsZoningHints.ps1 -TargetAlias vnx-b -Fabric B -ZoneSet cfg-prod

    Id CommandLine
    -- -----------
     0 ! Fabric B
     1 device-alias database
     2  device-alias name ESX01-vHba-B pwwn 20:01:00:25:B5:00:0B:01
     3  device-alias name ESX02-vHba-B pwwn 20:01:00:25:B5:00:0B:02
     4  device-alias name HVSV02-vHba-B pwwn 20:01:00:25:B5:00:0B:41
     5 device-alias commit
     6 ! Zones
     7 zone name ESX01-vHba-B_vnx-b vsan 1
     8  member device-alias vnx-b
     9  member device-alias ESX01-vHba-B
    10 zone name ESX02-vHba-B_vnx-b vsan 1
    11  member device-alias vnx-b
    12  member device-alias ESX02-vHba-B
    13 zone name HVSV02-vHba-B_vnx-b vsan 1
    14  member device-alias vnx-b
    15  member device-alias HVSV02-vHba-B
    16 ! Zoneset
    17 zoneset name cfg-prod vsan 1
    18  member ESX01-vHba-B_vnx-b
    19  member ESX02-vHba-B_vnx-b
    20  member HVSV02-vHba-B_vnx-b
    21 ! zoneset activate name cfg-prod vsan 1

    This example uses the -AssignState parameter when getting Service Profiles from UCS Manager. This will retrieve
    all Service Profiles that are assigned to a physical server. Piping the retrieved Service Profile objects to this 
    script, creates zones from each individual vHBA of each server to the device-alias specified using the -TargetAlias parameter.
    The -Fabric parameter specifies which Cisco UCS SwitchId is used to query vHBA information.
    The -ZoneSet parameter specifies the name of the zoneset to use in the configuration snippet. 

.EXAMPLE
    Get-UcsServiceProfile | .\Create-UcsZoningHints.ps1 -Vsan 200 -OutFile c:\temp\zoneset.txt
    ! Fabric A
    device-alias database
     device-alias name HVSV02-vHba-A pwwn 20:01:00:25:B5:00:0A:41
    ...
   
    This example creates zoning configuration for all configured Service Profiles. The -OutFile parameter specifies a filename where 
    the output is written to. The output is also written to the pipeline.
    Note: Using the -OutFile parameter does not output an object but a simple string of commands to make copy/pasting easier. 
    (alternatively use "| Select-Object -ExpandProperty CommandLine")
    The -Vsan parameter specifies the Id of the vsan to use in the NX-OS configuration.

.EXAMPLE
    Get-UcsServiceProfile | .\Create-UcsZoningHints.ps1 -TargetAlias vnx-1-a,vnx-2-a

    This example creates zoning configuration for all configured Service Profiles to all specified Targets.
#>

#Requires -Modules Cisco.Ucs.Core, Cisco.UcsManager, Cisco.UcsCentral

[CmdletBinding( HelpUri = 'http://www.ntsystems.it/page/PS-Create-UcsZoningHintsps1.aspx' )]
[OutputType( [psobject] , [string] )]
param(
    # Specify the Name of a Service Profile
    [Parameter(Mandatory=$true,
        #ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ProfileName')]
    [string]
    $Name,

    # Pipe an object to this script
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
        ParameterSetName='InputObject')]
    $InputObject,

    [Switch]
    $UcsCentral,

    # Specify the Name of a Service Profile Tempalte - not yet in use!
    [Parameter(Mandatory=$true,
        ParameterSetName='SPTemplateName')]
    [string]
    $TemplateName,

    # Specify the name of the Target for the Zone
    [Alias("Target")]
    [string[]]
    $TargetAlias = "myTarget",

    # Specify the pwwn of the Target for the Zone - not yet in use!
    [ValidatePattern("^([0-9A-Fa-f]{2}[:]){7}[0-9A-Fa-f]{2}$")]
    [string[]]
    $TargetPwwn,

    # Specify the vSan to use in the NX-OS configuration snippet
    [int]
    $vsan = 1,

    # Specify the name of the ZoneSet to use
    [string]
    $ZoneSet = "myZoneSet",

    # Specify for which Fabric the output should be generated, default is A
    [ValidateSet('A','B')]
    [string]
    $Fabric = 'A',

    # Specify an output file, default is none.
    [System.IO.FileInfo]
    $OutFile
)

Begin {
    # Create variable 
    $ServieProfileInfos = @()
} # Begin

Process {
    # collect information from UCS Manager or UCS Central
        
    if($Name -and $UcsCentral) {
        Write-Verbose "By Name and UcsCentral is $UcsCentral"
        foreach ($item in $Name) {
            $ucsSP = Get-UcsCentralServiceProfile -Name $item  | select Name,BootPolicyName,@{n="vHba-A";e={$_|Get-UcsCentralVhba -SwitchId A | select -ExpandProperty Addr}},@{n="vHba-B";e={$_|Get-UcsCentralVhba -SwitchId B | select -ExpandProperty Addr}}
            $ServieProfileInfos += $ucsSP
        }
    } elseif($Name -and -not $UcsCentral) {
        Write-Verbose "By Name and UcsCentral is $UcsCentral"
        foreach ($item in $Name) {
            $ucsSP = Get-UcsServiceProfile -Name $item  | select Name,BootPolicyName,@{n="vHba-A";e={$_|Get-UcsVhba -SwitchId A | select -ExpandProperty Addr}},@{n="vHba-B";e={$_|Get-UcsVhba -SwitchId B | select -ExpandProperty Addr}}
            $ServieProfileInfos += $ucsSP
        }
    } elseif ($InputObject -and $UcsCentral) {
        Write-Verbose "Input Object and UcsCentral is $UcsCentral"
        foreach ($item in $InputObject) {
            $ServieProfileInfos += $item | select Name,BootPolicyName,@{n="vHba-A";e={$_|Get-UcsCentralVhba -SwitchId A | select -ExpandProperty Addr}},@{n="vHba-B";e={$_|Get-UcsCentralVhba -SwitchId B | select -ExpandProperty Addr}}
        }
    } elseif ($InputObject -and -not $UcsCentral) {
        Write-Verbose "Input Object and UcsCentral is $UcsCentral"
        foreach ($item in $InputObject) {
            $ServieProfileInfos += $item | select Name,BootPolicyName,@{n="vHba-A";e={$_|Get-UcsVhba -SwitchId A | select -ExpandProperty Addr}},@{n="vHba-B";e={$_|Get-UcsVhba -SwitchId B | select -ExpandProperty Addr}}
        }
    } elseif ($TemplateName -and $UcsCentral) {
        
    }
} # Process
    
End {
    # Create an array and add the text for each fabric.
    # not terribly beautiful but better then using Write-Host :)
    $outDataFabricA = @()
    $outDataFabricA += "! Fabric A"
    $outDataFabricA += "device-alias database"
    foreach ($item in $ServieProfileInfos) {
        $outDataFabricA += " device-alias name $($item.Name)-vHba-A pwwn $($item.'vhba-a')"
    }
    $outDataFabricA += "device-alias commit"
    $outDataFabricA += "! Zones"
    foreach ($tar in $TargetAlias) {
        foreach ($item in $ServieProfileInfos) {
            $outDataFabricA += "zone name $($item.Name)-vHba-A_$tar vsan $vsan"
            $outDataFabricA += " member device-alias $tar"
            $outDataFabricA += " member device-alias $($item.Name)-vHba-A"
        }
    }
    $outDataFabricA += "! Zoneset"
    $outDataFabricA += "zoneset name $ZoneSet vsan $vsan"
    foreach ($tar in $TargetAlias) {
        foreach ($item in $ServieProfileInfos) {
            $outDataFabricA += " member $($item.Name)-vHba-A_$tar"
        }
    }
    $outDataFabricA += "! zoneset activate name $zoneset vsan $vsan"

    $outDataFabricB = @()
    $outDataFabricB += "! Fabric B"
    $outDataFabricB += "device-alias database"
    foreach ($item in $ServieProfileInfos) {
        $outDataFabricB += " device-alias name $($item.Name)-vHba-B pwwn $($item.'vhba-b')"
    }
    $outDataFabricB += "device-alias commit"
    $outDataFabricB += "! Zones"
    foreach ($tar in $TargetAlias) {
        foreach ($item in $ServieProfileInfos) {
            $outDataFabricB += "zone name $($item.Name)-vHba-B_$tar vsan $vsan"
            $outDataFabricB += " member device-alias $tar"
            $outDataFabricB += " member device-alias $($item.Name)-vHba-B"
        }
    }
    $outDataFabricB += "! Zoneset"
    $outDataFabricB += "zoneset name $ZoneSet vsan $vsan"
    foreach ($tar in $TargetAlias) {
        foreach ($item in $ServieProfileInfos) {
            $outDataFabricB += " member $($item.Name)-vHba-B_$tar"
        }
    }
    $outDataFabricB += "! zoneset activate name $zoneset vsan $vsan"

    # write the thing to the pipeline or a textfile 
    switch ($Fabric)
    {
        'A' {
            if ($OutFile) {$outDataFabricA | Tee-Object -FilePath $OutFile}
            else {
                for ($i = 0; $i -lt $outDataFabricA.Length; $i++) { 
                    $data = [ordered]@{
                        'Id' = $i
                        'CommandLine' = $outDataFabricA[$i]
                    } 
                    Write-Output -InputObject (New-Object -TypeName PSCustomObject -Property $data)
                }
            }
        }
        'B' {
            if ($OutFile) {$outDataFabricB | Tee-Object -FilePath $OutFile}
            else {
            for ($i = 0; $i -lt $outDataFabricB.Length; $i++) { 
                    $data = [ordered]@{
                        'Id' = $i
                        'CommandLine' = $outDataFabricB[$i]
                    } 
                    Write-Output -InputObject (New-Object -TypeName PSCustomObject -Property $data)
                }
            }
        }
    }
} # End