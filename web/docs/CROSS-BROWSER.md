# Cross-browser and Safari coverage

This project uses Cypress for E2E, with options to run against local browsers and BrowserStack for a wider matrix. Safari is not directly supported by Cypress; use BrowserStack (real Safari) or Playwright/WebKit for WebKit engine coverage.

## Local browsers (Chrome/Edge/Firefox)

- Open runner and choose browser:
  ```powershell
  npm run test:ui:open
  ```
- Or run headless in a specific browser:
  ```powershell
  npx cypress run --e2e --browser chrome
  npx cypress run --e2e --browser edge
  npx cypress run --e2e --browser firefox
  ```

## BrowserStack setup (recommended for cross-OS and Safari)

1. Install CLI (already listed in devDependencies):
   - `@browserstack/cypress-cli`
2. Set environment variables:
   - `BROWSERSTACK_USERNAME`
   - `BROWSERSTACK_ACCESS_KEY`
3. Optional: enable local testing (test apps on `http://localhost:3001`):
   - `BROWSERSTACK_LOCAL=1`
   - `BROWSERSTACK_LOCAL_IDENTIFIER=eventbn-local-<anything>`
4. browserstack.json is pre-configured at `web/browserstack.json` with a Windows/OS X matrix.

### Run on BrowserStack

- Synchronous run (waits for completion):
  ```powershell
  npm run bs:run
  ```
- With BrowserStack Local:
  ```powershell
  npm run bs:local
  ```

Notes:

- The config uses your `cypress.config.ts` and runs all specs under `cypress/e2e/**/*.cy.ts`.
- Adjust browsers, OS versions, parallels, or spec globs in `browserstack.json`.

## Safari coverage options

- BrowserStack real Safari: Add Safari to the `browsers` array in `browserstack.json`, e.g.:
  ```json
  { "browser": "safari", "os": "OS X", "os_version": "Sonoma" }
  ```
- Playwright WebKit: If you need local WebKit coverage, add a minimal Playwright suite for critical paths:
  - Install: `@playwright/test`
  - Run: `npx playwright test --project=webkit`
  - Keep this focused on smoke-level coverage (landing, login form renders, key nav).

## CI integration

- Add a GitHub Actions workflow that runs `npm ci`, `npm run test:ui:dev` for a quick check (Electron/Chrome), and a parallel job that uses `npm run bs:run` for cross-browser.
- Mask BrowserStack secrets using repo secrets.
