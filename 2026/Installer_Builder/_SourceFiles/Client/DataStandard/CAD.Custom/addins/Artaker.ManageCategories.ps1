function SetCategory
{ 
    #$dsDiag.Trace(">> SetCategory")
    switch ($Document.DocumentSubType.DocumentSubTypeID)
    {
        # detect Part Document
        "{4D29B490-49B2-11D0-93C3-7E0706000000}"
        {
            $iPartFactory = $Document.ComponentDefinition.IsiPartFactory()
            $iPartMember = $Document.ComponentDefinition.IsiPartMember()
            # iPart Factory
            if ($iPartFactory -eq $true)
            {
                $prop["_Category"].Value = "Inventor iPart Mutter"
            }
            # iPart Member
            elseif ($iPartMember -eq $true)
            {
                $prop["_Category"].Value = "Inventor iPart Kind"
            }
            # Standardpart
            elseif ($iPartMember -eq $false -and $iPartFactory -eq $false)
            {
                $Prop["_Category"].Value = "Inventor Bauteil"
            }
        }

        # detect Sheet Metal Document
        "{9C464203-9BAE-11D3-8BAD-0060B0CE6BB4}"
        {
            $Prop["_Category"].Value = "Inventor Bauteil"
        }

        # dectect Assembly Document
        "{E60F81E1-49B3-11D0-93C3-7E0706000000}"
        {
            $iAssemblyFactory = $Document.ComponentDefinition.IsiAssemblyFactory()
            $iAssemblyMember = $Document.ComponentDefinition.IsiAssemblyMember()
            # iAssembly Factory
            if ($iAssemblyFactory -eq $true)
            {
                $prop["_Category"].Value = "Inventor iAssembly Mutter"
            }
            # iAssembly Member
            elseif ($iAssemblyMember -eq $true)
            {
                $prop["_Category"].Value = "Inventor iAssembly Kind"
            }
            # Standardassembly
            elseif ($iAssemblyMember -eq $false -and $iAssemblyFactory -eq $false)
            {
                $Prop["_Category"].Value = "Inventor Baugruppe"
            }
        }
        
        # dectect Drawing Document
        "{BBF9FDF1-52DC-11D0-8C04-0800090BE8EC}"
        {
            $Prop["_Category"].Value = "Inventor Zeichnung"
        }
        
        # dectect IPN Document
        "{76283A80-50DD-11D3-A7E3-00C04F79D7BC}"
        {
            $Prop["_Category"].Value = "Inventor Praesentation"
        }
    }
    #$dsDiag.Trace("<< SetCategory")
}