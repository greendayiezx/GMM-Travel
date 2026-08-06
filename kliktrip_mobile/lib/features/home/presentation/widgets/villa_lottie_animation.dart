import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

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
