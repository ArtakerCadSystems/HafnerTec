# Get-ChildItem -path ($env:ProgramData + '\Artaker\Logging') -Filter "*.psm1" | ForEach-Object { Import-Module -Name $_.FullName -Global -Force }

# Logging Level Switch
function LoggingLevel
{
    param 
    (
        $logging,
        [string]$level,
        [string]$message
    )

    # switch between different Message Levels
    switch ($level)
    {
        "Debug" 
        {  
            $logging.Debug($message)
            return
        }
        "Info" 
        {  
            $logging.Info($message)
            return
        }
        "Warn" 
        {  
            $logging.Warn($message)
            return
        }
        "Error" 
        {  
            $logging.Error($message)
            return
        }
        "Fatal" 
        {  
            $logging.Fatal($message)
            return
        }
        Default
        {
            # if $level is set to a wrong Value or empty, the Log will display Info  
            $logging.Info($message)
            return
        }
    }

}

# Normal Job Logging
function CombiLogger
{
    param 
    (
        $logger,
        [string]$logMessage,
        [string]$logLevel
    )
    # wirte host Message
    write-host $logMessage

    # logging Message
    LoggingLevel -logging $logger -message $logMessage -level $logLevel 
    
}

# Job Logging that returns a string (should be used in combination with a throw call)
function CombiLoggerThrow
{
    param 
    (
        $logger,
        [string]$logMessage
    )

    # logging Message -> is always an error
    $logger.Error($logMessage)
    # return Message - to throw
    return $logMessage
}

