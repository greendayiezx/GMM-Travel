import 'package:flutter/material.dart';
import '../settings/settings_service.dart';

/// Helper lokalisasi & terjemahan untuk aplikasi `kliktrip_mobile`.
/// Mengambil Bahasa yang aktif secara terpusat dari [SettingsService.instance.language].
class AppLocalizations {
  AppLocalizations._();

  static bool get isEnglish =>
      SettingsService.instance.language == AppLanguage.en;

  /// Kembalikan teks [enText] jika bahasa aktif Bahasa Inggris,
  /// atau [idText] jika Bahasa Indonesia.
  static String tr(String idText, String enText) {
    return isEnglish ? enText : idText;
  }

  /// Map kamus terjemahan berdasarkan kata kunci (key).
  static final Map<String, Map<AppLanguage, String>> _localizedValues = {
    // ── Navigation ──────────────────────────────────────────────────────────
    'nav_home': {AppLanguage.id: 'Beranda', AppLanguage.en: 'Home'},
    'nav_booking': {AppLanguage.id: 'Booking', AppLanguage.en: 'Bookings'},
    'nav_explore': {AppLanguage.id: 'Explore', AppLanguage.en: 'Explore'},
    'nav_favorite': {AppLanguage.id: 'Favorit', AppLanguage.en: 'Favorites'},
    'nav_account': {AppLanguage.id: 'Akun', AppLanguage.en: 'Account'},

    // ── App Settings ────────────────────────────────────────────────────────
    'settings_title': {
      AppLanguage.id: 'Pengaturan Aplikasi',
      AppLanguage.en: 'App Settings'
    },
    'settings_sec_notifications': {
      AppLanguage.id: 'NOTIFIKASI',
      AppLanguage.en: 'NOTIFICATIONS'
    },
    'settings_push_notifications': {
      AppLanguage.id: 'Notifikasi Push',
      AppLanguage.en: 'Push Notifications'
    },
    'settings_email_promos': {
      AppLanguage.id: 'Promo Email',
      AppLanguage.en: 'Email Promotions'
    },
    'settings_order_updates': {
      AppLanguage.id: 'Pembaruan Pesanan',
      AppLanguage.en: 'Order Updates'
    },

    'settings_sec_security': {
      AppLanguage.id: 'KEAMANAN & PRIVASI',
      AppLanguage.en: 'SECURITY & PRIVACY'
    },
    'settings_change_password': {
      AppLanguage.id: 'Ubah Kata Sandi',
      AppLanguage.en: 'Change Password'
    },
    'settings_two_factor': {
      AppLanguage.id: 'Autentikasi Dua Faktor',
      AppLanguage.en: 'Two-Factor Authentication'
    },
    'settings_2fa_active': {
      AppLanguage.id: 'Aktif',
      AppLanguage.en: 'Active'
    },
    'settings_data_privacy': {
      AppLanguage.id: 'Pengaturan Privasi Data',
      AppLanguage.en: 'Data Privacy Settings'
    },

    'settings_sec_general': {
      AppLanguage.id: 'UMUM',
      AppLanguage.en: 'GENERAL'
    },
    'settings_language': {
      AppLanguage.id: 'Bahasa',
      AppLanguage.en: 'Language'
    },
    'settings_currency': {
      AppLanguage.id: 'Mata Uang',
      AppLanguage.en: 'Currency'
    },
    'settings_theme': {
      AppLanguage.id: 'Tema',
      AppLanguage.en: 'Theme'
    },

    'settings_sec_about': {
      AppLanguage.id: 'TENTANG',
      AppLanguage.en: 'ABOUT'
    },
    'settings_app_version': {
      AppLanguage.id: 'Versi Aplikasi',
      AppLanguage.en: 'App Version'
    },
    'settings_terms_of_service': {
      AppLanguage.id: 'Ketentuan Layanan',
      AppLanguage.en: 'Terms of Service'
    },
    'settings_privacy_policy': {
      AppLanguage.id: 'Kebijakan Privasi',
      AppLanguage.en: 'Privacy Policy'
    },
    'settings_sign_out': {
      AppLanguage.id: 'KELUAR DARI AKUN',
      AppLanguage.en: 'SIGN OUT OF ACCOUNT'
    },
    'settings_connected_as': {
      AppLanguage.id: 'Tersambung sebagai',
      AppLanguage.en: 'Connected as'
    },

    'pick_language': {
      AppLanguage.id: 'Pilih Bahasa',
      AppLanguage.en: 'Select Language'
    },
    'pick_currency': {
      AppLanguage.id: 'Pilih Mata Uang',
      AppLanguage.en: 'Select Currency'
    },
    'pick_theme': {
      AppLanguage.id: 'Pilih Tema',
      AppLanguage.en: 'Select Theme'
    },

    // ── Profile Page ────────────────────────────────────────────────────────
    'profile_dashboard': {
      AppLanguage.id: 'Dashboard Akun',
      AppLanguage.en: 'Account Dashboard'
    },
    'profile_my_bookings': {
      AppLanguage.id: 'Pesanan Saya',
      AppLanguage.en: 'My Bookings'
    },
    'profile_my_bookings_sub': {
      AppLanguage.id: 'Kelola perjalanan mendatang dan lalu',
      AppLanguage.en: 'Manage your upcoming and past trips'
    },
    'profile_saved_passenger': {
      AppLanguage.id: 'Data Penumpang Tersimpan',
      AppLanguage.en: 'Saved Passenger Data'
    },
    'profile_saved_passenger_sub': {
      AppLanguage.id: 'Kelola data penumpang & dokumen perjalanan',
      AppLanguage.en: 'Manage passenger data & travel documents'
    },
    'profile_rewards': {
      AppLanguage.id: 'Hadiah & Poin',
      AppLanguage.en: 'Rewards & Points'
    },
    'profile_payment_methods': {
      AppLanguage.id: 'Metode Pembayaran',
      AppLanguage.en: 'Payment Methods'
    },
    'profile_payment_methods_sub': {
      AppLanguage.id: 'Kartu tersimpan dan informasi penagihan',
      AppLanguage.en: 'Stored cards and billing information'
    },
    'profile_wishlist': {
      AppLanguage.id: 'Daftar Keinginan',
      AppLanguage.en: 'Wishlist'
    },
    'profile_wishlist_sub': {
      AppLanguage.id: 'Destinasi dan pengalaman yang Anda simpan',
      AppLanguage.en: 'Your saved destinations and experiences'
    },
    'profile_app_settings': {
      AppLanguage.id: 'Pengaturan Aplikasi',
      AppLanguage.en: 'App Settings'
    },
    'profile_app_settings_sub': {
      AppLanguage.id: 'Notifikasi, privasi, dan bahasa',
      AppLanguage.en: 'Notifications, privacy, and language'
    },
    'profile_support': {
      AppLanguage.id: 'Bantuan & Dukungan',
      AppLanguage.en: 'Support & Help'
    },
    'profile_support_sub': {
      AppLanguage.id: 'Pusat bantuan dan asistensi perjalanan 24/7',
      AppLanguage.en: 'Help center and 24/7 travel assistance'
    },
    'profile_latest_wishlist': {
      AppLanguage.id: 'Wishlist Terbaru Ditambahkan',
      AppLanguage.en: 'Latest Wishlist Added'
    },
    'profile_sign_out': {
      AppLanguage.id: 'Keluar dari Global Explore',
      AppLanguage.en: 'Sign Out of Global Explore'
    },
    'profile_total_trips': {
      AppLanguage.id: 'TOTAL TRIP',
      AppLanguage.en: 'TOTAL TRIPS'
    },
    'profile_points': {
      AppLanguage.id: 'POIN',
      AppLanguage.en: 'POINTS'
    },
    'profile_reviews': {
      AppLanguage.id: 'ULASAN',
      AppLanguage.en: 'REVIEWS'
    },

    // ── Home Page ───────────────────────────────────────────────────────────
    'home_pesawat': {AppLanguage.id: 'Pesawat', AppLanguage.en: 'Flights'},
    'home_wisata': {AppLanguage.id: 'Wisata', AppLanguage.en: 'Tours'},
    'home_shuttle': {AppLanguage.id: 'Shuttle', AppLanguage.en: 'Shuttle'},
    'home_villa': {AppLanguage.id: 'Vila & Apt.', AppLanguage.en: 'Villas & Apts'},
    'home_whoosh': {AppLanguage.id: 'Whoosh', AppLanguage.en: 'Whoosh'},
    'home_car_rental': {AppLanguage.id: 'Sewa Mobil', AppLanguage.en: 'Car Rental'},
    'home_recent_search': {
      AppLanguage.id: 'Pencarian terakhir',
      AppLanguage.en: 'Recent searches'
    },
    'home_clear': {AppLanguage.id: 'Hapus', AppLanguage.en: 'Clear'},
    'home_promo_title': {
      AppLanguage.id: 'Promo Menarik',
      AppLanguage.en: 'Hot Deals & Offers'
    },
    'home_see_all': {AppLanguage.id: 'Lihat Semua', AppLanguage.en: 'See All'},
    'home_popular_airlines': {
      AppLanguage.id: 'Maskapai Populer',
      AppLanguage.en: 'Popular Airlines'
    },
    'home_search_tickets': {
      AppLanguage.id: 'Cari Tiket',
      AppLanguage.en: 'Search Tickets'
    },
    'home_explore_destinations': {
      AppLanguage.id: 'Jelajahi Destinasi',
      AppLanguage.en: 'Explore Destinations'
    },

    // ── Booking List Page ──────────────────────────────────────────────────
    'booking_title': {AppLanguage.id: 'Booking', AppLanguage.en: 'Bookings'},
    'booking_filter_all': {AppLanguage.id: 'Semua', AppLanguage.en: 'All'},
    'booking_filter_flight': {AppLanguage.id: 'Pesawat', AppLanguage.en: 'Flight'},
    'booking_filter_shuttle': {AppLanguage.id: 'Shuttle', AppLanguage.en: 'Shuttle'},
    'booking_filter_tour': {AppLanguage.id: 'Wisata', AppLanguage.en: 'Tours'},
    'booking_empty_title': {AppLanguage.id: 'Belum memiliki riwayat booking', AppLanguage.en: 'No booking history yet'},
    'booking_empty_sub': {AppLanguage.id: 'Yuk, mulai perjalanan seru kamu dengan melakukan booking sekarang!', AppLanguage.en: 'Start your exciting journey by booking now!'},

    // ── Saved / Favorites Page ─────────────────────────────────────────────
    'saved_title': {AppLanguage.id: 'Favorit', AppLanguage.en: 'Favorites'},
    'saved_empty_title': {AppLanguage.id: 'Wishlist kamu masih kosong', AppLanguage.en: 'Your wishlist is currently empty'},
    'saved_empty_sub': {AppLanguage.id: 'Yuk, mulai simpan wishlist kamu disini!', AppLanguage.en: 'Start saving your favorite items here!'},
    'saved_search_hint': {AppLanguage.id: 'Cari favorit...', AppLanguage.en: 'Search favorites...'},

    // ── Explore / Wisata Page ───────────────────────────────────────────────
    'explore_title': {AppLanguage.id: 'Explore', AppLanguage.en: 'Explore'},
    'explore_sub': {AppLanguage.id: 'Temukan perjalanan terbaik untuk setiap momen', AppLanguage.en: 'Find the best trip for every moment'},
    'explore_search_hint': {AppLanguage.id: 'Cari paket, destinasi, atau kota...', AppLanguage.en: 'Search packages, destinations, or cities...'},
    'explore_categories': {AppLanguage.id: 'Kategori Jelajah', AppLanguage.en: 'Explore Categories'},
    'explore_today_special': {AppLanguage.id: 'Spesial Hari Ini', AppLanguage.en: "Today's Special"},

    // ── Flight Search Page ─────────────────────────────────────────────────
    'flight_search_title': {AppLanguage.id: 'Cek Tiket Pesawat', AppLanguage.en: 'Flight Ticket Search'},
    'flight_origin_dest_hint': {AppLanguage.id: 'Pilih Kota atau Bandara', AppLanguage.en: 'Select City or Airport'},
    'flight_roundtrip': {AppLanguage.id: 'Pulang Pergi?', AppLanguage.en: 'Roundtrip?'},
    'flight_passengers_class': {AppLanguage.id: 'Penumpang & Kelas', AppLanguage.en: 'Passengers & Class'},
    'flight_search_btn': {AppLanguage.id: 'Ayo Cari', AppLanguage.en: 'Search Flights'},

    // ── Shuttle Search Page ────────────────────────────────────────────────
    'shuttle_search_title': {AppLanguage.id: 'Cari Shuttle', AppLanguage.en: 'Shuttle Search'},
    'shuttle_origin_hint': {AppLanguage.id: 'Pilih Kota Asal', AppLanguage.en: 'Select Departure City'},
    'shuttle_dest_hint': {AppLanguage.id: 'Pilih Kota Tujuan', AppLanguage.en: 'Select Destination City'},
    'shuttle_search_btn': {AppLanguage.id: 'Cari Shuttle', AppLanguage.en: 'Search Shuttle'},
    'shuttle_recent_search': {AppLanguage.id: 'Pencarian Terakhir', AppLanguage.en: 'Recent Searches'},
    'shuttle_popular_routes': {AppLanguage.id: 'Rute Populer', AppLanguage.en: 'Popular Routes'},

    // ── Common Actions & Errors ────────────────────────────────────────────
    'btn_save': {AppLanguage.id: 'Simpan', AppLanguage.en: 'Save'},
    'btn_cancel': {AppLanguage.id: 'Batal', AppLanguage.en: 'Cancel'},
    'btn_retry': {AppLanguage.id: 'Coba Lagi', AppLanguage.en: 'Retry'},
    'btn_details': {AppLanguage.id: 'Detail', AppLanguage.en: 'Details'},
    'btn_complete_now': {AppLanguage.id: 'Lengkapi Sekarang', AppLanguage.en: 'Complete Now'},
    'empty_field_title': {AppLanguage.id: 'Field Keberangkatan Kosong', AppLanguage.en: 'Departure Field Empty'},
  };

  /// Ambil teks terjemahan berdasarkan [key]. Jika tidak ada, gunakan fallback [key].
  static String get(String key) {
    final lang = SettingsService.instance.language;
    final item = _localizedValues[key];
    if (item != null && item.containsKey(lang)) {
      return item[lang]!;
    }
    return key;
  }
}
