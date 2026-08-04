import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

/// Preferensi notifikasi user dari backend `/me/notification-settings`.
class NotificationPreference {
  const NotificationPreference({
    required this.pushNotifications,
    required this.emailPromos,
    required this.orderUpdates,
  });

  final bool pushNotifications;
  final bool emailPromos;
  final bool orderUpdates;

  factory NotificationPreference.fromJson(Map<String, dynamic> json) =>
      NotificationPreference(
        pushNotifications: (json['push_notifications'] as bool?) ?? true,
        emailPromos: (json['email_promos'] as bool?) ?? false,
        orderUpdates: (json['order_updates'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {
        'push_notifications': pushNotifications,
        'email_promos': emailPromos,
        'order_updates': orderUpdates,
      };
}

/// Baca & tulis preferensi notifikasi di server. Token Clerk disisipkan
/// otomatis oleh AuthInterceptor (via DioClient).
class NotificationPreferenceRemoteDataSource {
  NotificationPreferenceRemoteDataSource([Dio? dio])
      : _dio = dio ?? DioClient.create().dio;

  final Dio _dio;

  Future<NotificationPreference> fetch() async {
    final res = await _dio.get(ApiEndpoints.meNotificationSettings);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return NotificationPreference.fromJson(data);
    }
    return const NotificationPreference(
      pushNotifications: true,
      emailPromos: false,
      orderUpdates: true,
    );
  }

  Future<void> update(NotificationPreference pref) async {
    await _dio.put(
      ApiEndpoints.meNotificationSettings,
      data: pref.toJson(),
    );
  }
}
