import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';

/// Function to show half-screen popup modal bottom sheet when airport fields are empty.
Future<void> showFlightEmptyFieldBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const FlightEmptyFieldBottomSheet(),
  );
}

class FlightEmptyFieldBottomSheet extends StatelessWidget {
  const FlightEmptyFieldBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final hPadding = Responsive.horizontalPadding(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(hPadding, 14, hPadding, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle pill
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Foto image dari assets/images/no_filed_bandara.png
          Image.asset(
            'assets/images/no_filed_bandara.png',
            height: 150,
            width: 160,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.azureSky.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.connecting_airports_rounded,
                size: 70,
                color: AppColors.azureSky,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Field Keberangkatan Kosong',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: Responsive.fontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C1B1B),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Mohon lengkapi kode bandara asal (Dari) dan bandara tujuan (Ke) terlebih dahulu sebelum mencari tiket penerbangan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 13),
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: Responsive.buttonHeight(context),
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.azureSky,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.edit_location_alt_rounded, size: 20),
              label: Text(
                'Lengkapi Sekarang',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: Responsive.fontSize(context, 16),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// Backward compatibility alias for page reference
class FlightEmptyFieldPage extends StatelessWidget {
  const FlightEmptyFieldPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FlightEmptyFieldBottomSheet();
  }
}
