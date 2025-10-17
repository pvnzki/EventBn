/// <reference types="cypress" />
describe('UI elements on Login page', () => {
  it('renders login form controls and handles validation states', () => {
    cy.visit('/'); // redirects to /login
    cy.url().should('include', '/login');

  // Verify title text and labels
  cy.contains(/sign in/i).should('be.visible');
  cy.get('label[for="email"]').should('exist').and('be.visible');
  cy.get('#email').should('exist').and('be.visible');
  cy.get('label[for="password"]').should('exist').and('be.visible');
  cy.get('#password').should('exist').and('be.visible');

    // Button exists and is enabled
  cy.contains('button', /sign in/i).should('be.visible').and('not.be.disabled');

    // Stub backend login to simulate successful ORGANIZER auth
  cy.intercept('POST', '**/api/auth/login', {
    statusCode: 200,
    body: {
      success: true,
      token: 'test-token',
      data: { role: 'ORGANIZER', name: 'Organizer Test', email: 'organizer@example.com' }
    }
  }).as('login');

    // Submitting valid credentials shows loading state then redirects to organizer dashboard
  cy.get('#email').clear().type('organizer@example.com');
  cy.get('#password').clear().type('any-password');
  cy.contains('button', /sign in/i).click();
  // Button changes to "Signing in..." and becomes disabled during submission
  cy.contains('button', /signing in/i).should('exist').and('be.disabled');
  cy.wait('@login');
  // After simulated auth, user is redirected to organizer dashboard
  cy.url({ timeout: 10000 }).should('include', '/organizer/dashboard');
  });
});
