import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/website_loader.dart';
import '../../../auth/data/user_remote_data_source.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final _userSource = UserRemoteDataSource();
  UserStats? _stats;
  UserLoyalty? _loyalty;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _userSource.fetchStats().catchError((_) => UserStats.empty),
      _userSource.fetchLoyalty().catchError((_) => UserLoyalty.empty),
    ]);
    if (mounted) {
      setState(() {
        _stats = results[0] as UserStats;
        _loyalty = results[1] as UserLoyalty;
        _loading = false;
      });
    }
  }

  /// Format angka ke "1.234" / "Rp1.234.567".
  String _thousands(int value) {
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
    final s = Responsive.scale(context);
    final hPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.azureSky),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rewards & Points',
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: Responsive.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1B1B),
          ),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? _buildLoadingSkeleton()
          : SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Section: Membership Card ────────────────────────
            _buildMembershipCard(context, s),

            const SizedBox(height: 28),

            // ── Redeem Section: Tukarkan Poin ─────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tukarkan Poin',
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: Responsive.fontSize(context, 20),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.azureSky,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bento Grid for Rewards
            _buildRewardsBentoGrid(context),

            const SizedBox(height: 32),

            // ── History Section: Riwayat Poin ────────────────────────
            Text(
              'Riwayat Poin',
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: Responsive.fontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Riwayat poin nyata belum tersedia (menunggu ledger poin — fase 2).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 34, color: AppColors.onSurfaceVariant),
                  const SizedBox(height: 10),
                  Text(
                    'Belum ada riwayat poin',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14),
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Poin dari transaksimu akan muncul di sini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: AppColors.onSurfaceVariant,
                side: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.6),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.history_rounded, size: 20),
              label: const Text(
                'Lihat Semua Riwayat',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ShimmerLoader(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context),
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Membership Card skeleton ─────────────────────────────
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 140, height: 24, borderRadius: 12),
                  SizedBox(height: 18),
                  SkeletonBox(width: 90, height: 12),
                  SizedBox(height: 6),
                  SkeletonBox(width: 150, height: 32),
                  Spacer(),
                  SkeletonBox(width: 180, height: 12),
                  SizedBox(height: 10),
                  SkeletonBox(height: 8, width: double.infinity, borderRadius: 4),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── "Tukarkan Poin" header skeleton ───────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonBox(width: 140, height: 20),
                SkeletonBox(width: 80, height: 16),
              ],
            ),
            const SizedBox(height: 12),

            // ── Bento grid skeleton ───────────────────────────────────
            const SkeletonBox(height: 130, width: double.infinity, borderRadius: 24),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                  child: SkeletonBox(height: 140, width: double.infinity, borderRadius: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SkeletonBox(height: 140, width: double.infinity, borderRadius: 24),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── "Riwayat Poin" skeleton ───────────────────────────────
            const SkeletonBox(width: 120, height: 20),
            const SizedBox(height: 12),
            const SkeletonBox(height: 130, width: double.infinity, borderRadius: 16),
            const SizedBox(height: 16),
            const SkeletonBox(height: 50, width: double.infinity, borderRadius: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipCard(BuildContext context, double s) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background ambient glow circles
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.azureSky.withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.solarFlare.withValues(alpha: 0.15),
              ),
            ),
          ),

          // Card Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.solarFlare.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.solarFlare.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          size: 16,
                          color: AppColors.solarFlare,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_loyalty?.tierLabel ?? 'Blue'} Member',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.solarFlare,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'TOTAL POIN',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 11),
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _loading ? '—' : _thousands(_stats?.points ?? 0),
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: Responsive.fontSize(context, 36),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _loyalty?.isMaxTier == true
                        ? 'Tier tertinggi'
                        : 'Menuju ${_loyalty?.nextTierLabel ?? 'Silver'}',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  if (_loyalty?.isMaxTier != true)
                    RichText(
                      text: TextSpan(
                        text:
                            'Rp${_thousands(_loyalty?.remainingToNext ?? 0)} ',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        children: const [
                          TextSpan(
                            text: 'lagi',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 8,
                  width: double.infinity,
                  color: Colors.white.withValues(alpha: 0.15),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (_loyalty?.progressPct ?? 0) / 100.0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.azureSky, AppColors.solarFlare],
                        ),
                      ),
                    ),
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

  Widget _buildRewardsBentoGrid(BuildContext context) {
    return Column(
      children: [
        // Large Featured Card (Full Width)
        _buildBentoFeaturedCard(
          context,
          customIcon: _buildBedIcon(),
          title: 'Voucher Hotel Rp 100.000',
          subtitle: 'Min. transaksi 500rb di seluruh hotel partner.',
          points: '1,000 Poin',
        ),
        const SizedBox(height: 12),

        // 2 Square Cards Row
        Row(
          children: [
            Expanded(
              child: _buildBentoSquareCard(
                context,
                customIcon: _buildPlaneIcon(),
                iconBg: AppColors.secondaryContainer.withValues(alpha: 0.3),
                iconColor: AppColors.secondary,
                title: 'Diskon Pesawat 5%',
                subtitle: 'Domestik & Int\'l',
                points: '850 Poin',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoSquareCard(
                context,
                customIcon: _buildMerchantIcon(),
                iconBg: const Color(0xFFFFE170).withValues(alpha: 0.35),
                iconColor: const Color(0xFF705D00),
                title: 'Merchant Partner',
                subtitle: 'F&B, Retail',
                points: '500 Poin',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoFeaturedCard(
    BuildContext context, {
    IconData? icon,
    Widget? customIcon,
    required String title,
    required String subtitle,
    required String points,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: customIcon ?? Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: Responsive.fontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 12.5),
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                points,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoSquareCard(
    BuildContext context, {
    IconData? icon,
    Widget? customIcon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String points,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: customIcon ?? Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 13.5),
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 10.5),
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            points,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 13),
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Custom merchant/store icon matching the user's SVG design.
  Widget _buildMerchantIcon() {
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        size: const Size(32, 32),
        painter: _MerchantIconPainter(),
      ),
    );
  }

  /// Custom plane icon matching the user's SVG design (gradient paper plane).
  Widget _buildPlaneIcon() {
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        size: const Size(32, 32),
        painter: _PlaneIconPainter(),
      ),
    );
  }

  /// Custom bed icon matching the user's SVG design (blue bed + lime pillow).
  Widget _buildBedIcon() {
    return SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(
        size: const Size(36, 36),
        painter: _BedIconPainter(),
      ),
    );
  }
}

class _BedIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 64;

    // Blue gradient
    final bluePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2EA8FF), Color(0xFF1565D8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Lime gradient
    final limePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD8FF3F), Color(0xFFB8F000)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final darkBluePaint = Paint()..color = const Color(0xFF0E5BD6);
    final blanketPaint = Paint()..color = const Color(0x1FFFFFFF);

    // Headboard
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6 * scale, 18 * scale, 6 * scale, 30 * scale),
        Radius.circular(2 * scale),
      ),
      bluePaint,
    );

    // Mattress
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12 * scale, 24 * scale, 44 * scale, 18 * scale),
        Radius.circular(5 * scale),
      ),
      bluePaint,
    );

    // Blanket accent
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(27 * scale, 24 * scale, 29 * scale, 18 * scale),
        Radius.circular(5 * scale),
      ),
      blanketPaint,
    );

    // Pillow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(15 * scale, 27 * scale, 12 * scale, 8 * scale),
        Radius.circular(3 * scale),
      ),
      limePaint,
    );

    // Lime accent line
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12 * scale, 40 * scale, 44 * scale, 2 * scale),
        Radius.circular(1 * scale),
      ),
      limePaint,
    );

    // Bed frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6 * scale, 42 * scale, 52 * scale, 5 * scale),
        Radius.circular(2.5 * scale),
      ),
      darkBluePaint,
    );

    // Legs
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8 * scale, 47 * scale, 3 * scale, 8 * scale),
        Radius.circular(1.5 * scale),
      ),
      darkBluePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(53 * scale, 47 * scale, 3 * scale, 8 * scale),
        Radius.circular(1.5 * scale),
      ),
      darkBluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MerchantIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;

    // Blue gradient
    final bluePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2EA8FF), Color(0xFF1565D8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Lime gradient
    final limePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE4FF3A), Color(0xFFBFFF00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final darkBluePaint = Paint()..color = const Color(0xFF0F5DD9);
    final whitePaint = Paint()..color = const Color(0xF2FFFFFF);

    // Store body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10 * s, 22 * s, 44 * s, 28 * s),
        Radius.circular(5 * s),
      ),
      bluePaint,
    );

    // Awning
    final awningPath = Path()
      ..moveTo(12 * s, 18 * s)
      ..lineTo(52 * s, 18 * s)
      ..lineTo(49 * s, 25 * s)
      ..lineTo(15 * s, 25 * s)
      ..close();
    canvas.drawPath(awningPath, limePaint);

    // Door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(27 * s, 33 * s, 10 * s, 17 * s),
        Radius.circular(2 * s),
      ),
      darkBluePaint,
    );

    // Left window
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(16 * s, 31 * s, 7 * s, 7 * s),
        Radius.circular(2 * s),
      ),
      whitePaint,
    );

    // Right window
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(41 * s, 31 * s, 7 * s, 7 * s),
        Radius.circular(2 * s),
      ),
      whitePaint,
    );

    // Handshake lines (blue)
    final blueStroke = Paint()
      ..shader = bluePaint.shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;

    final handshake1 = Path()
      ..moveTo(24 * s, 16 * s)
      ..cubicTo(26 * s, 14 * s, 28 * s, 13 * s, 30 * s, 13 * s)
      ..cubicTo(32 * s, 13 * s, 34 * s, 14 * s, 37 * s, 16 * s);
    canvas.drawPath(handshake1, blueStroke);

    // Handshake lines (lime)
    final limeStroke = Paint()
      ..shader = limePaint.shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final handshake2 = Path()
      ..moveTo(26 * s, 16 * s)
      ..cubicTo(28 * s, 18 * s, 29 * s, 19 * s, 31 * s, 19 * s)
      ..cubicTo(33 * s, 19 * s, 34 * s, 18 * s, 37 * s, 16 * s);
    canvas.drawPath(handshake2, limeStroke);

    // Sparkles
    canvas.drawCircle(Offset(17 * s, 13 * s), 1.2 * s, limePaint);
    canvas.drawCircle(Offset(47 * s, 12 * s), 1.2 * s, limePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlaneIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512;

    // Body (blue gradient)
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF48C2FF), Color(0xFF1565D8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Accent (lime gradient)
    final accentPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE8FF3A), Color(0xFFC6FF00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);

    // Drop shadow
    final shadowPath = Path()..addPath(_bodyPath(s), Offset(0, 8 * s));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * s),
    );

    // Body
    canvas.drawPath(_bodyPath(s), bodyPaint);

    // Cockpit
    canvas.drawPath(_cockpitPath(s), accentPaint);

    // Windows
    canvas.drawCircle(Offset(256 * s, 118 * s), 6 * s, whitePaint);
    canvas.drawCircle(Offset(256 * s, 145 * s), 6 * s, whitePaint);
    canvas.drawCircle(Offset(256 * s, 172 * s), 6 * s, whitePaint);

    // Engines
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(145 * s, 188 * s, 26 * s, 64 * s),
        Radius.circular(13 * s),
      ),
      accentPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(341 * s, 188 * s, 26 * s, 64 * s),
        Radius.circular(13 * s),
      ),
      accentPaint,
    );

    // Tail accent
    canvas.drawPath(_tailPath(s), accentPaint);
  }

  Path _bodyPath(double s) => Path()
    ..moveTo(448 * s, 72 * s)
    ..cubicTo(465 * s, 72 * s, 480 * s, 87 * s, 480 * s, 104 * s)
    ..cubicTo(480 * s, 118 * s, 472 * s, 131 * s, 460 * s, 138 * s)
    ..lineTo(320 * s, 222 * s)
    ..lineTo(320 * s, 394 * s)
    ..lineTo(362 * s, 446 * s)
    ..cubicTo(366 * s, 451 * s, 364 * s, 460 * s, 358 * s, 463 * s)
    ..lineTo(336 * s, 474 * s)
    ..cubicTo(330 * s, 477 * s, 322 * s, 476 * s, 317 * s, 471 * s)
    ..lineTo(256 * s, 410 * s)
    ..lineTo(195 * s, 471 * s)
    ..cubicTo(190 * s, 476 * s, 182 * s, 477 * s, 176 * s, 474 * s)
    ..lineTo(154 * s, 463 * s)
    ..cubicTo(148 * s, 460 * s, 146 * s, 451 * s, 150 * s, 446 * s)
    ..lineTo(192 * s, 394 * s)
    ..lineTo(192 * s, 222 * s)
    ..lineTo(52 * s, 138 * s)
    ..cubicTo(40 * s, 131 * s, 32 * s, 118 * s, 32 * s, 104 * s)
    ..cubicTo(32 * s, 87 * s, 47 * s, 72 * s, 64 * s, 72 * s)
    ..lineTo(192 * s, 110 * s)
    ..lineTo(192 * s, 60 * s)
    ..cubicTo(192 * s, 27 * s, 219 * s, 0 * s, 256 * s, 0 * s)
    ..cubicTo(293 * s, 0 * s, 320 * s, 27 * s, 320 * s, 60 * s)
    ..lineTo(320 * s, 110 * s)
    ..close();

  Path _cockpitPath(double s) => Path()
    ..moveTo(256 * s, 24 * s)
    ..cubicTo(276 * s, 24 * s, 291 * s, 39 * s, 291 * s, 59 * s)
    ..cubicTo(291 * s, 68 * s, 287 * s, 77 * s, 281 * s, 83 * s)
    ..lineTo(231 * s, 83 * s)
    ..cubicTo(225 * s, 77 * s, 221 * s, 68 * s, 221 * s, 59 * s)
    ..cubicTo(221 * s, 39 * s, 236 * s, 24 * s, 256 * s, 24 * s)
    ..close();

  Path _tailPath(double s) => Path()
    ..moveTo(226 * s, 388 * s)
    ..lineTo(286 * s, 388 * s)
    ..lineTo(256 * s, 426 * s)
    ..close();

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
