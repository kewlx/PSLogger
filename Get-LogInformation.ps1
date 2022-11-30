function Get-LogInformation {
    <#
    .SYNOPSIS
        Parses the selected log file that is in supported formatting.
    .DESCRIPTION
        Parses the selected log file that is in supported formatting.
    .PARAMETER Path
        Log file to parse.
    .PARAMETER Filter
        Word or sentence to filter on.
    .PARAMETER Severity
        Severity to filter on. "Emergency","Alert","Critical","Error","Warning"
    .PARAMETER Count
        Count how many of each severity.
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Get-LogInformation -Path "C:\temp\log.log"
    .EXAMPLE
        Get-LogInformation -Path "C:\temp\log.log" -Severity "Emergency","Alert"
    .EXAMPLE
        Get-LogInformation -Path "C:\temp\log.log" -Filter "import"
    .EXAMPLE
        Get-LogInformation -Path "C:\temp\log.log" -Count
    .EXAMPLE
        Get-LogInformation -Path "C:\temp\log.log" -Severity "Emergency","Alert" -Count
    .LINK
        Links to further documentation.
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding(DefaultParameterSetName = "Filter")]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if (-Not ($_ | Test-Path) ) {
                    throw "File or folder does not exist"
                }
                if (-Not ($_ | Test-Path -PathType Leaf) ) {
                    throw "The path argument must be a file. Folder paths are not allowed."
                }
                if ($_ -notmatch "(\.log)") {
                    throw "The file specified in the path argument must be .log"
                }
                return $true 
            })]
        [string]$Path,

        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "Filter")]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "Severity")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Emergency", "Alert", "Critical", "Error", "Warning")]
        [array]$Severity,

        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [switch]$Count
    )
    
    begin {
        try {
            $log = Get-Content -Path $Path

            $hash = @{
                Emergency = $log | Select-String -SimpleMatch "[Emergency]"
                Alert     = $log | Select-String -SimpleMatch "[Alert]"
                Critical  = $log | Select-String -SimpleMatch "[Critical]"
                Error     = $log | Select-String -SimpleMatch "[Error]"
                Warning   = $log | Select-String -SimpleMatch "[Warning]"
            }

        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }
    
    process {
        try {
            if ($PSBoundParameters.ContainsKey('Filter')) {
                $log | Select-String -SimpleMatch $Filter

            }
            elseif ($PSBoundParameters.ContainsKey('Severity')) {
                foreach ($level in $Severity) {
                    $hash[$level]
                }

            }
            else {
                $log
            }

            if ($PSBoundParameters.ContainsKey('Count')) {
                $severityCounts = [PSCustomObject]@{
                    Emergency = ($hash["Emergency"]).count
                    Alert     = ($hash["Alert"]).count
                    Critical  = ($hash["Critical"]).count
                    Error     = ($hash["Error"]).count
                    Warning   = ($hash["Warning"]).count
                }
                $severityCounts
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }
    
    end { 
        
    }
}