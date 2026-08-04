import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime? readAt;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.readAt,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class NotificationRemoteDataSource {
  NotificationRemoteDataSource([Dio? dio]) : _dio = dio ?? DioClient.create().dio;

  final Dio _dio;

  Future<List<AppNotification>> fetchAll() async {
    final res = await _dio.get(ApiEndpoints.meNotifications);
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
    }
    return [];
  }

  Future<void> markRead(String id) async {
    await _dio.post('${ApiEndpoints.meNotifications}/$id/read');
  }
}
