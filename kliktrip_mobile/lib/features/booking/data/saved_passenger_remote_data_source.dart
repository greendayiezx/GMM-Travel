import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class SavedPassenger {
  final String id;
  final String title;
  final String fullName;
  final String category;
  final String identityNumber;
  final String? passportNumber;
  final String gender;
  final String birthDate;
  final bool isPrimary;

  const SavedPassenger({
    required this.id,
    required this.title,
    required this.fullName,
    required this.category,
    required this.identityNumber,
    this.passportNumber,
    required this.gender,
    required this.birthDate,
    this.isPrimary = false,
  });

  factory SavedPassenger.fromJson(Map<String, dynamic> json) {
    return SavedPassenger(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Dewasa',
      identityNumber: json['identity_number']?.toString() ?? '',
      passportNumber: json['passport_number']?.toString(),
      gender: json['gender']?.toString() ?? 'Laki-laki',
      birthDate: json['birth_date']?.toString() ?? '',
      isPrimary: json['is_primary'] == true || json['is_primary'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'full_name': fullName,
        'category': category,
        'identity_number': identityNumber,
        if (passportNumber != null && passportNumber!.isNotEmpty)
          'passport_number': passportNumber,
        'gender': gender,
        'birth_date': birthDate,
        'is_primary': isPrimary,
      };
}

class SavedPassengerRemoteDataSource {
  SavedPassengerRemoteDataSource([Dio? dio])
      : _dio = dio ?? DioClient.create().dio;

  final Dio _dio;

  Future<List<SavedPassenger>> fetchPassengers() async {
    final res = await _dio.get(ApiEndpoints.mePassengers);
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(SavedPassenger.fromJson)
          .toList();
    }
    return [];
  }

  Future<SavedPassenger> createPassenger(SavedPassenger passenger) async {
    final res = await _dio.post(ApiEndpoints.mePassengers, data: passenger.toJson());
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return SavedPassenger.fromJson(data);
    }
    throw const ServerFailure('Gagal menyimpan data penumpang.');
  }

  Future<void> deletePassenger(String id) async {
    final url = '${ApiEndpoints.mePassengers}/$id';
    await _dio.delete(url);
  }
}
