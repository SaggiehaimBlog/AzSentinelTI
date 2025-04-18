<#
.SYNOPSIS
    Removes Threat Intelligence indicators from Azure Sentinel workspace.

.DESCRIPTION
    This script removes Threat Intelligence indicators from a specified Azure Sentinel workspace
    based on the provided source. It handles authentication, pagination, and bulk deletion of indicators.

.PARAMETER TIsource
    The source of the Threat Intelligence indicators to be deleted.

.PARAMETER SubscriptionId
    The Azure subscription ID containing the Log Analytics workspace.

.PARAMETER LogAnalyticsResourceGroup
    The resource group containing the Log Analytics workspace.

.PARAMETER LogAnalyticsWorkspaceName
    The name of the Log Analytics workspace.

.PARAMETER DaysOld
    Optional. Remove only indicators older than specified number of days.
    
.EXAMPLE
    Remove-AzSentinelTIIndicators -TIsource "MySource" -SubscriptionId "1234" -LogAnalyticsResourceGroup "rg-sentinel" -LogAnalyticsWorkspaceName "law-sentinel" -DaysOld 30
    # Removes all indicators from "MySource" that are older than 30 days

.NOTES
    Version: 1.0
    Requires: Az.Accounts 2.2.3, Az.Kusto 2.3.0, PowerShell 6.2
#>
function Remove-AzSentinelTIIndicators {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $TIsource,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
        [string] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $LogAnalyticsResourceGroup,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $LogAnalyticsWorkspaceName,

        [Parameter(Mandatory = $false)]
        [int] $DaysOld = 0
    )
    
    # Initialize logging
    $LogFileName = "TIIndicatorDeletion_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    # Ensure required modules are installed
    try {
        Get-RequiredTIModules -LogFileName $LogFileName
    }
    catch {
        Write-Log -Message "Failed to initialize required modules: $_" -LogFileName $LogFileName -Severity Error
        throw
    }
    
    # Ensure Azure login and correct subscription
    try {
        Confirm-AzLogin -SubscriptionId $SubscriptionId
    }
    catch {
        Write-Log -Message "Failed to authenticate to Azure: $($_.Exception.Message)" -LogFileName $LogFileName -Severity Error
        throw $_
    }

    # Constants
    $ThreatIndicatorsApi = "https://management.azure.com/subscriptions/$SubscriptionId/resourcegroups/$LogAnalyticsResourceGroup/providers/Microsoft.OperationalInsights/workspaces/$LogAnalyticsWorkspaceName/providers/Microsoft.SecurityInsights/threatIntelligence/"
    $SECURITY_INSIGHTS_API_VERSION = "api-version=2022-07-01-preview"
    $PAGE_SIZE = "100"
    $getAllIndicatorsWithSourceFilterUri = $ThreatIndicatorsApi + "query?$SECURITY_INSIGHTS_API_VERSION"
    
    # Add age filter to query parameters if specified
    $queryParams = @{
        "pageSize" = $PAGE_SIZE
        "sources"  = @($TIsource)
    }
    
    if ($DaysOld -gt 0) {
        $cutoffDate = (Get-Date).AddDays(-$DaysOld).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $queryParams.Add("validUntilTime", $cutoffDate)
        Write-Log -Message "Filtering for indicators older than $DaysOld days (before $cutoffDate)" -LogFileName $LogFileName -Severity Information
    }
    
    $getAllIndicatorsPostParameters = $queryParams | ConvertTo-Json
    $bulkApi = "https://management.azure.com/batch?api-version=2020-06-01"

    # This flag checks whether the initial count of indicators in the workspace is already 0 or not
    $indicatorsFound = $false

    # Total count of indicators fetched for the customer's workspace ,and for the provided source
    $indicatorsFetched = 0

    # Total count of indicators deleted
    $indicatorsDeleted = 0

    # We have a max page size of 100 hence at a time, the fetch indicators call can only fetch a list of 100 indicators for any workspace. However, since the bulk
    # API can only support 20 requests in one single request we search for the first 20 results. Because a workspace can also have more than 100 indicators we will
    # loop untill we finish.
    while ($true) {
        try {
            $response = Invoke-AzRestMethod -Uri $getAllIndicatorsWithSourceFilterUri -Method POST -Payload $getAllIndicatorsPostParameters
            if ($response -eq $null -or $response.StatusCode -ne 200) {            
                Write-Log -Message "Failed to fetch indicators. Status Code = $($response.StatusCode)" -LogFileName $LogFileName -Severity Information
                exit 1
            }
    
            $indicatorList = ($response.Content | ConvertFrom-Json).value
        }
        catch {        
            Write-Log -Message "Failed to get all indicators with the specified source. $($_.Exception)" -LogFileName $LogFileName -Severity Error    
            exit 1
        }
    
        if ($indicatorList.Count -eq 0) {
            # If the initial count of indicators in the customer's workspace is already 0, exit.
            if ($indicatorsFound -eq $false) {
                Write-Log -Message "No indicators found with source = $Source! Exiting ..." -LogFileName $LogFileName -Severity Error            
                break
            }
            else {
                Write-Log -Message "Finished querying workspace = $WorkspaceName for indicators with Source = $Source ..." -LogFileName $LogFileName -Severity Information
                Write-Log -Message "Fetched $indicatorsFetched indicators" -LogFileName $LogFileName -Severity Information
                Write-Log -Message "Deleted $indicatorsDeleted indicators" -LogFileName $LogFileName -Severity Information

                if ($indicatorsFetched -eq $indicatorsDeleted) {                
                    Write-Log -Message "Successfully deleted all indicators in workspace = $WorkspaceName with Source = $Source" -LogFileName $LogFileName -Severity Information
                }
                else {                
                    Write-Log -Message "Please re-run the script to delete remaining indicators or reach out to the script owners if you're facing any issues." -LogFileName $LogFileName -Severity Information
                }
                break
            }
        }

        $indicatorsFound = $true    
        Write-Log -Message "Successfully fetched $($indicatorList.Count) indicators for source = $Source. Deleting ..." -LogFileName $LogFileName -Severity Information
    
        $indicatorsFetched += $indicatorList.Count

        try {
            if ($indicatorList.Count -le 20) {
                $indicatorChunks = @($indicatorList)
            }
            else {
                $indicatorChunks = $indicatorList | Split-Collection -Count 20
            }
            
            foreach ($indicatorChunk in $indicatorChunks) {
                $bulkDeletePayload = @{"requests" = (New-Object System.Collections.ArrayList) }
                $totalDels = $indicatorChunk.Count
                foreach ($indicator in $indicatorChunk) {
                    $indicatorName = $($indicator).name
                    Write-Log -Message "Preparing indicator with ID: ($indicatorName) for deleteion" -LogFileName $LogFileName -Severity Information
                    $deleteIndicatorUri = $ThreatIndicatorsApi + $indicator.name + "?$SECURITY_INSIGHTS_API_VERSION"
                    $bulkDeleteRequest = @{"url" = $deleteIndicatorUri; "httpMethod" = "DELETE" }
                    $bulkDeletePayload.requests.Add($bulkDeleteRequest)
                }
                $bulkDeletePayloadJson = $bulkDeletePayload | ConvertTo-Json
                $response = Invoke-AzRestMethod -Uri $bulkApi -Payload $bulkDeletePayloadJson -Method POST
                $bulkDeletePayload = @{"requests" = (New-Object System.Collections.ArrayList) }
                if ($response -eq $null -or $response.StatusCode -ne 200) {                
                    Write-Log -Message "Failed to bulk delete indicators. Status Code = $($response.StatusCode)" -LogFileName $LogFileName -Severity Information
                    Write-Log -Message $response.Content -LogFileName $LogFileName -Severity Information
                    break
                }
                $responseContent = $response.Content | ConvertFrom-Json
                $delFailures = 0
                $index = 0
                $failure = $false
                foreach ($responseItem in $responseContent.responses) {
                    if ($responseItem.httpStatusCode -ne "200") {
                        $failure = $true
                        $indicatorId = $indicatorChunk[$index].name
                        $delFailures++
                        Write-Log -Message "Failed to delete indicator with ID ($indicatorId). Status Code = $($responseItem.httpStatusCode)" -LogFileName $LogFileName -Severity Information
                    }
                    $index++
                }
                $totalDels -= $delFailures
                $indicatorsDeleted += $totalDels
                if ($failure) {
                    Write-Log -Message "Successfully deleted $($totalDels) and failed $($delFailures) indicators" -LogFileName $LogFileName -Severity Information
                    continue
                }
                Write-Log -Message "Successfully deleted all $($indicatorChunk.Count) indicators" -LogFileName $LogFileName -Severity Information
            }
        }
        catch {
            Write-Log -Message "Failed to delete indicator info: $($_.Exception)" -LogFileName $LogFileName -Severity Information        
        }
    }
}