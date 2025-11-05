function Show-Tree {
    param (
        [string]$Path = (Get-Location).Path,
        [int]$IndentLevel = 0,
        [string[]]$Exclude = $null,
        [switch]$AbsolutePath,
        [switch]$SkipHidden,
        [int]$Depth = [int]::MaxValue,
        [switch]$Size,
        [string[]]$PrefixParts = @()
    )

    $effectiveExclude = if ($Exclude) { $Exclude } else { @('node_modules', 'dist', '.git') }

    function Is-Excluded([string]$itemPath) {
        $itemName = Split-Path $itemPath -Leaf
        foreach ($e in $effectiveExclude) {
            if ($itemName -eq $e) { return $true }
        }
        return $false
    }

    if ($IndentLevel -gt $Depth) {
        return
    }

    $getChildItemParams = @{
        LiteralPath = $Path
        Force       = -not $SkipHidden
    }

    $dirs = Get-ChildItem @getChildItemParams -Directory |
        Where-Object { -not (Is-Excluded $_.FullName) }

    $files = Get-ChildItem @getChildItemParams -File

    $allItems = @($files) + @($dirs)
    
    $dirSet = New-Object -TypeName "System.Collections.Generic.HashSet[string]" -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    
    if ($null -ne $dirs) {
        foreach ($dir in $dirs) {
            $dirSet.Add($dir.FullName) | Out-Null
        }
    }

    for ($i = 0; $i -lt $allItems.Count; $i++) {
        $item = $allItems[$i]
        $isLast = ($i -eq $allItems.Count - 1)
        
        $prefix = ""
        foreach ($part in $PrefixParts) {
            $prefix += $part
        }
        
        $currentPrefix = if ($isLast) { "└── " } else { "├── " }
        $prefix += $currentPrefix
        
        $display = if ($AbsolutePath) { $item.FullName } else { $item.Name }

        if ($item -is [System.IO.FileInfo] -and $Size) {
            $fileSize = switch ($item.Length) {
                { $_ -gt 1GB } { "$([math]::Round($_ / 1GB, 2)) GB" }
                { $_ -gt 1MB } { "$([math]::Round($_ / 1MB, 2)) MB" }
                { $_ -gt 1KB } { "$([math]::Round($_ / 1KB, 2)) KB" }
                default { "$_ B" }
            }
            $display += " ($fileSize)"
        }

        Write-Host $prefix -ForegroundColor White -NoNewline
        
        if ($item -is [System.IO.DirectoryInfo]) {
            Write-Host $display -ForegroundColor Blue
        } else {
            Write-Host $display -ForegroundColor Cyan
        }

        if ($dirSet.Contains($item.FullName)) {
            $newPrefixParts = @()
            $newPrefixParts += $PrefixParts

            if ($isLast) {
                $newPrefixParts += "    "
            } else {
                $newPrefixParts += "│   "
            }

            Show-Tree -Path $item.FullName `
                -IndentLevel ($IndentLevel + 1) `
                -Exclude $effectiveExclude `
                -AbsolutePath:$AbsolutePath `
                -SkipHidden:$SkipHidden `
                -Depth $Depth `
                -Size:$Size `
                -PrefixParts $newPrefixParts
        }
    }
}