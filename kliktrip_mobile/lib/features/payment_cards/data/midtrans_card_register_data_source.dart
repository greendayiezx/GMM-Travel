import 'package:dio/dio.dart';
import '../../../core/config/midtrans_config.dart';
import '../../../core/network/dio_client.dart';

class MidtransCardRegisterResult {
  final String savedTokenId;
  final String maskedCard;

  const MidtransCardRegisterResult({
    required this.savedTokenId,
    required this.maskedCard,
  });
}

/// Mendaftarkan kartu LANGSUNG ke Midtrans dari device (bukan lewat backend
/// kita) memakai client_key publik. Nomor kartu mentah tidak pernah menyentuh
/// server kita — hanya saved_token_id + masked_card hasil tokenisasi yang
/// dikirim ke backend (lihat SavedCardRemoteDataSource).
///
/// Sengaja memakai Dio() polos, BUKAN DioClient.create(): instance itu
/// terkonfigurasi untuk host API kita sendiri dan otomatis menyisipkan
/// Authorization Bearer token Clerk lewat AuthInterceptor — keduanya salah
/// dan berbahaya kalau terbawa ke request ke Midtrans.
class MidtransCardRegisterDataSource {
  MidtransCardRegisterDataSource([Dio? dio]) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<MidtransCardRegisterResult> registerCard({
    required String cardNumber,
    required String expMonth,
    required String expYear,
  }) async {
    final res = await _dio.get(
      '${MidtransConfig.cardRegisterBaseUrl}/v2/card/register',
      queryParameters: {
        'card_number': cardNumber,
        'card_exp_month': expMonth,
        'card_exp_year': expYear,
        'client_key': MidtransConfig.clientKey,
      },
    );

    final data = res.data;
    if (data is Map && data['status_code']?.toString() == '200') {
      final savedTokenId = data['saved_token_id']?.toString() ?? '';
      final maskedCard = data['masked_card']?.toString() ?? '';
      if (savedTokenId.isEmpty || maskedCard.isEmpty) {
        throw const ServerFailure('Respons Midtrans tidak lengkap.');
      }
      return MidtransCardRegisterResult(
        savedTokenId: savedTokenId,
        maskedCard: maskedCard,
      );
    }

    final message = data is Map
        ? (data['status_message']?.toString() ?? 'Gagal mendaftarkan kartu.')
        : 'Gagal mendaftarkan kartu.';
    throw ServerFailure(message);
  }
}
