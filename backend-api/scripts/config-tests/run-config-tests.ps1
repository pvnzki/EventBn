param(
  [string]$ComposeFile = "docker-compose.config.yml",
  [string]$TestCommand = "npm run test:db-int"
)

$ErrorActionPreference = 'Stop'

# Ensure we run in backend-api directory regardless of where the script is invoked from
$scriptDir = $PSScriptRoot
Push-Location $scriptDir\..\..

$matrix = @(
  @{ name="pg13+nginx"; dbProfile="pg13"; webProfile="nginx"; dbPort=55432; dbHostInNet="db_pg13" }
  @{ name="pg13+apache"; dbProfile="pg13"; webProfile="apache"; dbPort=55432; dbHostInNet="db_pg13" }
  @{ name="pg15+nginx"; dbProfile="pg15"; webProfile="nginx"; dbPort=56432; dbHostInNet="db_pg15" }
  @{ name="pg15+apache"; dbProfile="pg15"; webProfile="apache"; dbPort=56432; dbHostInNet="db_pg15" }
)

function Wait-Port($targetHost, $port, $timeoutSec) {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  while ($sw.Elapsed.TotalSeconds -lt $timeoutSec) {
    try {
      $r = Test-NetConnection -ComputerName $targetHost -Port $port -WarningAction SilentlyContinue
      if ($r.TcpTestSucceeded) { return $true }
    } catch {}
    Start-Sleep -Seconds 2
  }
  return $false
}

foreach ($c in $matrix) {
  Write-Host "=== Running configuration: $($c.name) ===" -ForegroundColor Cyan

  # Ensure a clean slate
  docker compose -f $ComposeFile down -v --remove-orphans | Out-Null

  # Start services for this combo
  docker compose -f $ComposeFile --profile app --profile $($c.dbProfile) --profile $($c.webProfile) up -d --build

  # Wait for DB port on localhost (since DATABASE_URL uses localhost:port)
  if (-not (Wait-Port -targetHost 'localhost' -port $c.dbPort -timeoutSec 60)) {
    throw "Database on port $($c.dbPort) did not become ready in time for $($c.name)"
  }

  # Build connection string for in-network access from the app container
  $internalDbUrl = "postgres://postgres:postgres@$($c.dbHostInNet):5432/eventbn_test?schema=public"

  # Run DB migrations and tests with DATABASE_URL overridden inside the container
  Write-Host "Running prisma migrate deploy..." -ForegroundColor Yellow
  docker compose -f $ComposeFile exec -T app sh -lc "export DATABASE_URL='$internalDbUrl'; export DIRECT_URL='$internalDbUrl'; npx prisma migrate deploy || npx prisma db push" | Write-Output

  Write-Host "Executing tests: $TestCommand" -ForegroundColor Yellow
  docker compose -f $ComposeFile exec -T app sh -lc "export DATABASE_URL='$internalDbUrl'; export DIRECT_URL='$internalDbUrl'; $TestCommand"
  if ($LASTEXITCODE -ne 0) { throw "Tests failed for $($c.name)" }
}

docker compose -f $ComposeFile down -v --remove-orphans | Out-Null
Pop-Location
Write-Host "All configuration tests passed." -ForegroundColor Green
