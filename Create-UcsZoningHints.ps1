function Create-UcsZoningHints {

[CmdletBinding(ConfirmImpact='Low')]
    param(
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName='ByProfileName')]
        [string]
        $Name,

        [Parameter(Mandatory=$true,
            ParameterSetName='BySPTemplateName')]
        [string]
        $ServiceProfileTemplateName,

        # Specify the name of the Target for the Zone
        [string]
        $Target = "myTarget",

        # Specify the vSan to use        
        [int]
        $vsan = 1,

        # Specify the name of the ZoneSet to use
        [string]
        $ZoneSet = "myZoneSet",

        # Specify for which Fabric the output should be generated, default is Both
        [ValidateSet('A','B','Both')]
        [string]
        $Fabric = "Both",

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
            $outDataFabricB += "device-alias name $($item.Name)-vHba-B pwwn $($item.'vhba-b')"
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
                else {$outDataFabricA}
            }
            'B' {
                if ($OutFile) {$outDataFabricB | Tee-Object -FilePath $OutFile}
                else {$outDataFabricB}
            }
            'Both' {
                if ($OutFile) {
                    $outDataFabricA | Tee-Object -FilePath $OutFile
                    $outDataFabricB | Tee-Object -FilePath $OutFile -Append
                } else {$outDataFabricA;$outDataFabricB}
            }
        }
    }
}