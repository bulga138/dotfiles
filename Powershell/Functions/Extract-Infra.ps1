function Get-SystemInformation {
    <#
    .SYNOPSIS
        Gathers comprehensive system information including CPU, GPU, memory, and storage details.

    .DESCRIPTION
        The Get-SystemInformation function collects detailed hardware information from the local system
        using CIM/WMI queries. It displays information about the computer name, CPU specifications,
        GPU details, total memory, and storage devices in a formatted output.

    .PARAMETER None
        This function does not accept any parameters.

    .INPUTS
        None. This function does not accept input from the pipeline.

    .OUTPUTS
        None. The function writes formatted system information to the console.

    .EXAMPLE
        PS C:\> Get-SystemInformation

        This command displays comprehensive system information including CPU, GPU, memory, and storage details.

    .NOTES
        - Requires administrative privileges for some detailed hardware information
        - Uses CIM instances which are compatible with both WMI and CIM
    #>
    param ()

    Write-Host "=== SYSTEM INFORMATION ===" -ForegroundColor Green
    Write-Host "Computer Name: $($env:COMPUTERNAME)"
    Write-Host ""

    Write-Host "=== CPU ===" -ForegroundColor Yellow
    Get-CimInstance -ClassName Win32_Processor | ForEach-Object {
        Write-Host "Name: $($_.Name)"
        Write-Host "Cores: $($_.NumberOfCores)"
        Write-Host "Threads: $($_.NumberOfLogicalProcessors)"
        Write-Host "Max Speed: $($_.MaxClockSpeed) MHz"
    }

    Write-Host ""
    Write-Host "=== GPU ===" -ForegroundColor Yellow
    Get-CimInstance -ClassName Win32_VideoController | ForEach-Object {
        Write-Host "Name: $($_.Name)"
        Write-Host "RAM: $([math]::Round($_.AdapterRAM/1GB, 2)) GB"
    }

    Write-Host ""
    Write-Host "=== MEMORY ===" -ForegroundColor Yellow
    $TotalRAM = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
    Write-Host "Total RAM: $([math]::Round($TotalRAM/1GB, 2)) GB"

    Write-Host ""
    Write-Host "=== STORAGE ===" -ForegroundColor Yellow
    Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        $size = [math]::Round($_.Size/1GB, 2)
        $free = [math]::Round($_.FreeSpace/1GB, 2)
        Write-Host "$($_.DeviceID): $size GB (Free: $free GB)"
    }
}
