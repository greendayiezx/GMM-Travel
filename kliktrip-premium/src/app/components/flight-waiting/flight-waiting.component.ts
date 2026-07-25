import { Component, OnInit, OnDestroy, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { interval, Subscription } from 'rxjs';
import { switchMap, takeWhile } from 'rxjs/operators';
import { FlightBookingService } from '../../services/flight-booking.service';
import { environment } from '../../../environments/environment';

interface BookingStatus {
  booking_code: string;
  status: string;
  flight_data: any;
  passengers: any[];
  ticket_url: string | null;
  total_amount: number;
}

@Component({
  selector: 'app-flight-waiting',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './flight-waiting.component.html',
  styleUrl: './flight-waiting.component.css',
})
export class FlightWaitingComponent implements OnInit, OnDestroy {
  private route   = inject(ActivatedRoute);
  private router  = inject(Router);
  private http    = inject(HttpClient);
  public  flightService = inject(FlightBookingService);

  isNavigatingAway = false;

  bookingCode = '';
  booking: BookingStatus | null = null;
  isLoading   = true;
  loadError   = false;

  private pollSub: Subscription | null = null;

  readonly STATUS_LABELS: Record<string, string> = {
    PENDING:              'Menunggu Pembayaran',
    PAID:                 'Pembayaran Diterima',
    PROCESSING_ISSUANCE:  'Sedang Diproses',
    ISSUED:               'Tiket Siap',
    FAILED_ISSUANCE:      'Proses Gagal',
    EXPIRED:              'Kedaluwarsa',
    CANCELLED:            'Dibatalkan',
  };

  ngOnInit(): void {
    this.bookingCode = this.route.snapshot.paramMap.get('code') ?? '';
    this.fetchStatus();
    this.startPolling();
  }

  ngOnDestroy(): void {
    this.stopPolling();
  }

  private fetchStatus(): void {
    this.isLoading = true;
    this.http.get<BookingStatus>(`${environment.apiUrl}/flight-bookings/${this.bookingCode}/status`)
      .subscribe({
        next: (data) => {
          this.booking   = data;
          this.isLoading = false;

          if (data.status === 'ISSUED' && data.ticket_url) {
            this.stopPolling();
          }
        },
        error: () => {
          this.loadError = true;
          this.isLoading = false;
        }
      });
  }

  private startPolling(): void {
    this.pollSub = interval(30000).subscribe(() => {
      this.http.get<BookingStatus>(`${environment.apiUrl}/flight-bookings/${this.bookingCode}/status`)
        .subscribe({
          next: (data) => {
            this.booking = data;
            if (data.status === 'ISSUED') this.stopPolling();
          }
        });
    });
  }

  stopPolling(): void {
    if (this.pollSub) { this.pollSub.unsubscribe(); this.pollSub = null; }
  }

  refreshStatus(): void {
    this.fetchStatus();
  }

  viewTicket(): void {
    if (this.booking?.ticket_url) {
      window.open(this.booking.ticket_url, '_blank');
    }
  }

  goHome(): void {
    this.isNavigatingAway = true;
    this.flightService.reset();
    this.router.navigate(['/'], { replaceUrl: true });
  }

  get statusLabel(): string {
    return this.STATUS_LABELS[this.booking?.status ?? ''] ?? this.booking?.status ?? '';
  }

  get isPaid(): boolean {
    return this.booking?.status === 'PAID';
  }

  get isProcessing(): boolean {
    return this.booking?.status === 'PROCESSING_ISSUANCE';
  }

  get isIssued(): boolean {
    return this.booking?.status === 'ISSUED';
  }

  get isFailed(): boolean {
    return this.booking?.status === 'FAILED_ISSUANCE';
  }

  formatPrice(amount: number): string {
    return 'Rp ' + amount.toLocaleString('id-ID');
  }
}
