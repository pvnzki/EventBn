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

    // Error message appears on invalid credentials (no backend required)
  cy.get('#email').type('invalid@example.com');
  cy.get('#password').type('wrongpass');
  cy.contains('button', /sign in/i).click();

    // Either app shows a destructive Alert or inline error text
    cy.contains(/something went wrong|login failed/i).should('be.visible');
  });
});
