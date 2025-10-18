# Configuration Testing (3.1.8)

This doc shows how to validate the backend across DB and reverse proxy combinations, and verify env setup.

## Quick start (Windows PowerShell)

- Ensure Docker Desktop is running.
- From `backend-api/` run:

```powershell
# Build images and run matrix
./scripts/config-tests/run-config-tests.ps1 -TestCommand "npm test --silent"
```

The script iterates:

- Postgres 13 + NGINX (port 8080)
- Postgres 13 + Apache (port 8081)
- Postgres 15 + NGINX
- Postgres 15 + Apache

It uses `.env.test` which defaults to Postgres on localhost:55432/56432.

## Manual run (one combo)

```powershell
# Postgres 13 + NGINX
$env:DATABASE_URL = "postgres://postgres:postgres@localhost:55432/eventbn_test?schema=public"
$env:DIRECT_URL = $env:DATABASE_URL

docker compose -f docker-compose.config.yml --profile app --profile pg13 --profile nginx up -d --build

# Apply DB migrations
docker compose -f docker-compose.config.yml exec -T app sh -lc "npx prisma migrate deploy"

# Run tests inside container
docker compose -f docker-compose.config.yml exec -T app sh -lc "npm test --silent"

docker compose -f docker-compose.config.yml down -v
```

## Network conditions (optional)

Enable `toxiproxy` profile and configure proxies to simulate latency/bandwidth.

```powershell
# Start with toxiproxy
docker compose -f docker-compose.config.yml --profile app --profile pg13 --profile nginx --profile toxiproxy up -d --build
# Configure via Toxiproxy API on http://localhost:8474
```

## Notes

- Prisma provider is PostgreSQL; MySQL is not supported by the current schema. The matrix here focuses on Postgres 13 vs 15.
- If you add MySQL support in Prisma, extend compose with mysql57/mysql80 and update `.env.test` per combo.
- The test suite includes `tests/env.sanity.test.js` to fail fast when env vars are missing.
