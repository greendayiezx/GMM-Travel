import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class SavedCard {
  final String id;
  final String maskedCard;
  final String? cardType;
  final String? bank;
  final bool isDefault;

  const SavedCard({
    required this.id,
    required this.maskedCard,
    this.cardType,
    this.bank,
    this.isDefault = false,
  });

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      id: json['id']?.toString() ?? '',
      maskedCard: json['masked_card']?.toString() ?? '',
      cardType: json['card_type']?.toString(),
      bank: json['bank']?.toString(),
      isDefault: json['is_default'] == true || json['is_default'] == 1,
    );
  }
}

class SavedCardRemoteDataSource {
  SavedCardRemoteDataSource([Dio? dio]) : _dio = dio ?? DioClient.create().dio;

  final Dio _dio;

  Future<List<SavedCard>> fetchSavedCards() async {
    final res = await _dio.get(ApiEndpoints.meSavedCards);
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(SavedCard.fromJson)
          .toList();
    }
    return [];
  }

  Future<SavedCard> saveCard({
    required String savedTokenId,
    required String maskedCard,
    String? cardType,
    String? bank,
    bool isDefault = false,
  }) async {
    final res = await _dio.post(ApiEndpoints.meSavedCards, data: {
      'saved_token_id': savedTokenId,
      'masked_card': maskedCard,
      if (cardType != null) 'card_type': cardType,
      if (bank != null) 'bank': bank,
      'is_default': isDefault,
    });
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return SavedCard.fromJson(data);
    }
    throw const ServerFailure('Gagal menyimpan kartu.');
  }

  Future<void> deleteSavedCard(String id) async {
    await _dio.delete('${ApiEndpoints.meSavedCards}/$id');
  }
}
