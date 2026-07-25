import { inject } from '@angular/core';
import { CanActivateFn, CanDeactivateFn, Router } from '@angular/router';
import { FlightBookingService } from '../services/flight-booking.service';
import { FlightWaitingComponent } from '../components/flight-waiting/flight-waiting.component';

export const flightAlreadyPaidGuard: CanActivateFn = () => {
  const service = inject(FlightBookingService);
  const router  = inject(Router);
  const code    = service.bookingCode;

  if (code) {
    try {
      const existing = localStorage.getItem('gmm_flight_bookings');
      if (existing) {
        const bookings = JSON.parse(existing);
        if (bookings[code] && ['PAID', 'PROCESSING_ISSUANCE', 'ISSUED'].includes(bookings[code].status)) {
          router.navigate(['/flights/waiting', code], { replaceUrl: true });
          return false;
        }
      }
    } catch (e) { /* ignore */ }
  }

  return true;
};

export const flightWaitingLockGuard: CanDeactivateFn<FlightWaitingComponent> = (component) => {
  return component.isNavigatingAway;
};
