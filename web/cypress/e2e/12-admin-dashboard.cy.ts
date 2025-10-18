/// <reference types="cypress" />

describe('Admin - Dashboard smoke', () => {
  beforeEach(() => {
    cy.window().then((win) => {
      win.localStorage.setItem('user', JSON.stringify({ role: 'ADMIN', name: 'Ada Admin', user_id: 1 }));
      win.localStorage.setItem('token', 'fake-token');
    });
    // Admin pages likely call different endpoints; this spec asserts basic render
  });

  it('loads admin dashboard shell', () => {
    cy.visit('/admin/dashboard');
    cy.contains(/dashboard/i).should('be.visible');
    // Sidebar visible on desktop
    cy.get('div.fixed.inset-y-0.left-0').should('be.visible');
  });
});
