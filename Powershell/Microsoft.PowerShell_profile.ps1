$ProfileDir = Split-Path $MyInvocation.MyCommand.Path
$FunctionsPath = Join-Path $ProfileDir "Functions"
$AliasesPath = Join-Path $ProfileDir "Aliases"
$EnvPath = Join-Path $ProfileDir "Env"

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

if (Test-Path $EnvPath) {
    Get-ChildItem -Path $EnvPath -Filter *.env | ForEach-Object {
        try {
            foreach ($line in Get-Content $_.FullName) {
                if (![string]::IsNullOrWhiteSpace($line) -and !$line.StartsWith('#')) {
                    $name, $value = $line -split '=', 2
                    $name = $name.Trim()
                    $value = $value.Trim().Trim('"').Trim("'")
                    Set-Item -Path "env:$name" -Value $value
                }
            }
        } catch {
            Write-Error "Error loading env file: $($_.FullName) - $_"
        }
    }
    Write-Host "Loaded custom environment variables from $EnvPath"
}

if (-not $env:TERM_PROGRAM -or $env:TERM_PROGRAM -ne 'vscode') {
    Set-Location $HOME
}
$env:STARSHIP_CONFIG = "$HOME\.config\starship.toml"
Invoke-Expression (&starship init powershell)
