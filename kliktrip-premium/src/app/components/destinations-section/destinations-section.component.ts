import { Component, Output, EventEmitter, OnInit, AfterViewInit, HostListener } from '@angular/core';
import { CommonModule as NgCommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { DestinationCardComponent } from '../destination-card/destination-card.component';
import { SAFARIA_PACKAGES, SafariaPackage } from '../../data/safaria-packages.data';
import { TravelService } from '../../services/travel.service';

export interface Destination {
  name: string;
  country: string;
  price: string;
  image?: string;
  gradient?: string;
  logo?: string;
  emoji?: string;
  badge?: string;
  rating: number;
  tagline: string;
  duration: string;
  reviews: number;
  // Extended fields for Safaria packages
  id?: string;
  kategori?: string;
  harga_numerik?: number;
  kuota_total?: number;
  kuota_saat_ini?: number;
  isSafaria?: boolean;
}

@Component({
  selector: 'app-destinations-section',
  standalone: true,
  imports: [NgCommonModule, FormsModule, DestinationCardComponent],
  templateUrl: './destinations-section.component.html',
  styleUrl: './destinations-section.component.css'
})
export class DestinationsSectionComponent implements OnInit, AfterViewInit {
  /** Relays "Lihat Paket" clicks from the cards up to AppComponent. */
  @Output() selectDestination = new EventEmitter<Destination>();

  // ── Original 5 destinations (kept at top) ─────────────────
  private originalDestinations: Destination[] = [
    {
      name: 'Manado',
      country: 'Indonesia',
      image: 'assets/dest-manado.png',
      price: 'Rp 1.250.000',
      rating: 4.8,
      tagline: 'Snorkeling di terumbu karang Bunaken yang memukau.',
      duration: '4 Hari 3 Malam',
      reviews: 145,
      badge: 'Terpopuler',
      kategori: 'DOMESTIK',
      isSafaria: false
    },
    {
      name: 'Kotamobagu',
      country: 'Indonesia',
      image: 'assets/dest-kotamobagu.png',
      price: 'Rp 850.000',
      rating: 4.5,
      tagline: 'Udaranya sejuk dengan pemandangan pegunungan hijau.',
      duration: '3 Hari 2 Malam',
      reviews: 68,
      badge: 'Wisata Alam',
      kategori: 'DOMESTIK',
      isSafaria: false
    },
    {
      name: 'Gorontalo',
      country: 'Indonesia',
      image: 'assets/dest-gorontalo.png',
      price: 'Rp 1.500.000',
      rating: 4.7,
      tagline: 'Berenang bersama Hiu Paus raksasa yang ramah.',
      duration: '4 Hari 3 Malam',
      reviews: 112,
      badge: 'Eksotis',
      kategori: 'DOMESTIK',
      isSafaria: false
    },
    {
      name: 'Makassar',
      country: 'Indonesia',
      image: 'assets/dest-makassar.png',
      price: 'Rp 1.350.000',
      rating: 4.7,
      tagline: 'Pantai Losari dan petualangan kuliner legendaris.',
      duration: '3 Hari 2 Malam',
      reviews: 230,
      kategori: 'DOMESTIK',
      isSafaria: false
    },
    {
      name: 'Kendari',
      country: 'Indonesia',
      image: 'assets/dest-kendari.png',
      price: 'Rp 1.450.000',
      rating: 4.6,
      tagline: 'Keindahan teluk Kendari dan pulau Wakatobi.',
      duration: '4 Hari 3 Malam',
      reviews: 85,
      kategori: 'DOMESTIK',
      isSafaria: false
    }
  ];

  // ── Convert Safaria packages to Destination format ─────────
  private safariaDestinations: Destination[] = SAFARIA_PACKAGES.map(pkg => this.toDestination(pkg));

  // ── Merged all destinations ────────────────────────────────
  allDestinations: Destination[] = [...this.originalDestinations, ...this.safariaDestinations];

  // ── Filters & Search ───────────────────────────────────────
  filters = ['Semua', 'Ibadah', 'Internasional', 'Domestik', 'Event'];
  activeFilter = 'Semua';
  searchQuery = '';
  animating = false;

  // ── Sort ───────────────────────────────────────────────────
  sortOptions = [
    { label: 'Terbaru', value: 'newest' },
    { label: 'Harga Terendah', value: 'price-asc' },
    { label: 'Harga Tertinggi', value: 'price-desc' },
    { label: 'Rating Tertinggi', value: 'rating' },
  ];
  activeSort = 'newest';
  isSortOpen = false;

  get activeSortLabel(): string {
    return this.sortOptions.find(o => o.value === this.activeSort)?.label || 'Terbaru';
  }

  toggleSortDropdown(event: MouseEvent) {
    event.stopPropagation();
    this.isSortOpen = !this.isSortOpen;
  }

  selectSortOption(val: string) {
    this.setSort(val);
    this.isSortOpen = false;
  }

  @HostListener('document:click')
  onDocumentClick() {
    this.isSortOpen = false;
  }

  @HostListener('window:selectCategoryFilter', ['$event'])
  onCategoryFilterEvent(event: any) {
    if (event && event.detail) {
      this.setFilter(event.detail);
    }
  }

  // ── Pagination ─────────────────────────────────────────────
  itemsPerPage = 12;
  currentPage = 1;

  // ── Mobile Load More State ──────────────────────────────
  mobileLimit = 15;

  loadMoreMobile() {
    this.mobileLimit += 15;
  }

  get mobileFiltered(): Destination[] {
    return this.filteredAll.slice(0, this.mobileLimit);
  }

  get hasMoreMobile(): boolean {
    return this.mobileLimit < this.filteredAll.length;
  }

  /** Filtered + searched + sorted results */
  get filteredAll(): Destination[] {
    let results = this.allDestinations;

    // Category filter
    if (this.activeFilter !== 'Semua') {
      results = results.filter(d => d.kategori?.toUpperCase() === this.activeFilter.toUpperCase());
    }

    // Search filter
    if (this.searchQuery.trim()) {
      const q = this.searchQuery.toLowerCase().trim();
      results = results.filter(d =>
        d.name.toLowerCase().includes(q) ||
        d.country.toLowerCase().includes(q) ||
        d.tagline.toLowerCase().includes(q) ||
        (d.badge && d.badge.toLowerCase().includes(q))
      );
    }

    // Sort
    switch (this.activeSort) {
      case 'price-asc':
        results = [...results].sort((a, b) => (a.harga_numerik ?? 0) - (b.harga_numerik ?? 0));
        break;
      case 'price-desc':
        results = [...results].sort((a, b) => (b.harga_numerik ?? 0) - (a.harga_numerik ?? 0));
        break;
      case 'rating':
        results = [...results].sort((a, b) => b.rating - a.rating);
        break;
      default: // 'newest' — keep original order
        break;
    }

    return results;
  }

  /** Paginated results for current page */
  get filtered(): Destination[] {
    const start = (this.currentPage - 1) * this.itemsPerPage;
    return this.filteredAll.slice(start, start + this.itemsPerPage);
  }

  get totalPages(): number {
    return Math.ceil(this.filteredAll.length / this.itemsPerPage);
  }

  get totalResults(): number {
    return this.filteredAll.length;
  }

  get pageNumbers(): number[] {
    const pages: number[] = [];
    const total = this.totalPages;
    const current = this.currentPage;
    const maxVisible = 5;

    if (total <= maxVisible) {
      for (let i = 1; i <= total; i++) pages.push(i);
    } else {
      pages.push(1);
      let start = Math.max(2, current - 1);
      let end = Math.min(total - 1, current + 1);

      if (current <= 3) { start = 2; end = 4; }
      if (current >= total - 2) { start = total - 3; end = total - 1; }

      if (start > 2) pages.push(-1); // ellipsis
      for (let i = start; i <= end; i++) pages.push(i);
      if (end < total - 1) pages.push(-1); // ellipsis
      pages.push(total);
    }

    return pages;
  }

  /** Category counts */
  getCategoryCount(filter: string): number {
    if (filter === 'Semua') return this.allDestinations.length;
    return this.allDestinations.filter(d => d.kategori?.toUpperCase() === filter.toUpperCase()).length;
  }

  // ── Actions ────────────────────────────────────────────────
  setFilter(filter: string) {
    this.animating = true;
    this.activeFilter = filter;
    this.currentPage = 1;
    this.mobileLimit = 15;
    setTimeout(() => { this.animating = false; }, 200);
  }

  setSort(value: string) {
    this.activeSort = value;
    this.currentPage = 1;
    this.mobileLimit = 15;
  }

  onSearch() {
    this.currentPage = 1;
    this.mobileLimit = 15;
  }

  clearSearch() {
    this.searchQuery = '';
    this.currentPage = 1;
    this.mobileLimit = 15;
  }

  goToPage(page: number) {
    if (page < 1 || page > this.totalPages) return;
    this.animating = true;
    this.currentPage = page;
    setTimeout(() => { this.animating = false; }, 200);
    // Scroll to section top
    const el = document.getElementById('destinations-section');
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  constructor(public travelService: TravelService) {}

  ngOnInit(): void {
    if (this.travelService.lastSelectedPackageName) {
      if (this.travelService.lastSelectedFilter) {
        this.activeFilter = this.travelService.lastSelectedFilter;
      }
      const targetPkg = this.travelService.lastSelectedPackageName;
      const idx = this.filteredAll.findIndex(d => d.name === targetPkg);
      if (idx !== -1) {
        this.currentPage = Math.floor(idx / this.itemsPerPage) + 1;
      } else if (this.travelService.lastSelectedPage) {
        this.currentPage = this.travelService.lastSelectedPage;
      }
    }
  }

  ngAfterViewInit(): void {
    if (this.travelService.isReturningFromDetail) {
      setTimeout(() => {
        this.scrollToSelectedCard();
      }, 150);
    }
  }

  onCardSelect(dest: Destination): void {
    this.travelService.setLastSelectedPackage(dest.name, this.activeFilter, this.currentPage);
    this.selectDestination.emit(dest);
  }

  private scrollToSelectedCard(): void {
    const pkgName = this.travelService.lastSelectedPackageName;
    if (pkgName) {
      const card = document.getElementById('pkg-card-' + pkgName) ||
                   document.querySelector(`[data-pkg-name="${CSS.escape(pkgName)}"]`);
      if (card) {
        card.scrollIntoView({ behavior: 'instant' as ScrollBehavior, block: 'center' });
        card.classList.add('highlight-selected-card');
        setTimeout(() => card.classList.remove('highlight-selected-card'), 2000);
        return;
      }
    }
    const sec = document.getElementById('destinations-section') || document.getElementById('destinations-anchor');
    if (sec) {
      sec.scrollIntoView({ behavior: 'instant' as ScrollBehavior, block: 'start' });
    }
  }

  // ── Helper: Convert SafariaPackage → Destination ───────────
  private toDestination(pkg: SafariaPackage): Destination {
    const badgeMap: Record<string, string> = {
      'IBADAH': 'Ibadah',
      'INTERNASIONAL': 'Internasional',
      'DOMESTIK': 'Domestik',
      'EVENT': 'Event',
    };

    return {
      id: pkg.id,
      name: pkg.nama_paket,
      country: pkg.destinasi,
      price: pkg.harga_display,
      image: pkg.gambar,
      rating: pkg.rating,
      tagline: pkg.deskripsi_singkat,
      duration: pkg.durasi_display,
      reviews: Math.floor(Math.random() * 200) + 20, // simulated reviews
      badge: badgeMap[pkg.kategori] || pkg.kategori,
      kategori: pkg.kategori,
      harga_numerik: pkg.harga,
      kuota_total: pkg.kuota_total,
      kuota_saat_ini: pkg.kuota_saat_ini,
      isSafaria: true
    };
  }
}
