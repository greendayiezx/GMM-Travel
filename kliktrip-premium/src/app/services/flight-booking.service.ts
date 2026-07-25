import { Injectable, signal } from '@angular/core';
import { FlightResult, FlightPassenger } from '../models/flight.model';

export interface FlightBookingState {
  selectedFlight: FlightResult | null;
  passengers: FlightPassenger[];
  paymentMethod: string | null;
  bookingCode: string | null;
}

@Injectable({ providedIn: 'root' })
export class FlightBookingService {
  private _state = signal<FlightBookingState>({
    selectedFlight: null,
    passengers: [],
    paymentMethod: null,
    bookingCode: null,
  });

  readonly state = this._state.asReadonly();

  get selectedFlight()  { return this._state().selectedFlight; }
  get passengers()      { return this._state().passengers; }
  get paymentMethod()   { return this._state().paymentMethod; }
  get bookingCode()     { return this._state().bookingCode; }
  get totalPrice()      { return (this._state().selectedFlight?.price ?? 0) * Math.max(1, this._state().passengers.length); }

  setFlight(flight: FlightResult) {
    this._state.update(st => ({ ...st, selectedFlight: flight, passengers: [], paymentMethod: null, bookingCode: null }));
  }

  setPassengers(passengers: FlightPassenger[]) {
    this._state.update(st => ({ ...st, passengers }));
  }

  setPaymentMethod(method: string) {
    this._state.update(st => ({ ...st, paymentMethod: method }));
  }

  setBookingCode(code: string) {
    this._state.update(st => ({ ...st, bookingCode: code }));
  }

  reset() {
    this._state.set({ selectedFlight: null, passengers: [], paymentMethod: null, bookingCode: null });
  }

  saveToStorage(bookingCode: string, status: string = 'PAID') {
    try {
      const existing = localStorage.getItem('gmm_flight_bookings');
      const bookings = existing ? JSON.parse(existing) : {};
      bookings[bookingCode] = { ...this._state(), bookingCode, status };
      localStorage.setItem('gmm_flight_bookings', JSON.stringify(bookings));
    } catch (e) {
      console.error('Failed to save flight booking', e);
    }
  }

  loadFromStorage(code: string): boolean {
    try {
      const existing = localStorage.getItem('gmm_flight_bookings');
      if (!existing) return false;
      const bookings = JSON.parse(existing);
      const b = bookings[code];
      if (b) {
        this._state.set({
          selectedFlight: b.selectedFlight,
          passengers: b.passengers ?? [],
          paymentMethod: b.paymentMethod,
          bookingCode: b.bookingCode,
        });
        return true;
      }
    } catch (e) {
      console.error('Failed to load flight booking', e);
    }
    return false;
  }
}
