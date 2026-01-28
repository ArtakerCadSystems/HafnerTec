function InitializeWindow
{	
    # $DsDiag.Showlog()
    # $DsDiag.Clear()
    # $DsDiag.Trace(">> MainWindow")

    Get-ChildItem -path ($env:ProgramData + '\Artaker\Modules') -Filter "*.psm1" | ForEach-Object { Import-Module -Name $_.FullName -Global }

    $Global:currentTheme = [Autodesk.DataManagement.Client.Framework.Forms.SkinUtils.WinFormsTheme]::Instance.CurrentTheme
    $Global:autodeskVersion = "2026"
    #begin rules applying commonly	
    
    if ($application.Caption -like "Autodesk Inventor Professional $($Global:autodeskVersion)")
    {
        $Global:VaultVirtualPath = $Prop["_VaultVirtualPath"].Value
        $Global:WorkspacePath = $Prop["_WorkspacePath"].Value
        $Global:WorkingFolderLocation = $vault.DocumentService.GetRequiredWorkingFolderLocation()
        $Global:WorkingFolder = "Path"
        #ConnecttoERP
    }
    else
    {
        $Global:VaultVirtualPath = "$"
        $Global:WorkspacePath = "\Daten"
        $Global:WorkingFolderLocation = $vault.DocumentService.GetRequiredWorkingFolderLocation()
        $Global:WorkingFolder = "Path"
    }

    $dsWindow.Title = SetWindowTitle

    try
    {
        readXMLfile
    }
    catch
    {
        Show-ArtakerMessageBox -Message "User XML unter konnte nicht geladen werden" -Title "Artaker DataStandard" -Button "OK" -Icon "ERROR"
    }

    $mWindowName = $dsWindow.Name
    switch ($mWindowName)
    {
        "InventorWindow"
        {
            #InitializeStockNumberValidation
            # SetLayout

            if ($Prop["_CreateMode"].Value -eq $true)
            {
                # Dialog in Create Mode
                ##$DsDiag.Trace("Create mode")
                if (-not $Prop["_SaveCopyAsMode"].Value)
                {
                    readUserData
                    ReadAutodeskVaultShortCuts
                    SetCategory

                    # $Prop["Category"].Value = ($Prop["Path"].Value).split("\")[0]
                }
                # Add EventHandler for ShortCut (click in emptySpace)
                $DsWindow.FindName("TreeViewAutodeskVaultShortCuts").add_MouseLeftButtonDown( {
                        SetRemoveSelectionInTreeView
                    })
            }
            # else
            # {
            #     # visibilityDescriptionValues -visibility $false
            #     $FilePath = $Prop["_FilePath"].Value.Replace($vault.DocumentService.GetRequiredWorkingFolderLocation(), "").Replace(($Prop["_WorkspacePath"].Value.Replace("\", "")), "").Substring(1)
            #     if ($Prop["Path"].Value -ne $FilePath)
            #     {
            #         $Prop["Path"].Value = $FilePath
            #     }
            # }
            # Sync Props from 3D to Drawing
            Sync3Dto2D
            # Sync Props from 3D to IPN
            Sync3DtoIPN
            SetLayout
        }
        "AutoCADWindow"
        {
            #rules applying for AutoCAD
        }
        default
        {
            #rules applying commonly
        }
    }
    #$DsDiag.Trace("<< MainWindow")
	
}
function AddinLoaded
{
	
}
function AddinUnloaded
{
    #Executed when DataStandard is unloaded in Inventor
}

function GetNumSchms
{
    ##$DsDiag.Trace(">> Nummernschema wird eingelesen")
    # $specialFiles = @(".DWG", ".IDW", ".IPN")
    # if ($specialFiles -contains $Prop["_FileExt"].Value -and !$Prop["_GenerateFileNumber4SpecialFiles"].Value)
    # {
    #     return $null
    # }
	
    if (-Not $Prop["_EditMode"].Value)
    {
        [System.Collections.ArrayList]$numSchems = @($vault.NumberingService.GetNumberingSchemes('FILE', 'Activated'))
        if ($numSchems.Count -gt 1)
        {
            $numSchems = $numSchems | Sort-Object -Property IsDflt -Descending
        }
        return $numSchems
    }
}


function OnPostCloseDialog
{
    $mWindowName = $dsWindow.Name
    switch ($mWindowName)
    {
        "InventorWindow"
        {
            
        }
        "AutoCADWindow"
        {
            #rules applying for AutoCAD
        }
        default
        {
            #rules applying commonly
        }
    }
}

function SetWindowTitle
{
    $mWindowName = $dsWindow.Name
    switch ($mWindowName)
    {
        "InventorFrameWindow"
        {
            $windowTitle = $UIString["LBL54"]
        }
        "InventorDesignAcceleratorWindow"
        {
            $windowTitle = $UIString["LBL50"]
        }
        "InventorPipingWindow"
        {
            $windowTitle = $UIString["LBL39"]
        }
        "InventorHarnessWindow"
        {
            $windowTitle = $UIString["LBL44"]
        }
        default
        {
            #applies to InventorWindow and AutoCADWindow
            if ($Prop["_CreateMode"].Value)
            {
                if ($Prop["_CopyMode"].Value)
                {
                    $windowTitle = "$($UIString["LBL60"]) - $($Prop["_OriginalFileName"].Value)"
                }
                elseif ($Prop["_SaveCopyAsMode"].Value)
                {
                    $windowTitle = "$($UIString["LBL72"]) - $($Prop["_OriginalFileName"].Value)"
                }
                else
                {
                    $windowTitle = "$($UIString["LBL24"]) - $($Prop["_OriginalFileName"].Value)"
                }
            }
            else
            {
                $windowTitle = "$($UIString["LBL25"]) - $($Prop["_FileName"].Value)"
            } 
        }
    }
    return $windowTitle
}


function GetCategories
{
    return $Prop["_Category"].ListValues
}
