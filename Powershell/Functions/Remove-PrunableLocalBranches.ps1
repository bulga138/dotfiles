function Remove-PrunableLocalBranches {
    param(
        [string]$MainBranch = 'master',
        [string]$Remote = 'origin'
    )

    $useAnsi = $Host.UI.RawUI.ForegroundColor -ne $null -and
               $env:TERM -ne 'dumb' -and
               !$env:NO_COLOR

    # ── ANSI helpers ────────────────────────────────────────────────────────────
    function ansi($code) { if ($useAnsi) { "$([char]27)[$code`m" } else { '' } }
    function esc ($code) { if ($useAnsi) { "$([char]27)[$code"   } else { '' } }

    $RESET    = ansi 0
    $CYAN     = ansi 96
    $GREEN    = ansi '92'
    $DIM      = ansi 2
    $YELLOW   = ansi 93
    $BOLD     = ansi 1
    $INVERT   = ansi 7

    # ── Git work (unchanged) ────────────────────────────────────────────────────
    git fetch --prune $Remote 2>$null

    $gone = @(git branch -vv |
        ForEach-Object { $_.Trim() } |
        Where-Object   { $_ -match ':\s+gone\]' } |
        ForEach-Object { ($_ -split '\s+')[0] })

    if (-not $gone) {
        Write-Output "No local branches with gone remote refs."
        return
    }

    $merged = git branch --merged $MainBranch |
        ForEach-Object { $_.Trim() -replace '^[\*\s]+', '' }

    $candidates = @()
    foreach ($b in $gone) {
        $isMerged      = $merged -contains $b
        $lastCommit    = git rev-parse --short $b 2>$null
        $lastCommitMsg = git log -1 --pretty=format:'%s' $b 2>$null
        $prNumber      = $null
        $prAuthor      = $null

        $mergeLines = git log $MainBranch --merges --pretty=format:'%H %s' -n 200 2>$null
        if ($mergeLines) {
            foreach ($line in $mergeLines) {
                if ($line -match 'pull request #([0-9]+)') {
                    $contains = git branch --contains $lastCommit --format='%(refname:short)' 2>$null |
                                Select-String -Pattern $MainBranch -Quiet
                    if ($contains -or ($line -match [regex]::Escape($b))) {
                        $prNumber = $matches[1]; break
                    }
                } elseif ($line -match [regex]::Escape($b)) { break }
            }
        }
        if ($prNumber) {
            $mergeHash = git log $MainBranch --grep "#$prNumber" --pretty=format:'%H' -n 1 2>$null
            if ($mergeHash) { $prAuthor = git show -s --format='%an' $mergeHash 2>$null }
        }

        $candidates += [pscustomobject]@{
            Branch      = $b
            MergedInto  = if ($isMerged) { $MainBranch } else { '' }
            LastCommit  = $lastCommit
            LastMessage = $lastCommitMsg
            PRNumber    = $prNumber
            PRAuthor    = $prAuthor
        }
    }

    $items = @($candidates | Where-Object { $_.MergedInto -ne '' })

    if (-not $items) {
        Write-Output "No branches with gone remotes that are merged into '$MainBranch'."
        return
    }

    # ── In-place TUI ────────────────────────────────────────────────────────────
    # Layout (every row uses the SAME column widths):
    #
    #   PTR  CB    BRANCH INFO
    #   ▶    [✔]   feature/my-branch #42 (Alice)
    #        [ ]   fix/old-bug
    #
    # PTR  = 1 char + 1 space  (always rendered, '▶' or ' ')
    # CB   = 3 chars + 1 space ('[✔]' or '[ ]')
    # REST = branch + optional PR + optional author

    $HEADER_LINES = 3   # header block + 1 blank line below + column labels
    $FOOTER_LINES = 2   # blank line + "Selected: N" status

    # Returns the number of lines written (so next render knows how far to jump back)
    function Render-Menu ([int]$prevLines = 0) {
        # Move cursor back up to overwrite previous render
        if ($prevLines -gt 0) {
            Write-Host -NoNewline (esc "${prevLines}A")
        }

        $lines = 0

        # Header
        Write-Host -NoNewline (esc '2K')   # erase line before writing
        Write-Host "${CYAN}${BOLD}Prune merged branches${RESET}  ${DIM}↑↓ navigate · Space toggle · A all · Enter confirm · Q abort${RESET}"
        $lines++

        Write-Host -NoNewline (esc '2K')
        Write-Host "${DIM}  PTR  ●     BRANCH${RESET}"
        $lines++

        Write-Host -NoNewline (esc '2K')
        Write-Host "${DIM}  ─────────────────────────────────────────────────────${RESET}"
        $lines++

        # Branch rows
        for ($i = 0; $i -lt $items.Count; $i++) {
            $item       = $items[$i]
            $isCurrent  = $i -eq $currIndex
            $isSelected = $selected -contains $i

            # Fixed-width pointer column (1 char)
            $ptr = if ($isCurrent) { "${CYAN}▶${RESET}" } else { ' ' }

            # Fixed-width checkbox column (3 chars)
            $cb = if ($isSelected) { "${GREEN}◉${RESET}" } else { "${DIM}○${RESET}" }

            # Branch label – highlight entire row when current
            $prPart     = if ($item.PRNumber) { " ${DIM}#$($item.PRNumber)${RESET}" } else { '' }
            $authorPart = if ($item.PRAuthor) { " ${DIM}($($item.PRAuthor))${RESET}" } else { '' }
            $label      = if ($isCurrent) { "${INVERT}$($item.Branch)${RESET}" } else { $item.Branch }

            Write-Host -NoNewline (esc '2K')
            Write-Host "  $ptr  $cb  $label$prPart$authorPart"
            $lines++
        }

        # Footer
        Write-Host -NoNewline (esc '2K')
        Write-Host ''
        $lines++

        Write-Host -NoNewline (esc '2K')
        Write-Host "  ${YELLOW}Selected: $($selected.Count) / $($items.Count) branch(es)${RESET}"
        $lines++

        return $lines
    }

    $selected  = @()
    $currIndex = 0
    $prevLines = 0

    # Initial render
    $prevLines = Render-Menu 0

    do {
        $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

        switch ($key.VirtualKeyCode) {
            38 { # ↑
                $currIndex = if ($currIndex -eq 0) { $items.Count - 1 } else { $currIndex - 1 }
            }
            40 { # ↓
                $currIndex = if ($currIndex -eq $items.Count - 1) { 0 } else { $currIndex + 1 }
            }
            32 { # Space – toggle current
                if ($selected -contains $currIndex) {
                    $selected = $selected | Where-Object { $_ -ne $currIndex }
                } else {
                    $selected += $currIndex
                }
            }
            65 { # A – toggle all
                $selected = if ($selected.Count -eq $items.Count) { @() } else { 0..($items.Count - 1) }
            }
            81 { # Q – quit
                $selected  = @()
                $key       = [pscustomobject]@{ VirtualKeyCode = 13 }  # force exit
            }
        }

        $prevLines = Render-Menu $prevLines

    } while ($key.VirtualKeyCode -ne 13)

    # Move cursor below the TUI block cleanly (no leftover artifacts)
    Write-Host ''

    # ── Deletion (unchanged) ────────────────────────────────────────────────────
    $chosenBranches = if ($selected.Count -gt 0) { @($items[$selected]) } else { @() }

    if (-not $chosenBranches) {
        Write-Output "No branches selected. Aborting."
        return
    }

    Write-Output "Deleting the following branches:"
    $chosenBranches.Branch | ForEach-Object { Write-Output "  - $_" }

    Write-Host -NoNewline "Confirm deletion? ${YELLOW}[y/N]${RESET} "
    $answer = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Write-Host $answer.Character

    if ($answer.Character -notin @('y','Y')) {
        Write-Output "Aborted."
        return
    }

    foreach ($row in $chosenBranches) {
        git branch -d $row.Branch 2>&1 | Write-Output
    }

    Write-Output "Done."
}