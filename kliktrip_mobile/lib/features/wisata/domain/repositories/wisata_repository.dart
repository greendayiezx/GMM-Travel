import '../entities/wisata_entity.dart';

/// Kontrak akses data wisata untuk layer domain/presentation. Implementasinya
/// (`WisataRepositoryImpl`, di layer data) membungkus `WisataDataSource` yang
/// sudah ada — logic fetch aslinya tidak diubah.
abstract class WisataRepository {
  /// Seluruh paket wisata (dipakai halaman listing/pencarian).
  Future<List<WisataEntity>> getWisataList();

  /// Satu paket wisata berdasarkan id, atau `null` kalau tidak ditemukan.
  Future<WisataEntity?> getWisataDetail(String id);

  /// Subset acak untuk section "Jelajahi Destinasi" di halaman utama.
  Future<List<WisataEntity>> getTrendingWisata({int count = 4});

  /// Paket-paket yang sedang promo untuk section "Promo Menarik".
  Future<List<WisataEntity>> getPromoWisata({int count = 5});

  /// Trending + promo sekaligus dalam SATU fetch (dipakai halaman utama) —
  /// menghindari 2x round-trip network untuk data yang sama.
  Future<({List<WisataEntity> trending, List<WisataEntity> promos})> getHomeData({
    int trendingCount = 4,
    int promoCount = 5,
  });
}
