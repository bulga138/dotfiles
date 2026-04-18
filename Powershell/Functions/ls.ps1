function ls {
<#
.SYNOPSIS
    Lists directory contents in long format, including hidden and system items
    (PowerShell equivalent of Unix `ls -la`).

.DESCRIPTION
    The `ls` function is a thin wrapper around `Get‑ChildItem`. It automatically
    adds the `-Force` switch so that hidden (`.`‑prefixed) and system files are
    displayed, and it forwards any additional arguments you supply (paths,
    filters, wildcards, etc.) to `Get‑ChildItem`.

    The output format is the default long view provided by PowerShell, which
    includes Name, Length, Mode, LastWriteTime, etc.

.PARAMETER Args
    Any arguments you would normally pass to `Get‑ChildItem`, such as a path,
    a filter (`-Filter`), a wildcard (`*.txt`), or other switches. These are
    collected via `ValueFromRemainingArguments` and passed through unchanged.

.INPUTS
    None. This function does not accept pipeline input.

.OUTPUTS
    System.IO.FileInfo / System.IO.DirectoryInfo objects representing the
    items found, displayed in the standard PowerShell long listing format.

.EXAMPLE
    ls
    # Lists the current directory, showing all files (including hidden) in long format.

.EXAMPLE
    ls *.ps1
    # Lists only PowerShell script files in the current folder, including hidden ones.

.EXAMPLE
    ls C:\Temp -Recurse
    # Recursively lists everything under C:\Temp, showing hidden/system items.

.NOTES
    • This function does **not** replace the built‑in `ls` alias; it simply
      overrides it in the current session (or in your profile for persistence).
    • Because `Get‑ChildItem` already provides a detailed view, no extra formatting
      is required.
    • To make the function permanent, add it to your PowerShell profile
      (`$PROFILE`).

#>
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        $Args
    )
    Get-ChildItem -Force @Args
}
