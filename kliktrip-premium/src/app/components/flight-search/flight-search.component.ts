import { Component, inject, Output, EventEmitter, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { FlightSearchService } from '../../services/flight-search.service';
import { FlightBookingService } from '../../services/flight-booking.service';
import { AirportOption } from '../../models/flight.model';
import { debounceTime, distinctUntilChanged, Subject, switchMap, of, catchError } from 'rxjs';

@Component({
  selector: 'app-flight-search',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './flight-search.component.html',
  styleUrl: './flight-search.component.css',
})
export class FlightSearchComponent {
  @Output() searched = new EventEmitter<void>();

  private searchService = inject(FlightSearchService);
  private flightService = inject(FlightBookingService);
  private router        = inject(Router);

  origin: AirportOption | null = null;
  destination: AirportOption | null = null;
  departureDate = '';
  returnDate    = '';
  adults        = 1;
  children      = 0;
  infants       = 0;
  isRoundTrip   = false;
  seatClass: 'Economy' | 'Business' | 'Premium Economy' | 'First' = 'Economy';

  originQuery      = '';
  destinationQuery = '';
  originResults: AirportOption[]      = [];
  destinationResults: AirportOption[] = [];
  isSearchingOrigin      = false;
  isSearchingDestination = false;

  submitted = false;

  // Panel states
  showOriginPanel      = false;
  showDestinationPanel = false;
  showDatePanel        = false;
  showPaxPanel         = false;

  // Calendar
  calendarMonths: { year: number; month: number; name: string; days: (number | null)[] }[] = [];

  // Popular destinations — kode IATA eksplisit agar tidak salah resolve
  popularCities: { label: string; code: string; city: string; country: string }[] = [
    { label: 'Jakarta',       code: 'CGK', city: 'Jakarta',       country: 'Indonesia' },
    { label: 'Denpasar-Bali', code: 'DPS', city: 'Denpasar',      country: 'Indonesia' },
    { label: 'Surabaya',      code: 'SUB', city: 'Surabaya',      country: 'Indonesia' },
    { label: 'Medan',         code: 'KNO', city: 'Medan',         country: 'Indonesia' },
    { label: 'Kuala Lumpur',  code: 'KUL', city: 'Kuala Lumpur',  country: 'Malaysia'  },
    { label: 'Makassar',      code: 'UPG', city: 'Makassar',      country: 'Indonesia' },
    { label: 'Singapore',     code: 'SIN', city: 'Singapore',     country: 'Singapura' },
    { label: 'Yogyakarta',    code: 'JOG', city: 'Yogyakarta',    country: 'Indonesia' },
    { label: 'Balikpapan',    code: 'BPN', city: 'Balikpapan',    country: 'Indonesia' },
    { label: 'Batam',         code: 'BTH', city: 'Batam',         country: 'Indonesia' },
  ];

  private originInput$      = new Subject<string>();
  private destinationInput$ = new Subject<string>();

  todayMin = new Date().toISOString().split('T')[0];
  today = new Date();

  constructor() {
    this.buildCalendar();

    this.originInput$.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      switchMap(term => {
        if (term.length < 2) { this.originResults = []; return of([] as AirportOption[]); }
        this.isSearchingOrigin = true;
        return this.searchService.searchAirports(term).pipe(catchError(() => of([] as AirportOption[])));
      })
    ).subscribe(results => {
      this.originResults = results;
      this.isSearchingOrigin = false;
    });

    this.destinationInput$.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      switchMap(term => {
        if (term.length < 2) { this.destinationResults = []; return of([] as AirportOption[]); }
        this.isSearchingDestination = true;
        return this.searchService.searchAirports(term).pipe(catchError(() => of([] as AirportOption[])));
      })
    ).subscribe(results => {
      this.destinationResults = results;
      this.isSearchingDestination = false;
    });
  }

  // Close panels on Esc key
  @HostListener('window:keydown.escape')
  onEscape() {
    this.closeAllPanels();
  }

  // Close panels when clicking outside
  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent) {
    const target = event.target as HTMLElement;
    if (!target.closest('.fs-panel-anchor') && !target.closest('.fs-dropdown-panel') && !target.closest('.fs-calendar-panel') && !target.closest('.fs-pax-panel')) {
      this.closeAllPanels();
    }
  }

  closeAllPanels() {
    this.showOriginPanel = false;
    this.showDestinationPanel = false;
    this.showDatePanel = false;
    this.showPaxPanel = false;
  }

  togglePanel(panel: 'origin' | 'destination' | 'date' | 'pax', event: MouseEvent) {
    event.stopPropagation();
    const isAlreadyOpen =
      (panel === 'origin' && this.showOriginPanel) ||
      (panel === 'destination' && this.showDestinationPanel) ||
      (panel === 'date' && this.showDatePanel) ||
      (panel === 'pax' && this.showPaxPanel);

    this.closeAllPanels();

    if (!isAlreadyOpen) {
      if (panel === 'origin') this.showOriginPanel = true;
      else if (panel === 'destination') this.showDestinationPanel = true;
      else if (panel === 'date') this.showDatePanel = true;
      else if (panel === 'pax') this.showPaxPanel = true;
    }
  }

  closePanel(panel: 'origin' | 'destination' | 'date' | 'pax', event?: MouseEvent) {
    if (event) event.stopPropagation();
    if (panel === 'origin') this.showOriginPanel = false;
    else if (panel === 'destination') this.showDestinationPanel = false;
    else if (panel === 'date') this.showDatePanel = false;
    else if (panel === 'pax') this.showPaxPanel = false;
  }

  onOriginInput(value: string) {
    this.originQuery = value;
    this.origin = null;
    this.originInput$.next(value);
  }

  onDestinationInput(value: string) {
    this.destinationQuery = value;
    this.destination = null;
    this.destinationInput$.next(value);
  }

  onPopularClick(popular: { label: string; code: string; city: string; country: string }, type: 'origin' | 'destination', event?: MouseEvent) {
    if (event) event.stopPropagation();
    const airport: AirportOption = {
      code:        popular.code,
      name:        popular.label,
      city:        popular.city,
      country:     popular.country,
      displayName: `${popular.label} (${popular.code})`,
    };
    if (type === 'origin') {
      this.selectOrigin(airport);
    } else {
      this.selectDestination(airport);
    }
  }

  selectOrigin(airport: AirportOption, event?: MouseEvent) {
    if (event) event.stopPropagation();
    this.origin      = airport;
    this.originQuery = airport.displayName;
    this.closeAllPanels();
  }

  selectDestination(airport: AirportOption, event?: MouseEvent) {
    if (event) event.stopPropagation();
    this.destination      = airport;
    this.destinationQuery = airport.displayName;
    this.closeAllPanels();
  }

  swapAirports(event?: MouseEvent) {
    if (event) event.stopPropagation();
    const tmpOrigin       = this.origin;
    const tmpQuery        = this.originQuery;
    this.origin           = this.destination;
    this.originQuery      = this.destinationQuery;
    this.destination      = tmpOrigin;
    this.destinationQuery = tmpQuery;
  }

  get paxClassLabel(): string {
    return `${this.totalPassengers}, ${this.seatClass}`;
  }

  get totalPassengers() { return this.adults + this.children + this.infants; }

  addAdult()    { if (this.adults < 9) this.adults++; }
  removeAdult() { if (this.adults > 1) this.adults--; }
  addChild()    { if (this.children < 8) this.children++; }
  removeChild() { if (this.children > 0) this.children--; }
  addInfant()   { if (this.infants < 8) this.infants++; }
  removeInfant(){ if (this.infants > 0) this.infants--; }

  get isValid(): boolean {
    return !!this.origin && !!this.destination && !!this.departureDate;
  }

  // Calendar helpers
  buildCalendar() {
    const now = new Date();
    this.calendarMonths = [];
    for (let i = 0; i < 2; i++) {
      const d = new Date(now.getFullYear(), now.getMonth() + i, 1);
      const year = d.getFullYear();
      const month = d.getMonth();
      const name = d.toLocaleDateString('id-ID', { month: 'long', year: 'numeric' });
      const firstDay = d.getDay(); // 0=Sun
      const daysInMonth = new Date(year, month + 1, 0).getDate();
      const days: (number | null)[] = [];
      for (let blank = 0; blank < firstDay; blank++) days.push(null);
      for (let day = 1; day <= daysInMonth; day++) days.push(day);
      this.calendarMonths.push({ year, month, name, days });
    }
  }

  nextCalendarMonth(event?: MouseEvent) {
    if (event) event.stopPropagation();
    const last = this.calendarMonths[this.calendarMonths.length - 1];
    const d = new Date(last.year, last.month + 1, 1);
    const year = d.getFullYear();
    const month = d.getMonth();
    const name = d.toLocaleDateString('id-ID', { month: 'long', year: 'numeric' });
    const firstDay = d.getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const days: (number | null)[] = [];
    for (let blank = 0; blank < firstDay; blank++) days.push(null);
    for (let day = 1; day <= daysInMonth; day++) days.push(day);
    this.calendarMonths.shift();
    this.calendarMonths.push({ year, month, name, days });
  }

  prevCalendarMonth(event?: MouseEvent) {
    if (event) event.stopPropagation();
    const first = this.calendarMonths[0];
    const d = new Date(first.year, first.month - 1, 1);
    if (d < new Date(this.today.getFullYear(), this.today.getMonth(), 1)) return;
    const year = d.getFullYear();
    const month = d.getMonth();
    const name = d.toLocaleDateString('id-ID', { month: 'long', year: 'numeric' });
    const firstDay = d.getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const days: (number | null)[] = [];
    for (let blank = 0; blank < firstDay; blank++) days.push(null);
    for (let day = 1; day <= daysInMonth; day++) days.push(day);
    this.calendarMonths.pop();
    this.calendarMonths.unshift({ year, month, name, days });
  }

  selectDate(calMonth: { year: number; month: number }, day: number, event?: MouseEvent) {
    if (event) event.stopPropagation();
    const dateStr = `${calMonth.year}-${String(calMonth.month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    if (dateStr < this.todayMin) return;
    this.departureDate = dateStr;
    this.closeAllPanels();
  }

  isDateSelected(calMonth: { year: number; month: number }, day: number): boolean {
    if (!this.departureDate) return false;
    const dateStr = `${calMonth.year}-${String(calMonth.month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    return dateStr === this.departureDate;
  }

  isDatePast(calMonth: { year: number; month: number }, day: number): boolean {
    const dateStr = `${calMonth.year}-${String(calMonth.month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    return dateStr < this.todayMin;
  }

  isToday(calMonth: { year: number; month: number }, day: number): boolean {
    const t = this.today;
    return calMonth.year === t.getFullYear() && calMonth.month === t.getMonth() && day === t.getDate();
  }

  formatDepartureDisplay(): string {
    if (!this.departureDate) return 'Pilih Tanggal';
    const d = new Date(this.departureDate + 'T00:00:00');
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return `${days[d.getDay()]}, ${d.getDate()} ${months[d.getMonth()]} ${d.getFullYear()}`;
  }

  savePax(event?: MouseEvent) {
    if (event) event.stopPropagation();
    this.closeAllPanels();
  }

  onSearch() {
    this.submitted = true;
    if (!this.isValid) return;

    this.router.navigate(['/flights/results'], {
      queryParams: {
        origin:          this.origin!.code,
        destination:     this.destination!.code,
        originName:      this.origin!.displayName,
        destinationName: this.destination!.displayName,
        departure_date:  this.departureDate,
        return_date:     this.isRoundTrip ? this.returnDate : '',
        adults:          this.adults,
        children:        this.children,
        infants:         this.infants,
        seat_class:      this.seatClass,
      }
    });
  }
}
