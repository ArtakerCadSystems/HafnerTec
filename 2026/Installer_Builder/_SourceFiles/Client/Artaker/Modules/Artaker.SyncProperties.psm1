Function SyncPropertiesFrom3D
{
    Param
    (
        $SourceDocument,
        $document,
        [bool]$DataStandard
    )
   	try
    {
        $PropsDesignTracking = @("Description", "Stock Number")
        $SourceDocumentDesignTrackingProperties = $SourceDocument.PropertySets.Item("Design Tracking Properties")
        $DocumentDesignTrackingProperties = $document.PropertySets.Item("Design Tracking Properties")
      

        $PropsSummaryInformation = @("Comments")
        $SourceInventorSummaryInformation = $SourceDocument.PropertySets.Item("Inventor Summary Information")
        $InventorSummaryInformation = $document.PropertySets.Item("Inventor Summary Information")
        <#
        $PropsDocumentSummaryInformation = @("Category")
        $SourceDocumentInventorSummaryInformation = $SourceDocument.PropertySets.Item("Inventor Document Summary Information")
        $DocumentInventorSummaryInformation = $document.PropertySets.Item("Inventor Document Summary Information")
        #>

        # $PropsUserDefined = @("Verpackungseinheit", "Produktgruppe", "EchtGewicht", "Komponententyp", "Bezeichnungstext", "Abmessung", "Ausfuehrung", "BezeichnungstextFrei", "Kunde", "Zolltarifnummer", "EAN", "Klemmbereich", "Laenge", "Breite", "Hoehe", "Abmessungberechnet", "Modellgewicht", "Einsatzgewicht", "Geprueft", "Normenbezeichnung", "Oberflaechenbehandlung")
        


        $SourceDocumentInventorUserDefinedProperties = $SourceDocument.PropertySets.Item("Inventor User Defined Properties")
        $DocumentInventorUserDefinedProperties = $document.PropertySets.Item("Inventor User Defined Properties")

        foreach ($PropDesignTracking in $PropsDesignTracking)
        {
            try
            {
                if ($DataStandard -eq $true)
                {
                    $Prop["$($PropDesignTracking)"].Value = $SourceDocumentDesignTrackingProperties.Item("$($PropDesignTracking)").Value
                }
                else 
                {
                    $DocumentDesignTrackingProperties.item("$($PropDesignTracking)").Value = $SourceDocumentDesignTrackingProperties.Item("$($PropDesignTracking)").Value
                }
           
            }
            catch {}
        }

        foreach ($PropDocumentSummaryInformation in $PropsDocumentSummaryInformation)
        {
            try
            {
                if ($DataStandard -eq $true)
                {
                    $Prop["$($PropDocumentSummaryInformation)"].Value = $SourceDocumentInventorSummaryInformation.Item("$($PropDocumentSummaryInformation)").Value
                }
                else 
                {
                    $DocumentInventorSummaryInformation.Item("$($PropDocumentSummaryInformation)").Value = $SourceDocumentInventorSummaryInformation.Item("$($PropDocumentSummaryInformation)").Value
                }
            
            }
            catch {}
        }

        foreach ($PropSummaryInformation in $PropsSummaryInformation)
        {
            try
            {
                if ($DataStandard -eq $true)
                {
                    $Prop["$($PropSummaryInformation)"].Value = $SourceInventorSummaryInformation.Item("$($PropSummaryInformation)").Value
                }
                else 
                {
                    $InventorSummaryInformation.Item("$($PropSummaryInformation)").Value = $SourceInventorSummaryInformation.Item("$($PropSummaryInformation)").Value
                }
            
            }
            catch {}
        }

        foreach ($PropUserDefined in $PropsUserDefined)
        {
            try
            {
                if ($DataStandard -eq $true)
                {
                    $Prop["$($PropUserDefined)"].Value = $SourceDocumentInventorUserDefinedProperties.Item("$($PropUserDefined)").Value
                }
                else 
                {
                    try
                    {
                        $DocumentInventorUserDefinedProperties.item("$($PropUserDefined)").Value = [string]$SourceDocumentInventorUserDefinedProperties.Item("$($PropUserDefined)").Value
                    }
                    catch
                    {
                        $DocumentInventorUserDefinedProperties.Add([string]$SourceDocumentInventorUserDefinedProperties.Item("$($PropUserDefined)").Value, "$($PropUserDefined)") | Out-Null     
                    }
                }
            }
            catch 
            {
            }
        }

    }
    catch
    {
        # in Case of null Values
        Show-ArtakerMessagebox -Message "Konnte Eigenschaften nicht kopieren! Eigenschaften in 3D Model ausgefüllt?" -Title "Artaker DataStandard" -Button "OK" -Icon "Error"
    }
}