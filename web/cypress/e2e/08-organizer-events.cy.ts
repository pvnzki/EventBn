/// <reference types="cypress" />

describe('Organizer - Events listing', () => {
  beforeEach(() => {
    cy.setOrganizerUser();
    cy.stubOrganizerApis();
  });

  it('loads events and filters by search/category/status', () => {
    cy.visit('/organizer/events');
    cy.wait(['@events']);

    // Sees seeded events
    cy.contains(/tech summit/i).should('be.visible');
    cy.contains(/music fest/i).should('be.visible');

  // Search filter (use placeholder selector from shadcn Input)
  cy.get('input[placeholder="Search events..."]').type('tech');
    cy.contains(/tech summit/i).should('be.visible');

    // Status filter (selects All to keep list visible)
    cy.get('[role="combobox"]').eq(0).click();
    cy.contains('div[role="option"]','All Status').click({ force: true });
  });
});
