import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable Widget for rendering official Airline Logos
class AirlineLogoWidget extends StatelessWidget {
  final String code;
  final String? name;
  final double size;
  final double borderRadius;

  const AirlineLogoWidget({
    super.key,
    required this.code,
    this.name,
    this.size = 44,
    this.borderRadius = 10,
  });

  static const Map<String, String> _airlineLogos = {};

  @override
  Widget build(BuildContext context) {
    final cleanCode =
        code.trim().toUpperCase().isNotEmpty ? code.trim().toUpperCase() : 'GA';
    final primaryUrl = _airlineLogos[cleanCode] ??
        'https://www.gstatic.com/flights/airline_logos/70px/$cleanCode.png';
    final fallbackUrl = 'https://pics.avs.io/200/200/$cleanCode.png';
    final tertiaryUrl = 'https://images.kiwi.com/airlines/64/$cleanCode.png';
    final initial = (name != null && name!.isNotEmpty)
        ? name![0].toUpperCase()
        : (code.isNotEmpty ? code[0].toUpperCase() : 'A');

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: CachedNetworkImage(
        imageUrl: primaryUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorWidget: (context, url, error) => CachedNetworkImage(
          imageUrl: fallbackUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorWidget: (context, url, error) => CachedNetworkImage(
            imageUrl: tertiaryUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorWidget: (context, url, error) => Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.azureSky.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(borderRadius - 2),
              ),
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.w800,
                  color: AppColors.azureSky,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
