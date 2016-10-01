function Invoke-N1kApi {
    <#  
    .SYNOPSIS  
        Powershell script that calls Cisco Nexus 1000 V REST API to obtain Powershell objects      
    .DESCRIPTION  
        This scripts obtains your VSM credentials and with it invokes the Cisco Nexus 100V REST API,
        obtains XML output and parses out the content to form a Powershell object. The object may then 
        be utilized in a pipeline, for example. An array of objects are returned in the case of multiple
        instances.
    .NOTES  
        File Name      : Invoke-N1kApi.ps1 
        Author         : Robert Ling robling@cisco.com
        Adapted by     : Thomas Torggler @torggler   
    .LINK  
        Script posted over:  
        http://developer.cisco.com/web/n1k/documentation  
    .EXAMPLE  
        Invoke-N1kApi -ComputerName 10.193.196.201 -api vc/port-profile

        maxPorts    : 32
        minPorts    : 1
        name        : Unused_Or_Quarantine_Uplink
        status      : 1
        systemVlans : none
        type        : Ethernet
        usedPorts   : 0
        vlans       : 
        .......
            
    .EXAMPLE    
        Invoke-N1kApi -IP 10.193.196.201 -api vc/summary

        connectionName : vcenter
        datacenterName : VCPlugin
        haStatus       : false
        ip             : 10.193.196.201
        mode           : L2
        name           : rob-vsm-2
        switchMode     : Advanced
        vcIpaddress    : 172.23.180.106
        vcStatus       : Disconnected
        vcUuid         : 8a ea 32 50 4e 45 fb c3-de 90 e9 61 74 44 56 0d
        version        : version 4.2(1)SV2(2.1) [build 4.2(1)SV2(2.0.293)] [gdb]
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Alias("IP")]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName, 

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$api,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Get","Post","Delete")]
        [string]$Method = "Get",

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [pscredential]$Credential
    )

    $RequestUri = "http://{0}/api/{1}" -f $ComputerName, $api
    
    try {
        Write-Verbose "Try connecting to $RequestUri with Username $($credential.UserName)"
        $Params = @{
            Uri = $RequestUri;
            Credential = $Credential;
            Method = $Method;
            ContentType = "application/xml";
        }
        [xml]$Content = Invoke-WebRequest @Params | Select-Object -ExpandProperty Content
    } catch {
        Write-Warning $_
        break
    }

    $o = $null

    if ($Content -ne $null) {
        if ( $Content | Get-Member -Name 'set' ) { 
            #iterate multi instances and return an array of objects
            $o = @()
            foreach ($row in $Content.set.instance) {
                $oneO = New-Object PSObject
		        $props = Get-Member -MemberType Property -InputObject $row.properties
		 
                foreach ($prop in $props) {
                    if ($prop) {
                        $oneO | Add-Member -MemberType noteproperty -name $prop.name -value $row.properties[$prop.name]."#text"
                    }
                }
                $o += $oneO
            }
        } else { 
            #single instance return a single object
            $o = New-Object PSObject
 	        $props = Get-Member -MemberType Property -InputObject $Content.instance.properties
 
            foreach ($prop in $props) {
                if ($prop) {
                    $o | Add-Member -MemberType noteproperty -name $prop.name -value $Content.instance.properties[$prop.name]."#text"
                }
            }
        }
    } else {
        Write-Verbose "Web Request Content is `$null"
    }

    # Output
    Write-Output $o
}