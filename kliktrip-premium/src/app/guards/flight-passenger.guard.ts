import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { FlightBookingService } from '../services/flight-booking.service';

export const flightPassengerGuard: CanActivateFn = () => {
  const service = inject(FlightBookingService);
  const router  = inject(Router);

  if (service.selectedFlight) return true;

  router.navigate(['/flights/search']);
  return false;
};
