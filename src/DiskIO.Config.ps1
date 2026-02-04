# DiskIO.Config.ps1
# Global configuration for DiskIO

$Config = @{
    RootFolder      = "C:\KarlSpurlingUtils\DiskIO"
    IntervalMinutes = 15

    EnableSQL       = $false

    SQLConnection   = "Server=.;Database=DiskIO;Trusted_Connection=True;"

    Retention = @{
        RawDays    = 3
        HourlyDays = 90
        DailyDays  = 730
    }

    Features = @{
        Summaries = $true
        Rotation  = $true
    }
}

return $Config
