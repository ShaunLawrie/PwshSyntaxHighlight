function New-SavePath {
    param (
        [string] $Path,
        [string] $TemplateFilename = "screenshot1",
        [string] $TemplateExtension = ".png"
    )
    if([string]::IsNullOrWhiteSpace($Path)) {
        $suggestedFilename = "$TemplateFileName$TemplateExtension"

        $downloadsDirectory = Join-Path $HOME "downloads"
        if(!(Test-Path $downloadsDirectory)) {
            New-Item -Path $downloadsDirectory -ItemType Directory -Force | Out-Null
        }
        $Path = Join-Path $downloadsDirectory $SuggestedFilename
        $suffix = 1
        while((Test-Path -Path $Path) -and $suffix -le 1000) {
            $Path = $Path -replace "[0-9]+\$TemplateExtension`$", "$suffix$TemplateExtension"
            $suffix++
        }
    }
    return $Path
}