import { inject } from '@angular/core';
import { CanActivateFn, CanDeactivateFn, Router } from '@angular/router';
import { BookingService } from '../services/booking.service';
import { ETicketComponent } from '../components/e-ticket/e-ticket.component';

export function isBookingAlreadyPaid(bookingService: BookingService): { paid: boolean; code: string | null } {
  const code = bookingService.bookingCode;
  if (code) {
    try {
      const existing = localStorage.getItem('gmm_travel_bookings');
      if (existing) {
        const bookings = JSON.parse(existing);
        if (bookings[code] && bookings[code].status === 'PAID') {
          return { paid: true, code };
        }
      }
    } catch (e) {
      console.error('Failed to parse mock backend database in guard:', e);
    }
  }
  return { paid: false, code: null };
}

export const alreadyPaidGuard: CanActivateFn = (route, state) => {
  const bookingService = inject(BookingService);
  const router = inject(Router);

  const { paid, code } = isBookingAlreadyPaid(bookingService);
  if (paid && code) {
    // replaceUrl sangat penting di sini karena redirect ini terjadi saat user berada
    // di tengah history stack (hasil dari tombol Forward/Back). replaceUrl memastikan
    // entry lama (seat/payment) benar-benar digantikan dalam history browser.
    router.navigate(['/booking/ticket', code], { replaceUrl: true });
    return false;
  }

  return true;
};

export const ticketLockGuard: CanDeactivateFn<ETicketComponent> = (component) => {
  // Izinkan navigasi jika user sengaja klik "Kembali ke Beranda"
  if (component.isNavigatingAway) return true;

  // Blokir semua navigasi lain (tombol Back/Forward browser)
  // Angular Router akan cancel navigasi dan URL tetap di halaman tiket
  return false;
};
