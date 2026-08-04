import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/auth/clerk_auth_service.dart';
import '../auth/presentation/pages/login_page.dart';
import '../home/presentation/pages/home_page.dart';

/// Welcoming screen: pesawat mengelilingi bumi (native Flutter, ringan) dengan
/// branding "GMM Global Explore". Setelah animasi singkat, otomatis pindah ke
/// Home (bila sudah login) atau Login.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbit; // rotasi pesawat mengorbit
  late final AnimationController _intro; // fade/scale saat masuk
  late final Future<void> _initFuture; // inisialisasi Clerk (background)

  @override
  void initState() {
    super.initState();
    // Init Clerk berjalan di background selagi animasi welcome tampil, sehingga
    // tak ada layar kosong menunggu — begitu selesai, langsung tahu status login.
    _initFuture = _initClerk();

    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // Auto-navigasi setelah welcome tampil sebentar.
    Future.delayed(const Duration(milliseconds: 3200), _goNext);
  }

  Future<void> _initClerk() async {
    try {
      await clerkAuth.initialize();
    } catch (e) {
      debugPrint('Clerk init gagal: $e');
    }
  }

  Future<void> _goNext() async {
    await _initFuture; // pastikan status login sudah diketahui
    if (!mounted) return;
    // Sudah login → Home (punya loading sendiri). Belum → Login.
    final Widget next =
        clerkAuth.isSignedIn.value ? const HomePage() : const LoginPage();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _orbit.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF012242), Color(0xFF00558C), Color(0xFF1E9BF0)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _intro, curve: Curves.easeOut),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(flex: 2),
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.85, end: 1).animate(
                      CurvedAnimation(parent: _intro, curve: Curves.easeOutBack),
                    ),
                    child: _buildOrbit(),
                  ),
                  const SizedBox(height: 40),
                  _buildBrand(),
                  const SizedBox(height: 10),
                  Text(
                    'Your Trusted Travel Partner',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 0.4,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const Spacer(flex: 2),
                  _buildLoadingDots(),
                  const SizedBox(height: 8),
                  Text(
                    'Menyiapkan perjalananmu…',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Bumi + pesawat mengorbit ─────────────────────────────────────────
  Widget _buildOrbit() {
    const globeSize = 150.0;
    const orbitRx = 128.0; // radius horizontal orbit (elips = kesan 3D)
    const orbitRy = 60.0; // radius vertikal orbit
    const planeSize = 34.0;

    return SizedBox(
      width: orbitRx * 2 + planeSize,
      height: globeSize + orbitRy, // cukup untuk orbit atas/bawah
      child: AnimatedBuilder(
        animation: _orbit,
        builder: (context, _) {
          final a = _orbit.value * 2 * math.pi;
          final dx = orbitRx * math.cos(a);
          final dy = orbitRy * math.sin(a);
          // Bagian atas orbit (sin < 0) = di belakang bumi.
          final isBehind = math.sin(a) < 0;
          // Arah hadap pesawat mengikuti garis singgung orbit.
          final vx = -orbitRx * math.sin(a);
          final vy = orbitRy * math.cos(a);
          final planeAngle = math.atan2(vy, vx) + math.pi / 2;
          final scale = isBehind ? 0.72 : 1.0;

          Widget plane() => Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(
                  angle: planeAngle,
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: isBehind ? 0.65 : 1,
                      child: const Icon(
                        Icons.flight_rounded,
                        size: planeSize,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Color(0x66000000), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              );

          return Stack(
            alignment: Alignment.center,
            children: [
              // Jejak orbit (elips putus-putus)
              SizedBox(
                width: orbitRx * 2,
                height: orbitRy * 2,
                child: CustomPaint(painter: _OrbitPainter()),
              ),
              if (isBehind) plane(),
              SizedBox(
                width: globeSize,
                height: globeSize,
                child: CustomPaint(painter: _GlobePainter(_orbit.value)),
              ),
              if (!isBehind) plane(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrand() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'GMM Global ',
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD600), Color(0xFFFF9100)],
          ).createShader(bounds),
          child: const Text(
            'Explore',
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _orbit,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            // Gelombang opacity berjalan antar titik.
            final phase = (_orbit.value * 3 - i * 0.33) % 1.0;
            final op = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: op.clamp(0.0, 1.0)),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Bumi bergaya wireframe (gradient bola + garis lintang/bujur berputar).
class _GlobePainter extends CustomPainter {
  final double t; // 0..1
  _GlobePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Cahaya luar (glow)
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7CC5FF).withValues(alpha: 0.45),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r * 1.5));
    canvas.drawCircle(c, r * 1.5, glow);

    // Bola bumi
    final sphere = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.4, -0.5),
        radius: 1.15,
        colors: [Color(0xFF6FC0FF), Color(0xFF1E9BF0), Color(0xFF003E6B)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, sphere);

    // Garis grid (dipotong lingkaran bola)
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: 0.22);

    // Lintang (elips pipih)
    for (var i = -2; i <= 2; i++) {
      final oy = i * (r / 3);
      final w = math.sqrt(math.max(0, r * r - oy * oy));
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(c.dx, c.dy + oy), width: w * 2, height: w * 0.6),
        line,
      );
    }
    // Bujur (elips vertikal yang "berputar")
    for (var i = 0; i < 6; i++) {
      final phase = (i / 6 + t) % 1.0;
      final rx = (math.cos(phase * math.pi * 2)).abs() * r;
      canvas.drawOval(
        Rect.fromCenter(center: c, width: rx * 2, height: r * 2),
        line,
      );
    }
    canvas.restore();

    // Tepi bola
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_GlobePainter old) => old.t != t;
}

/// Jejak orbit elips putus-putus.
class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()..addOval(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.3);

    const dash = 7.0;
    const gap = 7.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => false;
}
