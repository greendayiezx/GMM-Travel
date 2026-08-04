import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

enum SavedItemType { wisata, shuttle, flight, generic }

class SavedItem {
  final String favoriteId;
  final SavedItemType type;
  // Id item asli (mis. WisataPackage.id) — dipakai mencocokkan status
  // favorit ke kartu produk yang sedang ditampilkan. Null untuk tipe yang
  // belum mendukung item_id (shuttle/flight/generic).
  final String? itemId;
  final String title;
  final String subtitle;
  final String? image;
  final double? rating;
  final String? price;
  final String? priceSub;

  const SavedItem({
    required this.favoriteId,
    required this.type,
    this.itemId,
    required this.title,
    required this.subtitle,
    this.image,
    this.rating,
    this.price,
    this.priceSub,
  });

  factory SavedItem.fromJson(Map<String, dynamic> json) {
    final type = switch (json['type']?.toString()) {
      'wisata' => SavedItemType.wisata,
      'shuttle' => SavedItemType.shuttle,
      'flight' => SavedItemType.flight,
      _ => SavedItemType.generic,
    };
    return SavedItem(
      favoriteId: json['favorite_id']?.toString() ?? '',
      type: type,
      itemId: json['item_id']?.toString(),
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      image: json['image']?.toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      price: json['price']?.toString(),
      priceSub: json['price_sub']?.toString(),
    );
  }
}

class FavoriteRemoteDataSource {
  FavoriteRemoteDataSource([Dio? dio])
      : _dio = dio ?? DioClient.create().dio;

  final Dio _dio;

  Future<List<SavedItem>> fetchFavorites() async {
    final res = await _dio.get(ApiEndpoints.meFavorites);
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(SavedItem.fromJson)
          .toList();
    }
    return [];
  }

  Future<SavedItem> addFavorite({required String type, required String itemId}) async {
    final res = await _dio.post(ApiEndpoints.meFavorites, data: {
      'type': type,
      'item_id': itemId,
    });
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return SavedItem.fromJson(data);
    }
    throw const ServerFailure('Gagal menyimpan favorit.');
  }

  Future<void> removeFavorite(String favoriteId) async {
    await _dio.delete('${ApiEndpoints.meFavorites}/$favoriteId');
  }
}
