import {
  Component, ViewChild, ElementRef, AfterViewInit, OnDestroy, OnInit
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, ActivatedRoute } from '@angular/router';
import maplibregl from 'maplibre-gl';
import { TravelService } from '../../services/travel.service';

export interface ItineraryDay  { day: string; title: string; desc: string; }
export interface PackageInclusion { label: string; included: boolean; }
export interface Highlight { icon: string; text: string; }
export interface HotelDetail { location: string; name: string; }
export interface PriceCategoryItem { type: string; price: string; }
export interface PriceCategory { dateLabel: string; prices: PriceCategoryItem[]; }
export interface OptionalActivity { name: string; price: string; }
export interface DatePill {
  dayName: string;
  dateDisplay: string;
  fullDate: string;
}

export interface TicketItem {
  name: string;
  priceNumber: number;
  originalPriceNumber?: number;
  discountPercent?: number;
  qty: number;
}

interface MapPin { lng: number; lat: number; label: string; }

export interface DestinationPackage {
  background?: string;
  image?: string;
  galleryImages?: string[];
  maxPax: number;
  ctaLabel: string;
  highlights: Highlight[];
  itinerary: ItineraryDay[];
  inclusions: PackageInclusion[];
  mapCenter: [number, number];
  mapZoom: number;
  mapPins: MapPin[];
  // display meta (matches Destination fields from destinations-section)
  badge?: string;
  tagline: string;
  price: string;
  duration: string;
  rating: number;
  reviews: number;
  // spec metadata matching the design mockup
  maskapai?: string;
  keberangkatan?: string;
  minPeserta?: string;
  hotelInfoText?: string;
  tipeKamarText?: string;
  // Extra detailed info fields
  hotelDetails?: HotelDetail[];
  priceCategories?: PriceCategory[];
  optionalActivities?: OptionalActivity[];
  syaratKetentuan?: string[];
  remarks?: string[];
  daftar_link?: string;
  harga_single_supplement?: number;
  tanggal_keberangkatan?: Record<string, string[]>;
  hasGroupEksklusif?: boolean;
  hasPembimbingIbadah?: boolean;
}

// ─── ALL per-destination data ─────────────────────────────────────────────────
const PACKAGES: Record<string, DestinationPackage> = {

  'Kotamobagu': {
    background: 'assets/wisata-alam.png',
    badge: 'Wisata Alam', tagline: 'Udaranya sejuk dengan pemandangan pegunungan hijau.',
    price: 'Rp 850.000', duration: '3 Hari 2 Malam', rating: 4.5, reviews: 68,
    maxPax: 15,
    ctaLabel: 'Pesan paket ini →',
    highlights: [
      { icon: '🌡️', text: '18–24°C' },
      { icon: '⛰️', text: 'Pegunungan Meratus' },
      { icon: '🌿', text: 'Trek hutan tropis & air terjun' },
      { icon: '🌾', text: 'Sawah bertingkat' },
      { icon: '🏔️', text: 'Pemandangan khas Bolmong' },
      { icon: '💨', text: 'Udara sejuk alami' },
      { icon: '🧘', text: 'Cocok untuk healing & detox' },
      { icon: '🍽️', text: 'Kuliner khas Bolmong' },
      { icon: '🥘', text: 'Ilabulo & goroho goreng' },
    ],
    itinerary: [
      { day: 'H1', title: 'Tiba & Explore Kota', desc: 'Jemput bandara Manado, perjalanan 2 jam ke Kotamobagu, cek-in penginapan, kuliner malam.' },
      { day: 'H2', title: 'Trek Alam & Air Terjun', desc: 'Hiking ke Dumoga-Bone, mampir air terjun Molobog, foto sawah bertingkat sore hari.' },
      { day: 'H3', title: 'Pasar Lokal & Pulang', desc: 'Sarapan khas Bolmong, belanja oleh-oleh rempah, kembali ke Manado.' },
    ],
    inclusions: [
      { label: 'Akomodasi 2 malam',    included: true  },
      { label: 'Transportasi lokal',   included: true  },
      { label: 'Makan 3× sehari',      included: true  },
      { label: 'Guide alam lokal',     included: true  },
      { label: 'Perlengkapan hiking',  included: true  },
      { label: 'Tiket masuk wisata',   included: true  },
      { label: 'Tiket pesawat',        included: false },
      { label: 'Asuransi perjalanan',  included: false },
    ],
    mapCenter: [124.3125, 0.7285],
    mapZoom: 10,
    mapPins: [
      { lng: 124.3125, lat: 0.7285, label: 'Kota Kotamobagu' },
      { lng: 124.1800, lat: 0.5200, label: 'Dumoga-Bone' },
      { lng: 124.2300, lat: 0.6600, label: 'Air Terjun Molobog' },
    ],
  },

  'Manado': {
    background: 'assets/terumbu-karang.png',
    badge: 'Terpopuler', tagline: 'Snorkeling di terumbu karang Bunaken yang memukau.',
    price: 'Rp 1.250.000', duration: '4 Hari 3 Malam', rating: 4.8, reviews: 145,
    maxPax: 12,
    ctaLabel: 'Pesan paket ini →',
    highlights: [
      { icon: '🌊', text: 'Snorkeling kelas dunia' },
      { icon: '🐠', text: 'Taman laut Bunaken' },
      { icon: '🐢', text: 'Penyu hijau & ikan napoleon' },
      { icon: '🍜', text: 'Tinutuan & cakalang fufu' },
      { icon: '🌅', text: 'Sunset Megamas' },
      { icon: '🏖️', text: 'Pantai pasir putih' },
      { icon: '🤿', text: 'Wall dive spektakuler' },
      { icon: '🐋', text: 'Mega biodiversitas laut' },
    ],
    itinerary: [
      { day: 'H1', title: 'Tiba & Orientasi', desc: 'Jemput bandara, check-in resort tepi pantai, briefing snorkeling malam.' },
      { day: 'H2', title: 'Full-day Bunaken', desc: 'Wall dive, ikan napoleon, penyu hijau, makan siang di pulau.' },
      { day: 'H3', title: 'Kota & Kuliner', desc: 'Bukit Kasih, tinutuan, cakalang fufu, sunset Megamas.' },
      { day: 'H4', title: 'Check-out', desc: 'Sarapan, oleh-oleh, antar bandara.' },
    ],
    inclusions: [
      { label: 'Akomodasi 3 malam',    included: true  },
      { label: 'Transportasi lokal',   included: true  },
      { label: 'Makan 3× sehari',      included: true  },
      { label: 'Perlengkapan snorkel', included: true  },
      { label: 'Guide berpengalaman',  included: true  },
      { label: 'Tiket masuk taman',    included: true  },
      { label: 'Tiket pesawat',        included: false },
      { label: 'Asuransi perjalanan',  included: false },
    ],
    mapCenter: [124.8299, 1.5905],
    mapZoom: 10,
    mapPins: [
      { lng: 124.8299, lat: 1.5905, label: 'Bandara Sam Ratulangi' },
      { lng: 124.7474, lat: 1.6326, label: 'Pulau Bunaken' },
      { lng: 124.8403, lat: 1.4748, label: 'Bukit Kasih' },
    ],
  },

  'Gorontalo': {
    background: 'assets/hiu-paus.png',
    badge: 'Eksotis', tagline: 'Berenang bersama Hiu Paus raksasa yang ramah.',
    price: 'Rp 1.500.000', duration: '4 Hari 3 Malam', rating: 4.7, reviews: 112,
    maxPax: 10,
    ctaLabel: 'Pesan paket ini →',
    highlights: [
      { icon: '🦈', text: 'Berenang Hiu Paus' },
      { icon: '✨', text: 'Pengalaman sekali seumur hidup' },
      { icon: '🤿', text: 'Snorkeling & Diving' },
      { icon: '🪸', text: 'Terumbu karang murni Teluk Tomini' },
      { icon: '🚤', text: 'Boat Trip' },
      { icon: '🌊', text: 'Menyusuri perairan Gorontalo' },
      { icon: '📸', text: 'Foto & Video Bawah Laut' },
      { icon: '🎥', text: 'Kamera underwater tersedia' },
    ],
    itinerary: [
      { day: 'H1', title: 'Tiba & Orientasi', desc: 'Jemput bandara Jalaluddin, check-in resort tepi teluk, briefing keselamatan malam.' },
      { day: 'H2', title: 'Whale Shark Encounter', desc: 'Boat pagi ke spot Hiu Paus Botubarani, berenang bersama, snorkeling terumbu karang sore.' },
      { day: 'H3', title: 'Danau Limboto & Kuliner', desc: 'Wisata Danau Limboto, Benteng Otanaha, malam kuliner ikan bakar khas Gorontalo.' },
      { day: 'H4', title: 'Check-out & Pulang', desc: 'Sarapan, oleh-oleh kue kacang & kopi Pinogu, antar bandara.' },
    ],
    inclusions: [
      { label: 'Akomodasi 3 malam',    included: true  },
      { label: 'Transportasi lokal',   included: true  },
      { label: 'Makan 3× sehari',      included: true  },
      { label: 'Guide & boat trip',    included: true  },
      { label: 'Perlengkapan snorkel', included: true  },
      { label: 'Kamera underwater',    included: true  },
      { label: 'Tiket pesawat',        included: false },
      { label: 'Asuransi perjalanan',  included: false },
    ],
    mapCenter: [122.9950, 0.5500],
    mapZoom: 10,
    mapPins: [
      { lng: 123.0595, lat: 0.5450, label: 'Bandara Jalaluddin' },
      { lng: 122.8470, lat: 0.5780, label: 'Spot Hiu Paus Botubarani' },
      { lng: 122.9950, lat: 0.5915, label: 'Danau Limboto' },
    ],
  },

  'Makassar': {
    background: 'assets/pantai-losari.png',
    tagline: 'Pantai Losari dan petualangan kuliner legendaris.',
    price: 'Rp 1.350.000', duration: '3 Hari 2 Malam', rating: 4.7, reviews: 230,
    maxPax: 15,
    ctaLabel: 'Pesan paket ini →',
    highlights: [
      { icon: '🌅', text: 'Sunset Pantai Losari' },
      { icon: '📸', text: 'Spot terbaik foto golden hour' },
      { icon: '⛵', text: 'Kapal Phinisi' },
      { icon: '🏛️', text: 'Ikon budaya Sulawesi Selatan' },
      { icon: '🍜', text: 'Kuliner legendaris' },
      { icon: '🥘', text: 'Coto, konro & pisang epe' },
      { icon: '🏰', text: 'Fort Rotterdam' },
      { icon: '🗿', text: 'Benteng kolonial bersejarah' },
    ],
    itinerary: [
      { day: 'H1', title: 'Tiba & Losari Sore', desc: 'Jemput bandara, check-in hotel, sore jalan kaki di Pantai Losari, foto sunset kapal Phinisi.' },
      { day: 'H2', title: 'Sejarah & Kuliner', desc: 'Fort Rotterdam, Masjid 99 Kubah, coto Makassar siang, malam di Pasar Malam Somba Opu.' },
      { day: 'H3', title: 'Belanja & Pulang', desc: 'Pisang epe sarapan, oleh-oleh khas Makassar, antar bandara.' },
    ],
    inclusions: [
      { label: 'Akomodasi 2 malam',    included: true  },
      { label: 'Transportasi lokal',   included: true  },
      { label: 'Makan 3× sehari',      included: true  },
      { label: 'Guide kota lokal',     included: true  },
      { label: 'Tiket masuk wisata',   included: true  },
      { label: 'Dokumentasi foto',     included: true  },
      { label: 'Tiket pesawat',        included: false },
      { label: 'Asuransi perjalanan',  included: false },
    ],
    mapCenter: [119.4191, -5.1477],
    mapZoom: 12,
    mapPins: [
      { lng: 119.4065, lat: -5.1477, label: 'Pantai Losari' },
      { lng: 119.4067, lat: -5.1370, label: 'Fort Rotterdam' },
      { lng: 119.4420, lat: -5.1475, label: 'Masjid 99 Kubah' },
    ],
  },

  'Kendari': {
    background: 'assets/teluk-kendari.png',
    tagline: 'Keindahan teluk Kendari dan pulau Wakatobi.',
    price: 'Rp 1.450.000', duration: '4 Hari 3 Malam', rating: 4.6, reviews: 85,
    maxPax: 12,
    ctaLabel: 'Pesan paket ini →',
    highlights: [
      { icon: '🌉', text: 'Jembatan Bahteramas' },
      { icon: '🏙️', text: 'Ikon kota kabel terpanjang' },
      { icon: '🌅', text: 'Sunset Teluk Kendari' },
      { icon: '🌇', text: 'Panorama langit ungu & oranye' },
      { icon: '🪸', text: 'Pulau Wakatobi' },
      { icon: '🌊', text: 'Dive spot kelas dunia UNESCO' },
      { icon: '🍽️', text: 'Kuliner Khas Tolaki' },
      { icon: '🐟', text: 'Sinonggi & ikan bakar teluk' },
    ],
    itinerary: [
      { day: 'H1', title: 'Tiba & Teluk Malam', desc: 'Jemput bandara Haluoleo, check-in hotel tepi teluk, malam foto Jembatan Bahteramas menyala.' },
      { day: 'H2', title: 'Day Trip Wakatobi', desc: 'Speedboat ke Pulau Hoga, snorkeling & diving terumbu karang Wakatobi, kembali sore.' },
      { day: 'H3', title: 'Kota & Kuliner', desc: 'Masjid Al-Alam di atas laut, Pantai Toronipa, makan malam sinonggi & ikan bakar teluk.' },
      { day: 'H4', title: 'Check-out & Pulang', desc: 'Sarapan, oleh-oleh tenun Tolaki & mete, antar bandara.' },
    ],
    inclusions: [
      { label: 'Akomodasi 3 malam',    included: true  },
      { label: 'Transportasi lokal',   included: true  },
      { label: 'Makan 3× sehari',      included: true  },
      { label: 'Speedboat Wakatobi',   included: true  },
      { label: 'Perlengkapan snorkel', included: true  },
      { label: 'Guide lokal',          included: true  },
      { label: 'Tiket pesawat',        included: false },
      { label: 'Asuransi perjalanan',  included: false },
    ],
    mapCenter: [122.5155, -3.9985],
    mapZoom: 10,
    mapPins: [
      { lng: 122.5155, lat: -3.9985, label: 'Bandara Haluoleo' },
      { lng: 122.5270, lat: -4.0220, label: 'Jembatan Bahteramas' },
      { lng: 122.5830, lat: -4.0170, label: 'Pantai Toronipa' },
      { lng: 123.8548, lat: -5.4904, label: 'Wakatobi' },
    ],
  },

  'UMROH ITIKAF': {
    badge: 'PAKET UMROH',
    image: 'https://images.unsplash.com/photo-1591604129939-f1efa4d9f7fa?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1591604129939-f1efa4d9f7fa?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1565552645632-d725f8bfc19a?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'Raih keberkahan umroh dengan Itikaf di Masjidil Haram. Fokus beribadah, mendekatkan diri kepada Allah di tempat paling mulia.',
    price: 'Rp 47.000.000',
    duration: '14 Hari',
    rating: 4.9,
    reviews: 150,
    maxPax: 12,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Etihad Airways',
    keberangkatan: '28 Feb - 13 Mar 2027',
    minPeserta: '2 Peserta',
    hotelInfoText: 'Bakkah Al Salah / Rua Int.',
    tipeKamarText: 'QUAD: Rp 47 Juta / Twin Share',
    highlights: [
      { icon: '✈️', text: 'Etihad Airways (Jakarta CGK PP)' },
      { icon: '📅', text: '28 Feb - 13 Mar 2027' },
      { icon: '🏨', text: 'Madinah: Rua International' },
      { icon: '🕌', text: 'Mekkah: Bakkah Al Salah' },
      { icon: '🛏️', text: 'Tipe Kamar QUAD: Rp 47 Juta' },
      { icon: '👥', text: 'Kuota: 0/24' },
      { icon: '💼', text: 'Komisi Cabang: Rp 1,5 Jt | Mitra: Rp 1,3 Jt' },
      { icon: '🌙', text: 'Makan Sahur & Buka Puasa Ramadhan' },
    ],
    hotelDetails: [
      { location: 'Madinah', name: 'Rua International' },
      { location: 'Mekkah', name: 'Bakkah Al Salah' },
    ],
    itinerary: [
      { day: '01', title: 'Jakarta – Madinah', desc: 'Berkumpul di Bandara Soekarno Hatta untuk penerbangan menuju Madinah via Etihad Airways.' },
      { day: '02', title: 'Madinah City Tour & Ziarah', desc: 'Tiba di Madinah, check-in hotel Rua International. Ziarah Raudhah, Masjid Nabawi, Masjid Quba, & Jabal Uhud.' },
      { day: '03', title: 'Memperbanyak Ibadah di Madinah', desc: 'Fokus memperbanyak ibadah khusyuk di Masjid Nabawi, ziarah kurma & persiapam ke Mekkah.' },
      { day: '04', title: 'Madinah – Mekkah & Umroh Pertama', desc: 'Mengambil miqat di Bir Ali, perjalanan ke Mekkah by Bus AC. Check-in hotel Bakkah Al Salah & pelaksanaan Umroh.' },
      { day: '05', title: 'Program Itikaf Masjidil Haram', desc: 'Fokus program Itikaf di Masjidil Haram, sahur & buka puasa bersama jamaah.' }
    ],
    inclusions: [
      { label: 'Tiket Pesawat PP (Economy Class)', included: true },
      { label: 'Bagasi 20kg & Cabin 7kg', included: true },
      { label: 'Akomodasi: Hotel Bintang 3/4', included: true },
      { label: 'Transportasi AC & Tiket Wisata', included: true },
      { label: 'Makan 3x Sehari', included: true },
      { label: 'Asuransi Perjalanan', included: true },
      { label: 'Visa & Perizinan', included: true },
      { label: 'Pembimbing Ibadah', included: true },
      { label: 'Air Zamzam 5 Liter', included: true },
      { label: 'Perlengkapan Umroh', included: true },
      { label: 'Handling & Airport Tax', included: true },
      { label: 'Biaya Pembuatan Paspor dan Dokumen Lain', included: false },
      { label: 'Tip Tour Leader, Local Guide & Driver', included: false },
      { label: 'Pengeluaran Pribadi', included: false },
      { label: 'Optional Tour', included: false },
      { label: 'Biaya Lain yang Tidak Tercantum', included: false }
    ],
    mapCenter: [39.8262, 21.4225],
    mapZoom: 10,
    mapPins: [
      { lng: 39.8262, lat: 21.4225, label: 'Masjidil Haram (Mekkah)' },
      { lng: 39.6125, lat: 24.4672, label: 'Masjid Nabawi (Madinah)' },
    ],
  },

  'UMROH CERIA MAULID': {
    badge: 'PAKET UMROH',
    image: 'assets/umroh-ceria-maulid.jpeg',
    galleryImages: [
      'assets/umroh-ceria-maulid.jpeg',
      'https://images.unsplash.com/photo-1591604129939-f1efa4d9f7fa?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1565552645632-d725f8bfc19a?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'Direct Tanpa Transit bersama Saudia Airlines! Hotel Dar Naeem Madinah (±7 mnt Nabawi) & Maysan Al Maqam Mekkah (±5 mnt Haram). Bonus Thaif Tour, Museum Al Amoudy, Ayam Albaik & Umroh Certificate + Frame.',
    price: 'Rp 31.900.000',
    duration: '9 Hari 7 Malam',
    rating: 4.8,
    reviews: 140,
    maxPax: 24,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Saudia Airlines (Direct, Tanpa Transit)',
    keberangkatan: '19 Okt 2026 | 19 Nov 2026 | 09 Jan 2027',
    minPeserta: '24 Peserta',
    hotelInfoText: 'Dar Naeem Madinah / Maysan Al Maqam Mekkah',
    tipeKamarText: 'Twin Share / Triple / Quad',
    hasGroupEksklusif: true,
    hasPembimbingIbadah: true,
    highlights: [
      { icon: '✈️', text: 'Saudia Airlines — Direct, Tanpa Transit' },
      { icon: '🏢', text: 'Dar Naeem Madinah (±7 mnt ke Masjid Nabawi)' },
      { icon: '🏢', text: 'Maysan Al Maqam Mekkah (±5 mnt ke Masjidil Haram)' },
      { icon: '🌹', text: 'FREE Thaif Tour — kota bunga mawar di atas pegunungan' },
      { icon: '🏛️', text: 'FREE Museum Al Amoudy' },
      { icon: '🍗', text: 'FREE Ayam Albaik khas Arab Saudi' },
      { icon: '📜', text: 'FREE Umroh Certificate + Frame' },
      { icon: '⛽', text: 'Biaya kenaikan avtur SUDAH termasuk dalam harga' },
      { icon: '🔥', text: 'PROMO: Rp 31,9 Jt (Normal Rp 34,5 Jt) s.d. 30 Jul 2026' },
      { icon: '📅', text: '3 Pilihan keberangkatan: Okt, Nov 2026 & Jan 2027' },
    ],
    priceCategories: [
      {
        dateLabel: '19 Oktober 2026 / 19 November 2026 / 09 Januari 2027',
        prices: [
          { type: 'Harga Promo (s.d. 30 Jul 2026)', price: 'Rp 31.900.000' },
          { type: 'Harga Normal',                   price: 'Rp 34.500.000' },
        ]
      }
    ],
    optionalActivities: [
      { name: 'Ziarah Tambahan Makkah & Madinah', price: 'Sesuai program' },
      { name: 'Oleh-oleh khas Tanah Suci',        price: 'Tersedia' },
    ],
    itinerary: [
      {
        day: 'Day 01',
        title: 'JAKARTA – MADINAH',
        desc: 'Berkumpul di Bandara Soekarno Hatta, berangkat menuju Madinah dengan Saudia Airlines penerbangan direct tanpa transit. Tiba di Madinah, transfer ke hotel Dar Naeem (±7 menit ke Masjid Nabawi).'
      },
      {
        day: 'Day 02–04',
        title: 'MADINAH — Ziarah & Ibadah (3 Malam)',
        desc: 'Program ziarah Madinah: Raudhah, Masjid Nabawi, Masjid Quba, Masjid Qiblatayn, Jabal Uhud, dan Percetakan Al-Quran. Memperbanyak ibadah shalat berjamaah di Masjid Nabawi.'
      },
      {
        day: 'Day 05',
        title: 'MADINAH – THAIF – MEKKAH',
        desc: 'Setelah sarapan, perjalanan menuju Mekkah via Thaif. FREE Thaif Tour: nikmati kesejukan kota bunga mawar, kebun anggur, dan tempat-tempat bersejarah. Tiba di Mekkah, mengambil miqat dan melaksanakan Umroh pertama. Check-in Hotel Maysan Al Maqam (±5 menit ke Masjidil Haram).'
      },
      {
        day: 'Day 06–08',
        title: 'MEKKAH — Ibadah & Ziarah (4 Malam)',
        desc: 'Program ziarah Mekkah: Jabal Rahmah, Jabal Tsur, Jabal Nur, Arafah, Mina, Muzdalifah. FREE Museum Al Amoudy. FREE Ayam Albaik khas Arab Saudi. Memperbanyak tawaf, sai, dan ibadah di Masjidil Haram.'
      },
      {
        day: 'Day 09',
        title: 'MEKKAH – JAKARTA',
        desc: 'Setelah check out, menuju Bandara King Abdul Aziz untuk penerbangan kembali ke Jakarta dengan Saudia Airlines direct. Tiba di tanah air membawa kenangan ibadah dan FREE Umroh Certificate + Frame dari Charisma Insani Umroh & Haji.'
      }
    ],
    inclusions: [
      { label: 'Tiket pesawat PP Saudia Airlines (Direct, tanpa transit)',               included: true  },
      { label: 'Biaya kenaikan avtur sudah termasuk dalam harga',                        included: true  },
      { label: 'Hotel Madinah: Dar Naeem ±7 mnt ke Masjid Nabawi (3 malam)',            included: true  },
      { label: 'Hotel Mekkah: Maysan Al Maqam ±5 mnt ke Masjidil Haram (4 malam)',      included: true  },
      { label: 'FREE Thaif Tour',                                                         included: true  },
      { label: 'FREE Museum Al Amoudy',                                                   included: true  },
      { label: 'FREE Ayam Albaik',                                                        included: true  },
      { label: 'FREE Umroh Certificate + Frame',                                          included: true  },
      { label: 'Pembuatan paspor',                                                        included: false },
      { label: 'Vaksin meningitis dan polio',                                             included: false },
      { label: 'Kelebihan bagasi (excess baggage)',                                       included: false },
      { label: 'Pengeluaran pribadi',                                                     included: false },
      { label: 'Tour di luar program',                                                    included: false },
    ],
    mapCenter: [39.6125, 24.4672],
    mapZoom: 6,
    mapPins: [
      { lng: 39.6125, lat: 24.4672, label: 'Masjid Nabawi (Madinah)' },
      { lng: 39.8262, lat: 21.4225, label: 'Masjidil Haram (Mekkah)' },
      { lng: 40.4138, lat: 21.2716, label: 'Thaif' },
    ]
  },

  'Korea Seoul 06 Hari / 04 Malam': {
    badge: 'PAKET INTERNASIONAL',
    image: 'assets/korea-seoul-poster.jpeg',
    galleryImages: [
      'assets/korea-seoul-poster.jpeg',
      'https://images.unsplash.com/photo-1517154421773-0529f29ea451?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1573832035811-48043f1f6afe?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1516796181074-bf453fbfa3e6?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'Seoul seru bareng Tway Air! Han River Park, Myeongdong Shopping Street, N Seoul Tower, Gwangjang Market, dan pengalaman Kimchi Making + Hanbok.',
    price: 'Rp 7.990.000',
    duration: '6 Hari 4 Malam',
    rating: 4.7,
    reviews: 120,
    maxPax: 25,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Tway Air (Economy Class — No Reschedule, No Refund, No Reroute)',
    keberangkatan: 'JUL 2026: 15, 19, 20',
    minPeserta: '25 Peserta',
    hotelInfoText: 'Hotel ★3 (1 kamar berdua / Twin Share)',
    tipeKamarText: 'Twin Share / Single Supplement +Rp 2.800.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Tway Air (Economy Class — Group Booking)' },
      { icon: '🧳', text: 'Bagasi 20 kg + Cabin 7 kg' },
      { icon: '🌉', text: 'Han River Park — keindahan sungai Han ikonik' },
      { icon: '🎤', text: 'Hongdae Street — busking & kafe estetis' },
      { icon: '🗼', text: 'N Seoul Tower — pemandangan 360° Gunung Namsan' },
      { icon: '🛍️', text: 'Myeongdong Shopping Street' },
      { icon: '🥬', text: 'Kimchi Making Experience & Hanbok Studio' },
      { icon: '🏮', text: 'Gwangjang Market & Dongdaemun Market' },
      { icon: '👥', text: 'Minimal 25 Pax, didampingi Tour Leader Indonesia' },
      { icon: '🛡️', text: 'Asuransi Perjalanan (Cover Maks. Usia 69 Tahun)' },
    ],
    priceCategories: [
      {
        dateLabel: 'Keberangkatan JUL 2026 (15, 19, 20 Jul)',
        prices: [
          { type: 'Twin Share / Dewasa',      price: 'Rp 7.990.000' },
          { type: 'Single Supplement',        price: '+Rp 2.800.000' },
          { type: 'Uang Muka (non-refundable)', price: 'Rp 7.000.000/orang' },
        ]
      }
    ],
    optionalActivities: [
      { name: 'Everland Theme Park',          price: 'Sesuai harga lokal' },
      { name: 'Nami Island Day Trip',         price: 'Sesuai harga lokal' },
      { name: 'DMZ (Demilitarized Zone) Tour', price: 'Sesuai harga lokal' },
      { name: 'K-Pop Concert / Fan Meeting',  price: 'Sesuai harga lokal' },
      { name: 'Rental Wifi Portable / SIM Card', price: 'Tersedia' },
    ],
    itinerary: [
      {
        day: 'H1',
        title: 'JAKARTA – INCHEON',
        desc: 'Pada waktu yang telah ditentukan, semua peserta diminta berkumpul di Bandara Soekarno Hatta untuk bersama-sama terbang menuju kota Incheon bersama Tway Air.'
      },
      {
        day: 'H2',
        title: 'INCHEON – SEOUL',
        desc: 'Setibanya di Incheon, foto di Han River Park menikmati keindahan sungai Han, kunjungi The Memorial of Korea, lalu menikmati waktu bebas di Hongdae Street — pusat budaya anak muda, seni indie, pertunjukan jalanan (busking), kafe estetis, belanja fashion murah — dan Itaewon Street.'
      },
      {
        day: 'H3',
        title: 'SEOUL',
        desc: 'Setelah sarapan, berkunjung ke National Ginseng Outlet dan Cosmetic Shop. Kemudian National Folk Museum, melewati The Blue House, N Seoul Tower (excluding cable car & lift) — menara observasi ikonik di puncak Gunung Namsan dengan pemandangan kota 360° — dan menikmati waktu berbelanja di Myeongdong Shopping Street.'
      },
      {
        day: 'H4',
        title: 'SEOUL (B)',
        desc: 'Setelah sarapan, kunjungi Kimchi Making Experience & Hanbok Studio, Red Pine Tree Shop, Amethyst Showroom, berbelanja di Duty Free Shop, lalu Gwangjang Market untuk menikmati kuliner lokal khas Korea, dan Dongdaemun Market.'
      },
      {
        day: 'H5',
        title: 'SEOUL — FREE DAY (B)',
        desc: 'Hari ini Anda memiliki waktu bebas untuk menikmati kota Seoul. Manfaatkan untuk eksplorasi mandiri, belanja, café hopping, atau kunjungi spot favorit. (Tidak ada guide dan bus.)'
      },
      {
        day: 'H6',
        title: 'INCHEON – JAKARTA (B)',
        desc: 'Setelah check out, diantar ke bandara Incheon untuk penerbangan kembali ke Jakarta bersama Tway Air. Selesailah perjalanan tour kali ini — terima kasih atas partisipasi Anda, sampai jumpa di acara tour kami lainnya!'
      }
    ],
    inclusions: [
      { label: 'Tiket International by Tway Air (Economy Class, Group Booking)',         included: true  },
      { label: 'Bagasi 20 kg & Cabin 7 kg',                                              included: true  },
      { label: 'Akomodasi hotel ★3 — 1 kamar berdua (Twin Share)',                      included: true  },
      { label: 'Transportasi Bus AC & biaya kunjungan objek wisata',                     included: true  },
      { label: 'Tour Leader dari Indonesia',                                              included: true  },
      { label: 'Asuransi Perjalanan Standard Group (Cover Maks. Usia 69 Tahun)',         included: true  },
      { label: 'Makan sesuai program (B=Pagi, L=Siang, D=Malam)',                        included: true  },
      { label: 'Air mineral',                                                             included: true  },
      { label: 'Airport Tax, Fuel Surcharge, ADM Visa Group IDR 2.984.472',              included: false },
      { label: 'Tipping Tour Leader, Local Guide & Driver IDR 750.000',                  included: false },
      { label: 'PPN 1,1%',                                                               included: false },
      { label: 'Pembuatan paspor & dokumen lainnya',                                     included: false },
      { label: 'Pengeluaran pribadi & Optional tour',                                    included: false },
    ],
    mapCenter: [126.9780, 37.5665],
    mapZoom: 11,
    mapPins: [
      { lng: 127.0276, lat: 37.5140, label: 'N Seoul Tower (Gunung Namsan)' },
      { lng: 126.9220, lat: 37.5563, label: 'Hongdae Street' },
      { lng: 126.9857, lat: 37.5600, label: 'Myeongdong Shopping Street' },
      { lng: 126.9991, lat: 37.5696, label: 'Gwangjang Market' },
      { lng: 126.9718, lat: 37.5707, label: 'Han River Park' },
    ]
  },

  '7D PREMIUM NEW YEAR VIETNAM HANOI SAPA FANSIPAN + HALONG BAY CRUISE': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1555921015-5532091f6026?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1516496636080-14fb876e029d?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'Rayakan Tahun Baru 2027 via Singapore Airlines! Fansipan "Roof of Indochina", Cat Cat Village, cruise Halong Bay Junk Boat, Mega Grand World & Hanoi Old Quarter.',
    price: 'Rp 14.990.000',
    duration: '7 Hari 6 Malam',
    rating: 4.8,
    reviews: 112,
    maxPax: 20,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Singapore Airlines SQ951/SQ192/SQ193/SQ950 (Economy, Group)',
    keberangkatan: '31 Desember 2026 (New Year)',
    minPeserta: '20 Peserta',
    hotelInfoText: 'Hotel ★4 Setaraf (Hanoi, Sapa & Ha Long)',
    tipeKamarText: 'Twin/Triple | Single Supplement +Rp 3.250.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Singapore Airlines SQ (Economy, Group Fixed Date)' },
      { icon: '🧳', text: 'Bagasi 25 kg sesuai ketentuan Singapore Airlines' },
      { icon: '🏔️', text: 'Fansipan 3.143m — "The Roof of Indochina"' },
      { icon: '🚡', text: 'Cable Car Fansipan ±20 mnt — panorama Hoang Lien Son' },
      { icon: '🏘️', text: 'Cat Cat Village — desa tradisional suku H\'mong' },
      { icon: '⛵', text: 'Halong Bay Junk Boat — makan siang seafood di atas kapal' },
      { icon: '🌊', text: 'ThienCung Cave & Dau Go Grotto — stalaktit menakjubkan' },
      { icon: '🎆', text: 'Mega Grand World Hanoi — nuansa Venezia & Korea' },
      { icon: '🎉', text: 'Rayakan Tahun Baru di Vietnam, 31 Des 2026' },
      { icon: '🛡️', text: 'Travel Insurance s.d. usia 82 tahun' },
    ],
    priceCategories: [
      {
        dateLabel: '31 Desember 2026 — New Year',
        prices: [
          { type: 'Dewasa (Twin/Triple)',      price: 'Rp 14.990.000' },
          { type: 'Child No Bed (<6 Tahun)',   price: 'Rp 14.590.000' },
          { type: 'Single Supplement',          price: '+Rp 3.250.000' },
          { type: 'Infant Flat Rate (<23 Bln)', price: 'Rp 4.000.000' },
        ]
      }
    ],
    optionalActivities: [
      { name: 'Funicular ke puncak Fansipan', price: 'USD 14/Pax' },
      { name: 'Rental Wifi / SIM Card Portable', price: 'Tersedia' },
    ],
    itinerary: [
      {
        day: 'Hari 01',
        title: 'JAKARTA – HANOI (Meals on Board)',
        desc: 'CGK (05.25) – SIN (08.05) by SQ 951, lanjut SIN (09.05) – HAN (11.30) by SQ 192. Berkumpul di Bandara Soekarno-Hatta Terminal 3. Tiba di Hanoi, disambut Guide lokal berbahasa Indonesia. Langsung menuju Mega Grand World — kawasan wisata modern memadukan nuansa Venezia dengan kanal air dan jalanan tematik bergaya Korea yang ramai & penuh warna. Check-in hotel ★4.'
      },
      {
        day: 'Hari 02',
        title: 'HANOI – SAPA – CAT CAT VILLAGE (Makan Pagi, Siang)',
        desc: 'Perjalanan menuju Sapa menikmati panorama pegunungan dan pedesaan Vietnam Utara. Cat Cat Village — desa tradisional suku H\'mong, aktivitas bertani & beternak lokal, air terjun Cat Cat, dan Hydro Electric Power Station peninggalan Perancis. Kemudian Sapa Church (gereja ikonik bergaya Prancis) dan Sapa Lake. Check-in hotel.'
      },
      {
        day: 'Hari 03',
        title: 'SAPA – FANSIPAN – HANOI (Makan Pagi, Siang, Malam)',
        desc: 'Menuju Gunung Fansipan — "The Roof of Indochina". Naik Cable Car ±20 menit menikmati panorama spektakuler Pegunungan Hoang Lien Son. Tiba di ketinggian 2.800m, kunjungi kompleks pagoda spiritual, lalu mendaki ±600 anak tangga menuju puncak (atau optional Funicular USD 14/pax). Kembali ke Hanoi, check-in hotel.'
      },
      {
        day: 'Hari 04',
        title: 'HANOI – HALONG (Makan Pagi, Siang)',
        desc: 'Menjelajahi Hanoi: St. Joseph Cathedral (gereja tertua Hanoi), Ho Chi Minh\'s House & Mausoleum, Ba Dinh Square, One-Pillar Pagoda, dan Buddhist Tran Quoc Pagoda on Westlake (pagoda tertua Vietnam). Lanjut ke Ha Long menikmati pemandangan Red River Delta. Malam bebas di VuiFest Night Market. Check-in hotel.'
      },
      {
        day: 'Hari 05',
        title: 'HALONG ISLAND TOUR – HANOI (Makan Pagi, Siang)',
        desc: 'Jelajahi pulau-pulau Halong dengan Junk Boat tradisional. ThienCung Cave (stalaktit & stalagmit menakjubkan) dan Dau Go Grotto (strategi Jenderal Tran Hung Dao melawan Mongol, 1288). Formasi batu unik: Chicken Rock, Incense Bowl Islet, Sail Islet, Turtle Island. Makan siang seafood di atas kapal sambil menikmati perairan hijau zamrud dan tebing batu kapur megah. Kembali ke Hanoi, waktu bebas di Old Quarter.'
      },
      {
        day: 'Hari 06',
        title: 'HANOI – SINGAPORE (Makan Pagi, Meals on Board)',
        desc: 'HAN (18.25) – SIN (23.05) by SQ 193. Sarapan pagi, waktu bebas hingga waktu yang ditentukan. Dijemput menuju bandara, transit ke Singapura. Bermalam di pesawat.'
      },
      {
        day: 'Hari 07',
        title: 'SINGAPORE – JAKARTA (Meals on Board)',
        desc: 'SIN (06.50) – CGK (07.35) by SQ 950. Penerbangan dari Singapura menuju Jakarta. Tiba di Jakarta — sampai jumpa di tour selanjutnya!'
      }
    ],
    inclusions: [
      { label: 'Tiket International Jakarta–Hanoi PP by Singapore Airlines Economy',       included: true  },
      { label: 'Bagasi 25 kg sesuai ketentuan airlines',                                    included: true  },
      { label: 'Akomodasi hotel ★4 setaraf (Twin/Triple) — Hanoi, Sapa & Ha Long',         included: true  },
      { label: 'Transportasi bus pariwisata & tiket masuk objek wisata',                    included: true  },
      { label: 'Makan sesuai program & mineral water 1 botol/hari',                         included: true  },
      { label: 'Tour Leader Indonesia',                                                      included: true  },
      { label: 'Travel Kits (Luggage Tag)',                                                  included: true  },
      { label: 'Travel Insurance s.d. usia 82 tahun',                                       included: true  },
      { label: 'Tipping Tour Leader, Local Guide & Driver: Rp 950.000/Pax',                 included: false },
      { label: 'Tips porter, mini bar, laundry, telp, kelebihan bagasi',                    included: false },
      { label: 'PPN 1,2%',                                                                   included: false },
      { label: 'Funicular ke puncak Fansipan: USD 14/Pax (optional)',                       included: false },
      { label: 'Rental Wifi / SIM Card Portable (optional)',                                 included: false },
      { label: 'Tidak ada refund jika ditolak imigrasi setempat',                           included: false },
    ],
    mapCenter: [105.8412, 21.0245],
    mapZoom: 7,
    mapPins: [
      { lng: 105.8412, lat: 21.0245, label: 'Hanoi — Mega Grand World & Old Quarter' },
      { lng: 103.8437, lat: 22.3364, label: 'Sapa — Cat Cat Village & Fansipan' },
      { lng: 107.0843, lat: 20.9101, label: 'Ha Long Bay — Junk Boat Cruise' },
    ]
  },

  '6D WINTER HOLIDAY HONGKONG SHENZHEN GUANGZHOU ZHUHAI + DISNEYLAND': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1536599018102-9f803c140fc1?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1536599018102-9f803c140fc1?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1518005068251-37900150dfca?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: '4 kota + HK Disneyland via Garuda Indonesia! Victoria Peak, Avenue of Stars, Huang Fei Hong Memorial Hall, Melania Town & satu hari penuh di Disneyland.',
    price: 'Rp 14.990.000 – Rp 15.990.000',
    duration: '6 Hari 5 Malam',
    rating: 4.6,
    reviews: 74,
    maxPax: 20,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Garuda Indonesia GA860/GA863 (Economy, Group Fixed Date, No Extend)',
    keberangkatan: '16–19 Des 2026 (Early School Holiday)',
    minPeserta: '20 Peserta',
    hotelInfoText: 'Hotel ★4 Lokal atau ★3 Setaraf',
    tipeKamarText: 'Twin/Triple | Single Supplement +Rp 3.000.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Garuda Indonesia GA860/GA863 (Economy Class)' },
      { icon: '🧳', text: 'Bagasi 30 kg' },
      { icon: '🆓', text: 'FREE Group Visa 144 China' },
      { icon: '🏔️', text: 'Victoria Peak — panorama skyline Hongkong' },
      { icon: '⭐', text: 'Avenue of Stars — penghargaan selebritas HK' },
      { icon: '🎡', text: 'Hong Kong Disneyland — seharian penuh (tiket included)' },
      { icon: '🏯', text: 'Huang Fei Hong Memorial Hall — legenda bela diri Tiongkok' },
      { icon: '🏙️', text: 'Melania Town Shenzhen — nuansa Eropa instagramable' },
      { icon: '👥', text: 'Minimal 20 Pax + Tour Leader Indonesia' },
      { icon: '🛡️', text: 'Travel Insurance s.d. usia 82 tahun' },
    ],
    priceCategories: [
      {
        dateLabel: '16 Des 2026 — Early School Holiday',
        prices: [
          { type: 'Dewasa (Twin/Triple)',   price: 'Rp 14.990.000' },
          { type: 'Child No Bed (Maks 6th)', price: 'Rp 13.990.000' },
          { type: 'Single Supplement',       price: '+Rp 3.000.000' },
        ]
      },
      {
        dateLabel: '17 Des 2026 — Early School Holiday',
        prices: [
          { type: 'Dewasa (Twin/Triple)',   price: 'Rp 15.290.000' },
          { type: 'Child No Bed (Maks 6th)', price: 'Rp 14.290.000' },
          { type: 'Single Supplement',       price: '+Rp 3.000.000' },
        ]
      },
      {
        dateLabel: '18 Des 2026 — Early School Holiday',
        prices: [
          { type: 'Dewasa (Twin/Triple)',   price: 'Rp 15.590.000' },
          { type: 'Child No Bed (Maks 6th)', price: 'Rp 14.590.000' },
          { type: 'Single Supplement',       price: '+Rp 3.000.000' },
        ]
      },
      {
        dateLabel: '19 Des 2026 — Early School Holiday',
        prices: [
          { type: 'Dewasa (Twin/Triple)',   price: 'Rp 15.990.000' },
          { type: 'Child No Bed (Maks 6th)', price: 'Rp 14.990.000' },
          { type: 'Single Supplement',       price: '+Rp 3.000.000' },
        ]
      },
      {
        dateLabel: 'Infant Flat Rate',
        prices: [
          { type: 'Infant (<23 Bulan)', price: 'Rp 4.000.000' },
        ]
      }
    ],
    optionalActivities: [
      { name: 'Rental Wifi / SIM Card Portable', price: 'Tersedia' },
    ],
    itinerary: [
      {
        day: 'Hari 01',
        title: 'JAKARTA – DEPARTURE (Meals on Board)',
        desc: 'CGK (23.50) – HKG (05.45) by GA 860. Malam hari berkumpul di Bandara Soekarno-Hatta Terminal 3 Ultimate untuk berangkat menuju Hongkong dengan Garuda Indonesia. Bermalam di pesawat.'
      },
      {
        day: 'Hari 02',
        title: 'HONGKONG – SHENZHEN (Makan Malam)',
        desc: 'Tiba di Bandara Chek Lap Kok, disambut Guide berbahasa Indonesia. Victoria Peak (top level) — panorama kota dari ketinggian. Golden Bauhinia Square — spot foto berlatar pelabuhan. Avenue of Stars — penghormatan seniman & selebritas HK. TST Clock Tower. Berbelanja di Jewellery & Chocolate Shop. Perjalanan ke Shenzhen, check-in hotel ★4 Lokal atau ★3 setaraf.'
      },
      {
        day: 'Hari 03',
        title: 'SHENZHEN – GUANGZHOU (Makan Pagi, Siang)',
        desc: 'Jade Shop & Herbs Shop. Photo stop Civic Center. Melania Town — kawasan wisata bernuansa Eropa yang instagramable. Lanjut ke Guangzhou: Haixinsha Square Asian Games Park (venue pembukaan Asian Games 2010, pinggir Sungai Pearl) & Huacheng Square (pusat kota baru modern ikonik). Check-in hotel.'
      },
      {
        day: 'Hari 04',
        title: 'GUANGZHOU – FOSHAN – ZHUHAI (Makan Pagi, Siang)',
        desc: 'Yuexiu Park — taman terbesar kota, suasana hijau asri. Perjalanan ke Foshan: Ancestral Temple & Huang Fei Hong Memorial Hall (tempat yang didedikasikan untuk legenda bela diri Tiongkok Huang Feihong). Perjalanan ke Zhuhai, berbelanja di Silk Shop. Check-in hotel.'
      },
      {
        day: 'Hari 05',
        title: 'ZHUHAI – HONGKONG DISNEYLAND (Makan Pagi)',
        desc: 'Perjalanan ke Hongkong via Golden Shuttle Bus melewati HZM Bridge. Seharian penuh di Hong Kong Disneyland — tiket masuk & transportasi 2 arah sudah termasuk. Nikmati berbagai wahana menarik, parade, dan pertunjukan spektakuler kelas dunia. Check-in hotel.'
      },
      {
        day: 'Hari 06',
        title: 'HONGKONG – JAKARTA (Makan Pagi/Box, Meals on Board)',
        desc: 'HKG (09.30) – CGK (13.15) by GA 863. Perjalanan ke Hong Kong International Airport untuk penerbangan kembali ke Jakarta. Sampai jumpa di tour selanjutnya!'
      }
    ],
    inclusions: [
      { label: 'Tiket International Jakarta–HK PP by Garuda Indonesia Economy (Fixed Date)',  included: true  },
      { label: 'Bagasi 30 kg atau sesuai ketentuan airlines',                                  included: true  },
      { label: 'Akomodasi hotel ★4 Lokal atau ★3 setaraf (Twin/Triple)',                      included: true  },
      { label: 'Transportasi bus pariwisata & tiket masuk objek wisata',                       included: true  },
      { label: 'Makan sesuai program & mineral water 1 botol/hari',                            included: true  },
      { label: 'Tour Leader Indonesia',                                                         included: true  },
      { label: 'Group Visa 144 China',                                                          included: true  },
      { label: 'Travel Kits (Luggage Tag)',                                                     included: true  },
      { label: 'Travel Insurance s.d. usia 82 tahun',                                          included: true  },
      { label: 'Tipping Tour Leader, Local Guide & Driver: Rp 950.000/Pax',                    included: false },
      { label: 'Tips porter, mini bar, laundry, telp, kelebihan bagasi',                       included: false },
      { label: 'PPN 1,2%',                                                                      included: false },
      { label: 'Rental Wifi / SIM Card Portable',                                               included: false },
    ],
    mapCenter: [113.9000, 22.5000],
    mapZoom: 7,
    mapPins: [
      { lng: 114.1497, lat: 22.2760, label: 'Victoria Peak — Hongkong' },
      { lng: 114.0364, lat: 22.3734, label: 'Hong Kong Disneyland' },
      { lng: 114.0618, lat: 22.5396, label: 'Melania Town — Shenzhen' },
      { lng: 113.2644, lat: 23.1291, label: 'Haixinsha Park — Guangzhou' },
      { lng: 113.1219, lat: 23.0219, label: 'Huang Fei Hong Hall — Foshan' },
      { lng: 113.5767, lat: 22.2745, label: 'Zhuhai' },
    ]
  },

  'Hongkong Shenzhen Macau by GA 06 Hari / 04 Malam': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1536599018102-9f803c140fc1?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1536599018102-9f803c140fc1?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1518005068251-37900150dfca?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1555217851-6141535c4789?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: '3 kota via Garuda Indonesia! Victoria Peak, Avenue of Stars, Ruin of St. Paul, Venetian Macau & Gankeng Hakka Town. Free China Visa Group untuk WNI.',
    price: 'Rp 10.780.000 – Rp 10.980.000',
    duration: '6 Hari 4 Malam',
    rating: 4.6,
    reviews: 87,
    maxPax: 20,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Garuda Indonesia GA860/GA863 (Economy Class, Group)',
    keberangkatan: 'AUG 2026: 13, 20, 25 Agustus',
    minPeserta: '20 Peserta',
    hotelInfoText: 'Dejin/Atour/Vienna (SZX) · Casa Real/Regency Art/Grand Dragon (MFM) · Panda Hotel (HKG)',
    tipeKamarText: 'Twin Sharing | Single Supplement +Rp 3.500.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Garuda Indonesia GA860/GA863 (Economy, Group)' },
      { icon: '🧳', text: 'Bagasi sesuai ketentuan Garuda Indonesia' },
      { icon: '🆓', text: 'FREE China Visa Group untuk WNI' },
      { icon: '🏔️', text: 'Victoria Peak — skyline Hongkong dari ketinggian' },
      { icon: '⭐', text: 'Avenue of Stars — penghargaan perfilman HK' },
      { icon: '🏰', text: 'Ruin of St. Paul — ikon gereja Katolik abad ke-16' },
      { icon: '🎰', text: 'Venetian Complex Macau — "Las Vegas of Asia"' },
      { icon: '🏘️', text: 'Gankeng Hakka Town — kota kuno berarsitektur unik' },
      { icon: '🏙️', text: 'Ping An Finance Center — gedung ±599m, >100 lantai' },
      { icon: '👥', text: 'Minimal 20 Pax + Tour Leader Indonesia berpengalaman' },
    ],
    priceCategories: [
      {
        dateLabel: '20 Agustus 2026',
        prices: [
          { type: 'Adult / Child Twin / Child Extra Bed', price: 'Rp 10.780.000' },
          { type: 'Child No Bed (Maks 6th)',              price: 'Rp 10.480.000' },
          { type: 'Single Supplement',                    price: '+Rp 3.500.000' },
        ]
      },
      {
        dateLabel: '13 & 25 Agustus 2026',
        prices: [
          { type: 'Adult / Child Twin / Child Extra Bed', price: 'Rp 10.980.000' },
          { type: 'Child No Bed (Maks 6th)',              price: 'Rp 10.680.000' },
          { type: 'Single Supplement',                    price: '+Rp 3.500.000' },
        ]
      }
    ],
    optionalActivities: [
      { name: 'Splendid China + China Folk Culture Village + Show / Window of the World', price: 'RMB 350/Pax' },
      { name: 'Shijingshan Mountain Cable Car + Dinner + Night Market',                   price: 'RMB 350/Pax' },
      { name: 'SZX Diwang Building',                                                       price: 'RMB 180/Pax' },
      { name: 'Rental Wifi / SIM Card Portable',                                           price: 'Tersedia' },
    ],
    itinerary: [
      {
        day: 'Day 01',
        title: 'JAKARTA – HONGKONG (GA860 CGK–HKG 22.50–05.45+1)',
        desc: 'Berkumpul di Bandara Internasional Soekarno Hatta untuk penerbangan menuju Hongkong dengan Garuda Indonesia GA860. Bermalam di pesawat.'
      },
      {
        day: 'Day 02',
        title: 'HONGKONG – SHENZHEN (-/L/-)',
        desc: 'Tiba di Hongkong, lanjut perjalanan ke Shenzhen. Kunjungi Melania Town — kawasan arsitektur Eropa dengan banyak spot foto instagramable dan suasana romantis European night street. Kemudian Dongmen Street — jalan tertua sejak Dinasti Ming, bangunan tradisional khas Tiongkok kuno.'
      },
      {
        day: 'Day 03',
        title: 'SHENZHEN (B/L/-)',
        desc: 'Gankeng Hakka Town — kota kuno berarsitektur khas Hakka. Photo stop Shenzhen Civic Center (landmark modern beratap menyerupai burung mengepak, bermandikan lampu LED malam hari). Nantou Ancient City — kota tua bersejarah Shenzhen. Photo stop Ping An Finance Center (±599m, >100 lantai). Akhiri hari di COCO Park — mall & pusat hiburan terpopuler Shenzhen.'
      },
      {
        day: 'Day 04',
        title: 'SHENZHEN – MACAU (B/-/-)',
        desc: 'Setelah sarapan, perjalanan menuju Macau. Kunjungi Ruin of St. Paul (gereja Katolik terbesar pada masanya). Photo stop Eiffel Macau. Kunjungi Venetian Complex — kanal indoor dengan gondola & pengemudi bernyanyi, ikon "Las Vegas of Asia" yang paling terkenal di Macau.'
      },
      {
        day: 'Day 05',
        title: 'MACAU – HONGKONG (B/L/-)',
        desc: 'Perjalanan ke Hongkong menggunakan bus. Avenue of Stars (penghormatan industri perfilman HK). Clock Tower Tsim Sha Tsui (landmark bersejarah 44 meter). Victoria Peak — titik tertinggi HK, panorama skyline ikonik. 1881 Heritage — butik & restoran arsitektur kolonial. Ladies Market Shopping Area.'
      },
      {
        day: 'Day 06',
        title: 'HONGKONG – JAKARTA (B/-/- GA863 HKG–CGK 09.30–13.15)',
        desc: 'Diantar ke Bandara Hongkong untuk penerbangan kembali ke Jakarta dengan GA863. Tiba di Jakarta, berakhirlah perjalanan tour dengan sejuta kenangan manis. Terima kasih atas partisipasi Anda!'
      }
    ],
    inclusions: [
      { label: 'Tiket pesawat PP Economy Garuda Indonesia (non-endorsable, non-refundable)',  included: true  },
      { label: 'Airport tax internasional',                                                    included: true  },
      { label: 'FREE China Visa Group untuk WNI',                                             included: true  },
      { label: 'Akomodasi hotel ★4 berdasarkan min. 2 orang/kamar (twin sharing)',            included: true  },
      { label: 'Transportasi bus pariwisata & tiket masuk objek wisata',                      included: true  },
      { label: 'Makan sesuai program (B=Pagi, L=Siang, D=Malam)',                             included: true  },
      { label: 'Tour Leader berpengalaman dari Indonesia',                                     included: true  },
      { label: 'Kunjungan Mandatory Shops (Jade, Herb, Jewelry, Chocolate, Souvenir)',        included: true  },
      { label: 'Biaya dokumen (paspor, entry permit, dll.)',                                   included: false },
      { label: 'Pengeluaran pribadi (telp, room service, laundry, mini bar, dll.)',            included: false },
      { label: 'Excess baggage & bea masuk',                                                   included: false },
      { label: 'Travelling bag',                                                               included: false },
      { label: 'Tips Tour Leader, Local Guide & Driver: IDR 850.000/Pax',                     included: false },
      { label: 'PPN 1,1% | Optional Tour | Asuransi Perjalanan Group',                        included: false },
    ],
    mapCenter: [114.1095, 22.3964],
    mapZoom: 8,
    mapPins: [
      { lng: 114.1497, lat: 22.2760, label: 'Victoria Peak — Hongkong' },
      { lng: 114.1694, lat: 22.2948, label: 'Avenue of Stars — Tsim Sha Tsui' },
      { lng: 113.5438, lat: 22.1987, label: 'Venetian & Ruin of St. Paul — Macau' },
      { lng: 114.0618, lat: 22.5396, label: 'Shenzhen Civic Center' },
      { lng: 114.2495, lat: 22.7282, label: 'Gankeng Hakka Town — Shenzhen' },
      { lng: 114.1295, lat: 22.5431, label: 'Ping An Finance Center — Shenzhen' },
    ]
  },

  '7D SPECIAL COMPLETE HOSEZHUMAGU +DISNEYLAND': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1536599018102-9f803c140fc1?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1536599018102-9f803c140fc1?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1555217851-6141535c4789?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1518005068251-37900150dfca?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: '5 kota dalam 7 hari via Garuda Indonesia! Victoria Peak, HK Disneyland, Venetian Macau, Fengjian Water Town, Ruin of St. Paul & Avenue of Stars.',
    price: 'Rp 18.390.000',
    duration: '7 Hari 6 Malam',
    rating: 4.7,
    reviews: 98,
    maxPax: 20,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Garuda Indonesia (Economy, Group Fixed Date, No Extend)',
    keberangkatan: '20–24 Des 2026 (Christmas) | 26–27 Des 2026 (New Year)',
    minPeserta: '20 Peserta',
    hotelInfoText: 'Hotel ★4 Lokal atau ★3 Setaraf',
    tipeKamarText: 'Twin/Triple | Single Supplement +Rp 4.500.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Garuda Indonesia GA860/GA863 (Economy Class)' },
      { icon: '🧳', text: 'Bagasi 30 kg' },
      { icon: '🏔️', text: 'Victoria Peak — panorama Hongkong dari ketinggian' },
      { icon: '⭐', text: 'Avenue of Stars — penghargaan selebritas HK' },
      { icon: '🎡', text: 'Hong Kong Disneyland (tiket + transport included)' },
      { icon: '🏰', text: 'Ruin of St. Paul — fasad gereja Katolik abad ke-16' },
      { icon: '🎰', text: 'Venetian Shopping Arcade — nuansa Venezia di Macau' },
      { icon: '🌊', text: 'Fengjian Water Town — desa air klasik nan tenang' },
      { icon: '👥', text: 'Minimal 20 Pax + Tour Leader Indonesia' },
      { icon: '🛡️', text: 'Travel Insurance s.d. usia 82 tahun' },
    ],
    priceCategories: [
      {
        dateLabel: '20 Des 2026 — Christmas',
        prices: [
          { type: 'Dewasa Twin/Triple',             price: 'Rp 18.390.000' },
          { type: 'Child w/ Extra Bed (Maks 12th)', price: 'Rp 18.390.000' },
          { type: 'Child No Bed (Maks 6th)',         price: 'Rp 17.390.000' },
          { type: 'Single Supplement',               price: '+Rp 4.500.000' },
        ]
      },
      {
        dateLabel: '21 Des 2026 — Christmas',
        prices: [
          { type: 'Dewasa Twin/Triple',             price: 'Rp 18.590.000' },
          { type: 'Child w/ Extra Bed (Maks 12th)', price: 'Rp 18.590.000' },
          { type: 'Child No Bed (Maks 6th)',         price: 'Rp 17.590.000' },
          { type: 'Single Supplement',               price: '+Rp 4.500.000' },
        ]
      },
      {
        dateLabel: '22–23–24 Des 2026 — Christmas',
        prices: [
          { type: 'Dewasa Twin/Triple',             price: 'Rp 18.990.000' },
          { type: 'Child w/ Extra Bed (Maks 12th)', price: 'Rp 18.990.000' },
          { type: 'Child No Bed (Maks 6th)',         price: 'Rp 17.990.000' },
          { type: 'Single Supplement',               price: '+Rp 4.500.000' },
        ]
      },
      {
        dateLabel: '26 Des 2026 — New Year',
        prices: [
          { type: 'Dewasa Twin/Triple',             price: 'Rp 19.690.000' },
          { type: 'Child w/ Extra Bed (Maks 12th)', price: 'Rp 19.690.000' },
          { type: 'Child No Bed (Maks 6th)',         price: 'Rp 18.690.000' },
          { type: 'Single Supplement',               price: '+Rp 4.500.000' },
        ]
      },
      {
        dateLabel: '27 Des 2026 — New Year',
        prices: [
          { type: 'Dewasa Twin/Triple',             price: 'Rp 19.990.000' },
          { type: 'Child w/ Extra Bed (Maks 12th)', price: 'Rp 19.990.000' },
          { type: 'Child No Bed (Maks 6th)',         price: 'Rp 18.990.000' },
          { type: 'Single Supplement',               price: '+Rp 4.500.000' },
        ]
      },
      {
        dateLabel: 'Infant Flat Rate',
        prices: [
          { type: 'Infant (<23 Bulan)', price: 'Rp 3.750.000' },
        ]
      }
    ],
    optionalActivities: [
      { name: 'Rental Wifi / SIM Card Portable', price: 'Tersedia' },
    ],
    itinerary: [
      {
        day: 'Hari 01',
        title: 'JAKARTA – DEPARTURE (Meals on Board)',
        desc: 'CGK (23.50) – HKG (05.45) by GA 860. Malam hari berkumpul di Bandara Soekarno-Hatta Terminal 3 Ultimate untuk berangkat menuju Hongkong dengan Garuda Indonesia. Bermalam di pesawat.'
      },
      {
        day: 'Hari 02',
        title: 'HONGKONG – SHENZHEN (Makan Malam)',
        desc: 'Tiba di Bandara Chek Lap Kok, disambut Guide berbahasa Indonesia. Kunjungi Victoria Peak (top level) dengan bus, Golden Bauhinia Square, Avenue of Stars (penghargaan selebritas HK), TST Clock Tower, dan Souvenir Shop. Perjalanan ke Shenzhen, check-in hotel ★4 Lokal atau ★3 setaraf.'
      },
      {
        day: 'Hari 03',
        title: 'SHENZHEN – GUANGZHOU (Makan Pagi, Siang)',
        desc: 'Jade Shop & Herbs Shop. Photo stop Civic Center. Kunjungi Melania Town (kawasan bernuansa Eropa). Lanjut ke Guangzhou: Haixinsha Square Asian Games Park (venue pembukaan Asian Games 2010, pinggir Sungai Pearl) & Huacheng Square (pusat kota baru ikonik). Check-in hotel.'
      },
      {
        day: 'Hari 04',
        title: 'GUANGZHOU – FOSHAN – ZHUHAI (Makan Pagi, Siang)',
        desc: 'Yuexiu Park — taman terbesar kota. Perjalanan ke Foshan: Ancestral Temple, Huang Fei Hong Memorial Hall (legenda bela diri Tiongkok), Grand Arch, dan Fengjian Water Town (desa air tradisional, kanal tenang, jembatan batu kuno). Lanjut ke Zhuhai, check-in hotel.'
      },
      {
        day: 'Hari 05',
        title: 'ZHUHAI – MACAU – ZHUHAI (Makan Pagi, Siang)',
        desc: 'Fishing Girl Statue (landmark Zhuhai) & Zhuhai Lover Road. Silk Shop & Latex/Bamboo Shop. City tour Macau: Senado Square (lantai mosaik khas Portugis), Ruin of St. Paul (fasad gereja Katolik abad ke-16), Souvenir Shop, dan Venetian Shopping Arcade (resort bernuansa Venezia). Kembali ke Zhuhai.'
      },
      {
        day: 'Hari 06',
        title: 'ZHUHAI – HONGKONG (Makan Pagi)',
        desc: 'Perjalanan ke Hongkong via Golden Shuttle Bus melewati HZM Bridge. Seharian penuh di Hong Kong Disneyland — tiket masuk & transportasi 2 arah sudah termasuk. Nikmati wahana, parade, dan pertunjukan spektakuler. Check-in hotel.'
      },
      {
        day: 'Hari 07',
        title: 'HONGKONG – JAKARTA (Makan Pagi/Box, Meals on Board)',
        desc: 'HKG (09.30) – CGK (13.15) by GA 863. Perjalanan ke Hong Kong International Airport untuk penerbangan kembali ke Jakarta. Sampai jumpa di tour selanjutnya!'
      }
    ],
    inclusions: [
      { label: 'Tiket International Jakarta–HK PP by Garuda Indonesia Economy (Fixed Date)',  included: true  },
      { label: 'Bagasi 30 kg atau sesuai ketentuan airlines',                                  included: true  },
      { label: 'Akomodasi hotel ★4 Lokal atau ★3 setaraf (Twin/Triple)',                      included: true  },
      { label: 'Transportasi bus pariwisata & tiket masuk objek wisata',                       included: true  },
      { label: 'Makan sesuai program & mineral water 1 botol/hari',                            included: true  },
      { label: 'Tour Leader Indonesia',                                                         included: true  },
      { label: 'Group Visa 144 China',                                                          included: true  },
      { label: 'Travel Kits (Luggage Tag)',                                                     included: true  },
      { label: 'Travel Insurance s.d. usia 82 tahun',                                          included: true  },
      { label: 'Tipping Tour Leader, Local Guide & Driver: Rp 1.100.000/Pax',                  included: false },
      { label: 'Tips porter, mini bar, laundry, telp, kelebihan bagasi',                       included: false },
      { label: 'PPN 1,2%',                                                                      included: false },
      { label: 'Rental Wifi / SIM Card Portable',                                               included: false },
    ],
    mapCenter: [114.1095, 22.3964],
    mapZoom: 7,
    mapPins: [
      { lng: 114.1497, lat: 22.2760, label: 'Victoria Peak — Hongkong' },
      { lng: 114.0364, lat: 22.3734, label: 'Hong Kong Disneyland' },
      { lng: 113.5438, lat: 22.1987, label: 'Venetian Macau & Ruin of St. Paul' },
      { lng: 113.5767, lat: 22.2745, label: 'Zhuhai & Fengjian Water Town' },
      { lng: 113.2644, lat: 23.1291, label: 'Guangzhou & Haixinsha Park' },
      { lng: 114.0579, lat: 22.5431, label: 'Shenzhen Civic Center' },
    ]
  },

  '7D NEW YEAR SALE CHINA - CHONGQING CHENGDU': {
    badge: 'PAKET INTERNASIONAL',
    image: 'assets/china-poster.jpg',
    galleryImages: [
      'assets/china-poster.jpg',
      'https://images.unsplash.com/photo-1526029655235-4f64396c0166?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: '7D New Year Special China: Chongqing & Chengdu (Kuixing Building, Liziba, Hongyadong, Panda Paradise)',
    price: 'Rp 13.990.000 - Rp 14.990.000',
    duration: '7 Hari 6 Malam',
    rating: 4.8,
    reviews: 185,
    maxPax: 20,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Malaysia Airlines',
    keberangkatan: '30 & 31 Des 2026',
    minPeserta: '20 Peserta',
    hotelInfoText: 'Hotel *3 atau *4 Local',
    tipeKamarText: 'Twin Share / Triple',
    highlights: [
      { icon: '✈️', text: 'Malaysia Airlines (MH716/MH526/MH527/MH713)' },
      { icon: '🧳', text: 'Bagasi 30 kg' },
      { icon: '🐼', text: 'Panda Paradise Dujiangyan (inc. battery car)' },
      { icon: '🚝', text: 'Liziba (Stasiun Kereta Menembus Gedung)' },
      { icon: '🏮', text: 'Hongyadong Ancient Architecture' },
      { icon: '🏢', text: 'Kuixing Building Unique Architecture' },
      { icon: '🏬', text: 'IFS Rooftop Panda & Taikoo Li' },
      { icon: '👥', text: 'Minimal 20 Pax (Didampingi 1 Tour Leader)' },
      { icon: '🛡️', text: 'Travel Insurance s.d. Usia 82 Tahun' },
      { icon: '💼', text: 'Komisi Cabang: Rp 350.000 | Mitra: Rp 300.000' },
    ],
    priceCategories: [
      {
        dateLabel: 'Keberangkatan 30 DEC 2026 (NEW YEAR)',
        prices: [
          { type: 'Dewasa Twin/Triple', price: 'Rp 14.990.000' },
          { type: 'Child with Extra Bed (<12 Tahun)', price: 'Rp 14.990.000' },
          { type: 'Child No Bed (<6 Tahun)', price: 'Rp 14.590.000' },
          { type: 'Single Supplement', price: '+Rp 4.500.000' },
        ]
      },
      {
        dateLabel: 'Keberangkatan 31 DEC 2026 (NEW YEAR)',
        prices: [
          { type: 'Dewasa Twin/Triple', price: 'Rp 13.990.000' },
          { type: 'Child with Extra Bed (<12 Tahun)', price: 'Rp 13.990.000' },
          { type: 'Child No Bed (<6 Tahun)', price: 'Rp 13.590.000' },
          { type: 'Single Supplement', price: '+Rp 4.500.000' },
        ]
      },
      {
        dateLabel: 'Infant Rate',
        prices: [
          { type: 'Infant Flat Rate (<23 Bulan)', price: 'Rp 3.750.000' }
        ]
      }
    ],
    optionalActivities: [
      { name: 'Sichuan Face Changing Show', price: '280 RMB/Pax' },
      { name: 'Chongqing Two Rivers Cruise', price: '280 RMB/Pax' },
      { name: 'Chongqing 1949 Show', price: '398 RMB/Pax' },
      { name: 'Hongya Cave Hanfu Changing + Photo', price: '398 RMB/Pax' },
      { name: 'Roomtop View + Take Photo + Rappelling', price: '598 RMB/Pax' },
      { name: 'Motorcycle + Photography', price: '598 RMB/Pax' },
      { name: 'Rental Wifi Portable / SIM Card', price: 'Tersedia' },
    ],
    itinerary: [
      {
        day: 'H1',
        title: 'JAKARTA – CHENGDU',
        desc: 'CGK (12.15) - KUL (15.20) by MH716, lanjut KUL (19.25) - TFU (00.15)+1 by MH526. Berkumpul di Bandara dan berangkat menuju Chengdu. Bermalam di Hotel *3 atau *4 local / similar.'
      },
      {
        day: 'H2',
        title: 'CHENGDU – CHONGQING (Makan Pagi, Siang, Malam)',
        desc: 'Jemput dari bandara, check-in hotel, sarapan pagi. Perjalanan menuju Chongqing by bus. Kunjungi Ciqikou Ancient Town & Guanyinqiao Street. Optional: Chongqing 1949 Show. Bermalam di Hotel *3 atau *4 local.'
      },
      {
        day: 'H3',
        title: 'CHONGQING (Makan Pagi, Siang)',
        desc: 'Sarapan di hotel. Belanja di Latex Shop. Kunjungi Danzishi, Liziba (photostop stasiun ikonik kereta menembus gedung), Kuixing Building (arsitektur unik), Jiefangbei, & Hongyadong. Optional: Chongqing Two Rivers Cruise.'
      },
      {
        day: 'H4',
        title: 'CHONGQING – CHENGDU (Makan Pagi, Siang, Malam)',
        desc: 'Sarapan di hotel. Belanja di Jewelry Store. Perjalanan kembali ke Chengdu dengan bus. Kunjungi Jinli Ancient Street (toko souvenir & jajanan tradisional). Check-in hotel dan istirahat.'
      },
      {
        day: 'H5',
        title: 'CHENGDU – DUJIANGYAN – CHENGDU (Makan Pagi, Siang, Malam)',
        desc: 'Sarapan di hotel. Perjalanan ke Dujiangyan. Belanja di Chinese Medicine Store. Kunjungi Panda Paradise (include battery car), toko buku ikonik Zhongshuge, & Yang Tian Wo Plaza (patung panda selfie raksasa).'
      },
      {
        day: 'H6',
        title: 'CHENGDU (Makan Pagi, Malam)',
        desc: 'Sarapan di hotel. Belanja di Silk Shop. Kunjungi Chunxi Road, IFS Rooftop Panda Raksasa, Taikoo Li, Kuanzhai Alley. Optional: Sichuan Face Changing Show. Menuju bandara penerbangan kembali ke Jakarta.'
      },
      {
        day: 'H7',
        title: 'CHENGDU – DEPARTURE',
        desc: 'TFU (01.15) - KUL (06.20) by MH527, KUL (07.25) - CGK (08.30) by MH713. Penerbangan kembali ke tanah air.'
      }
    ],
    inclusions: [
      { label: 'Tiket International by Malaysia Airlines (Economy)', included: true },
      { label: 'Bagasi 30 kg', included: true },
      { label: 'Akomodasi hotel *3 atau *4 lokal', included: true },
      { label: 'Transportasi bus pariwisata & tiket masuk objek wisata', included: true },
      { label: 'Acara tour & makan sesuai program', included: true },
      { label: 'Mineral water 1 botol per hari', included: true },
      { label: 'Tour Leader', included: true },
      { label: 'Travel Kits (Luggage Tag)', included: true },
      { label: 'Travel Insurance hingga usia 82 tahun', included: true },
      { label: 'Visa China (Rp 1.200.000 - Rp 1.600.000)', included: false },
      { label: 'Tipping Tour Leader/Local Guide/Driver: Rp 1.100.000/Pax', included: false },
      { label: 'Tips porter, mini bar, laundry, telp, kelebihan bagasi', included: false },
      { label: 'PPN 1,2%', included: false },
      { label: 'PCR/Rapid Test Antigen jika dibutuhkan', included: false },
    ],
    mapCenter: [104.0668, 30.5728],
    mapZoom: 8,
    mapPins: [
      { lng: 104.0668, lat: 30.5728, label: 'Chengdu IFS & Chunxi Road' },
      { lng: 106.5516, lat: 29.5630, label: 'Chongqing Hongyadong & Liziba' },
      { lng: 103.6186, lat: 30.9882, label: 'Dujiangyan Panda Paradise' }
    ]
  },

  '6D SPECIAL YEAR END VIETNAM HANOI SAPA FANSIPAN WITH HALONG BAY CRUISE': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1555921015-5532091f6026?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'HIGHLIGHT: HANOI – MEGA GRAND WORLD – CAT CAT VILLAGE – FANSIPAN MOUNTAIN – HALONG ISLAND TOUR',
    price: 'Rp 13.490.000',
    duration: '6 Hari 5 Malam',
    rating: 4.7,
    reviews: 110,
    maxPax: 20,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Malaysia Airlines (CGK–KUL–HAN PP)',
    keberangkatan: '24, 25, 27, 28, 30, 31 Des 2026',
    minPeserta: '20 Peserta (Didampingi 1 Tour Leader)',
    hotelInfoText: 'Hotel ★3 Local / Similar (Twin / Triple)',
    tipeKamarText: 'Twin / Triple | Single Supplement +Rp 3.250.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Malaysia Airlines (CGK–KUL–HAN PP)' },
      { icon: '🧳', text: 'Bagasi 30 kg' },
      { icon: '🏮', text: 'Mega Grand World Hanoi' },
      { icon: '🏞️', text: 'Cat Cat Village Sapa (Suku H’mong)' },
      { icon: '🏔️', text: 'Gunung Fansipan — The Roof of Indochina (Cable Car Included)' },
      { icon: '⛵', text: 'Halong Island Cruise (Junk Boat + Seafood Lunch)' },
      { icon: '🏰', text: 'St.Joseph Cathedral, Tran Quoc Pagoda & Old Quarter' },
      { icon: '👥', text: 'Keberangkatan Minimal 20 Pax (Didampingi 1 Tour Leader)' },
      { icon: '🛡️', text: 'Travel Insurance Sampai Usia 82 Tahun' },
      { icon: '💼', text: 'Komisi Cabang: Rp 350.000 | Mitra: Rp 300.000' },
    ],
    priceCategories: [
      {
        dateLabel: '24 Desember 2026 (CHRISTMAS)',
        prices: [
          { type: 'Dewasa (Twin/Triple)',     price: 'Rp 13.490.000' },
          { type: 'Child No Bed (<6 Years)',  price: 'Rp 12.990.000' },
          { type: 'Single Supplement',        price: '+Rp 3.250.000' }
        ]
      },
      {
        dateLabel: '25 Desember 2026 (CHRISTMAS)',
        prices: [
          { type: 'Dewasa (Twin/Triple)',     price: 'Rp 13.490.000' },
          { type: 'Child No Bed (<6 Years)',  price: 'Rp 12.990.000' },
          { type: 'Single Supplement',        price: '+Rp 3.250.000' }
        ]
      },
      {
        dateLabel: '27 Desember 2026 (NEW YEAR)',
        prices: [
          { type: 'Dewasa (Twin/Triple)',     price: 'Rp 13.990.000' },
          { type: 'Child No Bed (<6 Years)',  price: 'Rp 13.490.000' },
          { type: 'Single Supplement',        price: '+Rp 3.250.000' }
        ]
      },
      {
        dateLabel: '28 Desember 2026 (NEW YEAR)',
        prices: [
          { type: 'Dewasa (Twin/Triple)',     price: 'Rp 13.990.000' },
          { type: 'Child No Bed (<6 Years)',  price: 'Rp 13.490.000' },
          { type: 'Single Supplement',        price: '+Rp 3.250.000' }
        ]
      },
      {
        dateLabel: '30 Desember 2026 (NEW YEAR)',
        prices: [
          { type: 'Dewasa (Twin/Triple)',     price: 'Rp 13.790.000' },
          { type: 'Child No Bed (<6 Years)',  price: 'Rp 13.290.000' },
          { type: 'Single Supplement',        price: '+Rp 3.250.000' }
        ]
      },
      {
        dateLabel: '31 Desember 2026 (NEW YEAR)',
        prices: [
          { type: 'Dewasa (Twin/Triple)',     price: 'Rp 13.690.000' },
          { type: 'Child No Bed (<6 Years)',  price: 'Rp 13.190.000' },
          { type: 'Single Supplement',        price: '+Rp 3.250.000' }
        ]
      },
      {
        dateLabel: 'Infant Flat Rate',
        prices: [
          { type: 'Infant (< 23 Bulan)',      price: 'Rp 3.750.000' }
        ]
      }
    ],
    optionalActivities: [
      { name: 'Rental Wifi / SIM CARD Portable', price: 'Optional' },
      { name: 'Funicular to the peak of Fansipan', price: 'USD 14 / pax' }
    ],
    itinerary: [
      {
        day: 'Hari 01',
        title: 'JAKARTA – HANOI (MEALS ON BOARD)',
        desc: 'CGK (04.25) – KUL (07.30) by MH 726 | KUL (09.30) – HAN (12.00) by MH 752. Hari ini seluruh peserta berkumpul di Bandara Internasional Soekarno-Hatta, Terminal 3, untuk persiapan penerbangan menuju Hanoi, Vietnam menggunakan Maskapai Malaysia Airlines. Sesampainya di Hanoi, kita disambut oleh Guide Lokal berbahasa Indonesia yang ramah, kemudian kita akan langsung menuju Mega Grand World, kawasan wisata modern yang menggabungkan nuansa romantis Venesia dengan kanal air, serta jalanan tematik bergaya Korea yang ramai dan penuh warna. Peserta bebas berfoto dan menikmati suasana. Check-in Hotel dan Istirahat. Bermalam di Hotel*3 local / similar'
      },
      {
        day: 'Hari 02',
        title: 'HANOI – SAPA – CAT CAT VILLAGE (MAKAN PAGI, MAKAN SIANG)',
        desc: 'Sarapan pagi di hotel. Kita akan menuju Sapa selama perjalanan kita dapat menikmati panorama indah pegunungan dan pedesaan Vietnam Utara. Setibanya di Sapa, kita akan mengunjungi Cat Cat Village, desa tradisional suku H’mong yang indah. Peserta dapat melihat aktivitas penduduk lokal seperti bertani, beternak, serta mengunjungi air terjun Cat Cat dan Hydro Electric Power Station peninggalan Perancis. Selanjutnya kita akan kembali ke Sapa untuk mengunjungi Sapa Church, sebuah gereja ikonik bergaya Prancis, dan Sapa Lake. Check-in hotel istirahat. Bermalam di Hotel*3 local / similar'
      },
      {
        day: 'Hari 03',
        title: 'SAPA – FANSIPAN – HANOI (MAKAN PAGI, MAKAN SIANG, MAKAN MALAM)',
        desc: 'Sarapan Pagi di hotel. Kita akan menuju ke Gunung Fansipan yang dikenal sebagai The Roof of Indochina. Sesampainya kita akan menaiki Cable Car selama kurang lebih 20 menit kita akan menikmati panorama spektakuler Pegunungan Hoang Lien Son. Setiba nya di ketinggian 2.800 meter, peserta dapat berfoto dan mengunjungi kompleks pagoda spiritual, kemudian mendaki sekitar 600 anak tangga (optional membeli tiket Funicular apabila tidak mau tracking) menuju puncak Fansipan. Kembali ke Hanoi, check in hotel dan istirahat. Bermalam di Hotel*3 local / similar'
      },
      {
        day: 'Hari 04',
        title: 'HANOI - HALONG (MAKAN PAGI, MAKAN SIANG)',
        desc: 'Sarapan Pagi di hotel. Hari ini kita akan menikmati kota Hanoi dengan mengunjungi St.Joseph Cathedral yang merupakan gereja tertua di Hanoi dengan arsitektur yang menawan, kita juga akan mengunjungi tempat berjesarah dan budaya seperti Ho Chi Minh’s House, His Mausoleum, Ba Dinh Square, One-Pillar Pagoda. Selanjutnya mengunjungi Buddhist Tran Quoc Pagoda on Westlake, salah satu pagoda tertua di Vietnam. Setelah itu kita akan melanjutkan perjalanan menuju Ha Long, di sepanjang perjalanan Anda dapat menikmati pemandangan indah Red River Delta dengan desa-desa yang tenang. Setibanya di Ha Long, kita akan check-in hotel, kemudian waktu bebas untuk menikmati suasana malam di VuiFest Night Market yang ramai dengan kuliner dan hiburan lokal. Bermalam di Hotel*3 local / similar'
      },
      {
        day: 'Hari 05',
        title: 'HALONG ISLAND TOUR – HANOI (MAKAN PAGI, MAKAN SIANG)',
        desc: 'Sarapan Pagi di hotel. Hari ini kita akan menjelajahi pulau-pulau di Halong dengan kapal tradisional (Junk Boat) untuk memulai pelayaran menyusuri keindahan Teluk Ha Long. Kita akan melihat ThienCung cave yang terkenal dengan stalaktit dan stalagmitnya yang menakjubkan, kita juga berkesempatan melihat Dau Go grotto tempat bersejarah di mana Jenderal Tran Hung Dao menancapkan ratusan pasak kayu sebagai strategi melawan pasukan Mongol pada tahun 1288. Kemudian menikmati pemandangan formasi batu unik seperti Chicken Rock, Incense Bowl Islet, Sail Islet, dan Turtle Island. Makan siang dengan hidangan seafood disajikan di atas kapal sambil menikmati pemandangan perairan hijau zamrud yang berpadu dengan tebing-tebing batu kapur yang megah. Kembali ke Hanoi dan waktu bebas menjelajahi Hanoi Old Quarter. Check in hotel dan istirahat. Bermalam di Hotel*3 local / similar'
      },
      {
        day: 'Hari 06',
        title: 'HANOI - DEPARTURE (MAKAN PAGI, MEALS ON BOARD)',
        desc: 'HAN (13.00) - KUL (17.40) by MH 753 | KUL (22.30) – CGK (23.40) by MH 727. Setelah menikmati sarapan pagi di hotel, Anda memiliki waktu bebas untuk beristirahat atau mengeksplorasi sekitar hotel hingga waktu yang telah ditentukan. Selanjutnya, Anda akan dijemput dan diantar menuju bandara untuk penerbangan kembali ke tanah air. Sampai jumpa di tour selanjutnya bersama kami.'
      }
    ],
    inclusions: [
      { label: 'Tiket International Jakarta-Hanoi & Hanoi - Jakarta by Malaysia Airlines, Economy termasuk taxes internasional (Tiket Grup Fixed Date & No Extend)', included: true },
      { label: 'Bagasi 30 kg sesuai dengan ketentuan Airlines', included: true },
      { label: 'Akomodasi hotel *3 lokal setaraf (Twin / Triple)', included: true },
      { label: 'Transportasi bus Pariwisata & tiket masuk objek wisata', included: true },
      { label: 'Acara Tour & makan sesuai program paket tour diatas', included: true },
      { label: 'Mineral Water 1 Botol Perhari', included: true },
      { label: 'Tour Leader', included: true },
      { label: 'Travel Kits (Luggage Tag)', included: true },
      { label: 'Travel Insurance sampai usia 82 tahun', included: true },
      { label: 'Tipping Tour Leader, Local Guide, Driver: Rp850.000/ Pax', included: false },
      { label: 'Tips Porter Hotel, Mini Bar, Laundry, Telp, Kelebihan bagasi dll.', included: false },
      { label: 'PPN 1,2%', included: false },
      { label: 'Rental Wifi/SIM CARD Portable (OPTIONAL)', included: false },
      { label: 'Funicular to the peak of Fansipan USD 14 /pax (OPTIONAL)', included: false }
    ],
    mapCenter: [105.8342, 21.0278],
    mapZoom: 7,
    mapPins: [
      { lng: 105.8342, lat: 21.0278, label: 'Hanoi (Mega Grand World & Cathedral)' },
      { lng: 103.8438, lat: 22.3364, label: 'Sapa (Cat Cat Village & Fansipan)' },
      { lng: 107.0728, lat: 20.9505, label: 'Ha Long Bay (Island Tour)' }
    ]
  },

  '10D NEW YEAR TURKIYE CAPPADOCIA + MT ULUDAG & BOSPHORUS CRUISE': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'HIGHLIGHT: BLUE MOSQUE – MT ULUDAG – COTTON CASTLE – CAPPADOCIA – SALT LAKE – BOSPHORUS CRUISE',
    price: 'Rp 24.990.000',
    duration: '10 Hari 9 Malam',
    rating: 4.8,
    reviews: 135,
    maxPax: 20,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Singapore Airlines (CGK–SIN–IST PP)',
    keberangkatan: '24 Des 2026',
    minPeserta: '20 Peserta (Didampingi 1 Tour Leader)',
    hotelInfoText: 'Hotel ★4 Local / Similar (Twin / Triple)',
    tipeKamarText: 'Twin / Triple | Single Supplement +Rp 6.500.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Singapore Airlines (CGK–SIN–IST PP)' },
      { icon: '🧳', text: 'Bagasi 25 kg' },
      { icon: '🕌', text: 'Blue Mosque, Hippodrome Square & Hagia Sophia' },
      { icon: '🏔️', text: 'Mt. Uludag — Cable Car & Salju Musim Dingin Bursa' },
      { icon: '🏰', text: 'Cotton Castle Pamukkale & Sirince Village' },
      { icon: '🎈', text: 'Cappadocia — Pigeon Valley, Uchisar Castle & Goreme' },
      { icon: '🧊', text: 'Salt Lake — Danau Garam Spektakuler' },
      { icon: '⛵', text: 'Bosphorus Cruise & Grand Bazaar Istanbul' },
      { icon: '👥', text: 'Keberangkatan Minimal 20 Pax (Didampingi 1 Tour Leader)' },
      { icon: '🛡️', text: 'Travel Insurance Included' },
    ],
    priceCategories: [
      {
        dateLabel: '24 DESEMBER 2026',
        prices: [
          { type: 'Dewasa (Twin/Triple)',     price: 'Rp 24.990.000' },
          { type: 'Child No Bed (<6 Years)',  price: 'Rp 23.990.000' },
          { type: 'Single Supplement',        price: '+Rp 6.500.000' }
        ]
      },
      {
        dateLabel: 'Infant Rate',
        prices: [
          { type: 'Infant Flat Rate (< 23 Bulan)', price: 'Rp 4.500.000' }
        ]
      }
    ],
    optionalActivities: [
      { name: 'Simcard / Esim Portable', price: 'Optional' },
      { name: 'Hot Air Balloon Cappadocia', price: 'Optional (Depends on weather)' },
      { name: 'Jeep Safari Cappadocia', price: 'Optional' }
    ],
    itinerary: [
      {
        day: 'Hari 01',
        title: 'JAKARTA – SINGAPORE (MEALS ON BOARD)',
        desc: 'CGK (20.20) – SIN (23.05) by SQ 967. Malam ini kita berkumpul di Bandara Soekarno-Hatta terminal 3 Ultimate untuk berangkat menuju Turkiye dengan Singapore Airlines (Premium Airlines). Bermalam di pesawat.'
      },
      {
        day: 'Hari 02',
        title: 'SINGAPORE - ISTANBUL – BURSA (MAKAN SIANG, MAKAN MALAM)',
        desc: 'SIN (01.50) – IST (08.45) by SQ 392. Setiba di Istanbul, disambut guide berbahasa Indonesia. Mengunjungi Blue Mosque, masjid 6 menara biru beraksitektur unik, & area Hippodrome Square. Photostop Topkapi Palace & Hagia Sophia Mosque. Melanjutkan perjalanan ke Bursa. Check-in Hotel & istirahat. Bermalam di Hotel *4 Local / similar'
      },
      {
        day: 'Hari 03',
        title: 'BURSA – MT. ULUDAG – KUSADASI (MAKAN PAGI, MAKAN SIANG, MAKAN MALAM)',
        desc: 'Sarapan di hotel, mengunjungi Turkish Delight Shop & Grand Mosque (masjid 20 kubah khas Ottoman), belanja di Silk Market. Menuju Mt. Uludag (include return cable car) resor musim dingin populer dengan pemandangan salju indah. Perjalanan dilanjutkan menuju Kusadasi, kota pesisir Laut Aegea. Check-in Hotel & istirahat. Bermalam di Hotel *4 Local / similar'
      },
      {
        day: 'Hari 04',
        title: 'KUSADASI - PAMUKKALE (MAKAN PAGI, MAKAN SIANG, MAKAN MALAM)',
        desc: 'Sarapan di hotel, mengunjungi Sirince Village (desa kebun anggur & olive oil) & Turkish Leather Shop. Perjalanan ke Pamukkale: Natural Park & Observation Point (Photostop), Cotton Castle (Photostop) teras travertine putih alami kolam air panas. Check-in Hotel & istirahat. Bermalam di Hotel *4 Local / similar'
      },
      {
        day: 'Hari 05',
        title: 'PAMUKKALE - CAPPADOCIA (MAKAN PAGI, MAKAN SIANG, MAKAN MALAM)',
        desc: 'Sarapan di hotel, berbelanja di Textile Outlet Shop & Sultanhani Caravanserai (Photostop) pusat jalur perdagangan Modern Silkroad. Perjalanan ke Cappadocia, Check-in Hotel & istirahat. Bermalam di Hotel *4 Local / similar'
      },
      {
        day: 'Hari 06',
        title: 'CAPPADOCIA (MAKAN PAGI, MAKAN SIANG, MAKAN MALAM)',
        desc: 'Sarapan di hotel, mengunjungi Pigeon Valley & Uchisar Castle (benteng alami tertinggi), Goreme Valley & Panorama (desa formasi batuan cantik), Avanos Village & Pottery Shop. Berbelanja di Turkish Carpets & Jewelry Shop. [Optional: Hot Air Balloon Flight]. Kembali ke hotel & istirahat. Bermalam di Hotel *4 Local / similar'
      },
      {
        day: 'Hari 07',
        title: 'CAPPADOCIA – ISTANBUL (MAKAN PAGI, MAKAN SIANG, MAKAN MALAM)',
        desc: 'Sarapan di hotel, mengunjungi Salt Lake (Photostop) danau garam indah di dataran tinggi gersang. Perjalanan menuju Istanbul. Check-in Hotel & istirahat. Bermalam di Hotel *4 Local / similar'
      },
      {
        day: 'Hari 08',
        title: 'ISTANBUL (MAKAN PAGI)',
        desc: 'Sarapan di hotel, mengunjungi Grand Bazaar (pasar tertutup terbesar & tertua). Pengalaman Bosphorus Cruise menyusuri Selat Bosphorus panorama istana & masjid di antara Eropa dan Asia. Berkeliling di Taksim Square. Kembali ke hotel & istirahat. Bermalam di Hotel *4 Local / similar'
      },
      {
        day: 'Hari 09',
        title: 'ISTANBUL – SINGAPORE (MAKAN PAGI)',
        desc: 'IST (13.15) – SIN (04.45) by SQ 391. Sarapan di hotel, transfer ke Bandara Istanbul penerbangan ke Jakarta via Singapore. Bermalam di pesawat'
      },
      {
        day: 'Hari 10',
        title: 'SINGAPORE – JAKARTA (MEALS ON BOARD)',
        desc: 'SIN (06.50) – CGK (07.35) by SQ 950. Penerbangan menuju Jakarta. Terima kasih telah mengikuti tour kami, sampai jumpa di perjalanan selanjutnya.'
      }
    ],
    inclusions: [
      { label: 'Tiket International by Singapore Airlines, Economy termasuk taxes internasional (Tiket Grup Fixed Date & No Extend)', included: true },
      { label: 'Bagasi 25 kg sesuai dengan ketentuan Airlines', included: true },
      { label: 'Akomodasi hotel *4 atau setaraf (Twin / Triple)', included: true },
      { label: 'Transportasi bus Pariwisata & tiket masuk objek wisata', included: true },
      { label: 'Acara Tour & makan sesuai program paket tour diatas', included: true },
      { label: 'Mineral Water 02 Botol Perhari', included: true },
      { label: 'Travel Kits (Luggage Tag)', included: true },
      { label: 'Travel Insurance', included: true },
      { label: 'Tipping Tour Leader, Local Guide, Driver: Rp 1,950,000/Pax', included: false },
      { label: 'Tips Porter Hotel, Mini Bar, Laundry, Telp, Kelebihan bagasi dll.', included: false },
      { label: 'PPN 1,2%', included: false },
      { label: 'Simcard/Esim (OPTIONAL)', included: false },
      { label: 'Hot Air Balloon (OPTIONAL)', included: false },
      { label: 'Jeep Safari (OPTIONAL)', included: false }
    ],
    mapCenter: [35.2433, 38.9637],
    mapZoom: 6,
    mapPins: [
      { lng: 28.9784, lat: 41.0082, label: 'Istanbul (Blue Mosque & Bosphorus)' },
      { lng: 29.0610, lat: 40.1885, label: 'Bursa & Mt. Uludag' },
      { lng: 29.1187, lat: 37.9204, label: 'Pamukkale Cotton Castle' },
      { lng: 34.8289, lat: 38.6431, label: 'Cappadocia' },
      { lng: 33.5126, lat: 38.8354, label: 'Salt Lake' }
    ]
  },

  '8D FESTIVE YEAR END DUAL THEME PARK': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1536599018102-9f803c140fc1?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'HIGHLIGHT: SHANGHAI DISNEYLAND, WUZHEN, WEST LAKE, FORBIDDEN CITY, UNIVERSAL STUDIO BEIJING',
    price: 'Rp 24.990.000',
    duration: '8 Hari 7 Malam',
    rating: 4.8,
    reviews: 140,
    maxPax: 20,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Singapore Airlines (CGK-SIN-PVG / PEK-SIN-CGK)',
    keberangkatan: '23 Des 2026',
    minPeserta: '20 Peserta (Didampingi 1 Tour Leader)',
    hotelInfoText: 'Hotel ★3 / ★4 Local / Similar (Twin / Triple)',
    tipeKamarText: 'Twin / Triple | Single Supplement +Rp 4.000.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Singapore Airlines (SQ 951/830/805/964)' },
      { icon: '🧳', text: 'Bagasi 25 kg' },
      { icon: '🏰', text: 'Shanghai Disneyland (Termasuk One Day Pass)' },
      { icon: '🛶', text: 'Wuzhen Ancient Water Town (Termasuk Boat Ride)' },
      { icon: '🌊', text: 'West Lake Hangzhou Cruise & Yue Fei Temple' },
      { icon: '🍵', text: 'Tea Garden & Suzhou Couple’s Garden' },
      { icon: '🚄', text: 'Bullet Train Suzhou ke Beijing' },
      { icon: '🏛️', text: 'Tiananmen Square & Forbidden City' },
      { icon: '🎬', text: 'Universal Studios Beijing — 1 Day Pass' },
      { icon: '👥', text: 'Keberangkatan Minimal 20 Pax (Didampingi 1 Tour Leader)' },
      { icon: '🛡️', text: 'Travel Insurance Included' },
    ],
    priceCategories: [
      {
        dateLabel: '23 DESEMBER 2026 (YEAR END)',
        prices: [
          { type: 'Dewasa (Twin/Triple)',     price: 'Rp 24.990.000' },
          { type: 'Child No Bed (<6 Years)',  price: 'Rp 23.990.000' },
          { type: 'Single Supplement',        price: '+Rp 4.000.000' }
        ]
      },
      {
        dateLabel: 'Infant Rate',
        prices: [
          { type: 'Infant Flat Rate (< 23 Bulan)', price: 'Rp 4.000.000' }
        ]
      }
    ],
    optionalActivities: [
      { name: 'Rental Wifi Portable / SIM card', price: 'Optional' }
    ],
    itinerary: [
      {
        day: 'Hari 01',
        title: 'JAKARTA – DEPARTURE SHANGHAI (MEALS ON BOARD)',
        desc: 'CGK (05.25) – SIN (08.05) by SQ 951 & SIN (09.20) - PVG (14.35) by SQ 830. Hari ini kita berkumpul di Bandara Soekarno-Hatta terminal 3 Ultimate untuk berangkat menuju Shanghai dengan Singapore Airlines. Sesampainya di Shanghai, disambut oleh Guide yang ramah dan diajak mengunjungi The Bund, kawasan tepi sungai ikonik Shanghai berarsitektur klasik Eropa & pemandangan gedung pencakar langit modern. Check-in hotel & istirahat. Bermalam di Hotel *3 atau *4 local / similar'
      },
      {
        day: 'Hari 02',
        title: 'SHANGHAI DISNEYLAND (MAKAN PAGI)',
        desc: 'Sarapan pagi di hotel. Hari ini kita akan mengunjungi Shanghai Disneyland (termasuk One Day Pass), taman hiburan dengan berbagai wahana seru, pertunjukan spektakuler, serta area bertema karakter Disney yang terkenal. Kembali ke hotel & istirahat. Bermalam di Hotel *3 atau *4 local / similar'
      },
      {
        day: 'Hari 03',
        title: 'SHANGHAI – WUZHEN – HANGZHOU (MAKAN PAGI, MAKAN SIANG, MAKAN MALAM)',
        desc: 'Sarapan pagi di hotel. Kunjungi Wuzhen (termasuk boat ride), kota air kuno dengan kanal cantik & jembatan batu. Perjalanan ke Hangzhou menikmati West Lake dengan perahu, danau ikonik penuh legenda. Kunjungi Yue Fei Temple, kuil bersejarah pahlawan nasional Yue Fei. Check in hotel & istirahat. Bermalam di Hotel *3 atau *4 local / similar'
      },
      {
        day: 'Hari 04',
        title: 'HANGZHOU – SUZHOU (MAKAN PAGI, MAKAN SIANG)',
        desc: 'Sarapan pagi di hotel. Kunjungi Tea Garden untuk melihat perkebunan teh hijau & proses produksi teh. Perjalanan ke Suzhou mengunjungi Couple’s Garden (taman klasik tradisional yang tenang), Jinji Lake, dan Guanqian Street (kawasan belanja populer). Bermalam di Hotel *3 atau *4 local / similar'
      },
      {
        day: 'Hari 05',
        title: 'SUZHOU – BEIJING (MAKAN PAGI, MAKAN MALAM)',
        desc: 'Sarapan pagi di hotel. Kunjungi Silk Factory melihat proses pembuatan sutra khas Tiongkok dari pemintalan hingga produk jadi. Naik bullet train menuju Beijing untuk melanjutkan rangkaian perjalanan di ibu kota Tiongkok. Check-in Hotel & istirahat. Bermalam di Hotel *3 atau *4 local / similar'
      },
      {
        day: 'Hari 06',
        title: 'BEIJING (MAKAN PAGI, MAKAN SIANG)',
        desc: 'Sarapan pagi di hotel. Kunjungi Tiananmen Square (alun-alun terbesar di dunia ikon sejarah Tiongkok), Forbidden City (kompleks istana kekaisaran megah tempat kediaman kaisar selama ratusan tahun), dan Wangfujing Street (kawasan perbelanjaan & pusat kuliner). Kembali ke hotel & istirahat. Bermalam di Hotel *3 atau *4 local / similar'
      },
      {
        day: 'Hari 07',
        title: 'UNIVERSAL STUDIOS BEIJING (MAKAN PAGI)',
        desc: 'Sarapan pagi di hotel. Kunjungi Universal Studios Beijing (taman hiburan Universal pertama di Tiongkok) dengan area Hollywood, Jurassic World Isla Nublar, Kung Fu Panda Land of Awesomeness, The Wizarding World of Harry Potter, dll. Wahana & pertunjukan untuk segala usia. Kembali ke hotel & istirahat. Bermalam di Hotel *3 atau *4 local / similar'
      },
      {
        day: 'Hari 08',
        title: 'BEIJING – DEPARTURE (MEALS ON BOARD)',
        desc: 'PEK (08.45) – SIN (15.30) by SQ 805 & SIN (17.20) – CGK (18.05) by SQ 964. Hari ini kita akan kembali ke tanah air tercinta. Berakhirlah tour yang berkesan ini dan sampai jumpa di tour selanjutnya bersama kami.'
      }
    ],
    inclusions: [
      { label: 'Tiket International by Singapore Airlines, Economy termasuk taxes internasional (Tiket Grup Fixed Date & No Extend)', included: true },
      { label: 'Bagasi 25 kg sesuai dengan ketentuan Airlines', included: true },
      { label: 'Akomodasi hotel *3 atau *4 local / similar (Twin / Triple)', included: true },
      { label: 'Transportasi bus Pariwisata & tiket masuk objek wisata', included: true },
      { label: 'Acara Tour & makan sesuai program paket tour diatas', included: true },
      { label: 'Mineral Water 01 Botol Perhari', included: true },
      { label: 'Tour Leader', included: true },
      { label: 'Travel Kits (Luggage Tag)', included: true },
      { label: 'Travel Insurance', included: true },
      { label: 'Visa Group China Rp 1.200.000 / Single Visa Rp 1.300.000 - Rp 1.600.000', included: false },
      { label: 'Tipping Tour Leader, Local Guide, Driver: Rp 1,300,000/Pax', included: false },
      { label: 'Tips Porter Hotel, Mini Bar, Laundry, Telp, Kelebihan bagasi dll.', included: false },
      { label: 'PPN 1,2%', included: false },
      { label: 'Rental Wifi Portable / SIM card (OPTIONAL)', included: false }
    ],
    mapCenter: [116.4074, 39.9042],
    mapZoom: 6,
    mapPins: [
      { lng: 121.4737, lat: 31.2304, label: 'Shanghai (The Bund & Disneyland)' },
      { lng: 120.4856, lat: 30.7490, label: 'Wuzhen Ancient Water Town' },
      { lng: 120.1551, lat: 30.2741, label: 'Hangzhou West Lake' },
      { lng: 120.5853, lat: 31.2989, label: 'Suzhou Couple’s Garden' },
      { lng: 116.4074, lat: 39.9042, label: 'Beijing (Forbidden City & Universal)' }
    ]
  },

  '6D PROMO MONO SEOUL': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1538485399081-7191377e8241?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1538485399081-7191377e8241?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1540979388789-6cee28a1cdc9?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1517154421773-0529f29ea451?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1549719386-74dfcbf7dbed?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'Promo spesial Seoul via Malaysia Airlines! Inspire Ent, Gwangmyeong Cave, Starfield Library, Kimchi Making & Hanbok Experience — 11 jadwal Jun–Agt 2026.',
    price: 'Rp 8.499.000 – Rp 8.999.000',
    duration: '6 Hari 5 Malam',
    rating: 4.6,
    reviews: 108,
    maxPax: 30,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Malaysia Airlines MH720/MH722/MH066/MH039/MH713 (Economy, Group Fixed Date, No Extend)',
    keberangkatan: 'Jun: 03, 06, 13 | Jul: 01, 04, 14, 26 | Agt: 08, 12, 18, 31 (2026)',
    minPeserta: '30 Peserta',
    hotelInfoText: 'Hotel ★3 Setaraf (Twin/Triple)',
    tipeKamarText: 'Twin/Triple | Single Supplement +Rp 5.000.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Malaysia Airlines MH (Economy, Group Fixed Date, No Extend)' },
      { icon: '🎰', text: 'Incheon Inspire Entertainment Resort — kompleks hiburan modern' },
      { icon: '⛏️', text: 'Gwangmyeong Cave — bekas tambang jadi destinasi wisata kreatif' },
      { icon: '📚', text: 'Starfield Library & COEX Mall — ikon perpustakaan terbesar Seoul' },
      { icon: '🗼', text: 'N Seoul Tower (Elektrik Bus) — panorama kota dari ketinggian' },
      { icon: '🥬', text: 'Making Kimchi & Wearing Hanbok — pengalaman budaya Korea' },
      { icon: '🏯', text: 'Gyeongbokgung Palace & National Museum — sejarah Korea' },
      { icon: '🛍️', text: 'Myeongdong Street & Dongdaemun Fashion Town' },
      { icon: '🛡️', text: 'Free Travel Insurance Group s.d. usia 84 tahun' },
      { icon: '👥', text: 'Minimal 30 Pax + Tour Leader' },
    ],
    priceCategories: [
      {
        dateLabel: '03 JUNI 2026',
        prices: [
          { type: 'Dewasa Twin/Triple',        price: 'Rp 8.499.000' },
          { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 7.999.000' },
          { type: 'Single Supplement',          price: '+Rp 5.000.000' },
        ]
      },
      {
        dateLabel: '06 JUNI 2026',
        prices: [
          { type: 'Dewasa Twin/Triple',        price: 'Rp 8.499.000' },
          { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 7.999.000' },
          { type: 'Single Supplement',          price: '+Rp 5.000.000' },
        ]
      },
      {
        dateLabel: '13 JUNI 2026 — FULL',
        prices: [
          { type: 'Dewasa Twin/Triple',        price: 'Rp 8.499.000' },
          { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 7.999.000' },
          { type: 'Single Supplement',          price: '+Rp 5.000.000' },
        ]
      },
      {
        dateLabel: '01 JULI 2026 — SCHOOL HOLIDAY',
        prices: [
          { type: 'Dewasa Twin/Triple',        price: 'Rp 8.999.000' },
          { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 8.599.000' },
          { type: 'Single Supplement',          price: '+Rp 5.000.000' },
        ]
      },
      {
        dateLabel: '04 JULI 2026 — SCHOOL HOLIDAY',
        prices: [
          { type: 'Dewasa Twin/Triple',        price: 'Rp 8.999.000' },
          { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 8.599.000' },
          { type: 'Single Supplement',          price: '+Rp 5.000.000' },
        ]
      },
      {
        dateLabel: '14 JULI 2026',
        prices: [
          { type: 'Dewasa Twin/Triple',        price: 'Rp 8.499.000' },
          { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 7.999.000' },
          { type: 'Single Supplement',          price: '+Rp 5.000.000' },
        ]
      },
      {
        dateLabel: '26 JULI 2026',
        prices: [
          { type: 'Dewasa Twin/Triple',        price: 'Rp 8.499.000' },
          { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 7.999.000' },
          { type: 'Single Supplement',          price: '+Rp 5.000.000' },
        ]
      },
      {
        dateLabel: '08 AGUSTUS 2026',
        prices: [
          { type: 'Dewasa Twin/Triple',        price: 'Rp 8.499.000' },
          { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 7.999.000' },
          { type: 'Single Supplement',          price: '+Rp 5.000.000' },
        ]
      },
      {
        dateLabel: '12 AGUSTUS 2026',
        prices: [
          { type: 'Dewasa Twin/Triple',        price: 'Rp 8.499.000' },
          { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 7.999.000' },
          { type: 'Single Supplement',          price: '+Rp 5.000.000' },
        ]
      },
      {
        dateLabel: '18 AGUSTUS 2026',
        prices: [
          { type: 'Dewasa Twin/Triple',        price: 'Rp 8.499.000' },
          { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 7.999.000' },
          { type: 'Single Supplement',          price: '+Rp 5.000.000' },
        ]
      },
      {
        dateLabel: '31 AGUSTUS 2026',
        prices: [
          { type: 'Dewasa Twin/Triple',        price: 'Rp 8.499.000' },
          { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 7.999.000' },
          { type: 'Single Supplement',          price: '+Rp 5.000.000' },
        ]
      },
      {
        dateLabel: 'INFANT FLAT RATE',
        prices: [
          { type: 'Infant (< 23 Bulan)', price: 'Rp 3.000.000' },
        ]
      },
    ],
    optionalActivities: [
      { name: 'Rental Wifi Portable / SIM Card', price: 'Tersedia' },
      { name: 'Visa Individual Korea (jika tidak lolos syarat group)', price: 'Rp 1.700.000' },
    ],
    itinerary: [
      {
        day: 'Hari 01',
        title: 'JAKARTA – KUALA LUMPUR – ON BOARD (Meals on Board)',
        desc: 'MH720 CGK–KUL 15:40–18:50 atau MH722 CGK–KUL 18:25–21:35 & MH066 KUL–ICN 23:30–07:10+1. Berkumpul di Bandara Soekarno-Hatta untuk check-in dan persiapan penerbangan menuju Seoul via Kuala Lumpur. Bermalam di pesawat.'
      },
      {
        day: 'Hari 02',
        title: 'ARRIVAL INCHEON – INCHEON CITY TOUR (-)',
        desc: 'Tiba di Incheon pagi hari. Kunjungi Incheon Inspire Entertainment Resort — kompleks hiburan modern megah penuh spot menarik. Incheon China Town & Songwol Fairy Tale Village — kawasan budaya Tiongkok dan desa mural warna-warni bertema dongeng. Menikmati suasana tepi laut di Wolmido Theme Park. Berbelanja di Incheon Underground Shopping Mall. Menuju hotel untuk beristirahat.'
      },
      {
        day: 'Hari 03',
        title: 'SEOUL CITY TOUR (Makan Pagi)',
        desc: 'Gwangmyeong Cave — destinasi unik dari bekas tambang yang kini menjadi tempat wisata kreatif. Starfield Library & COEX Mall — ikon perpustakaan modern di dalam pusat perbelanjaan terbesar Seoul. HiKR Ground — pusat pengalaman budaya Korea interaktif. Sore: N Seoul Tower (naik Elektrik Bus) — panorama kota dari ketinggian. Hongdae Youth Avenue — pusat anak muda: hiburan, kuliner & shopping.'
      },
      {
        day: 'Hari 04',
        title: 'SEOUL HERITAGE & SHOPPING (Makan Pagi)',
        desc: 'Kunjungi National Ginseng Museum & K-Cosmetic Shop. Gyeongbokgung Palace & National Museum — kekayaan sejarah Korea. Berbelanja di Dongdaemun Fashion Town — pusat fashion terkenal di Seoul.'
      },
      {
        day: 'Hari 05',
        title: 'SEOUL CITY TOUR – DEPARTURE (Makan Pagi)',
        desc: 'Sarapan dan check-out hotel. Kunjungi Red Pine Tree Shop & Amethyst Shop. Making Kimchi & Wearing Hanbok — mencoba pakaian tradisional Korea dan belajar membuat kimchi. Duty Free Shop & Myeongdong Street — pusat belanja dan kuliner paling populer di Seoul. Local Supermarket untuk oleh-oleh khas Korea. Diantar ke bandara.'
      },
      {
        day: 'Hari 06',
        title: 'ON FLIGHT – ARRIVAL JAKARTA (Meals on Board)',
        desc: 'MH039 ICN–KUL 00:10–05:45 & MH713 KUL–CGK 07:20–08:25 atau MH711 KUL–CGK 09:00–10:15. Penerbangan kembali ke Jakarta via Kuala Lumpur. Setibanya di tanah air, berakhirlah perjalanan yang menyenangkan ini. Terima kasih dan sampai jumpa di perjalanan berikutnya!'
      }
    ],
    inclusions: [
      { label: 'Tiket International Jakarta–Incheon by Malaysia Airlines Economy (Group Fixed Date, No Extend)',  included: true  },
      { label: 'Bagasi sesuai ketentuan Airlines',                                                                 included: true  },
      { label: 'Akomodasi hotel ★3 setaraf (Twin/Triple)',                                                         included: true  },
      { label: 'Transportasi bus pariwisata & tiket masuk objek wisata',                                           included: true  },
      { label: 'Acara tour & makan sesuai program',                                                                included: true  },
      { label: 'Mineral water 1 botol per hari',                                                                   included: true  },
      { label: 'Tour Leader',                                                                                       included: true  },
      { label: 'Free Travel Insurance Group s.d. usia 84 tahun',                                                   included: true  },
      { label: 'Biaya Administrasi Visa Group Korea Rp 450.000 (wajib)',                                           included: true  },
      { label: 'Tipping Tour Leader, Local Guide, Driver: Rp 1.100.000/pax',                                      included: false },
      { label: 'Tips porter hotel, mini bar, laundry, telp, kelebihan bagasi',                                     included: false },
      { label: 'PPN 1,2%',                                                                                          included: false },
      { label: 'Rental Wifi Portable / SIM Card (optional)',                                                        included: false },
      { label: 'Visa Individual Korea Rp 1.700.000 (jika tidak lolos syarat visa group)',                          included: false },
    ],
    syaratKetentuan: [
      'Minimal keberangkatan 30 Pax, didampingi 1 Tour Leader.',
      'Deposit Rp 6.000.000 (First Come First Serve).',
      'Peak season period: pelunasan 30 hari sebelum keberangkatan.',
      'Tiket Grup Fixed Date & No Extend — tidak dapat diubah tanggal.',
      'Visa Group Korea Rp 450.000 (wajib). Jika tidak memenuhi syarat visa group → Visa Individual Rp 1.700.000.',
      'Infant Flat Rate (<23 bulan): Rp 3.000.000.',
      'Term & Condition: https://safaria.co.id/artikel/show/ITS_Terms_and_Condition_Consortium_B2B_(Series_Group_Tour)',
    ],
    remarks: [
      'Keberangkatan 13 Juni 2026 sudah FULL — segera daftar untuk tanggal lain.',
      'Harga School Holiday (1 & 4 Juli 2026) berbeda: Dewasa Rp 8.999.000 / Child No Bed Rp 8.599.000.',
      'Visa Group wajib dibuat melalui kami; biaya administrasi Rp 450.000 tetap dikenakan meskipun tidak membuat visa di kami.',
      'Jika peserta dianggap tidak memenuhi syarat visa group, akan diarahkan ke Visa Individual Rp 1.700.000.',
      'No meals on Day 02 (Hari 02) — makan tidak termasuk saat tiba di Incheon.',
    ],
    mapCenter: [126.9780, 37.5665],
    mapZoom: 10,
    mapPins: [
      { lng: 126.7060, lat: 37.4563, label: 'Incheon Inspire Entertainment Resort' },
      { lng: 126.8669, lat: 37.4490, label: 'Gwangmyeong Cave' },
      { lng: 127.0590, lat: 37.5130, label: 'Starfield Library & COEX Mall' },
      { lng: 126.9882, lat: 37.5512, label: 'N Seoul Tower (Namsan)' },
      { lng: 126.9247, lat: 37.5574, label: 'Hongdae Youth Avenue' },
      { lng: 126.9770, lat: 37.5796, label: 'Gyeongbokgung Palace' },
      { lng: 127.0095, lat: 37.5648, label: 'Dongdaemun Fashion Town' },
      { lng: 126.9849, lat: 37.5633, label: 'Myeongdong Street' },
    ]
  },

  'Chengdu Jiuzhaigou Mounigou 11 Hari / 08 Malam': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1537519191377-d3305ffddce4?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1518005068251-37900150dfca?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'Jiuzhaigou UNESCO + Mounigou Zhaga Waterfall + Panda Park via Xiamen Airlines! Bipenggou, Pingwu Bao\'en Temple, Songpan Ancient Town & 5 kota dalam 11 hari.',
    price: 'Rp 13.900.000 – Rp 14.900.000',
    duration: '11 Hari 8 Malam',
    rating: 4.7,
    reviews: 67,
    maxPax: 24,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Xiamen Airlines MF8673 (Economy, Fix Date, Fix Flight, No Refund)',
    keberangkatan: 'Jun 22 & Jun 29 (2026)',
    minPeserta: 'Individu / Grup',
    hotelInfoText: 'Hotel ★4 (1 kamar berdua/bertiga) — Chongqing, Jiuzhaigou, Maoxian, Dujiangyan & Chengdu',
    tipeKamarText: 'Twin/Triple | Single Supplement +Rp 3.600.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Xiamen Airlines Economy (Fix Date, Fix Flight, No Refund)' },
      { icon: '🧳', text: 'Bagasi 23 kg + Kabin 5 kg per pax' },
      { icon: '🌊', text: 'Jiuzhaigou National Park — "Surga Dunia" Warisan UNESCO' },
      { icon: '💧', text: 'Mounigou – Zhaga Waterfall Scenic Area di Lembah Muni' },
      { icon: '🏔️', text: 'Bipenggou Scenic Area (eco car + battery car included)' },
      { icon: '🐼', text: 'Dujiangyan Panda Park (battery car included)' },
      { icon: '🏯', text: 'Pingwu Bao\'en Temple — "Hidden Forbidden City in Mountains"' },
      { icon: '🚃', text: 'Liziba Light Rail Through the Building — pengalaman unik' },
      { icon: '🛤️', text: 'Songpan Ancient Town & Ciqikou Ancient Town' },
      { icon: '🛡️', text: 'Asuransi Perjalanan Standard Group (cover ≤83 tahun)' },
    ],
    priceCategories: [
      {
        dateLabel: '29 Juni 2026',
        prices: [
          { type: 'Twin/Triple Share',          price: 'Rp 13.900.000' },
          { type: 'Child No Bed / Infant',       price: 'Rp 11.815.000' },
          { type: 'Single Supplement',            price: '+Rp 3.600.000' },
        ]
      },
      {
        dateLabel: '22 Juni 2026',
        prices: [
          { type: 'Twin/Triple Share',          price: 'Rp 14.900.000' },
          { type: 'Child No Bed / Infant',       price: 'Rp 12.665.000' },
          { type: 'Single Supplement',            price: '+Rp 3.600.000' },
        ]
      }
    ],
    optionalActivities: [
      { name: 'Optional tour (wajib pesan via kami)', price: 'Sesuai penawaran' },
    ],
    itinerary: [
      {
        day: 'Day 01',
        title: 'JAKARTA – CHONGQING',
        desc: 'Berkumpul di Bandara Udara Soekarno-Hatta untuk memulai perjalanan menuju Chongqing, China.'
      },
      {
        day: 'Day 02',
        title: 'CHONGQING – CHENGDU (L/D)',
        desc: 'Setibanya di Chongqing, rasakan pengalaman Liziba Light Rail Through the Building — stasiun unik di jalur CRT Line 2 yang terkenal karena rel melewati gedung apartemen. Kunjungi Ciqikou Ancient Town, "Little Chongqing" yang dikelilingi tiga gunung dengan satu sungai dan dua anak sungai. Perjalanan dilanjutkan menuju Chengdu dengan bus.'
      },
      {
        day: 'Day 03',
        title: 'CHENGDU – JIUZHAIGOU (B/L/D)',
        desc: 'Setelah sarapan, kunjungi Pingwu Bao\'en Temple — "The Hidden Forbidden City in Mountains", kompleks arsitektur kuno Dinasti Ming terbesar di Sichuan, dibangun tahun 1440 (±600 tahun). Lanjut perjalanan dengan bus menuju hotel di Jiuzhaigou.'
      },
      {
        day: 'Day 04',
        title: 'JIUZHAIGOU (B/L/D)',
        desc: 'Jiuzhaigou National Park naik bus ekologi umum. Kunjungi Mirror Lake, Pearl Waterfall, Nuorilang Waterfall, Five Color Pond, Long Lake, Shuzheng, dan masih banyak lagi. Kawasan ini dinamai "Jiuzhaigou" karena terdapat sembilan desa Tibet. Wisatawan menyebutnya "Surga Dunia".'
      },
      {
        day: 'Day 05',
        title: 'JIUZHAIGOU – MAOXIAN (B/L/D)',
        desc: 'Berbelanja di Comprehensive Shop. Kunjungi Mounigou – Zhaga Waterfall Scenic Area di Lembah Muni — nikmati mata air Yishouquan dan Air Terjun Foshan. Photo stop Songpan Ancient Town — kota sejak Dinasti Tang, landmark Patung Putri Wencheng dan Songtsen Gampo. Bermalam di Maoxian.'
      },
      {
        day: 'Day 06',
        title: 'MAOXIAN – BIPENGGOU – DUJIANGYAN (B/L/D)',
        desc: 'Kunjungi Bipenggou Scenic Area (termasuk eco car + Shanghaizi–Panyang Lake battery car) — permata tersembunyi dengan hutan lebat, danau jernih, puncak bersalju, dan padang rumput luas. Setiap musim menawarkan pesona berbeda, ideal untuk foto dan menikmati ketenangan.'
      },
      {
        day: 'Day 07',
        title: 'DUJIANGYAN (B/L/D)',
        desc: 'Berbelanja di Herbal Medicine Shop. Kunjungi Dujiangyan Panda Park (termasuk battery car) — ±18 km dari pusat Chengdu, berbatasan langsung dengan World Heritage Site of Giant Panda Habitat. Berbelanja di Latex Shop. Photo stop Giant Selfie Panda Statue karya seniman Belanda Florentine Hoffman — ikon "Panda Capital".'
      },
      {
        day: 'Day 08',
        title: 'DUJIANGYAN – CHENGDU (B/L)',
        desc: 'Berbelanja di Jade & Silk Shop. Perjalanan menuju Chengdu. Kunjungi Eastern Suburbs Memory Cultural and Creative Park ("Eastern District Music Park"). Wide and Narrow Alley — kota tua Dinasti Qing. Chunxi Road Pedestrian Street. Photo stop IFS Panda Climbing the Wall. Berbelanja di Taikoo Li — pusat perbelanjaan paling terkenal di Chengdu.'
      },
      {
        day: 'Day 09',
        title: 'CHENGDU – CHONGQING (B/L/D)',
        desc: 'Menuju Chongqing dengan bus. Photo stop Great Hall of the People. Kunjungi Hongya Cave (dahulu Hongya Gate) — salah satu gerbang kota tua Chongqing dengan pemandangan tepi sungai yang memukau.'
      },
      {
        day: 'Day 10',
        title: 'CHONGQING (B/L/-)',
        desc: 'Kunjungi Danzishi Old Street — photo stop di depan Mixue Ice Cream & Tea Store. Kuixing Building — masuk lantai 1 dengan 22 lantai di bawahnya, sensasi unik yang mendebarkan. Liberation Monument dan Liberation Monument Walking Street. Diantar ke bandara untuk penerbangan kembali ke Jakarta.'
      },
      {
        day: 'Day 11',
        title: 'CHONGQING – JAKARTA (MF8673 CKG–CGK 00:05–05:20)',
        desc: 'Tibalah pada akhir perjalanan tour kali ini dengan membawa sejuta kenangan manis. Terima kasih atas partisipasi Anda, sampai jumpa pada acara tour kami lainnya!'
      }
    ],
    inclusions: [
      { label: 'Tiket International Group Xiamen Airlines Economy (Fix Date, Fix Flight, No Refund)',  included: true  },
      { label: 'Bagasi 1 piece 23 kg + Cabin 5 kg',                                                    included: true  },
      { label: 'Akomodasi hotel ★4 (Twin/Triple)',                                                      included: true  },
      { label: 'Transportasi Bus AC & biaya kunjungan objek wisata',                                    included: true  },
      { label: 'Tour Leader dari Jakarta',                                                               included: true  },
      { label: 'Asuransi Perjalanan Standard Group (cover ≤83 tahun)',                                  included: true  },
      { label: 'Bipenggou Scenic Area (eco car + Shanghaizi–Panyang Lake battery car)',                 included: true  },
      { label: 'Dujiangyan Panda Park (battery car included)',                                           included: true  },
      { label: 'Fuel Surcharge / Airport Tax Rp 3.033.000/pax (dapat berubah)',                         included: false },
      { label: 'Visa Group China Rp 980.000/pax (WAJIB; holding visa +Rp 485.280)',                    included: false },
      { label: 'Tipping Tour Leader, Guide & Driver: Rp 986.000/pax',                                   included: false },
      { label: 'Pembuatan paspor dan dokumen lainnya',                                                   included: false },
      { label: 'Pengeluaran pribadi & optional tour',                                                    included: false },
      { label: 'PPN 1,1%',                                                                               included: false },
    ],
    mapCenter: [103.5, 32.0],
    mapZoom: 6,
    mapPins: [
      { lng: 106.5505, lat: 29.5630, label: 'Chongqing — Ciqikou & Hongya Cave' },
      { lng: 104.1537, lat: 32.4200, label: 'Pingwu Bao\'en Temple' },
      { lng: 103.9684, lat: 33.2600, label: 'Jiuzhaigou National Park' },
      { lng: 103.5994, lat: 33.4527, label: 'Mounigou – Zhaga Waterfall (Songpan)' },
      { lng: 103.5870, lat: 31.6878, label: 'Maoxian' },
      { lng: 103.6200, lat: 31.0450, label: 'Bipenggou Scenic Area' },
      { lng: 103.4668, lat: 30.9985, label: 'Dujiangyan Panda Park' },
      { lng: 104.0665, lat: 30.5723, label: 'Chengdu — Wide & Narrow Alley, Taikoo Li' },
    ]
  },

  'MOTOGP SEPANG 2026': {
    badge: 'PAKET EVENT',
    image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1504214208698-ea1916a2195a?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'Saksikan aksi MotoGP Sepang 2026 langsung dari K1 Grandstand via Batik Air! Free T-Shirt, SIM Card, jas hujan & city tour Twin Tower + Dataran Merdeka.',
    price: 'Rp 8.990.000',
    duration: '3 Hari 2 Malam',
    rating: 4.8,
    reviews: 41,
    maxPax: 25,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Batik Air OD397Q/OD396Q (CGK–KUL PP)',
    keberangkatan: '30 Oktober – 1 November 2026',
    minPeserta: '25 Peserta',
    hotelInfoText: 'Cosmo Hotel ★3 atau setara (include breakfast)',
    tipeKamarText: 'Twin/Triple | Single Supplement +Rp 1.000.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Batik Air OD397Q/OD396Q (CGK–KUL PP, bagasi 20 kg)' },
      { icon: '🏍️', text: 'Tiket MotoGP K1 Grandstand (X VR Tribune) — Race Weekend' },
      { icon: '🏁', text: 'Grand Prix MotoGP: Moto3, Moto2 & MotoGP (15:00-16:00)' },
      { icon: '⚡', text: 'Kualifikasi + Sprint Race (included)' },
      { icon: '👕', text: 'Free T-Shirt MotoGP + SIM Card 1GB/hari' },
      { icon: '🧥', text: 'Jas hujan + penutup telinga (siap cuaca apapun)' },
      { icon: '🏙️', text: 'Petronas Twin Tower & Dataran Merdeka city tour' },
      { icon: '🛡️', text: 'Tourism Tax Malaysia included' },
      { icon: '💰', text: 'Upgrade ticket tersedia: Main Grandstand, Premiere Seat, dll.' },
      { icon: '👥', text: 'Minimal 25 Pax + Tour Leader Pendamping' },
    ],
    priceCategories: [
      {
        dateLabel: '30 Oktober – 1 November 2026',
        prices: [
          { type: 'Dewasa (Twin/Triple)',           price: 'Rp 8.990.000' },
          { type: 'Child Extra Bed (maks 10 thn)',  price: 'Rp 8.690.000' },
          { type: 'Child No Bed (maks 5 thn)',      price: 'Rp 8.390.000' },
          { type: 'Single Supplement',               price: '+Rp 1.000.000' },
        ]
      }
    ],
    optionalActivities: [
      { name: 'Upgrade Main Grandstand',      price: '+RM 150/pax' },
      { name: 'Upgrade Marc Marquez Tribune', price: '+RM 65/pax' },
      { name: 'Upgrade Premiere Roving',      price: '+RM 320/pax' },
      { name: 'Upgrade Premiere Seat',        price: '+RM 450/pax' },
      { name: 'Rental Wifi Portable',         price: 'Tersedia' },
      { name: 'Travel Insurance',              price: 'Optional' },
    ],
    itinerary: [
      {
        day: 'Hari 01',
        title: 'JAKARTA – KUALA LUMPUR (Makan Siang, Makan Malam)',
        desc: 'OD397Q CGK–KUL 05:15–08:30. Pagi berkumpul di Bandara Soekarno-Hatta Terminal 3 Ultimate. Setibanya di KL, disambut Guide berbahasa Indonesia. Langsung menuju Sepang International Circuit — saksikan Kualifikasi MotoGP (tiket K1 included). Makan siang, waktu bebas shopping merchandise. Makan malam, check-in Cosmo Hotel / setara.'
      },
      {
        day: 'Hari 02',
        title: 'KUALA LUMPUR (Makan Pagi, Siang, Malam)',
        desc: 'Santap pagi. Diantar ke Sepang Circuit untuk Qualifying & Sprint Race (tiket included). Makan siang. City tour: Petronas Twin Tower — pencakar langit kembar tertinggi di dunia. Dataran Merdeka — saksi bisu pengibaran bendera Malaysia pertama kali 31 Agustus 1957. Makan malam dan kembali ke hotel.'
      },
      {
        day: 'Hari 03',
        title: 'KUALA LUMPUR – JAKARTA (Makan Pagi, Cashmeal Malam)',
        desc: 'OD396Q KUL–CGK 21:55–23:10. Santap pagi, check-out. Menuju Sepang Circuit — Grand Prix MotoGP (tiket included): Moto3 (12:00–13:00), Moto2 (13:20–14:20), MotoGP (15:00–16:00). Usai race, diantar ke KLIA. Cashmeal makan malam dibagikan. Penerbangan kembali ke Jakarta. Terima kasih dan sampai berjumpa di tour selanjutnya!'
      }
    ],
    inclusions: [
      { label: 'Tiket pesawat Batik Air PP + bagasi 20 kg (OD397Q & OD396Q)',                included: true  },
      { label: 'Tiket MotoGP K1 Grandstand (X VR Tribune) — Kualifikasi, Sprint Race & Grand Prix', included: true  },
      { label: 'Akomodasi Cosmo Hotel ★3 atau setara (Twin/Triple) include breakfast',       included: true  },
      { label: 'Transportasi bus 43 seater / Van 13 seater',                                  included: true  },
      { label: 'Local Guide berbahasa Indonesia/Melayu',                                       included: true  },
      { label: 'Makan sesuai program + Mineral water 2 botol/hari',                           included: true  },
      { label: 'Jas hujan + penutup telinga',                                                  included: true  },
      { label: 'Free T-Shirt MotoGP',                                                          included: true  },
      { label: 'SIM Card 1GB/hari',                                                            included: true  },
      { label: 'Tour Leader Pendamping',                                                        included: true  },
      { label: 'Tourism Tax Malaysia',                                                          included: true  },
      { label: 'City Tour (Twin Tower & Dataran Merdeka)',                                     included: true  },
      { label: 'Tipping Guide & Driver',                                                        included: false },
      { label: 'Personal expenses & tips porter, mini bar, laundry, dll.',                    included: false },
      { label: 'Travel Insurance (optional)',                                                   included: false },
      { label: 'Upgrade ticket kategori MotoGP (additional)',                                  included: false },
      { label: 'Rental Wifi Portable (optional)',                                               included: false },
    ],
    mapCenter: [101.7024, 3.1390],
    mapZoom: 10,
    mapPins: [
      { lng: 101.7382, lat: 2.7609,  label: 'Sepang International Circuit — MotoGP Race' },
      { lng: 101.7122, lat: 3.1578,  label: 'Petronas Twin Tower — Kuala Lumpur' },
      { lng: 101.6942, lat: 3.1488,  label: 'Dataran Merdeka — Kuala Lumpur' },
      { lng: 101.7019, lat: 2.7451,  label: 'KLIA — Kuala Lumpur International Airport' },
    ]
  },

  '8D WINTER SCHOOL HOLIDAY BEIJING SHANGHAI WITH UNIVERSAL STUDIO': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1537519191377-d3305ffddce4?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1518005068251-37900150dfca?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'Liburan sekolah musim dingin via Malaysia Airlines! Universal Studio Beijing, Juyongguan Great Wall, Temple of Heaven, West Lake, Wuzhen & The Bund Shanghai.',
    price: 'Rp 16.990.000',
    duration: '8 Hari 7 Malam',
    rating: 4.7,
    reviews: 86,
    maxPax: 25,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Malaysia Airlines MH722/MH318/MH387/MH717 (Economy, Group Fixed Date, No Extend)',
    keberangkatan: '14 – 18 Desember 2026 (Winter School Holiday)',
    minPeserta: '20 Peserta',
    hotelInfoText: 'Hotel ★3 atau ★4 Lokal/Similar (Beijing, Suzhou/Hangzhou & Shanghai)',
    tipeKamarText: 'Twin/Triple | Single Supplement +Rp 4.750.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Malaysia Airlines MH (Economy, Group Fixed Date, No Extend)' },
      { icon: '🧳', text: 'Bagasi 30 kg sesuai ketentuan Malaysia Airlines' },
      { icon: '🎢', text: 'Universal Studios Beijing — Harry Potter, Jurassic World & lebih' },
      { icon: '🧱', text: 'Juyongguan Great Wall — salah satu keajaiban dunia' },
      { icon: '⛩️', text: 'Temple of Heaven — kuil kekaisaran berarsitektur megah' },
      { icon: '🏟️', text: 'Bird\'s Nest & Water Cube — ikon Olimpiade Beijing 2008' },
      { icon: '🌊', text: 'West Lake Hangzhou — naik kapal di panorama legendaris' },
      { icon: '🏘️', text: 'Wuzhen East Gate — kota air tradisional penuh budaya' },
      { icon: '🌉', text: 'The Bund Shanghai — simbol kota dengan skyline Pudong' },
      { icon: '🎉', text: 'Liburan sekolah akhir tahun, Des 2026' },
    ],
    priceCategories: [
      {
        dateLabel: '14 Des 2026',
        prices: [
          { type: 'Dewasa (Twin/Triple)',        price: 'Rp 16.990.000' },
          { type: 'Child No Bed (<6 Tahun)',     price: 'Rp 16.590.000' },
          { type: 'Single Supplement',            price: '+Rp 4.750.000' },
          { type: 'Infant Flat Rate (<23 Bln)',   price: 'Rp 3.750.000' },
        ]
      },
      {
        dateLabel: '15 Des 2026',
        prices: [
          { type: 'Dewasa (Twin/Triple)',        price: 'Rp 16.990.000' },
          { type: 'Child No Bed (<6 Tahun)',     price: 'Rp 16.590.000' },
          { type: 'Single Supplement',            price: '+Rp 4.750.000' },
        ]
      },
      {
        dateLabel: '16 Des 2026',
        prices: [
          { type: 'Dewasa (Twin/Triple)',        price: 'Rp 16.990.000' },
          { type: 'Child No Bed (<6 Tahun)',     price: 'Rp 16.590.000' },
          { type: 'Single Supplement',            price: '+Rp 4.750.000' },
        ]
      },
      {
        dateLabel: '17 Des 2026',
        prices: [
          { type: 'Dewasa (Twin/Triple)',        price: 'Rp 16.990.000' },
          { type: 'Child No Bed (<6 Tahun)',     price: 'Rp 16.590.000' },
          { type: 'Single Supplement',            price: '+Rp 4.750.000' },
        ]
      },
      {
        dateLabel: '18 Des 2026',
        prices: [
          { type: 'Dewasa (Twin/Triple)',        price: 'Rp 16.990.000' },
          { type: 'Child No Bed (<6 Tahun)',     price: 'Rp 16.590.000' },
          { type: 'Single Supplement',            price: '+Rp 4.750.000' },
        ]
      },
    ],
    optionalActivities: [
      { name: 'Rental Wifi Portable / SIM Card', price: 'Tersedia' },
    ],
    itinerary: [
      {
        day: 'Hari 01',
        title: 'JAKARTA – DEPARTURE BEIJING (Meals on Board)',
        desc: 'CGK (18.25) – KUL (21.35) by MH722, lanjut KUL (00.50) – PKX (07.00) by MH318. Berkumpul di Bandara Soekarno-Hatta Terminal 3 Ultimate untuk berangkat menuju Beijing dengan Malaysia Airlines. Bermalam di pesawat.'
      },
      {
        day: 'Hari 02',
        title: 'BEIJING (Makan Siang)',
        desc: 'Tiba di Beijing, disambut Guide yang ramah. Kunjungi Temple of Heaven — kuil dengan arsitektur khas dan megah. Tian An Men Square — lapangan terluas di dunia. Wangfujing Street untuk berbelanja. Check-in hotel ★3 atau ★4 lokal/similar. Istirahat.'
      },
      {
        day: 'Hari 03',
        title: 'BEIJING — UNIVERSAL STUDIOS (Makan Pagi)',
        desc: 'Sarapan pagi di hotel. Seharian di Universal Studios Beijing — taman hiburan Universal Studios pertama di Tiongkok. Nikmati area bertema: Hollywood, Jurassic World Isla Nublar, Kung Fu Panda Land of Awesomeness, The Wizarding World of Harry Potter, dan masih banyak lagi. Setiap area menawarkan wahana, pertunjukan, dan restoran yang terinspirasi film-film populer untuk segala usia. Check-in hotel, istirahat.'
      },
      {
        day: 'Hari 04',
        title: 'BEIJING (Makan Pagi, Siang, Malam)',
        desc: 'Sarapan pagi di hotel. Kunjungi Juyongguan Great Wall — tembok terpanjang di dunia, salah satu keajaiban dunia. Photo stop Beijing National Stadium (Bird\'s Nest) & Water Cube National Aquatics Center (Outlook). Berbelanja di Xiushui Market. Menikmati bebek Peking — hidangan khas China yang terkenal. Check-in hotel, istirahat.'
      },
      {
        day: 'Hari 05',
        title: 'BEIJING – SUZHOU – HANGZHOU (Makan Pagi, Makan Malam)',
        desc: 'Sarapan pagi di hotel. Menuju Suzhou menggunakan Bullet Train. Di Suzhou: photo stop Oriental Gate — gedung pencakar langit yang ikonik, dan Jinji Lake — danau terbesar di kota China. Lanjut ke Hangzhou, kunjungi Hefang Street — jalan bersejarah santai untuk belanja dan kuliner lokal. Check-in hotel, istirahat.'
      },
      {
        day: 'Hari 06',
        title: 'HANGZHOU – WUZHEN – SHANGHAI (Makan Pagi, Siang, Malam)',
        desc: 'Sarapan pagi di hotel. Naiki kapal menjelajahi West Lake, menikmati panorama indah di Su Di. Kunjungi Wuzhen East Gate (exclude rowing boat) — pintu masuk kawasan Wuzhen yang kaya akan pesona tradisional dan budaya. Kunjungi Chenghuang Market — kuliner khas Shanghai dan souvenir oleh-oleh. Check-in hotel, istirahat.'
      },
      {
        day: 'Hari 07',
        title: 'SHANGHAI (Makan Pagi, Makan Siang)',
        desc: 'Sarapan pagi di hotel. Kunjungi The Bund — simbol kota Shanghai dengan deretan bangunan kolonial berlatar Pudong modern. Nanjing Road untuk berbelanja. Dilanjutkan perjalanan menuju airport.'
      },
      {
        day: 'Hari 08',
        title: 'SHANGHAI – DEPARTURE (Meals on Board)',
        desc: 'PVG (02.15) – KUL (08.05) by MH387, lanjut KUL (10.00) – CGK (11.20) by MH717. Kembali ke tanah air tercinta. Berakhirlah tour yang berkesan ini — sampai jumpa di tour selanjutnya!'
      }
    ],
    inclusions: [
      { label: 'Tiket International Malaysia Airlines Economy (Group Fixed Date, No Extend) + taxes internasional', included: true  },
      { label: 'Bagasi 30 kg sesuai ketentuan Airlines',                                                             included: true  },
      { label: 'Akomodasi hotel ★3 atau ★4 lokal/similar (Twin/Triple)',                                             included: true  },
      { label: 'Transportasi bus pariwisata & tiket masuk objek wisata',                                              included: true  },
      { label: 'Acara tour & makan sesuai program',                                                                   included: true  },
      { label: 'Mineral water 1 botol per hari',                                                                      included: true  },
      { label: 'Tour Leader',                                                                                          included: true  },
      { label: 'Travel Kits (Luggage Tag)',                                                                            included: true  },
      { label: 'Travel Insurance',                                                                                     included: true  },
      { label: 'Visa Group China Rp 1.200.000 (atau Single: Jkt Rp 1.200.000 | Sby/Mdn Rp 1.500.000 | Bali Rp 1.600.000)', included: true  },
      { label: 'Tipping Tour Leader, Local Guide, Driver: Rp 1.300.000/Pax',                                         included: false },
      { label: 'Tips porter hotel, mini bar, laundry, telp, kelebihan bagasi',                                        included: false },
      { label: 'PPN 1,2%',                                                                                             included: false },
      { label: 'Rental Wifi Portable / SIM Card (optional)',                                                           included: false },
      { label: 'Apabila visa di-reject, biaya pembatalan sesuai ketentuan yang berlaku',                              included: false },
    ],
    mapCenter: [116.4074, 31.5],
    mapZoom: 5,
    mapPins: [
      { lng: 116.4074, lat: 39.9042, label: 'Beijing — Temple of Heaven, Great Wall & Universal Studio' },
      { lng: 120.6196, lat: 31.2990, label: 'Suzhou — Jinji Lake & Oriental Gate' },
      { lng: 120.1551, lat: 30.2741, label: 'Hangzhou — West Lake & Hefang Street' },
      { lng: 120.4856, lat: 30.7490, label: 'Wuzhen — Kota Air Tradisional' },
      { lng: 121.4737, lat: 31.2304, label: 'Shanghai — The Bund & Nanjing Road' },
    ]
  },

  'Best Deal Guilin Yangshuo by Batik Air 09 Hari / 07 Malam': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1537519191377-d3305ffddce4?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1537519191377-d3305ffddce4?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1518005068251-37900150dfca?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: '4 kota via Batik Air! Elephant Trunk Hill, Bamboo Raft & Cormorant Show, Moon Hill, Yangshuo West Street & Fuli Ancient Town.',
    price: 'Rp 7.980.000',
    duration: '9 Hari 7 Malam',
    rating: 4.7,
    reviews: 93,
    maxPax: 30,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Batik Air ID7623 (Economy Class, non-endorsable, non-refundable)',
    keberangkatan: 'Jun: 30 | Jul: 07, 14, 21, 28 | Aug: 04, 11, 18, 25',
    minPeserta: '30 Peserta',
    hotelInfoText: 'Nanning Yingcheng · Guilin Vienna · Yangshuo Wanli Garden · Liuzhou Nantian',
    tipeKamarText: 'Twin Sharing | Single Supplement +Rp 2.500.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Batik Air Economy (non-endorsable, non-refundable)' },
      { icon: '🧳', text: 'Bagasi 20 kg + Kabin 5 kg per pax' },
      { icon: '🐘', text: 'Elephant Trunk Hill — ikon Guilin di tepi Sungai Li' },
      { icon: '⭐', text: 'Seven Star Park (battery car included) — taman terbesar Guilin' },
      { icon: '🛶', text: 'Bamboo Raft & Cormorant Show — tradisi nelayan burung kormoran' },
      { icon: '🌕', text: 'Moon Hill — puncak karst dengan lengkungan berbentuk bulan' },
      { icon: '🏘️', text: 'Fuli Ancient Town — kipas lukis warisan budaya tak benda' },
      { icon: '🏙️', text: 'Yaobu Ancient Town — nuansa Dinasti Ming & Qing tepi sungai' },
      { icon: '🏪', text: '4 Toko Wajib: Tibetan Medicine, An Gong, Silk & Jade Store' },
      { icon: '👥', text: 'Minimal 30 Pax + Tour Leader Indonesia' },
    ],
    priceCategories: [
      {
        dateLabel: 'Jun 30 | Jul 07, 14, 21, 28 | Aug 04, 11, 18, 25 (2026)',
        prices: [
          { type: 'Dewasa / Child Twin / Child Extra Bed', price: 'Rp 7.980.000' },
          { type: 'Child No Bed',                          price: 'Rp 7.680.000' },
          { type: 'Single Supplement',                     price: '+Rp 2.500.000' },
        ]
      }
    ],
    optionalActivities: [
      { name: 'Night cruise on Guilin\'s Four Lakes',                       price: 'RMB 300/orang' },
      { name: 'Guilin Eternal Love Show atau Impression Liu Sanjie',        price: 'RMB 300/orang' },
      { name: 'Guilin Ruyi Peak (cable car + glass bridge)',                price: 'RMB 400/orang' },
      { name: 'Night boat cruise on the Liu River',                         price: 'RMB 300/orang' },
      { name: 'Reed Flute Cave',                                            price: 'RMB 250/orang' },
      { name: 'Cruise on Lijiang River',                                    price: 'RMB 300/orang' },
    ],
    itinerary: [
      {
        day: 'Day 01',
        title: 'JAKARTA – NANNING (ID7623 CGK–NNG 18.55–23.30)',
        desc: 'Berkumpul di Bandara Internasional Soekarno-Hatta untuk penerbangan menuju Nanning dengan Batik Air ID7623. Setibanya, diantar menuju hotel untuk beristirahat.'
      },
      {
        day: 'Day 02',
        title: 'NANNING – GUILIN (B/L/-)',
        desc: 'Setelah sarapan, diantar menuju Guilin menggunakan bus. Kunjungi Qingxiu Mountain Park — kawasan wisata nasional "Paru-paru Hijau Nanning". Rongshan Lake Scenic Area: The Sun Moon Twin Tower — bangunan tembaga tertinggi di dunia sekaligus menara tertinggi di atas air. Diakhiri di Zhengyang Pedestrian Street — jalan komersial pusat Guilin yang memadukan perbelanjaan dan hiburan.'
      },
      {
        day: 'Day 03',
        title: 'GUILIN (B/L/-)',
        desc: 'City tour Guilin: Elephant Trunk Hill Scenic Area — bukit bebatuan berbentuk gajah di tepi Sungai Li yang sedang minum dari sungai. Seven Star Park (termasuk battery car) — taman terbesar di Guilin dengan pemandangan indah dari Bukit Unta.'
      },
      {
        day: 'Day 04',
        title: 'GUILIN (B/L/-)',
        desc: 'Kunjungi Fubo Mountain — puncak batu kapur menawarkan panorama kota dan Sungai Li yang menakjubkan. Berjalan-jalan di Dongxi Lane and Xiaoyao Tower — jalan bersejarah peninggalan Dinasti Ming dan Qing di Guilin.'
      },
      {
        day: 'Day 05',
        title: 'GUILIN – YANGSHUO (B/L/-)',
        desc: 'Setelah sarapan, diantar menuju Yangshuo. Kunjungi Nanxishan Park — dua puncak gunung saling berhadapan dengan sungai mengalir di antaranya. Osmanthus Commune Scenic Area — mencicipi kue osmanthus, hidangan penutup tradisional Tiongkok dari tepung beras ketan, madu, gula, dan bunga osmanthus manis.'
      },
      {
        day: 'Day 06',
        title: 'YANGSHUO (B/L/-)',
        desc: 'Kunjungi Fuli Ancient Town — mempelajari pembuatan kipas lukis Fuli, warisan budaya tak benda. Menaiki Bamboo Raft & Cormorant Show — perjalanan santai di rakit bambu dengan pertunjukan tradisional nelayan burung kormoran. Diakhiri di Yangshuo West Street — berbelanja atau mencicipi makanan lokal.'
      },
      {
        day: 'Day 07',
        title: 'YANGSHUO – LIUZHOU (B/L/-)',
        desc: 'Diantar menuju kota Liuzhou. Saksikan Moon Hill — puncak karst dengan lengkungan alami berbentuk bulan. Kunjungi Yaobu Ancient Town — kota tua bergaya tradisional tepi sungai yang memadukan budaya kuno Tiongkok dengan wisata modern, kuliner, pertokoan, pertunjukan seni, dan bangunan klasik bernuansa Dinasti Ming dan Qing.'
      },
      {
        day: 'Day 08',
        title: 'LIUZHOU – NANNING (B/L/-)',
        desc: 'Setelah sarapan dan check-out, kunjungi Longtan Park — area pemandangan luas yang menggabungkan lanskap karst dan adat istiadat budaya etnis minoritas Tiongkok Selatan. Lanjut ke Nanhu Park. Sore hari, kunjungi Three Streets and Two Alleys — jalanan bersejarah dari Dinasti Song. Kemudian diantar ke bandara untuk penerbangan menuju Jakarta.'
      },
      {
        day: 'Day 09',
        title: 'NANNING – JAKARTA',
        desc: 'Setibanya di Jakarta, tibalah pada akhir perjalanan tour kali ini dengan membawa sejuta kenangan manis. Terima kasih atas partisipasi Anda dan sampai jumpa pada acara tour kami lainnya!'
      }
    ],
    inclusions: [
      { label: 'Tiket pesawat PP kelas ekonomi Batik Air (non-endorsable, non-refundable)',    included: true  },
      { label: 'Bagasi 20 kg/pax + Kabin 5 kg/pax',                                            included: true  },
      { label: 'Penginapan hotel twin sharing di Nanning, Guilin, Yangshuo & Liuzhou',          included: true  },
      { label: 'Acara tour, transportasi & makan sesuai program (B/L/D)',                        included: true  },
      { label: '4x Toko Wajib: Tibetan Medicine, An Gong Store, Silk Store, Jade Store',        included: true  },
      { label: 'Tour Leader dari Indonesia',                                                      included: true  },
      { label: 'Fuel Surcharge Rp 2.224.200/pax (dapat berubah)',                               included: false },
      { label: 'Biaya dokumen perjalanan: paspor, entry permit, dll.',                           included: false },
      { label: 'Pengeluaran pribadi: telepon, room service, laundry, mini bar, dll.',            included: false },
      { label: 'Excess baggage di atas 20 kg & bea masuk',                                       included: false },
      { label: 'Single Supplement +Rp 2.500.000',                                               included: false },
      { label: 'Travelling bag',                                                                  included: false },
      { label: 'Visa China Group Single Entry Rp 960.450/pax (MUST USE GROUP VISA)',             included: false },
      { label: 'Tips Tour Leader, Local Guide & Driver: Rp 950.000/pax',                         included: false },
      { label: 'Optional Tour, Foreign Surcharge & PPN 1,1%',                                   included: false },
      { label: 'Asuransi perjalanan: 0–69th Rp 247.000 | >70th Rp 593.000/pax',                included: false },
    ],
    mapCenter: [110.2900, 25.2744],
    mapZoom: 7,
    mapPins: [
      { lng: 108.3665, lat: 22.8170, label: 'Nanning — Qingxiu Mountain & Sun Moon Tower' },
      { lng: 110.2900, lat: 25.2744, label: 'Guilin — Elephant Trunk Hill & Seven Star Park' },
      { lng: 110.4966, lat: 24.7784, label: 'Yangshuo — Bamboo Raft & West Street' },
      { lng: 109.4285, lat: 24.3264, label: 'Liuzhou — Yaobu Ancient Town & Longtan Park' },
      { lng: 110.4432, lat: 24.8194, label: 'Moon Hill — Yangshuo' },
    ]
  },

  'UZBEKISTAN 9D7N': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1596484552834-6a58f850e0a1?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1596484552834-6a58f850e0a1?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1587049352851-8d4e89133924?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1548694904-7e2bb5fb5f3b?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'Jalur Sutra legendaris via Batik Air! Registan Square, Maqam Imam Al Bukhari, Citadel Ark Bukhara, Chimgan Mountains & Afrosiyob Bullet Train.',
    price: 'Rp 34.990.000',
    duration: '9 Hari 7 Malam',
    rating: 4.8,
    reviews: 54,
    maxPax: 25,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Batik Air OD381/OD751/OD752/OD392 (via Kuala Lumpur)',
    keberangkatan: '03 – 11 November 2026',
    minPeserta: 'Individu / Grup',
    hotelInfoText: 'Khan Palace Hotel★4 (Tashkent) · Samaria Hotel★4 (Samarkand) · Sahid Zarafshon★4 (Bukhara)',
    tipeKamarText: 'Sesuai program | Single Supplement tersedia',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Batik Air via Kuala Lumpur (CGK–KUL–TAS PP)' },
      { icon: '🕌', text: 'Registan Square — ikon tiga madrasah mozaik keramik Samarkand' },
      { icon: '📿', text: 'Maqam Imam Al Bukhari — makam imam hadits termasyhur' },
      { icon: '🏰', text: 'Citadel Ark — benteng kuno kediaman penguasa Bukhara' },
      { icon: '🌿', text: 'Bahauddin Naqshbandi Complex — situs ziarah sakral Asia Tengah' },
      { icon: '🚄', text: 'Afrosiyob Bullet Train Bukhara–Tashkent (included)' },
      { icon: '⛰️', text: 'Chimgan Mountains & Charvak Lake — panorama Tian Shan' },
      { icon: '🏺', text: 'Pottery Workshop Gijduvan & Samarkand Paper Workshop' },
      { icon: '🌍', text: 'Guide berbahasa Indonesia + makanan halal sesuai program' },
      { icon: '🛡️', text: 'Deposit Rp 10.000.000 | Pelunasan 30 hari sebelum berangkat' },
    ],
    priceCategories: [
      {
        dateLabel: '03 – 11 November 2026',
        prices: [
          { type: 'Per Pax (Twin/Triple)',       price: 'Rp 34.990.000' },
          { type: 'Tipping & Asuransi (WAJIB)', price: 'Rp 1.750.000/Pax' },
          { type: 'Airport Tax & Fuel Surcharge', price: 'USD 200–300/Pax' },
        ]
      }
    ],
    optionalActivities: [
      { name: 'Jiuzhai Tibetan & Qiang Ethnic Singing & Dancing Party (Samarkand)', price: 'Sesuai penawaran' },
      { name: 'Optional Tour lainnya (wajib pesan via kami)',                         price: 'Sesuai penawaran' },
    ],
    itinerary: [
      {
        day: 'Day 01',
        title: 'JAKARTA – KUALA LUMPUR – TASHKENT (03 Nov)',
        desc: 'Berkumpul di Soekarno-Hatta International Airport pukul 07:00. Berangkat menuju Kuala Lumpur dengan Batik Air OD381 (ETD 09:15 | ETA 12:30). Berangkat menuju Tashkent OD751 (ETD 17:00 | ETA 21:50). Setelah proses imigrasi dan pengambilan bagasi, bertemu guide berbahasa Indonesia. Check-in hotel dan bermalam di Tashkent.'
      },
      {
        day: 'Day 02',
        title: 'TASHKENT – SAMARKAND (B/L/D)',
        desc: 'Sarapan di hotel lalu check-out. Perjalanan menuju Samarkand. Kunjungi Gur Emir Mausoleum — makam Tamerlane yang megah. Registan Square — ikon tiga madrasah berhiaskan mozaik keramik. Siyaab Bazaar dan Bibi Khanym Mosque. Mengunjungi Shakhi Zindeh — kompleks makam berornamen keramik biru yang menakjubkan. Makan malam di restoran lokal. Check-in hotel dan bermalam di Samarkand.'
      },
      {
        day: 'Day 03',
        title: 'SAMARKAND (B/L/D)',
        desc: 'Sarapan di hotel. Kunjungi Maqam Imam Al Bukhari — makam imam hadits termasyhur. Ulughbek Observatory — observatorium astronomi abad ke-15. National Bazaar. Carpet Factory — menyaksikan pembuatan karpet tradisional Uzbekistan. Samarkand Paper Workshop — kertas tradisional dari kayu murbei. Makan malam di restoran lokal. Bermalam di Samarkand.'
      },
      {
        day: 'Day 04',
        title: 'SAMARKAND – GIJDUVAN – BUKHARA (B/L/D)',
        desc: 'Sarapan di hotel lalu check-out. Perjalanan menuju Gijduvan. Kunjungi Pottery Workshop — kerajinan tembikar khas seniman Gijduvan yang terkenal di Jalur Sutra. Lanjut perjalanan menuju Bukhara. Check-in hotel dan bermalam di Bukhara.'
      },
      {
        day: 'Day 05',
        title: 'BUKHARA (B/L/D)',
        desc: 'Sarapan di hotel. Kunjungi Citadel Ark — benteng kuno kediaman penguasa Bukhara. Samanid\'s Mausoleum — makam dinasti Samanid abad ke-10. Chashma Ayub dan Bolo Hauz Mosque. Berbelanja di Nodir Divan Begi. Photo stop Lyabi Hauz Complex, Poi Kalon Complex, dan Kalon Minaret — menara setinggi 47m. Kunjungi Mir Arab Madrasah. Bermalam di Bukhara.'
      },
      {
        day: 'Day 06',
        title: 'BUKHARA – TASHKENT (B/L/D)',
        desc: 'Sarapan di hotel lalu check-out. Kunjungi Bahauddin Naqshbandi Complex, Mosques of Kushbegi dan Muzafarohana, serta Tomb of Saint Bakhauddin Nakshbandi — salah satu situs ziarah paling sakral di Asia Tengah. Perjalanan menuju Tashkent menggunakan kereta Afrosiyob bullet train. Makan malam di restoran lokal. Check-in hotel dan bermalam di Tashkent.'
      },
      {
        day: 'Day 07',
        title: 'TASHKENT (B/L/D)',
        desc: 'Sarapan di hotel. Kunjungi Chimgan Mountains — pegunungan bersalju di utara Tashkent dengan panorama Tian Shan yang memukau. Kunjungi Charvak Lake — danau reservoir berwarna biru-hijau yang dikelilingi pegunungan indah. Makan malam di restoran lokal. Kembali ke hotel dan bermalam di Tashkent.'
      },
      {
        day: 'Day 08',
        title: 'TASHKENT – KUALA LUMPUR (B/L/D) (10 Nov)',
        desc: 'Sarapan di hotel lalu check-out. Kunjungi Independence Square dan Amir Timur Square — pusat kota Tashkent modern. Chorsu Bazaar — pasar tertua dan terbesar di Tashkent. Kukaldash Madrasah dan The Hast Imam Complex — koleksi manuskrip Al-Qur\'an tertua di dunia. Menuju Tashkent International Airport ETD 23:30 dengan OD752.'
      },
      {
        day: 'Day 09',
        title: 'KUALA LUMPUR – JAKARTA (11 Nov)',
        desc: 'Tiba di Kuala Lumpur International Airport ETA 11:00. Berangkat kembali menuju Jakarta OD392 pukul 17:55. Tiba di Soekarno-Hatta International Airport ETA 19:10. Perjalanan selesai — semoga kita bisa berjumpa di perjalanan selanjutnya!'
      }
    ],
    inclusions: [
      { label: 'Tiket penerbangan International Batik Air (CGK–KUL–TAS PP)',               included: true  },
      { label: 'Akomodasi hotel ★4: Khan Palace (Tashkent), Samaria (Samarkand), Sahid Zarafshon (Bukhara)', included: true  },
      { label: 'Guide berbahasa Indonesia',                                                  included: true  },
      { label: 'Tour & transportasi sesuai program',                                         included: true  },
      { label: 'Afrosiyob Bullet Train Bukhara–Tashkent',                                   included: true  },
      { label: 'Makanan halal sesuai program',                                               included: true  },
      { label: 'Tipping dan asuransi perjalanan Rp 1.750.000/Pax (WAJIB)',                  included: false },
      { label: 'Airport Tax & Fuel Surcharge USD 200–300/Pax',                              included: false },
      { label: 'Pengeluaran pribadi',                                                         included: false },
      { label: 'Biaya optional tour (wajib pesan via kami)',                                 included: false },
      { label: 'Porter',                                                                      included: false },
      { label: 'Minuman dan makanan tambahan selama makan',                                  included: false },
    ],
    mapCenter: [63.0, 40.5],
    mapZoom: 6,
    mapPins: [
      { lng: 69.2401, lat: 41.2995, label: 'Tashkent — Chorsu Bazaar & Hast Imam' },
      { lng: 66.9597, lat: 39.6270, label: 'Samarkand — Registan Square & Gur Emir' },
      { lng: 67.2879, lat: 40.1173, label: 'Gijduvan — Pottery Workshop' },
      { lng: 64.4286, lat: 39.7747, label: 'Bukhara — Citadel Ark & Kalon Minaret' },
      { lng: 69.9725, lat: 41.5735, label: 'Chimgan Mountains & Charvak Lake' },
    ]
  },

  'Chongqing Wulong Jiuzhaigou by SQ 09 Hari / 07 Malam': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1537819191377-d3305ffddce4?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1518005068251-37900150dfca?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'Jiuzhaigou UNESCO + Wulong Three Bridges + Panda Park via Singapore Airlines! Fairy Mountain, Hongya Cave & Chunxi Road.',
    price: 'Rp 19.900.000',
    duration: '9 Hari 7 Malam',
    rating: 4.8,
    reviews: 78,
    maxPax: 20,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Singapore Airlines (Economy Class, Fixed Date, Fixed Flight)',
    keberangkatan: '25 Agustus 2026',
    minPeserta: '20 Peserta',
    hotelInfoText: 'Hotel ★4 — Dujiangyan, Jiuzhaigou, Chengdu, Chongqing & Wulong',
    tipeKamarText: 'Twin/Triple | Single Supplement +Rp 5.000.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Singapore Airlines Economy (Fixed Date, Fixed Flight)' },
      { icon: '🧳', text: 'Bagasi 25 kg + Kabin 7 kg per pax' },
      { icon: '🐼', text: 'Dujiangyan Panda Park — pusat konservasi panda raksasa' },
      { icon: '🌊', text: 'Jiuzhaigou Scenic Area — Situs Warisan Dunia UNESCO' },
      { icon: '🏔️', text: 'Five Color Pond & Long Lake — keajaiban warna alam' },
      { icon: '🌉', text: 'Wulong Tiankeng Three Bridges — jembatan alami karst raksasa' },
      { icon: '⛰️', text: 'Fairy Mountain — "Eastern Switzerland" di China' },
      { icon: '🏮', text: 'Hongya Cave — ikon tepi sungai Chongqing bergaya diaojiaolou' },
      { icon: '🚄', text: 'Bullet train 2nd class Chengdu–Jiuzhaigou PP (included)' },
      { icon: '🛡️', text: 'Tour Leader Indonesia + Guide berbahasa Inggris' },
    ],
    priceCategories: [
      {
        dateLabel: '25 Agustus 2026',
        prices: [
          { type: 'Dewasa / Child (Twin/Triple)',   price: 'Rp 19.900.000' },
          { type: 'Child No Bed',                    price: 'Rp 19.500.000' },
          { type: 'Single Supplement',               price: '+Rp 5.000.000' },
        ]
      }
    ],
    optionalActivities: [
      { name: 'Jiuzhai Tibetan & Qiang Ethnic Singing & Dancing Party', price: 'RMB 280/Pax' },
      { name: 'Chongqing Two Rivers Night Tour',                         price: 'RMB 280/Pax' },
      { name: '"Chongqing.1949" (termasuk Region of Rotation)',           price: 'RMB 398/Pax' },
    ],
    itinerary: [
      {
        day: 'Day 01',
        title: 'JAKARTA – SINGAPORE – CHENGDU – DUJIANGYAN (-/-/D)',
        desc: 'Pada waktu yang telah ditentukan, semua peserta diminta berkumpul di Bandara Soekarno-Hatta untuk melakukan penerbangan menuju Chengdu via Singapore. Setibanya di Chengdu, dijemput dan melakukan perjalanan menuju Dujiangyan menggunakan bus. Setibanya akan makan malam dan check-in hotel.'
      },
      {
        day: 'Day 02',
        title: 'DUJIANGYAN – CHENGDU – JIUZHAIGOU (B/L/D)',
        desc: 'Setelah sarapan pagi, diantar menuju Dujiangyan Panda Park (termasuk battery car) — pusat konservasi dan penelitian panda raksasa. Kemudian perjalanan ke Chengdu menggunakan bus, dilanjutkan ke Jiuzhaigou menggunakan bullet train (termasuk tiket 2nd class). Setibanya check-in hotel dan makan malam.'
      },
      {
        day: 'Day 03',
        title: 'JIUZHAIGOU (B/L/D)',
        desc: 'Fullday tour Jiuzhaigou Scenic Area (termasuk public eco-bus). Nikmati keindahan Jiuzhaigou: Mirror Lake, Pearl Waterfall, Nuorilang Waterfall, Five Color Pond, dan Long Lake — danau terbesar, terdalam, dan tertinggi (±3.000–3.150 mdpl) di kawasan tersebut. Berbentuk seperti bulan sabit dan dikelilingi pegunungan bersalju, menawarkan pemandangan menakjubkan dengan air biru tua yang jernih. Situs Warisan Dunia UNESCO.'
      },
      {
        day: 'Day 04',
        title: 'JIUZHAIGOU – CHENGDU (B/L/D)',
        desc: 'Setelah sarapan, berbelanja di Comprehensive Shop untuk melihat berbagai produk lokal dan suvenir khas. Lanjut perjalanan ke Chengdu menggunakan bullet train (termasuk tiket 2nd class). Tiba di Chengdu, kunjungi Chunxi Road Pedestrian Street dan Taikoo Li Chengdu — area lifestyle terbuka memadukan arsitektur tradisional dan modern. Photo stop IFS Panda Climbing the Wall. Makan malam, kemudian check-in hotel.'
      },
      {
        day: 'Day 05',
        title: 'CHENGDU – CHONGQING (B/L/D)',
        desc: 'Setelah sarapan, berbelanja di Herbal Medicine Center. Lanjut perjalanan ke Chongqing dengan bus. Kunjungi Liberation Monument Walking Street. Lanjut ke Hongya Cave — kompleks bangunan tradisional bergaya diaojiaolou yang ikonik dengan pemandangan malam indah di tepi sungai. Makan malam dan check-in hotel.'
      },
      {
        day: 'Day 06',
        title: 'CHONGQING – WULONG (B/L/D)',
        desc: 'Setelah sarapan, perjalanan menuju Wulong menggunakan bus. Kunjungi Wulong Tiankeng Three Bridges (termasuk elevator + shuttle bus + battery car) — geopark terkenal dengan formasi karst raksasa berupa tiga jembatan alami yang terbentuk dari runtuhan gua purba. Saksikan lembah sinkhole (tiankeng) yang dalam dan tebing batu kapur menjulang tinggi. Makan malam dan check-in hotel.'
      },
      {
        day: 'Day 07',
        title: 'WULONG – CHONGQING (B/L/D)',
        desc: 'Setelah sarapan, kunjungi Fairy Mountain (termasuk small train) — kawasan pegunungan dengan padang rumput luas yang dikenal sebagai "Eastern Switzerland", terkenal dengan udara sejuk dan pemandangan alam yang indah. Lanjut kembali ke Chongqing dengan bus. Kunjungi Danzishi Old Street — kawasan bernuansa klasik dengan arsitektur tradisional dan pemandangan pertemuan Sungai Yangtze dan Jialing.'
      },
      {
        day: 'Day 08',
        title: 'CHONGQING – SINGAPORE – JAKARTA (B/L/-)',
        desc: 'Setelah sarapan, berbelanja di Latex Shop. Kunjungi Ciqikou Ancient Town — kota tua terkenal dengan arsitektur tradisional, jajanan lokal, dan suasana klasik khas Tiongkok. Kemudian Kuixing Building — bangunan ikonik bertingkat yang sering menjadi spot foto menarik. Waktu bebas berbelanja di The Ring Shopping Park. Diantar ke bandara untuk penerbangan kembali ke Jakarta via Singapore.'
      },
      {
        day: 'Day 09',
        title: 'ARRIVAL JAKARTA',
        desc: 'Setibanya di Jakarta, perjalanan bersama kami pada kali ini sudah berakhir. Terima kasih atas partisipasi Anda, sampai jumpa pada perjalanan berikutnya!'
      }
    ],
    inclusions: [
      { label: 'Tiket International Group by Singapore Airlines Economy (Fixed Date, Fixed Flight)',  included: true  },
      { label: 'Bagasi 25 kg/Pax, Kabin 7 kg/Pax',                                                   included: true  },
      { label: 'Akomodasi hotel ★4 dengan makan pagi (Twin/Triple)',                                   included: true  },
      { label: 'Makanan sesuai itinerary (B=Pagi, L=Siang, D=Malam)',                                  included: true  },
      { label: 'Transportasi Bus AC',                                                                   included: true  },
      { label: 'Tour Leader Indonesia dari Jakarta',                                                    included: true  },
      { label: 'Tour Guide berbahasa Inggris',                                                          included: true  },
      { label: 'Tiket masuk objek wisata sesuai itinerary',                                             included: true  },
      { label: 'Dujiangyan Panda Park (battery car included)',                                          included: true  },
      { label: 'Bullet train Chengdu–Jiuzhaigou & Jiuzhaigou–Chengdu 2nd class',                       included: true  },
      { label: 'Jiuzhaigou Scenic Area (public eco-bus included)',                                      included: true  },
      { label: 'Wulong Tiankeng Three Bridges (elevator + shuttle + battery car)',                      included: true  },
      { label: 'Fairy Mountain (small train included)',                                                  included: true  },
      { label: 'Biaya dokumen perjalanan: paspor, entry permit, dll.',                                  included: false },
      { label: 'Pengeluaran pribadi: telepon, room service, laundry, mini bar, dll.',                   included: false },
      { label: 'Excess baggage di atas 25 kg & bea masuk',                                              included: false },
      { label: 'Single Supplement +Rp 5.000.000',                                                       included: false },
      { label: 'Travelling bag',                                                                         included: false },
      { label: 'Tips Tour Leader, Local Guide & Driver: Rp 1.100.000/Pax',                              included: false },
      { label: 'Visa Group Single Entry: Rp 990.780 (MUST USE GROUP VISA)',                              included: false },
      { label: 'Optional Tour & PPN 1,1%',                                                              included: false },
    ],
    mapCenter: [106.5505, 29.5630],
    mapZoom: 5,
    mapPins: [
      { lng: 103.4668, lat: 30.9985, label: 'Dujiangyan Panda Park' },
      { lng: 103.9684, lat: 33.2600, label: 'Jiuzhaigou Scenic Area' },
      { lng: 104.0665, lat: 30.5723, label: 'Chengdu — Chunxi Road & Taikoo Li' },
      { lng: 106.5505, lat: 29.5630, label: 'Chongqing — Hongya Cave & Ciqikou' },
      { lng: 107.7520, lat: 29.3234, label: 'Wulong Tiankeng Three Bridges' },
      { lng: 107.8123, lat: 29.5021, label: 'Fairy Mountain — "Eastern Switzerland"' },
    ]
  },

  '9D SNOWY NEW YEAR CHINA HARBIN SNOW TOWN + BEIJING': {
    badge: 'PAKET INTERNASIONAL',
    image: 'assets/china-poster.jpg',
    galleryImages: [
      'assets/china-poster.jpg',
      'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1537819191377-d3305ffddce4?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'Rayakan Tahun Baru di musim dingin China via Singapore Airlines! Forbidden City, Juyongguan Great Wall, Giant Snowman, Songhua River Ice World, Yabuli Ski Resort & Snow Town.',
    price: 'Rp 29.990.000',
    duration: '9 Hari 8 Malam',
    rating: 4.8,
    reviews: 65,
    maxPax: 20,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Singapore Airlines SQ967/SQ800/SQ805/SQ964 (Economy, Group Fixed Date, No Extend)',
    keberangkatan: '30 Desember 2026 (New Year)',
    minPeserta: '20 Peserta',
    hotelInfoText: 'Hotel ★3 atau ★4 Lokal Setaraf (Beijing, Harbin & Erlanghe)',
    tipeKamarText: 'Twin/Triple | Single Supplement +Rp 7.500.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Singapore Airlines SQ (Economy Class, Group Fixed Date)' },
      { icon: '🧳', text: 'Bagasi 25 kg sesuai ketentuan Singapore Airlines' },
      { icon: '🏯', text: 'Forbidden City — istana kekaisaran megah bersejarah' },
      { icon: '🧱', text: 'Juyongguan Great Wall — Tembok Besar dengan pemandangan pegunungan' },
      { icon: '⛄', text: 'Giant Snowman 18m — landmark ikonik di tepi Sungai Songhua' },
      { icon: '❄️', text: 'Songhua River Ice & Snow World — festival patung es terbesar dunia' },
      { icon: '🎿', text: 'Yabuli Ski Resort — resort ski terbesar di China' },
      { icon: '🏔️', text: 'Snow Town — desa salju impian bak negeri dongeng' },
      { icon: '🎉', text: 'Rayakan Tahun Baru 2027 di China, 31 Des 2026' },
      { icon: '🛡️', text: 'Travel Insurance s.d. usia 82 tahun' },
    ],
    priceCategories: [
      {
        dateLabel: '30 Desember 2026 — New Year',
        prices: [
          { type: 'Dewasa (Twin/Triple)',        price: 'Rp 29.990.000' },
          { type: 'Child No Bed (<6 Tahun)',     price: 'Rp 28.990.000' },
          { type: 'Single Supplement',            price: '+Rp 7.500.000' },
          { type: 'Infant Flat Rate (<23 Bln)',   price: 'Rp 4.500.000' },
        ]
      }
    ],
    optionalActivities: [
      { name: 'Funicular ke puncak Snow Town',          price: 'Tersedia' },
      { name: 'Rental Wifi Portable / SIM Card',        price: 'Tersedia' },
      { name: 'Visa Single Jakarta',                     price: 'Rp 1.300.000' },
      { name: 'Visa Single Surabaya / Medan',            price: 'Rp 1.500.000' },
      { name: 'Visa Single Bali',                        price: 'Rp 1.600.000' },
    ],
    itinerary: [
      {
        day: 'Hari 01',
        title: 'JAKARTA – DEPARTURE (Meals on Board)',
        desc: 'CGK (20.20) – SIN (23.05) by SQ 967. Berkumpul di Bandara Soekarno-Hatta untuk berangkat menuju Beijing transit Singapore dengan Singapore Airlines. Bermalam di pesawat.'
      },
      {
        day: 'Hari 02',
        title: 'BEIJING (Makan Siang, Makan Malam)',
        desc: 'SIN (01.10) – PEK (07.15) by SQ 800. Tiba di Beijing, disambut Guide ramah. Langsung menuju Tian An Men Square — lapangan terluas di dunia. Kemudian Forbidden City (Kota Terlarang) — kompleks istana kekaisaran megah kediaman kaisar selama ratusan tahun dengan arsitektur tradisional luar biasa. Check-in hotel ★3/★4 lokal.'
      },
      {
        day: 'Hari 03',
        title: 'BEIJING – HARBIN (Makan Pagi, Makan Malam)',
        desc: 'Sarapan di hotel. Perjalanan ke Harbin menggunakan kereta. Kunjungi Purchase Warm Clothing — toko pakaian hangat. Central Street — jalan pejalan kaki terpanjang di Asia, satu-satunya jalan berbatu di Harbin. Centennial Binzhou Railway Bridge — jembatan kereta api berusia seabad. Check-in hotel.'
      },
      {
        day: 'Hari 04',
        title: 'HARBIN CITY TOUR (Makan Pagi, Siang, Malam)',
        desc: 'Giant Snowman 18 meter — landmark daya tarik utama Harbin di area Sungai Songhua. Saksikan Winter Swimming — atraksi masyarakat setempat. Sophia Cathedral Square — salah satu gereja tertua di Harbin. Photo stop Harbin Grand Theater. Songhua River Ice and Snow World — Festival Patung Es & Salju Internasional Harbin, objek wisata musim dingin terpopuler di dunia (jika tutup, diganti Siberian Tiger Park).'
      },
      {
        day: 'Hari 05',
        title: 'HARBIN – SNOW TOWN – ERLANGHE (Makan Pagi, Siang, Malam)',
        desc: 'Snow Rhythm Street — berbelanja souvenir & produk lokal. Sightseeing Plank Road — pemandangan indah gunung dan alam sekitar. Photo stop Fairy Tale Post Office. Folk Customs Museum — museum adat rakyat China. Snow Village Disco Square — sekitar 20 rumah salju dengan pemandangan salju yang menakjubkan. Check-in hotel.'
      },
      {
        day: 'Hari 06',
        title: 'ERLANGHE – YABULI – HARBIN (Makan Pagi, Siang, Malam)',
        desc: 'Yabuli Ski Resort — resort ski terbesar di China. Naiki kereta luncur kuda melewati hutan birch dan saksikan the Asian Winter Games site. Kembali ke Harbin menggunakan bus. Check-in hotel.'
      },
      {
        day: 'Hari 07',
        title: 'HARBIN – BEIJING (Makan Pagi, Makan Malam)',
        desc: 'Sarapan di hotel. Perjalanan ke Beijing menggunakan kereta. Kunjungi Wangfujing — kawasan belanja oleh-oleh paling terkenal di Beijing. Check-in hotel.'
      },
      {
        day: 'Hari 08',
        title: 'BEIJING (Makan Pagi, Siang, Malam)',
        desc: 'Juyongguan Great Wall — bagian Tembok Besar Tiongkok terkenal dengan pemandangan pegunungan indah dan sejarah pertahanan kuno yang megah. Photo stop Beijing National Stadium (Bird\'s Nest) & Beijing National Aquatics Center (Water Cube) — ikon Olimpiade Beijing 2008 yang modern. Kembali ke hotel.'
      },
      {
        day: 'Hari 09',
        title: 'BEIJING – DEPARTURE (Meals on Board)',
        desc: 'PEK (08.45) – SIN (15.30) by SQ 805, lanjut SIN (17.20) – CGK (18.05) by SQ 964. Penerbangan kembali ke tanah air. Berakhirlah tour yang berkesan ini — sampai jumpa di tour selanjutnya!'
      }
    ],
    inclusions: [
      { label: 'Tiket International CGK–PEK PP by Singapore Airlines Economy (Group Fixed Date, No Extend)',  included: true  },
      { label: 'Bagasi 25 kg sesuai ketentuan Singapore Airlines',                                             included: true  },
      { label: 'Akomodasi hotel ★3 atau ★4 Lokal setaraf (Twin/Triple) — Beijing, Harbin & Erlanghe',        included: true  },
      { label: 'Transportasi bus pariwisata & tiket masuk objek wisata',                                       included: true  },
      { label: 'Acara tour & makan sesuai program',                                                            included: true  },
      { label: 'Mineral water 1 botol per hari',                                                               included: true  },
      { label: 'Tour Leader Indonesia',                                                                         included: true  },
      { label: 'Travel Kits (Luggage Tag)',                                                                     included: true  },
      { label: 'Travel Insurance s.d. usia 82 tahun',                                                          included: true  },
      { label: 'Visa Group China Rp 1.200.000 (Single: Jkt Rp 1.300.000 | Sby/Mdn Rp 1.500.000 | Bali Rp 1.600.000)',  included: true  },
      { label: 'Tipping Tour Leader, Local Guide & Driver: Rp 1.500.000/Pax',                                 included: false },
      { label: 'Tips porter, mini bar, laundry, telp, kelebihan bagasi',                                       included: false },
      { label: 'PPN 1,2%',                                                                                      included: false },
      { label: 'Rental Wifi Portable / SIM Card (optional)',                                                   included: false },
      { label: 'Apabila visa di-reject, biaya pembatalan sesuai ketentuan yang berlaku',                       included: false },
    ],
    mapCenter: [116.4074, 39.9042],
    mapZoom: 5,
    mapPins: [
      { lng: 116.4074, lat: 39.9042, label: 'Beijing — Forbidden City & Great Wall' },
      { lng: 126.5348, lat: 45.8038, label: 'Harbin — Ice & Snow World, Giant Snowman' },
      { lng: 128.3247, lat: 44.5831, label: 'Snow Town (Erlanghe) — Snow Village' },
      { lng: 128.5605, lat: 44.9108, label: 'Yabuli Ski Resort' },
    ]
  },

  'Macau + Hongkong 06 Hari / 04 Malam': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1518684079-3c830dcef090?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1518684079-3c830dcef090?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1536599018102-9f803c140fc1?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'HIGHLIGHT: YONGQINGFANG – BEIJING ROAD – ZHUHAI OPERA HOUSE – RUIN ST. PAUL – SENADO SQUARE – VENETIAN MACAU – HZMB BRIDGE – VICTORIA PEAK – AVENUE OF STARS – OH BAY FERRIS WHEEL – CANTON TOWER',
    price: 'Rp 8.880.000',
    duration: '6 Hari 4 Malam',
    rating: 4.6,
    reviews: 110,
    maxPax: 26,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Air China / Spring Airlines (Economy Class)',
    keberangkatan: 'Jun / Aug / Sep / Oct 2026',
    minPeserta: '26 Peserta (Didampingi 1 Tour Leader)',
    hotelInfoText: 'Hotel ★4 Local / Similar: Zhuhai (Days Inn Wyndham / Starcity), Macau (Casa Real), Shenzhen (Dejin / Venus)',
    tipeKamarText: 'Twin Sharing | Single Supplement +Rp 2.300.000 (Jun) / +Rp 2.500.000 (Aug-Oct)',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Air China / Spring Airlines Economy Class' },
      { icon: '🧳', text: 'Bagasi 20 kg + Handbag 7 kg' },
      { icon: '🛍️', text: 'Guangzhou — Yongqingfang & Beijing Road Shopping' },
      { icon: '🏛️', text: 'Zhuhai — Opera House, Lovers Road & Fisher Girl Statue' },
      { icon: '🎰', text: 'Macau — Ruin St. Paul, Senado Square, Eiffel Tower Parisian & Venetian Macau (Gondola)' },
      { icon: '🌉', text: 'HZMB — Jembatan Laut Terpanjang di Dunia (Macau–Hongkong)' },
      { icon: '🏙️', text: 'Hongkong — Victoria Peak, Avenue of Stars, Clock Tower & K11' },
      { icon: '🎡', text: 'Shenzhen — OH Bay! Ferris Wheel, Shenzhen Bay Book City & Nantou Ancient City' },
      { icon: '🗼', text: 'Canton Tower & Huacheng Square Guangzhou' },
      { icon: '📜', text: 'China Group Visa FREE untuk WNI' },
    ],
    priceCategories: [
      {
        dateLabel: 'JUN 2026 (28, 30 JUN)',
        prices: [
          { type: 'Dewasa / Child Twin', price: 'Rp 9.790.000' },
          { type: 'Child No Bed',         price: 'Rp 9.590.000' },
          { type: 'Single Supplement',   price: '+Rp 2.300.000' },
          { type: 'Fuel Surcharge',       price: 'IDR 800.000 (dapat berubah)' }
        ]
      },
      {
        dateLabel: 'AUG - OCT 2026 (16, 18, 23, 25 AUG | 01, 08, 15 SEP | 13 OCT)',
        prices: [
          { type: 'Dewasa / Child Twin', price: 'Rp 8.880.000' },
          { type: 'Child No Bed',         price: 'Rp 8.680.000' },
          { type: 'Single Supplement',   price: '+Rp 2.500.000' },
          { type: 'Fuel Surcharge',       price: 'IDR 2.500.000 (dapat berubah)' }
        ]
      }
    ],
    optionalActivities: [
      { name: 'Splendid China + Folk Culture Village + Show / Window of the World', price: 'RMB 350/pax' },
      { name: 'Shijingshan Mountain Cable Car + Dinner + Night Market', price: 'RMB 350/pax' },
      { name: 'Shenzhen Diwang Building', price: 'RMB 180/pax' }
    ],
    itinerary: [
      {
        day: 'Hari 01',
        title: 'JAKARTA – GUANGZHOU',
        desc: 'Pada waktu yang telah ditentukan, berkumpul di Bandara Internasional Soekarno Hatta untuk penerbangan menuju Guangzhou.'
      },
      {
        day: 'Hari 02',
        title: 'GUANGZHOU - ZHUHAI (MAKAN PAGI, MAKAN SIANG, MAKAN MALAM)',
        desc: 'Setibanya di Guangzhou, diantar menuju hotel untuk menikmati sarapan. Kunjungi Yongqingfang (perpaduan arsitektur tradisional & modern) & berbelanja di Beijing Road (pusat perbelanjaan sejak Dinasti Qin). Makan siang, dilanjutkan perjalanan menuju Zhuhai melihat Zhuhai Opera House di tepi laut, melewati Lovers Road, & photostop Fisher Girl Statue.'
      },
      {
        day: 'Hari 03',
        title: 'ZHUHAI - MACAU (MAKAN PAGI)',
        desc: 'Setelah sarapan, diantar menuju Macau menggunakan bus. City tour Macau: Ruin St. Paul (gereja terbesar pada masanya), Senado Square (kawasan Eropa abad ke-16), Eiffel Tower Parisian Hotel (photo stop), & free time di Venetian Macau (naik gondola & kuliner).'
      },
      {
        day: 'Hari 04',
        title: 'MACAU - HONGKONG - SHENZHEN (MAKAN PAGI, MAKAN SIANG)',
        desc: 'Perjalanan menuju Hongkong melewati HZMB (jembatan laut terpanjang di dunia menghubungkan Hongkong-Zhuhai-Macau). Nikmati pemandangan spektakuler Victoria Peak, mengunjungi Avenue of Stars, Clock Tower, & K11.'
      },
      {
        day: 'Hari 05',
        title: 'SHENZHEN (MAKAN PAGI, MAKAN SIANG)',
        desc: 'Sarapan, mengunjungi OH Bay! (melihat Ferris Wheel Shenzhen ikonik), Shenzhen Bay Book City (book mall futuristik), & Nantou Ancient City (kota tua bersejarah Shenzhen). Kunjungi pusat Jade & toko herbal Tongrentang, diakhiri waktu berbelanja di Dongmen Shopping Street.'
      },
      {
        day: 'Hari 06',
        title: 'SHENZHEN - GUANGZHOU - JAKARTA (MAKAN PAGI, MAKAN SIANG)',
        desc: 'Sarapan, perjalanan kembali ke Guangzhou, singgah ke Canton Tower (simbol kota Guangzhou) & Huacheng Square (pencakar langit megah). Makan siang, diantar ke bandara untuk penerbangan kembali ke Jakarta.'
      }
    ],
    inclusions: [
      { label: 'Tiket pesawat udara p.p. kelas ekonomi Air China / Spring Airlines (Fixed Group Date & No Extend)', included: true },
      { label: 'China Visa Group untuk WNI (FREE, namun dapat berubah sesuai kebijakan pemerintah China)', included: true },
      { label: 'Airport Tax International (dapat berubah sewaktu-waktu)', included: true },
      { label: 'Penginapan hotel bintang 4* (Twin Sharing): Zhuhai (Days Inn Wyndham/Starcity), Macau (Casa Real), Shenzhen (Dejin/Venus)', included: true },
      { label: 'Acara tour, transportasi bus pariwisata & makan (B/L/D) sesuai jadwal', included: true },
      { label: 'Bagasi 20 kg (1 pcs) + Handbag 7 kg ke kabin', included: true },
      { label: 'Tour Leader berpengalaman dari Indonesia', included: true },
      { label: 'Kunjungan toko wajib selama tour (Pearl & Jade, Herb, Latex, Silk)', included: true },
      { label: 'Fuel Surcharge: Jun IDR 800.000 / Aug-Oct IDR 2.500.000', included: false },
      { label: 'Tipping Tour Leader, Local Guide & Driver: IDR 750.000/Pax', included: false },
      { label: 'PPN 1,1%', included: false },
      { label: 'Biaya dokumen perjalanan (paspor, entry permit, dll)', included: false },
      { label: 'Optional Tour (Splendid China RMB350, Shijingshan Cable Car RMB350, Diwang Building RMB180)', included: false },
      { label: 'Asuransi Perjalanan', included: false }
    ],
    mapCenter: [113.5439, 22.1987],
    mapZoom: 7,
    mapPins: [
      { lng: 113.2644, lat: 23.1291, label: 'Guangzhou (Beijing Road & Canton Tower)' },
      { lng: 113.5767, lat: 22.2710, label: 'Zhuhai (Opera House & Lovers Road)' },
      { lng: 113.5439, lat: 22.1987, label: 'Macau (Ruin St. Paul & Venetian)' },
      { lng: 114.1694, lat: 22.3193, label: 'Hongkong (Victoria Peak & Avenue of Stars)' },
      { lng: 114.0579, lat: 22.5431, label: 'Shenzhen (OH Bay & Dongmen)' }
    ]
  },

  '6D ENCHANTING AUTUMN KOREA SEOUL BUSAN': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1538485399081-7191377e8241?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1538485399081-7191377e8241?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1517154421773-0529f29ea451?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1546874177-9e664107314e?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'HIGHLIGHT: NAMI ISLAND, KIMBAP MAKING, GYEONGBOK PALACE, BLUE LINE PARK + CAPSULE TRAIN, GAMCHEON CULTURAL VILLAGE',
    price: 'Rp 13.990.000',
    duration: '6 Hari 5 Malam',
    rating: 4.8,
    reviews: 125,
    maxPax: 20,
    ctaLabel: 'Pesan Sekarang',
    maskapai: 'Garuda Indonesia (CGK-ICN-CGK: GA 878 / GA 879)',
    keberangkatan: '9 Oct - 15 Nov 2026',
    minPeserta: '20 Peserta (Didampingi 1 Tour Leader)',
    hotelInfoText: 'Hotel ★3 Local / Similar (Twin / Triple)',
    tipeKamarText: 'Twin / Triple | Single Supplement +Rp 4.000.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Garuda Indonesia Economy (CGK-ICN-CGK GA 878/879)' },
      { icon: '🧳', text: 'Bagasi 30 kg' },
      { icon: '🍁', text: 'Nami Island — Lokasi Syuting "Winter Sonata"' },
      { icon: '🍱', text: 'Kimbab Making Experience & Hanbok Wearing' },
      { icon: '🛍️', text: 'Hongdae Youth Avenue, Dongdaemun & Myeongdong Street' },
      { icon: '🏯', text: 'Gyeongbok Palace, National Folk Museum & Blue House (pass by)' },
      { icon: '🕌', text: 'Itaewon (Masjid / Lokasi Syuting "Itaewon Class")' },
      { icon: '🌊', text: 'Cheonggyecheon Stream & Gwanganri Bridge Night View' },
      { icon: '⛩️', text: 'Haedong Yonggungsa Temple — Kuil Tepi Laut' },
      { icon: '🚟', text: 'Blue Line Park (Capsule Train Included) & Haeundae Beach' },
      { icon: '🎨', text: 'Gamcheon Cultural Village — Rumah Warna-Warni' },
      { icon: '🍢', text: 'BIFF Market & Kukje Market Busan' },
      { icon: '🛡️', text: 'Travel Insurance Included (s.d. Usia 69 Tahun)' },
    ],
    priceCategories: [
      {
        dateLabel: 'KEBERANGKATAN OKTOBER & NOVEMBER 2026',
        prices: [
          { type: 'Dewasa (Twin/Triple)',        price: 'Rp 13.990.000' },
          { type: 'Child No Bed (<6 Tahun)',     price: 'Rp 13.590.000' },
          { type: 'Single Supplement',           price: '+Rp 4.000.000' }
        ]
      },
      {
        dateLabel: 'Infant Rate',
        prices: [
          { type: 'Infant Flat Rate (< 23 Bulan)', price: 'Rp 4.000.000' }
        ]
      }
    ],
    optionalActivities: [
      { name: 'Rental Wifi Portable', price: 'Optional' }
    ],
    itinerary: [
      {
        day: 'Hari 01',
        title: 'JAKARTA – INCHEON (MEALS ON BOARD)',
        desc: 'CGK (23.15) – ICN (08.30) +1 by GA 878. Malam ini kita berkumpul di Bandara Soekarno-Hatta terminal 3 Ultimate untuk berangkat menuju ke Incheon dengan Garuda Indonesia. Bermalam di pesawat.'
      },
      {
        day: 'Hari 02',
        title: 'INCHEON – NAMI ISLAND (MAKAN SIANG)',
        desc: 'Setiba di Incheon disambut Guide berbahasa Indonesia yang ramah, langsung mengunjungi Nami Island (lokasi syuting "Winter Sonata"). Belajar membuat Kimbab & Hanbok Wearing (pakaian tradisional Korea). Malam hari berbelanja di Hongdae Youth Avenue. Check-in hotel & istirahat. Bermalam di Hotel *3 / similar.'
      },
      {
        day: 'Hari 03',
        title: 'SEOUL CITY TOUR (MAKAN PAGI, MAKAN SIANG)',
        desc: 'Sarapan pagi di hotel. Mengunjungi National Ginseng Museum & K-Cosmetic Shop. Kunjungi Gyeongbok Palace & National Folk Museum (tidak termasuk hanbok), melewati Blue House (pass by), Itaewon (Masjid / lokasi syuting "Itaewon Class"), Dongdaemun (pusat belanja fashion), & melewati Cheonggyecheon Stream (pass by). Kembali ke hotel & istirahat. Bermalam di Hotel *3 / similar.'
      },
      {
        day: 'Hari 04',
        title: 'SEOUL – BUSAN (MAKAN PAGI, MAKAN SIANG)',
        desc: 'Sarapan pagi di hotel, shopping tour di Red Pine Shop, Amethyst Shop, & Duty Free Shop. Berbelanja di Myeongdong Street, dilanjutkan perjalanan menuju Busan. Setibanya di Busan, melewati Gwanganri Bridge (pass by) menikmati pemandangan malam gemerlap lampu jembatan pantai Busan. Check-in hotel & istirahat. Bermalam di Hotel *3 / similar.'
      },
      {
        day: 'Hari 05',
        title: 'BUSAN CITY TOUR (MAKAN PAGI, MAKAN SIANG)',
        desc: 'Sarapan pagi di hotel. Mengunjungi Haedong Yonggungsa Temple (kuil tepi laut), Blue Line Park (termasuk Capsule Train - lokasi syuting "Now We Are Breaking Up"), Haeundae Beach (pantai paling populer di Busan), Gamcheon Cultural Village (rumah bertingkat warna-warni), BIFF Market & Kukje Market (pusat kuliner & pasar tradisional). Kembali ke hotel & istirahat. Bermalam di Hotel *3 / similar.'
      },
      {
        day: 'Hari 06',
        title: 'BUSAN – SEOUL – DEPARTURE (MEALS ON BOARD)',
        desc: 'ICN (10.35) - CGK (15.40) by GA 879. Pagi hari kembali ke Seoul, mengunjungi Local Supermarket untuk berbelanja oleh-oleh sebelum ke Incheon Airport. Diantar ke Airport untuk penerbangan kembali ke Jakarta.'
      }
    ],
    inclusions: [
      { label: 'Tiket International Jakarta-Incheon Garuda Indonesia Economy termasuk taxes internasional (Fixed Date & No Extend)', included: true },
      { label: 'Bagasi 30 kg sesuai ketentuan Garuda Indonesia', included: true },
      { label: 'Akomodasi hotel *3 setaraf (Twin / Triple)', included: true },
      { label: 'Transportasi bus Pariwisata & tiket masuk objek wisata', included: true },
      { label: 'Acara Tour & makan sesuai program paket tour diatas', included: true },
      { label: 'Mineral Water 1 Botol Per Hari', included: true },
      { label: 'Tour Leader berpengalaman dari Indonesia', included: true },
      { label: 'Travel Kits (Luggage Tag)', included: true },
      { label: 'Travel Insurance (sampai usia 69 Tahun)', included: true },
      { label: 'Visa Group Korea (Jika diarahkan Visa Individual, biaya Rp 1.075.000)', included: true },
      { label: 'Tipping Tour Leader, Local Guide, Driver: Rp 990.000/Pax', included: false },
      { label: 'Tips Porter Hotel, Mini Bar, Laundry, Telp, Kelebihan bagasi dll.', included: false },
      { label: 'PPN 1,2%', included: false },
      { label: 'Rental Wifi Portable (OPTIONAL)', included: false }
    ],
    mapCenter: [129.0756, 35.1796],
    mapZoom: 7,
    mapPins: [
      { lng: 126.9780, lat: 37.5665, label: 'Seoul (Gyeongbok Palace & Hongdae)' },
      { lng: 127.5252, lat: 37.7915, label: 'Nami Island (Winter Sonata)' },
      { lng: 129.0756, lat: 35.1796, label: 'Busan (Haeundae & Gamcheon Cultural Village)' }
    ],
    remarks: [
      'Apabila Visa Korea direject akan dikenakan biaya pembatalan sesuai ketentuan yang berlaku',
      'Tour ini merupakan tour bersubsidi dengan mengunjungi Shopping Stop, Penalty akan dikenakan untuk peserta yang tidak mengunjungi shopping stop',
      'Rules (Term and Condition) telah diatur sesuai dengan yang ditetapkan oleh wholesaler dan tidak dapat diganggu gugat',
      'No cancel/Change Name after 35 Days before Departure'
    ]
  },

  'UMROH LUXURY FAMILY': {
    badge: 'PAKET IBADAH',
    image: 'https://images.unsplash.com/photo-1591604129939-f1efa4d9f7fa?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1591604129939-f1efa4d9f7fa?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1519817650390-64a93db51149?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'HIGHLIGHT: SAUDIA AIRLINES DIRECT FLIGHT – HOTEL FULLBOARD MAKKAH & MADINAH – LOUNGE TERMINAL 3 – ZIARAH MAKKAH & MADINAH',
    price: 'Rp 34.900.000',
    duration: '9 Hari 7 Malam',
    rating: 4.9,
    reviews: 160,
    maxPax: 45,
    ctaLabel: 'Pesan Paket Umroh',
    maskapai: 'Saudia Airlines (SV 819 Direct Flight)',
    keberangkatan: '30 Sep 2026',
    minPeserta: '20 Jamaah (Didampingi Pembimbing & TL)',
    hotelInfoText: 'Hotel ★4 Fullboard Makkah & Madinah',
    tipeKamarText: 'Quad / Triple / Double Sharing Fullboard',
    hasGroupEksklusif: true,
    hasPembimbingIbadah: true,
    highlights: [
      { icon: '✈️', text: 'Saudia Airlines SV 819 (Direct Flight CGK-JED)' },
      { icon: '🏨', text: 'Hotel Fullboard Makkah & Madinah' },
      { icon: '🕋', text: 'Pelaksanaan Umroh Pertama & Umroh Kedua di Ji’ronah' },
      { icon: '🕌', text: 'Sholat Jumat di Masjidil Haram Makkah' },
      { icon: '🌴', text: 'Ziarah Makkah: Jabal Tsur, Jabal Nur, Jabal Rahmah, Arafah, Muzdalifah & Mina' },
      { icon: '💚', text: 'Makam Rasulullah SAW, Makam Sahabat & Raudhah Taman Surga (Masjid Nabawi)' },
      { icon: '🚌', text: 'City Tour Madinah: Makam Baqi, Gunung Uhud, Qiblatain, Quba & Kebun Kurma' },
      { icon: '🛋️', text: 'Lounge Keberangkatan Terminal 3 Bandara Soekarno-Hatta' },
      { icon: '🧳', text: 'Perlengkapan Umroh, Travel Kit, Manasik & Sikopatuh' },
      { icon: '🛡️', text: 'Asuransi Perjalanan Umroh Included' },
    ],
    priceCategories: [
      {
        dateLabel: 'KEBERANGKATAN 30 SEPTEMBER 2026',
        prices: [
          { type: 'Paket Umroh Luxury (Quad Share)', price: 'Rp 34.900.000' }
        ]
      }
    ],
    itinerary: [
      {
        day: 'Hari 01',
        title: 'RABU, 30 SEPTEMBER 2026: JAKARTA – JEDDAH – MAKKAH',
        desc: 'Jamaah berkumpul di Bandara Soekarno Hatta Terminal 3 keberangkatan Internasional pukul 13.00 WIB. Pembagian Paspor Asli & Boarding Pass, Pengarahan Teknis, Doa, serta Proses Boarding & Imigrasi. Berangkat menuju Jeddah dengan Saudia Airlines SV 819 pukul 17.30 WIB. Tiba di Bandara King Abdul Aziz Jeddah pukul 23.00 WAS. Imigrasi & bagasi. Perjalanan bus ke Makkah, check-in hotel. Bersama-sama melaksanakan UMROH PERTAMA.'
      },
      {
        day: 'Hari 02',
        title: 'KAMIS, 01 OKTOBER 2026: MAKKAH',
        desc: 'Acara bebas, jamaah memperbanyak ibadah wajib dan sunnah di Masjidil Haram.'
      },
      {
        day: 'Hari 03',
        title: 'JUM’AT, 02 OKTOBER 2026: MAKKAH',
        desc: 'Melaksanakan Sholat Jumat di Masjidil Haram, jamaah memperbanyak ibadah di Masjidil Haram.'
      },
      {
        day: 'Hari 04',
        title: 'SABTU, 03 OKTOBER 2026: MAKKAH – MAZARATH',
        desc: 'Ziarah Kota Makkah: mengunjungi Jabal Tsur, Jabal Nur, Jabal Rahmah, Arafah – Muzdalifah – Mina, dan Ji’ronah untuk mengambil Miqot UMROH KEDUA.'
      },
      {
        day: 'Hari 05',
        title: 'MINGGU, 04 OKTOBER 2026: MAKKAH – MADINAH',
        desc: 'Koper disiapkan di depan kamar masing-masing. Pagi hari melaksanakan Thawaf Wada’, jamaah bersiap-siap melanjutkan perjalanan menuju Madinah. Tiba di Madinah, check-in hotel, acara bebas perbanyak ibadah di Masjid Nabawi.'
      },
      {
        day: 'Hari 06',
        title: 'SENIN, 05 OKTOBER 2026: MADINAH',
        desc: 'Jamaah memperbanyak ibadah di Masjid Nabawi, mengunjungi Makam Rasulullah SAW, Makam Sahabat, dan Raudhah Taman Surga (Jadwal Raudhah menyesuaikan izin Muasasah/pihak terkait).'
      },
      {
        day: 'Hari 07',
        title: 'SELASA, 06 OKTOBER 2026: MADINAH – MAZARATH',
        desc: 'Pagi hari City Tour Kota Madinah: mengunjungi Makam Baqi, Gunung Uhud, Masjid Qiblatain, Masjid Quba, Masjid Sab’ah, dan Kebun Kurma.'
      },
      {
        day: 'Hari 08',
        title: 'RABU, 07 OKTOBER 2026: MADINAH – JAKARTA',
        desc: 'Persiapan Check-out hotel, perjalanan menuju Bandara Madinah untuk penerbangan ke Jakarta menggunakan Saudia Airlines take-off pukul 20.15 WAS.'
      },
      {
        day: 'Hari 09',
        title: 'KAMIS, 08 OKTOBER 2026: JAKARTA',
        desc: 'InsyaAllah jamaah tiba di Bandara Soekarno Hatta pukul 10.25 WIB, pengambilan bagasi & imigrasi. Berakhirlah perjalanan ibadah umroh, semoga Allah menerima amal ibadah kita. Aamiin.'
      }
    ],
    inclusions: [
      { label: 'Tiket Pesawat PP Saudia Airlines (SV 819 Direct Flight)', included: true },
      { label: 'Visa Umroh + Transportasi Bus AC Pariwisata', included: true },
      { label: 'Hotel Fullboard Makkah & Madinah', included: true },
      { label: 'Handling Saudi, CGK, Guide & Tour Leader berpengalaman', included: true },
      { label: 'Lounge keberangkatan Terminal 3 Bandara Soekarno-Hatta', included: true },
      { label: 'Asuransi Perjalanan Umroh', included: true },
      { label: 'Perlengkapan umroh & Travel Kit', included: true },
      { label: 'Manasik Umroh & Sikopatuh', included: true },
      { label: 'Pembuatan Paspor', included: false },
      { label: 'Biaya Keperluan Pribadi diluar paket (telepon, laundry, room service, dll)', included: false }
    ],
    remarks: [
      'Pelaksanaan Miqot Umroh bisa di Yalamlam atau di Bandara Jeddah dikoordinir oleh Tour Leader.',
      'Kain Ihram harus dimasukkan ke dalam Cabin, jangan dimasukkan ke dalam koper bagasi.',
      'Mandi Ihram dilaksanakan di rumah masing-masing sebelum berangkat.',
      'Jadwal Raudhah menyesuaikan dengan jadwal Raudhah yang dikeluarkan dari Muasasah / pihak terkait.',
      'Program bersifat tentatif, kemungkinan perubahan urutan acara/jadwal bisa terjadi sesuai dengan kondisi operasional di lapangan.'
    ],
    mapCenter: [39.8262, 21.4225],
    mapZoom: 7,
    mapPins: [
      { lng: 39.8262, lat: 21.4225, label: 'Makkah Al-Mukarramah (Masjidil Haram)' },
      { lng: 39.6142, lat: 24.4672, label: 'Madinah Al-Munawwarah (Masjid Nabawi)' },
      { lng: 39.1565, lat: 21.6796, label: 'Bandara King Abdulaziz Jeddah' }
    ]
  },

  'Umroh Al Fatih Spesial Series 12 Hari Bintang 5': {
    badge: 'PAKET IBADAH',
    image: 'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1591604129939-f1efa4d9f7fa?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1519817650390-64a93db51149?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'HIGHLIGHT: GARUDA INDONESIA DIRECT FLIGHT – HOTEL BINTANG 5 PELATARAN MASJID (MADEN & SOFWA TOWER III) – KERETA CEPAT HARAMAIN – SPIRITUAL JOURNEY THE WINNER',
    price: 'Rp 49.500.000',
    duration: '12 Hari 10 Malam',
    rating: 4.9,
    reviews: 180,
    maxPax: 45,
    ctaLabel: 'Pesan Paket Umroh Al Fatih',
    maskapai: 'Garuda Indonesia (Boeing 777-300 Direct Flight CGK-MED / JED-CGK)',
    keberangkatan: '03 Sep 2026',
    minPeserta: '20 Jamaah (Didampingi Pembimbing & TL)',
    hotelInfoText: 'Hotel ★5 Pelataran Masjid: Maden Hotel Madinah & Sofwa Tower III Makkah',
    tipeKamarText: 'Quad Rp 49,5 Jt | Triple Rp 53,5 Jt | Double Rp 58,5 Jt',
    hasGroupEksklusif: true,
    hasPembimbingIbadah: true,
    highlights: [
      { icon: '✈️', text: 'Garuda Indonesia Direct Flight Jakarta-Madinah (GA 960 / GA 981 Boeing 777-300)' },
      { icon: '🏨', text: 'Hotel Bintang 5 Pelataran Masjid: Maden Hotel Madinah & Sofwa Tower III Makkah' },
      { icon: '🚅', text: 'Kereta Cepat Haramain (Madinah ke Makkah)' },
      { icon: '📖', text: 'Modul Spiritual Journey & Leadership "The Winner" (Target Hafal Surah Al-Mulk)' },
      { icon: '🕌', text: '2x Sholat Jumat di Masjidil Haram & Program Arbain' },
      { icon: '💚', text: 'Ziarah Makam Rasulullah SAW, Makam Sahabat & Raudhah Taman Surga (Masjid Nabawi)' },
      { icon: '🌴', text: '3x City Tour Lengkap: Madinah, Makkah & Jeddah Corniche / Masjid Qishash' },
      { icon: '🍗', text: 'Kuliner Khas Albaik & Lounge Bandara Terminal 3 Soekarno-Hatta' },
      { icon: '💧', text: 'Air Zamzam 5 Liter + Asuransi Perjalanan + Manasik H-1 Jakarta' },
      { icon: '🛡️', text: '5 Pasti Umroh: Izin, Tanggal Berangkat, Pesawat, Hotel, Visa' },
    ],
    priceCategories: [
      {
        dateLabel: 'HARGA PROMO 20 SEAT PERTAMA (KEBERANGKATAN 03 SEPTEMBER 2026)',
        prices: [
          { type: 'QUAD (Sekamar Berempat)', price: 'Rp 49.500.000' },
          { type: 'TRIPLE (Sekamar Bertiga)', price: 'Rp 53.500.000' },
          { type: 'DOUBLE (Sekamar Berdua)', price: 'Rp 58.500.000' }
        ]
      }
    ],
    itinerary: [
      {
        day: 'Day 01',
        title: '3 SEPT 2026: JAKARTA – MADINAH (GA 960: 14.25 - 20.50 WAS)',
        desc: 'Berkumpul di Lounge Bandara International Soekarno Hatta Terminal 3, 3 jam sebelum terbang. Penerbangan Jakarta menuju Madinah direct dengan Garuda Indonesia GA 960 (14.25 WIB - 20.50 WAS). Setibanya di Bandara Prince Mohammad bin Abdul Aziz Madinah, transfer bus menuju Hotel Madinah, check-in, makan malam & istirahat.'
      },
      {
        day: 'Day 02',
        title: '4 SEPT 2026: MADINAH (IBADAH MASJID NABAWI)',
        desc: 'Setelah sarapan pagi, acara bebas & memperbanyak ibadah di Masjid Nabawi. (Makan Pagi, Makan Siang & Makan Malam)'
      },
      {
        day: 'Day 03',
        title: '5 SEPT 2026: MADINAH – ZIARAH BAQI & RAUDHAH',
        desc: 'Sarapan pagi, acara bebas memperbanyak ibadah di Masjid Nabawi. Sore hari Ziarah Maqam Baqi di area Masjid Nabawi. Setelah Isya & makan malam, berziarah ke Makam Rasulullah SAW & Para Sahabat didampingi Mutawwif serta beribadah & berdoa di Raudhah Taman Surga (sesuai tasreh resmi). (Makan Pagi, Makan Siang & Makan Malam)'
      },
      {
        day: 'Day 04',
        title: '6 SEPT 2026: MADINAH – CITY TOUR',
        desc: 'Setelah sarapan pagi, Ziarah Kota Madinah: mengunjungi Jabal Uhud, Masjid Quba, dan Pasar Kurma. Kembali ke hotel & memperbanyak ibadah di Masjid Nabawi. (Makan Pagi, Makan Siang & Makan Malam)'
      },
      {
        day: 'Day 05',
        title: '7 SEPT 2026: MADINAH (IBADAH MASJID NABAWI)',
        desc: 'Setelah sarapan pagi, acara bebas & memperbanyak ibadah di Masjid Nabawi. (Makan Pagi, Makan Siang & Makan Malam)'
      },
      {
        day: 'Day 06',
        title: '8 SEPT 2026: MADINAH – KERETA CEPAT – MAKKAH (UMROH PERTAMA)',
        desc: 'Sarapan pagi, mandi sunnah ihram & persiapan check-out. Diantar ke Stasiun Kereta Cepat Haramain menuju Makkah (ambil miqot di perjalanan). Tiba di Makkah, menuju Hotel Makkah untuk simpan koper, makan malam, & bersama-sama melaksanakan IBADAH UMROH PERTAMA. (Makan Pagi, Meal Box Siang, Makan Malam)'
      },
      {
        day: 'Day 07',
        title: '9 SEPT 2026: MAKKAH (IBADAH MASJIDIL HARAM)',
        desc: 'Setelah sarapan pagi, memperbanyak ibadah di Masjidil Haram (Free Program). (Makan Pagi, Makan Siang & Makan Malam)'
      },
      {
        day: 'Day 08',
        title: '10 SEPT 2026: MAKKAH (IBADAH MASJIDIL HARAM)',
        desc: 'Setelah sarapan pagi, memperbanyak ibadah di Masjidil Haram (Free Program). (Makan Pagi, Makan Siang & Makan Malam)'
      },
      {
        day: 'Day 09',
        title: '11 SEPT 2026: MAKKAH – ZIARAH & MIQOT JI’RONAH (UMROH KEDUA)',
        desc: 'Sarapan pagi, Ziarah Kota Makkah: Padang Arafah, Jabal Rahmah, Muzdalifah, Mina, dan Jabal Tsur. Berakhir di Ji’ronah untuk mengambil miqot UMROH KEDUA (bagi yang tidak umroh kedua perbanyak ibadah di Masjidil Haram). (Makan Pagi, Makan Siang & Makan Malam)'
      },
      {
        day: 'Day 10',
        title: '12 SEPT 2026: MAKKAH (IBADAH MASJIDIL HARAM)',
        desc: 'Memperbanyak ibadah di Masjidil Haram (Free Program). (Makan Pagi, Makan Siang & Makan Malam)'
      },
      {
        day: 'Day 11',
        title: '13 SEPT 2026: MAKKAH – THAWAF WADA – JEDDAH – JAKARTA',
        desc: 'Setelah Sholat Subuh & Thawaf Wada’, check-out hotel. Bertolak menuju Jeddah untuk City Tour: Corniche, Masjid Qishash, & makan siang di Restoran. 4 jam sebelum terbang menuju Bandara Jeddah untuk penerbangan ke Jakarta (GA 981 18.40 WAS). (Makan Pagi, Makan Siang & Makan Malam)'
      },
      {
        day: 'Day 12',
        title: '14 SEPT 2026: JAKARTA',
        desc: 'InsyaAllah tiba di Bandara Soekarno Hatta Jakarta pukul 10.00 WIB (+1). Pengambilan bagasi & imigrasi. Berakhirlah perjalanan ibadah umroh membawa Umrah Maqbulah. Aamiin.'
      }
    ],
    inclusions: [
      { label: 'Tiket Pesawat PP Garuda Indonesia Direct Flight (CGK-MED / JED-CGK Boeing 777-300)', included: true },
      { label: 'Hotel Bintang 5 Pelataran Masjid: Maden Hotel Madinah & Sofwa Tower III Makkah (Fullboard)', included: true },
      { label: 'Visa Umroh + Transportasi Bus AC Pariwisata selama di Tanah Suci', included: true },
      { label: 'Kereta Cepat Haramain (Madinah ke Makkah)', included: true },
      { label: 'Mutawwif & Pendampingan Tour Leader dari Indonesia', included: true },
      { label: 'Modul Spiritual Journey & Leadership "The Winner" (Target Hafal Surah Al-Mulk)', included: true },
      { label: 'City Tour / Ziarah lengkap Madinah, Makkah & Jeddah (Corniche / Masjid Qishash)', included: true },
      { label: 'Lounge Bandara Terminal 3 Soekarno-Hatta', included: true },
      { label: 'Kuliner Khas Albaik', included: true },
      { label: 'Manasik Umroh H-1 di Jakarta', included: true },
      { label: 'Air Zamzam 5 Liter', included: true },
      { label: 'Asuransi Perjalanan', included: true },
      { label: 'Perlengkapan Umroh dan Handling Total Rp 1.500.000', included: false },
      { label: 'Biaya Pembuatan Paspor', included: false },
      { label: 'Perubahan Kebijakan dari Pemerintah Saudi/Indonesia yang berdampak kenaikan biaya', included: false }
    ],
    syaratKetentuan: [
      'Dengan membayar DP anda menyetujui yang menjadi persyaratan di Safaria.',
      'Usia 1–23 bulan estimasi harga 11,5 juta (tidak dapat perlengkapan dan air zamzam) harga valid setelah booking.',
      'Usia 2 tahun ke atas harga full. Kecuali tanpa bed ada potongan Rp. 1,5 jt / anak.',
      'Pembayaran: DP Minimal Sebesar Rp. 10.000.000,- (Book seat).',
      'Pembayaran: DP ke- 2 Sebesar 50% dari harga paket 45 hari sebelum berangkat.',
      'Pembayaran: Pelunasan dan Dokumen Terkumpul maximal 4 Minggu Sebelum Keberangkatan.',
      'Ketentuan Canceling Fee: Pembatalan Setelah melakukan Deposit dan Pembatalan dilakukan 45–30 Hari Sebelum tanggal Keberangkatan dikenakan Biaya Rp. 7.500.000 per tiket.',
      'Ketentuan Canceling Fee: Pembatalan Setelah melakukan Deposit dan Pembatalan dilakukan 30–14 Hari Sebelum tanggal Keberangkatan dikenakan biaya sebesar harga 1 tiket plus admin 10% dari harga tiket.',
      'Ketentuan Canceling Fee: Pembatalan Setelah melakukan Deposit dan Pembatalan dilakukan Kurang dari 14 Hari Sebelum Tanggal Keberangkatan dikenakan Biaya Pembatalan 100 % dari Biaya Paket.',
      'Dengan membayar DP anda sudah menyetujui syarat dan ketentuan yang ditetapkan diatas. Bismillah diberi kelancaran semua urusan, sehat sejahtera selalu menjadi Umroh Yang Mabrur, Aamiin.'
    ],
    remarks: [
      '5 Pasti Umroh: Izin, Tanggal Berangkat, Pesawat, Hotel, Visa.',
      'Biaya bayar setelah sampai tanah suci atau setelah pulang (S&K berlaku).',
      'Dokumen yang perlu disiapkan: Paspor asli (min 2 suku kata), Soft file KTP, Soft file KK, Soft file Akta Lahir (untuk anak-anak), Soft file Foto background putih 4x6 (2 lembar).',
      'Jadwal Raudhah Tentatif (Sesuai Jadwal Tasreh resmi dari Muasasah / pihak terkait).',
      'Harga sewaktu-waktu bisa berubah tergantung Kurs, Available Seat, Occupansi Hotel, Harga Visa, Dll.',
      'Program / Fasilitas / Harga Paket dapat berubah sewaktu-waktu dengan / tanpa mengurangi nilai ibadah.'
    ],
    mapCenter: [39.6142, 24.4672],
    mapZoom: 7,
    mapPins: [
      { lng: 39.6142, lat: 24.4672, label: 'Madinah Al-Munawwarah (Maden Hotel *5)' },
      { lng: 39.8262, lat: 21.4225, label: 'Makkah Al-Mukarramah (Sofwa Tower III *5)' },
      { lng: 39.1565, lat: 21.6796, label: 'Bandara King Abdulaziz Jeddah' }
    ]
  },

  'Chongqing Zhangjiajie 09 Hari / 06 Malam': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1529921879218-f99546d03a70?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'HIGHLIGHT: CIQIKOU ANCIENT TOWN – LIZIBA LIGHT RAIL (MENEMBUS APARTEMEN) – FENGHUANG PHOENIX TOWN – FURONG WATERFALL TOWN – TIANZISHAN AVATAR MOUNTAIN – GLASS BRIDGE GRAND CANYON – PIPA YUAN HOT POT',
    price: 'Rp 10.900.000',
    duration: '9 Hari 6 Malam',
    rating: 4.8,
    reviews: 140,
    maxPax: 25,
    ctaLabel: 'Pesan Paket Chongqing Zhangjiajie',
    maskapai: 'Xiamen Airlines (MF8674 CGK-CKG 23:20-06:20+1 / MF8673 CKG-CGK 00:05-05:20)',
    keberangkatan: 'May / Jun / Jul / Aug / Sep / Oct 2026',
    minPeserta: '20 Peserta (Didampingi 1 Tour Leader)',
    hotelInfoText: 'Hotel ★4/★5 Lokal: Qianjiang (Rose Plaza *5), Fenghuang (Fenghuang Int\'l *4), Zhangjiajie (Western Grand / Jingtian *4), Pengshui (Vienna Int\'l *4)',
    tipeKamarText: 'Twin Share / Triple Share | Single Supp +Rp 2.800.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Xiamen Airlines Direct Flight (MF8674 / MF8673)' },
      { icon: '🧳', text: 'Bagasi 23 kg + Cabin 5 kg' },
      { icon: '🚝', text: 'Liziba Light Rail (Pengalaman unik kereta menembus gedung apartemen)' },
      { icon: '🏰', text: 'Fenghuang Ancient Town (Phoenix Town) & Furong Ancient Town (Kota di atas air terjun)' },
      { icon: '🏔️', text: 'Zhangjiajie National Forest Park & Mount Tianzishan (Gunung Avatar via Bailong Elevator)' },
      { icon: '🌉', text: 'Glass Bridge at Zhangjiajie Grand Canyon' },
      { icon: '🍲', text: 'Makan Malam Spesial di PIPA YUAN HOT POT (Restoran Hotpot Terbesar di Dunia)' },
      { icon: '🏨', text: 'Menginap di Hotel ★5 Lokal Qianjiang & ★4 Fenghuang, Zhangjiajie, Pengshui' },
    ],
    priceCategories: [
      {
        dateLabel: 'MAY, JUN, JUL, AUG, SEP, OCT 2026 (SERIES LOW SEASON)',
        prices: [
          { type: 'Adult / Child Twin Share (May / Jun / Jul / Aug / Sep / Oct)', price: 'Rp 10.900.000' },
          { type: 'Child No Bed (< 6 Tahun)', price: 'Rp 9.265.000' },
          { type: 'Infant Flat Rate (< 23 Bulan)', price: 'Rp 3.815.000' },
          { type: 'Single Supplement (Kamar Sendiri)', price: '+Rp 2.800.000' }
        ]
      },
      {
        dateLabel: 'KEBERANGKATAN JUN (18, 19, 20, 30) & JUL (2, 3, 5)',
        prices: [
          { type: 'Adult / Child Twin Share', price: 'Rp 11.900.000' },
          { type: 'Child No Bed (< 6 Tahun)', price: 'Rp 10.115.000' },
          { type: 'Single Supplement', price: '+Rp 4.165.000' }
        ]
      },
      {
        dateLabel: 'KEBERANGKATAN JUN (21, 23, 25, 26, 27, 28)',
        prices: [
          { type: 'Adult / Child Twin Share', price: 'Rp 12.900.000' },
          { type: 'Child No Bed (< 6 Tahun)', price: 'Rp 10.965.000' },
          { type: 'Single Supplement', price: '+Rp 4.515.000' }
        ]
      }
    ],
    optionalActivities: [
      { name: 'Tianmen Mountain Scenic Area (Zhangjiajie City)', price: 'RMB 500 / pax' },
      { name: 'Tianmen Fox Fairy Show or Charming Xiangxi Show', price: 'RMB 400 / pax' }
    ],
    itinerary: [
      {
        day: 'Day 01',
        title: 'JAKARTA – CHONGQING (MF8674 CGK-CKG 23:20-06:20+1)',
        desc: 'Pada hari ini Anda berkumpul di Bandar Udara Soekarno Hatta untuk memulai perjalanan menuju Chongqing, China.'
      },
      {
        day: 'Day 02',
        title: 'CHONGQING – QIANJIANG (Makan Siang, Makan Malam)',
        desc: 'Setibanya di Chongqing, Anda akan mengunjungi Ciqikou Ancient Town dan merasakan sensasi menaiki Liziba Light Rail through The Building (kereta yang menembus gedung apartemen). Mengunjungi Great Hall of The People (simbol keajaiban masyarakat Chongqing). Perjalanan dilanjutkan menuju Qianjiang & mengunjungi Zhuoshui Ancient Town. Check-in hotel.'
      },
      {
        day: 'Day 03',
        title: 'QIANJIANG – FENGHUANG (Makan Pagi, Makan Siang)',
        desc: 'Mengunjungi Fenghuang (Phoenix Town). Menjelajahi Wanming Tower, Shawan Scenic Spot, Ancient Stone Slate Street & Bar Street. Malam hari acara bebas menikmati pemandangan malam kota tua Fenghuang yang memukau. Check-in hotel.'
      },
      {
        day: 'Day 04',
        title: 'FENGHUANG – YONGSHUN – ZHANGJIAJIE (Makan Pagi, Makan Siang)',
        desc: 'Mengunjungi Furong Ancient Town (Hibiscus Town) — kota tua berusia lebih dari 2000 tahun yang terletak di atas tebing & air terjun You River (lokasi syuting film "Hibiscus Town"). Dilanjutkan mengunjungi The 72 Tujia Stilted Buildings. Perjalanan ke Zhangjiajie & check-in hotel.'
      },
      {
        day: 'Day 05',
        title: 'ZHANGJIAJIE (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Acara bebas (free time) di Zhangjiajie atau dapat mengikuti Optional Tour (Tianmen Mountain Scenic Area RMB 500 / Fox Fairy Show RMB 400). Mengunjungi Herbal Medicine Shop & Junsheng Art Academy (galeri lukisan pasir yang terkenal). Check-in hotel.'
      },
      {
        day: 'Day 06',
        title: 'ZHANGJIAJIE (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Mengunjungi Zhangjiajie National Forest Park. Menaiki Bailong Elevator (lift tertinggi di gunung di dunia) ke Puncak Gunung Tianzishan (Gunung Avatar). Mengunjungi Golden Whip Brook & menikmati Tea Ceremony di Tea House. Check-in hotel.'
      },
      {
        day: 'Day 07',
        title: 'ZHANGJIAJIE – PENGSHUI (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Mengunjungi Jewelry Shop dan Latex Shop. Perjalanan ke The Grand Canyon di Kabupaten Cili & menyeberangi Glass Bridge yang sangat terkenal di Zhangjiajie. Perjalanan dilanjutkan ke Pengshui & check-in hotel.'
      },
      {
        day: 'Day 08',
        title: 'PENGSHUI – CHONGQING (Makan Pagi, Makan Malam Hotpot)',
        desc: 'Kembali ke Chongqing. Mengunjungi Bayi Road Food Street & pemandangan malam Hongya Cave (Hongya Gate). Mengunjungi Kuixing Building (masuk lantai 1 namun terdapat 22 lantai di bawahnya) & Liberation Monument Walking Street. Makan malam spesial di PIPA YUAN HOT POT (Restoran Hot Pot Terbesar di Dunia). Diantar ke bandara untuk penerbangan kembali ke Jakarta.'
      },
      {
        day: 'Day 09',
        title: 'CHONGQING – JAKARTA (MF8673 CKG-CGK 00:05 - 05:20)',
        desc: 'Penerbangan kembali ke Jakarta dengan Xiamen Airlines (MF8673). Tiba di Bandara Soekarno Hatta Jakarta dengan membawa sejuta kenangan manis. Terima kasih atas partisipasi Anda!'
      }
    ],
    inclusions: [
      { label: 'Tiket International group by Xiamen Airlines (Economy Class, Fix Date, Fix Flight, No Refund, No Reroute, No Reschedule)', included: true },
      { label: 'Bagasi 1 Piece 23KG + Cabin 5KG', included: true },
      { label: 'Akomodasi di hotel 4★ / 5★ berdasarkan 1 kamar berdua/bertiga (Twin/Triple Share)', included: true },
      { label: 'Transportasi Bus AC & biaya kunjungan objek wisata sesuai program', included: true },
      { label: 'Tour Leader dari Jakarta yang menemani selama tour', included: true },
      { label: 'Asuransi Perjalanan Standard group (mengcover peserta berusia 83 tahun ke bawah)', included: true },
      { label: 'Fuel Surcharge / Airport Tax sebesar IDR 3.233.000', included: false },
      { label: 'Visa Group China IDR 980.000 (Wajib Visa Group; holding visa surcharge IDR 485.280/pax)', included: false },
      { label: 'Tipping Tour Leader, Guide dan Driver IDR 865.000', included: false },
      { label: 'Pembuatan passport dan dokumen lainnya', included: false },
      { label: 'Pengeluaran pribadi & Optional Tour (Tianmen Mountain RMB 500 / Fox Fairy Show RMB 400)', included: false },
      { label: 'PPN 1,1%', included: false }
    ],
    syaratKetentuan: [
      'Harga Airport tax & Fuel Surcharge (IDR 3.233.000) dapat berubah sewaktu-waktu dengan atau tanpa pemberitahuan terlebih dahulu.',
      'Uang muka sebesar Rp 6.000.000 / orang pada saat pendaftaran dan tidak dapat dikembalikan (non-refundable) bila terjadi pembatalan oleh peserta.',
      'Pelunasan paling lambat 30 (tiga puluh) hari sebelum tanggal keberangkatan.',
      'Syarat Visa Group China (IDR 980.000): Scan Paspor Berwarna Hal 2 & 3 full (min 6 bulan dari kepulangan) & Softcopy Pasfoto 3,3x4,8 latar putih, zoom 70%, baju tua (bukan putih/abu-abu), dahi & telinga wajib terlihat.',
      'GROUP INCENTIVE AKAN DIKENAKAN SURCHARGE Rp 1.011.000/PAX. Group incentive yang mengaku series (tidak jujur) akan di-surcharge Rp 2.000.000/pax on the spot.',
      'Akomodasi Hotel: Qianjiang (Local 5★ Rose Plaza), Fenghuang (Local 4★ Fenghuang Int\'l), Zhangjiajie (Local 4★ Western Grand / Jingtian Shengshi), Pengshui (Local 4★ Vienna Int\'l Plaza).',
      'Optional Tour: Tianmen Mountain Scenic Area (RMB 500/pax) & Tianmen Fox Fairy / Charming Xiangxi Show (RMB 400/pax).',
      'Pembatalan 30–15 hari sebelum keberangkatan: 75% dari biaya tour.',
      'Pembatalan 14–00 hari sebelum keberangkatan: 100% dari biaya tour.',
      'Force Majeur (bencana alam, gangguan sarana transportasi, dll) bersifat non-refundable.'
    ],
    remarks: [
      '4 Mandatory Shops: Herbal Medicine, Jewelry Shop, Tea House, Latex.',
      'Syarat dokumen Visa Group: Scan paspor berwarna (hal 2-3 full, min 6 bln aktif) & Softcopy foto 3.3x4.8 latar putih, zoom 70%, baju tua, dahi & telinga wajib terlihat.',
      'Holding Visa Surcharge IDR 485.280/pax jika diarahkan holding visa.',
      'Susunan acara tour dapat berubah sewaktu-waktu tergantung kondisi di lapangan tanpa mengurangi objek wisata.'
    ],
    mapCenter: [110.4792, 29.1171],
    mapZoom: 7,
    mapPins: [
      { lng: 106.5516, lat: 29.5630, label: 'Chongqing (Liziba Rail & Hongya Cave)' },
      { lng: 109.5990, lat: 27.9490, label: 'Fenghuang Ancient Town' },
      { lng: 110.4792, lat: 29.1171, label: 'Zhangjiajie (National Forest Park & Glass Bridge)' }
    ]
  },

  'Autumn in Japan 07 Hari / 05 Malam': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'HIGHLIGHT: SENSOJI TEMPLE – NAKAMISE SHOPPING – TOKYO SKYTREE – SHIBUYA CROSSING – KAMIKOCHI JAPANESE ALPS – MT. FUJI & LAKE KAWAGUCHI – OSHINO HAKKAI UNESCO VILLAGE – GOTEMBA PREMIUM OUTLET',
    price: 'Rp 24.500.000',
    duration: '7 Hari 5 Malam',
    rating: 4.9,
    reviews: 165,
    maxPax: 20,
    ctaLabel: 'Pesan Paket Autumn in Japan',
    maskapai: 'Air China (International Group Economy Class, Fixed Date, Non Refund)',
    keberangkatan: '17 Sep 2026',
    minPeserta: '20 Peserta (Didampingi 1 Tour Leader)',
    hotelInfoText: 'Hotel ★3 Local / Similar (Twin Share)',
    tipeKamarText: 'Twin Share | Single Supplement +Rp 5.500.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Air China International Group Economy Class (Fixed Date)' },
      { icon: '🧳', text: 'Bagasi sesuai ketentuan penerbangan Air China' },
      { icon: '🏯', text: 'Asakusa Sensoji Temple (Kuil Buddha tertua di Tokyo sejak tahun 654 AD)' },
      { icon: '🗼', text: 'Tokyo Skytree (Menara 634m), Nakamise Shopping Street & Shibuya Crossing' },
      { icon: '🍁', text: 'Kamikochi — Lembah pegunungan cantik di Japanese Alps dengan sungai bening kristal' },
      { icon: '🏔️', text: 'Mount Fuji, Lake Kawaguchiko (Fuji Five Lakes) & Oshino Hakkai (Desa UNESCO)' },
      { icon: '🛍️', text: 'Gotemba Premium Outlets — Belanja brand internasional & lokal Tiongkok/Jepang' },
      { icon: '🏨', text: 'Akomodasi Hotel ★3 & Transportasi Private Bus AC' },
    ],
    priceCategories: [
      {
        dateLabel: 'KEBERANGKATAN 17 SEPTEMBER 2026 (EARLY BIRD DISCOUNT RP 2.000.000/PAX HINGGA 31 MEI)',
        prices: [
          { type: 'Adult / Child Twin Share (Harga Early Bird)', price: 'Rp 24.500.000 (Harga Normal Rp 26.500.000)' },
          { type: 'Child No Bed (< 6 Tahun) (Harga Early Bird)', price: 'Rp 24.100.000 (Harga Normal Rp 26.100.000)' },
          { type: 'Single Supplement (Sekamar Sendiri)', price: '+Rp 5.500.000' }
        ]
      }
    ],
    itinerary: [
      {
        day: 'Day 01',
        title: 'JAKARTA – NARITA',
        desc: 'Pada waktu yang telah ditentukan, semua peserta diminta berkumpul di Bandara Soekarno Hatta untuk melakukan penerbangan menuju Narita, Jepang dengan Air China.'
      },
      {
        day: 'Day 02',
        title: 'ARRIVAL NARITA – TOKYO',
        desc: 'Setibanya di Narita, menuju Asakusa (distrik bersejarah Tokyo) dengan private bus. Mengunjungi Asakusa Sensoji Temple (kuil Buddha tertua di Tokyo sejak tahun 654 AD). Berbelanja di Nakamise Shopping Street & photo stop di Tokyo Skytree (menara setinggi 634 meter). Diakhiri dengan mengunjungi Shibuya Crossing (persimpangan tersibuk di dunia). Check-in hotel.'
      },
      {
        day: 'Day 03',
        title: 'TOKYO (B/-/-)',
        desc: 'Setelah sarapan, Anda mendapatkan free time seharian penuh untuk menikmati keindahan & keseruan di kota Tokyo (tanpa bus dan guide).'
      },
      {
        day: 'Day 04',
        title: 'TOKYO – KAMIKOCHI – SUWA (B/-/D)',
        desc: 'Perjalanan menuju Kamikochi di kawasan Japanese Alps menggunakan private bus. Jalan-jalan menikmati keindahan Kamikochi — lembah pegunungan spektakuler dengan sungai sebening kristal & hutan asri. Perjalanan dilanjutkan menuju Suwa, makan malam & check-in hotel.'
      },
      {
        day: 'Day 05',
        title: 'SUWA – MT. FUJI (B/-/D)',
        desc: 'Menuju Gunung Fuji — simbol ikonik negara Jepang. Mengunjungi Lake Kawaguchiko (danau tercantik memantulkan panorama Gunung Fuji). Mengunjungi Oshino Hakkai — desa tradisional Tiongkok/Jepang UNESCO "Japan\'s Fairytale Village" dengan 8 kolam air jernih lelehan salju Gunung Fuji. Check-in hotel.'
      },
      {
        day: 'Day 06',
        title: 'MT. FUJI – GOTEMBA – NARITA (B/-/-)',
        desc: 'Pagi hari berbelanja di Gotemba Premium Outlets — salah satu outlet terbesar di Jepang dengan ratusan brand internasional & lokal. Perjalanan dilanjutkan menuju Narita untuk check-in hotel & beristirahat.'
      },
      {
        day: 'Day 07',
        title: 'NARITA – JAKARTA (B)',
        desc: 'Setelah sarapan, diantar menuju Bandara Narita untuk penerbangan kembali menuju Jakarta dengan Air China. Tiba di Jakarta, berakhirlah acara tour dengan membawa kenangan manis. Terima kasih!'
      }
    ],
    inclusions: [
      { label: 'Tiket International group Air China (Economy Class, Fixed Date, Non Refund)', included: true },
      { label: 'Bagasi sesuai dengan peraturan penerbangan Air China', included: true },
      { label: 'Akomodasi di hotel 3 star berdasarkan 1 kamar berdua (Twin Share)', included: true },
      { label: 'Transportasi Bus AC & biaya kunjungan objek wisata sesuai itinerary', included: true },
      { label: 'Tour Leader dari Jakarta yang menemani selama tour', included: true },
      { label: 'International Airport Tax', included: true },
      { label: 'Asuransi Perjalanan Standard group (hanya mengcover peserta berusia 69 tahun ke bawah)', included: true },
      { label: 'Fuel Surcharge / Airport Tax IDR 1.000.000 (dapat berubah sewaktu-waktu)', included: false },
      { label: 'Visa Waiver Japan IDR 400.000 // Visa Japan Single Entry IDR 830.000', included: false },
      { label: 'Tipping Tour Leader, Guide dan Driver IDR 750.000', included: false },
      { label: 'Pembuatan paspor dan dokumen lainnya', included: false },
      { label: 'Pengeluaran pribadi', included: false },
      { label: 'Optional tour', included: false },
      { label: 'PPN 1,1%', included: false }
    ],
    syaratKetentuan: [
      'EARLY BIRD DISCOUNT IDR 2.000.000/PAX UNTUK BOOKING SAMPAI 31 MEI.',
      'Harga Airport tax & Fuel Surcharge, biaya visa serta asuransi dapat berubah sewaktu-waktu tanpa pemberitahuan.',
      'Uang muka sebesar Rp 11.000.000 / orang pada saat pendaftaran dan tidak dapat dikembalikan (non-refundable).',
      'Pelunasan paling lambat 30 (tiga puluh) hari sebelum tanggal keberangkatan.',
      'Dalam hal aplikasi visa, peserta bersedia memenuhi syarat dokumen; biaya visa tetap harus dilunasi walaupun visa tidak disetujui.',
      'Group akan diberangkatkan apabila mencapai jumlah minimum peserta.',
      'Apabila hotel yang ditawarkan penuh, akan diganti dengan hotel lain yang setaraf.',
      'Pembatalan 30–15 hari sebelum keberangkatan: 75% dari biaya tour.',
      'Pembatalan 14–00 hari sebelum keberangkatan: 100% dari biaya tour.',
      'Force Majeur (bencana alam, kerusakan, keterlambatan sarana transportasi, dll) bersifat non-refundable.'
    ],
    remarks: [
      'EARLY BIRD DISCOUNT IDR 2.000.000/PAX FOR BOOKING UNTIL 31 MAY.',
      'Visa Waiver Japan IDR 400.000 / Visa Japan Single Entry IDR 830.000.',
      'Susunan acara tour dapat berubah sewaktu-waktu tanpa mengurangi objek tour, tergantung kondisi di lapangan.'
    ],
    mapCenter: [139.6917, 35.6895],
    mapZoom: 7,
    mapPins: [
      { lng: 139.7967, lat: 35.7148, label: 'Tokyo (Asakusa Sensoji & Skytree)' },
      { lng: 137.6378, lat: 36.2494, label: 'Kamikochi (Japanese Alps)' },
      { lng: 138.7274, lat: 35.3606, label: 'Mount Fuji & Lake Kawaguchiko' }
    ]
  },

  'Inner Mongolia by Singapore Airlines 08 Hari / 05 Malam': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1529921879218-f99546d03a70?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'HIGHLIGHT: HANGING TEMPLE – XILAMUREN GRASSLAND WINE CEREMONY – WHISTLING DUNE BAY CABLE CAR – KANGBASHI KOTA HANTU – DAZHAO TEMPLE – YUNGANG GROTTOES',
    price: 'Rp 16.980.000',
    duration: '8 Hari 5 Malam',
    rating: 4.8,
    reviews: 145,
    maxPax: 20,
    ctaLabel: 'Pesan Paket Inner Mongolia',
    maskapai: 'Singapore Airlines (Economy Class, CGK-SIN-PEK PP)',
    keberangkatan: 'May - Sep 2026',
    minPeserta: '20 Peserta (Didampingi 1 Tour Leader)',
    hotelInfoText: 'Hotel ★4 Local / Similar: Datong, Xilamuren Grassland, Whistling Dune Bay & Hohhot',
    tipeKamarText: 'Twin / Triple / Extra Bed | Single Supp +Rp 3.500.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Singapore Airlines (Economy Class via Singapore)' },
      { icon: '🧳', text: 'Bagasi 20 kg + Cabin 5 kg' },
      { icon: '🏯', text: 'Hanging Temple Datong (Kuil unik yang dibangun menggantung di tebing tebing 75m)' },
      { icon: '🌾', text: 'Xilamuren Grassland (Penyambutan Wine Ceremony, Khatag & Kuliner Kambing khas Mongolia)' },
      { icon: '🐪', text: 'Whistling Dune Bay (Pasir Bernyanyi include Round Trip Cable Car)' },
      { icon: '🏛️', text: 'Kangbashi New Area "Kota Hantu" & Genghis Khan Statue Square' },
      { icon: '🕌', text: 'Dazhao Temple (Kuil Buddha Tibet tertua di Hohhot) & Yungang Grottoes UNESCO' },
      { icon: '🏨', text: 'Menginap di Hotel ★4 Lokal Datong, Grassland, Dune Bay & Hohhot' },
    ],
    priceCategories: [
      {
        dateLabel: 'KEBERANGKATAN 06 MEI 2026 (PROMO SPECIAL MAY)',
        prices: [
          { type: 'Adult / Child Twin Share / Extra Bed', price: 'Rp 15.980.000' },
          { type: 'Child No Bed (< 6 Tahun)', price: 'Rp 14.980.000' },
          { type: 'Single Supplement (Sekamar Sendiri)', price: '+Rp 3.500.000' }
        ]
      },
      {
        dateLabel: 'KEBERANGKATAN MAY (16), JUN (27), JUL (18, 26), AUG (02, 15, 22), SEP (05) 2026',
        prices: [
          { type: 'Adult / Child Twin Share / Extra Bed', price: 'Rp 16.980.000' },
          { type: 'Child No Bed (< 6 Tahun)', price: 'Rp 15.980.000' },
          { type: 'Single Supplement (Sekamar Sendiri)', price: '+Rp 3.500.000' }
        ]
      }
    ],
    optionalActivities: [
      { name: 'Xilamuren Grassland - Horse Riding (2 Scenic Spots)', price: 'RMB 380 / pax' },
      { name: 'Whistling Dune Bay - Xiansha Island', price: 'RMB 280 / pax' },
      { name: 'Whistling Dune Bay - Uensha Island', price: 'RMB 280 / pax' },
      { name: 'Whistling Dune Bay - Siled', price: 'RMB 20 / pax' },
      { name: 'Hong Geer Aobao Show', price: 'RMB 280 / pax' },
      { name: 'Zhama Feast', price: 'RMB 398 / pax' }
    ],
    itinerary: [
      {
        day: 'Day 01',
        title: 'JAKARTA - SINGAPORE',
        desc: 'Pada waktu yang ditentukan, Anda berkumpul di Bandara Soekarno Hatta untuk terbang menuju China transit di Singapore dengan Singapore Airlines.'
      },
      {
        day: 'Day 02',
        title: 'SINGAPORE - BEIJING - DATONG (Makan Siang, Makan Malam)',
        desc: 'Penerbangan menuju Beijing. Setibanya dengan bus diantar ke kota Datong. Mengunjungi Hanging Temple (exclude climbing) — kuil Buddha/Tao unik yang dibangun menggantung di tebing 75m di atas tanah. Bermalam di Datong.'
      },
      {
        day: 'Day 03',
        title: 'DATONG - XILAMUREN GRASSLAND (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Mengunjungi Xilamuren Grassland (padang rumput Mongolia). Disambut dengan penyambutan tradisional Wine Ceremony, dikalungkan selendang Khatag khas Mongolia, dan mencicipi daging kambing khas Mongolia. Bermalam di Xilamuren Grassland.'
      },
      {
        day: 'Day 04',
        title: 'XILAMUREN - WHISTLING DUNE BAY - ORDOS (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Menuju Whistling Dune Bay (termasuk round trip cable car) yang terkenal dengan fenomena "pasir bernyanyi" (gerakan pasir menghasilkan deru suara indah bak simfoni/guntur). Lanjut menuju Ordos untuk bermalam.'
      },
      {
        day: 'Day 05',
        title: 'ORDOS - HOHHOT (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'City tour Ordos: Ordos Cultural Industrial Park (termasuk battery car) — basis film/TV peradaban Dinasti Yuan. Kangbashi New Area "Kota Hantu" & photo stop Genghis Khan Statue Square. Lanjut menuju Hohhot untuk bermalam.'
      },
      {
        day: 'Day 06',
        title: 'HOHHOT – DATONG (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Mengunjungi Mongolian Nationalistic Style Garden yang cantik & Dazhao Temple (kuil Buddha Tibet tertua & terbesar di Hohhot). Lanjut ke Datong Ancient City & Saishang Old Street untuk acara bebas berbelanja. Bermalam di Datong.'
      },
      {
        day: 'Day 07',
        title: 'DATONG – BEIJING AIRPORT (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Mengunjungi Yungang Grottoes (termasuk battery car) — satu dari tiga kompleks gua terpenting di China. Kembali ke Beijing & diantar ke bandara untuk penerbangan ke Jakarta via Singapore.'
      },
      {
        day: 'Day 08',
        title: 'BEIJING – SINGAPORE - JAKARTA',
        desc: 'Penerbangan kembali dan tiba di Jakarta dengan membawa sejuta kenangan manis bersama Singapore Airlines. Terima kasih atas partisipasi Anda!'
      }
    ],
    inclusions: [
      { label: 'Tiket pesawat PP Singapore Airlines kelas ekonomi (non-endorsable, non-refundable & non-reroutable)', included: true },
      { label: 'Airport tax International, fuel surcharge, dan tax lainnya', included: true },
      { label: 'Penginapan di hotel 4★ lokal / setaraf berdasarkan 2 orang dalam 1 kamar (twin sharing)', included: true },
      { label: 'Acara tour, transportasi Bus AC dan makan sesuai itinerary (MP, MS, MM)', included: true },
      { label: 'Bagasi 20 kg + Cabin 5 kg', included: true },
      { label: 'Air Mineral 1 botol per orang per hari', included: true },
      { label: 'Asuransi perjalanan Group (maksimal usia 69 tahun)', included: true },
      { label: 'Tour Leader dari Indonesia', included: true },
      { label: 'Biaya dokumen perjalanan (paspor, entry permit, dll.)', included: false },
      { label: 'Pengeluaran pribadi (telepon, room service, laundry, mini bar, dll.)', included: false },
      { label: 'Excess baggage (kelebihan bagasi >20 kg) & bea masuk imigrasi', included: false },
      { label: 'Single Supplement (+Rp 3.500.000)', included: false },
      { label: 'Visa China Rp 960.450 / orang (Single Entry, Proses Normal)', included: false },
      { label: 'Tips Tour Leader, Lokal Guide & Driver IDR 800.000 / pax', included: false },
      { label: 'Optional Tour (Horse Riding RMB 380, Dune Bay Islands RMB 280, Aobao Show RMB 280, Zhama Feast RMB 398)', included: false },
      { label: 'PPN 1,1%', included: false }
    ],
    syaratKetentuan: [
      'Harga Airport tax & Fuel Surcharge dapat berubah sewaktu-waktu dengan atau tanpa pemberitahuan terlebih dahulu.',
      'Uang muka sebesar Rp 8.000.000 / orang pada saat pendaftaran dan tidak dapat dikembalikan (non-refundable).',
      'Pelunasan paling lambat 30 (tiga puluh) hari sebelum tanggal keberangkatan.',
      'Syarat Visa China (Rp 960.450): Peserta wajib memenuhi kelengkapan dokumen sesuai ketentuan Kedutaan; biaya visa tidak dapat dikembalikan jika visa ditolak.',
      'Group akan diberangkatkan apabila mencapai jumlah minimum 20 peserta.',
      'Akomodasi Hotel 4★ Lokal: Datong, Xilamuren Grassland, Whistling Dune Bay & Hohhot.',
      'Pembatalan 30–15 hari sebelum keberangkatan: 75% dari biaya tour.',
      'Pembatalan 14–00 hari sebelum keberangkatan: 100% dari biaya tour.',
      'Force Majeur (bencana alam, keterlambatan sarana transportasi, dll) bersifat non-refundable.'
    ],
    remarks: [
      'Acara perjalanan, Harga Tour / Visa / Apt Tax & YQ serta flight detail dapat berubah sewaktu-waktu tanpa pemberitahuan lebih lanjut.',
      'Optional Tour: Xilamuren Horse Riding (RMB 380/pax), Whistling Dune Bay Islands (RMB 280/pax), Hong Geer Aobao Show (RMB 280/pax), Zhama Feast (RMB 398/pax).'
    ],
    mapCenter: [111.7492, 40.8425],
    mapZoom: 7,
    mapPins: [
      { lng: 113.3001, lat: 40.0768, label: 'Datong (Hanging Temple & Yungang Grottoes)' },
      { lng: 111.2333, lat: 41.3500, label: 'Xilamuren Grassland' },
      { lng: 109.9833, lat: 39.8167, label: 'Ordos & Whistling Dune Bay' },
      { lng: 111.7492, lat: 40.8425, label: 'Hohhot (Dazhao Temple)' }
    ]
  },
  'Inner Mongolia': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1529921879218-f99546d03a70?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'HIGHLIGHT: HANGING TEMPLE – XILAMUREN GRASSLAND WINE CEREMONY – WHISTLING DUNE BAY CABLE CAR – KANGBASHI KOTA HANTU – DAZHAO TEMPLE – YUNGANG GROTTOES',
    price: 'Rp 16.980.000',
    duration: '8 Hari 5 Malam',
    rating: 4.8,
    reviews: 145,
    maxPax: 20,
    ctaLabel: 'Pesan Paket Inner Mongolia',
    maskapai: 'Singapore Airlines (Economy Class, CGK-SIN-PEK PP)',
    keberangkatan: 'May - Sep 2026',
    minPeserta: '20 Peserta (Didampingi 1 Tour Leader)',
    hotelInfoText: 'Hotel ★4 Local / Similar: Datong, Xilamuren Grassland, Whistling Dune Bay & Hohhot',
    tipeKamarText: 'Twin / Triple / Extra Bed | Single Supp +Rp 3.500.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Singapore Airlines (Economy Class via Singapore)' },
      { icon: '🧳', text: 'Bagasi 20 kg + Cabin 5 kg' },
      { icon: '🏯', text: 'Hanging Temple Datong (Kuil unik yang dibangun menggantung di tebing tebing 75m)' },
      { icon: '🌾', text: 'Xilamuren Grassland (Penyambutan Wine Ceremony, Khatag & Kuliner Kambing khas Mongolia)' },
      { icon: '🐪', text: 'Whistling Dune Bay (Pasir Bernyanyi include Round Trip Cable Car)' },
      { icon: '🏛️', text: 'Kangbashi New Area "Kota Hantu" & Genghis Khan Statue Square' },
      { icon: '🕌', text: 'Dazhao Temple (Kuil Buddha Tibet tertua di Hohhot) & Yungang Grottoes UNESCO' },
      { icon: '🏨', text: 'Menginap di Hotel ★4 Lokal Datong, Grassland, Dune Bay & Hohhot' },
    ],
    priceCategories: [
      {
        dateLabel: 'KEBERANGKATAN 06 MEI 2026 (PROMO SPECIAL MAY)',
        prices: [
          { type: 'Adult / Child Twin Share / Extra Bed', price: 'Rp 15.980.000' },
          { type: 'Child No Bed (< 6 Tahun)', price: 'Rp 14.980.000' },
          { type: 'Single Supplement (Sekamar Sendiri)', price: '+Rp 3.500.000' }
        ]
      },
      {
        dateLabel: 'KEBERANGKATAN MAY (16), JUN (27), JUL (18, 26), AUG (02, 15, 22), SEP (05) 2026',
        prices: [
          { type: 'Adult / Child Twin Share / Extra Bed', price: 'Rp 16.980.000' },
          { type: 'Child No Bed (< 6 Tahun)', price: 'Rp 15.980.000' },
          { type: 'Single Supplement (Sekamar Sendiri)', price: '+Rp 3.500.000' }
        ]
      }
    ],
    optionalActivities: [
      { name: 'Xilamuren Grassland - Horse Riding (2 Scenic Spots)', price: 'RMB 380 / pax' },
      { name: 'Whistling Dune Bay - Xiansha Island', price: 'RMB 280 / pax' },
      { name: 'Whistling Dune Bay - Uensha Island', price: 'RMB 280 / pax' },
      { name: 'Whistling Dune Bay - Siled', price: 'RMB 20 / pax' },
      { name: 'Hong Geer Aobao Show', price: 'RMB 280 / pax' },
      { name: 'Zhama Feast', price: 'RMB 398 / pax' }
    ],
    itinerary: [
      {
        day: 'Day 01',
        title: 'JAKARTA - SINGAPORE',
        desc: 'Pada waktu yang ditentukan, Anda berkumpul di Bandara Soekarno Hatta untuk terbang menuju China transit di Singapore dengan Singapore Airlines.'
      },
      {
        day: 'Day 02',
        title: 'SINGAPORE - BEIJING - DATONG (Makan Siang, Makan Malam)',
        desc: 'Penerbangan menuju Beijing. Setibanya dengan bus diantar ke kota Datong. Mengunjungi Hanging Temple (exclude climbing) — kuil Buddha/Tao unik yang dibangun menggantung di tebing 75m di atas tanah. Bermalam di Datong.'
      },
      {
        day: 'Day 03',
        title: 'DATONG - XILAMUREN GRASSLAND (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Mengunjungi Xilamuren Grassland (padang rumput Mongolia). Disambut dengan penyambutan tradisional Wine Ceremony, dikalungkan selendang Khatag khas Mongolia, dan mencicipi daging kambing khas Mongolia. Bermalam di Xilamuren Grassland.'
      },
      {
        day: 'Day 04',
        title: 'XILAMUREN - WHISTLING DUNE BAY - ORDOS (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Menuju Whistling Dune Bay (termasuk round trip cable car) yang terkenal dengan fenomena "pasir bernyanyi" (gerakan pasir menghasilkan deru suara indah bak simfoni/guntur). Lanjut menuju Ordos untuk bermalam.'
      },
      {
        day: 'Day 05',
        title: 'ORDOS - HOHHOT (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'City tour Ordos: Ordos Cultural Industrial Park (termasuk battery car) — basis film/TV peradaban Dinasti Yuan. Kangbashi New Area "Kota Hantu" & photo stop Genghis Khan Statue Square. Lanjut menuju Hohhot untuk bermalam.'
      },
      {
        day: 'Day 06',
        title: 'HOHHOT – DATONG (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Mengunjungi Mongolian Nationalistic Style Garden yang cantik & Dazhao Temple (kuil Buddha Tibet tertua & terbesar di Hohhot). Lanjut ke Datong Ancient City & Saishang Old Street untuk acara bebas berbelanja. Bermalam di Datong.'
      },
      {
        day: 'Day 07',
        title: 'DATONG – BEIJING AIRPORT (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Mengunjungi Yungang Grottoes (termasuk battery car) — satu dari tiga kompleks gua terpenting di China. Kembali ke Beijing & diantar ke bandara untuk penerbangan ke Jakarta via Singapore.'
      },
      {
        day: 'Day 08',
        title: 'BEIJING – SINGAPORE - JAKARTA',
        desc: 'Penerbangan kembali dan tiba di Jakarta dengan membawa sejuta kenangan manis bersama Singapore Airlines. Terima kasih atas partisipasi Anda!'
      }
    ],
    inclusions: [
      { label: 'Tiket pesawat PP Singapore Airlines kelas ekonomi (non-endorsable, non-refundable & non-reroutable)', included: true },
      { label: 'Airport tax International, fuel surcharge, dan tax lainnya', included: true },
      { label: 'Penginapan di hotel 4★ lokal / setaraf berdasarkan 2 orang dalam 1 kamar (twin sharing)', included: true },
      { label: 'Acara tour, transportasi Bus AC dan makan sesuai itinerary (MP, MS, MM)', included: true },
      { label: 'Bagasi 20 kg + Cabin 5 kg', included: true },
      { label: 'Air Mineral 1 botol per orang per hari', included: true },
      { label: 'Asuransi perjalanan Group (maksimal usia 69 tahun)', included: true },
      { label: 'Tour Leader dari Indonesia', included: true },
      { label: 'Biaya dokumen perjalanan (paspor, entry permit, dll.)', included: false },
      { label: 'Pengeluaran pribadi (telepon, room service, laundry, mini bar, dll.)', included: false },
      { label: 'Excess baggage (kelebihan bagasi >20 kg) & bea masuk imigrasi', included: false },
      { label: 'Single Supplement (+Rp 3.500.000)', included: false },
      { label: 'Visa China Rp 960.450 / orang (Single Entry, Proses Normal)', included: false },
      { label: 'Tips Tour Leader, Lokal Guide & Driver IDR 800.000 / pax', included: false },
      { label: 'Optional Tour (Horse Riding RMB 380, Dune Bay Islands RMB 280, Aobao Show RMB 280, Zhama Feast RMB 398)', included: false },
      { label: 'PPN 1,1%', included: false }
    ],
    syaratKetentuan: [
      'Harga Airport tax & Fuel Surcharge dapat berubah sewaktu-waktu dengan atau tanpa pemberitahuan terlebih dahulu.',
      'Uang muka sebesar Rp 8.000.000 / orang pada saat pendaftaran dan tidak dapat dikembalikan (non-refundable).',
      'Pelunasan paling lambat 30 (tiga puluh) hari sebelum tanggal keberangkatan.',
      'Syarat Visa China (Rp 960.450): Peserta wajib memenuhi kelengkapan dokumen sesuai ketentuan Kedutaan; biaya visa tidak dapat dikembalikan jika visa ditolak.',
      'Group akan diberangkatkan apabila mencapai jumlah minimum 20 peserta.',
      'Akomodasi Hotel 4★ Lokal: Datong, Xilamuren Grassland, Whistling Dune Bay & Hohhot.',
      'Pembatalan 30–15 hari sebelum keberangkatan: 75% dari biaya tour.',
      'Pembatalan 14–00 hari sebelum keberangkatan: 100% dari biaya tour.',
      'Force Majeur (bencana alam, keterlambatan sarana transportasi, dll) bersifat non-refundable.'
    ],
    remarks: [
      'Acara perjalanan, Harga Tour / Visa / Apt Tax & YQ serta flight detail dapat berubah sewaktu-waktu tanpa pemberitahuan lebih lanjut.',
      'Optional Tour: Xilamuren Horse Riding (RMB 380/pax), Whistling Dune Bay Islands (RMB 280/pax), Hong Geer Aobao Show (RMB 280/pax), Zhama Feast (RMB 398/pax).'
    ],
    mapCenter: [111.7492, 40.8425],
    mapZoom: 7,
    mapPins: [
      { lng: 113.3001, lat: 40.0768, label: 'Datong (Hanging Temple & Yungang Grottoes)' },
      { lng: 111.2333, lat: 41.3500, label: 'Xilamuren Grassland' },
      { lng: 109.9833, lat: 39.8167, label: 'Ordos & Whistling Dune Bay' },
      { lng: 111.7492, lat: 40.8425, label: 'Hohhot (Dazhao Temple)' }
    ]
  },

  'Danang Hanoi Sapa Halong Bay 07 Hari / 06 Malam': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1509099836639-18ba1795216d?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'HIGHLIGHT: BA NA HILLS CABLE CAR – GOLDEN BRIDGE – HOI AN ANCIENT TOWN – DRAGON & LOVE BRIDGE DANANG – CAT CAT VILLAGE SAPA – FANSIPAN MOUNTAIN CABLE CAR – HALONG BAY CRUISE',
    price: 'Rp 16.900.000',
    duration: '7 Hari 6 Malam',
    rating: 4.8,
    reviews: 150,
    maxPax: 20,
    ctaLabel: 'Pesan Paket Danang Hanoi Sapa Halong Bay',
    maskapai: 'Air China (Domestic Flight VietJet VJ512 DAD-HAN 14:25-15:45)',
    keberangkatan: '28 Jun 2026',
    minPeserta: '20 Peserta (Didampingi 1 Tour Leader)',
    hotelInfoText: 'Hotel ★4 Local / Similar (Twin Share)',
    tipeKamarText: 'Twin Share | Single Supplement +Rp 2.500.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Air China International + Domestic Flight VietJet Danang-Hanoi (VJ512)' },
      { icon: '🚡', text: 'Ba Na Hills Cable Car (2 arah) & Golden Bridge (Jembatan Tangan Raksasa)' },
      { icon: '🌉', text: 'Dragon Bridge (Jembatan Naga 666m) & Love Bridge Danang + Hoi An Old Town' },
      { icon: '🚃', text: 'Electric Car di Sapa & Kereta Funicular di Ba Na Hills' },
      { icon: '🏔️', text: 'Mount Fansipan Cable Car ("Indochina\'s Rooftop" 3.143m) & Cat Cat Village' },
      { icon: '⛵', text: 'Halong Bay Cruise (Junk Boat) World Heritage + Seafood Lunch' },
      { icon: '🏨', text: 'Akomodasi Hotel ★4 & Air Mineral 2 Botol/Hari/Pax' },
    ],
    priceCategories: [
      {
        dateLabel: 'KEBERANGKATAN 28 JUNI 2026 (MINIMAL 20 PAIR DEWASA)',
        prices: [
          { type: 'Adult / Child Twin Share', price: 'Rp 16.900.000' },
          { type: 'Single Supplement (Sekamar Sendiri)', price: '+Rp 2.500.000' }
        ]
      }
    ],
    itinerary: [
      {
        day: 'Day 01',
        title: 'JAKARTA – DANANG',
        desc: 'Hari ini para peserta berkumpul di Bandara Soekarno Hatta untuk melakukan penerbangan menuju kota Da Nang dengan Air China. Setibanya, Anda akan diajak untuk check-in hotel & bermalam.'
      },
      {
        day: 'Day 02',
        title: 'DANANG - BA NA HILLS (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Menuju Ba Na Hills & menaiki cable car ke Station By Night (Vong Nguyet Hills & Old Villas of French). Puncak Ba Na Hills (Nui Chua Mountain): Golden Bridge (Jembatan Tangan Raksasa), Nghinh Phong Peak, Le Nim Villas & Orchid Garden. Kereta funicular, Debay Wine Cellar, taman bunga Le Jardin D\'amour & Fantasy Park. Lanjut ke Hoi An: Japanese Bridge, Phuc Kien Assembly Hall & Hoi An Old Town.'
      },
      {
        day: 'Day 03',
        title: 'DANANG - HANOI (Makan Pagi, Makan Siang, Makan Malam) VJ512 DAD-HAN 14.25-15.45',
        desc: 'City tour Da Nang: Dragon Bridge (jembatan naga 666m) & Love Bridge. Transfer ke bandara untuk penerbangan ke Hanoi. Setibanya di Hanoi, city tour Hoan Kiem Lake, Ngoc Son Temple, Old Quarter & makan malam Pho khas Vietnam.'
      },
      {
        day: 'Day 04',
        title: 'HANOI - SAPA (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Perjalanan menuju Sapa di Pegunungan Hoang Lien Son Range. Makan siang, check-in hotel. Kunjungi Stone Church (gereja abad ke-20) & Cat Cat Village (desa tradisional suku Hmong dengan air terjun & jembatan bambu). Kunjungi Sapa Market & makan malam Sapa Salmon Fish.'
      },
      {
        day: 'Day 05',
        title: 'SAPA - FANSIPAN MOUNTAIN PEAK - HANOI (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Menaiki Cable Car Fansipan ("Indochina\'s Rooftop" 3.143m) — pemandangan alam spektakuler pegunungan subtropis. Makan siang di Fansipan Restaurant & perjalanan kembali ke Hanoi. Makan malam di restoran lokal & check-in hotel.'
      },
      {
        day: 'Day 06',
        title: 'HANOI - HALONG BAY (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Perjalanan menuju Halong Bay "World Heritage". Naik Junk Boat di pelabuhan & makan siang seafood segar di atas kapal. Jelajahi Dau Go Cave, Thien Cung Cave, Tuan Chau Island, Dinh Huong Island, Ga Choi Island & Dog Island. Check-in hotel.'
      },
      {
        day: 'Day 07',
        title: 'HANOI - JAKARTA (Makan Pagi)',
        desc: 'Setelah sarapan, diantar menuju Bandara Hanoi untuk penerbangan kembali ke Jakarta dengan Air China. Tiba di Jakarta dengan sejuta kenangan manis. Terima kasih!'
      }
    ],
    inclusions: [
      { label: 'Tiket Pesawat Internasional Air China (non-endorsable, non-refundable & non-reroutable)', included: true },
      { label: 'Domestic Flight Danang - Hanoi by VietJet (VJ512 DAD-HAN)', included: true },
      { label: 'Acara tour, transportasi AC dan makan sesuai itinerary (B, L, D)', included: true },
      { label: 'Electric car di Sapa', included: true },
      { label: 'Cable car Fansipan & Ba Na Hills (2 arah)', included: true },
      { label: 'Transportasi AC & biaya kunjungan objek wisata', included: true },
      { label: 'Hotel 4★ berdasarkan 1 kamar berdua (Twin Share)', included: true },
      { label: 'Tour Leader yang menemani dari Jakarta & Local Guide', included: true },
      { label: 'Air mineral 2 botol/day/pax', included: true },
      { label: 'Tipping untuk Tour Leader, Local Guide & Driver sebesar IDR 750.000', included: false },
      { label: 'Asuransi Perjalanan', included: false },
      { label: 'Pembuatan passport dan dokumen lainnya', included: false },
      { label: 'Pengeluaran pribadi & Optional Tour', included: false },
      { label: 'PPN 1,1%', included: false }
    ],
    syaratKetentuan: [
      'Harga berdasarkan 20 Peserta Dewasa + 1 Tour Leader.',
      'Harga Airport tax & Fuel Surcharge dapat berubah sewaktu-waktu dengan atau tanpa pemberitahuan terlebih dahulu.',
      'Uang muka sebesar Rp 9.000.000 / orang pada saat pendaftaran + biaya visa (non-refundable).',
      'Pelunasan paling lambat 25 (dua puluh lima) hari sebelum tanggal keberangkatan.',
      'Group akan diberangkatkan apabila mencapai jumlah minimum 20 peserta.',
      'Pembatalan setelah pendaftaran: Uang Muka hangus | 30–15 hari = 50% | 14–07 hari = 75% | ≤06 hari = 100% biaya tour.',
      'Force Majeur (bencana alam, keterlambatan sarana transportasi, dll) bersifat non-refundable.'
    ],
    remarks: [
      'Electric car di Sapa & Cable car Fansipan + Ba Na Hills (2 arah) sudah termasuk dalam paket.',
      'Susunan acara tour dapat berubah sewaktu-waktu tanpa mengurangi objek tour, tergantung kondisi di lapangan.'
    ],
    mapCenter: [105.8342, 21.0278],
    mapZoom: 6,
    mapPins: [
      { lng: 108.2022, lat: 16.0544, label: 'Da Nang & Ba Na Hills (Golden Bridge)' },
      { lng: 103.8438, lat: 22.3364, label: 'Sapa & Mount Fansipan (3.143m)' },
      { lng: 107.0843, lat: 20.9101, label: 'Halong Bay Cruise (World Heritage)' }
    ]
  },

  '5D SIGNATURE YEAR END VIETNAM HANOI SAPA FANSIPAN WITH HALONG BAY CRUISE': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1509099836639-18ba1795216d?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'HIGHLIGHT: CAT CAT VILLAGE – FANSIPAN MOUNTAIN – HALONG ISLAND TOUR – MEGA GRAND WORLD',
    price: 'Rp 12.990.000',
    duration: '5 Hari 4 Malam',
    rating: 4.8,
    reviews: 140,
    maxPax: 20,
    ctaLabel: 'Pesan Paket Signature Vietnam',
    maskapai: 'Malaysia Airlines (CGK-KUL-HAN PP MH 726/752/753/727)',
    keberangkatan: '20, 21, 23, 26, 29 Des 2026',
    minPeserta: '20 Peserta (Didampingi 1 Tour Leader)',
    hotelInfoText: 'Hotel ★3 Local / Similar (First Eden Hotel Hanoi *** / Sapa Panorama Hotel ***)',
    tipeKamarText: 'Twin / Triple Share | Single Supplement +Rp 3.000.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Malaysia Airlines Economy Class (CGK-KUL-HAN PP)' },
      { icon: '🧳', text: 'Bagasi sesuai ketentuan Airlines' },
      { icon: '🌾', text: 'Sapa & Cat Cat Village (Desa H\'mong, Hydro Electric Power Station Prancis, Sapa Church & Sapa Lake)' },
      { icon: '🏔️', text: 'Mount Fansipan Cable Car ("The Roof of Indochina")' },
      { icon: '⛵', text: 'Halong Bay Junk Boat Cruise (World Nature Heritage, Thiencung Cave, Dau Go Grotto & Seafood Lunch)' },
      { icon: '🛍️', text: 'Mega Grand World Mall & Hanoi Old Quarter' },
      { icon: '🏨', text: 'Menginap di Hotel ★3 (First Eden Hotel Hanoi & Sapa Panorama Hotel)' },
    ],
    priceCategories: [
      {
        dateLabel: '20 DECEMBER 2026 (SCHOOL HOLIDAY)',
        prices: [
          { type: 'Adult Dewasa Twin/Triple', price: 'Rp 12.990.000' },
          { type: 'Child No Bed (< 6 Tahun)', price: 'Rp 12.490.000' },
          { type: 'Single Supplement (Sekamar Sendiri)', price: '+Rp 3.000.000' }
        ]
      },
      {
        dateLabel: '21 DECEMBER 2026 (CHRISTMAS)',
        prices: [
          { type: 'Adult Dewasa Twin/Triple', price: 'Rp 13.190.000' },
          { type: 'Child No Bed (< 6 Tahun)', price: 'Rp 12.690.000' },
          { type: 'Single Supplement (Sekamar Sendiri)', price: '+Rp 3.000.000' }
        ]
      },
      {
        dateLabel: '23 DECEMBER 2026 (CHRISTMAS)',
        prices: [
          { type: 'Adult Dewasa Twin/Triple', price: 'Rp 13.390.000' },
          { type: 'Child No Bed (< 6 Tahun)', price: 'Rp 12.890.000' },
          { type: 'Single Supplement (Sekamar Sendiri)', price: '+Rp 3.000.000' }
        ]
      },
      {
        dateLabel: '26 DECEMBER 2026 (YEAR END)',
        prices: [
          { type: 'Adult Dewasa Twin/Triple', price: 'Rp 13.390.000' },
          { type: 'Child No Bed (< 6 Tahun)', price: 'Rp 12.890.000' },
          { type: 'Single Supplement (Sekamar Sendiri)', price: '+Rp 3.000.000' }
        ]
      },
      {
        dateLabel: '29 DECEMBER 2026 (NEW YEAR)',
        prices: [
          { type: 'Adult Dewasa Twin/Triple', price: 'Rp 13.990.000' },
          { type: 'Child No Bed (< 6 Tahun)', price: 'Rp 13.490.000' },
          { type: 'Single Supplement (Sekamar Sendiri)', price: '+Rp 3.000.000' }
        ]
      }
    ],
    itinerary: [
      {
        day: 'Day 01',
        title: 'JAKARTA - HANOI',
        desc: 'CGK (04.25) - KUL (07.30) by MH 726 & KUL (09.30) – HAN (12.00). Hari ini kita berkumpul di Bandara Soekarno-Hatta Terminal 3 Ultimate untuk terbang ke Hanoi dengan Malaysia Airlines. Setiba di Bandara Noi Bai, Hanoi, disambut Guide berbahasa Indonesia. Berkesempatan menjelajahi Hanoi Old Quarter, diantar ke hotel untuk check-in & istirahat. Bermalam di First Eden Hotel *** / setaraf.'
      },
      {
        day: 'Day 02',
        title: 'HANOI – SAPA – CAT CAT VILLAGE (Makan Pagi, Makan Siang)',
        desc: 'Sarapan pagi di hotel. Perjalanan menuju Sapa menikmati keindahan gunung dan sawah. Setibanya di Sapa, makan siang sebelum mengunjungi Cat Cat – Shin Chai Village of H’mong. Melihat Hydro Electric Power Station peninggalan Prancis, Sapa Church & Sapa Lake. Check-in Sapa Panorama Hotel *** / setaraf.'
      },
      {
        day: 'Day 03',
        title: 'SAPA FANSIPAN THE ROOF INDOCHINA - HANOI (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Menuju Gunung Fansipan, menaiki Cable Car Station menikmati keindahan Gunung Hoang Lien Son. Melanjutkan tracking ±1,5 jam ke puncak Fansipan – "The Roof of Indochina" (atau optional Funicular). Kembali ke cable car station & kembali menuju Hanoi. Check-in First Eden Hotel *** / setaraf.'
      },
      {
        day: 'Day 04',
        title: 'HANOI – HALONG ISLAND TOUR - HANOI (Makan Pagi, Makan Siang)',
        desc: 'Perjalanan menuju Halong. Naik Halong Bay Cruise mengelilingi pulau & makan siang seafood di atas kapal. Kunjungi Thiencung Cave (stalaktit & stalagmit) & Dau Go Grotto. Menyusuri Incense Bowl Islet, Cock Fighting Islet, Sail Islet, & Turtle Island. Kembali ke Hanoi & mengunjungi Mega Grand World Mall. Check-in hotel.'
      },
      {
        day: 'Day 05',
        title: 'HANOI – JAKARTA (Makan Pagi)',
        desc: 'HAN (13.00) – KUL (17.40) by MH753 & KUL (22.30) - CGK (23.40) by MH727. Sarapan pagi. Waktu bebas sampai diantar ke Airport untuk penerbangan kembali ke Jakarta dengan Malaysia Airlines. Sampai jumpa di tour selanjutnya!'
      }
    ],
    inclusions: [
      { label: 'Tiket International Jakarta-Hanoi & Hanoi - Jakarta by Malaysia Airlines, Economy termasuk taxes internasional (Tiket Grup Fixed Date & No Extend)', included: true },
      { label: 'Bagasi sesuai dengan ketentuan Airlines', included: true },
      { label: 'Akomodasi hotel ★3 setaraf (First Eden Hotel Hanoi *** / Sapa Panorama Hotel *** - Twin/Triple Share)', included: true },
      { label: 'Transportasi bus Pariwisata & tiket masuk objek wisata', included: true },
      { label: 'Acara Tour & makan sesuai program', included: true },
      { label: 'Mineral Water 1 Botol Perhari', included: true },
      { label: 'Tour Leader dari Indonesia', included: true },
      { label: 'Travel Kits (Luggage Tag)', included: true },
      { label: 'Travel Insurance sampai usia 82 tahun', included: true },
      { label: 'Tipping Tour Leader, Local Guide, Driver: Rp 750.000/Pax', included: false },
      { label: 'Tips Porter Hotel, Mini Bar, Laundry, Telp, Kelebihan bagasi dll.', included: false },
      { label: 'PCR Test / Rapid Test Antigen jika dibutuhkan', included: false },
      { label: 'PPN 1.2%', included: false },
      { label: 'Rental Wifi / SIM CARD Portable (optional)', included: false },
      { label: 'Funicular ke puncak Fansipan (optional)', included: false }
    ],
    syaratKetentuan: [
      'Keberangkatan Minimal 20 Pax (Didampingi 1 Tour Leader)',
      'Pendaftaran Deposit Rp 6.000.000 (First Come First Serve)',
      'Peak season period pelunasan 28 hari sebelum keberangkatan',
      'Infant Flat Rate (< 23 Bulan): Rp 3.750.000',
      'Promo Cashback sewaktu-waktu dapat berubah atau habis tanpa pemberitahuan',
      'Tidak ada refund untuk peserta tour yang ditolak oleh imigrasi setempat.',
      'Jadwal dapat berubah sewaktu-waktu sesuai dengan operasional',
      'Rules (Term and Condition) telah diatur sesuai yang ditetapkan wholesaler dan tidak dapat diganggu gugat'
    ],
    remarks: [
      'Infant Flat Rate (< 23 Bulan): Rp 3.750.000.',
      'Jadwal dapat berubah sewaktu-waktu sesuai operasional.'
    ],
    mapCenter: [105.8342, 21.0278],
    mapZoom: 6,
    mapPins: [
      { lng: 105.8342, lat: 21.0278, label: 'Hanoi — Old Quarter & Mega Grand World Mall' },
      { lng: 103.8438, lat: 22.3364, label: 'Sapa & Mount Fansipan (The Roof of Indochina)' },
      { lng: 107.0843, lat: 20.9101, label: 'Halong Bay Cruise (World Nature Heritage)' }
    ]
  },

  'Southern Xinjiang 11 Hari / 09 Malam': {
    badge: 'PAKET INTERNASIONAL',
    image: 'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=1200&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1529921879218-f99546d03a70?auto=format&fit=crop&w=400&q=80'
    ],
    tagline: 'HIGHLIGHT: WENSU RAINBOW GRAND CANYON – N39 TAKLAMAKAN DESERT – ID KAH MOSQUE & KASHGAR OLD CITY – WHITE SAND LAKE – PANLONG ANCIENT ROAD – URUMQI GRAND BAZAAR',
    price: 'Rp 34.300.000',
    duration: '11 Hari 9 Malam',
    rating: 4.9,
    reviews: 175,
    maxPax: 20,
    ctaLabel: 'Pesan Paket Southern Xinjiang',
    maskapai: 'Air China (CGK-PEK-AKU CA978/1239, Kashgar-Urumqi domestic, URC-PEK-CGK CA1296/977)',
    keberangkatan: '11, 18, 30 Okt 2026',
    minPeserta: '20 Peserta (Didampingi 1 Tour Leader)',
    hotelInfoText: 'Hotel ★4 Local / Similar (Twin Share)',
    tipeKamarText: 'Twin Share | Single Supplement +Rp 9.500.000',
    hasGroupEksklusif: false,
    hasPembimbingIbadah: false,
    highlights: [
      { icon: '✈️', text: 'Air China Group Ticket + Penerbangan Domestik Kashgar-Urumqi' },
      { icon: '🧳', text: 'Bagasi sesuai peraturan maskapai penerbangan Air China' },
      { icon: '🏜️', text: 'Taklamakan Desert N39 Area ("Sea of Death" - Gurun pasir bergeser terbesar ke-2 dunia & Sand Slide)' },
      { icon: '🏞️', text: 'Wensu Grand Canyon ("Rainbow Canyon" ngarai spektakuler bebatuan erosi angin-air)' },
      { icon: '🕌', text: 'Id Kah Mosque (Masjid terbesar Tiongkok), Afaq Khoja Mausoleum & Tarian khas Uyghur' },
      { icon: '🏰', text: 'Old City Opening Ceremony & Kota Tua Kashgar (Art & Craft Streets)' },
      { icon: '🏔️', text: 'White Sand Lake (3000m dpl pasir putih alami berlatar Muztagh Ata Snow Mountain)' },
      { icon: '🐉', text: 'Panlong Ancient Road (Jalur kuno kelokan tajam naga melingkar include shuttle bus) & Bandir Blue Lake' },
      { icon: '🛍️', text: 'Urumqi Grand Bazaar & Factory Outlet + Premium Outlet Beijing' },
      { icon: '🏨', text: 'Akomodasi Hotel ★4 & Asuransi Perjalanan Group' },
    ],
    priceCategories: [
      {
        dateLabel: 'KEBERANGKATAN 11, 18, 30 OKTOBER 2026 (MINIMAL 20 PESERTA)',
        prices: [
          { type: 'Adult / Child Twin Share', price: 'Rp 34.300.000' },
          { type: 'Single Supplement (Sekamar Sendiri)', price: '+Rp 9.500.000' }
        ]
      }
    ],
    itinerary: [
      {
        day: 'Day 01',
        title: 'BERKUMPUL DI BANDARA JAKARTA',
        desc: 'Pada waktu yang ditentukan, semua peserta berkumpul di Bandara Soekarno Hatta Jakarta untuk penerbangan menuju Beijing dengan Air China.'
      },
      {
        day: 'Day 02',
        title: 'JAKARTA - BEIJING (CA978 CGKPEK 0145 - 1015)',
        desc: 'Setibanya di Beijing, diantar menuju Premium Outlet untuk menikmati waktu bebas berbelanja.'
      },
      {
        day: 'Day 03',
        title: 'BEIJING - AKSU (Makan Pagi, Makan Malam) CA1239 PEKAKU 0845 - 1610',
        desc: 'Pagi hari diantar menuju bandara untuk penerbangan menuju Aksu. Setibanya di Aksu, makan malam sebelum check-in hotel & bermalam.'
      },
      {
        day: 'Day 04',
        title: 'AKSU - N39 DESERT (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Mengunjungi Wensu Grand Canyon ("Rainbow Canyon" ngarai spektakuler bebatuan berwarna-warni erosi angin-air Tiongkok Barat). Lanjut menuju N39 Desert Area di Taklamakan Desert ("Sea of Death" gurun pasir bergeser terbesar ke-2 dunia), nikmati Sand Slide & Cultural Show.'
      },
      {
        day: 'Day 05',
        title: 'N39 DESERT - KASHGAR (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Perjalanan menuju kota Kashgar. Photo stop di Id Kah Mosque (masjid terbesar di China & simbol kota Kashgar), mengunjungi Afaq Khoja Mausoleum (arsitektur kubah besar ubin keramik hijau-biru & tarian khas suku Uyghur).'
      },
      {
        day: 'Day 06',
        title: 'KASHGAR (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Menyaksikan Old City Opening Ceremony, jalan-jalan di Kota Tua Kashgar & melihat kerajinan tangan di Art & Craft Streets.'
      },
      {
        day: 'Day 07',
        title: 'KASHGAR - TASHKURGAN (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Mengunjungi White Sand Lake (danau pasir putih alami 3000m dpl berlatar Gunung Es Muztagh Ata Mountain) & Karakul Lake.'
      },
      {
        day: 'Day 08',
        title: 'TASHKURGAN (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Menuju Panlong Ancient Road (termasuk shuttle bus) jalur kuno unik kelokan tajam naga melingkar. Melewati Bandir Blue Lake dengan danau jernih kebiruan dipadukan biru langit.'
      },
      {
        day: 'Day 09',
        title: 'TASHKURGAN - KASHGAR - URUMQI (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Kembali menuju Kashgar dengan bus. Transfer ke Bandara Kashgar penerbangan domestik ke Urumqi. Setibanya di Urumqi, check-in hotel & bermalam.'
      },
      {
        day: 'Day 10',
        title: 'URUMQI (Makan Pagi, Makan Siang, Makan Malam)',
        desc: 'Setelah makan pagi, menikmati waktu bebas berbelanja di Grand Bazaar Urumqi & Factory Outlet.'
      },
      {
        day: 'Day 11',
        title: 'URUMQI - JAKARTA (Makan Pagi) CA1296 URCPEK 10.25-14.10 / CA977 PEKCGK 17.25-00.15',
        desc: 'Diantar menuju Bandara Urumqi untuk penerbangan kembali ke Jakarta via Beijing. Tiba di Jakarta dengan membawa sejuta kenangan manis. Terima kasih!'
      }
    ],
    inclusions: [
      { label: 'Tiket International group by Air China (Economy Class, Group Ticket, Fix Date, Fix Flight)', included: true },
      { label: 'Bagasi sesuai dengan peraturan maskapai penerbangan Air China', included: true },
      { label: 'Akomodasi di hotel 4★ berdasarkan 1 kamar berdua (Twin Share)', included: true },
      { label: 'Transportasi Bus AC & biaya kunjungan objek wisata sesuai itinerary', included: true },
      { label: 'Tour Leader dari Jakarta yang menemani selama tour', included: true },
      { label: 'Asuransi Perjalanan Group (Max Coverage Usia 69th)', included: true },
      { label: 'Fuel Surcharge / Airport Tax IDR 4.200.000 (dapat berubah sewaktu-waktu)', included: false },
      { label: 'Visa Group sebesar Rp 1.000.000 per orang', included: false },
      { label: 'Tipping TL, Guide & Driver Rp 1.360.000', included: false },
      { label: 'Paspor dan dokumen lainnya', included: false },
      { label: 'Pengeluaran pribadi & Optional tour', included: false },
      { label: 'PPN 1,1%', included: false }
    ],
    syaratKetentuan: [
      'Harga Airport tax & Fuel Surcharge, biaya visa serta asuransi dapat berubah sewaktu-waktu tanpa pemberitahuan.',
      'Uang muka sebesar Rp 16.000.000 / orang pada saat pendaftaran dan tidak dapat dikembalikan (non-refundable).',
      'Pelunasan paling lambat 30 (tiga puluh) hari sebelum tanggal keberangkatan.',
      'Syarat Visa Group China (Rp 1.000.000): Peserta wajib memenuhi kelengkapan dokumen; biaya visa tetap harus dilunasi walaupun visa tidak disetujui.',
      'Group akan diberangkatkan apabila mencapai jumlah minimum 20 peserta.',
      'Apabila hotel yang ditawarkan penuh, akan diganti dengan hotel lain yang setaraf.',
      'Pembatalan 30–15 hari sebelum keberangkatan: 75% dari biaya tour.',
      'Pembatalan 14–00 hari sebelum keberangkatan: 100% dari biaya tour.',
      'Force Majeur (bencana alam, keterlambatan sarana transportasi, dll) bersifat non-refundable.'
    ],
    remarks: [
      'Fuel Surcharge / Airport Tax IDR 4.200.000 & Visa Group China Rp 1.000.000 / pax.',
      'Susunan acara tour dapat berubah sewaktu-waktu tanpa mengurangi objek tour, tergantung kondisi di lapangan.'
    ],
    mapCenter: [75.9938, 39.4677],
    mapZoom: 5,
    mapPins: [
      { lng: 80.2634, lat: 41.1675, label: 'Aksu & Wensu Rainbow Grand Canyon' },
      { lng: 75.9938, lat: 39.4677, label: 'Kashgar (Id Kah Mosque & Kashgar Old City)' },
      { lng: 75.2312, lat: 37.7725, label: 'Tashkurgan (White Sand Lake & Panlong Ancient Road)' },
      { lng: 87.6168, lat: 43.8256, label: 'Urumqi Grand Bazaar & Factory Outlet' }
    ]
  },

  'Beijing Shanghai 09 Hari / 06 Malam': {
    image: 'https://images.unsplash.com/photo-1474181487882-5abf3f0ba6c2?auto=format&fit=crop&w=800&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1474181487882-5abf3f0ba6c2?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=800&q=80',
    ],
    maxPax: 24,
    ctaLabel: 'Pesan Sekarang',
    tagline: '6 Shopping Stop — Beijing, Suzhou, Hangzhou & Shanghai: Great Wall, Forbidden City, The Bund, West Lake, dan Wuzhen Water Town.',
    price: 'Rp 15.900.000',
    duration: '9 Hari 6 Malam',
    rating: 4.7,
    reviews: 0,
    maskapai: 'Singapore Airlines / Garuda Indonesia (Economy, No Refund, No Reschedule, No Reroute)',
    keberangkatan: 'Mei 2026',
    minPeserta: 'Sesuai Minimum Group',
    hotelInfoText: 'Hotel ★4 (1 kamar berdua) — Mustel Beijing / Tian Ping Suzhou / Mahood Lestie Hangzhou / Rais International Shanghai',
    tipeKamarText: 'Twin Share | Single Supplement +Rp 3.000.000',
    highlights: [
      { icon: '🏯', text: 'Great Wall & Forbidden City Beijing' },
      { icon: '🌉', text: 'The Bund & Oriental Pearl Tower Shanghai' },
      { icon: '🛶', text: 'West Lake Cruise Hangzhou' },
      { icon: '🛍️', text: '6 Shopping Stop (Tongrentang, Silk, Jewelry, Tea...)' },
    ],
    priceCategories: [
      { dateLabel: 'MEI 2026 (25 Mei)', prices: [
        { type: 'Twin Share', price: 'Rp 16.900.000' },
        { type: 'Child No Bed', price: 'Rp 15.900.000' },
        { type: 'Single Supplement', price: '+Rp 3.000.000' },
      ]},
      { dateLabel: 'DISC BOOKING S/D 30 APRIL 2026', prices: [
        { type: 'Twin Share', price: 'Rp 16.500.000' },
        { type: 'Child No Bed', price: 'Rp 15.500.000' },
        { type: 'Single Supplement', price: '+Rp 3.000.000' },
      ]},
    ],
    optionalActivities: [],
    itinerary: [
      { day: 'Day 01', title: 'JAKARTA – SINGAPORE', desc: 'Peserta berkumpul di Bandara Jakarta untuk penerbangan ke Beijing via Singapore.' },
      { day: 'Day 02', title: 'SINGAPORE – BEIJING (L, D)', desc: 'Setibanya di Beijing, berjalan-jalan di Qianmen Street dan Dashilan Street.' },
      { day: 'Day 03', title: 'BEIJING (B, L, D)', desc: 'Great Wall — salah satu dari tujuh keajaiban dunia, membentang ±6.000 km di 5 Provinsi China. Photo Stop Bird Nest Stadium & Water Cube (venue Olimpiade 2008).' },
      { day: 'Day 04', title: 'BEIJING (B, L, D)', desc: 'Herbal Medicine Shop (Tongrentang / Baoshutang) → Tian An Men (alun-alun terluas di dunia, 400.000m²) → Forbidden City (720.000m², 9.999 ruangan) → Wangfujing Street kuliner lokal.' },
      { day: 'Day 05', title: 'BEIJING – SHANGHAI (B, D)', desc: 'Perjalanan ke Shanghai via bullet train. The Bund (bangunan bersejarah abad 18-19, foto dengan Oriental Pearl TV Tower) → Chenghuangmiao Market.' },
      { day: 'Day 06', title: 'SHANGHAI – SUZHOU (B, L, D)', desc: 'Jewelry Shop → Nanjing Road (pusat perbelanjaan, restoran & hiburan) → Suzhou: Jinji Lake & Shantang Street.' },
      { day: 'Day 07', title: 'SUZHOU – WUZHEN – HANGZHOU (B, L, D)', desc: 'Wuzhen Water Town (kota air kuno yang indah — tidak termasuk boat) → Hangzhou: Sand\'s Ship Outlets.' },
      { day: 'Day 08', title: 'HANGZHOU DEPARTURE (B, L)', desc: 'Tea Plantation → West Lake Cruise (legenda ular putih) → Hefangjie (waktu bebas). Malam diantar ke bandara untuk penerbangan ke Jakarta via Singapore.' },
      { day: 'Day 09', title: 'HANGZHOU – JAKARTA', desc: 'Tiba di Jakarta — berakhirlah perjalanan tour dengan sejuta kenangan manis.' },
    ],
    inclusions: [
      { label: 'Tiket International by Singapore Airlines & Garuda Indonesia (Economy Class, No Refund, No Reschedule, No Reroute)', included: true },
      { label: 'Bagasi sesuai ketentuan maskapai', included: true },
      { label: 'Akomodasi hotel ★4 (1 kamar berdua) — Mustel Beijing / Tian Ping Suzhou / Mahood Lestie Hangzhou / Rais International or Gmile Hotel Shanghai (or similar)', included: true },
      { label: 'Transportasi Bus AC & biaya kunjungan objek wisata', included: true },
      { label: 'Tour Leader yang menemani selama tour', included: true },
      { label: 'International Airport Tax', included: true },
      { label: 'Asuransi Perjalanan Group (max coverage usia 69 tahun)', included: true },
      { label: 'Visa Group China: IDR 980.000 (subject to change)', included: false },
      { label: 'Tipping TL, Guide & Driver: IDR 950.000', included: false },
      { label: 'Pembuatan passport dan dokumen lainnya', included: false },
      { label: 'Pengeluaran pribadi & optional tour', included: false },
      { label: 'PPN 1.1%', included: false },
    ],
    syaratKetentuan: [
      'DISCOUNT Rp 1.000.000 untuk periode booking hingga 30 April 2026',
      'Harga Airport Tax, Fuel Surcharge, biaya visa & asuransi dapat berubah sewaktu-waktu',
      'Uang muka Rp 8.000.000/orang saat pendaftaran — non-refundable bila terjadi pembatalan',
      'Pelunasan paling lambat 30 hari sebelum keberangkatan',
      'Visa tetap harus dilunasi walaupun tidak disetujui kedutaan',
      'Group diberangkatkan apabila mencapai jumlah minimum peserta',
      'Pembatalan 30–15 hari sebelum keberangkatan: 75% dari biaya tour',
      'Pembatalan 14–00 hari sebelum keberangkatan: 100% dari biaya tour',
      'Force Majeur bersifat non-refundable',
      'Susunan acara tour dapat berubah sewaktu-waktu tanpa mengurangi objek tour',
    ],
    remarks: [],
    mapCenter: [116.3912, 39.9075],
    mapZoom: 5,
    mapPins: [
      { lng: 116.3912, lat: 39.9075, label: 'Beijing (Great Wall, Forbidden City, Tian An Men)' },
      { lng: 121.4737, lat: 31.2304, label: 'Shanghai (The Bund, Nanjing Road)' },
      { lng: 120.5853, lat: 31.2990, label: 'Suzhou (Jinji Lake, Shantang Street)' },
      { lng: 120.1551, lat: 30.2741, label: 'Hangzhou (West Lake, Tea Plantation)' },
      { lng: 120.8889, lat: 30.6478, label: 'Wuzhen Water Town' },
    ]
  },

  '5D NEW DEAL JAPAN FUKUOKA YUFUIN BEPPU': {
    image: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?auto=format&fit=crop&w=800&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?auto=format&fit=crop&w=800&q=80',
    ],
    maxPax: 20,
    ctaLabel: 'Pesan Sekarang',
    tagline: 'Jelajahi sisi lain Jepang — Yunotsubo Street, onsen Yufuin, neraka Beppu, dan Tenjin District bersama Malaysia Airlines.',
    price: 'Rp 15.990.000',
    duration: '5 Hari 4 Malam',
    rating: 4.7,
    reviews: 0,
    maskapai: 'Malaysia Airlines MH722/MH056/MH057/MH725 (Economy, Group Fixed Date, No Extend)',
    keberangkatan: 'Sep, Okt, Nov 2026',
    minPeserta: '20 Peserta',
    hotelInfoText: 'Hotel ★3 Setaraf',
    tipeKamarText: 'Twin / Triple | Single Supplement +Rp 4.000.000',
    highlights: [
      { icon: '🛍️', text: 'Yunotsubo Street & Yufuin Floral Village' },
      { icon: '♨️', text: 'Beppu Umi Jigoku (Kolam Neraka Biru)' },
      { icon: '🏙️', text: 'Tenjin District & Canal City Hakata' },
      { icon: '🛒', text: 'Tosu Premium Outlets' },
    ],
    priceCategories: [
      { dateLabel: '16 SEPTEMBER 2026', prices: [
        { type: 'Dewasa (Twin/Triple)', price: 'Rp 15.990.000' },
        { type: 'Child w/ Extra Bed (Maks 12 Thn)', price: 'Rp 15.990.000' },
        { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 15.590.000' },
        { type: 'Single Supplement', price: '+Rp 4.000.000' },
      ]},
      { dateLabel: '23 SEPTEMBER 2026', prices: [
        { type: 'Dewasa (Twin/Triple)', price: 'Rp 15.990.000' },
        { type: 'Child w/ Extra Bed (Maks 12 Thn)', price: 'Rp 15.990.000' },
        { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 15.590.000' },
        { type: 'Single Supplement', price: '+Rp 4.000.000' },
      ]},
      { dateLabel: '7 OKTOBER 2026 (Autumn)', prices: [
        { type: 'Dewasa (Twin/Triple)', price: 'Rp 16.590.000' },
        { type: 'Child w/ Extra Bed (Maks 12 Thn)', price: 'Rp 16.590.000' },
        { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 16.190.000' },
        { type: 'Single Supplement', price: '+Rp 4.000.000' },
      ]},
      { dateLabel: '21 OKTOBER 2026 (Autumn)', prices: [
        { type: 'Dewasa (Twin/Triple)', price: 'Rp 16.590.000' },
        { type: 'Child w/ Extra Bed (Maks 12 Thn)', price: 'Rp 16.590.000' },
        { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 16.190.000' },
        { type: 'Single Supplement', price: '+Rp 4.000.000' },
      ]},
      { dateLabel: '1 NOVEMBER 2026', prices: [
        { type: 'Dewasa (Twin/Triple)', price: 'Rp 16.990.000' },
        { type: 'Child w/ Extra Bed (Maks 12 Thn)', price: 'Rp 16.990.000' },
        { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 16.590.000' },
        { type: 'Single Supplement', price: '+Rp 4.000.000' },
      ]},
      { dateLabel: '11 NOVEMBER 2026', prices: [
        { type: 'Dewasa (Twin/Triple)', price: 'Rp 16.990.000' },
        { type: 'Child w/ Extra Bed (Maks 12 Thn)', price: 'Rp 16.990.000' },
        { type: 'Child No Bed (Maks 6 Thn)', price: 'Rp 16.590.000' },
        { type: 'Single Supplement', price: '+Rp 4.000.000' },
      ]},
      { dateLabel: 'INFANT FLAT RATE (< 23 Bulan)', prices: [
        { type: 'Infant', price: 'Rp 3.750.000' },
      ]},
    ],
    optionalActivities: [],
    itinerary: [
      { day: 'Hari 01', title: 'JAKARTA DEPARTURE (Meals on Board)', desc: 'CGK (18.25) – KUL (21.35) by MH 722 & KUL (23.45) – FUK (07.05) by MH 056. Peserta berkumpul di Bandara Soekarno-Hatta 3 jam sebelum keberangkatan untuk check-in dan briefing perjalanan. Bermalam di pesawat.' },
      { day: 'Hari 02', title: 'ARRIVAL FUKUOKA – YUFUIN – BEPPU – OITA', desc: 'Tiba di Fukuoka, perjalanan menuju Yufuin: Yunotsubo Street (toko souvenir unik, kafe, suasana pedesaan tenang) dan Yufuin Floral Village (area bergaya Eropa yang estetik). Lanjut ke Beppu Umi Jigoku — kolam "neraka" Beppu dengan air panas biru yang ikonik (tiket masuk termasuk). Check-in hotel di Oita. Bermalam di Hotel★★★/similar.' },
      { day: 'Hari 03', title: 'OITA – FUKUOKA (MAKAN PAGI)', desc: 'Makan pagi di hotel. Perjalanan ke Fukuoka via Tosu Premium Outlets (berbagai brand internasional dengan harga menarik). Di Fukuoka: Canal City Hakata (kompleks perbelanjaan modern dengan desain kanal unik), Tenjin District (pusat perbelanjaan utama suasana kota dinamis). Check-in hotel. Bermalam di Hotel★★★/similar.' },
      { day: 'Hari 04', title: 'FUKUOKA FREE DAY (MAKAN PAGI)', desc: 'Hari bebas tanpa bus dan tanpa guide. Eksplorasi Fukuoka secara mandiri — kuliner khas Hakata, berbelanja, atau kunjungi tempat wisata pilihan. Bermalam di Hotel★★★/similar.' },
      { day: 'Hari 05', title: 'FUKUOKA – DEPARTURE (MAKAN PAGI/BOX, Meals on Board)', desc: 'FUK (10.00) – KUL (15.45) by MH 057 & KUL (17.50) – CGK (19.05) by MH 725. Diantar ke Bandara Fukuoka untuk penerbangan kembali ke tanah air. Berakhirlah perjalanan menyenangkan menjelajahi keindahan Fukuoka.' },
    ],
    inclusions: [
      { label: 'Tiket International Jakarta – Fukuoka / Fukuoka – Jakarta dengan Malaysia Airlines Economy, termasuk seluruh taxes (Tiket Grup Fixed Date & No Extend)', included: true },
      { label: 'Bagasi 30 kg per orang atau sesuai ketentuan Airlines', included: true },
      { label: 'Akomodasi hotel ★3 setaraf (Twin/Triple)', included: true },
      { label: 'Transportasi bus pariwisata & tiket masuk objek wisata', included: true },
      { label: 'Acara tour & makan sesuai program paket', included: true },
      { label: 'Tour Leader', included: true },
      { label: 'Travel Insurance sampai usia 69 tahun', included: true },
      { label: 'Luggage Tag', included: true },
      { label: 'Visa Jepang: Rp 1.000.000/pax (Domisili Jakarta & sekitarnya)', included: false },
      { label: 'Visa Jepang Biasa: Rp 1.300.000/pax (Domisili Luar Jakarta)', included: false },
      { label: 'Visa Waiver: Rp 400.000/pax', included: false },
      { label: 'Tipping Local Guide, Driver, Tour Leader: Rp 850.000', included: false },
      { label: 'Tips Porter Hotel, Mini Bar, Laundry, Telp, Kelebihan Bagasi dll.', included: false },
      { label: 'PPN 1.2%', included: false },
      { label: 'Air Mineral (tidak disediakan di dalam bus efektif Juni 2025)', included: false },
      { label: 'OPTIONAL: Rental Wifi Portable', included: false },
    ],
    syaratKetentuan: [
      'Minimum keberangkatan 20 Pax (didampingi 1 Tour Leader)',
      'Pendaftaran Deposit: Rp 7.000.000 (First Come First Serve)',
      'Deadline Pelunasan: 25 hari sebelum keberangkatan',
      'Apabila Visa Jepang direject akan dikenakan biaya pembatalan sesuai rules yang berlaku',
      'Harga dapat berubah sewaktu-waktu',
      'INFANT FLAT RATE (< 23 Bulan): Rp 3.750.000',
    ],
    remarks: [],
    mapCenter: [130.4017, 33.5902],
    mapZoom: 8,
    mapPins: [
      { lng: 130.4017, lat: 33.5902, label: 'Fukuoka (Canal City, Tenjin District)' },
      { lng: 131.3656, lat: 33.2598, label: 'Yufuin (Yunotsubo Street & Floral Village)' },
      { lng: 131.4913, lat: 33.2845, label: 'Beppu (Umi Jigoku)' },
      { lng: 130.5994, lat: 33.5597, label: 'Tosu Premium Outlets' },
    ]
  },

  '7D SUPER SALE AUSTRALIA (MELBOURNE+SYDNEY) WITH PENGUIN PARADE AND THE NOBBIES': {
    image: 'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?auto=format&fit=crop&w=800&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1523482580672-f109ba8cb9be?auto=format&fit=crop&w=800&q=80',
    ],
    maxPax: 20,
    ctaLabel: 'Pesan Sekarang',
    tagline: 'Pengalaman terbaik di Australia — Sydney Opera House, Bondi Beach, Penguin Parade, dan Moonlit Sanctuary bersama Qantas Airlines.',
    price: 'Rp 21.490.000',
    duration: '7 Hari 6 Malam',
    rating: 4.8,
    reviews: 0,
    maskapai: 'Qantas Airlines',
    keberangkatan: 'Jul, Agt, Okt, Nov 2026',
    minPeserta: '20 Peserta',
    hotelInfoText: 'Hotel ★3 Setaraf',
    tipeKamarText: 'Twin / Triple | Single Supplement +Rp 5.000.000',
    highlights: [
      { icon: '🎭', text: 'Sydney Opera House & Bondi Beach' },
      { icon: '🌿', text: 'Fitzroy Garden Melbourne' },
      { icon: '🦘', text: 'Moonlit Sanctuary (Kangguru & Koala)' },
      { icon: '🐧', text: 'The Nobbies & Penguin Parade' },
    ],
    priceCategories: [
      { dateLabel: '23 JULI 2026', prices: [
        { type: 'Dewasa (Twin/Triple)', price: 'Rp 21.490.000' },
        { type: 'Child with Extra Bed', price: 'Rp 20.490.000' },
        { type: 'Child No Bed (< 6 Thn)', price: 'Rp 18.990.000' },
        { type: 'Single Supplement', price: 'Rp 5.000.000' },
      ]},
      { dateLabel: '22 AGUSTUS 2026', prices: [
        { type: 'Dewasa (Twin/Triple)', price: 'Rp 21.490.000' },
        { type: 'Child with Extra Bed', price: 'Rp 20.490.000' },
        { type: 'Child No Bed (< 6 Thn)', price: 'Rp 18.990.000' },
        { type: 'Single Supplement', price: 'Rp 5.000.000' },
      ]},
      { dateLabel: '22 OKTOBER 2026', prices: [
        { type: 'Dewasa (Twin/Triple)', price: 'Rp 21.490.000' },
        { type: 'Child with Extra Bed', price: 'Rp 20.490.000' },
        { type: 'Child No Bed (< 6 Thn)', price: 'Rp 18.990.000' },
        { type: 'Single Supplement', price: 'Rp 5.000.000' },
      ]},
      { dateLabel: '21 NOVEMBER 2026', prices: [
        { type: 'Dewasa (Twin/Triple)', price: 'Rp 21.490.000' },
        { type: 'Child with Extra Bed', price: 'Rp 20.490.000' },
        { type: 'Child No Bed (< 6 Thn)', price: 'Rp 18.990.000' },
        { type: 'Single Supplement', price: 'Rp 5.000.000' },
      ]},
      { dateLabel: 'INFANT FLAT RATE (< 23 Bulan)', prices: [
        { type: 'Infant', price: 'Rp 4.000.000' },
      ]},
    ],
    optionalActivities: [],
    itinerary: [
      { day: 'Hari 01', title: 'JAKARTA – SYDNEY', desc: 'CGK (19.50) – SYD (06.55) By QF-0042. Malam ini berkumpul di Bandara Soekarno-Hatta Terminal 3 Ultimate untuk berangkat menuju Sydney dengan Qantas Airlines. Bermalam di Hotel★★★/similar.' },
      { day: 'Hari 02', title: 'SYDNEY CITY TOUR', desc: 'Setiba di Sydney, kunjungi Sydney Opera House, The Rocks & Circular Quay, Royal Botanical Garden, Mrs. Macquarie\'s Chair, The Gap, Bondi Beach, dan QVB Mall. Check-in hotel dan istirahat. Bermalam di Hotel★★★/similar.' },
      { day: 'Hari 03', title: 'SYDNEY FREE DAY (MAKAN PAGI)', desc: 'Sarapan pagi di hotel. Waktu bebas untuk explore Kota Sydney seharian. Kembali ke hotel dan istirahat. (No Guide, No Transport, No Tour Leader). Bermalam di Hotel★★★/similar.' },
      { day: 'Hari 04', title: 'SYDNEY – MELBOURNE (MAKAN PAGI)', desc: 'DOMESTIC FLIGHT. Sarapan pagi Box Meal, check-out menuju Airport. Tiba di Melbourne: Parliament House (Photostop), St. Patrick Cathedral (Photostop), Fitzroy Garden (26 Ha, era Ratu Victoria), Shrine of Remembrance, St. Kilda Beach. Check-in hotel dan istirahat. Bermalam di Hotel★★★/similar.' },
      { day: 'Hari 05', title: 'MELBOURNE CITY TOUR (MAKAN PAGI)', desc: 'Queen Victoria Market, Islamic Council of Victoria, Moonlit Sanctuary (Kangguru & Koala), The Nobbies (koloni Anjing Laut di ujung tebing pantai), dan Penguin Parade. Bermalam di Hotel★★★. (Jika tiket Phillip Island habis saat group closing, dapat digantikan Sovereign Hill / Great Ocean / lainnya sesuai kebijakan penyelenggara — tidak dapat diganggu gugat)' },
      { day: 'Hari 06', title: 'MELBOURNE FREE DAY (MAKAN PAGI)', desc: 'Sarapan pagi di hotel. Waktu bebas untuk explore Kota Melbourne seharian. Kembali ke hotel dan istirahat. (No Guide, No Transport, No Tour Leader). Bermalam di Hotel★★★.' },
      { day: 'Hari 07', title: 'MELBOURNE – DEPARTURE (MAKAN PAGI)', desc: 'MEL (15.10) – CGK (18.30) By QF-0039. Sarapan pagi di hotel, kemudian diantar ke Airport untuk kembali ke Jakarta. Berakhirlah tour yang berkesan ini — sampai jumpa di tour selanjutnya bersama kami!' },
    ],
    inclusions: [
      { label: 'Tiket International Jakarta – Sydney & Melbourne – Jakarta by Qantas Airways Economy (Tiket Grup Fixed Date & No Extend) termasuk taxes internasional', included: true },
      { label: 'Bagasi sesuai ketentuan Airlines', included: true },
      { label: 'Akomodasi hotel ★3 setaraf (Twin/Triple)', included: true },
      { label: 'Transportasi bus pariwisata & tiket masuk objek wisata', included: true },
      { label: 'Acara tour & makan sesuai program paket', included: true },
      { label: 'Mineral Water 1 Botol per hari', included: true },
      { label: 'Tour Leader', included: true },
      { label: 'Travel Kits (Luggage Tag)', included: true },
      { label: 'Travel Insurance', included: true },
      { label: 'Biaya Visa Australia: Rp 3.000.000/Pax', included: false },
      { label: 'Tipping Tour Leader & Driver: Rp 1.200.000', included: false },
      { label: 'Tips Porter Hotel, Mini Bar, Laundry, Telp, Kelebihan Bagasi dll.', included: false },
      { label: 'PPN 1.2%', included: false },
      { label: 'PCR Test / Rapid Test Antigen jika dibutuhkan', included: false },
      { label: 'OPTIONAL: Rental Wifi Portable', included: false },
    ],
    syaratKetentuan: [
      'Minimum keberangkatan 20 Pax (didampingi 1 Tour Leader)',
      'Deposit 1 (DP1): Rp 11.000.000/pax + visa',
      'Deposit 2 (DP2): Rp 5.000.000/pax',
      'Pelunasan maksimal 31 hari sebelum keberangkatan',
      'Apabila Visa Australia direject akan dikenakan biaya pembatalan sesuai ketentuan yang berlaku',
      'INFANT FLAT RATE (< 23 Bulan): Rp 4.000.000',
      'START JAKARTA — Jadwal dapat berubah sewaktu-waktu sesuai operasional',
      'Rules (Term and Condition) telah diatur sesuai dengan yang ditetapkan oleh wholesaler dan tidak dapat diganggu gugat',
    ],
    remarks: [],
    mapCenter: [151.2093, -33.8688],
    mapZoom: 5,
    mapPins: [
      { lng: 151.2093, lat: -33.8688, label: 'Sydney (Opera House, Bondi Beach)' },
      { lng: 144.9631, lat: -37.8136, label: 'Melbourne (Fitzroy Garden, Shrine of Remembrance)' },
      { lng: 145.3626, lat: -38.4996, label: 'Phillip Island (The Nobbies & Penguin Parade)' },
    ]
  },

  'LONG WEEKEND WEST EUROPE LUCERNE + SCAFFHAUSEN 9D': {
    image: 'https://images.unsplash.com/photo-1500916434205-0c77489c6cf7?auto=format&fit=crop&w=800&q=80',
    galleryImages: [
      'https://images.unsplash.com/photo-1500916434205-0c77489c6cf7?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=400&q=80',
    ],
    tagline: '8 Negara Eropa Barat — Eiffel Tower, Rhine Falls, Lucerne Old Town & Galleria Vittorio Emanuele bersama Qatar Airways.',
    price: 'Rp 26.990.000',
    duration: '9 Hari 8 Malam',
    rating: 4.8,
    reviews: 62,
    maxPax: 20,
    ctaLabel: 'Pesan Paket Ini →',
    maskapai: 'Qatar Airways (Economy Class)',
    keberangkatan: '03 Jul 2026',
    minPeserta: '20 Pax',
    highlights: [
      { icon: '🗼', text: 'Eiffel Tower & Paris City Tour' },
      { icon: '🌊', text: 'Rhine Falls Schaffhausen — Air Terjun Terbesar Swiss' },
      { icon: '🏔️', text: 'Lucerne Old Town & Chapel Bridge' },
      { icon: '🇧🇪', text: 'Grand Place Brussels & Manneken Piss' },
      { icon: '🎡', text: 'Zaanse Schans — Windmolen & Cheese Factory' },
      { icon: '🛍️', text: 'McArthurGlen Designer Outlet Roermond' },
      { icon: '🇮🇹', text: 'Duomo di Milano & Galleria Vittorio Emanuele' },
      { icon: '🏰', text: 'Vaduz — Ibukota Liechtenstein' },
    ],
    itinerary: [
      { day: 'Hari 01', title: 'JAKARTA – PARIS (via Doha)', desc: 'CGK (18.10) – DOH (22.00) | DOH (01.35) – CDG (07.25). Berkumpul di Bandara Soekarno-Hatta Terminal 3 untuk penerbangan menuju Paris transit Doha.' },
      { day: 'Hari 02', title: 'ARRIVAL PARIS – PARIS FULLDAY TOUR', desc: 'City Tour Paris: Arc de Triomphe, Place de la Concorde, Notre-Dame Cathedral, Louvre Museum, Eiffel Tower (Photostop), Seine River Banks. Shopping di Galleries Lafayette & Benlux. Hotel: Ibis Styles Paris Gennevilliers ★3/Similar.' },
      { day: 'Hari 03', title: 'PARIS – BRUSSELS – AMSTERDAM', desc: 'Brussels: Mini Europe, Manneken Piss, Grand Place (belanja coklat khas Belgia). Bermalam di Amsterdam. Hotel: Joy Hotel Amsterdam ★3/Similar.' },
      { day: 'Hari 04', title: 'AMSTERDAM – ZAANSE SCHANS – VOLENDAM – MONHEIM', desc: 'Zaanse Schans: Windmolen, Cheese & Clog Factory. Volendam: foto dengan pakaian tradisional Belanda. Photostop Dam Square. Hotel: Hey Lou Monheim am Rhein ★3/Similar.' },
      { day: 'Hari 05', title: 'MONHEIM – COLOGNE – ROERMOND – FRANKFURT', desc: 'Photostop Cologne Cathedral. Shopping di McArthurGlen Designer Outlet Roermond (Luxembourg). Hotel: Mercure Hotel Frankfurt Eschborn Helfmann Park ★4/Similar.' },
      { day: 'Hari 06', title: 'FRANKFURT – TITISEE – SCHAFFHAUSEN – ZURICH', desc: 'Lake Titisee & Cuckoo Clock Shop. Shopping di Drubba Mall. Schaffhausen: Rhine Falls — air terjun terbesar di Swiss. Hotel: Zleep Hotel Zürich Kloten ★3/Similar.' },
      { day: 'Hari 07', title: 'ZURICH – LUCERNE – VADUZ – MILAN', desc: 'Lion Monument, Chapel Bridge, Lucerne Old Town. Vaduz (Liechtenstein): Parliament Building, St. Florin\'s Cathedral. Hotel: Best Western Hotel Goldenmile Milan ★4/Similar.' },
      { day: 'Hari 08', title: 'MILAN – JAKARTA (via Doha)', desc: 'MXP (16.00) – DOH (22.45). Photostop Galleria Vittorio Emanuele, Duomo di Milano, Castello Sforzesco. Diantar ke Airport untuk penerbangan kembali ke Jakarta.' },
      { day: 'Hari 09', title: 'ARRIVAL JAKARTA', desc: 'DOH (03.30) – CGK (16.30) by QR. Tiba di Jakarta. Sampai jumpa di acara tour selanjutnya!' },
    ],
    inclusions: [
      { label: 'Tiket Jakarta – Paris | Milan – Jakarta (Qatar Airways Economy)', included: true },
      { label: 'Bagasi sesuai peraturan penerbangan', included: true },
      { label: 'Hotel ★3/★4 — 6 malam (Twin Sharing)', included: true },
      { label: 'Transportasi Bus AC & Admission Fee objek wisata', included: true },
      { label: 'Tour Leader dari Jakarta', included: true },
      { label: 'Asuransi Perjalanan Group', included: true },
      { label: 'Visa Schengen: Rp 3.950.000/Pax (Non Refund)', included: false },
      { label: 'International Taxes & Surcharges: Rp 3.000.000/Pax', included: false },
      { label: 'Tipping TL, Driver, City Tax: Rp 2.900.000/Pax', included: false },
      { label: 'Travel Insurance: Rp 700.000/Pax (Wajib)', included: false },
      { label: 'Pengeluaran pribadi (Laundry, Phone, Minibar, dll)', included: false },
      { label: 'Optional Tour & Kelebihan Bagasi', included: false },
      { label: 'Travelling Bag', included: false },
    ],
    priceCategories: [
      { dateLabel: '03 JULI 2026', prices: [
        { type: 'Dewasa / Child (Twin Sharing)', price: 'Rp 26.990.000' },
        { type: 'Single Supplement', price: '+ Rp 8.500.000' },
      ]},
    ],
    syaratKetentuan: [
      'Minimal 20 Peserta didampingi oleh Tour Leader dari Jakarta',
      'Uang Muka Pendaftaran Rp 7.500.000 + Biaya Visa — non-refundable bila terjadi pembatalan',
      'Pelunasan biaya tour paling lambat 30 hari sebelum keberangkatan',
      'Pembatalan setelah pendaftaran: Uang Muka non-refundable',
      'Pembatalan 35–16 hari sebelum keberangkatan: 50% dari biaya tour',
      'Pembatalan 15–08 hari sebelum keberangkatan: 75% dari biaya tour',
      'Pembatalan 07 hari sebelum keberangkatan: 100% dari biaya tour',
      'Visa Schengen tetap harus dilunasi walaupun tidak disetujui kedutaan',
      'Harga dapat berubah sewaktu-waktu sesuai availability airlines & hotel',
      'Force Majeur bersifat non-refundable',
    ],
    mapCenter: [2.3522, 48.8566],
    mapZoom: 4,
    mapPins: [
      { lng: 2.3522, lat: 48.8566, label: 'Paris — Prancis' },
      { lng: 4.3517, lat: 50.8503, label: 'Brussels — Belgia' },
      { lng: 4.9041, lat: 52.3676, label: 'Amsterdam — Belanda' },
      { lng: 6.9602, lat: 50.9333, label: 'Cologne — Jerman' },
      { lng: 8.6821, lat: 50.1109, label: 'Frankfurt — Jerman' },
      { lng: 8.5417, lat: 47.3769, label: 'Zurich — Swiss' },
      { lng: 8.3093, lat: 47.0502, label: 'Lucerne — Swiss' },
      { lng: 9.5215, lat: 47.1410, label: 'Vaduz — Liechtenstein' },
      { lng: 9.1900, lat: 45.4654, label: 'Milan — Italia' },
    ],
  },
};

// ─────────────────────────────────────────────────────────────────────────────

@Component({
  selector: 'app-destination-detail',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './destination-detail.component.html',
  styleUrls: ['./destination-detail.component.css', '../../../../node_modules/maplibre-gl/dist/maplibre-gl.css']
})
export class DestinationDetailComponent implements AfterViewInit, OnDestroy, OnInit {
  @ViewChild('mapContainer') mapContainer!: ElementRef<HTMLDivElement>;

  destinationName = '';
  private map: maplibregl.Map | null = null;
  private markers: maplibregl.Marker[] = [];

  get pkg(): DestinationPackage | undefined {
    if (!this.destinationName) return undefined;
    if (PACKAGES[this.destinationName]) return PACKAGES[this.destinationName];
    if (PACKAGES[this.destinationName.toUpperCase()]) return PACKAGES[this.destinationName.toUpperCase()];

    const targetNorm = this.destinationName.toLowerCase().trim();
    const keys = Object.keys(PACKAGES);
    const matchedKey = keys.find(k => {
      const kNorm = k.toLowerCase().trim();
      return kNorm === targetNorm || kNorm.includes(targetNorm) || targetNorm.includes(kNorm);
    });
    if (matchedKey) {
      return PACKAGES[matchedKey];
    }
    return undefined;
  }

  get backgroundStyle(): string {
    const bg = this.pkg?.background;
    if (!bg) {
      return '#ffffff';
    }
    return `url('/${bg}') center center / cover no-repeat fixed`;
  }

  selectedImage = '';
  previewImageModal: string | null = null;

  openImagePreview(imgUrl: string): void {
    this.previewImageModal = imgUrl;
    document.body.classList.add('lightbox-open');
  }

  closeImagePreview(): void {
    this.previewImageModal = null;
    document.body.classList.remove('lightbox-open');
  }

  get activeMainImage(): string {
    if (this.selectedImage) return this.selectedImage;
    if (this.pkg?.image) return this.pkg.image;
    if (this.pkg?.galleryImages?.length) return this.pkg.galleryImages[0];
    return 'assets/terumbu-karang.png';
  }

  get galleryImages(): string[] {
    if (this.pkg?.galleryImages?.length) {
      return this.pkg.galleryImages;
    }
    const defaultImg = this.activeMainImage;
    return [defaultImg];
  }

  selectImage(img: string): void {
    this.selectedImage = img;
  }

  scrollToItinerary(): void {
    const el = document.getElementById('itinerary-section');
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }

  showAllItinerary = false;

  get itinerary(): ItineraryDay[] { return this.pkg?.itinerary ?? []; }
  cachedDatePills: DatePill[] = [];

  get displayedItinerary(): ItineraryDay[] {
    if (this.showAllItinerary || this.itinerary.length <= 5) {
      return this.itinerary;
    }
    return this.itinerary.slice(0, 5);
  }

  toggleItinerary(): void {
    this.showAllItinerary = !this.showAllItinerary;
  }

  get inclusions(): PackageInclusion[] { return this.pkg?.inclusions ?? []; }
  get highlights(): Highlight[] { return this.pkg?.highlights ?? []; }
  get maxPax(): number { return this.pkg?.maxPax ?? 12; }
  get ctaLabel(): string { return this.pkg?.ctaLabel ?? 'Pesan Sekarang'; }
  get hotelDetails(): HotelDetail[] { return this.pkg?.hotelDetails ?? []; }
  get priceCategories(): PriceCategory[] { return this.pkg?.priceCategories ?? []; }
  get optionalActivities(): OptionalActivity[] { return this.pkg?.optionalActivities ?? []; }
  get syaratKetentuan(): string[] { return this.pkg?.syaratKetentuan ?? []; }
  get remarks(): string[] { return this.pkg?.remarks ?? []; }

  get cleanRemarks(): string[] {
    const terms = this.syaratKetentuan || [];
    const termsNorm = terms.map(t => t.toLowerCase().replace(/[^a-z0-9]/g, ''));

    return (this.pkg?.remarks ?? []).filter(rem => {
      const remNorm = rem.toLowerCase().replace(/[^a-z0-9]/g, '');
      if (!remNorm) return false;
      return !termsNorm.some(t => t === remNorm || (remNorm.length > 15 && (t.includes(remNorm) || remNorm.includes(t))));
    });
  }

  get hasGroupEksklusif(): boolean {
    if (this.pkg?.hasGroupEksklusif !== undefined) {
      return this.pkg.hasGroupEksklusif;
    }
    return true;
  }

  get hasPembimbingIbadah(): boolean {
    if (this.pkg?.hasPembimbingIbadah !== undefined) {
      return this.pkg.hasPembimbingIbadah;
    }
    const badge = (this.pkg?.badge || '').toLowerCase();
    const name = (this.destinationName || '').toLowerCase();
    return badge.includes('umroh') || badge.includes('ibadah') || name.includes('umroh');
  }

  formatBintang(text: string | undefined): string {
    if (!text) return '';
    return text
      .replace(/Bintang\s*/gi, '★ ')
      .replace(/\*(\d)/g, '★ $1');
  }

  constructor(
    private router: Router,
    private route: ActivatedRoute,
    private travelService: TravelService
  ) {}

  ngOnInit(): void {
    window.scrollTo({ top: 0, left: 0, behavior: 'instant' });
    this.destinationName = this.route.snapshot.paramMap.get('name') ?? '';
    if (this.destinationName) {
      this.travelService.setLastSelectedPackage(this.destinationName);
    }
  }

  ngAfterViewInit(): void { this.initMap(); }

  goBack(): void {
    this.travelService.isReturningFromDetail = true;
    this.router.navigate(['/']);
  }

  showTicketModal = false;
  showTicketDropdown = false;
  selectedDate = '';
  ticketItems: TicketItem[] = [];

  get availableDates(): string[] {
    const datesObj = this.pkg?.tanggal_keberangkatan;
    if (!datesObj) {
      return this.pkg?.keberangkatan ? [this.pkg.keberangkatan] : [];
    }
    const result: string[] = [];
    Object.values(datesObj).forEach((arr: string[]) => {
      if (Array.isArray(arr)) {
        arr.forEach((d: string) => result.push(d));
      }
    });
    return result.length ? result : (this.pkg?.keberangkatan ? [this.pkg.keberangkatan] : []);
  }

  get formattedDatePills(): DatePill[] {
    if (this.cachedDatePills && this.cachedDatePills.length > 0) {
      return this.cachedDatePills;
    }
    const dates = this.availableDates;
    const pills: DatePill[] = [];

    if (dates && dates.length > 0) {
      dates.forEach(dStr => {
        if (dStr.includes(':')) {
          const parts = dStr.split(':');
          const monthYear = parts[0].trim();
          const days = parts[1].split(',').map(s => s.trim());
          const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Minggu'];
          days.forEach(dayNum => {
            const num = parseInt(dayNum, 10) || 1;
            const dayName = dayNames[(num - 1) % 5];
            pills.push({
              dayName: dayName,
              dateDisplay: `${dayNum} ${monthYear.split(' ')[0]}`,
              fullDate: `${dayNum} ${monthYear}`
            });
          });
        } else {
          const tokens = dStr.trim().split(' ');
          const dayNum = tokens[0] || '27';
          const month = tokens[1] || 'Jul';
          const year = tokens[2] || '2026';
          const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Minggu'];
          const num = parseInt(dayNum, 10) || 1;
          const dayName = dayNames[(num - 1) % 5];
          pills.push({
            dayName: dayName,
            dateDisplay: `${dayNum} ${month}`,
            fullDate: `${dayNum} ${month} ${year}`
          });
        }
      });
    }

    if (pills.length === 0) {
      pills.push(
        { dayName: 'Sen', dateDisplay: '27 Jul', fullDate: '27 Jul 2026' },
        { dayName: 'Sel', dateDisplay: '28 Jul', fullDate: '28 Jul 2026' },
        { dayName: 'Kam', dateDisplay: '30 Jul', fullDate: '30 Jul 2026' },
        { dayName: 'Jum', dateDisplay: '31 Jul', fullDate: '31 Jul 2026' },
        { dayName: 'Sen', dateDisplay: '03 Agt', fullDate: '03 Agt 2026' },
        { dayName: 'Sel', dateDisplay: '04 Agt', fullDate: '04 Agt 2026' },
        { dayName: 'Kam', dateDisplay: '06 Agt', fullDate: '06 Agt 2026' }
      );
    }

    this.cachedDatePills = pills;
    if (!this.selectedDate && pills.length > 0) {
      this.selectedDate = pills[0].fullDate;
    }
    return this.cachedDatePills;
  }

  selectDatePill(pill: DatePill, event?: Event): void {
    if (event) {
      event.stopPropagation();
    }
    this.selectedDate = pill.fullDate;
  }

  private parseFirstPrice(str: string): number {
    const match = (str || '').match(/\d[\d.,]*/);
    if (!match) return 0;
    return parseInt(match[0].replace(/[^0-9]/g, ''), 10) || 0;
  }

  initTicketModal(): void {
    this.cachedDatePills = [];
    const rawPrice = this.pkg?.price || '0';
    const basePriceNum = this.parseFirstPrice(rawPrice) || 7990000;

    const list: TicketItem[] = [];

    if (this.priceCategories && this.priceCategories.length > 0 && this.priceCategories[0].prices.length > 0) {
      const catPrices = this.priceCategories[0].prices;
      catPrices.forEach((cp) => {
        const typeLower = (cp.type || '').toLowerCase();
        if (typeLower.includes('uang muka') || typeLower.includes('dp')) {
          return;
        }
        const itemPriceNum = this.parseFirstPrice(cp.price) || basePriceNum;
        list.push({
          name: cp.type,
          priceNumber: itemPriceNum,
          qty: list.length === 0 ? 1 : 0
        });
      });
    } else {
      list.push(
        { name: 'Child', priceNumber: Math.round(basePriceNum * 0.85), qty: 0 },
        { name: 'Senior', priceNumber: Math.round(basePriceNum * 0.95), qty: 0 },
        { name: 'Adult', priceNumber: basePriceNum, qty: 1 }
      );
    }

    this.ticketItems = list;
  }

  incrementQty(item: TicketItem): void {
    item.qty++;
  }

  decrementQty(item: TicketItem): void {
    if (item.qty > 0) {
      item.qty--;
    }
  }

  get totalTicketPrice(): number {
    return this.ticketItems.reduce((sum, item) => sum + (item.priceNumber * item.qty), 0);
  }

  get totalTicketPriceFormatted(): string {
    const total = this.totalTicketPrice > 0 ? this.totalTicketPrice : this.rawPriceNumber;
    return 'IDR ' + total.toLocaleString('id-ID');
  }

  get totalTicketQty(): number {
    return this.ticketItems.reduce((sum, item) => sum + item.qty, 0);
  }

  get selectedPesertaSummary(): string {
    const activeItems = this.ticketItems.filter(i => i.qty > 0);
    if (activeItems.length === 0) return '1 orang (Twin Share)';
    return activeItems.map(i => `${i.qty} ${i.name}`).join(', ');
  }

  showConfirmationModal = false;

  get displayTanggal(): string {
    if (this.selectedDate) {
      return this.selectedDate;
    }
    if (this.pkg?.keberangkatan) {
      return this.pkg.keberangkatan;
    }
    return '27 Jul 2026';
  }

  get rawPriceNumber(): number {
    const rawPrice = this.pkg?.price || '0';
    return this.parseFirstPrice(rawPrice) || 7990000;
  }

  get unitPriceDisplay(): string {
    const price = this.totalTicketPrice > 0 ? this.totalTicketPrice : this.rawPriceNumber;
    return price.toLocaleString('id-ID');
  }

  get dpNumber(): number {
    const total = this.totalTicketPrice > 0 ? this.totalTicketPrice : this.rawPriceNumber;
    return Math.round(total * 0.5);
  }

  get dpDisplay(): string {
    return 'Rp ' + this.dpNumber.toLocaleString('id-ID');
  }

  get totalPriceFormatted(): string {
    const total = this.totalTicketPrice > 0 ? this.totalTicketPrice : this.rawPriceNumber;
    return 'Rp ' + total.toLocaleString('id-ID');
  }

  onBookNow(): void {
    if (!this.ticketItems || this.ticketItems.length === 0) {
      this.initTicketModal();
    }
    this.showTicketDropdown = !this.showTicketDropdown;
  }

  closeTicketModal(): void {
    this.showTicketModal = false;
    this.showTicketDropdown = false;
  }

  proceedToConfirmation(): void {
    if (this.totalTicketQty === 0 && this.ticketItems.length > 0) {
      this.ticketItems[0].qty = 1;
    }
    this.showTicketDropdown = false;
    this.showConfirmationModal = true;
    document.documentElement.classList.add('modal-open');
    document.body.classList.add('modal-open', 'lightbox-open');
    document.documentElement.style.overflow = 'hidden';
    document.body.style.overflow = 'hidden';
  }

  closeConfirmationModal(): void {
    this.showConfirmationModal = false;
    document.documentElement.classList.remove('modal-open');
    document.body.classList.remove('modal-open', 'lightbox-open');
    document.documentElement.style.overflow = '';
    document.body.style.overflow = '';
  }

  finalConfirmOrder(): void {
    const activeTickets = this.ticketItems.filter(i => i.qty > 0);
    this.travelService.packageBookingData = {
      packageName: this.destinationName,
      selectedDate: this.displayTanggal,
      ticketItems: activeTickets.length > 0 ? activeTickets : [{ name: 'Adult', priceNumber: this.rawPriceNumber, qty: 1 }],
      totalPriceFormatted: this.totalPriceFormatted,
      totalPriceNumber: this.totalTicketPrice > 0 ? this.totalTicketPrice : this.rawPriceNumber,
      packageImage: this.activeMainImage,
      duration: 'Berlaku di hari kerja (Senin-Jumat)'
    };
    this.closeConfirmationModal();
    this.router.navigate(['/booking/package-checkout']);
  }

  ngOnDestroy(): void {
    document.documentElement.classList.remove('modal-open');
    document.body.classList.remove('modal-open', 'lightbox-open');
    document.documentElement.style.overflow = '';
    document.body.style.overflow = '';
    this.map?.remove();
    this.map = null;
  }

  private initMap(): void {
    const pkg = this.pkg;
    if (!this.mapContainer || !pkg) return;

    this.map = new maplibregl.Map({
      container: this.mapContainer.nativeElement,
      style: 'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json',
      center: pkg.mapCenter,
      zoom: pkg.mapZoom,
      attributionControl: false,
    });

    this.map.addControl(new maplibregl.NavigationControl({ showCompass: false }), 'top-right');
    this.map.addControl(new maplibregl.AttributionControl({ compact: true }), 'bottom-right');
    this.map.on('load', () => this.addMarkers());
  }

  private addMarkers(): void {
    const pkg = this.pkg;
    if (!this.map || !pkg) return;

    this.markers.forEach(m => m.remove());
    this.markers = [];

    pkg.mapPins.forEach((pin, i) => {
      const el = document.createElement('div');
      el.style.cssText = `
        width:34px;height:34px;border-radius:50% 50% 50% 0;
        background:${i === 0 ? '#22c55e' : '#1e9bf0'};
        border:3px solid #fff;transform:rotate(-45deg);
        box-shadow:0 4px 14px rgba(0,0,0,0.25);cursor:pointer;
      `;

      const lbl = document.createElement('div');
      lbl.style.cssText = `
        position:absolute;bottom:42px;left:50%;transform:translateX(-50%);
        background:rgba(15,23,42,0.9);color:#fff;font-size:11px;font-weight:700;
        padding:4px 10px;border-radius:8px;white-space:nowrap;pointer-events:none;
        box-shadow:0 2px 8px rgba(0,0,0,0.3);
      `;
      lbl.textContent = pin.label;

      const wrap = document.createElement('div');
      wrap.style.cssText = 'position:relative;display:flex;align-items:center;justify-content:center;';
      wrap.appendChild(lbl);
      wrap.appendChild(el);

      this.markers.push(
        new maplibregl.Marker({ element: wrap, anchor: 'bottom' })
          .setLngLat([pin.lng, pin.lat])
          .addTo(this.map!)
      );
    });
  }

  private updateMap(): void {
    const pkg = this.pkg;
    if (!pkg || !this.map) return;
    this.map.flyTo({ center: pkg.mapCenter, zoom: pkg.mapZoom, duration: 800 });
    setTimeout(() => this.addMarkers(), 200);
  }
}
