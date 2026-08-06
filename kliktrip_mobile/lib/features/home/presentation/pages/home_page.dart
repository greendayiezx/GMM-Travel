import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/airline_logo.dart';
import '../../../../core/widgets/bottom_nav.dart';
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
import '../../../wisata/presentation/bloc/wisata_bloc.dart';
import '../../../wisata/presentation/bloc/wisata_event.dart';
import '../../../wisata/presentation/bloc/wisata_state.dart';
import '../widgets/car_rental_lottie_animation.dart';
import '../widgets/home_header_bar.dart';
import '../widgets/promo_section.dart';
import '../widgets/recent_search_item.dart';
import '../widgets/recent_search_section.dart';
import '../widgets/trending_wisata_section.dart';
import '../widgets/villa_lottie_animation.dart';
import '../widgets/whoosh_lottie_animation.dart';
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
  late final WisataBloc _wisataBloc;
  final _favoriteDataSource = FavoriteRemoteDataSource();
  final _notificationDataSource = NotificationRemoteDataSource();
  // itemId (WisataPackage.id) -> favoriteId, dipakai FavoriteButton tahu
  // status awal tanpa tiap kartu fetch sendiri-sendiri.
  Map<String, String> _favoriteIdByItemId = {};
  bool _hasUnreadNotifications = false;

  List<RecentSearchItem> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _wisataBloc = sl<WisataBloc>();
    _initHomePage();
  }

  @override
  void dispose() {
    _wisataBloc.close();
    super.dispose();
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
      _wisataBloc.add(const WisataHomeDataRequested());
      await _wisataBloc.stream.firstWhere(
        (s) => s is WisataHomeDataLoaded || s is WisataError,
      );
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
    final recentPackages = _recentSearches
        .map((item) => item.package)
        .whereType<WisataPackage>()
        .toList();
    final selected = await Navigator.push<WisataPackage>(
      context,
      MaterialPageRoute(
        builder: (_) => SearchPage(recentPackages: recentPackages),
      ),
    );
    if (selected == null || !mounted) return;
    _openWisataResult(selected);
  }

  void _openWisataResult(WisataPackage pkg) {
    setState(() {
      _recentSearches.removeWhere((item) => item.package?.id == pkg.id);
      _recentSearches.insert(
        0,
        RecentSearchItem(
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

                    RecentSearchSection(
                      recentSearches: _recentSearches,
                      filters: _filters,
                      selectedFilterIndex: _selectedFilterIndex,
                      onFilterSelected: (index) {
                        setState(() => _selectedFilterIndex = index);
                      },
                      onClear: _clearRecentSearches,
                      onItemTap: (item) => item.package != null
                          ? _openWisataResult(item.package!)
                          : _openSearch(),
                    ),

                    const SizedBox(height: 28),

                    BlocBuilder<WisataBloc, WisataState>(
                      bloc: _wisataBloc,
                      builder: (context, state) {
                        final promos = state is WisataHomeDataLoaded
                            ? state.promos.map(WisataPackage.fromEntity).toList()
                            : <WisataPackage>[];
                        return PromoSection(
                          promos: promos,
                          favoriteIdByItemId: _favoriteIdByItemId,
                          onPromoTap: (promo) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WisataDetailPage(pkg: promo),
                            ),
                          ),
                        );
                      },
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

                    BlocBuilder<WisataBloc, WisataState>(
                      bloc: _wisataBloc,
                      builder: (context, state) {
                        final trendingWisata = state is WisataHomeDataLoaded
                            ? state.trending.map(WisataPackage.fromEntity).toList()
                            : <WisataPackage>[];
                        return TrendingWisataSection(
                      trendingWisata: trendingWisata,
                      favoriteIdByItemId: _favoriteIdByItemId,
                      onSeeAllTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WisataPage(),
                          ),
                        );
                      },
                      onItemTap: (pkg) {
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
                        );
                      },
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
              child: HomeHeaderBar(
                hasUnreadNotifications: _hasUnreadNotifications,
                onSearchTap: _openSearch,
                onNotificationTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  );
                  _loadNotificationStatus();
                },
              ),
            ),
        ],
      ),
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

}

enum _Icon3DType {
  flight,
  wisata,
  airportShuttle,
  villa,
  whoosh,
  carRental,
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
