import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

/// Status klaim promo per user — dipakai [WisataDetailPage] menentukan
/// apakah harga diskon untuk paket promo tertentu sudah "terbuka" untuk
/// user yang sedang login.
class PromoClaimDataSource {
  PromoClaimDataSource({Dio? dio}) : _dio = dio ?? DioClient.create().dio;

  final Dio _dio;

  /// item_id (WisataPackage.id) paket-paket promo yang sudah diklaim user.
  Future<Set<String>> fetchClaimedItemIds() async {
    // Status klaim berubah tiap user tap "Klaim" — jangan sampai kena cache
    // GET 5 menit dan menampilkan status lama.
    final res = await _dio.get<dynamic>(
      ApiEndpoints.mePromoClaims,
      options: noCacheOptions(),
    );
    final data = res.data;
    if (data is List) {
      return data.map((e) => e.toString()).toSet();
    }
    return {};
  }

  Future<void> claimPromo(String itemId) async {
    await _dio.post<dynamic>(
      ApiEndpoints.mePromoClaims,
      data: {'item_id': itemId},
    );
  }
}
