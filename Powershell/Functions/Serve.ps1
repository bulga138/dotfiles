function Serve {
<#
.SYNOPSIS
    Starts a simple HTTP server that serves the current directory.

.DESCRIPTION
    Uses the built‑in .NET `HttpListener` (no external tools required) to expose
    the folder you are in on `http://localhost:<port>/`.  The default port is
    **3000**, but you can supply any free port you like.

.PARAMETER Port
    TCP port on which the server will listen.  Defaults to 3000.

.EXAMPLE
    Serve               # http://localhost:3000/
    Serve 8080          # http://localhost:8080/
#>
    param(
        [int]$Port = 3000
    )

    # Resolve the absolute path of the folder we are in
    $root = (Get-Location).ProviderPath

    # Build the listener URL
    $url = "http://localhost:$Port/"

    # Create and start the listener
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add($url)
    try {
        $listener.Start()
        Write-Host "Serving $root on $url (Press Ctrl+C to stop)" -ForegroundColor Cyan

        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response

            # Map the request URL to a file system path
            $relativePath = [System.Uri]::UnescapeDataString($request.Url.AbsolutePath.TrimStart('/'))
            $localPath = Join-Path $root $relativePath

            if ([string]::IsNullOrEmpty($relativePath) -or $relativePath -eq '/') {
                # Default to index.html if present, otherwise list directory
                $index = Join-Path $root 'index.html'
                if (Test-Path $index) {
                    $localPath = $index
                }
            }

            if (Test-Path $localPath -PathType Leaf) {
                # Serve a file
                $bytes = [System.IO.File]::ReadAllBytes($localPath)
                $response.ContentType = [System.Web.MimeMapping]::GetMimeMapping($localPath)
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes,0,$bytes.Length)
            }
            elseif (Test-Path $localPath -PathType Container) {
                # Simple directory listing
                $items = Get-ChildItem -Force $localPath | ForEach-Object {
                    "<a href='$_'>$($_.Name)</a>"
                }
                $html = @"
<!DOCTYPE html>
<html><head><meta charset='utf-8'><title>Index of $relativePath</title></head>
<body><h2>Index of $relativePath</h2><ul>
$($items -join "`n")
</ul></body></html>
"@
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
                $response.ContentType = 'text/html; charset=utf-8'
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes,0,$bytes.Length)
            }
            else {
                # 404
                $response.StatusCode = 404
                $msg = "File not found"
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes,0,$bytes.Length)
            }

            $response.OutputStream.Close()
        }
    }
    finally {
        $listener.Stop()
        $listener.Close()
    }
}
