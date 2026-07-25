import { Injectable, signal, computed } from '@angular/core';

export interface SearchFormState {
  departure: string;
  destination: string;
  startDate: Date | null;
  endDate: Date | null;
  adults: number;
  children: number;
  isRoundTrip: boolean;
}

export interface ValidationResult {
  valid: boolean;
  errors: string[];
}

@Injectable({ providedIn: 'root' })
export class SearchFormService {
  submitted = signal(false);

  state = signal<SearchFormState>({
    departure: '',
    destination: '',
    startDate: null,
    endDate: null,
    adults: 2,
    children: 0,
    isRoundTrip: false,
  });

  totalPassengers = computed(() => this.state().adults + this.state().children);

  validation = computed((): ValidationResult => {
    const s = this.state();
    const errors: string[] = [];
    if (!s.departure.trim()) errors.push('Pilih kota asal keberangkatan.');
    if (!s.destination.trim()) errors.push('Pilih destinasi tujuan.');
    if (s.departure.trim() && s.destination.trim() && s.departure.trim() === s.destination.trim()) {
      errors.push('Kota asal dan kota tujuan tidak boleh sama.');
    }
    if (!s.startDate) errors.push('Pilih tanggal berangkat.');
    if (s.isRoundTrip) {
      if (!s.endDate) errors.push('Pilih tanggal pulang.');
      if (s.startDate && s.endDate && s.endDate <= s.startDate) errors.push('Tanggal pulang harus setelah tanggal berangkat.');
    }
    return { valid: errors.length === 0, errors };
  });

  patch(partial: Partial<SearchFormState>) {
    this.state.update(s => ({ ...s, ...partial }));
  }

  markSubmitted() {
    this.submitted.set(true);
  }

  reset() {
    this.submitted.set(false);
    this.state.set({ departure: '', destination: '', startDate: null, endDate: null, adults: 2, children: 0, isRoundTrip: false });
  }

  isFieldInvalid(field: 'departure' | 'destination' | 'startDate' | 'endDate'): boolean {
    if (!this.submitted()) return false;
    const s = this.state();
    if (field === 'departure') return !s.departure.trim();
    if (field === 'destination') return !s.destination.trim();
    if (field === 'startDate') return !s.startDate;
    if (field === 'endDate') return s.isRoundTrip && (!s.endDate || (!!s.startDate && s.endDate <= s.startDate!));
    return false;
  }
}
