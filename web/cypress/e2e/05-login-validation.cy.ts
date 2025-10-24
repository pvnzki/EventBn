/// <reference types="cypress" />

describe('Login form validation', () => {
  beforeEach(() => {
    cy.visit('/login');
  });

  it('requires email and password', () => {
    cy.contains('button', /sign in/i).click();
    // built-in browser constraint validation messages are not easily assertable cross-browsers
    // Instead verify the inputs are still invalid and focused cycles
    cy.get('#email:invalid').should('exist');
    cy.get('#password:invalid').should('exist');
  });

  it('validates email format', () => {
    cy.get('#email').type('not-an-email');
    cy.get('#password').type('somepassword');
    cy.contains('button', /sign in/i).click();
    cy.get('#email:invalid').should('exist');
  });

  it('shows loading state and prevents double submit', () => {
    // stub login to delay
    cy.intercept('POST', '**/api/auth/login', (req) => {
      return new Promise((resolve) => setTimeout(() => resolve(req.reply({ statusCode: 401, body: { success: false, message: 'Login failed' } })), 500));
    }).as('login');

    cy.get('#email').type('user@example.com');
    cy.get('#password').type('password');
    cy.contains('button', /sign in/i).click();

    // Button changes text and becomes disabled during in-flight request
    cy.contains('button', /signing in/i).should('exist').and('be.disabled');
    cy.wait('@login');
  });
});
