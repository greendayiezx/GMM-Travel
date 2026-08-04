import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

enum BookingCategory { flight, shuttle, wisata }

enum BookingStatusType { pending, success, completed, failed }

class BookingStatus {
  final String raw;
  final String label;
  final BookingStatusType type;

  const BookingStatus({
    required this.raw,
    required this.label,
    required this.type,
  });

  static BookingStatus fromRaw(String? raw) {
    final s = (raw ?? '').toUpperCase();
    switch (s) {
      case 'PENDING':
        return BookingStatus(
          raw: s, label: 'Menunggu Pembayaran', type: BookingStatusType.pending);
      case 'PAID':
      case 'ISSUED':
      case 'CONFIRMED':
        return BookingStatus(
          raw: s, label: 'Berhasil', type: BookingStatusType.success);
      case 'COMPLETED':
      case 'DONE':
      case 'FINISHED':
        return BookingStatus(
          raw: s, label: 'Selesai', type: BookingStatusType.completed);
      case 'CANCELLED':
      case 'CANCELED':
      case 'FAILED':
      case 'EXPIRED':
        return BookingStatus(
          raw: s, label: 'Dibatalkan', type: BookingStatusType.failed);
      default:
        return BookingStatus(
          raw: s, label: s, type: BookingStatusType.pending);
    }
  }
}

class BookingAction {
  final String label;
  final bool primary;
  const BookingAction({required this.label, this.primary = false});
}

class BookingItem {
  final BookingCategory category;
  final String code;
  final String title;
  final BookingStatus status;
  final String date;
  final int price;
  final DateTime? createdAt;

  const BookingItem({
    required this.category,
    required this.code,
    required this.title,
    required this.status,
    required this.date,
    required this.price,
    this.createdAt,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    final category = switch (json['category']?.toString()) {
      'flight' => BookingCategory.flight,
      'shuttle' => BookingCategory.shuttle,
      _ => BookingCategory.wisata,
    };
    return BookingItem(
      category: category,
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: BookingStatus.fromRaw(json['status']?.toString()),
      date: json['date']?.toString() ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  String get dateLabel {
    switch (category) {
      case BookingCategory.flight:
        return 'Keberangkatan';
      case BookingCategory.shuttle:
        return 'Tanggal Perjalanan';
      case BookingCategory.wisata:
        return '';
    }
  }

  String get priceNote => category == BookingCategory.wisata
      ? 'Total Terbayar'
      : 'Harga Total';

  bool get hasTicket => category == BookingCategory.shuttle &&
      (status.type == BookingStatusType.success ||
          status.type == BookingStatusType.completed);

  bool get canPay => status.type == BookingStatusType.pending;

  List<BookingAction> get actions {
    switch (category) {
      case BookingCategory.flight:
        return [
          const BookingAction(label: 'Detail'),
          if (canPay) const BookingAction(label: 'Bayar Sekarang', primary: true),
        ];
      case BookingCategory.shuttle:
        return [const BookingAction(label: 'Detail')];
      case BookingCategory.wisata:
        return [
          const BookingAction(label: 'Detail'),
          if (status.type == BookingStatusType.completed)
            const BookingAction(label: 'Review'),
        ];
    }
  }
}

class BookingRemoteDataSource {
  BookingRemoteDataSource([Dio? dio])
      : _dio = dio ?? DioClient.create().dio;

  final Dio _dio;

  Future<List<BookingItem>> fetchBookings() async {
    final res = await _dio.get(ApiEndpoints.meBookings);
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(BookingItem.fromJson)
          .toList();
    }
    return [];
  }
}
