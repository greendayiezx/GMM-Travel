import { Component, OnInit, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { TravelService, PackageBookingState } from '../../services/travel.service';
import { SAFARIA_PACKAGES } from '../../data/safaria-packages.data';

export interface VisitorDetail {
  ticketIndex: number;
  ticketType: string;
  pickupPoint: string;
  fullName: string;
  passportNumber: string;
  dateOfBirth: string;
  passportExpiry: string;
  isPickupOpen?: boolean;
}

export interface KoreaOptionItem {
  id: string;
  title: string;
  category: string;
  price: number;
  priceDisplay: string;
  description: string;
  features?: string[];
  perPax: boolean;
  selected: boolean;
  imageIcon?: string;
}

export interface KoreaOptionCategoryGroup {
  categoryName: string;
  icon: string;
  imageIcon?: string;
  badge?: string;
  items: KoreaOptionItem[];
}

export interface BaggageOption {
  label: string;
  price: number;
}

@Component({
  selector: 'app-package-checkout',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './package-checkout.component.html',
  styleUrl: './package-checkout.component.css'
})
export class PackageCheckoutComponent implements OnInit {
  bookingData: PackageBookingState | null = null;

  // Validation State
  showValidationErrors = false;
  validationErrorMessage = '';

  // Detail Pemesanan Form
  salutation: 'Tuan' | 'Nyonya' | 'Nona' = 'Tuan';
  fullName: string = '';
  phoneCode: string = '+62';
  phoneNumber: string = '';
  email: string = '';
  country: string = 'Indonesia';

  countryCodes = [
    { code: '+62', flag: '🇮🇩', name: '🇮🇩 Indonesia (+62)' },
    { code: '+65', flag: '🇸🇬', name: '🇸🇬 Singapura (+65)' },
    { code: '+60', flag: '🇲🇾', name: '🇲🇾 Malaysia (+60)' },
    { code: '+966', flag: '🇸🇦', name: '🇸🇦 Arab Saudi (+966)' },
    { code: '+81', flag: '🇯🇵', name: '🇯🇵 Jepang (+81)' },
    { code: '+82', flag: '🇰🇷', name: '🇰🇷 Korea Selatan (+82)' },
    { code: '+1', flag: '🇺🇸', name: '🇺🇸 Amerika Serikat (+1)' },
    { code: '+44', flag: '🇬🇧', name: '🇬🇧 Inggris (+44)' },
    { code: '+61', flag: '🇦🇺', name: '🇦🇺 Australia (+61)' },
    { code: '+971', flag: '🇦🇪', name: '🇦🇪 UAE (+971)' },
    { code: '+90', flag: '🇹🇷', name: '🇹🇷 Turki (+90)' },
  ];

  // Detail Pengunjung Form
  visitorList: VisitorDetail[] = [];
  pickupOptions: string[] = [
    'Singapura Center Point',
    'Hotel Lobby Pick-up',
    'Changi Airport Terminal 3',
    'Custom Meeting Point (Konfirmasi via WA)'
  ];

  // Fasilitas Ekstra state
  selectedBaggagePrice = 0;
  selectedBaggageLabel = 'Tambah bagasi ekstra';
  baggageOptions: BaggageOption[] = [
    { label: 'Tidak ada bagasi ekstra', price: 0 },
    { label: 'Tambah Bagasi 10 kg (+ IDR 150.000/pax)', price: 150000 },
    { label: 'Tambah Bagasi 20 kg (+ IDR 280.000/pax)', price: 280000 },
    { label: 'Tambah Bagasi 30 kg (+ IDR 400.000/pax)', price: 400000 }
  ];

  isBaggageOpen = false;
  isPhoneCodeOpen = false;

  @HostListener('document:click')
  onDocumentClick() {
    this.visitorList.forEach(v => v.isPickupOpen = false);
    this.isBaggageOpen = false;
    this.isPhoneCodeOpen = false;
  }

  togglePhoneCodeDropdown(event: MouseEvent) {
    event.stopPropagation();
    this.visitorList.forEach(v => v.isPickupOpen = false);
    this.isBaggageOpen = false;
    this.isPhoneCodeOpen = !this.isPhoneCodeOpen;
  }

  selectPhoneCode(c: { code: string; flag: string; name: string }, event: MouseEvent) {
    event.stopPropagation();
    this.phoneCode = c.code;
    this.isPhoneCodeOpen = false;
  }

  get selectedCountryObj() {
    return this.countryCodes.find(c => c.code === this.phoneCode) || this.countryCodes[0];
  }

  togglePickupDropdown(v: VisitorDetail, event: MouseEvent) {
    event.stopPropagation();
    const currentState = v.isPickupOpen;
    this.visitorList.forEach(item => item.isPickupOpen = false);
    this.isBaggageOpen = false;
    v.isPickupOpen = !currentState;
  }

  selectPickupOption(v: VisitorDetail, opt: string, event: MouseEvent) {
    event.stopPropagation();
    v.pickupPoint = opt;
    v.isPickupOpen = false;
  }

  toggleBaggageDropdown(event: MouseEvent) {
    event.stopPropagation();
    this.visitorList.forEach(item => item.isPickupOpen = false);
    this.isBaggageOpen = !this.isBaggageOpen;
  }

  selectBaggageOption(opt: BaggageOption, event: MouseEvent) {
    event.stopPropagation();
    this.selectedBaggagePrice = opt.price;
    this.selectedBaggageLabel = opt.label;
    this.onBaggageChange(opt);
    this.isBaggageOpen = false;
  }

  // Korea Seoul Specific Recommended Optional Items Groups
  defaultKoreaOptionGroups: KoreaOptionCategoryGroup[] = [
    {
      categoryName: 'Tipping & Gratifikasi Pemandu',
      icon: '',
      imageIcon: 'assets/icon-tipping-gratifikasi-pemandu.svg',
      badge: '',
      items: [
        {
          id: 'tipping_guide',
          category: 'Tipping Pemandu',
          title: 'Tipping Tour Leader + Driver + Local Guide',
          price: 750000,
          priceDisplay: 'IDR 750.000',
          description: 'Dibayar di muka. Tour leader & driver bekerja keras, tipping adalah standar internasional untuk kepuasan & kualitas layanan.',
          features: ['Inklusi Tour Leader', 'Driver Lokal Korea', 'Local English/Indo Guide'],
          perPax: true,
          selected: false,
          imageIcon: 'assets/icon-tipping-gratifikasi-pemandu.svg'
        }
      ]
    },
    {
      categoryName: 'Upgrade Kamar (Single Supplement)',
      icon: '',
      imageIcon: 'assets/icon-upgrade-kamar.svg',
      badge: '',
      items: [
        {
          id: 'single_supp_korea',
          category: 'Single Supplement',
          title: 'Kamar Sendiri (Single Supplement)',
          price: 4000000,
          priceDisplay: 'IDR 4.000.000',
          description: 'Dapatkan 1 kamar hotel sendiri selama perjalanan tur untuk privasi penuh tanpa berbagi kamar.',
          features: ['Private Room 1 Orang', 'Jaminan Kamar Sendiri', 'Kenyamanan Maksimal'],
          perPax: true,
          selected: false,
          imageIcon: 'assets/icon-upgrade-kamar.svg'
        }
      ]
    },
    {
      categoryName: 'Asuransi Perjalanan Extended',
      icon: '',
      badge: '',
      items: [
        {
          id: 'ins_extended',
          category: 'Asuransi Extended',
          title: 'Asuransi Perjalanan Premium (Extended Coverage)',
          price: 500000,
          priceDisplay: 'IDR 500.000',
          description: 'Medical Emergency s.d IDR 500jt + Evakuasi 1jt + Proteksi Keterlambatan + Trip Cancellation Full Refund.',
          features: ['Medical Emergency IDR 500jt', 'Trip Cancellation Full Refund', 'Coverage Tanpa Batas Usia Tua'],
          perPax: true,
          selected: false
        },
        {
          id: 'ins_baggage',
          category: 'Asuransi Bagasi',
          title: 'Asuransi Kehilangan & Kerusakan Bagasi',
          price: 159000,
          priceDisplay: 'IDR 159.000',
          description: 'Perlindungan kehilangan/kerusakan bagasi di bandara hingga IDR 25.000.000.',
          features: ['Klaim mudah & cepat', 'Coverage Kehilangan s.d IDR 25jt'],
          perPax: true,
          selected: false
        }
      ]
    },
    {
      categoryName: 'Airport Transfer & Lounge Access',
      icon: '',
      imageIcon: 'assets/icon-airport-lounge.svg',
      badge: '',
      items: [
        {
          id: 'lounge_cgk',
          category: 'Airport Lounge',
          title: 'Airport Lounge Access (CGK Terminal 3)',
          price: 250000,
          priceDisplay: 'IDR 250.000',
          description: 'Fasilitas 3 jam sebelum departure: Makanan & minuman buffet, WiFi gratis, shower facilities & charging station.',
          features: ['Buffet Makanan & Minuman', 'Fasilitas Shower & Rest Area', 'WiFi Super Cepat'],
          perPax: true,
          selected: false,
          imageIcon: 'assets/icon-airport-lounge.svg'
        },
        {
          id: 'welcome_icn',
          category: 'Incheon Welcome',
          title: 'Welcome Service & Fast-Track Incheon Airport (ICN)',
          price: 150000,
          priceDisplay: 'IDR 150.000',
          description: 'Airport pickup khusus di penjemputan Incheon, guide lokal ramah & briefing perjalanan awal.',
          features: ['Penjemputan Personal di ICN', 'Guide Lokal Berbahasa Indo', 'Briefing Perjalanan'],
          perPax: true,
          selected: false,
          imageIcon: 'assets/icon-airport-pickup.svg'
        },
        {
          id: 'pickup_cgk',
          category: 'Airport Pickup',
          title: 'Airport Pickup Jakarta (CGK → Rumah/Hotel)',
          price: 300000,
          priceDisplay: 'IDR 300.000',
          description: '1 Mobil + Driver profesional khusus penjemputan saat kembali ke Jakarta (Maks 4 orang/grup).',
          features: [' include Mobil MPV + Driver', 'Penjemputan 24 Jam Fleksibel'],
          perPax: false,
          selected: false,
          imageIcon: 'assets/icon-airport-pickup.svg'
        }
      ]
    },
    {
      categoryName: 'Meal & Beverage Add-ons',
      icon: '',
      badge: '',
      items: [
        {
          id: 'bbq_gourmet',
          category: 'Kuliner Korea',
          title: 'Dinner Special: Gourmet Korean BBQ Night',
          price: 600000,
          priceDisplay: 'IDR 600.000',
          description: 'All-You-Can-Eat Authentic Gourmet Korean BBQ di restoran ternama Seoul.',
          features: ['Daging Sapi & Daging Pilihan Premium', 'Lauk Pauk Banchan Melimpah'],
          perPax: true,
          selected: false
        },
        {
          id: 'culinary_class',
          category: 'Kuliner Korea',
          title: 'Korean Culinary Experience & Cooking Class',
          price: 400000,
          priceDisplay: 'IDR 400.000',
          description: 'Belajar memasak masakan Korea khas 2 jam bersama Chef lokal + Makan malam hasil masakan sendiri.',
          features: ['Cooking Class 2 Jam', 'Buku Resep Bahasa Indonesia'],
          perPax: true,
          selected: false
        },
        {
          id: 'breakfast_upgrade',
          category: 'Kuliner Korea',
          title: 'Breakfast Upgrade: Korean Traditional Taste',
          price: 800000,
          priceDisplay: 'IDR 800.000',
          description: 'Sarapan khas Korea tradisional (Kimbap, Tteokbokki, Teh Korea) untuk paket 4 hari.',
          features: ['Menu Berbeda Setiap Hari', 'Teh & Makanan Otentik'],
          perPax: true,
          selected: false
        }
      ]
    },
    {
      categoryName: 'Shopping & Personal Assistance',
      icon: '',
      badge: '',
      items: [
        {
          id: 'shopping_guide',
          category: 'Personal Shopping',
          title: 'Personal Shopping Guide (DFS, Cosmetic & Ginseng Tour)',
          price: 250000,
          priceDisplay: 'IDR 250.000',
          description: 'Pendamping belanja fasih Indo/English untuk negosiasi harga terbaik, cek kualitas & kemasan ekspor (6-8 jam).',
          features: ['Bantuan Negosiasi Harga', 'Rekomendasi DFS & Kosmetik Asli'],
          perPax: true,
          selected: false
        },
        {
          id: 'kbeauty_workshop',
          category: 'Personal Shopping',
          title: 'Cosmetic & K-Beauty Workshop',
          price: 350000,
          priceDisplay: 'IDR 350.000',
          description: 'Sesi tutorial Korean Beauty 2-3 jam dari MUA Korea + Voucher diskon khusus 10-20%.',
          features: ['MUA Professional Korea', 'Diskon Produk 10-20%'],
          perPax: true,
          selected: false
        }
      ]
    },
    {
      categoryName: 'Activity & Experience Add-ons',
      icon: '',
      badge: '',
      items: [
        {
          id: 'hanbok_photo',
          category: 'Aktivitas Korea',
          title: 'Hanbok Photo Session Premium + Photographer',
          price: 200000,
          priceDisplay: 'IDR 200.000',
          description: 'Sewa Hanbok Premium + 1 jam foto profesional di Gyeongbokgung Palace + 25 file digital + 1 Album cetak.',
          features: ['Sewa Hanbok Premium', '25 File Foto Digital + 1 Album Cetak'],
          perPax: true,
          selected: false
        },
        {
          id: 'seoul_tower',
          category: 'Aktivitas Korea',
          title: 'N Seoul Tower Observation Deck & Cable Car Pass',
          price: 150000,
          priceDisplay: 'IDR 150.000',
          description: 'Tiket Observation Deck N Seoul Tower + Pulang-Pergi Cable Car saat sunset.',
          features: ['Tiket Observation Deck 360°', 'Pulang-Pergi Cable Car Pass'],
          perPax: true,
          selected: false
        },
        {
          id: 'jjimjilbang_spa',
          category: 'Aktivitas Korea',
          title: 'Korean Spa (Jjimjilbang) Relaxation Experience',
          price: 250000,
          priceDisplay: 'IDR 250.000',
          description: 'Entry sauna, hot spring, ice room + Pijat relaksasi Korea 30 menit & welcome drink.',
          features: ['Fasilitas Sauna & Hot Spring Lengkap', 'Pijat Relaksasi Korea 30 Min'],
          perPax: true,
          selected: false
        },
        {
          id: 'night_tour',
          category: 'Aktivitas Korea',
          title: 'Nighttime Seoul City Tour (Myeongdong & Dongdaemun)',
          price: 400000,
          priceDisplay: 'IDR 400.000',
          description: 'Tour malam 4-5 jam: Lampu neon Myeongdong, Gangnam 3D Art Gallery & Dongdaemun night market.',
          features: ['Transportasi Tour Malam', 'Kuliner Malam & Tour Guide'],
          perPax: true,
          selected: false
        }
      ]
    },
    {
      categoryName: 'Visa & Support Dokumen',
      icon: '',
      badge: '',
      items: [
        {
          id: 'visa_expedited',
          category: 'Visa Support',
          title: 'Layanan Visa Korea Expedited & Konsultasi',
          price: 500000,
          priceDisplay: 'IDR 500.000',
          description: 'Layanan jemput dokumen ke rumah, konsultasi dokumen, tracking status & jaminan approval.',
          features: ['Jemput Dokumen Ke Rumah', 'Jaminan Approval / Garansi'],
          perPax: true,
          selected: false
        },
        {
          id: 'doc_prep',
          category: 'Visa Support',
          title: 'Persiapan & Penerjemahan Dokumen Korea',
          price: 300000,
          priceDisplay: 'IDR 300.000',
          description: 'Translate dokumen ke Bahasa Korea, legalisir dokumen & foto 4x6 profesional.',
          features: ['Terjemahan Resmi Bahasa Korea', 'Foto 4x6 K-Standard'],
          perPax: true,
          selected: false
        }
      ]
    },
    {
      categoryName: 'Travel & Comfort Items',
      icon: '',
      badge: '',
      items: [
        {
          id: 'fasttrack_cgk',
          category: 'Fast Track',
          title: 'Airport Fast-Track Immigration Jakarta (CGK)',
          price: 200000,
          priceDisplay: 'IDR 200.000',
          description: 'Bebas antrean imigrasi CGK (Hemat 1-2 jam antrean, sangat direkomendasikan untuk lansia/keluarga).',
          features: ['Prioritas Imigrasi Tanpa Antre', 'Hemat Waktu 1-2 Jam'],
          perPax: true,
          selected: false
        },
        {
          id: 'travel_app',
          category: 'Travel App',
          title: 'App Travel Companion & Peta Offline Korea',
          price: 50000,
          priceDisplay: 'IDR 50.000',
          description: 'Aplikasi peta offline Korea, penerjemah instan 30+ bahasa, hotline darurat & panduan lokal.',
          features: ['Peta Offline Tanpa Internet', 'Penerjemah Instan & Hotline Darurat'],
          perPax: true,
          selected: false
        }
      ]
    }
  ];

  // Active option groups rendered for the current booking
  koreaOptionGroups: KoreaOptionCategoryGroup[] = [];

  // Vouchers State
  vouchersClaimed: { [key: string]: boolean } = {};
  showAllVouchers = false;

  isSubmitting = false;

  constructor(
    private router: Router,
    private travelService: TravelService
  ) { }

  ngOnInit(): void {
    window.scrollTo({ top: 0, left: 0, behavior: 'instant' });
    this.bookingData = this.travelService.packageBookingData;

    if (!this.bookingData) {
      this.bookingData = {
        packageName: 'Korea Seoul 06 Hari / 04 Malam',
        selectedDate: 'Sen, 27 Jul 2026',
        ticketItems: [{ name: 'Child 1', priceNumber: 982786, qty: 1 }],
        totalPriceFormatted: 'IDR 982.786',
        totalPriceNumber: 982786,
        duration: 'Berlaku di hari kerja (Senin-Jumat)'
      };
    }

    this.buildVisitorList();
    this.buildPackageOptions();
    this.buildPickupOptions();
  }

  buildPickupOptions(): void {
    const pkgName = this.bookingData?.packageName || '';
    const pkg = SAFARIA_PACKAGES.find(p =>
      p.nama_paket.toLowerCase() === pkgName.toLowerCase() ||
      pkgName.toLowerCase().includes(p.nama_paket.toLowerCase()) ||
      p.nama_paket.toLowerCase().includes(pkgName.toLowerCase())
    );

    if (pkg?.kategori === 'IBADAH') {
      this.pickupOptions = [
        'Bandara Soekarno-Hatta (CGK) - Lounge Terminal 3 International',
        'Hotel Transit Bandara Soekarno-Hatta',
        'Penjemputan Rumah / Alamat Domisili (Private Transfer)',
        'Meeting Point Bandara (Konfirmasi via Tour Leader / WA)'
      ];
    } else if (pkg?.kategori === 'INTERNASIONAL') {
      this.pickupOptions = [
        'Bandara Soekarno-Hatta (CGK) - Terminal 3 International',
        'Bandara Internasional Juanda (SUB) - Terminal 2 International',
        'Hotel Lobby Pick-up / Penjemputan Private Transfer',
        'Meeting Point Bandara (Konfirmasi via Tour Leader / WA)'
      ];
    } else if (pkg?.kategori === 'DOMESTIK') {
      this.pickupOptions = [
        'Bandara Soekarno-Hatta (CGK) - Terminal 2/3 Domestik',
        'Hotel Lobby Pick-up (Area Destinasi)',
        'Pool / Stasiun / Terminal Keberangkatan Utama',
        'Custom Meeting Point (Konfirmasi via WA)'
      ];
    } else {
      this.pickupOptions = [
        'Bandara Soekarno-Hatta (CGK) - Terminal 3 International',
        'Hotel Lobby Pick-up / Private Transfer',
        'Meeting Point Utama (Konfirmasi via Tour Leader)',
        'Custom Pick-up Point (Konfirmasi via WA)'
      ];
    }
  }

  buildPackageOptions(): void {
    const pkgName = this.bookingData?.packageName || '';
    const isKorea = pkgName.toLowerCase().includes('korea');

    if (isKorea) {
      // Korea Seoul gets the full 8 detailed optional item categories
      this.koreaOptionGroups = JSON.parse(JSON.stringify(this.defaultKoreaOptionGroups));
    } else {
      // Other packages get tailored options according to their specific package description and exclusions!
      this.koreaOptionGroups = this.generateOptionsForPackage(pkgName);
    }
  }

  generateOptionsForPackage(pkgName: string): KoreaOptionCategoryGroup[] {
    const pkg = SAFARIA_PACKAGES.find(p =>
      p.nama_paket.toLowerCase() === pkgName.toLowerCase() ||
      pkgName.toLowerCase().includes(p.nama_paket.toLowerCase()) ||
      p.nama_paket.toLowerCase().includes(pkgName.toLowerCase())
    );

    const groups: KoreaOptionCategoryGroup[] = [];
    const kategori = (pkg?.kategori || '').toUpperCase();
    const isDomestik = kategori === 'DOMESTIK';
    const isUmroh = kategori === 'UMROH' || /umroh|haji/i.test(pkgName);
    const isInternational = !isDomestik && !isUmroh;
    const hargaPaket = pkg?.harga || 0;
    const tidakTermasuk = pkg?.tidak_termasuk || [];

    const extractPrice = (line: string): number => {
      const cleaned = line.replace(/rp|idr|\.|,/gi, '').match(/\d{5,}/);
      return cleaned ? parseInt(cleaned[0], 10) : 0;
    };

    let idx = 1;

    // ─── 1. TIPPING ────────────────────────────────────────────────────────
    let tippingPrice = isInternational ? 1500000 : (isUmroh ? 1200000 : 400000);
    let tippingText = 'Tipping Tour Leader, Local Guide, dan Driver selama perjalanan';
    const tippingLine = tidakTermasuk.find(l => /tipping|tips/i.test(l));
    if (tippingLine) {
      tippingText = tippingLine;
      const p = extractPrice(tippingLine);
      if (p > 50000) tippingPrice = p;
    }
    groups.push({
      categoryName: 'Tipping & Gratifikasi Pemandu',
      icon: '',
      imageIcon: 'assets/icon-tipping-gratifikasi-pemandu.svg',
      badge: '',
      items: [{
        id: 'tipping_pkg', category: 'Tipping',
        title: 'Tipping Tour Leader, Guide & Driver',
        price: tippingPrice,
        priceDisplay: 'IDR ' + tippingPrice.toLocaleString('id-ID'),
        description: `Bayar di muka: ${tippingText}.`,
        features: ['Standar Internasional', 'Layanan Driver & Guide Lokal', 'Pengurusan Kolektif'],
        perPax: true, selected: false,
        imageIcon: 'assets/icon-tipping-gratifikasi-pemandu.svg'
      }]
    });

    // ─── 2. SINGLE SUPPLEMENT ──────────────────────────────────────────────
    let singleSuppPrice = pkg?.harga_single_supplement || 0;
    if (!singleSuppPrice && hargaPaket > 0) {
      const rate = isInternational ? 0.32 : (isUmroh ? 0.30 : 0.20);
      singleSuppPrice = Math.round((hargaPaket * rate) / 100000) * 100000;
    }
    if (singleSuppPrice > 0) {
      groups.push({
        categoryName: 'Upgrade Kamar (Single Supplement)',
        icon: '',
        imageIcon: 'assets/icon-upgrade-kamar.svg',
        badge: '',
        items: [{
          id: 'single_supp', category: 'Single Supplement',
          title: 'Kamar Sendiri (Single Supplement)',
          price: singleSuppPrice,
          priceDisplay: 'IDR ' + singleSuppPrice.toLocaleString('id-ID'),
          description: 'Dapatkan 1 kamar hotel sendiri selama perjalanan tur untuk privasi penuh tanpa berbagi kamar.',
          features: ['Private Room 1 Orang', 'Jaminan Kamar Sendiri', 'Kenyamanan Maksimal'],
          perPax: true, selected: false,
          imageIcon: 'assets/icon-upgrade-kamar.svg'
        }]
      });
    }

    // ─── 3. VISA & AIRPORT TAX (INTERNASIONAL) ─────────────────────────────
    if (isInternational) {
      let visaPrice = 1500000;
      let visaText = 'Visa & International Taxes untuk perjalanan luar negeri';
      const visaLine = tidakTermasuk.find(l => /visa|schengen|tax|surcharge/i.test(l));
      if (visaLine) {
        visaText = visaLine;
        const p = extractPrice(visaLine);
        if (p > 100000) visaPrice = p;
      }
      groups.push({
        categoryName: 'Layanan Visa & Airport Tax',
        icon: '',
        imageIcon: 'assets/icon-layanan-visa-airport-tax.svg',
        badge: '',
        items: [{
          id: 'visa_tax_pkg', category: 'Visa & Tax',
          title: 'Pengurusan Visa & Airport Tax',
          price: visaPrice,
          priceDisplay: 'IDR ' + visaPrice.toLocaleString('id-ID'),
          description: `Sesuai ketentuan paket: ${visaText}.`,
          features: ['Bantuan Kelengkapan Dokumen', 'Pemeriksaan Berkas Kedutaan', 'Handling International Tax'],
          perPax: true, selected: false
        }]
      });
    }

    // ─── 4. TRAVEL INSURANCE ───────────────────────────────────────────────
    // Kalau di tidak_termasuk tertulis "Wajib" → sudah include di harga /pax, TIDAK ditampilkan sebagai opsi.
    const insLine = tidakTermasuk.find(l => /travel insurance|asuransi perjalanan|asuransi wajib/i.test(l));
    const insuranceIsWajib = insLine ? /wajib|mandatory|obligatori/i.test(insLine) : false;
    if (insLine && !insuranceIsWajib) {
      let insurancePrice = extractPrice(insLine);
      if (insurancePrice < 50000) insurancePrice = isInternational ? 500000 : 150000;
      groups.push({
        categoryName: 'Travel Insurance',
        icon: '',
        imageIcon: 'assets/icon-travel-insurance.svg',
        badge: '',
        items: [{
          id: 'travel_ins', category: 'Travel Insurance',
          title: 'Travel Insurance (Coverage Standar)',
          price: insurancePrice,
          priceDisplay: 'IDR ' + insurancePrice.toLocaleString('id-ID'),
          description: `Perlindungan dasar: ${insLine}.`,
          features: ['Medical Emergency', 'Personal Accident', 'Delayed Baggage'],
          perPax: true, selected: false
        }]
      });
    }

    // ─── 5. OPTIONAL TOUR / EXCURSION ──────────────────────────────────────
    const optLine = tidakTermasuk.find(l => /optional tour|excursion/i.test(l));
    if (pkg?.optional_tour_price || optLine || isInternational) {
      const optPrice = pkg?.optional_tour_price ?? (isInternational ? 850000 : 450000);
      groups.push({
        categoryName: 'Optional Tour & Wisata Tambahan',
        icon: '',
        imageIcon: 'assets/icon-optional-tour-wisata-tambahan.svg',
        badge: '',
        items: [{
          id: 'opt_tour_pkg', category: 'Optional Tour',
          title: 'Paket Wisata & Atraksi Tambahan',
          price: optPrice,
          priceDisplay: 'IDR ' + optPrice.toLocaleString('id-ID'),
          description: optLine ? `Sesuai deskripsi paket: ${optLine}.` : 'Aktivitas & atraksi ekstra di luar itinerary utama, dipilih sesuai destinasi.',
          features: ['Tiket Atraksi Khusus', 'Pendampingan Guide', 'Fleksibel & Sesuai Minat'],
          perPax: true, selected: false
        }]
      });
    }

    // ─── 6. EXCESS BAGGAGE HANDLING ────────────────────────────────────────
    if (pkg?.handling_bagasi_price || isInternational || isUmroh) {
      const bagPrice = pkg?.handling_bagasi_price ?? 350000;
      groups.push({
        categoryName: 'Handling Kelebihan Bagasi',
        icon: '',
        imageIcon: 'assets/icon-handling-kelebihan-bagasi.svg',
        badge: '',
        items: [{
          id: 'excess_baggage', category: 'Baggage Handling',
          title: 'Handling & Fee Kelebihan Bagasi',
          price: bagPrice,
          priceDisplay: 'IDR ' + bagPrice.toLocaleString('id-ID'),
          description: 'Layanan handling bagasi ekstra di bandara + biaya excess bagasi maskapai (estimasi).',
          features: ['Antrian Prioritas', 'Handling di Bandara', 'Estimasi Fee Excess'],
          perPax: true, selected: false,
          imageIcon: 'assets/icon-handling-kelebihan-bagasi.svg'
        }]
      });
    }

    // ─── 7. UMROH-SPECIFIC OPTIONS ─────────────────────────────────────────
    if (isUmroh) {
      const perlPrice = pkg?.perlengkapan_umroh_price ?? 1250000;
      const ziarahPrice = pkg?.ziarah_tambahan_price ?? 750000;
      groups.push({
        categoryName: 'Perlengkapan & Manasik Ibadah',
        icon: '',
        imageIcon: 'assets/icon-perlengkapan-manasik.svg',
        badge: '',
        items: [
          {
            id: 'perlengkapan_umroh', category: 'Perlengkapan',
            title: 'Paket Perlengkapan Umroh Lengkap',
            price: perlPrice,
            priceDisplay: 'IDR ' + perlPrice.toLocaleString('id-ID'),
            description: 'Ihram, mukena, koper, buku doa, ID card, tas paspor, seragam batik.',
            features: ['Ihram Set (Pria/Wanita)', 'Koper 24 inch', 'Buku Doa & Manasik'],
            perPax: true, selected: false,
            imageIcon: 'assets/icon-perlengkapan-manasik.svg'
          },
          {
            id: 'ziarah_madinah', category: 'Ziarah Tambahan',
            title: 'Ziarah Tambahan Madinah / Kota Suci',
            price: ziarahPrice,
            priceDisplay: 'IDR ' + ziarahPrice.toLocaleString('id-ID'),
            description: 'Tour ziarah tambahan ke masjid & tempat bersejarah dengan muthawwif berbahasa Indonesia.',
            features: ['Bus AC', 'Muthawwif Berpengalaman', 'Kunjungan Ekstra'],
            perPax: true, selected: false
          }
        ]
      });
    }

    // ─── 8. ASURANSI EXTENDED & AIRPORT LOUNGE ─────────────────────────────
    const asrExtPrice = pkg?.asuransi_extended_price ?? (isInternational ? 500000 : 250000);
    const loungePrice = pkg?.lounge_price ?? 250000;
    groups.push({
      categoryName: 'Asuransi Extended & Lounge Bandara',
      icon: '',
      imageIcon: 'assets/icon-airport-lounge.svg',
      badge: '',
      items: [
        {
          id: 'ins_premium_gen', category: 'Asuransi Premium',
          title: 'Upgrade Asuransi Perjalanan Premium',
          price: asrExtPrice,
          priceDisplay: 'IDR ' + asrExtPrice.toLocaleString('id-ID'),
          description: 'Proteksi kesehatan darurat, keterlambatan penerbangan & jaminan refund cancellation.',
          features: [
            isInternational ? 'Coverage Medical s.d IDR 500jt' : 'Coverage Medical s.d IDR 100jt',
            'Trip Cancellation Full Refund',
            'Kompensasi Keterlambatan'
          ],
          perPax: true, selected: false
        },
        {
          id: 'lounge_gen', category: 'Airport Lounge',
          title: isInternational ? 'Airport Lounge Access (CGK Terminal 3)' : 'Airport Lounge Access',
          price: loungePrice,
          priceDisplay: 'IDR ' + loungePrice.toLocaleString('id-ID'),
          description: 'Akses lounge bandara 3 jam sebelum terbang: buffet makanan & minuman, shower & WiFi cepat.',
          features: ['Buffet Makanan & Minuman', 'Shower & Rest Area', 'WiFi Super Cepat'],
          perPax: true, selected: false,
          imageIcon: 'assets/icon-airport-lounge.svg'
        }
      ]
    });

    // ─── 9. AIRPORT PICKUP (JAKARTA) ───────────────────────────────────────
    const pickupPrice = pkg?.airport_pickup_price ?? 300000;
    groups.push({
      categoryName: 'Airport Pickup & Transfer',
      icon: '',
      imageIcon: 'assets/icon-airport-pickup.svg',
      badge: '',
      items: [{
        id: 'pickup_cgk', category: 'Airport Pickup',
        title: 'Airport Pickup Jakarta (Kembali → Rumah/Hotel)',
        price: pickupPrice,
        priceDisplay: 'IDR ' + pickupPrice.toLocaleString('id-ID'),
        description: '1 Mobil MPV + Driver profesional untuk penjemputan saat kembali ke Jakarta (maks 4 orang/grup).',
        features: ['Mobil MPV + Driver', 'Penjemputan 24 Jam', 'Fleksibel'],
        perPax: false, selected: false,
        imageIcon: 'assets/icon-airport-pickup.svg'
      }]
    });

    return groups;
  }

  buildVisitorList(): void {
    const list: VisitorDetail[] = [];
    if (!this.bookingData?.ticketItems) return;

    let totalCount = 0;
    this.bookingData.ticketItems.forEach(item => {
      for (let i = 0; i < item.qty; i++) {
        totalCount++;
        list.push({
          ticketIndex: totalCount,
          ticketType: `${item.name} ${item.qty > 1 ? i + 1 : ''}`.trim(),
          pickupPoint: this.pickupOptions[0],
          fullName: '',
          passportNumber: '',
          dateOfBirth: '',
          passportExpiry: ''
        });
      }
    });

    if (list.length === 0) {
      list.push({
        ticketIndex: 1,
        ticketType: 'Child 1',
        pickupPoint: this.pickupOptions[0],
        fullName: '',
        passportNumber: '',
        dateOfBirth: '',
        passportExpiry: ''
      });
    }

    this.visitorList = list;
  }

  get totalTicketCount(): number {
    return this.visitorList.length;
  }

  get ticketSummaryText(): string {
    if (!this.bookingData?.ticketItems) return '1 Tiket';
    return this.bookingData.ticketItems.map(i => `${i.qty} Tiket - ${i.name}`).join(', ');
  }

  goBack(): void {
    if (this.bookingData?.packageName) {
      this.router.navigate(['/destination', encodeURIComponent(this.bookingData.packageName)]);
    } else {
      this.router.navigate(['/']);
    }
  }

  toggleKoreaOption(item: KoreaOptionItem): void {
    item.selected = !item.selected;
  }

  claimVoucher(id: string): void {
    this.vouchersClaimed[id] = !this.vouchersClaimed[id];
  }

  onBaggageChange(opt: BaggageOption): void {
    this.selectedBaggagePrice = opt.price;
    this.selectedBaggageLabel = opt.label;
  }

  get selectedKoreaOptions(): KoreaOptionItem[] {
    const selected: KoreaOptionItem[] = [];
    this.koreaOptionGroups.forEach(g => {
      g.items.forEach(item => {
        if (item.selected) selected.push(item);
      });
    });
    return selected;
  }

  get addonsTotalPrice(): number {
    const pax = this.totalTicketCount || 1;
    let sum = this.selectedBaggagePrice * pax;

    this.koreaOptionGroups.forEach(g => {
      g.items.forEach(item => {
        if (item.selected) {
          sum += item.perPax ? (item.price * pax) : item.price;
        }
      });
    });

    return sum;
  }

  get finalTotalPayment(): number {
    const base = this.bookingData?.totalPriceNumber || 982786;
    return base + this.addonsTotalPrice;
  }

  get finalTotalPaymentFormatted(): string {
    return 'IDR ' + this.finalTotalPayment.toLocaleString('id-ID');
  }

  isValidForm(): boolean {
    if (!this.fullName || !this.fullName.trim()) return false;
    if (!this.phoneNumber || !this.phoneNumber.trim()) return false;
    if (!this.email || !this.email.trim() || !this.email.includes('@')) return false;

    for (const v of this.visitorList) {
      if (!v.fullName || !v.fullName.trim()) return false;
      if (!v.pickupPoint || !v.pickupPoint.trim()) return false;
      if (!v.dateOfBirth) return false;
      if (!v.passportNumber || !v.passportNumber.trim()) return false;
      if (!v.passportExpiry) return false;
    }
    return true;
  }

  submitBooking(): void {
    this.showValidationErrors = true;

    if (!this.isValidForm()) {
      // Find missing elements for alert
      const missing: string[] = [];
      if (!this.fullName?.trim()) missing.push('Nama Lengkap Pemesan');
      if (!this.phoneNumber?.trim()) missing.push('Nomor Ponsel Pemesan');
      if (!this.email?.trim() || !this.email.includes('@')) missing.push('Email Pemesan Valid');

      this.visitorList.forEach((v, i) => {
        if (!v.fullName?.trim()) missing.push(`Nama Lengkap (Tiket ${v.ticketIndex})`);
        if (!v.dateOfBirth) missing.push(`Tanggal Lahir (Tiket ${v.ticketIndex})`);
        if (!v.passportNumber?.trim()) missing.push(`Nomor Paspor (Tiket ${v.ticketIndex})`);
        if (!v.passportExpiry) missing.push(`Masa Berlaku Paspor (Tiket ${v.ticketIndex})`);
      });

      this.validationErrorMessage = `Mohon lengkapi formulir wajib berikut sebelum melanjutkan: ${missing.join(', ')}.`;

      // Smooth scroll to top of invalid card
      const firstInvalid = document.querySelector('.field-input.input-error, .custom-select-trigger.input-error');
      if (firstInvalid) {
        firstInvalid.scrollIntoView({ behavior: 'smooth', block: 'center' });
      } else {
        window.scrollTo({ top: 120, behavior: 'smooth' });
      }
      return;
    }

    this.validationErrorMessage = '';
    this.isSubmitting = true;

    const message = `*DETAIL PEMESANAN BARU*\n\n` +
      `📦 Paket: ${this.bookingData?.packageName}\n` +
      `📅 Tanggal: ${this.bookingData?.selectedDate}\n` +
      `🎟 Tiket: ${this.ticketSummaryText}\n` +
      `💰 Total Pembayaran: ${this.finalTotalPaymentFormatted}\n\n` +
      `🧳 *FASILITAS EKSTRA:*\n` +
      `• Bagasi: ${this.selectedBaggageLabel}\n\n` +
      `🎁 *OPSIONAL & PERLINDUNGAN EKSTRA:*\n` +
      (this.selectedKoreaOptions.length > 0 ? this.selectedKoreaOptions.map(p => `• ${p.title} (${p.priceDisplay}${p.perPax ? '/pax' : '/grup'})`).join('\n') : '• Tidak memilih opsional ekstra') + `\n\n` +
      `👤 *DATA PEMESAN:*\n` +
      `• Sapaan: ${this.salutation}\n` +
      `• Nama Lengkap: ${this.fullName || '-'}\n` +
      `• No. HP: ${this.phoneCode}${this.phoneNumber || '-'}\n` +
      `• Email: ${this.email || '-'}\n` +
      `• Negara: ${this.country}\n\n` +
      `👥 *DATA PENGUNJUNG:*\n` +
      this.visitorList.map(v =>
        `*Tiket ${v.ticketIndex} (${v.ticketType}):*\n` +
        `  - Pick-up: ${v.pickupPoint}\n` +
        `  - Nama: ${v.fullName || '-'}\n` +
        `  - Paspor: ${v.passportNumber || '-'}\n` +
        `  - Tgl Lahir: ${v.dateOfBirth || '-'}\n` +
        `  - Masa Paspor: ${v.passportExpiry || '-'}`
      ).join('\n\n') + `\n\n` +
      `Mohon diproses untuk penerbitan e-tiket. Terima kasih!`;

    // Persist the WhatsApp message payload for staff (optional, kept in sessionStorage).
    try { sessionStorage.setItem('gmm_last_booking_wa', message); } catch {}

    // Update booking state with final total so payment page displays correct amount.
    if (this.bookingData) {
      this.bookingData.totalPriceNumber = this.finalTotalPayment;
      this.bookingData.totalPriceFormatted = this.finalTotalPaymentFormatted;
      this.travelService.packageBookingData = this.bookingData;
    }

    setTimeout(() => {
      this.isSubmitting = false;
      this.router.navigate(['/booking/package-payment']);
    }, 300);
  }
}
