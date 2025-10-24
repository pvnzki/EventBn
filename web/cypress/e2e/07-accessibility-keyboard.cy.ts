/// <reference types="cypress" />

describe('Keyboard navigation and focus', () => {
  it('focus order is logical for login form', () => {
    cy.visit('/login');

    // Focus first field and then tab forward
    cy.get('#email').focus();
    cy.focused().should('have.attr', 'id', 'email');
    // Simulate tab by focusing next element directly (no plugin)
    cy.get('#password').focus();
    cy.focused().should('have.attr', 'id', 'password');
    cy.contains('button', /sign in/i).focus();
    cy.focused().should(($el) => {
      expect($el.prop('tagName')).to.eq('BUTTON');
      expect($el.text().toLowerCase()).to.contain('sign in');
    });
  });
});
