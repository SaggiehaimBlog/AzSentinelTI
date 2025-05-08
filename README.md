# Azure Sentinel Threat Intelligence Bulk Delete Module

This PowerShell module helps manage Azure Sentinel Threat Intelligence indicators by providing bulk deletion capabilities.

## Prerequisites

- Azure Subscription with Sentinel enabled
- Contributor permissions on the Azure Sentinel workspace

## Required Modules

The module will automatically install these dependencies if needed:
- Az.Accounts (2.2.3 or higher)
- Az.OperationalInsights (2.3.0 or higher)

## Installation

1. Clone the repository:
```powershell
git clone https://github.com/saggiehaim/Sentinel-Bulk-TI-Delete.git
```

2. Import the module:
```powershell
Import-Module .\AzSentinelTI\AzSentinelTI.psd1
```

## Usage

### Remove Threat Intelligence Indicators by Source

```powershell
Remove-AzSentinelTIIndicators `
    -TIsource "MyThreatFeed" `
    -SubscriptionId "12345678-1234-1234-1234-123456789012" `
    -LogAnalyticsResourceGroup "my-sentinel-rg" `
    -LogAnalyticsWorkspaceName "my-sentinel-workspace"
```

### Remove Indicators Older Than X Days

```powershell
Remove-AzSentinelTIIndicators `
    -TIsource "MyThreatFeed" `
    -SubscriptionId "12345678-1234-1234-1234-123456789012" `
    -LogAnalyticsResourceGroup "my-sentinel-rg" `
    -LogAnalyticsWorkspaceName "my-sentinel-workspace" `
    -DaysOld 30
```

## Parameters

- `TIsource`: The source of the Threat Intelligence indicators to delete
- `SubscriptionId`: Azure Subscription ID containing the Log Analytics workspace
- `LogAnalyticsResourceGroup`: Resource group name containing the Log Analytics workspace
- `LogAnalyticsWorkspaceName`: Name of the Log Analytics workspace
- `DaysOld` (Optional): Remove only indicators older than specified number of days

## Authentication

The module supports two authentication methods:
1. Device Code authentication (interactive)
2. Regular Azure PowerShell authentication

If not already authenticated, you will be prompted to choose your preferred method.

## Logging

All operations are logged to a CSV file in the execution directory:
`TIIndicatorDeletion_YYYYMMDD_HHMMSS.log`

## Notes

- The module uses Azure REST API to perform bulk operations
- Maximum of 100 indicators can be fetched per API call
- Bulk deletion is performed in chunks of 20 indicators
- Progress and results are displayed in real-time


## TODO

- [X] Publish the module to PSGallery
- [ ] Add support for multiple TI sources in single operation
- [ ] Test the Days Old parameter
- [ ] Implement parallel processing for faster bulk deletions
- [ ] Add support for indicator type filtering
- [ ] Add progress bar for bulk operations
- [ ] Implement retry logic for failed deletions


## Author

Saggie Haim

## License

This project is licensed under the MIT License - see the LICENSE file for details
