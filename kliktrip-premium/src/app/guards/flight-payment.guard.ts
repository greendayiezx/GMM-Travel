import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { FlightBookingService } from '../services/flight-booking.service';

export const flightPaymentGuard: CanActivateFn = () => {
  const service = inject(FlightBookingService);
  const router  = inject(Router);

  if (!service.selectedFlight) {
    router.navigate(['/flights/search']);
    return false;
  }

  if (service.passengers.length === 0) {
    router.navigate(['/flights/passengers']);
    return false;
  }

  return true;
};
