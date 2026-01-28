param
(   
    [string]$CopyDir,
    [string]$AutodeskVersion
)
<#
$CopyDir = "C:\_GitHub\ArtakerStandards\Installer\Installer_Builder\_SourceFiles\Server"
$AutodeskVersion = "2025"

foreach ($FolderSync in $FolderSyncMatrix.GetEnumerator())
{
    foreach ($Sync in $FolderSync.Value.GetEnumerator())
    {
        $SyncValues = $Sync.Value.Split("|")
               
        $DestinationFolder = $SyncValues[1]
        $SourceFolder = "$($CopyDir)\$($FolderSync.Key)\$($Sync.Key)"
        Write-host "SourceFolder: $($SyncValues[1])"
        Write-host "DestinationFolder: $($DestinationFolder)"

        if ($SyncValues[0] -ne "FILE")
        {
            if (-not(Test-Path -path $DestinationFolder)) { New-Item $DestinationFolder -Type Directory }
        }
        if ($SyncValues[0] -eq "FLDR")
        {
            Robocopy $SourceFolder $DestinationFolder /MIR /FFT /Z /E /W:5 /purge
        }
        elseif ($SyncValues[0] -eq "FILE")
        {
            $FileNameOnly = [system.io.path]::GetFileName($DestinationFolder)
            $DestinationFolder = "$([system.io.path]::GetDirectoryName($DestinationFolder))"
            $SourceFolder = "$($SourceFolder)\$($FileNameOnly)"

            Write-host "**************************************************************************************************************************"
            Write-host "************************************************************* Copy from $($SourceFolder) to $($DestinationFolder) *************************************************************"
            
            copy-Item $SourceFolder -Destination $DestinationFolder -Recurse -Force
            Write-host "**************************************************************************************************************************"
        }
    }
}


#>
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

# MessageBox popup when building PowerGateServer-Installer
$MessageBoxResult = [System.Windows.Forms.MessageBox]::Show("Would you like to copy necessary Files for the PowerGateServer-Installer from SourceFolders?", "Artaker Installer - Server", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

# On MessageBox = Yes => Start Copying Folders / Files from different Directories
if ($MessageBoxResult -eq "Yes")
{
    $CopyDir = $CopyDir.Replace("SetupBuilder\..\", "")

    write-host "***************************************************************************************"
    write-host "CopyDirectory: $($CopyDir)"
    write-host "***************************************************************************************"
   
    #Syntax for copy : 1|2|3
    # 1 = File or Folder (specific File or complete Folder)
    # 3 = Folder recurse or not
    # 2 = Directory

    $FolderSyncMatrix = @{
        # Artaker Files
        "Artaker"    = @{

            "Icons"       = "FLDR|C:\ProgramData\Artaker\Icons|True"; 
            "Modules"     = "FLDR|C:\ProgramData\Artaker\Modules|True" 
            "Logging"     = "FLDR|C:\ProgramData\Artaker\Logging|True"
            "Libraries"   = "FLDR|C:\ProgramData\Artaker\Libraries|True"
            "ServerTasks" = "FLDR|C:\ProgramData\Artaker\ServerTasks|True" 
        }
       
        # coolOrange Files
        "coolOrange" = @{
            "powerGateServer" = "FLDR|C:\ProgramData\coolOrange\powerGateServer|True";
        }
    }

    $ExcludedObjects = @("test.txt", "CatalogService")
    
    remove-item -Path $CopyDir -Force -Recurse | Out-Null
    
    # Check if Folders / Files Exist
    foreach ($FolderSync in $FolderSyncMatrix.GetEnumerator())
    {       
        foreach ($Sync in $FolderSync.Value.GetEnumerator())
        {
            $SyncValues = $Sync.Value.Split("|")

            $SourceFolder = $SyncValues[1]
            $DestinationFolder = "$($CopyDir)\$($FolderSync.Key)\$($Sync.Key)"
            Write-host "SourceFolder: $($SyncValues[1])"
            Write-host "DestinationFolder: $($DestinationFolder)"

            if (-not(Test-Path -path $DestinationFolder)) { New-Item $DestinationFolder -Type Directory }

            if ($SyncValues[0] -eq "FLDR")
            {
                
                if ($SyncValues[2] -eq "True")
                {
                    $AllIncludedObjects = Get-ChildItem -Path $SourceFolder -Recurse
                }
                else
                {
                    $AllIncludedObjects = Get-ChildItem -Path $SourceFolder
                }
                
                foreach ($Include in $AllIncludedObjects)
                {
                    if ($ExcludedObjects -contains $Include.Name)
                    {
                        Write-Host("#### INFO: Folder Excluded: $($Include)")
                        continue
                    }

                    try
                    {
                        $destination = Join-Path $DestinationFolder $Include.FullName.Substring($SourceFolder.Length)
                        Copy-Item $Include.FullName -Destination $destination -Force 
                    }
                    catch
                    {
                        Write-Host("#### INFO: $($Include) could not be copied because parent-folder was excluded")
                    }
                }
            }
            elseif ($SyncValues[0] -eq "FILE")
            {
                Write-host "**************************************************************************************************************************"
                Write-host "************************************************************* Copy from $($SourceFolder) to $($DestinationFolder) *************************************************************"
                copy-Item $SourceFolder -Destination $DestinationFolder -Recurse -Force
                Write-host "**************************************************************************************************************************"
            }
        }
    }
}