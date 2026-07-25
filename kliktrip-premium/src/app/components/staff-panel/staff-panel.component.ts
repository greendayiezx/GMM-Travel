import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { environment } from '../../../environments/environment';

interface FlightBookingItem {
  booking_code: string;
  status: string;
  total_amount: number;
  flight_data: any;
  passengers: any[];
  ticket_url: string | null;
  created_at: string;
}

@Component({
  selector: 'app-staff-panel',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './staff-panel.component.html',
  styleUrl: './staff-panel.component.css',
})
export class StaffPanelComponent implements OnInit {
  private http = inject(HttpClient);

  isAuthenticated = false;
  staffKey = '';
  loginError = '';

  bookings: FlightBookingItem[] = [];
  isLoading = false;
  loadError = false;

  selectedBooking: FlightBookingItem | null = null;
  uploadFile: File | null = null;
  isUploading = false;
  failReason = '';
  actionMsg = '';

  readonly STATUS_LABELS: Record<string, string> = {
    PAID:                 'Pembayaran Diterima',
    PROCESSING_ISSUANCE:  'Sedang Diproses',
    ISSUED:               'Tiket Sudah Upload',
    FAILED_ISSUANCE:      'Gagal',
  };

  ngOnInit(): void {
    const saved = sessionStorage.getItem('gmm_staff_key');
    if (saved) {
      this.staffKey = saved;
      this.isAuthenticated = true;
      this.loadQueue();
    }
  }

  login(): void {
    if (!this.staffKey.trim()) return;
    this.isLoading = true;
    this.http.get<any>(`${environment.apiUrl}/staff/flight-bookings`, { headers: this.headers() })
      .subscribe({
        next: (res) => {
          this.isAuthenticated = true;
          this.loginError = '';
          sessionStorage.setItem('gmm_staff_key', this.staffKey);
          this.bookings = res.data ?? [];
          this.isLoading = false;
        },
        error: (err) => {
          this.loginError = err.status === 401 ? 'Kunci staff salah.' : 'Gagal terhubung ke server.';
          this.isLoading = false;
        }
      });
  }

  logout(): void {
    sessionStorage.removeItem('gmm_staff_key');
    this.isAuthenticated = false;
    this.staffKey = '';
    this.bookings = [];
    this.selectedBooking = null;
  }

  loadQueue(): void {
    this.isLoading = true;
    this.loadError = false;
    this.http.get<any>(`${environment.apiUrl}/staff/flight-bookings`, { headers: this.headers() })
      .subscribe({
        next: (res) => { this.bookings = res.data ?? []; this.isLoading = false; },
        error: () => { this.loadError = true; this.isLoading = false; }
      });
  }

  selectBooking(b: FlightBookingItem): void {
    this.selectedBooking = b;
    this.uploadFile = null;
    this.failReason = '';
    this.actionMsg  = '';
  }

  closeDetail(): void {
    this.selectedBooking = null;
  }

  startProcessing(code: string): void {
    this.http.post<any>(`${environment.apiUrl}/staff/flight-bookings/${code}/processing`, {}, { headers: this.headers() })
      .subscribe({
        next: () => { this.actionMsg = 'Status diubah ke Sedang Diproses.'; this.loadQueue(); },
        error: (e) => { this.actionMsg = e.error?.message ?? 'Gagal mengubah status.'; }
      });
  }

  onFileChange(event: Event): void {
    const input = event.target as HTMLInputElement;
    this.uploadFile = input.files?.[0] ?? null;
  }

  uploadTicket(code: string): void {
    if (!this.uploadFile) return;
    this.isUploading = true;
    const form = new FormData();
    form.append('ticket', this.uploadFile);

    this.http.post<any>(`${environment.apiUrl}/staff/flight-bookings/${code}/ticket`, form, { headers: this.uploadHeaders() })
      .subscribe({
        next: () => {
          this.isUploading = false;
          this.actionMsg = 'Tiket berhasil diupload. Status → ISSUED.';
          this.uploadFile = null;
          this.loadQueue();
        },
        error: (e) => {
          this.isUploading = false;
          this.actionMsg = e.error?.message ?? 'Gagal upload tiket.';
        }
      });
  }

  markFailed(code: string): void {
    if (!this.failReason.trim()) { this.actionMsg = 'Isi alasan gagal terlebih dahulu.'; return; }
    this.http.post<any>(`${environment.apiUrl}/staff/flight-bookings/${code}/failed`, { reason: this.failReason }, { headers: this.headers() })
      .subscribe({
        next: () => { this.actionMsg = 'Status diubah ke FAILED_ISSUANCE.'; this.loadQueue(); },
        error: (e) => { this.actionMsg = e.error?.message ?? 'Gagal mengubah status.'; }
      });
  }

  private headers(): HttpHeaders {
    return new HttpHeaders({ 'X-Staff-Key': this.staffKey });
  }

  private uploadHeaders(): HttpHeaders {
    return new HttpHeaders({ 'X-Staff-Key': this.staffKey });
  }

  formatPrice(v: number): string { return 'Rp ' + v.toLocaleString('id-ID'); }
  formatDate(iso: string): string {
    if (!iso) return '-';
    return new Date(iso).toLocaleString('id-ID', { dateStyle: 'medium', timeStyle: 'short' });
  }
}
