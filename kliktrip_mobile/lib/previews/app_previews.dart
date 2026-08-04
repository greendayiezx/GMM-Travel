// Widget Previews — lihat setiap halaman langsung di panel IDE (tanpa
// emulator/Android Studio). Jalankan: `flutter widget-preview start`
//
// Halaman yang butuh data (hasil pencarian, jadwal, dsb.) diberi data contoh
// (mock) di bawah supaya bisa dirender berdiri sendiri.
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/booking/presentation/booking_list_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/home/presentation/pages/profile_page.dart';
import '../features/home/presentation/pages/flight_search_page.dart';
import '../features/home/presentation/pages/flight_results_page.dart';
import '../features/home/presentation/pages/flight_booking_details_page.dart';
import '../features/home/presentation/pages/flight_payment_page.dart';
import '../features/home/presentation/pages/shuttle_search_page.dart';
import '../features/home/presentation/pages/shuttle_schedules_page.dart';
import '../features/home/presentation/pages/shuttle_seat_selection_page.dart';
import '../features/home/presentation/pages/shuttle_passenger_details_page.dart';
import '../features/home/data/flight_remote_data_source.dart';
import '../features/home/data/shuttle_schedule_remote_data_source.dart';
import '../features/wisata/presentation/wisata_page.dart';

// Ukuran layar HP standar dipakai di semua preview agar konsisten.
const kPreviewPhoneSize = Size(390, 844);

// ── Halaman tanpa parameter wajib ────────────────────────────────
@Preview(name: 'Login', size: kPreviewPhoneSize)
Widget previewLoginPage() => const LoginPage();

@Preview(name: 'Register', size: kPreviewPhoneSize)
Widget previewRegisterPage() => const RegisterPage();

@Preview(name: 'Home', size: kPreviewPhoneSize)
Widget previewHomePage() => const HomePage();

@Preview(name: 'Profile', size: kPreviewPhoneSize)
Widget previewProfilePage() => const ProfilePage();

@Preview(name: 'Booking List', size: kPreviewPhoneSize)
Widget previewBookingListPage() => const BookingListPage();

@Preview(name: 'Flight Search', size: kPreviewPhoneSize)
Widget previewFlightSearchPage() => const FlightSearchPage();

@Preview(name: 'Shuttle Search', size: kPreviewPhoneSize)
Widget previewShuttleSearchPage() => const ShuttleSearchPage();

@Preview(name: 'Wisata', size: kPreviewPhoneSize)
Widget previewWisataPage() => const WisataPage();

// ── Halaman dengan data contoh (mock) ─────────────────────────────
const _mockFlight = FlightResult(
  id: 'preview-flight-1',
  airline: 'Garuda Indonesia',
  flightNumber: 'GA-402',
  origin: 'CGK',
  destination: 'DPS',
  departureTime: '08:00',
  arrivalTime: '10:45',
  duration: '1h 45m',
  transitCount: 0,
  price: 1250000,
  currency: 'IDR',
  bookingClass: 'Economy',
  bookable: true,
);

@Preview(name: 'Flight Results', size: kPreviewPhoneSize)
Widget previewFlightResultsPage() => const FlightResultsPage(
      params: FlightSearchParams(
        origin: 'CGK',
        destination: 'DPS',
        departureDate: '2026-08-01',
      ),
    );

@Preview(name: 'Flight Booking Details', size: kPreviewPhoneSize)
Widget previewFlightBookingDetailsPage() =>
    const FlightBookingDetailsPage(flight: _mockFlight);

@Preview(name: 'Flight Payment', size: kPreviewPhoneSize)
Widget previewFlightPaymentPage() => const FlightPaymentPage(
      flight: _mockFlight,
      passenger: PassengerData(
        title: 'Mr.',
        fullName: 'Budi Santoso',
        nationality: 'Indonesia',
        idNumber: 'A1234567',
      ),
      basePrice: 1250000,
      insurancePrice: 24.0,
      baggagePrice: 45.0,
      totalPrice: 1250069,
    );

final _mockShuttleSchedule = ShuttleSchedule(
  id: 'preview-shuttle-1',
  departureTime: DateTime(2026, 8, 1, 8, 0),
  price: 150000,
  availableSeats: 12,
  status: 'AVAILABLE',
  departureCity: 'Manado',
  arrivalCity: 'Kotamobagu',
  durationMinutes: 240,
);

@Preview(name: 'Shuttle Schedules', size: kPreviewPhoneSize)
Widget previewShuttleSchedulesPage() => ShuttleSchedulesPage(
      origin: 'Manado',
      destination: 'Kotamobagu',
      date: DateTime(2026, 8, 1),
      passengers: 2,
    );

@Preview(name: 'Shuttle Seat Selection', size: kPreviewPhoneSize)
Widget previewShuttleSeatSelectionPage() => ShuttleSeatSelectionPage(
      schedule: _mockShuttleSchedule,
      formattedPrice: 'Rp150.000',
      origin: 'Manado',
      destination: 'Kotamobagu',
      date: '1 Agustus 2026',
    );

@Preview(name: 'Shuttle Passenger Details', size: kPreviewPhoneSize)
Widget previewShuttlePassengerDetailsPage() => ShuttlePassengerDetailsPage(
      schedule: _mockShuttleSchedule,
      selectedSeat: 'A1',
      formattedPrice: 'Rp150.000',
      origin: 'Manado',
      destination: 'Kotamobagu',
      date: '1 Agustus 2026',
      departureTime: '08:00',
    );
