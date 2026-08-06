import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/responsive/responsive.dart';
import 'recent_search_item.dart';

/// Section "Pencarian terakhir" (judul + tombol Hapus + filter chip + list
/// horizontal, atau empty state kalau belum ada pencarian). Diekstrak dari
/// `_HomePageState.build()` — perilaku identik dengan sebelumnya.
class RecentSearchSection extends StatelessWidget {
  const RecentSearchSection({
    super.key,
    required this.recentSearches,
    required this.filters,
    required this.selectedFilterIndex,
    required this.onFilterSelected,
    required this.onClear,
    required this.onItemTap,
  });

  final List<RecentSearchItem> recentSearches;
  final List<String> filters;
  final int selectedFilterIndex;
  final ValueChanged<int> onFilterSelected;
  final VoidCallback onClear;
  final ValueChanged<RecentSearchItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    final hPadding = Responsive.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 32 * s,
                    height: 32 * s,
                    child: SvgPicture.asset(
                      'assets/images/icon_search_history.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Pencarian terakhir',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 18),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF102A43),
                    ),
                  ),
                ],
              ),
              if (recentSearches.isNotEmpty)
                GestureDetector(
                  onTap: onClear,
                  child: Text(
                    'Hapus',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0064D2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentSearches.isEmpty)
            _buildEmptyState(context)
          else ...[
            Row(
              children: List.generate(filters.length, (index) {
                final isSelected = selectedFilterIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filters[index]),
                    selected: isSelected,
                    selectedColor: const Color(0xFFEBF3FF),
                    backgroundColor: Colors.white,
                    elevation: 0,
                    pressElevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF0064D2)
                          : const Color(0xFF486581),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: Responsive.fontSize(context, 13),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF0064D2)
                          : const Color(0xFFD9E2EC),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    onSelected: (val) => onFilterSelected(index),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 82 * s,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recentSearches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _buildItemCard(context, recentSearches[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF102A43);
    final textSecondary =
        isDark ? const Color(0xFF9FB3C8) : const Color(0xFF627D98);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF2E333B)) : null,
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: const Color(0xFF0064D2),
            size: Responsive.iconSize(context, 28),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.tr(
                'Belum ada pencarian terakhir', 'No recent searches yet'),
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 14),
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.tr('Riwayat pencarianmu akan muncul di sini.',
                'Your search history will appear here.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 12),
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, RecentSearchItem item) {
    final s = Responsive.scale(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1E22) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF102A43);
    final textSecondary =
        isDark ? const Color(0xFF9FB3C8) : const Color(0xFF627D98);

    final title = item.title;
    final category = item.category;
    final icon = item.icon;
    final iconColor = item.iconColor;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onItemTap(item),
      child: Container(
        width: 250 * s,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? const Color(0xFF2E333B) : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32 * s,
              height: 32 * s,
              child: Icon(icon, color: iconColor, size: Responsive.iconSize(context, 24)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 13),
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 10),
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: isDark ? const Color(0xFF9FB3C8) : const Color(0xFF9FB3C8),
                size: 20),
          ],
        ),
      ),
    );
  }
}
