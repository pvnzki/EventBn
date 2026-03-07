/// <reference types="cypress" />

describe('Responsive sidebar behavior', () => {
  beforeEach(() => {
    // set organizer user so sidebar renders
    cy.window().then((win) => {
      win.localStorage.setItem('user', JSON.stringify({ role: 'ORGANIZER', name: 'Org', organization_id: 1 }));
    });
    // stub network calls used by dashboard
    cy.intercept('GET', '**/api/analytics/organizer/*/dashboard/overview', {
      statusCode: 200,
      body: { success: true, data: { totalRevenue: 0, ticketsSold: 0, conversionRate: 0, pageViews: 0, totalPayments: 0, totalEvents: 0 } },
    }).as('overview');
    cy.intercept('GET', '**/api/analytics/organizer/*/dashboard/revenue-trend', {
      statusCode: 200,
      body: { success: true, data: [] },
    }).as('trend');
    cy.intercept('GET', '**/api/events', {
      statusCode: 200,
      body: { success: true, data: [] },
    }).as('events');
  });

  it('sidebar hidden on mobile, visible on desktop', () => {
    cy.viewport('iphone-6');
    cy.visit('/organizer/dashboard');
    // Mobile menu button visible
    cy.get('button.fixed.top-4.left-4.lg\\:hidden').should('be.visible');
    // Sidebar off-canvas initially
    cy.get('div.fixed.inset-y-0.left-0').should('have.class', '-translate-x-full');
    // Open menu and verify sidebar slides in
    cy.get('button.fixed.top-4.left-4.lg\\:hidden').click();
    cy.get('div.fixed.inset-y-0.left-0').should('have.class', 'translate-x-0');

    // Desktop
    cy.viewport(1280, 800);
    // Toggle button hidden on desktop
    cy.get('button.fixed.top-4.left-4.lg\\:hidden').should('not.be.visible');
    // Sidebar has desktop-visible class
    cy.get('div.fixed.inset-y-0.left-0')
      .should('have.class', 'lg:translate-x-0')
      .and('be.visible');
  });
});
