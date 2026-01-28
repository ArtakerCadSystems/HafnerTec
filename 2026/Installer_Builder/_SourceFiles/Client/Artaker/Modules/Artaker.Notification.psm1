Function New-ArtakerNotification
{
    [cmdletBinding()]
    Param(
      
        [Parameter(Mandatory, Position = 0)][String]$headlineText,
        [Parameter(Position = 1)][String]$bodyText,
        [Parameter(Position = 2)][String]$Logo = "C:\Program Files\WindowsPowerShell\Modules\BurntToast\0.6.2\Images\BurntToast.png",
        [Parameter(Position = 3)][String]$MessageCenterGroup,
        [Parameter(Position = 4)][int]$ExpirationTime
    )
    
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null

    # Toasts templates: 
    # https://msdn.microsoft.com/en-us/library/windows/apps/hh761494.aspx
       
    # # $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
    # # $toastXml = [xml] $template.GetXml()
    # # # Customize the toast message
    # # $toastXml.GetElementsByTagName(“text”)[0].AppendChild($toastXml.CreateTextNode(“Script test”)) > $null
    # # $toastXml.GetElementsByTagName(“text”)[1].AppendChild($toastXml.CreateTextNode(“Customizated notification: ” + [DateTime]::Now.ToShortTimeString())) > $null

    # Sounds:
    # https://docs.microsoft.com/en-us/uwp/schemas/tiles/toastschema/element-audio


    $XmlString = @"
<toast>
    <visual>
        <binding template="ToastImageAndText03">
            <image id="1" src="$($logo)" hint-crop="circle"/>
            <text id="1">$($headlineText)</text>
            <text id="2">$($bodyText)</text>
        </binding>  
    </visual>
    <audio src="ms-winsoundevent:Notification.SMS" loop="false"/>
</toast>
"@  

    #$xml = New-Object xml
    # Convert back to WinRT type
    $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
    $xml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml($XmlString)
    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
    

    # Unique Application id/tag and group
    $toast.Tag = $MessageCenterGroup
    $toast.Group = $headlineText
    $toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes($ExpirationTime)

    # Create the toats and show the toast. Make sure to include the AppId
    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($toast.Tag)
    $notifier.Show($toast);

}

#New-ArtakerNotification -headlineText "Das ist die erste Zeile mit Wrap2" -bodyText "Body Text" -Logo "C:\Users\Adskjs\Desktop\Artaker_S.png" -MessageCenterGroup "ArtakerDataStandard" -ExpirationTime 2