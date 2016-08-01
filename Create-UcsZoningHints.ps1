
<#PSScriptInfo

.VERSION 1.0.0

.GUID 37efbb5e-37a8-49d1-9fab-345e0cb2bdbd

.AUTHOR @torggler

.TAGS CiscoUCS

.PROJECTURI http://www.ntsystems.it/page/PS-Create-UcsZoningHintsps1.aspx

.EXTERNALMODULEDEPENDENCIES CiscoUcsPS

#>

<#
.Synopsis
    Creates zoning configuration for UCS service profiles.

.DESCRIPTION
    This script uses the CiscoUcs PowerTool to get information about one or more service profiles
    and creates SIST zoning configuration for NX-OS. The Target's device-alias as well as the name
    for the ZoneSet and the VSAN can be specified with parameters.
    Zone names will be automatically created. 

.INPUTS
    Cisco.Ucs.LsServer

    Cisco.Ucs.ManagedObject

    You can pipe objects of the above types to this script.
.OUTPUTS
    System.Management.Automation.PSObject

    System.String

    Depending on the parameters used, this script writes a custom PSObject or a System.String to the pipeline.

.EXAMPLE
    PS Scripts:\> Connect-Ucs 192.168.1.100
    PS Scripts:\> Get-UcsServiceProfile -Name HVSV02 | .\Create-UcsZoningHints.ps1 -Target vnx-a

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
    creates the output shown above. The -Target parameter specifies the device-alias to use as zone target.
    Lines 1-3 create a device-alias for the vHBA of Fabric A in the NX-OS configuration.
    Lines 5-7 create a zone create a SIST zone and adds the vHBA's and the target's device-aliases as members.
    Lines 9 and 10 add the newly created zone to an existing zoneset configuration.
    Line 11 can be uncommented to activate the updated zoneset.

.EXAMPLE
    Get-UcsServiceProfile -AssignState assigned | .\Create-UcsZoningHints.ps1 -Target vnx-b -Fabric B -ZoneSet cfg-prod

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
    script, creates zones from each individual vHBA of each server to the device-alias specified using the -Target parameter.
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
#>

[CmdletBinding(ConfirmImpact='Low')]
[OutputType([psobject],[string])]
param(
    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='ByProfileName')]
    [string]
    $Name,

    # This parameter is not yet in use.
    [Parameter(Mandatory=$true,
        ParameterSetName='BySPTemplateName')]
    [string]
    $ServiceProfileTemplateName,

    # Specify the name of the Target for the Zone
    [string]
    $Target = "myTarget",

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

    # switch inputs
}

Process {
    # collect information from UCS 
    foreach ($ServiceProfile in $Name) {
        $ucsSP = Get-UcsServiceProfile -Name $ServiceProfile  | select Name,BootPolicyName,@{n="vHba-A";e={$_|Get-UcsVhba -SwitchId A | select -ExpandProperty Addr}},@{n="vHba-B";e={$_|Get-UcsVhba -SwitchId B | select -ExpandProperty Addr}}
        $ServieProfileInfos += $ucsSP
    }
}
    
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
    foreach ($item in $ServieProfileInfos) {
        $outDataFabricA += "zone name $($item.Name)-vHba-A_$target vsan $vsan"
        $outDataFabricA += " member device-alias $Target"
        $outDataFabricA += " member device-alias $($item.Name)-vHba-A"
    }
    $outDataFabricA += "! Zoneset"
    $outDataFabricA += "zoneset name $ZoneSet vsan $vsan"
    foreach ($item in $ServieProfileInfos) {
        $outDataFabricA += " member $($item.Name)-vHba-A_$target"
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
    foreach ($item in $ServieProfileInfos) {
        $outDataFabricB += "zone name $($item.Name)-vHba-B_$target vsan $vsan"
        $outDataFabricB += " member device-alias $Target"
        $outDataFabricB += " member device-alias $($item.Name)-vHba-B"
    }
    $outDataFabricB += "! Zoneset"
    $outDataFabricB += "zoneset name $ZoneSet vsan $vsan"
    foreach ($item in $ServieProfileInfos) {
        $outDataFabricB += " member $($item.Name)-vHba-B_$target"
    }
    $outDataFabricB += "! zoneset activate name $zoneset vsan $vsan"

    # write the thing to the pipeline or a textfile 
    switch ($Fabric)
    {
        'A' {
            if ($OutFile) {$outDataFabricA | Tee-Object -FilePath $OutFile}
            else {
                for ($i = 0; $i -lt $outDataFabricA.Length; $i++)
                { 
                    Write-Verbose "i $i"
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
            for ($i = 0; $i -lt $outDataFabricB.Length; $i++)
                { 
                    Write-Verbose "i $i"
                    $data = [ordered]@{
                        'Id' = $i
                        'CommandLine' = $outDataFabricB[$i]
                    } 
                    Write-Output -InputObject (New-Object -TypeName PSCustomObject -Property $data)
                }
            }
        }
    }
}
