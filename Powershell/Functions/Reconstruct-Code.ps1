function Reconstruct-Code {
    <#
    .SYNOPSIS
        Recreates a directory structure and files from a Markdown-formatted consolidation file.

    .DESCRIPTION
        The Reconstruct-Code function parses a text file containing multiple code blocks 
        prefixed by Markdown headers (### path/to/file.ext). It extracts the content 
        within the code blocks and writes them to the specified directory, automatically 
        creating any necessary subfolders.

    .PARAMETER InputFile
        The path to the consolidated text/markdown file containing the code blocks.
        This parameter is mandatory.

    .PARAMETER DestinationFolder
        The root directory where the files and folders should be recreated.
        Defaults to the current location.

    .PARAMETER Force
        When specified, allows the script to overwrite existing files without prompting.

    .EXAMPLE
        PS C:\> Reconstruct-Code -InputFile "code-compiled.txt" -DestinationFolder ".\RestoredProject"

        This command reads code-compiled.txt and recreates all files inside the "RestoredProject" folder.

    .NOTES
        - The function uses regex to identify the pattern: ### path/to/file followed by ```code```.
        - Uses UTF-8 encoding for all created files.
        - Uses ${variable} syntax to avoid namespace resolution errors with colons.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [string]$DestinationFolder = ".",

        [switch]$Force
    )

    # Resolve paths
    if (-not (Test-Path $InputFile)) {
        Write-Error "Input file not found: $InputFile"
        return
    }

    $inputPath = (Resolve-Path $InputFile).Path
    
    # Ensure destination exists
    if (-not (Test-Path $DestinationFolder)) {
        New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
    }
    $destRoot = (Resolve-Path $DestinationFolder).Path

    Write-Host "Reading consolidated file: $inputPath" -ForegroundColor Cyan

    try {
        $content = Get-Content -Raw -Path $inputPath -ErrorAction Stop
        
        # Regex pattern: 
        # 1. Matches line starting with ### and captures the path
        # 2. Matches starting backticks and optional language hint
        # 3. Captures everything inside until the closing backticks
        $pattern = '(?ms)^###\s+(?<path>[^\r\n]+)\s*\r?\n```[a-z]*\r?\n(?<code>(.*?))```'
        $matches = [regex]::Matches($content, $pattern)

        if ($matches.Count -eq 0) {
            Write-Warning "No valid file patterns (### path/to/file) found in the input file."
            return
        }

        foreach ($m in $matches) {
            $relativePath = $m.Groups['path'].Value.Trim()
            $fileContent  = $m.Groups['code'].Value
            
            # Combine root destination with the relative path from the text file
            $fullPath = Join-Path -Path $destRoot -ChildPath $relativePath
            
            # Ensure the parent directory exists
            $parentDir = Split-Path -Path $fullPath -Parent
            if (-not (Test-Path $parentDir)) {
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            }

            try {
                # Recreate the file
                $setContentParams = @{
                    Path     = $fullPath
                    Value    = $fileContent
                    Encoding = "UTF8"
                    Force    = $Force
                }
                Set-Content @setContentParams -ErrorAction Stop
                Write-Host "Successfully recreated: ${relativePath}" -ForegroundColor Green
            }
            catch {
                # Using ${fullPath} to prevent the colon variable reference error
                Write-Warning "Failed to write ${fullPath}: $($_.Exception.Message)"
            }
        }

        Write-Host "`nProcess Complete. $($matches.Count) files processed." -ForegroundColor Yellow
    }
    catch {
        Write-Error "An error occurred while processing the file: $($_.Exception.Message)"
    }
}