param([switch]$NoBrowser)
$ErrorActionPreference = 'Stop'
$installRoot = Split-Path -Parent $PSScriptRoot
$nodePath = Join-Path $PSScriptRoot 'runtime\node.exe'
$caddyPath = Join-Path $PSScriptRoot 'runtime\caddy.exe'
$distPath = Join-Path $installRoot 'frontend\dist'
$setupPath = Join-Path $PSScriptRoot 'setup'
$logsPath = Join-Path $PSScriptRoot 'logs'
$storagePath = Join-Path $PSScriptRoot 'caddy-storage'
$stateFile = Join-Path $PSScriptRoot 'processes.json'
$utf8 = New-Object Text.UTF8Encoding($false)
foreach ($required in @($nodePath, $caddyPath, (Join-Path $distPath 'index.html'))) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Required file missing: $required" }
}
& (Join-Path $PSScriptRoot 'Stop-openGym.ps1') -Quiet
$ipScript = "const os = require('os'); const all = Object.entries(os.networkInterfaces()).flatMap(([n, aa]) => aa.filter(a => a.family === 'IPv4' && !a.internal && !/vethernet|virtual|wsl/i.test(n)).map(a => a.address)); const ip = all.find(a => /^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.)/.test(a)); if (!ip) process.exit(1); process.stdout.write(ip);"
$lanIp = $null
try {
    $physicalLan = Get-NetIPConfiguration -ErrorAction Stop | Where-Object {
        $_.NetAdapter.HardwareInterface -and $_.NetAdapter.Status -eq 'Up' -and $_.IPv4DefaultGateway
    } | Select-Object -First 1
    if ($physicalLan) { $lanIp = @($physicalLan.IPv4Address.IPAddress)[0] }
} catch { }
if (-not $lanIp) { $lanIp = & $nodePath -e $ipScript }
if (-not $lanIp) { throw 'No private LAN address found. Connect this computer to your home network first.' }
$lanIp = $lanIp.Trim()
$origin = 'https://' + $lanIp + ':8443'
$setupUrl = 'http://' + $lanIp + ':8080'
foreach ($listenPort in @(30347, 8080, 8443, 23019)) {
    $probe = New-Object Net.Sockets.TcpClient
    try {
        $probe.Connect('127.0.0.1', $listenPort)
        throw "Port $listenPort is already in use. Close the other program and try again."
    } catch [Net.Sockets.SocketException] {
        # An unused port refuses the connection.
    } finally { $probe.Dispose() }
}
$forwardRoot = $installRoot.Replace('\', '/')
$forwardSetup = $setupPath.Replace('\', '/')
$forwardStorage = $storagePath.Replace('\', '/')
$caddyConfig = @"
{
    admin 127.0.0.1:23019
    persist_config off
    skip_install_trust
    auto_https disable_redirects
    storage file_system "$forwardStorage"
    pki {
        ca local {
            name "openGym on this PC"
            root_cn "openGym Local Root"
        }
    }
    servers {
        protocols h1 h2
    }
}

$origin {
    tls internal
    bind $lanIp 127.0.0.1
    encode gzip
    header {
        X-Frame-Options DENY
        X-Content-Type-Options nosniff
        Referrer-Policy same-origin
        Content-Security-Policy "frame-ancestors 'none'"
    }
    handle /api/* {
        request_body {
            max_size 48MB
        }
        reverse_proxy 127.0.0.1:30347 {
            header_up -CF-Connecting-IP
        }
    }
    handle_path /exercise-media/* {
        root * "$forwardRoot/catalogue/media"
        header Cross-Origin-Resource-Policy same-origin
        header Cache-Control "public, max-age=2592000, immutable"
        file_server
    }
    handle {
        root * "$forwardRoot/frontend/dist"
        header Cache-Control "no-cache, must-revalidate"
        file_server
    }
}

http://$($lanIp):8080, http://localhost:8080 {
    bind $lanIp 127.0.0.1
    root * "$forwardSetup"
    header Cache-Control no-store
    @certificate path /openGym-root.cer
    header @certificate Content-Type application/x-x509-ca-cert
    @iphoneProfile path /openGym-iphone.mobileconfig
    header @iphoneProfile Content-Type application/x-apple-aspen-config
    file_server
}
"@
$caddyConfigPath = Join-Path $PSScriptRoot 'Caddyfile'
[IO.File]::WriteAllText($caddyConfigPath, $caddyConfig, $utf8)
$template = [IO.File]::ReadAllText((Join-Path $setupPath 'index.template.html'))
$onboarding = $template.Replace('@@IP@@', $lanIp).Replace('@@ORIGIN@@', $origin)
[IO.File]::WriteAllText((Join-Path $setupPath 'index.html'), $onboarding, $utf8)
& $nodePath (Join-Path $PSScriptRoot 'make-qr.mjs') $setupUrl (Join-Path $setupPath 'phone-setup-qr.png')
if ($LASTEXITCODE -ne 0) { throw 'Could not generate the iPhone setup QR code.' }
$env:PORT = '30347'
$env:DATA_DIR = Join-Path $installRoot 'data'
$env:RP_ID = $lanIp
$env:ORIGIN = $origin
$env:RP_NAME = 'openGym'
$env:PASSWORD_LOGIN = '1'
$env:DEFAULT_LANG = 'zh'
$env:FIRST_USER_ADMIN = '1'
$env:ALLOW_GUEST = '0'
$env:TRUST_PROXY = '1'
$env:COACH_DISABLED = '0'
$processRecords = @()
try {
    $apiArguments = '"' + (Join-Path $PSScriptRoot 'start-api.mjs') + '"'
    $apiProcess = Start-Process -FilePath $nodePath -ArgumentList $apiArguments `
        -WorkingDirectory (Join-Path $installRoot 'api') -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $logsPath 'api.log') -RedirectStandardError (Join-Path $logsPath 'api-error.log')
    $processRecords += [pscustomobject]@{ Id=$apiProcess.Id; Path=$nodePath; StartTimeTicks=$apiProcess.StartTime.ToUniversalTime().Ticks.ToString() }
    [IO.File]::WriteAllText($stateFile, (ConvertTo-Json -InputObject $processRecords), $utf8)
    $caddyArguments = 'run --config "' + $caddyConfigPath + '" --adapter caddyfile'
    $webProcess = Start-Process -FilePath $caddyPath -ArgumentList $caddyArguments `
        -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $logsPath 'web.log') -RedirectStandardError (Join-Path $logsPath 'web-error.log')
    $processRecords += [pscustomobject]@{ Id=$webProcess.Id; Path=$caddyPath; StartTimeTicks=$webProcess.StartTime.ToUniversalTime().Ticks.ToString() }
    [IO.File]::WriteAllText($stateFile, (ConvertTo-Json -InputObject $processRecords), $utf8)
    $rootCert = Join-Path $storagePath 'pki\authorities\local\root.crt'
    $ready = $false
    for ($attempt = 0; $attempt -lt 60; $attempt++) {
        Start-Sleep -Milliseconds 250
        $apiProcess.Refresh()
        $webProcess.Refresh()
        if ($apiProcess.HasExited -or $webProcess.HasExited) { throw 'A server stopped. See windows\logs for details.' }
        if (Test-Path -LiteralPath $rootCert) {
            try {
                $config = Invoke-RestMethod -Uri 'http://127.0.0.1:30347/api/config' -TimeoutSec 2
                if ($config.password_login -eq $true) { $ready=$true; break }
            } catch { }
        }
    }
    if (-not $ready) { throw 'The servers did not become ready. See windows\logs.' }
    $fingerprint = & $nodePath (Join-Path $PSScriptRoot 'make-iphone-profile.mjs') $rootCert $setupPath
    if ($LASTEXITCODE -ne 0) { throw 'Could not export the iPhone certificate profile.' }
    $access = [ordered]@{ version='1.4.3'; ip=$lanIp; setup=$setupUrl; app=$origin; certificate_sha256=$fingerprint; started=(Get-Date).ToString('o') }
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'access.json'), ($access | ConvertTo-Json), $utf8)
    Write-Host ''
    Write-Host 'openGym 1.4.3 is running.'
    Write-Host "On your iPhone, open Safari: $setupUrl"
    Write-Host "App after certificate setup: $origin"
    Write-Host 'Keep this computer on and on the same home network.'
    Write-Host 'If the phone cannot connect, run Allow-iPhone.cmd and accept the Windows prompt.'
    if (-not $NoBrowser) { Start-Process 'http://localhost:8080' }
} catch {
    & (Join-Path $PSScriptRoot 'Stop-openGym.ps1') -Quiet
    throw
}
