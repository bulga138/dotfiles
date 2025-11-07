function Start-Venv {
    <#
    .SYNOPSIS
        Activates a Python virtual environment, creating it if it does not exist.

    .DESCRIPTION
        The Start-Venv function is designed to simplify the management of Python virtual
        environments in PowerShell. It first checks for the existence of an activation
        script at the specified path.

        If the script is found, it simply activates the environment in the current
        PowerShell session.

        If the script is not found, it attempts to create a new virtual environment
        in the parent directory of the specified activation script (e.g., './venv')
        using the `python -m venv` command. Upon successful creation, it immediately
        activates the new environment.

        This function requires that 'python' is available in the system's PATH.

    .PARAMETER Path
        Specifies the full path to the virtual environment's activation script.
        The default value is `.\venv\Scripts\Activate.ps1`, which assumes a virtual
        environment named 'venv' in the current working directory.

    .PARAMETER Force
        This parameter is currently not implemented in the function's logic.
        It is defined for potential future use where it might force the recreation of
        the virtual environment. The function will currently always create the
        environment if it's missing, regardless of this switch.

    .INPUTS
        None. You cannot pipe objects to this function.

    .OUTPUTS
        None. This function activates a virtual environment in the current session
        and writes status messages to the console.

    .EXAMPLE
        PS C:\MyProject> Start-Venv

        This command looks for the activation script at `.\venv\Scripts\Activate.ps1`.
        If found, it activates the environment. If not, it creates a new virtual
        environment in a folder named 'venv' and then activates it.

    .EXAMPLE
        PS C:\MyProject> Start-Venv -Path "C:\Environments\my-app\.venv\Scripts\Activate.ps1"

        This command operates on a virtual environment located at a custom path.
        It will attempt to activate it if it exists, or create a new one at
        `C:\Environments\my-app\.venv` if it does not.

    .NOTES
        - Ensure that Python is installed and its location is added to your system's
        PATH environment variable.
        - For this function to run successfully, your PowerShell Execution Policy
        must allow running scripts. You may need to run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process`
        before using this function for the first time.
    #>
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
