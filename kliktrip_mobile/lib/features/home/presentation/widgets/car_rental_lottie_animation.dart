import 'dart:math';
import 'package:flutter/material.dart';

class CarRentalLottieAnimation extends StatefulWidget {
  const CarRentalLottieAnimation({super.key});

  @override
  State<CarRentalLottieAnimation> createState() => _CarRentalLottieAnimationState();
}

class _CarRentalLottieAnimationState extends State<CarRentalLottieAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
        final carBobbingY = sin(progress * pi * 2) * -4.0;
        final keyBounceY = (1.0 - (progress - 0.5).abs() * 2) * -10.0;
        final roadLineX = (progress * 50.0) % 30.0;
        final scaleGlow = 1.0 + (progress * 0.07);

        return SizedBox(
          width: 240,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Emerald/Azure Glow Circle
              Transform.scale(
                scale: scaleGlow,
                child: Container(
                  width: 175,
                  height: 175,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0064D2).withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0064D2).withValues(alpha: 0.15 * progress),
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
                    color: const Color(0xFF0064D2).withValues(alpha: 0.3),
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
              // Road Asphalt Track Line
              Positioned(
                bottom: 58,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    width: 160,
                    height: 5,
                    color: const Color(0xFF102A43).withValues(alpha: 0.12),
                    child: Transform.translate(
                      offset: Offset(-roadLineX, 0),
                      child: Row(
                        children: List.generate(
                          10,
                          (_) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 12,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0064D2).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Floating Rental Key Handoff Icon
              Positioned(
                top: 28,
                left: 36,
                child: Transform.translate(
                  offset: Offset(0, keyBounceY),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9500).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.vpn_key_rounded,
                      size: 22,
                      color: Color(0xFFFF9500),
                    ),
                  ),
                ),
              ),
              // Floating Location Destination Pin
              Positioned(
                top: 30,
                right: 38,
                child: Transform.scale(
                  scale: 0.9 + (sin(progress * pi) * 0.2),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C853).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      size: 22,
                      color: Color(0xFF00C853),
                    ),
                  ),
                ),
              ),
              // Car Icon directly without border box
              Transform.translate(
                offset: Offset(0, carBobbingY),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.directions_car_filled_rounded,
                      size: 64,
                      color: Color(0xFF0064D2),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFAAEE00),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
