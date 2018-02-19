 <#
Created:	 2018-02-01
Version:	 1.0
Author       Dave Kawula MVP
Homepage:    http://www.checkyourlogs.net

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and 
is not supported by the authors or CheckyourLogs or MVPDays Publishing

Author - Dave Kawula
    Twitter: @DaveKawula
    Blog   : http://www.checkyourlogs.net


    .Synopsis
    Deploys System Center SQL Server 2016 Instance to  a Hyper-V Lab VM
    .DESCRIPTION
    This Script was part of my BIGDemo series and I have broken it out into a standalone function

    You will need to have a SVC_SQL Pre-Created and SQL 2016 Media for this lab to work
    The Script will prompt for the path of the Files Required
    The Script will prompt for an Admin Account which will be used in $DomainCred
    If your File names are different than mine adjust accordingly.

    We will use PowerShell Direct to setup the Veeam Server in Hyper-V

    The Source Hyper-V Virtual Machine needs to be Windows Server 2016

    .EXAMPLE
    TODO: Dave, add something more meaningful in here
    .PARAMETER WorkingDir
    Transactional directory for files to be staged and written
    .PARAMETER VMname
    The name of the Virtual Machine
    .PARAMETER VMPath
    The Path to the VM Working Folder - We create a new VHDx for the DPM Install
    .PARAMETER GuestOSName
    Name of the Guest Operating System Name
    

    Usage: Install-DPM -Vmname YOURVM -GuestOS VEEAMSERVER -VMpath f:\VMs\SCVMM -WorkingDir f:\Temp 
#>
  #Installs SCVMM 1801 for your lab

 Function Install-SQLDPM{
 
 param
  (
    [string]$VMName, 
    [string]$GuestOSName,
    [string]$VMPath
   

  )
     

     #Ask for DPM EXE

        [reflection.assembly]::loadwithpartialname("System.Windows.Forms")
        $openFile = New-Object System.Windows.Forms.OpenFileDialog -Property @{
            Title="Please SQL Server ISO"
        }
        $openFile.Filter = "iso files (*.iso)|*.iso|All files (*.*)|*.*" 
        If($openFile.ShowDialog() -eq "OK")
        {
              Write-Host "File $($openfile.FileName) selected"
        } 
        if (!$openFile.FileName){
                WriteErrorAndExit  "Iso was not selected... Exitting"
            }
            $SQLISO = $openfile.FileName
           
     
     #Ask for SSMS EXE

        [reflection.assembly]::loadwithpartialname("System.Windows.Forms")
        $openFile = New-Object System.Windows.Forms.OpenFileDialog -Property @{
            Title="Please Select the SQL Server Management Studio SSMS .exe Version 16.5 ONLY!!!"
        }
        $openFile.Filter = "exe files (*.exe)|*.exe|All files (*.*)|*.*" 
        If($openFile.ShowDialog() -eq "OK")
        {
              Write-Host "File $($openfile.FileName) selected"
        } 
        if (!$openFile.FileName){
                WriteErrorAndExit  "Iso was not selected... Exitting"
            }
            $SSMSEXE = $openfile.FileName

              
     #Ask for Windows Server ISO

        [reflection.assembly]::loadwithpartialname("System.Windows.Forms")
        $openFile = New-Object System.Windows.Forms.OpenFileDialog -Property @{
            Title="Please Select the Windows Server 2016 ISO"
        }
        $openFile.Filter = "ISO files (*.ISO)|*.ISO|All files (*.*)|*.*" 
        If($openFile.ShowDialog() -eq "OK")
        {
              Write-Host "File $($openfile.FileName) selected"
        } 
        if (!$openFile.FileName){
                WriteErrorAndExit  "Iso was not selected... Exitting"
            }
            $WS2016ISO = $openfile.FileName
           

       
     $DomainCred = Get-Credential
     #$VMName = 'DPM01'
     #$GuestOSname = 'DPM01'
     #$VMPath = 'f:\dcbuild_Test\VMs'
     #$SQL = 'VMM01\MSSQLSERVER'
     #$SCOMDrive = 'd:'

   
     
      
    Write-Output -InputObject "[$($VMName)]:: Adding Drive for DPM Install"

    New-VHD -Path "$($VMPath)\$($GuestOSName) - SQL Data 2.vhdx" -Dynamic -SizeBytes 50GB 
    Mount-VHD -Path "$($VMPath)\$($GuestOSName) - SQL Data 2.vhdx" 
    $DiskNumber = (Get-Diskimage -ImagePath "$($VMPath)\$($GuestOSName) - SQL Data 2.vhdx").Number
    Initialize-Disk -Number $DiskNumber -PartitionStyle GPT 
    Get-Disk -Number $DiskNumber | New-Partition -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem NTFS -NewFileSystemLabel "SQL" -Confirm:$False
    $Driveletter = get-wmiobject -class "Win32_Volume" -namespace "root\cimv2" | where-object {$_.Label -like "SQL*"}
    $SQLDriveLetter = $DriveLetter.DriveLetter
    Write-Output -InputObject "[$($VMName)]:: Copying SQL ISO to the new VHDx"
    Copy-Item -Path $SQLISO -Destination "$($SQLDriveLetter)\en_sql_server_2016_standard_with_service_pack_1_x64_dvd_9540929.iso" -Force
    Write-Output -InputObject "[$($VMName)]:: Copying SSMS EXE to the new VHDx"
    Copy-Item -Path $SSMSEXE -Destination "$($SQLDriveLetter)\SSMS-Setup-ENU.exe" -Force
    Write-Output -InputObject "[$($VMName)]:: Copying WS 2016 ISO to the new VHDx"
    Copy-Item -Path $WS2016ISO -Destination "$($SQLDriveLetter)\en_windows_server_2016_x64_dvd_9718492.iso" -Force
    Dismount-VHD -Path "$($VMPath)\$($GuestOSName) - SQL Data 2.vhdx"
    Add-VMHardDiskDrive -VMName $VMName -Path "$($VMPath)\$($GuestOSName) - SQL Data 2.vhdx" -ControllerType SCSI
  


    icm -VMName $VMName -Credential $domainCred {
      
    Write-Output -InputObject "[$($VMName)]:: Adding the new VHDx for the SQL Install"
    Get-Disk | Where OperationalStatus -EQ "Offline" | Set-Disk -IsOffline $False 
    Get-Disk | Where Number -NE "0" |  Set-Disk -IsReadOnly $False
    $Driveletter = get-wmiobject -class "Win32_Volume" -namespace "root\cimv2" | where-object {$_.Label -like "SQL*"}
    $SQLDrive = $Driveletter.DriveLetter
    $SQLDrive
    Write-Output -InputObject "[$($VMName)]:: Mounting SQL ISO"

    $iso = Get-ChildItem -Path "$($SQLDrive)\en_sql_server_2016_standard_with_service_pack_1_x64_dvd_9540929.iso"  #CHANGE THIS!

    Mount-DiskImage $iso.FullName

    $setup = $(Get-DiskImage -ImagePath $iso.FullName | Get-Volume).DriveLetter +':' 
    $setup

    Write-Output -InputObject "[$($VMName)]:: Mounting WS2016 ISO"

    $iso = Get-ChildItem -Path "$($SQLDrive)\en_windows_server_2016_x64_dvd_9718492.iso"  #CHANGE THIS!

    Mount-DiskImage $iso.FullName

    $setup1 = $(Get-DiskImage -ImagePath $iso.FullName | Get-Volume).DriveLetter +':' 
    $setup1
    

     Write-Output -InputObject "[$($VMName)]:: Configure DPM Service Account as a Local Admin"

   # Add-LocalGroupMember -Group Administrators -Member $DPMServiceAcct

    
     Write-Output -InputObject "[$($VMName)]:: Enable .Net Framework 3.5"

     Dism.exe /Online /Enable-Feature /FeatureName:NetFx3 /All /Source:d:\sources\sxs

}    
      

    Restart-DemoVM -VMName $VMname
    Wait-PSDirect -VMName $VMName -cred $DomainCred
}

 function Wait-PSDirect {
     param
     (
         [string]
         $VMName,

         [Object]
         $cred
     )

    Write-Log $VMName "Waiting for PowerShell Direct (using $($cred.username))"
    while ((Invoke-Command -VMName $VMName -Credential $cred {
                'Test'
    } -ea SilentlyContinue) -ne 'Test') 
    {
        Start-Sleep -Seconds 1
    }
}

 function Restart-DemoVM {
     param
     (
         [string]
         $VMName
     )

    Write-Log $VMName 'Rebooting'
    stop-vm $VMName
    start-vm $VMName
}
     
 function Write-Log {
    param
    (
        [string]$systemName,
        [string]$message
    )

    Write-Host -Object (Get-Date).ToShortTimeString() -ForegroundColor Cyan -NoNewline
    Write-Host -Object ' - [' -ForegroundColor White -NoNewline
    Write-Host -Object $systemName -ForegroundColor Yellow -NoNewline
    Write-Host -Object "]::$($message)" -ForegroundColor White
}


