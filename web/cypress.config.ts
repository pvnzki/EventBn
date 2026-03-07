import { defineConfig } from "cypress";

export default defineConfig({
  // Use Mochawesome for reporting
  reporter: "mochawesome",
  reporterOptions: {
    reportDir: "cypress/reports/mochawesome",
    overwrite: false,
    html: false, // generate JSON files only during run
    json: true,
    quiet: true,
  },
  e2e: {
    // Next.js dev server runs on 5000 via package.json scripts
    baseUrl: "http://localhost:5000",
    specPattern: "cypress/e2e/**/*.cy.{js,jsx,ts,tsx}",
    supportFile: "cypress/support/e2e.ts",
    video: false,
    defaultCommandTimeout: 8000,
    viewportWidth: 1280,
    viewportHeight: 800,
    retries: {
      runMode: 1,
      openMode: 0,
    },
    setupNodeEvents(on, config) {
      // implement node event listeners here
      return config;
    },
  },
});
