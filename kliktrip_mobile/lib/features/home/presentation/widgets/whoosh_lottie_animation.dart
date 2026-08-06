import 'dart:math';
import 'package:flutter/material.dart';

class WhooshLottieAnimation extends StatefulWidget {
  const WhooshLottieAnimation({super.key});

  @override
  State<WhooshLottieAnimation> createState() => _WhooshLottieAnimationState();
}

class _WhooshLottieAnimationState extends State<WhooshLottieAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
        final progress = _controller.value;
        final trainX = -65.0 + (progress * 130.0);
        final speedLinesOpacity = (sin(progress * pi * 2).abs()).clamp(0.2, 1.0);
        final scaleGlow = 1.0 + (sin(progress * pi) * 0.06);

        return SizedBox(
          width: 240,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Crimson Red Glow Circle
              Transform.scale(
                scale: scaleGlow,
                child: Container(
                  width: 175,
                  height: 175,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFBA1A1A).withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFBA1A1A).withValues(alpha: 0.18 * progress),
                        blurRadius: 32,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              // Inner White Card Circle
              Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFBA1A1A).withValues(alpha: 0.3),
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
              // Railway Track (Bottom Rail Lines)
              Positioned(
                bottom: 60,
                child: Container(
                  width: 170,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF102A43).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      8,
                      (_) => Container(
                        width: 4,
                        height: 6,
                        color: const Color(0xFFBA1A1A).withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
              // Speed Motion Wind Lines
              Positioned(
                top: 85,
                left: 30,
                child: Opacity(
                  opacity: speedLinesOpacity,
                  child: Row(
                    children: [
                      Container(
                        width: 35,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFAAEE00),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 20,
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBA1A1A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // High-Speed Bullet Train (Moving Bullet Train)
              Transform.translate(
                offset: Offset(trainX, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBA1A1A),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFBA1A1A).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.train_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 12,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFAAEE00),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Top Electric Lightning Bolt (Sparking Pantograph)
              Positioned(
                top: 32,
                child: Opacity(
                  opacity: (sin(progress * pi * 4).abs()).clamp(0.3, 1.0),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFAAEE00).withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      size: 24,
                      color: Color(0xFFAAEE00),
                    ),
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
