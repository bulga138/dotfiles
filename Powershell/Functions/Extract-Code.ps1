function Extract-Code {
    <#
    .SYNOPSIS
        Concatenates source code files from a folder into a single Markdown-formatted text file.

    .DESCRIPTION
        The Extract-Code function processes all files within a specified source folder.
        It reads each file's content and formats it into a Markdown document. Each file
        is separated by a Markdown header (### filename.ext) and its content is wrapped
        in a fenced code block with the appropriate language hint (e.g., ```ps1, ```js).
        This is useful for creating a single file for code review, analysis, or pasting
        into a Large Language Model (LLM) for context.

        The function resolves relative paths to absolute paths and ensures the output
        file is created with UTF-8 encoding. It will overwrite the output file if it
        already exists.

    .PARAMETER SourceFolder
        Specifies the path to the folder containing the files you want to process.
        This parameter is mandatory.

    .PARAMETER OutputFile
        Specifies the name of the output file. The file will be created inside the
        SourceFolder. The default value is "code-compiled.txt".

    .INPUTS
        None. This function does not accept input from the pipeline.

    .OUTPUTS
        None. The function creates a file on disk specified by the OutputFile parameter.
        It writes a status message to the console.

    .EXAMPLE
        PS C:\> Extract-Code -SourceFolder "C:\MyProject\src"

        This command finds all files in the "C:\MyProject\src" directory and consolidates
        them into a single file named "code-compiled.txt" located in that same directory.

    .EXAMPLE
        PS C:\> Extract-Code -SourceFolder ".\scripts" -OutputFile "all-scripts.md"

        This command processes all files in the "scripts" sub-directory of the current
        location and saves the compiled output to "all-scripts.md".

    .NOTES
        - The function reads files using the -Raw switch to preserve line breaks.
        - The output file is encoded in UTF-8 to support a wide range of characters.
        - By default, the function only processes files in the top-level of the
        SourceFolder. To include files in all sub-directories, uncomment the
        -Recurse switch in the Get-ChildItem command within the function's script block.
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$SourceFolder,          # Folder that holds the files to process

        [string]$OutputFile = "code-compiled.txt"   # Name of the compiled file (created in $SourceFolder)
    )

    # Resolve absolute paths
    $sourcePath = Resolve-Path -Path $SourceFolder
    $outputPath = Join-Path -Path $sourcePath -ChildPath $OutputFile

    # Start with a clean output file
    if (Test-Path $outputPath) { Remove-Item $outputPath -Force }

    # Check if folder has files
    $files = Get-ChildItem -Path $sourcePath -File
    if ($files.Count -eq 0) {
        Write-Warning "No files found in folder: $sourcePath"
        return
    }

    # Enumerate files (add -Recurse if you need sub‑folders)
    $files | ForEach-Object {
        $file      = $_
        $extension = $file.Extension.TrimStart('.')   # e.g. ps1, js, py

        try {
            # Read the whole file as a single string (preserves line breaks)
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
            $filenameHeader = "### $($file.Name)"
            $codeBlock = @"
$filenameHeader
``````$extension
$content
``````
"@
            # Append to the output file (UTF‑8)
            Add-Content -Path $outputPath -Value $codeBlock -Encoding UTF8
        }
        catch {
            Write-Warning "Failed to process $($file.Name): $($_.Exception.Message)"
        }
    }

    Write-Host "All files compiled into: $outputPath"
}
