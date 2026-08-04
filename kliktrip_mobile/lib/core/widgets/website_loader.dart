import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Loading Screen Overlay matching website's `route-loader` design.
class WebsiteRouteLoader extends StatefulWidget {
  final bool isLoading;
  final Widget child;
  final String text;

  const WebsiteRouteLoader({
    super.key,
    required this.isLoading,
    required this.child,
    this.text = 'Memuat halaman…',
  });

  @override
  State<WebsiteRouteLoader> createState() => _WebsiteRouteLoaderState();
}

class _WebsiteRouteLoaderState extends State<WebsiteRouteLoader> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: const Color(0x8C0F172A), // rgba(15, 23, 42, 0.55)
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const InfinityAnimatedLoader(size: 56, color: AppColors.azureSky),
                        const SizedBox(height: 16),
                        Text(
                          widget.text,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.3,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Infinity Animated Loader SVG Painter matching `infinity-loader.component.ts`
class InfinityAnimatedLoader extends StatefulWidget {
  final double size;
  final Color color;
  const InfinityAnimatedLoader({super.key, this.size = 56, this.color = AppColors.azureSky});

  @override
  State<InfinityAnimatedLoader> createState() => _InfinityAnimatedLoaderState();
}

class _InfinityAnimatedLoaderState extends State<InfinityAnimatedLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _InfinityLoaderPainter(
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _InfinityLoaderPainter extends CustomPainter {
  final double progress;
  final Color color;

  _InfinityLoaderPainter({required this.progress, required this.color});

  static final Path _infinityPath = Path()
    ..moveTo(29.76, 18.72)
    ..cubicTo(29.76, 26.0, 25.84, 32.32, 19.92, 35.68)
    ..cubicTo(17.04, 37.36, 13.68, 38.32, 10.08, 38.32)
    ..cubicTo(6.48, 38.32, 3.2, 37.36, 0.32, 35.68)
    ..cubicTo(0.32, 28.4, 4.24, 22.16, 10.16, 18.72)
    ..cubicTo(13.04, 17.04, 16.4, 16.08, 19.92, 16.08)
    ..cubicTo(23.44, 16.08, 26.88, 17.04, 29.76, 18.72)
    ..cubicTo(35.6, 22.08, 39.52, 28.4, 39.6, 35.68)
    ..cubicTo(36.72, 37.36, 33.36, 38.32, 29.84, 38.32)
    ..cubicTo(26.24, 38.32, 22.96, 37.36, 20.0, 35.68)
    ..cubicTo(14.16, 32.32, 10.24, 26.0, 10.24, 18.72)
    ..cubicTo(10.24, 11.44, 14.16, 5.12, 20.0, 1.76)
    ..cubicTo(25.84, 5.12, 29.76, 11.44, 29.76, 18.72)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 44.0;
    canvas.save();
    canvas.scale(scale, scale);
    canvas.translate(2, 2);

    // Track
    final trackPaint = Paint()
      ..color = AppColors.azureSky.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(_infinityPath, trackPaint);

    // Dash
    final metrics = _infinityPath.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final totalLen = metric.length;
      final dashLen = totalLen * 0.25;
      final start = (progress * totalLen) % totalLen;
      final end = (start + dashLen) % totalLen;

      final dashPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.0;

      if (start < end) {
        canvas.drawPath(metric.extractPath(start, end), dashPaint);
      } else {
        canvas.drawPath(metric.extractPath(start, totalLen), dashPaint);
        canvas.drawPath(metric.extractPath(0, end), dashPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InfinityLoaderPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ── Skeleton Loader Shimmer ──────────────────────────────────────

class ShimmerLoader extends StatefulWidget {
  final Widget child;
  const ShimmerLoader({super.key, required this.child});

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class WisataItemSkeleton extends StatelessWidget {
  const WisataItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            const SkeletonBox(width: 90, height: 90, borderRadius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 16, borderRadius: 4),
                  SizedBox(height: 8),
                  SkeletonBox(width: 120, height: 14, borderRadius: 4),
                  SizedBox(height: 8),
                  SkeletonBox(width: 80, height: 12, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
