import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { FlightBookingService } from '../services/flight-booking.service';

export const flightTicketGuard: CanActivateFn = (route) => {
  const service = inject(FlightBookingService);
  const router  = inject(Router);
  const code    = route.paramMap.get('code') ?? '';

  if (!code) {
    router.navigate(['/']);
    return false;
  }

  // Coba muat dari state service atau localStorage
  if (service.bookingCode === code) return true;
  if (service.loadFromStorage(code)) return true;

  // Izinkan akses — komponen akan poll status dari API
  return true;
};
