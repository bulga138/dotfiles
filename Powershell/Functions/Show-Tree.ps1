function Show-Tree {
    <#
    .SYNOPSIS
        Displays a visual, recursive tree of a folder's contents in the console.

    .DESCRIPTION
        The Show-Tree function emulates the behavior of the classic 'tree' command,
        providing a color-coded, visual representation of a directory structure.
        It recursively lists files and directories from a specified path using
        box-drawing characters to illustrate the hierarchy.

        The function offers several options for customization, including excluding
        specific folders, limiting the recursion depth, showing file sizes, displaying
        absolute paths, and skipping hidden items.

    .PARAMETER Path
        Specifies the path to the root folder to display. The default is the current
        location.

    .PARAMETER Exclude
        Specifies an array of folder or file names to exclude from the output.
        By default, the function excludes 'node_modules', 'dist', and '.git'.

    .PARAMETER Depth
        Specifies the maximum number of directory levels to display. The default
        value (`[int]::MaxValue`) displays all levels.

    .PARAMETER Size
        If specified, displays the size of each file in a human-readable format
        (B, KB, MB, GB) next to its name.

    .PARAMETER AbsolutePath
        If specified, displays the full, absolute path for each item instead of
        just its name.

    .PARAMETER SkipHidden
        If specified, hidden files and directories are excluded from the output.

    .PARAMETER IndentLevel
        This parameter is intended for internal use by the recursive function calls
        to track the current recursion depth. It should not be specified manually.

    .PARAMETER PrefixParts
        This parameter is intended for internal use by the recursive function calls
        to build the visual prefix (`│   `, `    `) for each line. It should not be
        specified manually.

    .INPUTS
        None. This function does not accept input from the pipeline.

    .OUTPUTS
        System.String. The function writes a formatted tree structure directly
        to the console; it does not return a string object.

    .EXAMPLE
        PS C:\MyProject> Show-Tree

        This command displays a recursive tree of the current directory, excluding
        the default 'node_modules', 'dist', and '.git' folders.

    .EXAMPLE
        PS C:\MyProject> Show-Tree -Depth 2 -Size

        This command displays the directory tree for only the top two levels and
        includes the size of each file.

    .EXAMPLE
        PS C:\> Show-Tree -Path "C:\Users\Alice\Documents" -SkipHidden -Exclude @("temp", "old_files")

        This command displays the tree for the user's Documents folder, skips all
        hidden items, and additionally excludes any folders or files named "temp"
        or "old_files".

    .NOTES
        - Directories are displayed in blue, and files are displayed in cyan.
        - The visual prefix characters (├──, └──, │  ) are in white.
        - This is a pure PowerShell implementation. Performance may vary on
        extremely large directory structures compared to native compiled tools.
    #>
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