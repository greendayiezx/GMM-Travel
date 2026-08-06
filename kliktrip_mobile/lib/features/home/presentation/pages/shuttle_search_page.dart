import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../../../booking/presentation/booking_list_page.dart';
import '../../../wisata/presentation/wisata_page.dart';
import '../../data/shuttle_city_data_source.dart';
import '../../data/shuttle_route_data_source.dart';
import 'profile_page.dart';
import 'saved_page.dart';
import 'shuttle_empty_field_page.dart';
import 'shuttle_schedules_page.dart';

class ShuttleSearchPage extends StatefulWidget {
  const ShuttleSearchPage({super.key});

  @override
  State<ShuttleSearchPage> createState() => _ShuttleSearchPageState();
}

class _ShuttleSearchPageState extends State<ShuttleSearchPage> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _originFocusNode = FocusNode();
  final _destinationFocusNode = FocusNode();
  final _cityDataSource = ShuttleCityDataSource();
  final _routeDataSource = ShuttleRouteDataSource();
  DateTime _selectedDate = DateTime.now();
  int _passengers = 1;
  bool _isSearching = false;

  // Dropdown overlay state
  List<CityOption> _overlaySuggestions = [];
  bool _showOverlay = false;
  bool _overlayIsDefault = false;
  bool _overlayIsOrigin = true;
  Timer? _overlayDebounce;
  List<_RecentSearch> _recentSearches = const [];

  List<PopularRoute> _popularRoutes = [];
  bool _loadingPopularRoutes = true;

  @override
  void initState() {
    super.initState();
    _originFocusNode.addListener(() => _onFocusChanged(isOrigin: true));
    _destinationFocusNode.addListener(() => _onFocusChanged(isOrigin: false));
    _loadPopularRoutes();
  }

  Future<void> _loadPopularRoutes() async {
    try {
      final routes = await _routeDataSource.fetchPopularRoutes();
      if (mounted) setState(() => _popularRoutes = routes);
    } catch (_) {
      // Biarkan kosong — section akan tampilkan empty state, bukan dummy data.
    } finally {
      if (mounted) setState(() => _loadingPopularRoutes = false);
    }
  }

  String _formatPrice(int price) {
    final numStr = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return 'Rp$numStr';
  }

  void _onFocusChanged({required bool isOrigin}) {
    final focusNode = isOrigin ? _originFocusNode : _destinationFocusNode;
    final controller = isOrigin ? _originController : _destinationController;
    if (focusNode.hasFocus) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
      _showDropdownOverlay(isOrigin ? 'origin' : 'destination', '');
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !focusNode.hasFocus) {
          setState(() => _showOverlay = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _originFocusNode.dispose();
    _destinationFocusNode.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _overlayDebounce?.cancel();
    super.dispose();
  }

  void _showDropdownOverlay(String field, String query) {
    _overlayDebounce?.cancel();
    _overlayDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      final results = await _cityDataSource.searchCities(query);
      if (!mounted) return;
      setState(() {
        _overlayIsOrigin = field == 'origin';
        _overlaySuggestions = results;
        _overlayIsDefault = query.isEmpty;
        _showOverlay = results.isNotEmpty;
      });
    });
  }

  void _hideOverlay() {
    _overlayDebounce?.cancel();
    setState(() {
      _showOverlay = false;
      _overlaySuggestions = [];
    });
  }

  void _selectOverlayCity(CityOption city) {
    if (_overlayIsOrigin) {
      _originController.text = city.name;
    } else {
      _destinationController.text = city.name;
    }
    _hideOverlay();
    FocusScope.of(context).unfocus();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _selectPassengers() async {
    final selectedPassengers = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (context) {
        var passengers = _passengers;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Responsive.horizontalPadding(context),
                  8,
                  Responsive.horizontalPadding(context),
                  28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jumlah penumpang',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 20),
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    SizedBox(height: Responsive.verticalPadding(context)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Penumpang',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: passengers > 1
                                  ? () => setModalState(() => passengers--)
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            SizedBox(
                              width: 48,
                              child: Text(
                                '$passengers',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 18),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed: passengers < 8
                                  ? () => setModalState(() => passengers++)
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.verticalPadding(context)),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, passengers),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.azureSky,
                          padding: EdgeInsets.symmetric(
                            vertical: Responsive.verticalPadding(context) * 0.6,
                          ),
                        ),
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selectedPassengers != null) {
      setState(() => _passengers = selectedPassengers);
    }
  }

  void _swapLocations() {
    final origin = _originController.text;
    setState(() {
      _originController.text = _destinationController.text;
      _destinationController.text = origin;
    });
  }

  Future<void> _searchShuttle() async {
    if (_originController.text.trim().isEmpty ||
        _destinationController.text.trim().isEmpty) {
      showShuttleEmptyFieldBottomSheet(context);
      return;
    }

    setState(() => _isSearching = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() => _isSearching = false);
    _recordRecentSearch();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShuttleSchedulesPage(
          origin: _originController.text.trim(),
          destination: _destinationController.text.trim(),
          date: _selectedDate,
          passengers: _passengers,
        ),
      ),
    );
  }

  /// Catat pencarian yang benar-benar dilakukan user ke daftar
  /// "Pencarian Terakhir" (paling baru di atas, tanpa duplikasi).
  void _recordRecentSearch() {
    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();
    if (origin.isEmpty || destination.isEmpty) return;

    final search = _RecentSearch(
      origin: origin,
      destination: destination,
      passengers: _passengers,
      serviceClass: 'Ekonomi',
    );

    setState(() {
      _recentSearches = [
        search,
        ..._recentSearches.where((s) =>
            s.origin != origin || s.destination != destination),
      ];
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.sublist(0, 5);
      }
    });
  }

  void _applySearch(_RecentSearch search) {
    setState(() {
      _originController.text = search.origin;
      _destinationController.text = search.destination;
      _passengers = search.passengers;
    });
  }

  void _applyRoute(String origin, String destination) {
    setState(() {
      _originController.text = origin;
      _destinationController.text = destination;
    });
  }

  String get _formattedDate {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${_selectedDate.day} ${monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';
  }

  String get _passengerLabel =>
      '$_passengers ${_passengers == 1 ? 'Penumpang' : 'Penumpang'}';

  @override
  Widget build(BuildContext context) {
    final topSafeArea = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121417) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: _showOverlay
                ? const NeverScrollableScrollPhysics()
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HERO: gambar shuttle full-width + tombol kembali melayang + kartu search ──
                _buildShuttleHeader(),

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.horizontalPadding(context),
                    28,
                    Responsive.horizontalPadding(context),
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_recentSearches.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pencarian Terakhir',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 24),
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _recentSearches = const []),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ..._recentSearches.map(
                          (search) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RecentSearchTile(
                              search: search,
                              onTap: () => _applySearch(search),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Rute Populer',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 24),
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: (252 * Responsive.scale(context)).clamp(200, 360),
                        child: _loadingPopularRoutes
                            ? const Center(child: CircularProgressIndicator())
                            : _popularRoutes.isEmpty
                                ? Center(
                                    child: Text(
                                      'Belum ada rute populer saat ini.',
                                      style: TextStyle(
                                        fontSize: Responsive.fontSize(context, 13),
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _popularRoutes.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                                    itemBuilder: (context, index) {
                                      final route = _popularRoutes[index];
                                      return _PopularRouteCard(
                                        route: route.routeLabel,
                                        fare: route.minPrice != null
                                            ? 'Mulai dari ${_formatPrice(route.minPrice!)}'
                                            : 'Hubungi kami untuk harga',
                                        badge: '${route.scheduleCount} jadwal/minggu',
                                        onBook: () => _applyRoute(
                                          route.departureCity,
                                          route.arrivalCity,
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Dropdown overlay — rendered on TOP of everything
          if (_showOverlay)
            Positioned(
              top: topSafeArea + 200.0 + (_overlayIsOrigin ? 30.0 : 78.0),
              left: Responsive.horizontalPadding(context),
              right: Responsive.horizontalPadding(context),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                child: SizedBox(
                  height: (340 * Responsive.scale(context)).clamp(280, 440),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (_overlayIsDefault)
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: Row(
                            children: [
                              const Icon(Icons.trending_up,
                                  size: 14, color: AppColors.azureSky),
                              const SizedBox(width: 6),
                              Text(
                                'KOTA POPULER',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 11),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.azureSky.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ...List.generate(_overlaySuggestions.length, (index) {
                        final city = _overlaySuggestions[index];
                        final showDivider = index < _overlaySuggestions.length - 1;
                        return InkWell(
                          onTap: () => _selectOverlayCity(city),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.azureSky
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.location_city,
                                        size: 16,
                                        color: AppColors.azureSky,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            city.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: Responsive.fontSize(context, 14),
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.onSurface,
                                            ),
                                          ),
                                          if (city.province.isNotEmpty)
                                            Text(
                                              city.province,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: Responsive.fontSize(context, 12),
                                                color: AppColors.onSurfaceVariant
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (showDivider)
                                const Divider(height: 1, indent: 16, endIndent: 16),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.pop(context);
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
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedPage()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
      ),
    );
  }

  /// Header hero: gambar shuttle full-width + judul "Cari Shuttle" + kartu search di bawah gambar
  Widget _buildShuttleHeader() {
    final topSafeArea = MediaQuery.of(context).padding.top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Full Width Shuttle Banner ──
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 200 + topSafeArea,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/cari_shuttle.png'),
                  alignment: Alignment.center,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Floating Back Button
            Positioned(
              top: topSafeArea + 12,
              left: 16,
              child: Material(
                color: Colors.white.withValues(alpha: 0.9),
                shape: const CircleBorder(),
                elevation: 3,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.azureSky,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            // Judul "Cari Shuttle"
            Positioned(
              bottom: 16,
              left: Responsive.horizontalPadding(context),
              right: Responsive.horizontalPadding(context),
              child: Text(
                'Cari Shuttle',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: Responsive.fontSize(context, 22),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── 2. Kartu Pencarian Full-Width Sejajar Dengan Gambar Shuttle ──
        _buildSearchCard(),
      ],
    );
  }

  Widget _buildSearchCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final tileBg = isDark ? const Color(0xFF242830) : const Color(0xFFF5F6F9);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1C1E);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 1. Origin & Destination Block ──
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _buildShuttleTile(
                      icon: Icons.location_on_outlined,
                      controller: _originController,
                      focusNode: _originFocusNode,
                      placeholder: AppLocalizations.get('shuttle_origin_hint'),
                      isOrigin: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark ? const Color(0xFF3A3E44) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    _buildShuttleTile(
                      icon: Icons.location_on_outlined,
                      controller: _destinationController,
                      focusNode: _destinationFocusNode,
                      placeholder: AppLocalizations.get('shuttle_dest_hint'),
                      isOrigin: false,
                    ),
                  ],
                ),
              ),
              // Floating Swap Button
              Positioned(
                right: 18,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    elevation: 3,
                    shadowColor: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? const Color(0xFF2E333B) : Colors.white,
                    child: InkWell(
                      onTap: _swapLocations,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.swap_vert,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── 2. Date Block ──
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: Color(0xFF8E8E93),
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _formattedDate,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── 3. Passenger Block ──
          InkWell(
            onTap: _selectPassengers,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: Color(0xFF8E8E93),
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    _passengerLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Search Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isSearching ? null : _searchShuttle,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.azureSky,
                disabledBackgroundColor:
                    AppColors.azureSky.withValues(alpha: 0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isSearching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search, size: 22),
              label: Text(
                _isSearching ? 'Mencari...' : 'Cari Shuttle',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShuttleTile({
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    required bool isOrigin,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8E8E93), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
              ),
              decoration: InputDecoration(
                filled: false,
                fillColor: Colors.transparent,
                hintText: placeholder,
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                final q = value.trim();
                _showDropdownOverlay(isOrigin ? 'origin' : 'destination', q);
              },
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}





class _RecentSearch {
  const _RecentSearch({
    required this.origin,
    required this.destination,
    required this.passengers,
    required this.serviceClass,
  });

  final String origin;
  final String destination;
  final int passengers;
  final String serviceClass;
}

class _RecentSearchTile extends StatelessWidget {
  const _RecentSearchTile({required this.search, required this.onTap});

  final _RecentSearch search;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.horizontalPadding(context) * 0.5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.history,
                    color: AppColors.onSurfaceVariant, size: Responsive.iconSize(context, 20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${search.origin} → ${search.destination}',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 14),
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${search.passengers} Penumpang • ${search.serviceClass}',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 12),
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.outline, size: Responsive.iconSize(context, 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularRouteCard extends StatelessWidget {
  const _PopularRouteCard({
    required this.route,
    required this.fare,
    required this.badge,
    required this.onBook,
  });

  final String route;
  final String fare;
  final String badge;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (240 * Responsive.scale(context)).clamp(200, 360),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 116,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage('assets/images/shuttle_keren.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_bus_rounded,
                          size: Responsive.iconSize(context, 14),
                          color: AppColors.solarFlare,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badge,
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 12),
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(Responsive.horizontalPadding(context) * 0.8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 14),
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  fare,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 13),
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onBook,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.azureSky,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'PILIH RUTE',
                      style:
                          TextStyle(fontSize: Responsive.fontSize(context, 11), fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
