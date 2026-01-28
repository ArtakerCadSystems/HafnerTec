# Artaker Logging Module Loader
Add-Type -Path  ($env:ProgramData + "\Artaker\Logging\Artaker.Logger.dll")

# Add-Type -Path "$PSScriptRoot\Artaker.Logger.dll"

Function PrepareLogging
{
    param
    (
        [string]$LogFileName,
        [string]$FolderName = $null
    )

    $DateTimeExport = Get-Date -format yyyy-MM-dd

    $fileLocation = ""
    if (-not [string]::IsNullOrEmpty($FolderName))
    {
        $fileLocation += $FolderName + "_" + $DateTimeExport + "\"
    }

    $Log = New-Object Artaker.Logger -ArgumentList @($LogFileName, $fileLocation)
    return $Log
}

