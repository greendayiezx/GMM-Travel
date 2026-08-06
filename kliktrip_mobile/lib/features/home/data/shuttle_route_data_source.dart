import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

/// Satu rute shuttle "populer" — dihitung backend dari jumlah jadwal
/// tersedia per rute (bukan data booking/rating asli, karena belum ada).
class PopularRoute {
  const PopularRoute({
    required this.id,
    required this.departureCity,
    required this.arrivalCity,
    required this.minPrice,
    required this.scheduleCount,
  });

  final String id;
  final String departureCity;
  final String arrivalCity;
  final int? minPrice;
  final int scheduleCount;

  String get routeLabel => '$departureCity - $arrivalCity';

  factory PopularRoute.fromJson(Map<String, dynamic> json) {
    return PopularRoute(
      id: json['id']?.toString() ?? '',
      departureCity: json['departure_city']?.toString() ?? '',
      arrivalCity: json['arrival_city']?.toString() ?? '',
      minPrice: (json['min_price'] as num?)?.toInt(),
      scheduleCount: (json['schedule_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ShuttleRouteDataSource {
  ShuttleRouteDataSource({Dio? dio}) : _dio = dio ?? DioClient.create().dio;

  final Dio _dio;

  Future<List<PopularRoute>> fetchPopularRoutes() async {
    final res = await _dio.get<dynamic>(ApiEndpoints.shuttlePopularRoutes);
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => PopularRoute.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }
}
