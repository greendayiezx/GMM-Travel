import { Component, OnInit, OnDestroy, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { FlightBookingService } from '../../services/flight-booking.service';
import { environment } from '../../../environments/environment';
import { Subscription, interval } from 'rxjs';
import { switchMap, takeWhile } from 'rxjs/operators';
import QRCode from 'qrcode';

interface PaymentMethod {
  id: string;
  label: string;
  icon: string;
  detail: string;
}

@Component({
  selector: 'app-flight-payment',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './flight-payment.component.html',
  styleUrl: './flight-payment.component.css',
})
export class FlightPaymentComponent implements OnInit, OnDestroy {
  private http = inject(HttpClient);

  methods: PaymentMethod[] = [
    { id: 'bni',     label: 'BNI Virtual Account',     icon: '/assets/logo-bni.svg',     detail: 'Transfer ke VA BNI otomatis' },
    { id: 'bri',     label: 'BRI Virtual Account',     icon: '/assets/logo-bri.svg',     detail: 'Transfer ke VA BRI otomatis' },
    { id: 'mandiri', label: 'Mandiri Virtual Account', icon: '/assets/logo-mandiri.svg', detail: 'Transfer ke VA Mandiri otomatis' },
    { id: 'gopay',   label: 'GoPay',                   icon: '/assets/logo-gopay.svg',   detail: 'Bayar via aplikasi Gojek' },
    { id: 'ovo',     label: 'OVO',                     icon: '/assets/logo-ovo.svg',     detail: 'Bayar via aplikasi OVO' },
    { id: 'dana',    label: 'DANA',                    icon: '/assets/logo-dana.svg',    detail: 'Bayar via aplikasi DANA' },
    { id: 'qris',    label: 'QRIS',                    icon: '/assets/logo-qris.svg',    detail: 'Scan QR dengan app apapun' },
  ];

  selected: string | null = null;
  timeLeft = 15 * 60;
  private timer: ReturnType<typeof setInterval> | null = null;
  isProcessing = false;

  paymentType: 'va' | 'echannel' | 'qr' | null = null;
  instructions: any = null;
  paymentId: string | null = null;
  bookingCode: string | null = null;
  qrDataUrl = '';
  copyStatus: Record<string, string> = {};
  isSandbox = false;
  isSimulating = false;
  private pollSub: Subscription | null = null;

  constructor(public flightService: FlightBookingService, public router: Router) {}

  ngOnInit(): void {
    this.timer = setInterval(() => {
      if (this.timeLeft > 0) this.timeLeft--;
      else this.stopStatusPolling();
    }, 1000);
  }

  ngOnDestroy(): void {
    if (this.timer) clearInterval(this.timer);
    this.stopStatusPolling();
  }

  get minutes(): string { return String(Math.floor(this.timeLeft / 60)).padStart(2, '0'); }
  get seconds(): string { return String(this.timeLeft % 60).padStart(2, '0'); }
  get methodLabel(): string { return this.methods.find(m => m.id === this.selected)?.label ?? ''; }

  select(id: string): void {
    if (this.instructions) return;
    this.selected = id;
  }

  confirm(): void {
    if (!this.selected || this.isProcessing) return;
    this.isProcessing = true;

    const flight     = this.flightService.selectedFlight!;
    const passengers = this.flightService.passengers;

    const payload = {
      flight_data:     flight,
      passengers:      passengers,
      payment_method:  this.selected,
    };

    this.http.post<any>(`${environment.apiUrl}/flight-payments`, payload).subscribe({
      next: (res) => {
        this.isProcessing = false;
        if (!res.success) return;

        this.bookingCode  = res.booking_code;
        this.paymentId    = res.payment.id;
        this.paymentType  = res.payment_type;
        this.instructions = res.instructions;
        this.isSandbox    = res.sandbox ?? false;

        if (this.paymentType === 'qr') {
          const qrString = this.instructions?.qr_string ?? this.instructions?.qr_code ?? '';
          if (qrString) {
            QRCode.toDataURL(qrString, { width: 220, margin: 2 })
              .then(url => { this.qrDataUrl = url; })
              .catch(() => { this.qrDataUrl = ''; });
          }
        }

        this.startStatusPolling();
      },
      error: (err) => {
        this.isProcessing = false;
        alert(err.error?.message ?? 'Terjadi kesalahan sistem pembayaran.');
      }
    });
  }

  copyToClipboard(key: string, text: string): void {
    navigator.clipboard.writeText(text).then(() => {
      this.copyStatus[key] = 'Tersalin!';
      setTimeout(() => { delete this.copyStatus[key]; }, 2000);
    });
  }

  getCopyLabel(key: string): string { return this.copyStatus[key] ?? 'Salin'; }

  simulateSuccess(): void {
    if (!this.paymentId || this.isSimulating) return;
    this.isSimulating = true;
    this.http.post<any>(`${environment.apiUrl}/payments/${this.paymentId}/simulate-success`, {}).subscribe({
      next: (res) => {
        if (res.success) {
          this.stopStatusPolling();
          this.flightService.saveToStorage(this.bookingCode!, 'PAID');
          this.router.navigate(['/flights/waiting', this.bookingCode], { replaceUrl: true });
        }
      },
      error: () => { this.isSimulating = false; }
    });
  }

  startStatusPolling(): void {
    this.stopStatusPolling();
    this.pollSub = interval(3000).pipe(
      switchMap(() => this.http.get<any>(`${environment.apiUrl}/payments/${this.paymentId}/status`)),
      takeWhile(res => res.status === 'PENDING', true)
    ).subscribe({
      next: (res) => {
        if (res.status === 'SUCCESS') {
          this.stopStatusPolling();
          this.flightService.saveToStorage(this.bookingCode!, 'PAID');
          this.router.navigate(['/flights/waiting', this.bookingCode], { replaceUrl: true });
        } else if (res.status === 'FAILED' || res.status === 'EXPIRED') {
          this.stopStatusPolling();
          alert('Batas waktu pembayaran habis atau transaksi dibatalkan.');
          this.instructions = null;
          this.paymentType  = null;
        }
      }
    });
  }

  stopStatusPolling(): void {
    if (this.pollSub) { this.pollSub.unsubscribe(); this.pollSub = null; }
  }
}
