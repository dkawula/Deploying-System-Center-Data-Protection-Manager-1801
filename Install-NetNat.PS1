Function Install-NetNat {
   param
  (
    [string]$VMName, 
    [string]$GuestOSName
  )

    Write-Output -InputObject "[$($VMName)]:: Configuring NAT on the Hyper-V Internal Switch `"$($env:computername)`""
    $CheckNATSwitch = get-vmswitch | where Name -eq $virtualNATSwitchName | Select Name

    If ($CheckNATSwitch -ne $null) {
    write-Host "Internal NAT Switch Found"}
    Else {
    
    write-Host "Not Found"
    Write-Host "Creating NAT Switch"

    New-VMSwitch -SwitchName $virtualNATSwitchName -SwitchType Internal 
    $ifindex = Get-NetAdapter | Where Name -like *$virtualNATSwitchName* |  New-NetIPAddress 192.168.10.1 -PrefixLength 24 
    
    Get-Netnat | Remove-NetNat -confirm:$false
    New-NetNat -Name $virtualNATSwitchName -InternalIPInterfaceAddressPrefix 192.168.10.0/24
               
    }
    }