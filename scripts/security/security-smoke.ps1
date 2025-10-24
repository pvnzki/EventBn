param(
  [Parameter(Mandatory = $false)] [string]$TargetUrl = "http://localhost:3000",
  [Parameter(Mandatory = $false)] [string]$OutDir = $null
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Section($Title) {
  $line = "`n==== $Title ===="
  $summary = Join-Path $OutDir 'summary.txt'
  if (Test-Path $summary) {
    Add-Content -Path $summary -Value $line -Encoding UTF8
  } else {
    Set-Content -Path $summary -Value $line -Encoding UTF8
  }
}

function Test-Command($name) {
  $cmd = Get-Command $name -ErrorAction SilentlyContinue
  return ($null -ne $cmd)
}

try {
  $uri = [Uri]$TargetUrl
} catch {
  Write-Error ("Invalid TargetUrl: {0}" -f $TargetUrl)
  exit 1
}
$hostName = $uri.Host
$port = if ($uri.IsDefaultPort) { if ($uri.Scheme -eq 'https') { 443 } else { 80 } } else { $uri.Port }

$workspaceRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
if (-not $OutDir) {
  $OutDir = Join-Path $workspaceRoot 'security-reports'
} elseif (-not [System.IO.Path]::IsPathRooted($OutDir)) {
  $OutDir = Join-Path $workspaceRoot $OutDir
}
$OutDir = [System.IO.Path]::GetFullPath($OutDir)
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

# Clean previous report files to avoid mixed encodings
$summaryPath = Join-Path $OutDir 'summary.txt'
$headersPath = Join-Path $OutDir 'headers.txt'
$tlsPath = Join-Path $OutDir 'tls.txt'
$zapLog = Join-Path $OutDir 'zap.log'
$zapHtml = Join-Path $OutDir 'zap_report.html'
$zapXml = Join-Path $OutDir 'zap_report.xml'
$zapJson = Join-Path $OutDir 'zap_report.json'
foreach ($f in @($summaryPath,$headersPath,$tlsPath,$zapLog,$zapHtml,$zapXml,$zapJson)) {
  if (Test-Path $f) { Remove-Item -Force $f -ErrorAction SilentlyContinue }
}

Write-Host "Target: $TargetUrl"
"Target: $TargetUrl" | Set-Content -Encoding ASCII $summaryPath
Write-Host ("Output Directory: {0}" -f $OutDir)
("Output Directory: {0}" -f $OutDir) | Add-Content -Encoding ASCII $summaryPath

# Preflight connectivity check
try {
  $tcpOk = $false
  try {
    $tcpOk = (Test-NetConnection -ComputerName $hostName -Port $port -WarningAction SilentlyContinue).TcpTestSucceeded
  } catch {}
  $msg = if ($tcpOk) { "Connectivity: ${hostName}:${port} is reachable" } else { "Connectivity: ${hostName}:${port} is NOT reachable" }
  Write-Host $msg
  $msg | Add-Content -Encoding ASCII $summaryPath
} catch {}

# 1) Nmap quick scan
if (Test-Command 'nmap') {
  Write-Section 'Nmap'
  try {
    $portList = if ($port -ne 443) { "$port,443" } else { "$port" }
    $nmapOut = Join-Path $OutDir 'nmap.txt'
    nmap -Pn -sS -sV -T4 -p $portList -oN $nmapOut $hostName | Out-Null
    Write-Host ("Nmap saved: {0}" -f $nmapOut)
    Add-Content -Path (Join-Path $OutDir 'summary.txt') -Value ("Saved: {0}" -f $nmapOut) -Encoding ASCII
  } catch {
    Write-Warning "Nmap failed: $_"
  }
} else {
  Write-Warning "nmap not found. Install: winget install -e --id Insecure.Nmap"
}

# 2) HTTP Security Headers
Write-Section 'HTTP Security Headers'
try {
  $headers = @{}
  $usedHttpClient = $false
  try {
    Add-Type -AssemblyName System.Net.Http -ErrorAction Stop
    $handler = New-Object System.Net.Http.HttpClientHandler
    $client = New-Object System.Net.Http.HttpClient($handler)
    $client.DefaultRequestHeaders.Add('User-Agent','security-smoke')
    $resp = $client.GetAsync($TargetUrl).GetAwaiter().GetResult()
    foreach ($h in $resp.Headers) { $headers[$h.Key] = ($h.Value -join ', ') }
    if ($resp.Content) { foreach ($h in $resp.Content.Headers) { $headers[$h.Key] = ($h.Value -join ', ') } }
    $client.Dispose()
    $usedHttpClient = $true
  } catch {
    # Fallback for Windows PowerShell 5.1 without System.Net.Http types
    $iwr = Invoke-WebRequest -Uri $TargetUrl -UseBasicParsing -Headers @{ 'User-Agent' = 'security-smoke' }
    foreach ($k in $iwr.Headers.Keys) { $headers[$k] = $iwr.Headers[$k] }
  }

  $required = @(
    'Strict-Transport-Security',
    'Content-Security-Policy',
    'X-Content-Type-Options',
    'X-Frame-Options',
    'Referrer-Policy',
    'Permissions-Policy'
  )
  $lines = @()
  foreach ($h in $required) {
    $val = if ($headers.ContainsKey($h)) { $headers[$h] } else { '<missing>' }
    $lines += ("{0}: {1}" -f $h, $val)
  }
  $lines | Set-Content -Encoding UTF8 (Join-Path $OutDir 'headers.txt')
  Write-Host ("Headers saved: {0}" -f (Join-Path $OutDir 'headers.txt'))
  Add-Content -Path (Join-Path $OutDir 'summary.txt') -Value ("Saved: {0}" -f (Join-Path $OutDir 'headers.txt')) -Encoding ASCII
} catch {
  Write-Warning ("Failed to fetch {0} for header check: {1}" -f $TargetUrl, $_)
  "Failed to fetch headers for $TargetUrl" | Set-Content -Encoding UTF8 (Join-Path $OutDir 'headers.txt')
}

# 3) TLS protocol/cipher
Write-Section 'TLS'
if ($uri.Scheme -eq 'https') {
  try {
    $tcp = New-Object System.Net.Sockets.TcpClient($hostName, $port)
    $ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, { $true })
    $ssl.AuthenticateAsClient($hostName)
    "Negotiated TLS: $($ssl.SslProtocol)" | Set-Content -Encoding UTF8 (Join-Path $OutDir 'tls.txt')
    $ssl.Close(); $tcp.Close()
    Write-Host ("TLS saved: {0}" -f (Join-Path $OutDir 'tls.txt'))
    Add-Content -Path (Join-Path $OutDir 'summary.txt') -Value ("Saved: {0}" -f (Join-Path $OutDir 'tls.txt')) -Encoding ASCII
  } catch { Write-Warning "TLS check failed: $_" }
} else {
  "Target is not HTTPS. Ensure production enforces HTTPS and HSTS." | Set-Content -Encoding UTF8 (Join-Path $OutDir 'tls.txt')
  Write-Host ("TLS saved: {0}" -f (Join-Path $OutDir 'tls.txt'))
}

# 4) OWASP ZAP Baseline
Write-Section 'OWASP ZAP Baseline'
$zapTarget = $TargetUrl
if (Test-Command 'docker') {
  if ($uri.Host -in @('localhost','127.0.0.1')) {
    $zapTarget = $TargetUrl -replace 'localhost','host.docker.internal' -replace '127\.0\.0\.1','host.docker.internal'
  }
  try {
    Write-Output "Running ZAP Docker baseline against $zapTarget ..."
    $images = @('zaproxy/zap-stable','owasp/zap2docker-stable','zaproxy/zap-weekly')
    $pulled = $false
    foreach ($img in $images) {
      try { docker pull $img | Out-Null; $selectedImage = $img; $pulled = $true; break } catch {}
    }
    if (-not $pulled) { throw "Failed to pull any ZAP image: $($images -join ', ')" }
    # Use --mount to handle Windows paths with spaces
    $args = @('run','--rm','-t','--mount', "type=bind,source=$OutDir,target=/zap/wrk", $selectedImage, 'zap-baseline.py',
      '-t', "$zapTarget", '-m', '5', '-r', 'zap_report.html', '-x', 'zap_report.xml', '-J', 'zap_report.json', '-d')
    & docker @args 2>&1 | Tee-Object -FilePath $zapLog | Out-Null
    Write-Host ("ZAP report saved: {0}" -f $zapHtml)
    Add-Content -Path (Join-Path $OutDir 'summary.txt') -Value ("Saved: {0}" -f $zapHtml) -Encoding ASCII
  } catch {
    Write-Warning "ZAP Docker baseline failed: $_"
  }
} elseif (Test-Command 'zap.bat') {
  try {
    Write-Output "Running ZAP Quick Scan (desktop) against $TargetUrl ..."
    $quickOut = Join-Path $OutDir 'zap_quick_report.html'
    & zap.bat -cmd -quickurl "$TargetUrl" -quickprogress -quickout $quickOut 2>&1 |
      Tee-Object -FilePath (Join-Path $OutDir 'zap.log') | Out-Null
    Write-Host ("ZAP quick report saved: {0}" -f $quickOut)
    Add-Content -Path (Join-Path $OutDir 'summary.txt') -Value ("Saved: {0}" -f $quickOut) -Encoding ASCII
  } catch { Write-Warning "ZAP desktop quick scan failed: $_" }
} else {
  Write-Warning "Neither Docker nor ZAP found. Install: winget install -e --id OWASP.ZAP or install Docker Desktop."
}

Write-Section 'Done'
("Reports folder: {0}" -f $OutDir) | Add-Content -Path (Join-Path $OutDir 'summary.txt') -Encoding ASCII
