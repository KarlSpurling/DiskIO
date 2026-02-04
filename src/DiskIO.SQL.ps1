# DiskIO.SQL.ps1
# Optional SQL ingestion

function Write-SQLSnapshot {
    param(
        [Parameter(Mandatory=$true)]$Snapshot,
        [Parameter(Mandatory=$true)]$Config
    )

    if (-not $Config.EnableSQL) {
        return
    }

    $connectionString = $Config.SQLConnection

    # Placeholder: implement real SQL write later.
    return
}
