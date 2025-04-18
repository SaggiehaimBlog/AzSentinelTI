function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$true)]
        [string]$LogFileName,
        
        [Parameter()]
        [ValidateSet('Information', 'Warning', 'Error')]
        [string]$Severity = 'Information'
    )
    
    # Create timestamp
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Write to console with color
    switch ($Severity) {
        'Information' { Write-Host "$Timestamp - $Message" -ForegroundColor Green }
        'Warning' { Write-Host "$Timestamp - $Message" -ForegroundColor Yellow }
        'Error' { Write-Host "$Timestamp - $Message" -ForegroundColor Red }
    }
    
    # Write to log file
    try {
        $LogEntry = [PSCustomObject]@{
            Timestamp = $Timestamp
            Message = $Message
            Severity = $Severity
        }
        $LogEntry | Export-Csv -Path $LogFileName -Append -NoTypeInformation
    }
    catch {
        Write-Warning "Failed to write to log file: $_"
    }
}
