import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/airline_logo.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../../../booking/presentation/booking_list_page.dart';
import '../../../wisata/presentation/wisata_page.dart';
import '../../data/flight_remote_data_source.dart';
import '../../data/recent_activity.dart';
import 'flight_empty_field_page.dart';
import 'flight_results_page.dart';
import 'profile_page.dart';
import 'saved_page.dart';

class FlightSearchPage extends StatefulWidget {
  const FlightSearchPage({super.key});

  @override
  State<FlightSearchPage> createState() => _FlightSearchPageState();
}

class _FlightSearchPageState extends State<FlightSearchPage> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _dataSource = FlightRemoteDataSource();
  DateTime _departureDate = DateTime.now().add(const Duration(days: 7));
  bool _isRoundTrip = false;
  int _adults = 1;
  String _seatClass = 'Business';

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _swapAirports() {
    setState(() {
      final temp = _originController.text;
      _originController.text = _destinationController.text;
      _destinationController.text = temp;
    });
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _departureDate = picked);
  }

  String get _formattedDateTiket {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final d = _departureDate;
    final dayName = days[d.weekday % 7];
    final monthName = months[d.month - 1];
    final dayStr = d.day.toString().padLeft(2, '0');
    return '$dayName, $dayStr $monthName';
  }

  String get _isoDate {
    final d = _departureDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _selectPassengerAndClass() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Penumpang & Kelas Kursi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Dewasa (≥12 thn)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: _adults > 1
                                ? () {
                                    setModalState(() => _adults--);
                                    setState(() {});
                                  }
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '$_adults',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: _adults < 9
                                ? () {
                                    setModalState(() => _adults++);
                                    setState(() {});
                                  }
                                : null,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Kelas Kabin',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final cls in ['Ekonomi', 'Premium Ekonomi', 'Business', 'First'])
                        ChoiceChip(
                          label: Text(cls),
                          selected: _seatClass == cls,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => _seatClass = cls);
                              setState(() {});
                            }
                          },
                        )
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.azureSky,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _search() {
    final rawOrigin = _originController.text.trim();
    final rawDestination = _destinationController.text.trim();

    // Extract code if format is "Manado MDC"
    final originParts = rawOrigin.split(' ');
    final origin = originParts.isNotEmpty ? originParts.last.toUpperCase() : '';

    final destParts = rawDestination.split(' ');
    final destination = destParts.isNotEmpty ? destParts.last.toUpperCase() : '';

    if (origin.isEmpty || destination.isEmpty) {
      showFlightEmptyFieldBottomSheet(context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlightResultsPage(
          params: FlightSearchParams(
            origin: origin,
            destination: destination,
            departureDate: _isoDate,
            adults: _adults,
          ),
        ),
      ),
    );
    RecentActivityService.instance.add(RecentActivity(
      id: 'flight-$origin-$destination',
      type: 'flight',
      title: '$origin → $destination',
      subtitle: '$_adults dewasa • $_formattedDateTiket',
      icon: Icons.flight_takeoff,
      color: const Color(0xFF1E9BF0),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121417) : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? Colors.white : AppColors.onSurface;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HERO: gambar pesawat full-width + tombol kembali melayang + kartu search ──
            _buildPlaneHeader(),

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
                  // Maskapai Populer Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Maskapai Populer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'Geser →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.scale(context) * 12),
                  SizedBox(
                    height: 94,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _AirlineChip(name: 'Garuda Indonesia', code: 'GA'),
                        SizedBox(width: 8),
                        _AirlineChip(name: 'Lion Air', code: 'JT'),
                        SizedBox(width: 8),
                        _AirlineChip(name: 'Batik Air', code: 'ID'),
                        SizedBox(width: 8),
                        _AirlineChip(name: 'Citilink', code: 'QG'),
                        SizedBox(width: 8),
                        _AirlineChip(name: 'AirAsia', code: 'AK'),
                        SizedBox(width: 8),
                        _AirlineChip(name: 'Super Air Jet', code: 'IU'),
                        SizedBox(width: 8),
                        _AirlineChip(name: 'Singapore Airlines', code: 'SQ'),
                        SizedBox(width: 8),
                        _AirlineChip(name: 'Qatar Airways', code: 'QR'),
                        SizedBox(width: 8),
                        _AirlineChip(name: 'Emirates', code: 'EK'),
                        SizedBox(width: 8),
                        _AirlineChip(name: 'TransNusa', code: '8B'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  /// Card persis tiket.com
  Widget _buildTiketSearchCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final tileBg = isDark ? const Color(0xFF242830) : const Color(0xFFF5F6F9);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final textSecondary = isDark ? const Color(0xFF9FB3C8) : Colors.grey.shade600;

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
                    _AirportTile(
                      icon: Icons.flight_takeoff_outlined,
                      controller: _originController,
                      placeholder: AppLocalizations.get('flight_origin_dest_hint'),
                      dataSource: _dataSource,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark ? const Color(0xFF3A3E44) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    _AirportTile(
                      icon: Icons.flight_land_outlined,
                      controller: _destinationController,
                      placeholder: AppLocalizations.get('flight_origin_dest_hint'),
                      dataSource: _dataSource,
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
                      onTap: _swapAirports,
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

          // ── 2. Date & Roundtrip Block ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  child: InkWell(
                    onTap: _selectDate,
                    child: Text(
                      _formattedDateTiket,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.get('flight_roundtrip'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: _isRoundTrip,
                    onChanged: (val) => setState(() => _isRoundTrip = val),
                    activeColor: AppColors.azureSky,
                    inactiveTrackColor: isDark ? const Color(0xFF3A3E44) : const Color(0xFFD1D5DB),
                    inactiveThumbColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── 3. Passenger & Class Block ──
          InkWell(
            onTap: _selectPassengerAndClass,
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
                    '$_adults ${AppLocalizations.tr("Penumpang", "Passengers")}, $_seatClass',
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

          const SizedBox(height: 16),

          // ── Tombol Ayo Cari (di dalam card, sesuai desain) ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _search,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.azureSky,
                elevation: 2,
                shadowColor: AppColors.azureSky.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                AppLocalizations.get('flight_search_btn'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header hero: gambar pesawat full-width + judul "Cek Tiket Pesawat" + kartu search di bawah gambar
  Widget _buildPlaneHeader() {
    final topSafeArea = MediaQuery.of(context).padding.top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Full Width Airplane Banner ──
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 200 + topSafeArea,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/cari_penerbangan.png'),
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
            // Judul "Cek Tiket Pesawat"
            Positioned(
              bottom: 16,
              left: Responsive.horizontalPadding(context),
              right: Responsive.horizontalPadding(context),
              child: Text(
                'Cek Tiket Pesawat',
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

        // ── 2. Kartu Pencarian Full-Width Sejajar Dengan Gambar Pesawat ──
        _buildTiketSearchCard(),
      ],
    );
  }
}

class _AirportTile extends StatefulWidget {
  const _AirportTile({
    required this.icon,
    required this.controller,
    required this.placeholder,
    required this.dataSource,
  });

  final IconData icon;
  final TextEditingController controller;
  final String placeholder;
  final FlightRemoteDataSource dataSource;

  @override
  State<_AirportTile> createState() => _AirportTileState();
}

class _AirportTileState extends State<_AirportTile> {
  final _focusNode = FocusNode();
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  final _tileKey = GlobalKey();

  List<AirportOption> _suggestions = [];
  Timer? _debounce;
  bool _isLoading = false;
  bool _showDropdown = false;
  bool _isShowingDefault = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      // Select all text on focus so typing replaces existing text immediately
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
      // Show default popular suggestions immediately when clicked
      _showDefaultSuggestions();
    } else {
      // Delay closing dropdown so user clicks inside overlay execute first
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _hideDropdown();
        }
      });
    }
  }

  void _onTextChanged() {
    setState(() {}); // refresh rich text formatting
    if (!_focusNode.hasFocus) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      String query = widget.controller.text.trim();

      // If query is full label like "Manado MDC", extract city name for searching
      final parts = query.split(' ');
      if (parts.length > 1 && parts.last.length <= 4) {
        query = parts.sublist(0, parts.length - 1).join(' ');
      }

      if (query.length >= 2) {
        _isShowingDefault = false;
        _fetchSuggestions(query);
      } else {
        _showDefaultSuggestions();
      }
    });
  }

  void _showDefaultSuggestions() async {
    setState(() => _isLoading = true);
    try {
      final results = await widget.dataSource.searchAirports('');
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isLoading = false;
        _showDropdown = results.isNotEmpty;
        _isShowingDefault = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _showDropdown = false;
      });
    }
  }

  void _fetchSuggestions(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await widget.dataSource.searchAirports(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isLoading = false;
        _showDropdown = results.isNotEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _showDropdown = false;
      });
    }
  }

  void _hideDropdown() {
    setState(() {
      _showDropdown = false;
      _suggestions = [];
    });
  }

  void _selectAirport(AirportOption airport) {
    widget.controller.text = '${airport.city} ${airport.code}';
    _hideDropdown();
    _focusNode.unfocus();
  }

  /// Parses text like "Manado MDC" -> "Manado " (bold dark) + "MDC" (bold grey)
  Widget _buildFormattedContent() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      return Text(
        widget.placeholder,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF94A3B8),
        ),
      );
    }

    final parts = text.split(' ');
    if (parts.length > 1 && parts.last.length <= 4) {
      final code = parts.last;
      final city = parts.sublist(0, parts.length - 1).join(' ');
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$city ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
              ),
            ),
            TextSpan(
              text: code,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1C1C1E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final should = _showDropdown && _suggestions.isNotEmpty;
      if (should && !_portal.isShowing) _portal.show();
      if (!should && _portal.isShowing) _portal.hide();
    });

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (_) => _dropdownOverlay(),
      child: CompositedTransformTarget(
        link: _link,
        child: Padding(
          key: _tileKey,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(widget.icon, color: const Color(0xFF8E8E93), size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E),
                  ),
                  decoration: InputDecoration(
                    filled: false,
                    fillColor: Colors.transparent,
                    hintText: widget.placeholder,
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                      maxWidth: 24,
                      maxHeight: 24,
                    ),
                    suffixIcon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.azureSky,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 40), // Space for floating swap button
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownOverlay() {
    final box = _tileKey.currentContext?.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 280.0;
    return CompositedTransformFollower(
      link: _link,
      showWhenUnlinked: false,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, 6),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            surfaceTintColor: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  if (_isShowingDefault)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: const Row(
                        children: [
                          Icon(Icons.trending_up,
                              size: 14, color: AppColors.azureSky),
                          SizedBox(width: 6),
                          Text(
                            'BANDARA POPULER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.azureSky,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ...List.generate(_suggestions.length, (index) {
                    final airport = _suggestions[index];
                    return InkWell(
                      onTap: () => _selectAirport(airport),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 44,
                              child: Text(
                                airport.code,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.azureSky,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    airport.city,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    airport.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
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
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AirlineChip extends StatelessWidget {
  const _AirlineChip({required this.name, required this.code});

  final String name;
  final String code;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AirlineLogoWidget(
            code: code,
            name: name,
            size: 46,
            borderRadius: 10,
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
