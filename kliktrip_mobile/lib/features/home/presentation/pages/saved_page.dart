import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../../../../core/widgets/website_loader.dart';
import '../../../booking/data/favorite_remote_data_source.dart';
import '../../../booking/presentation/booking_list_page.dart';
import 'home_page.dart';
import 'profile_page.dart';
import '../../../wisata/presentation/wisata_page.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/settings/settings_service.dart';

class SavedPage extends StatefulWidget {
  /// Jika `true` (dibuka dari sub-menu Akun/Profil), tampilkan tombol panah
  /// kembali ke halaman sebelumnya dan sembunyikan bottom nav.
  final bool showBackButton;
  const SavedPage({this.showBackButton = false, super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  final FavoriteRemoteDataSource _dataSource = FavoriteRemoteDataSource();

  String _selectedFilter = 'Semua';
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<SavedItem>? _items;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _dataSource.fetchFavorites();
      if (mounted) setState(() => _items = list);
    } catch (_) {
      if (mounted) setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SavedItem> get _filteredItems {
    final all = _items ?? [];
    final matchesFilter = all.where((item) {
      if (_selectedFilter == 'Semua' || _selectedFilter == 'All') return true;
      if (_selectedFilter == 'Paket Wisata' || _selectedFilter == 'Tours') {
        return item.type == SavedItemType.wisata;
      }
      return item.type == SavedItemType.shuttle;
    });
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return matchesFilter.toList();
    return matchesFilter
        .where((item) =>
            item.title.toLowerCase().contains(q) ||
            item.subtitle.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final hPadding = Responsive.horizontalPadding(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final scaffoldBg = isDark ? const Color(0xFF121417) : const Color(0xFFFCF9F8);
        final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);

        final filters = [
          AppLocalizations.tr('Semua', 'All'),
          AppLocalizations.tr('Paket Wisata', 'Tours'),
          'Shuttle',
        ];

        return Scaffold(
          backgroundColor: scaffoldBg,
          bottomNavigationBar: widget.showBackButton
              ? null
              : BottomNav(
                  currentIndex: 3,
                  onItemSelected: (index) {
                    if (index == 0) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      );
                    } else if (index == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BookingListPage()),
                      );
                    } else if (index == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WisataPage()),
                      );
                    } else if (index == 4) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    }
                  },
                ),
          body: WebsiteRouteLoader(
            isLoading: _isLoading,
            text: AppLocalizations.tr('Memuat halaman…', 'Loading page...'),
            child: SafeArea(
            child: Column(
              children: [
                // ── Top App Bar ───────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPadding, vertical: 8,
                  ),
                  child: Row(
                    children: [
                      if (widget.showBackButton) ...[
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        AppLocalizations.get('saved_title'),
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: Responsive.fontSize(context, 22),
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.search_rounded,
                          color: textPrimary,
                          size: 24,
                        ),
                        onPressed: () =>
                            setState(() => _isSearching = !_isSearching),
                      ),
                    ],
                  ),
                ),

            if (_isSearching)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFBFC7D3).withValues(alpha: 0.4),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Cari favorit...',
                      hintStyle: TextStyle(
                        fontSize: Responsive.fontSize(context, 13),
                        color: const Color(0xFF6F7883),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF1E9BF0),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // ── Filter Chips ──────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: Row(
                children: filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedFilter = filter),
                      selectedColor: const Color(0xFF1E9BF0),
                      backgroundColor: isDark ? const Color(0xFF1B1E22) : Colors.white,
                      elevation: 0,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? const Color(0xFF9FB3C8) : const Color(0xFF3F4851)),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: Responsive.fontSize(context, 12.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF1E9BF0)
                              : (isDark ? const Color(0xFF2E333B) : const Color(0xFFBFC7D3)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // ── Saved Items List ──────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.cloud_off_rounded,
                                size: 48,
                                color: Color(0xFFBFC7D3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Gagal memuat favorit',
                                style: TextStyle(
                                  fontSize:
                                      Responsive.fontSize(context, 14),
                                  color: const Color(0xFF6F7883),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadFavorites,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E9BF0),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        )
                      : _filteredItems.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/images/no_wishlist.png',
                                      height: 150,
                                      width: 160,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.favorite_border_rounded,
                                        size: 72,
                                        color: Color(0xFFBFC7D3),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Wishlist kamu masih kosong',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Avenir',
                                        fontSize:
                                            Responsive.fontSize(context, 20),
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1C1B1B),
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Yuk, mulai simpan wishlist kamu disini!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize:
                                            Responsive.fontSize(context, 13),
                                        color: const Color(0xFF6F7883),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: hPadding, vertical: 10,
                              ),
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                switch (item.type) {
                                  case SavedItemType.shuttle:
                                    return _buildShuttleCard(context, item);
                                  case SavedItemType.wisata:
                                    return _buildWisataCard(context, item);
                                  default:
                                    return _buildGenericCard(context, item);
                                }
                              },
                            ),
            ),
          ],
        ),
      ),
      ),
    );
  },
);
}

  // ── Wisata Image Card ─────────────────────────────────────────
  // ── Wisata Image Card ─────────────────────────────────────────
  Widget _buildWisataCard(BuildContext context, SavedItem item) {
    final s = Responsive.scale(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final textSecondary = isDark ? const Color(0xFF9FB3C8) : const Color(0xFF3F4851);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2E333B) : const Color(0xFFBFC7D3).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              if (item.image != null && item.image!.isNotEmpty)
                AppNetworkImage(
                  src: item.image!,
                  height: 220 * s,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorIcon: Icons.landscape_outlined,
                  iconSize: 40,
                )
              else
                _imagePlaceholder(220 * s),
              Container(
                height: 220 * s,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              const Positioned(
                top: 12,
                right: 12,
                child: Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF3B30),
                  size: 24,
                ),
              ),
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.rating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFAAEE00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFFFB800),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${item.rating}',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 11),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF131F00),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: Responsive.fontSize(context, 18),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 12.5),
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (item.price != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.priceSub ?? AppLocalizations.tr('Harga', 'Price'),
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 11),
                              color: const Color(0xFF6F7883),
                            ),
                          ),
                          Text(
                            item.price!,
                            style: TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: Responsive.fontSize(context, 18),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E9BF0),
                            ),
                          ),
                        ],
                      ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E9BF0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        AppLocalizations.get('btn_details'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shuttle Route Card ────────────────────────────────────────
  Widget _buildShuttleCard(BuildContext context, SavedItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
    final textSecondary = isDark ? const Color(0xFF9FB3C8) : const Color(0xFF3F4851);
    final iconBg = isDark ? const Color(0xFF252A31) : const Color(0xFFF0EDED);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2E333B) : const Color(0xFFBFC7D3).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Color(0xFF1E9BF0),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: Responsive.fontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 12),
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.favorite_rounded,
            color: Color(0xFF1E9BF0),
            size: 24,
          ),
        ],
      ),
    );
  }

  // ── Generic Card ──────────────────────────────────────────────
  Widget _buildGenericCard(BuildContext context, SavedItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
    final iconBg = isDark ? const Color(0xFF252A31) : const Color(0xFFF0EDED);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2E333B) : const Color(0xFFBFC7D3).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFF1E9BF0),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFEAE7E7),
      child: const Center(
        child: Icon(
          Icons.travel_explore_rounded,
          size: 48,
          color: Color(0xFFBFC7D3),
        ),
      ),
    );
  }
}
