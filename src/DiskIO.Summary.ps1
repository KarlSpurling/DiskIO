# DiskIO.Summary.ps1
# Hourly and daily summaries

function Update-HourlySummary {
    param(
        [Parameter(Mandatory=$true)]$Snapshot,
        [Parameter(Mandatory=$true)]$Config,
        [Parameter(Mandatory=$true)][string]$HourlyFolder
    )

    $now      = Get-Date
    $fileName = $now.ToString("yyyy-MM-dd-HH") + ".csv"
    $filePath = Join-Path $HourlyFolder $fileName

    $grouped = $Snapshot | Group-Object ProcessName | ForEach-Object {
        [PSCustomObject]@{
            Timestamp   = $now.ToString("yyyy-MM-dd HH:00:00")
            ProcessName = $_.Name
            TotalRead   = ($_.Group | Measure-Object ReadBytes  -Sum).Sum
            TotalWrite  = ($_.Group | Measure-Object WriteBytes -Sum).Sum
            Count       = $_.Count
        }
    }

    foreach ($row in $grouped) {
        "$($row.Timestamp),$($row.ProcessName),$($row.TotalRead),$($row.TotalWrite),$($row.Count)" |
            Out-File -FilePath $filePath -Append -Encoding UTF8
    }
}

function Update-DailySummary {
    param(
        [Parameter(Mandatory=$true)]$Snapshot,
        [Parameter(Mandatory=$true)]$Config,
        [Parameter(Mandatory=$true)][string]$DailyFolder
    )

    $now      = Get-Date
    $fileName = $now.ToString("yyyy-MM-dd") + ".csv"
    $filePath = Join-Path $DailyFolder $fileName

    $grouped = $Snapshot | Group-Object ProcessName | ForEach-Object {
        [PSCustomObject]@{
            Date        = $now.ToString("yyyy-MM-dd")
            ProcessName = $_.Name
            TotalRead   = ($_.Group | Measure-Object ReadBytes  -Sum).Sum
            TotalWrite  = ($_.Group | Measure-Object WriteBytes -Sum).Sum
            Count       = $_.Count
        }
    }

    foreach ($row in $grouped) {
        "$($row.Date),$($row.ProcessName),$($row.TotalRead),$($row.TotalWrite),$($row.Count)" |
            Out-File -FilePath $filePath -Append -Encoding UTF8
    }
}
