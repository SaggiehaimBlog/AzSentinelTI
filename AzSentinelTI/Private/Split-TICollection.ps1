#requires -version 6.2

function Split-Collection {
    <#
    .SYNOPSIS
    Splits a collection of Threat Intelligence indicators into smaller chunks for bulk processing.

    .DESCRIPTION
    This function is used to split large collections of TI indicators into smaller chunks
    to accommodate API limitations and improve performance of bulk operations.
    It supports pipeline input and ensures efficient memory usage.

    .PARAMETER Collection
    The collection of items to split. Can be passed through the pipeline.
    Typically contains Threat Intelligence indicators.

    .PARAMETER Count
    The maximum size of each chunk. Must be between 1 and 247483647.
    For TI operations, this is typically set to 20 due to API limitations.

    .EXAMPLE
    $indicators | Split-Collection -Count 20
    Splits a collection of indicators into chunks of 20 items each.

    .EXAMPLE
    Split-Collection -Collection $largeArray -Count 100
    Splits the large array into chunks of 100 items each.

    .NOTES
    Author: Saggie Haim
    Version: 1.0
    Purpose: Support function for Remove-AzSentinelTIIndicators
    #>

    param (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        $Collection,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 247483647)]
        [int] $Count
    )

    begin {
        $Ctr = 0
        $Array = @()
        $TempArray = @()
    }

    process {
        foreach ($e in $Collection) {
            if (++$Ctr -eq $Count) {
                $Ctr = 0
                $Array += , @($TempArray + $e)
                $TempArray = @()
                continue
            }
            $TempArray += $e
        }
    }
    end {
        if ($TempArray) { $Array += , $TempArray }
        $Array
    }
}