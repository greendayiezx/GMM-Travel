import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/airline_logo.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../../../../core/widgets/favorite_button.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/website_loader.dart';
import '../../../booking/data/favorite_remote_data_source.dart';
import '../../../booking/presentation/booking_list_page.dart';
import '../../../wisata/data/wisata_data_source.dart';
import '../../data/notification_remote_data_source.dart';
import 'flight_search_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';
import 'saved_page.dart';
import 'search_page.dart';
import 'shuttle_search_page.dart';
import '../../../wisata/presentation/wisata_page.dart';
import '../../../wisata/presentation/wisata_detail_page.dart';
import '../../../wisata/presentation/wisata_listing_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Wisata', 'Pesawat', 'Sewa Mobil'];
  bool _isRefreshing = false;
  bool _isPageLoading = true;
  final _wisataSource = WisataDataSource();
  final _favoriteDataSource = FavoriteRemoteDataSource();
  final _notificationDataSource = NotificationRemoteDataSource();
  List<WisataPackage> _trendingWisata = [];
  List<WisataPackage> _promos = [];
  // itemId (WisataPackage.id) -> favoriteId, dipakai FavoriteButton tahu
  // status awal tanpa tiap kartu fetch sendiri-sendiri.
  Map<String, String> _favoriteIdByItemId = {};
  bool _hasUnreadNotifications = false;
  final _rng = Random();

  List<_RecentSearchItem> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _initHomePage();
  }

  Future<void> _initHomePage() async {
    await Future.wait([
      _loadTrendingWisata(),
      _loadFavorites(),
      _loadNotificationStatus(),
    ]);
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _isPageLoading = false);
    }
  }

  Future<void> _loadTrendingWisata() async {
    try {
      final all = await _wisataSource.fetchAll();
      final shuffled = List<WisataPackage>.from(all);
      shuffled.shuffle(_rng);
      final picked = shuffled.take(4).toList();
      final promos = all.where((p) => p.isPromo).take(5).toList();
      if (mounted) {
        setState(() {
          _trendingWisata = picked;
          _promos = promos;
        });
      }
    } catch (_) {
    }
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
      // Biarkan kosong — tombol favorit akan mulai dari status "belum disimpan".
    }
  }

  Future<void> _loadNotificationStatus() async {
    try {
      final list = await _notificationDataSource.fetchAll();
      if (!mounted) return;
      setState(() {
        _hasUnreadNotifications = list.any((n) => n.readAt == null);
      });
    } catch (_) {
      // Biarkan false — bell tidak menampilkan badge kalau gagal fetch.
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Halaman diperbarui')),
      );
    }
  }

  void _clearRecentSearches() {
    if (_recentSearches.isEmpty) return;
    setState(() => _recentSearches = []);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pencarian terakhir telah dihapus')),
    );
  }

  Future<void> _openSearch() async {
    final selected = await Navigator.push<WisataPackage>(
      context,
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
    if (selected == null || !mounted) return;
    _openWisataResult(selected);
  }

  void _openWisataResult(WisataPackage pkg) {
    setState(() {
      _recentSearches.removeWhere((item) => item.package?.id == pkg.id);
      _recentSearches.insert(
        0,
        _RecentSearchItem(
          title: pkg.namaPaket,
          category: 'Wisata • ${pkg.destinasi}',
          icon: Icons.travel_explore_rounded,
          iconBg: AppColors.azureSky.withValues(alpha: 0.1),
          iconColor: AppColors.azureSky,
          package: pkg,
        ),
      );
      if (_recentSearches.length > 8) {
        _recentSearches = _recentSearches.sublist(0, 8);
      }
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WisataDetailPage(pkg: pkg)),
    );
  }

  Widget _buildWisataThumbnail(String pathOrUrl) {
    final s = Responsive.scale(context);
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return AppNetworkImage(
        src: pathOrUrl,
        width: 90 * s,
        height: 90 * s,
        fit: BoxFit.cover,
        errorIcon: Icons.landscape_outlined,
        iconSize: 28,
      );
    } else if (pathOrUrl.startsWith('assets/images/')) {
      // Hanya muat aset yang benar-benar di-bundle. Path lokal lain (mis. poster
      // milik web) tidak ada di app → tampilkan fallback tanpa fetch (hindari 404).
      return Image.asset(
        pathOrUrl,
        width: 90 * s,
        height: 90 * s,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(),
      );
    }
    return _buildFallbackThumbnail();
  }

  Widget _buildFallbackThumbnail() {
    final s = Responsive.scale(context);
    return Container(
      width: 90 * s,
      height: 90 * s,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0064D2), Color(0xFF1E9BF0)],
        ),
      ),
      child: Center(
        child: Icon(Icons.explore, color: Colors.white70, size: Responsive.iconSize(context, 32)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final s = Responsive.scale(context);
    final hPadding = Responsive.horizontalPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121417) : const Color(0xFFF3F6FA);

    return Scaffold(
      backgroundColor: scaffoldBg,
      bottomNavigationBar: BottomNav(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 0) {
            // Beranda
          } else if (index == 1) {
            // Booking
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookingListPage()),
            );
          } else if (index == 2) {
            // Explore
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WisataPage()),
            );
          } else if (index == 3) {
            // Favorit / Saved
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedPage()),
            );
          } else if (index == 4) {
            // Akun
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
      ),
      body: WebsiteRouteLoader(
        isLoading: _isPageLoading,
        text: 'Memuat halaman…',
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero background + floating menu, stacked so the forest
                    // image fills the whole area down to "Pencarian terakhir".
                    Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(
                                  'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=1200',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF0064D2)
                                        .withValues(alpha: 0.92),
                                    const Color(0xFF0064D2)
                                        .withValues(alpha: 0.28),
                                    const Color(0xFFF3F6FA)
                                        .withValues(alpha: 0.55),
                                    const Color(0xFFF3F6FA),
                                  ],
                                  stops: const [0.0, 0.32, 0.8, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: hPadding),
                          child: Column(
                            children: [
                              SizedBox(height: topPadding + 60 + 96 * s),
                              Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1B1E22) : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: isDark ? Border.all(color: const Color(0xFF2E333B)) : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _build3DServiceCard(
                                        title: AppLocalizations.get('home_pesawat'),
                                        iconType: _Icon3DType.flight,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const FlightSearchPage(),
                                            ),
                                          );
                                        },
                                      ),
                                      _build3DServiceCard(
                                        title: AppLocalizations.get('home_wisata'),
                                        iconType: _Icon3DType.wisata,
                                        badgeText: 'B1G1',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const WisataListingPage(),
                                            ),
                                          );
                                        },
                                      ),
                                      _build3DServiceCard(
                                        title: AppLocalizations.get('home_shuttle'),
                                        iconType: _Icon3DType.airportShuttle,
                                        badgeText: '-25%',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const ShuttleSearchPage(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  Divider(
                                    height: 1,
                                    thickness: 0.6,
                                    color: isDark ? const Color(0xFF2E333B) : const Color(0xFFEEF2F6),
                                  ),
                                  const SizedBox(height: 14),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _build3DServiceCardCompact(
                                        title: AppLocalizations.get('home_villa'),
                                        iconType: _Icon3DType.villa,
                                        badgeText: '-40%',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ServicePage(
                                                title: AppLocalizations.get('home_villa'),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      _build3DServiceCardCompact(
                                        title: AppLocalizations.get('home_whoosh'),
                                        iconType: _Icon3DType.whoosh,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ServicePage(
                                                title: AppLocalizations.get('home_whoosh'),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      _build3DServiceCardCompact(
                                        title: AppLocalizations.get('home_car_rental'),
                                        iconType: _Icon3DType.carRental,
                                        badgeText: '-50%',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ServicePage(
                                                title: AppLocalizations.get('home_car_rental'),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 32 * s,
                                    height: 32 * s,
                                    child: SvgPicture.asset(
                                      'assets/images/icon_search_history.svg',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Pencarian terakhir',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 18),
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF102A43),
                                    ),
                                  ),
                                ],
                              ),
                              if (_recentSearches.isNotEmpty)
                                GestureDetector(
                                  onTap: _clearRecentSearches,
                                  child: Text(
                                    'Hapus',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 14),
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0064D2),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          if (_recentSearches.isEmpty)
                            _buildRecentEmptyState()
                          else ...[
                            Row(
                              children: List.generate(_filters.length, (index) {
                                final isSelected =
                                    _selectedFilterIndex == index;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(_filters[index]),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFFEBF3FF),
                                    backgroundColor: Colors.white,
                                    elevation: 0,
                                    pressElevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF0064D2)
                                          : const Color(0xFF486581),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: Responsive.fontSize(context, 13),
                                    ),
                                    side: BorderSide(
                                      color: isSelected
                                          ? const Color(0xFF0064D2)
                                          : const Color(0xFFD9E2EC),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                    onSelected: (val) {
                                      setState(() {
                                        _selectedFilterIndex = index;
                                      });
                                    },
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 82 * s,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _recentSearches.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (_, i) => _buildRecentSearchItemCard(
                                  _recentSearches[i],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 32 * s,
                                    height: 32 * s,
                                    child: SvgPicture.asset(
                                      'assets/images/icon_promo_discount.svg',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Promo Menarik',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 18),
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF102A43),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Lihat Semua',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 13),
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0064D2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 160 * s,
                            child: _promos.isEmpty
                                ? Center(
                                    child: Text(
                                      'Belum ada promo saat ini.',
                                      style: TextStyle(
                                        fontSize: Responsive.fontSize(context, 13),
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _promos.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                                    itemBuilder: (_, i) {
                                      final promo = _promos[i];
                                      final (badgeBg, badgeFg) = _promoBadgeColors(promo.promoBadge);
                                      return _buildPromoCard(
                                        imageUrl: promo.gambar,
                                        badgeText: promo.promoBadge ?? 'PROMO',
                                        badgeColor: badgeBg,
                                        badgeTextColor: badgeFg,
                                        title: promo.namaPaket,
                                        subtitle: promo.diskonPersen != null
                                            ? 'Diskon ${promo.diskonPersen}% — ${promo.hargaDisplay}'
                                            : promo.hargaDisplay,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => WisataDetailPage(pkg: promo),
                                          ),
                                        ),
                                        favoriteButton: FavoriteButton(
                                          itemId: promo.id,
                                          initiallyFavorited: _favoriteIdByItemId.containsKey(promo.id),
                                          favoriteId: _favoriteIdByItemId[promo.id],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 32 * s,
                                    height: 32 * s,
                                    child: SvgPicture.asset(
                                      'assets/images/icon_airline_popular.svg',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Maskapai Populer',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 18),
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF102A43),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const FlightSearchPage()),
                                  );
                                },
                                child: Text(
                                  'Cari Tiket',
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 13),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0064D2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 104 * s,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: const [
                                _PopularAirlineCard(
                                    name: 'Garuda Indonesia',
                                    code: 'GA',
                                    tag: 'Bintang 5'),
                                SizedBox(width: 10),
                                _PopularAirlineCard(
                                    name: 'Lion Air', code: 'JT', tag: 'Populer'),
                                SizedBox(width: 10),
                                _PopularAirlineCard(
                                    name: 'Batik Air', code: 'ID', tag: 'Premium'),
                                SizedBox(width: 10),
                                _PopularAirlineCard(
                                    name: 'Citilink',
                                    code: 'QG',
                                    tag: 'LCC Terbaik'),
                                SizedBox(width: 10),
                                _PopularAirlineCard(
                                    name: 'AirAsia', code: 'AK', tag: 'Hemat'),
                                SizedBox(width: 10),
                                _PopularAirlineCard(
                                    name: 'Super Air Jet',
                                    code: 'IU',
                                    tag: 'Kekinian'),
                                SizedBox(width: 10),
                                _PopularAirlineCard(
                                    name: 'Singapore Airlines',
                                    code: 'SQ',
                                    tag: 'Internasional'),
                                SizedBox(width: 10),
                                _PopularAirlineCard(
                                    name: 'Qatar Airways',
                                    code: 'QR',
                                    tag: 'Mewah'),
                                SizedBox(width: 10),
                                _PopularAirlineCard(
                                    name: 'Emirates', code: 'EK', tag: 'Global'),
                                SizedBox(width: 10),
                                _PopularAirlineCard(
                                    name: 'TransNusa',
                                    code: '8B',
                                    tag: 'Regional'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 34 * s,
                                    height: 34 * s,
                                    child: SvgPicture.asset(
                                      'assets/images/icon_jelajahi_destinasi.svg',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Jelajahi Destinasi',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 18),
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF102A43),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const WisataPage(),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      'Lihat Semua',
                                      style: TextStyle(
                                        fontSize: Responsive.fontSize(context, 13),
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0064D2),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        size: 18, color: Color(0xFF0064D2)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_trendingWisata.isEmpty)
                            const ShimmerLoader(
                              child: Column(
                                children: [
                                  WisataItemSkeleton(),
                                  WisataItemSkeleton(),
                                  WisataItemSkeleton(),
                                ],
                              ),
                            ),

                          ..._trendingWisata.map((pkg) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                    color: Color(0xFFE2E8F0), width: 0.8),
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
                                        allPackages: null,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 90 * s,
                                      height: 90 * s,
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          bottomLeft: Radius.circular(16),
                                        ),
                                        child: _buildWisataThumbnail(pkg.gambar),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                            Row(
                                              children: [
                                                const Icon(Icons.star_rounded,
                                                    size: 15,
                                                    color: Color(0xFFFFC107)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${pkg.rating}',
                                                  style: TextStyle(
                                                    fontSize: Responsive.fontSize(context, 12),
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF486581),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
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
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FavoriteButton(
                                        itemId: pkg.id,
                                        initiallyFavorited:
                                            _favoriteIdByItemId.containsKey(pkg.id),
                                        favoriteId: _favoriteIdByItemId[pkg.id],
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(right: 12),
                                      child: Icon(Icons.chevron_right,
                                          color: Color(0xFF9FB3C8)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: topPadding + 6,
                  left: 14,
                  right: 14,
                  bottom: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0064D2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _openSearch,
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/gmm-tour-logo.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFD600),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Cari tiket atau aktivitas...',
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 13),
                                    color: const Color(0xFF829AB1),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),

                  const SizedBox(width: 8),

                  // 1. Lonceng Notifikasi
                  _buildHeaderActionButton(
                    icon: Icons.notifications_none_rounded,
                    hasRedBadge: _hasUnreadNotifications,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsPage()),
                      );
                      _loadNotificationStatus();
                    },
                  ),

                  const SizedBox(width: 8),

                  // 2. Foto Profile Avatar
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfilePage(),
                        ),
                      );
                    },
                    child: Container(
                      width: 38 * s,
                      height: 38 * s,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: UserAvatar(
                          size: 34 * s,
                        ),
                      ),
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
}

  Widget _buildHeaderActionButton({
    required IconData icon,
    bool hasRedBadge = false,
    required VoidCallback onTap,
  }) {
    final s = Responsive.scale(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38 * s,
            height: 38 * s,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: Responsive.iconSize(context, 20),
              color: const Color(0xFF0064D2),
            ),
          ),
          if (hasRedBadge)
            Positioned(
              top: 1,
              right: 1,
              child: Container(
                width: 9 * s,
                height: 9 * s,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _build3DServiceCard({
    required String title,
    required _Icon3DType iconType,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    final s = Responsive.scale(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 74 * s,
                height: 64 * s,
                child: Center(
                  child: _build3DIconWidget(iconType),
                ),
              ),
              if (badgeText != null)
                Positioned(
                  top: -6,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3B30).withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 9),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8 * s),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 12),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF102A43),
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DServiceCardCompact({
    required String title,
    required _Icon3DType iconType,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    final s = Responsive.scale(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 74 * s,
                height: 64 * s,
                child: Center(
                  child: _build3DIconWidget(iconType, isCompact: true),
                ),
              ),
              if (badgeText != null)
                Positioned(
                  top: -6,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 8.5),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6 * s),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 11),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334E68),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DIconWidget(_Icon3DType type, {bool isCompact = false}) {
    final s = Responsive.scale(context);
    final size = 54.0 * s;

    final String imageAsset = switch (type) {
      _Icon3DType.flight => 'assets/images/icon_pesawat_cropped.png',
      _Icon3DType.wisata => 'assets/images/icon_menu_wisata.png',
      _Icon3DType.airportShuttle => 'assets/images/icon_shuttle_cropped.png',
      _Icon3DType.villa => 'assets/images/icon_villa_cropped.png',
      _Icon3DType.whoosh => 'assets/images/icon_whoosh_cropped.png',
      _Icon3DType.carRental => 'assets/images/icon_sewamobil_cropped.png',
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(12 * s),
      child: Image.asset(
        imageAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          final String svgAsset = switch (type) {
            _Icon3DType.flight => 'assets/images/icon_menu_pesawat.svg',
            _Icon3DType.wisata => 'assets/images/icon_menu_wisata.svg',
            _Icon3DType.airportShuttle => 'assets/images/icon_menu_shuttle.svg',
            _Icon3DType.villa => 'assets/images/icon_menu_villa.svg',
            _Icon3DType.whoosh => 'assets/images/icon_menu_whoosh.svg',
            _Icon3DType.carRental => 'assets/images/icon_menu_sewamobil.svg',
          };
          return SvgPicture.asset(
            svgAsset,
            width: size,
            height: size,
            fit: BoxFit.contain,
          );
        },
      ),
    );
  }

  Widget _buildRecentEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF102A43);
    final textSecondary = isDark ? const Color(0xFF9FB3C8) : const Color(0xFF627D98);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF2E333B)) : null,
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: const Color(0xFF0064D2),
            size: Responsive.iconSize(context, 28),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.tr('Belum ada pencarian terakhir', 'No recent searches yet'),
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 14),
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.tr('Riwayat pencarianmu akan muncul di sini.', 'Your search history will appear here.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 12),
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearchItemCard(_RecentSearchItem item) {
    final s = Responsive.scale(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF102A43);
    final textSecondary = isDark ? const Color(0xFF9FB3C8) : const Color(0xFF627D98);

    final title = item.title;
    final category = item.category;
    final icon = item.icon;
    final iconColor = item.iconColor;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: item.package != null
          ? () => _openWisataResult(item.package!)
          : _openSearch,
      child: Container(
      width: 250 * s,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF2E333B) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32 * s,
            height: 32 * s,
            child: Icon(icon, color: iconColor, size: Responsive.iconSize(context, 24)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 13),
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 10),
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: isDark ? const Color(0xFF9FB3C8) : const Color(0xFF9FB3C8), size: 20),
        ],
      ),
      ),
    );
  }

  Widget _buildPromoCard({
    required String imageUrl,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? favoriteButton,
  }) {
    final s = Responsive.scale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: 260 * s,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: CachedNetworkImageProvider(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
          if (favoriteButton != null)
            Positioned(top: 10, right: 10, child: favoriteButton),
          Positioned(
            bottom: 14,
            left: 14,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: Responsive.fontSize(context, 9.5),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.fontSize(context, 14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: Responsive.fontSize(context, 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  (Color, Color) _promoBadgeColors(String? badge) {
    switch (badge) {
      case 'FLASH SALE':
        return (const Color(0xFFFF5252), Colors.white);
      case 'DISKON SPESIAL':
        return (AppColors.azureSky, Colors.white);
      case 'PROMO AKHIR TAHUN':
        return (const Color(0xFF7C4DFF), Colors.white);
      case 'PAKET HEMAT':
        return (AppColors.secondary, Colors.white);
      case 'HOT DEAL':
      default:
        return (const Color(0xFFFFD600), Colors.black);
    }
  }
}

enum _Icon3DType {
  flight,
  wisata,
  airportShuttle,
  villa,
  whoosh,
  carRental,
}

class _RecentSearchItem {
  final String title;
  final String category;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final WisataPackage? package;

  const _RecentSearchItem({
    required this.title,
    required this.category,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.package,
  });
}

class ServicePage extends StatelessWidget {
  final String title;
  const ServicePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final titleLower = title.toLowerCase();
    final isWhoosh = titleLower.contains('whoosh');
    final isCarRental = titleLower.contains('sewa') || titleLower.contains('mobil') || titleLower.contains('car');

    final Color themeColor;
    if (isWhoosh) {
      themeColor = const Color(0xFFBA1A1A);
    } else if (isCarRental) {
      themeColor = const Color(0xFF0064D2);
    } else {
      themeColor = AppColors.azureSky;
    }

    final Widget animationWidget;
    if (isWhoosh) {
      animationWidget = const WhooshLottieAnimation();
    } else if (isCarRental) {
      animationWidget = const CarRentalLottieAnimation();
    } else {
      animationWidget = const VillaLottieAnimation();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F8),
      appBar: AppBar(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            }
          },
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Avenir',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              animationWidget,
              const SizedBox(height: 28),
              Text(
                'Layanan $title',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: Responsive.fontSize(context, 22),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF102A43),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Fitur ini sedang disiapkan untuk Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                  color: const Color(0xFF627D98),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 220,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Kami akan memberi tahu Anda saat layanan $title siap!'),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.notifications_active_outlined, size: 20),
                  label: const Text(
                    'Beri Tahu Saya',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CarRentalLottieAnimation extends StatefulWidget {
  const CarRentalLottieAnimation({super.key});

  @override
  State<CarRentalLottieAnimation> createState() => _CarRentalLottieAnimationState();
}

class _CarRentalLottieAnimationState extends State<CarRentalLottieAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final carBobbingY = sin(progress * pi * 2) * -4.0;
        final keyBounceY = (1.0 - (progress - 0.5).abs() * 2) * -10.0;
        final roadLineX = (progress * 50.0) % 30.0;
        final scaleGlow = 1.0 + (progress * 0.07);

        return SizedBox(
          width: 240,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Emerald/Azure Glow Circle
              Transform.scale(
                scale: scaleGlow,
                child: Container(
                  width: 175,
                  height: 175,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0064D2).withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0064D2).withValues(alpha: 0.15 * progress),
                        blurRadius: 32,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              // Inner White Card Circle
              Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFF0064D2).withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
              // Road Asphalt Track Line
              Positioned(
                bottom: 58,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    width: 160,
                    height: 5,
                    color: const Color(0xFF102A43).withValues(alpha: 0.12),
                    child: Transform.translate(
                      offset: Offset(-roadLineX, 0),
                      child: Row(
                        children: List.generate(
                          10,
                          (_) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 12,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0064D2).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Floating Rental Key Handoff Icon
              Positioned(
                top: 28,
                left: 36,
                child: Transform.translate(
                  offset: Offset(0, keyBounceY),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9500).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.vpn_key_rounded,
                      size: 22,
                      color: Color(0xFFFF9500),
                    ),
                  ),
                ),
              ),
              // Floating Location Destination Pin
              Positioned(
                top: 30,
                right: 38,
                child: Transform.scale(
                  scale: 0.9 + (sin(progress * pi) * 0.2),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C853).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      size: 22,
                      color: Color(0xFF00C853),
                    ),
                  ),
                ),
              ),
              // Car Icon directly without border box
              Transform.translate(
                offset: Offset(0, carBobbingY),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.directions_car_filled_rounded,
                      size: 64,
                      color: Color(0xFF0064D2),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFAAEE00),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class WhooshLottieAnimation extends StatefulWidget {
  const WhooshLottieAnimation({super.key});

  @override
  State<WhooshLottieAnimation> createState() => _WhooshLottieAnimationState();
}

class _WhooshLottieAnimationState extends State<WhooshLottieAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final trainX = -65.0 + (progress * 130.0);
        final speedLinesOpacity = (sin(progress * pi * 2).abs()).clamp(0.2, 1.0);
        final scaleGlow = 1.0 + (sin(progress * pi) * 0.06);

        return SizedBox(
          width: 240,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Crimson Red Glow Circle
              Transform.scale(
                scale: scaleGlow,
                child: Container(
                  width: 175,
                  height: 175,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFBA1A1A).withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFBA1A1A).withValues(alpha: 0.18 * progress),
                        blurRadius: 32,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              // Inner White Card Circle
              Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFBA1A1A).withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
              // Railway Track (Bottom Rail Lines)
              Positioned(
                bottom: 60,
                child: Container(
                  width: 170,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF102A43).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      8,
                      (_) => Container(
                        width: 4,
                        height: 6,
                        color: const Color(0xFFBA1A1A).withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
              // Speed Motion Wind Lines
              Positioned(
                top: 85,
                left: 30,
                child: Opacity(
                  opacity: speedLinesOpacity,
                  child: Row(
                    children: [
                      Container(
                        width: 35,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFAAEE00),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 20,
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBA1A1A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // High-Speed Bullet Train (Moving Bullet Train)
              Transform.translate(
                offset: Offset(trainX, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBA1A1A),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFBA1A1A).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.train_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 12,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFAAEE00),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Top Electric Lightning Bolt (Sparking Pantograph)
              Positioned(
                top: 32,
                child: Opacity(
                  opacity: (sin(progress * pi * 4).abs()).clamp(0.3, 1.0),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFAAEE00).withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      size: 24,
                      color: Color(0xFFAAEE00),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class VillaLottieAnimation extends StatefulWidget {
  const VillaLottieAnimation({super.key});

  @override
  State<VillaLottieAnimation> createState() => _VillaLottieAnimationState();
}

class _VillaLottieAnimationState extends State<VillaLottieAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final hammerAngle = (progress - 0.5) * 0.6;
        final scaleGlow = 1.0 + (progress * 0.08);
        final floatY = (1.0 - (progress - 0.5).abs() * 2) * -8.0;

        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Pulsing Glow Circle
              Transform.scale(
                scale: scaleGlow,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.azureSky.withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.azureSky.withValues(alpha: 0.15 * progress),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              // Inner White Card Circle
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: AppColors.azureSky.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
              // Floating Villa House & Swimming Pool Icon
              Transform.translate(
                offset: Offset(0, floatY),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.villa_rounded,
                      size: 64,
                      color: AppColors.azureSky,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFAAEE00),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              // Animated Hammer Tool (Tapping)
              Positioned(
                top: 30,
                left: 34,
                child: Transform.rotate(
                  angle: hammerAngle,
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.build_rounded,
                      size: 24,
                      color: AppColors.azureSky,
                    ),
                  ),
                ),
              ),
              // Animated Wrench Tool (Spinning)
              Positioned(
                bottom: 30,
                right: 34,
                child: Transform.rotate(
                  angle: progress * 6.28,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.handyman_rounded,
                      size: 24,
                      color: Color(0xFF00629D),
                    ),
                  ),
                ),
              ),
              // Sparkle Particle 1
              Positioned(
                top: 25 + (progress * 10),
                right: 45,
                child: Opacity(
                  opacity: (0.3 + (progress * 0.7)).clamp(0.0, 1.0),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: Color(0xFFFFD600),
                  ),
                ),
              ),
              // Sparkle Particle 2
              Positioned(
                bottom: 35 + ((1.0 - progress) * 8),
                left: 42,
                child: Opacity(
                  opacity: (1.0 - progress).clamp(0.0, 1.0),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Color(0xFFAAEE00),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PopularAirlineCard extends StatelessWidget {
  const _PopularAirlineCard({
    required this.name,
    required this.code,
    required this.tag,
  });

  final String name;
  final String code;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FlightSearchPage()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AirlineLogoWidget(
              code: code,
              name: name,
              size: 40 * s,
              borderRadius: 8,
            ),
            SizedBox(height: 6 * s),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 11),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF102A43),
              ),
            ),
            SizedBox(height: 3 * s),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF3FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 9),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0064D2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
