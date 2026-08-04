import 'package:flutter/material.dart';

import '../../../../core/auth/clerk_auth_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/settings/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../../../../core/widgets/user_avatar.dart';
import 'app_settings_page.dart';
import 'payment_methods_page.dart';
import 'rewards_page.dart';
import 'saved_page.dart';
import 'saved_passenger_page.dart';
import 'support_page.dart';
import '../../../auth/data/user_remote_data_source.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../booking/presentation/booking_list_page.dart';
import '../../../wisata/presentation/wisata_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _userSource = UserRemoteDataSource();
  UserStats? _stats;
  UserLoyalty? _loyalty;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Ambil stats & loyalty paralel; masing-masing punya fallback aman.
    final results = await Future.wait([
      _userSource.fetchStats().catchError((e) {
        debugPrint('Gagal memuat stats profil: $e');
        return UserStats.empty;
      }),
      _userSource.fetchLoyalty().catchError((e) {
        debugPrint('Gagal memuat loyalty profil: $e');
        return UserLoyalty.empty;
      }),
    ]);
    if (mounted) {
      setState(() {
        _stats = results[0] as UserStats;
        _loyalty = results[1] as UserLoyalty;
        _statsLoading = false;
      });
    }
  }

  Future<void> _onSignOut() async {
    try {
      await clerkAuth.signOut();
    } catch (e) {
      debugPrint('Sign out gagal: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  /// '—' selagi memuat, angka nyata setelahnya (bukan dummy).
  String _statValue(int? value) => _statsLoading ? '—' : '${value ?? 0}';

  /// Format angka ke "Rp1.234.567".
  String _formatRupiah(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp$buf';
  }

  /// Format poin ke "12.450".
  String _formatPoints(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final topPadding = MediaQuery.of(context).padding.top;
        final hPadding = Responsive.horizontalPadding(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final scaffoldBg = isDark ? const Color(0xFF121417) : const Color(0xFFFCF9F8);
        final cardBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
        final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
        final textSecondary = isDark ? const Color(0xFF9FB3C8) : const Color(0xFF3F4851);

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: Stack(
            children: [
              // ── Scrollable Body Content ──────────────────────────────────
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPadding, topPadding + 16, hPadding, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Profile Banner Card (Background Image) ──────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00629D).withValues(alpha: 0.3),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/images/background_baru.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                              child: Column(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: (90 * Responsive.scale(context)).clamp(72, 110),
                                        height: (90 * Responsive.scale(context)).clamp(72, 110),
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFFFF5722),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.4),
                                            width: 3.5,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(50),
                                          child: UserAvatar(
                                            size: (90 * Responsive.scale(context)).clamp(72, 110),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: -6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFB0F413),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x20000000),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.stars_rounded,
                                                size: 13,
                                                color: Color(0xFF131F00),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                (_loyalty?.tierLabel ?? 'Blue')
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF131F00),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    clerkAuth.displayName ?? 'Pengguna',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 22),
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    clerkAuth.email ?? 'Global Explore Member',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 13),
                                      color: Colors.white.withValues(alpha: 0.95),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatBox(
                                          context, _statValue(_stats?.trips), AppLocalizations.get('profile_total_trips'),
                                          customIcon: _buildSuitcaseIcon()),
                                      const SizedBox(width: 8),
                                      _buildStatBox(
                                          context, _statValue(_stats?.points), AppLocalizations.get('profile_points'),
                                          customIcon: _buildStarIcon()),
                                      const SizedBox(width: 8),
                                      _buildStatBox(
                                          context, _statValue(_stats?.reviews), AppLocalizations.get('profile_reviews'),
                                          customIcon: _buildReviewIcon()),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Account Dashboard Section Header ─────────────────
                    Text(
                      AppLocalizations.get('profile_dashboard'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Dashboard Group 1: Bookings, Payment, Wishlist ───
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDashboardItem(
                            customIcon: _buildBookingsIcon(),
                            iconBg: const Color(0xFFCFE5FF),
                            iconColor: const Color(0xFF004A78),
                            title: AppLocalizations.get('profile_my_bookings'),
                            subtitle: AppLocalizations.get('profile_my_bookings_sub'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const BookingListPage(showBackButton: true),
                                ),
                              );
                            },
                            isDark: isDark,
                          ),
                          _buildDashboardItem(
                            customIcon: _buildPassengerIcon(),
                            iconBg: const Color(0xFFFFE170).withValues(alpha: 0.35),
                            iconColor: const Color(0xFF544600),
                            title: AppLocalizations.get('profile_saved_passenger'),
                            subtitle: AppLocalizations.get('profile_saved_passenger_sub'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SavedPassengerPage(),
                                ),
                              );
                            },
                            isDark: isDark,
                          ),
                          _buildDashboardItem(
                            customIcon: _buildRewardsIcon(),
                            iconBg: const Color(0xFFFFD600).withValues(alpha: 0.25),
                            iconColor: const Color(0xFF705D00),
                            title: AppLocalizations.get('profile_rewards'),
                            subtitle: '${_formatPoints(_loyalty?.pointsBalance ?? 0)} pts • ${_loyalty?.tierLabel ?? 'Blue'} Member',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RewardsPage(),
                                ),
                              );
                            },
                            isDark: isDark,
                          ),
                          _buildDashboardItem(
                            customIcon: _buildPaymentIcon(),
                            iconBg: const Color(0xFFB0F413),
                            iconColor: const Color(0xFF354E00),
                            title: AppLocalizations.get('profile_payment_methods'),
                            subtitle: AppLocalizations.get('profile_payment_methods_sub'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PaymentMethodsPage(),
                                ),
                              );
                            },
                            isDark: isDark,
                          ),
                          _buildDashboardItem(
                            customIcon: _buildWishlistIcon(),
                            iconBg: const Color(0xFFFFDAD6),
                            iconColor: const Color(0xFF93000A),
                            title: AppLocalizations.get('profile_wishlist'),
                            subtitle: AppLocalizations.get('profile_wishlist_sub'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const SavedPage(showBackButton: true),
                                ),
                              );
                            },
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Dashboard Group 2: Settings & Support ────────────
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDashboardItem(
                            customIcon: _buildAppSettingsIcon(),
                            iconBg: isDark ? const Color(0xFF282D35) : const Color(0xFFEAE7E7),
                            iconColor: textSecondary,
                            title: AppLocalizations.get('profile_app_settings'),
                            subtitle: AppLocalizations.get('profile_app_settings_sub'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AppSettingsPage(),
                                ),
                              );
                            },
                            isDark: isDark,
                          ),
                          _buildDashboardItem(
                            customIcon: _buildSupportIcon(),
                            iconBg: isDark ? const Color(0xFF282D35) : const Color(0xFFEAE7E7),
                            iconColor: textSecondary,
                            title: AppLocalizations.get('profile_support'),
                            subtitle: AppLocalizations.get('profile_support_sub'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SupportPage(),
                                ),
                              );
                            },
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Loyalty Status Card ───────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/icon_loyalty_status.png',
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Loyalty Status',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text.rich(
                            _statsLoading || _loyalty == null
                                ? TextSpan(
                                    text: AppLocalizations.tr('Memuat status loyalitas…', 'Loading loyalty status…'),
                                    style: TextStyle(
                                        fontSize: 12.5, color: textSecondary),
                                  )
                                : _loyalty!.isMaxTier
                                    ? TextSpan(
                                        text: AppLocalizations.tr('Kamu sudah di tier tertinggi. Terima kasih! 🎉', 'You are at the highest tier. Thank you! 🎉'),
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            color: textSecondary),
                                      )
                                    : TextSpan(
                                        text: AppLocalizations.tr(
                                            'Belanja ${_formatRupiah(_loyalty!.remainingToNext)} lagi menuju ',
                                            'Spend ${_formatRupiah(_loyalty!.remainingToNext)} more to reach '),
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            color: textSecondary),
                                        children: [
                                          TextSpan(
                                            text:
                                                '${_loyalty!.nextTierLabel} Tier',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: textPrimary),
                                          ),
                                          const TextSpan(text: ' perks!'),
                                        ],
                                      ),
                          ),
                          const SizedBox(height: 14),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (_loyalty?.progressPct ?? 0) / 100.0,
                              minHeight: 8,
                              backgroundColor: isDark ? const Color(0xFF282D35) : const Color(0xFFEAE7E7),
                              color: const Color(0xFF1E9BF0),
                            ),
                          ),
                          const SizedBox(height: 6),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _loyalty?.tierLabel ?? 'Blue',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6F7883),
                                ),
                              ),
                              Text(
                                _loyalty?.nextTierLabel ?? 'Max',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6F7883),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Latest Wishlist Added Card (Bento Image Card) ─────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.get('profile_latest_wishlist'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                AppNetworkImage(
                                  src: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBkKSxKndhHO5n5IHTcQIoHVaPX8F-Ltd86lV009mTlbDw6QVUysw3DTdUsxrvHttuVWOyoGc0JfVSU8Q8Iv1N_rnqD-Gcf5y9yxwkKoLDGe_YMxeopClT1jzh_AFAmJG9e19ezaJy0fC9HEYrNldG5eaUbYgeof1dL058rrt8bjE1Ke_IDnYSEKdwnxXzQDaD8o-VpXE12_ztrXs154PtE9XqgwtiwAxsznGHE2jFX1lOE1011LPRPWSqoPLmUmVWp4KhEc3k2eAp9',
                                  fit: BoxFit.cover,
                                  placeholderIcon: Icons.landscape_rounded,
                                  placeholderIconColor: Colors.white54,
                                  errorIcon: Icons.landscape_rounded,
                                  errorIconColor: Colors.white54,
                                  iconSize: 48,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.75),
                                      ],
                                    ),
                                  ),
                                ),
                                const Positioned(
                                  bottom: 14,
                                  left: 14,
                                  right: 14,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Santorini, Greece',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Dream Vacation • 2024',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Sign Out Button ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _onSignOut,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: cardBg,
                          foregroundColor: const Color(0xFFBA1A1A),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: Text(
                          AppLocalizations.get('profile_sign_out'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNav(
            currentIndex: 4,
            onItemSelected: (index) {
              if (index == 0) {
                Navigator.popUntil(context, (route) => route.isFirst);
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
              }
            },
          ),
        );
      },
    );
  }

  /// Custom suitcase icon matching the user's SVG design.
  Widget _buildSuitcaseIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        size: const Size(20, 20),
        painter: _SuitcaseIconPainter(),
      ),
    );
  }

  /// Custom star icon matching the user's SVG design.
  Widget _buildStarIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        size: const Size(20, 20),
        painter: _StarIconPainter(),
      ),
    );
  }

  /// Custom review icon matching the user's SVG design (chat bubble + star).
  Widget _buildReviewIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        size: const Size(20, 20),
        painter: _ReviewIconPainter(),
      ),
    );
  }

  /// Custom bookings icon matching the user's SVG design (suitcase + ticket).
  Widget _buildBookingsIcon() {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        size: const Size(28, 28),
        painter: _BookingsIconPainter(),
      ),
    );
  }

  /// Custom passenger icon matching the user's SVG design (ID card).
  Widget _buildPassengerIcon() {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        size: const Size(28, 28),
        painter: _PassengerIconPainter(),
      ),
    );
  }

  /// Custom rewards icon matching the user's SVG design (gift box + coin).
  Widget _buildRewardsIcon() {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        size: const Size(28, 28),
        painter: _RewardsIconPainter(),
      ),
    );
  }

  /// Custom payment icon matching the user's SVG design (credit card).
  Widget _buildPaymentIcon() {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        size: const Size(28, 28),
        painter: _PaymentIconPainter(),
      ),
    );
  }

  /// Custom wishlist icon matching the user's SVG design (bookmark + heart).
  Widget _buildWishlistIcon() {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        size: const Size(28, 28),
        painter: _WishlistIconPainter(),
      ),
    );
  }

  /// Custom settings icon matching the user's SVG design (gear + slider).
  Widget _buildAppSettingsIcon() {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        size: const Size(28, 28),
        painter: _AppSettingsIconPainter(),
      ),
    );
  }

  /// Custom support icon matching the user's SVG design (headset).
  Widget _buildSupportIcon() {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        size: const Size(28, 28),
        painter: _SupportIconPainter(),
      ),
    );
  }

  // ── Stat Box Helper ──────────────────────────────────────────────────
  Widget _buildStatBox(BuildContext context, String value, String label,
      {IconData? icon, Widget? customIcon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (customIcon != null) ...[
              customIcon,
              const SizedBox(width: 5),
            ] else if (icon != null) ...[
              Icon(
                icon,
                color: const Color(0xFF00629D),
                size: Responsive.fontSize(context, 18),
              ),
              const SizedBox(width: 5),
            ],
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 16),
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 9),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF486581),
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Dashboard Item Row Helper ───────────────────────────────────────
  Widget _buildDashboardItem({
    IconData? icon,
    Widget? customIcon,
    Color? iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDark = false,
  }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1B1B);
    final textSecondary = isDark ? const Color(0xFF9FB3C8) : const Color(0xFF3F4851);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: customIcon ?? Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF6F7883),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuitcaseIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;

    // Body (blue gradient)
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF39B8FF), Color(0xFF1565D8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Lime gradient
    final limePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE8FF3A), Color(0xFFC6FF00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final dividerPaint = Paint()..color = Colors.white.withValues(alpha: 0.25);
    final linePaint = Paint()..color = Colors.white.withValues(alpha: 0.22);
    final outlinePaint = Paint()
      ..color = const Color(0xFF0E5BD6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;
    final wheelPaint = Paint()..color = const Color(0xFF22314D);
    final hubPaint = Paint()..color = const Color(0xFF7BAFFF);
    final lockCenterPaint = Paint()..color = const Color(0xFF1565D8);

    // Handle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(26 * s, 4 * s, 12 * s, 8 * s),
        Radius.circular(3 * s),
      ),
      limePaint,
    );

    // Handle outline
    final handlePath = Path()
      ..moveTo(24 * s, 12 * s)
      ..lineTo(24 * s, 10 * s)
      ..cubicTo(24 * s, 6.7 * s, 26.7 * s, 4 * s, 30 * s, 4 * s)
      ..lineTo(34 * s, 4 * s)
      ..cubicTo(37.3 * s, 4 * s, 40 * s, 6.7 * s, 40 * s, 10 * s)
      ..lineTo(40 * s, 12 * s);
    canvas.drawPath(handlePath, outlinePaint);

    // Suitcase body with drop shadow
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(14 * s, 12 * s, 36 * s, 42 * s),
      Radius.circular(7 * s),
    );
    canvas.drawRRect(
      bodyRect.shift(Offset(0, 2 * s)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * s),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Center divider
    canvas.drawRect(
      Rect.fromLTWH(31 * s, 12 * s, 2 * s, 42 * s),
      dividerPaint,
    );

    // Decorative lines
    for (final x in [20.0, 25.0, 37.0, 42.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * s, 18 * s, 2 * s, 30 * s),
          Radius.circular(1 * s),
        ),
        linePaint,
      );
    }

    // Lock
    canvas.drawCircle(Offset(32 * s, 32 * s), 3.5 * s, limePaint);
    canvas.drawCircle(Offset(32 * s, 32 * s), 1.3 * s, lockCenterPaint);

    // Wheels
    for (final cx in [22.0, 42.0]) {
      canvas.drawCircle(Offset(cx * s, 57 * s), 3 * s, wheelPaint);
      canvas.drawCircle(Offset(cx * s, 57 * s), 1.2 * s, hubPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 128;

    // Star fill (lime gradient)
    final starFillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF4FF62), Color(0xFFC8FF00)],
      ).createShader(Rect.fromLTRB(20 * s, 20 * s, 108 * s, 108 * s));

    // Star stroke (blue gradient)
    final starStrokePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4FC3FF), Color(0xFF1565D8)],
      ).createShader(Rect.fromLTRB(20 * s, 20 * s, 108 * s, 108 * s));

    final shadowPaint = Paint()
      ..color = const Color(0xFF1565D8).withValues(alpha: 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * s);

    final starPath = Path()
      ..moveTo(64 * s, 12 * s)
      ..lineTo(78.8 * s, 42 * s)
      ..lineTo(112 * s, 46.8 * s)
      ..lineTo(88 * s, 70 * s)
      ..lineTo(93.8 * s, 103 * s)
      ..lineTo(64 * s, 87.5 * s)
      ..lineTo(34.2 * s, 103 * s)
      ..lineTo(40 * s, 70 * s)
      ..lineTo(16 * s, 46.8 * s)
      ..lineTo(49.2 * s, 42 * s)
      ..close();

    // Star drop shadow
    canvas.drawPath(
      Path()..addPath(starPath, Offset(0, 6 * s)),
      shadowPaint,
    );

    // Star fill + stroke
    canvas.drawPath(starPath, starFillPaint);
    canvas.drawPath(
      starPath,
      Paint()
        ..shader = starStrokePaint.shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * s
        ..strokeJoin = StrokeJoin.round,
    );

    // Highlight arc
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * s
      ..strokeCap = StrokeCap.round;
    final highlightPath = Path()
      ..moveTo(50 * s, 33 * s)
      ..cubicTo(56 * s, 27 * s, 70 * s, 27 * s, 76 * s, 33 * s);
    canvas.drawPath(highlightPath, highlightPaint);

    // Sparkle
    final sparklePath = Path()
      ..moveTo(99 * s, 22 * s)
      ..lineTo(101 * s, 28 * s)
      ..lineTo(107 * s, 30 * s)
      ..lineTo(101 * s, 32 * s)
      ..lineTo(99 * s, 38 * s)
      ..lineTo(97 * s, 32 * s)
      ..lineTo(91 * s, 30 * s)
      ..lineTo(97 * s, 28 * s)
      ..close();

    // Sparkle + dots shadows
    canvas.drawPath(
      Path()..addPath(sparklePath, Offset(0, 6 * s)),
      shadowPaint,
    );
    canvas.drawCircle(Offset(30 * s, 94 * s), 2.8 * s, shadowPaint);
    canvas.drawCircle(Offset(100 * s, 82 * s), 2.5 * s, shadowPaint);

    canvas.drawPath(sparklePath, Paint()..color = const Color(0xFFD6FF34));
    canvas.drawCircle(Offset(30 * s, 94 * s), 2.8 * s, Paint()..color = const Color(0xFF8BD3FF));
    canvas.drawCircle(Offset(100 * s, 82 * s), 2.5 * s, Paint()..color = const Color(0xFFD6FF34));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReviewIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;

    // Chat bubble (blue gradient)
    final bluePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF38B6FF), Color(0xFF1565D8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Star (lime gradient)
    final limePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE9FF3A), Color(0xFFBFFF00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);

    final bubblePath = Path()
      ..moveTo(12 * s, 16 * s)
      ..cubicTo(12 * s, 12 * s, 15 * s, 9 * s, 19 * s, 9 * s)
      ..lineTo(45 * s, 9 * s)
      ..cubicTo(49 * s, 9 * s, 52 * s, 12 * s, 52 * s, 16 * s)
      ..lineTo(52 * s, 34 * s)
      ..cubicTo(52 * s, 38 * s, 49 * s, 41 * s, 45 * s, 41 * s)
      ..lineTo(28 * s, 41 * s)
      ..lineTo(19 * s, 49 * s)
      ..lineTo(19 * s, 41 * s)
      ..cubicTo(15 * s, 41 * s, 12 * s, 38 * s, 12 * s, 34 * s)
      ..close();

    // Chat bubble drop shadow
    canvas.drawPath(
      Path()..addPath(bubblePath, Offset(0, 2 * s)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * s),
    );
    canvas.drawPath(bubblePath, bluePaint);

    // Star
    final starPath = Path()
      ..moveTo(32 * s, 17 * s)
      ..lineTo(34.8 * s, 23 * s)
      ..lineTo(41.5 * s, 24 * s)
      ..lineTo(36.6 * s, 28.5 * s)
      ..lineTo(37.8 * s, 35 * s)
      ..lineTo(32 * s, 31.8 * s)
      ..lineTo(26.2 * s, 35 * s)
      ..lineTo(27.4 * s, 28.5 * s)
      ..lineTo(22.5 * s, 24 * s)
      ..lineTo(29.2 * s, 23 * s)
      ..close();
    canvas.drawPath(starPath, limePaint);

    // Rating dots
    canvas.drawCircle(Offset(22 * s, 38 * s), 1.5 * s, dotPaint);
    canvas.drawCircle(Offset(32 * s, 38 * s), 1.5 * s, dotPaint);
    canvas.drawCircle(Offset(42 * s, 38 * s), 1.5 * s, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BookingsIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;

    // Blue gradient
    final bluePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF38B6FF), Color(0xFF1565D8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Lime gradient
    final limePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE8FF3A), Color(0xFFC6FF00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final whitePaint = Paint()..color = Colors.white.withValues(alpha: 0.95);
    final dividerPaint = Paint()..color = Colors.white.withValues(alpha: 0.18);
    final perforationPaint = Paint()
      ..color = const Color(0xFF38B6FF)
      ..strokeWidth = 1.2 * s;
    final checkPaint = Paint()
      ..color = const Color(0xFF1565D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * s);

    // Suitcase
    final suitcaseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(12 * s, 16 * s, 40 * s, 34 * s),
      Radius.circular(6 * s),
    );
    canvas.drawRRect(suitcaseRect.shift(Offset(0, 2 * s)), shadowPaint);
    canvas.drawRRect(suitcaseRect, bluePaint);

    // Handle (lime stroke)
    final handlePath = Path()
      ..moveTo(24 * s, 16 * s)
      ..lineTo(24 * s, 12 * s)
      ..cubicTo(24 * s, 9.8 * s, 25.8 * s, 8 * s, 28 * s, 8 * s)
      ..lineTo(36 * s, 8 * s)
      ..cubicTo(38.2 * s, 8 * s, 40 * s, 9.8 * s, 40 * s, 12 * s)
      ..lineTo(40 * s, 16 * s);
    canvas.drawPath(
      handlePath,
      Paint()
        ..shader = limePaint.shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8 * s
        ..strokeCap = StrokeCap.round,
    );

    // Divider
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(31 * s, 16 * s, 2 * s, 34 * s),
        Radius.circular(1 * s),
      ),
      dividerPaint,
    );

    // Ticket
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(18 * s, 23 * s, 18 * s, 10 * s),
        Radius.circular(2 * s),
      ),
      whitePaint,
    );

    // Ticket perforation (dashes)
    const dashLen = 1.5;
    var y = 24.0;
    while (y < 32.0) {
      final end = y + dashLen <= 32.0 ? y + dashLen : 32.0;
      canvas.drawLine(
        Offset(27 * s, y * s),
        Offset(27 * s, end * s),
        perforationPaint,
      );
      y += dashLen * 2;
    }

    // Check badge
    canvas.drawCircle(Offset(44 * s, 42 * s), 8 * s, limePaint);

    // Check mark
    final checkPath = Path()
      ..moveTo(40.5 * s, 42 * s)
      ..lineTo(43 * s, 44.5 * s)
      ..lineTo(47.5 * s, 39.8 * s);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PassengerIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;

    // Blue gradient
    final bluePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF39B8FF), Color(0xFF1565D8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Lime gradient
    final limePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE9FF3A), Color(0xFFC8FF00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()..color = Colors.white;
    final checkPaint = Paint()
      ..color = const Color(0xFF1565D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * s);

    // Card
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8 * s, 12 * s, 48 * s, 40 * s),
      Radius.circular(8 * s),
    );
    canvas.drawRRect(cardRect.shift(Offset(0, 2 * s)), shadowPaint);
    canvas.drawRRect(cardRect, bluePaint);

    // Avatar
    canvas.drawCircle(Offset(23 * s, 25 * s), 6 * s, limePaint);
    final avatarBody = Path()
      ..moveTo(15 * s, 38 * s)
      ..cubicTo(15 * s, 33.5 * s, 19 * s, 31 * s, 23 * s, 31 * s)
      ..cubicTo(27 * s, 31 * s, 31 * s, 33.5 * s, 31 * s, 38 * s)
      ..close();
    canvas.drawPath(avatarBody, limePaint);

    // Info lines
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(36 * s, 22 * s, 12 * s, 3 * s),
        Radius.circular(1.5 * s),
      ),
      linePaint..color = Colors.white.withValues(alpha: 0.95),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(36 * s, 29 * s, 10 * s, 3 * s),
        Radius.circular(1.5 * s),
      ),
      linePaint..color = Colors.white.withValues(alpha: 0.75),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(36 * s, 36 * s, 8 * s, 3 * s),
        Radius.circular(1.5 * s),
      ),
      linePaint..color = Colors.white.withValues(alpha: 0.55),
    );

    // Check badge
    canvas.drawCircle(Offset(48 * s, 46 * s), 7 * s, limePaint);

    // Check mark
    final checkPath = Path()
      ..moveTo(45.2 * s, 46 * s)
      ..lineTo(47.3 * s, 48.2 * s)
      ..lineTo(51 * s, 43.8 * s);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RewardsIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;

    // Blue gradient
    final bluePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF42C4FF), Color(0xFF1565D8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Lime gradient
    final limePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF2FF59), Color(0xFFC8FF00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final ribbonPaint = Paint()..color = Colors.white.withValues(alpha: 0.95);
    final starPaint = Paint()..color = const Color(0xFF1565D8);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * s);

    // Gift box
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(14 * s, 22 * s, 36 * s, 28 * s),
      Radius.circular(6 * s),
    );
    canvas.drawRRect(boxRect.shift(Offset(0, 2 * s)), shadowPaint);
    canvas.drawRRect(boxRect, bluePaint);

    // Lid
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12 * s, 18 * s, 40 * s, 8 * s),
        Radius.circular(4 * s),
      ),
      limePaint,
    );

    // Ribbon vertical
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(30 * s, 18 * s, 4 * s, 32 * s),
        Radius.circular(2 * s),
      ),
      ribbonPaint,
    );

    // Ribbon horizontal
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(14 * s, 30 * s, 36 * s, 4 * s),
        Radius.circular(2 * s),
      ),
      ribbonPaint,
    );

    // Coin
    canvas.drawCircle(Offset(47 * s, 47 * s), 8 * s, limePaint);

    // Star
    final starPath = Path()
      ..moveTo(47 * s, 41.8 * s)
      ..lineTo(48.7 * s, 45.2 * s)
      ..lineTo(52.4 * s, 45.7 * s)
      ..lineTo(49.7 * s, 48.3 * s)
      ..lineTo(50.4 * s, 52 * s)
      ..lineTo(47 * s, 50.2 * s)
      ..lineTo(43.6 * s, 52 * s)
      ..lineTo(44.3 * s, 48.3 * s)
      ..lineTo(41.6 * s, 45.7 * s)
      ..lineTo(45.3 * s, 45.2 * s)
      ..close();
    canvas.drawPath(starPath, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PaymentIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;

    // Blue gradient
    final bluePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF42C4FF), Color(0xFF1565D8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Lime gradient
    final limePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF2FF59), Color(0xFFC8FF00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final stripePaint = Paint()..color = const Color(0xFF0F57C7).withValues(alpha: 0.35);
    final linePaint = Paint()..color = Colors.white;
    final checkPaint = Paint()
      ..color = const Color(0xFF1565D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * s);

    // Card
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10 * s, 14 * s, 44 * s, 30 * s),
      Radius.circular(6 * s),
    );
    canvas.drawRRect(cardRect.shift(Offset(0, 2 * s)), shadowPaint);
    canvas.drawRRect(cardRect, bluePaint);

    // Stripe
    canvas.drawRect(
      Rect.fromLTWH(10 * s, 20 * s, 44 * s, 6 * s),
      stripePaint,
    );

    // Chip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(16 * s, 30 * s, 8 * s, 6 * s),
        Radius.circular(1.5 * s),
      ),
      limePaint,
    );

    // Card lines
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(28 * s, 31 * s, 16 * s, 2.5 * s),
        Radius.circular(1.2 * s),
      ),
      linePaint..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(28 * s, 36 * s, 10 * s, 2.5 * s),
        Radius.circular(1.2 * s),
      ),
      linePaint..color = Colors.white.withValues(alpha: 0.6),
    );

    // Check badge
    canvas.drawCircle(Offset(48 * s, 46 * s), 8 * s, limePaint);

    // Check mark
    final checkPath = Path()
      ..moveTo(45 * s, 46 * s)
      ..lineTo(47.4 * s, 48.4 * s)
      ..lineTo(51.5 * s, 43.8 * s);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WishlistIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;

    // Blue gradient
    final bluePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF45C3FF), Color(0xFF1565D8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Lime gradient
    final limePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF4FF62), Color(0xFFC8FF00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * s);

    // Bookmark
    final bookmarkPath = Path()
      ..moveTo(18 * s, 10 * s)
      ..lineTo(46 * s, 10 * s)
      ..cubicTo(49.3 * s, 10 * s, 52 * s, 12.7 * s, 52 * s, 16 * s)
      ..lineTo(52 * s, 52 * s)
      ..lineTo(32 * s, 42 * s)
      ..lineTo(12 * s, 52 * s)
      ..lineTo(12 * s, 16 * s)
      ..cubicTo(12 * s, 12.7 * s, 14.7 * s, 10 * s, 18 * s, 10 * s)
      ..close();

    canvas.drawPath(
      Path()..addPath(bookmarkPath, Offset(0, 2 * s)),
      shadowPaint,
    );
    canvas.drawPath(bookmarkPath, bluePaint);

    // Heart
    final heartPath = Path()
      ..moveTo(32 * s, 34 * s)
      ..cubicTo(28.8 * s, 31.2 * s, 22 * s, 26.8 * s, 22 * s, 21.8 * s)
      ..cubicTo(22 * s, 18.7 * s, 24.5 * s, 16 * s, 27.6 * s, 16 * s)
      ..cubicTo(29.7 * s, 16 * s, 31.2 * s, 17 * s, 32 * s, 18.4 * s)
      ..cubicTo(32.8 * s, 17 * s, 34.3 * s, 16 * s, 36.4 * s, 16 * s)
      ..cubicTo(39.5 * s, 16 * s, 42 * s, 18.7 * s, 42 * s, 21.8 * s)
      ..cubicTo(42 * s, 26.8 * s, 35.2 * s, 31.2 * s, 32 * s, 34 * s)
      ..close();
    canvas.drawPath(heartPath, limePaint);

    // Shine
    final shinePath = Path()
      ..moveTo(25 * s, 15 * s)
      ..cubicTo(27 * s, 13 * s, 31 * s, 12 * s, 35 * s, 13 * s);
    canvas.drawPath(shinePath, shinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AppSettingsIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;

    // Blue gradient
    final bluePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF42C4FF), Color(0xFF1565D8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Lime gradient
    final limePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF4FF62), Color(0xFFC8FF00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final darkBluePaint = Paint()..color = const Color(0xFF1565D8);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * s);

    // Gear
    final gearPath = Path()
      ..moveTo(32 * s, 12 * s)
      ..lineTo(36 * s, 14 * s)
      ..lineTo(41 * s, 12 * s)
      ..lineTo(44 * s, 16 * s)
      ..lineTo(49 * s, 17 * s)
      ..lineTo(49 * s, 23 * s)
      ..lineTo(53 * s, 27 * s)
      ..lineTo(50 * s, 32 * s)
      ..lineTo(53 * s, 37 * s)
      ..lineTo(49 * s, 41 * s)
      ..lineTo(49 * s, 47 * s)
      ..lineTo(44 * s, 48 * s)
      ..lineTo(41 * s, 52 * s)
      ..lineTo(36 * s, 50 * s)
      ..lineTo(32 * s, 52 * s)
      ..lineTo(28 * s, 50 * s)
      ..lineTo(23 * s, 52 * s)
      ..lineTo(20 * s, 48 * s)
      ..lineTo(15 * s, 47 * s)
      ..lineTo(15 * s, 41 * s)
      ..lineTo(11 * s, 37 * s)
      ..lineTo(14 * s, 32 * s)
      ..lineTo(11 * s, 27 * s)
      ..lineTo(15 * s, 23 * s)
      ..lineTo(15 * s, 17 * s)
      ..lineTo(20 * s, 16 * s)
      ..lineTo(23 * s, 12 * s)
      ..lineTo(28 * s, 14 * s)
      ..close();

    canvas.drawPath(
      Path()..addPath(gearPath, Offset(0, 2 * s)),
      shadowPaint,
    );
    canvas.drawPath(gearPath, bluePaint);

    // Center
    canvas.drawCircle(Offset(32 * s, 32 * s), 9 * s, limePaint);
    canvas.drawCircle(Offset(32 * s, 32 * s), 3 * s, darkBluePaint);

    // Slider accent
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(43 * s, 10 * s, 4 * s, 18 * s),
        Radius.circular(2 * s),
      ),
      limePaint,
    );
    canvas.drawCircle(Offset(45 * s, 21 * s), 4 * s, darkBluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SupportIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;

    // Blue gradient
    final bluePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF42C4FF), Color(0xFF1565D8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Lime gradient
    final limePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF4FF62), Color(0xFFC8FF00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final darkBluePaint = Paint()..color = const Color(0xFF1565D8);
    final strokePaint = Paint()
      ..shader = limePaint.shader
      ..style = PaintingStyle.stroke;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * s);

    // Chat bubble
    final bubblePath = Path()
      ..moveTo(14 * s, 16 * s)
      ..cubicTo(14 * s, 12.7 * s, 16.7 * s, 10 * s, 20 * s, 10 * s)
      ..lineTo(44 * s, 10 * s)
      ..cubicTo(47.3 * s, 10 * s, 50 * s, 12.7 * s, 50 * s, 16 * s)
      ..lineTo(50 * s, 34 * s)
      ..cubicTo(50 * s, 37.3 * s, 47.3 * s, 40 * s, 44 * s, 40 * s)
      ..lineTo(30 * s, 40 * s)
      ..lineTo(22 * s, 48 * s)
      ..lineTo(22 * s, 40 * s)
      ..lineTo(20 * s, 40 * s)
      ..cubicTo(16.7 * s, 40 * s, 14 * s, 37.3 * s, 14 * s, 34 * s)
      ..close();

    canvas.drawPath(
      Path()..addPath(bubblePath, Offset(0, 2 * s)),
      shadowPaint,
    );
    canvas.drawPath(bubblePath, bluePaint);

    // Headset
    final headsetPath = Path()
      ..moveTo(24 * s, 28 * s)
      ..cubicTo(24 * s, 22.5 * s, 27.8 * s, 19 * s, 32 * s, 19 * s)
      ..cubicTo(36.2 * s, 19 * s, 40 * s, 22.5 * s, 40 * s, 28 * s);
    canvas.drawPath(
      headsetPath,
      strokePaint
        ..strokeWidth = 3 * s
        ..strokeCap = StrokeCap.round,
    );

    // Ear cups
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(22 * s, 27 * s, 4 * s, 10 * s),
        Radius.circular(2 * s),
      ),
      limePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(38 * s, 27 * s, 4 * s, 10 * s),
        Radius.circular(2 * s),
      ),
      limePaint,
    );

    // Mic
    final micPath = Path()
      ..moveTo(40 * s, 35 * s)
      ..lineTo(45 * s, 35 * s)
      ..cubicTo(46.5 * s, 35 * s, 48 * s, 36.2 * s, 48 * s, 38 * s)
      ..cubicTo(48 * s, 40 * s, 46.5 * s, 41 * s, 45 * s, 41 * s)
      ..lineTo(40 * s, 41 * s);
    canvas.drawPath(
      micPath,
      strokePaint
        ..strokeWidth = 2.5 * s
        ..strokeCap = StrokeCap.round,
    );

    // Notification
    canvas.drawCircle(Offset(48 * s, 16 * s), 4 * s, limePaint);
    canvas.drawCircle(Offset(48 * s, 16 * s), 1.3 * s, darkBluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
