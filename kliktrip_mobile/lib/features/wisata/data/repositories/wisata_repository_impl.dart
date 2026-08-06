import 'dart:math';

import '../../domain/entities/wisata_entity.dart';
import '../../domain/repositories/wisata_repository.dart';
import '../wisata_data_source.dart';

/// Implementasi [WisataRepository] yang membungkus [WisataDataSource] yang
/// sudah ada — logic fetch (backend `/tours` dengan fallback ke asset lokal)
/// TIDAK ditulis ulang di sini, cuma dibungkus dan dipetakan ke
/// [WisataEntity].
class WisataRepositoryImpl implements WisataRepository {
  WisataRepositoryImpl(this._dataSource);

  final WisataDataSource _dataSource;
  final _rng = Random();

  @override
  Future<List<WisataEntity>> getWisataList() async {
    final all = await _dataSource.fetchAll();
    return all.map((p) => p.toEntity()).toList();
  }

  @override
  Future<WisataEntity?> getWisataDetail(String id) async {
    final all = await _dataSource.fetchAll();
    for (final p in all) {
      if (p.id == id) return p.toEntity();
    }
    return null;
  }

  @override
  Future<List<WisataEntity>> getTrendingWisata({int count = 4}) async {
    final all = await _dataSource.fetchAll();
    final shuffled = List<WisataPackage>.from(all)..shuffle(_rng);
    return shuffled.take(count).map((p) => p.toEntity()).toList();
  }

  @override
  Future<List<WisataEntity>> getPromoWisata({int count = 5}) async {
    final all = await _dataSource.fetchAll();
    return all
        .where((p) => p.isPromo)
        .take(count)
        .map((p) => p.toEntity())
        .toList();
  }

  @override
  Future<({List<WisataEntity> trending, List<WisataEntity> promos})> getHomeData({
    int trendingCount = 4,
    int promoCount = 5,
  }) async {
    // Satu fetchAll() dibagi buat trending + promo — dulu masing-masing
    // manggil fetchAll() sendiri (2x round-trip network untuk 1 kali buka
    // Home), padahal datanya sama persis.
    final all = await _dataSource.fetchAll();

    final shuffled = List<WisataPackage>.from(all)..shuffle(_rng);
    final trending =
        shuffled.take(trendingCount).map((p) => p.toEntity()).toList();

    final promos = all
        .where((p) => p.isPromo)
        .take(promoCount)
        .map((p) => p.toEntity())
        .toList();

    return (trending: trending, promos: promos);
  }
}
