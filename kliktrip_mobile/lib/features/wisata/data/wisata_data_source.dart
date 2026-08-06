import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/network/dio_client.dart';
import '../domain/entities/wisata_entity.dart';

/// Satu item paket wisata (sama persis dengan data di website).
class WisataPackage {
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
  final List<WisataItinerary> itinerary;
  final List<String> syaratKetentuan;
  final bool isPromo;
  final int? diskonPersen;
  final String? hargaAsli;
  final String? promoBadge;

  const WisataPackage({
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

  /// Harga SEBELUM diskon, dihitung balik dari [harga] (yang sudah diskon)
  /// dan [diskonPersen] — dipakai menampilkan harga normal untuk paket promo
  /// yang belum diklaim user. Kalau bukan promo (atau tanpa diskonPersen),
  /// sama saja dengan [harga].
  int get hargaSebelumDiskon {
    if (!isPromo || diskonPersen == null || diskonPersen! <= 0 || diskonPersen! >= 100) {
      return harga;
    }
    return (harga / (1 - diskonPersen! / 100)).round();
  }

  /// Salinan dengan sebagian field ditimpa — dipakai [WisataDetailPage] untuk
  /// "mengunci" tampilan & jumlah bayar ke harga normal selama promo belum
  /// diklaim user, tanpa mengubah field lain (itinerary, gambar, dst).
  WisataPackage copyWith({int? harga, String? hargaDisplay}) => WisataPackage(
        id: id,
        namaPaket: namaPaket,
        kategori: kategori,
        destinasi: destinasi,
        harga: harga ?? this.harga,
        hargaDisplay: hargaDisplay ?? this.hargaDisplay,
        durasiDisplay: durasiDisplay,
        durasiHari: durasiHari,
        durasiMalam: durasiMalam,
        kuotaSaatIni: kuotaSaatIni,
        kuotaTotal: kuotaTotal,
        deskripsiSingkat: deskripsiSingkat,
        gambar: gambar,
        rating: rating,
        status: status,
        maskapai: maskapai,
        minPeserta: minPeserta,
        tanggalKeberangkatan: tanggalKeberangkatan,
        termasuk: termasuk,
        tidakTermasuk: tidakTermasuk,
        itinerary: itinerary,
        syaratKetentuan: syaratKetentuan,
        isPromo: isPromo,
        diskonPersen: diskonPersen,
        hargaAsli: hargaAsli,
        promoBadge: promoBadge,
      );

  factory WisataPackage.fromJson(Map<String, dynamic> j) {
    List<String> strList(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? const [];

    Map<String, List<String>> tglMap(dynamic v) {
      if (v is! Map) return const {};
      return v.map((k, val) => MapEntry(k.toString(), strList(val)));
    }

    return WisataPackage(
      id: j['id']?.toString() ?? '',
      namaPaket: j['nama_paket']?.toString() ?? '',
      kategori: j['kategori']?.toString() ?? 'DOMESTIK',
      destinasi: j['destinasi']?.toString() ?? '',
      harga: (j['harga'] as num?)?.toInt() ?? 0,
      hargaDisplay: j['harga_display']?.toString() ?? '',
      durasiDisplay: j['durasi_display']?.toString() ?? '',
      durasiHari: (j['durasi_hari'] as num?)?.toInt() ?? 0,
      durasiMalam: (j['durasi_malam'] as num?)?.toInt() ?? 0,
      kuotaSaatIni: (j['kuota_saat_ini'] as num?)?.toInt() ?? 0,
      kuotaTotal: (j['kuota_total'] as num?)?.toInt() ?? 0,
      deskripsiSingkat: j['deskripsi_singkat']?.toString() ?? '',
      gambar: j['gambar']?.toString() ?? '',
      rating: (j['rating'] as num?)?.toDouble() ?? 0,
      status: j['status']?.toString() ?? '',
      maskapai: j['maskapai']?.toString(),
      minPeserta: (j['min_peserta'] as num?)?.toInt(),
      tanggalKeberangkatan: tglMap(j['tanggal_keberangkatan']),
      termasuk: strList(j['termasuk']),
      tidakTermasuk: strList(j['tidak_termasuk']),
      itinerary: (j['itinerary'] as List?)
              ?.map((e) => WisataItinerary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      syaratKetentuan: strList(j['syarat_ketentuan']),
      isPromo: j['is_promo'] == true,
      diskonPersen: (j['diskon_persen'] as num?)?.toInt(),
      hargaAsli: j['harga_asli']?.toString(),
      promoBadge: j['promo_badge']?.toString(),
    );
  }

  /// Konversi ke representasi domain (pure Dart, tanpa dependency JSON).
  WisataEntity toEntity() => WisataEntity(
        id: id,
        namaPaket: namaPaket,
        kategori: kategori,
        destinasi: destinasi,
        harga: harga,
        hargaDisplay: hargaDisplay,
        durasiDisplay: durasiDisplay,
        durasiHari: durasiHari,
        durasiMalam: durasiMalam,
        kuotaSaatIni: kuotaSaatIni,
        kuotaTotal: kuotaTotal,
        deskripsiSingkat: deskripsiSingkat,
        gambar: gambar,
        rating: rating,
        status: status,
        maskapai: maskapai,
        minPeserta: minPeserta,
        tanggalKeberangkatan: tanggalKeberangkatan,
        termasuk: termasuk,
        tidakTermasuk: tidakTermasuk,
        itinerary: itinerary
            .map((i) => WisataItineraryEntity(
                  day: i.day,
                  title: i.title,
                  desc: i.desc,
                ))
            .toList(),
        syaratKetentuan: syaratKetentuan,
        isPromo: isPromo,
        diskonPersen: diskonPersen,
        hargaAsli: hargaAsli,
        promoBadge: promoBadge,
      );

  /// Kebalikan dari [toEntity] — dipakai widget presentation yang masih
  /// mengharapkan `WisataPackage` (mis. `WisataDetailPage`) saat datanya
  /// bersumber dari `WisataBloc` (yang bekerja dengan `WisataEntity`).
  factory WisataPackage.fromEntity(WisataEntity e) => WisataPackage(
        id: e.id,
        namaPaket: e.namaPaket,
        kategori: e.kategori,
        destinasi: e.destinasi,
        harga: e.harga,
        hargaDisplay: e.hargaDisplay,
        durasiDisplay: e.durasiDisplay,
        durasiHari: e.durasiHari,
        durasiMalam: e.durasiMalam,
        kuotaSaatIni: e.kuotaSaatIni,
        kuotaTotal: e.kuotaTotal,
        deskripsiSingkat: e.deskripsiSingkat,
        gambar: e.gambar,
        rating: e.rating,
        status: e.status,
        maskapai: e.maskapai,
        minPeserta: e.minPeserta,
        tanggalKeberangkatan: e.tanggalKeberangkatan,
        termasuk: e.termasuk,
        tidakTermasuk: e.tidakTermasuk,
        itinerary: e.itinerary
            .map((i) => WisataItinerary(day: i.day, title: i.title, desc: i.desc))
            .toList(),
        syaratKetentuan: e.syaratKetentuan,
        isPromo: e.isPromo,
        diskonPersen: e.diskonPersen,
        hargaAsli: e.hargaAsli,
        promoBadge: e.promoBadge,
      );
}

class WisataItinerary {
  final String day;
  final String title;
  final String desc;
  const WisataItinerary({required this.day, required this.title, required this.desc});

  factory WisataItinerary.fromJson(Map<String, dynamic> j) => WisataItinerary(
        day: j['day']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        desc: j['desc']?.toString() ?? '',
      );
}

/// Memuat data wisata dari backend (/tours). Bila backend offline, fallback ke
/// asset lokal `assets/data/wisata.json` supaya app tetap jalan.
class WisataDataSource {
  WisataDataSource({Dio? dio}) : _dio = dio ?? DioClient.create().dio;

  final Dio _dio;

  Future<List<WisataPackage>> fetchAll() async {
    try {
      final res = await _dio.get<dynamic>(ApiEndpoints.tours);
      final data = res.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => WisataPackage.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {
      // Backend offline / gagal → pakai data lokal.
    }
    return _fromAsset();
  }

  Future<List<WisataPackage>> _fromAsset() async {
    final raw = await rootBundle.loadString('assets/data/wisata.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => WisataPackage.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
