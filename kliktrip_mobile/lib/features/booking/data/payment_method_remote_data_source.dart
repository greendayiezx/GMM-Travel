import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class PaymentMethod {
  final String id;
  final String name;
  final String code;
  final String gateway;
  final String? logo;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.code,
    required this.gateway,
    this.logo,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      gateway: json['gateway']?.toString() ?? '',
      logo: json['logo']?.toString(),
    );
  }

  bool get isEwallet =>
      code == 'GOPAY' || code == 'OVO' || code == 'DANA' || code == 'QRIS';

  String get brandLabel {
    if (code == 'BNI_VA') return 'BNI';
    if (code == 'BRI_VA') return 'BRI';
    if (code == 'MANDIRI_VA') return 'Mandiri';
    if (code == 'BCA_VA') return 'BCA';
    return name;
  }
}

class PaymentMethodRemoteDataSource {
  PaymentMethodRemoteDataSource([Dio? dio])
      : _dio = dio ?? DioClient.create().dio;

  final Dio _dio;

  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    final res = await _dio.get(ApiEndpoints.mePaymentMethods);
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PaymentMethod.fromJson)
          .toList();
    }
    return [];
  }
}
