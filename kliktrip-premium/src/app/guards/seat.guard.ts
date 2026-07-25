import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { BookingService } from '../services/booking.service';

export const seatGuard: CanActivateFn = (route, state) => {
  const bookingService = inject(BookingService);
  const router = inject(Router);

  if (bookingService.schedule) {
    return true;
  }

  return router.createUrlTree(['/']);
};
