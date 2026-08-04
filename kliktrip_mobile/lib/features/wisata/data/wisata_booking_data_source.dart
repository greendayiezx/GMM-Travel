import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

/// Fasilitas tambahan opsional (seperti add-on di website).
class ExtraFacility {
  final String id;
  final String title;
  final String subtitle;
  final int price;
  final String icon; // nama Material icon
  const ExtraFacility({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.icon,
  });
}

/// Daftar fasilitas opsional standar (mengikuti kategori add-on di website).
const kExtraFacilities = <ExtraFacility>[
  ExtraFacility(
    id: 'asuransi',
    title: 'Asuransi Perjalanan Premium',
    subtitle: 'Perlindungan menyeluruh selama perjalanan',
    price: 150000,
    icon: 'health_and_safety',
  ),
  ExtraFacility(
    id: 'lounge',
    title: 'Airport Lounge Access',
    subtitle: 'Akses lounge bandara sebelum keberangkatan',
    price: 250000,
    icon: 'weekend',
  ),
  ExtraFacility(
    id: 'optional_tour',
    title: 'Optional Tour Tambahan',
    subtitle: 'Destinasi wisata ekstra di luar itinerary',
    price: 500000,
    icon: 'tour',
  ),
  ExtraFacility(
    id: 'transfer',
    title: 'Airport Transfer (Antar-Jemput)',
    subtitle: 'Penjemputan pribadi dari & ke bandara',
    price: 200000,
    icon: 'airport_shuttle',
  ),
  ExtraFacility(
    id: 'bagasi',
    title: 'Handling Bagasi',
    subtitle: 'Bantuan bawa & urus bagasi Anda',
    price: 100000,
    icon: 'luggage',
  ),
];

/// Data pemesan + rincian yang dikirim ke backend.
class WisataChargeRequest {
  final String orderId;
  final int amount;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String packageName;
  final List<Map<String, dynamic>> items;
  final String paymentMethod;

  const WisataChargeRequest({
    required this.orderId,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.packageName,
    required this.items,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'amount': amount,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'packageName': packageName,
        'items': items,
        'paymentMethod': paymentMethod,
      };
}

/// Hasil charge (instruksi pembayaran Midtrans).
class WisataChargeResult {
  final bool success;
  final String orderCode;
  final String paymentType;
  final Map<String, dynamic> instructions;
  final bool sandbox;
  final DateTime? expiredAt;

  const WisataChargeResult({
    required this.success,
    required this.orderCode,
    required this.paymentType,
    required this.instructions,
    required this.sandbox,
    this.expiredAt,
  });

  String? get vaNumber =>
      instructions['va_number']?.toString() ?? instructions['bill_key']?.toString();
  String? get bank => instructions['bank']?.toString();
  String? get qrString =>
      instructions['qr_string']?.toString() ?? instructions['qr_code']?.toString();

  factory WisataChargeResult.fromJson(Map<String, dynamic> j) => WisataChargeResult(
        success: j['success'] == true,
        orderCode: j['order_code']?.toString() ?? '',
        paymentType: j['payment_type']?.toString() ?? '',
        instructions: (j['instructions'] as Map?)?.cast<String, dynamic>() ?? const {},
        sandbox: j['sandbox'] == true,
        expiredAt: DateTime.tryParse(j['expired_at']?.toString() ?? ''),
      );
}

class WisataBookingDataSource {
  WisataBookingDataSource({Dio? dio})
      : _dio = dio ?? DioClient.create(connectTimeout: const Duration(seconds: 20), receiveTimeout: const Duration(seconds: 30)).dio;

  final Dio _dio;

  Future<WisataChargeResult> charge(WisataChargeRequest req) async {
    final res = await _dio.post<dynamic>(
      ApiEndpoints.mobilePackageCharge,
      data: req.toJson(),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return WisataChargeResult.fromJson(data);
    }
    throw Exception('Respons pembayaran tidak valid.');
  }
}
