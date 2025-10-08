/// <reference types="cypress" />

describe('Navigation flow - Organizer', () => {
  beforeEach(() => {
    // Stub successful login and store user in localStorage
    cy.window().then((win) => {
      const user = { role: 'ORGANIZER', organization_id: 1 };
      win.localStorage.setItem('user', JSON.stringify(user));
      win.localStorage.setItem('token', 'fake-token');
    });
  });

  it('navigates to organizer dashboard and renders key widgets', () => {
    // Intercept analytics and events network calls to avoid backend dependency
    cy.intercept('GET', 'http://localhost:3000/api/analytics/organizer/*/dashboard/overview', {
      statusCode: 200,
      body: { success: true, data: { totalRevenue: 0, ticketsSold: 0, conversionRate: 0, pageViews: 0, totalPayments: 0, totalEvents: 0 } },
    }).as('overview');
    cy.intercept('GET', 'http://localhost:3000/api/analytics/organizer/*/dashboard/revenue-trend', {
      statusCode: 200,
      body: { success: true, data: [] },
    }).as('trend');
    cy.intercept('GET', 'http://localhost:3000/api/events', {
      statusCode: 200,
      body: { success: true, data: [] },
    }).as('events');

    cy.visit('/organizer/dashboard');
    cy.contains(/organizer dashboard/i).should('be.visible');
    cy.contains(/total events/i).should('be.visible');
    cy.contains(/tickets sold/i).should('be.visible');
  });
});
