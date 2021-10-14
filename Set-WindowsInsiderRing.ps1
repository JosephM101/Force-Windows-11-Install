param
(
    [Parameter(Mandatory,ValueFromPipeline)]
    [string] $Ring
    # [ValidateSet('Dev','Beta','ReleasePreview')]
)

process
{
    $RK1 = "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\Applicability"
    $RK2 = "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection"

    Function ValidateStringInput {
        Param (
            [Parameter(Mandatory = $true)]
            [ref]$ByRef,
            [Parameter(Mandatory = $true)]
            [ValidateNotNullorEmpty()]
            [string]$ParamName,
            [Parameter(Mandatory=$false)]
            [string]$ParamValue = '',
            [Parameter(Mandatory=$true)]
            [ValidateNotNullorEmpty()]
            [string[]]$ValidValues
        )
        while (1) {
            If ($ParamValue -And ($ValidValues -contains $ParamValue)) {
                break
            } Else {
                If ($ParamValue) {
                    #$Message = "Unable to match the identifier $ParamValue to a valid enumerator name. Specify one of"
                    $Message = "$ParamValue is not a valid option. Specify one of"
                    Foreach ($Value in $ValidValues) {
                        $Message += " $Value,"
                    }
                    $Message = $Message.TrimEnd(",")
                    $Message += "."
                    Write-Host $Message
                } Else {
                    Write-Host "Supply values for the following parameters:"
                }
                $ParamValue = Read-Host "$ParamName"
            }
        }
        $ByRef.Value = $ParamValue
    }
    
    ValidateStringInput -ByRef ([ref]$Ring) -ParamName 'Ring' -ParamValue $Ring -ValidValues @('Dev','Beta','ReleasePreview')

    function SetChannel ($channel) {
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" -Name "AllowBuildPreview" -Value 1 -Force
            Set-ItemProperty -Path $RK1 -Name "EnablePreviewBuilds" -Value 1 -Force
            Set-ItemProperty -Path $RK1 -Name "IsBuildFlightingEnabled" -Value 1 -Force
            
            Set-ItemProperty -Path $RK1 -Name "BranchName" -Value $channel -ErrorAction "Stop"
            Set-ItemProperty -Path $RK1 -Name "ContentType" -Value "Mainline" -ErrorAction "Stop"
            Set-ItemProperty -Path $RK1 -Name "Ring" -Value "External" -ErrorAction "Stop"
            Set-ItemProperty -Path $RK2 -Name "UIBranch" -Value $channel -ErrorAction "Stop"
            Set-ItemProperty -Path $RK2 -Name "UIContentType" -Value "Mainline" -ErrorAction "Stop"
            Set-ItemProperty -Path $RK2 -Name "UIRing" -Value "External" -ErrorAction "Stop"
            Write-Host "Done! Your PC may need to be restarted for changes to take effect."
        } catch {
            Write-Host "There was a problem setting the Insider Ring. You may not have the necessary privileges to do so. Check to see if you're running this script as an administrator, then try again." -ForegroundColor Red
            Exit
        }
    }

    switch ($Ring) {
        'Dev' { SetChannel "Dev" }
        'Beta' { SetChannel "Beta" }
        'ReleasePreview' { SetChannel "ReleasePreview" }
        Default { Write-Host "Not a valid branch. Must be 'Dev', 'Beta', or 'ReleasePreview.'"}
    }
    
}
