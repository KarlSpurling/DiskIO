# DiskIO.Rotate.ps1
# Log rotation based on retention

function Rotate-Logs {
    param(
        [Parameter(Mandatory=$true)]$Config,
        [Parameter(Mandatory=$true)][string]$RawFolder,
        [Parameter(Mandatory=$true)][string]$HourlyFolder,
        [Parameter(Mandatory=$true)][string]$DailyFolder
    )

    $now = Get-Date

    Get-ChildItem $RawFolder -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $now.AddDays(-$Config.Retention.RawDays) } |
        Remove-Item -Force -ErrorAction SilentlyContinue

    Get-ChildItem $HourlyFolder -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $now.AddDays(-$Config.Retention.HourlyDays) } |
        Remove-Item -Force -ErrorAction SilentlyContinue

    Get-ChildItem $DailyFolder -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $now.AddDays(-$Config.Retention.DailyDays) } |
        Remove-Item -Force -ErrorAction SilentlyContinue
}
