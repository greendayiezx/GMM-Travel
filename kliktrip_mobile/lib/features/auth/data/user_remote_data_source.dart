import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

/// Statistik profil user yang nyata (bukan dummy) dari backend `/me/stats`.
class UserStats {
  final int trips;
  final int points;
  final int reviews;

  const UserStats({
    required this.trips,
    required this.points,
    required this.reviews,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        trips: (json['trips'] as num?)?.toInt() ?? 0,
        points: (json['points'] as num?)?.toInt() ?? 0,
        reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      );

  static const empty = UserStats(trips: 0, points: 0, reviews: 0);
}

/// Ringkasan tier & progres loyalitas dari backend `/me/loyalty`.
class UserLoyalty {
  final String tier; // 'blue' | 'silver' | 'gold' | 'platinum'
  final String tierLabel;
  final int pointsBalance;
  final int spend12m;
  final String? nextTier;
  final String? nextTierLabel;
  final int? nextTierThreshold;
  final int remainingToNext;
  final int progressPct;

  const UserLoyalty({
    required this.tier,
    required this.tierLabel,
    required this.pointsBalance,
    required this.spend12m,
    required this.nextTier,
    required this.nextTierLabel,
    required this.nextTierThreshold,
    required this.remainingToNext,
    required this.progressPct,
  });

  factory UserLoyalty.fromJson(Map<String, dynamic> json) => UserLoyalty(
        tier: (json['tier'] as String?) ?? 'blue',
        tierLabel: (json['tier_label'] as String?) ?? 'Blue',
        pointsBalance: (json['points_balance'] as num?)?.toInt() ?? 0,
        spend12m: (json['spend_12m'] as num?)?.toInt() ?? 0,
        nextTier: json['next_tier'] as String?,
        nextTierLabel: json['next_tier_label'] as String?,
        nextTierThreshold: (json['next_tier_threshold'] as num?)?.toInt(),
        remainingToNext: (json['remaining_to_next'] as num?)?.toInt() ?? 0,
        progressPct: (json['progress_pct'] as num?)?.toInt() ?? 0,
      );

  bool get isMaxTier => nextTier == null;

  static const empty = UserLoyalty(
    tier: 'blue',
    tierLabel: 'Blue',
    pointsBalance: 0,
    spend12m: 0,
    nextTier: 'silver',
    nextTierLabel: 'Silver',
    nextTierThreshold: 5000000,
    remainingToNext: 5000000,
    progressPct: 0,
  );
}

/// Mengambil data profil user dari backend. Token Clerk disisipkan otomatis
/// oleh AuthInterceptor (via DioClient), lalu diverifikasi backend.
class UserRemoteDataSource {
  UserRemoteDataSource([Dio? dio]) : _dio = dio ?? DioClient.create().dio;

  final Dio _dio;

  Future<UserStats> fetchStats() async {
    final res = await _dio.get(ApiEndpoints.meStats);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return UserStats.fromJson(data);
    }
    return UserStats.empty;
  }

  Future<UserLoyalty> fetchLoyalty() async {
    final res = await _dio.get(ApiEndpoints.meLoyalty);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return UserLoyalty.fromJson(data);
    }
    return UserLoyalty.empty;
  }
}
