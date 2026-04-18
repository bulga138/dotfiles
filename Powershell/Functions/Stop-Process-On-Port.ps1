function Stop-ProcessOnPort {
    <#
    .SYNOPSIS
        Terminates any process that is listening on a specified TCP port.

    .DESCRIPTION
        The function looks up the owning process ID(s) for the given local port
        using `Get-NetTCPConnection`.  If one or more processes are found they
        are stopped with `Stop-Process -Force`.  Errors are reported with a
        clear warning that includes the original exception message.

    .PARAMETER Port
        The local TCP port number (1-65535) to free.

    .EXAMPLE
        Stop-ProcessOnPort -Port 8080
        # Stops whatever process is listening on port 8080.

    .NOTES
        Requires administrative privileges to query and kill processes that
        you do not own.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateRange(1,65535)]
        [int]$Port
    )

    # -------------------------------------------------------------------------
    # Find the PID(s) listening on the requested port
    # -------------------------------------------------------------------------
    $targetPids = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty OwningProcess -Unique

    if (-not $targetPids) {
        Write-Host "No process is listening on port $Port." -ForegroundColor Cyan
        return
    }

    # -------------------------------------------------------------------------
    # Attempt to stop each PID
    # -------------------------------------------------------------------------
    foreach ($targetPid in $targetPids) {
        try {
            $proc = Get-Process -Id $targetPid -ErrorAction Stop
            Write-Host "Stopping process $($proc.Name) (PID $targetPid) listening on port $Port..." `
                       -ForegroundColor Yellow
            Stop-Process -Id $targetPid -Force -ErrorAction Stop
            Write-Host "Process $targetPid terminated." -ForegroundColor Green
        }
        catch {
            # Use a format string to embed the error record safely
            $msg = "Failed to stop PID ${targetPid}: {0}" -f $_
            Write-Warning $msg
        }
    }
}