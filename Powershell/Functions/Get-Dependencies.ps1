function Get-Dependencies {
    <#
    .SYNOPSIS
        Recursively scans for *package.json* files (excluding any under a *node_modules* folder),
        extracts `dependencies` and `devDependencies`, and returns a Markdown‑formatted table.

    .DESCRIPTION
        * By default the table excludes the **Package File** column that shows the path
          relative to the supplied `-RootPath` **and** collapse duplicate dependency entries (keeping the first encountered version).
        * Use `-ShowPackageFile:$true` to show that column.
        * Output is always sorted alphabetically by dependency name.

    .PARAMETER RootPath
        Starting directory for the search. Defaults to the current location.

    .PARAMETER ShowPackageFile
        Switch to control whether the *Package File* column appears.
        Default is `$false`.

    .OUTPUTS
        [string] – The complete Markdown table (including header).

    .EXAMPLE
        Get-Dependencies -RootPath "C:\Projects"
        Get-Dependencies -RootPath "C:\Projects" -ShowPackageFile:$true
    #>

    param (
        [string]$RootPath = (Get-Location).Path,
        [bool]$ShowPackageFile = $false
    )

    # ------------------------------------------------------------------
    # Helper – turn any dictionary‑like object into Markdown rows
    # ------------------------------------------------------------------
    function Convert-ToMarkdownRow {
        param (
            [string]$RelativePath,
            [hashtable]$Deps   # already a hashtable
        )

        foreach ($name in $Deps.Keys) {
            $version = $Deps[$name]

            $escapedName    = $name    -replace '\|', '\|'
            $escapedVersion = $version -replace '\|', '\|'

            if ($ShowPackageFile) {
                "$RelativePath | $escapedName | $escapedVersion"
            } else {
                "$escapedName | $escapedVersion"
            }
        }
    }

    # --------------------------------------------------------------
    # Find all package.json files, skipping any inside node_modules
    # --------------------------------------------------------------
    $packageFiles = Get-ChildItem -Path $RootPath -Recurse -Filter 'package.json' -File |
        Where-Object { $_.FullName -notmatch '[\\/]node_modules[\\/]' }

    # --------------------------------------------------------------
    # Build the Markdown table header
    # --------------------------------------------------------------
    $mdLines = @()
    if ($ShowPackageFile) {
        $mdLines += '| Package File | Dependency | Version |'
        $mdLines += '|--------------|------------|---------|'
    } else {
        $mdLines += '| Dependency | Version |'
        $mdLines += '|------------|---------|'
    }

    # When deduplication is required we keep a hashtable of seen dependencies
    $seen = @{}   # key = dependency name, value = version (first encountered)

    foreach ($file in $packageFiles) {
        try {
            $json = Get-Content $file.FullName -Raw | ConvertFrom-Json -Depth 10
        } catch {
            Write-Warning "Unable to parse JSON in $($file.FullName): $_"
            continue
        }

        # Relative path (relative to the supplied RootPath)
        $relativePath = $file.FullName.Substring($RootPath.Length).TrimStart('\','/')

        $sections = @()
        if ($json.dependencies)   { $sections += $json.dependencies }
        if ($json.devDependencies) { $sections += $json.devDependencies }

        foreach ($section in $sections) {
            # Ensure we have a hashtable for uniform handling
            if ($section -isnot [hashtable]) {
                $hashtable = @{}
                foreach ($prop in $section.PSObject.Properties) {
                    $hashtable[$prop.Name] = $prop.Value
                }
            } else {
                $hashtable = $section
            }

            if ($ShowPackageFile) {
                # No deduplication – list everything with its source file
                $mdLines += Convert-ToMarkdownRow -RelativePath $relativePath -Deps $hashtable
            } else {
                # Deduplicate across all files
                foreach ($name in $hashtable.Keys) {
                    if (-not $seen.ContainsKey($name)) {
                        $seen[$name] = $hashtable[$name]
                    }
                }
            }
        }
    }

    # ------------------------------------------------------------------
    # When deduplication is active, output the collected entries sorted
    # ------------------------------------------------------------------
    if (-not $ShowPackageFile) {
        $sorted = $seen.GetEnumerator() | Sort-Object Name
        foreach ($entry in $sorted) {
            $mdLines += Convert-ToMarkdownRow -RelativePath '' -Deps @{ $entry.Name = $entry.Value }
        }
    }

    return ($mdLines -join "`n")
}
