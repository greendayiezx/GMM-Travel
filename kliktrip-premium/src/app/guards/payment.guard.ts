import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { BookingService } from '../services/booking.service';

export const paymentGuard: CanActivateFn = (route, state) => {
  const bookingService = inject(BookingService);
  const router = inject(Router);

  // B. JIKA DATA PENUMPANG BELUM LENGKAP -> REDIRECT KE LANGKAH SEBELUMNYA
  const passenger = bookingService.passenger;
  const isPassengerComplete = passenger && passenger.fullName.trim() && passenger.phone.trim();

  if (!bookingService.selectedSeat || !isPassengerComplete) {
    return router.createUrlTree(['/booking/seat']);
  }

  // C. JIKA SEMUA VALID -> IZINKAN AKSES HALAMAN PAYMENT
  return true;
};
