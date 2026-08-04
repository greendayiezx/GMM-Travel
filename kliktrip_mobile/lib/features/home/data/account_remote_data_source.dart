import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class AccountRemoteDataSource {
  AccountRemoteDataSource([Dio? dio]) : _dio = dio ?? DioClient.create().dio;

  final Dio _dio;

  Future<void> exportData() => _dio.post(ApiEndpoints.meExportData);

  Future<void> deleteAccount() => _dio.delete(ApiEndpoints.meAccount);
}
