# Initial Version 03.09.2020
# Updated Version to Support DarkTheme 25.07.2022
# Daniel Stockinger
# Icons are located at C:\ProgramData\Artaker\Icons
# ToUse Change $Prop[$($Global:WorkingFolder)].Value to your Folder Path
# Module for Messageboxes (WPF and WindowsForms) is required


#region Generate TreeView

function ReadAutodeskVaultShortCuts
{

	# Define a custom class to represent the tree nodes
	class TreeNode
	{
		[string]$Name
		[string]$URI
		[string]$Icon
		[System.Collections.ArrayList]$Children
		[bool]$IsGroup
		[bool]$IsEditable

		TreeNode([string]$name, $uri, [string]$Icon)
		{
			$this.Name = $name
			$this.URI = $uri
			$this.Icon = $Icon
			$this.Children = [System.Collections.ArrayList]::new()
			$this.IsGroup = $false
			$this.IsEditable = $false
		}

		[void]AddChild([TreeNode]$child)
		{
			$this.Children.Add($child)
		}
	}	


	# Subscribe to Selection event
	# Define the event handler function
	# Add event handler to the TreeView
	$dsWindow.FindName("TreeViewAutodeskVaultShortCuts").add_SelectedItemChanged({
			param($sender, $e)
			OnSelectedItemChanged -sender $sender -e $e
		})
	
	#create a List to save node object
	$Global:m_ScTreeList = [System.Collections.ArrayList]::new()

	# Get the treeView element from the window
	$treeView = $dsWindow.FindName("TreeViewAutodeskVaultShortCuts")

	# Create a treeRoot node for the treeView
	$IconSource = "C:\ProgramData\Artaker\Icons\Icons" + $Global:currentTheme + "\User_CO_16.png"
	
	$treeRoot = [TreeNode]::new("UserRoot", "", "")
	$MyScRoot = [TreeNode]::New("My Shortcuts", "", $IconSource)

	#read the user shortcuts stored in appdata
	[XML]$mUserScXML = mGetShortcutXML
	if ($null -ne $mUserScXML)
	{
		if ($mUserScXML.Shortcuts.ChildNodes.Count -gt 0)
		{
			foreach ($Node in $mUserScXML.Shortcuts.ChildNodes)
			{
				mAddTreeNode $Node $MyScRoot $true
			}
		}
	}

	# add the user shortcuts to the tree's root
	$treeRoot.AddChild($MyScRoot)

	# Get the tree for distributed shortcuts
	$IconSource = "C:\ProgramData\Artaker\Icons\Icons" + $Global:currentTheme + "\User_Admin_16.png"
	
	$DstrbScRoot = [TreeNode]::new("Distributed Shortcuts", "", $IconSource)

	#read the distributed shortcuts stored in the Vault
	$mAdminScXML = [XML]$vault.KnowledgeVaultService.GetVaultOption("AdminShortcuts")
	if ($null -ne $mAdminScXML)
	{		
		if ($mAdminScXML.AdminShortcuts.ChildNodes.Count -gt 0)
		{

			foreach ($Node in $mAdminScXML.AdminShortcuts.ChildNodes)
			{
				mAddTreeNode $Node $DstrbScRoot $false
			}			 
		}		
	}
	
	#add the distributed shortcuts to the tree's root
	$treeRoot.AddChild($DstrbScRoot)
	
	#bind the tree items to the treeview
	$treeView.ItemsSource = $treeRoot.Children
	# #enable the click event on tree items
	# $dsWindow.FindName("TreeViewAutodeskVaultShortCuts").add_SelectedItemChanged({
	# 	mClickScTreeItem
	# })

}

function mAddTreeNode($XmlNode, $TreeLevel, $EnableDelete)
{

	if ($XmlNode.LocalName -eq "Shortcut")
	{
		if (($XmlNode.NavigationContextType -eq "Connectivity.Explorer.Document.DocFolder") -and ($XmlNode.NavigationContext.URI -like "*" + $global:CAx_Root + "/*"))
		{
					
			#create a tree node
			$IconSource = mGetIconSource($XmlNode.ImageMetaData)
            
			$child = [TreeNode]::new($XmlNode.Name, $XmlNode.NavigationContext.URI, $IconSource)
			$child.IsEditable = $EnableDelete	
			$child.IsGroup = $false	
			$TreeLevel.AddChild($child)
			#add the shortcut to the dictionary for instant read on selection change	
			$Global:m_ScTreeList.Add($child)	
		}
	}
	elseif ($XmlNode.LocalName -eq "ShortcutGroup")
	{
		$IconSource = "C:\ProgramData\Artaker\Icons\Icons" + $Global:currentTheme + "\FolderClosedMask_16.png"
		if ($XmlNode.HasChildNodes -eq $true)
		{
			$NextLevel = [TreeNode]::new($XmlNode.Name, "", $IconSource)
			$NextLevel.IsGroup = $true
			$NextLevel.IsEditable = $EnableDelete
			$XmlNode.ChildNodes | ForEach-Object {
				mAddTreeNode -XmlNode $_ -TreeLevel $NextLevel $EnableDelete
			}
			$child = $NextLevel
			$Global:m_ScTreeList.Add($child)	
		}
		else
		{
			$child = [TreeNode]::new($XmlNode.Name, $XmlNode.NavigationContext.URI, $IconSource)
			$child.IsGroup = $true
			$child.IsEditable = $EnableDelete
			$Global:m_ScTreeList.Add($child)
		}
		#add the group to the tree		
		$TreeLevel.AddChild($child)
			
	}
}

function mAddShortcutByName([STRING] $mScName, $parentNode)
{
	$newNode = $global:m_ScXML.CreateElement("Shortcut", $global:m_ScXML.DocumentElement.NamespaceURI)
	$newNode.SetAttribute("Name", $mScName)
	$newNode.SetAttribute("IsAdmin", "false")
	$newNode.SetAttribute("IsShown", "true")
	$newNode.SetAttribute("Id", [System.Guid]::NewGuid().ToString())

	
	$DsDiag.Trace("WorkspacePath: " + $Global:WorkingFolderLocation)
	$newURI = $Prop["_FilePath"].Value.TrimStart($Global:WorkingFolderLocation)
	$newURI = ("vaultfolderpath:$/" + $newURI).replace("\", "/")

	
	$NavigationContext = $global:m_ScXML.CreateElement("NavigationContext", $global:m_ScXML.DocumentElement.NamespaceURI)
	$NavigationContext.SetAttribute("URI", "$($newURI)")

	$NavigationContextType = $global:m_ScXML.CreateElement("NavigationContextType", $global:m_ScXML.DocumentElement.NamespaceURI)
	$NavigationContextType.InnerText = "Connectivity.Explorer.Document.DocFolder"

	$ImageMetaData = $global:m_ScXML.CreateElement("ImageMetaData", $global:m_ScXML.DocumentElement.NamespaceURI)

	#get the navigation folder's color
	$mFldrPath = $newURI.Replace("vaultfolderpath:", "")
	
	$mFldr = $vault.DocumentService.FindFoldersByPaths(@($mFldrPath))

	

	$mCatDef = $vault.CategoryService.GetCategoryById($mFldr[0].Cat.CatId)


	$mFldrColor = [System.Drawing.Color]::FromArgb($mCatDef.Color)

	$ImageMetaData.InnerText = "TAG=FolderColor [A=$($mFldrColor.A), R=$($mFldrColor.R), G=$($mFldrColor.G), B=$($mFldrColor.B)]LightColor [A=$($mFldrColor.A), R=$($mFldrColor.R), G=$($mFldrColor.G), B=$($mFldrColor.B)]Dark,DATA=iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAACxEAAAsRAX9kX5EAAABKSURBVDhP7dKxDQAgCERRpnFn12ELpjmhNSdCbC1eQ3K/QgA8ETMDMRwd7E6BUIpkgemGqiJDqz4M13EQduz4gR8I9BM76LEOsgBZDDF0oQ2lvQAAAABJRU5ErkJggg=="
	
	$newNode.AppendChild($NavigationContext)
	$newNode.AppendChild($NavigationContextType)
	$newNode.AppendChild($ImageMetaData)

	# add to parent node
	if ($null -ne $parentNode)
	{
		$parentNode.AppendChild($newNode);
	}
	else
	{
		$global:m_ScXML.Shortcuts.AppendChild($newNode)
	}

	$global:m_ScXML.Save($mScFile)
	
	return $true
}

function mAddGroupByName([STRING] $mGroupName, $parentNode)
{
	# get file from path
	$groupNode = $global:m_ScXML.CreateElement("ShortcutGroup", $global:m_ScXML.DocumentElement.NamespaceURI)
	$groupNode.SetAttribute("Name", $mGroupName)
	$groupNode.SetAttribute("IsAdmin", "false")
	$groupNode.SetAttribute("IsShown", "true")
	$groupNode.SetAttribute("Id", [System.Guid]::NewGuid().ToString())

	# add to parent node
	if ($null -ne $parentNode)
	{
		$parentNode.AppendChild($groupNode);
	}
	else
	{
		$global:m_ScXML.Shortcuts.AppendChild($groupNode)
	}

	$global:m_ScXML.Save($mScFile)
	
	return $true

}

function mRemoveShortcutByName ([STRING] $mScName)
{
	try
	{
		#catch all nodes; multiple shortcuts can be equally named
		
		$mNodesToSelect = "//*[@Name='$($mScName)']"
		$dsDiag.Trace($mNodesToSelect)
		
		$nodes = $global:m_ScXML.SelectNodes($mNodesToSelect)
		$response = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowWarning("Are you sure you want to delete this Object? All Children will be deleted!", "Artaker", "YesNo" )
		if ($response -eq "Yes")
		{
			foreach ($node in $nodes)
			{
				$node.ParentNode.RemoveChild($node)
			}
		}
		$global:m_ScXML.Save($global:mScFile)
		return $true
	}
	catch
	{
		return $false
	}
}

# Define a function to recursively search for nodes by name and attribute value
function FindXmlNodeByNameAndAttribute($node, $nodeName, $attributeName, $attributeValue)
{
	if ($node -ne $null -and $node.Name -eq $nodeName -and $node[$attributeName] -eq $attributeValue)
	{
		return $node
	}
    
	foreach ($childNode in $node.ChildNodes)
	{
		$result = FindXmlNodeByNameAndAttribute $childNode $nodeName $attributeName $attributeValue
		if ($result -ne $null)
		{
			return $result
		}
	}
    
	return $null
}

#endregion Generate TreeView

#region Working Functions

function mGetIconSource
{
	param (
		$ImageMetaData
	)

	[string]$ImagePath = "C:\ProgramData\Artaker\Icons\Icons" + $Global:currentTheme + "\Unknown_Sc_16x16.png"

	if ($ImageMetaData -like "*.iam?*")
	{
		return $ImagePath = "C:\ProgramData\Artaker\Icons\Icons" + $Global:currentTheme + "\IAM_Sc_16x16.png" 
	}
	if ($ImageMetaData -like '*.ipt?*')
	{
		return $ImagePath = "C:\ProgramData\Artaker\Icons\Icons" + $Global:currentTheme + "\IPT_Sc_16x16.png"
	}
	if ($ImageMetaData -like '*.ipn?*')
	{
		return $ImagePath = "C:\ProgramData\Artaker\Icons\Icons" + $Global:currentTheme + "\IPN_Sc_16x16.png"
	}
	if ($ImageMetaData -like "*.idw?*")
	{
		return $ImagePath = "C:\ProgramData\Artaker\Icons\Icons" + $Global:currentTheme + "\IDW_Sc_16x16.png"
	}
	if ($ImageMetaData -like '*.dwg?*')
	{
		return $ImagePath = "C:\ProgramData\Artaker\Icons\Icons" + $Global:currentTheme + "\DWG_Sc_16x16.png"
	}
	if ($ImageMetaData -like '*TAG=Folder*')
	{
		$FolderTemplate = "C:\ProgramData\Artaker\Icons\Icons" + $Global:currentTheme + "\FolderScToRecolor_16.png"
		#extract ARGB part of ImageMetaData
		$ARGB = [Regex]::Matches($ImageMetaData, "\[A\=\d{1,3}, R\=\d{1,3}, G\=\d{1,3}, B\=\d{1,3}\]")[0].Value.TrimStart("[").TrimEnd(']')
		#create string array for ARGB values
		$ARGBValues = [Regex]::Matches($ARGB, "\d{1,3}")
		#build file name for recolored image
		$FlrdArgbName = "C:\ProgramData\Artaker\Icons\ShortCuts\FolderScColored-$($ARGBValues[0].Value)-$($ARGBValues[1].Value)-$($ARGBValues[2].Value)-$($ARGBValues[3].Value)_16.png"		
		#check if file exists and create it if it doesn't
		if (Test-Path $FlrdArgbName)
		{
			return $ImagePath = $FlrdArgbName
		}
		else
		{
			#create a folder image with the ARGB values applied
			$ImageRecolored = mReplaceColor -ImagePath $FolderTemplate -OldColor ([System.Drawing.Color]::FromArgb(255, 255, 0, 0)) -NewColor ([System.Drawing.Color]::FromArgb($ARGBValues[0].Value, $ARGBValues[1].Value, $ARGBValues[2].Value, $ARGBValues[3].Value))
			#save the recolored image the the user's temp folder
			$ImageRecolored.Save($FlrdArgbName)
			$ImageRecolored.Dispose()
			return $FlrdArgbName
		}	
 }	
	
	return $ImagePath
}

function mReplaceColor
{
	param (
		[string]$ImagePath,
		[System.Drawing.Color]$OldColor,
		[System.Drawing.Color]$NewColor
	)
  
	# Load the image from the file
	$Image = [System.Drawing.Image]::FromFile($ImagePath)
  
	# Create a new bitmap object with the same size as the image
	$Bitmap = New-Object System.Drawing.Bitmap($Image.Width, $Image.Height)
  
	# Loop through each pixel of the image
	for ($x = 0; $x -lt $Image.Width; $x++)
	{
		for ($y = 0; $y -lt $Image.Height; $y++)
		{
  
			# Check if the color matches the old color and replace in case
			$PixelColor = $Image.GetPixel($x, $y)
			if ($PixelColor.Name -eq $OldColor.Name)
			{  
				$Bitmap.SetPixel($x, $y, $NewColor)
			}
			else
			{  
				# keep the original color
				$Bitmap.SetPixel($x, $y, $PixelColor)
			}
		}
	}
  
	# Dispose the image object and return the new bitmap
	$Image.Dispose()
	return $Bitmap
}

function mGetShortcutXML
{
	# OLD CODE WORKING

	$m_Server = $VaultConnection.Server.Replace(":", "_").Replace("/", "_").Replace(".", "\.")
	$m_Vault = $VaultConnection.Vault

	$AllXMLFiles = @()
	$XMLFilterFiles = @()
	$ShortCutXMLPath = "$($env:APPDATA)\Autodesk\VaultCommon\Servers\"
	$AllXMLFiles += Get-ChildItem -Path $ShortCutXMLPath -Filter 'Shortcuts.xml' -Recurse

	$ShortCutXMLPathEscaped = $ShortCutXMLPath.Replace("/", "_").Replace("\", "\\").Replace(".", "\.")

	$RegEx = [regex]"$($ShortCutXMLPathEscaped)Services_Security_\d{1,2}_\d{1,2}_\d{1,4}\\$($m_Server)\\Vaults\\$($m_Vault)\\Objects\\Shortcuts\.xml"

	foreach ($XMLFile in $AllXMLFiles)
	{
		if ($RegEx.Match($XMLFile.FullName).Success -eq $true)
		{
			$XMLFilterFiles += $XMLFile
		}
	}


	if ($XMLFilterFiles.count -gt 0) 
	{
		$global:mScFile = $XMLFilterFiles.SyncRoot[$XMLFilterFiles.Count - 1].FullName
	}
	else
	{
		$global:m_ScXML = $null
		return 
	}

	if (Test-Path $global:mScFile)
	{
		$global:m_ScXML = New-Object XML 
		$global:m_ScXML.Load($mScFile)
		
		$global:Namespace = New-Object -TypeName "Xml.XmlNamespaceManager" -ArgumentList $global:m_ScXML.NameTable
		$global:Namespace.AddNamespace("ns", $global:m_ScXML.DocumentElement.NamespaceURI)
		$global:Namespace.AddNamespace("xmlns:xsd", "http://www.w3.org/2001/XMLSchema")
		$global:Namespace.AddNamespace("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
	}
	else
	{
		$global:m_ScXML = $null
		return 
	}

	return $global:m_ScXML
}

#endregion Working Functions


#region Support Functions

# used to check if a node is already existing
function mCheckUniqueNodeByName ($nameToCheck)
{

	if ([string]::IsNullOrEmpty($nameToCheck))
	{
		return $false
	}

	foreach ($node in $Global:m_ScTreeList)
	{
		if ($node.name -contains $nameToCheck)
		{
			return $false
		}
	}
	return $true
}
#endregion Support Functions


#region TreeView MenuItem Functions

function ActivateAutodeskVaultShortCut
{
	$selectedItemObject = $null
	$selectedItemObject = $DsWindow.FindName("TreeViewAutodeskVaultShortCuts").SelectedItem
	$wsPath = ($Prop["_WorkspacePath"].Value).Replace("\", "")
	$newURI = $selectedItemObject.URI.Replace("vaultfolderpath:$/$($wsPath)/", "").replace("/", "\")
	$Prop["$($Global:WorkingFolder)"].Value = $newURI
}

function RemoveAutodeskVaultShortCutOrShortCutGroup
{
	# ADD REMOVE GROUP
	try
	{
        
		$selectedItemObject = $null
        
		$selectedItemObject = $DsWindow.FindName("TreeViewAutodeskVaultShortCuts").SelectedItem
		if ($true -eq $selectedItemObject.IsEditable)
		{
			mRemoveShortcutByName $selectedItemObject.Name $selectedItemObject.IsGroup
			#rebuild the tree view to include the new shortcut
			ReadAutodeskVaultShortCuts
		}
	}
	catch
	{ 
		Show-ArtakerMessageBox -Message "Failed to remove item" -Title "Artaker DataStandard" -Button "Ok" -Icon "ERROR"
	}
}

Function AddAutodeskVaultFolderShortCut
{

	if ([string]::IsNullOrEmpty($global:m_ScXML))
	{
		Show-ArtakerMessageBox -Message "No Shortcuts.xml found, please add a Shortcut inside Vault!" -Title "Artaker DataStandard" -Button "Ok" -Icon "Information"
		return $null
	}


	$selectedItemObject = $DsWindow.FindName("TreeViewAutodeskVaultShortCuts").SelectedItem
	$xPathQuery = "//*[@Name='$($selectedItemObject.Name)']"
	$parentNode = $global:m_ScXML.SelectSingleNode($xPathQuery)
	
	$LastPath = $Prop["$($Global:WorkingFolder)"].Value.Split("\") | Select-Object -Last 1
	$WpfMessageBoxReturnValues = Show-WpfMessageBox -LabelText "Name" -TextBoxText "$($LastPath)"

	if ( $WpfMessageBoxReturnValues.DialogResult -eq $false)
	{
		return
	}

	$scName = $WpfMessageBoxReturnValues.FindName("TextBoxWpfMessageBox").Text

	if (mCheckUniqueNodeByName $scName)
	{
		# add group to tree view
		mAddShortcutByName $scName $parentNode
		ReadAutodeskVaultShortCuts	
	}
	else 
	{
		Show-ArtakerMessageBox -Message "Name must be unique!" -Title "Artaker DataStandard" -Button "Ok" -Icon "Information"
	}
}

function AddAutodeskVaultShortGroup
{
	if ([string]::IsNullOrEmpty($global:m_ScXML))
	{
		Show-ArtakerMessageBox -Message "No Shortcuts.xml found, please add a Shortcut inside Vault!" -Title "Artaker DataStandard" -Button "Ok" -Icon "Information"
		return $null
	}
	
	$selectedTreeItem = $DsWindow.FindName("TreeViewAutodeskVaultShortCuts").SelectedItem

	$xPathQuery = "//*[@Name='$($selectedTreeItem.Name)']"
	$parentNode = $global:m_ScXML.SelectSingleNode($xPathQuery)

	$WpfMessageBoxReturnValues = Show-WpfMessageBox -LabelText "Name" -TextBoxText "New Group"

	if ( $WpfMessageBoxReturnValues.DialogResult -eq $false)
	{
		return
	}

	$groupName = $WpfMessageBoxReturnValues.FindName("TextBoxWpfMessageBox").Text
	
	if (mCheckUniqueNodeByName $groupName)
	{
		# add group to tree view
		mAddGroupByName $groupName $parentNode
		ReadAutodeskVaultShortCuts
	}
	else 
	{
		Show-ArtakerMessageBox -Message "Name must be unique!" -Title "Artaker DataStandard" -Button "Ok" -Icon "Information"
	}
    
}


Function RenameAutodeskVaultShortCutOrShortCutGroup
{

	$selectedItemObject = $DsWindow.FindName("TreeViewAutodeskVaultShortCuts").SelectedItem

	if ($null -ne $selectedItemObject -and $selectedItemObject.IsEditable)
	{

		$xmlNS = New-Object System.Xml.XmlNamespaceManager($global:m_ScXML.NameTable)
		$xmlNS.AddNamespace("plm", "http://schemas.autodesk.com/msd/plm/Shortcuts/2004-08-16")

		$xPathQuery = "//*[@Name='$($selectedItemObject.Name)']"
		$xmlItem = $global:m_ScXML.SelectSingleNode($xPathQuery)
        
		$WpfMessageBoxReturnValues = Show-WpfMessageBox -LabelText "Name" -TextBoxText $selectedItemObject.Name
		$newName = $WpfMessageBoxReturnValues.FindName("TextBoxWpfMessageBox").Text


		if (mCheckUniqueNodeByName $newName)
		{
			$xmlItem.SetAttribute("Name", $newName)
        
			#Save the changes to the XML file
			$global:m_ScXML.Save($mScFile)
			
			ReadAutodeskVaultShortCuts
		}
		else 
		{
			Show-ArtakerMessageBox -Message "Name must be unique!" -Title "Artaker DataStandard" -Button "Ok" -Icon "Information"
		}
	}
	else 
	{
		Show-ArtakerMessageBox -Message "nothing selected!`nShortCut or GroupFolder is valid selection" -Title "Artaker DataStandard" -Button "Ok" -Icon "Information"
	}
}

#endregion TreeView MenuItem Functions

#region Handle TreeView MenuItem Visibility

Function SetRemoveSelectionInTreeView
{
	param
	(
		$selectedItemObject,
		[bool]$SelectTreeNode = $false
	)

	$TreeView = $DsWindow.FindName("TreeViewAutodeskVaultShortCuts")
    
	if (-not $selectedItemObject)
	{
		$selectedItemObject = $TreeView.SelectedItem
	}

	if ($selectedItemObject)
	{
		$container = GetSelectionInTreeViewRecursive -root $TreeView -selection  $selectedItemObject

		if ($container)
		{
			$container.IsSelected = $SelectTreeNode
		}
	}
}

#endregion Handle TreeView MenuItem Visibility

Function GetSelectionInTreeViewRecursive
{
	param
	(
		$root,
		$selection
	)



	$NewObject = $root.Items | Where-Object { $_.Name -eq $selection.Name -and $_.FullPath -eq $selection.FullPath }
        
	if ($NewObject)
	{ 
		# Select First in Case two Nodes with the Same Name in the Same FullPath are preset
		$selection = $NewObject | Select-Object -first 1
	}


	$item = $root.ItemContainerGenerator.ContainerFromItem($selection)
    
	if ($null -eq $item)
	{
		foreach ($subItem in $root.Items)
		{
			if ($subItem.Children.count -gt 0)

			{

				$ChildContainer = $root.ItemContainerGenerator.ContainerFromItem($subItem)
				if ($ChildContainer.ItemContainerGenerator.Status -eq "NotStarted")
				{
					#$ChildContainer.Focus()
					$ChildContainer.UpdateLayout()
				}
				$item = GetSelectionInTreeViewRecursive -root $ChildContainer -Selection $selection
			}
			if ($item)
			{
				break;
			}
		}
	}
	return $item;
}



#region UI
function OnSelectedItemChanged
{
	param (
		[Object]$sender,
		[System.Windows.RoutedPropertyChangedEventArgs[Object]]$e
	)
	$DsWindow.FindName("MenuItemSelectShortCut").Visibility = "Collapsed"
	$DsWindow.FindName("MenuItemAddFolderShortCut").Visibility = "Collapsed"
	$DsWindow.FindName("MenuItemAddGroup").Visibility = "Collapsed"
	$DsWindow.FindName("ShortcutEditSep").Visibility = "Collapsed"
	$DsWindow.FindName("MenuItemDeleteShortCutorShortCutGroup").Visibility = "Collapsed"
	$DsWindow.FindName("MenuItemRenameShortCutorShortCutGroup").Visibility = "Collapsed"
	$DsWindow.FindName("ShortcutClearSep").Visibility = "Collapsed"
	$DsWindow.FindName("MenuItemClearSelection").Visibility = "Visible"

	$selectedItem = $DsWindow.FindName("TreeViewAutodeskVaultShortCuts").SelectedItem
	
	if ($selectedItem.Name -eq "My Shortcuts")
	{
		$DsWindow.FindName("MenuItemAddFolderShortCut").Visibility = "Visible"
		$DsWindow.FindName("MenuItemAddGroup").Visibility = "Visible"
		$DsWindow.FindName("ShortcutClearSep").Visibility = "Visible"
		$DsWindow.FindName("MenuItemClearSelection").Visibility = "Visible"
		
		return
	}
	elseif ($selectedItem.Name -eq "Distributed Shortcuts" )
	{
		
	}
	else
	{
		if (!$selectedItem.IsGroup -and $selectedItem.IsEditable)
		{
			$DsWindow.FindName("MenuItemSelectShortCut").Visibility = "Visible"
			$DsWindow.FindName("MenuItemAddFolderShortCut").Visibility = "Collapsed"
			$DsWindow.FindName("MenuItemAddGroup").Visibility = "Collapsed"
			$DsWindow.FindName("ShortcutEditSep").Visibility = "Visible"
			$DsWindow.FindName("MenuItemDeleteShortCutorShortCutGroup").Visibility = "Visible"
			$DsWindow.FindName("MenuItemRenameShortCutorShortCutGroup").Visibility = "Visible"
			$DsWindow.FindName("ShortcutClearSep").Visibility = "Visible"
			$DsWindow.FindName("MenuItemClearSelection").Visibility = "Visible"
		}	
		elseif ($selectedItem.IsGroup -and $selectedItem.IsEditable)
		{
			$DsWindow.FindName("MenuItemSelectShortCut").Visibility = "Collapsed"
			$DsWindow.FindName("MenuItemAddFolderShortCut").Visibility = "Visible"
			$DsWindow.FindName("MenuItemAddGroup").Visibility = "Visible"
			$DsWindow.FindName("ShortcutEditSep").Visibility = "Visible"
			$DsWindow.FindName("MenuItemDeleteShortCutorShortCutGroup").Visibility = "Visible"
			$DsWindow.FindName("MenuItemRenameShortCutorShortCutGroup").Visibility = "Visible"
			$DsWindow.FindName("ShortcutClearSep").Visibility = "Visible"
			$DsWindow.FindName("MenuItemClearSelection").Visibility = "Visible"
		}
		elseif (!$selectedItem.IsGroup -and !$selectedItem.IsEditable)
		{
			$DsWindow.FindName("MenuItemSelectShortCut").Visibility = "Visible"
			$DsWindow.FindName("MenuItemAddFolderShortCut").Visibility = "Collapsed"
			$DsWindow.FindName("MenuItemAddGroup").Visibility = "Collapsed"
			$DsWindow.FindName("ShortcutEditSep").Visibility = "Collapsed"
			$DsWindow.FindName("MenuItemDeleteShortCutorShortCutGroup").Visibility = "Collapsed"
			$DsWindow.FindName("MenuItemRenameShortCutorShortCutGroup").Visibility = "Collapsed"
			$DsWindow.FindName("ShortcutClearSep").Visibility = "Visible"
			$DsWindow.FindName("MenuItemClearSelection").Visibility = "Visible"
		}
		else
		{
			$DsWindow.FindName("MenuItemSelectShortCut").Visibility = "Collapsed"
			$DsWindow.FindName("MenuItemAddFolderShortCut").Visibility = "Collapsed"
			$DsWindow.FindName("MenuItemAddGroup").Visibility = "Collapsed"
			$DsWindow.FindName("ShortcutEditSep").Visibility = "Collapsed"
			$DsWindow.FindName("MenuItemDeleteShortCutorShortCutGroup").Visibility = "Collapsed"
			$DsWindow.FindName("MenuItemRenameShortCutorShortCutGroup").Visibility = "Collapsed"
			$DsWindow.FindName("ShortcutClearSep").Visibility = "Collapsed"
			$DsWindow.FindName("MenuItemClearSelection").Visibility = "Visible"
		}
	}

	$dsDiag.Trace("SELECTION IS Valid: " + $selectedItem.Name)
}

#endregion UI