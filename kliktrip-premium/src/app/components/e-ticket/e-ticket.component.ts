import { Component, OnInit, ElementRef, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, ActivatedRoute } from '@angular/router';
import { BookingService } from '../../services/booking.service';
import QRCode from 'qrcode';

@Component({
  selector: 'app-e-ticket',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './e-ticket.component.html',
  styleUrl: './e-ticket.component.css'
})
export class ETicketComponent implements OnInit {
  @ViewChild('qrCanvas') qrCanvas!: ElementRef<HTMLCanvasElement>;

  qrDataUrl = '';

  // Flag dibaca oleh ticketLockGuard untuk membedakan
  // "user sengaja keluar" vs "tombol Back/Forward browser"
  public isNavigatingAway = false;

  constructor(
    public bookingService: BookingService,
    private router: Router,
    private route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    // Prefer route param :code; fall back to BookingService state
    const routeCode = this.route.snapshot.paramMap.get('code');
    const code = routeCode ?? this.bookingService.bookingCode ?? 'GMM-UNKNOWN';

    const payload = `${code}|${this.bookingService.schedule?.tripCode}|${this.bookingService.passenger?.fullName}|${this.bookingService.selectedSeat}`;
    QRCode.toDataURL(payload, { width: 180, margin: 2, color: { dark: '#1e293b', light: '#ffffff' } })
      .then(url => { this.qrDataUrl = url; })
      .catch(() => { this.qrDataUrl = ''; });
  }

  goHome(): void {
    // Set flag agar ticketLockGuard mengizinkan navigasi ini
    this.isNavigatingAway = true;
    this.bookingService.reset();
    window.location.href = '/';
  }

  printTicket(): void {
    window.print();
  }
}

