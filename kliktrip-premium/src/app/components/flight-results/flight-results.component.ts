import { Component, OnInit, inject, HostListener } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { FlightSearchService } from '../../services/flight-search.service';
import { FlightBookingService } from '../../services/flight-booking.service';
import { FlightResult } from '../../models/flight.model';
import { FooterSectionComponent } from '../footer-section/footer-section.component';

@Component({
  selector: 'app-flight-results',
  standalone: true,
  imports: [CommonModule, FormsModule, FooterSectionComponent],
  templateUrl: './flight-results.component.html',
  styleUrl: './flight-results.component.css',
})
export class FlightResultsComponent implements OnInit {
  private route         = inject(ActivatedRoute);
  private router        = inject(Router);
  private searchService = inject(FlightSearchService);
  private flightService = inject(FlightBookingService);

  flights: FlightResult[] = [];
  isLoading  = true;
  loadError  = false;

  // Sumber data respons — mempengaruhi tombol booking
  dataSource: 'duffel' | 'travelpayouts' = 'travelpayouts';
  bookable    = false;
  redirectLink: string | null = null;

  originName      = '';
  destinationName = '';
  departureDate   = '';
  adults          = 1;
  children        = 0;
  infants         = 0;

  private origin      = '';
  private destination = '';
  private returnDate: string | undefined;

  ngOnInit(): void {
    const q = this.route.snapshot.queryParamMap;
    this.originName      = q.get('originName')      ?? '';
    this.destinationName = q.get('destinationName') ?? '';
    this.departureDate   = q.get('departure_date')  ?? '';
    this.adults          = +(q.get('adults')   ?? 1);
    this.children        = +(q.get('children') ?? 0);
    this.infants         = +(q.get('infants')  ?? 0);
    this.origin          = q.get('origin')      ?? '';
    this.destination     = q.get('destination') ?? '';
    this.returnDate      = q.get('return_date') || undefined;
    this.seatClass       = q.get('seat_class')  ?? 'Economy';

    if (!this.origin || !this.destination || !this.departureDate) {
      this.router.navigate(['/flights/search']);
      return;
    }

    this.buildNearbyDates();
    this.loadFlights();
  }

  private loadFlights(): void {
    this.isLoading = true;
    this.loadError = false;

    this.searchService.searchFlightsFull({
      origin: this.origin,
      destination: this.destination,
      departure_date: this.departureDate,
      return_date: this.returnDate,
      adults: this.adults,
      children: this.children || undefined,
      infants: this.infants || undefined,
      seat_class: this.seatClass,
    }).subscribe({
      next: (res) => {
        this.flights      = res.data ?? [];
        this.dataSource   = res.source;
        this.bookable     = res.bookable;
        this.redirectLink = res.redirect_link ?? null;
        this.isLoading    = false;
        this.applyDatePricesFromSearch(res.date_prices);
        this.fetchRemainingDatePrices();
      },
      error: () => {
        this.loadError = true;
        this.isLoading = false;
      }
    });
  }


  /** Handler tombol berdasarkan sumber data */
  onSelectFlight(flight: FlightResult): void {
    if (this.isBookableFlight(flight)) {
      // Duffel — booking langsung di web
      this.selectFlight(flight);
    } else if (this.redirectLink) {
      // Travelpayouts — redirect ke partner
      window.open(this.redirectLink, '_blank', 'noopener,noreferrer');
    } else {
      // Fallback: lanjut ke passenger flow
      this.selectFlight(flight);
    }
  }

  isBookableFlight(flight: FlightResult): boolean {
    return flight.bookable === true || this.bookable === true;
  }

  selectFlight(flight: FlightResult): void {
    this.flightService.setFlight(flight);
    this.router.navigate(['/flights/passengers']);
  }

  get totalPassengers(): number { return this.adults + this.children + this.infants; }

  get formattedDate(): string {
    if (!this.departureDate) return '';
    const d = new Date(this.departureDate);
    return d.toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
  }

  formatPrice(price: number): string {
    return 'Rp ' + price.toLocaleString('id-ID');
  }

  /** Hanya angka tanpa prefix — dipakai di date strip dengan prefix "IDR" di template */
  formatNumber(price: number): string {
    return price.toLocaleString('id-ID');
  }

  expandedIndex: number | null = null;
  seatClass = 'Economy';

  // Edit search modal
  showEditModal = false;
  editOrigin = '';
  editDestination = '';
  editOriginName = '';
  editDestinationName = '';
  editDate = '';
  editPassengers = 1;
  editSeatClass = 'Economy';
  editRoundTrip = false;
  editReturnDate = '';

  // Autocomplete for edit modal
  editOriginResults: { code: string; name: string; city: string }[] = [];
  editDestResults: { code: string; name: string; city: string }[] = [];
  editOriginQuery = '';
  editDestQuery = '';

  // ── Date price strip ──────────────────────────────────────────
  nearbyDates: { label: string; dateStr: string; price: number; active: boolean; loading: boolean }[] = [];
  selectedDateStr = '';

  // ── Filter bar ────────────────────────────────────────────────
  openDropdown: string | null = null;

  sortMode: 'reko' | 'price_low' | 'dep_early' | 'dep_late' | 'arr_early' | 'arr_late' | 'dur_short' = 'reko';
  sortLabels: Record<string, string> = {
    reko: 'Rekomendasi',
    price_low: 'Harga terendah',
    dep_early: 'Keberangkatan paling awal',
    dep_late: 'Keberangkatan paling akhir',
    arr_early: 'Kedatangan paling awal',
    arr_late: 'Kedatangan paling akhir',
    dur_short: 'Durasi terpendek',
  };

  transitFilter: '' | 'direct' | '1' = '';
  airlineFilter = new Set<string>();
  directOnly = false;

  // Applied state (dipakai filter list) - hanya berubah saat user klik "Simpan"
  depFrom = 0;  depTo = 24;
  arrFrom = 0;  arrTo = 24;

  // Draft state (nilai slider live saat user menggeser, belum diterapkan)
  draftDepFrom = 0;  draftDepTo = 24;
  draftArrFrom = 0;  draftArrTo = 24;

  clampDep(): void {
    if (this.draftDepFrom > this.draftDepTo) {
      [this.draftDepFrom, this.draftDepTo] = [this.draftDepTo, this.draftDepFrom];
    }
  }
  clampArr(): void {
    if (this.draftArrFrom > this.draftArrTo) {
      [this.draftArrFrom, this.draftArrTo] = [this.draftArrTo, this.draftArrFrom];
    }
  }

  formatHour(h: number): string {
    if (h >= 24) return '23:59';
    return h.toString().padStart(2, '0') + ':00';
  }

  isTimeFiltered(): boolean {
    return this.depFrom !== 0 || this.depTo !== 24 || this.arrFrom !== 0 || this.arrTo !== 24;
  }

  /** Saat dropdown Waktu dibuka, sinkronkan draft dengan nilai aktif. */
  openTimeDropdown(event: Event): void {
    if (this.openDropdown !== 'time') {
      this.draftDepFrom = this.depFrom;
      this.draftDepTo   = this.depTo;
      this.draftArrFrom = this.arrFrom;
      this.draftArrTo   = this.arrTo;
    }
    this.toggleDropdown('time', event);
  }

  /** Terapkan draft ke state aktif dan tutup. */
  applyTimeFilter(): void {
    this.depFrom = this.draftDepFrom;
    this.depTo   = this.draftDepTo;
    this.arrFrom = this.draftArrFrom;
    this.arrTo   = this.draftArrTo;
    this.openDropdown = null;
  }

  /** Reset baik draft maupun applied. */
  resetTimeFilters(): void {
    this.draftDepFrom = 0; this.draftDepTo = 24;
    this.draftArrFrom = 0; this.draftArrTo = 24;
    this.depFrom = 0; this.depTo = 24;
    this.arrFrom = 0; this.arrTo = 24;
  }

  toggleDropdown(name: string, event?: Event): void {
    event?.stopPropagation();
    this.openDropdown = this.openDropdown === name ? null : name;
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    const target = event.target as HTMLElement;
    if (!target.closest('.filter-bar')) {
      this.openDropdown = null;
    }
  }

  get availableAirlines(): { code: string; name: string; count: number; minPrice: number }[] {
    const map = new Map<string, { count: number; min: number }>();
    for (const f of this.flights) {
      const e = map.get(f.airline) || { count: 0, min: Infinity };
      e.count++;
      e.min = Math.min(e.min, f.price);
      map.set(f.airline, e);
    }
    return [...map.entries()]
      .map(([code, v]) => ({ code, name: this.airlineName(code), count: v.count, minPrice: v.min }))
      .sort((a, b) => a.minPrice - b.minPrice);
  }

  toggleAirline(code: string): void {
    if (this.airlineFilter.has(code)) this.airlineFilter.delete(code);
    else this.airlineFilter.add(code);
  }

  resetAllFilters(): void {
    this.sortMode = 'reko';
    this.transitFilter = '';
    this.airlineFilter.clear();
    this.resetTimeFilters();
    this.directOnly = false;
  }

  activeFilterCount(): number {
    let c = 0;
    if (this.sortMode !== 'reko') c++;
    if (this.transitFilter) c++;
    if (this.airlineFilter.size) c++;
    if (this.depFrom !== 0 || this.depTo !== 24) c++;
    if (this.arrFrom !== 0 || this.arrTo !== 24) c++;
    return c;
  }

  toggleDetails(i: number) {
    this.expandedIndex = this.expandedIndex === i ? null : i;
  }

  buildNearbyDates(): void {
    if (!this.departureDate) return;
    const today  = new Date();
    today.setHours(0, 0, 0, 0);
    const days   = ['Min','Sen','Sel','Rab','Kam','Jum','Sab'];
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];

    // Mulai dari HARI INI, sampai 30 hari ke depan
    const start = new Date(today);
    const end   = new Date(today);
    end.setDate(end.getDate() + 30);

    this.nearbyDates = [];
    for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
      const cur = new Date(d);
      cur.setHours(0, 0, 0, 0);
      const yyyy = cur.getFullYear();
      const mm   = String(cur.getMonth() + 1).padStart(2, '0');
      const dd   = String(cur.getDate()).padStart(2, '0');
      const dateStr  = `${yyyy}-${mm}-${dd}`;
      const isActive = dateStr === this.departureDate;
      const label    = `${days[cur.getDay()]}, ${cur.getDate()} ${months[cur.getMonth()]} ${yyyy}`;
      this.nearbyDates.push({
        label, dateStr, price: 0, active: isActive, loading: true,
      });
    }
    this.selectedDateStr = this.departureDate;
  }

  private fetchRemainingDatePrices(): void {
    const remaining = this.nearbyDates.filter(d => d.loading);
    if (remaining.length === 0) return;

    const dateFrom = remaining[0].dateStr;
    const dateTo   = remaining[remaining.length - 1].dateStr;

    this.searchService.getPriceStrip(
      this.origin, this.destination, dateFrom, dateTo, this.seatClass
    ).subscribe(data => {
      remaining.forEach(item => {
        const info = data[item.dateStr];
        if (info && info.available && info.price > 0) {
          item.price = info.price;
        } else {
          item.price = -1;
        }
        item.loading = false;
      });
    });
  }

  private applyDatePricesFromSearch(datePrices?: Record<string, number>): void {
    const prices = datePrices ?? {};
    this.nearbyDates.forEach(item => {
      if (item.dateStr === this.departureDate) {
        item.price = this.flights.length > 0 ? this.flights[0].price : -1;
        item.loading = false;
      } else if (prices[item.dateStr] && prices[item.dateStr] > 0) {
        item.price = prices[item.dateStr];
        item.loading = false;
      }
    });
  }

  scrollStrip(el: HTMLElement, dir: 1 | -1): void {
    el.scrollBy({ left: dir * 260, behavior: 'smooth' });
  }

  selectDate(item: { label: string; dateStr: string; price: number; active: boolean; loading: boolean }): void {
    if (item.dateStr === this.departureDate) return; // tanggal sama, no-op
    this.nearbyDates.forEach(d => d.active = false);
    item.active = true;
    this.departureDate   = item.dateStr;
    this.selectedDateStr = item.dateStr;
    this.expandedIndex   = null;
    this.loadFlights();
  }

  get filteredFlights(): FlightResult[] {
    let list = [...this.flights];

    // Transit filter (chip or Penerbangan Langsung toggle)
    if (this.directOnly || this.transitFilter === 'direct') {
      list = list.filter(f => f.transitCount === 0);
    } else if (this.transitFilter === '1') {
      list = list.filter(f => f.transitCount === 1);
    }

    // Maskapai filter
    if (this.airlineFilter.size > 0) {
      list = list.filter(f => this.airlineFilter.has(f.airline));
    }

    // Waktu keberangkatan (jam)
    if (this.depFrom !== 0 || this.depTo !== 24) {
      list = list.filter(f => {
        const h = parseInt(f.departureTime.split(':')[0], 10);
        return h >= this.depFrom && h <= this.depTo;
      });
    }

    // Waktu kedatangan (jam)
    if (this.arrFrom !== 0 || this.arrTo !== 24) {
      list = list.filter(f => {
        const h = parseInt(f.arrivalTime.split(':')[0], 10);
        return h >= this.arrFrom && h <= this.arrTo;
      });
    }

    // Sort
    switch (this.sortMode) {
      case 'price_low': list.sort((a, b) => a.price - b.price); break;
      case 'dep_early': list.sort((a, b) => a.departureTime.localeCompare(b.departureTime)); break;
      case 'dep_late':  list.sort((a, b) => b.departureTime.localeCompare(a.departureTime)); break;
      case 'arr_early': list.sort((a, b) => a.arrivalTime.localeCompare(b.arrivalTime)); break;
      case 'arr_late':  list.sort((a, b) => b.arrivalTime.localeCompare(a.arrivalTime)); break;
      case 'dur_short': list.sort((a, b) =>
        this.parseDurationMin(a.duration) - this.parseDurationMin(b.duration)); break;
    }
    return list;
  }

  airlineName(code: string): string {
    const map: Record<string, string> = {
      GA: 'Garuda Indonesia', QG: 'Citilink', JT: 'Lion Air',
      ID: 'Batik Air', IU: 'Super Air Jet', IN: 'Nam Air',
      SJ: 'Sriwijaya Air', IL: 'Trigana Air', BI: 'Royal Brunei',
      SQ: 'Singapore Airlines', MI: 'SilkAir', TZ: 'Scoot',
      '8B': 'TransNusa', TR: 'Scoot', MH: 'Malaysia Airlines',
      AK: 'AirAsia', QZ: 'AirAsia Indonesia', OD: 'Batik Air Malaysia',
      D7: 'AirAsia X', XT: 'Indonesia AirAsia X', KD: 'KalStar Aviation',
      // Timur Tengah / Eropa / Global
      GF: 'Gulf Air', TK: 'Turkish Airlines', EK: 'Emirates',
      QR: 'Qatar Airways', EY: 'Etihad Airways', SV: 'Saudia',
      LH: 'Lufthansa', KL: 'KLM', AF: 'Air France', BA: 'British Airways',
      // Asia Timur
      CX: 'Cathay Pacific', KE: 'Korean Air', OZ: 'Asiana Airlines',
      JL: 'Japan Airlines', NH: 'All Nippon Airways', BR: 'EVA Air',
      CI: 'China Airlines', CA: 'Air China', CZ: 'China Southern',
      MU: 'China Eastern', TG: 'Thai Airways', PG: 'Bangkok Airways',
      VN: 'Vietnam Airlines', PR: 'Philippine Airlines', UL: 'SriLankan',
    };
    return map[code] ?? 'Penerbangan ' + code;
  }

  airlineLogoUrl(code: string): string {
    // CDN publik kiwi.com — resolusi HD 128px
    return `https://images.kiwi.com/airlines/128/${code}.png`;
  }

  onLogoError(event: Event, code: string): void {
    const img = event.target as HTMLImageElement;
    // Fallback 1: coba versi 64px
    if (img.src.includes('/128/')) {
      img.src = `https://images.kiwi.com/airlines/64/${code}.png`;
      return;
    }
    // Fallback 2: SVG dengan initial + warna brand
    const initial = this.airlineInitial(code);
    const color   = this.airlineColor(code).replace('#', '%23');
    img.src = `data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'><circle cx='32' cy='32' r='32' fill='${color}'/><text x='50%' y='54%' text-anchor='middle' font-family='Arial' font-size='24' font-weight='900' fill='white'>${initial}</text></svg>`;
  }

  airlineInitial(code: string): string {
    const name = this.airlineName(code);
    if (name.startsWith('Penerbangan')) return code.substring(0, 2);
    const parts = name.split(' ');
    return (parts[0][0] + (parts[1]?.[0] ?? '')).toUpperCase();
  }

  airlineColor(code: string): string {
    const map: Record<string, string> = {
      GA: '#0a3d8f', QG: '#00a651', JT: '#c8102e',
      ID: '#0057a8', IU: '#7d3cff', SJ: '#e30613',
      IN: '#0057a8', AK: '#e10600', QZ: '#e10600',
      OD: '#0057a8', SQ: '#f8b400', MH: '#006dc7',
      '8B': '#00a1e0',
    };
    return map[code] ?? '#1E9BF0';
  }

  aircraftModel(code: string): string {
    const map: Record<string, string> = {
      GA: 'Boeing 737-800', QG: 'Airbus A320',   JT: 'Boeing 737-900ER',
      ID: 'Airbus A320',   IU: 'Boeing 737-800', SJ: 'Boeing 737-500',
      IN: 'ATR 72-600',    AK: 'Airbus A320',    QZ: 'Airbus A320neo',
      OD: 'Boeing 737-800',SQ: 'Boeing 787-10',  MH: 'Boeing 737-800',
      '8B': 'ATR 72-600',
      // Long-haul internasional
      GF: 'Boeing 787-9',  TK: 'Airbus A350-900',EK: 'Airbus A380-800',
      QR: 'Boeing 777-300ER', EY: 'Boeing 787-9', SV: 'Boeing 777-300ER',
      LH: 'Airbus A350-900', KL: 'Boeing 787-10', AF: 'Boeing 777-300ER',
      BA: 'Boeing 787-9',
      CX: 'Airbus A350-1000', KE: 'Boeing 777-300ER', OZ: 'Airbus A350-900',
      JL: 'Boeing 787-9',  NH: 'Boeing 787-9',  BR: 'Boeing 787-10',
      CI: 'Airbus A350-900', CA: 'Boeing 787-9', CZ: 'Airbus A330-300',
      MU: 'Airbus A330-300', TG: 'Boeing 777-300ER', PG: 'Airbus A320',
      VN: 'Airbus A350-900', PR: 'Airbus A330-300', UL: 'Airbus A330-300',
    };
    return map[code] ?? 'Pesawat Komersial';
  }

  private readonly AIRPORTS: Record<string, { name: string; city: string }> = {
    // ── Indonesia ─────────────────────────────────────────────────────────
    CGK: { name: 'Soekarno-Hatta Intl',            city: 'Jakarta' },
    HLP: { name: 'Halim Perdanakusuma',             city: 'Jakarta' },
    DPS: { name: 'Ngurah Rai Intl (Bali)',           city: 'Denpasar - Bali' },
    SUB: { name: 'Juanda Intl',                     city: 'Surabaya' },
    UPG: { name: 'Sultan Hasanuddin Intl',          city: 'Makassar' },
    MDC: { name: 'Sam Ratulangi Intl',              city: 'Manado' },
    KNO: { name: 'Kualanamu Intl',                  city: 'Medan' },
    BPN: { name: 'Sultan Aji Muhammad Sulaiman',    city: 'Balikpapan' },
    PLM: { name: 'Sultan Mahmud Badaruddin II',     city: 'Palembang' },
    JOG: { name: 'Yogyakarta Intl (YIA)',           city: 'Yogyakarta' },
    SRG: { name: 'Ahmad Yani Intl',                 city: 'Semarang' },
    PNK: { name: 'Supadio Intl',                    city: 'Pontianak' },
    BDJ: { name: 'Syamsudin Noor Intl',             city: 'Banjarmasin' },
    BTH: { name: 'Hang Nadim Intl',                 city: 'Batam' },
    BTJ: { name: 'Sultan Iskandar Muda Intl',       city: 'Banda Aceh' },
    PDG: { name: 'Minangkabau Intl',                city: 'Padang' },
    MES: { name: 'Soewondo Air Force Base',         city: 'Medan' },
    DJJ: { name: 'Sentani Intl',                    city: 'Jayapura' },
    AMQ: { name: 'Pattimura Intl',                  city: 'Ambon' },
    KDI: { name: 'Haluoleo Intl',                   city: 'Kendari' },
    PLW: { name: 'Mutiara SIS Al-Jufrie',           city: 'Palu' },
    LOP: { name: 'Lombok Intl',                     city: 'Lombok' },
    TIM: { name: 'Moses Kilangin Intl',             city: 'Timika' },
    SOC: { name: 'Adisumarmo Intl',                 city: 'Solo' },
    SRI: { name: 'Temindung',                       city: 'Samarinda' },
    KOE: { name: 'El Tari Intl',                    city: 'Kupang' },
    MOF: { name: 'Frans Sales Lega',                city: 'Maumere' },
    TKG: { name: 'Raden Inten II Intl',             city: 'Bandar Lampung' },
    PGK: { name: 'Depati Amir',                     city: 'Pangkal Pinang' },
    TJQ: { name: 'H.A.S. Hanandjoeddin',            city: 'Tanjung Pandan' },
    GNS: { name: 'Binaka',                          city: 'Gunungsitoli' },
    BKS: { name: 'Fatmawati Soekarno',              city: 'Bengkulu' },
    MLG: { name: 'Abdul Rachman Saleh',             city: 'Malang' },
    TRK: { name: 'Juwata Intl',                     city: 'Tarakan' },
    TTE: { name: 'Sultan Babullah Intl',            city: 'Ternate' },
    LUW: { name: 'Syukuran Aminuddin Amir',         city: 'Luwuk' },
    MKQ: { name: 'Mopah Intl',                      city: 'Merauke' },
    BIK: { name: 'Frans Kaisiepo Intl',             city: 'Biak' },
    FKQ: { name: 'Fakfak Torea',                    city: 'Fakfak' },
    NBX: { name: 'Nabire',                          city: 'Nabire' },
    LBJ: { name: 'Komodo Intl',                     city: 'Labuan Bajo' },
    WMX: { name: 'Wamena',                          city: 'Wamena' },
    // ── ASEAN ─────────────────────────────────────────────────────────────
    SIN: { name: 'Changi Intl',                     city: 'Singapura' },
    KUL: { name: 'Kuala Lumpur Intl (KLIA)',        city: 'Kuala Lumpur' },
    SZB: { name: 'Sultan Abdul Aziz Shah',          city: 'Kuala Lumpur' },
    BKK: { name: 'Suvarnabhumi Intl',               city: 'Bangkok' },
    DMK: { name: 'Don Mueang Intl',                 city: 'Bangkok' },
    HDY: { name: 'Hat Yai Intl',                    city: 'Hat Yai' },
    CNX: { name: 'Chiang Mai Intl',                 city: 'Chiang Mai' },
    HKT: { name: 'Phuket Intl',                     city: 'Phuket' },
    MNL: { name: 'Ninoy Aquino Intl',               city: 'Manila' },
    CEB: { name: 'Mactan-Cebu Intl',               city: 'Cebu' },
    SGN: { name: 'Tan Son Nhat Intl',               city: 'Ho Chi Minh City' },
    HAN: { name: 'Noi Bai Intl',                    city: 'Hanoi' },
    DAD: { name: 'Da Nang Intl',                    city: 'Da Nang' },
    RGN: { name: 'Yangon Intl',                     city: 'Yangon' },
    PNH: { name: 'Phnom Penh Intl',                 city: 'Phnom Penh' },
    VTE: { name: 'Wattay Intl',                     city: 'Vientiane' },
    BWN: { name: 'Brunei Intl',                     city: 'Bandar Seri Begawan' },
    // ── Asia Selatan ──────────────────────────────────────────────────────
    DEL: { name: 'Indira Gandhi Intl',              city: 'New Delhi' },
    BOM: { name: 'Chhatrapati Shivaji Maharaj Intl', city: 'Mumbai' },
    MAA: { name: 'Chennai Intl',                    city: 'Chennai' },
    BLR: { name: 'Kempegowda Intl',                 city: 'Bangalore' },
    HYD: { name: 'Rajiv Gandhi Intl',               city: 'Hyderabad' },
    CCU: { name: 'Netaji Subhas Chandra Bose Intl', city: 'Kolkata' },
    COK: { name: 'Cochin Intl',                     city: 'Kochi' },
    CMB: { name: 'Bandaranaike Intl',               city: 'Colombo' },
    DAC: { name: 'Hazrat Shahjalal Intl',           city: 'Dhaka' },
    KTM: { name: 'Tribhuvan Intl',                  city: 'Kathmandu' },
    // ── Asia Timur ────────────────────────────────────────────────────────
    HKG: { name: 'Hong Kong Intl',                  city: 'Hong Kong' },
    NRT: { name: 'Narita Intl',                     city: 'Tokyo' },
    HND: { name: 'Haneda Intl',                     city: 'Tokyo' },
    KIX: { name: 'Kansai Intl',                     city: 'Osaka' },
    ITM: { name: 'Itami',                            city: 'Osaka' },
    NGO: { name: 'Chubu Centrair Intl',             city: 'Nagoya' },
    CTS: { name: 'New Chitose',                     city: 'Sapporo' },
    ICN: { name: 'Incheon Intl',                    city: 'Seoul' },
    GMP: { name: 'Gimpo Intl',                      city: 'Seoul' },
    PEK: { name: 'Beijing Capital Intl',            city: 'Beijing' },
    PKX: { name: 'Beijing Daxing Intl',             city: 'Beijing' },
    PVG: { name: 'Pudong Intl',                     city: 'Shanghai' },
    SHA: { name: 'Hongqiao Intl',                   city: 'Shanghai' },
    CAN: { name: 'Baiyun Intl',                     city: 'Guangzhou' },
    SZX: { name: 'Bao\'an Intl',                   city: 'Shenzhen' },
    CTU: { name: 'Tianfu Intl',                     city: 'Chengdu' },
    XIY: { name: 'Xianyang Intl',                   city: "Xi'an" },
    WUH: { name: 'Tianhe Intl',                     city: 'Wuhan' },
    KMG: { name: 'Changshui Intl',                  city: 'Kunming' },
    TPE: { name: 'Taoyuan Intl',                    city: 'Taipei' },
    TSA: { name: 'Songshan',                        city: 'Taipei' },
    MFM: { name: 'Macau Intl',                      city: 'Macau' },
    // ── Timur Tengah ──────────────────────────────────────────────────────
    DXB: { name: 'Dubai Intl',                      city: 'Dubai' },
    AUH: { name: 'Abu Dhabi Intl',                  city: 'Abu Dhabi' },
    SHJ: { name: 'Sharjah Intl',                    city: 'Sharjah' },
    DOH: { name: 'Hamad Intl',                      city: 'Doha' },
    BAH: { name: 'Bahrain Intl',                    city: 'Manama' },
    KWI: { name: 'Kuwait Intl',                     city: 'Kuwait City' },
    MCT: { name: 'Muscat Intl',                     city: 'Muscat' },
    RUH: { name: 'King Khalid Intl',                city: 'Riyadh' },
    JED: { name: 'King Abdulaziz Intl',             city: 'Jeddah' },
    MED: { name: 'Prince Mohammad Bin Abdulaziz',   city: 'Madinah' },
    AMM: { name: 'Queen Alia Intl',                 city: 'Amman' },
    BEY: { name: 'Rafic Hariri Intl',               city: 'Beirut' },
    CAI: { name: 'Cairo Intl',                      city: 'Kairo' },
    // ── Turki ─────────────────────────────────────────────────────────────
    IST: { name: 'Istanbul Airport',                city: 'Istanbul' },
    SAW: { name: 'Istanbul Sabiha Gökçen',          city: 'Istanbul' },
    AYT: { name: 'Antalya Intl',                    city: 'Antalya' },
    ADB: { name: 'Izmir Adnan Menderes Intl',       city: 'Izmir' },
    // ── Eropa ─────────────────────────────────────────────────────────────
    LHR: { name: 'Heathrow',                        city: 'London' },
    LGW: { name: 'Gatwick',                         city: 'London' },
    STN: { name: 'Stansted',                        city: 'London' },
    CDG: { name: 'Charles de Gaulle',               city: 'Paris' },
    ORY: { name: 'Orly',                            city: 'Paris' },
    AMS: { name: 'Schiphol',                        city: 'Amsterdam' },
    FRA: { name: 'Frankfurt Intl',                  city: 'Frankfurt' },
    MUC: { name: 'Munich Intl',                     city: 'Munich' },
    ZRH: { name: 'Zürich Intl',                     city: 'Zürich' },
    VIE: { name: 'Vienna Intl',                     city: 'Vienna' },
    BRU: { name: 'Brussels Intl',                   city: 'Brussels' },
    FCO: { name: 'Leonardo da Vinci Intl',          city: 'Roma' },
    MXP: { name: 'Malpensa Intl',                   city: 'Milan' },
    MAD: { name: 'Barajas Intl',                    city: 'Madrid' },
    BCN: { name: 'Barcelona–El Prat',               city: 'Barcelona' },
    LIS: { name: 'Humberto Delgado Intl',           city: 'Lisbon' },
    ARN: { name: 'Stockholm Arlanda',               city: 'Stockholm' },
    CPH: { name: 'Copenhagen Intl',                 city: 'Kopenhagen' },
    OSL: { name: 'Oslo Gardermoen Intl',            city: 'Oslo' },
    HEL: { name: 'Helsinki-Vantaa Intl',            city: 'Helsinki' },
    DUB: { name: 'Dublin Intl',                     city: 'Dublin' },
    ATH: { name: 'Eleftherios Venizelos Intl',      city: 'Athena' },
    WAW: { name: 'Chopin Intl',                     city: 'Warsawa' },
    PRG: { name: 'Václav Havel Intl',               city: 'Praha' },
    BUD: { name: 'Budapest Ferenc Liszt Intl',      city: 'Budapest' },
    SVO: { name: 'Sheremetyevo Intl',               city: 'Moskow' },
    DME: { name: 'Domodedovo Intl',                 city: 'Moskow' },
    // ── Afrika ────────────────────────────────────────────────────────────
    JNB: { name: 'O.R. Tambo Intl',                city: 'Johannesburg' },
    CPT: { name: 'Cape Town Intl',                  city: 'Cape Town' },
    NBO: { name: 'Jomo Kenyatta Intl',              city: 'Nairobi' },
    ADD: { name: 'Addis Ababa Bole Intl',           city: 'Addis Ababa' },
    LOS: { name: 'Murtala Muhammed Intl',           city: 'Lagos' },
    CMN: { name: 'Mohammed V Intl',                 city: 'Casablanca' },
    // ── Australia & Pasifik ───────────────────────────────────────────────
    SYD: { name: 'Kingsford Smith Intl',            city: 'Sydney' },
    MEL: { name: 'Melbourne Tullamarine Intl',      city: 'Melbourne' },
    BNE: { name: 'Brisbane Intl',                   city: 'Brisbane' },
    PER: { name: 'Perth Intl',                      city: 'Perth' },
    ADL: { name: 'Adelaide Intl',                   city: 'Adelaide' },
    DRW: { name: 'Darwin Intl',                     city: 'Darwin' },
    AKL: { name: 'Auckland Intl',                   city: 'Auckland' },
    CHC: { name: 'Christchurch Intl',               city: 'Christchurch' },
    NAN: { name: 'Nadi Intl',                       city: 'Nadi' },
    GUM: { name: 'A.B. Won Pat Intl',               city: 'Guam' },
    // ── Amerika Utara ─────────────────────────────────────────────────────
    JFK: { name: 'John F. Kennedy Intl',            city: 'New York' },
    EWR: { name: 'Newark Liberty Intl',             city: 'New York' },
    LGA: { name: 'LaGuardia',                       city: 'New York' },
    LAX: { name: 'Los Angeles Intl',                city: 'Los Angeles' },
    SFO: { name: 'San Francisco Intl',              city: 'San Francisco' },
    ORD: { name: "O'Hare Intl",                     city: 'Chicago' },
    ATL: { name: 'Hartsfield-Jackson Intl',         city: 'Atlanta' },
    DFW: { name: 'Dallas/Fort Worth Intl',          city: 'Dallas' },
    DEN: { name: 'Denver Intl',                     city: 'Denver' },
    SEA: { name: 'Seattle-Tacoma Intl',             city: 'Seattle' },
    MIA: { name: 'Miami Intl',                      city: 'Miami' },
    BOS: { name: 'Logan Intl',                      city: 'Boston' },
    IAD: { name: 'Dulles Intl',                     city: 'Washington D.C.' },
    DCA: { name: 'Ronald Reagan Washington Natl',   city: 'Washington D.C.' },
    LAS: { name: 'Harry Reid Intl',                 city: 'Las Vegas' },
    HNL: { name: 'Daniel K. Inouye Intl',           city: 'Honolulu' },
    YYZ: { name: 'Toronto Pearson Intl',            city: 'Toronto' },
    YVR: { name: 'Vancouver Intl',                  city: 'Vancouver' },
    YUL: { name: 'Montréal-Trudeau Intl',           city: 'Montréal' },
    MEX: { name: 'Benito Juárez Intl',              city: 'Mexico City' },
    // ── Amerika Selatan ───────────────────────────────────────────────────
    GRU: { name: 'São Paulo/Guarulhos Intl',        city: 'São Paulo' },
    EZE: { name: 'Ministro Pistarini Intl',         city: 'Buenos Aires' },
    BOG: { name: 'El Dorado Intl',                  city: 'Bogota' },
    LIM: { name: 'Jorge Chávez Intl',               city: 'Lima' },
    SCL: { name: 'Arturo Merino Benítez Intl',      city: 'Santiago' },
  };

  airportName(code: string): string {
    return this.AIRPORTS[code]?.name ?? 'Bandara ' + code;
  }

  airportLabel(code: string): string {
    const a = this.AIRPORTS[code];
    if (!a) return 'Bandara ' + code;
    return `${code} - ${a.name}`;
  }

  airportCity(code: string): string {
    return this.AIRPORTS[code]?.city ?? code;
  }

  transitArrivalTime(f: FlightResult): string {
    // Data segmen asli dulu
    if (f.segments && f.segments.length >= 2 && f.segments[0].arriving_at) {
      return f.segments[0].arriving_at.substring(11, 16);
    }
    const totalMin = this.parseDurationMin(f.duration);
    const waitMin  = this.parseDurationMin(this.transitWait(f));
    const leg1Min  = Math.round((totalMin - waitMin) * 0.55);
    return this.addMinutes(f.departureTime, leg1Min);
  }

  transitDepartureTime(f: FlightResult): string {
    if (f.segments && f.segments.length >= 2 && f.segments[1].departing_at) {
      return f.segments[1].departing_at.substring(11, 16);
    }
    const arr = this.transitArrivalTime(f);
    const waitMin = this.parseDurationMin(this.transitWait(f));
    return this.addMinutes(arr, waitMin);
  }

  secondAirlineCode(f: FlightResult): string {
    if (f.segments && f.segments.length >= 2 && f.segments[1].airline) {
      return f.segments[1].airline;
    }
    return f.airline;
  }

  secondFlightNumber(f: FlightResult): string {
    if (f.segments && f.segments.length >= 2 && f.segments[1].flight_number) {
      return this.secondAirlineCode(f) + f.segments[1].flight_number;
    }
    const code = this.secondAirlineCode(f);
    const hash = f.flightNumber.split('').reduce((s, c) => s + c.charCodeAt(0), 0);
    return code + (1000 + (hash % 8999));
  }

  private parseDurationMin(dur: string): number {
    const h = /(\d+)j/.exec(dur);
    const m = /(\d+)m/.exec(dur);
    return (h ? +h[1] : 0) * 60 + (m ? +m[1] : 0);
  }

  private addMinutes(hhmm: string, min: number): string {
    const [h, m] = hhmm.split(':').map(Number);
    const total = (h * 60 + m + min) % (24 * 60);
    const nh = Math.floor(total / 60).toString().padStart(2, '0');
    const nm = (total % 60).toString().padStart(2, '0');
    return `${nh}:${nm}`;
  }

  transitAirport(f: FlightResult): string {
    // Pakai data segmen asli dulu (Duffel) — jauh lebih akurat dari tebak hub
    if (f.segments && f.segments.length >= 2) {
      return f.segments[0].destination;
    }
    // Pilih hub transit yang MASUK AKAL berdasarkan geografi rute
    const domesticID = ['CGK','HLP','SUB','DPS','UPG','MDC','KNO','BPN','JOG','SRG','PNK','BDJ','PLM'];
    const originIsID = domesticID.includes(f.origin);
    const destIsID   = domesticID.includes(f.destination);

    let hubs: string[];
    if (originIsID && destIsID) {
      // Domestik Indonesia: hub domestik utama saja
      hubs = ['CGK', 'DPS', 'SUB', 'UPG'];
    } else if (destIsID || originIsID) {
      // Internasional ↔ Indonesia: hub transit internasional yang realistis
      // (KUL, SIN, DOH, HKG untuk Asia; jangan pakai bandara domestik ID sebagai transit)
      hubs = ['KUL', 'SIN', 'DOH', 'DXB', 'HKG', 'BKK'];
    } else {
      // Internasional ↔ Internasional: hub global besar
      hubs = ['DXB', 'DOH', 'SIN', 'HKG', 'IST'];
    }

    const candidates = hubs.filter(h => h !== f.origin && h !== f.destination);
    if (candidates.length === 0) return hubs[0];
    const hash = f.flightNumber.split('').reduce((s, c) => s + c.charCodeAt(0), 0);
    return candidates[hash % candidates.length];
  }

  isLongTransit(f: FlightResult): boolean {
    return this.parseDurationMin(this.transitWait(f)) >= 180;
  }

  /**
   * Timeline model dengan posisi proporsional (px) berdasarkan waktu aktual.
   * Semua event dipetakan ke sumbu vertikal: 0px = keberangkatan awal,
   * height = kedatangan akhir. Titik tengah (transit) diposisikan tepat
   * pada menit ke-N sejak keberangkatan.
   */
  detailTimeline(f: FlightResult): {
    height: number;
    hasTransit: boolean;
    nodes: { top: number; time: string; type: string }[];
    transitBox: { top: number; height: number } | null;
  } {
    // FIXED LAYOUT — tinggi tetap tanpa peduli lama transit. Alasan:
    // layover 9j vs 1j menghasilkan proporsi visual yang bikin transit box
    // menutupi node destinasi. UX lebih baik dengan ukuran konsisten.

    if (f.transitCount === 0) {
      return {
        height: 120,
        hasTransit: false,
        nodes: [
          { top: 0,   time: f.departureTime, type: 'depart' },
          { top: 100, time: f.arrivalTime,   type: 'arrive' },
        ],
        transitBox: null,
      };
    }

    // Transit — fixed height 190px total, compact transit box
    const height   = 190;
    const arriveY  = 65;    // transit arrive
    const departY  = 125;   // transit depart (jarak 60px untuk box)

    return {
      height,
      hasTransit: true,
      nodes: [
        { top: 0,       time: f.departureTime,           type: 'depart' },
        { top: arriveY, time: this.transitArrivalTime(f),  type: 'transit-arrive' },
        { top: departY, time: this.transitDepartureTime(f), type: 'transit-depart' },
        { top: height,  time: f.arrivalTime,             type: 'arrive' },
      ],
      transitBox: {
        top:    arriveY,
        height: departY - arriveY,
      },
    };
  }

  transitWait(f: FlightResult): string {
    // Kalau ada segmen asli, hitung selisih arriving_at leg-1 ↔ departing_at leg-2
    if (f.segments && f.segments.length >= 2
        && f.segments[0].arriving_at && f.segments[1].departing_at) {
      const arr = new Date(f.segments[0].arriving_at).getTime();
      const dep = new Date(f.segments[1].departing_at).getTime();
      const min = Math.max(Math.round((dep - arr) / 60000), 0);
      const h = Math.floor(min / 60);
      const m = min % 60;
      return h > 0 ? `${h}j ${m}m` : `${m}m`;
    }
    // Fallback deterministic
    const hash = f.flightNumber.split('').reduce((s, c) => s + c.charCodeAt(0), 0);
    const totalMin = 75 + (hash % 136);
    const h = Math.floor(totalMin / 60);
    const m = totalMin % 60;
    return h > 0 ? `${h}j ${m}m` : `${m}m`;
  }

  baggageKg(code: string): number {
    const map: Record<string, number> = {
      GA: 20, QG: 15, JT: 10, ID: 20, IU: 7,  SJ: 15,
      IN: 15, AK: 7,  QZ: 7,  OD: 20, SQ: 30, MH: 30, '8B': 10,
    };
    return map[code] ?? 10;
  }

  tagLabel(i: number): string {
    return i === 0 ? 'Harga Terbaik' : i % 3 === 1 ? 'Populer' : 'Tersedia';
  }

  goBack(): void {
    this.router.navigate(['/']);
  }

  openEditModal(): void {
    this.editOrigin = this.origin;
    this.editDestination = this.destination;
    this.editOriginName = this.originName;
    this.editDestinationName = this.destinationName;
    this.editDate = this.departureDate;
    this.editPassengers = this.totalPassengers;
    this.editSeatClass = this.seatClass;
    this.editRoundTrip = !!this.returnDate;
    this.editReturnDate = this.returnDate ?? '';
    this.editOriginQuery = '';
    this.editDestQuery = '';
    this.editOriginResults = [];
    this.editDestResults = [];
    this.showEditModal = true;
  }

  closeEditModal(): void {
    this.showEditModal = false;
  }

  swapEditCities(): void {
    [this.editOrigin, this.editDestination] = [this.editDestination, this.editOrigin];
    [this.editOriginName, this.editDestinationName] = [this.editDestinationName, this.editOriginName];
  }

  onEditOriginInput(query: string): void {
    this.editOriginQuery = query;
    if (query.length < 2) { this.editOriginResults = []; return; }
    this.searchService.searchAirports(query).subscribe(r => this.editOriginResults = r);
  }

  onEditDestInput(query: string): void {
    this.editDestQuery = query;
    if (query.length < 2) { this.editDestResults = []; return; }
    this.searchService.searchAirports(query).subscribe(r => this.editDestResults = r);
  }

  selectEditOrigin(ap: { code: string; name: string; city: string }): void {
    this.editOrigin = ap.code;
    this.editOriginName = ap.city + ' ' + ap.code;
    this.editOriginQuery = '';
    this.editOriginResults = [];
  }

  selectEditDest(ap: { code: string; name: string; city: string }): void {
    this.editDestination = ap.code;
    this.editDestinationName = ap.city + ' ' + ap.code;
    this.editDestQuery = '';
    this.editDestResults = [];
  }

  submitEditSearch(): void {
    this.showEditModal = false;
    this.router.navigate(['/flights/results'], {
      queryParams: {
        origin: this.editOrigin,
        destination: this.editDestination,
        departure_date: this.editDate,
        adults: this.editPassengers,
        seat_class: this.editSeatClass,
        originName: this.editOriginName,
        destinationName: this.editDestinationName,
        ...(this.editRoundTrip && this.editReturnDate ? { return_date: this.editReturnDate } : {}),
      }
    }).then(() => {
      this.origin = this.editOrigin;
      this.destination = this.editDestination;
      this.originName = this.editOriginName;
      this.destinationName = this.editDestinationName;
      this.departureDate = this.editDate;
      this.seatClass = this.editSeatClass;
      this.adults = this.editPassengers;
      this.returnDate = this.editRoundTrip ? this.editReturnDate : undefined;
      this.flights = [];
      this.nearbyDates = [];
      this.buildNearbyDates();
      this.loadFlights();
    });
  }
}
