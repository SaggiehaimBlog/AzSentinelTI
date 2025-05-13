@{
    # Version number of this module
    ModuleVersion = '1.0.3'

    # ID used to generate the module manifest
    GUID = 'd0e1f7a2-3b4c-4f5d-8a6b-7c8d9e0f1a2b'

    # Author of this module
    Author = 'Saggie Haim'

    # Company or vendor of this module
    CompanyName = 'Saggie Haim Blog'

    # Copyright statement(s) for this module
    Copyright = 'Copyright 2025 Saggie Haim'

    # Description of the functionality provided by this module
    Description = 'This module provides functions to manage Azure Sentinel Threat Intelligence indicators.'

    # Script module or binary module file associated with this manifest
    RootModule = 'AzSentinelTI.psm1'

    # Functions to export from this module
    FunctionsToExport    = @(
        'Remove-AzSentinelTIIndicators'
    )

    # Cmdlets to export from this module
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module
    AliasesToExport      = @()

    # List of all modules that must be imported when this module is imported
    RequiredModules      = @(
        @{ModuleName = 'Az.Accounts'; ModuleVersion = '2.2.3'},
        @{ModuleName = 'Az.OperationalInsights'; ModuleVersion = '2.3.0'}
    )

    # List of all modules that are loaded automatically with this module
    NestedModules        = @()

    # List of all files that are loaded automatically with this module
    FileList             = @(
        'Public\Remove-AzSentinelTIIndicators.ps1',
        'Private\Write-Log.ps1',
        'Private\Split-TICollection.ps1',
        'Private\Get-RequiredTIModules.ps1',
        'Private\Confirm-AzLogin.ps1'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Azure', 'Sentinel', 'Security', 'ThreatIntelligence', 'Microsoft-Sentinel')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/saggiehaim/Sentinel-Bulk-TI-Delete/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/saggiehaim/Sentinel-Bulk-TI-Delete'

            # ReleaseNotes of this module
            ReleaseNotes = @'
            ## v1.0.1
            * Initial release
            * Added Remove-AzSentinelTIIndicators function
            * Added support for bulk deletion of Threat Intelligence indicators
'@
        }
    }
}