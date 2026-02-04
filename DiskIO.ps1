<#
    DiskIO.ps1
    Purpose: Collect per‑process disk I/O metrics on Windows 10/11 VMs.
    Authors: Karl Spurling & Copilot
    Notes:
        - This is a starter stub.
        - Logging, rotation, summaries, and error trapping will be added next.
#>

# -------------------------------
# Configuration
# -------------------------------

$RootFolder = "C:\KarlSpurlingUtils"
$LogRoot    = Join-Path $RootFolder "DiskIO"

$RawLog     = Join-Path $LogRoot "raw.csv"
$ErrorLog   = Join-Path $LogRoot "errors.log"

# -------------------------------
# Ensure folder structure exists
# -------------------------------

foreach ($folder in @($RootFolder, $LogRoot)) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
    }
}

# -------------------------------
# Helper: Write error safely
# -------------------------------
function Write-ErrorLog {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp`t$Message" | Out-File -FilePath $ErrorLog -Append -Encoding UTF8
}

# -------------------------------
# Collect Disk I/O Snapshot
# -------------------------------
function Get-DiskIOSnapshot {
    try {
        $processes = Get-Process | Select-Object `
            Id,
            ProcessName,
            Path,
            @{Name="ReadBytes";Expression={$_.IOReadBytes}},
            @{Name="WriteBytes";Expression={$_.IOWriteBytes}}

        return $processes
    }
    catch {
        Write-ErrorLog "Snapshot failed: $($_.Exception.Message)"
        return $null
    }
}

# -------------------------------
# Main Execution
# -------------------------------

$snapshot = Get-DiskIOSnapshot

if ($snapshot) {
    foreach ($p in $snapshot) {
        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),$($p.Id),$($p.ProcessName),$($p.Path),$($p.ReadBytes),$($p.WriteBytes)" |
            Out-File -FilePath $RawLog -Append -Encoding UTF8
    }
}
