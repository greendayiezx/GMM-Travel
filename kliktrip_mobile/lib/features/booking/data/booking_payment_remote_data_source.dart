import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class PaymentChargeRequest {
  final int scheduleId;
  final int totalSeats;
  final double amount;
  final String customerName;
  final String customerEmail;
  final String customerPhone;

  PaymentChargeRequest({
    required this.scheduleId,
    required this.totalSeats,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
  });

  Map<String, dynamic> toJson() => {
    'schedule_id': scheduleId,
    'total_seats': totalSeats,
    'amount': amount,
    'customer_name': customerName,
    'customer_email': customerEmail,
    'customer_phone': customerPhone,
  };
}

class PaymentResponseModel {
  final String transactionId;
  final String status;
  final String redirectUrl;

  PaymentResponseModel({
    required this.transactionId,
    required this.status,
    required this.redirectUrl,
  });

  factory PaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentResponseModel(
      transactionId: json['transaction_id']?.toString() ?? json['id']?.toString() ?? '',
      status: json['status'] as String? ?? 'PENDING',
      redirectUrl: json['redirect_url'] as String? ?? json['payment_url'] as String? ?? '',
    );
  }
}

abstract class BookingPaymentRemoteDataSource {
  Future<PaymentResponseModel> createPackageCharge(PaymentChargeRequest request);
  Future<Map<String, dynamic>> checkPaymentStatus(String paymentId);
}

class BookingPaymentRemoteDataSourceImpl implements BookingPaymentRemoteDataSource {
  final DioClient _client;

  BookingPaymentRemoteDataSourceImpl(this._client);

  @override
  Future<PaymentResponseModel> createPackageCharge(PaymentChargeRequest request) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.chargePackage,
        data: request.toJson(),
      );
      return PaymentResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerFailure(
        e.response?.data['message'] ?? 'Gagal membuat transaksi pembayaran paket',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    try {
      final url = ApiEndpoints.paymentStatus.replaceAll('{id}', paymentId);
      final response = await _client.dio.get(url);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerFailure(
        e.response?.data['message'] ?? 'Gagal mengecek status pembayaran',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
