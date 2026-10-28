param([switch]$Elevated)
$ErrorActionPreference = 'Stop'
$principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($Elevated) { throw 'Administrator permission was not granted.' }
    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $PSCommandPath + '" -Elevated'
    $helper = Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -PassThru -Wait
    if ($helper.ExitCode -ne 0) { throw 'Could not add the local-network firewall rule.' }
    Write-Host 'iPhone access enabled for this private network.'
    exit 0
}
$caddyPath = Join-Path $PSScriptRoot 'runtime\caddy.exe'
if (-not (Test-Path -LiteralPath $caddyPath)) { throw 'The bundled Caddy executable is missing.' }
$ruleName = 'openGym-PWA-Private-LAN'
$existing = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
if ($existing) { $existing | Remove-NetFirewallRule }
New-NetFirewallRule -Name $ruleName -DisplayName 'openGym iPhone - private local network' `
    -Direction Inbound -Action Allow -Enabled True -Profile Private `
    -Protocol TCP -LocalPort 8080,8443 -RemoteAddress LocalSubnet -Program $caddyPath | Out-Null
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'firewall-enabled.txt'), (Get-Date).ToString('o'))
