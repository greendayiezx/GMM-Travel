import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onItemSelected;
  const BottomNav(
      {this.currentIndex = 0, required this.onItemSelected, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF161A20) : const Color(0xFF0064D2);
    final exploreBorder = isDark ? const Color(0xFF161A20) : const Color(0xFF0064D2);

    return SizedBox(
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Background Curved Navigation Bar
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: navBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              bottom: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    label: AppLocalizations.get('nav_home'),
                    isSelected: currentIndex == 0,
                    onTap: () => onItemSelected(0),
                  ),
                  _buildNavItem(
                    icon: Icons.confirmation_number_rounded,
                    label: AppLocalizations.get('nav_booking'),
                    isSelected: currentIndex == 1,
                    onTap: () => onItemSelected(1),
                  ),
                  const SizedBox(width: 48), // Space for center Explore button
                  _buildNavItem(
                    icon: Icons.favorite_rounded,
                    label: AppLocalizations.get('nav_favorite'),
                    isSelected: currentIndex == 3,
                    onTap: () => onItemSelected(3),
                  ),
                  _buildNavItem(
                    icon: Icons.person_rounded,
                    label: AppLocalizations.get('nav_account'),
                    isSelected: currentIndex == 4,
                    onTap: () => onItemSelected(4),
                  ),
                ],
              ),
            ),
          ),

          // Prominent Floating Center Explore Button
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () => onItemSelected(2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFAAEE00),
                      shape: BoxShape.circle,
                      border: Border.all(color: exploreBorder, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: exploreBorder,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    AppLocalizations.get('nav_explore'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: currentIndex == 2
                          ? const Color(0xFFAAEE00)
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.65),
              size: 22,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
