$ProfileDir = Split-Path $MyInvocation.MyCommand.Path
$FunctionsPath = Join-Path $ProfileDir "Functions"
$AliasesPath = Join-Path $ProfileDir "Aliases"

if (Test-Path $FunctionsPath) {
    Get-ChildItem -Path $FunctionsPath -Filter *.ps1 | ForEach-Object {
        try {
            . $_.FullName
        } catch {
            Write-Error "Error loading profile script: $($_.FullName) - $_"
        }
    }
    Write-Host "Loaded custom functions from $FunctionsPath"
}
if (Test-Path $AliasesPath) {
    Get-ChildItem -Path $AliasesPath -Filter *.ps1 | ForEach-Object {
        try {
            . $_.FullName
        } catch {
            Write-Error "Error loading profile script: $($_.FullName) - $_"
        }
    }
    Write-Host "Loaded custom aliases from $AliasesPath"
}


if (-not $env:TERM_PROGRAM -or $env:TERM_PROGRAM -ne 'vscode') {
    Set-Location $HOME
}
$env:STARSHIP_CONFIG = "$HOME\.config\starship.toml"
Invoke-Expression (&starship init powershell)