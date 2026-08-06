import 'package:flutter/material.dart';
import '../../../wisata/data/wisata_data_source.dart';

/// Satu entri "Pencarian terakhir" di halaman utama. Dulu private
/// (`_RecentSearchItem`) di dalam `home_page.dart` — dipublikkan supaya bisa
/// dipakai `RecentSearchSection` di file terpisah.
class RecentSearchItem {
  final String title;
  final String category;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final WisataPackage? package;

  const RecentSearchItem({
    required this.title,
    required this.category,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.package,
  });
}
