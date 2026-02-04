<#
    DiskIO.ps1
    Purpose: Per-process disk I/O collector with summaries and optional SQL.
    Authors: Karl Spurling & Copilot
#>

param(
    [int]$IntervalSeconds,
    [int]$IntervalMinutes,

    [int]$RunSeconds,
    [int]$RunMinutes,
    [int]$RunHours,
    [switch]$RunForever,

    [switch]$EnableSQL,
    [switch]$DisableSQL,

    [switch]$EnableSummaries,
    [switch]$DisableSummaries,

    [switch]$EnableRotation,
    [switch]$DisableRotation
)

# -------------------------------
# Load config
# -------------------------------

$Config = . (Join-Path $PSScriptRoot "DiskIO.Config.ps1")

# -------------------------------
# Resolve interval
# -------------------------------

if ($IntervalSeconds) {
    $Interval = $IntervalSeconds
}
elseif ($IntervalMinutes) {
    $Interval = $IntervalMinutes * 60
}
else {
    $Interval = $Config.IntervalMinutes * 60
}

# -------------------------------
# Resolve duration
# -------------------------------

$EndTime = $null

if (-not $RunForever) {
    $totalSeconds = $null

    if ($RunSeconds) {
        $totalSeconds = $RunSeconds
    }
    elseif ($RunMinutes) {
        $totalSeconds = $RunMinutes * 60
    }
    elseif ($RunHours) {
        $totalSeconds = $RunHours * 3600
    }

    if ($totalSeconds) {
        $EndTime = (Get-Date).AddSeconds($totalSeconds)
    }
}

# -------------------------------
# Feature toggles
# -------------------------------

$UseSQL        = $Config.EnableSQL
$UseSummaries  = $Config.Features.Summaries
$UseRotation   = $Config.Features.Rotation

if ($EnableSQL)       { $UseSQL       = $true }
if ($DisableSQL)      { $UseSQL       = $false }
if ($EnableSummaries) { $UseSummaries = $true }
if ($DisableSummaries){ $UseSummaries = $false }
if ($EnableRotation)  { $UseRotation  = $true }
if ($DisableRotation) { $UseRotation  = $false }

# -------------------------------
# Paths & folders
# -------------------------------

$RootFolder   = $Config.RootFolder
$LogsRoot     = Join-Path $RootFolder "logs"
$RawFolder    = Join-Path $LogsRoot "raw"
$HourlyFolder = Join-Path $LogsRoot "hourly"
$DailyFolder  = Join-Path $LogsRoot "daily"
$ErrorFolder  = Join-Path $LogsRoot "errors"

foreach ($folder in @($RootFolder, $LogsRoot, $RawFolder, $HourlyFolder, $DailyFolder, $ErrorFolder)) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
    }
}

$ErrorLog = Join-Path $ErrorFolder "errors.log"

# -------------------------------
# Helpers
# -------------------------------

function Write-ErrorLog {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp`t$Message" | Out-File -FilePath $ErrorLog -Append -Encoding UTF8
}

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

function Write-RawSnapshot {
    param(
        [Parameter(Mandatory=$true)]$Snapshot
    )

    $timestamp = Get-Date
    $fileName  = $timestamp.ToString("yyyy-MM-dd") + ".csv"
    $rawFile   = Join-Path $RawFolder $fileName

    foreach ($p in $Snapshot) {
        "$($timestamp.ToString('yyyy-MM-dd HH:mm:ss')),$($p.Id),$($p.ProcessName),$($p.Path),$($p.ReadBytes),$($p.WriteBytes)" |
            Out-File -FilePath $rawFile -Append -Encoding UTF8
    }
}

# -------------------------------
# Load modules
# -------------------------------

. (Join-Path $PSScriptRoot "DiskIO.Summary.ps1")
. (Join-Path $PSScriptRoot "DiskIO.Rotate.ps1")
. (Join-Path $PSScriptRoot "DiskIO.SQL.ps1")

# -------------------------------
# Main loop
# -------------------------------

Write-Host "DiskIO starting. Interval: $Interval seconds. SQL: $UseSQL. Summaries: $UseSummaries. Rotation: $UseRotation."

while ($true) {
    if ($EndTime -and (Get-Date) -ge $EndTime) {
        Write-Host "DiskIO reached end time, exiting."
        break
    }

    try {
        $snapshot = Get-DiskIOSnapshot

        if ($snapshot) {
            Write-RawSnapshot -Snapshot $snapshot

            if ($UseSummaries) {
                Update-HourlySummary -Snapshot $snapshot -Config $Config -HourlyFolder $HourlyFolder
                Update-DailySummary  -Snapshot $snapshot -Config $Config -DailyFolder  $DailyFolder
            }

            if ($UseRotation) {
                Rotate-Logs -Config $Config -RawFolder $RawFolder -HourlyFolder $HourlyFolder -DailyFolder $DailyFolder
            }

            if ($UseSQL) {
                Write-SQLSnapshot -Snapshot $snapshot -Config $Config
            }
        }
    }
    catch {
        Write-ErrorLog "Loop error: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds $Interval
}
