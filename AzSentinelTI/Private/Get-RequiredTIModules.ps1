function Get-RequiredTIModules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFileName
    )

    $requiredModules = @(
        @{Name = 'Az.Accounts'; Version = '2.2.3'},
        @{Name = 'Az.OperationalInsights'; Version = '2.3.0'}
    )

    foreach ($module in $requiredModules) {
        try {
            $installedModule = Get-InstalledModule -Name $module.Name -MinimumVersion $module.Version -ErrorAction SilentlyContinue
            
            if (-not $installedModule) {
                Write-Log -Message "Installing $($module.Name) module version $($module.Version)" -LogFileName $LogFileName -Severity Information
                
                # Check for admin privileges
                $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                $scope = $isAdmin ? 'AllUsers' : 'CurrentUser'
                
                Install-Module -Name $module.Name -MinimumVersion $module.Version -Scope $scope -Force -AllowClobber
            }
            
            Import-Module -Name $module.Name -MinimumVersion $module.Version -Force
            Write-Log -Message "Successfully loaded $($module.Name) module version $($module.Version)" -LogFileName $LogFileName -Severity Information
        }
        catch {
            Write-Log -Message "Failed to install/import $($module.Name): $_" -LogFileName $LogFileName -Severity Error
            throw
        }
    }
}
