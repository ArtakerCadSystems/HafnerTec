Function Artaker-Get-XMLFile
{
	Param
	(
		[Parameter(Mandatory)]
		[string]$FullXmlFilePath,
		[Parameter(Mandatory)]
		[string]$BaseFolder,
		[Parameter(Mandatory)]
		[bool]$CreateXmlFile,
		[string]$xmlns
	)
	
	if (Test-Path $FullXmlFilePath)
	{
		# XML exist
		$XmlObject = New-Object xml
		$XmlObject.Load($FullXmlFilePath)
  
		$XmlNamespace = New-Object -TypeName "Xml.XmlNamespaceManager" -ArgumentList $XmlObject.NameTable
		$XmlNamespace.AddNamespace("ns", $XmlObject.DocumentElement.NamespaceURI)
		$XmlNamespace.AddNamespace("xmlns:xsd", "http://www.w3.org/2001/XMLSchema")
		$XmlNamespace.AddNamespace("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")


		if ($xmlObject.DocumentElement.Name -ne $BaseFolder)
		{
			return $null
		}
	}
	elseif ($CreateXmlFile -eq $true)
	{
		# XML does not exist
		if ((Test-Path -Path (Split-Path $FullXmlFilePath)) -eq $false)
		{
			$NewFolder = New-Item -ItemType Directory -Path (Split-Path $FullXmlFilePath)
		}

		$xmlnsObject = "http://schemas.Artaker.com/xml/$($xmlns)/2020-12-29"

		# Create XML and Root Object
		$xmlObject = New-Object xml
		$xmlObject = [xml] "<?xml version='1.0' encoding='utf-8'?><$BaseFolder xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns='$xmlnsObject' />"
		
		#Save XML File
		$xmlObject.Save($FullXmlFilePath)
	}
	
	return $xmlObject, $XmlNamespace
}

# $FullXmlFilePath = "C:\ProgramData\Artaker\ServerTasks\Artaker.Vault.ServerTasks.xml"
# $BaseFolder = "DataSet"
# $Result = Artaker-Get-XMLFile -FullXmlFilePath $FullXmlFilePath -BaseFolder $BaseFolder

# Info: Reads XML Nodes or Attributes
# Sampe Requests
# $xmlNode = Read-NodeOrAttributeFromXmlObject -xmlObject $xmlObject -ParrentFolder "Products" -NodeFolder "Product"
# $xmlAttribute = Read-NodeOrAttributeFromXmlObject -xmlObject $xmlObject -ParrentFolder "Products" -NodeFolder "Product" -AttrName "featureid"
# $xmlAttribute = Read-NodeOrAttributeFromXmlObject -xmlObject $xmlObject -NodeFolder "Daniel" -AttrName "Name1"
function Read-NodeOrAttributeFromXmlObject
{
	# Argumente definieren
	Param
	(
		[Parameter(Mandatory)]
		[STRING]$FullXmlFilePath,
		[Parameter(Mandatory)]
		[String]$BaseFolder,
		[Parameter(Mandatory = $false)]
		[String]$ParrentFolder,
		[Parameter(Mandatory)]
		[STRING]$NodeFolder,
		[Parameter(Mandatory = $false)]
		[STRING]$AttrName
	)
	
	if ($EnableLogging -eq $true)
	{
		WriteLogging -Message  ">> Read-NodeOrAttributeFromXmlObject"
	}
	
	$xmlObject = Get-XMLFile -xmlFile $FullXmlFilePath -BaseFolder $BaseFolder
	
	# Chef if XML Object exist
	if ($xmlObject)
	{
		if ([string]::IsNullOrEmpty($ParrentFolder))
		{
			# no Parrent Folder
			$xmlNodeFolder = $xmlObject.$BaseFolder.$NodeFolder
		}
		else
		{
			# with Parrent Folder
			$xmlNodeFolder = $xmlObject.$BaseFolder.$ParrentFolder.$NodeFolder
		}
		
		# Get Attribute if exist an return Attribute Value
		if ($xmlNodeFolder -and $AttrName)
		{
			# XML Attribut vorhanden
			if ($xmlNodeFolder.HasAttribute($AttrName))
			{
				#ArtakerLogToFile -LogFileName $LogFileName  -Message "return XML Attribute" -LogState "INFO" -LogLevel $LogLevel
				return $xmlNodeFolder.$AttrName
			}
		}
		# Argument für Attributname nicht vorhanden -> xmlNodeFolder zurück geben
		else
		{
			#ArtakerLogToFile -LogFileName $LogFileName  -Message "return XMLNode" -LogState "INFO" -LogLevel $LogLevel
			#ArtakerLogToFile -LogFileName $LogFileName  -Message "<< xmlUserDataRead" -LogState "INFO" -LogLevel $LogLevel
			return $xmlNodeFolder
		}
		
	}
	else
	{
		# XML Data not found, create NewOne
		$xmlObject = Get-XMLFile -xmlFile $FullXmlFilePath -BaseFolder "DataSet"
	}
	if ($EnableLogging -eq $true)
	{
		WriteLogging -Message  "<< Read-NodeOrAttributeFromXmlObject"
	}
}

function Write-NodeToXMLObject
{
	# Argumente definieren
	Param
	(
		[Parameter(Mandatory)]
		[STRING]$FullXmlFilePath,
		[Parameter(Mandatory)]
		[String]$BaseFolder,
		[Parameter(Mandatory = $false)]
		[STRING]$ParrentFolder,
		[Parameter(Mandatory)]
		[STRING]$NodeFolder,
		[Parameter(Mandatory)]
		[Hashtable]$HashTable,
		[Parameter(Mandatory)]
		[bool]$ForceCreateNode
	)
	
	if ($EnableLogging -eq $true)
	{
		WriteLogging -Message  ">> Write-NodeToXMLObject"
	}
	
	$xmlObject = Get-XMLFile -xmlFile $FullXmlFilePath -BaseFolder $BaseFolder
	$BaseFolder = $xmlObject.DocumentElement.Name
	# Parrent Folder required
	if (-not [string]::IsNullOrEmpty($ParrentFolder))
	{
		# get Parrent Folder
		try
		{
			$xmlParrentFolder = $xmlObject.$BaseFolder.get_Item($ParrentFolder)
		}
		catch
		{
			
		}
		
		
		if (-not $xmlParrentFolder)
		{
			# Parrent Folder does not exist
			$xmlParrentFolder = $xmlObject.CreateElement($ParrentFolder)
			$XmlParrentFolder = $xmlObject.$BaseFolder.AppendChild($xmlParrentFolder)
		}
		else
		{
			# Parrent Folder exist in XML
			$xmlParrentFolder = $xmlObject.$BaseFolder.$ParrentFolder
		}
		
		if ($ForceCreateNode -eq $true)
		{
			# Create Node (Force Node Creation)
			$xmlNodeFolder = $xmlObject.CreateElement($NodeFolder)
			$xmlParrentFolder.AppendChild($xmlNodeFolder)
		}
		else
		{
			# get Node if Exist, otherwise create Node
			try
			{
				$xmlNodeFolder = $null
				$XmlNodeFolder = $xmlObject.$BaseFolder.$ParrentFolder.get_Item($NodeFolder)
			}
			catch
			{
				
			}
			
			if (-not $xmlNodeFolder)
			{
				$xmlNodeFolder = $xmlObject.CreateElement($NodeFolder)
				$xmlParrentFolder.AppendChild($xmlNodeFolder)
			}
		}
	}
	else
	{
		# no Parrent Folder Neccesarry
		# get Node if Exist, otherwise create Node
		try
		{
			$xmlNodeFolder = $null
			$XmlNodeFolder = $xmlObject.$BaseFolder.get_Item($NodeFolder)
		}
		catch
		{
			
		}
		
		if (-not $xmlNodeFolder)
		{
			$xmlNodeFolder = $xmlObject.CreateElement($NodeFolder)
			$xmlObject.$BaseFolder.AppendChild($xmlNodeFolder)
		}
		
		
	}
	
	foreach ($HashTableItem in $HashTable.GetEnumerator())
	{
		$xmlNodeFolder.SetAttribute($HashTableItem.Key, $HashTableItem.Value) | Out-Null
	}
	
	
	$xmlObject.save($FullXmlFilePath)
	
	if ($EnableLogging -eq $true)
	{
		WriteLogging -Message  "<< Write-NodeToXMLObject"
	}
	
}

function Remove-NodesInXMLFile
{
	# Argumente definieren
	Param
	(
		[Parameter(Mandatory)]
		[STRING]$FullXmlFilePath,
		[Parameter(Mandatory)]
		[STRING]$BaseFolder,
		[Parameter(Mandatory)]
		[STRING]$ParrentFolder,
		[Parameter(Mandatory)]
		[STRING]$NodeFolder
	)
	
	if ($EnableLogging -eq $true)
	{
		WriteLogging -Message  ">> Remove-NodesInXMLFile"
	}
	
	if (Test-Path $FullXmlFilePath)
	{
		# $xmlObject = Get-XMLFile -xmlFile $XMLReportConfigurationPath -BaseFolder "DataSet"
		$xmlObject = Get-XMLFile -xmlFile $FullXmlFilePath -BaseFolder $BaseFolder
		
		# Ausführen, wenn XML Datei vorhanden
		if ($xmlObject)
		{
			#ArtakerLogToFile -LogFileName $LogFileName  -Message "XmlObject available" -LogState "INFO" -LogLevel $LogLevel
			# XML Hauptordner bestimmen
			$BaseFolder = $xmlObject.DocumentElement.Name
			
			# XML Unterordner vorhanden
			$XmlParrentFolder = $xmlObject.$BaseFolder.$ParrentFolder
			if ($XmlParrentFolder)
			{
				#ArtakerLogToFile -LogFileName $LogFileName  -Message "Parrent Folder available" -LogState "INFO" -LogLevel $LogLevel
				$xmlNodeFolder = $xmlObject.$BaseFolder.$ParrentFolder.$NodeFolder
				
				# Argument für Attributname vorhanden -> Attributtwert überprüfen
				if ($xmlNodeFolder)
				{
					#ArtakerLogToFile -LogFileName $LogFileName  -Message "Node Folder available" -LogState "INFO" -LogLevel $LogLevel
					# Wenn mehrere $xmlNodeFolder mit Namen von $NodeFolder vorhanden
					if ($xmlNodeFolder.Count -gt 1)
					{
						#ArtakerLogToFile -LogFileName $LogFileName  -Message "more than one => Delte" -LogState "INFO" -LogLevel $LogLevel
						foreach ($Item in $xmlNodeFolder)
						{
							$xmlObject.$BaseFolder.$ParrentFolder.RemoveChild($Item)
						}
					}
					
					# Nur ein $xmlNodeFolder mit Namen von $NodeFolder vorhanden
					else
					{
						$xmlObject.$BaseFolder.$ParrentFolder.RemoveChild($xmlNodeFolder)
					}
					
					$xmlObject.$BaseFolder.RemoveChild($XmlParrentFolder)
					$xmlObject.save($FullXmlFilePath)
				}
			}
		}
	}
	
	if ($EnableLogging -eq $true)
	{
		WriteLogging -Message  "<< Remove-NodesInXMLFile"
	}
}