/// <reference types="cypress" />
describe('Responsiveness - Login page', () => {
  const sizes: Array<Cypress.ViewportPreset | [number, number]> = [
    'iphone-6',
    'ipad-2',
    [1280, 800],
  ];

  sizes.forEach((size) => {
    const label = Array.isArray(size) ? `${size[0]}x${size[1]}` : size;
    it(`renders correctly at ${label}`, () => {
      if (Array.isArray(size)) {
        cy.viewport(size[0], size[1]);
      } else {
        cy.viewport(size);
      }
      cy.visit('/login');

      // Basic assertions that important elements are visible
      cy.contains(/sign in/i).should('be.visible');
      cy.get('label[for="email"]').should('be.visible');
      cy.get('#email').should('be.visible');
      cy.get('label[for="password"]').should('be.visible');
      cy.get('#password').should('be.visible');
    });
  });
});
