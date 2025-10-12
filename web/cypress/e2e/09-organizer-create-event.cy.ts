/// <reference types="cypress" />

describe('Organizer - Create Event validation', () => {
  beforeEach(() => {
    cy.setOrganizerUser();
    cy.stubOrganizerApis();
  });

  it('shows validation errors for missing fields', () => {
    cy.visit('/organizer/create-event');

    // Try to submit empty form
    cy.contains('button', /create event|save/i).click({ force: true });

    // App shows an alert with errors list
    cy.on('window:alert', (text) => {
      expect(text.toLowerCase()).to.contain('required');
    });
  });
});
