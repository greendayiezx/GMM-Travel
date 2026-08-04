import 'package:dio/dio.dart';

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
  static const String meStats = '/me/stats';
  static const String meLoyalty = '/me/loyalty';
  static const String meBookings = '/me/bookings';
  static const String mePassengers = '/me/passengers';
  static const String mePaymentMethods = '/me/payment-methods';
  static const String meFavorites = '/me/favorites';
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

class SslPinningInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.baseUrl.startsWith('http://')) {
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
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
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
    ]);

    return DioClient._(dio);
  }
}
