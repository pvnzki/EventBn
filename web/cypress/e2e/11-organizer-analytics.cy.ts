/// <reference types="cypress" />

describe('Organizer - Analytics page', () => {
  beforeEach(() => {
    cy.setOrganizerUser();
    cy.stubOrganizerApis();
  });

  it('renders analytics cards and charts', () => {
    cy.visit('/organizer/analytics');
  cy.wait(['@overview']);

    cy.contains(/total events/i).should('be.visible');
    cy.contains(/tickets sold/i).should('be.visible');
    cy.contains(/total revenue/i).should('be.visible');
  });
});
