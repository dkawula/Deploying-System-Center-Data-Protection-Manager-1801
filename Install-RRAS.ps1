Function Install-RRAS{
    param
    (
        [string] $VMName, 
        [string] $GuestOSName,
        [string] $IPAddress
    ) 

    Add-VMNetworkAdapter -VMName $VMName -SwitchName $virtualNATSwitchName

    Invoke-Command -VMName $VMName -Credential $domainCred {
    Write-Output -InputObject "[$($VMName)]:: Setting InternetIP Address to 192.168.10.254"


  
    $null = New-NetIPAddress -IPAddress "192.168.10.254" -InterfaceAlias 'Ethernet 2' -PrefixLength 24
    $newroute = '192.168.10.1'
    Write-Output -InputObject "[$($VMName)]:: Configuring Default Gateway"
    $null = Get-Netroute | Where DestinationPrefix -eq "0.0.0.0/0" | Remove-NetRoute -Confirm:$False
    #$null = Test-NetConnection localhost
    new-netroute -InterfaceAlias "Ethernet 2" -NextHop $newroute  -DestinationPrefix '0.0.0.0/0' -verbose
    $null = Get-NetAdapter | where name -EQ "Ethernet" | Rename-NetAdapter -NewName CorpNet
    $null = Get-NetAdapter | where name -EQ "Ethernet 2" | Rename-NetAdapter -NewName Internet
    Write-Output -InputObject "[$($VMName)]:: Installing RRAS"
    $null = Install-WindowsFeature -Name RemoteAccess,Routing,RSAT-RemoteAccess-Mgmt 
    #$null =  Stop-Service -Name WDSServer -ErrorAction SilentlyContinue
    #$null = Set-Service -Name WDSServer -StartupType Disabled -ErrorAction SilentlyContinue

    $ExternalInterface="Internet"
    $InternalInterface="CorpNet"
    Write-Output -InputObject "[$($VMName)]:: Coniguring RRAS - Adding Internal and External Adapters"
    $null = Start-Process -Wait:$true -FilePath "netsh" -ArgumentList "ras set conf ENABLED"
    $null = Set-Service -Name RemoteAccess -StartupType Automatic
    $null = Start-Service -Name RemoteAccess

     Write-Output -InputObject "[$($VMName)]:: Configuring NAT - Lab is now Internet Enabled"
    $null = Start-Process -Wait:$true -FilePath "netsh" -ArgumentList "routing ip nat install"
    $null = Start-Process -Wait:$true -FilePath "netsh" -ArgumentList "routing ip nat add interface ""CorpNet"""
    $null = Test-NetConnection 192.168.10.1
    $null = Test-NetConnection 4.2.2.2
    $null = cmd.exe /c "netsh routing ip nat add interface $externalinterface"
    $null = cmd.exe /c "netsh routing ip nat set interface $externalinterface mode=full"
    $null = Test-NetConnection 192.168.10.1
   # $null = Test-NetConnection $($Subnet)1
    $null = Test-NetConnection 4.2.2.2
     Write-Output -InputObject "[$($VMName)]:: Disable FireWall"
    $null = cmd.exe /c "netsh firewall set opmode disable"
      
    
    }
    }