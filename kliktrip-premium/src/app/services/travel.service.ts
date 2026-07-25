import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';

export interface ApiSchedule {
  id: string;
  departure_time: string;
  price: number;
  available_seats: number;
  status: string;
  travel_route: {
    departure_city: { name: string };
    arrival_city: { name: string };
  };
}

export interface PackageBookingState {
  packageName: string;
  selectedDate: string;
  ticketItems: { name: string; priceNumber: number; qty: number }[];
  totalPriceFormatted: string;
  totalPriceNumber: number;
  packageImage?: string;
  duration?: string;
  contactName?: string;
  contactEmail?: string;
  contactPhone?: string;
}

@Injectable({ providedIn: 'root' })
export class TravelService {
  private http = inject(HttpClient);
  private _schedules = signal<ApiSchedule[]>([]);

  readonly schedules = this._schedules.asReadonly();

  // ── Package selection & navigation state ──
  lastSelectedPackageName: string | null = null;
  lastSelectedFilter: string = 'Semua';
  lastSelectedPage: number = 1;
  isReturningFromDetail: boolean = false;

  private static readonly BOOKING_STORAGE_KEY = 'gmm_package_booking_state';
  private _packageBookingData: PackageBookingState | null = null;

  get packageBookingData(): PackageBookingState | null {
    if (this._packageBookingData) return this._packageBookingData;
    try {
      const raw = sessionStorage.getItem(TravelService.BOOKING_STORAGE_KEY);
      if (raw) {
        this._packageBookingData = JSON.parse(raw);
        return this._packageBookingData;
      }
    } catch {}
    return null;
  }

  set packageBookingData(value: PackageBookingState | null) {
    this._packageBookingData = value;
    try {
      if (value) {
        sessionStorage.setItem(TravelService.BOOKING_STORAGE_KEY, JSON.stringify(value));
      } else {
        sessionStorage.removeItem(TravelService.BOOKING_STORAGE_KEY);
      }
    } catch {}
  }

  setLastSelectedPackage(packageName: string, filter: string = 'Semua', page: number = 1): void {
    this.lastSelectedPackageName = packageName;
    this.lastSelectedFilter = filter;
    this.lastSelectedPage = page;
  }

  loadSchedules(): void {
    this.http.get<ApiSchedule[]>(`${environment.apiUrl}/schedules`).subscribe({
      next: (data) => this._schedules.set(data),
      error: (err) => console.warn('Gagal memuat jadwal dari API:', err.message)
    });
  }

  /** Semua schedules untuk rute tertentu, diurutkan berdasarkan jam keberangkatan */
  getRouteSchedules(departure: string, destination: string): ApiSchedule[] {
    const dep  = departure.toLowerCase();
    const dest = destination.toLowerCase();

    return this._schedules()
      .filter(s => {
        const depCity = s.travel_route?.departure_city?.name?.toLowerCase() ?? '';
        const arrCity = s.travel_route?.arrival_city?.name?.toLowerCase() ?? '';
        return depCity === dep && arrCity === dest;
      })
      .sort((a, b) => new Date(a.departure_time).getTime() - new Date(b.departure_time).getTime());
  }

  /** Format jam dari ISO string ke HH:MM — ekstrak langsung dari string agar tidak ada konversi timezone */
  formatTime(isoString: string): string {
    const match = isoString.match(/T(\d{2}:\d{2})/);
    if (match) return match[1];
    // fallback: parse Date dengan UTC methods
    const d = new Date(isoString);
    const hh = String(d.getUTCHours()).padStart(2, '0');
    const mm = String(d.getUTCMinutes()).padStart(2, '0');
    return `${hh}:${mm}`;
  }

  /** Generate trip code dari jam keberangkatan, misal "GMM-0530" */
  toTripCode(isoString: string): string {
    return `GMM-${this.formatTime(isoString).replace(':', '')}`;
  }

  /** Cari UUID schedule berdasarkan rute dan index */
  getScheduleId(departure: string, destination: string, index: number): string | null {
    const matching = this.getRouteSchedules(departure, destination);
    if (matching.length === 0) return null;
    return matching[index % matching.length].id;
  }

  /** Cari harga dari DB untuk rute tertentu (atau null jika tidak ada) */
  getPriceFromDb(departure: string, destination: string): number | null {
    const match = this.getRouteSchedules(departure, destination)[0];
    return match ? Number(match.price) : null;
  }
}
