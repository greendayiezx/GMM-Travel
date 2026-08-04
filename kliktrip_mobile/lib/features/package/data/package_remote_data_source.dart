import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class TravelScheduleModel {
  final int id;
  final int travelRouteId;
  final String departureTime;
  final double price;
  final int availableSeats;
  final String status;
  final String? departureCity;
  final String? arrivalCity;

  TravelScheduleModel({
    required this.id,
    required this.travelRouteId,
    required this.departureTime,
    required this.price,
    required this.availableSeats,
    required this.status,
    this.departureCity,
    this.arrivalCity,
  });

  factory TravelScheduleModel.fromJson(Map<String, dynamic> json) {
    final route = json['travel_route'] as Map<String, dynamic>?;
    final depCity = route?['departure_city']?['name'] as String?;
    final arrCity = route?['arrival_city']?['name'] as String?;

    return TravelScheduleModel(
      id: json['id'] as int,
      travelRouteId: json['travel_route_id'] as int? ?? 0,
      departureTime: json['departure_time'] as String? ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      availableSeats: json['available_seats'] as int? ?? 0,
      status: json['status'] as String? ?? 'ACTIVE',
      departureCity: depCity,
      arrivalCity: arrCity,
    );
  }
}

abstract class PackageRemoteDataSource {
  Future<List<TravelScheduleModel>> getSchedules();
  Future<Map<String, dynamic>> getSeatAvailability(int scheduleId);
}

class PackageRemoteDataSourceImpl implements PackageRemoteDataSource {
  final DioClient _client;

  PackageRemoteDataSourceImpl(this._client);

  @override
  Future<List<TravelScheduleModel>> getSchedules() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.schedules);
      final List<dynamic> data = response.data;
      return data.map((e) => TravelScheduleModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ServerFailure(
        e.response?.data['message'] ?? 'Gagal mengambil jadwal travel',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getSeatAvailability(int scheduleId) async {
    try {
      final url = ApiEndpoints.seats.replaceAll('{id}', scheduleId.toString());
      final response = await _client.dio.get(url);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerFailure(
        e.response?.data['message'] ?? 'Gagal mengecek ketersediaan kursi',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
