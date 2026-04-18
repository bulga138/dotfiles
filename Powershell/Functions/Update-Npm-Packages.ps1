# 1. Define Enum for Strict Status Typing
enum NpmUpdateStatus {
    Updated         = 0
    Simulated       = 1
    Failed          = 2
    Skipped         = 3
    Excluded        = 4
    UpToDate        = 5
    New             = 6
    Unknown         = 7
    ManifestUpdated = 8
}

function Update-NpmPackages {
    <#
    .SYNOPSIS
        Professional npm update manager.
    .DESCRIPTION
        Fixed to respect shell environment variables (NVM/Volta) to prevent node internal crashes.
    #>
    [CmdletBinding()]
    param(
        [string[]]$Exclude = @(),
        [string]$ExportMarkdown,
        [switch]$IgnoreDev,
        [switch]$DryRun,
        [switch]$Audit,
        [switch]$Fix,
        [switch]$AutoBackup,
        [switch]$ListBackups,
        [switch]$PassThru,
        [switch]$Force,
        [switch]$Compatible,
        [switch]$Restore,
        [switch]$CleanInstall
    )

    # --- Shared State ---
    $script:DeprecationWarnings = @()

    # --- 2. Helper: Logging ---
    function Write-Log {
        param([string]$Message, [string]$Color = "White", [int]$Level = 0)
        $prefix = " " * ($Level * 2)
        Write-Host "$prefix$Message" -ForegroundColor $Color
    }

    # --- 3. Helper: Robust SemVer Comparison ---
    function Compare-SemVer {
        param([string]$Current, [string]$Target)
        $cClean = $Current -replace '[^0-9\.]',''; $tClean = $Target -replace '[^0-9\.]',''
        if ([string]::IsNullOrWhiteSpace($cClean) -or [string]::IsNullOrWhiteSpace($tClean)) { return "Unknown" }
        try {
            $cParts = $cClean.Split('.') | ForEach-Object { [int]$_ }
            $tParts = $tClean.Split('.') | ForEach-Object { [int]$_ }
            $maxLen = [Math]::Max($cParts.Count, $tParts.Count)
            for ($i = 0; $i -lt $maxLen; $i++) {
                $cNum = if ($i -lt $cParts.Count) { $cParts[$i] } else { 0 }
                $tNum = if ($i -lt $tParts.Count) { $tParts[$i] } else { 0 }
                if ($tNum -gt $cNum) { return if ($i -eq 0) { "Major" } elseif ($i -eq 1) { "Minor" } else { "Patch" } }
                if ($tNum -lt $cNum) { return "Downgrade" }
            }
            return "Equal"
        } catch { return "Unknown" }
    }

    # --- 4. Helper: Native Shell Execution (FIXED) ---
    function Invoke-NpmInstall {
        param([string[]]$Args)

        # We use simple PowerShell redirection. 
        # This respects NVM/Volta/Path settings because it runs in the current shell context.
        $installOutput = npm @Args 2>&1 
        
        # Check success immediately
        $exitCode = $LASTEXITCODE

        # Process output for warnings (Post-execution to avoid stream locking)
        $installOutput | ForEach-Object {
            $line = $_.ToString()
            if ($line -match "warn deprecated") {
                $script:DeprecationWarnings += $line
            }
            # Optional: Uncomment below to see errors during install
            # if ($exitCode -ne 0 -and $line -notmatch "npm warn") { Write-Host $line -ForegroundColor Red }
        }

        return $exitCode
    }

    # --- 5. Pre-checks & Restore ---
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { Write-Error "npm not found."; return }
    if (-not (Test-Path "package.json")) { Write-Error "package.json not found."; return }

    if ($ListBackups) {
        Get-ChildItem "package.json.*.bak" | Sort-Object LastWriteTime -Descending | 
            Select-Object Name, @{N='Date';E={$_.LastWriteTime.ToString("yyyy-MM-dd HH:mm")}} | Format-Table -AutoSize
        return
    }

    if ($Restore) {
        $latest = Get-ChildItem "package.json.*.bak" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not $latest) { Write-Log "No backups found." "Yellow"; return }
        Write-Log "Found backup: $($latest.Name)" "Cyan"
        if (-not ($Force -or $DryRun)) { if ((Read-Host "Restore? (Y/N)") -ne "Y") { return } }
        Copy-Item $latest.FullName -Destination "package.json" -Force
        Write-Log "Restored." "Green"; return
    }

    if ($AutoBackup -and -not $DryRun) {
        $ts = Get-Date -Format "yyyyMMdd-HHmm"
        Copy-Item "package.json" -Destination "package.json.$ts.bak"
        Write-Log "Backup created." "Gray"
    }

    # --- 6. Worker Function ---
    function Update-SinglePackage {
        param([Parameter(Mandatory)]$PkgProp, [Parameter(Mandatory)]$TypeLabel)
        
        $pkgName = $PkgProp.Name
        $currentVer = if ($PkgProp.Value.current) { $PkgProp.Value.current } else { "Missing" }
        
        if ($Compatible) { $targetVer = $PkgProp.Value.wanted; $targetDesc = "Compatible" } 
        else { $targetVer = $PkgProp.Value.latest; $targetDesc = "Latest" }

        if ($Exclude -contains $pkgName) { return [PSCustomObject]@{ Package=$pkgName; Current=$currentVer; Target=$targetVer; Status=[NpmUpdateStatus]::Excluded } }

        $changeType = "Unknown"; $color = "Magenta"
        if ($currentVer -eq "Missing") { $changeType = "New"; $color = "Red" } 
        else {
            $semVerDiff = Compare-SemVer -Current $currentVer -Target $targetVer
            switch ($semVerDiff) {
                "Equal"     { return [PSCustomObject]@{ Package=$pkgName; Current=$currentVer; Target=$targetVer; Status=[NpmUpdateStatus]::UpToDate } }
                "Downgrade" { Write-Verbose "Skipping ${pkgName}: Target $targetVer is older than $currentVer"; return [PSCustomObject]@{ Package=$pkgName; Status=[NpmUpdateStatus]::Skipped } }
                "Major"     { $changeType = "Major"; $color = "Red" }
                "Minor"     { $changeType = "Minor"; $color = "Yellow" }
                "Patch"     { $changeType = "Patch"; $color = "Magenta" }
            }
        }

        $status = [NpmUpdateStatus]::Updated
        
        if ($DryRun) {
            Write-Log "[DryRun] $pkgName : $currentVer -> $targetVer ($changeType)" $color 1
            $status = [NpmUpdateStatus]::Simulated
        } else {
            if ($CleanInstall) {
                 Write-Host -NoNewline "  Updating Manifest $pkgName... " -ForegroundColor $color
                 $sect = if ($TypeLabel -eq "DevDep") { "devDependencies" } else { "dependencies" }
                 npm pkg set "$sect.$pkgName=$targetVer" 2>$null
                 if ($LASTEXITCODE -eq 0) { Write-Host "OK" -ForegroundColor Green; $status = [NpmUpdateStatus]::ManifestUpdated }
                 else { Write-Host "FAILED" -ForegroundColor Red; $status = [NpmUpdateStatus]::Failed }
            } else {
                Write-Host -NoNewline "  Updating $pkgName... " -ForegroundColor $color
                $args = @("install", "$pkgName@$targetVer", "--save-exact")
                if ($Force) { $args += "--legacy-peer-deps" }
                
                $code = Invoke-NpmInstall -Args $args
                if ($code -eq 0) { Write-Host "OK" -ForegroundColor Green; $status = [NpmUpdateStatus]::Updated }
                else { 
                    Write-Host "FAILED" -ForegroundColor Red
                    Write-Log "    (Run 'npm i $pkgName' manually to see specific errors)" "DarkGray"
                    $status = [NpmUpdateStatus]::Failed 
                }
            }
        }
        return [PSCustomObject]@{ Package=$pkgName; Current=$currentVer; Target=$targetVer; Change=$changeType; Status=$status; Type=$TypeLabel }
    }

    # --- 7. Main Execution Flow ---
    Write-Log "Checking for outdated packages..." "Cyan"
    $npmArgs = @("outdated", "--json"); if ($IgnoreDev) { $npmArgs += "--prod" }
    $outdatedOutput = npm @npmArgs 2>$null

    if ([string]::IsNullOrWhiteSpace($outdatedOutput)) { Write-Log "All packages are up to date." "Green" 1; return }
    try { $outdatedObj = $outdatedOutput.Substring($outdatedOutput.IndexOf("{")) | ConvertFrom-Json } 
    catch { Write-Error "Failed to parse npm output."; return }

    $devDepNames = @(); if (Test-Path "package.json") { try { $devDepNames = (Get-Content "package.json" -Raw | ConvertFrom-Json).devDependencies.PSObject.Properties.Name } catch {} }
    
    $finalResults = @()
    if ($outdatedObj) {
        $prodList = @(); $devList = @()
        foreach ($prop in $outdatedObj.PSObject.Properties) { if ($devDepNames -contains $prop.Name) { $devList += $prop } else { $prodList += $prop } }

        if ($prodList.Count -gt 0) { Write-Log "`n--- Dependencies ---" "Cyan"; foreach ($p in $prodList) { $r=Update-SinglePackage -PkgProp $p -TypeLabel "Dep"; if($r){$finalResults+=$r} } }
        if (-not $IgnoreDev -and $devList.Count -gt 0) { Write-Log "`n--- DevDependencies ---" "Cyan"; foreach ($d in $devList) { $r=Update-SinglePackage -PkgProp $d -TypeLabel "DevDep"; if($r){$finalResults+=$r} } }
    }

    # --- 8. Clean Install ---
    if ($CleanInstall) {
        Write-Log "`n--- Clean Install ---" "Magenta"
        if ($DryRun) { Write-Log "[DryRun] Delete node_modules & npm install" "Gray" } 
        else {
            if (Test-Path "node_modules") { Remove-Item "node_modules" -Recurse -Force -ErrorAction SilentlyContinue }
            Write-Host -NoNewline "  Running fresh npm install... " -ForegroundColor White
            $iArgs = @("install"); if ($Force) { $iArgs += "--legacy-peer-deps" }
            
            $code = Invoke-NpmInstall -Args $iArgs
            if ($code -eq 0) { Write-Host "OK" -ForegroundColor Green } else { Write-Host "FAILED" -ForegroundColor Red }
        }
    }

    if ($Fix) { Write-Log "`n--- Audit Fix ---" "Magenta"; if (-not $DryRun) { npm audit fix } }
    elseif ($Audit) { Write-Log "`n--- Audit ---" "Magenta"; if (-not $DryRun) { npm audit } }

    # --- 9. Summary & Stats ---
    $statusCounts = $finalResults | Group-Object { $_.Status.ToString() } -AsHashTable -AsString
    $GetCount = { param($k) if ($statusCounts.ContainsKey($k)) { return $statusCounts[$k].Count } else { return 0 } }
    
    $totalUpdates = (& $GetCount "Updated") + (& $GetCount "ManifestUpdated") + (& $GetCount "Simulated")
    $fails = & $GetCount "Failed"
    
    if ($finalResults.Count -gt 0) {
        Write-Log "`n----------------------------------------" "Gray"
        Write-Log "Summary: $totalUpdates Updated, $fails Failed" $(if($fails -gt 0){"Red"}else{"Green"})
    }

    # --- 10. Deprecation Analysis ---
    if ($script:DeprecationWarnings.Count -gt 0) {
        Write-Log "`n----------------------------------------" "Gray"
        Write-Log "⚠️  DEPRECATION WARNINGS DETECTED" "Yellow"
        
        $pkgJson = Get-Content "package.json" -Raw | ConvertFrom-Json
        $directDeps = @()
        if ($pkgJson.dependencies) { $directDeps += $pkgJson.dependencies.PSObject.Properties.Name }
        if ($pkgJson.devDependencies) { $directDeps += $pkgJson.devDependencies.PSObject.Properties.Name }

        $overrides = @{}

        foreach ($warn in ($script:DeprecationWarnings | Select-Object -Unique)) {
            if ($warn -match "deprecated ([^@]+)@([^:\s]+)") {
                $depName = $matches[1]; $depVer = $matches[2]
                if ($directDeps -contains $depName) {
                     Write-Host "  • [Direct] $depName @ $depVer (Check manual update)" -ForegroundColor Red
                } else {
                     Write-Host "  • [Nested] $depName @ $depVer" -ForegroundColor Yellow
                     $overrides[$depName] = "latest"
                }
            }
        }
        if ($overrides.Count -gt 0) {
            Write-Log "`n  [Suggested Overrides]" "Cyan"
            Write-Host "`n  `"overrides`": {" -ForegroundColor White
            foreach ($k in $overrides.Keys) { Write-Host "    `"$k`": `"$($overrides[$k])`"," -ForegroundColor Green }
            Write-Host "  }" -ForegroundColor White
        }
        Write-Log "----------------------------------------" "Gray"
    }

    if ($PassThru) { return $finalResults }
    if ($ExportMarkdown) { $finalResults | Where-Object { $_.Status -le 1 } | Export-Csv $ExportMarkdown -NoTypeInformation }
}