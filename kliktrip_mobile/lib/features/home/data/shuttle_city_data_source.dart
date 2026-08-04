import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class CityOption {
  const CityOption({
    required this.id,
    required this.name,
    required this.province,
    required this.displayName,
  });

  final String id;
  final String name;
  final String province;
  final String displayName;

  factory CityOption.fromJson(Map<String, dynamic> json) {
    return CityOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
    );
  }
}

const _localCities = <CityOption>[
  CityOption(id: '1', name: 'Manado', province: 'Sulawesi Utara', displayName: 'Manado'),
  CityOption(id: '2', name: 'Kotamobagu', province: 'Sulawesi Utara', displayName: 'Kotamobagu'),
  CityOption(id: '3', name: 'Gorontalo', province: 'Gorontalo', displayName: 'Gorontalo'),
  CityOption(id: '4', name: 'Makassar', province: 'Sulawesi Selatan', displayName: 'Makassar'),
  CityOption(id: '5', name: 'Kendari', province: 'Sulawesi Tenggara', displayName: 'Kendari'),
];

const _popularCities = <CityOption>[
  CityOption(id: '1', name: 'Manado', province: 'Sulawesi Utara', displayName: 'Manado'),
  CityOption(id: '2', name: 'Kotamobagu', province: 'Sulawesi Utara', displayName: 'Kotamobagu'),
  CityOption(id: '3', name: 'Gorontalo', province: 'Gorontalo', displayName: 'Gorontalo'),
  CityOption(id: '4', name: 'Makassar', province: 'Sulawesi Selatan', displayName: 'Makassar'),
  CityOption(id: '5', name: 'Kendari', province: 'Sulawesi Tenggara', displayName: 'Kendari'),
];

class ShuttleCityDataSource {
  ShuttleCityDataSource({Dio? dio})
      : _dio = dio ?? DioClient.create().dio;

  final Dio _dio;

  List<CityOption> getPopularCities() => List.from(_popularCities);

  List<CityOption> getAllCities() => List.from(_localCities);

  Future<List<CityOption>> searchCities(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getPopularCities();

    final results = <CityOption>[];
    final seenNames = <String>{};
    void addUnique(CityOption city) {
      final key = city.name.trim().toLowerCase();
      if (key.isNotEmpty && seenNames.add(key)) {
        results.add(city);
      }
    }

    _localCities
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.province.toLowerCase().contains(q))
        .take(10)
        .forEach(addUnique);

    if (results.length < 3) {
      try {
        final response = await _dio.get<dynamic>(
          ApiEndpoints.cities,
          queryParameters: {'q': query},
        );

        final data = response.data;
        if (data is List) {
          for (final raw in data.whereType<Map>()) {
            addUnique(CityOption.fromJson(Map<String, dynamic>.from(raw)));
          }
        }
      } catch (_) {}
    }

    return results;
  }
}
