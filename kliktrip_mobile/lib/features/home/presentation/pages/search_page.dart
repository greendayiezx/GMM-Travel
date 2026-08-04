import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../wisata/data/wisata_data_source.dart';

/// Halaman pencarian tiket/aktivitas dari search bar di halaman utama.
/// Mengembalikan [WisataPackage] yang dipilih user lewat Navigator.pop,
/// supaya pemanggil (HomePage) bisa mencatatnya sebagai "Pencarian terakhir"
/// lalu membuka halaman detailnya.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.recentPackages = const []});

  /// Pencarian terakhir milik user (dari HomePage) — ditampilkan saat query
  /// masih kosong, menggantikan hint generik.
  final List<WisataPackage> recentPackages;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _dataSource = WisataDataSource();

  List<WisataPackage> _all = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _dataSource.fetchAll();
      if (mounted) setState(() => _all = list);
    } catch (_) {
      if (mounted) setState(() => _all = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<WisataPackage> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _all.where((p) {
      return p.namaPaket.toLowerCase().contains(q) ||
          p.destinasi.toLowerCase().contains(q) ||
          p.kategori.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.azureSky),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari tiket atau aktivitas...',
                    hintStyle: TextStyle(
                      fontSize: Responsive.fontSize(context, 13),
                      color: AppColors.outline,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (_controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    setState(() => _query = '');
                  },
                  child: const Icon(Icons.close_rounded, color: AppColors.outline, size: 18),
                ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _query.trim().isEmpty
              ? _buildRecentOrHint(context, hPadding)
              : _results.isEmpty
                  ? _buildEmpty(context)
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _buildResultTile(context, _results[i]),
                    ),
    );
  }

  Widget _buildRecentOrHint(BuildContext context, double hPadding) {
    if (widget.recentPackages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.travel_explore_rounded, size: 56, color: AppColors.outlineVariant),
              const SizedBox(height: 12),
              Text(
                'Ketik untuk mencari paket wisata, destinasi, atau kategori.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 13),
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12),
      itemCount: widget.recentPackages.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'Pencarian Terakhir',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 13),
                fontWeight: FontWeight.bold,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          );
        }
        return _buildResultTile(context, widget.recentPackages[i - 1]);
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 56, color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'Tidak ditemukan hasil untuk "$_query".',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 13),
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(BuildContext context, WisataPackage pkg) {
    return InkWell(
      onTap: () => Navigator.pop(context, pkg),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            AppNetworkImage(
              src: pkg.gambar,
              width: 64,
              height: 64,
              borderRadius: 12,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pkg.namaPaket,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14),
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pkg.destinasi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pkg.hargaDisplay,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 13),
                      fontWeight: FontWeight.w700,
                      color: AppColors.azureSky,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
