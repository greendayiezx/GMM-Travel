import { Injectable, signal } from '@angular/core';

export interface BookingSchedule {
  id: string;
  operator: string;
  tripCode: string;
  class: 'EXECUTIVE' | 'ECONOMY';
  origin: string;
  destination: string;
  departureTime: string;
  arrivalTime: string;
  duration: string;
  pricePerPax: number;
  tag: string;
}

export interface BookingPassenger {
  fullName: string;
  phone: string;
}

export interface BookingState {
  schedule: BookingSchedule | null;
  selectedSeat: string | null;
  passenger: BookingPassenger | null;
  paymentMethod: string | null;
  bookingCode: string | null;
}

@Injectable({ providedIn: 'root' })
export class BookingService {
  private _state = signal<BookingState>({
    schedule: null,
    selectedSeat: null,
    passenger: null,
    paymentMethod: null,
    bookingCode: null,
  });

  readonly state = this._state.asReadonly();

  constructor() {
    this.prepopulateMockBackend();
  }

  get schedule()       { return this._state().schedule; }
  get selectedSeat()   { return this._state().selectedSeat; }
  get passenger()      { return this._state().passenger; }
  get paymentMethod()  { return this._state().paymentMethod; }
  get bookingCode()    { return this._state().bookingCode; }
  get totalPrice()     { return this._state().schedule?.pricePerPax ?? 0; }

  setSchedule(s: BookingSchedule) {
    this._state.update(st => ({ ...st, schedule: s, selectedSeat: null, passenger: null, paymentMethod: null, bookingCode: null }));
  }

  setSeat(seat: string) {
    this._state.update(st => ({ ...st, selectedSeat: seat }));
  }

  setPassenger(p: BookingPassenger) {
    this._state.update(st => ({ ...st, passenger: p }));
  }

  setPaymentMethod(m: string) {
    this._state.update(st => ({ ...st, paymentMethod: m }));
  }

  generateBookingCode(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const rand = Array.from({ length: 8 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
    const code = `GMM-${rand}`;
    this._state.update(st => ({ ...st, bookingCode: code }));
    return code;
  }

  reset() {
    this._state.set({ schedule: null, selectedSeat: null, passenger: null, paymentMethod: null, bookingCode: null });
  }

  saveBookingToMockBackend(booking: BookingState) {
    try {
      const existing = localStorage.getItem('gmm_travel_bookings');
      const bookings = existing ? JSON.parse(existing) : {};
      bookings[booking.bookingCode!] = {
        ...booking,
        status: 'PAID'
      };
      localStorage.setItem('gmm_travel_bookings', JSON.stringify(bookings));
    } catch (e) {
      console.error('Failed to save to mock backend', e);
    }
  }

  verifyAndLoadBooking(code: string): boolean {
    try {
      const existing = localStorage.getItem('gmm_travel_bookings');
      if (!existing) return false;
      const bookings = JSON.parse(existing);
      const booking = bookings[code];
      if (booking && booking.status === 'PAID') {
        this._state.set({
          schedule: booking.schedule,
          selectedSeat: booking.selectedSeat,
          passenger: booking.passenger,
          paymentMethod: booking.paymentMethod,
          bookingCode: booking.bookingCode
        });
        return true;
      }
    } catch (e) {
      console.error('Failed to verify booking', e);
    }
    return false;
  }

  private prepopulateMockBackend() {
    try {
      const key = 'gmm_travel_bookings';
      const existing = localStorage.getItem(key);
      const bookings = existing ? JSON.parse(existing) : {};
      
      if (!bookings['GMM-9R5QWHAP']) {
        bookings['GMM-9R5QWHAP'] = {
          bookingCode: 'GMM-9R5QWHAP',
          schedule: {
            id: 'mock-sch-1',
            operator: 'GMM Travel',
            tripCode: 'GMM-TR-101',
            class: 'EXECUTIVE',
            origin: 'Manado',
            destination: 'Kotamobagu',
            departureTime: '05:30',
            arrivalTime: '10:30',
            duration: '5 jam',
            pricePerPax: 100000,
            tag: 'Tercepat'
          },
          selectedSeat: '6',
          passenger: {
            fullName: 'gwwegwgw',
            phone: 'wegwegwegwe'
          },
          paymentMethod: 'bni',
          status: 'PAID'
        };
        localStorage.setItem(key, JSON.stringify(bookings));
      }
    } catch (e) {
      console.error('Failed to prepopulate mock backend', e);
    }
  }
}
