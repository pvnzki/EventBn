/// <reference types="cypress" />

describe('Accessibility - Login page', () => {
  it('has no critical accessibility violations', () => {
    cy.visit('/login');
    cy.injectAxe();
    cy.checkA11y(undefined, { includedImpacts: ['critical', 'serious'] });
  });
});
