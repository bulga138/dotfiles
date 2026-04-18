function sudo {
    <#
    .SYNOPSIS
        Run a command elevated (UAC prompt) from PowerShell 7.
    .DESCRIPTION
        Elevates the provided command or script block using Start-Process with -Verb RunAs.
        Works with external executables and PowerShell -Command strings. Returns exit code.
    .PARAMETER Command
        The command to run (string or scriptblock). When passing complex arguments, supply a single string.
    .PARAMETER Args
        Additional arguments to pass to the command.
    #>
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [AllowNull()]
        [Object]$Command,

        [Parameter(ValueFromRemainingArguments=$true)]
        [String[]]$Args
    )

    # Build executable and argument string
    if ($Command -is [System.Management.Automation.ScriptBlock]) {
        $psCommand = $Command.ToString()
        $argLine = "-NoProfile -NonInteractive -Command `"& { $psCommand }`""
        if ($Args) { $argLine += ' ' + ($Args -join ' ') }
        $file = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
        if (-not $file) { $file = (Get-Command powershell -ErrorAction SilentlyContinue).Source }
        if (-not $file) { Write-Error "PowerShell executable not found."; return 1 }
        $startInfo = @{ FilePath = $file; ArgumentList = $argLine; Verb = 'RunAs'; Wait = $true }
    } elseif ($Command -is [string]) {
        # If command is an executable path or command name, pass args separately
        $exe = $Command
        $argLine = if ($Args) { $Args -join ' ' } else { '' }
        $startInfo = @{ FilePath = $exe; ArgumentList = $argLine; Verb = 'RunAs'; Wait = $true }
    } else {
        Write-Error "Unsupported command type."
        return 1
    }

    try {
        $proc = Start-Process @startInfo -PassThru
        return $proc.ExitCode
    } catch [System.ComponentModel.Win32Exception] {
        # User cancelled UAC or cannot elevate
        Write-Error "Elevation canceled or failed: $($_.Exception.Message)"
        return 1
    } catch {
        Write-Error "Failed to start elevated process: $_"
        return 1
    }
}
