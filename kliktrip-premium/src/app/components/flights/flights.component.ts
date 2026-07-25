import { Component, Inject, OnInit, forwardRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { BookingService, BookingSchedule } from '../../services/booking.service';
import { SearchFormService } from '../../services/search-form.service';
import { TravelService, ApiSchedule } from '../../services/travel.service';
import { FlightCardComponent } from '../flight-card/flight-card.component';
import { FooterSectionComponent } from '../footer-section/footer-section.component';
import { AppComponent } from '../../app.component';

// Tipe tiket yang ditampilkan di kartu
interface DisplayTicket {
  scheduleId: string;
  flightNumber: string;   // GMM-HHMM dari departure_time API
  departureTime: string;  // HH:MM untuk tampilan
  arrivalTime: string;
  price: number;
  type: 'EXECUTIVE' | 'ECONOMY';
}

// Tiket fallback jika API belum load
const FALLBACK_TICKETS = [
  { flightNumber: 'GMM-0530', departureTime: '05:30', type: 'EXECUTIVE' as const },
  { flightNumber: 'GMM-0915', departureTime: '09:15', type: 'ECONOMY'   as const },
  { flightNumber: 'GMM-1200', departureTime: '12:00', type: 'EXECUTIVE' as const },
  { flightNumber: 'GMM-1540', departureTime: '15:40', type: 'EXECUTIVE' as const },
  { flightNumber: 'GMM-1830', departureTime: '18:30', type: 'ECONOMY'   as const },
  { flightNumber: 'GMM-2100', departureTime: '21:00', type: 'ECONOMY'   as const },
];

// Pola kelas per slot (0–5): E E E Ec Ec Ec
const CLASS_PATTERN: Array<'EXECUTIVE' | 'ECONOMY'> =
  ['EXECUTIVE', 'ECONOMY', 'EXECUTIVE', 'EXECUTIVE', 'ECONOMY', 'ECONOMY'];

@Component({
  selector: 'app-flights',
  standalone: true,
  imports: [CommonModule, FlightCardComponent, FooterSectionComponent],
  templateUrl: './flights.component.html'
})
export class FlightsComponent implements OnInit {

  constructor(
    @Inject(forwardRef(() => AppComponent)) private appComponent: AppComponent,
    private router: Router,
    public bookingService: BookingService,
    public searchFormService: SearchFormService,
    public travelService: TravelService
  ) {}

  ngOnInit(): void {
    this.travelService.loadSchedules();
  }

  get origin(): string {
    return this.getCityName(this.searchFormService.state().departure) || 'Manado';
  }

  get destination(): string {
    return this.getCityName(this.searchFormService.state().destination) || 'Kotamobagu';
  }

  /** Tiket yang ditampilkan — dari API jika tersedia, fallback jika belum */
  get displayTickets(): DisplayTicket[] {
    const apiSchedules = this.travelService.getRouteSchedules(this.origin, this.destination);

    if (apiSchedules.length > 0) {
      return apiSchedules.map((s, i) => ({
        scheduleId:    s.id,
        flightNumber:  this.travelService.toTripCode(s.departure_time),
        departureTime: this.travelService.formatTime(s.departure_time),
        arrivalTime:   this.calcArrival(this.travelService.formatTime(s.departure_time)),
        price:         Number(s.price),
        type:          CLASS_PATTERN[i % CLASS_PATTERN.length],
      }));
    }

    // Fallback: API belum load, gunakan data statis dengan harga dari tariff map
    return FALLBACK_TICKETS.map((t, i) => ({
      scheduleId:    '',
      flightNumber:  t.flightNumber,
      departureTime: t.departureTime,
      arrivalTime:   this.calcArrival(t.departureTime),
      price:         this.appComponent.getTicketPrice(t.type),
      type:          t.type,
    }));
  }

  goBack(): void {
    this.appComponent.onBackToHomeAnimation();
  }

  onBookTicket(ticket: DisplayTicket): void {
    // Blokir jika scheduleId bukan UUID (artinya API belum load)
    if (!ticket.scheduleId) {
      alert('Jadwal belum termuat dari server. Harap tunggu sebentar lalu coba lagi.');
      return;
    }

    const schedule: BookingSchedule = {
      id:            ticket.scheduleId,
      operator:      'GMM Travel',
      tripCode:      ticket.flightNumber,
      class:         ticket.type,
      origin:        this.origin,
      destination:   this.destination,
      departureTime: ticket.departureTime,
      arrivalTime:   ticket.arrivalTime,
      duration:      this.getTravelDuration(),
      pricePerPax:   ticket.price,
      tag:           ticket.type === 'EXECUTIVE' ? 'Layanan Premium' : 'Harga Terbaik',
    };

    this.bookingService.setSchedule(schedule);
    this.router.navigate(['/booking/seat']);
  }

  private calcArrival(departureTime: string): string {
    const durationStr = this.getTravelDuration();
    const match = durationStr.match(/(\d+)\s*jam/i);
    const hoursToAdd = match ? parseInt(match[1], 10) : 3;
    const [h, m] = departureTime.split(':').map(Number);
    const pad = (n: number) => String(n).padStart(2, '0');
    return `${pad((h + hoursToAdd) % 24)}:${pad(m)}`;
  }

  getTravelDuration(): string  { return this.appComponent.getTravelDuration(); }
  getRouteDescription(): string { return this.appComponent.getRouteDescription(); }

  getCityName(fullString: string): string {
    if (!fullString) return '';
    return fullString.split(',')[0].trim();
  }
}
