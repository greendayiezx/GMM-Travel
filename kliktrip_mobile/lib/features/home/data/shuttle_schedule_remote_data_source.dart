import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class ShuttleSchedule {
  const ShuttleSchedule({
    required this.id,
    required this.departureTime,
    required this.price,
    required this.availableSeats,
    required this.status,
    required this.departureCity,
    required this.arrivalCity,
    this.durationMinutes,
    this.vehicleName,
    this.vehicleType,
    this.seatCapacity,
  });

  final String id;
  final DateTime departureTime;
  final double price;
  final int availableSeats;
  final String status;
  final String departureCity;
  final String arrivalCity;
  final int? durationMinutes;
  final String? vehicleName;
  final String? vehicleType;
  final int? seatCapacity;

  DateTime? get arrivalTime {
    if (durationMinutes == null) return null;
    return departureTime.add(Duration(minutes: durationMinutes!));
  }

  factory ShuttleSchedule.fromJson(Map<String, dynamic> json) {
    final route = _asMap(json['travel_route']);
    final departureCity = _asMap(route['departure_city']);
    final arrivalCity = _asMap(route['arrival_city']);
    final vehicle = _asMap(json['vehicle']);

    return ShuttleSchedule(
      id: json['id']?.toString() ?? '',
      departureTime: DateTime.parse(json['departure_time'].toString()),
      price: _asDouble(json['price']),
      availableSeats: _asInt(json['available_seats']),
      status: json['status']?.toString() ?? '',
      departureCity: departureCity['name']?.toString() ?? '',
      arrivalCity: arrivalCity['name']?.toString() ?? '',
      durationMinutes: route['duration_minutes'] == null
          ? null
          : _asInt(route['duration_minutes']),
      vehicleName: vehicle['name']?.toString(),
      vehicleType: vehicle['type']?.toString(),
      seatCapacity:
          vehicle['capacity'] == null ? null : _asInt(vehicle['capacity']),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    return value is Map<String, dynamic>
        ? value
        : Map<String, dynamic>.from(value as Map? ?? const {});
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ShuttleScheduleRemoteDataSource {
  ShuttleScheduleRemoteDataSource({Dio? dio})
      : _dio = dio ?? DioClient.create().dio;

  final Dio _dio;

  Future<List<ShuttleSchedule>> fetchSchedules({DateTime? date}) async {
    final query = date == null
        ? null
        : <String, dynamic>{
            'date': '${date.year.toString().padLeft(4, '0')}-'
                '${date.month.toString().padLeft(2, '0')}-'
                '${date.day.toString().padLeft(2, '0')}',
          };
    final response =
        await _dio.get<dynamic>(ApiEndpoints.schedules, queryParameters: query);
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Format data jadwal tidak valid.');
    }

    return data
        .whereType<Map>()
        .map((schedule) => ShuttleSchedule.fromJson(
              Map<String, dynamic>.from(schedule),
            ))
        .toList();
  }
}