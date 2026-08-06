/// Satu hari di itinerary paket wisata. Versi pure-Dart dari `WisataItinerary`
/// (lihat `features/wisata/data/wisata_data_source.dart`) — dipakai di layer
/// domain supaya tidak bergantung pada detail parsing JSON di layer data.
class WisataItineraryEntity {
  final String day;
  final String title;
  final String desc;

  const WisataItineraryEntity({
    required this.day,
    required this.title,
    required this.desc,
  });
}

/// Representasi domain dari satu paket wisata — pure Dart, tanpa dependency
/// JSON/Flutter. Versi data (model) yang setara ada di
/// `features/wisata/data/wisata_data_source.dart` sebagai `WisataPackage`,
/// yang punya method `toEntity()` untuk dikonversi ke sini.
class WisataEntity {
  final String id;
  final String namaPaket;
  final String kategori; // IBADAH | INTERNASIONAL | DOMESTIK | EVENT
  final String destinasi;
  final int harga;
  final String hargaDisplay;
  final String durasiDisplay;
  final int durasiHari;
  final int durasiMalam;
  final int kuotaSaatIni;
  final int kuotaTotal;
  final String deskripsiSingkat;
  final String gambar;
  final double rating;
  final String status;
  final String? maskapai;
  final int? minPeserta;
  final Map<String, List<String>> tanggalKeberangkatan;
  final List<String> termasuk;
  final List<String> tidakTermasuk;
  final List<WisataItineraryEntity> itinerary;
  final List<String> syaratKetentuan;
  final bool isPromo;
  final int? diskonPersen;
  final String? hargaAsli;
  final String? promoBadge;

  const WisataEntity({
    required this.id,
    required this.namaPaket,
    required this.kategori,
    required this.destinasi,
    required this.harga,
    required this.hargaDisplay,
    required this.durasiDisplay,
    required this.durasiHari,
    required this.durasiMalam,
    required this.kuotaSaatIni,
    required this.kuotaTotal,
    required this.deskripsiSingkat,
    required this.gambar,
    required this.rating,
    required this.status,
    this.maskapai,
    this.minPeserta,
    this.tanggalKeberangkatan = const {},
    this.termasuk = const [],
    this.tidakTermasuk = const [],
    this.itinerary = const [],
    this.syaratKetentuan = const [],
    this.isPromo = false,
    this.diskonPersen,
    this.hargaAsli,
    this.promoBadge,
  });

  int get sisaKuota => (kuotaTotal - kuotaSaatIni).clamp(0, kuotaTotal);
}
