import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/favorite_button.dart';
import '../../../core/widgets/website_loader.dart';
import '../../booking/data/favorite_remote_data_source.dart';
import '../../home/presentation/pages/home_page.dart';
import '../data/wisata_data_source.dart';
import 'bloc/wisata_bloc.dart';
import 'bloc/wisata_event.dart';
import 'bloc/wisata_state.dart';
import 'wisata_detail_page.dart';

import '../../../core/settings/settings_service.dart';

class WisataListingPage extends StatefulWidget {
  const WisataListingPage({this.initialCategory = 'SEMUA', super.key});

  final String initialCategory;

  @override
  State<WisataListingPage> createState() => _WisataListingPageState();
}

class _WisataListingPageState extends State<WisataListingPage> {
  final _searchController = TextEditingController();
  final _favoriteDataSource = FavoriteRemoteDataSource();
  late final WisataBloc _wisataBloc;

  String _category = 'SEMUA';
  String _query = '';
  Map<String, String> _favoriteIdByItemId = {};

  static const _categories = <String, String>{
    'SEMUA': 'Semua',
    'IBADAH': 'Paket Umroh & Haji',
    'INTERNASIONAL': 'Tour Internasional',
    'DOMESTIK': 'Tour Domestik',
    'EVENT': 'Open & Private Trip',
  };

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _wisataBloc = sl<WisataBloc>()..add(const WisataListRequested());
    _loadFavorites();
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

  @override
  void dispose() {
    _searchController.dispose();
    _wisataBloc.close();
    super.dispose();
  }

  List<WisataPackage> _filterPackages(List<WisataPackage> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      final matchCategory = _category == 'SEMUA' || p.kategori == _category;
      final matchQuery = q.isEmpty ||
          p.namaPaket.toLowerCase().contains(q) ||
          p.destinasi.toLowerCase().contains(q);
      return matchCategory && matchQuery;
    }).toList();
  }

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
            // Hero Header Section with hiu-paus.png & Floating Back Button
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
                  // Floating Back Button (Tombol panah balik saja)
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
                              'Wisata',
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
                            const Icon(Icons.card_travel_rounded, color: Color(0xFFAAEE00), size: 28),
                          ],
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 14),
                              color: Colors.white.withValues(alpha: 0.95),
                              shadows: const [
                                Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                              ],
                            ),
                            children: const [
                              TextSpan(text: 'Temukan paket wisata terbaik untuk '),
                              TextSpan(
                                text: 'setiap momen',
                                style: TextStyle(
                                  color: Color(0xFFAAEE00),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar & Filter Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Cari paket, destinasi, atau kota...',
                          hintStyle: TextStyle(
                            fontSize: Responsive.fontSize(context, 13),
                            color: const Color(0xFF6F7883),
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1E9BF0)),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6F7883), size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40 * s,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final e = _categories.entries.elementAt(index);
                          final selected = _category == e.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(e.value),
                              selected: selected,
                              onSelected: (_) => setState(() => _category = e.key),
                              selectedColor: const Color(0xFF1E9BF0),
                              backgroundColor: const Color(0xFFF0EDED),
                              elevation: 0,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : const Color(0xFF3F4851),
                                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                fontSize: Responsive.fontSize(context, 12),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Package List
            SliverPadding(
              padding: EdgeInsets.fromLTRB(hPadding, 12, hPadding, 24),
              sliver: SliverToBoxAdapter(
                child: BlocBuilder<WisataBloc, WisataState>(
                  bloc: _wisataBloc,
                  builder: (context, state) {
                    if (state is WisataListLoaded) {
                      final all =
                          state.packages.map(WisataPackage.fromEntity).toList();
                      return _buildPackageList(context, all);
                    }
                    if (state is WisataError) {
                      return _buildPackageList(context, const []);
                    }
                    return const ShimmerLoader(
                      child: Column(
                        children: [
                          WisataItemSkeleton(),
                          WisataItemSkeleton(),
                          WisataItemSkeleton(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
);
}

  Widget _buildPackageList(BuildContext context, List<WisataPackage> allPackages) {
    final s = Responsive.scale(context);
    final packages = _filterPackages(allPackages);

    if (packages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Icons.card_travel_rounded, size: 56, color: Color(0xFFBFC7D3)),
            const SizedBox(height: 12),
            Text(
              'Paket wisata tidak ditemukan',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 15),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3F4851),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba ubah kata kunci atau kategori pencarian Anda.',
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
          '${packages.length} Paket Wisata',
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 13),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6F7883),
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: packages.length,
          itemBuilder: (context, index) {
            final pkg = packages[index];
            return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
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
                      allPackages: allPackages,
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
                              color: const Color(0xFF102A43),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pkg.destinasi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 12),
                              color: const Color(0xFF486581),
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
                                  color: const Color(0xFF486581),
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
          },
        ),
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
