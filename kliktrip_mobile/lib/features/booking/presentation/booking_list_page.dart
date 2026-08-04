import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/website_loader.dart';
import '../../home/presentation/pages/profile_page.dart';
import '../../home/presentation/pages/saved_page.dart';
import '../../wisata/presentation/wisata_page.dart';
import '../data/booking_remote_data_source.dart';

class BookingListPage extends StatefulWidget {
  /// Jika `true` (dibuka dari sub-menu Akun/Profil), tampilkan tombol panah
  /// kembali ke halaman sebelumnya dan sembunyikan bottom nav.
  final bool showBackButton;
  const BookingListPage({this.showBackButton = false, super.key});

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  final BookingRemoteDataSource _dataSource = BookingRemoteDataSource();

  final List<String> _filters = ['Semua', 'Pesawat', 'Shuttle', 'Wisata'];
  int _selectedFilter = 0;

  List<BookingItem>? _bookings;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _dataSource.fetchBookings();
      if (mounted) setState(() => _bookings = items);
    } catch (_) {
      // Backend belum online (Railway offline). Untuk sementara tampilkan
      // empty state (no_bookings.png), bukan error, agar UI tetap bersih.
      if (mounted) setState(() => _bookings = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<BookingItem> get _visibleBookings {
    final all = _bookings ?? [];
    if (_selectedFilter == 0) return all;
    final category = BookingCategory.values[_selectedFilter - 1];
    return all.where((b) => b.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hPadding = Responsive.horizontalPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121417) : AppColors.surfaceAlt;

    return Scaffold(
      backgroundColor: scaffoldBg,
      bottomNavigationBar: widget.showBackButton
          ? null
          : BottomNav(
              currentIndex: 1,
              onItemSelected: (index) {
                if (index == 0) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } else if (index == 1) {
                  // Sudah di halaman Booking.
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
      body: WebsiteRouteLoader(
        isLoading: _isLoading,
        text: 'Memuat halaman…',
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              _buildFilterTabs(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorState()
                        : _visibleBookings.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _loadBookings,
                                child: ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.fromLTRB(
                                    hPadding, 4, hPadding, 96,
                                  ),
                                  itemCount: _visibleBookings.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (_, i) =>
                                      _BookingCard(item: _visibleBookings[i]),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
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
            'Booking',
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: Responsive.fontSize(context, 22),
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.search_rounded,
              color: textPrimary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? const Color(0xFF121417) : AppColors.surfaceAlt;
    final unselectedBg = isDark ? const Color(0xFF1B1E22) : AppColors.surfaceContainerLow;
    final unselectedFg = isDark ? const Color(0xFF9FB3C8) : AppColors.onSurfaceVariant;

    final localizedFilters = [
      AppLocalizations.get('booking_filter_all'),
      AppLocalizations.get('booking_filter_flight'),
      AppLocalizations.get('booking_filter_shuttle'),
      AppLocalizations.get('booking_filter_tour'),
    ];

    return Container(
      color: containerBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: List.generate(localizedFilters.length, (index) {
            final isSelected = _selectedFilter == index;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.azureSky
                        : unselectedBg,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.azureSky
                                  .withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    localizedFilters[index],
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 13),
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : unselectedFg,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.outlineVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat pesanan',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Periksa koneksi internet lalu coba lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 13),
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBookings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azureSky,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF12275C);
    final textSecondary = isDark ? const Color(0xFF9FB3C8) : AppColors.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/no_bookings.png',
              height: 150,
              width: 160,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.confirmation_number_rounded,
                size: 72,
                color: AppColors.outlineVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.get('booking_empty_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: Responsive.fontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.get('booking_empty_sub'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 13),
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingItem item;
  const _BookingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1E22) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2E333B) : AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: item.category == BookingCategory.wisata
          ? _WisataCardContent(item: item)
          : _SimpleCardContent(item: item),
    );
  }
}

class _SimpleCardContent extends StatelessWidget {
  final BookingItem item;
  const _SimpleCardContent({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.onSurface;
    final textSecondary = isDark ? const Color(0xFF9FB3C8) : AppColors.onSurfaceVariant;
    final bottomBarBg = isDark ? const Color(0xFF242830) : AppColors.surfaceContainerLow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconBadge(category: item.category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_categoryLabel(item.category)} • ${item.code}'
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 12),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 17),
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _StatusBadge(status: item.status),
              ),
              const SizedBox(height: 14),
              Divider(color: isDark ? const Color(0xFF2E333B) : AppColors.outlineVariant.withValues(alpha: 0.25)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.dateLabel,
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 12),
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(item.date),
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 15),
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.priceNote,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12),
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        _formatRp(item.price),
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 17),
                          fontWeight: FontWeight.bold,
                          color: item.category == BookingCategory.flight
                              ? AppColors.azureSky
                              : textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: bottomBarBg,
          ),
          child: item.hasTicket
              ? Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.tr('E-Tiket Tersedia', 'E-Ticket Available'),
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 12),
                        color: textSecondary,
                      ),
                    ),
                    const Spacer(),
                    _ActionButton(label: AppLocalizations.tr('Lihat Tiket', 'View Ticket')),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: item.actions
                      .map((a) => _ActionButton(
                            label: a.label,
                            primary: a.primary,
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  static String _categoryLabel(BookingCategory c) {
    switch (c) {
      case BookingCategory.flight:
        return 'Flight';
      case BookingCategory.shuttle:
        return 'Shuttle';
      case BookingCategory.wisata:
        return 'Wisata';
    }
  }
}

class _WisataCardContent extends StatelessWidget {
  final BookingItem item;
  const _WisataCardContent({required this.item});

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 160 * s,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6E7CF0), Color(0xFF1E3A8A)],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.travel_explore_rounded,
              size: 64,
              color: Colors.white70,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.explore_rounded,
                              size: 15,
                              color: AppColors.azureSky,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.code.toUpperCase(),
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 12),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: AppColors.azureSky,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 17),
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: item.status, gray: true),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(item.date),
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 13),
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: AppColors.outlineVariant.withValues(alpha: 0.25)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.priceNote,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12),
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatRp(item.price),
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 17),
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _ActionButton(
                    label: item.actions.first.label,
                    primary: item.actions.first.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  final BookingCategory category;
  const _IconBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (category) {
      BookingCategory.flight => (
          Icons.flight_rounded,
          AppColors.azureSky.withValues(alpha: 0.10),
          AppColors.azureSky,
        ),
      BookingCategory.shuttle => (
          Icons.directions_bus_rounded,
          AppColors.secondaryContainer.withValues(alpha: 0.12),
          AppColors.secondary,
        ),
      BookingCategory.wisata => (
          Icons.explore_rounded,
          AppColors.azureSky.withValues(alpha: 0.10),
          AppColors.azureSky,
        ),
    };
    return SizedBox(
      width: 32,
      height: 32,
      child: Icon(icon, size: 28, color: fg),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  final bool gray;
  const _StatusBadge({required this.status, this.gray = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status.type) {
      BookingStatusType.success => (
          AppColors.secondaryContainer.withValues(alpha: 0.3),
          AppColors.secondary,
        ),
      BookingStatusType.completed => (
          AppColors.surfaceContainerHigh,
          AppColors.onSurfaceVariant,
        ),
      BookingStatusType.failed => (
          const Color(0xFFFFDAD6),
          const Color(0xFF93000A),
        ),
      BookingStatusType.pending => (
          AppColors.solarFlare.withValues(alpha: 0.2),
          const Color(0xFFCAA900),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool primary;
  const _ActionButton({required this.label, this.primary = false});

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azureSky,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
    }
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: AppColors.azureSky,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _formatRp(int value) {
  final s = value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]}.',
      );
  return 'Rp $s';
}

String _formatDate(String date) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) return date;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
}
