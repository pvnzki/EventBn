/// <reference types="cypress" />

describe('Organizer - Tickets page', () => {
  beforeEach(() => {
    cy.setOrganizerUser();
    cy.stubOrganizerApis();
  });

  it('loads ticket stats and events with stubs', () => {
    cy.visit('/organizer/tickets');
    cy.wait(['@tickets']);

    cy.contains(/tickets sold/i).should('be.visible');
    cy.contains(/active events/i).should('be.visible');
    cy.contains(/avg ticket price/i).should('be.visible');
    cy.contains(/tech summit/i).should('be.visible');
  });
});
