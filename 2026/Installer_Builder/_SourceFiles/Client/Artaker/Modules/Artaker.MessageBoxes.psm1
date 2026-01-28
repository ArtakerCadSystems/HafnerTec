Function Show-WpfMessageBox
{
    param
    (
        [string]$LabelText,
        [string]$TextBoxText
    )
    add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase
    [xml]$xamlMessageBox = [System.IO.File]::ReadAllText("C:\ProgramData\Artaker\Dialogs\Artaker.WpfMessageBox.xaml", [System.Text.Encoding]::UTF8)
    $readerMessageBox = New-Object System.Xml.XmlNodeReader $xamlMessageBox
    $MessageBoxwindow = [Windows.Markup.XamlReader]::Load($readerMessageBox)

    $MessageBoxwindow.add_Loaded( {
            
            $MessageBoxwindow.FindName("LabelWpfMessageBox").Content = $LabelText
            $MessageBoxwindow.FindName("TextBoxWpfMessageBox").Text = $TextBoxText

            $MessageBoxwindow.FindName("ButtonOKWpfMessageBox").add_Click( {
                    # $ReturnValue = $MessageBoxwindow.FindName("TextBoxWpfMessageBox").Text
                    $MessageBoxwindow.DialogResult = $True
                    [void]$MessageBoxwindow.Close()
                })
        })
        
    [void]$MessageBoxwindow.ShowDialog()
    return $MessageBoxwindow #.Content.Children | Select-Object Name, Text
}

function Show-ArtakerMessageBox
{
    param
    (
        [String]$Message = "Default Text",
        [String]$Title = "Artaker MessageBox",
        [ValidateSet("Abort", "ContinueCancel", "None", "Ok", "OkCancel", "RetryCancel", "SkipAll", "YesNo", "YesNoCancel")][String]$Button = "Ok",
        [ValidateSet("Error", "Information", "Warning")][String]$Icon = "Information"
    )
    
    <#
    BUTTON Definition

    Abort The dialog contains an Abort button. 
    ContinueCancel The dialog contains a Continue and a Cancel button. 
    None The dialog contains a default OK button. 
    Ok The dialog contains an OK button. 
    OkCancel The dialog contains an OK and a Cancel button. 
    RetryCancel The dialog contains a Retry and a Cancel button. 
    SkipAll The dialog contains a Skip, Skip All, and an OK Button. 
    YesNo The dialog contains a Yes and a No button. 
    YesNoCancel The dialog contains a Yes, No and a Cancel button. 
      #> 
    <#
      try
    {
        [System.Reflection.Assembly]::LoadFrom("C:\Programme\Autodesk\Vault Client 2024\Explorer\Autodesk.DataManagement.Client.Framework.Forms.dll") | out-null
    }
    catch
    {
      
    }
 #>
    Switch ($Icon)
    {
        { $_ -eq "Error" }
        {
            $Result = [Autodesk.DataManagement.Client.Framework.Forms.Library]::"ShowError"($Message, $Title)
        }
        { $_ -eq "Information" }
        {
            $Result = [Autodesk.DataManagement.Client.Framework.Forms.Library]::"ShowMessage"($Message, $Title, $Button)
        }
        { $_ -eq "Warning" }
        {
           
            $Result = [Autodesk.DataManagement.Client.Framework.Forms.Library]::"ShowWarning"($Message, $Title, $Button)
        }
    }

    return  $Result 
}

function Show-ArtakerVaultRestriction
{
    param
    (
        [string]$Description = "Default Text in Dialog",    

        [String]$TextRestrictedObjectNameColumnCaption = "Text Column 1",
        [String]$TextRestrictionColumnCaption = "Text Column 2",
        [String]$TextReasonColumnCaption = "Text Column 3",


        [string]$RestrictedObjectNameColumnCaption = "Header ColumnHeader 1",
        [String]$RestrictionColumnCaption = "Header ColumnHeader 2",
        [string]$ReasonColumnCaption = "Header ColumnHeader 3",

        [String]$Title = "Artaker Restriction MessageBox",
        [Boolean]$DisplayMessage1InDescription = $true,
        [ValidateSet("Info", "Error", "Warning")][String]$Icon = "Error"
    )

    try
    {
        [System.Reflection.Assembly]::LoadFrom("C:\Program Files\Autodesk\Vault Client 2024\Explorer\Autodesk.DataManagement.Client.Framework.dll") | out-null
        [System.Reflection.Assembly]::LoadFrom("C:\Program Files\Autodesk\Vault Client 2024\Explorer\Autodesk.DataManagement.Client.Framework.Forms.dll") | out-null
    }
    catch
    {
        
    }
   
    $NewRestriction = New-Object Autodesk.DataManagement.Client.Framework.Currency.Restriction( "$($TextRestrictedObjectNameColumnCaption)", "$($TextRestrictionColumnCaption)", "$($TextReasonColumnCaption)");
    
    # Info Error, Warning
    $showRestrictionsSettings = New-Object Autodesk.DataManagement.Client.Framework.Forms.Settings.ShowRestrictionsSettings("$($Title)", $Icon)

    $showRestrictionsSettings.AddRestriction($NewRestriction)
    $showRestrictionsSettings.ShowDetailsArea = $true;
    $showRestrictionsSettings.RestrictionColumnCaption = $RestrictionColumnCaption;
    $showRestrictionsSettings.RestrictedObjectNameColumnCaption = $RestrictedObjectNameColumnCaption;
    $showRestrictionsSettings.ReasonColumnCaption = $ReasonColumnCaption;
    
    if ($DisplayMessage1InDescription -eq $true)
    {
        $showRestrictionsSettings.SetDescription("$($Description) {0}");
    }
    else
    {
        $showRestrictionsSettings.SetDescription("$($Description)");
    }


    $result = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowRestrictions($showRestrictionsSettings)

    return $result
}