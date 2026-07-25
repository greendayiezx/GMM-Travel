import { Routes } from '@angular/router';
import { authGuard } from './guards/auth.guard';
import { seatGuard } from './guards/seat.guard';
import { paymentGuard } from './guards/payment.guard';
import { ticketGuard } from './guards/ticket.guard';
import { alreadyPaidGuard, ticketLockGuard } from './guards/booking.guard';
import { flightPassengerGuard } from './guards/flight-passenger.guard';
import { flightPaymentGuard } from './guards/flight-payment.guard';
import { flightTicketGuard } from './guards/flight-ticket.guard';
import { flightAlreadyPaidGuard, flightWaitingLockGuard } from './guards/flight-booking.guard';

export const routes: Routes = [

  // ── Destination detail ──────────────────────────────────────
  {
    path: 'destination/:name',
    loadComponent: () =>
      import('./components/destination-detail/destination-detail.component')
        .then(m => m.DestinationDetailComponent),
  },

  {
    path: 'booking/package-checkout',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./components/package-checkout/package-checkout.component')
        .then(m => m.PackageCheckoutComponent),
  },
  {
    path: 'booking/package-payment',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./components/package-payment/package-payment.component')
        .then(m => m.PackagePaymentComponent),
  },
  {
    path: 'booking/flights',
    loadComponent: () =>
      import('./components/flights/flights.component')
        .then(m => m.FlightsComponent),
  },
  {
    path: 'booking/seat',
    // authGuard: wajib login sebelum masuk flow booking travel.
    canActivate: [authGuard, alreadyPaidGuard, seatGuard],
    loadComponent: () =>
      import('./components/seat-selection/seat-selection.component')
        .then(m => m.SeatSelectionComponent),
  },
  {
    path: 'booking/payment',
    canActivate: [authGuard, alreadyPaidGuard, paymentGuard],
    loadComponent: () =>
      import('./components/payment/payment.component')
        .then(m => m.PaymentComponent),
  },
  {
    path: 'booking/ticket/:code',
    canActivate: [ticketGuard],
    canDeactivate: [ticketLockGuard],
    loadComponent: () =>
      import('./components/e-ticket/e-ticket.component')
        .then(m => m.ETicketComponent),
  },

  // ── Flight booking flow (prefix: flights/) ──────────────────
  {
    path: 'flights/search',
    redirectTo: '',
    pathMatch: 'full',
  },
  {
    path: 'flights/results',
    loadComponent: () =>
      import('./components/flight-results/flight-results.component')
        .then(m => m.FlightResultsComponent),
  },
  {
    path: 'flights/passengers',
    canActivate: [authGuard, flightAlreadyPaidGuard, flightPassengerGuard],
    loadComponent: () =>
      import('./components/flight-passenger-details/flight-passenger-details.component')
        .then(m => m.FlightPassengerDetailsComponent),
  },
  {
    path: 'flights/payment',
    canActivate: [authGuard, flightAlreadyPaidGuard, flightPaymentGuard],
    loadComponent: () =>
      import('./components/flight-payment/flight-payment.component')
        .then(m => m.FlightPaymentComponent),
  },
  {
    path: 'flights/waiting/:code',
    canActivate: [flightTicketGuard],
    canDeactivate: [flightWaitingLockGuard],
    loadComponent: () =>
      import('./components/flight-waiting/flight-waiting.component')
        .then(m => m.FlightWaitingComponent),
  },

  // ── Staff panel ─────────────────────────────────────────────
  {
    path: 'staff',
    loadComponent: () =>
      import('./components/staff-panel/staff-panel.component')
        .then(m => m.StaffPanelComponent),
  },

  // ── Auth pages ──────────────────────────────────────────────
  {
    path: 'login',
    loadComponent: () =>
      import('./components/login-page/login-page.component')
        .then(m => m.LoginPageComponent),
  },
  {
    path: 'register',
    loadComponent: () =>
      import('./components/register-page/register-page.component')
        .then(m => m.RegisterPageComponent),
  },
  {
    path: 'sso-callback',
    loadComponent: () =>
      import('./components/sso-callback/sso-callback.component')
        .then(m => m.SsoCallbackComponent),
  },

  // ── Fallback ────────────────────────────────────────────────
  { path: '**', redirectTo: '', pathMatch: 'full' },
];
