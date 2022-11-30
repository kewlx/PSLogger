Function Write-Log {
    <#
    .SYNOPSIS
        Simple script to write logs.
    .DESCRIPTION
        Simple script to write logs.
    .PARAMETER Path
        Path to the file
    .PARAMETER Message
        Message you wish to write
    .PARAMETER Severity
        Severity level of the message
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Write-Log -Path "C:\Temp\test.log" -Message "hi" -Severity Notice
    .EXAMPLE
        "Just","some","text" | Write-Log -Path "C:\Temp\test.log"
    .LINK
        Links to further documentation.
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ($_ -notlike "(\.log)") {
                    throw "The file specified in the path argument must be .log"
                }
                return $true 
            })]
        [string]$Path,

        [Parameter(Mandatory,
            Position = 1,
            ValueFromPipeline)]
        [string]$Message,

        [Parameter(Position = 2)]
        [ValidateSet("Informational", "Warning", "Error", "Critical", "Alert", "Notice", "Debug")]
        [string]$Severity = "Informational"
    )

    begin {

    }
    process {
        $msg = '<{0}> [{1}] - {2}' -f [DateTime]::UtcNow.tostring('yyyy-MM-dd HH:mm:ssK'), $Severity, $message
        Add-Content -Path $Path -Value $msg    
    }
    end {

    }
}
