function Chunk-File {
    <#
    .SYNOPSIS
        Splits a file into smaller chunks based on size, character count, or a set number of parts.

    .DESCRIPTION
        This function reads a single file and splits it into multiple output files.
        It operates in one of three mutually exclusive modes:
        - BySize: Creates chunks of a specific byte size (e.g., 10MB).
        - ByChars: Creates chunks of a specific character count (for text files).
        - ByParts: Splits the file into a specific number of equal-sized parts (by bytes).

        This function uses efficient .NET streams and can handle very large files
        without consuming excessive memory.

    .PARAMETER Path
        The path to the source file you want to split.
        This parameter is mandatory and accepts pipeline input.

    .PARAMETER DestinationPath
        The output directory where the chunked files will be saved.
        If not specified, the chunks are saved in the same directory as the source file.

    .PARAMETER BaseName
        The base name to use for the output files.
        If not specified, the source file's name is used.
        Files will be named like: [BaseName]_[mode]_part[number].[ext]

    .PARAMETER ChunkSize
        (Parameter Set: BySize)
        Specifies the maximum size, in bytes, for each chunk.
        You can use suffixes like KB, MB, GB (e.g., 10MB).

    .PARAMETER PartCount
        (Parameter Set: ByParts)
        Specifies the exact number of parts to split the file into.
        The file size (in bytes) will be divided by this number to determine the chunk size.

    .PARAMETER CharacterCount
        (Parameter Set: ByChars)
        Specifies the number of characters for each chunk.
        This mode is intended for text files and respects encoding.

    .EXAMPLE
        # Example 1: Split a 1GB log file into 100MB chunks
        Chunk-File -Path "C:\Logs\large-app.log" -ChunkSize 100MB

    .EXAMPLE
        # Example 2: Split a large text file into exactly 4 parts
        Chunk-File -Path "D:\Data\big-file.zip" -PartCount 4

    .EXAMPLE
        # Example 3: Split a document into chunks of 50,000 characters each
        Chunk-File -Path "C:\Docs\novel.txt" -CharacterCount 50000

    .EXAMPLE
        # Example 4: Use the pipeline and a custom output directory
        Get-Item "C:\Logs\archive.log" | Chunk-File -PartCount 10 -DestinationPath "C:\Chunks"

    .NOTES
        - 'BySize' and 'ByParts' modes perform a binary split. They are fast and work on
          any file type, but they may split multi-byte text characters in the middle.
        - 'ByChars' mode performs a text-aware split and is recommended for
          splitting text files (like .txt, .log, .csv, .json) to preserve
          character encoding and integrity.
    #>
    [CmdletBinding(DefaultParameterSetName = 'BySize')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false)]
        [string]$BaseName,

        [Parameter(ParameterSetName = 'BySize', Mandatory = $true)]
        [long]$ChunkSize,

        [Parameter(ParameterSetName = 'ByParts', Mandatory = $true)]
        [int]$PartCount,

        [Parameter(ParameterSetName = 'ByChars', Mandatory = $true)]
        [long]$CharacterCount
    )

    process {
        try {
            # --- 1. Resolve Paths and Validate ---
            $File = Get-Item -LiteralPath (Resolve-Path $Path)
            if (-not $File.Exists -or $File.PSIsContainer) {
                Write-Error "Invalid file path: '$Path'. File does not exist or is a directory."
                return
            }

            # Determine output directory
            $DestDir = if ($PSBoundParameters.ContainsKey('DestinationPath')) {
                Resolve-Path $DestinationPath
            } else {
                $File.DirectoryName
            }

            # Determine output base name
            $Base = if ($PSBoundParameters.ContainsKey('BaseName')) {
                $BaseName
            } else {
                $File.BaseName
            }
            
            $Ext = $File.Extension
            $ChunkIndex = 1
            $PartLabel = ""

            Write-Verbose "Starting chunking process for: $($File.FullName)"
            Write-Verbose "Parameter Set: $($PsCmdlet.ParameterSetName)"

            # --- 2. Process based on Parameter Set ---
            switch ($PsCmdlet.ParameterSetName) {
                'ByChars' {
                    # --- Mode: By Character Count (Text-aware) ---
                    $PartLabel = "char"
                    $reader = $null
                    try {
                        $reader = [System.IO.File]::OpenText($File.FullName)
                        $buffer = [char[]]::new($CharacterCount)
                        
                        while (($charsRead = $reader.Read($buffer, 0, $CharacterCount)) -gt 0) {
                            $outPath = Join-Path $DestDir ("{0}_{1}_part{2:D4}{3}" -f $Base, $PartLabel, $ChunkIndex, $Ext)
                            Write-Verbose "Creating chunk: $outPath ($charsRead characters)"
                            
                            # Write only the characters that were read
                            [System.IO.File]::WriteAllText($outPath, ([string]::new($buffer, 0, $charsRead)), $reader.CurrentEncoding)
                            $ChunkIndex++
                        }
                    }
                    finally {
                        if ($null -ne $reader) {
                            $reader.Dispose()
                        }
                    }
                    break
                }

                'ByParts' {
                    # --- Mode: By Number of Parts (Binary) ---
                    $PartLabel = "part"
                    $totalSize = $File.Length
                    # Calculate chunk size, rounding up to ensure all bytes are included
                    $bytesPerChunk = [Math]::Ceiling($totalSize / $PartCount)
                    break
                }

                'BySize' {
                    # --- Mode: By Byte Size (Binary) ---
                    $PartLabel = "size"
                    $bytesPerChunk = $ChunkSize
                    break
                }
            }

            # --- 3. Shared Logic for Binary Splits (BySize and ByParts) ---
            if ($bytesPerChunk -gt 0) {
                $inStream = $null
                try {
                    $inStream = [System.IO.File]::OpenRead($File.FullName)
                    $buffer = [byte[]]::new($bytesPerChunk)

                    while (($bytesRead = $inStream.Read($buffer, 0, $bytesPerChunk)) -gt 0) {
                        $outPath = Join-Path $DestDir ("{0}_{1}_part{2:D4}{3}" -f $Base, $PartLabel, $ChunkIndex, $Ext)
                        Write-Verbose "Creating chunk: $outPath ($bytesRead bytes)"
                        
                        $outStream = $null
                        try {
                            $outStream = [System.IO.File]::OpenWrite($outPath)
                            # Write only the bytes that were read
                            $outStream.Write($buffer, 0, $bytesRead)
                        }
                        finally {
                            if ($null -ne $outStream) {
                                $outStream.Dispose()
                            }
                        }
                        $ChunkIndex++
                    }
                }
                finally {
                    if ($null -ne $inStream) {
                        $inStream.Dispose()
                    }
                }
            }

            Write-Output "Successfully split '$($File.Name)' into $($ChunkIndex - 1) parts in '$DestDir'."

        }
        catch {
            Write-Error $_.Exception.Message
        }
    }
}