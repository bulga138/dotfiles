function Start-Venv {
    param(
        [string]$Path = ".\venv\Scripts\Activate.ps1",
        [switch]$Force
    )
    
    $venvDir = Split-Path (Split-Path $Path -Parent) -Parent
    
    # Check if venv exists or if force creation is requested
    if (Test-Path $Path) {
        Write-Host "Activating virtual environment..." -ForegroundColor Green
        & $Path
    } else {
        Write-Host "Virtual environment not found. Creating new one..." -ForegroundColor Yellow
        
        # Create the virtual environment
        try {
            python -m venv $venvDir
            Write-Host "Virtual environment created successfully!" -ForegroundColor Green
            
            # Activate it
            if (Test-Path $Path) {
                Write-Host "Activating virtual environment..." -ForegroundColor Green
                & $Path
            } else {
                Write-Host "Error: Could not find activation script after creation" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Error creating virtual environment: $_" -ForegroundColor Red
            Write-Host "Make sure Python is installed and in your PATH" -ForegroundColor Yellow
        }
    }
}
