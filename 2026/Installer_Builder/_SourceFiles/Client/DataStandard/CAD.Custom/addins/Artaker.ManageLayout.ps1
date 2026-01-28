function SetLayout
{
    $dsWindow.FindName("LabelNumScheme").Visibility = $collapsed
    $dsWindow.FindName("ComboBoxNumScheme").Visibility = $collapsed

    $dsWindow.FindName("LabelGeneratedNumber").Visibility = $collapsed
    $dsWindow.FindName("DSNumSchmsCtrl").Visibility = $collapsed
    
    if (@(".idw", ".ipn", ".iam") -contains $Prop["_FileExt"].Value)
    {
        $dsWindow.FindName("GroupBoxPhysicalProperties").Visibility = $collapsed
    }

    if ($Prop["_CreateMode"].Value)
    {
        $dsWindow.FindName("ExpanderShortCuts").IsExpanded = $true
        $dsWindow.FindName("ExpanderAdditional").IsExpanded = $false
        $dsWindow.FindName("TextBoxFileName").Text = "wird generiert"
    }
    # EditMode
    else
    {
        $dsWindow.FindName("TextBoxFileName").Text = $Prop["Part Number"].Value
    }

    if (@(".idw", ".ipn") -contains $Prop["_FileExt"].Value)
    {
        $dsWindow.FindName("TextBoxDescription").IsReadOnly = $true
        $dsWindow.FindName("TextBoxStocknumber").IsReadOnly = $true
        $dsWindow.FindName("TextBoxComments").IsReadOnly = $true
    }
}
