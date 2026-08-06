import 'package:flutter/material.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/settings/settings_service.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/favorite_button.dart';
import '../../../core/widgets/website_loader.dart';
import '../../booking/data/favorite_remote_data_source.dart';
import '../../home/presentation/pages/home_page.dart';
import '../data/wisata_data_source.dart';
import 'wisata_detail_page.dart';

enum IbadahJenis { haji, umroh }

/// Halaman khusus daftar paket ibadah (Haji / Umroh) dengan sub-tab di atasnya.
/// Dibuka dari kartu kategori "Paket Haji" / "Paket Umroh" di halaman Explore.
class IbadahListingPage extends StatefulWidget {
  const IbadahListingPage({required this.jenis, super.key});

  final IbadahJenis jenis;

  @override
  State<IbadahListingPage> createState() => _IbadahListingPageState();
}

class _IbadahListingPageState extends State<IbadahListingPage> {
  final _wisataSource = WisataDataSource();
  final _favoriteDataSource = FavoriteRemoteDataSource();

  String _tab = 'SEMUA';
  List<WisataPackage> _all = const [];
  Map<String, String> _favoriteIdByItemId = {};
  bool _loading = true;

  IbadahJenis get _jenis => widget.jenis;

  String get _title => _jenis == IbadahJenis.haji ? 'Paket Haji' : 'Paket Umroh';

  String get _subtitle => _jenis == IbadahJenis.haji
      ? 'Raih panggilan ibadah dengan paket haji terbaik'
      : 'Temukan paket umroh terbaik untuk setiap momen';

  IconData get _headerIcon => _jenis == IbadahJenis.haji
      ? Icons.stars_rounded
      : Icons.mosque_rounded;

  static const _tabsHaji = <(String, String)>[
    ('SEMUA', 'Semua'),
    ('REGULER', 'Haji Reguler'),
    ('PLUS', 'Haji Plus'),
    ('KHUSUS', 'Haji Khusus'),
  ];

  static const _tabsUmroh = <(String, String)>[
    ('SEMUA', 'Semua'),
    ('UMROH', 'Paket Umroh'),
    ('ZIARAH', 'Paket Ziarah'),
  ];

  List<(String, String)> get _tabs =>
      _jenis == IbadahJenis.haji ? _tabsHaji : _tabsUmroh;

  bool _isInScope(WisataPackage p) {
    final name = p.namaPaket.toUpperCase();
    if (_jenis == IbadahJenis.haji) {
      return p.kategori == 'IBADAH' && name.contains('HAJI');
    }
    return p.kategori == 'IBADAH' && !name.contains('HAJI');
  }

  String _tabKeyOf(WisataPackage p) {
    final name = p.namaPaket.toUpperCase();
    if (_jenis == IbadahJenis.haji) {
      if (name.contains('KHUSUS')) return 'KHUSUS';
      if (name.contains('FURODA') || name.contains('PLUS')) return 'PLUS';
      return 'REGULER';
    }
    if (name.contains('ZIARAH') ||
        name.contains('HOLYLAND') ||
        name.contains('AQSA')) {
      return 'ZIARAH';
    }
    return 'UMROH';
  }

  @override
  void initState() {
    super.initState();
    _loadPackages();
    _loadFavorites();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _favoriteDataSource.fetchFavorites();
      if (!mounted) return;
      setState(() {
        _favoriteIdByItemId = {
          for (final f in favorites)
            if (f.itemId != null) f.itemId!: f.favoriteId,
        };
      });
    } catch (_) {
      // Biarkan kosong — tombol favorit mulai dari status "belum disimpan".
    }
  }

  Future<void> _loadPackages() async {
    setState(() => _loading = true);
    try {
      final data = await _wisataSource.fetchAll();
      if (mounted) setState(() => _all = data);
    } catch (_) {
      // Backend & asset gagal → biarkan kosong.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<WisataPackage> get _filtered => _all.where((p) {
        if (!_isInScope(p)) return false;
        return _tab == 'SEMUA' || _tabKeyOf(p) == _tab;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final s = Responsive.scale(context);
        final hPadding = Responsive.horizontalPadding(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final scaffoldBg = isDark ? const Color(0xFF121417) : const Color(0xFFFCF9F8);

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            top: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Hero Header
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Container(
                        height: 200 * s + MediaQuery.of(context).padding.top,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/hiu-paus.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                const Color(0xFF00629D).withValues(alpha: 0.5),
                                const Color(0xFFFCF9F8),
                              ],
                              stops: const [0.0, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Floating Back Button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 12,
                        left: 16,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: const CircleBorder(),
                          elevation: 3,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HomePage()),
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.arrow_back,
                                color: Color(0xFF1E9BF0),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: hPadding,
                        right: hPadding,
                        bottom: 24 * s,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _title,
                                  style: TextStyle(
                                    fontFamily: 'Avenir',
                                    fontSize: Responsive.fontSize(context, 28),
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(_headerIcon, color: const Color(0xFFAAEE00), size: 28),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _subtitle,
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 14),
                                color: Colors.white.withValues(alpha: 0.95),
                                shadows: const [
                                  Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Sub-Tab Filter
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
                    child: SizedBox(
                      height: 40 * s,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _tabs.map((tab) {
                          final selected = _tab == tab.$1;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(tab.$2),
                              selected: selected,
                              onSelected: (_) => setState(() => _tab = tab.$1),
                              selectedColor: const Color(0xFF1E9BF0),
                              backgroundColor: isDark ? const Color(0xFF1B1E22) : const Color(0xFFF0EDED),
                              elevation: 0,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : (isDark ? const Color(0xFF9FB3C8) : const Color(0xFF3F4851)),
                                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                fontSize: Responsive.fontSize(context, 12),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                // Package List
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPadding, 12, hPadding, 24),
                  sliver: SliverToBoxAdapter(
                    child: _loading
                        ? const ShimmerLoader(
                            child: Column(
                              children: [
                                WisataItemSkeleton(),
                                WisataItemSkeleton(),
                                WisataItemSkeleton(),
                              ],
                            ),
                          )
                        : _buildPackageList(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPackageList(BuildContext context) {
    final s = Responsive.scale(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final packages = _filtered;

    if (packages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Icons.card_travel_rounded, size: 56, color: Color(0xFFBFC7D3)),
            const SizedBox(height: 12),
            Text(
              'Belum ada paket pada kategori ini',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 15),
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF3F4851),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Silakan coba kategori lain atau kembali lagi nanti.',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 12.5),
                color: const Color(0xFF6F7883),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${packages.length} Paket ${_jenis == IbadahJenis.haji ? 'Haji' : 'Umroh'}',
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 13),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6F7883),
          ),
        ),
        const SizedBox(height: 10),
        ...packages.map((pkg) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isDark ? const Color(0xFF1B1E22) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? const Color(0xFF2E333B) : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WisataDetailPage(
                      pkg: pkg,
                      allPackages: _all,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 100 * s,
                    height: 100 * s,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: _buildThumbnail(pkg.gambar),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: FavoriteButton(
                            itemId: pkg.id,
                            size: 16,
                            initiallyFavorited: _favoriteIdByItemId.containsKey(pkg.id),
                            favoriteId: _favoriteIdByItemId[pkg.id],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pkg.namaPaket,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.fontSize(context, 14),
                              color: isDark ? Colors.white : const Color(0xFF102A43),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pkg.destinasi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 12),
                              color: isDark ? const Color(0xFF9FB3C8) : const Color(0xFF486581),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFFC107)),
                              const SizedBox(width: 3),
                              Text(
                                pkg.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 12),
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF9FB3C8) : const Color(0xFF486581),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF0064D2)),
                              const SizedBox(width: 3),
                              Text(
                                pkg.durasiDisplay,
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 11),
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0064D2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            pkg.hargaDisplay.isEmpty
                                ? _formatPrice(pkg.harga)
                                : pkg.hargaDisplay,
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 15),
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E9BF0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildThumbnail(String pathOrUrl) {
    if (pathOrUrl.startsWith('http')) {
      return AppNetworkImage(
        src: pathOrUrl,
        fit: BoxFit.cover,
        errorIcon: Icons.landscape_outlined,
        iconSize: 28,
      );
    }
    return Image.asset(
      pathOrUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _thumbnailFallback(),
    );
  }

  Widget _thumbnailFallback() {
    return Container(
      color: const Color(0xFFEAF6FF),
      child: const Icon(Icons.landscape_rounded, color: Color(0xFF1E9BF0), size: 32),
    );
  }

  String _formatPrice(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp $buffer';
  }
}
