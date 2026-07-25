import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-flight-card',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './flight-card.component.html',
  styleUrl: './flight-card.component.css'
})
export class FlightCardComponent {
  @Input() airline!: { name: string; logo: string; flightNumber: string };
  @Input() departureTime!: string;
  @Input() arrivalTime!: string;
  @Input() duration!: string;
  @Input() stops!: number;
  @Input() price!: number;
  @Input() currency = 'IDR';
  @Input() offer?: string;
  @Input() refundableType!: string;
  @Input() departureCity = 'CGK';
  @Input() arrivalCity = 'DPS';
  @Input() routeDescription = 'Jalur darat Trans Sulawesi';

  showDetails = false;

  @Output() book = new EventEmitter<void>();

  toggleDetails() {
    this.showDetails = !this.showDetails;
  }

  get stopText(): string {
    return this.stops === 0 ? 'Non-stop' : `${this.stops} stop${this.stops > 1 ? 's' : ''}`;
  }

  formatCurrency(amount: number, currency: string = 'IDR'): string {
    if (currency === 'IDR' || currency === 'Rp') {
      return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
      }).format(amount);
    }
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: currency,
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
  }
}
