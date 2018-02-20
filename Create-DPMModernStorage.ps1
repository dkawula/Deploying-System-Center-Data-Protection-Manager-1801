#Variables
Function Create-DPMModernStorage {
param
(
[string]$VMName, 
[string]$GuestOSName

)

$DomainCred = Get-Credential
$Pool1 = "DPM Storage Pool"
$VD1 = "Simple DPM vDisk01"
#$VMName = 'DPM01'
icm -VMName $VMName -Credential $DomainCred {
$VMName
Write-Output -InputObject "[$($VMName)]:: Defining the Variables"
$Pool1 = "DPM Storage Pool"
Write-Output -InputObject "[$($VMName)]:: Pool Name = $($Pool1)"
$VD1 = "Simple DPM vDisk01"
Write-Output -InputObject "[$($VMName)]:: Virtual Disk Name = $($VD1)"
Write-Output -InputObject "[$($VMName)]:: Checking the Drives and the Disk SubSystem"
Get-PhysicalDisk | FT
Get-StorageSubSystem | FT
Write-Output -InputObject "[$($VMName)]:: Creating the Storage Pool"
New-StoragePool -FriendlyName $Pool1 -StorageSubSystemFriendlyName "Windows Storage*" -PhysicalDisks (Get-PhysicalDisk -CanPool $True)
Get-StoragePool DPM* | Get-PhysicalDisk | Sort Size | FT FriendlyName, Size, MediaType, HealthStatus, OperationalStatus -AutoSize
Get-StoragePool DPM* | Get-PhysicalDisk | Where MediaType -eq "Unspecified" |Set-PhysicalDisk -MediaType HDD
Get-StoragePool DPM* | Get-PhysicalDisk | Sort Size | FT FriendlyName, Size, MediaType, HealthStatus, OperationalStatus -AutoSize
#Create Simple Storage Space Virtual Disk
Write-Output -InputObject "[$($VMName)]:: Creating the Virtual Disk $($VD1)"
New-VirtualDisk -StoragePoolFriendlyName $Pool1 -FriendlyName $VD1 -ResiliencySettingName Simple -UseMaximumSize -ProvisioningType Thin -MediaType HDD -Interleave 256KB -NumberOfColumns 1
Get-VirtualDisk -FriendlyName $VD1 |Get-Disk | Initialize-Disk -PassThru |New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -AllocationUnitSize 64KB -FileSystem ReFS -NewFileSystemLabel "DPM Modern Storage" -Confirm:$False
} 
}