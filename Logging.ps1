Class PsLogger {
    <#
    .SYNOPSIS
        Creates a runspace to run your event driven logger.
    .DESCRIPTION
        Creates a runspace to run your event driven logger.
    .PARAMETER Path
        Path of the logfile you want it to log to.
    .PARAMETER Write
        Writes to the console as well as the log file.
    .PARAMETER Severity
        "Emergency","Alert","Critical","Error","Warning","Notice","Informational","Debug"
    .PARAMETER CleanLogs
        Remove Logs older than $X days from Path.
    .PARAMETER IsEmpty
        IsEmpty method to see if anything is still processing
    .PARAMETER Remove
        Remove method to close and dispose of the logging thread
    .PARAMETER GetStatus
        Get Status Method Tells you the runspace information and its state and availability.
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        # Create a new log with the name Test
        $logger = [PSLogger]::new("C:\Temp","Test")
    .EXAMPLE
        # Create a new log with the name Test1 and write to the console
        $logger = [PSLogger]::new("C:\Temp","Test1",$True)
    .EXAMPLE
        # write to the log with a informational severity
        $logger.Informational("info goes here")
    .EXAMPLE
        # Clean logs older than "-1"
        $logger.CleanLogs("C:\Temp",-1)
    .EXAMPLE
        # Checks if the queue is empty
        $logger.IsEmpty()
        True
    .EXAMPLE
        # Waits one second for the queue to empty and then closes the thread
        $logger.Remove()
    .EXAMPLE
        $logger.GetStatus()
        Id Name            ComputerName    Type          State         Availability   
        -- ----            ------------    ----          -----         ------------   
        2 PSLogger        localhost       Local         Opened        Available  
    .EXAMPLE
        $logPath = "C:\temp"
        if (!("PSLogger" -as [type])) {
            $callingScript = ($MyInvocation.MyCommand.Name) -split('.ps1')
            ."\\server\path\here\Logging.ps1"
            $logger = [PSLogger]::new($logPath,$callingScript)
        }
    .LINK
        Links to further documentation.
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    # Code that will run in the runspace when it is invoked later on
    hidden $loggingScript = {
        
        function Start-Logging {
            $loggingTimer = New-Object Timers.Timer
            $action = { logging }
            $loggingTimer.Interval = 1000
            $null = Register-ObjectEvent -InputObject $loggingTimer -EventName elapsed -Sourceidentifier loggingTimer -Action $action
            $loggingTimer.start()
        }
    
        function logging {
            $sw = $logFile.AppendText()
            while (-not $logEntries.IsEmpty) {
                $entry = ''
                $null = $logEntries.TryDequeue([ref]$entry)
                $sw.WriteLine($entry)
            }
            $sw.Flush()
            $sw.Close()
        }
        $logFile = New-Item -ItemType File -Name "$ExecutingScript`_$([DateTime]::UtcNow.ToString(`"yyyyMMddTHHmmssZ`")).log" -Path $logLocation
    
        Start-Logging
    }

    # Variables
    hidden $loggingRunspace = [runspacefactory]::CreateRunspace()
    hidden $logEntries = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    hidden $logLocation = "C:\Temp"
    hidden $ExecutingScript = "Default"
    hidden $Write = $False
    
    
    # Constructor with default values
    PsLogger() {
        $this.logLocation = "C:\Temp"
        $this.ExecutingScript = "Default"
        $this.Write = $False

        # Check for and build log path
        if (!(Test-Path -Path $this.logLocation)) {
            [void](New-Item -path $this.logLocation -ItemType directory -force)
        }

        # Start Logging runspace
        $this.StartLogging()
    }    
    
    # Constructor with log path and the name of the log
    PsLogger([string]$logLocation, [string]$ExecutingScript) {
        $this.logLocation = $logLocation
        $this.ExecutingScript = $ExecutingScript
        $this.Write = $False

        # Check for and build log path
        if (!(Test-Path -Path $this.logLocation)) {
            [void](New-Item -path $this.logLocation -ItemType directory -force)
        }

        # Start Logging runspace
        $this.StartLogging()
    }

    # Constructor with log path and the name of the log and switch for writing to console
    PsLogger([string]$logLocation, [string]$ExecutingScript, [switch]$Write) {
        $this.logLocation = $logLocation
        $this.ExecutingScript = $ExecutingScript
        $this.Write = $Write

        # Check for and build log path
        if (!(Test-Path -Path $this.logLocation)) {
            [void](New-Item -path $this.logLocation -ItemType directory -force)
        }

        # Start Logging runspace
        $this.StartLogging()
    }

    Emergency([string]$message) {
        $this.LogMessage($message, "Emergency")
    }

    Alert([string]$message) {
        $this.LogMessage($message, "Alert")
    }

    Critical([string]$message) {
        $this.LogMessage($message, "Critical")
    }

    Error([string]$message) {
        $this.LogMessage($message, "Error")
    }

    Warning([string]$message) {
        $this.LogMessage($message, "Warning")
    }

    Notice([string]$message) {
        $this.LogMessage($message, "Notice")
    }

    Informational([string]$message) {
        $this.LogMessage($message, "Informational")
    }

    Debug([string]$message) {
        $this.LogMessage($message, "Debug")
    }
    
    hidden LogMessage([string]$message, [string]$severity) {
        $addResult = $false

        $funcName = (Get-PSCallStack).FunctionName[2]

        if ($funcName -eq "<ScriptBlock>") {
            $funcName = ""
        }

        $msg = $null

        while ($addResult -eq $false) {
            $msg = '<{0}> [{1}] {2} - {3}' -f [DateTime]::UtcNow.tostring('yyyy-MM-dd HH:mm:ssK'), $severity, $funcName, $message
            $addResult = $this.logEntries.TryAdd($msg)
        }

        if ($this.Write) {
            write-host "$msg"
        }
        

    }

    # Create
    hidden StartLogging() {
        $this.LoggingRunspace.ThreadOptions = "ReuseThread"
        $this.loggingRunspace.name = 'PSLogger'
        $this.LoggingRunspace.Open()
        $this.LoggingRunspace.SessionStateProxy.SetVariable("logEntries", $this.logEntries)
        $this.LoggingRunspace.SessionStateProxy.SetVariable("logLocation", $this.logLocation)
        $this.LoggingRunspace.SessionStateProxy.SetVariable("ExecutingScript", $this.ExecutingScript)
        $this.LoggingRunspace.SessionStateProxy.SetVariable("Write", $this.Write)
        $cmd = [PowerShell]::Create().AddScript($this.loggingScript)
      
        $cmd.Runspace = $this.LoggingRunspace
        $null = $cmd.BeginInvoke()
    }

        # Remove Logs older than $X days from Path
     CleanLogs([string]$logLocation, [int]$Days) {
        $Logs = (Get-ChildItem $logLocation -Filter "*.log").Where( { $_.LastWriteTime -LT (Get-Date).AddDays($Days) })
        foreach ($Log in $Logs) {
            Try {
                $Log | Remove-Item -Force
                $this.Logger.Informational("Cleaned $($log.Name)")
            }
            Catch {
                #$this.Logger.Error("$PSitem")
            }
        }
    }

    # Stop Method
    #Stop() {
    #    $This.LoggingRunspace.Stop()
    #}
 
    # IsEmpty method to see if anything is still processing
    [bool]IsEmpty() {
    if ($this.logEntries.IsEmpty) {
            return $true
        } else {
            return $false
        }
       
    }

    # Remove method to close and dispose of the logging thread
    Remove() {
        Start-Sleep -Seconds 1
        $This.LoggingRunspace.close()
        $This.LoggingRunspace.Dispose()
        If ($This.LoggingRunspace) {
            $This.LoggingRunspace.close()
            $This.LoggingRunspace.Dispose()
        }
    }

    # Get Status Method
    [object]GetStatus() {
        return $This.LoggingRunspace
    }
}
