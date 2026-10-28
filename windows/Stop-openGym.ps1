param([switch]$Quiet)
$ErrorActionPreference = 'Stop'
$stateFile = Join-Path $PSScriptRoot 'processes.json'
if (Test-Path -LiteralPath $stateFile) {
    $records = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
    foreach ($record in $records) {
        $running = Get-Process -Id $record.Id -ErrorAction SilentlyContinue
        if ($running -and $running.Path -eq $record.Path -and
            $running.StartTime.ToUniversalTime().Ticks.ToString() -eq $record.StartTimeTicks) {
            Stop-Process -Id $running.Id
            $running.WaitForExit(5000) | Out-Null
        }
    }
    Remove-Item -LiteralPath $stateFile
}
if (-not $Quiet) { Write-Host 'openGym stopped. Your data is kept in the data folder.' }
