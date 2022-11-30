# PSLogger
Logging scripts

# Introduction
PSLogger Powershell script creates a concurrent queue logger..

# Requirements and Dependencies
* [PowerShell 5.1](https://www.microsoft.com/en-us/download/details.aspx?id=54616) or later

## Usage

```Powershell
# Create a new log with the name Test
$logger = [PSLogger]::new("C:\Temp","Test")
```

```Powershell
# Create a new log with the name Test1 and write to the console
$logger = [PSLogger]::new("C:\Temp","Test1",$True)
```

```Powershell
# write to the log with a informational severity
$logger.Informational("info goes here")
```

```Powershell
# Clean logs older than "-1"
$logger.CleanLogs("C:\Temp",-1)
```

```Powershell
# Checks if the queue is empty
$logger.IsEmpty()
True
```

```Powershell
# Waits one second for the queue to empty and then closes the thread
$logger.Remove()
```

```Powershell
$logger.GetStatus()
Id Name            ComputerName    Type          State         Availability   
-- ----            ------------    ----          -----         ------------   
2 PSLogger        localhost       Local         Opened        Available  
```

```Powershell
<# 
    Check if the logger is already running and create if not, while using a certain logging path
    $callingscript var automatically calls the current scripts name and uses that as the file name prefix
#>
$logPath = "C:\temp"
if (!("PSLogger" -as [type])) {
    $callingScript = ($MyInvocation.MyCommand.Name) -split('.ps1')
    ."\\server\path\here\Logging.ps1"
    $logger = [PSLogger]::new($logPath,$callingScript)
}
```

