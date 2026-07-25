import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { BookingService } from '../services/booking.service';
import { Observable, of } from 'rxjs';
import { delay, map } from 'rxjs/operators';

export const ticketGuard: CanActivateFn = (route, state): Observable<boolean | import('@angular/router').UrlTree> => {
  const bookingService = inject(BookingService);
  const router = inject(Router);

  const code = route.paramMap.get('code');
  if (!code) {
    return of(router.createUrlTree(['/']));
  }

  // Simulate an async backend API check with 300ms delay
  return of(null).pipe(
    delay(300),
    map(() => {
      const isValid = bookingService.verifyAndLoadBooking(code);
      if (isValid) {
        return true;
      }
      return router.createUrlTree(['/']);
    })
  );
};
