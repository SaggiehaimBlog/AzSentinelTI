<#
.SYNOPSIS
    Confirms and manages Azure login state, handling both interactive and device code authentication.

.DESCRIPTION
    This function verifies the current Azure login status and manages authentication if needed.
    It supports both regular interactive login and device code authentication methods.
    Additionally, it can switch to a specified subscription after successful authentication.

.PARAMETER TenantId
    The Entra AD tenant ID to log into. If not specified, the default tenant will be used.

.PARAMETER SubscriptionId
    The Azure subscription ID to switch to after login. If not specified, the current subscription will be used.

.EXAMPLE
    Confirm-AzLogin
    # Verifies login status and prompts for authentication if needed

.EXAMPLE
    Confirm-AzLogin -TenantId "11111111-1111-1111-1111-111111111111" -SubscriptionId "22222222-2222-2222-2222-222222222222"
    # Logs into specific tenant and switches to specified subscription

.OUTPUTS
    None. This function sets the Azure context and displays status messages.

.NOTES
    Requires Az PowerShell module to be installed
    Author: Your Name
    Version: 1.0
#>
function Confirm-AzLogin {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, HelpMessage="Azure Entra Tenant ID")]
        [string]$TenantId,
        
        [Parameter(Mandatory=$false, HelpMessage="Azure Subscription ID")]
        [string]$SubscriptionId
    )

    function Invoke-Login {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$false)]
            [switch]$UseDeviceCode
        )

        $loginParams = @{}
        if ($TenantId) { $loginParams.TenantId = $TenantId }

        if ($UseDeviceCode) {
            $loginParams.UseDeviceAuthentication = $true
        }

        try {
            Connect-AzAccount @loginParams -ErrorAction Stop | Out-Null
        }
        catch {
            throw "Failed to connect to Azure: $($_.Exception.Message)"
        }
    }

    try {
        $context = Get-AzContext
        if (-not $context) {
            throw "No context found"
        }

        Write-Host "✅ Already logged in as $($context.Account)" -ForegroundColor Green

        # Optional: switch to the desired subscription if provided
        if ($SubscriptionId -and $context.Subscription.Id -ne $SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
            Write-Host "🔄 Switched to subscription: $SubscriptionId" -ForegroundColor Cyan
        }
    } catch {
        Write-Warning "⚠ Not logged into Azure."

        while ($true) {
            $choice = Read-Host "Choose login method: [1] Device Code  [2] Regular Login"
            switch ($choice) {
                '1' {
                    Write-Host "🔐 Using Device Code login..." -ForegroundColor Yellow
                    Invoke-Login -UseDeviceCode
                    break
                }
                '2' {
                    Write-Host "🔐 Using Regular login..." -ForegroundColor Yellow
                    Invoke-Login
                    break
                }
                default {
                    Write-Host "❌ Invalid selection. Please choose 1 or 2." -ForegroundColor Red
                }
            }
        }

        # Optional: switch context after login
        if ($SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
            Write-Host "✅ Using subscription: $SubscriptionId" -ForegroundColor Green
        }
    }
}
