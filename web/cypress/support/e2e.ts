import '@testing-library/cypress/add-commands';
import 'cypress-axe';

Cypress.on('uncaught:exception', (err) => {
  // Prevent tests from failing on non-critical client errors during app init
  console.error('Ignoring uncaught exception in test:', err);
  return false;
});

// Custom helper to inject axe and check a11y with sensible defaults
Cypress.Commands.add('checkA11yWithContext', (context?: string | HTMLElement | JQuery<HTMLElement>) => {
  cy.injectAxe();
  cy.checkA11y(context || undefined, {
    includedImpacts: ['critical', 'serious'],
  });
});

// Set organizer user + token in localStorage
Cypress.Commands.add('setOrganizerUser', () => {
  cy.fixture('organizer.json').then(({ user, token }) => {
    cy.window().then((win) => {
      win.localStorage.setItem('user', JSON.stringify(user));
      win.localStorage.setItem('token', token);
    });
  });
});

// Stub common organizer endpoints
Cypress.Commands.add('stubOrganizerApis', () => {
  // Organizer analytics & org fetches (Next app base defaults to port 3001 in hooks)
  cy.fixture('organizer.json').then(({ user }) => {
    cy.fixture('organization.json').then((org) => {
      // Organization by user
      cy.intercept(
        'GET',
        `http://localhost:3000/api/organizations/user/${user.user_id}`,
        org
      ).as('organization');
    });
  });

  cy.fixture('analytics.json').then((a) => {
    cy.intercept('GET', 'http://localhost:3000/api/analytics/organizer/*/dashboard/overview*', a.overview).as('overview');
    cy.intercept('GET', 'http://localhost:3000/api/analytics/organizer/*/dashboard/revenue-trend*', a.trend).as('trend');
    cy.intercept('GET', 'http://localhost:3000/api/analytics/organizer/*/dashboard/categories*', a.categories).as('categories');
    cy.intercept('GET', 'http://localhost:3000/api/analytics/organizer/*/dashboard/daily-attendees*', a.attendees).as('attendees');
    cy.intercept('GET', 'http://localhost:3000/api/analytics/organizer/*/dashboard/top-events*', a.topEvents).as('topEvents');
  });
  cy.fixture('events.json').then((e) => {
    cy.intercept('GET', 'http://localhost:3000/api/events', e.list).as('events');
  });
  cy.fixture('tickets.json').then((t) => {
    cy.intercept('GET', 'http://localhost:3000/api/tickets/my-events-tickets', t.myEvents).as('tickets');
  });
});

declare global {
  namespace Cypress {
    interface Chainable {
      checkA11yWithContext(context?: string | HTMLElement | JQuery<HTMLElement>): Chainable<void>;
      setOrganizerUser(): Chainable<void>;
      stubOrganizerApis(): Chainable<void>;
    }
  }
}
