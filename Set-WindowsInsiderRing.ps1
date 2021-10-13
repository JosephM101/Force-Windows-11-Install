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

    function SetChannel ($channel) {
        Set-ItemProperty -Path $RK1 -Name "BranchName" -Value $channel
        Set-ItemProperty -Path $RK1 -Name "ContentType" -Value "Mainline"
        Set-ItemProperty -Path $RK1 -Name "Ring" -Value "External"

        Set-ItemProperty -Path $RK2 -Name "UIBranch" -Value $channel
        Set-ItemProperty -Path $RK2 -Name "UIContentType" -Value "Mainline"
        Set-ItemProperty -Path $RK2 -Name "UIRing" -Value "External"
    }

    switch ($Ring) {
        'Dev' { SetChannel "Dev" }
        'Beta' { SetChannel "Beta" }
        'ReleasePreview' { SetChannel "ReleasePreview" }
        Default { Write-Host "Not a valid branch. Must be Dev, Beta, or ReleasePreview."}
    }
}