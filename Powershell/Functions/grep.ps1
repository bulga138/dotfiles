function grep {
  [CmdletBinding()]
  param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Args
  )

  # Helpers
  $patterns = @()
  $files = @()
  $flags = @{
    i = $false; F = $false; v = $false; w = $false; x = $false
    c = $false; o = $false; q = $false; s = $false; n = $false
    recurse = $false; recurseAll = $false; m = -1
  }

  # Parse simple GNU-like options from $Args
  for ($i=0; $i -lt $Args.Count; $i++) {
    $a = $Args[$i]
    if ($a -match '^-(?<s>[a-zA-Z]+)$' ) {
      foreach ($ch in $Matches.s.ToCharArray()) {
        switch -Case ($ch) {
          'i' { $flags.i = $true }
          'F' { $flags.F = $true }
          'v' { $flags.v = $true }
          'w' { $flags.w = $true }
          'x' { $flags.x = $true }
          'c' { $flags.c = $true }
          'o' { $flags.o = $true }
          'q' { $flags.q = $true }
          's' { $flags.s = $true }
          'n' { $flags.n = $true }
          'r' { $flags.recurse = $true }
          'R' { $flags.recurseAll = $true }
          default { } # ignore unknown single-letter flags here
        }
      }
      continue
    }

    if ($a -match '^-m$') {
      $i++; if ($i -lt $Args.Count) { $flags.m = [int]$Args[$i] }
      continue
    }

    if ($a -match '^-e$') {
      $i++; if ($i -lt $Args.Count) { $patterns += $Args[$i] }
      continue
    }

    if ($a -match '^-f$') {
      $i++; if ($i -lt $Args.Count) {
        $fn = $Args[$i]
        if ($fn -eq '-') { $patterns += [Console]::In.ReadToEnd().Split("`n") } else { $patterns += Get-Content -LiteralPath $fn -ErrorAction SilentlyContinue }
      }
      continue
    }

    if ($a -match '^--') {
      switch ($a) {
        '--help' { "Usage: grep [OPTIONS] PATTERN [FILE...]" ; return }
        '--version' { "grep (ps-grep) 1.0" ; return }
        default { continue }
      }
    }

    # Non-option: collect
    $files += $a
  }

  if ($patterns.Count -eq 0) {
    if ($files.Count -eq 0) { Write-Error 'grep: no pattern'; return }
    $Pattern = $files[0]; if ($files.Count -gt 1) { $files = $files[1..($files.Count-1)] } else { $files = @('.') }
    $patterns += $Pattern
  }

  # Determine file list (handle recursion simply)
  if ($files.Count -eq 0) { $files = @('.') }
  $fileList = @()
  foreach ($p in $files) {
    if (Test-Path $p) {
      $it = Get-Item -LiteralPath $p -ErrorAction SilentlyContinue
      if ($it -and $it.PSIsContainer) {
        if ($flags.recurse -or $flags.recurseAll) { $fileList += Get-ChildItem -Path $p -Recurse -File -ErrorAction SilentlyContinue }
        else { $fileList += Get-ChildItem -Path $p -File -ErrorAction SilentlyContinue }
      } elseif ($it) { $fileList += $it }
    } else {
      if (-not $flags.s) { Write-Error ("grep: {0}: No such file or directory" -f $p) }
    }
  }

  if ($fileList.Count -eq 0) { 
    if ([Console]::IsInputRedirected) {
      $inputLines = [Console]::In.ReadToEnd().Split("`n")
      $fileList = ,([PSCustomObject]@{ FullName = '(standard input)'; Lines = $inputLines })
    } else {
      return # Exit immediately instead of hanging!
    }
  }
  else {
    $fileList = $fileList | ForEach-Object {
      try { $lns = Get-Content -LiteralPath $_.FullName -ErrorAction Stop -Encoding Default } catch { $lns = @(); if (-not $flags.s) { Write-Error ("grep: {0}: {1}" -f $_.FullName, $_.Exception.Message) } }
      [PSCustomObject]@{ FullName = $_.FullName; Lines = $lns }
    }
  }

  foreach ($f in $fileList) {
    $matchCount = 0
    for ($ln=0; $ln -lt $f.Lines.Count; $ln++) {
      $line = $f.Lines[$ln]
      $isMatch = $false
      foreach ($pat in $patterns) {
        if ($flags.F) {
          $cmp = if ($flags.i) { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
          if ($line.IndexOf($pat, $cmp) -ge 0) { $isMatch = $true; break }
        } else {
          $regexPat = $pat
          if ($flags.w) { $regexPat = "\b($regexPat)\b" }
          if ($flags.x) { $regexPat = "^(?:$regexPat)$" }
          try {
            $opts = if ($flags.i) { [System.Text.RegularExpressions.RegexOptions]::IgnoreCase } else { [System.Text.RegularExpressions.RegexOptions]::None }
            if ([regex]::IsMatch($line, $regexPat, $opts)) { $isMatch = $true; break }
          } catch { }
        }
      }

      if ($flags.v) { $isMatch = -not $isMatch }

      if ($isMatch) {
        $matchCount++
        if ($flags.q) { return 0 }
        if ($flags.c) { continue }
        if ($flags.o) {
          try { 
            $matchOpts = if ($flags.i) { 'IgnoreCase' } else { [System.Text.RegularExpressions.RegexOptions]::None }
            $matches = [regex]::Matches($line, $regexPat, $matchOpts) | ForEach-Object { $_.Value } 
          } catch { 
            $matches = @($pat) 
          }
          foreach ($mo in $matches) {
            $prefix = if ($fileList.Count -gt 1) { "$($f.FullName):" } else { '' }
            if ($flags.n) { $prefix += "$($ln+1):" }
            Write-Output ("{0}{1}" -f $prefix, $mo)
          }
        } else {
          $prefix = if ($fileList.Count -gt 1) { "$($f.FullName):" } else { '' }
          if ($flags.n) { $prefix += "$($ln+1):" }
          Write-Output ("{0}{1}" -f $prefix, $line)
        }
        if ($flags.m -ge 0 -and $matchCount -ge $flags.m) { break }
      }
    }

    if ($flags.c) {
      $out = if ($fileList.Count -gt 1) { "{0}:{1}" -f $f.FullName, $matchCount } else { $matchCount.ToString() }
      Write-Output $out
    }
  }
}
