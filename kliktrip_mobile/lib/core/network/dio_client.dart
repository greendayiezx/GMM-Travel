import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../auth/clerk_auth_service.dart';

class ApiEndpoints {
  // Bisa dioverride saat run tanpa mengedit kode:
  //   flutter run -d chrome --dart-define=API_BASE_URL=https://xxx.trycloudflare.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://gmm-travel-production.up.railway.app/api',
  );

  static const String health = '/health';
  static const String schedules = '/schedules';
  static const String seats = '/travel-schedules/{id}/seats';
  static const String orders = '/orders/detail';
  static const String invoice = '/orders/invoice';
  static const String chargePackage = '/charge';
  static const String mobilePackageCharge = '/mobile/package-charge';
  static const String payments = '/payments';
  static const String paymentStatus = '/payments/{id}/status';
  static const String flightSearch = '/flights/search';
  static const String flightAirports = '/flights/airports';
  static const String flightCalendar = '/flights/calendar';
  static const String flightPriceCheck = '/flights/price-check';
  static const String flightPriceStrip = '/flights/price-strip';
  static const String flightPayments = '/flight-payments';
  static const String flightBookingStatus = '/flight-bookings/{code}/status';
  static const String paymentSimulateSuccess =
      '/payments/{id}/simulate-success';
  static const String paymentNotification = '/payments/notification';
  static const String cities = '/cities';
  static const String tours = '/tours';
  static const String shuttlePopularRoutes = '/shuttle/popular-routes';
  static const String meStats = '/me/stats';
  static const String meLoyalty = '/me/loyalty';
  static const String meBookings = '/me/bookings';
  static const String mePassengers = '/me/passengers';
  static const String mePaymentMethods = '/me/payment-methods';
  static const String meFavorites = '/me/favorites';
  static const String mePromoClaims = '/me/promo-claims';
  static const String meSavedCards = '/me/saved-cards';
  static const String meExportData = '/me/export-data';
  static const String meAccount = '/me/account';
  static const String meNotificationSettings = '/me/notification-settings';
  static const String meNotifications = '/me/notifications';
}

abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await clerkAuth.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';
    super.onRequest(options, handler);
  }
}

/// Cache policy default untuk semua request GET (listing wisata/flight/
/// cities/dll) — TTL 5 menit, in-memory (LRU, hilang saat app restart).
/// POST/PUT/DELETE TIDAK PERNAH di-cache (bawaan package: `allowPostMethod`
/// default false), jadi booking/payment yang selalu POST otomatis aman.
/// Untuk endpoint GET yang harus selalu fresh (status pembayaran/booking),
/// pakai [noCacheOptions] di call site-nya sebagai `options:` override.
final CacheOptions dioCacheOptions = CacheOptions(
  store: MemCacheStore(),
  policy: CachePolicy.request,
  maxStale: const Duration(minutes: 5),
  priority: CachePriority.normal,
);

/// Override per-request: lewati cache, selalu ambil data terbaru dari
/// network. Pakai untuk polling status pembayaran/booking, atau endpoint
/// GET lain yang datanya tidak boleh basi.
Options noCacheOptions() =>
    dioCacheOptions.copyWith(policy: CachePolicy.refresh).toOptions();

class SslPinningInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // HTTP polos ditolak di release build (proteksi produksi dari koneksi
    // tidak terenkripsi). Di debug build (flutter run) HTTP diizinkan supaya
    // testing ke backend lokal (mis. http://127.0.0.1:8000) tetap bisa jalan.
    if (!kDebugMode && options.baseUrl.startsWith('http://')) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'HTTP tidak diizinkan. Gunakan HTTPS.',
          type: DioExceptionType.connectionError,
        ),
      );
      return;
    }
    handler.next(options);
  }
}

class DioClient {
  final Dio dio;

  DioClient._(this.dio);

  static DioClient create({
    // Debug build (flutter run) dikasih timeout lebih longgar — server dev
    // lokal (mis. `php artisan serve`, single-threaded) + DB cloud jarak jauh
    // bisa jauh lebih lambat daripada server production yang sudah di-scale.
    Duration connectTimeout =
        kDebugMode ? const Duration(seconds: 30) : const Duration(seconds: 15),
    Duration receiveTimeout =
        kDebugMode ? const Duration(seconds: 30) : const Duration(seconds: 15),
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: const {'Accept': 'application/json'},
    ));

    dio.interceptors.addAll([
      SslPinningInterceptor(),
      AuthInterceptor(),
      DioCacheInterceptor(options: dioCacheOptions),
    ]);

    return DioClient._(dio);
  }
}
